// An Enemy Within map as a real XCOM 2 plot (features/lw-missions.md, "real XCOM 2 maps"): Long War X2's template plot
// (tools/maps/LWX2_EWPlotTemplate.umap, made in the SDK editor) with the converted EW map's geometry, materials, lights and
// drop zones written into its level as XCOM 2 actors, and its level volume and tile grid sized to EW's play area. The
// actors are clones of the template's samples (a level actor with its mesh component, a point and a spot light, a group
// spawn, a material instance) with their properties set; what they show (meshes, textures) stays in the converted map
// package (ew-map.ts), which the plot imports. XCOM 2 then loads the plot as it loads its own and builds its tiles,
// cover and paths from the geometry.
//   node tools/convert/ew-plot.ts <template .umap> <converted map's section .ini> <out LWX2_<map>.umap>
import { readFileSync, writeFileSync } from 'node:fs'
import { openPackage, type Export, type Import, type NameEntry, type NameRef } from '@innonova/upkit/package'
import { Reader, Writer } from '@innonova/upkit/bytes'
import { readTags, type Tag } from '@innonova/upkit/objects'
import { writePackage } from '@innonova/upkit/writer'

/** One converted EW map's section (LWX2EWMapData, as ew-map.ts writes it). */
export interface EWMap {
  name: string
  mapPackage: string
  playCenter: number[]
  playExtent: number[]
  dropZones: number[][]
  pieces: { mesh: string; loc: number[]; rot: number[]; scale: number[]; materials: string[]; backdrop: boolean }[]
  looks: Map<string, { kind: string; diffuse: string; normal: string }>
  lights: { kind: string; loc: number[]; rot: number[]; radius: number; brightness: number; color: number[]; falloff: number; inner: number; outer: number }[]
}

/** The section read from an .ini (ew-map.ts's output). */
export function readSection(text: string): EWMap {
  const num = (s: string, k: string) => Number(new RegExp(`\\b${k}=(-?[\\d.e+-]+)`).exec(s)?.[1] ?? 0)
  const vec = (s: string) => ['X', 'Y', 'Z'].map((k) => num(s, k))
  const sub = (s: string, k: string) => new RegExp(`\\b${k}=\\(([^()]*)\\)`).exec(s)?.[1] ?? ''
  const str = (s: string, k: string) => new RegExp(`\\b${k}="([^"]*)"`).exec(s)?.[1] ?? ''
  const m: EWMap = { name: '', mapPackage: '', playCenter: [0, 0, 0], playExtent: [0, 0, 0], dropZones: [], pieces: [], looks: new Map(), lights: [] }
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim()
    let x: RegExpExecArray | null
    if ((x = /^\[(\S+) LWX2EWMapData\]/.exec(line))) m.name = x[1]!
    else if (line.startsWith('MapPackage=')) m.mapPackage = str(line, 'MapPackage')
    else if (line.startsWith('PlayCenter=')) m.playCenter = vec(line)
    else if (line.startsWith('PlayExtent=')) m.playExtent = vec(line)
    else if (line.startsWith('+DropZones=')) m.dropZones.push(vec(line))
    else if (line.startsWith('+Looks='))
      m.looks.set(str(line, 'Material'), { kind: /Kind=(\w+)/.exec(line)?.[1] ?? 'Prop', diffuse: str(line, 'Diffuse'), normal: str(line, 'Normal') })
    else if (line.startsWith('+Pieces=')) {
      const mats = /Materials=\(([^)]*)\)/.exec(line)?.[1] ?? ''
      m.pieces.push({
        mesh: str(line, 'Mesh'),
        loc: vec(sub(line, 'Loc')),
        rot: ['Pitch', 'Yaw', 'Roll'].map((k) => num(sub(line, 'Rot'), k)),
        scale: vec(sub(line, 'Scale')),
        materials: mats ? mats.split(',').map((s) => s.replace(/"/g, '')) : [],
        backdrop: /Backdrop=true/.test(line),
      })
    } else if (line.startsWith('+Lights=')) {
      const c = sub(line, 'Color')
      m.lights.push({
        kind: /Kind=(\w+)/.exec(line)?.[1] ?? '',
        loc: vec(sub(line, 'Loc')),
        rot: ['Pitch', 'Yaw', 'Roll'].map((k) => num(sub(line, 'Rot'), k)),
        radius: num(line, 'Radius'),
        brightness: num(line, 'Brightness'),
        color: ['R', 'G', 'B', 'A'].map((k) => num(c, k)),
        falloff: num(line, 'Falloff'),
        inner: num(line, 'Inner'),
        outer: num(line, 'Outer'),
      })
    }
  }
  return m
}

/** Settings the plot is written with (the shared ones of XComLWEWMaps.ini). */
export interface PlotSettings {
  /** The XCOM 2 parent material for each kind of EW material (Prop, Foliage, Alien). */
  parents: Record<string, string>
  /** Scalars and textures set on every stand-in. */
  scalars: [string, number][]
  textures: [string, string][]
  /** EW's light brightness scale, and the kinds placed. */
  lightScale: number
  lightKinds: string[]
}

const TILE = 96
const FLOOR = 64

/** The plot for an EW map, written from the template; returns its bytes and a report. */
export function writePlot(template: Uint8Array, map: EWMap, settings: PlotSettings): { bytes: Uint8Array; report: string } {
  const pkg: any = openPackage(template)
  const names: NameEntry[] = []
  const imports: Import[] = []
  const added: { entry: Export; data: Uint8Array }[] = []
  const data = new Map<number, Uint8Array>()
  const nameFlags: bigint = pkg.names[pkg.names.findIndex((n: NameEntry) => n.name === 'None')].flags
  const allNames = (): NameEntry[] => [...pkg.names, ...names]

  // --- Names, imports, exports -----------------------------------------------------------------------------------
  const nameIndex = (s: string): number => {
    const i = allNames().findIndex((n) => n.name === s)
    if (i >= 0) return i
    names.push({ name: s, flags: nameFlags })
    return pkg.names.length + names.length - 1
  }
  /** An object name: "Foo_12" is name Foo, number 13 (UE3's numbered names). */
  const objName = (s: string): NameRef => {
    const m = /^(.*)_(\d+)$/.exec(s)
    return m && !m[2]!.startsWith('0') ? { index: nameIndex(m[1]!), number: Number(m[2]) + 1 } : { index: nameIndex(s), number: 0 }
  }
  const nm = (r: NameRef) => allNames()[r.index]!.name + (r.number ? '_' + (r.number - 1) : '')
  const allImports = (): Import[] => [...pkg.imports, ...imports]
  const importPath = (ref: number): string => {
    const i = allImports()[-ref - 1]!
    return (i.outer ? importPath(i.outer) + '.' : '') + nm(i.objectName)
  }
  /** An import by path (its outers made as packages), of a class in a class package. */
  const importRef = (path: string, className: string, classPackage = 'Engine'): number => {
    const found = allImports().findIndex((_, k) => importPath(-k - 1).toLowerCase() === path.toLowerCase())
    if (found >= 0) return -found - 1
    const parts = path.split('.')
    const outer = parts.length > 1 ? importRef(parts.slice(0, -1).join('.'), 'Package', 'Core') : 0
    imports.push({ classPackage: objName(classPackage), className: objName(className), outer, objectName: objName(parts.at(-1)!) })
    return -(pkg.imports.length + imports.length)
  }
  const exportCount = () => pkg.exports.length + added.length
  const byPath = (suffix: string): number => {
    const path = (ref: number): string => {
      const e = ref <= pkg.exports.length ? pkg.exports[ref - 1] : added[ref - pkg.exports.length - 1]!.entry
      return (e.outer > 0 ? path(e.outer) + '.' : '') + nm(e.objectName)
    }
    for (let k = 1; k <= pkg.exports.length; k++) if (path(k).endsWith(suffix)) return k
    throw new Error(`no ${suffix} in the template`)
  }
  /** A new export: a clone of a sample's entry under a new name and outer. */
  const addExport = (sample: number, name: string, outer: number, bytes: Uint8Array): number => {
    const e = pkg.exports[sample - 1]
    added.push({ entry: { ...e, outer, objectName: objName(name), serialSize: 0, serialOffset: 0, exportFlags: 0, netObjects: [] }, data: bytes })
    return exportCount()
  }
  const counters = new Map<string, number>()
  const nextName = (base: string) => {
    const n = (counters.get(base) ?? 1000) + 1
    counters.set(base, n)
    return `${base}_${n}`
  }

  // --- Tags ------------------------------------------------------------------------------------------------------
  interface T { name: string; type: string; struct?: string; enumName?: string; bool?: number; arrayIndex: number; value: Uint8Array }
  const parse = (bytes: Uint8Array, start: number): { head: Uint8Array; tags: T[]; tail: Uint8Array } => {
    const r = new Reader(bytes.subarray(start))
    const tags: Tag[] = readTags(r, pkg)
    return {
      head: bytes.subarray(0, start),
      tags: tags.map((t) => ({ name: t.name, type: t.type, struct: t.structName, enumName: t.enumName, bool: t.boolValue, arrayIndex: t.arrayIndex, value: t.value })),
      tail: bytes.subarray(start + r.o),
    }
  }
  const serialize = (p: { head: Uint8Array; tags: T[]; tail: Uint8Array }): Uint8Array => {
    const w = new Writer()
    w.bytes(p.head)
    const nr = (s: string) => {
      const r = objName(s)
      w.i32(r.index).i32(r.number)
    }
    for (const t of p.tags) {
      nr(t.name)
      nr(t.type)
      w.i32(t.value.length).i32(t.arrayIndex)
      if (t.type === 'StructProperty') nr(t.struct!)
      else if (t.type === 'ByteProperty') nr(t.enumName ?? 'None')
      else if (t.type === 'BoolProperty') w.u8(t.bool ?? 0)
      w.bytes(t.value)
    }
    nr('None')
    w.bytes(p.tail)
    return w.done()
  }
  const set = (tags: T[], t: T) => {
    const k = tags.findIndex((x) => x.name === t.name && x.arrayIndex === t.arrayIndex)
    if (k >= 0) tags[k] = t
    else tags.push(t)
  }
  const bin = (f: (w: Writer) => void) => {
    const w = new Writer()
    f(w)
    return w.done()
  }
  const tObj = (name: string, ref: number): T => ({ name, type: 'ObjectProperty', arrayIndex: 0, value: bin((w) => w.i32(ref)) })
  const tVec = (name: string, v: number[]): T => ({ name, type: 'StructProperty', struct: 'Vector', arrayIndex: 0, value: bin((w) => v.forEach((c) => w.f32(c))) })
  const tRot = (name: string, r: number[]): T => ({ name, type: 'StructProperty', struct: 'Rotator', arrayIndex: 0, value: bin((w) => r.forEach((c) => w.i32(c))) })
  const tFloat = (name: string, f: number): T => ({ name, type: 'FloatProperty', arrayIndex: 0, value: bin((w) => w.f32(f)) })
  const tInt = (name: string, n: number): T => ({ name, type: 'IntProperty', arrayIndex: 0, value: bin((w) => w.i32(n)) })
  const tBool = (name: string, b: boolean): T => ({ name, type: 'BoolProperty', arrayIndex: 0, bool: b ? 1 : 0, value: new Uint8Array(0) })
  const tColor = (name: string, c: number[]): T => ({ name, type: 'StructProperty', struct: 'Color', arrayIndex: 0, value: Uint8Array.from([c[2]!, c[1]!, c[0]!, c[3]!]) })
  const tGuid = (name: string): T => ({ name, type: 'StructProperty', struct: 'Guid', arrayIndex: 0, value: crypto.getRandomValues(new Uint8Array(16)) })
  const NONE = -1
  /** A copy of an actor's head (its state frame and net index) with the net index cleared. */
  const actorHead = (head: Uint8Array) => {
    const h = Uint8Array.from(head)
    new DataView(h.buffer).setInt32(22, NONE, true)
    return h
  }
  const componentHead = (head: Uint8Array) => {
    const h = Uint8Array.from(head)
    new DataView(h.buffer).setInt32(4, NONE, true)
    return h
  }
  const objectHead = () => bin((w) => w.i32(NONE))

  // --- The template's samples ------------------------------------------------------------------------------------
  const level = byPath('TheWorld.PersistentLevel')
  const sampleActor = byPath('PersistentLevel.XComLevelActor_0')
  const sampleMesh = byPath('XComLevelActor_0.StaticMeshComponent_0')
  const samplePoint = byPath('PersistentLevel.PointLightMovable_0')
  const samplePointC = byPath('PointLightMovable_0.PointLightComponent_0')
  const sampleSpot = byPath('PersistentLevel.SpotLightMovable_0')
  const sampleSpotC = byPath('SpotLightMovable_0.SpotLightComponent_0')
  const spawn = byPath('PersistentLevel.XComGroupSpawn_0')
  const parcel = byPath('PersistentLevel.XComParcel_0')
  const volume = byPath('PersistentLevel.XComLevelVolume_0')
  const worldData = byPath('XComLevelVolume_0.XComWorldData_0')
  const sampleMIC = byPath('MaterialInstanceConstant_0')
  const placed: number[] = []

  // --- Stand-in materials: one MaterialInstanceConstant of an XCOM 2 parent per EW material ----------------------
  const mics = new Map<string, number>()
  const micFor = (path: string): number => {
    if (!path) return 0
    if (mics.has(path)) return mics.get(path)!
    const look = map.looks.get(path)
    let ref = 0
    if (look && look.diffuse && settings.parents[look.kind]) {
      const p = parse(pkg.data(sampleMIC), 4)
      const tags: T[] = [tObj('Parent', importRef(settings.parents[look.kind]!, 'Material')), tGuid('LightingGuid')]
      const texParams: [string, number][] = [['Diffuse', importRef(look.diffuse, 'Texture2D')]]
      if (look.normal) texParams.push(['Normal', importRef(look.normal, 'Texture2D')])
      for (const [n, t] of settings.textures) texParams.push([n, importRef(t, 'Texture2D')])
      // TextureParameterValues: an array of (ParameterName, ParameterValue, ExpressionGUID) structs, tagged.
      tags.push({
        name: 'TextureParameterValues', type: 'ArrayProperty', arrayIndex: 0,
        value: bin((w) => {
          w.i32(texParams.length)
          for (const [n, t] of texParams)
            w.bytes(serialize({ head: new Uint8Array(0), tags: [{ name: 'ParameterName', type: 'NameProperty', arrayIndex: 0, value: bin((x) => { const r = objName(n); x.i32(r.index).i32(r.number) }) }, tObj('ParameterValue', t)], tail: new Uint8Array(0) }))
        }),
      })
      if (settings.scalars.length)
        tags.push({
          name: 'ScalarParameterValues', type: 'ArrayProperty', arrayIndex: 0,
          value: bin((w) => {
            w.i32(settings.scalars.length)
            for (const [n, v] of settings.scalars)
              w.bytes(serialize({ head: new Uint8Array(0), tags: [{ name: 'ParameterName', type: 'NameProperty', arrayIndex: 0, value: bin((x) => { const r = objName(n); x.i32(r.index).i32(r.number) }) }, tFloat('ParameterValue', v)], tail: new Uint8Array(0) }))
          }),
        })
      ref = addExport(sampleMIC, nextName('LWX2Standin'), level, serialize({ head: objectHead(), tags, tail: p.tail }))
    } else if (path) {
      // No stand-in (no diffuse map or no parent for its kind): the EW material itself (XCOM 2 draws its checker).
      ref = importRef(path, 'Material')
    }
    mics.set(path, ref)
    return ref
  }

  // --- The pieces ------------------------------------------------------------------------------------------------
  const actorSample = parse(pkg.data(sampleActor), 26)
  const meshSample = parse(pkg.data(sampleMesh), 8)
  // Meshes EW generated inside its own level (its volumes' meshes) are not in the converted package's carried content.
  const pieces = map.pieces.filter((p) => !p.mesh.startsWith('TheWorld.'))
  for (const piece of pieces) {
    // Its stand-ins first: they are exports too, and the actor's component must come right after the actor.
    const mats = piece.materials.map(micFor)
    const actorName = nextName('XComLevelActor')
    const actorRef = exportCount() + 1
    const compRef = actorRef + 1
    const atags = actorSample.tags.map((t) => ({ ...t })).filter((t) => t.name !== 'Tag')
    set(atags, tObj('StaticMeshComponent', compRef))
    set(atags, tObj('CollisionComponent', compRef))
    set(atags, tVec('Location', piece.loc))
    set(atags, tRot('Rotation', piece.rot))
    set(atags, tVec('DrawScale3D', piece.scale))
    addExport(sampleActor, actorName, level, serialize({ head: actorHead(actorSample.head), tags: atags, tail: actorSample.tail }))
    const ctags = meshSample.tags.map((t) => ({ ...t }))
    set(ctags, tObj('StaticMesh', importRef(piece.mesh, 'StaticMesh')))
    if (mats.length)
      set(ctags, { name: 'Materials', type: 'ArrayProperty', arrayIndex: 0, value: bin((w) => { w.i32(mats.length); mats.forEach((m) => w.i32(m)) }) })
    if (piece.backdrop)
      for (const b of ['CollideActors', 'BlockActors', 'BlockZeroExtent', 'BlockNonZeroExtent', 'BlockRigidBody']) set(ctags, tBool(b, false))
    addExport(sampleMesh, nextName('StaticMeshComponent'), actorRef, serialize({ head: componentHead(meshSample.head), tags: ctags, tail: meshSample.tail }))
    placed.push(actorRef)
  }

  // --- EW's point and spot lights as movable lights ---------------------------------------------------------------
  let lightCount = 0
  for (const light of map.lights) {
    if (!settings.lightKinds.includes(light.kind) || (light.kind !== 'Point' && light.kind !== 'Spot')) continue
    const spot = light.kind === 'Spot'
    const actorSampleL = parse(pkg.data(spot ? sampleSpot : samplePoint), 26)
    const compSampleL = parse(pkg.data(spot ? sampleSpotC : samplePointC), 8)
    const actorRef = exportCount() + 1
    const atags = actorSampleL.tags.map((t) => ({ ...t })).filter((t) => t.name !== 'Tag')
    set(atags, tObj('LightComponent', actorRef + 1))
    set(atags, tVec('Location', light.loc))
    set(atags, tRot('Rotation', light.rot))
    addExport(spot ? sampleSpot : samplePoint, nextName(spot ? 'SpotLightMovable' : 'PointLightMovable'), level, serialize({ head: actorHead(actorSampleL.head), tags: atags, tail: actorSampleL.tail }))
    // The component: its editor previews dropped, its lighting set; its transform is made when it is attached.
    const ctags = compSampleL.tags.filter((t) => !/^Preview|^CachedParentToWorld$/.test(t.name)).map((t) => ({ ...t }))
    set(ctags, tGuid('LightGuid'))
    set(ctags, tGuid('LightmapGuid'))
    set(ctags, tFloat('Brightness', light.brightness * (settings.lightScale > 0 ? settings.lightScale : 1)))
    set(ctags, tColor('LightColor', light.color))
    set(ctags, tFloat('Radius', light.radius))
    set(ctags, tFloat('FalloffExponent', light.falloff))
    set(ctags, tBool('CastShadows', false))
    if (spot) {
      set(ctags, tFloat('InnerConeAngle', light.inner))
      set(ctags, tFloat('OuterConeAngle', light.outer))
    }
    addExport(spot ? sampleSpotC : samplePointC, nextName(spot ? 'SpotLightComponent' : 'PointLightComponent'), actorRef, serialize({ head: componentHead(compSampleL.head), tags: ctags, tail: compSampleL.tail }))
    placed.push(actorRef)
    lightCount++
  }

  // --- The level volume and its tile grid: EW's play area, two tiles to spare on each side, on EW's floor ----------
  // The template's box brush: X and Y from -1536 to 1536, Z from -48 to 1104 (its world bounds a unit wider).
  const BOX = { half: 1536, z0: -48, z1: 1104 }
  const ext = map.playExtent.map((e) => Math.max(e, TILE * 4))
  const min = [map.playCenter[0]! - ext[0]! - 2 * TILE, map.playCenter[1]! - ext[1]! - 2 * TILE, map.playCenter[2]! - ext[2]!]
  const max = [map.playCenter[0]! + ext[0]! + 2 * TILE, map.playCenter[1]! + ext[1]! + 2 * TILE, map.playCenter[2]! + ext[2]!]
  const scale = [(max[0]! - min[0]!) / (2 * BOX.half), (max[1]! - min[1]!) / (2 * BOX.half), (max[2]! - min[2]!) / (BOX.z1 - BOX.z0)]
  const vloc = [(min[0]! + max[0]!) / 2, (min[1]! + max[1]!) / 2, min[2]! - BOX.z0 * scale[2]!]
  {
    const p = parse(pkg.data(volume), 26)
    set(p.tags, tVec('Location', vloc))
    set(p.tags, tVec('DrawScale3D', scale))
    data.set(volume, serialize(p))
  }
  {
    const p = parse(pkg.data(worldData), 4)
    const nx = Math.round((max[0]! - min[0]!) / TILE), ny = Math.round((max[1]! - min[1]!) / TILE), nz = Math.max(1, Math.round((max[2]! - min[2]!) / FLOOR))
    set(p.tags, { name: 'WorldBounds', type: 'StructProperty', struct: 'Box', arrayIndex: 0, value: bin((w) => { [min[0]! - 1, min[1]! - 1, min[2]! - 1, max[0]! + 1, max[1]! + 1, max[2]! + 1].forEach((c) => w.f32(c)); w.u8(1) }) })
    set(p.tags, tInt('NumX', nx))
    set(p.tags, tInt('NumY', ny))
    set(p.tags, tInt('NumZ', nz))
    set(p.tags, tInt('NumTiles', nx * ny * nz))
    data.set(worldData, serialize(p))
  }

  // --- The soldiers' spawns at EW's drop zones (the first in the template's own group spawn) -----------------------
  const spawnSample = parse(pkg.data(spawn), 26)
  map.dropZones.forEach((dz, k) => {
    const loc = [dz[0]!, dz[1]!, dz[2]! - 40]
    if (k === 0) {
      const p = { ...spawnSample, tags: spawnSample.tags.map((t) => ({ ...t })) }
      set(p.tags, tVec('Location', loc))
      data.set(spawn, serialize(p))
      return
    }
    const tags = spawnSample.tags.map((t) => ({ ...t })).filter((t) => t.name !== 'Tag' && t.name !== 'StaticMesh')
    set(tags, tVec('Location', loc))
    placed.push(addExport(spawn, nextName('XComGroupSpawn'), level, serialize({ head: actorHead(spawnSample.head), tags, tail: spawnSample.tail })))
  })
  // The parcel slot (the empty parcel goes there) in the middle of the play area.
  {
    const p = parse(pkg.data(parcel), 26)
    set(p.tags, tVec('Location', [map.playCenter[0]!, map.playCenter[1]!, min[2]! + 16]))
    data.set(parcel, serialize(p))
  }

  // --- The level's actors: the template's own (but its samples and anything deleted), then the new ones -----------
  {
    const d = pkg.data(level)
    const v = new DataView(d.buffer, d.byteOffset, d.byteLength)
    // After the level's (empty) tags: the actor list's owner (the level), its count and its actors.
    const countAt = 16
    const count = v.getInt32(countAt, true)
    const old = Array.from({ length: count }, (_, k) => v.getInt32(countAt + 4 + 4 * k, true))
    const keep = old.filter((r) => r !== 0 && r !== sampleActor && r !== samplePoint && r !== sampleSpot)
    const actors = [...keep, ...placed]
    const w = new Writer()
    w.bytes(d.subarray(0, countAt))
    w.i32(actors.length)
    actors.forEach((r) => w.i32(r))
    w.bytes(d.subarray(countAt + 4 + 4 * count))
    data.set(level, w.done())
  }

  // A package of its own (a new GUID: the game tells packages apart by it).
  pkg.summary.guid = crypto.getRandomValues(new Uint8Array(16))
  const bytes = writePackage(pkg, { data, names, imports, exports: added })
  const tiles = [Math.round((max[0]! - min[0]!) / TILE), Math.round((max[1]! - min[1]!) / TILE), Math.round((max[2]! - min[2]!) / FLOOR)]
  return {
    bytes,
    report: `${map.name}: ${pieces.length} pieces, ${[...mics.values()].filter((r) => r > 0).length} stand-in materials, ${lightCount} lights, ${map.dropZones.length} drop zones; level volume ${tiles.join(' x ')} tiles; ${(bytes.length / 1024).toFixed(0)} KB`,
  }
}

if (/ew-plot\.ts$/.test(process.argv[1] ?? '')) {
  const [template, section, out] = process.argv.slice(2).filter((a) => a !== '--')
  if (!out) {
    console.error('usage: ew-plot.ts <template .umap> <converted map section .ini> <out .umap>')
    process.exit(2)
  }
  const settings: PlotSettings = {
    parents: { Prop: 'Materials.Approved.Props_SD', Foliage: 'Materials.Approved.Vegetations_VO', Alien: 'Materials.Approved.Alien_Props' },
    scalars: [['SpecularScale', 0]],
    textures: [['Masks', 'EngineResources.WhiteSquareTexture']],
    lightScale: 3,
    lightKinds: ['Point', 'Spot'],
  }
  const { bytes, report } = writePlot(new Uint8Array(readFileSync(template!)), readSection(readFileSync(section!, 'latin1')), settings)
  writeFileSync(out!, bytes)
  console.log(report)
}
