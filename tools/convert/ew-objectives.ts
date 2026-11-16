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

/** The variant levels of these maps' council missions: converted with them, each joined with its map into a plot of its own,
 *  LWX2V_<level> (ew-maps.ts writePlots), on which that mission plays. */
export function variantLevels(mod: string, maps: Iterable<string>): string[] {
  const want = new Set(maps)
  return [...new Set(councilMissions(mod).filter((m) => want.has(m.map)).map((m) => m.level))]
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

/** Every bomb disposal and VIP mission this install has, written into the mod's config; returns how many. */
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
  writeFileSync(join(mod, 'Config', 'XComLWX2EWObjectives.ini'), lines.join('\r\n') + '\r\n')
  return n
}

if (/ew-objectives\.ts$/.test(process.argv[1] ?? '')) {
  const [cooked, mod] = process.argv.slice(2).filter((a) => a !== '--')
  if (!mod) {
    console.error('usage: ew-objectives.ts <EW CookedPCConsole> <mod folder>')
    process.exit(2)
  }
  console.log(`${writeObjectives(cooked!, mod!)} council missions' objectives written`)
}
