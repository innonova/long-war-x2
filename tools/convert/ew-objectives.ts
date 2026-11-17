// Enemy Within's council missions' objectives (features/lw-council-missions.md, step 2), read from the player's own install:
// a mission variant is a streamed level beside its map (URB_CemeteryGrand_Bomb.upk …, the mod's XComLWCouncil.ini names each
// mission's, from Long War's DefaultMaps.ini) whose Kismet holds its rules and whose actors mark its objects. For the bomb disposals: the bomb (the high hot button, HotButton.ARC_IA_HotButtonColumnHigh, where
// EW's bomb stands) and the power nodes (the low hot buttons), at EW's coordinates (the map's plot keeps them); the bomb's
// Timer at the start and the number of nodes (#Nodes), the Kismet variables of those names. Written as the mod's config,
// Config/XComLWX2EWObjectives.ini (+Bombs=), which LWX2CouncilBomb reads. Numbers only.
//   node tools/convert/ew-objectives.ts <EW CookedPCConsole> <mod folder>
import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { openPackage } from '@innonova/upkit/package'
import { Reader } from '@innonova/upkit/bytes'
import { readTags, type Tag } from '@innonova/upkit/objects'
import { Linker } from '@innonova/upkit/linker'
import { decompileFunction } from '@innonova/upkit/decompile'

/** The council's missions (the mod's Config/XComLWCouncil.ini, from Long War's own data: scripts/council-config.mjs): each
 *  its kind (1 assault, 2 bomb, 3 extraction, 4 rescue), its EW map and the streamed level that carries its variant. */
export interface CouncilMission { id: number; kind: number; map: string; level: string }
export function councilMissions(mod: string): CouncilMission[] {
  const ini = join(mod, 'Config', 'XComLWCouncil.ini')
  if (!existsSync(ini)) return []
  return [...readFileSync(ini, 'latin1').matchAll(/^\+Missions=\(Id=(\d+), Kind=(\d+), Map="(\w+)", Level="(\w*)"/gm)]
    .map((m) => ({ id: Number(m[1]), kind: Number(m[2]), map: m[3]!, level: m[4]! }))
    .filter((m) => m.level)
}

/** EXALT's covert missions' maps (the mod's Config/XComLWEWMaps.ini, from Long War's DefaultMaps.ini: scripts/maps-config.mjs),
 *  each with its kind (CovertExtraction, DataRecovery) and the streamed level that carries it. */
export interface CovertMap { map: string; kind: string; level: string }
export function covertMaps(mod: string): CovertMap[] {
  const ini = join(mod, 'Config', 'XComLWEWMaps.ini')
  if (!existsSync(ini)) return []
  return [...readFileSync(ini, 'latin1').matchAll(/^\+Maps=\(Name="(\w+)".*Kind=(\w+),.*Level="(\w+)"/gm)].map((m) => ({ map: m[1]!, kind: m[2]!, level: m[3]! }))
}

/** Every map with a variant level (the council's missions, EXALT's covert ones): [map, level], each pair once. */
export function variantPairs(mod: string): [string, string][] {
  const pairs = new Map<string, string>()
  for (const m of [...councilMissions(mod), ...covertMaps(mod)]) pairs.set(m.level, m.map)
  return [...pairs].map(([level, map]) => [map, level])
}

/** The variant levels of these maps' missions: converted with them, each joined with its map into a plot of its own,
 *  LWX2V_<level> (ew-maps.ts writePlots), on which that mission plays. */
export function variantLevels(mod: string, maps: Iterable<string>): string[] {
  const want = new Set(maps)
  return [...new Set(variantPairs(mod).filter(([map]) => want.has(map)).map(([, level]) => level))]
}

/** A level's package in the install, whatever the case of its name (Long War writes URB_HighwayBomb_Stream, EW ships
 *  URB_HIghwayBomb_Stream.upk). */
function levelFile(cooked: string, level: string): string | undefined {
  const exact = join(cooked, `${level}.upk`)
  if (existsSync(exact)) return exact
  const found = readdirSync(cooked).find((f) => f.toLowerCase() === `${level}.upk`.toLowerCase())
  return found ? join(cooked, found) : undefined
}

export interface Bomb { map: string; level: string; timer: number; nodes: number; bomb: number[]; nodeAt: number[][] }

/** A bomb disposal's level read: its bomb, nodes and numbers; undefined when it is not as expected. */
export function readBomb(file: string, map: string, level: string): Bomb | undefined {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  const dv = (t: Tag) => new DataView(t.value.buffer, t.value.byteOffset, t.value.byteLength)
  const nameOf = (i: number) => String(pkg.names[i]?.name)
  const archetypeOf = (k: number) => {
    const r = v.getInt32(meta.exports[k].entryOffset + 20, true)
    return r > 0 ? meta.exports[r - 1].fullName : r < 0 ? meta.imports[-r - 1].fullName : ''
  }
  // A placed actor's properties: after its state frame, found by trying (as ew-map.ts's actorTags).
  const actorTags = (k: number): Tag[] => {
    const data = pkg.data(k + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, j) => j)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), pkg)
        if (t.some((x: Tag) => x.name === 'Location' || x.name === 'StaticMeshComponent' || x.name === 'SkeletalMeshComponent')) return t
      } catch {
        // not here
      }
    }
    return []
  }
  const locationOf = (k: number): number[] | undefined => {
    const loc = actorTags(k).find((t) => t.name === 'Location')
    return loc ? [0, 4, 8].map((o) => Math.round(dv(loc).getFloat32(o, true))) : undefined
  }
  let timer = 0
  let nodes = 0
  let bomb: number[] | undefined
  const nodeAt: number[][] = []
  meta.exports.forEach((e: any, k: number) => {
    if (e.type === 'SeqVar_Int') {
      const t = readTags(new Reader(pkg.data(k + 1).subarray(4)), pkg) as Tag[]
      const name = t.find((x) => x.name === 'VarName')
      const value = t.find((x) => x.name === 'IntValue')
      if (name && value && nameOf(dv(name).getInt32(0, true)) === 'Timer') timer = dv(value).getInt32(0, true)
      if (name && value && nameOf(dv(name).getInt32(0, true)) === '#Nodes') nodes = dv(value).getInt32(0, true)
    }
    if (e.type === 'XComInteractiveLevelActor' && /PersistentLevel/.test(e.fullName)) {
      const a = archetypeOf(k)
      const at = locationOf(k) ?? locationOf(meta.exports.findIndex((x: any) => x.fullName === a))
      if (!at) return
      if (/HotButtonColumnHigh/.test(a)) bomb = at
      else if (/HotButtonColumnLow/.test(a)) nodeAt.push(at)
    }
  })
  if (!bomb || nodeAt.length === 0 || timer <= 0) return undefined
  return { map, level, timer, nodes: nodes || nodeAt.length, bomb, nodeAt }
}

/** A Kismet op or variable: its class, properties, output links and variable links (export indices, 0-based). */
interface KOp { k: number; type: string; props: Map<string, Tag>; out: number[]; links: { desc: string; to: number }[]; vars: Map<string, number[]> }

/** A level's whole Kismet (every sequence's ops and variables), with what is needed to follow it. */
function readKismet(bytes: Uint8Array) {
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const dv = (b: Uint8Array) => new DataView(b.buffer, b.byteOffset, b.byteLength)
  const nameOf = (i: number) => String(pkg.names[i]?.name)
  const structs = (v: Uint8Array): Tag[][] => {
    const n = dv(v).getInt32(0, true)
    const r = new Reader(v.subarray(4))
    return Array.from({ length: n }, () => readTags(r, pkg) as Tag[])
  }
  const str = (t: Tag | undefined) => (t ? new TextDecoder('latin1').decode(t.value.subarray(4)).replace(/\0/g, '') : '')
  const ops = new Map<number, KOp>()
  meta.exports.forEach((e: any, k: number) => {
    if (!/^Seq/.test(e.type)) return
    let tags: Tag[] = []
    try {
      tags = readTags(new Reader(pkg.data(k + 1).subarray(4)), pkg) as Tag[]
    } catch {
      return
    }
    const op: KOp = { k, type: e.type, props: new Map(), out: [], links: [], vars: new Map() }
    for (const t of tags) {
      if (t.name === 'OutputLinks' && t.type === 'ArrayProperty') {
        for (const ol of structs(t.value)) {
          const desc = str(ol.find((x) => x.name === 'LinkDesc'))
          const links = ol.find((x) => x.name === 'Links')
          if (links) for (const l of structs(links.value)) {
            const to = l.find((x) => x.name === 'LinkedOp')
            if (to) {
              op.out.push(dv(to.value).getInt32(0, true) - 1)
              op.links.push({ desc, to: dv(to.value).getInt32(0, true) - 1 })
            }
          }
        }
      } else if (t.name === 'VariableLinks' && t.type === 'ArrayProperty') {
        for (const vl of structs(t.value)) {
          const desc = str(vl.find((x) => x.name === 'LinkDesc'))
          const lv = vl.find((x) => x.name === 'LinkedVariables')
          if (!lv) continue
          const n = dv(lv.value).getInt32(0, true)
          op.vars.set(desc, Array.from({ length: n }, (_, i) => dv(lv.value).getInt32(4 + 4 * i, true) - 1))
        }
      } else op.props.set(t.name, t)
    }
    ops.set(k, op)
  })
  return {
    ops: [...ops.values()],
    op: (k: number) => ops.get(k),
    /** A property as a name, a string or an object (export index). */
    name: (o: KOp, p: string) => {
      const t = o.props.get(p)
      return t ? (t.value.length === 8 || t.type === 'NameProperty' ? nameOf(dv(t.value).getInt32(0, true)) : '') : ''
    },
    str: (o: KOp, p: string) => str(o.props.get(p)),
    obj: (o: KOp, p: string) => {
      const t = o.props.get(p)
      return t ? dv(t.value).getInt32(0, true) - 1 : -1
    },
    /** The ops reached from one (its output links, up to depth). */
    reach: (from: KOp, depth: number): KOp[] => {
      const seen = new Set<number>([from.k])
      let front = [from.k]
      for (let d = 0; d < depth; d++) {
        front = front.flatMap((k) => ops.get(k)?.out ?? []).filter((k) => !seen.has(k) && ops.has(k))
        front.forEach((k) => seen.add(k))
      }
      return [...seen].filter((k) => k !== from.k).map((k) => ops.get(k)!)
    },
  }
}

export interface VIP {
  map: string
  level: string
  /** Where the VIP stands (the spawn point of EW's SpawnCivilian), and its name. */
  at: number[]
  first: string
  last: string
  /** Where XCOM's soldiers find the VIP (the volume whose touch swaps it to XCOM); none: XCOM's from the start (a rescue). */
  approach?: number[]
  /** Where it is to be escorted (the Skyranger: the arrow's target as the escort begins). */
  extract: number[]
  /** EW's objective texts in their order (locate, approach, escort; or escort alone), then "kill the rest" and "report to evac". */
  texts: string[]
  killRest: string
  report: string
}

/** A VIP mission's level read: the VIP, where it is found and where it goes; undefined when it is not as expected. */
export function readVIP(file: string, map: string, level: string): VIP | undefined {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const K = readKismet(bytes)
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  const dv = (t: Tag) => new DataView(t.value.buffer, t.value.byteOffset, t.value.byteLength)
  const archetypeOf = (k: number) => {
    const r = v.getInt32(meta.exports[k].entryOffset + 20, true)
    return r > 0 ? r - 1 : -1
  }
  const actorTags = (k: number): Tag[] => {
    const data = pkg.data(k + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, j) => j)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), pkg)
        if (t.some((x: Tag) => x.name === 'Location' || x.name === 'Tag')) return t
      } catch {
        // not here
      }
    }
    return []
  }
  const locationOf = (k: number): number[] | undefined => {
    if (k < 0) return undefined
    const loc = actorTags(k).find((t) => t.name === 'Location')
    if (loc) return [0, 4, 8].map((o) => Math.round(dv(loc).getFloat32(o, true)))
    return archetypeOf(k) >= 0 ? locationOf(archetypeOf(k)) : undefined
  }
  /** The actor a variable holds (a SeqVar_Object's ObjValue). */
  const held = (k: number | undefined) => (k !== undefined && K.op(k) ? K.obj(K.op(k)!, 'ObjValue') : -1)
  const text = (k: number | undefined) => (k !== undefined && K.op(k) ? K.str(K.op(k)!, 'StrValue') : '')
  const civ = K.ops.find((o) => o.type === 'SeqAct_SpawnCivilian' && o.out.some((k) => K.op(k)?.type === 'SeqAct_XComSetUnitName'))
  if (!civ) return undefined
  const at = locationOf(held(civ.vars.get('SpawnPoints')?.[0]))
  const naming = civ.out.map((k) => K.op(k)!).find((o) => o?.type === 'SeqAct_XComSetUnitName')!
  const toXCom = K.ops.filter((o) => o.type === 'SeqAct_SwapTeams' && /XCom/.test(K.name(o, 'DestinationTeam')))
  const joins = (o: KOp) => o.out.some((k) => toXCom.some((x) => x.k === k))
  // Approached: the touched volume that swaps it to XCOM (none when the spawn does it).
  const touch = joins(civ) ? undefined : K.ops.find((o) => o.type === 'SeqEvent_Touch' && joins(o))
  const approach = touch ? locationOf(K.obj(touch, 'Originator')) : undefined
  // The Skyranger: the arrow shown as the escort begins (the first shown: one over the VIP is taken off first).
  const escort = K.ops.find((o) => o.type === 'SeqEvent_RemoteEvent' && K.name(o, 'EventName') === 'EscortVIP_Begin')
  const shown = (o: KOp) => {
    const b = K.op(o.vars.get('bShow?')?.[0] ?? -1)?.props.get('bValue')
    return !!b && new DataView(b.value.buffer, b.value.byteOffset, 4).getInt32(0, true) !== 0
  }
  const arrow = escort ? K.reach(escort, 3).find((o) => o.type === 'SeqAct_DisplayUIArrowPointingToActor' && shown(o)) : undefined
  const extract = arrow ? locationOf(held(arrow.vars.get('Target Actor')?.[0])) : undefined
  if (!at || !extract || (!joins(civ) && !approach)) return undefined
  // EW's texts, by their localization keys: m_str<Place>Extract1..3 / m_str<Place>Rescue1, and the shared ones.
  const strings = K.ops.filter((o) => o.type === 'SeqVar_LocalizedString').map((o) => ({ key: K.str(o, 'strLookup').split('.').pop() ?? '', value: K.str(o, 'StrValue') }))
  // (Progeny's Portent: m_strDLC2_1Obj1..3, then its own "kill the rest" and "report to evac", 4 and 5.)
  const texts = strings.filter((s) => /(Extract|Rescue)\d$|DLC2_1Obj[1-3]$/.test(s.key)).sort((a, b) => a.key.localeCompare(b.key)).map((s) => s.value)
  const shared = (key: string, other = '') => strings.find((s) => s.key === key)?.value ?? strings.find((s) => s.key === other)?.value ?? ''
  return {
    map, level, at, approach, extract, texts,
    first: text(naming.vars.get('First Name')?.[0]),
    last: text(naming.vars.get('Last Name')?.[0]),
    killRest: shared('m_strBombObj3', 'm_strDLC2_1Obj4'),
    report: shared('m_strBombObj4', 'm_strDLC2_1Obj5'),
  }
}

export interface Covert {
  map: string
  level: string
  /** EW's comm relays (its radar arrays), of which the battle activates two; the operative's own spawn point. */
  relays: number[][]
  operative?: number[]
  /** EW's texts: hack the relays, the count's label, escort the operative, eliminate or evacuate, retreat. */
  hack: string
  left: string
  escort: string
  cleanup: string
  retreat: string
}

/** A covert extraction's level read (XGBattle_SPCovertOpsExtraction's: its XComRadarArrayActors and the covert operative's
 *  spawn point; the Kismet's texts); undefined when it has no relays. */
export function readCovert(file: string, map: string, level: string): Covert | undefined {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const K = readKismet(bytes)
  const dv = (t: Tag) => new DataView(t.value.buffer, t.value.byteOffset, t.value.byteLength)
  const actorTags = (k: number): Tag[] => {
    const data = pkg.data(k + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, j) => j)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), pkg)
        if (t.some((x: Tag) => x.name === 'Location')) return t
      } catch {
        // not here
      }
    }
    return []
  }
  const at = (t: Tag[]) => {
    const loc = t.find((x) => x.name === 'Location')
    return loc ? [0, 4, 8].map((o) => Math.round(dv(loc).getFloat32(o, true))) : undefined
  }
  const relays: number[][] = []
  let operative: number[] | undefined
  meta.exports.forEach((e: any, k: number) => {
    if (!/^TheWorld\.PersistentLevel\.[^.]+$/.test(e.fullName)) return
    if (e.type === 'XComRadarArrayActor') {
      const p = at(actorTags(k))
      if (p) relays.push(p)
    }
    if (e.type === 'XComSpawnPoint') {
      const t = actorTags(k)
      const type = t.find((x) => x.name === 'UnitType')
      if (type && /CovertOperative/.test(String(pkg.names[dv(type).getInt32(0, true)]?.name))) operative = at(t)
    }
  })
  if (relays.length < 2) return undefined
  const strings = new Map(K.ops.filter((o) => o.type === 'SeqVar_LocalizedString').map((o) => [K.str(o, 'strLookup').split('.').pop() ?? '', K.str(o, 'StrValue')]))
  return {
    map, level, relays, operative,
    hack: strings.get('m_strCovExObj1') ?? '',
    left: (strings.get('m_strCovExArrayCount') ?? '').trim(),
    escort: strings.get('m_strCovExObj2') ?? '',
    cleanup: strings.get('m_strCovExObj3') ?? '',
    retreat: strings.get('m_strCovExObj4') ?? '',
  }
}

export interface Recovery {
  map: string
  level: string
  /** EW's capture areas (XComCapturePointVolume): the box, the turns EXALT needs alone in it, its order (0 first). */
  points: { center: number[]; extent: number[]; turns: number; seq: number }[]
  /** EW's wave system (XComWaveSystem): each group of each wave, its set (0 from the start, 1 once the first area
   *  falls), its turn after the set starts, how many and where. */
  groups: { set: number; turn: number; count: number; at: number[][] }[]
  /** EW's texts: protect the area, protect the backup, eliminate all EXALT, the hint. */
  protect: string
  backup: string
  kill: string
  hint: string
}

/** A data recovery's level read (XGBattle_SPCaptureAndHold's capture areas and the level's wave system; the Kismet's
 *  texts); undefined when it has no capture area. */
export function readRecovery(file: string, map: string, level: string): Recovery | undefined {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const K = readKismet(bytes)
  const dv = (b: Uint8Array) => new DataView(b.buffer, b.byteOffset, b.byteLength)
  const nameOf = (t: Tag | undefined) => (t ? String(pkg.names[dv(t.value).getInt32(0, true)]?.name) : '')
  const int = (t: Tag | undefined, d: number) => (t ? dv(t.value).getInt32(0, true) : d)
  const actorTags = (k: number): Tag[] => {
    const data = pkg.data(k + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, j) => j)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), pkg)
        if (t.some((x: Tag) => x.name === 'Location' || x.name === 'Tag')) return t
      } catch {
        // not here
      }
    }
    return []
  }
  const loc = (t: Tag[]) => {
    const l = t.find((x) => x.name === 'Location')
    return l ? [0, 4, 8].map((o) => Math.round(dv(l.value).getFloat32(o, true))) : undefined
  }
  const structs = (t: Tag | undefined): Tag[][] => {
    if (!t) return []
    const n = dv(t.value).getInt32(0, true)
    const r = new Reader(t.value.subarray(4))
    return Array.from({ length: n }, () => readTags(r, pkg) as Tag[])
  }
  // A brush actor's box: its location plus its brush's bounds (a Model's data starts with them), as ew-map.ts reads them.
  const box = (t: Tag[]) => {
    const l = loc(t)
    const brush = t.find((x) => x.name === 'Brush')
    if (!l || !brush) return undefined
    const d = pkg.data(dv(brush.value).getInt32(0, true))
    const v = dv(d)
    const none = meta.names.indexOf('None')
    let o = 4
    while (v.getInt32(o, true) !== none) o += 24 + v.getInt32(o + 16, true)
    o += 8
    const b = Array.from({ length: 6 }, (_, k) => v.getFloat32(o + 4 * k, true))
    return { center: [0, 1, 2].map((k) => Math.round(l[k]! + b[k]!)), extent: [3, 4, 5].map((k) => Math.round(b[k]!)) }
  }
  const points: Recovery['points'] = []
  let firstCaptured = ''
  const spawnAt = new Map<number, number[]>()
  let waves: Tag[] | undefined
  meta.exports.forEach((e: any, k: number) => {
    if (!/^TheWorld\.PersistentLevel\.[^.]+$/.test(e.fullName)) return
    if (e.type === 'XComCapturePointVolume') {
      const t = actorTags(k)
      const b = box(t)
      if (!b) return
      const seq = int(t.find((x) => x.name === 'm_iCaptureSequenceIndex'), 0)
      points.push({ ...b, turns: int(t.find((x) => x.name === 'm_iTurnsToCapture'), 2), seq })
      // (The first area's capture event starts the second set of waves.)
      if (seq === 0)
        firstCaptured = structs(t.find((x) => x.name === 'm_arrCaptureEvents')).map((c) => ({ name: nameOf(c.find((x) => x.name === 'm_nEventName')), left: int(c.find((x) => x.name === 'm_iTurnsRemaining'), 0) })).find((c) => c.left === 0)?.name ?? ''
    }
    if (e.type === 'XComSpawnPoint_Alien') {
      const p = loc(actorTags(k))
      if (p) spawnAt.set(k, p)
    }
    if (e.type === 'XComWaveSystem') waves = actorTags(k)
  })
  if (points.length === 0) return undefined
  const groups: Recovery['groups'] = []
  structs(waves?.find((x) => x.name === 'm_arrAlienSets')).forEach((set) => {
    const start = nameOf(set.find((x) => x.name === 'EventName'))
    const which = !start || start === 'None' ? 0 : start === firstCaptured ? 1 : -1
    if (which < 0) return
    for (const w of structs(set.find((x) => x.name === 'Waves'))) {
      const turn = int(w.find((x) => x.name === 'TurnAppearance'), 0)
      for (const g of structs(w.find((x) => x.name === 'Groups'))) {
        const sp = g.find((x) => x.name === 'SpawnPoints')
        const n = sp ? dv(sp.value).getInt32(0, true) : 0
        const at = Array.from({ length: n }, (_, i) => spawnAt.get(dv(sp!.value).getInt32(4 + 4 * i, true) - 1)).filter((p): p is number[] => !!p)
        groups.push({ set: which, turn, count: int(g.find((x) => x.name === 'NumAliens'), 1), at })
      }
    }
  })
  const strings = new Map(K.ops.filter((o) => o.type === 'SeqVar_LocalizedString').map((o) => [K.str(o, 'strLookup').split('.').pop() ?? '', K.str(o, 'StrValue')]))
  return {
    map, level, points: points.sort((a, b) => a.seq - b.seq), groups,
    protect: strings.get('m_strCnHObj1') ?? '',
    backup: strings.get('m_strCnHObj2') ?? '',
    kill: strings.get('m_strCnHObj4') ?? '',
    hint: strings.get('m_strCnHHint1') ?? '',
  }
}

export interface HiveSpawn {
  /** Long War's character: 13 a Chryssalid, 14 a zombie. */
  char: number
  at: number[]
  /** 0 at the start; 1 as a soldier enters a volume; 2 on a turn of the hive's (the aliens' turns after the whale is seen);
   *  3 from a ship's exit, the aliens' turn after a soldier enters its volume on the run to the EVAC; 4 as the run starts. */
  when: number
  volume: number
  turn: number
  /** Only at this enemy level (EW's EnemyLevel: 2 with more than 4 roaming aliens, 1 with 4, 0 fewer); -1 at any. */
  level: number
}

export interface Hive {
  map: string
  level: string
  /** XCOM's turns from the transponder's activation to the air strike (AirStrikeRemainingTime). */
  countdown: number
  /** The ship's transponder (the interactive actor the beacon state enables; its InteractRemoteEvent starts the run). */
  transponder: number[]
  /** The EVAC volume (the trigger volume tagged EVAC). */
  evac: { center: number[]; extent: number[] }
  /** Where the squad sees the infestation's source (the ship: find the source) and the whale (the hive: reactivate the
   *  transponder): EW's XComSquadVisiblePoints that raise ShipSpotted and WhaleSpotted. */
  ship: number[][]
  whale: number[][]
  spawns: HiveSpawn[]
  volumes: { center: number[]; extent: number[] }[]
  /** EW's objectives in order (investigate, find the source, the transponder, reach the EVAC) and the count's label. */
  texts: string[]
  strike: string
}

/** The Chryssalid hive's level read (XComSpecialMissionHandler_ChrysHive's states and the level's Kismet): the transponder,
 *  the EVAC volume, the points that move the objectives on, and every scripted spawn of a zombie or a Chryssalid with what
 *  sets it off; undefined when it is not as expected. */
export function readHive(file: string, map: string, level: string): Hive | undefined {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const K = readKismet(bytes)
  const dv = (b: Uint8Array) => new DataView(b.buffer, b.byteOffset, b.byteLength)
  const nameOf = (t: Tag | undefined) => (t ? String(pkg.names[dv(t.value).getInt32(0, true)]?.name) : '')
  const actorTags = (k: number): Tag[] => {
    const data = pkg.data(k + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, j) => j)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), pkg)
        if (t.some((x: Tag) => x.name === 'Location' || x.name === 'Tag')) return t
      } catch {
        // not here
      }
    }
    return []
  }
  const loc = (k: number) => {
    const l = k >= 0 ? actorTags(k).find((x) => x.name === 'Location') : undefined
    return l ? [0, 4, 8].map((o) => Math.round(dv(l.value).getFloat32(o, true))) : undefined
  }
  // A brush actor's box, as readRecovery reads it.
  const box = (k: number) => {
    const t = actorTags(k)
    const l = loc(k)
    const brush = t.find((x) => x.name === 'Brush')
    if (!l || !brush) return undefined
    const v = dv(pkg.data(dv(brush.value).getInt32(0, true)))
    const none = meta.names.indexOf('None')
    let o = 4
    while (v.getInt32(o, true) !== none) o += 24 + v.getInt32(o + 16, true)
    o += 8
    const b = Array.from({ length: 6 }, (_, j) => v.getFloat32(o + 4 * j, true))
    return { center: [0, 1, 2].map((j) => Math.round(l[j]! + b[j]!)), extent: [3, 4, 5].map((j) => Math.round(b[j]!)) }
  }
  const actors = (type: string) => meta.exports.map((e: any, k: number) => ({ e, k })).filter((x: any) => x.e.type === type && /^TheWorld\.PersistentLevel\.[^.]+$/.test(x.e.fullName))
  const evacK = actors('TriggerVolume').find((x: any) => nameOf(actorTags(x.k).find((t) => t.name === 'Tag')) === 'EVAC')?.k ?? -1
  const evac = evacK >= 0 ? box(evacK) : undefined
  const seen = (event: string) => actors('XComSquadVisiblePoint').filter((x: any) => nameOf(actorTags(x.k).find((t) => t.name === 'nmRemoteEventToTrigger')) === event).map((x: any) => loc(x.k)!).filter(Boolean)
  const remote = (name: string) => K.ops.filter((o) => o.type === 'SeqEvent_RemoteEvent' && K.name(o, 'EventName') === name)
  const beacon = remote('ActivateBeacon_Begin').flatMap((o) => K.reach(o, 1)).find((o) => o.type === 'SeqAct_EnableInteractiveActor')
  const held = (k: number | undefined) => (k !== undefined && K.op(k) ? K.obj(K.op(k)!, 'ObjValue') : -1)
  const transponder = beacon ? loc(held(beacon.vars.get('XComInteractiveLevelActor')?.[0])) : undefined
  const ints = (o: KOp | undefined) => {
    const t = o?.props.get('IntValue')
    return t ? dv(t.value).getInt32(0, true) : 0
  }
  const countdown = ints(K.ops.find((o) => o.type === 'SeqVar_Int' && K.name(o, 'VarName') === 'AirStrikeRemainingTime'))
  if (!evac || !transponder || countdown <= 0) return undefined

  // A variable as what it stands for: a named one by the variable of that name; an external one (a subsequence's) by what
  // its sequence links there.
  const byName = (n: string) => K.ops.find((o) => /^SeqVar_/.test(o.type) && o.type !== 'SeqVar_Named' && K.name(o, 'VarName') === n)
  const seqOf = (k: number) => meta.exports.findIndex((e: any) => e.fullName === meta.exports[k].fullName.split('.').slice(0, -1).join('.'))
  const resolve = (k: number, depth = 0): KOp | undefined => {
    const o = K.op(k)
    if (!o || depth > 4) return o
    if (o.type === 'SeqVar_Named') {
      const to = byName(K.name(o, 'FindVarName'))
      return to ? resolve(to.k, depth + 1) : undefined
    }
    if (o.type === 'SeqVar_External') {
      const outer = K.op(seqOf(k))
      const linked = outer?.vars.get(K.str(o, 'VariableLabel'))?.[0]
      return linked !== undefined ? resolve(linked, depth + 1) : undefined
    }
    return o
  }
  const varName = (o: KOp, link: string) => {
    const k = o.vars.get(link)?.[0]
    const v = k !== undefined ? K.op(k) : undefined
    return v?.type === 'SeqVar_Named' ? K.name(v, 'FindVarName') : v ? K.name(v, 'VarName') : ''
  }
  // Who links into an op (with the link's label); a subsequence's start, from what starts the subsequence.
  const into = new Map<number, { desc: string; from: number }[]>()
  for (const o of K.ops) for (const l of o.links) into.set(l.to, [...(into.get(l.to) ?? []), { desc: l.desc, from: o.k }])
  const callers = (k: number) => {
    const o = K.op(k)
    if (o?.type === 'SeqEvent_SequenceActivated') return into.get(seqOf(k)) ?? []
    return into.get(k) ?? []
  }
  type Found = { when: number; volume: number; turn: number; level: number; exitVar: string }
  const volumes: Hive['volumes'] = []
  const volumeIndex = (k: number) => {
    const b = box(k)
    if (!b) return -1
    const i = volumes.findIndex((v) => v.center.join() === b.center.join())
    if (i >= 0) return i
    volumes.push(b)
    return volumes.length - 1
  }
  // The nearest thing upstream that sets a spawn off, with the conditions on the way (a breadth-first walk back).
  const trigger = (start: KOp): Found | undefined => {
    let front = [{ k: start.k, turn: 0, level: -1, exitVar: '' }]
    const done = new Set<number>([start.k])
    for (let depth = 0; depth < 24 && front.length; depth++) {
      const next: typeof front = []
      for (const f of front) {
        for (const c of callers(f.k)) {
          if (done.has(c.from)) continue
          done.add(c.from)
          const o = K.op(c.from)
          if (!o) continue
          let { turn, level, exitVar } = f
          if (o.type === 'SeqCond_CompareInt' && c.desc === 'A == B') {
            const b = resolve(o.vars.get('B')?.[0] ?? -1)
            if (varName(o, 'A') === 'TurnCounter' && !turn) turn = ints(b)
            if (varName(o, 'A') === 'EnemyLevel' && level < 0) level = ints(b)
          }
          if (o.type === 'SeqCond_CompareBool' && /^Exit\w*Active$/.test(varName(o, 'Bool')) && c.desc === 'True') exitVar = varName(o, 'Bool')
          if (turn) return { when: 2, volume: -1, turn, level, exitVar }
          if (exitVar && o.type === 'SeqEvent_OnAlienEndingTurn') return { when: 3, volume: -1, turn: 0, level, exitVar }
          if (o.type === 'SeqEvent_Touch') return { when: 1, volume: volumeIndex(K.obj(o, 'Originator')), turn: 0, level, exitVar: '' }
          if (o.type === 'SeqEvent_RemoteEvent' && K.name(o, 'EventName') === 'EngineActivated') return { when: 4, volume: -1, turn: 0, level, exitVar: '' }
          if (o.type === 'SeqEvent_RemoteEvent' && K.name(o, 'EventName') === 'XGBattle_Running_BeginBlockFinished') return { when: 0, volume: -1, turn: 0, level, exitVar: '' }
          next.push({ k: c.from, turn, level, exitVar })
        }
      }
      front = next
    }
    return undefined
  }
  // A ship's exit: the volume whose touch arms it (the SetBool of its Active variable, after a touch).
  const exitVolume = (exitVar: string) => {
    const set = K.ops.find((o) => o.type === 'SeqAct_SetBool' && (o.vars.get('Target') ?? []).some((k) => {
      const v = K.op(k)
      return v && (K.name(v, 'FindVarName') === exitVar || K.name(v, 'VarName') === exitVar)
    }))
    const t = set ? trigger(set) : undefined
    return t?.when === 1 ? t.volume : -1
  }
  const spawns: HiveSpawn[] = []
  for (const o of K.ops.filter((x) => x.type === 'SeqAct_SpawnAlien')) {
    const type = K.name(o, 'ForceAlienType')
    const char = type === 'ePawnType_Zombie' ? 14 : type === 'ePawnType_Chryssalid' ? 13 : 0
    const point = resolve(o.vars.get('SpawnPoints')?.[0] ?? -1)
    const at = point ? loc(K.obj(point, 'ObjValue')) : undefined
    const t = trigger(o)
    if (!char || !at || !t) continue
    const volume = t.when === 3 ? exitVolume(t.exitVar) : t.volume
    if ((t.when === 1 || t.when === 3) && volume < 0) continue
    spawns.push({ char, at, when: t.when, volume, turn: t.turn, level: t.level })
  }
  const strings = new Map(K.ops.filter((o) => o.type === 'SeqVar_LocalizedString').map((o) => [K.str(o, 'strLookup').split('.').pop() ?? '', K.str(o, 'StrValue')]))
  return {
    map, level, countdown, transponder, evac,
    ship: seen('ShipSpotted'), whale: seen('WhaleSpotted'), spawns, volumes,
    texts: [1, 2, 3, 4].map((i) => strings.get(`m_strChrysObj${i}`) ?? ''),
    strike: (strings.get('m_strAirStrikeCount') ?? '').trim(),
  }
}

/** The Temple Ship (EW's XComSpecialMissionHandler_Templeship with its level's Kismet): the two arenas' pods, each of a forced
 *  alien type (their Kismet variables FirstArenaPod0-6, SecondArenaPod0-6; a pod whose type is none spawns nothing, as
 *  XComAlienPodManager.GetAlienPawnType has it), and the Kismet's scripted spawns, each with the stage that brings it. */
export interface Temple {
  map: string
  /** Arena 1 or 2; Long War's character; EW's NumAliens_Min and _Max; where the pod stands. */
  pods: { arena: number; char: number; min: number; max: number; at: number[] }[]
  /** The stage: 1 the first swarm (FirstSwarmTriggered, at an aliens' turn end), 2 the second (SecondSwarmTriggered), 3 the
   *  boss gate opened (BossGateOpen), 4 the boss arena begun (BossArena_Begin: the Uber Ethereal), 5 the Uber Ethereal seen
   *  (UberVisibleComplete); the alien; its point. */
  spawns: { stage: number; char: number; at: number[] }[]
}

/** Long War's character for an EW pawn type name, whatever its spelling (ePawnType_Sectoid_Commander, …_CyberDisc). */
export function charOfPawn(type: string): number {
  const key = type.replace(/^ePawnType_/, '').replace(/_/g, '').toLowerCase()
  const more: Record<string, number> = { elder: 12, etherealuber: 19, sectopoddrone: 17, mutonberserker: 15 }
  if (more[key]) return more[key]!
  for (const [k, v] of Object.entries(CHAR_OF)) if (k.replace(/_/g, '').toLowerCase() === key) return v
  return 0
}

/** The Temple Ship's level read; undefined when it is not as expected. */
export function readTemple(file: string, map: string): Temple | undefined {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const K = readKismet(bytes)
  const dv = (b: Uint8Array) => new DataView(b.buffer, b.byteOffset, b.byteLength)
  const actorTags = (k: number): Tag[] => {
    const data = pkg.data(k + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, j) => j)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), pkg)
        if (t.some((x: Tag) => x.name === 'Location')) return t
      } catch {
        // not here
      }
    }
    return []
  }
  const loc = (t: Tag[]) => {
    const l = t.find((x) => x.name === 'Location')
    return l ? [0, 4, 8].map((o) => Math.round(dv(l.value).getFloat32(o, true))) : undefined
  }
  const int = (t: Tag[], n: string) => {
    const x = t.find((y) => y.name === n)
    return x ? dv(x.value).getInt32(0, true) : 0
  }
  const nameIn = (t: Tag[], n: string) => {
    const x = t.find((y) => y.name === n)
    return x && x.value.byteLength >= 8 ? String(pkg.names[dv(x.value).getInt32(0, true)]?.name) : ''
  }
  const pods: Temple['pods'] = []
  for (const o of K.ops.filter((x) => x.type === 'SeqVar_Object')) {
    const m = /^(First|Second)ArenaPod\d$/.exec(K.name(o, 'VarName'))
    const k = K.obj(o, 'ObjValue')
    if (!m || k < 0 || !/^XComAlienPod/.test(meta.exports[k]?.type ?? '')) continue
    const t = actorTags(k)
    const at = loc(t)
    const char = t.some((x) => x.name === 'ForceAlienType') ? charOfPawn(nameIn(t, 'AlienType')) : 0
    if (!at || !char) continue
    pods.push({ arena: m[1] === 'First' ? 1 : 2, char, min: int(t, 'NumAliens_Min'), max: int(t, 'NumAliens_Max'), at })
  }
  // Who links into an op; the stage of a spawn: the nearest marker upstream (a gate on a swarm's variable, a remote event).
  const into = new Map<number, number[]>()
  for (const o of K.ops) for (const t of o.out) into.set(t, [...(into.get(t) ?? []), o.k])
  const boolVar = (o: KOp) => {
    const v = K.op(o.vars.get('Bool')?.[0] ?? -1)
    return v ? K.name(v, 'FindVarName') || K.name(v, 'VarName') : ''
  }
  const MARK: Record<string, number> = { FirstSwarmTriggered: 1, SecondSwarmTriggered: 2, BossGateOpen: 3, BossArena_Begin: 4, UberVisibleComplete: 5 }
  const stageOf = (start: KOp) => {
    let front = [start.k]
    const done = new Set(front)
    for (let d = 0; d < 32 && front.length; d++) {
      const next: number[] = []
      for (const k of front)
        for (const c of into.get(k) ?? []) {
          if (done.has(c)) continue
          done.add(c)
          const o = K.op(c)
          if (!o) continue
          const mark = o.type === 'SeqCond_CompareBool' ? MARK[boolVar(o)] : o.type === 'SeqEvent_RemoteEvent' ? MARK[K.name(o, 'EventName')] : undefined
          if (mark) return mark
          next.push(c)
        }
      front = next
    }
    return 0
  }
  const spawns: Temple['spawns'] = []
  for (const o of K.ops.filter((x) => x.type === 'SeqAct_SpawnAlien')) {
    const char = charOfPawn(K.name(o, 'ForceAlienType'))
    const v = K.op(o.vars.get('SpawnPoints')?.[0] ?? -1)
    const at = v ? loc(actorTags(K.obj(v, 'ObjValue'))) : undefined
    const stage = stageOf(o)
    if (char && at && stage) spawns.push({ stage, char, at })
  }
  if (!pods.some((p) => p.arena === 1) || !spawns.some((s) => s.char === 19)) return undefined
  return { map, pods, spawns }
}

export interface CustomSoldier {
  mission: number
  first: string
  last: string
  nick: string
  /** EW's ECountry name without its prefix (USA, France, Egypt …), as the mod's countries are named. */
  country: string
  female: boolean
  /** EW's base class (1 sniper, 2 heavy weapons, 3 support, 4 assault) and rank (1 squaddie … 7 colonel). */
  baseClass: number
  rank: number
  hp: number
  aim: number
  will: number
  /** What GiveCustomSoldier adds for this soldier (by its head or nickname): a mobility, psi powers (each with an
   *  alternative it is given instead half the time; 0 none), the psi rank. */
  mobility: number
  perks: number[]
  alt: number[]
  psiRank: number
}

/** Long War's character (ECharacter) for EW's pawn type a Kismet spawns (SeqAct_SpawnAlien.ForceAlienType); 0 unknown. */
const CHAR_OF: Record<string, number> = {
  Sectoid: 4, Floater: 5, ThinMan: 6, Muton: 7, Cyberdisc: 8, SectoidCommander: 9, FloaterHeavy: 10, MutonElite: 11, Ethereal: 12,
  Chryssalid: 13, Zombie: 14, Muton_Berserker: 15, Sectopod: 16, Drone: 17, Outsider: 18, Mechtoid: 21, Seeker: 23,
}

export interface Deluge {
  map: string
  level: string
  /** The bypass valves (the interactive actors raising TransponderActivated), by their number in the Kismet (TransponderN). */
  valves: number[][]
  /** Where the transport vehicle is spotted (the volume whose touch moves the objective to securing it), and where it is
   *  secured (the volume whose touch presses its control button). */
  spotted: { center: number[]; extent: number[] }
  secure: { center: number[]; extent: number[] }
  /** XCOM's turns until the dam collapses, at the start and again for the run to the EVAC (Turn Max); the turns a valve
   *  adds (the AddInt on Turns Left). */
  turns: number
  valveTurns: number
  /** The aliens each valve's opening brings, as the aliens' turn ends: the valve's number, the alien, its point. */
  drops: { valve: number; char: number; at: number[] }[]
  /** EW's texts: locate the transport, open the valves, secure it, report to the EVAC; the two counts' labels. */
  locate: string
  valvesText: string
  secureText: string
  report: string
  collapse: string
  remaining: string
}

/** Progeny's Deluge (its level's Kismet, with EW's bomb handler for its objectives); undefined when it is not as expected. */
export function readDeluge(file: string, map: string, level: string): Deluge | undefined {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const K = readKismet(bytes)
  const dv = (b: Uint8Array) => new DataView(b.buffer, b.byteOffset, b.byteLength)
  const actorTags = (k: number): Tag[] => {
    const data = pkg.data(k + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, j) => j)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), pkg)
        if (t.some((x: Tag) => x.name === 'Location' || x.name === 'Tag')) return t
      } catch {
        // not here
      }
    }
    return []
  }
  const loc = (k: number) => {
    const l = k >= 0 ? actorTags(k).find((x) => x.name === 'Location') : undefined
    return l ? [0, 4, 8].map((o) => Math.round(dv(l.value).getFloat32(o, true))) : undefined
  }
  const box = (k: number) => {
    const t = actorTags(k)
    const l = loc(k)
    const brush = t.find((x) => x.name === 'Brush')
    if (!l || !brush) return undefined
    const v = dv(pkg.data(dv(brush.value).getInt32(0, true)))
    const none = meta.names.indexOf('None')
    let o = 4
    while (v.getInt32(o, true) !== none) o += 24 + v.getInt32(o + 16, true)
    o += 8
    const b = Array.from({ length: 6 }, (_, j) => v.getFloat32(o + 4 * j, true))
    return { center: [0, 1, 2].map((j) => Math.round(l[j]! + b[j]!)), extent: [3, 4, 5].map((j) => Math.round(b[j]!)) }
  }
  const ints = (o: KOp | undefined) => {
    const t = o?.props.get('IntValue')
    return t ? dv(t.value).getInt32(0, true) : 0
  }
  const varName = (k: number | undefined) => {
    const v = k !== undefined ? K.op(k) : undefined
    return v?.type === 'SeqVar_Named' ? K.name(v, 'FindVarName') : v ? K.name(v, 'VarName') : ''
  }
  const held = (k: number | undefined) => (k !== undefined && K.op(k) ? K.obj(K.op(k)!, 'ObjValue') : -1)
  const into = new Map<number, { desc: string; from: number }[]>()
  for (const o of K.ops) for (const l of o.links) into.set(l.to, [...(into.get(l.to) ?? []), { desc: l.desc, from: o.k }])
  // The ops upstream of one (breadth first, to a depth), with the labels they were left by.
  const upstream = (k: number, depth: number) => {
    const out: { op: KOp; desc: string }[] = []
    const seen = new Set<number>([k])
    let front = [k]
    for (let d = 0; d < depth; d++) {
      const next: number[] = []
      for (const f of front) for (const c of into.get(f) ?? []) {
        if (seen.has(c.from) || !K.op(c.from)) continue
        seen.add(c.from)
        out.push({ op: K.op(c.from)!, desc: c.desc })
        next.push(c.from)
      }
      front = next
    }
    return out
  }
  // The valves: each 'TransponderActivated' listener disables its valve and marks TransponderN_Activated.
  const valves: number[][] = []
  for (const ev of K.ops.filter((o) => o.type === 'SeqEvent_RemoteEvent' && K.name(o, 'EventName') === 'TransponderActivated')) {
    const near = K.reach(ev, 6)
    const off = near.find((o) => o.type === 'SeqAct_DisableInteractiveActor')
    const mark = near.map((o) => (o.type === 'SeqAct_SetBool' ? /^Transponder(\d+)_Activated$/.exec(varName(o.vars.get('Target')?.[0])) : null)).find(Boolean)
    const at = off ? loc(held(off.vars.get('XComInteractiveLevelActor')?.[0])) : undefined
    if (mark && at) valves[Number(mark[1])] = at
  }
  // The volumes: the one whose touch leads to ApproachDefuseBomb, and the one whose touch raises ControlButtonActivated.
  const touchTo = (pred: (o: KOp) => boolean) => {
    const target = K.ops.find(pred)
    const touch = target ? upstream(target.k, 8).find((u) => u.op.type === 'SeqEvent_Touch' && K.obj(u.op, 'Originator') >= 0) : undefined
    return touch ? box(K.obj(touch.op, 'Originator')) : undefined
  }
  const spotted = touchTo((o) => o.type === 'SeqAct_SpecialMissionHandler_GotoState' && K.name(o, 'StateName') === 'ApproachDefuseBomb')
  const secure = touchTo((o) => o.type === 'SeqAct_ActivateRemoteEvent' && K.name(o, 'EventName') === 'ControlButtonActivated')
  const turns = ints(K.ops.find((o) => o.type === 'SeqVar_Int' && K.name(o, 'VarName') === 'Turn Max'))
  const adds = K.ops.find((o) => o.type === 'SeqAct_AddInt' && [...o.vars.values()].flat().some((k) => varName(k) === 'Turns Left') && K.op(o.vars.get('A')?.[0] ?? -1)?.type === 'SeqVar_Int')
  const valveTurns = adds ? ints(K.op(adds.vars.get('A')![0]!)) : 0
  const drops: Deluge['drops'] = []
  for (const o of K.ops.filter((x) => x.type === 'SeqAct_SpawnAlien')) {
    const char = CHAR_OF[K.name(o, 'ForceAlienType').replace(/^ePawnType_/, '')] ?? 0
    const at = loc(held(o.vars.get('SpawnPoints')?.[0]))
    const gate = upstream(o.k, 10).map((u) => (u.op.type === 'SeqCond_CompareBool' && u.desc === 'True' ? /^Transponder(\d+)_Activated$/.exec(varName(u.op.vars.get('Bool')?.[0])) : null)).find(Boolean)
    if (char && at && gate) drops.push({ valve: Number(gate[1]), char, at })
  }
  if (valves.filter(Boolean).length === 0 || !spotted || !secure || turns <= 0) return undefined
  const strings = new Map(K.ops.filter((o) => o.type === 'SeqVar_LocalizedString').map((o) => [K.str(o, 'strLookup').split('.').pop() ?? '', K.str(o, 'StrValue')]))
  return {
    map, level, valves: valves.map((v) => v ?? [0, 0, 0]), spotted, secure, turns, valveTurns, drops,
    locate: strings.get('m_strDLC2_2Obj1') ?? '',
    valvesText: strings.get('m_strDLC2_2Obj2') ?? '',
    secureText: strings.get('m_strDLC2_2Obj3') ?? '',
    report: strings.get('m_strDLC2_3Obj4') ?? '',
    collapse: (strings.get('m_strDLC2_2TurnsToCollapse') ?? '').trim(),
    remaining: (strings.get('m_strDLC2_2TurnsRem') ?? '').trim(),
  }
}

export interface LevelDrops {
  level: string
  volumes: { center: number[]; extent: number[] }[]
  /** An alien the level drops once a soldier has entered the volume, as the aliens' turn ends (the Kismet's gates: a bool
   *  set as the volume is touched, checked on SeqEvent_OnAlienEndingTurn, a "…Once" bool so it drops but once). */
  drops: { volume: number; char: number; at: number[] }[]
}

/** A variant level's gated alien drops (Portent's Thin Men, Furies', the council's variants'); undefined when it has none. */
export function readDrops(file: string, level: string): LevelDrops | undefined {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const K = readKismet(bytes)
  const dv = (b: Uint8Array) => new DataView(b.buffer, b.byteOffset, b.byteLength)
  const actorTags = (k: number): Tag[] => {
    const data = pkg.data(k + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, j) => j)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), pkg)
        if (t.some((x: Tag) => x.name === 'Location' || x.name === 'Tag')) return t
      } catch {
        // not here
      }
    }
    return []
  }
  const loc = (k: number) => {
    const l = k >= 0 ? actorTags(k).find((x) => x.name === 'Location') : undefined
    return l ? [0, 4, 8].map((o) => Math.round(dv(l.value).getFloat32(o, true))) : undefined
  }
  const box = (k: number) => {
    const t = actorTags(k)
    const l = loc(k)
    const brush = t.find((x) => x.name === 'Brush')
    if (!l || !brush) return undefined
    const v = dv(pkg.data(dv(brush.value).getInt32(0, true)))
    const none = meta.names.indexOf('None')
    let o = 4
    while (v.getInt32(o, true) !== none) o += 24 + v.getInt32(o + 16, true)
    o += 8
    const b = Array.from({ length: 6 }, (_, j) => v.getFloat32(o + 4 * j, true))
    return { center: [0, 1, 2].map((j) => Math.round(l[j]! + b[j]!)), extent: [3, 4, 5].map((j) => Math.round(b[j]!)) }
  }
  const varName = (k: number | undefined) => {
    const v = k !== undefined ? K.op(k) : undefined
    return v?.type === 'SeqVar_Named' ? K.name(v, 'FindVarName') : v ? K.name(v, 'VarName') : ''
  }
  const held = (k: number | undefined) => {
    const v = k !== undefined ? K.op(k) : undefined
    if (v?.type === 'SeqVar_Named') {
      const to = K.ops.find((o) => o.type === 'SeqVar_Object' && K.name(o, 'VarName') === K.name(v, 'FindVarName'))
      return to ? K.obj(to, 'ObjValue') : -1
    }
    return v ? K.obj(v, 'ObjValue') : -1
  }
  const into = new Map<number, { desc: string; from: number }[]>()
  for (const o of K.ops) for (const l of o.links) into.set(l.to, [...(into.get(l.to) ?? []), { desc: l.desc, from: o.k }])
  // Walking back from an op: the first event reached, and the bools tested True on the way.
  const back = (k: number) => {
    const gates: string[] = []
    const seen = new Set<number>([k])
    let front = [k]
    for (let d = 0; d < 16 && front.length; d++) {
      const next: number[] = []
      for (const f of front) for (const c of into.get(f) ?? []) {
        if (seen.has(c.from)) continue
        seen.add(c.from)
        const o = K.op(c.from)
        if (!o) continue
        if (o.type === 'SeqCond_CompareBool' && c.desc === 'True') gates.push(varName(o.vars.get('Bool')?.[0]))
        if (/^SeqEvent_/.test(o.type)) return { event: o, gates }
        next.push(c.from)
      }
      front = next
    }
    return { event: undefined as KOp | undefined, gates }
  }
  const volumes: LevelDrops['volumes'] = []
  const volumeIndex = (k: number) => {
    const b = box(k)
    if (!b) return -1
    const i = volumes.findIndex((v) => v.center.join() === b.center.join())
    if (i >= 0) return i
    volumes.push(b)
    return volumes.length - 1
  }
  // A gate's volume: the touch upstream of a SetBool that sets it.
  const gateVolume = (gate: string) => {
    for (const set of K.ops.filter((o) => o.type === 'SeqAct_SetBool' && (o.vars.get('Target') ?? []).some((t) => varName(t) === gate))) {
      const b = back(set.k)
      if (b.event?.type === 'SeqEvent_Touch' && K.obj(b.event, 'Originator') >= 0) return volumeIndex(K.obj(b.event, 'Originator'))
    }
    return -1
  }
  const drops: LevelDrops['drops'] = []
  for (const o of K.ops.filter((x) => x.type === 'SeqAct_SpawnAlien')) {
    const char = CHAR_OF[K.name(o, 'ForceAlienType').replace(/^ePawnType_/, '')] ?? 0
    const at = loc(held(o.vars.get('SpawnPoints')?.[0]))
    const b = back(o.k)
    if (!char || !at || b.event?.type !== 'SeqEvent_OnAlienEndingTurn') continue
    const volume = b.gates.map(gateVolume).find((v) => v >= 0) ?? -1
    if (volume >= 0) drops.push({ volume, char, at })
  }
  return drops.length ? { level, volumes, drops } : undefined
}

export interface Furies {
  map: string
  level: string
  /** The command console (the interactive actor raising ConsoleActivated). */
  console: number[]
  /** The volume whose touch sounds the alarm (sets AlarmAudioActive): the execution's countdown starts. */
  alarm: { center: number[]; extent: number[] }
  /** XCOM's turns from the alarm to the execution (the Kismet's Timer). */
  timer: number
  /** EW's texts: rescue the abductees, destroy or disarm the console, kill the rest; the count's label. */
  rescue: string
  consoleText: string
  kill: string
  execution: string
}

/** Progeny's Furies (its level's Kismet, with EW's rescue handler for its objectives); undefined when it is not as expected. */
export function readFuries(file: string, map: string, level: string): Furies | undefined {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const K = readKismet(bytes)
  const dv = (b: Uint8Array) => new DataView(b.buffer, b.byteOffset, b.byteLength)
  const nameOf = (t: Tag | undefined) => (t ? String(pkg.names[dv(t.value).getInt32(0, true)]?.name) : '')
  const actorTags = (k: number): Tag[] => {
    const data = pkg.data(k + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, j) => j)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), pkg)
        if (t.some((x: Tag) => x.name === 'Location' || x.name === 'Tag')) return t
      } catch {
        // not here
      }
    }
    return []
  }
  const loc = (k: number) => {
    const l = k >= 0 ? actorTags(k).find((x) => x.name === 'Location') : undefined
    return l ? [0, 4, 8].map((o) => Math.round(dv(l.value).getFloat32(o, true))) : undefined
  }
  const box = (k: number) => {
    const t = actorTags(k)
    const l = loc(k)
    const brush = t.find((x) => x.name === 'Brush')
    if (!l || !brush) return undefined
    const v = dv(pkg.data(dv(brush.value).getInt32(0, true)))
    const none = meta.names.indexOf('None')
    let o = 4
    while (v.getInt32(o, true) !== none) o += 24 + v.getInt32(o + 16, true)
    o += 8
    const b = Array.from({ length: 6 }, (_, j) => v.getFloat32(o + 4 * j, true))
    return { center: [0, 1, 2].map((j) => Math.round(l[j]! + b[j]!)), extent: [3, 4, 5].map((j) => Math.round(b[j]!)) }
  }
  const varName = (k: number | undefined) => {
    const v = k !== undefined ? K.op(k) : undefined
    return v?.type === 'SeqVar_Named' ? K.name(v, 'FindVarName') : v ? K.name(v, 'VarName') : ''
  }
  const consoleK = meta.exports.findIndex((e: any) => e.type === 'XComInteractiveLevelActor' && /^TheWorld\.PersistentLevel\.[^.]+$/.test(e.fullName)
    && nameOf(actorTags(meta.exports.indexOf(e)).find((t) => t.name === 'InteractRemoteEvent')) === 'ConsoleActivated')
  const console = loc(consoleK)
  // The alarm: the touch that sets AlarmAudioActive.
  const into = new Map<number, number[]>()
  for (const o of K.ops) for (const l of o.links) into.set(l.to, [...(into.get(l.to) ?? []), o.k])
  const set = K.ops.find((o) => o.type === 'SeqAct_SetBool' && (o.vars.get('Target') ?? []).some((t) => varName(t) === 'AlarmAudioActive'))
  const touch = set ? (into.get(set.k) ?? []).map((k) => K.op(k)!).find((o) => o?.type === 'SeqEvent_Touch') : undefined
  const alarm = touch ? box(K.obj(touch, 'Originator')) : undefined
  const timerVar = K.ops.find((o) => o.type === 'SeqVar_Int' && K.name(o, 'VarName') === 'Timer')
  const timer = timerVar?.props.get('IntValue') ? dv(timerVar.props.get('IntValue')!.value).getInt32(0, true) : 0
  if (!console || !alarm || timer <= 0) return undefined
  const strings = new Map(K.ops.filter((o) => o.type === 'SeqVar_LocalizedString').map((o) => [K.str(o, 'strLookup').split('.').pop() ?? '', K.str(o, 'StrValue')]))
  return {
    map, level, console, alarm, timer,
    rescue: strings.get('m_strDLC2_3Obj1') ?? '',
    consoleText: strings.get('m_strDLC2_3Obj2') ?? '',
    kill: strings.get('m_strDLC2_3Obj3') ?? '',
    execution: (strings.get('m_strDLC2_3UntilExecution') ?? '').trim(),
  }
}

/** Long War's named soldiers that its council missions reward (XGFundingCouncil.BuildMission's arrRewardSoldiers, and
 *  GiveCustomSoldier's additions), read from the player's own XComStrategyGame.upk with upkit's decompiler: Progeny's
 *  (eFCM_Progeny_*). Their names are Long War's, so they are only ever written on the player's machine. */
export function readCustomSoldiers(cooked: string): CustomSoldier[] {
  if (!levelFile(cooked, 'XComStrategyGame')) return []
  const linker = new Linker([cooked])
  const pkg = linker.package('XComStrategyGame')
  if (!pkg) return []
  let build = ''
  let give = ''
  try {
    build = decompileFunction(linker, pkg, 'XGFundingCouncil.BuildMission')
    give = decompileFunction(linker, pkg, 'XGFundingCouncil.GiveCustomSoldier')
  } catch {
    return []
  }
  const MISSION: Record<string, number> = { Portent: 25, Deluge: 26, Furies: 27 }
  const CLASS: Record<string, number> = { Sniper: 1, HeavyWeapons: 2, Support: 3, Assault: 4 }
  const RANK: Record<string, number> = { Rookie: 0, Squaddie: 1, Corporal: 2, Sergeant: 3, Lieutenant: 4, Captain: 5, Major: 6, Colonel: 7 }
  // GiveCustomSoldier's additions, by the head or the nickname they key on (the innermost condition holds them).
  type Extra = { mobility: number; perks: number[]; alt: number[]; psiRank: number }
  const byHead = new Map<number, Extra>()
  const byNick = new Map<string, Extra>()
  const stack: { depth: number; extra: Extra }[] = []
  let depth = 0
  let pending: Extra | undefined
  for (const line of give.split('\n')) {
    // (As the decompiler writes the comparisons: a native's call, or the operator when it knows it.)
    const head = /Appearance\.iHead(?:, | == )(\d+)\)\)?\s*$/.exec(line)
    const nick = /^\s*if \((?:__native\d+\()?Soldier\.m_kSoldier\.strNickName(?:, | == )"([^"]+)"\)\)?\s*$/.exec(line)
    if (head || nick) {
      pending = { mobility: 0, perks: [], alt: [], psiRank: 0 }
      if (head) byHead.set(Number(head[1]), pending)
      if (nick) byNick.set(nick[1]!, pending)
    }
    if (/^\s*\{\s*$/.test(line)) {
      depth++
      if (pending) stack.push({ depth, extra: pending })
      pending = undefined
      continue
    }
    if (/^\s*\}\s*$/.test(line)) {
      if (stack.length && stack[stack.length - 1]!.depth === depth) stack.pop()
      depth--
      continue
    }
    const extra = stack[stack.length - 1]?.extra
    if (!extra) continue
    const mob = /aStats\[3\] = (\d+);/.exec(line)
    if (mob) extra.mobility = Number(mob[1])
    const rank = /iPsiRank = (0x[0-9a-f]+|\d+);/i.exec(line)
    if (rank) extra.psiRank = Number(rank[1])
    const either = /GivePerk\(.*\? (\d+) : (\d+)\);/.exec(line)
    const one = /GivePerk\((\d+)\);/.exec(line)
    if (either) {
      extra.perks.push(Number(either[1]))
      extra.alt.push(Number(either[2]))
    } else if (one) {
      extra.perks.push(Number(one[1]))
      extra.alt.push(0)
    }
  }
  const out: CustomSoldier[] = []
  for (const [name, mission] of Object.entries(MISSION)) {
    const at = build.indexOf(`case eFCM_Progeny_${name}:`)
    if (at < 0) continue
    const end = build.slice(at + 1).search(/\n\s*(case |default:)/)
    const block = build.slice(at, end < 0 ? undefined : at + 1 + end)
    const cur: Record<string, string> = {}
    for (const line of block.split('\n')) {
      const set = /CustomSoldier\.(?:Appearance\.)?(\w+) = (.+);/.exec(line)
      if (set) cur[set[1]!] = set[2]!.trim()
      if (!/arrRewardSoldiers\.AddItem\(CustomSoldier\)/.test(line)) continue
      const str = (k: string) => (cur[k] ?? '').replace(/^"|"$/g, '')
      const int = (k: string) => Number(cur[k] ?? 0)
      const extra = byNick.get(str('NickName')) ?? byHead.get(int('iHead')) ?? { mobility: 0, perks: [], alt: [], psiRank: 0 }
      out.push({
        mission,
        first: str('firstName'),
        last: str('lastName'),
        nick: str('NickName'),
        country: (cur.Country ?? '').replace(/^eCountry_/, ''),
        female: int('iGender') === 2,
        baseClass: CLASS[(cur.soldierClass ?? '').replace(/^eSC_/, '')] ?? 0,
        rank: RANK[(cur.SoldierRank ?? '').replace(/^eRank_/, '')] ?? 0,
        hp: int('HP'),
        aim: int('Aim'),
        will: int('Will'),
        ...extra,
      })
    }
  }
  return out
}

/** Every bomb disposal, VIP mission, covert extraction, data recovery and the hive this install has, written into the mod's
 *  config; returns how many. */
export function writeObjectives(cooked: string, mod: string): number {
  const vec = (p: number[]) => `(X=${p[0]}, Y=${p[1]}, Z=${p[2]})`
  const lines = [
    "; Enemy Within's council missions' objectives, read from this machine's EW by tools/convert/ew-objectives.ts.",
    '[LongWarX2.LWX2CouncilBomb]',
  ]
  let n = 0
  const missions = councilMissions(mod)
  for (const m of missions.filter((x) => x.kind === 2)) {
    const file = levelFile(cooked, m.level)
    if (!file) continue
    const b = readBomb(file, m.map, m.level)
    if (!b) continue
    lines.push(`+Bombs=(Map="${b.map}", Level="${b.level}", Timer=${b.timer}, Nodes=${b.nodes}, Bomb=${vec(b.bomb)}, NodeAt=(${b.nodeAt.map(vec).join(', ')}))`)
    n++
  }
  // The VIP missions (LWX2CouncilVIP): EW's own words in them, as this install has them.
  const q = (t: string) => `"${t.replace(/"/g, "'")}"`
  lines.push('', '[LongWarX2.LWX2CouncilVIP]')
  for (const m of missions.filter((x) => x.kind === 3 || x.kind === 4 || x.id === 25)) {
    const file = levelFile(cooked, m.level)
    if (!file) continue
    const p = readVIP(file, m.map, m.level)
    if (!p) continue
    lines.push(`+VIPs=(Map="${p.map}", Level="${p.level}", At=${vec(p.at)}, First=${q(p.first)}, Last=${q(p.last)}, ${p.approach ? `bApproach=true, Approach=${vec(p.approach)}, ` : ''}Extract=${vec(p.extract)}, ` +
      `Texts=(${p.texts.map(q).join(', ')}), KillRest=${q(p.killRest)}, Report=${q(p.report)})`)
    n++
  }
  // EXALT's covert extractions (LWX2CovertExtraction).
  lines.push('', '[LongWarX2.LWX2CovertExtraction]')
  for (const m of covertMaps(mod).filter((x) => x.kind === 'CovertExtraction')) {
    const file = levelFile(cooked, m.level)
    if (!file) continue
    const c = readCovert(file, m.map, m.level)
    if (!c) continue
    lines.push(`+Extractions=(Map="${c.map}", Level="${c.level}", Relays=(${c.relays.map(vec).join(', ')}), ${c.operative ? `bOperativeSpawn=true, OperativeAt=${vec(c.operative)}, ` : ''}` +
      `Hack=${q(c.hack)}, Left=${q(c.left)}, Escort=${q(c.escort)}, Cleanup=${q(c.cleanup)}, Retreat=${q(c.retreat)})`)
    n++
  }
  // EXALT's data recoveries (LWX2DataRecovery): the areas and the waves, an entry each, by level.
  lines.push('', '[LongWarX2.LWX2DataRecovery]')
  for (const m of covertMaps(mod).filter((x) => x.kind === 'DataRecovery')) {
    const file = levelFile(cooked, m.level)
    if (!file) continue
    const r = readRecovery(file, m.map, m.level)
    if (!r) continue
    lines.push(`+Recoveries=(Map="${r.map}", Level="${r.level}", Protect=${q(r.protect)}, Backup=${q(r.backup)}, Kill=${q(r.kill)}, Hint=${q(r.hint)})`)
    for (const p of r.points) lines.push(`+Points=(Level="${r.level}", Center=${vec(p.center)}, Extent=${vec(p.extent)}, Turns=${p.turns}, Seq=${p.seq})`)
    for (const g of r.groups) lines.push(`+Groups=(Level="${r.level}", Set=${g.set}, Turn=${g.turn}, Count=${g.count}, At=(${g.at.map(vec).join(', ')}))`)
    n++
  }
  // The Chryssalid hive (LWX2ChryssalidHive): its points, its volumes and its scripted spawns, by level.
  lines.push('', '[LongWarX2.LWX2ChryssalidHive]', 'ReachTiles=1.5', 'SightShare=0.75')
  for (const m of missions.filter((x) => x.id === 29)) {
    const file = levelFile(cooked, m.level)
    if (!file) continue
    const h = readHive(file, m.map, m.level)
    if (!h) continue
    const vecs = (ps: number[][]) => `(${ps.map(vec).join(', ')})`
    lines.push(`+Hives=(Map="${h.map}", Level="${h.level}", Countdown=${h.countdown}, Transponder=${vec(h.transponder)}, EvacCenter=${vec(h.evac.center)}, EvacExtent=${vec(h.evac.extent)}, ` +
      `Ship=${vecs(h.ship)}, Whale=${vecs(h.whale)}, Texts=(${h.texts.map(q).join(', ')}), Strike=${q(h.strike)})`)
    for (const v of h.volumes) lines.push(`+Volumes=(Level="${h.level}", Center=${vec(v.center)}, Extent=${vec(v.extent)})`)
    for (const s of h.spawns) lines.push(`+Spawns=(Level="${h.level}", Char=${s.char}, At=${vec(s.at)}, When=${s.when}, Volume=${s.volume}, Turn=${s.turn}, EnemyLevel=${s.level})`)
    n++
  }
  // Progeny's Deluge (LWX2Deluge): its valves, its volumes, its countdown and its drops.
  lines.push('', '[LongWarX2.LWX2Deluge]', 'ReachTiles=1.5')
  for (const m of missions.filter((x) => x.id === 26)) {
    const file = levelFile(cooked, m.level)
    if (!file) continue
    const d = readDeluge(file, m.map, m.level)
    if (!d) continue
    lines.push(`+Deluges=(Map="${d.map}", Level="${d.level}", Valves=(${d.valves.map(vec).join(', ')}), SpottedCenter=${vec(d.spotted.center)}, SpottedExtent=${vec(d.spotted.extent)}, ` +
      `SecureCenter=${vec(d.secure.center)}, SecureExtent=${vec(d.secure.extent)}, Turns=${d.turns}, ValveTurns=${d.valveTurns}, Locate=${q(d.locate)}, ValvesText=${q(d.valvesText)}, ` +
      `SecureText=${q(d.secureText)}, Report=${q(d.report)}, Collapse=${q(d.collapse)}, Remaining=${q(d.remaining)})`)
    for (const x of d.drops) lines.push(`+Drops=(Level="${d.level}", Valve=${x.valve}, Char=${x.char}, At=${vec(x.at)})`)
    n++
  }
  // Progeny's Furies (LWX2Furies): the console, the alarm, the execution's countdown.
  lines.push('', '[LongWarX2.LWX2Furies]', 'ReachTiles=1.5')
  for (const m of missions.filter((x) => x.id === 27)) {
    const file = levelFile(cooked, m.level)
    if (!file) continue
    const f = readFuries(file, m.map, m.level)
    if (!f) continue
    lines.push(`+Furies=(Map="${f.map}", Level="${f.level}", Console=${vec(f.console)}, AlarmCenter=${vec(f.alarm.center)}, AlarmExtent=${vec(f.alarm.extent)}, Timer=${f.timer}, ` +
      `Rescue=${q(f.rescue)}, ConsoleText=${q(f.consoleText)}, Kill=${q(f.kill)}, Execution=${q(f.execution)})`)
    n++
  }
  // The Temple Ship (LWX2TempleShip): its arenas' pods and its scripted spawns.
  // (FirstSwarmAt, SecondSwarmAt: EW's handler's LiveAliensThreshold for its first arena and its first wave; UberChar: Long War's
  // eChar_EtherealUber.)
  lines.push('', '[LongWarX2.LWX2TempleShip]', 'FirstSwarmAt=8', 'SecondSwarmAt=1', 'UberChar=19')
  const templeFile = levelFile(cooked, 'TempleShip')
  const t = templeFile ? readTemple(templeFile, 'TempleShip') : undefined
  if (t) {
    for (const p of t.pods) lines.push(`+Pods=(Arena=${p.arena}, Char=${p.char}, Min=${p.min}, Max=${p.max}, At=${vec(p.at)})`)
    for (const x of t.spawns) lines.push(`+Spawns=(Stage=${x.stage}, Char=${x.char}, At=${vec(x.at)})`)
    n++
  }
  // The variant levels' gated alien drops (LWX2LevelDrops): every council and covert level but the hive's and Deluge's, which
  // have their own (LWX2ChryssalidHive, LWX2Deluge).
  lines.push('', '[LongWarX2.LWX2LevelDrops]')
  const own = new Set(missions.filter((x) => x.id === 29 || x.id === 26).map((x) => x.level))
  for (const [, level] of variantPairs(mod)) {
    if (own.has(level)) continue
    const file = levelFile(cooked, level)
    if (!file) continue
    const d = readDrops(file, level)
    if (!d) continue
    for (const v of d.volumes) lines.push(`+Volumes=(Level="${level}", Center=${vec(v.center)}, Extent=${vec(v.extent)})`)
    for (const x of d.drops) lines.push(`+Drops=(Level="${level}", Volume=${x.volume}, Char=${x.char}, At=${vec(x.at)})`)
  }
  // Long War's named soldiers its council missions reward (LWX2CustomSoldiers, the council's reward 9: Progeny's).
  lines.push('', '[LongWarX2.LWX2CustomSoldiers]')
  for (const c of readCustomSoldiers(cooked)) {
    lines.push(`+Soldiers=(Mission=${c.mission}, First=${q(c.first)}, Last=${q(c.last)}, Nick=${q(c.nick)}, Country=${c.country}, Female=${c.female}, BaseClass=${c.baseClass}, ` +
      `Rank=${c.rank}, HP=${c.hp}, Aim=${c.aim}, Will=${c.will}, Mobility=${c.mobility}, PsiRank=${c.psiRank}, Perks=(${c.perks.join(', ')}), Alt=(${c.alt.join(', ')}))`)
  }
  writeFileSync(join(mod, 'Config', 'XComLWX2EWObjectives.ini'), lines.join('\r\n') + '\r\n')
  return n
}

if (/ew-objectives\.ts$/.test(process.argv[1] ?? '')) {
  const [cooked, mod] = process.argv.slice(2).filter((a) => a !== '--')
  if (!mod) {
    console.error('usage: ew-objectives.ts <EW CookedPCConsole> <mod folder>')
    process.exit(2)
  }
  console.log(`${writeObjectives(cooked!, mod!)} missions' objectives written (the council's, EXALT's)`)
}
