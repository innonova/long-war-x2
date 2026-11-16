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
interface KOp { k: number; type: string; props: Map<string, Tag>; out: number[]; vars: Map<string, number[]> }

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
    const op: KOp = { k, type: e.type, props: new Map(), out: [], vars: new Map() }
    for (const t of tags) {
      if (t.name === 'OutputLinks' && t.type === 'ArrayProperty') {
        for (const ol of structs(t.value)) {
          const links = ol.find((x) => x.name === 'Links')
          if (links) for (const l of structs(links.value)) {
            const to = l.find((x) => x.name === 'LinkedOp')
            if (to) op.out.push(dv(to.value).getInt32(0, true) - 1)
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
  const texts = strings.filter((s) => /(Extract|Rescue)\d$/.test(s.key)).sort((a, b) => a.key.localeCompare(b.key)).map((s) => s.value)
  const shared = (key: string) => strings.find((s) => s.key === key)?.value ?? ''
  return {
    map, level, at, approach, extract, texts,
    first: text(naming.vars.get('First Name')?.[0]),
    last: text(naming.vars.get('Last Name')?.[0]),
    killRest: shared('m_strBombObj3'),
    report: shared('m_strBombObj4'),
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

/** Every bomb disposal, VIP mission and covert extraction this install has, written into the mod's config; returns how many. */
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
  for (const m of missions.filter((x) => x.kind === 3 || x.kind === 4)) {
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
