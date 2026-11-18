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

export interface Person { group: string; mesh: string; materials: string[]; loc: number[]; rot: number[]; scale: number; animSets: string[]; seqs: string[]; loop: boolean }

export function peopleOf(file: string): Person[] {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
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
  const groups = new Map<string, { animSets: string[]; seqs: string[] }>()
  exports.forEach((e, i) => {
    if (e.type !== 'InterpGroup') return
    const t = tagsAt(i)
    const g = { animSets: refs(t.find((x) => x.name === 'GroupAnimSets')).map(path).filter(Boolean), seqs: [] as string[] }
    for (const tr of refs(t.find((x) => x.name === 'InterpTracks'))) {
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
    const comp = i32(t.find((x) => x.name === 'SkeletalMeshComponent'))
    let ct: Tag[] = []
    if (comp > 0) ct = tagsAt(comp - 1, [8, 12, 4, 16])
    const mesh = path(i32(ct.find((x) => x.name === 'SkeletalMesh')))
    if (!mesh || /CineDummy/.test(mesh)) return
    const loc = t.find((x) => x.name === 'Location')
    const rot = t.find((x) => x.name === 'Rotation')
    const ds = t.find((x) => x.name === 'DrawScale')
    out.push({
      group: group!,
      mesh,
      materials: refs(ct.find((x) => x.name === 'Materials')).map(path),
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
