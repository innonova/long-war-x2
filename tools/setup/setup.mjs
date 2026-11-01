// The player's setup program (features/playable-build.md): installs the mod into XCOM 2: War of
// the Chosen and writes Long War's words for it from the player's own Long War install.
//
//   LongWarX2-setup.exe                  install (or update) the mod beside this program, write the words
//   LongWarX2-setup.exe --uninstall      remove the mod
//   options: --xcom2 <War of the Chosen folder> --ew <Enemy Within's XEW folder> --no-pause
//
// Bundled with upkit into one Windows program (tools/setup/bundle.mjs); runs from the repository
// too: node tools/setup/setup.mjs --mod LongWarX2 …
import { cpSync, existsSync, readFileSync, rmSync, writeFileSync, mkdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { createInterface } from 'node:readline'
import { execFileSync } from 'node:child_process'
import { makeWords, readConsts } from '../../scripts/lw-words.mjs'
import plan from '../../scripts/words-plan.json' with { type: 'json' }

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

/** The game's list of active mods (it reads it at start; the launchers write it): the player's Documents, wherever they are. */
function modOptionsFile() {
  const docs = [
    registry('HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders', 'Personal'),
    process.env.USERPROFILE && join(process.env.USERPROFILE, 'Documents'),
  ].filter(Boolean)
  return docs.map((d) => join(d, 'My Games', 'XCOM2 War of the Chosen', 'XComGame', 'Config', 'XComModOptions.ini')).find((p) => existsSync(p))
}

/** The mod made active (on) or taken out (off) in the game's list; the player's other mods kept, the file's own sections too. */
function setActive(on) {
  const file = modOptionsFile()
  if (!file) return undefined
  const lines = readFileSync(file, 'utf8').split(/\r?\n/)
  const mine = `ActiveMods="${MOD}"`
  const kept = lines.filter((l) => l.trim() !== mine)
  if (on) {
    const at = kept.findIndex((l) => l.trim() === '[Engine.XComModOptions]')
    if (at < 0) kept.unshift('[Engine.XComModOptions]', mine)
    else kept.splice(at + 1, 0, mine)
  }
  if (!existsSync(`${file}.before-lwx2`)) writeFileSync(`${file}.before-lwx2`, lines.join('\r\n'))
  writeFileSync(file, kept.join('\r\n'))
  return file
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
  const target = join(xcom2, 'XComGame', 'Mods', MOD)
  say(`XCOM 2: War of the Chosen: ${xcom2}`)

  if (flag('--uninstall')) {
    rmSync(target, { recursive: true, force: true })
    say(`Removed ${target}.`)
    const file = setActive(false)
    if (file) say(`Taken out of the game's active mods (${file}).`)
    return 0
  }

  if (!existsSync(join(source, `${MOD}.XComMod`))) {
    say(`The mod's folder (${source}) is not beside this program: unpack the whole download.`)
    return 1
  }
  if (source !== target) {
    rmSync(target, { recursive: true, force: true })
    mkdirSync(dirname(target), { recursive: true })
    cpSync(source, target, { recursive: true })
    say(`Installed the mod: ${target}`)
  }
  // Made active in the game's own list: since 2K's launcher was removed, Steam starts the game
  // directly, and the game loads the mods listed there.
  const options = setActive(true)
  if (options) say(`Enabled in the game's active mods: ${options}`)
  else say("The game's list of active mods (My Games\\XCOM2 War of the Chosen\\XComGame\\Config\\XComModOptions.ini) was not found: start War of the Chosen once, quit, and run this again.")

  // Long War's words, from the player's Long War install.
  const eu = findSteamApp(EU_APP, 'XCom-Enemy-Unknown', 'XEW')
  const ew = opt('--ew') ?? (eu && join(eu, 'XEW'))
  const core = ew && join(ew, 'XComGame', 'Config', 'DefaultGameCore.ini')
  const loc = ew && join(ew, 'XComGame', 'Localization', 'INT', 'XComGame.int')
  const upk = ew && join(ew, 'XComGame', 'CookedPCConsole', 'XComGame.upk')
  if (!ew || !existsSync(core) || !existsSync(loc)) {
    say('XCOM: Enemy Within was not found (give its XEW folder with --ew). The classes will show without their names and words.')
    return 0
  }
  const coreText = readFileSync(core, 'latin1')
  if (!/^SoldierPerkTrees=\(SoldierType=11,/m.test(coreText)) {
    say(`Enemy Within at ${ew} does not have Long War installed: the classes' names and words come from Long War's files, so they are left out.`)
    return 0
  }
  const consts = existsSync(upk) ? readConsts(new Uint8Array(readFileSync(upk))) : new Map()
  const words = makeWords({ plan, core: coreText, loc: readFileSync(loc, 'latin1'), consts })
  mkdirSync(join(target, 'Localization'), { recursive: true })
  writeFileSync(join(target, 'Localization', 'XComGame.int'), words.text)
  say(`Long War's words written from ${ew}: ${words.perks} perks, ${words.ranks} rank names${words.unfilled.length ? ` (${words.unfilled.length} numbers unknown)` : ''}.`)
  say('')
  say('Next: start XCOM 2: War of the Chosen from Steam. (With a mod launcher such as the Alternative Mod Launcher, tick "Long War X2" there: it rewrites the list when it starts the game.)')
  return 0
}

async function run() {
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
