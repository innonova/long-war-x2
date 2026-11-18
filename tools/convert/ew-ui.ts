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
import { actionStrings, importsExports, swfOf, tagsOf } from './swf-as2.ts'
import { X2_UI_SYMBOLS } from './x2-ui-symbols.ts'

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
// has classes of the same names, loaded first; EW's movies then ran on XCOM 2's (its Container, XComList, Navigator …),
// which take other calls: EW's lists and submenus made no rows. So every class EW's movies compile in (their
// __Packages.<name> exports) gets a name of its own, the same length (first letter Q; Colors → EWClrs), in every movie
// alike: in the export and import tables (its symbol and registration) and in the ActionScript's strings (constant pools
// and pushed strings), each dotted segment that is such a name. EW's movies then run on EW's framework, whole.
// The symbols bound to those classes (Object.registerClass("VerticalScrollMC", VerticalAutoScrollText) in an init action)
// clash the same way: XCOM 2's movies bind symbols of the same names to their own classes, and that binding won, so an
// EW clip came up as XCOM 2's class and EW's casts to its own failed (the promotion screen's description stayed empty).
// So each EW symbol of a name XCOM 2's movies register (x2-ui-symbols.ts) gets a name of its own, by the same rule and in
// the same places. (Only those: Long War's movies register symbols of plain
// names, such as "Menu", whose other uses as strings would change with them.)
const BUILTINS = new Set(['Object', 'Function', 'Array', 'String', 'Number', 'Boolean', 'Math', 'Date', 'MovieClip', 'TextField',
  'TextFormat', 'Sound', 'Color', 'Key', 'Mouse', 'Stage', 'System', 'Selection', 'XML', 'XMLNode', 'LoadVars', 'LocalConnection',
  'SharedObject', 'Camera', 'Microphone', 'NetConnection', 'NetStream', 'Video', 'ContextMenu', 'ContextMenuItem', 'Error',
  'MovieClipLoader', 'PrintJob', 'TextSnapshot', 'Button', 'AsBroadcaster', 'ExternalInterface', 'BitmapData', 'Rectangle',
  'Point', 'Matrix', 'ColorTransform', 'Transform', 'Accessibility', 'CustomActions'])
const swfs: Uint8Array[] = []
for (const e of pkg.exports as { type: string; offset: number; size: number }[]) {
  if (e.type !== 'SwfMovie') continue
  const swf = swfOf(bytes.subarray(e.offset, e.offset + e.size))
  if (!swf || swf[0] !== 0x47) throw new Error('an EW movie not stored uncompressed')
  swfs.push(swf)
}
const classNames = new Set<string>()
for (const swf of swfs)
  for (const name of importsExports(tagsOf(swf)).exports)
    if (name.startsWith('__Packages.')) {
      const last = name.split('.').pop()!
      if (!BUILTINS.has(last)) classNames.add(last)
    }
// The symbols of the names XCOM 2 registers, wherever an export or import table names them (the same in every package
// converted: one imports another's, as the promotion screen its perk icons from XComIcons). A symbol whose name is also an instance's on a timeline (theScreen, imageContainer …: in a
// PlaceObject tag), which code and the mod's paths name, is renamed only where it is a symbol: the export and import
// tables and the registering init actions. The others everywhere (attachMovie names them in code too).
const symbols = new Set<string>()
const registers = (t: { code: number; body: Uint8Array }) => t.code === 59 && actionStrings(t.body, 2).includes('registerClass')
for (const swf of swfs) {
  const { imports, exports } = importsExports(tagsOf(swf))
  for (const n of [...exports, ...imports.flatMap((i) => i.names)]) if (X2_UI_SYMBOLS.has(n) && !classNames.has(n)) symbols.add(n)
}
const linkOnly = new Set<string>()
for (const swf of swfs)
  for (const t of tagsOf(swf))
    if (t.code === 26 || t.code === 70) {
      const text = Buffer.from(t.body).toString('latin1')
      for (const n of symbols) if (text.includes(n + '\0')) linkOnly.add(n)
    }
for (const n of symbols) classNames.add(n)
const renamed = new Map<string, string>()
for (const c of classNames) {
  const to = c === 'Colors' ? 'EWClrs' : (c[0] === 'Q' ? 'Z' : 'Q') + c.slice(1)
  if (classNames.has(to)) throw new Error(`renaming ${c} to ${to}: already a class`)
  renamed.set(c, to)
}
let classRefs = 0
/** A string in place (bytes [at, at + length)): each dotted segment that is a renamed class, renamed (a symbol that is also
 *  an instance's name only where it is a symbol: asSymbol). */
let asSymbol = true
const renameAt = (b: Uint8Array, at: number, length: number) => {
  let segStart = at
  for (let i = at; i <= at + length; i++) {
    if (i < at + length && b[i] !== 0x2e) continue
    const seg = Buffer.from(b.subarray(segStart, i)).toString('latin1')
    const to = renamed.get(seg)
    if (to && (asSymbol || !linkOnly.has(seg))) {
      b.set(Buffer.from(to, 'latin1'), segStart)
      classRefs++
    }
    segStart = i + 1
  }
}
const cstrEnd = (b: Uint8Array, o: number) => { let e = o; while (e < b.length && b[e] !== 0) e++; return e }
for (const swf of swfs) {
  for (const t of tagsOf(swf)) {
    const b = t.body
    asSymbol = t.code === 56 || t.code === 57 || t.code === 71 || registers(t)
    if (t.code === 56 || t.code === 57 || t.code === 71) {
      let o = 0
      if (t.code !== 56) { o = cstrEnd(b, 0) + 1; if (t.code === 71) o += 2 }
      const n = b[o]! | (b[o + 1]! << 8)
      o += 2
      for (let i = 0; i < n; i++) {
        o += 2
        const e = cstrEnd(b, o)
        renameAt(b, o, e - o)
        o = e + 1
      }
    } else if (t.code === 12 || t.code === 59) {
      // The actions, walked in order (functions' bodies are inline): constant pools' strings and pushed strings.
      let o = t.code === 59 ? 2 : 0
      while (o < b.length) {
        const op = b[o++]!
        if (op === 0) break
        if (op < 0x80) continue
        const len = b[o]! | (b[o + 1]! << 8)
        o += 2
        const end = o + len
        if (op === 0x88) {
          const n = b[o]! | (b[o + 1]! << 8)
          let p = o + 2
          for (let i = 0; i < n; i++) { const e = cstrEnd(b, p); renameAt(b, p, e - p); p = e + 1 }
        } else if (op === 0x96) {
          let p = o
          while (p < end) {
            const ty = b[p++]!
            if (ty === 0) { const e = cstrEnd(b, p); renameAt(b, p, e - p); p = e + 1 }
            else p += ({ 1: 4, 2: 0, 3: 0, 4: 1, 5: 1, 6: 8, 7: 4, 8: 1, 9: 2 } as Record<number, number>)[ty] ?? end - p
          }
        } else if (op === 0x8e || op === 0x9b) {
          // A function's header; its body follows as ordinary actions.
          o = end
          continue
        }
        o = end
      }
    }
  }
}
const tex = inlineTextures(bytes, pkg.exports, pkg.names, dirname(src), bytes.length)
const outBytes = new Uint8Array(bytes.length + tex.appended.length)
outBytes.set(bytes)
outBytes.set(tex.appended, bytes.length)
writeFileSync(out, outBytes)
return `${out}: ${outBytes.length} bytes; ${groups.length} groups renamed gfx → ewx, ${replaced} names in the movies, ${renamed.size} classes and their symbols renamed (${classRefs} references); ${tex.textures} textures rewritten (${tex.mips} mips)`
}

if (/ew-ui\.ts$/.test(process.argv[1] ?? '')) {
  const [src, out] = process.argv.slice(2).filter((a) => a !== '--')
  if (!out) {
    console.error('usage: ew-ui.ts <EW UI package .upk> <out .upk>')
    process.exit(2)
  }
  console.log(convertUI(src!, out!))
}

