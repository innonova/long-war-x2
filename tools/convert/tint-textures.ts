// EW's people's colour mods (features/ew-base-people.md): EW's character parent (CHH_Soldiers) recolours the part of a body
// its Spc_Ems_Ref_Opc texture's alpha marks (a clerk's uniform, a lab coat) with the instance's CMOD colour; the same body
// is dark green in engineering and light grey in the labs. XCOM 2's stand-in for EW's people takes a diffuse only, so the
// converted package gets a tinted copy of the diffuse per colour mod (<diffuse>_LWX2Tint<n>, added by addTextureCopies, its
// mips made as the textures are inlined by tintMip): where the mask is, the mod's colour shaded by the diffuse's own
// brightness against its mean there (APPROXIMATION: EW's exact blend is in its compiled shader; this keeps the folds and
// seams and gives the part EW's colour).
import { decodeDXT1, encodeDXT1 } from './lightmap-bake.ts'

/** The alpha of a DXT5 image, one byte a texel. */
export function decodeDXT5Alpha(data: Uint8Array, w: number, h: number): Uint8Array {
  const out = new Uint8Array(w * h)
  const bw = Math.max(1, Math.ceil(w / 4))
  const levels = new Array<number>(8)
  for (let by = 0; by < Math.ceil(h / 4); by++)
    for (let bx = 0; bx < bw; bx++) {
      const p = 16 * (by * bw + bx)
      if (p + 16 > data.length) continue
      const a0 = data[p]!
      const a1 = data[p + 1]!
      levels[0] = a0
      levels[1] = a1
      if (a0 > a1) for (let i = 1; i <= 6; i++) levels[i + 1] = ((7 - i) * a0 + i * a1) / 7
      else {
        for (let i = 1; i <= 4; i++) levels[i + 1] = ((5 - i) * a0 + i * a1) / 5
        levels[6] = 0
        levels[7] = 255
      }
      // 48 bits of 3-bit indices, little-endian.
      let bits = 0n
      for (let k = 0; k < 6; k++) bits |= BigInt(data[p + 2 + k]!) << BigInt(8 * k)
      for (let i = 0; i < 16; i++) {
        const x = 4 * bx + (i % 4)
        const y = 4 * by + Math.floor(i / 4)
        if (x < w && y < h) out[y * w + x] = Math.round(levels[Number((bits >> BigInt(3 * i)) & 7n)]!)
      }
    }
  return out
}

/** A tinted mip: the diffuse's (DXT1) recoloured with Tint (0-1 RGB) where the mask (DXT5, its alpha) is, the same size. */
const SKIN_WARMTH = [1.15, 0.95, 0.9]
function tintMipDXT1(diffuse: Uint8Array, mask: Uint8Array, w: number, h: number, tint: number[], bright = 1, channel: 'alpha' | 'blue' = 'alpha', linear = false, multiply = false, mw = w, mh = h): Uint8Array {
  // (multiply: the texture × the tint in linear light, as EW's skin material colours a face by its SkinColor; else the
  // tint replaces the colour, shaded by the texture's brightness, as for a uniform's or a car's paint.)
  const toLinear = (v: number) => (v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4))
  // (linear: the tint a linear colour, as EW's vehicles' TintColor is, made sRGB: the store's red SUV, 0.49 0.08 0.08,
  // draws 171 82 68 in EW, its sRGB 186 79 79. The people's ×2 below stands in for that, by eye.)
  const srgb = (c: number) => (c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055)
  const rgba = decodeDXT1(diffuse, w, h)
  // (The mask in a DXT5's alpha (people's Spc_Ems_Ref_Opc), or in a DXT1's blue (vehicles' Spc_Ems_Mod_Ref: its "Mod").)
  // (A blue mask from a DXT1, or from a DXT5's colour blocks: twice the DXT1's size, the colour in each block's second half.)
  const colourOf = (m: Uint8Array) => {
    const dxt1 = 8 * Math.max(1, Math.ceil(mw / 4)) * Math.max(1, Math.ceil(mh / 4))
    if (m.length !== 2 * dxt1) return m
    const c = new Uint8Array(dxt1)
    for (let b = 0; b < dxt1 / 8; b++) c.set(m.subarray(16 * b + 8, 16 * b + 16), 8 * b)
    return c
  }
  // (The mask at its own size, sampled at the diffuse's: Vahlen's skin mask is smaller than her face's texture, and the
  // face's larger mips had been left untinted, green-grey.)
  const am = channel === 'blue' ? (() => { const c = decodeDXT1(colourOf(mask), mw, mh); return Uint8Array.from({ length: mw * mh }, (_, k) => c[4 * k + 2]!) })() : decodeDXT5Alpha(mask, mw, mh)
  const a = mw === w && mh === h ? am : Uint8Array.from({ length: w * h }, (_, k) => am[Math.min(mh - 1, Math.floor(((Math.floor(k / w) + 0.5) * mh) / h)) * mw + Math.min(mw - 1, Math.floor((((k % w) + 0.5) * mw) / w))]!)
  const lum = (k: number) => (0.299 * rgba[4 * k]! + 0.587 * rgba[4 * k + 1]! + 0.114 * rgba[4 * k + 2]!) / 255
  let sum = 0
  let weight = 0
  for (let k = 0; k < w * h; k++) {
    sum += lum(k) * a[k]!
    weight += a[k]!
  }
  const mean = weight > 0 ? sum / weight : 1
  for (let k = 0; k < w * h; k++) {
    const m = a[k]! / 255
    // (The part the mask leaves, brightened as EW's people draw: bright.)
    if (m <= 0) {
      if (bright !== 1) for (let c = 0; c < 3; c++) rgba[4 * k + c] = Math.min(255, Math.round(rgba[4 * k + c]! * bright))
      continue
    }
    const shade = Math.min(2, mean > 0 ? lum(k) / mean : 1)
    for (let c = 0; c < 3; c++) {
      // (× 2: EW's labs' grey colour mod, 0.48, draws the vests near white in EW's captures; APPROXIMATION.)
      const t = multiply
        // (× SKIN_WARMTH: EW's skin material's subsurface red, which ours has not; Shen's face read yellow, red/green 1.06
        // against EW's 1.32. APPROXIMATION, by eye and that ratio.)
        ? Math.min(255, 255 * srgb(Math.min(1, toLinear(rgba[4 * k + c]! / 255) * tint[c]! * bright * bright * SKIN_WARMTH[c]!)))
        : Math.min(255, linear ? 255 * srgb(tint[c]!) * shade : 255 * 2 * tint[c]! * shade)
      rgba[4 * k + c] = Math.round(Math.min(255, rgba[4 * k + c]! * bright) * (1 - m) + t * m)
    }
  }
  return encodeDXT1(rgba, w, h)
}

/** tintMipDXT1 on a DXT1 mip, or on a DXT5's colour blocks with its alpha kept (Vahlen's face is DXT5: untinted, it drew
 *  raw, dark with cyan patches). */
export function tintMip(diffuse: Uint8Array, mask: Uint8Array, w: number, h: number, tint: number[], bright = 1, channel: 'alpha' | 'blue' = 'alpha', linear = false, multiply = false, mw = w, mh = h): Uint8Array {
  const dxt1 = 8 * Math.max(1, Math.ceil(w / 4)) * Math.max(1, Math.ceil(h / 4))
  if (diffuse.length !== 2 * dxt1) return tintMipDXT1(diffuse, mask, w, h, tint, bright, channel, linear, multiply, mw, mh)
  const colour = new Uint8Array(dxt1)
  for (let b = 0; b < dxt1 / 8; b++) colour.set(diffuse.subarray(16 * b + 8, 16 * b + 16), 8 * b)
  const done = tintMipDXT1(colour, mask, w, h, tint, bright, channel, linear, multiply, mw, mh)
  const out = diffuse.slice()
  for (let b = 0; b < dxt1 / 8; b++) out.set(done.subarray(8 * b, 8 * b + 8), 16 * b + 8)
  return out
}

/** A mip brightened by a factor (DXT1 or DXT5, the same size): its colour decoded, scaled and encoded again, the alpha
 *  as it was. EW's hair and people. (Scaling the blocks' endpoints in place clamped bright ones equal, which turned DXT1
 *  blocks into their three-colour mode with black for its last index: black squares on Vahlen's coat and cheek.) */
export function scaleMip(mip: Uint8Array, format: string, k: number): Uint8Array {
  const block = format === 'PF_DXT5' ? 16 : 8
  const w = 4, blocks = mip.length / block
  // (Decoded as a strip of blocks, one block wide: each block on its own, the layout does not matter.)
  const colour = new Uint8Array(blocks * 8)
  for (let b = 0; b < blocks; b++) colour.set(mip.subarray(block * b + block - 8, block * b + block), 8 * b)
  const rgba = decodeDXT1(colour, w, 4 * blocks)
  // (Each texel's hue kept: where its brightest channel would pass 255, all three scaled by as much as that one can take.
  // Clipped channel by channel, skin's red saturated first and the people drew yellow-green; converter 53.)
  for (let p = 0; p < rgba.length; p += 4) {
    const m = Math.max(rgba[p]!, rgba[p + 1]!, rgba[p + 2]!)
    const kk = m > 0 ? Math.min(k, 255 / m) : k
    for (let c = 0; c < 3; c++) rgba[p + c] = Math.min(255, Math.round(rgba[p + c]! * kk))
  }
  const enc = encodeDXT1(rgba, w, 4 * blocks)
  if (block === 8) return enc
  const out = mip.slice()
  for (let b = 0; b < blocks; b++) out.set(enc.subarray(8 * b, 8 * b + 8), block * b + 8)
  return out
}

/** A mip made white where it has any colour (DXT1 or DXT5, the same size): each texel's brightest channel in all three.
 *  EW's console screens (HQscreens_test): a sheet of UI panels drawn in its green channel, accents in red and blue, which
 *  EW's material tints; tinted as a picture by ours, it came out green. */
export function whiteMip(mip: Uint8Array, format: string, w: number, h: number): Uint8Array {
  const block = format === 'PF_DXT5' ? 16 : 8
  const colour = new Uint8Array((mip.length / block) * 8)
  for (let b = 0; b < mip.length / block; b++) colour.set(mip.subarray(block * b + block - 8, block * b + block), 8 * b)
  const rgba = decodeDXT1(colour, w, h)
  for (let k = 0; k < w * h; k++) {
    const m = Math.max(rgba[4 * k]!, rgba[4 * k + 1]!, rgba[4 * k + 2]!)
    rgba[4 * k] = m
    rgba[4 * k + 1] = m
    rgba[4 * k + 2] = m
  }
  const enc = encodeDXT1(rgba, w, h)
  if (block === 8) return enc
  const out = mip.slice()
  for (let b = 0; b < mip.length / block; b++) out.set(enc.subarray(8 * b, 8 * b + 8), block * b + 8)
  return out
}
