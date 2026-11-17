// Enemy Within levels' Kismet, exported for the mod's interpreter (LWX2Kismet, features/lw-story.md), read from the player's own
// install: every sequence op of a level with its output links (to which op, which input), its variable links and the few
// properties the interpreter acts on; every variable those links reach, resolved to the variable it stands for (a named one
// to the variable of that name, a subsequence's external one to what its sequence links there), with its value (an int, a
// bool, a float, a string; for an actor: its class, where it stands and, for a volume, its box); and each sequence's inputs
// and outputs (the event inside that an input starts, the finish op that ends at an output). Also the level's wave system
// (XComWaveSystem: its alien sets, their waves and groups), which the interpreter's remote events start and stop.
// Written as the mod's config, Config/XComLWX2Kismet.ini. Numbers, names and the level's own texts (objectives), on the
// player's machine only.
//   node tools/convert/ew-kismet.ts <EW CookedPCConsole> <mod folder> [level …]
import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { openPackage } from '@innonova/upkit/package'
import { Reader } from '@innonova/upkit/bytes'
import { readTags, type Tag } from '@innonova/upkit/objects'
import { charOfPawn } from './ew-objectives.ts'

/** The levels whose Kismet the mod runs (LWX2Kismet's users): the HQ assault's. */
export const KISMET_LEVELS = ['EWI_HQAssault_Stream']

/** Event classes that fire any number of times (their class default MaxTriggerCount=0: Engine's SeqEvent_RemoteEvent and
 *  SeqEvent_SequenceActivated, XComGame's turn, kill and victory events); every other event fires once unless the level
 *  sets its count. */
const UNLIMITED = /^(SeqEvent_RemoteEvent|SeqEvent_SequenceActivated|SeqEvent_On\w+|SeqEvent_RoamingAlienNumberSet|SeqEvent_DynamicAlienSpawned)$/

interface Op {
  k: number
  type: string
  seq: number
  props: Map<string, Tag>
  /** Output links: per output index, its links (op, input index) and, on a sequence, the finish op inside that ends there. */
  outs: { links: { to: number; input: number }[]; finish: number }[]
  /** A sequence's inputs: the event inside each starts. */
  ins: number[]
  vars: { desc: string; ids: number[] }[]
}

function levelFile(cooked: string, level: string): string | undefined {
  const exact = join(cooked, `${level}.upk`)
  if (existsSync(exact)) return exact
  const found = readdirSync(cooked).find((f) => f.toLowerCase() === `${level}.upk`.toLowerCase())
  return found ? join(cooked, found) : undefined
}

/** One level's Kismet and wave system as config lines (K: the level's number × 100000 + the op's export index, unique
 *  across levels); undefined when the level has no Kismet. */
export function kismetLines(file: string, level: string, levelNo: number): { kismet: string[]; waves: string[] } | undefined {
  const bytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const dv = (b: Uint8Array) => new DataView(b.buffer, b.byteOffset, b.byteLength)
  const nameAt = (i: number) => String(pkg.names[i]?.name ?? '')
  const structs = (v: Uint8Array): Tag[][] => {
    const n = dv(v).getInt32(0, true)
    const r = new Reader(v.subarray(4))
    return Array.from({ length: n }, () => readTags(r, pkg) as Tag[])
  }
  const str = (t: Tag | undefined) => (t ? new TextDecoder('latin1').decode(t.value.subarray(4)).replace(/\0/g, '') : '')
  const int = (t: Tag | undefined, d = 0) => (t ? dv(t.value).getInt32(0, true) : d)
  const obj = (t: Tag | undefined) => (t ? dv(t.value).getInt32(0, true) - 1 : -1)
  const name = (t: Tag | undefined) => (t && t.value.byteLength >= 8 ? nameAt(dv(t.value).getInt32(0, true)) : '')
  const bool = (t: Tag | undefined, d: boolean) => (t ? (t as any).bool ?? t.value[0] !== 0 : d)
  const outerOf = (k: number) => meta.exports.findIndex((e: any) => e.fullName === meta.exports[k].fullName.split('.').slice(0, -1).join('.'))
  const K = (k: number) => levelNo * 100000 + k

  // The ops and variables.
  const ops = new Map<number, Op>()
  meta.exports.forEach((e: any, k: number) => {
    if (!/^Seq/.test(e.type)) return
    let tags: Tag[] = []
    try {
      tags = readTags(new Reader(pkg.data(k + 1).subarray(4)), pkg) as Tag[]
    } catch {
      return
    }
    const op: Op = { k, type: e.type, seq: outerOf(k), props: new Map(), outs: [], ins: [], vars: [] }
    for (const t of tags) {
      if (t.name === 'OutputLinks' && t.type === 'ArrayProperty') {
        for (const ol of structs(t.value)) {
          const links = ol.find((x) => x.name === 'Links')
          op.outs.push({
            links: links ? structs(links.value).map((l) => ({ to: obj(l.find((x) => x.name === 'LinkedOp')), input: int(l.find((x) => x.name === 'InputLinkIdx')) })).filter((l) => l.to >= 0) : [],
            finish: obj(ol.find((x) => x.name === 'LinkedOp')),
          })
        }
      } else if (t.name === 'InputLinks' && t.type === 'ArrayProperty') {
        op.ins = structs(t.value).map((il) => obj(il.find((x) => x.name === 'LinkedOp')))
      } else if (t.name === 'VariableLinks' && t.type === 'ArrayProperty') {
        for (const vl of structs(t.value)) {
          const lv = vl.find((x) => x.name === 'LinkedVariables')
          const n = lv ? dv(lv.value).getInt32(0, true) : 0
          op.vars.push({ desc: str(vl.find((x) => x.name === 'LinkDesc')), ids: Array.from({ length: n }, (_, i) => dv(lv!.value).getInt32(4 + 4 * i, true) - 1) })
        }
      } else op.props.set(t.name, t)
    }
    ops.set(k, op)
  })
  if (ops.size === 0) return undefined

  // A variable as the one it stands for (a named one: the variable of that name; an external one: what its sequence links
  // to that label), each once.
  const byName = new Map<string, number>()
  for (const o of ops.values()) if (/^SeqVar_/.test(o.type) && o.type !== 'SeqVar_Named' && o.type !== 'SeqVar_External') {
    const n = name(o.props.get('VarName'))
    if (n && n !== 'None' && !byName.has(n)) byName.set(n, o.k)
  }
  const resolve = (k: number, depth = 0): number[] => {
    const o = ops.get(k)
    if (!o || depth > 6) return []
    if (o.type === 'SeqVar_Named') {
      const to = byName.get(name(o.props.get('FindVarName')))
      return to !== undefined ? resolve(to, depth + 1) : []
    }
    if (o.type === 'SeqVar_External') {
      const label = str(o.props.get('VariableLabel'))
      const outer = ops.get(o.seq)
      return (outer?.vars.find((v) => v.desc === label)?.ids ?? []).flatMap((id) => resolve(id, depth + 1))
    }
    return [k]
  }

  // An actor's properties (its tags start a little into its data); its location; a brush volume's box.
  const actorTags = (k: number): Tag[] => {
    const data = pkg.data(k + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, j) => j)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), pkg) as Tag[]
        if (t.some((x) => x.name === 'Location' || x.name === 'Tag' || x.name === 'Brush')) return t
      } catch {
        // not here
      }
    }
    return []
  }
  const locOf = (t: Tag[]) => {
    const l = t.find((x) => x.name === 'Location')
    return l ? [0, 4, 8].map((o) => Math.round(dv(l.value).getFloat32(o, true))) : [0, 0, 0]
  }
  const boxOf = (t: Tag[]) => {
    const brush = t.find((x) => x.name === 'Brush')
    if (!brush) return undefined
    const l = locOf(t)
    const v = dv(pkg.data(dv(brush.value).getInt32(0, true)))
    const none = meta.names.indexOf('None')
    let o = 4
    while (v.getInt32(o, true) !== none) o += 24 + v.getInt32(o + 16, true)
    o += 8
    const b = Array.from({ length: 6 }, (_, j) => v.getFloat32(o + 4 * j, true))
    return { center: [0, 1, 2].map((j) => Math.round(l[j]! + b[j]!)), extent: [3, 4, 5].map((j) => Math.round(b[j]!)) }
  }
  const vec = (p: number[]) => `(X=${p[0]}, Y=${p[1]}, Z=${p[2]})`
  const q = (s: string) => `"${s.replace(/"/g, "'")}"`

  const kismet: string[] = []
  const usedVars = new Set<number>()
  const sorted = [...ops.values()].filter((o) => !/^SeqVar_/.test(o.type) && !/^SequenceFrame/.test(o.type)).sort((a, b) => a.k - b.k)
  for (const o of sorted) {
    // What the interpreter needs of each kind: a name (an event's, a state's, a label, a property to modify), an int, a float.
    let n = ''
    let i = 0
    let f = 0
    switch (o.type) {
      case 'SeqEvent_RemoteEvent':
      case 'SeqAct_ActivateRemoteEvent':
        n = name(o.props.get('EventName')) || 'DefaultEvent'
        break
      case 'SeqAct_SpecialMissionHandler_GotoState':
        n = name(o.props.get('StateName'))
        break
      case 'SeqAct_SpecialMissionHandler_Initialize':
        n = name(o.props.get('SpecialMissionHandlerType'))
        break
      case 'SeqEvent_SequenceActivated':
        n = str(o.props.get('InputLabel'))
        break
      case 'SeqAct_FinishSequence':
        n = str(o.props.get('OutputLabel'))
        break
      case 'SeqAct_RandomSwitch':
        i = int(o.props.get('LinkCount'), 1)
        break
      case 'SeqAct_Delay':
        f = o.props.get('Duration') ? dv(o.props.get('Duration')!.value).getFloat32(0, true) : 1
        break
      case 'SeqAct_SpawnReinforcement':
        i = bool(o.props.get('SpawnBlueshirt'), false) ? 1 : 0
        break
      case 'SeqAct_ModifyProperty': {
        const p = o.props.get('Properties')
        n = p ? structs(p.value).map((s) => `${name(s.find((x) => x.name === 'PropertyName'))}=${str(s.find((x) => x.name === 'PropertyValue'))}`).join(';') : ''
        break
      }
    }
    // Events: how many times they may fire (0: any).
    const maxT = /^SeqEvent_/.test(o.type) ? (o.props.has('MaxTriggerCount') ? int(o.props.get('MaxTriggerCount')) : UNLIMITED.test(o.type) ? 0 : 1) : 0
    kismet.push(`+Ops=(K=${K(o.k)}, T=${o.type}, Sq=${o.seq >= 0 ? K(o.seq) : 0}, N=${q(n)}, I=${i}, F=${f}, M=${maxT})`)
    o.outs.forEach((out, oi) => {
      for (const l of out.links) if (ops.has(l.to)) kismet.push(`+Links=(K=${K(o.k)}, O=${oi}, To=${K(l.to)}, In=${l.input})`)
    })
    for (const v of o.vars)
      for (const id of v.ids.flatMap((x) => resolve(x))) {
        kismet.push(`+VL=(K=${K(o.k)}, D=${q(v.desc)}, V=${K(id)})`)
        usedVars.add(id)
      }
    if (o.type === 'Sequence') {
      o.ins.forEach((e, ii) => e >= 0 && kismet.push(`+SeqIn=(K=${K(o.k)}, In=${ii}, E=${K(e)})`))
      o.outs.forEach((out, oi) => out.finish >= 0 && kismet.push(`+SeqOut=(K=${K(o.k)}, O=${oi}, F=${K(out.finish)})`))
    }
  }
  // The variables reached: each with its value.
  for (const k of [...usedVars].sort((a, b) => a - b)) {
    const o = ops.get(k)!
    const p = o.props
    let line = `+Vars=(K=${K(k)}, T=${o.type}`
    switch (o.type) {
      case 'SeqVar_Int':
        line += `, I=${int(p.get('IntValue'))}`
        break
      case 'SeqVar_Bool':
        line += `, I=${int(p.get('bValue'))}`
        break
      case 'SeqVar_Float':
        line += `, F=${p.get('FloatValue') ? dv(p.get('FloatValue')!.value).getFloat32(0, true) : 0}`
        break
      case 'SeqVar_String':
      case 'SeqVar_LocalizedString':
        line += `, S=${q(str(p.get('StrValue')))}`
        break
      case 'SeqVar_Object': {
        const a = obj(p.get('ObjValue'))
        if (a >= 0 && meta.exports[a]) {
          const t = actorTags(a)
          const box = boxOf(t)
          line += `, A=${meta.exports[a].type}, P=${vec(box?.center ?? locOf(t))}${box ? `, E=${vec(box.extent)}` : ''}`
        }
        break
      }
    }
    kismet.push(line + ')')
  }

  // The level's wave system (XComWaveSystem): each group of each wave of each alien set, with its set's start and stop events.
  const waves: string[] = []
  meta.exports.forEach((e: any, k: number) => {
    if (e.type !== 'XComWaveSystem' || !/^TheWorld\.PersistentLevel\.[^.]+$/.test(e.fullName)) return
    const t = actorTags(k)
    const sets = t.find((x) => x.name === 'm_arrAlienSets')
    if (!sets) return
    structs(sets.value).forEach((set, si) => {
      const start = name(set.find((x) => x.name === 'EventName'))
      const stop = name(set.find((x) => x.name === 'DisableEvent'))
      const ws = set.find((x) => x.name === 'Waves')
      const list = ws ? structs(ws.value) : []
      if (list.length === 0) waves.push(`+Groups=(L=${levelNo}, Set=${si}, Start=${q(start === 'None' ? '' : start)}, Stop=${q(stop === 'None' ? '' : stop)}, Wave=-1)`)
      list.forEach((w, wi) => {
        const turn = int(w.find((x) => x.name === 'TurnAppearance'), -1)
        const when = /Beginning/.test(name(w.find((x) => x.name === 'SpawnTime'))) ? 0 : 1
        const gs = w.find((x) => x.name === 'Groups')
        for (const g of gs ? structs(gs.value) : []) {
          const pts = g.find((x) => x.name === 'SpawnPoints')
          const n = pts ? dv(pts.value).getInt32(0, true) : 0
          const at = Array.from({ length: n }, (_, j) => locOf(actorTags(dv(pts!.value).getInt32(4 + 4 * j, true) - 1)))
          const method = g.find((x) => x.name === 'SpawnMethod')
          const type = method ? name(readTags(new Reader(method.value), pkg).find((x: Tag) => x.name === 'SpawnType')) : ''
          waves.push(`+Groups=(L=${levelNo}, Set=${si}, Start=${q(start === 'None' ? '' : start)}, Stop=${q(stop === 'None' ? '' : stop)}, Wave=${wi}, Turn=${turn}, ` +
            `When=${when}, Char=${charOfPawn(name(g.find((x) => x.name === 'AlienType')))}, Scalable=${bool(g.find((x) => x.name === 'Scalable'), false)}, ` +
            `Method=${/FlyIn/.test(type) ? 2 : /WalkIn/.test(type) ? 1 : 0}, N=${int(g.find((x) => x.name === 'NumAliens'))}, Hunter=${bool(g.find((x) => x.name === 'Hunter'), true)}, ` +
            `OnActivated=${q(name(g.find((x) => x.name === 'm_strOnGroupActivated')).replace(/^None$/, ''))}, OnSpawned=${q(name(g.find((x) => x.name === 'm_strOnGroupSpawned')).replace(/^None$/, ''))}, ` +
            `At=(${at.map(vec).join(', ')}))`)
        }
      })
    })
  })
  return { kismet, waves }
}

/** The levels' Kismet and wave systems written into the mod's config; returns how many levels. */
export function writeKismet(cooked: string, mod: string, levels: string[] = KISMET_LEVELS): number {
  const kismet = ["; Enemy Within levels' Kismet, read from this machine's EW by tools/convert/ew-kismet.ts.", '[LongWarX2.LWX2Kismet]']
  const waves: string[] = []
  let n = 0
  levels.forEach((level, i) => {
    const file = levelFile(cooked, level)
    if (!file) return
    const r = kismetLines(file, level, i + 1)
    if (!r) return
    kismet.push(`+Levels=(L=${i + 1}, Name="${level}")`, ...r.kismet)
    waves.push(...r.waves)
    n++
  })
  // (Flyers: Long War's species with EW's fly ability, for the scalable groups that fly in: Floaters, Heavy Floaters, Cyberdiscs,
  // Drones, Seekers.)
  kismet.push('', '[LongWarX2.LWX2WaveSystem]', '+Flyers=5', '+Flyers=8', '+Flyers=10', '+Flyers=17', '+Flyers=23', ...waves)
  writeFileSync(join(mod, 'Config', 'XComLWX2Kismet.ini'), kismet.join('\r\n') + '\r\n')
  return n
}

if (/ew-kismet\.ts$/.test(process.argv[1] ?? '')) {
  const [cooked, mod, ...levels] = process.argv.slice(2).filter((a) => a !== '--')
  if (!mod) {
    console.error('usage: ew-kismet.ts <EW CookedPCConsole> <mod folder> [level …]')
    process.exit(2)
  }
  console.log(`${writeKismet(cooked!, mod!, levels.length ? levels : KISMET_LEVELS)} levels' Kismet written`)
}
