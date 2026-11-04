// EW's Situation Room earth in EW's colours (features/lw-ew-screens.md): the hologram texture (FX_Globe.T_Earth_Holo) holds
// the borders in red, the city lights in green and the land in blue (sea grey); EW's material makes the teal map from
// them. XCOM 2's Flash cannot run that material, so the texture itself is made teal, once, on the player's machine, in
// the converted package (ew-package.ts: its mips uncompressed and inline). The colour is an affine function of the
// channels, fitted to EW's own Situation Room as seen (sea about (16,62,64), land about (45,105,110), borders lighter)
// through XCOM 2's Flash, which draws a texture's values as linear (gamma 2.2: the fit is to the seen colours' 1/2.2
// power); so it is applied to each DXT1 block's two endpoint colours and holds for the colours between them. In place.
//
//   node tools/convert/ew-earth.ts <converted EWSitRoomMap.upk>
import { readFileSync, writeFileSync } from 'node:fs'
import { Package } from '@innonova/upkit/upk'

/** out = M · (r, g, b) + c, each 0-255: rows for out red, green, blue; columns for in red (borders), green (lights), blue (land). */
const M = [
  [0.3, 0.05, 0.38],
  [0.27, 0.06, 0.32],
  [0.26, 0.06, 0.33],
]
const C = [48, 113, 115]

const to565 = (r: number, g: number, b: number) =>
  (Math.round(Math.min(255, Math.max(0, r)) * 31 / 255) << 11) | (Math.round(Math.min(255, Math.max(0, g)) * 63 / 255) << 5) | Math.round(Math.min(255, Math.max(0, b)) * 31 / 255)
const from565 = (c: number) => [((c >> 11) & 31) * 255 / 31, ((c >> 5) & 63) * 255 / 63, (c & 31) * 255 / 31]
const map = (c: number) => {
  const [r, g, b] = from565(c) as [number, number, number]
  return to565(...([0, 1, 2].map((k) => M[k]![0]! * r + M[k]![1]! * g + M[k]![2]! * b + C[k]!) as [number, number, number]))
}

/** The earth texture's mips in the package recoloured, in place; returns how many blocks. */
export function tealEarth(bytes: Uint8Array): number {
  const meta: any = new Package(bytes)
  const names: string[] = meta.names.map((n: any) => String(n.name ?? n))
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  const e = meta.exports.find((x: any) => x.type === 'Texture2D' && x.fullName === 'FX_Globe.T_Earth_Holo')
  if (!e) throw new Error('no FX_Globe.T_Earth_Holo')
  const none = names.indexOf('None')
  let o = e.offset + 4
  let format = ''
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
    if (names[n] === 'Format') format = names[v.getInt32(o, true)]!
    o += size
  }
  if (format !== 'PF_DXT1') throw new Error(`the earth is ${format}, not DXT1`)
  /** A bulk record: its inline bytes' offset and length (the converted package stores mips inline, uncompressed). */
  const bulk = () => {
    const flags = v.getUint32(o, true)
    const count = v.getInt32(o + 4, true)
    const size = v.getInt32(o + 8, true)
    o += 16
    if (flags & 0x20 || count === 0) return undefined
    if (flags & 0x11) throw new Error('the earth\'s mips are not inline and uncompressed (convert the package first)')
    const at = o
    o += size
    return { at, size }
  }
  bulk() // source art
  const mips = v.getInt32(o, true)
  o += 4
  let blocks = 0
  for (let k = 0; k < mips; k++) {
    const b = bulk()
    o += 8 // width, height
    if (!b) continue
    for (let p = b.at; p + 8 <= b.at + b.size; p += 8) {
      const c0 = v.getUint16(p, true)
      const c1 = v.getUint16(p + 2, true)
      let n0 = map(c0)
      let n1 = map(c1)
      // DXT1's mode is c0 > c1 (four colours) or not (three and transparent): kept as it was. Where the new endpoints
      // compare the other way they are swapped and the indices remapped; equal ones in four-colour mode are nudged apart.
      if (c0 > c1 && n0 === n1) n0 = n0 < 0xffff ? n0 + 1 : n0, n1 = n0 === n1 ? n1 - 1 : n1
      else if ((c0 > c1) !== (n0 > n1) && n0 !== n1) {
        ;[n0, n1] = [n1, n0]
        swapIndices(v, p + 4, c0 > c1)
      }
      v.setUint16(p, n0, true)
      v.setUint16(p + 2, n1, true)
      blocks++
    }
  }
  return blocks
}

/** The endpoints swapped: each 2-bit index changed to address the same colour (0 and 1 swap; in four-colour mode 2 and 3
 *  swap; in three-colour mode 2, the midpoint, and 3, transparent, stay). */
function swapIndices(v: DataView, at: number, fourColours: boolean) {
  const idx = v.getUint32(at, true)
  let out = 0
  for (let i = 0; i < 16; i++) {
    let x = (idx >>> (2 * i)) & 3
    if (x < 2) x ^= 1
    else if (fourColours) x ^= 1
    out |= x << (2 * i)
  }
  v.setUint32(at, out >>> 0, true)
}

if (/ew-earth\.ts$/.test(process.argv[1] ?? '')) {
  const file = process.argv.slice(2).find((a) => a !== '--')
  if (!file) {
    console.error('usage: ew-earth.ts <converted EWSitRoomMap.upk>')
    process.exit(2)
  }
  const bytes = new Uint8Array(readFileSync(file))
  console.log(`${tealEarth(bytes)} blocks of the earth recoloured`)
  writeFileSync(file, bytes)
}
