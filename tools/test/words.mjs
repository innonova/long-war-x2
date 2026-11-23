// Long War's words written again into the mod installed on the test machine, as the setup writes them (scripts/write-words.mjs),
// for a development build whose words have changed (a new word the setup will write for players): run on the test machine
// from the checkout. The words are written there only, from that machine's Long War install (nothing into the repository).
//   node tools/test/words.mjs [<mod folder>] [<EW's XEW folder>]
import { readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { wordsFrom } from '../../scripts/write-words.mjs'

const mod = process.argv[2] ?? 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\XCOM 2\\XCom2-WarOfTheChosen\\XcomGame\\Mods\\LongWarX2'
const ew = process.argv[3] ?? 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\XCom-Enemy-Unknown\\XEW'
const words = wordsFrom(ew, ...['XComLWResearch.ini', 'XComLWStrategy.ini', 'XComLWGear.ini', 'XComLWBase.ini', 'XComLWSHIVs.ini', 'XComLWMECs.ini'].map((n) => readFileSync(join(mod, 'Config', n), 'utf8')))
if (words.missing) { console.log(words.missing); process.exit(1) }
writeFileSync(join(mod, 'Localization', 'XComGame.int'), words.text)
writeFileSync(join(mod, 'Localization', 'LongWarX2.int'), words.modText)
console.log(`words written: ${words.report}`)
