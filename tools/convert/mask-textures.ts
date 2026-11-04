// Masks for the cut-out stand-ins (features/lw-missions.md, 2026-11-04): XCOM 2's parents for cut-out surfaces read the
// opacity from a colour channel of their Masks texture (Props_OpcMask_TC: green, through StandardShader's "Mask G";
// Vegetations_VO: blue, "Mask B"), where EW's cut-out materials keep it in the diffuse's alpha. So beside each such
// diffuse the converted package gets a texture of its own, <name>_LWX2Mask: the same size, format and mips, its red
// white, its green and blue the diffuse's alpha (white is the parents' own value where a material has no mask).
//
// Two steps, so that the package is small while objects are added (each addition moves the whole file): the masks are
// added as copies of their diffuses (addMaskTextures, before inline-textures.ts), and their mips are made from the
// diffuse's as the textures are inlined (maskMip). DXT5 and DXT1.
import { Package } from '@innonova/upkit/upk'

/** The package with a copy of each texture (export references) added as its mask; the masks' references by texture. */
export function addMaskTextures(bytes: Uint8Array, textures: number[]): { bytes: Uint8Array; masks: Map<number, number> } {
  const pkg = new Package(bytes)
  const masks = new Map<number, number>()
  const view = () => new DataView(pkg.bytes.buffer, pkg.bytes.byteOffset, pkg.bytes.byteLength)
  const wanted = [...new Set(textures)].filter((ref) => pkg.exports[ref - 1]?.type === 'Texture2D')
  // The names first (each moves every offset after the name table), then the exports.
  for (const ref of wanted) {
    const name = maskName(pkg.exports[ref - 1]!.name)
    if (pkg.findName(name) >= 0) continue
    // The texture's own name entry's flags (its entry points at it: an export's name may carry a number, Leaves_2).
    const n = pkg.nameEntries[view().getInt32(pkg.exports[ref - 1]!.entryOffset + 12, true)]!
    pkg.addName(nameEntry(name, pkg.bytes.slice(n.offset + n.size - 8, n.offset + n.size)))
  }
  for (const ref of wanted) {
    const e = pkg.exports[ref - 1]!
    const data = pkg.exportData(ref).slice()
    const entry = pkg.bytes.slice(e.entryOffset, e.entryOffset + 68)
    const ev = new DataView(entry.buffer)
    ev.setInt32(12, pkg.findName(maskName(e.name)), true) // object name
    ev.setInt32(16, 0, true) // its number
    ev.setInt32(32, data.length, true) // serial size
    ev.setInt32(36, 0, true) // serial offset (the end of the file)
    ev.setInt32(44, 0, true) // no net objects
    const added = pkg.addExport(entry)
    const x = pkg.exports[added - 1]!
    // The diffuse's data as it is (its mips are read from where it says, by inline-textures.ts), with its own net index.
    new DataView(data.buffer).setInt32(0, view().getInt32(x.offset, true), true)
    pkg.write(x.offset, data)
    masks.set(ref, added)
  }
  return { bytes: pkg.bytes, masks }
}

/** A mask's name: its texture's (with the number it may carry) and _LWX2Mask. */
export const maskName = (texture: string) => `${texture}_LWX2Mask`

/** A name table entry: the string (its length with the NUL, the characters, the NUL) and its flags. */
function nameEntry(name: string, flags: Uint8Array): Uint8Array {
  const b = new Uint8Array(4 + name.length + 1 + 8)
  new DataView(b.buffer).setInt32(0, name.length + 1, true)
  b.set(new TextEncoder().encode(name), 4)
  b.set(flags, 4 + name.length + 1)
  return b
}

/** A mip of a mask, from its diffuse's (a copy: the source may be shared); unchanged in other formats than DXT5 and DXT1. */
export function maskMip(format: string, mip: Uint8Array): Uint8Array {
  const block = format === 'PF_DXT5' ? 16 : format === 'PF_DXT1' ? 8 : 0
  const out = mip.slice()
  if (!block) return out
  const v = new DataView(out.buffer)
  for (let p = 0; p + block <= out.length; p += block) (block === 16 ? maskDXT5 : maskDXT1)(out, v, p)
  return out
}

/** A colour block (8 bytes at p) holding the 16 values as (255, a, a), each texel the nearest of its four colours. */
function writeColour(v: DataView, p: number, alphas: number[]) {
  let hi = 0
  let lo = 255
  for (const a of alphas) {
    if (a > hi) hi = a
    if (a < lo) lo = a
  }
  const c = (a: number) => (31 << 11) | (Math.round(a * 63 / 255) << 5) | Math.round(a * 31 / 255)
  const c0 = c(hi)
  const c1 = c(lo)
  v.setUint16(p, c0, true)
  v.setUint16(p + 2, c1, true)
  if (c0 === c1) {
    // One value: every texel colour 0 (whichever the mode).
    v.setUint32(p + 4, 0, true)
    return
  }
  // Four-colour mode (c0 > c1): index 0 = hi, 2 = (2 hi + lo) / 3, 3 = (hi + 2 lo) / 3, 1 = lo.
  const step = (hi - lo) / 3
  const INDEX = [0, 2, 3, 1] // steps down from hi
  let idx = 0
  for (let i = 0; i < 16; i++) idx |= INDEX[Math.round((hi - alphas[i]!) / step)]! << (2 * i)
  v.setUint32(p + 4, idx >>> 0, true)
}

const alphas = new Array<number>(16)
const levels = new Array<number>(8)

/** DXT5: the alpha block kept (the alpha stays the alpha), the colour block made from it. */
function maskDXT5(b: Uint8Array, v: DataView, p: number) {
  const a0 = b[p]!
  const a1 = b[p + 1]!
  levels[0] = a0
  levels[1] = a1
  if (a0 > a1) for (let i = 1; i <= 6; i++) levels[i + 1] = ((7 - i) * a0 + i * a1) / 7
  else {
    for (let i = 1; i <= 4; i++) levels[i + 1] = ((5 - i) * a0 + i * a1) / 5
    levels[6] = 0
    levels[7] = 255
  }
  // 48 bits of 3-bit indices, in two 24-bit halves.
  const lo = b[p + 2]! | (b[p + 3]! << 8) | (b[p + 4]! << 16)
  const hi = b[p + 5]! | (b[p + 6]! << 8) | (b[p + 7]! << 16)
  for (let i = 0; i < 8; i++) alphas[i] = levels[(lo >> (3 * i)) & 7]!
  for (let i = 0; i < 8; i++) alphas[i + 8] = levels[(hi >> (3 * i)) & 7]!
  writeColour(v, p + 8, alphas)
}

/** DXT1: a texel is cut out where the block is in three-colour mode (c0 <= c1) and its index is 3. */
function maskDXT1(_b: Uint8Array, v: DataView, p: number) {
  const threeColour = v.getUint16(p, true) <= v.getUint16(p + 2, true)
  const idx = v.getUint32(p + 4, true)
  for (let i = 0; i < 16; i++) alphas[i] = threeColour && ((idx >>> (2 * i)) & 3) === 3 ? 0 : 255
  writeColour(v, p, alphas)
}
