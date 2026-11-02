// The player's setup program (features/playable-build.md): installs the mod into XCOM 2: War of
// the Chosen, writes Long War's words for it from the player's own Long War install, and converts
// Enemy Within's content the mod uses from that install (features/lw-ew-screens.md, lw-missions.md):
// its strategy screens and its earth always, its maps when asked (about 18 GB).
//
//   LongWarX2-setup.exe                  install (or update) the mod beside this program, write the words, convert
//   LongWarX2-setup.exe --uninstall      remove the mod
//   options: --xcom2 <War of the Chosen folder> --ew <Enemy Within's XEW folder> --no-pause
//            --maps / --no-maps          convert Enemy Within's maps, or not (else asked)
//
// Bundled with upkit into one Windows program (tools/setup/bundle.mjs); runs from the repository
// too: node tools/setup/setup.mjs --mod LongWarX2 …
import { cpSync, existsSync, readFileSync, renameSync, rmSync, writeFileSync, mkdirSync, statSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { createInterface } from 'node:readline'
import { execFileSync } from 'node:child_process'
import { wordsFrom } from '../../scripts/write-words.mjs'
import { convertUI } from '../convert/ew-ui.ts'
import { convertPackage } from '../convert/ew-package.ts'
import { convertMap } from '../convert/ew-map.ts'
import { convertMaps, listedMaps } from '../convert/ew-maps.ts'

const MOD = 'LongWarX2'
const args = process.argv.slice(2)
const opt = (name) => {
  const i = args.indexOf(name)
  return i >= 0 ? args[i + 1] : undefined
}
const flag = (name) => args.includes(name)
const say = (...a) => console.log(...a)

/** A registry value through Windows' reg tool, the 64- then the 32-bit view (as the Long War Tech Tree does), or undefined. */
function registry(key, name) {
  for (const view of ['/reg:64', '/reg:32']) {
    try {
      const out = execFileSync('reg', ['query', key, '/v', name, view], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], windowsHide: true })
      for (const line of out.split(/\r?\n/)) {
        const m = /^\s*(\S+)\s+(REG_\w+)\s+(.*)$/.exec(line)
        if (m && m[1].toLowerCase() === name.toLowerCase()) return m[3].trim().replace(/\//g, '\\')
      }
    } catch {
      // not in this view
    }
  }
  return undefined
}

/** From Steam's libraryfolders.vdf, the libraries whose "apps" list holds the app (an older file without lists: all of them). */
function librariesWithApp(vdf, app) {
  const hits = [...vdf.matchAll(/"path"\s+"([^"]+)"/g)]
  return hits
    .filter((m, i) => {
      const block = vdf.slice(m.index + m[0].length, hits[i + 1]?.index ?? vdf.length)
      return !block.includes('"apps"') || block.includes(`"${app}"`)
    })
    .map((m) => m[1].replace(/\\\\/g, '\\'))
}

/**
 * A Steam game's folder, found as the Long War Tech Tree finds Enemy Within (desktop/src/game.ts):
 * its uninstall entry's InstallLocation, else the library Steam's own list says holds it. No drive
 * searching. `folder` is its folder under steamapps/common, `sub` a folder that must be inside.
 */
function findSteamApp(app, folder, sub) {
  const ok = (dir) => dir && existsSync(join(dir, sub)) && dir
  for (const hive of ['HKLM', 'HKCU']) {
    const dir = ok(registry(`${hive}\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Steam App ${app}`, 'InstallLocation'))
    if (dir) return dir
  }
  const steams = [registry('HKCU\\Software\\Valve\\Steam', 'SteamPath'), registry('HKLM\\SOFTWARE\\Valve\\Steam', 'InstallPath')].filter(Boolean)
  for (const steam of steams) {
    const libs = []
    for (const f of [join('steamapps', 'libraryfolders.vdf'), join('config', 'libraryfolders.vdf')])
      if (existsSync(join(steam, f))) libs.push(...librariesWithApp(readFileSync(join(steam, f), 'utf8'), app))
    libs.push(steam)
    for (const lib of libs) {
      const dir = ok(join(lib, 'steamapps', 'common', folder))
      if (dir) return dir
    }
  }
  return undefined
}
const XCOM2_APP = '268500'
const EU_APP = '200510' // XCOM: Enemy Unknown; Enemy Within (and Long War in it) is its XEW folder

/** The player's Documents folder (wherever Windows keeps it; LWX2_DOCS for tests). */
function documents() {
  return process.env.LWX2_DOCS ?? registry('HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders', 'Personal') ?? (process.env.USERPROFILE && join(process.env.USERPROFILE, 'Documents'))
}

const isMine = (l) => /^\s*ActiveMods\s*=\s*"?LongWarX2"?\s*$/i.test(l)

/**
 * The mod switched on (or off) in the game's list of active mods, as the Alternative Mod Launcher
 * does it (X2CommunityCore/xcom2-launcher, DefaultConfigFile): in My Games' XComModOptions.ini,
 * with its [IniVersion] stamp set to the modification time of the game folder's
 * DefaultModOptions.ini it is built from. When the stamp does not match, the game rebuilds the
 * file from the default at start and the active mods are gone (seen on the person's PC). The
 * game folder's file is not changed (an earlier build of this setup added the mod there: that
 * line is taken out again). The player's other mods stay as they are.
 */
function setActive(xcom2, on) {
  const base = join(xcom2, 'XComGame', 'Config', 'DefaultModOptions.ini')
  if (existsSync(base)) {
    const lines = readFileSync(base, 'utf8').split(/\r?\n/)
    if (lines.some(isMine)) writeFileSync(base, lines.filter((l) => !isMine(l)).join('\r\n'))
  }
  const docs = documents()
  if (!docs) return undefined
  const file = join(docs, 'My Games', 'XCOM2 War of the Chosen', 'XComGame', 'Config', 'XComModOptions.ini')
  const before = existsSync(file) ? readFileSync(file, 'utf8') : existsSync(base) ? readFileSync(base, 'utf8') : '[Engine.XComModOptions]'
  const lines = before.split(/\r?\n/).filter((l) => !isMine(l))
  if (on) {
    let at = lines.findIndex((l) => l.trim() === '[Engine.XComModOptions]')
    if (at < 0) {
      lines.unshift('[Engine.XComModOptions]', '')
      at = 0
    }
    lines.splice(at + 1, 0, `ActiveMods="${MOD}"`)
  }
  // The stamp: the last entry of [IniVersion] is the default file's time (whole seconds, as the game writes it).
  if (existsSync(base)) {
    const stamp = `${Math.floor(statSync(base).mtimeMs / 1000)}.000000`
    let sec = lines.findIndex((l) => l.trim() === '[IniVersion]')
    if (sec < 0) {
      while (lines.length && lines[lines.length - 1].trim() === '') lines.pop()
      lines.push('', '[IniVersion]', `0=${stamp}`)
    } else {
      let last = -1
      for (let i = sec + 1; i < lines.length && !lines[i].startsWith('['); i++) if (/^\d+=/.test(lines[i])) last = i
      if (last < 0) lines.splice(sec + 1, 0, `0=${stamp}`)
      else lines[last] = lines[last].replace(/=.*/, `=${stamp}`)
    }
  }
  mkdirSync(dirname(file), { recursive: true })
  if (existsSync(file) && !existsSync(`${file}.before-lwx2`)) writeFileSync(`${file}.before-lwx2`, before)
  writeFileSync(file, lines.join('\r\n'))
  return file
}

/**
 * Where the game looks for local mods: ModRootDirs in My Games' XComEngine.ini (mod launchers set
 * it: the Alternative Mod Launcher puts the base game's XCOM 2\XComGame\Mods there, seen on the
 * person's PC), else the game's DefaultEngine.ini (..\..\XComGame\Mods, War of the Chosen's own),
 * resolved from the game's Binaries\Win64; Steam's Workshop folders left out.
 */
function modRoots(xcom2) {
  const read = (file) => {
    if (!existsSync(file)) return []
    let inSection = false
    const dirs = []
    for (const line of readFileSync(file, 'utf8').split(/\r?\n/)) {
      if (line.startsWith('[')) inSection = line.trim() === '[Engine.DownloadableContentEnumerator]'
      else if (inSection) {
        const m = /^\s*[+]?ModRootDirs\s*=\s*(.+?)\s*$/i.exec(line)
        if (m) dirs.push(m[1].replace(/^"|"$/g, ''))
      }
    }
    return dirs
  }
  const docs = documents()
  let dirs = docs ? read(join(docs, 'My Games', 'XCOM2 War of the Chosen', 'XComGame', 'Config', 'XComEngine.ini')) : []
  if (!dirs.length) dirs = read(join(xcom2, 'XComGame', 'Config', 'DefaultEngine.ini'))
  const bin = join(xcom2, 'Binaries', 'Win64')
  const roots = dirs
    .map((d) => (/^([A-Za-z]:)?[\\/]/.test(d) ? d : join(bin, d)))
    .filter((d) => !/[\\/]workshop[\\/]/i.test(d))
  return roots.length ? roots : [join(xcom2, 'XComGame', 'Mods')]
}

async function main() {
  // The mod to install: beside this program (the download), or --mod.
  const here = process.execPath.toLowerCase().endsWith('node.exe') || process.execPath.endsWith('/node') ? process.cwd() : dirname(process.execPath)
  const source = opt('--mod') ?? join(here, MOD)
  const x2 = findSteamApp(XCOM2_APP, 'XCOM 2', 'XCom2-WarOfTheChosen')
  const xcom2 = opt('--xcom2') ?? (x2 && join(x2, 'XCom2-WarOfTheChosen'))
  if (!xcom2 || !existsSync(join(xcom2, 'XComGame'))) {
    say('XCOM 2: War of the Chosen was not found through Steam (its uninstall entry and library list). Give its folder with --xcom2 "<…\\XCOM 2\\XCom2-WarOfTheChosen>".')
    return 1
  }
  say(`XCOM 2: War of the Chosen: ${xcom2}`)
  // Into the first folder the game looks in for mods; a copy elsewhere (an earlier setup's) removed.
  const roots = modRoots(xcom2)
  const target = join(roots[0], MOD)
  const elsewhere = [...new Set([...roots.slice(1), join(xcom2, 'XComGame', 'Mods'), join(xcom2, '..', 'XComGame', 'Mods')].map((r) => join(r, MOD)))].filter(
    (p) => p.toLowerCase() !== target.toLowerCase() && existsSync(join(p, `${MOD}.XComMod`)),
  )

  if (flag('--uninstall')) {
    for (const p of [target, ...elsewhere]) if (existsSync(p)) {
      rmSync(p, { recursive: true, force: true })
      say(`Removed ${p}.`)
    }
    const file = setActive(xcom2, false)
    if (file) say(`Taken out of the game's active mods (${file}).`)
    return 0
  }

  if (!existsSync(join(source, `${MOD}.XComMod`))) {
    say(`The mod's folder (${source}) is not beside this program: unpack the whole download.`)
    return 1
  }
  if (source !== target) {
    // The Enemy Within content converted by an earlier setup is kept (the maps take minutes and many GB).
    const kept = join(dirname(target), `${MOD}.converted`)
    if (existsSync(join(target, 'Content'))) {
      rmSync(kept, { recursive: true, force: true })
      renameSync(join(target, 'Content'), kept)
    }
    rmSync(target, { recursive: true, force: true })
    mkdirSync(dirname(target), { recursive: true })
    cpSync(source, target, { recursive: true })
    if (existsSync(kept)) {
      rmSync(join(target, 'Content'), { recursive: true, force: true })
      renameSync(kept, join(target, 'Content'))
    }
    say(`Installed the mod: ${target}`)
  }
  for (const p of elsewhere) {
    rmSync(p, { recursive: true, force: true })
    say(`Removed an older copy the game would not use: ${p}`)
  }
  // Made active where the game takes its list from (2K's launcher is gone: Steam starts the game).
  say(`Enabled in the game's active mods: ${setActive(xcom2, true)}`)

  // Long War's words, from the player's Long War install.
  const eu = findSteamApp(EU_APP, 'XCom-Enemy-Unknown', 'XEW')
  const ew = opt('--ew') ?? (eu && join(eu, 'XEW'))
  const words = ew
    ? wordsFrom(ew, ...['XComLWResearch.ini', 'XComLWStrategy.ini', 'XComLWGear.ini', 'XComLWBase.ini'].map((n) => readFileSync(join(target, 'Config', n), 'utf8')))
    : { missing: 'XCOM: Enemy Within was not found' }
  if (words.missing) {
    say(`${words.missing}${ew ? ` (${ew})` : ''}: give its XEW folder with --ew. The classes and techs will show without Long War's names and words.`)
    return 0
  }
  mkdirSync(join(target, 'Localization'), { recursive: true })
  writeFileSync(join(target, 'Localization', 'XComGame.int'), words.text)
  say(`Long War's words written from ${ew}: ${words.report}.`)
  await convertEW(ew, target)
  say('')
  say('Next: start XCOM 2: War of the Chosen from Steam. (With a mod launcher such as the Alternative Mod Launcher, tick "Long War X2" there: it rewrites the list when it starts the game.)')
  return 0
}

/**
 * Enemy Within's content the mod uses, converted from the player's install into the mod's Content: its strategy
 * screens (ew-ui.ts) and the earth behind its Situation Room (ew-package.ts) always; its maps (ew-map.ts, one child
 * process of this program each, with a larger heap) when asked, and then the mod plays its missions on them.
 */
async function convertEW(ew, target) {
  const cooked = join(ew, 'XComGame', 'CookedPCConsole')
  const content = join(target, 'Content')
  mkdirSync(content, { recursive: true })
  try {
    say(`Enemy Within's strategy screens: ${convertUI(join(cooked, 'UICollection_Strategy_SF.upk'), join(content, 'EWStrategyUI.upk'))}`)
    say(`Enemy Within's earth: ${convertPackage(join(cooked, 'Static_SituationRoom.upk'), join(content, 'EWSitRoomMap.upk'))}`)
  } catch (e) {
    say(`Enemy Within's screens could not be converted (${e?.message ?? e}); XCOM 2's screens will show instead.`)
  }
  const maps = listedMaps(target).map((m) => m.name)
  let want = flag('--maps') ? true : flag('--no-maps') ? false : undefined
  if (want === undefined && process.stdin.isTTY) {
    const rl = createInterface({ input: process.stdin, output: process.stdout })
    const answer = await new Promise((done) =>
      rl.question(`\nConvert Enemy Within's maps for the missions (${new Set(maps).size} maps, about 18 GB, a few minutes; already converted ones are kept)? [y/N] `, (a) => done(rl.close() ?? a)),
    )
    want = /^y/i.test(String(answer).trim())
  }
  if (want) {
    convertMaps(cooked, target, maps, content, join(content, 'ewmaps'), (src, out, ini) =>
      execFileSync(process.execPath, ['--convert-map', src, out, ini], {
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'pipe'],
        env: { ...process.env, NODE_OPTIONS: '--max-old-space-size=12288' },
        windowsHide: true,
      }),
    false, say)
  }
  // The missions on Enemy Within's maps when this machine has them converted.
  const sections = existsSync(join(target, 'Config', 'XComLWX2EWMap.ini')) ? (readFileSync(join(target, 'Config', 'XComLWX2EWMap.ini'), 'latin1').match(/ LWX2EWMapData\]/g) ?? []).length : 0
  const air = join(target, 'Config', 'XComLWAirWar.ini')
  writeFileSync(air, readFileSync(air, 'utf8').replace(/^PlaceEWMapWhole=.*$/m, `PlaceEWMapWhole=${sections > 0}`))
  say(sections > 0 ? `Missions play on Enemy Within's maps (${sections} converted).` : "Missions play on XCOM 2's maps (Enemy Within's not converted: run this again with --maps).")
}

async function run() {
  // A child of this program converting one map (convertEW): its own heap, its own process.
  if (args[0] === '--convert-map') {
    convertMap(args[1], args[2], args[3])
    process.exit(0)
  }
  const code = await main().catch((e) => {
    say(`Failed: ${e?.stack ?? e}`)
    return 1
  })
  // Double-clicked, the window would close before the player reads it.
  if (!flag('--no-pause') && process.stdin.isTTY) {
    const rl = createInterface({ input: process.stdin, output: process.stdout })
    await new Promise((done) => rl.question('\nPress Enter to close.', () => done(rl.close())))
  }
  process.exit(code)
}
run()
