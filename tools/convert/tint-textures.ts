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
const SKIN_WARMTH = [1.07, 0.98, 0.95]
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

/**
 * A hair mip: each texel's brightness × k in the colour hue (EW's hair material lightens the dark hairstyle texture to its
 * own colour: Vahlen's olive-blonde, 84 82 58 in EW's capture, where the texture's brown, brightened, read orange). DXT1 or
 * DXT5 (alpha, the strands' cut-out, kept).
 */
export function hairMip(mip: Uint8Array, format: string, k: number, colour: number[]): Uint8Array {
  const block = format === 'PF_DXT5' ? 16 : 8
  const blocks = mip.length / block
  const col = new Uint8Array(blocks * 8)
  for (let b = 0; b < blocks; b++) col.set(mip.subarray(block * b + block - 8, block * b + block), 8 * b)
  const rgba = decodeDXT1(col, 4, 4 * blocks)
  const cl = 0.299 * colour[0]! + 0.587 * colour[1]! + 0.114 * colour[2]!
  for (let p = 0; p < rgba.length; p += 4) {
    const l = (0.299 * rgba[p]! + 0.587 * rgba[p + 1]! + 0.114 * rgba[p + 2]!) * k
    for (let c = 0; c < 3; c++) rgba[p + c] = Math.min(255, Math.round((l * colour[c]!) / cl))
  }
  const enc = encodeDXT1(rgba, 4, 4 * blocks)
  if (block === 8) return enc
  const out = mip.slice()
  for (let b = 0; b < blocks; b++) out.set(enc.subarray(8 * b, 8 * b + 8), block * b + 8)
  return out
}

/**
 * EW's hologram earth (FX_Globe.T_Earth_Holo: land in its blue, about 128-200 against the sea's 32-64; borders in its red)
 * in EW's Situation Room wall colours, for the wall's 3D plane: sea dark teal, land bright cyan, borders near white
 * (sampled by eye from EW's capture; APPROXIMATION). DXT1 or DXT5 colour; converter 66.
 */
export function earthWallMip(mip: Uint8Array, format: string, w: number, h: number): Uint8Array {
  const block = format === 'PF_DXT5' ? 16 : 8
  const blocks = mip.length / block
  const col = new Uint8Array(blocks * 8)
  for (let b = 0; b < blocks; b++) col.set(mip.subarray(block * b + block - 8, block * b + block), 8 * b)
  const rgba = decodeDXT1(col, w, h)
  const sea = [28, 75, 82], land = [95, 190, 200], border = [210, 250, 255]
  for (let p = 0; p < rgba.length; p += 4) {
    const t = Math.max(0, Math.min(1, (rgba[p + 2]! - 70) / 80))
    const e = Math.max(0, Math.min(1, rgba[p]! / 160))
    for (let c = 0; c < 3; c++) {
      const base = sea[c]! + (land[c]! - sea[c]!) * t
      rgba[p + c] = Math.round(base + (border[c]! - base) * e)
    }
  }
  const enc = encodeDXT1(rgba, w, h)
  if (block === 8) return enc
  const out = mip.slice()
  for (let b = 0; b < blocks; b++) out.set(enc.subarray(8 * b, 8 * b + 8), block * b + 8)
  return out
}


/** EW's detail layer baked over its main layer (DXT1 both; converter 67, 69): the detail tiled `ratio` times across the
 *  main's w×h, each texel as EW's cave material computes its diffuse: (main × detail)^0.65 in linear light (HQ_Caves_Simple's
 *  compiled pixel shader, read with tools/convert/ew-shaders.ts), plus its specular colour, √(main × detail), at an average
 *  share (our stand-in has no specular input). EW's cave rock: Rock_Detail_A_DIF ×6 over Rock_A_DIF ×2. Not carried: the main layer's own rotation and offset
 *  (MainRotation, MainOffset_U/V), which a tiling texture cannot hold. */
/** The share of EW's specular colour folded into a baked detail layer (detailMip): measured on EW's hangar rock. */
const SPECULAR_SHARE = 1.7
export function detailMip(main: Uint8Array, w: number, h: number, detail: Uint8Array, dw: number, dh: number, ratio: number): Uint8Array {
  const m = decodeDXT1(main, w, h)
  const d = decodeDXT1(detail, dw, dh)
  const lin = (x: number) => { const c = x / 255; return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4 }
  const srgb = (c: number) => Math.round(255 * Math.min(1, c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055))
  const out = new Uint8Array(w * h * 4)
  for (let y = 0; y < h; y++)
    for (let x = 0; x < w; x++) {
      const p = 4 * (y * w + x)
      const dx = Math.floor(((x + 0.5) / w) * ratio * dw) % dw, dy = Math.floor(((y + 0.5) / h) * ratio * dh) % dh
      const q = 4 * (dy * dw + dx)
      // (EW's diffuse, (m·d)^0.65, and its specular colour, √(m·d), folded in at SPECULAR_SHARE: what its specular adds on
      // average where the cave is lit, measured against EW's hangar, since our stand-in has no specular input.)
      for (let c = 0; c < 3; c++) { const md = lin(m[p + c]!) * lin(d[q + c]!); out[p + c] = srgb(md ** 0.65 + SPECULAR_SHARE * Math.sqrt(md)) }
      out[p + 3] = 255
    }
  return encodeDXT1(out, w, h)
}

/** One of EW's custom screens' pictures (HQ_CustomScreens_B; converter 70): its decal sheet's blue channel through the
 *  screen's UV transform, UV = (UV0 + uv.xy) × uv.zw (its TintColor, as its compiled shader reads it), resampled so that
 *  the copy's 0..1 is the screen's region; grey, for our glow material to colour. The same size, DXT1 or DXT5 (the alpha
 *  left as it was); sampled from `from`, a larger mip of the same texture (fw × fh), so the small mips keep the detail. */
export function screenMip(mip: Uint8Array, format: string, w: number, h: number, uv: number[], from = mip, fw = w, fh = h): Uint8Array {
  const block = format === 'PF_DXT5' ? 16 : 8
  const colourOf = (m: Uint8Array) => {
    const n = m.length / block, col = new Uint8Array(n * 8)
    for (let b = 0; b < n; b++) col.set(m.subarray(block * b + block - 8, block * b + block), 8 * b)
    return col
  }
  // (uv[4]: the channel the picture is in, 2 blue (HQ_CustomScreens_B) or 3 alpha (_F, the DXT5 sheet's alpha), or 5 the
  // sum of red, green and blue (HQ_ConsoleScreen's static picture), or 6 red + green (the tanks' froth).)
  const channel = uv[4] ?? 2
  const src = channel === 3 && format === 'PF_DXT5' ? (() => { const a = decodeDXT5Alpha(from, fw, fh); const o = new Uint8Array(fw * fh * 4); for (let k = 0; k < fw * fh; k++) o[4 * k + 3] = a[k]!; return o })() : decodeDXT1(colourOf(from), fw, fh)
  const out = new Uint8Array(w * h * 4)
  const wrap = (x: number) => x - Math.floor(x)
  // (Each texel the mean of the source texels it covers: the source is larger, as the region magnifies the sheet.)
  const sx = Math.max(1, Math.round((fw / w) * Math.abs(uv[2]!))), sy = Math.max(1, Math.round((fh / h) * Math.abs(uv[3]!)))
  for (let y = 0; y < h; y++)
    for (let x = 0; x < w; x++) {
      const u = wrap((x / w + uv[0]!) * uv[2]!), v = wrap((y / h + uv[1]!) * uv[3]!)
      const x0 = Math.floor(u * fw), y0 = Math.floor(v * fh)
      let sum = 0
      for (let j = 0; j < sy; j++)
        for (let i = 0; i < sx; i++) {
          const q = 4 * (((y0 + j) % fh) * fw + ((x0 + i) % fw))
          sum += channel === 5 ? Math.min(255, src[q]! + src[q + 1]! + src[q + 2]!) : channel === 6 ? Math.min(255, src[q]! + src[q + 1]!) : src[q + channel]!
        }
      const b = Math.round(sum / (sx * sy))
      const p = 4 * (y * w + x)
      out[p] = out[p + 1] = out[p + 2] = b
      out[p + 3] = 255
    }
  const enc = encodeDXT1(out, w, h)
  if (block === 8) return enc
  const res = mip.slice()
  for (let b = 0; b < mip.length / block; b++) res.set(enc.subarray(8 * b, 8 * b + 8), block * b + 8)
  return res
}
