// An Enemy Within map's geometry for XCOM 2 (features/hard-parts.md, experiment 2):
// XCOM 2 cannot load an EW map as a map (its level data is serialized differently),
// but it reads EW's static meshes. So:
//   - the map package is made a content package: its world (the level, its actors,
//     their components, lighting) turned into empty objects XCOM 2 can read; the packages it
//     carries copies of (FX_Shared, UFO_SmallScout …) renamed, so they do not clash
//     with XCOM 2's packages of the same names (the first letter becomes "Q");
//   - every placed static mesh (StaticMeshActor, XComLevelActor, XComDestructibleActor,
//     XComFracLevelActor …) is written out: its mesh's path, its location, rotation and scale, as config
//     for the mod to spawn (LWX2EWMapPieces).
// The textures are rewritten with their mips uncompressed in the package (inline-textures.ts:
// XCOM 2 does not read EW's compression), so the map needs no texture cache.
//
// Run from the Long War Tech Tree's checkout (it has upkit):
//   cd ../xcom-ew-lw-tree
//   npx vite-node ../long-war-x2/tools/convert/ew-map.ts -- <EW map .upk> <out .upk> <out pieces .ini>
import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import { basename, dirname, join } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { openPackage } from '@innonova/upkit/package'
import { Reader } from '@innonova/upkit/bytes'
import { readTags, type Tag } from '@innonova/upkit/objects'
import { inlineTextures } from './inline-textures.ts'
import { addMaskTextures, maskMip } from './mask-textures.ts'

/** Raised when what a conversion writes changes so that maps converted before must be converted again
 *  (2: carried packages nested in the map's package, for its plot; 3: its building volumes and floors; 4: terror pods,
 *  spawn points by type; 5: the walls, EW's fracturable meshes; meshes at the root of the map's package; objects of one
 *  name made unique; materials cut out by their diffuse's alpha, a kind of their own; 6: walls marked fractured, so the
 *  plot imports them as such; the buildings' surface textures, Diffuse_Base; 7: the doors, the pieces' cover flags;
 *  8: the walls' fracture data and toughness, for XCOM 2's breakable walls; 9: the textures of materials cooked without
 *  their expressions, read from the compiled shader (the road paint, asphalt patches), translucent ones masked; 10: masks for the
 *  cut-out looks, the diffuse's alpha in green and blue, which XCOM 2's cut-out parents read their opacity from;
 *  11: vehicles not to be stood on; 12: nor sandbags; 13: their tops no valid destinations; 14: no path written as
 *  none, not as the map's name and a dot). */
export const CONVERTER_VERSION = 14

const CACHES: Record<string, string> = {
  CharTextures: 'EWCharTextrs',
  Textures: 'EWTextrs',
  Lighting: 'EWLightg',
  Textures_startup: 'EWTextrs_startup',
}

/**
 * Objects of one name in one outer made unique, in place: EW's cooker kept, for one, a mesh and a texture both
 * `Foliage.grassPatch`, and a destructible's actions all `Action`. XCOM 2 keeps one object of a name, so a plot's piece
 * got the texture for its mesh and the game crashed as it built the map (URB_Boulevard, lw-missions.md). The second and
 * later of a name get a name number of their own (the export table's; the package refers to its objects by index, so
 * nothing else changes). Returns how many.
 */
function uniqueNames(bytes: Uint8Array): number {
  const meta: any = new Package(bytes)
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  const names: string[] = meta.names.map((n: any) => String(n.name ?? n).toLowerCase())
  const used = new Map<string, Set<number>>()
  const groups = new Map<string, number[]>()
  for (const e of meta.exports as any[]) {
    const o = e.entryOffset
    const key = `${v.getInt32(o + 8, true)}|${names[v.getInt32(o + 12, true)]}`
    const number = v.getInt32(o + 16, true)
    if (!used.has(key)) used.set(key, new Set())
    used.get(key)!.add(number)
    const k = `${key}|${number}`
    groups.set(k, [...(groups.get(k) ?? []), o])
  }
  let changed = 0
  for (const [k, offsets] of groups) {
    if (offsets.length < 2) continue
    const key = k.slice(0, k.lastIndexOf('|'))
    const taken = used.get(key)!
    for (const o of offsets.slice(1)) {
      let n = Math.max(...taken) + 1
      while (taken.has(n)) n++
      taken.add(n)
      v.setInt32(o + 16, n, true)
      changed++
    }
  }
  return changed
}

/** One EW map converted (the package to out, its section to iniOut); its report lines printed. Used by ew-maps.ts and the
 *  player's setup program as well as from the command line. */
export function convertMap(src: string, out: string, iniOut: string): void {
const original = new Uint8Array(readFileSync(src))
let bytes = decompressPackage(original)
const renumbered = uniqueNames(bytes)
// Two readers of the same bytes: upk's for names, paths and table entries; package's for object data. (Read again once
// the masks are added, below.)
let meta: any = new Package(bytes)
let pkg: any = openPackage(bytes)
let exports = meta.exports as any[]
let v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)

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
      if (t.some((x) => x.name === 'StaticMeshComponent' || x.name === 'FracturedStaticMeshComponent' || x.name === 'Location')) return t
    } catch {
      // not here
    }
  }
  return undefined
}
/** An export's archetype (its export table entry, after its name): what it inherits from. */
const archetypeOf = (index: number) => v.getInt32(exports[index].entryOffset + 20, true)
/**
 * What units may do with a piece (XCOM 2's and EW's cover flags): stand on it (bCanClimbOnto), vault it
 * (bCanClimbOver), end a move on it (bIsValidDestination), take cover by it (bIgnoreForCover, CoverForceFlag). Read
 * from the placed actor, then its archetypes; what none sets is its class's default (a destructible's, a car's or
 * sandbags', is not to be stood on; XCOM 2 places every piece as an XComLevelActor, whose default is).
 */
interface Cover { onto: boolean; over: boolean; destination: boolean; ignore: boolean; force: string }
const COVER_DEFAULTS: Record<string, Partial<Cover>> = {
  XComDestructibleActor: { onto: false },
  XComFracLevelActor: { onto: false },
  XComDecoFracLevelActor: { onto: false },
}
/** EW's vehicles (its VEH_ packages) and sandbags (SandBag): not to be stood on, whatever EW's data says (EW's sedan
 *  prefab and some sandbag piles set bCanClimbOnto, and XCOM 2 then makes their tops floors; a sandbag is low enough to be
 *  stepped onto without a climb, so their tops are no valid destination either). The person, 2026-11-03:
 *  "you should not be able to stand on the sandbags", nor "on the hood and trunk" of a car. */
const notStoodOn = (mesh: string, c: Cover): Cover => (/^(VEH_|SandBag\.)/.test(mesh) ? { ...c, onto: false, destination: false } : c)
function coverOf(index: number, own: Tag[]): Cover {
  const found: Partial<Cover> = {}
  const take = (tags: Tag[]) => {
    for (const t of tags) {
      if (t.name === 'bCanClimbOnto' && found.onto === undefined) found.onto = !!t.boolValue
      else if (t.name === 'bCanClimbOver' && found.over === undefined) found.over = !!t.boolValue
      else if (t.name === 'bIsValidDestination' && found.destination === undefined) found.destination = !!t.boolValue
      else if (t.name === 'bIgnoreForCover' && found.ignore === undefined) found.ignore = !!t.boolValue
      else if (t.name === 'CoverForceFlag' && found.force === undefined)
        found.force = String(pkg.names[new DataView(t.value.buffer, t.value.byteOffset).getInt32(0, true)].name)
    }
  }
  take(own)
  for (let i = index, depth = 0; depth < 8; depth++) {
    const arch = archetypeOf(i)
    if (arch <= 0) break
    i = arch - 1
    for (const start of [4, 26, 8]) {
      try {
        take(tagsOf(i, start))
        break
      } catch {
        // not here
      }
    }
  }
  const d = COVER_DEFAULTS[exports[index].type] ?? {}
  return {
    onto: found.onto ?? d.onto ?? true,
    over: found.over ?? d.over ?? false,
    destination: found.destination ?? d.destination ?? true,
    ignore: found.ignore ?? d.ignore ?? false,
    force: found.force ?? 'CoverForce_Default',
  }
}
/** A property's tag on an export or the first of its archetypes that has it. */
function inherited(index: number, own: Tag[], name: string, start: number): Tag | undefined {
  let found = own.find((t) => t.name === name)
  for (let i = index, depth = 0; !found && depth < 8; depth++) {
    const arch = archetypeOf(i)
    if (arch <= 0) break
    i = arch - 1
    for (const s of [start, 4, 8, 26]) {
      try {
        found = tagsOf(i, s).find((t) => t.name === name)
        break
      } catch {
        // not here
      }
    }
  }
  return found
}
/** A wall's fracture data (its component index and properties, its actor's), for an XCOM 2 wall that breaks. */
function fracOf(actorIndex: number, actor: Tag[], compIndex: number, comp: Tag[]): Frac {
  const indices = inherited(compIndex, comp, 'NumResourceIndices', 8)
  const minZ = inherited(compIndex, comp, 'FragmentBoundsMinZ', 8)
  const maxZ = inherited(compIndex, comp, 'FragmentBoundsMaxZ', 8)
  const tough = inherited(actorIndex, actor, 'Toughness', 4)
  const toughPath = tough && ref(tough) ? pathOf(ref(tough)) : ''
  return {
    indices: indices ? i32(indices, 0) : 0,
    minZ: minZ ? f32(minZ, 0) : 0,
    maxZ: maxZ ? f32(maxZ, 0) : 0,
    toughness: /Toughness_(\w+)$/.exec(toughPath)?.[1] ?? '',
  }
}
/** A static mesh's bounds' half sizes: the first thing in its data after the properties (origin, extent, radius). */
function meshExtent(path: string): number[] {
  const i = exports.findIndex((e) => e.fullName === path)
  if (i < 0) return [0, 0, 0]
  const d = pkg.data(i + 1)
  const dv = new DataView(d.buffer, d.byteOffset, d.byteLength)
  const none = meta.names.indexOf('None')
  let o = 4
  try {
    readTags(new Reader(d.subarray(4)), pkg)
    while (dv.getInt32(o, true) !== none) o += 24 + dv.getInt32(o + 16, true) + (meta.names[dv.getInt32(o + 8, true)] === 'StructProperty' || meta.names[dv.getInt32(o + 8, true)] === 'ByteProperty' ? 8 : 0) + (meta.names[dv.getInt32(o + 8, true)] === 'BoolProperty' ? 1 : 0)
  } catch {
    return [0, 0, 0]
  }
  o += 8
  return [dv.getFloat32(o + 12, true), dv.getFloat32(o + 16, true), dv.getFloat32(o + 20, true)]
}
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
/** An object array property's references. */
const refs = (t: Tag) => {
  const dv = new DataView(t.value.buffer, t.value.byteOffset)
  return Array.from({ length: dv.getInt32(0, true) }, (_, k) => dv.getInt32(4 + 4 * k, true))
}
/**
 * A component's materials, slot by slot: its own overrides, then its archetype's for the
 * slots it leaves empty. EW's meshes carry none that XCOM 2 can read: the archetypes do.
 */
function materialsOf(index: number, tags: Tag[]): number[] {
  const slots: number[] = []
  for (let depth = 0; depth < 8; depth++) {
    const own = tags.find((t) => t.name === 'Materials')
    if (own) refs(own).forEach((r, k) => { if (!slots[k] && r) slots[k] = r })
    const arch = archetypeOf(index)
    if (arch <= 0) break
    index = arch - 1
    try {
      tags = tagsOf(index, 8)
    } catch {
      break
    }
  }
  return Array.from(slots, (r) => r ?? 0)
}
/** A wall's fracture: its mesh's index count and fragments' height (the component's, or its archetypes'), and EW's
 *  toughness by name (MASONRY, WOOD …), so XCOM 2 can break it as EW did. */
interface Frac { indices: number; minZ: number; maxZ: number; toughness: string }
interface Piece { mesh: string; loc: number[]; rot: number[]; scale: number[]; materials: number[]; extent: number[]; fractured: boolean; cover: Cover; frac?: Frac }
const pieces: Piece[] = []
const skipped: Record<string, number> = {}
exports.forEach((e, i) => {
  const parts = e.fullName.split('.')
  if (parts[0] !== 'TheWorld' || parts[1] !== 'PersistentLevel' || parts.length !== 3) return
  const tags = actorTags(i)
  if (!tags) return
  // EW's walls are fracturable (XComFracLevelActor, XComDecoFracLevelActor): their mesh is a FracturedStaticMesh, which
  // XCOM 2 draws whole in a plain static mesh component.
  const comp = tags.find((t) => t.name === 'StaticMeshComponent') ?? tags.find((t) => t.name === 'FracturedStaticMeshComponent')
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
    materials: materialsOf(ref(comp) - 1, ctags),
    extent: [0, 0, 0],
    // A wall's mesh is a FracturedStaticMesh: the plot imports it as that class (as a StaticMesh it is not found).
    fractured: exports.find((x) => x.fullName === mesh)?.type === 'FracturedStaticMesh',
    cover: notStoodOn(mesh, coverOf(i, tags)),
    frac: comp.name === 'FracturedStaticMeshComponent' ? fracOf(i, tags, ref(comp) - 1, ctags) : undefined,
  })
})

/** The backdrop (the sky dome, the mountains): too big to be ground; it must not collide, or it encloses the map. */
const isBackdrop = (p: Piece) => p.extent[0]! > 2400 || p.extent[1]! > 2400 || p.extent[2]! > 1200
const extents = new Map<string, number[]>()
for (const p of pieces) {
  if (!extents.has(p.mesh)) extents.set(p.mesh, meshExtent(p.mesh))
  p.extent = extents.get(p.mesh)!.map((x, k) => Math.abs(x * p.scale[k]!))
}
if (process.env.LWX2_EXTENTS) for (const [m, e] of [...extents].sort((a, b) => Math.max(...b[1]) - Math.max(...a[1])).slice(0, 12)) console.log('extent', m, e.map((x) => x.toFixed(0)).join(','))

// --- The doors: EW's interactive actors (a skeletal mesh that opens by its AnimTree) ---
// XCOM 2's XComInteractiveLevelActor is EW's, nearly field for field: the plot places one per EW door with EW's mesh,
// AnimTree, AnimSets and interaction points (where a unit stands to open it, the door's animations by name).
interface DoorPoint { src: string; dest: string; anim: string; destroy: string; inactive: string; facing: string; mirror: boolean }
interface Door { mesh: string; materials: number[]; tree: string; sets: string[]; physics: string; loc: number[]; rot: number[]; scale: number[]; idle: string; points: DoorPoint[]; blocksSight: boolean; window: boolean }
const doors: Door[] = []
const nameAt = (v: Uint8Array) => String(pkg.names[new DataView(v.buffer, v.byteOffset).getInt32(0, true)].name)
exports.forEach((e, i) => {
  if (e.type !== 'XComInteractiveLevelActor' || !e.fullName.startsWith('TheWorld.PersistentLevel.')) return
  const tags = actorTags(i)
  const comp = tags?.find((t) => t.name === 'SkeletalMeshComponent')
  if (!tags || !comp || ref(comp) <= 0) return
  let ctags: Tag[]
  try {
    ctags = tagsOf(ref(comp) - 1, 8)
  } catch {
    return
  }
  const obj = (name: string) => { const t = ctags.find((x) => x.name === name); return t && ref(t) ? pathOf(ref(t)) : '' }
  const mesh = obj('SkeletalMesh')
  // Its materials: the component's own, else the mesh's (in its data after the properties and bounds: count, refs).
  const meshRef = ref(ctags.find((x) => x.name === 'SkeletalMesh')!)
  const own = ctags.find((x) => x.name === 'Materials')
  let materials: number[] = own ? refs(own) : []
  if (!materials.length && meshRef > 0) {
    try {
      const d = pkg.data(meshRef)
      const r = new Reader(d.subarray(4))
      readTags(r, pkg)
      const at = 4 + (r as any).o + 28
      const dv = new DataView(d.buffer, d.byteOffset)
      materials = Array.from({ length: Math.min(dv.getInt32(at, true), 16) }, (_, k) => dv.getInt32(at + 4 + 4 * k, true))
    } catch {
      materials = []
    }
  }
  const pointsTag = tags.find((t) => t.name === 'InteractionPoints')
  if (!mesh || !pointsTag) return
  const points: DoorPoint[] = []
  const count = new DataView(pointsTag.value.buffer, pointsTag.value.byteOffset).getInt32(0, true)
  const r = new Reader(pointsTag.value.subarray(4))
  for (let k = 0; k < count; k++) {
    const st = readTags(r, pkg)
    const en = (name: string) => { const t = st.find((x) => x.name === name); return t ? nameAt(t.value) : '' }
    points.push({ src: en('SrcSocket'), dest: en('DestSocket'), anim: en('InteractionAnim'), destroy: en('DestroyAnim'), inactive: en('InactiveIdleAnim'), facing: en('Facing') || 'eIF_Left', mirror: !!st.find((x) => x.name === 'bMirrorAnims')?.boolValue })
  }
  const vis = tags.find((t) => t.name === 'VisibilityBlockingData')
  const visTags = vis ? readTags(new Reader(vis.value), pkg) : []
  const sets = ctags.find((t) => t.name === 'AnimSets')
  const loc = tags.find((t) => t.name === 'Location')
  const rot = tags.find((t) => t.name === 'Rotation')
  const ds = tags.find((t) => t.name === 'DrawScale')
  const ds3 = tags.find((t) => t.name === 'DrawScale3D')
  const s = ds ? f32(ds, 0) : 1
  const idle = tags.find((t) => t.name === 'ActiveIdleAnim')
  doors.push({
    mesh, materials, tree: obj('AnimTreeTemplate'), physics: obj('PhysicsAsset'),
    sets: sets ? Array.from({ length: new DataView(sets.value.buffer, sets.value.byteOffset).getInt32(0, true) }, (_, k) => pathOf(new DataView(sets.value.buffer, sets.value.byteOffset).getInt32(4 + 4 * k, true))).filter(Boolean) : [],
    loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)],
    rot: [i32(rot, 0), i32(rot, 1), i32(rot, 2)],
    scale: ds3 ? [f32(ds3, 0) * s, f32(ds3, 1) * s, f32(ds3, 2) * s] : [s, s, s],
    idle: idle ? nameAt(idle.value) : '',
    points,
    blocksSight: visTags.find((t) => t.name === 'bBlockUnitVisibility')?.boolValue !== 0,
    window: !!visTags.find((t) => t.name === 'bIsWindow')?.boolValue,
  })
})

// --- The play area and the drop zones ---------------------------------------------
// The level volume (its location plus its brush's bounds: a Model's data starts with them)
// and the player starts (one per drop zone), for placing the map as a mission's ground.
let play: { center: number[]; extent: number[] } | undefined
const starts: number[][] = []
// EW's building volumes (where its buildings are and their floors: what XCOM 2's building visibility cuts away when a
// unit is inside or below), for the map's plot (ew-plot.ts).
const buildings: { center: number[]; extent: number[]; floors: { center: number[]; extent: number[] }[]; ufo: boolean }[] = []
/** A brush actor's box in the world: its location plus its brush's bounds (a Model's data starts with them), scaled. */
function brushBox(index: number): { center: number[]; extent: number[] } | undefined {
  const t = actorTags(index)
  const loc = t?.find((x) => x.name === 'Location')
  const brush = t?.find((x) => x.name === 'Brush')
  if (!loc || !brush || ref(brush) <= 0) return undefined
  const scale = t?.find((x) => x.name === 'DrawScale3D')
  const s = scale ? [f32(scale, 0), f32(scale, 1), f32(scale, 2)] : [1, 1, 1]
  const d = pkg.data(ref(brush))
  const dv = new DataView(d.buffer, d.byteOffset, d.byteLength)
  const none = meta.names.indexOf('None')
  let o = 4
  while (dv.getInt32(o, true) !== none) o += 24 + dv.getInt32(o + 16, true)
  o += 8
  const b = Array.from({ length: 6 }, (_, k) => dv.getFloat32(o + 4 * k, true))
  return { center: [0, 1, 2].map((k) => f32(loc, k) + b[k]! * s[k]!), extent: [0, 1, 2].map((k) => b[k + 3]! * Math.abs(s[k]!)) }
}
// EW's alien pods (where its aliens stand: the commander's pod, how many) and its spawn points.
const pods: { loc: number[]; commander: boolean; min: number; max: number; level: string }[] = []
const spawnPoints: number[][] = []
// EW's lights (lw-missions.md, step 2): baked into its lightmaps, which XCOM 2 cannot use, so
// the mod spawns each as a movable light. Kind, place, direction, and its component's values
// (Unreal's defaults where the map does not set them).
interface EWLight {
  kind: 'Point' | 'Spot' | 'Sun' | 'Sky'
  loc: number[]
  rot: number[]
  radius: number
  brightness: number
  color: number[]
  falloff: number
  inner: number
  outer: number
  lower: number
}
const lights: EWLight[] = []
const LIGHTS: Record<string, EWLight['kind']> = {
  PointLight: 'Point', PointLightToggleable: 'Point', PointLightMovable: 'Point',
  SpotLight: 'Spot', SpotLightToggleable: 'Spot', SpotLightMovable: 'Spot',
  DirectionalLight: 'Sun', DominantDirectionalLight: 'Sun', SkyLight: 'Sky',
}
/**
 * A component's properties: after its leading fields (net index, template names), found by trying.
 * A dominant light's come after its shadow map: there every offset that holds a property name
 * (a name index followed by 0) is tried, so no bytes are read as a property that are not one.
 */
function componentTags(r: number): Tag[] {
  if (r <= 0) return []
  const data = pkg.data(r)
  const dv = new DataView(data.buffer, data.byteOffset, data.byteLength)
  const isName = (k: number) => k + 8 <= data.length && dv.getInt32(k + 4, true) === 0 && dv.getInt32(k, true) > 0 && dv.getInt32(k, true) < meta.names.length
  const starts = [4, 8, 12, 16, 20, 0]
  if (/^Dominant/.test(exports[r - 1].type)) for (let k = 0; k < data.length; k++) if (isName(k)) starts.push(k)
  for (const start of starts) {
    try {
      const t = readTags(new Reader(data.subarray(start)), pkg)
      if (t.some((x) => x.name === 'LightGuid' || x.name === 'Brightness' || x.name === 'LightColor')) return t
    } catch {
      // not here
    }
  }
  return []
}
exports.forEach((e, i) => {
  const parts = e.fullName.split('.')
  if (parts[0] !== 'TheWorld' || parts.length !== 3) return
  if (e.type === 'PlayerStart') {
    const t = actorTags(i)
    const loc = t?.find((x) => x.name === 'Location')
    if (loc) starts.push([f32(loc, 0), f32(loc, 1), f32(loc, 2)])
  }
  if (e.type === 'XComAlienPod' || e.type === 'XComAlienPod_Abduction' || e.type === 'XComAlienPod_Terror' || e.type === 'XComSpawnPoint') {
    const t = actorTags(i)
    const loc = t?.find((x) => x.name === 'Location')
    if (!loc) return
    // A spawn point's unit type (EW takes a terror site's civilians from the civilian ones: XGBattle_SP.GetCivilianSpawnPoints).
    if (e.type === 'XComSpawnPoint') {
      const ut = t!.find((x) => x.name === 'UnitType')
      const type = ut && ut.value.byteLength >= 8 ? meta.names[new DataView(ut.value.buffer, ut.value.byteOffset).getInt32(0, true)] : ut && ut.value.byteLength === 1 ? String(ut.value[0]) : ''
      spawnPoints.push([f32(loc, 0), f32(loc, 1), f32(loc, 2), /Civilian/i.test(type) ? 1 : 0])
    } else
      pods.push({
        loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)],
        commander: t!.some((x) => x.name === 'bCommanderPod'),
        min: i32(t!.find((x) => x.name === 'NumAliens_Min'), 0),
        max: i32(t!.find((x) => x.name === 'NumAliens_Max'), 0),
        level: e.type === 'XComAlienPod_Abduction' ? 'Abduction' : '',
      })
  }
  if (LIGHTS[e.type]) {
    const t = actorTags(i) ?? []
    const loc = t.find((x) => x.name === 'Location')
    const rot = t.find((x) => x.name === 'Rotation')
    const c = componentTags(ref(t.find((x) => x.name === 'LightComponent')))
    const get = (k: string) => c.find((x) => x.name === k)
    if (get('bEnabled')?.boolValue === 0) return
    const color = (k: string) => {
      const x = get(k)
      return x ? [x.value[2]!, x.value[1]!, x.value[0]!, x.value[3]!] : [255, 255, 255, 0]
    }
    const num = (k: string, d: number) => (get(k) ? f32(get(k), 0) : d)
    lights.push({
      kind: LIGHTS[e.type]!,
      loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)],
      rot: [i32(rot, 0), i32(rot, 1), i32(rot, 2)],
      radius: num('Radius', 1024),
      brightness: num('Brightness', 1),
      color: color('LightColor'),
      falloff: num('FalloffExponent', 2),
      inner: num('InnerConeAngle', 0),
      outer: num('OuterConeAngle', 44),
      lower: num('LowerBrightness', 0),
    })
  }
  if (e.type === 'XComBuildingVolume') {
    const t = actorTags(i)
    const box = brushBox(i)
    if (!t || !box) return
    // Its floors: an array of tagged structs, each with its floor volumes (box actors, merged into one box a floor).
    const floors: { center: number[]; extent: number[] }[] = []
    const ft = t.find((x) => x.name === 'Floors')
    if (ft && ft.value.byteLength >= 4) {
      const r = new Reader(ft.value)
      const n = r.i32()
      for (let k = 0; k < n; k++) {
        const ftags = readTags(r, pkg)
        const fv = ftags.find((x) => x.name === 'FloorVolumes')
        const boxes: { center: number[]; extent: number[] }[] = []
        if (fv && fv.value.byteLength >= 4) {
          const dv = new DataView(fv.value.buffer, fv.value.byteOffset, fv.value.byteLength)
          for (let j = 0; j < dv.getInt32(0, true); j++) {
            const r2 = dv.getInt32(4 + 4 * j, true)
            const fb = r2 > 0 ? brushBox(r2 - 1) : undefined
            if (fb) boxes.push(fb)
          }
        }
        if (!boxes.length) continue
        const lo = [0, 1, 2].map((c) => Math.min(...boxes.map((x) => x.center[c]! - x.extent[c]!)))
        const hi = [0, 1, 2].map((c) => Math.max(...boxes.map((x) => x.center[c]! + x.extent[c]!)))
        floors.push({ center: [0, 1, 2].map((c) => (lo[c]! + hi[c]!) / 2), extent: [0, 1, 2].map((c) => (hi[c]! - lo[c]!) / 2) })
      }
    }
    const ufo = !!t.find((x) => x.name === 'IsUfo' && x.boolValue)
    buildings.push({ ...box, floors, ufo })
  }
  if (e.type === 'XComLevelVolume' && !play) {
    const t = actorTags(i)
    const loc = t?.find((x) => x.name === 'Location')
    const brush = t?.find((x) => x.name === 'Brush')
    if (!loc || !brush || ref(brush) <= 0) return
    const d = pkg.data(ref(brush))
    const dv = new DataView(d.buffer, d.byteOffset, d.byteLength)
    const none = meta.names.indexOf('None')
    let o = 4
    while (dv.getInt32(o, true) !== none) o += 24 + dv.getInt32(o + 16, true)
    o += 8
    const b = Array.from({ length: 6 }, (_, k) => dv.getFloat32(o + 4 * k, true))
    play = { center: [f32(loc, 0) + b[0]!, f32(loc, 1) + b[1]!, f32(loc, 2) + b[2]!], extent: [b[3]!, b[4]!, b[5]!] }
  }
})

// EW keeps a map's pods in its sub-levels too (URB_TruckStop: _Stream, the abduction variant _EWI,
// _CNH), streamed in with it by mission: their pods read from the packages beside the map, each
// noted with its level (the part of its name after the map's).
const mapName = basename(src, '.upk')
for (const level of ['Stream', 'EWI', 'CNH']) {
  const file = join(dirname(src), `${mapName}_${level}.upk`)
  if (!existsSync(file)) continue
  const subBytes = decompressPackage(new Uint8Array(readFileSync(file)))
  const subMeta: any = new Package(subBytes)
  const sub: any = openPackage(subBytes)
  ;(subMeta.exports as any[]).forEach((e, i) => {
    if (!/^XComAlienPod/.test(e.type) || e.fullName.split('.').length !== 3) return
    const data = sub.data(i + 1)
    for (const start of [26, ...Array.from({ length: 81 }, (_, k) => k)]) {
      try {
        const t = readTags(new Reader(data.subarray(start)), sub)
        const loc = t.find((x) => x.name === 'Location')
        if (!loc) continue
        pods.push({
          loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)],
          commander: t.some((x) => x.name === 'bCommanderPod'),
          min: i32(t.find((x) => x.name === 'NumAliens_Min'), 0),
          max: i32(t.find((x) => x.name === 'NumAliens_Max'), 0),
          level,
        })
        break
      } catch {
        // not here
      }
    }
  })
}

// --- The materials' textures, for XCOM 2 stand-ins --------------------------------
// XCOM 2 cannot draw EW's materials (no shaders for them in its caches, and the game does
// not compile any), so the mod replaces each with an instance of an XCOM 2 parent given
// the EW material's diffuse and normal maps. Read here: an instance's texture parameters
// (its parents' for those it does not set), a material's texture expressions.
interface Look { diffuse: string; normal: string; kind: 'Prop' | 'Foliage' | 'Masked' | 'Alien'; mask?: string }
const nameOf = (t: Tag) => pkg.names[new DataView(t.value.buffer, t.value.byteOffset).getInt32(0, true)].name as string
/** Root materials drawn see-through (EW's BlendMode BLEND_Translucent: road paint, decals), by name. */
const translucent = new Set<string>()
const isTexture = (r: number) =>
  r > 0 ? r <= exports.length && /^Texture/.test(exports[r - 1].type) : r < 0 && -r <= meta.imports.length && /^Texture/.test(meta.imports[-r - 1].className ?? '')
/**
 * The textures a cooked material's compiled shader reads (its uniform expressions' texture list: a count, then that many
 * references, in the data after its properties). Cooking strips a material's expressions where no parameter names
 * them (EW's road paint, asphalt patches): this list is then the only place its textures are named.
 */
function compiledTextures(index: number): number[] {
  const d: Uint8Array = pkg.data(index + 1)
  const dv = new DataView(d.buffer, d.byteOffset, d.byteLength)
  const found: number[] = []
  for (let o = 0; o + 8 <= d.length; o++) {
    const n = dv.getInt32(o, true)
    if (n < 1 || n > 16 || o + 4 + 4 * n > d.length) continue
    const rs = Array.from({ length: n }, (_, i) => dv.getInt32(o + 4 + 4 * i, true))
    if (rs.every(isTexture)) {
      for (const r of rs) if (!found.includes(r)) found.push(r)
      o += 4 * n
    }
  }
  return found
}
function texturesOf(r: number, into: Map<string, string>, depth = 0): string {
  // returns the root material's name, for the kind
  if (r <= 0 || depth > 8) return r < 0 ? pathOf(r) : ''
  const e = exports[r - 1]
  let tags: Tag[]
  try {
    tags = tagsOf(r - 1, 4)
  } catch {
    return e.fullName
  }
  if (e.type === 'Material') {
    const ex = tags.find((t) => t.name === 'Expressions')
    for (const x of ex ? refs(ex) : []) {
      if (x <= 0) continue
      let xt: Tag[]
      try {
        xt = tagsOf(x - 1, 4)
      } catch {
        continue
      }
      const tex = xt.find((t) => t.name === 'Texture')
      if (!tex || ref(tex) === 0) continue
      const pn = xt.find((t) => t.name === 'ParameterName')
      const key = pn ? nameOf(pn) : pathOf(ref(tex)).split('.').pop()!
      if (!into.has(key)) into.set(key, pathOf(ref(tex)))
    }
    for (const t of compiledTextures(r - 1)) {
      const path = pathOf(t)
      const key = path.split('.').pop()!
      if (![...into.values()].includes(path) && !into.has(key)) into.set(key, path)
    }
    const blend = tags.find((t) => t.name === 'BlendMode')
    if (blend && nameOf(blend) === 'BLEND_Translucent') translucent.add(e.fullName)
    return e.fullName
  }
  const tp = tags.find((t) => t.name === 'TextureParameterValues')
  if (tp) {
    const rd = new Reader(tp.value.subarray(4))
    const count = new DataView(tp.value.buffer, tp.value.byteOffset).getInt32(0, true)
    for (let k = 0; k < count; k++) {
      const st = readTags(rd, pkg)
      const pn = st.find((t) => t.name === 'ParameterName')
      const pv = st.find((t) => t.name === 'ParameterValue')
      if (pn && pv && ref(pv) !== 0 && !into.has(nameOf(pn))) into.set(nameOf(pn), pathOf(ref(pv)))
    }
  }
  const parent = tags.find((t) => t.name === 'Parent')
  return parent ? texturesOf(ref(parent), into, depth + 1) : e.fullName
}
function lookOf(r: number): Look {
  const tex = new Map<string, string>()
  const root = texturesOf(r, tex)
  if (process.env.LWX2_LOOKS) console.log('look', pathOf(r), root, JSON.stringify([...tex]))
  // The parameter names EW's parents use, the main layer first (the ground blends take their
  // Grass layer: one texture where EW blends four by vertex colour); else by the texture's name.
  // (The buildings' parents, BLDG_*, name their surface Diffuse_Base; their Damage_* layer, rubble, is what shows once a
  // wall is broken, never the stand-in's.)
  const pick = (params: string[], re: RegExp) =>
    params.map((p) => tex.get(p)).find(Boolean)
    ?? [...tex].find(([param, p]) => !/^Damage/i.test(param) && re.test(p.split('.').pop()!))?.[1] ?? ''
  const diffuse = pick(['Diffuse', 'Diffuse_Base', 'Grass', 'Diffuse_Grass', 'Diffuse_Rock'], /(_DIFF?|_D|Diffuse|_Dif)\d*$/i)
  return {
    diffuse,
    normal: pick(['Normal', 'Normal_Base', 'Leaves_Normal', 'Dirt_Normal', 'Rock_Normal'], /(_NRM|_NORM|_N|Normal|_Nrm)\d*$/i),
    // Masked: cut out by the diffuse's alpha (tree cards, signs, fences: PROP_DifOpc, PROP_OpacityMask_Tile; and a
    // translucent parent's, as the road paint's, whose diffuse alpha holds the paint).
    kind: /Foliage|Grass|Veget/i.test(root) ? 'Foliage' : /DifOpc|OpacityMask/i.test(root) || (translucent.has(root) && diffuse) ? 'Masked' : /ALIEN/i.test(root) ? 'Alien' : 'Prop',
  }
}
const looks = new Map<number, Look>()
for (const p of [...pieces, ...doors]) for (const m of p.materials) if (m && !looks.has(m)) looks.set(m, lookOf(m))

// The cut-out looks' masks (mask-textures.ts): XCOM 2's cut-out parents read the opacity from Masks, not the diffuse.
// Added now, while the package is small; their mips are made as the textures are inlined. Additions go at the tables'
// ends, so every reference read so far stays good.
const cutOut = new Map<string, number>()
for (const l of looks.values())
  if ((l.kind === 'Masked' || l.kind === 'Foliage') && l.diffuse) {
    const k = exports.findIndex((e) => e.fullName === l.diffuse && e.type === 'Texture2D')
    if (k >= 0) cutOut.set(l.diffuse, k + 1)
  }
const masked = addMaskTextures(bytes, [...cutOut.values()])
for (const l of looks.values()) if (masked.masks.has(cutOut.get(l.diffuse) ?? 0)) l.mask = l.diffuse + '_LWX2Mask'
bytes = masked.bytes
meta = new Package(bytes)
pkg = openPackage(bytes)
exports = meta.exports as any[]
v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
const maskExports = new Set([...masked.masks.values()].map((r) => exports[r - 1]))

// --- The package: the world neutralized, the carried packages and the caches renamed -
// XCOM 2 reads every object of a package it loads, and reads EW's level objects wrong.
// So each object of the world becomes a plain object of a simple class the package
// already uses (PhysicalMaterial): no archetype, plain flags, and as data a stub
// appended to the file: a net index and "None" (no properties).
const donor = exports.find((e) => e.type === 'PhysicalMaterial')
if (!donor) throw new Error('no PhysicalMaterial in the package to borrow a class from')
const donorClass = v.getInt32(donor.entryOffset + 0, true)
const donorFlagsLo = v.getUint32(donor.entryOffset + 24, true)
const donorFlagsHi = v.getUint32(donor.entryOffset + 28, true)
const noneIndex = meta.names.indexOf('None')
const stubAt = bytes.length
const stub = new Uint8Array(12)
new DataView(stub.buffer).setInt32(0, -1, true)
new DataView(stub.buffer).setInt32(4, noneIndex, true)
let neutralized = 0
exports.forEach((e) => {
  if (e.fullName.split('.')[0] !== 'TheWorld') return
  const at = e.entryOffset
  v.setInt32(at + 0, donorClass, true) // class
  v.setInt32(at + 4, 0, true) // super
  v.setInt32(at + 20, 0, true) // archetype
  v.setUint32(at + 24, donorFlagsLo, true)
  v.setUint32(at + 28, donorFlagsHi, true)
  v.setInt32(at + 32, stub.length, true) // serial size
  v.setInt32(at + 36, stubAt, true) // serial offset
  neutralized++
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
// The carried packages nested in the map's own package rather than loaded as packages of their own: their forced-export
// flag cleared, so Qighway_B.Meshes.X is URB_HighwayFallen.Qighway_B.Meshes.X. A plot (ew-plot.ts) can then import them
// the ordinary way, by loading the map's package.
let nested = 0
exports.forEach((e) => {
  if (e.type !== 'Package' || e.outer !== 0) return
  const at = e.entryOffset + 40
  const flags = v.getUint32(at, true)
  if (flags & 1) {
    v.setUint32(at, flags & ~1, true)
    nested++
  }
})
// The textures with their mips uncompressed in the package (inline-textures.ts), after the stub.
const tex = inlineTextures(bytes, exports, meta.names, dirname(src), stubAt + stub.length, (e) => e.fullName.startsWith('TheWorld'),
  (e, format, mip) => (maskExports.has(e) ? maskMip(format, mip) : undefined))
const outBytes = new Uint8Array(bytes.length + stub.length + tex.appended.length)
outBytes.set(bytes)
outBytes.set(stub, stubAt)
outBytes.set(tex.appended, stubAt + stub.length)
writeFileSync(out, outBytes)

// --- The pieces as config ------------------------------------------------------------
// Names are shared by everything in the package: a mesh named like a carried package was renamed with it.
// What is in a carried package is under the map's own package now (above): its path starts with the map's name.
const mapPackage = basename(out, '.upk')
const carriedNames = new Set(renamedPackages.values())
const rename = (path: string) => {
  // No path stays none (a look without a normal map, glass without a diffuse): written as the map package's name and a
  // dot, the plot took it for a texture, and glass for an opaque surface (black windows, the person, 2026-11-04).
  if (!path) return ''
  const p = path.split('.').map((part) => renamedPackages.get(part) ?? CACHES[part] ?? part).join('.')
  // Carried content, and objects at the root of the map's own package (a path of one part: URB_OfficePaper_EWI has a
  // StaticMesh_0 there, its road stripes; left bare, the plot imported a package of that name and the game crashed as
  // it built the map, lw-missions.md) are the map package's.
  return carriedNames.has(p.split('.')[0]!) || !p.includes('.') ? `${mapPackage}.${p}` : p
}
const n = (x: number) => (Math.abs(x) < 1e-4 ? '0' : String(Math.round(x * 1000) / 1000))
/** A piece's cover flags where they differ from an XComLevelActor's defaults (what the plot places). */
const coverText = (c: Cover) =>
  (c.onto ? '' : ',ClimbOnto=false') + (c.over ? ',ClimbOver=true' : '') + (c.destination ? '' : ',Destination=false')
  + (c.ignore ? ',IgnoreForCover=true' : '') + (c.force !== 'CoverForce_Default' ? `,CoverForce=${c.force}` : '')
const lines = [
  `; The static meshes of ${basename(src)}, converted on this machine by tools/convert/ew-map.ts.`,
  // The converter's version: a section without it (or with an older one) is converted again (ew-maps.ts).
  `; ew-map.ts ${CONVERTER_VERSION}`,
  '; Not in the repository: generated from the player\'s own Enemy Within install.',
  // One section per map (LWX2EWMapData, per-object config): a machine's maps are these sections joined
  // (tools/convert/ew-maps.ts); the shared settings are the mod's own (XComLWEWMaps.ini).
  `[${basename(src, '.upk')} LWX2EWMapData]`,
  `MapPackage="${basename(out, '.upk')}"`,
  ...(play
    ? [
        '; The play area (EW\'s level volume: centre and half sizes) and the drop zones (its player starts).',
        `PlayCenter=(X=${n(play.center[0]!)},Y=${n(play.center[1]!)},Z=${n(play.center[2]!)})`,
        `PlayExtent=(X=${n(play.extent[0]!)},Y=${n(play.extent[1]!)},Z=${n(play.extent[2]!)})`,
      ]
    : []),
  ...starts.map((p) => `+DropZones=(X=${n(p[0]!)},Y=${n(p[1]!)},Z=${n(p[2]!)})`),
  "; EW's building volumes (centre, half sizes) and their floors (each floor's volumes as one box), for the plot's building visibility.",
  ...doors.map(
    (d) =>
      `+Doors=(Mesh="${rename(d.mesh)}",Materials=(${d.materials.map((m) => `"${m ? rename(pathOf(m)) : ''}"`).join(',')}),AnimTree="${rename(d.tree)}",Physics="${rename(d.physics)}",AnimSets=(${d.sets.map((x) => `"${rename(x)}"`).join(',')}),` +
      `Loc=(X=${n(d.loc[0]!)},Y=${n(d.loc[1]!)},Z=${n(d.loc[2]!)}),Rot=(Pitch=${d.rot[0]},Yaw=${d.rot[1]},Roll=${d.rot[2]}),Scale=(X=${n(d.scale[0]!)},Y=${n(d.scale[1]!)},Z=${n(d.scale[2]!)}),` +
      `Idle=${d.idle || 'None'},BlocksSight=${d.blocksSight},Window=${d.window},Points=(${d.points.map((q) => `(Src=${q.src},Dest=${q.dest || 'None'},Anim=${q.anim || 'None'},Destroy=${q.destroy || 'None'},Inactive=${q.inactive || 'None'},Facing=${q.facing},Mirror=${q.mirror})`).join(',')}))`,
  ),
  ...buildings.map(
    (b) =>
      `+Buildings=(Center=(X=${n(b.center[0]!)},Y=${n(b.center[1]!)},Z=${n(b.center[2]!)}),Extent=(X=${n(b.extent[0]!)},Y=${n(b.extent[1]!)},Z=${n(b.extent[2]!)}),Floors=(${b.floors.map((f) => `(Center=(X=${n(f.center[0]!)},Y=${n(f.center[1]!)},Z=${n(f.center[2]!)}),Extent=(X=${n(f.extent[0]!)},Y=${n(f.extent[1]!)},Z=${n(f.extent[2]!)}))`).join(',')})${b.ufo ? ',Ufo=true' : ''})`,
  ),
  "; EW's alien pods (the commander's, how many aliens; Level: the sub-level it is in, none: the map's own) and its spawn points.",
  ...pods.map((p) => `+Pods=(Loc=(X=${n(p.loc[0]!)},Y=${n(p.loc[1]!)},Z=${n(p.loc[2]!)}),Commander=${p.commander},Min=${p.min},Max=${p.max}${p.level ? `,Level=${p.level}` : ''})`),
  ...spawnPoints.filter((p) => !p[3]).map((p) => `+SpawnPoints=(X=${n(p[0]!)},Y=${n(p[1]!)},Z=${n(p[2]!)})`),
  ...spawnPoints.filter((p) => p[3]).map((p) => `+CivilianSpawns=(X=${n(p[0]!)},Y=${n(p[1]!)},Z=${n(p[2]!)})`),
  "; EW's lights (point, spot, its sun and sky), spawned as movable lights.",
  ...lights.map(
    (l) =>
      `+Lights=(Kind=${l.kind},Loc=(X=${n(l.loc[0]!)},Y=${n(l.loc[1]!)},Z=${n(l.loc[2]!)}),Rot=(Pitch=${l.rot[0]},Yaw=${l.rot[1]},Roll=${l.rot[2]}),` +
      `Radius=${n(l.radius)},Brightness=${n(l.brightness)},Color=(R=${l.color[0]},G=${l.color[1]},B=${l.color[2]},A=${l.color[3]}),` +
      `Falloff=${n(l.falloff)},Inner=${n(l.inner)},Outer=${n(l.outer)},Lower=${n(l.lower)})`,
  ),
  "; Each EW material's textures, for the XCOM 2 parent of its kind (XComLWEWMaps.ini).",
  ...[...looks].map(
    ([r, l]) => `+Looks=(Material="${rename(pathOf(r))}",Kind=${l.kind},Diffuse="${rename(l.diffuse)}",Normal="${rename(l.normal)}"${l.mask ? `,Mask="${rename(l.mask)}"` : ''})`,
  ),
  ...pieces.map(
    (p) =>
      `+Pieces=(Mesh="${rename(p.mesh)}",Loc=(X=${n(p.loc[0]!)},Y=${n(p.loc[1]!)},Z=${n(p.loc[2]!)}),Rot=(Pitch=${p.rot[0]},Yaw=${p.rot[1]},Roll=${p.rot[2]}),Scale=(X=${n(p.scale[0]!)},Y=${n(p.scale[1]!)},Z=${n(p.scale[2]!)})${p.materials.length ? `,Materials=(${p.materials.map((m) => `"${m ? rename(pathOf(m)) : ''}"`).join(',')})` : ''}${isBackdrop(p) ? ',Backdrop=true' : ''}${p.fractured ? ',Fractured=true' : ''}${p.frac ? `,Frac=(Indices=${p.frac.indices},MinZ=${n(p.frac.minZ)},MaxZ=${n(p.frac.maxZ)},Toughness=${p.frac.toughness || 'None'})` : ''}${coverText(p.cover)})`,
  ),
]
writeFileSync(iniOut, lines.join('\r\n') + '\r\n')
const meshes = new Set(pieces.map((p) => p.mesh))
console.log(`${out}: world neutralized (${neutralized} objects), ${renamedPackages.size} carried packages renamed (${nested} nested), ${tex.textures} textures rewritten (${tex.mips} mips, ${(tex.appended.length / 1e6).toFixed(0)} MB), ${masked.masks.size} masks for cut-out looks`)
const noDiffuse = [...looks.values()].filter((l) => !l.diffuse).length
console.log(`${iniOut}: ${looks.size} materials (${noDiffuse} without a diffuse map found)`)
console.log(`${iniOut}: ${pods.length} pods, ${spawnPoints.length} spawn points (${spawnPoints.filter((p) => p[3]).length} civilian), ${lights.length} lights, ${buildings.length} buildings (${buildings.reduce((a, b) => a + b.floors.length, 0)} floors)`)
console.log(`${iniOut}: ${pieces.length} pieces of ${meshes.size} meshes, ${doors.length} doors${renumbered ? `; ${renumbered} objects of a name shared renumbered` : ''}${Object.keys(skipped).length ? `; components not read: ${JSON.stringify(skipped)}` : ''}`)
}

// From the command line: node tools/convert/ew-map.ts <EW map .upk> <out .upk> <out pieces .ini>
if (/ew-map\.ts$/.test(process.argv[1] ?? '')) {
  const [src, out, iniOut] = process.argv.slice(2).filter((a) => a !== '--')
  if (!iniOut) {
    console.error('usage: ew-map.ts <EW map .upk> <out .upk> <out pieces .ini>')
    process.exit(2)
  }
  convertMap(src!, out!, iniOut!)
}

