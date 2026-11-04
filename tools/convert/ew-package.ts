// An Enemy Within package made loadable by XCOM 2 as it is, from the player's own
// install (features/hard-parts.md, experiment 1): decompressed, its texture caches
// renamed, its textures rewritten uncompressed into the package. XCOM 2 reads EW's objects (same package version, 845): its
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
import { dirname } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { inlineTextures } from './inline-textures.ts'
import { quietParticleNotifies, stubMaterials } from './stub-materials.ts'
import { renameAnims, X2_SECTOID } from './ew-unit-anims.ts'

/** EW's texture caches and the names they take in a converted package (the same lengths). */
export const CACHES: Record<string, string> = {
  CharTextures: 'EWCharTextrs',
  Textures: 'EWTextrs',
  Lighting: 'EWLightg',
  Textures_startup: 'EWTextrs_startup',
}

/** An EW package made loadable by XCOM 2, written to out; returns its report. */
export function convertPackage(src: string, out: string, transform?: (bytes: Uint8Array) => { bytes: Uint8Array; report: string }): string {
const original = new Uint8Array(readFileSync(src))
let bytes = decompressPackage(original)
// A change to the package itself (a unit's animations under XCOM 2's names, ew-unit-anims.ts) before its textures are
// appended: a package written again would lose them, or their offsets.
let changed = ''
if (transform) {
  const t = transform(bytes)
  bytes = t.bytes
  changed = `; ${t.report}`
}
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
// The textures with their mips uncompressed in the package (inline-textures.ts): XCOM 2 reads
// EW's LZO-compressed mips as noise, so a material made from them in XCOM 2 needs these. The
// texture caches are then not read for this package at all.
// EW's materials made inert (stub-materials.ts): XCOM 2 would compile each as the package loads, for nothing it draws.
const stubbed = stubMaterials(bytes)
bytes = stubbed.bytes
const quieted = quietParticleNotifies(bytes)
const tex = inlineTextures(bytes, pkg.exports, pkg.names, dirname(src), bytes.length)
const outBytes = new Uint8Array(bytes.length + tex.appended.length)
outBytes.set(bytes)
outBytes.set(tex.appended, bytes.length)
writeFileSync(out, outBytes)

return `${out}: ${outBytes.length} bytes, decompressed; caches ${renamed.join(', ') || 'none named'}; ${tex.textures} textures rewritten (${tex.mips} mips); ${stubbed.count} materials made inert; ${quieted} animations' particle effects left out${changed}`
}

if (/ew-package\.ts$/.test(process.argv[1] ?? '')) {
  const args = process.argv.slice(2).filter((a) => a !== '--')
  // --anims <AnimSet path>: a unit's animations also under XCOM 2's names (ew-unit-anims.ts; XCOM 2's Sectoid's names).
  const at = args.indexOf('--anims')
  const set = at >= 0 ? args.splice(at, 2)[1] : undefined
  const [src, out] = args
  if (!out) {
    console.error('usage: ew-package.ts <EW package .upk> <out .upk> [--anims <AnimSet path>]')
    process.exit(2)
  }
  console.log(convertPackage(src!, out!, set ? (bytes) => renameAnims(bytes, set, X2_SECTOID) : undefined))
}

