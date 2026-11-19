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
export function tintMip(diffuse: Uint8Array, mask: Uint8Array, w: number, h: number, tint: number[]): Uint8Array {
  const rgba = decodeDXT1(diffuse, w, h)
  const a = decodeDXT5Alpha(mask, w, h)
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
    if (m <= 0) continue
    const shade = Math.min(2, mean > 0 ? lum(k) / mean : 1)
    for (let c = 0; c < 3; c++) {
      const t = Math.min(255, 255 * tint[c]! * shade)
      rgba[4 * k + c] = Math.round(rgba[4 * k + c]! * (1 - m) + t * m)
    }
  }
  return encodeDXT1(rgba, w, h)
}
