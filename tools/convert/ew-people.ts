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

/** A key of a matinee's animation track (InterpTrackAnimControl's AnimSeqs): from its time on, the animation from `from`
 *  seconds to its length less `end`, forwards or (reverse) backwards, held at the stretch's end. */
export interface AnimKey { time: number; from: number; end: number; reverse: boolean }
export interface Person { bay?: number; bayState?: string; key?: number[]; keyRot?: number[]; group: string; mesh: string; materials: string[]; loc: number[]; rot: number[]; scale: number; animSets: string[]; seqs: string[]; loop: boolean; physicsAsset?: string; start?: number; rate?: number; window?: number; keys?: AnimKey[]; meshRef: number; materialRefs: number[]; animSetRefs: number[] }

export function peopleOf(file: string): Person[] {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  return peopleIn(new Package(bytes), openPackage(bytes))
}

/** The people of a level already open (ew-map.ts: with its own readers of the same bytes). Material references: the
 *  component's own, else its skeletal mesh's. */
/** The cameras of EW's matinees that the port looks through (the hangar's craft view), from the last peopleIn. */
export const cameras: { tag: string; loc: number[]; rot: number[]; fov: number }[] = []

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
  type Group = { animSets: string[]; seqs: string[]; animSetRefs: number[]; key?: number[]; keyRot?: number[]; fov?: number; start?: number }
  const groups = new Map<string, Group>()
  const groupAt = new Map<number, Group>()
  exports.forEach((e, i) => {
    if (e.type !== 'InterpGroup') return
    const t = tagsAt(i)
    const setRefs = refs(t.find((x) => x.name === 'GroupAnimSets')).filter((r) => r !== 0)
    const g: Group = { animSets: setRefs.map(path), animSetRefs: setRefs, seqs: [] as string[] }
    for (const tr of refs(t.find((x) => x.name === 'InterpTracks'))) {
      if (tr > 0 && exports[tr - 1]!.type === 'InterpTrackMove') {
        // (Its first key: where the matinee puts the actor, and its rotation.)
        const mt = tagsAt(tr - 1)
        const first = (name: string) => {
          const c = mt.find((x) => x.name === name)
          if (!c) return undefined
          const pts = (readTags(new Reader(c.value), pkg) as Tag[]).find((x) => x.name === 'Points')
          if (!pts || dv(pts.value).getInt32(0, true) < 1) return undefined
          // (A key whose value is the default, (0,0,0), has no OutVal tag: a key all the same, at the origin. The Genetics
          // Lab's canisters stand there, their conveyor animation taking them out along the room.)
          const ov = (readTags(new Reader(pts.value.subarray(4)), pkg) as Tag[]).find((x) => x.name === 'OutVal')
          return ov ? [0, 1, 2].map((k) => dv(ov.value).getFloat32(4 * k, true)) : [0, 0, 0]
        }
        try {
          g.key = first('PosTrack')
          g.keyRot = first('EulerTrack')
        } catch {
          // none read
        }
      }
      // (A camera's field of view by a float track on FOVAngle: its first key.)
      if (tr > 0 && exports[tr - 1]!.type === 'InterpTrackFloatProp') {
        const ft = tagsAt(tr - 1)
        if (name(ft.find((x) => x.name === 'PropertyName')) === 'FOVAngle') {
          try {
            const c = ft.find((x) => x.name === 'FloatTrack')
            const pts = c ? (readTags(new Reader(c.value), pkg) as Tag[]).find((x) => x.name === 'Points') : undefined
            const ov = pts && dv(pts.value).getInt32(0, true) > 0 ? (readTags(new Reader(pts.value.subarray(4)), pkg) as Tag[]).find((x) => x.name === 'OutVal') : undefined
            if (ov) g.fov = dv(ov.value).getFloat32(0, true)
          } catch {
            // none read
          }
        }
      }
      if (tr <= 0 || exports[tr - 1]!.type !== 'InterpTrackAnimControl') continue
      const at = tagsAt(tr - 1).find((x) => x.name === 'AnimSeqs')
      if (at)
        for (const k of structs(at.value)) {
          g.seqs.push(name(k.find((x) => x.name === 'AnimSeqName')))
          // (Where in it the matinee has it at its own start: the key's start offset, plus how long it has played already where
          // the key starts before the matinee does. The Genetics Lab's canisters share one conveyor animation, each keyed
          // 1.667 s after the next in the lab's base loop, so each rides at its own place on the belt.)
          if (g.start === undefined) g.start = f32(k.find((x) => x.name === 'AnimStartOffset')) - f32(k.find((x) => x.name === 'StartTime'))
        }
    }
    groups.set(name(t.find((x) => x.name === 'GroupName')), g)
    groupAt.set(i + 1, g)
  })
  // The matinee's bindings: group name → actor (through its SeqVar_Object).
  const bound = new Map<number, string>()
  // (The play rate of the looping matinee an actor is in: the Genetics Lab's base loop runs at half speed.)
  const rateOf = new Map<number, number>()
  // (And its length: EW's base loop replays that much of each canister's animation from its place, then starts over.)
  const windowOf = new Map<number, number>()
  const keysOf = new Map<number, AnimKey[]>()
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
        const pr = t.find((x) => x.name === 'PlayRate')
        if (actor > 0 && pr && t.some((x) => x.name === 'bLooping')) {
          rateOf.set(actor, f32(pr))
          for (const l2 of structs(vl.value))
            for (const d of refs(l2.find((x) => x.name === 'LinkedVariables'))) {
              if (d <= 0 || exports[d - 1]!.type !== 'InterpData') continue
              windowOf.set(actor, f32(tagsAt(d - 1).find((x) => x.name === 'InterpLength')))
              // (Its animation keys in that matinee: where each starts, the stretch of the animation it plays, forwards or
              // back. The canisters' base loop steps them along the belt and back, six keys each.)
              for (const gr of refs(tagsAt(d - 1).find((x) => x.name === 'InterpGroups'))) {
                const gt = tagsAt(gr - 1)
                if (name(gt.find((x) => x.name === 'GroupName')) !== desc) continue
                for (const tr of refs(gt.find((x) => x.name === 'InterpTracks'))) {
                  if (tr <= 0 || exports[tr - 1]!.type !== 'InterpTrackAnimControl') continue
                  const ak = tagsAt(tr - 1).find((x) => x.name === 'AnimSeqs')
                  if (ak)
                    keysOf.set(actor, structs(ak.value).map((k) => ({
                      time: f32(k.find((x) => x.name === 'StartTime')),
                      from: f32(k.find((x) => x.name === 'AnimStartOffset')),
                      end: f32(k.find((x) => x.name === 'AnimEndOffset')),
                      reverse: !!(k.find((x) => x.name === 'bReverse') as { boolValue?: number } | undefined)?.boolValue,
                    })))
                }
              }
            }
        }
      }
    }
  })

  // Where the matinee puts an actor. An actor attached to another (its Base: EW hangs a scene's people and props on a
  // hidden CineDummy) has its keys in its base's frame: the base where the matinee puts it (its own group's first key),
  // else where it stands; turned by the base's yaw. An actor on its own: its key is where it goes. (Before, the keys were
  // read as one frame per level, which held for none: engineering's people stood about the room's front.)
  const deg = 65536 / 360
  const actorAt = (a: number) => {
    const t = tagsAt(a - 1, [26, 22, 30, 4, 8])
    const loc = t.find((x) => x.name === 'Location')
    const rot = t.find((x) => x.name === 'Rotation')
    return { t, loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)], rot: [i32(rot, 0), i32(rot, 1), i32(rot, 2)] }
  }
  const placed = (actor: number, g: Group, groupOf: (a: number) => Group | undefined): { loc: number[]; rot: number[] } | undefined => {
    if (!g.key) return undefined
    const r = g.keyRot ?? [0, 0, 0]
    const own = { loc: g.key, rot: [Math.round(r[1]! * deg), Math.round(r[2]! * deg), Math.round(r[0]! * deg)] }
    const base = i32(actorAt(actor).t.find((x) => x.name === 'Base'))
    if (base <= 0) return own
    const bg = groupOf(base)
    const frame = bg?.key ? placed(base, bg, groupOf) ?? actorAt(base) : actorAt(base)
    const yaw = (frame.rot[1]! / 65536) * 2 * Math.PI
    const [x, y, z] = own.loc as [number, number, number]
    return {
      loc: [frame.loc[0]! + x * Math.cos(yaw) - y * Math.sin(yaw), frame.loc[1]! + x * Math.sin(yaw) + y * Math.cos(yaw), frame.loc[2]! + z],
      rot: [own.rot[0]!, own.rot[1]! + frame.rot[1]!, own.rot[2]!],
    }
  }

  // EW's hangar bays (Anim_Hangar_LaunchBays): a matinee per bay and state, Base_Bay<n>_<Open|Repair|Closed>
  // (XGFacility_Hangar.UpdateHangarBays plays one of the three per bay). Its Track group is the bay's launch pad (an actor
  // of the level, posed by the state's loop); its Interceptor and FireStorm groups are where the bay's craft stands
  // (XGFacility_Hangar.SetHangarShipsForKismet binds the craft; the level's own stand-ins are hidden). Each a record of
  // its bay and state; their actors not people of the level.
  const bays: Person[] = []
  const inBays = new Set<number>()
  cameras.length = 0
  exports.forEach((e, i) => {
    if (e.type !== 'SeqAct_Interp') return
    const t = tagsAt(i)
    const m = /^Base_Bay(\d)_(Open|Repair|Closed|ViewWeapons)$/.exec(str(t.find((x) => x.name === 'ObjComment')))
    const vl = t.find((x) => x.name === 'VariableLinks')
    if (!m || !vl) return
    const links = structs(vl.value).map((link) => ({ desc: str(link.find((x) => x.name === 'LinkDesc')), vars: refs(link.find((x) => x.name === 'LinkedVariables')).filter((v) => v > 0) }))
    const data = links.flatMap((l) => l.vars).find((v) => exports[v - 1]!.type === 'InterpData')
    if (!data) return
    const byName = new Map<string, Group>()
    for (const gr of refs(tagsAt(data - 1).find((x) => x.name === 'InterpGroups'))) {
      const g = groupAt.get(gr)
      if (g) byName.set(name(tagsAt(gr - 1).find((x) => x.name === 'GroupName')), g)
    }
    const descOf = new Map<number, string>()
    for (const l of links) for (const v of l.vars) if (exports[v - 1]!.type === 'SeqVar_Object') descOf.set(i32(tagsAt(v - 1).find((x) => x.name === 'ObjValue')), l.desc)
    const groupOf = (a: number) => byName.get(descOf.get(a) ?? '')
    for (const l of links) {
      const g = byName.get(l.desc)
      // (The craft summary's view, ViewWeapons: its camera, Cam01, where the matinee puts it, its field of view the
      // camera's own; XGFacility_Hangar.SetupWeaponView plays it with the chosen craft in bay 1.)
      for (const v of g && !g.seqs.length ? l.vars : []) {
        const actor = exports[v - 1]!.type === 'SeqVar_Object' ? i32(tagsAt(v - 1).find((x) => x.name === 'ObjValue')) : 0
        if (actor <= 0 || exports[actor - 1]!.type !== 'CameraActor') continue
        const at = placed(actor, g!, groupOf)
        const fov = actorAt(actor).t.find((x) => x.name === 'FOVAngle')
        if (at) cameras.push({ tag: `Hangar_Bay${m[1]}_${m[2]}`, loc: at.loc, rot: at.rot, fov: g!.fov ?? (fov ? f32(fov) : 90) })
      }
      if (!g || !g.seqs.length) continue
      for (const v of l.vars) {
        if (exports[v - 1]!.type !== 'SeqVar_Object') continue
        const actor = i32(tagsAt(v - 1).find((x) => x.name === 'ObjValue'))
        if (actor <= 0 || !/^SkeletalMeshActor/.test(exports[actor - 1]!.type)) continue
        inBays.add(actor)
        const p = personOf(actor - 1, l.desc, g, true)
        if (!p) continue
        p.bay = Number(m[1])
        p.bayState = m[2]
        // (The pad and the craft where the state's matinee puts them: the pad on its base, turned by its key so its arm (its
        // bones' −Y) reaches the bay; a craft (bound at run time to the bay's ship, on nothing) at its key.)
        const at = placed(actor, g, groupOf)
        if (at) {
          p.loc = at.loc
          p.rot = at.rot
        }
        p.key = undefined
        bays.push(p)
      }
    }
  })

  function personOf(i: number, group: string, g: Group, hiddenToo = false): Person | undefined {
    const t = tagsAt(i, [26, 22, 30, 4, 8])
    // (Hidden in the level: a scene's actor EW shows only while its matinee plays, as the armory's MEC suit and its weapons
    // on the soldier's pad for a MEC conversion; left out.)
    if (!hiddenToo && (t.find((x) => x.name === 'bHidden') as { boolValue?: number } | undefined)?.boolValue) return
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
          // (Empty slots allowed: the Genetics Lab's station has two.)
          if (rs.some((x) => x !== 0) && rs.every((x) => x === 0 || /Material/.test(x > 0 ? exports[x - 1]!.type : String(meta.imports[-x - 1].className)))) materialRefs = rs
        }
      } catch {
        // none read
      }
    }
    const loc = t.find((x) => x.name === 'Location')
    const rot = t.find((x) => x.name === 'Rotation')
    const ds = t.find((x) => x.name === 'DrawScale')
    // (Its physics asset: the Genetics Lab's canisters ride a conveyor their animation drives a bone along, from the rack
    // under the ceiling down to the column; their bounds follow the bodies of PHYS_Canister. Without it the bounds stayed
    // the mesh's at the rack, and the canisters were never drawn at the column.)
    const physicsAsset = path(i32(ct.find((x) => x.name === 'PhysicsAsset'))) || undefined
    return {
      physicsAsset,
      group,
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
      seqs: [...g.seqs],
      start: g.start || undefined,
      rate: rateOf.get(i + 1),
      window: windowOf.get(i + 1) || undefined,
      keys: keysOf.get(i + 1),
      loop,
    }
  }

  const out: Person[] = []
  exports.forEach((e, i) => {
    if (!/^SkeletalMeshActor/.test(e.type) || !e.fullName.startsWith('TheWorld.PersistentLevel.') || inBays.has(i + 1)) return
    const group = bound.get(i + 1)
    const g = group ? groups.get(group) : undefined
    if (!g || !g.seqs.length) return
    const p = personOf(i, group!, g)
    if (!p) return
    // (Attached to a base: placed by the matinee, in its base's frame; on its own, where it stands, as before.)
    if (i32(actorAt(i + 1).t.find((x) => x.name === 'Base')) > 0) {
      const at = placed(i + 1, g, (a) => (bound.has(a) ? groups.get(bound.get(a)!) : undefined))
      if (at) {
        p.loc = at.loc
        p.rot = at.rot
        p.key = undefined
      }
    }
    out.push(p)
  })
  return [...out, ...bays]
}

if (/ew-people\.ts$/.test(process.argv[1] ?? '')) {
  for (const f of process.argv.slice(2).filter((a) => a !== '--')) for (const p of peopleOf(f)) console.log(JSON.stringify(p))
}

/**
 * Where EW's matinees leave the actors they move by separate axes (InterpTrackMove's SubTracks, InterpTrackMoveAxis: the
 * main menu's camera, XComShell's LeftShoulder): each axis's last key, for each actor a SeqAct_Interp binds to such a group
 * (by its variable link named as the group). Translation as given; rotation in degrees (X roll, Y pitch, Z yaw) made
 * rotator units. An axis without keys leaves the actor's own value (undefined here).
 */
export function matineeAxisPoses(meta: any, pkg: any): Map<number, { loc: (number | undefined)[]; rot: (number | undefined)[] }> {
  const exports = meta.exports as { type: string; fullName: string }[]
  const dv = (b: Uint8Array) => new DataView(b.buffer, b.byteOffset, b.byteLength)
  const nameAt = (i: number) => String(pkg.names[i]?.name ?? '')
  const tagsAt = (i: number) => {
    for (const s of [4, 8]) {
      try {
        const t = readTags(new Reader(pkg.data(i + 1).subarray(s)), pkg) as Tag[]
        if (t.length) return t
      } catch {
        // not here
      }
    }
    return [] as Tag[]
  }
  const refs = (t: Tag | undefined) => (t ? Array.from({ length: dv(t.value).getInt32(0, true) }, (_, k) => dv(t.value).getInt32(4 + 4 * k, true)) : [])
  const structs = (v: Uint8Array): Tag[][] => {
    const n = dv(v).getInt32(0, true)
    const r = new Reader(v.subarray(4))
    return Array.from({ length: n }, () => readTags(r, pkg) as Tag[])
  }
  const str = (t: Tag | undefined) => (t ? new TextDecoder('latin1').decode(t.value.subarray(4)).replace(/\0/g, '') : '')
  const AXES = ['AXIS_TranslationX', 'AXIS_TranslationY', 'AXIS_TranslationZ', 'AXIS_RotationX', 'AXIS_RotationY', 'AXIS_RotationZ']
  // A group's axes' last keys.
  const groupAxes = (g: number): (number | undefined)[] | undefined => {
    let out: (number | undefined)[] | undefined
    for (const tr of refs(tagsAt(g - 1).find((x) => x.name === 'InterpTracks'))) {
      if (tr <= 0 || exports[tr - 1]!.type !== 'InterpTrackMove') continue
      for (const sub of refs(tagsAt(tr - 1).find((x) => x.name === 'SubTracks'))) {
        if (sub <= 0 || exports[sub - 1]!.type !== 'InterpTrackMoveAxis') continue
        const st = tagsAt(sub - 1)
        const ax = st.find((x) => x.name === 'MoveAxis')
        const k = AXES.indexOf(ax ? nameAt(dv(ax.value).getInt32(0, true)) : 'AXIS_TranslationX')
        const ft = st.find((x) => x.name === 'FloatTrack')
        if (k < 0 || !ft) continue
        const pts = (readTags(new Reader(ft.value), pkg) as Tag[]).find((x) => x.name === 'Points')
        if (!pts) continue
        const keys = structs(pts.value)
        const last = keys[keys.length - 1]?.find((x) => x.name === 'OutVal')
        if (!last) continue
        out ??= [undefined, undefined, undefined, undefined, undefined, undefined]
        out[k] = dv(last.value).getFloat32(0, true)
      }
    }
    return out
  }
  const poses = new Map<number, { loc: (number | undefined)[]; rot: (number | undefined)[] }>()
  exports.forEach((e, i) => {
    if (e.type !== 'SeqAct_Interp') return
    const vl = tagsAt(i).find((x) => x.name === 'VariableLinks')
    if (!vl) return
    const links = structs(vl.value).map((l) => ({ desc: str(l.find((x) => x.name === 'LinkDesc')), vars: refs(l.find((x) => x.name === 'LinkedVariables')).filter((v) => v > 0) }))
    const data = links.flatMap((l) => l.vars).find((v) => exports[v - 1]!.type === 'InterpData')
    if (!data) return
    const byName = new Map<string, number>()
    for (const g of refs(tagsAt(data - 1).find((x) => x.name === 'InterpGroups'))) {
      const gn = tagsAt(g - 1).find((x) => x.name === 'GroupName')
      if (gn) byName.set(nameAt(dv(gn.value).getInt32(0, true)), g)
    }
    for (const l of links) {
      const g = byName.get(l.desc)
      const axes = g ? groupAxes(g) : undefined
      if (!axes) continue
      for (const v of l.vars) {
        if (exports[v - 1]!.type !== 'SeqVar_Object') continue
        const o = tagsAt(v - 1).find((x) => x.name === 'ObjValue')
        const actor = o ? dv(o.value).getInt32(0, true) : 0
        if (actor <= 0) continue
        const deg = 65536 / 360
        poses.set(actor, {
          loc: [axes[0], axes[1], axes[2]],
          // (Rotator order: pitch, yaw, roll.)
          rot: [axes[4] !== undefined ? Math.round(axes[4] * deg) : undefined, axes[5] !== undefined ? Math.round(axes[5] * deg) : undefined, axes[3] !== undefined ? Math.round(axes[3] * deg) : undefined],
        })
      }
    }
  })
  return poses
}
