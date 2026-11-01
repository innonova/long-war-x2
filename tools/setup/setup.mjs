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

/** Steam's library folders: the default install and those listed in libraryfolders.vdf. */
function steamLibraries() {
  const roots = ['C:\\Program Files (x86)\\Steam', 'C:\\Program Files\\Steam']
  const libs = new Set()
  for (const root of roots) {
    const vdf = join(root, 'steamapps', 'libraryfolders.vdf')
    if (!existsSync(vdf)) continue
    libs.add(root)
    for (const m of readFileSync(vdf, 'utf8').matchAll(/"path"\s+"([^"]+)"/g)) libs.add(m[1].replace(/\\\\/g, '\\'))
  }
  return [...libs]
}
const inLibraries = (...rel) => steamLibraries().map((lib) => join(lib, 'steamapps', 'common', ...rel)).find((p) => existsSync(p))

async function main() {
  // The mod to install: beside this program (the download), or --mod.
  const here = process.execPath.toLowerCase().endsWith('node.exe') || process.execPath.endsWith('/node') ? process.cwd() : dirname(process.execPath)
  const source = opt('--mod') ?? join(here, MOD)
  const xcom2 = opt('--xcom2') ?? inLibraries('XCOM 2', 'XCom2-WarOfTheChosen')
  if (!xcom2 || !existsSync(join(xcom2, 'XComGame'))) {
    say('XCOM 2: War of the Chosen was not found in the Steam libraries. Give its folder with --xcom2 "<…\\XCOM 2\\XCom2-WarOfTheChosen>".')
    return 1
  }
  const target = join(xcom2, 'XComGame', 'Mods', MOD)
  say(`XCOM 2: War of the Chosen: ${xcom2}`)

  if (flag('--uninstall')) {
    rmSync(target, { recursive: true, force: true })
    say(`Removed ${target}.`)
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

  // Long War's words, from the player's Long War install.
  const ew = opt('--ew') ?? inLibraries('XCom-Enemy-Unknown', 'XEW')
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
  say('Next: start XCOM 2 with the launcher, enable "Long War X2" in its mod list, and play War of the Chosen.')
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
