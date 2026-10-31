// An Enemy Within map's geometry for XCOM 2 (features/hard-parts.md, experiment 2):
// XCOM 2 cannot load an EW map as a map (its level data is serialized differently),
// but it reads EW's static meshes. So:
//   - the map package is made a content package: its world (the level, its actors,
//     their components, lighting) blanked, so nothing of it is read; the packages it
//     carries copies of (FX_Shared, UFO_SmallScout …) renamed, so they do not clash
//     with XCOM 2's packages of the same names (the first letter becomes "Q");
//   - every placed static mesh (StaticMeshActor, XComLevelActor, XComDestructibleActor
//     …) is written out: its mesh's path, its location, rotation and scale, as config
//     for the mod to spawn (LWX2EWMapPieces).
// The texture caches are renamed as ew-package.ts does.
//
// Run from the Long War Tech Tree's checkout (it has upkit):
//   cd ../xcom-ew-lw-tree
//   npx vite-node ../long-war-x2/tools/convert/ew-map.ts -- <EW map .upk> <out .upk> <out pieces .ini>
import { readFileSync, writeFileSync } from 'node:fs'
import { basename } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { openPackage } from '@innonova/upkit/package'
import { Reader } from '@innonova/upkit/bytes'
import { readTags, type Tag } from '@innonova/upkit/objects'

const CACHES: Record<string, string> = {
  CharTextures: 'EWCharTextrs',
  Textures: 'EWTextrs',
  Lighting: 'EWLightg',
  Textures_startup: 'EWTextrs_startup',
}

const [src, out, iniOut] = process.argv.slice(2).filter((a) => a !== '--')
if (!iniOut) {
  console.error('usage: ew-map.ts <EW map .upk> <out .upk> <out pieces .ini>')
  process.exit(2)
}
const original = new Uint8Array(readFileSync(src))
const bytes = decompressPackage(original)
fixHeader(original, bytes)
// Two readers of the same bytes: upk's for names, paths and table entries; package's for object data.
const meta: any = new Package(bytes)
const pkg: any = openPackage(bytes)
const exports = meta.exports as any[]
const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)

// --- The placements, read before anything is changed -----------------------------
const f32 = (t: Tag | undefined, k: number) => (t ? new DataView(t.value.buffer, t.value.byteOffset).getFloat32(4 * k, true) : 0)
const i32 = (t: Tag | undefined, k: number) => (t ? new DataView(t.value.buffer, t.value.byteOffset).getInt32(4 * k, true) : 0)
const ref = (t: Tag | undefined) => (t ? new DataView(t.value.buffer, t.value.byteOffset).getInt32(0, true) : 0)
const tagsOf = (index: number, start: number) => readTags(new Reader(pkg.data(index + 1).subarray(start)), pkg)
const pathOf = (r: number): string => {
  if (r > 0) return exports[r - 1].fullName
  if (r < 0) return meta.imports[-r - 1].fullName
  return ''
}
/**
 * A placed actor's properties: after its state frame (22 bytes in EW's levels) and net
 * index, so from byte 26; found by trying when that does not read.
 */
function actorTags(index: number): Tag[] | undefined {
  const data = pkg.data(index + 1)
  for (const start of [26, ...Array.from({ length: 81 }, (_, k) => k)]) {
    try {
      const t = readTags(new Reader(data.subarray(start)), pkg)
      if (t.some((x) => x.name === 'StaticMeshComponent' || x.name === 'Location')) return t
    } catch {
      // not here
    }
  }
  return undefined
}
/** An export's archetype (its export table entry, after its name): what it inherits from. */
const archetypeOf = (index: number) => v.getInt32(exports[index].entryOffset + 20, true)
/** A component's static mesh: its own, or its archetype's (placed actors store only what differs). */
function meshOf(index: number, tags: Tag[]): string {
  for (let depth = 0; depth < 8; depth++) {
    const own = tags.find((t) => t.name === 'StaticMesh')
    if (own) return pathOf(ref(own))
    const arch = archetypeOf(index)
    if (arch <= 0) return ''
    index = arch - 1
    try {
      tags = tagsOf(index, 8)
    } catch {
      return ''
    }
  }
  return ''
}
interface Piece { mesh: string; loc: number[]; rot: number[]; scale: number[] }
const pieces: Piece[] = []
const skipped: Record<string, number> = {}
exports.forEach((e, i) => {
  const parts = e.fullName.split('.')
  if (parts[0] !== 'TheWorld' || parts[1] !== 'PersistentLevel' || parts.length !== 3) return
  const tags = actorTags(i)
  if (!tags) return
  const comp = tags.find((t) => t.name === 'StaticMeshComponent')
  if (!comp || ref(comp) <= 0) return
  let ctags: Tag[]
  try {
    ctags = tagsOf(ref(comp) - 1, 8)
  } catch {
    skipped[e.type] = (skipped[e.type] ?? 0) + 1
    return
  }
  const mesh = meshOf(ref(comp) - 1, ctags)
  if (!mesh) return
  const hidden = tags.find((t) => t.name === 'bHidden')
  if (hidden?.boolValue) return
  const loc = tags.find((t) => t.name === 'Location')
  const rot = tags.find((t) => t.name === 'Rotation')
  const ds = tags.find((t) => t.name === 'DrawScale')
  const ds3 = tags.find((t) => t.name === 'DrawScale3D')
  const s = ds ? f32(ds, 0) : 1
  pieces.push({
    mesh,
    loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)],
    rot: [i32(rot, 0), i32(rot, 1), i32(rot, 2)],
    scale: ds3 ? [f32(ds3, 0) * s, f32(ds3, 1) * s, f32(ds3, 2) * s] : [s, s, s],
  })
})

// --- The package: the world blanked, the carried packages and the caches renamed -
let blanked = 0
exports.forEach((e) => {
  if (e.fullName.split('.')[0] !== 'TheWorld') return
  v.setInt32(e.entryOffset + 32, 0, true) // serial size: nothing to read
  blanked++
})
const carried = new Set(exports.filter((e) => e.type === 'Package' && e.outer === 0).map((e) => e.name as string))
const renamedPackages = new Map<string, string>()
meta.nameEntries.forEach((n: { name: string; offset: number }) => {
  const to = CACHES[n.name] ?? (carried.has(n.name) ? 'Q' + n.name.slice(1) : undefined)
  if (!to) return
  const at = n.offset + 4
  if (new TextDecoder('latin1').decode(bytes.subarray(at, at + n.name.length)) !== n.name)
    throw new Error(`name table entry ${n.name} is not where it was read`)
  bytes.set(new TextEncoder().encode(to), at)
  if (carried.has(n.name)) renamedPackages.set(n.name, to)
})
writeFileSync(out, bytes)

// --- The pieces as config ------------------------------------------------------------
const rename = (path: string) => {
  const [top, ...rest] = path.split('.')
  return [renamedPackages.get(top!) ?? top, ...rest].join('.')
}
const n = (x: number) => (Math.abs(x) < 1e-4 ? '0' : String(Math.round(x * 1000) / 1000))
const lines = [
  `; The static meshes of ${basename(src)}, converted on this machine by tools/convert/ew-map.ts.`,
  '; Not in the repository: generated from the player\'s own Enemy Within install.',
  '[LongWarX2.LWX2EWMapPieces]',
  `MapPackage="${basename(out, '.upk')}"`,
  ...pieces.map(
    (p) =>
      `+Pieces=(Mesh="${rename(p.mesh)}",Loc=(X=${n(p.loc[0]!)},Y=${n(p.loc[1]!)},Z=${n(p.loc[2]!)}),Rot=(Pitch=${p.rot[0]},Yaw=${p.rot[1]},Roll=${p.rot[2]}),Scale=(X=${n(p.scale[0]!)},Y=${n(p.scale[1]!)},Z=${n(p.scale[2]!)}))`,
  ),
]
writeFileSync(iniOut, lines.join('\r\n') + '\r\n')
const meshes = new Set(pieces.map((p) => p.mesh))
console.log(`${out}: world blanked (${blanked} objects), ${renamedPackages.size} carried packages renamed`)
console.log(`${iniOut}: ${pieces.length} pieces of ${meshes.size} meshes${Object.keys(skipped).length ? `; components not read: ${JSON.stringify(skipped)}` : ''}`)

function fixHeader(compressed: Uint8Array, outBytes: Uint8Array) {
  const cv = new DataView(compressed.buffer, compressed.byteOffset, compressed.byteLength)
  if (cv.getInt32(4, true) === 0x20000) return
  let o = 12
  o += 4 + cv.getInt32(o, true)
  o += 4 + 4 * 7 + 16 + 16
  o += 4 + 12 * cv.getInt32(o, true) + 8
  const flagsAt = o
  const count = cv.getInt32(o + 4, true)
  if (cv.getInt32(o, true) === 0 || count === 0) return
  const tableEnd = flagsAt + 8 + 16 * count
  const firstChunk = cv.getInt32(flagsAt + 8, true)
  outBytes.copyWithin(flagsAt + 8, tableEnd, firstChunk)
  outBytes.fill(0, firstChunk - 16 * count, firstChunk)
}
