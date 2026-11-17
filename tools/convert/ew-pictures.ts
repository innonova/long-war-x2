// Long War's pictures for EW's strategy screens (features/lw-ew-pictures.md), from the player's own install. Long War keeps
// each item's, tech's and Foundry project's picture in DefaultContent.ini's MultiplayerLoadoutSlots, which its patched
// UIUtilities reads (GetItemImagePath: iPointValue 0 and the item's number; GetTechImagePath: 2 and the tech's;
// GetFoundryImagePath: 3 and the project's). The paths go into the mod's XComLWX2Images.ini (written on the player's
// machine, never committed), EW's own moved to where the converted base carries them (ew-images.ts:
// Command1.QILibrary_StrategyImages), Long War's own (its LongWar.upk) kept, that package made loadable by cookPictures.
//   node tools/convert/ew-pictures.ts <EW's XEW folder> <the mod's folder> [--with-longwar]
//   node tools/convert/ew-pictures.ts --cook <Long War's LongWar.upk> <out .upk>
import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'
import { Package, decompressPackage } from '@innonova/upkit/upk'

const KINDS: Record<string, string> = { '0': 'Items', '2': 'Techs', '3': 'Foundry' }

/** The ini text for a DefaultContent.ini's text: [LongWarX2.LWX2Pictures] +Items=(Id=…, Path="…"), +Techs, +Foundry. */
export function picturesIni(content: string, withLongWar = false): { text: string; count: number } {
  const lines: string[] = []
  const seen = new Set<string>()
  for (const m of content.matchAll(/^MultiplayerLoadoutSlots=\(strUnitName="([^"]+)",\s*iPointValue=(\d+),\s*iIconType=(\d+)\)/gm)) {
    const kind = KINDS[m[2]!]
    if (!kind) continue
    const key = `${kind}:${m[3]}`
    if (seen.has(key)) continue
    seen.add(key)
    if (!m[1]!.startsWith('UILibrary_StrategyImages.') && !(withLongWar && m[1]!.startsWith('LongWar.'))) continue
    const path = m[1]!.replace(/^UILibrary_StrategyImages\./, 'Command1.QILibrary_StrategyImages.')
    lines.push(`+${kind}=(Id=${m[3]}, Path="${path}")`)
  }
  return { text: ['[LongWarX2.LWX2Pictures]', ...lines, ''].join('\r\n'), count: lines.length }
}

/** XComLWX2Images.ini written into the mod's Config from the player's EW install; how many pictures. */
export function writePictures(ew: string, mod: string, withLongWar = false): number {
  const ini = join(ew, 'XComGame', 'Config', 'DefaultContent.ini')
  if (!existsSync(ini)) throw new Error('no DefaultContent.ini in the Enemy Within install')
  const { text, count } = picturesIni(readFileSync(ini, 'latin1'), withLongWar)
  writeFileSync(join(mod, 'Config', 'XComLWX2Images.ini'), text)
  return count
}


if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href && process.argv[2] === '--cook') {
  console.log(cookPictures(process.argv[3]!, process.argv[4]!))
} else if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const [ew, mod, flag] = process.argv.slice(2)
  if (!ew || !mod) {
    console.error('node tools/convert/ew-pictures.ts <EW XEW folder> <mod folder>')
    process.exit(1)
  }
  console.log(`${writePictures(ew, mod, flag === '--with-longwar')} pictures in Config/XComLWX2Images.ini`)
}

/**
 * Long War's pictures package made as EW's cooked ones are (features/lw-ew-pictures.md), so XCOM 2 loads it: Long War saved its
 * LongWar.upk uncooked (package flags 0x1, licensee version 0), its textures with their source art inline and a shorter tail
 * after their GUID than EW's cooked textures have (EW's: the GUID, then 0, 1, 0). Each texture is written again in EW's
 * cooked layout (its properties, no source art, its mips inline, the GUID and EW's tail), appended, its export pointed at
 * it; the package is marked cooked with EW's licensee version.
 */
export function cookPictures(src: string, out: string): string {
  const bytes: Uint8Array = decompressPackage(new Uint8Array(readFileSync(src)))
  const pkg: any = new Package(bytes)
  const names: string[] = pkg.names.map((n: any) => String(n.name ?? n))
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  const none = names.indexOf('None')
  const parts: Uint8Array[] = []
  let at = bytes.length
  let count = 0
  const i32s = (...xs: number[]) => {
    const b = new Uint8Array(4 * xs.length)
    const d = new DataView(b.buffer)
    xs.forEach((x, k) => d.setInt32(4 * k, x, true))
    return b
  }
  for (const e of pkg.exports) {
    if (e.type !== 'Texture2D') continue
    let o = e.offset + 4
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
      o += size
    }
    const chunks: Uint8Array[] = [bytes.subarray(e.offset, o)]
    let len = o - e.offset
    const push = (b: Uint8Array) => {
      chunks.push(b)
      len += b.length
    }
    // The source art: dropped (cooked textures have none).
    const sflags = v.getUint32(o, true)
    const scount = v.getInt32(o + 4, true)
    const ssize = v.getInt32(o + 8, true)
    o += 16 + (!(sflags & 0x21) && scount > 0 ? ssize : 0)
    push(i32s(0, 0, 0, at + len + 16))
    const mips = v.getInt32(o, true)
    o += 4
    push(i32s(mips))
    for (let k = 0; k < mips; k++) {
      const flags = v.getUint32(o, true)
      const c = v.getInt32(o + 4, true)
      const sod = v.getInt32(o + 8, true)
      if (flags & 0x31) throw new Error(`${e.fullName}: a mip not stored inline uncompressed (flags ${flags})`)
      const data = bytes.subarray(o + 16, o + 16 + sod)
      o += 16 + sod
      const w = v.getInt32(o, true)
      const h = v.getInt32(o + 4, true)
      o += 8
      push(i32s(0, c, sod, at + len + 16))
      push(data)
      push(i32s(w, h))
    }
    push(bytes.subarray(o, o + 16)) // the GUID
    push(i32s(0, 1, 0)) // EW's cooked tail
    const blob = new Uint8Array(len)
    let p = 0
    for (const ch of chunks) {
      blob.set(ch, p)
      p += ch.length
    }
    v.setInt32(e.entryOffset + 32, blob.length, true)
    v.setInt32(e.entryOffset + 36, at, true)
    parts.push(blob)
    at += blob.length
    count++
  }
  // EW's licensee version, and cooked (PKG_Cooked 0x8): the header's tag, version (2 bytes), licensee (2 bytes), header size,
  // folder name, then the flags.
  v.setUint16(6, 64, true)
  const folder = v.getInt32(12, true)
  const flagsAt = 16 + (folder > 0 ? folder : -folder * 2)
  v.setUint32(flagsAt, v.getUint32(flagsAt, true) | 0x8, true)
  const outBytes = new Uint8Array(at)
  outBytes.set(bytes)
  let q = bytes.length
  for (const b of parts) {
    outBytes.set(b, q)
    q += b.length
  }
  writeFileSync(out, outBytes)
  return `${out}: ${count} textures in EW's cooked layout`
}
