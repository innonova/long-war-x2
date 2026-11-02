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

/** An EW UI package converted to out; returns its report. */
export function convertUI(src: string, out: string): string {
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
// ActionScript 2 classes are global and the first definition of a name wins. XCOM 2's Flash framework grew from EW's and
// has classes of the same names, loaded first; where they differ, EW's movies get XCOM 2's. EW's Colors (its panic and
// state colours) is renamed in EW's movies, as a whole name in their string tables, to EWClrs (the same length).
const CLASSES: [string, string][] = [['Colors', 'EWClrs']]
let classNames = 0
for (const e of pkg.exports as { type: string; offset: number; size: number }[]) {
  if (e.type !== 'SwfMovie') continue
  const body = bytes.subarray(e.offset, e.offset + e.size)
  for (const [from, to] of CLASSES) {
    for (const before of [0x00, 0x2e]) {
      const needle = Buffer.from([before, ...Buffer.from(from, 'latin1'), 0x00])
      let i = 0
      const view = Buffer.from(body.buffer, body.byteOffset, body.byteLength)
      while ((i = view.indexOf(needle, i)) >= 0) {
        body.set(Buffer.from(to, 'latin1'), i + 1)
        classNames++
        i += needle.length - 1
      }
    }
  }
}
const tex = inlineTextures(bytes, pkg.exports, pkg.names, dirname(src), bytes.length)
const outBytes = new Uint8Array(bytes.length + tex.appended.length)
outBytes.set(bytes)
outBytes.set(tex.appended, bytes.length)
writeFileSync(out, outBytes)
return `${out}: ${outBytes.length} bytes; ${groups.length} groups renamed gfx → ewx, ${replaced} names in the movies, ${classNames} class names; ${tex.textures} textures rewritten (${tex.mips} mips)`
}

if (/ew-ui\.ts$/.test(process.argv[1] ?? '')) {
  const [src, out] = process.argv.slice(2).filter((a) => a !== '--')
  if (!out) {
    console.error('usage: ew-ui.ts <EW UI package .upk> <out .upk>')
    process.exit(2)
  }
  console.log(convertUI(src!, out!))
}

