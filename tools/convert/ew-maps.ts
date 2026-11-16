// Enemy Within's maps for Long War's missions converted on the player's machine, many at once
// (features/lw-missions.md): each map by ew-map.ts (its package to the content folder), its section kept in a work
// folder, and every section joined into the mod's XComLWX2EWMap.ini, which the mod reads (LWX2EWMapData).
//   node tools/convert/ew-maps.ts <EW's CookedPCConsole> <the mod's folder (LongWarX2)> [--all | --kind <Kind> | <map> …] [--force] [--out <folder>]
// The packages go to --out (default: BuildCache/ewcontent beside the mod's folder, which tools/test/build.ps1 links into
// the built mod's Content: in Content itself they would be processed by every build); in a player's installed mod
// (the setup program), the mod's Content.
// Then each converted map's own plot (writePlots: ew-plot.ts, LWX2_<map>.umap beside the packages), and for a map with a
// council mission's variant level (ew-objectives.ts VARIANT_LEVELS, converted with it) a plot of the two, LWX2V_<map>.umap.
// --all: every map Long War lists for its missions (Config/XComLWEWMaps.ini); --kind Abduction|Crash|Landed|Terror:
// those of a kind; --base: EW's base's levels (BaseLevels, for LWX2EWBase; no plots), with any of the others. A map
// already converted is skipped unless --force.
import { execFileSync } from 'node:child_process'
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { readSection, writePlot, type PlotSettings } from './ew-plot.ts'
import { openImages } from './ew-images.ts'
import { VARIANT_LEVELS, variantLevels } from './ew-objectives.ts'

/** The converter version ew-map.ts writes into its sections (kept in step with its CONVERTER_VERSION; read from the
 *  section, so this file need not load the converter). */
const CONVERTER_VERSION = 17
/** Whether a converted map's section is of the current converter (an older one is converted again). */
export function sectionCurrent(ini: string): boolean {
  const m = /; ew-map\.ts (\d+)/.exec(readFileSync(ini, 'latin1'))
  return !!m && Number(m[1]) >= CONVERTER_VERSION
}

/** The plot writer's settings from the mod's own XComLWEWMaps.ini (the stand-ins' parents and parameters, the lights). */
export function plotSettings(mod: string): PlotSettings {
  const ini = readFileSync(join(mod, 'Config', 'XComLWEWMaps.ini'), 'latin1')
  const str = (k: string) => new RegExp(`^${k}="([^"]*)"`, 'm').exec(ini)?.[1] ?? ''
  return {
    parents: { Prop: str('PropParent'), Foliage: str('FoliageParent'), Masked: str('MaskedParent'), Alien: str('AlienParent') },
    diffuseMasks: str('DiffuseMasks').split(',').map((k) => k.trim()).filter(Boolean),
    scalars: [...ini.matchAll(/^\+StandinScalars=\(Name=(\w+), Value=([-\d.]+)\)/gm)].map((m) => [m[1]!, Number(m[2])] as [string, number]),
    textures: [...ini.matchAll(/^\+StandinTextures=\(Name=(\w+), Path="([^"]+)"\)/gm)].map((m) => [m[1]!, m[2]!] as [string, string]),
    lightScale: Number(/^PlotLightScale=([\d.]+)/m.exec(ini)?.[1] ?? 1),
    lightKinds: [...ini.matchAll(/^\+LightKinds=(\w+)/gm)].map((m) => m[1]!),
    buildings: /^PlotBuildings=true/m.test(ini),
    fracWalls: /^PlotFracWalls=true/m.test(ini),
  }
}

/**
 * Each converted map's own plot (ew-plot.ts: LWX2_<map>.umap in content), from its section in work, for the sections of
 * the current converter (an older section's package is not nested, and its map is placed at run time instead). Returns
 * the plots' names.
 */
export function writePlots(mod: string, content: string, work: string, template: string, say: (line: string) => void = console.log): string[] {
  const settings = plotSettings(mod)
  const bytes = new Uint8Array(readFileSync(template))
  const plots: string[] = []
  const base = new Set([...baseLevels(mod), ...Object.values(VARIANT_LEVELS)].map((l) => `${l}.ini`))
  let old = 0
  for (const f of readdirSync(work).filter((f) => f.endsWith('.ini') && !base.has(f)).sort()) {
    const ini = join(work, f)
    if (!sectionCurrent(ini)) {
      old++
      continue
    }
    const map = readSection(readFileSync(ini, 'latin1'))
    const { bytes: plot } = writePlot(bytes, map, settings)
    writeFileSync(join(content, `LWX2_${map.name}.umap`), plot)
    plots.push(`LWX2_${map.name}`)
  }
  // Each map with its council mission's variant level converted: a plot of the two (LWX2V_<map>), for that mission.
  for (const [name, level] of Object.entries(VARIANT_LEVELS)) {
    const [mapIni, levelIni] = [join(work, `${name}.ini`), join(work, `${level}.ini`)]
    if (!existsSync(mapIni) || !existsSync(levelIni) || !sectionCurrent(mapIni) || !sectionCurrent(levelIni)) continue
    const map = readSection(readFileSync(mapIni, 'latin1'))
    const variant = readSection(readFileSync(levelIni, 'latin1'))
    map.pieces.push(...variant.pieces)
    map.doors.push(...variant.doors)
    map.lights.push(...variant.lights)
    for (const [k, look] of variant.looks) map.looks.set(k, look)
    writeFileSync(join(content, `LWX2V_${name}.umap`), writePlot(bytes, map, settings).bytes)
    plots.push(`LWX2V_${name}`)
  }
  say(`${plots.length} maps written as plots of their own${old ? `; ${old} converted by an older version, placed at run time until converted again` : ''}`)
  return plots
}

/** The levels of EW's base (the mod's Config/XComLWEWMaps.ini, BaseLevels): converted like maps, but no plots of their own. */
export function baseLevels(mod: string): string[] {
  return [...readFileSync(join(mod, 'Config', 'XComLWEWMaps.ini'), 'latin1').matchAll(/^\+BaseLevels="([^"]+)"/gm)].map((m) => m[1]!)
}

/** How many mission maps (not the base's levels) the mod's Config/XComLWX2EWMap.ini holds. */
export function missionSections(mod: string): number {
  const ini = join(mod, 'Config', 'XComLWX2EWMap.ini')
  if (!existsSync(ini)) return 0
  const base = new Set([...baseLevels(mod), ...Object.values(VARIANT_LEVELS)])
  return [...readFileSync(ini, 'latin1').matchAll(/^\[(\S+) LWX2EWMapData\]/gm)].filter((m) => !base.has(m[1]!)).length
}

/** The maps Long War lists for its missions (the mod's Config/XComLWEWMaps.ini): their names and kinds. */
export function listedMaps(mod: string): { name: string; kind: string }[] {
  return readFileSync(join(mod, 'Config', 'XComLWEWMaps.ini'), 'latin1')
    .split(/\r?\n/)
    .map((l) => l.match(/^\+Maps=\(Name="([^"]+)".*Kind=(\w+),/))
    .filter((m): m is RegExpMatchArray => !!m)
    .map((m) => ({ name: m[1]!, kind: m[2]! }))
}

/**
 * The maps converted, one by one with convertOne (a child process each: a map can need a large heap), their sections kept
 * in work, then all sections joined into the mod's Config/XComLWX2EWMap.ini. Returns the maps not converted.
 */
export function convertMaps(
  cooked: string,
  mod: string,
  maps: string[],
  content: string,
  work: string,
  convertOne: (src: string, out: string, ini: string) => string,
  force = false,
  say: (line: string) => void = console.log,
): string[] {
  mkdirSync(work, { recursive: true })
  mkdirSync(content, { recursive: true })
  const failed: string[] = []
  for (const name of [...new Set(maps)]) {
    const src = join(cooked, `${name}.upk`)
    const out = join(content, `${name}.upk`)
    const ini = join(work, `${name}.ini`)
    if (!existsSync(src)) {
      say(`${name}: not in this install`)
      failed.push(name)
      continue
    }
    if (!force && existsSync(out) && existsSync(ini) && sectionCurrent(ini)) {
      say(`${name}: converted already`)
      continue
    }
    const started = Date.now()
    try {
      const log = convertOne(src, out, ini)
      say(`${name}: ${((Date.now() - started) / 1000).toFixed(0)} s; ${log.trim().split('\n').pop()}`)
    } catch (e) {
      say(`${name}: FAILED (${String((e as { stderr?: string }).stderr ?? e).trim().split('\n').slice(-2).join(' ')})`)
      failed.push(name)
    }
  }
  const sections = readdirSync(work).filter((f) => f.endsWith('.ini')).sort()
  writeFileSync(
    join(mod, 'Config', 'XComLWX2EWMap.ini'),
    [
      "; Enemy Within's maps converted on this machine (tools/convert/ew-maps.ts): one section each. Not in the repository.",
      ...sections.map((f) => readFileSync(join(work, f), 'latin1').trimEnd()),
    ].join('\r\n') + '\r\n',
  )
  say(`${sections.length} maps in Config/XComLWX2EWMap.ini; ${failed.length} not converted${failed.length ? ': ' + failed.join(', ') : ''}`)
  return failed
}

if (/ew-maps\.ts$/.test(process.argv[1] ?? '')) {
  const args = process.argv.slice(2).filter((a) => a !== '--')
  const [cooked, mod] = args
  if (!mod) {
    console.error('usage: ew-maps.ts <EW CookedPCConsole> <mod folder> [--all | --kind <Kind> | <map> …] [--base] [--force] [--out <folder>]')
    process.exit(2)
  }
  const listed = listedMaps(mod)
  const at = (flag: string) => args.indexOf(flag)
  let maps: string[]
  if (args.includes('--all')) maps = listed.map((m) => m.name)
  else if (at('--kind') >= 0) maps = listed.filter((m) => m.kind === args[at('--kind') + 1]).map((m) => m.name)
  else {
    // The names: what is neither a flag nor a flag's value.
    const values = new Set([at('--kind'), at('--out')].filter((i) => i >= 0).map((i) => i + 1))
    maps = args.slice(2).filter((a, i) => !a.startsWith('--') && !values.has(i + 2))
  }
  maps = [...maps, ...variantLevels(maps)]
  if (args.includes('--base')) maps = [...maps, ...baseLevels(mod)]
  const content = at('--out') >= 0 ? args[at('--out') + 1]! : join(mod, '..', 'BuildCache', 'ewcontent')
  const converter = join(dirname(fileURLToPath(import.meta.url)), 'ew-map.ts')
  const work = join(mod, '..', 'BuildCache', 'ewmaps')
  convertMaps(cooked!, mod, maps, content, work, (src, out, ini) =>
    execFileSync(process.execPath, ['--max-old-space-size=12288', converter, '--', src, out, ini], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }),
    args.includes('--force'),
  )
  // EW's strategy pictures in the converted base (ew-images.ts), as the setup makes them ready.
  if (existsSync(join(content, 'Command1.upk'))) openImages(join(content, 'Command1.upk'))
  // Their plots, from the repository's template (tools/test/build.ps1 links and lists them on the test machine).
  writePlots(mod, content, work, join(dirname(fileURLToPath(import.meta.url)), '..', 'maps', 'LWX2_EWPlotTemplate.umap'))
}
