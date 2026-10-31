// An Enemy Within package made loadable by XCOM 2 as it is, from the player's own
// install (features/hard-parts.md, experiment 1): decompressed, and its texture
// caches renamed. XCOM 2 reads EW's objects (same package version, 845): its
// AnimSets loaded and played as they are. But both games have caches called
// CharTextures.tfc and Textures.tfc, and an EW texture read from XCOM 2's cache
// crashes the game. The names are changed in the package's name table to ones of
// the same length (nothing else moves), and the player's EW caches are linked into
// the mod's Content folder under those names (tools/convert/README.md).
//
// Run from the Long War Tech Tree's checkout (it has upkit):
//   cd ../xcom-ew-lw-tree
//   npx vite-node ../long-war-x2/tools/convert/ew-package.ts -- <EW package .upk> <out .upk>
import { readFileSync, writeFileSync } from 'node:fs'
import { Package, decompressPackage } from '@innonova/upkit/upk'

/** EW's texture caches and the names they take in a converted package (the same lengths). */
export const CACHES: Record<string, string> = {
  CharTextures: 'EWCharTextrs',
  Textures: 'EWTextrs',
  Lighting: 'EWLightg',
  Textures_startup: 'EWTextrs_startup',
}

const [src, out] = process.argv.slice(2).filter((a) => a !== '--')
if (!out) {
  console.error('usage: ew-package.ts <EW package .upk> <out .upk>')
  process.exit(2)
}
const original = new Uint8Array(readFileSync(src))
const bytes = decompressPackage(original)
fixHeader(original, bytes)
const pkg = new Package(bytes)
const renamed: string[] = []
pkg.nameEntries.forEach((e: { name: string; offset: number }) => {
  const to = CACHES[e.name]
  if (!to) return
  if (to.length !== e.name.length) throw new Error(`${e.name} → ${to}: not the same length`)
  // An FString: its length (int32), then the characters.
  const at = e.offset + 4
  if (new TextDecoder('latin1').decode(bytes.subarray(at, at + e.name.length)) !== e.name)
    throw new Error(`name table entry ${e.name} is not where it was read`)
  bytes.set(new TextEncoder().encode(to), at)
  renamed.push(`${e.name} → ${to}`)
})
writeFileSync(out, bytes)

/**
 * upkit's decompressPackage zeroes the chunk count but leaves the old chunk entries in
 * the header, so the fields after the table (the package source, the packages to cook,
 * the texture allocations) are read from them: XCOM 2 then loops on the garbage. The
 * fields are moved up to follow the count; the rest of the header is left as it is (the
 * tables are found by their offsets).
 */
function fixHeader(compressed: Uint8Array, out: Uint8Array) {
  const v = new DataView(compressed.buffer, compressed.byteOffset, compressed.byteLength)
  if (v.getInt32(4, true) === 0x20000) return // compressed whole: no chunk table
  let o = 4 + 2 + 2 + 4 // tag, versions, header size
  o += 4 + v.getInt32(o, true) // folder name (an FString)
  o += 4 + 4 * 7 + 16 + 16 // package flags; names, exports, imports, depends; 845's extra and the GUID
  const generations = v.getInt32(o, true)
  o += 4 + 12 * generations + 8 // generations; engine and cooker versions
  const flagsAt = o
  const count = v.getInt32(o + 4, true)
  if (v.getInt32(o, true) === 0 || count === 0) return
  const tableEnd = flagsAt + 8 + 16 * count
  const firstChunk = v.getInt32(flagsAt + 8, true) // where the uncompressed data starts: the header's end
  out.copyWithin(flagsAt + 8, tableEnd, firstChunk)
  out.fill(0, firstChunk - 16 * count, firstChunk)
}
console.log(`${out}: ${bytes.length} bytes, decompressed; caches ${renamed.join(', ') || 'none named'}`)
