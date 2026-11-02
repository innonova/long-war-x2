// Enemy Within's maps for Long War's missions converted on the player's machine, many at once
// (features/lw-missions.md): each map by ew-map.ts (its package to --out, below), its section kept in a work folder,
// and every section joined into the mod's XComLWX2EWMap.ini, which the mod reads (LWX2EWMapData).
//   node tools/convert/ew-maps.ts <EW's CookedPCConsole> <the mod's folder (LongWarX2)> [--all | --kind <Kind> | <map> …] [--force] [--out <folder>]
// The packages go to --out (default: BuildCache/ewcontent beside the mod's folder, which tools/test/build.ps1 links into
// the built mod's Content: in Content itself they would be processed by every build); in a player's installed mod,
// --out is the mod's Content.
// --all: every map Long War lists for its missions (Config/XComLWEWMaps.ini); --kind Abduction|Crash|Landed|Terror:
// those of a kind. A map already converted is skipped unless --force. Ends with the joined ini, from every section
// in the work folder (BuildCache/ewmaps beside the mod's folder).
import { execFileSync } from 'node:child_process'
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const args = process.argv.slice(2).filter((a) => a !== '--')
const [cooked, mod] = args
if (!mod) {
  console.error('usage: ew-maps.ts <EW CookedPCConsole> <mod folder> [--all | --kind <Kind> | <map> …] [--force]')
  process.exit(2)
}
const force = args.includes('--force')
const listed = readFileSync(join(mod, 'Config', 'XComLWEWMaps.ini'), 'latin1')
  .split(/\r?\n/)
  .map((l) => l.match(/^\+Maps=\(Name="([^"]+)".*Kind=(\w+),/))
  .filter((m): m is RegExpMatchArray => !!m)
  .map((m) => ({ name: m[1]!, kind: m[2]! }))
const kindAt = args.indexOf('--kind')
let maps: string[]
if (args.includes('--all')) maps = listed.map((m) => m.name)
else if (kindAt >= 0) maps = listed.filter((m) => m.kind === args[kindAt + 1]).map((m) => m.name)
else {
  // The names: what is neither a flag nor a flag's value.
  const values = new Set([args.indexOf('--kind'), args.indexOf('--out')].filter((i) => i >= 0).map((i) => i + 1))
  maps = args.slice(2).filter((a, i) => !a.startsWith('--') && !values.has(i + 2))
}
maps = [...new Set(maps)]

const work = join(mod, '..', 'BuildCache', 'ewmaps')
const outAt = args.indexOf('--out')
const content = outAt >= 0 ? args[outAt + 1]! : join(mod, '..', 'BuildCache', 'ewcontent')
mkdirSync(work, { recursive: true })
mkdirSync(content, { recursive: true })
const converter = join(dirname(fileURLToPath(import.meta.url)), 'ew-map.ts')
const failed: string[] = []
for (const name of maps) {
  const src = join(cooked, `${name}.upk`)
  const out = join(content, `${name}.upk`)
  const ini = join(work, `${name}.ini`)
  if (!existsSync(src)) {
    console.log(`${name}: not in this install`)
    failed.push(name)
    continue
  }
  if (!force && existsSync(out) && existsSync(ini)) {
    console.log(`${name}: converted already`)
    continue
  }
  const started = Date.now()
  try {
    const log = execFileSync(process.execPath, ['--max-old-space-size=12288', converter, '--', src, out, ini], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })
    console.log(`${name}: ${((Date.now() - started) / 1000).toFixed(0)} s; ${log.trim().split('\n').pop()}`)
  } catch (e) {
    console.log(`${name}: FAILED (${String((e as { stderr?: string }).stderr ?? e).trim().split('\n').slice(-2).join(' ')})`)
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
console.log(`${sections.length} maps in Config/XComLWX2EWMap.ini; ${failed.length} not converted${failed.length ? ': ' + failed.join(', ') : ''}`)
