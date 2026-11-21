// EW's textures rewritten so XCOM 2 reads their pixels (features/hard-parts.md, experiment 2).
// EW stores a texture's mips LZO-compressed, most of them in a texture cache (.tfc); XCOM 2
// reads the same records but not EW's compression (its own packages use another), and draws
// noise. So every Texture2D gets new data: its properties as they were, then each mip
// uncompressed and inline (in the package, no cache: its name cleared), then the rest as it was. The new data
// is appended to the package and the export pointed at it (its old data stays, unused).
//
// The layout is the one the Long War Tech Tree reads (src/model/texture.ts): the net index,
// the tagged properties up to "None", the source art and the mips as bulk data (flags,
// element count, size on disk, offset in file, the bytes when inline), each mip with its
// width and height.
import { readFileSync } from 'node:fs'
import { unchunk } from '@innonova/upkit/lzo'

const BULK_SEPARATE = 0x01
const BULK_LZO = 0x10
const BULK_UNUSED = 0x20

interface Export { type: string; fullName: string; offset: number; size: number; entryOffset: number }

/**
 * The textures' new data, to be appended at `base` (the package's current length); the
 * export entries are changed to point at it. Returns the bytes to append.
 */
export function inlineTextures(
  bytes: Uint8Array,
  exports: Export[],
  names: string[],
  cacheDir: string,
  base: number,
  skip: (e: Export) => boolean = () => false,
  /** A texture's mips made otherwise (by its pixel format), as they are written: the masks (mask-textures.ts). */
  transform?: (e: Export, format: string, mip: Uint8Array, width: number, height: number) => Uint8Array | undefined,
  /** Bytes left off the end of a texture's data (a LightMapTexture2D made a Texture2D: its lightmap flags). */
  trimEnd: (e: Export) => number = () => 0,
  /** Bytes added at the end of each texture's data (a package made with the UDK, licensee 0: XCOM's own two fields after
   *  the cache's GUID and the mobile mips, which every XCOM texture has as 1 and 0; without them XCOM 2 read past the
   *  texture: "Serial size mismatch", Long War's LongWar.upk). */
  padEnd?: Uint8Array,
  /** Linear, not sRGB (a tagged SRGB=False added before the properties' end): EW's light-map atlases made Texture2D, whose
   *  class default is sRGB, where EW's LightMapTexture2D is linear. */
  linear: (e: Export) => boolean = () => false,
): { appended: Uint8Array; textures: number; mips: number } {
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  const caches = new Map<string, Uint8Array>()
  const cache = (name: string) => {
    if (!caches.has(name)) caches.set(name, new Uint8Array(readFileSync(`${cacheDir}/${name}.tfc`)))
    return caches.get(name)!
  }
  const none = names.indexOf('None')
  const parts: Uint8Array[] = []
  let at = base
  let textures = 0
  let mipCount = 0
  for (const e of exports) {
    // (EW's lightmap atlases too, LightMapTexture2D: a Texture2D with its flags after, kept with the rest.)
    if ((e.type !== 'Texture2D' && e.type !== 'LightMapTexture2D') || skip(e)) continue
    let o = e.offset + 4 // net index
    let cacheName = ''
    let cacheAt = -1
    let format = ''
    // Tagged properties: name, type, size, array index, then the value.
    for (;;) {
      const n = v.getInt32(o, true)
      if (n === none) {
        o += 8
        break
      }
      const type = names[v.getInt32(o + 8, true)]
      const size = v.getInt32(o + 16, true)
      o += 24
      if (type === 'StructProperty' || type === 'ByteProperty') o += 8
      if (type === 'BoolProperty') {
        o += 1
        continue
      }
      if (names[n] === 'Format' && type === 'ByteProperty') format = names[v.getInt32(o, true)]!
      if (names[n] === 'TextureFileCacheName' && type === 'NameProperty') {
        cacheName = names[v.getInt32(o, true)]!
        cacheAt = o
      }
      o += size
    }
    let hasSRGB = false
    {
      let q = e.offset + 4
      for (;;) {
        const n2 = v.getInt32(q, true)
        if (n2 === none) break
        const type2 = names[v.getInt32(q + 8, true)]
        const size2 = v.getInt32(q + 16, true)
        if (names[n2] === 'SRGB') hasSRGB = true
        q += 24 + (type2 === 'StructProperty' || type2 === 'ByteProperty' ? 8 : 0) + (type2 === 'BoolProperty' ? 1 : size2)
      }
    }
    const srgb = names.indexOf('SRGB'), boolType = names.indexOf('BoolProperty')
    const chunks: Uint8Array[] = linear(e) && !hasSRGB && srgb >= 0 && boolType >= 0
      ? [bytes.subarray(e.offset, o - 8), (() => {
          // (name, its number; type, its number; size 0; array index 0; the bool's one byte, false.)
          const b = new Uint8Array(25); const d = new DataView(b.buffer)
          d.setInt32(0, srgb, true); d.setInt32(8, boolType, true)
          return b
        })(), bytes.subarray(o - 8, o)]
      : [bytes.subarray(e.offset, o)]
    let len = chunks.reduce((s, c) => s + c.length, 0)
    const push = (b: Uint8Array) => {
      chunks.push(b)
      len += b.length
    }
    const i32s = (...xs: number[]) => {
      const b = new Uint8Array(4 * xs.length)
      const d = new DataView(b.buffer)
      xs.forEach((x, k) => d.setInt32(4 * k, x, true))
      return b
    }
    /** One bulk record read at o: its bytes, uncompressed (undefined when not stored). */
    const bulk = () => {
      const flags = v.getUint32(o, true)
      const count = v.getInt32(o + 4, true)
      const sizeOnDisk = v.getInt32(o + 8, true)
      const offset = v.getInt32(o + 12, true)
      o += 16
      if (flags & BULK_UNUSED || count === 0) return undefined
      let raw: Uint8Array
      if (flags & BULK_SEPARATE) raw = cache(cacheName).subarray(offset, offset + sizeOnDisk)
      else {
        raw = bytes.subarray(o, o + sizeOnDisk)
        o += sizeOnDisk
      }
      return flags & BULK_LZO ? unchunk(raw, count) : raw
    }
    /** A bulk record written inline, uncompressed (or as not stored). */
    const writeBulk = (data: Uint8Array | undefined) => {
      if (!data) return push(i32s(BULK_UNUSED, 0, 0, -1))
      push(i32s(0, data.length, data.length, at + len + 16))
      push(data)
    }
    writeBulk(bulk()) // source art (none in cooked packages)
    const n = v.getInt32(o, true)
    o += 4
    push(i32s(n))
    for (let k = 0; k < n; k++) {
      const read = bulk()
      const w = v.getInt32(o, true)
      const h = v.getInt32(o + 4, true)
      const data = read && transform ? (transform(e, format, read, w, h) ?? read) : read
      o += 8
      writeBulk(data)
      push(i32s(w, h))
      if (data) mipCount++
    }
    push(bytes.subarray(o, e.offset + e.size - trimEnd(e))) // the rest (the cache's GUID …) as it was
    if (padEnd) push(padEnd)
    const blob = new Uint8Array(len)
    let p = 0
    for (const c of chunks) {
      blob.set(c, p)
      p += c.length
    }
    // No texture cache any more: else XCOM 2 streams the large mips from it, at these offsets.
    if (cacheAt >= 0) new DataView(blob.buffer).setBigInt64(cacheAt - e.offset, BigInt(none), true)
    v.setInt32(e.entryOffset + 32, blob.length, true) // serial size
    v.setInt32(e.entryOffset + 36, at, true) // serial offset
    parts.push(blob)
    at += blob.length
    textures++
  }
  const appended = new Uint8Array(at - base)
  let p = 0
  for (const b of parts) {
    appended.set(b, p)
    p += b.length
  }
  return { appended, textures, mips: mipCount }
}
