// Enemy Within's people in its base (features/ew-base-people.md): each Anim_<room> level's skeletal mesh actors
// (Vahlen, Shen, the clerks and engineers) with the animations its matinee plays on them. The matinee (an InterpData)
// has a group per actor (GroupName, GroupAnimSets, an anim track's AnimSeqs, a move track); the level's SeqAct_Interp ties
// each group to its actor by a variable link named as the group. Read from the player's EW install; written as config
// lines for the mod (+People=), the meshes and AnimSets left in the level's package, which ew-package.ts makes loadable.
//   node tools/convert/ew-people.ts <EW CookedPCConsole>/Anim_ScienceLabs.upk
import { readFileSync } from 'node:fs'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { openPackage } from '@innonova/upkit/package'
import { Reader } from '@innonova/upkit/bytes'
import { readTags, type Tag } from '@innonova/upkit/objects'

export interface Person { key?: number[]; keyRot?: number[]; group: string; mesh: string; materials: string[]; loc: number[]; rot: number[]; scale: number; animSets: string[]; seqs: string[]; loop: boolean; meshRef: number; materialRefs: number[]; animSetRefs: number[] }

export function peopleOf(file: string): Person[] {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  return peopleIn(new Package(bytes), openPackage(bytes))
}

/** The people of a level already open (ew-map.ts: with its own readers of the same bytes). Material references: the
 *  component's own, else its skeletal mesh's. */
export function peopleIn(meta: any, pkg: any): Person[] {
  const exports = meta.exports as { type: string; fullName: string }[]
  const dv = (b: Uint8Array) => new DataView(b.buffer, b.byteOffset, b.byteLength)
  const path = (r: number) => (r > 0 ? exports[r - 1]!.fullName : r < 0 ? meta.imports[-r - 1].fullName : '')
  const nameAt = (i: number) => String(pkg.names[i]?.name ?? '')
  const i32 = (t: Tag | undefined, k = 0) => (t ? dv(t.value).getInt32(4 * k, true) : 0)
  const f32 = (t: Tag | undefined, k = 0) => (t ? dv(t.value).getFloat32(4 * k, true) : 0)
  const name = (t: Tag | undefined) => (t ? nameAt(dv(t.value).getInt32(0, true)) : '')
  const str = (t: Tag | undefined) => (t ? new TextDecoder('latin1').decode(t.value.subarray(4)).replace(/\0/g, '') : '')
  const structs = (v: Uint8Array): Tag[][] => {
    const n = dv(v).getInt32(0, true)
    const r = new Reader(v.subarray(4))
    return Array.from({ length: n }, () => readTags(r, pkg) as Tag[])
  }
  const refs = (t: Tag | undefined) => (t ? Array.from({ length: dv(t.value).getInt32(0, true) }, (_, k) => dv(t.value).getInt32(4 + 4 * k, true)) : [])
  const tagsAt = (i: number, starts = [4]) => {
    for (const s of starts) {
      try {
        const t = readTags(new Reader(pkg.data(i + 1).subarray(s)), pkg) as Tag[]
        if (t.length) return t
      } catch {
        // not here
      }
    }
    return [] as Tag[]
  }

  // The groups: name, AnimSets, the anim track's sequences.
  const groups = new Map<string, { animSets: string[]; seqs: string[]; animSetRefs: number[]; key?: number[]; keyRot?: number[] }>()
  exports.forEach((e, i) => {
    if (e.type !== 'InterpGroup') return
    const t = tagsAt(i)
    const setRefs = refs(t.find((x) => x.name === 'GroupAnimSets')).filter((r) => r !== 0)
    const g = { animSets: setRefs.map(path), animSetRefs: setRefs, seqs: [] as string[] }
    for (const tr of refs(t.find((x) => x.name === 'InterpTracks'))) {
      if (tr > 0 && exports[tr - 1]!.type === 'InterpTrackMove') {
        // (Its first key: where the matinee puts the actor, and its rotation.)
        const mt = tagsAt(tr - 1)
        const first = (name: string) => {
          const c = mt.find((x) => x.name === name)
          if (!c) return undefined
          const pts = (readTags(new Reader(c.value), pkg) as Tag[]).find((x) => x.name === 'Points')
          if (!pts || dv(pts.value).getInt32(0, true) < 1) return undefined
          const ov = (readTags(new Reader(pts.value.subarray(4)), pkg) as Tag[]).find((x) => x.name === 'OutVal')
          return ov ? [0, 1, 2].map((k) => dv(ov.value).getFloat32(4 * k, true)) : undefined
        }
        try {
          g.key = first('PosTrack')
          g.keyRot = first('EulerTrack')
        } catch {
          // none read
        }
      }
      if (tr <= 0 || exports[tr - 1]!.type !== 'InterpTrackAnimControl') continue
      const at = tagsAt(tr - 1).find((x) => x.name === 'AnimSeqs')
      if (at) for (const k of structs(at.value)) g.seqs.push(name(k.find((x) => x.name === 'AnimSeqName')))
    }
    groups.set(name(t.find((x) => x.name === 'GroupName')), g)
  })
  // The matinee's bindings: group name → actor (through its SeqVar_Object).
  const bound = new Map<number, string>()
  let loop = false
  exports.forEach((e, i) => {
    if (e.type !== 'SeqAct_Interp') return
    const t = tagsAt(i)
    loop = loop || t.some((x) => x.name === 'bLooping')
    const vl = t.find((x) => x.name === 'VariableLinks')
    if (!vl) return
    for (const link of structs(vl.value)) {
      const desc = str(link.find((x) => x.name === 'LinkDesc'))
      for (const v of refs(link.find((x) => x.name === 'LinkedVariables'))) {
        if (v <= 0) continue
        const actor = i32(tagsAt(v - 1).find((x) => x.name === 'ObjValue'))
        if (actor > 0) bound.set(actor, desc)
      }
    }
  })

  const out: Person[] = []
  exports.forEach((e, i) => {
    if (!/^SkeletalMeshActor/.test(e.type) || !e.fullName.startsWith('TheWorld.PersistentLevel.')) return
    const group = bound.get(i + 1)
    const g = group ? groups.get(group) : undefined
    if (!g || !g.seqs.length) return
    const t = tagsAt(i, [26, 22, 30, 4, 8])
    // (Hidden in the level: a scene's actor EW shows only while its matinee plays, as the armory's MEC suit and its weapons
    // on the soldier's pad for a MEC conversion; left out.)
    if ((t.find((x) => x.name === 'bHidden') as { boolValue?: number } | undefined)?.boolValue) return
    const comp = i32(t.find((x) => x.name === 'SkeletalMeshComponent'))
    let ct: Tag[] = []
    if (comp > 0) ct = tagsAt(comp - 1, [8, 12, 4, 16])
    const meshRef = i32(ct.find((x) => x.name === 'SkeletalMesh'))
    const mesh = path(meshRef)
    if (!mesh || /CineDummy/.test(mesh)) return
    let materialRefs = refs(ct.find((x) => x.name === 'Materials'))
    if (!materialRefs.length && meshRef > 0) {
      // (The mesh's own: a SkeletalMesh keeps them in its native data, after its properties: its bounds, 28 bytes, then
      // the materials' count and references.)
      try {
        const d: Uint8Array = pkg.data(meshRef)
        const r = new Reader(d.subarray(4))
        readTags(r, pkg)
        const o = 4 + (r as unknown as { o: number }).o + 28
        const n = dv(d).getInt32(o, true)
        if (n > 0 && n < 16) {
          const rs = Array.from({ length: n }, (_, k) => dv(d).getInt32(o + 4 + 4 * k, true))
          if (rs.every((x) => /Material/.test(x > 0 ? exports[x - 1]!.type : x < 0 ? String(meta.imports[-x - 1].className) : ''))) materialRefs = rs
        }
      } catch {
        // none read
      }
    }
    const loc = t.find((x) => x.name === 'Location')
    const rot = t.find((x) => x.name === 'Rotation')
    const ds = t.find((x) => x.name === 'DrawScale')
    out.push({
      group: group!,
      key: g.key,
      keyRot: g.keyRot,
      mesh,
      materials: materialRefs.map(path),
      meshRef,
      materialRefs,
      animSetRefs: g.animSetRefs,
      loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)],
      rot: [i32(rot, 0), i32(rot, 1), i32(rot, 2)],
      scale: ds ? f32(ds) : 1,
      animSets: g.animSets,
      seqs: g.seqs,
      loop,
    })
  })
  return out
}

if (/ew-people\.ts$/.test(process.argv[1] ?? '')) {
  for (const f of process.argv.slice(2).filter((a) => a !== '--')) for (const p of peopleOf(f)) console.log(JSON.stringify(p))
}
