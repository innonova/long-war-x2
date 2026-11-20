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
import { addMaskTextures, addTextureCopies, maskMip } from './mask-textures.ts'
import { scaleMip, tintMip, whiteMip } from './tint-textures.ts'
import { combineLightmapMip } from './lightmap-bake.ts'
import { cameras as matineeCameras, matineeAxisPoses, peopleIn } from './ew-people.ts'

/** Raised when what a conversion writes changes so that maps converted before must be converted again
 *  (2: carried packages nested in the map's package, for its plot; 3: its building volumes and floors; 4: terror pods,
 *  spawn points by type; 5: the walls, EW's fracturable meshes; meshes at the root of the map's package; objects of one
 *  name made unique; materials cut out by their diffuse's alpha, a kind of their own; 6: walls marked fractured, so the
 *  plot imports them as such; the buildings' surface textures, Diffuse_Base; 7: the doors, the pieces' cover flags;
 *  8: the walls' fracture data and toughness, for XCOM 2's breakable walls; 9: the textures of materials cooked without
 *  their expressions, read from the compiled shader (the road paint, asphalt patches), translucent ones masked; 10: masks for the
 *  cut-out looks, the diffuse's alpha in green and blue, which XCOM 2's cut-out parents read their opacity from;
 *  11: vehicles not to be stood on; 12: nor sandbags; 13: their tops no valid destinations; 14: no path written as
 *  none, not as the map's name and a dot; 15: EW's materials made inert, XCOM 2 compiling each as the map loaded;
 *  16: the meld canisters' places, MeldPoints; 17: what units see through (EW's VisibilityBlockingData on every piece:
 *  windows, foliage, cars), written onto the plot's pieces; 21: EW's lightmaps, its glowing parts' colours, its 3D UI
 *  panels, features/ew-lightmaps.md and ew-3d-screens.md; 22: EW's people, ew-base-people.md; 23: people hidden in their level left out, as the armory's MEC scene); 24: the plinths soldiers stand on
 *  (Spots: EW's SkeletalMeshActors tagged …Plinth, XGStrategySoldier.PlaceOnPlinth); 25: the hangar's bays (People with
 *  Bay, BayState, BayPart: Anim_Hangar_LaunchBays' launch pads and craft), a diffuse named plain "diff" (the Skyranger's); 26: EW's people where their matinee puts them, in their base's frame
 *  (an actor's Base: the scene's CineDummy, itself placed by its key); 27: people's glowing slots (Glow, Tint: the Genetics
 *  Lab's tank glass).; 28: people's colour mods baked into tinted diffuses (tint-textures.ts:
 *  the clerks' uniforms).; 29: cameras where a matinee leaves them by axes
 *  (the main menu's).; 30: pieces whose component EW hides in play (HiddenGame) left out.; 31: the lightmap atlases public
 *  (the plots import them).; 32: EW's hair brightened (its hair parent's lightening, baked: tint-textures.ts scaleMip).; 33:
 *  a look's tiling (Tile: EW's MainTile_U).; 34: the tinted copies named without a trailing "_<digits>".; 35: the colour
 *  mods twice as bright.; 36: EW's emitters and their sprites (Emitters, ParticleLooks).; 37: EW's lens flares (Flares,
 *  FlareLooks).; 38: emitters EW keeps still or off left out, their draw distance kept.; 39: their time dilation.; 40:
 *  the console screens' picture made white for our glow to tint (whiteMip).; 41: EW's people brightened (PEOPLE_SCALE).;
 *  42: the props' tiling (Tile U) too.; 43: brightened textures decoded and encoded again (no black blocks).; 44: the custom
 *  screens' decal sheet, whitened, as their picture.; 45: taken back (the whole sheet showed). */
export const CONVERTER_VERSION = 57

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
interface Cover { onto: boolean; over: boolean; destination: boolean; ignore: boolean; force: string; sight: boolean; window: boolean; ontoSet?: boolean; floor?: boolean }
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
      // Whether units see through it (EW's windows, glass: bBlockUnitVisibility off), as for the doors.
      else if (t.name === 'VisibilityBlockingData' && found.sight === undefined) {
        const vis = readTags(new Reader(t.value), pkg)
        found.sight = vis.find((x) => x.name === 'bBlockUnitVisibility')?.boolValue !== 0
        found.window = !!vis.find((x) => x.name === 'bIsWindow')?.boolValue
      }
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
    ontoSet: found.onto !== undefined,
    over: found.over ?? d.over ?? false,
    destination: found.destination ?? d.destination ?? true,
    ignore: found.ignore ?? d.ignore ?? false,
    force: found.force ?? 'CoverForce_Default',
    sight: found.sight ?? true,
    window: found.window ?? false,
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
/** A piece's baked lighting (features/ew-lightmaps.md): its two atlases (EW's colour and directional coefficients) and their
 *  scales, and where its part of them lies: lightmap UV = the mesh's lightmap UV set × scale + bias. */
interface LightMap { color: number; dir: number; s0: number[]; s1: number[]; scale: number[]; bias: number[]; uv: number }
interface Piece { lightmap?: LightMap; mesh: string; loc: number[]; rot: number[]; scale: number[]; materials: number[]; extent: number[]; fractured: boolean; cover: Cover; frac?: Frac }
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
  // (Nor one whose mesh EW keeps hidden in play: Command1's stray sidewalk tile in front of the hangar; converter 30.)
  if ((ctags.find((t) => t.name === 'HiddenGame') as { boolValue?: number } | undefined)?.boolValue) return
  const lightmap = lightmapOf(ref(comp), mesh)
  // (A placed actor stores only what differs from its archetype: one standing where its archetype stands has no Location
  // of its own, and was put at the origin until converter 18: Street Hurricane's storefront row then covered its drop zone.)
  const loc = inherited(i, tags, 'Location', 26)
  const rot = inherited(i, tags, 'Rotation', 26)
  const ds = inherited(i, tags, 'DrawScale', 26)
  const ds3 = inherited(i, tags, 'DrawScale3D', 26)
  const s = ds ? f32(ds, 0) : 1
  pieces.push({
    lightmap,
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

/** EW's 3D UI panels (UIDisplay_LevelActor, placed by tag: EW's screens draw on them, features/ew-3d-screens.md). */
interface Display { tag: string; loc: number[]; rot: number[]; scale: number[]; mesh: string }
const displays: Display[] = []
exports.forEach((e, i) => {
  if (e.type !== 'UIDisplay_LevelActor' || !e.fullName.startsWith('TheWorld.PersistentLevel.')) return
  const tags = actorTags(i)
  if (!tags) return
  const tag = inherited(i, tags, 'Tag', 26)
  const loc = inherited(i, tags, 'Location', 26)
  const rot = inherited(i, tags, 'Rotation', 26)
  const ds = inherited(i, tags, 'DrawScale', 26)
  const ds3 = inherited(i, tags, 'DrawScale3D', 26)
  const s1 = ds ? f32(ds, 0) : 1
  // Its panel's mesh: EW's own, whose UVs take the screen's part of the movie (the Situation Room's wall is eight panels).
  const comp = inherited(i, tags, 'StaticMeshComponent', 26)
  let mesh = ''
  if (comp && ref(comp) > 0) {
    try {
      mesh = meshOf(ref(comp) - 1, tagsOf(ref(comp) - 1, 8))
    } catch {
      // none read
    }
  }
  displays.push({
    mesh,
    tag: tag ? (pkg.names[new DataView(tag.value.buffer, tag.value.byteOffset).getInt32(0, true)].name as string) : '',
    loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)],
    rot: [i32(rot, 0), i32(rot, 1), i32(rot, 2)],
    scale: ds3 ? [f32(ds3, 0) * s1, f32(ds3, 1) * s1, f32(ds3, 2) * s1] : [s1, s1, s1],
  })
})

/** EW's emitters (steam, mist, light beams, blinking lights: features/ew-emitters.md): each placed Emitter's particle
 *  system, where it stands; the systems' sprites' textures are read later (particleLooks), with the materials. */
interface EmitterPlace { template: number; loc: number[]; rot: number[]; scale: number; maxDraw: number; dilation: number }
const emitterPlaces: EmitterPlace[] = []
/** A component's property, its own or its archetype's (placed components store only what differs). */
function componentTag(index: number, name: string): Tag | undefined {
  for (let depth = 0; depth < 8 && index >= 0; depth++) {
    for (const start of [8, 4, 12, 16]) {
      try {
        const t = tagsOf(index, start).find((x) => x.name === name)
        if (t) return t
        break
      } catch {
        // not from here
      }
    }
    const arch = archetypeOf(index)
    if (arch <= 0) return undefined
    index = arch - 1
  }
  return undefined
}
/** An object property of a component, its own or its archetype's (placed components store only what differs). */
function componentObject(index: number, name: string): number {
  for (let depth = 0; depth < 8 && index >= 0; depth++) {
    for (const start of [8, 4, 12, 16]) {
      try {
        const t = tagsOf(index, start).find((x) => x.name === name)
        if (t) return ref(t)
        break
      } catch {
        // not from here
      }
    }
    const arch = archetypeOf(index)
    if (arch <= 0) return 0
    index = arch - 1
  }
  return 0
}
exports.forEach((e, i) => {
  if (e.type !== 'Emitter' || !e.fullName.startsWith('TheWorld.PersistentLevel.') || e.fullName.split('.').length !== 3) return
  const tags = actorTags(i)
  if (!tags || (tags.find((t) => t.name === 'bHidden') as { boolValue?: number } | undefined)?.boolValue) return
  const comp = inherited(i, tags, 'ParticleSystemComponent', 26)
  const template = comp && ref(comp) > 0 ? componentObject(ref(comp) - 1, 'Template') : 0
  if (!template) return
  // (Not one EW keeps still or off: its time frozen, CustomTimeDilation 0; not started, bAutoActivate off; converter 38.)
  const dil = componentTag(ref(comp) - 1, 'CustomTimeDilation')
  if (dil && f32(dil, 0) === 0) return
  const auto = componentTag(ref(comp) - 1, 'bAutoActivate') as { boolValue?: number } | undefined
  if (auto && !auto.boolValue) return
  const md = componentTag(ref(comp) - 1, 'MaxDrawDistance')
  const loc = inherited(i, tags, 'Location', 26)
  const rot = inherited(i, tags, 'Rotation', 26)
  const ds = inherited(i, tags, 'DrawScale', 26)
  emitterPlaces.push({ template, loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)], rot: [i32(rot, 0), i32(rot, 1), i32(rot, 2)], scale: ds ? f32(ds, 0) : 1, maxDraw: md ? f32(md, 0) : 0, dilation: dil ? f32(dil, 0) : 1 })
})

/** EW's lens flares (the autopsy lamp's glow, the labs' lamp streaks: features/ew-emitters.md): each placed
 *  LensFlareSource's flare, where it stands; its elements' textures are read later (flareLooks). */
interface FlarePlace { template: number; loc: number[] }
const flarePlaces: FlarePlace[] = []
exports.forEach((e, i) => {
  if (e.type !== 'LensFlareSource' || !e.fullName.startsWith('TheWorld.PersistentLevel.') || e.fullName.split('.').length !== 3) return
  const tags = actorTags(i)
  if (!tags) return
  const comp = inherited(i, tags, 'LensFlareComp', 26)
  const template = comp && ref(comp) > 0 ? componentObject(ref(comp) - 1, 'Template') : 0
  if (!template) return
  const loc = inherited(i, tags, 'Location', 26)
  flarePlaces.push({ template, loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)] })
})

/**
 * A static mesh component's baked lighting, after its properties (the component's leading 8 bytes, then the tagged
 * properties): its LODs; the first's shadow maps and shadow vertex buffers (counts and references), then its light map:
 * the type (2: a 2D lightmap), the lights' GUIDs, three coefficients (an atlas and a scale, three floats), the atlas
 * placement's scale and bias (two floats each). Read from EW's Static_ScienceLabs; undefined where it is not that.
 */
function lightmapOf(r: number, mesh: string): LightMap | undefined {
  if (r <= 0) return undefined
  const d: Uint8Array = pkg.data(r)
  const rd = new Reader(d.subarray(8))
  try {
    readTags(rd, pkg)
  } catch {
    return undefined
  }
  const dv = new DataView(d.buffer, d.byteOffset, d.byteLength)
  let o = 8 + (rd as unknown as { o: number }).o
  const i = () => {
    const x = dv.getInt32(o, true)
    o += 4
    return x
  }
  const f = () => {
    const x = dv.getFloat32(o, true)
    o += 4
    return x
  }
  try {
    const lods = i()
    if (lods < 1 || lods > 8) return undefined
    const shadowMaps = i()
    if (shadowMaps < 0 || shadowMaps > 64) return undefined
    o += 4 * shadowMaps
    const shadowBuffers = i()
    if (shadowBuffers < 0 || shadowBuffers > 64) return undefined
    o += 4 * shadowBuffers
    if (i() !== 2) return undefined
    const guids = i()
    if (guids < 0 || guids > 256) return undefined
    o += 16 * guids
    const coef = [0, 1, 2].map(() => ({ tex: i(), s: [f(), f(), f()] }))
    const scale = [f(), f()]
    const bias = [f(), f()]
    if (!coef[0]!.tex || !coef[1]!.tex || !(scale[0]! > 0) || !(scale[1]! > 0)) return undefined
    const isLM = (t: number) => t > 0 && exports[t - 1]?.type === 'LightMapTexture2D'
    if (!isLM(coef[0]!.tex) || !isLM(coef[1]!.tex)) return undefined
    // The mesh's lightmap UV set (StaticMesh.LightMapCoordinateIndex; EW's are 1).
    const mi = exports.findIndex((x) => x.fullName === mesh)
    let uv = 1
    if (mi >= 0) {
      try {
        const mt = tagsOf(mi, 4).find((t) => t.name === 'LightMapCoordinateIndex')
        if (mt) uv = new DataView(mt.value.buffer, mt.value.byteOffset).getInt32(0, true)
      } catch {
        // its default
      }
    }
    return { color: coef[0]!.tex, dir: coef[1]!.tex, s0: coef[0]!.s, s1: coef[1]!.s, scale, bias, uv }
  } catch {
    return undefined
  }
}

/** The backdrop (the sky dome, the mountains): too big to be ground; it must not collide, or it encloses the map. */
const isBackdrop = (p: Piece) => p.extent[0]! > 2400 || p.extent[1]! > 2400 || p.extent[2]! > 1200
const extents = new Map<string, number[]>()
for (const p of pieces) {
  if (!extents.has(p.mesh)) extents.set(p.mesh, meshExtent(p.mesh))
  p.extent = extents.get(p.mesh)!.map((x, k) => Math.abs(x * p.scale[k]!))
  // (A fracturable piece two tiles wide each way is a building's core or a slab, its top a roof or a floor: EW's class
  // default, not to be climbed onto, is for walls, and XCOM 2 then makes no floor on top: Commercial Restaurant's roof
  // terrace, a data recovery's capture area, had none.)
  if (p.fractured && !p.cover.ontoSet && p.extent[0]! >= 96 && p.extent[1]! >= 96 && !/^(VEH_|SandBag\.)/.test(p.mesh)) {
    p.cover.onto = true
    // (XCOM 2 makes a floor of a breakable piece only when it says so, bIsFloor: EW's floor tiles did not ask. The plot
    // writes it, and to be stood on, over XCOM 2's wall default. Converter 20.)
    p.cover.floor = true
  }
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
/** EW's base (features/lw-base-view.md): its room locations (XComHQ_RoomLocation, tagged R<row>_C<column>) and its cameras
 *  (CameraActor: the base's view, each tile's, each room's and its displays'), by their tags. */
const rooms: { tag: string; loc: number[] }[] = []
const cameras: { tag: string; loc: number[]; rot: number[]; fov: number }[] = []
/** EW's plinths (SkeletalMeshActors tagged ArmorySoldierPlinth, GeneLabSoldierPlinth, CyberneticsLabMecPlinth): where EW
 *  stands a soldier or MEC for a screen (XGStrategySoldier.PlaceOnPlinth), by tag. */
const spots: { tag: string; loc: number[]; rot: number[] }[] = []
// EW's meld canisters' places (XComMeldContainerSpawnPoint: lw-loot.md): its spawn group (the drop zone's, in order), the
// turn it self-destructs on (EW's default 3), hard or easy.
const meldPoints: { loc: number[]; group: number; turns: number; hard: boolean }[] = []
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
// EW's atmosphere (features/ew-lightmaps.md): its WorldInfo's height fog (XComHeightFog) and its default post-process's
// colour grading (Scene_Colorize, _Shadows, _HighLights, _MidTones, _Desaturation), where the level sets them.
const atmosphere: { fog?: Record<string, number | number[]>; grade: Record<string, number | number[]> } = { grade: {} }
exports.forEach((e, i) => {
  if (e.type !== 'WorldInfo' || !e.fullName.startsWith('TheWorld.PersistentLevel.')) return
  let t: Tag[] = []
  for (const start of [26, ...Array.from({ length: 81 }, (_, k) => k)]) {
    try {
      t = readTags(new Reader(pkg.data(i + 1).subarray(start)), pkg)
      if (t.some((x) => x.name === 'DefaultPostProcessSettings' || x.name === 'XComHeightFog')) break
    } catch {
      t = []
    }
  }
  const inner = (name: string) => {
    const s = t.find((x) => x.name === name)
    try {
      return s ? (readTags(new Reader(s.value), pkg) as Tag[]) : []
    } catch {
      return []
    }
  }
  const value = (x: Tag): number | number[] | undefined =>
    x.type === 'FloatProperty' ? new DataView(x.value.buffer, x.value.byteOffset).getFloat32(0, true)
    : x.type === 'BoolProperty' ? (x as { boolValue?: number }).boolValue ?? 0
    : x.type === 'StructProperty' && (x as { structName?: string }).structName === 'Color' ? [...x.value.slice(0, 4)]
    : x.type === 'StructProperty' && x.value.length === 12 ? [0, 1, 2].map((k) => new DataView(x.value.buffer, x.value.byteOffset).getFloat32(4 * k, true))
    : undefined
  const fog = inner('XComHeightFog')
  if (fog.length) {
    atmosphere.fog = {}
    for (const x of fog) { const v = value(x); if (v !== undefined) atmosphere.fog[x.name] = v }
  }
  for (const x of inner('DefaultPostProcessSettings')) {
    if (!/^Scene_/.test(x.name)) continue
    const v = value(x)
    if (v !== undefined) atmosphere.grade[x.name] = v
  }
})
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
const axisPoses = (() => {
  try {
    return matineeAxisPoses(meta, pkg)
  } catch {
    return new Map<number, { loc: (number | undefined)[]; rot: (number | undefined)[] }>()
  }
})()
exports.forEach((e, i) => {
  const parts = e.fullName.split('.')
  if (parts[0] !== 'TheWorld' || parts.length !== 3) return
  if (e.type === 'PlayerStart') {
    const t = actorTags(i)
    const loc = t?.find((x) => x.name === 'Location')
    if (loc) starts.push([f32(loc, 0), f32(loc, 1), f32(loc, 2)])
  }
  if (/SkeletalMeshActor/.test(e.type)) {
    const t = actorTags(i)
    const tag = t?.find((x) => x.name === 'Tag')
    const loc = t?.find((x) => x.name === 'Location')
    const name = tag ? meta.names[new DataView(tag.value.buffer, tag.value.byteOffset).getInt32(0, true)] : ''
    if (name && loc && /Plinth$/.test(name)) {
      const rot = t!.find((x) => x.name === 'Rotation')
      spots.push({ tag: name, loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)], rot: rot ? [i32(rot, 0), i32(rot, 1), i32(rot, 2)] : [0, 0, 0] })
    }
  }
  if (e.type === 'XComHQ_RoomLocation' || e.type === 'CameraActor') {
    const t = actorTags(i)
    const tag = t?.find((x) => x.name === 'Tag')
    const loc = t?.find((x) => x.name === 'Location')
    const name = tag ? meta.names[new DataView(tag.value.buffer, tag.value.byteOffset).getInt32(0, true)] : ''
    if (!name || !loc) return
    if (e.type === 'XComHQ_RoomLocation') rooms.push({ tag: name, loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)] })
    else {
      const rot = t!.find((x) => x.name === 'Rotation')
      const fov = t!.find((x) => x.name === 'FOVAngle')
      // (Where a matinee leaves it, by axes, if one moves it: the main menu's camera, XComShell's LeftShoulder.)
      const pose = axisPoses.get(i + 1)
      const at = [f32(loc, 0), f32(loc, 1), f32(loc, 2)].map((x, k) => pose?.loc[k] ?? x)
      const turn = [i32(rot, 0), i32(rot, 1), i32(rot, 2)].map((x, k) => pose?.rot[k] ?? x)
      cameras.push({ tag: name, loc: at, rot: turn, fov: fov ? f32(fov, 0) : 90 })
    }
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
  if (e.type === 'XComMeldContainerSpawnPoint') {
    const t = actorTags(i)
    const loc = t?.find((x) => x.name === 'Location')
    if (!loc) return
    const group = t!.find((x) => x.name === 'm_iSpawnGroup')
    const turns = t!.find((x) => x.name === 'm_iDestroyedOnTurn')
    const diff = t!.find((x) => x.name === 'm_eDifficulty')
    const diffName = diff && diff.value.byteLength >= 8 ? meta.names[new DataView(diff.value.buffer, diff.value.byteOffset).getInt32(0, true)] : ''
    meldPoints.push({ loc: [f32(loc, 0), f32(loc, 1), f32(loc, 2)], group: group ? i32(group, 0) : 0, turns: turns ? i32(turns, 0) : 3, hard: /Hard/.test(diffName ?? '') })
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
interface Look { diffuse: string; normal: string; kind: 'Prop' | 'Foliage' | 'Masked' | 'Alien' | 'Glow'; mask?: string; tint?: number[]; tile?: number }
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
  const diffuse = pick(['Diffuse', 'Diffuse_Base', 'Grass', 'Diffuse_Grass', 'Diffuse_Rock', 'Hairstyle Texture'], /(_DIFF?|_D|Diffuse|_Dif|^diff)\d*$/i)
  return {
    diffuse,
    normal: pick(['Normal', 'Normal_Base', 'Leaves_Normal', 'Dirt_Normal', 'Rock_Normal', 'Normal Map'], /(_NRM|_NORM|_N|Normal|_Nrm)\d*$/i),
    // Masked: cut out by the diffuse's alpha (tree cards, signs, fences: PROP_DifOpc, PROP_OpacityMask_Tile; and a
    // translucent parent's, as the road paint's, whose diffuse alpha holds the paint).
    kind: /Foliage|Grass|Veget/i.test(root) ? 'Foliage' : /DifOpc|OpacityMask/i.test(root) || (translucent.has(root) && diffuse) ? 'Masked' : /ALIEN/i.test(root) ? 'Alien' : 'Prop',
    // (How often EW's material tiles its main texture, where it says: the base's cave rock twice, MainTile_U; converter 33.)
    // (And EW's props' Tile U, the grilles' and panels' 2 and 4; converter 42.)
    tile: (() => { const t = scalarParam(r, 'MainTile_U') ?? scalarParam(r, 'Tile U'); return t && t > 0 && t !== 1 ? t : undefined })(),
  }
}
/**
 * A material's scalar parameter: its own or a parent instance's value, else its root material's default (the
 * parameter expression's DefaultValue). EW's cave rock tiles by MainTile_U (2).
 */
function scalarParam(r: number, name: string, depth = 0): number | undefined {
  if (r <= 0 || depth > 8) return undefined
  let tags: Tag[]
  try {
    tags = tagsOf(r - 1, 4)
  } catch {
    return undefined
  }
  const sp = tags.find((t) => t.name === 'ScalarParameterValues')
  if (sp) {
    const rd = new Reader(sp.value.subarray(4))
    const count = new DataView(sp.value.buffer, sp.value.byteOffset).getInt32(0, true)
    for (let k = 0; k < count; k++) {
      const st = readTags(rd, pkg)
      const pn = st.find((t) => t.name === 'ParameterName')
      const pv = st.find((t) => t.name === 'ParameterValue')
      if (pn && pv && nameOf(pn) === name) return new DataView(pv.value.buffer, pv.value.byteOffset).getFloat32(0, true)
    }
  }
  const parent = tags.find((t) => t.name === 'Parent')
  if (parent) return scalarParam(ref(parent), name, depth + 1)
  // (The root material: its parameter expression's default.)
  const root = exports[r - 1]
  if (!root) return undefined
  for (let k = 0; k < exports.length; k++) {
    const e = exports[k]!
    if (e.type !== 'MaterialExpressionScalarParameter' || !e.fullName.startsWith(root.fullName + '.')) continue
    try {
      const et = tagsOf(k, 4)
      const pn = et.find((t) => t.name === 'ParameterName')
      if (pn && nameOf(pn) === name) {
        const dv = et.find((t) => t.name === 'DefaultValue')
        return dv ? new DataView(dv.value.buffer, dv.value.byteOffset).getFloat32(0, true) : 0
      }
    } catch {
      // (an expression not read)
    }
  }
  return undefined
}
/**
 * A material's colour parameter (a vector parameter of this name on it or a parent instance): EW's glowing parts, light
 * strips and screens, carry theirs in TintColor (HDR: above 1 is brighter).
 */
/** A material instance's vector parameter, its own or its parents'; with withDefault, else the material's expression
 *  default (EW draws that where no instance sets one: the tank glass's olive, a car's paint). Without it, as before: the
 *  people's CMOD is only a colour mod where an instance sets one (with the default, Shen's jacket came out green). */
function vectorParam(r: number, name: string, depth = 0, withDefault = false): number[] | undefined {
  if (r <= 0 || depth > 8) return undefined
  let tags: Tag[]
  try {
    tags = tagsOf(r - 1, 4)
  } catch {
    return undefined
  }
  const vp = tags.find((t) => t.name === 'VectorParameterValues')
  if (vp) {
    const rd = new Reader(vp.value.subarray(4))
    const count = new DataView(vp.value.buffer, vp.value.byteOffset).getInt32(0, true)
    for (let k = 0; k < count; k++) {
      const st = readTags(rd, pkg)
      const pn = st.find((t) => t.name === 'ParameterName')
      const pv = st.find((t) => t.name === 'ParameterValue')
      if (pn && pv && nameOf(pn) === name && pv.value.length >= 16) {
        const d = new DataView(pv.value.buffer, pv.value.byteOffset)
        return [0, 4, 8, 12].map((o) => d.getFloat32(o, true))
      }
    }
  }
  const parent = tags.find((t) => t.name === 'Parent')
  if (parent) return vectorParam(ref(parent), name, depth + 1, withDefault)
  if (!withDefault) return undefined
  // (The material at the chain's end: its parameter expression's default, where no instance sets it.)
  const ex = tags.find((t) => t.name === 'Expressions')
  for (const x of ex ? refs(ex) : []) {
    if (x <= 0 || exports[x - 1]!.type !== 'MaterialExpressionVectorParameter') continue
    let xt: Tag[]
    try {
      xt = tagsOf(x - 1, 4)
    } catch {
      continue
    }
    const pn = xt.find((t) => t.name === 'ParameterName')
    const dvl = xt.find((t) => t.name === 'DefaultValue')
    if (pn && nameOf(pn) === name && dvl && dvl.value.length >= 16) {
      const d = new DataView(dvl.value.buffer, dvl.value.byteOffset)
      return [0, 4, 8, 12].map((o) => d.getFloat32(o, true))
    }
  }
  return undefined
}

/** The textures a material instance's chain ends on: its material's references (its compiled expressions'), by name. */
function materialTexture(r: number, test: RegExp, depth = 0): string | undefined {
  if (r <= 0 || depth > 8) return undefined
  let tags: Tag[]
  try {
    tags = tagsOf(r - 1, 4)
  } catch {
    return undefined
  }
  const parent = tags.find((t) => t.name === 'Parent')
  if (parent) return materialTexture(ref(parent), test, depth + 1)
  const d: Uint8Array = pkg.data(r)
  const v = new DataView(d.buffer, d.byteOffset, d.byteLength)
  for (let o = 0; o + 4 <= d.length; o++) {
    const x = v.getInt32(o, true)
    if (x > 0 && x <= exports.length && exports[x - 1]!.type === 'Texture2D' && test.test(exports[x - 1]!.fullName)) return exports[x - 1]!.fullName
  }
  return undefined
}
/** EW's glowing materials (the base's light rings and strips, its consoles' and walls' screens, the custom screens: the
 *  Genetics Lab's tank faces among them): their own kind, with their colour and, for a screen, its picture. */
// (Not HQ_Master_EmissiveComboPallet: a lamp's housing and its light in one material, the light picked out by something
// cooked away; glowing whole, a lamp seen close (the craft summary's) was a solid orange block.)
const GLOW = /HQ_ColorizedLight|HQ_ConsoleScreen|HQ_CustomScreens|HQ_EmissivePallete/i
const looks = new Map<number, Look>()
for (const p of [...pieces, ...doors]) for (const m of p.materials) if (m && !looks.has(m)) looks.set(m, lookOf(m))
for (const [r, l] of looks) {
  if (!GLOW.test(pathOf(r))) continue
  const tex = new Map<string, string>()
  const root = texturesOf(r, tex)
  l.kind = 'Glow'
  // (The palette lights take theirs in Colorize A.)
  l.tint = vectorParam(r, 'TintColor') ?? vectorParam(r, 'Colorize A')
  // (A custom screen's colour is HDR over a picture of its own, which is cooked away: alone, it drew the screen white; its
  // hue kept, brightest channel 1.)
  if (l.tint && /HQ_CustomScreens/i.test(pathOf(r))) {
    const m = Math.max(l.tint[0]!, l.tint[1]!, l.tint[2]!)
    if (m > 1) l.tint = [l.tint[0]! / m, l.tint[1]! / m, l.tint[2]! / m, 1]
  }
  // (A console's screen its picture; a light, and a custom screen, its colour alone: a custom screen's compiled material
  // draws a region of a decal sheet, HQ_DecalSheet_A, picked by expressions cooked away; the whole sheet on it, tried in
  // converter 44, showed letters and icons. Converter 45.)
  l.diffuse = tex.get('StaticScreenTexture') ?? ''
  void root
}
// EW's people in its base (an Anim_ level's skeletal mesh actors and its matinee's loops: ew-people.ts), their material
// slots read as looks are (diffuse and normal for XCOM 2's skeletal stand-in parent).
const people = (() => {
  try {
    return peopleIn(meta, pkg)
  } catch {
    return []
  }
})()
// (A slot of EW's unlit glowing materials, the Genetics Lab's tanks' glass: a glow in its colour, not a stand-in body.)
const PERSON_GLOW = /TankGlassMaster|HQ_ColorizedLight|EmissivePallete/i
const personSlots = people.map((p) =>
  p.materialRefs.map((m) => {
    if (!m) return undefined
    const l = lookOf(m)
    if (PERSON_GLOW.test(pathOf(m))) {
      l.kind = 'Glow'
      l.tint = vectorParam(m, 'Color') ?? vectorParam(m, 'TintColor')
      // (EW's tank glass: its body is the material's olive, wer (its Color, orange, is the rim's), through its froth
      // texture; the tanks had been flat orange-yellow. Converter 48.)
      if (/TankGlassMaster/i.test(pathOf(m))) {
        l.tint = vectorParam(m, 'wer', 0, true) ?? l.tint
        l.diffuse = materialTexture(m, /Froth/i) ?? ''
      }
    }
    return l
  }),
)
// (And the matinees' cameras the port looks through: the hangar's craft view.)
cameras.push(...matineeCameras)

// EW's emitters' sprites (features/ew-emitters.md): for each particle system placed, each of its emitters' material's
// texture, whether it adds (BLEND_Additive) or blends, and its sub-image grid (an animated sheet), from its first LOD.
interface ParticleLook { template: number; emitter: number; texture: string; additive: boolean; subX: number; subY: number }
const particleLooks: ParticleLook[] = []
for (const template of new Set(emitterPlaces.map((p) => p.template))) {
  if (template <= 0) continue
  let ems: number[] = []
  try {
    const em = tagsOf(template - 1, 4).find((t) => t.name === 'Emitters')
    ems = em ? refs(em) : []
  } catch {
    continue
  }
  ems.forEach((em, k) => {
    if (em <= 0) return
    try {
      const lod = refs(tagsOf(em - 1, 4).find((t) => t.name === 'LODLevels')!)[0]!
      const rq = ref(tagsOf(lod - 1, 4).find((t) => t.name === 'RequiredModule'))
      const rt = tagsOf(rq - 1, 4)
      const mat = ref(rt.find((t) => t.name === 'Material'))
      const tex = new Map<string, string>()
      const root = mat ? texturesOf(mat, tex) : ''
      const texture = tex.get('Texture') ?? tex.get('Diffuse') ?? [...tex.values()][0] ?? ''
      let additive = false
      const rootIndex = exports.findIndex((x) => x.fullName === root && x.type === 'Material')
      if (rootIndex >= 0) {
        const b = tagsOf(rootIndex, 4).find((t) => t.name === 'BlendMode')
        additive = !!b && nameOf(b) === 'BLEND_Additive'
      }
      const int = (n: string) => { const t = rt.find((x) => x.name === n); return t ? new DataView(t.value.buffer, t.value.byteOffset).getInt32(0, true) : 1 }
      if (texture) particleLooks.push({ template, emitter: k, texture, additive, subX: int('SubImages_Horizontal'), subY: int('SubImages_Vertical') })
    } catch {
      // an emitter not read: left as it is
    }
  })
}

// EW's lens flares' elements (features/ew-emitters.md): each flare's source element (-1) and reflections (0…), the
// texture of each one's first material.
interface FlareLook { template: number; element: number; texture: string }
const flareLooks: FlareLook[] = []
for (const template of new Set(flarePlaces.map((p) => p.template))) {
  if (template <= 0) continue
  try {
    const t = tagsOf(template - 1, 4)
    const lookOfElement = (st: Tag[], element: number) => {
      const lm = st.find((x) => x.name === 'LFMaterials')
      const mat = lm ? refs(lm)[0] ?? 0 : 0
      const tex = new Map<string, string>()
      if (mat) texturesOf(mat, tex)
      const texture = tex.get('Texture') ?? tex.get('Diffuse') ?? [...tex.values()][0] ?? ''
      if (texture) flareLooks.push({ template, element, texture })
    }
    const src = t.find((x) => x.name === 'SourceElement')
    if (src) lookOfElement(readTags(new Reader(src.value), pkg), -1)
    const re = t.find((x) => x.name === 'Reflections')
    if (re) {
      const r = new Reader(re.value.subarray(4))
      const n = new DataView(re.value.buffer, re.value.byteOffset).getInt32(0, true)
      for (let k = 0; k < n; k++) lookOfElement(readTags(r, pkg), k)
    }
  } catch {
    // a flare not read: left out
  }
}

// The cut-out looks' masks (mask-textures.ts): XCOM 2's cut-out parents read the opacity from Masks, not the diffuse.
// Added now, while the package is small; their mips are made as the textures are inlined. Additions go at the tables'
// ends, so every reference read so far stays good.
const cutOut = new Map<string, number>()
for (const l of looks.values())
  if ((l.kind === 'Masked' || l.kind === 'Foliage') && l.diffuse) {
    const k = exports.findIndex((e) => e.fullName === l.diffuse && e.type === 'Texture2D')
    if (k >= 0) cutOut.set(l.diffuse, k + 1)
  }
// EW's people's colour mods (tint-textures.ts): a tinted copy of the diffuse for each slot whose material sets CMOD over a
// Spc_Ems_Ref_Opc mask; the slot takes the copy.
/** How much brighter EW's hair draws than its hairstyle texture (APPROXIMATION, by eye against EW's capture of Vahlen). */
const HAIR_SCALE = 2.6
/** How much brighter EW draws its people than their diffuse (its character lighting, which XCOM 2's staff material does
 *  not answer: ambient and light environments changed nothing): every person's diffuse brightened by it, colour-modded
 *  parts included (APPROXIMATION, by eye against EW's captures of the labs' clerks and Vahlen; converter 41). */
const PEOPLE_SCALE = 1.6
const tints: { slot: Look; diffuse: number; mask: number; tint: number[]; name: string; scale?: boolean; channel?: 'alpha' | 'blue'; bright?: number; multiply?: boolean }[] = []
const lookAlso: { slot: Look; name: string }[] = []
people.forEach((p, k) =>
  p.materialRefs.forEach((m, j) => {
    const l = personSlots[k]![j]
    if (!m || !l || l.kind === 'Glow' || !l.diffuse) return
    const cmod = vectorParam(m, 'CMOD')
    const tex = new Map<string, string>()
    const root = texturesOf(m, tex)
    // (EW's hair: its parent lightens the dark hairstyle texture, ColorMod white; a brightened copy, HAIR_SCALE.)
    if (/HairMaskNrm/.test(root)) {
      const hd = exports.findIndex((e) => e.fullName === l.diffuse && e.type === 'Texture2D')
      if (hd >= 0) tints.push({ slot: l, diffuse: hd + 1, mask: 0, tint: [HAIR_SCALE], name: `${exports[hd]!.name}_LWX2Bright`, scale: true })
      return
    }
    // (A head: EW's skin material colours the skin its Spc_dNrm_Skn_iBrw's blue marks with the instance's SkinColor, a
    // linear colour; the rest brightened as the people's. Shen's face had been pale green-grey for EW's peach. Converter 55.)
    const skin = vectorParam(m, 'SkinColor')
    const skinMaskPath = tex.get('Spc_dNrm_Skn_iBrw')
    if (skin && skinMaskPath) {
      const hd = exports.findIndex((e) => e.fullName === l.diffuse && e.type === 'Texture2D')
      const sk = exports.findIndex((e) => e.fullName === skinMaskPath && e.type === 'Texture2D')
      if (hd >= 0 && sk >= 0) {
        const key = skin.slice(0, 3).map((c) => Math.round(c * 100)).join('x')
        tints.push({ slot: l, diffuse: hd + 1, mask: sk + 1, tint: skin, name: `${exports[hd]!.name}_LWX2Tint${key}`, channel: 'blue', bright: PEOPLE_SCALE, multiply: true })
        return
      }
    }
    const maskPath = tex.get('Spc_Ems_Ref_Opc')
    const d = exports.findIndex((e) => e.fullName === l.diffuse && e.type === 'Texture2D')
    const mk = maskPath ? exports.findIndex((e) => e.fullName === maskPath && e.type === 'Texture2D') : -1
    if (!cmod || d < 0 || mk < 0) {
      // (No colour mod: the diffuse brightened alone.)
      if (d >= 0) tints.push({ slot: l, diffuse: d + 1, mask: 0, tint: [PEOPLE_SCALE], name: `${exports[d]!.name}_LWX2Lit`, scale: true })
      return
    }
    // (No "_<digits>" at the end: the engine reads that as an instance number, and the name looked up never matched: the
    // clerks drew with no material at all until converter 34.)
    const key = cmod.slice(0, 3).map((c) => Math.round(c * 100)).join('x')
    tints.push({ slot: l, diffuse: d + 1, mask: mk + 1, tint: cmod, name: `${exports[d]!.name}_LWX2Tint${key}` })
  }),
)
// EW's vehicles' paint (converter 51): a car's material sets TintColor (its own per car: the store's red SUV) over the
// paint its Spc_Ems_Mod_Ref's blue marks; a tinted copy of the diffuse per colour, as the people's (the master's default
// colour where a car sets none, as EW draws it). They had all been white.
for (const [r, l] of looks) {
  if (l.kind !== 'Prop' || !l.diffuse || r <= 0) continue
  const tex = new Map<string, string>()
  texturesOf(r, tex)
  const maskPath = tex.get('Spc_Ems_Mod_Ref')
  const tint = maskPath ? vectorParam(r, 'TintColor', 0, true) : undefined
  if (!tint || !maskPath) continue
  const d = exports.findIndex((e) => e.fullName === l.diffuse && e.type === 'Texture2D')
  const mk = exports.findIndex((e) => e.fullName === maskPath && e.type === 'Texture2D')
  if (d < 0 || mk < 0) continue
  const key = tint.slice(0, 3).map((c) => Math.round(c * 100)).join('x')
  const name = `${exports[d]!.name}_LWX2Tint${key}`
  // (One copy per diffuse and colour, shared by the looks that ask for it.)
  const same = tints.find((t) => t.name === name)
  if (same) { lookAlso.push({ slot: l, name }); continue }
  tints.push({ slot: l, diffuse: d + 1, mask: mk + 1, tint, name, channel: 'blue', bright: 1 })
}
if (tints.length) {
  const made = addTextureCopies(bytes, tints.map((t) => ({ ref: t.diffuse, name: t.name })))
  bytes = made.bytes
  meta = new Package(bytes)
  pkg = openPackage(bytes)
  exports = meta.exports as any[]
  for (const t of tints) {
    const r = made.refs.get(t.name)
    if (r) t.slot.diffuse = exports[r - 1]!.fullName
  }
  for (const t of lookAlso) {
    const r = made.refs.get(t.name)
    if (r) t.slot.diffuse = exports[r - 1]!.fullName
  }
}
// EW's console screens' picture (HQscreens_test: UI panels in its green channel) made white, for our glow to tint
// (converter 40): a copy per screen texture, its looks pointed at it.
// (And the Genetics Lab's tank glass's froth, which EW's material reads as a mask: its colours had come out green.
// Converter 49.)
const screenLooks = [...new Set([...looks.values(), ...personSlots.flat()])].filter((l): l is Look => !!l && l.kind === 'Glow' && /HQscreens|Froth/i.test(l.diffuse))
if (screenLooks.length) {
  const refsOf = [...new Set(screenLooks.map((l) => l.diffuse))].map((d) => ({ d, k: exports.findIndex((e) => e.fullName === d && e.type === 'Texture2D') })).filter((x) => x.k >= 0)
  const made = addTextureCopies(bytes, refsOf.map((x) => ({ ref: x.k + 1, name: `${exports[x.k]!.name}_LWX2White` })))
  bytes = made.bytes
  meta = new Package(bytes)
  pkg = openPackage(bytes)
  exports = meta.exports as any[]
  for (const l of screenLooks) {
    const x = refsOf.find((y) => y.d === l.diffuse)
    const r = x ? made.refs.get(`${l.diffuse.split('.').pop()}_LWX2White`) : undefined
    if (r) l.diffuse = exports[r - 1]!.fullName
  }
}
const tintOf = new Map<string, { mask: string; tint: number[]; scale?: boolean; channel?: 'alpha' | 'blue'; bright?: number; multiply?: boolean }>()
for (const t of tints) if (/_LWX2(Tint|Bright|Lit)/.test(t.slot.diffuse)) tintOf.set(t.slot.diffuse, { mask: t.mask ? exports[t.mask - 1]!.fullName : '', tint: t.tint, scale: t.scale, channel: t.channel, bright: t.bright, multiply: t.multiply })
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
// (Small levels, as EW's base's tiles, have none: then a carried package's class, Core.Package, as plain.)
const donor = exports.find((e) => e.type === 'PhysicalMaterial') ?? exports.find((e) => e.type === 'Package')
if (!donor) throw new Error('no PhysicalMaterial or Package in the package to borrow a class from')
const donorClass = v.getInt32(donor.entryOffset + 0, true)
const donorFlagsLo = v.getUint32(donor.entryOffset + 24, true)
const donorFlagsHi = v.getUint32(donor.entryOffset + 28, true)
const noneIndex = meta.names.indexOf('None')
const stubAt = bytes.length
const stub = new Uint8Array(12)
new DataView(stub.buffer).setInt32(0, -1, true)
new DataView(stub.buffer).setInt32(4, noneIndex, true)
let neutralized = 0
// And EW's materials (stub-materials.ts): XCOM 2 would compile each as the map loads, for nothing it draws (the plot's
// stand-ins draw the map).
// As empty material instances (no parent: a material wherever one is expected, nothing to compile), their instances too
// (one with static permutations builds them from its parent as it loads: with an empty one the game crashed).
// The skeletal meshes' own material references cleared (EW's people, ew-people.ts): a skeletal mesh checks its materials'
// usage as it loads, and the inert instances below have no parent (XCOM 2 crashed as an Anim_ level loaded). The mod gives
// each person stand-ins of its own.
let skelCleared = 0
// (And the people's animations' notifies cleared: footsteps, sounds, EW's IK blends, which the mod's base has no use for;
// the IK ones are made inert below, and a sequence firing one crashed XCOM 2.)
let notifiesCleared = 0
if (people.length)
  exports.forEach((e, k) => {
    if (e.type !== 'AnimSequence') return
    try {
      const st = readTags(new Reader(pkg.data(k + 1).subarray(4)), pkg) as Tag[]
      const nt = st.find((t) => t.name === 'Notifies')
      if (!nt) return
      const n = new DataView(nt.value.buffer, nt.value.byteOffset).getInt32(0, true)
      const r = new Reader(nt.value.subarray(4))
      for (let j = 0; j < n; j++) {
        const f = (readTags(r, pkg) as Tag[]).find((t) => t.name === 'Notify')
        if (f && f.value.byteOffset >= bytes.byteOffset) {
          v.setInt32(f.value.byteOffset - bytes.byteOffset, 0, true)
          notifiesCleared++
        }
      }
    } catch {
      // left as it is
    }
  })
exports.forEach((e, k) => {
  if (e.type !== 'SkeletalMesh') return
  try {
    const d: Uint8Array = pkg.data(k + 1)
    const r = new Reader(d.subarray(4))
    const st = readTags(r, pkg) as Tag[]
    // (Its FaceFX asset too: made inert below, XCOM 2 has no FaceFX.)
    const fx = st.find((t) => t.name === 'FaceFXAsset')
    if (fx && fx.value.byteOffset >= bytes.byteOffset) v.setInt32(fx.value.byteOffset - bytes.byteOffset, 0, true)
    const o = e.offset + 4 + (r as unknown as { o: number }).o + 28
    const n = v.getInt32(o, true)
    if (n <= 0 || n >= 16) return
    for (let j = 0; j < n; j++) v.setInt32(o + 4 + 4 * j, 0, true)
    skelCleared++
  } catch {
    // left as it is
  }
})
let materialsStubbed = 0
const micDonor = exports.find((e) => e.type === 'MaterialInstanceConstant')
exports.forEach((e) => {
  if ((e.type === 'Material' || e.type === 'MaterialInstanceConstant' || e.type === 'MaterialInstanceTimeVarying') && micDonor) {
    const at = e.entryOffset
    v.setInt32(at + 0, v.getInt32(micDonor.entryOffset + 0, true), true)
    v.setInt32(at + 4, 0, true)
    v.setInt32(at + 20, 0, true)
    v.setUint32(at + 24, v.getUint32(micDonor.entryOffset + 24, true), true)
    v.setUint32(at + 28, v.getUint32(micDonor.entryOffset + 28, true), true)
    v.setInt32(at + 32, stub.length, true)
    v.setInt32(at + 36, stubAt, true)
    if (e.type === 'Material') materialsStubbed++
    return
  }
  // (And with EW's people, what of theirs XCOM 2 cannot load: EW's FaceFX, its cinematic anim tree and its nodes; the mod
  // drives each person with an AnimNodeSequence of its own. XCOM 2 crashed as an Anim_ level loaded.)
  if (e.fullName.split('.')[0] !== 'TheWorld' && !(people.length && /^(FaceFXAsset|AnimTree|AnimNode\w*|AnimNotify_BlendIK)$/.test(e.type))) return
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
// EW's lightmaps (lightmap-bake.ts): each colour atlas's mips combined with its directional atlas's. The directional mips
// read first, in a pass over a copy (inlining changes the entries it is given).
const lmPairs = new Map<(typeof exports)[number], (typeof exports)[number]>()
for (const p of pieces) if (p.lightmap) lmPairs.set(exports[p.lightmap.color - 1]!, exports[p.lightmap.dir - 1]!)
const lmDirs = new Set(lmPairs.values())
const tintMasks = new Set([...tintOf.values()].map((t) => t.mask))
const dirMips = new Map<string, Uint8Array>()
if (lmDirs.size || tintMasks.size)
  inlineTextures(bytes.slice(), exports, meta.names, dirname(src), stubAt + stub.length, (e) => !lmDirs.has(e) && !tintMasks.has(e.fullName), (e, format, mip, w, h) => {
    if (lmDirs.has(e) || tintMasks.has(e.fullName) || format === 'PF_DXT5') dirMips.set(`${e.fullName}:${w}x${h}`, mip.slice())
    return undefined
  })
// The combined atlases made plain textures (Texture2D's class, the lightmap's flags at the end left off): bound to our
// material as LightMapTexture2D, XCOM 2 crashed (heap corruption) as the base came into view.
const tex2dClass = exports.find((e) => e.type === 'Texture2D')
if (tex2dClass) for (const e of lmPairs.keys()) v.setInt32(e.entryOffset + 0, v.getInt32(tex2dClass.entryOffset + 0, true), true)
// (And public, as EW's other textures are: a mission's plot, another package, imports them for its pieces' baked lighting;
// private, the plot failed to load, "Can't import private object". The object flags' low half is the entry's second
// dword; RF_Public 0x4. Converter 31.)
for (const e of lmPairs.keys()) v.setUint32(e.entryOffset + 28, v.getUint32(e.entryOffset + 28, true) | 4, true)
const tex = inlineTextures(bytes, exports, meta.names, dirname(src), stubAt + stub.length, (e) => e.fullName.startsWith('TheWorld'),
  (e, format, mip, w, h) => {
    if (maskExports.has(e)) return maskMip(format, mip)
    const tinted = tintOf.get(e.fullName)
    if (tinted?.scale) return scaleMip(mip, format, tinted.tint[0]!)
    if (e.fullName.endsWith('_LWX2White') && (format === 'PF_DXT5' || format === 'PF_DXT1')) return whiteMip(mip, format, w, h)
    const tm = tinted && (format === 'PF_DXT1' || format === 'PF_DXT5') ? dirMips.get(`${tinted.mask}:${w}x${h}`) : undefined
    if (tinted && tm) return tintMip(mip, tm, w, h, tinted.tint, tinted.bright ?? PEOPLE_SCALE, tinted.channel ?? 'alpha', tinted.channel === 'blue', tinted.multiply)
    const dir = lmPairs.get(e)
    const d = dir && format === 'PF_DXT1' ? dirMips.get(`${dir.fullName}:${w}x${h}`) : undefined
    return d ? combineLightmapMip(mip, d, w, h) : undefined
  },
  (e) => (tex2dClass && lmPairs.has(e) ? 4 : 0))
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
/** A piece's lightmap in the ini (LWX2PieceLightMap). */
const lightmapText = (l?: LightMap) =>
  l
    ? `,LightMap=(Color="${rename(pathOf(l.color))}",Dir="${rename(pathOf(l.dir))}",S0=(X=${n(l.s0[0]!)},Y=${n(l.s0[1]!)},Z=${n(l.s0[2]!)}),S1=(X=${n(l.s1[0]!)},Y=${n(l.s1[1]!)},Z=${n(l.s1[2]!)}),ScaleX=${l.scale[0]},ScaleY=${l.scale[1]},BiasX=${l.bias[0]},BiasY=${l.bias[1]},UV=${l.uv})`
    : ''
const coverText = (c: Cover) =>
  (c.onto ? '' : ',ClimbOnto=false') + (c.floor ? ',ClimbOnto=true,Floor=true' : '') + (c.over ? ',ClimbOver=true' : '') + (c.destination ? '' : ',Destination=false') +
  (c.sight ? '' : ',BlocksSight=false') + (c.window ? ',Window=true' : '')
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
  ...(rooms.length || cameras.length ? ["; EW's base (features/lw-base-view.md): its room locations (R<row>_C<column>) and its cameras, by their tags."] : []),
  ...rooms.map((r) => `+Rooms=(Tag=${r.tag},Loc=(X=${n(r.loc[0]!)},Y=${n(r.loc[1]!)},Z=${n(r.loc[2]!)}))`),
  ...cameras.map((c) => `+Cameras=(Tag=${c.tag},Loc=(X=${n(c.loc[0]!)},Y=${n(c.loc[1]!)},Z=${n(c.loc[2]!)}),Rot=(Pitch=${c.rot[0]},Yaw=${c.rot[1]},Roll=${c.rot[2]}),FOV=${n(c.fov)})`),
  ...spots.map((c) => `+Spots=(Tag=${c.tag},Loc=(X=${n(c.loc[0]!)},Y=${n(c.loc[1]!)},Z=${n(c.loc[2]!)}),Rot=(Pitch=${c.rot[0]},Yaw=${c.rot[1]},Roll=${c.rot[2]}))`),
  "; EW's meld canisters' places (Group: the drop zone's, in their order; Turns: when it self-destructs; Hard or easy).",
  ...meldPoints.map((p) => `+MeldPoints=(Loc=(X=${n(p.loc[0]!)},Y=${n(p.loc[1]!)},Z=${n(p.loc[2]!)}),Group=${p.group},Turns=${p.turns},Hard=${p.hard})`),
  "; EW's atmosphere: its height fog (density, height, falloff, inscattering and opposite colours; -1: EW's default)",
  '; and its colour grading.',
  ...(atmosphere.fog ? [(() => {
    const f = atmosphere.fog!
    const num = (k: string) => (typeof f[k] === 'number' ? n(f[k] as number) : '-1')
    const col = (k: string) => (Array.isArray(f[k]) ? `(R=${(f[k] as number[])[0]},G=${(f[k] as number[])[1]},B=${(f[k] as number[])[2]},A=255)` : '(R=0,G=0,B=0,A=0)')
    return `Fog=(Enabled=${f.bEnabled ? 'true' : 'false'},Density=${num('FogDensity')},Height=${num('FogHeight')},Falloff=${num('FogHeightFalloff')},Inscatter=${col('LightInscatteringColor')},Opposite=${col('OppositeLightColor')})`
  })()] : []),
  ...(Object.keys(atmosphere.grade).length ? [(() => {
    const g = atmosphere.grade
    const vec = (k: string, d: number) => { const v = g[k] as number[] | undefined; return `(X=${n(v?.[0] ?? d)},Y=${n(v?.[1] ?? d)},Z=${n(v?.[2] ?? d)})` }
    return `Grade=(Colorize=${vec('Scene_Colorize', 1)},Shadows=${vec('Scene_Shadows', 0)},HighLights=${vec('Scene_HighLights', 1)},MidTones=${vec('Scene_MidTones', 1)},Desaturation=${n(typeof g.Scene_Desaturation === 'number' ? g.Scene_Desaturation : 0)})`
  })()] : []),
  "; EW's lights (point, spot, its sun and sky), spawned as movable lights.",
  ...lights.map(
    (l) =>
      `+Lights=(Kind=${l.kind},Loc=(X=${n(l.loc[0]!)},Y=${n(l.loc[1]!)},Z=${n(l.loc[2]!)}),Rot=(Pitch=${l.rot[0]},Yaw=${l.rot[1]},Roll=${l.rot[2]}),` +
      `Radius=${n(l.radius)},Brightness=${n(l.brightness)},Color=(R=${l.color[0]},G=${l.color[1]},B=${l.color[2]},A=${l.color[3]}),` +
      `Falloff=${n(l.falloff)},Inner=${n(l.inner)},Outer=${n(l.outer)},Lower=${n(l.lower)})`,
  ),
  "; EW's 3D UI panels: its screens draw on the one of their tag (features/ew-3d-screens.md).",
  "; EW's emitters (features/ew-emitters.md): each placed particle system, and each of its emitters' sprite texture.",
  ...emitterPlaces.map((e) => `+Emitters=(Template="${rename(pathOf(e.template))}",Loc=(X=${n(e.loc[0]!)},Y=${n(e.loc[1]!)},Z=${n(e.loc[2]!)}),Rot=(Pitch=${e.rot[0]},Yaw=${e.rot[1]},Roll=${e.rot[2]}),Scale=${n(e.scale)}${e.maxDraw ? `,MaxDraw=${n(e.maxDraw)}` : ''}${e.dilation !== 1 ? `,Dilation=${n(e.dilation)}` : ''})`),
  ...flarePlaces.map((f) => `+Flares=(Template="${rename(pathOf(f.template))}",Loc=(X=${n(f.loc[0]!)},Y=${n(f.loc[1]!)},Z=${n(f.loc[2]!)}))`),
  ...flareLooks.map((l) => `+FlareLooks=(Template="${rename(pathOf(l.template))}",Element=${l.element},Texture="${rename(l.texture)}")`),
  ...particleLooks.map((l) => `+ParticleLooks=(Template="${rename(pathOf(l.template))}",Emitter=${l.emitter},Texture="${rename(l.texture)}"${l.additive ? ',Additive=true' : ''}${l.subX * l.subY > 1 ? `,SubX=${l.subX},SubY=${l.subY}` : ''})`),
  ...displays.map((d) => `+Displays=(${d.mesh ? `Mesh="${rename(d.mesh)}",` : ''}Tag=${d.tag || 'None'},Loc=(X=${n(d.loc[0]!)},Y=${n(d.loc[1]!)},Z=${n(d.loc[2]!)}),Rot=(Pitch=${d.rot[0]},Yaw=${d.rot[1]},Roll=${d.rot[2]}),Scale=(X=${n(d.scale[0]!)},Y=${n(d.scale[1]!)},Z=${n(d.scale[2]!)}))`),
  "; EW's people (an Anim_ level's: its matinee's loops; features/ew-base-people.md).",
  ...people.map((p, k) => `+People=(Mesh="${rename(p.mesh)}",Loc=(X=${n(p.loc[0]!)},Y=${n(p.loc[1]!)},Z=${n(p.loc[2]!)}),Rot=(Pitch=${p.rot[0]},Yaw=${p.rot[1]},Roll=${p.rot[2]}),Scale=${n(p.scale)},${p.key ? `Key=(X=${n(p.key[0]!)},Y=${n(p.key[1]!)},Z=${n(p.key[2]!)}),` : ''}${p.bay ? `Bay=${p.bay},BayState="${p.bayState}",BayPart=${p.group},` : ''}AnimSets=(${p.animSets.map((a) => `"${rename(a)}"`).join(',')}),Seqs=(${p.seqs.map((q) => `"${q}"`).join(',')}),${p.physicsAsset ? `PhysicsAsset="${rename(p.physicsAsset)}",` : ''}${p.start ? `Start=${n(p.start)},` : ''}${p.rate ? `Rate=${n(p.rate)},` : ''}${p.window ? `Window=${n(p.window)},` : ''}${p.keys?.length ? `Keys=(${p.keys.map((k) => `(Time=${n(k.time)},From=${n(k.from)},End=${n(k.end)}${k.reverse ? ',Reverse=true' : ''})`).join(',')}),` : ''}Slots=(${personSlots[k]!.map((l) => `(Diffuse="${l ? rename(l.diffuse) : ''}",Normal="${l ? rename(l.normal) : ''}"${l?.kind === 'Glow' ? `,Glow=true${l.tint ? `,Tint=(R=${n(l.tint[0]!)},G=${n(l.tint[1]!)},B=${n(l.tint[2]!)},A=1)` : ''}` : ''})`).join(',')}))`),
  "; Each EW material's textures, for the XCOM 2 parent of its kind (XComLWEWMaps.ini).",
  ...[...looks].map(
    ([r, l]) => `+Looks=(Material="${rename(pathOf(r))}",Kind=${l.kind},Diffuse="${rename(l.diffuse)}",Normal="${rename(l.normal)}"${l.mask ? `,Mask="${rename(l.mask)}"` : ''}${l.tint ? `,Tint=(R=${l.tint[0]},G=${l.tint[1]},B=${l.tint[2]},A=1)` : ''}${l.tile ? `,Tile=${l.tile}` : ''})`,
  ),
  ...pieces.map(
    (p) =>
      `+Pieces=(Mesh="${rename(p.mesh)}",Loc=(X=${n(p.loc[0]!)},Y=${n(p.loc[1]!)},Z=${n(p.loc[2]!)}),Rot=(Pitch=${p.rot[0]},Yaw=${p.rot[1]},Roll=${p.rot[2]}),Scale=(X=${n(p.scale[0]!)},Y=${n(p.scale[1]!)},Z=${n(p.scale[2]!)})${p.materials.length ? `,Materials=(${p.materials.map((m) => `"${m ? rename(pathOf(m)) : ''}"`).join(',')})` : ''}${isBackdrop(p) ? ',Backdrop=true' : ''}${p.fractured ? ',Fractured=true' : ''}${p.frac ? `,Frac=(Indices=${p.frac.indices},MinZ=${n(p.frac.minZ)},MaxZ=${n(p.frac.maxZ)},Toughness=${p.frac.toughness || 'None'})` : ''}${coverText(p.cover)}${lightmapText(p.lightmap)})`,
  ),
]
writeFileSync(iniOut, lines.join('\r\n') + '\r\n')
const meshes = new Set(pieces.map((p) => p.mesh))
console.log(`${out}: world neutralized (${neutralized} objects), ${renamedPackages.size} carried packages renamed (${nested} nested), ${tex.textures} textures rewritten (${tex.mips} mips, ${(tex.appended.length / 1e6).toFixed(0)} MB), ${masked.masks.size} masks for cut-out looks, ${materialsStubbed} materials made inert${skelCleared ? `, ${skelCleared} skeletal meshes' materials cleared` : ''}${notifiesCleared ? `, ${notifiesCleared} anim notifies cleared` : ''}`)
const noDiffuse = [...looks.values()].filter((l) => !l.diffuse).length
console.log(`${iniOut}: ${looks.size} materials (${noDiffuse} without a diffuse map found)`)
console.log(`${iniOut}: ${pods.length} pods, ${spawnPoints.length} spawn points (${spawnPoints.filter((p) => p[3]).length} civilian), ${meldPoints.length} meld points, ${lights.length} lights, ${buildings.length} buildings (${buildings.reduce((a, b) => a + b.floors.length, 0)} floors)`)
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

