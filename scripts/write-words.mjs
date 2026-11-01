// Long War's words for the mod, from a Long War install (features/playable-build.md): the classes'
// names and perks (makeWords), the techs' names and texts (makeTechWords) and the artifacts'
// (makeItemWords), into the mod's
// Localization/XComGame.int. Long War's text: written on the player's machine (the setup program
// does the same), never committed.
//   node scripts/write-words.mjs <Long War's XEW folder> [<the mod's folder>]
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { decodeInt, makeItemWords, makeTechWords, makeWeaponWords, makeWords, readConsts } from './lw-words.mjs'
import plan from './words-plan.json' with { type: 'json' }

/** The words for an XEW folder, as { text, report }; undefined (with the reason) if Long War is not there. */
export function wordsFrom(ew, researchIni, strategyIni = '', gearIni = '') {
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
  const strategyText = existsSync(strategyLoc) ? decodeInt(readFileSync(strategyLoc)) : ''
  const tech = strategyText ? makeTechWords({ strategyLoc: strategyText, techs }) : { text: '', named: 0 }
  // The corpses, and every item research asks for.
  const corpses = [
    ...new Set([
      ...[...strategyIni.matchAll(/^\+Species=\(.*?Corpse=(\w+)/gm)].map((m) => m[1]),
      ...[...researchIni.matchAll(/EverHad=(\w+)/g)].map((m) => m[1]),
      ...[...researchIni.matchAll(/InStores=\(([^)]*)\)/g)].flatMap((m) => m[1].split(',')),
    ]),
  ].filter((n) => !['Alloys', 'Elerium'].includes(n))
  const items = makeItemWords({ loc: decodeInt(readFileSync(loc)), strategyLoc: strategyText, more: corpses })
  const gear = makeWeaponWords({
    loc: decodeInt(readFileSync(loc)),
    strategyLoc: strategyText,
    weapons: [...gearIni.matchAll(/^\+Weapons=\(Item=(\d+), Enum=(\w+), Family=(\w+), Tier=(\w+), Damage=(-?\d+), Crit=(-?\d+), Aim=(-?\d+), Ammo=(\d+)/gm)].map((m) => ({
      item: Number(m[1]), enum: m[2], family: m[3], tier: m[4], damage: Number(m[5]), crit: Number(m[6]), aim: Number(m[7]), ammo: Number(m[8]),
    })),
  })
  return {
    text: words.text + '\r\n' + tech.text + '\r\n' + items.text + '\r\n' + gear.text,
    report: `${words.perks} perks, ${words.ranks} rank names${words.unfilled.length ? ` (${words.unfilled.length} numbers unknown)` : ''}, ${tech.named} techs, ${items.named} artifacts and corpses, ${gear.named} weapons`,
  }
}

// Run as a script (not when the setup program's bundle imports it: there import.meta.url is not a file URL).
const self = (() => {
  try {
    return fileURLToPath(import.meta.url)
  } catch {
    return ''
  }
})()
if (self && process.argv[1] === self) {
  const ew = process.argv[2]
  const mod = process.argv[3] ?? join(dirname(fileURLToPath(import.meta.url)), '..', 'LongWarX2')
  const cfg = (n) => readFileSync(join(mod, 'Config', n), 'utf8')
  const w = wordsFrom(ew, cfg('XComLWResearch.ini'), cfg('XComLWStrategy.ini'), cfg('XComLWGear.ini'))
  if (w.missing) {
    console.error(`${w.missing}: ${ew}`)
    process.exit(1)
  }
  mkdirSync(join(mod, 'Localization'), { recursive: true })
  writeFileSync(join(mod, 'Localization', 'XComGame.int'), w.text)
  console.log(`Long War's words written: ${w.report}`)
}
