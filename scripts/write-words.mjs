// Long War's words for the mod, from a Long War install (features/playable-build.md): the classes'
// names and perks (makeWords) and the techs' names and texts (makeTechWords), into the mod's
// Localization/XComGame.int. Long War's text: written on the player's machine (the setup program
// does the same), never committed.
//   node scripts/write-words.mjs <Long War's XEW folder> [<the mod's folder>]
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { decodeInt, makeTechWords, makeWords, readConsts } from './lw-words.mjs'
import plan from './words-plan.json' with { type: 'json' }

/** The words for an XEW folder, as { text, report }; undefined (with the reason) if Long War is not there. */
export function wordsFrom(ew, researchIni) {
  const file = (...p) => join(ew, 'XComGame', ...p)
  const core = file('Config', 'DefaultGameCore.ini')
  const loc = file('Localization', 'INT', 'XComGame.int')
  const strategyLoc = file('Localization', 'INT', 'XComStrategyGame.int')
  const upk = file('CookedPCConsole', 'XComGame.upk')
  if (!existsSync(core) || !existsSync(loc)) return { missing: 'XCOM: Enemy Within was not found' }
  const coreText = readFileSync(core, 'latin1')
  if (!/^SoldierPerkTrees=\(SoldierType=11,/m.test(coreText)) return { missing: 'Long War is not installed in this Enemy Within' }
  const consts = existsSync(upk) ? readConsts(new Uint8Array(readFileSync(upk))) : new Map()
  const words = makeWords({ plan, core: coreText, loc: decodeInt(readFileSync(loc)), consts })
  const techs = [...researchIni.matchAll(/^\+Techs=\(Id=(\d+), Enum=(\w+)/gm)].map((m) => ({ id: Number(m[1]), enum: m[2] }))
  const tech = existsSync(strategyLoc) ? makeTechWords({ strategyLoc: decodeInt(readFileSync(strategyLoc)), techs }) : { text: '', named: 0 }
  return {
    text: words.text + '\r\n' + tech.text,
    report: `${words.perks} perks, ${words.ranks} rank names${words.unfilled.length ? ` (${words.unfilled.length} numbers unknown)` : ''}, ${tech.named} techs`,
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const ew = process.argv[2]
  const mod = process.argv[3] ?? join(dirname(fileURLToPath(import.meta.url)), '..', 'LongWarX2')
  const w = wordsFrom(ew, readFileSync(join(mod, 'Config', 'XComLWResearch.ini'), 'utf8'))
  if (w.missing) {
    console.error(`${w.missing}: ${ew}`)
    process.exit(1)
  }
  mkdirSync(join(mod, 'Localization'), { recursive: true })
  writeFileSync(join(mod, 'Localization', 'XComGame.int'), w.text)
  console.log(`Long War's words written: ${w.report}`)
}
