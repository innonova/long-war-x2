// An Enemy Within UI package (its Flash screens: UICollection_Strategy_SF.upk …) made loadable by XCOM 2 beside its
// own, from the player's own install. Both games use Scaleform with ActionScript 2 movies (EW's are Flash 8, XCOM 2's
// Flash 9), and both name a screen's movie gfx<Screen>.<Screen>; several names are the same in both games
// (gfxChooseFacility, gfxComponents …). So every gfx<Name> group becomes ewx<Name> (the same length: nothing moves),
// in the package's name table and inside each movie, where the imports name their libraries by path
// (../gfxComponents/components.swf). Fonts (gfxfontlib) stay XCOM 2's. The textures are rewritten uncompressed into the
// package, as for EW's other packages (inline-textures.ts).
//   node tools/convert/ew-ui.ts <EW UICollection_*_SF.upk> <out .upk>
// The movies are then at "/ package/ewx<Screen>/<Screen>" for a UIScreen's Package, once the package is loaded.
import { readFileSync, writeFileSync } from 'node:fs'
import { dirname } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { inlineTextures } from './inline-textures.ts'

const [src, out] = process.argv.slice(2).filter((a) => a !== '--')
if (!out) {
  console.error('usage: ew-ui.ts <EW UI package .upk> <out .upk>')
  process.exit(2)
}
const bytes = decompressPackage(new Uint8Array(readFileSync(src)))
const pkg = new Package(bytes)
const latin1 = new TextDecoder('latin1')
const groups: string[] = []
for (const e of pkg.nameEntries as { name: string; offset: number }[]) {
  if (!e.name.startsWith('gfx') || e.name === 'gfxfontlib') continue
  const at = e.offset + 4
  if (latin1.decode(bytes.subarray(at, at + e.name.length)) !== e.name) throw new Error(`name ${e.name} is not where it was read`)
  bytes.set(new TextEncoder().encode('ewx'), at)
  groups.push(e.name)
}
// Inside the movies: each group's name wherever it appears (import paths, image names), case-insensitively, as the
// movies write paths in either case. Only whole names: the next character is not a letter or digit.
const lower = groups.map((g) => g.toLowerCase())
let replaced = 0
for (const e of pkg.exports as { type: string; offset: number; size: number }[]) {
  if (e.type !== 'SwfMovie') continue
  const body = bytes.subarray(e.offset, e.offset + e.size)
  const text = latin1.decode(body).toLowerCase()
  lower.forEach((g) => {
    let i = 0
    while ((i = text.indexOf(g, i)) >= 0) {
      const next = text.charCodeAt(i + g.length)
      if (!(next >= 48 && next <= 57) && !(next >= 97 && next <= 122)) {
        body.set(new TextEncoder().encode(body[i] === 0x47 ? 'EWX' : 'ewx'), i)
        replaced++
      }
      i += g.length
    }
  })
}
const tex = inlineTextures(bytes, pkg.exports, pkg.names, dirname(src), bytes.length)
const outBytes = new Uint8Array(bytes.length + tex.appended.length)
outBytes.set(bytes)
outBytes.set(tex.appended, bytes.length)
writeFileSync(out, outBytes)
console.log(`${out}: ${outBytes.length} bytes; ${groups.length} groups renamed gfx → ewx, ${replaced} names in the movies; ${tex.textures} textures rewritten (${tex.mips} mips)`)
