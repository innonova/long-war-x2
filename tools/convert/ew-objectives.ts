// Enemy Within's council missions' objectives (features/lw-council-missions.md, step 2), read from the player's own install:
// a mission variant is a streamed level beside its map (URB_CemeteryGrand_Bomb.upk …) whose Kismet holds its rules and whose
// actors mark its objects. For the bomb disposals: the bomb (the high hot button, HotButton.ARC_IA_HotButtonColumnHigh, where
// EW's bomb stands) and the power nodes (the low hot buttons), at EW's coordinates (the map's plot keeps them); the bomb's
// Timer at the start and the number of nodes (#Nodes), the Kismet variables of those names. Written as the mod's config,
// Config/XComLWX2EWObjectives.ini (+Bombs=), which LWX2CouncilBomb reads. Numbers only.
//   node tools/convert/ew-objectives.ts <EW CookedPCConsole> <mod folder>
import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { openPackage } from '@innonova/upkit/package'
import { Reader } from '@innonova/upkit/bytes'
import { readTags, type Tag } from '@innonova/upkit/objects'

/** Each bomb disposal's map (XComLWCouncil.ini's) and the streamed level that carries its variant. */
export const BOMB_LEVELS: Record<string, string> = {
  URB_CemeteryGrand: 'URB_CemeteryGrand_Bomb',
  URB_HighwayBridge: 'URB_HIghwayBomb_Stream',
  URB_TrainStation: 'URB_TrainStation_Stream',
  URB_Trainyard: 'URB_Trainyard_Stream',
  URB_SlaughterhouseA: 'URB_Slaughterhouse_Stream',
}

/** Every map's mission variant level (the council's): converted with the map and joined into a plot of its own, LWX2V_<map>
 *  (ew-maps.ts writePlots), on which that mission plays. */
export const VARIANT_LEVELS: Record<string, string> = { ...BOMB_LEVELS }

/** The variant levels of these maps. */
export function variantLevels(maps: Iterable<string>): string[] {
  return [...maps].map((m) => VARIANT_LEVELS[m]).filter((l): l is string => !!l)
}

export interface Bomb { map: string; timer: number; nodes: number; bomb: number[]; nodeAt: number[][] }

/** A bomb disposal's level read: its bomb, nodes and numbers; undefined when it is not as expected. */
export function readBomb(file: string, map: string): Bomb | undefined {
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
  return { map, timer, nodes: nodes || nodeAt.length, bomb, nodeAt }
}

/** Every bomb disposal this install has, written into the mod's config; returns how many. */
export function writeObjectives(cooked: string, mod: string): number {
  const vec = (p: number[]) => `(X=${p[0]}, Y=${p[1]}, Z=${p[2]})`
  const lines = [
    "; Enemy Within's council missions' objectives, read from this machine's EW by tools/convert/ew-objectives.ts.",
    '[LongWarX2.LWX2CouncilBomb]',
  ]
  let n = 0
  for (const [map, level] of Object.entries(BOMB_LEVELS)) {
    const file = join(cooked, `${level}.upk`)
    if (!existsSync(file)) continue
    const b = readBomb(file, map)
    if (!b) continue
    lines.push(`+Bombs=(Map="${b.map}", Timer=${b.timer}, Nodes=${b.nodes}, Bomb=${vec(b.bomb)}, NodeAt=(${b.nodeAt.map(vec).join(', ')}))`)
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
  console.log(`${writeObjectives(cooked!, mod!)} bomb disposals written`)
}
