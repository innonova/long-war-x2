// EW's baked lighting in one texture (features/ew-lightmaps.md). EW keeps a 2D lightmap as two DXT1 atlases:
// NormalizedAverageColor (the light's colour) and DirectionalMaxComponent (its intensity along three directions, one per
// channel), each times a scale per mesh. Our material (LongWarX2/Content/LWX2Lightmap.upk) takes one: the colour atlas's
// mips are rewritten as colour × the mean of the three directional channels (what a surface facing straight out of its
// face receives, the three weighing alike), and the scales become one brightness per piece at run time
// (LWX2EWMapPieces.Lightmapped).

/** A DXT1 image decoded to RGBA. */
export function decodeDXT1(data: Uint8Array, w: number, h: number): Uint8Array {
  const out = new Uint8Array(w * h * 4)
  const bw = Math.max(1, Math.ceil(w / 4))
  const bh = Math.max(1, Math.ceil(h / 4))
  const v = new DataView(data.buffer, data.byteOffset, data.byteLength)
  const pal = new Uint8Array(16)
  const rgb = (c: number, k: number) => {
    pal[k] = ((c >> 11) & 31) * 255 / 31
    pal[k + 1] = ((c >> 5) & 63) * 255 / 63
    pal[k + 2] = (c & 31) * 255 / 31
    pal[k + 3] = 255
  }
  for (let by = 0; by < bh; by++) {
    for (let bx = 0; bx < bw; bx++) {
      const p = 8 * (by * bw + bx)
      if (p + 8 > data.length) continue
      const c0 = v.getUint16(p, true)
      const c1 = v.getUint16(p + 2, true)
      rgb(c0, 0)
      rgb(c1, 4)
      for (let k = 0; k < 3; k++) {
        if (c0 > c1) {
          pal[8 + k] = (2 * pal[k]! + pal[4 + k]!) / 3
          pal[12 + k] = (pal[k]! + 2 * pal[4 + k]!) / 3
        } else {
          pal[8 + k] = (pal[k]! + pal[4 + k]!) / 2
          pal[12 + k] = 0
        }
      }
      pal[11] = 255
      pal[15] = c0 > c1 ? 255 : 0
      const idx = v.getUint32(p + 4, true)
      for (let i = 0; i < 16; i++) {
        const x = 4 * bx + (i & 3)
        const y = 4 * by + (i >> 2)
        if (x >= w || y >= h) continue
        const s = 4 * ((idx >>> (2 * i)) & 3)
        out.set(pal.subarray(s, s + 4), 4 * (y * w + x))
      }
    }
  }
  return out
}

/** RGBA encoded as DXT1 (four colours a block, the block's darkest and brightest corners as its ends). */
export function encodeDXT1(rgba: Uint8Array, w: number, h: number): Uint8Array {
  const bw = Math.max(1, Math.ceil(w / 4))
  const bh = Math.max(1, Math.ceil(h / 4))
  const out = new Uint8Array(8 * bw * bh)
  const v = new DataView(out.buffer)
  const px = new Array<number>(48)
  const to565 = (r: number, g: number, b: number) => (Math.round(r * 31 / 255) << 11) | (Math.round(g * 63 / 255) << 5) | Math.round(b * 31 / 255)
  const from565 = (c: number) => [((c >> 11) & 31) * 255 / 31, ((c >> 5) & 63) * 255 / 63, (c & 31) * 255 / 31]
  for (let by = 0; by < bh; by++) {
    for (let bx = 0; bx < bw; bx++) {
      const lo = [255, 255, 255]
      const hi = [0, 0, 0]
      for (let i = 0; i < 16; i++) {
        const x = Math.min(w - 1, 4 * bx + (i & 3))
        const y = Math.min(h - 1, 4 * by + (i >> 2))
        for (let k = 0; k < 3; k++) {
          const c = rgba[4 * (y * w + x) + k]!
          px[3 * i + k] = c
          if (c < lo[k]!) lo[k] = c
          if (c > hi[k]!) hi[k] = c
        }
      }
      let c0 = to565(hi[0]!, hi[1]!, hi[2]!)
      let c1 = to565(lo[0]!, lo[1]!, lo[2]!)
      const p = 8 * (by * bw + bx)
      if (c0 === c1) {
        v.setUint16(p, c0, true)
        v.setUint16(p + 2, c1, true)
        continue
      }
      if (c0 < c1) [c0, c1] = [c1, c0]
      const a = from565(c0)
      const b = from565(c1)
      const pal = [a, b, a.map((x, k) => (2 * x + b[k]!) / 3), a.map((x, k) => (x + 2 * b[k]!) / 3)]
      let idx = 0
      for (let i = 0; i < 16; i++) {
        let best = 0
        let bestD = Infinity
        for (let j = 0; j < 4; j++) {
          const d = (px[3 * i]! - pal[j]![0]!) ** 2 + (px[3 * i + 1]! - pal[j]![1]!) ** 2 + (px[3 * i + 2]! - pal[j]![2]!) ** 2
          if (d < bestD) {
            bestD = d
            best = j
          }
        }
        idx |= best << (2 * i)
      }
      v.setUint16(p, c0, true)
      v.setUint16(p + 2, c1, true)
      v.setUint32(p + 4, idx >>> 0, true)
    }
  }
  return out
}

/** The side of a square DXT1 mip of this many bytes (EW's lightmap atlases are square). */
export function dxt1Side(bytes: number): number {
  return Math.max(1, Math.round(Math.sqrt(bytes * 2)))
}

/** A colour atlas's mip combined with the directional atlas's mip of the same size: colour × mean of the directions. */
export function combineLightmapMip(color: Uint8Array, dir: Uint8Array): Uint8Array {
  const side = dxt1Side(color.length)
  if (dir.length !== color.length || side < 4) return color
  const c = decodeDXT1(color, side, side)
  const d = decodeDXT1(dir, side, side)
  for (let i = 0; i < side * side; i++) {
    const k = (d[4 * i]! + d[4 * i + 1]! + d[4 * i + 2]!) / (3 * 255)
    for (let j = 0; j < 3; j++) c[4 * i + j] = Math.round(c[4 * i + j]! * k)
  }
  return encodeDXT1(c, side, side)
}
