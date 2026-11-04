// Masks for the cut-out stand-ins (features/lw-missions.md, 2026-11-04): XCOM 2's parents for cut-out surfaces read the
// opacity from a colour channel of their Masks texture (Props_OpcMask_TC: green, through StandardShader's "Mask G";
// Vegetations_VO: blue, "Mask B"), where EW's cut-out materials keep it in the diffuse's alpha. So beside each such
// diffuse the converted package gets a texture of its own, <name>_LWX2Mask: the same size, format and mips, its red
// white, its green and blue the diffuse's alpha (white is the parents' own value where a material has no mask).
// Works on a converted package (mips inline and uncompressed: inline-textures.ts); DXT5 and DXT1 diffuses.
import { Package } from '@innonova/upkit/upk'

const BULK_UNUSED = 0x20

/** The package with a mask added for each of the textures (export references); the masks' names by texture reference. */
export function addMaskTextures(bytes: Uint8Array, textures: number[]): { bytes: Uint8Array; masks: Map<number, string> } {
  let pkg = new Package(bytes)
  const masks = new Map<number, string>()
  const made: { ref: number; data: Uint8Array; bulks: number[] }[] = []
  for (const ref of new Set(textures)) {
    const e = pkg.exports[ref - 1]
    if (!e || e.type !== 'Texture2D') continue
    const m = maskData(pkg, ref)
    if (!m) continue
    made.push({ ref, ...m })
    masks.set(ref, `${e.name}_LWX2Mask`)
  }
  // The names first (each moves every offset after the name table), then the exports.
  const flagsOf = (ref: number) => {
    // The name its entry points at (an export's name may carry a number: Leaves_2 is Leaves, number 3).
    const n = pkg.nameEntries[new DataView(pkg.bytes.buffer, pkg.bytes.byteOffset).getInt32(pkg.exports[ref - 1]!.entryOffset + 12, true)]!
    return pkg.bytes.slice(n.offset + n.size - 8, n.offset + n.size)
  }
  for (const m of made) if (pkg.findName(masks.get(m.ref)!) < 0) pkg.addName(nameEntry(masks.get(m.ref)!, flagsOf(m.ref)))
  for (const m of made) {
    const e = pkg.exports[m.ref - 1]!
    const entry = pkg.bytes.slice(e.entryOffset, e.entryOffset + 68)
    const ev = new DataView(entry.buffer)
    ev.setInt32(12, pkg.findName(masks.get(m.ref)!), true) // object name
    ev.setInt32(16, 0, true) // its number
    ev.setInt32(32, m.data.length, true) // serial size
    ev.setInt32(36, 0, true) // serial offset (the end of the file)
    ev.setInt32(44, 0, true) // no net objects
    const added = pkg.addExport(entry)
    const x = pkg.exports[added - 1]!
    const data = m.data.slice()
    const dv = new DataView(data.buffer)
    dv.setInt32(0, new DataView(pkg.bytes.buffer, pkg.bytes.byteOffset).getInt32(x.offset, true), true) // its net index
    for (const at of m.bulks) dv.setInt32(at + 12, x.offset + at + 16, true) // inline bulk data: its offset in the file
    pkg.write(x.offset, data)
    pkg = new Package(pkg.bytes)
  }
  return { bytes: pkg.bytes, masks }
}

/** A name table entry: the string (its length with the NUL, the characters, the NUL) and its flags (the texture's own). */
function nameEntry(name: string, flags: Uint8Array): Uint8Array {
  const b = new Uint8Array(4 + name.length + 1 + 8)
  new DataView(b.buffer).setInt32(0, name.length + 1, true)
  b.set(new TextEncoder().encode(name), 4)
  b.set(flags, 4 + name.length + 1)
  return b
}

/** The mask's data (a copy of the texture's, its mips' blocks rewritten) and where its bulk records are; none if the
 *  format has no alpha to carry or a mip is not inline. */
function maskData(pkg: Package, ref: number): { data: Uint8Array; bulks: number[] } | undefined {
  const data = pkg.exportData(ref).slice()
  const v = new DataView(data.buffer)
  const none = pkg.findName('None')
  let o = 4
  let format = ''
  for (;;) {
    const n = v.getInt32(o, true)
    if (n === none) {
      o += 8
      break
    }
    const type = pkg.names[v.getInt32(o + 8, true)]
    const size = v.getInt32(o + 16, true)
    o += 24
    if (type === 'StructProperty' || type === 'ByteProperty') o += 8
    if (type === 'BoolProperty') {
      o += 1
      continue
    }
    if (pkg.names[n] === 'Format') format = pkg.names[v.getInt32(o, true)]!
    o += size
  }
  const block = format === 'PF_DXT5' ? 16 : format === 'PF_DXT1' ? 8 : 0
  if (!block) return undefined
  const bulks: number[] = []
  const bulk = () => {
    const at = o
    const flags = v.getUint32(o, true)
    const count = v.getInt32(o + 4, true)
    const size = v.getInt32(o + 8, true)
    o += 16
    if (flags & BULK_UNUSED || count === 0) return true
    if (flags & ~BULK_UNUSED & 0x11) return false // compressed or in a cache: not converted
    bulks.push(at)
    for (let p = o; p + block <= o + size; p += block) (block === 16 ? maskDXT5 : maskDXT1)(data, v, p)
    o += size
    return true
  }
  if (!bulk()) return undefined // source art
  const mips = v.getInt32(o, true)
  o += 4
  for (let k = 0; k < mips; k++) {
    if (!bulk()) return undefined
    o += 8 // width, height
  }
  return { data, bulks }
}

/** A colour block (8 bytes at p) holding the 16 values as (255, a, a), nearest of its four colours. */
function writeColour(v: DataView, p: number, alphas: number[]) {
  const hi = Math.max(...alphas)
  const lo = Math.min(...alphas)
  const c = (a: number) => (31 << 11) | (Math.round(a * 63 / 255) << 5) | Math.round(a * 31 / 255)
  let c0 = c(hi)
  let c1 = c(lo)
  if (c0 === c1) {
    // One value: every texel colour 0 (whichever the mode).
    v.setUint16(p, c0, true)
    v.setUint16(p + 2, c1, true)
    v.setUint32(p + 4, 0, true)
    return
  }
  // Four-colour mode (c0 > c1): 0 = hi, 1 = lo, 2 = 2/3 hi, 3 = 1/3 hi.
  const levels = [hi, lo, (2 * hi + lo) / 3, (hi + 2 * lo) / 3]
  let idx = 0
  alphas.forEach((a, i) => {
    let best = 0
    for (let k = 1; k < 4; k++) if (Math.abs(levels[k]! - a) < Math.abs(levels[best]! - a)) best = k
    idx |= best << (2 * i)
  })
  v.setUint16(p, c0, true)
  v.setUint16(p + 2, c1, true)
  v.setUint32(p + 4, idx >>> 0, true)
}

/** DXT5: the alpha block kept (the alpha stays the alpha), the colour block made from it. */
function maskDXT5(b: Uint8Array, v: DataView, p: number) {
  const a0 = b[p]!
  const a1 = b[p + 1]!
  const av = a0 > a1 ? [a0, a1, ...[1, 2, 3, 4, 5, 6].map((i) => ((7 - i) * a0 + i * a1) / 7)] : [a0, a1, ...[1, 2, 3, 4].map((i) => ((5 - i) * a0 + i * a1) / 5), 0, 255]
  let bits = 0n
  for (let i = 0; i < 6; i++) bits |= BigInt(b[p + 2 + i]!) << BigInt(8 * i)
  const alphas = Array.from({ length: 16 }, (_, i) => av[Number((bits >> BigInt(3 * i)) & 7n)]!)
  writeColour(v, p + 8, alphas)
}

/** DXT1: a texel is cut out where the block is in three-colour mode (c0 <= c1) and its index is 3. */
function maskDXT1(_b: Uint8Array, v: DataView, p: number) {
  const threeColour = v.getUint16(p, true) <= v.getUint16(p + 2, true)
  const idx = v.getUint32(p + 4, true)
  const alphas = Array.from({ length: 16 }, (_, i) => (threeColour && ((idx >>> (2 * i)) & 3) === 3 ? 0 : 255))
  writeColour(v, p, alphas)
}
