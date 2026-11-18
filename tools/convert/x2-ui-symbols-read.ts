// For development (features/strategy-flow.md): the symbols XCOM 2's own Flash movies bind to classes
// (Object.registerClass("<symbol>", <class>) in an init action), read from the War of the Chosen SDK's uncooked UI
// packages (every gfx*.upk under its XComGame/Content; the game's cooked ones use a compression upkit does not read),
// written as tools/convert/x2-ui-symbols.ts. Names only. EW's movies bind symbols of some of the same names to their own
// classes, and XCOM 2's binding wins; ew-ui.ts gives those EW symbols names of their own. The player's machine has no
// SDK: the list ships with the converter.
//
//   node tools/convert/x2-ui-symbols-read.ts <the SDK's XComGame/Content> > tools/convert/x2-ui-symbols.ts
import { readdirSync, statSync } from 'node:fs'
import { join } from 'node:path'
import { actionStrings, importsExports, movies, tagsOf } from './swf-as2.ts'

const dir = process.argv.slice(2).find((a) => a !== '--')
if (!dir) {
  console.error('usage: x2-ui-symbols-read.ts <the SDK\'s XComGame/Content>')
  process.exit(2)
}
const names = new Set<string>()
let read = 0
const files: string[] = []
const walk = (d: string) => {
  for (const f of readdirSync(d).sort()) {
    const p = join(d, f)
    if (statSync(p).isDirectory()) walk(p)
    else if (/^gfx.*\.upk$/i.test(f)) files.push(p)
  }
}
walk(dir)
for (const f of files) {
  let list: { name: string; swf: Uint8Array }[]
  try {
    list = movies(f)
  } catch (e) {
    console.error(`${f}: ${(e as Error).message}`)
    continue
  }
  for (const m of list) {
    read++
    const tags = tagsOf(m.swf)
    const exported = new Set(importsExports(tags).exports.filter((n) => !n.startsWith('__Packages.')))
    for (const t of tags) {
      if (t.code !== 59) continue
      const strings = actionStrings(t.body, 2)
      if (strings.includes('registerClass')) for (const n of strings) if (exported.has(n)) names.add(n)
    }
  }
}
console.error(`${read} movies, ${names.size} symbols bound to classes`)
console.log(`// The symbols XCOM 2's own movies bind to classes (from War of the Chosen by x2-ui-symbols-read.ts; names only). Generated: do not edit.
export const X2_UI_SYMBOLS = new Set<string>(${JSON.stringify([...names].sort())})`)
