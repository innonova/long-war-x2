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
  pieces: { mesh: string; loc: number[]; rot: number[]; scale: number[]; materials: string[]; backdrop: boolean; fractured: boolean; cover: string[]; frac?: { indices: number; minZ: number; maxZ: number; toughness: string } }[]
  /** EW's doors (ew-map.ts): mesh, AnimTree, AnimSets, physics, where, the idle animation, the interaction points. */
  doors: { mesh: string; materials: string[]; tree: string; physics: string; sets: string[]; loc: number[]; rot: number[]; scale: number[]; idle: string; blocksSight: boolean; window: boolean; points: Record<string, string>[] }[]
  looks: Map<string, { kind: string; diffuse: string; normal: string }>
  lights: { kind: string; loc: number[]; rot: number[]; radius: number; brightness: number; color: number[]; falloff: number; inner: number; outer: number }[]
  /** EW's building volumes, each with its floors (a box each). */
  buildings: { center: number[]; extent: number[]; floors: { center: number[]; extent: number[] }[]; ufo: boolean }[]
}

/** The section read from an .ini (ew-map.ts's output). */
export function readSection(text: string): EWMap {
  const num = (s: string, k: string) => Number(new RegExp(`\\b${k}=(-?[\\d.e+-]+)`).exec(s)?.[1] ?? 0)
  const vec = (s: string) => ['X', 'Y', 'Z'].map((k) => num(s, k))
  const sub = (s: string, k: string) => new RegExp(`\\b${k}=\\(([^()]*)\\)`).exec(s)?.[1] ?? ''
  const str = (s: string, k: string) => new RegExp(`\\b${k}="([^"]*)"`).exec(s)?.[1] ?? ''
  const m: EWMap = { name: '', mapPackage: '', playCenter: [0, 0, 0], playExtent: [0, 0, 0], dropZones: [], pieces: [], doors: [], looks: new Map(), lights: [], buildings: [] }
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim()
    let x: RegExpExecArray | null
    if ((x = /^\[(\S+) LWX2EWMapData\]/.exec(line))) m.name = x[1]!
    else if (line.startsWith('MapPackage=')) m.mapPackage = str(line, 'MapPackage')
    else if (line.startsWith('PlayCenter=')) m.playCenter = vec(line)
    else if (line.startsWith('PlayExtent=')) m.playExtent = vec(line)
    else if (line.startsWith('+DropZones=')) m.dropZones.push(vec(line))
    else if (line.startsWith('+Buildings=')) {
      // Center=(…),Extent=(…),Floors=((Center=(…),Extent=(…)),…)
      const boxes = [...line.matchAll(/Center=\(([^()]*)\),Extent=\(([^()]*)\)/g)].map((x) => ({ center: vec(x[1]!), extent: vec(x[2]!) }))
      if (boxes.length) m.buildings.push({ ...boxes[0]!, floors: boxes.slice(1), ufo: /Ufo=true/.test(line) })
    }
    else if (line.startsWith('+Looks='))
      m.looks.set(str(line, 'Material'), { kind: /Kind=(\w+)/.exec(line)?.[1] ?? 'Prop', diffuse: str(line, 'Diffuse'), normal: str(line, 'Normal') })
    else if (line.startsWith('+Doors=')) {
      const sets = /AnimSets=\(([^)]*)\)/.exec(line)?.[1] ?? ''
      const mats = /Materials=\(([^)]*)\)/.exec(line)?.[1] ?? ''
      const points = /Points=\((.*)\)\)$/.exec(line)?.[1] ?? ''
      m.doors.push({
        mesh: str(line, 'Mesh'),
        materials: mats ? mats.split(',').map((x) => x.replace(/"/g, '')) : [],
        tree: str(line, 'AnimTree'),
        physics: str(line, 'Physics'),
        sets: sets ? sets.split(',').map((x) => x.replace(/"/g, '')) : [],
        loc: vec(sub(line, 'Loc')),
        rot: ['Pitch', 'Yaw', 'Roll'].map((k) => num(sub(line, 'Rot'), k)),
        scale: vec(sub(line, 'Scale')),
        idle: /Idle=(\w+)/.exec(line)?.[1] ?? 'None',
        blocksSight: /BlocksSight=true/.test(line),
        window: /Window=true/.test(line),
        points: [...points.matchAll(/\(([^()]*)\)/g)].map((p) => Object.fromEntries(p[1]!.split(',').map((kv) => kv.split('=') as [string, string]))),
      })
    }
    else if (line.startsWith('+Pieces=')) {
      const mats = /Materials=\(([^)]*)\)/.exec(line)?.[1] ?? ''
      m.pieces.push({
        mesh: str(line, 'Mesh'),
        loc: vec(sub(line, 'Loc')),
        rot: ['Pitch', 'Yaw', 'Roll'].map((k) => num(sub(line, 'Rot'), k)),
        scale: vec(sub(line, 'Scale')),
        materials: mats ? mats.split(',').map((s) => s.replace(/"/g, '')) : [],
        backdrop: /Backdrop=true/.test(line),
        fractured: /Fractured=true/.test(line),
        frac: (() => {
          const f = /Frac=\(Indices=(\d+),MinZ=([-\d.]+),MaxZ=([-\d.]+),Toughness=(\w+)\)/.exec(line)
          return f ? { indices: Number(f[1]), minZ: Number(f[2]), maxZ: Number(f[3]), toughness: f[4]! } : undefined
        })(),
        // Its cover flags where they differ from an XComLevelActor's (ew-map.ts: ClimbOnto=false, CoverForce=…).
        cover: [...line.matchAll(/,(ClimbOnto|ClimbOver|Destination|IgnoreForCover|CoverForce)=(\w+)/g)].map((m) => `${m[1]}=${m[2]}`),
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
  /** The XCOM 2 parent material for each kind of EW material (Prop, Foliage, Masked, Alien). */
  parents: Record<string, string>
  /** The kinds whose stand-ins take their diffuse as their Masks texture too (the ones cut out by its alpha). */
  diffuseMasks?: string[]
  /** The parent for pieces inside EW's buildings (XCOM 2's building material, whose shaders its building visibility
   *  draws with); "" for the kind's parent. */
  buildingParent?: string
  /** Whether EW's buildings are written as XCOM 2 building and floor volumes (roofs cut away; off: some maps' plots
   *  crashed the game as they loaded, lw-missions.md). */
  buildings?: boolean
  /** Whether EW's walls are XCOM 2's breakable walls (XComFracLevelActor; else drawn whole as level actors). */
  fracWalls?: boolean
  /** Scalars and textures set on every stand-in. */
  scalars: [string, number][]
  textures: [string, string][]
  /** EW's light brightness scale, and the kinds placed. */
  lightScale: number
  lightKinds: string[]
}

/**
 * EW materials no stand-in can be made from (no diffuse map found): by name. Markers and skies are not written at all (a
 * drop zone's marker, the level designers' border; EW's sky domes, where XCOM 2's lighting map brings its own sky), nor
 * decal-like effects an opaque stand-in would draw as slabs (road paint, puddles, scorch marks, fire). Glass becomes a
 * translucent pane; anything else a plain grey stand-in.
 */
const SKIPPED_MATERIAL = /Drop_Zone|DESIGN_Border|Sky\b|Sky_|NightSky|DuskSky|NoonSky|SkyDome|RoadPaint|Puddle|Decal|Scar|Asphalt_Patch|Burning|Charred|Black$/i
const GLASS_MATERIAL = /Glass|Window/i
const GLASS = { parent: 'Materials.Approved.Translucent_SD', diffuse: 'EngineResources.WhiteSquareTexture', opacity: 0.35, specular: 0.5 }
const GREY = { diffuse: 'EngineResources.WhiteSquareTexture', tint: [0.35, 0.35, 0.35, 1] }

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
  const namesByText = new Map<string, number>()
  pkg.names.forEach((n: NameEntry, k: number) => { if (!namesByText.has(n.name)) namesByText.set(n.name, k) })
  const nameIndex = (s: string): number => {
    const i = namesByText.get(s)
    if (i !== undefined) return i
    names.push({ name: s, flags: nameFlags })
    namesByText.set(s, pkg.names.length + names.length - 1)
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
  /** The imports by path (lower case), the template's read once. */
  const importsByPath = new Map<string, number>()
  pkg.imports.forEach((_: Import, k: number) => importsByPath.set(importPath(-k - 1).toLowerCase(), -k - 1))
  /** An import by path (its outers made as packages), of a class in a class package. */
  const importRef = (path: string, className: string, classPackage = 'Engine'): number => {
    const found = importsByPath.get(path.toLowerCase())
    if (found !== undefined) return found
    const parts = path.split('.')
    const outer = parts.length > 1 ? importRef(parts.slice(0, -1).join('.'), 'Package', 'Core') : 0
    imports.push({ classPackage: objName(classPackage), className: objName(className), outer, objectName: objName(parts.at(-1)!) })
    const ref = -(pkg.imports.length + imports.length)
    importsByPath.set(path.toLowerCase(), ref)
    return ref
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
  const addExport = (sample: number, name: string, outer: number, bytes: Uint8Array, over: Partial<Export> = {}): number => {
    const e = pkg.exports[sample - 1]
    added.push({ entry: { ...e, outer, objectName: objName(name), serialSize: 0, serialOffset: 0, exportFlags: 0, netObjects: [], ...over }, data: bytes })
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
  const tName = (name: string, value: string): T => ({ name, type: 'NameProperty', arrayIndex: 0, value: bin((w) => { const r = objName(value); w.i32(r.index).i32(r.number) }) })
  const tEnum = (name: string, enumName: string, value: string): T => ({ name, type: 'ByteProperty', enumName, arrayIndex: 0, value: bin((w) => { const r = objName(value); w.i32(r.index).i32(r.number) }) })
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
  const micFor = (path: string, inBuilding = false): number => {
    if (!path) return 0
    const key = (inBuilding ? 'B|' : '') + path
    if (mics.has(key)) return mics.get(key)!
    const look = map.looks.get(path)
    let ref = 0
    if (look && !look.diffuse && !SKIPPED_MATERIAL.test(path)) {
      // No diffuse map found: glass as a translucent pane, anything else plain grey.
      const glass = GLASS_MATERIAL.test(path)
      const p = parse(pkg.data(sampleMIC), 4)
      const name = (n: string) => bin((x) => { const r = objName(n); x.i32(r.index).i32(r.number) })
      const param = (n: string, value: T) => serialize({ head: new Uint8Array(0), tags: [{ name: 'ParameterName', type: 'NameProperty', arrayIndex: 0, value: name(n) }, value], tail: new Uint8Array(0) })
      const scalars: [string, number][] = glass ? [['Opacity', GLASS.opacity], ['SpecularScale', GLASS.specular]] : settings.scalars
      const tags: T[] = [
        tObj('Parent', importRef(glass ? GLASS.parent : settings.parents.Prop!, 'Material')),
        tGuid('LightingGuid'),
        { name: 'TextureParameterValues', type: 'ArrayProperty', arrayIndex: 0, value: bin((w) => { w.i32(1); w.bytes(param('Diffuse', tObj('ParameterValue', importRef(glass ? GLASS.diffuse : GREY.diffuse, 'Texture2D')))) }) },
        { name: 'ScalarParameterValues', type: 'ArrayProperty', arrayIndex: 0, value: bin((w) => { w.i32(scalars.length); for (const [n, v] of scalars) w.bytes(param(n, tFloat('ParameterValue', v))) }) },
      ]
      if (!glass)
        tags.push({ name: 'VectorParameterValues', type: 'ArrayProperty', arrayIndex: 0, value: bin((w) => { w.i32(1); w.bytes(param('TintColor', { name: 'ParameterValue', type: 'StructProperty', struct: 'LinearColor', arrayIndex: 0, value: bin((x) => GREY.tint.forEach((c) => x.f32(c))) })) }) })
      ref = addExport(sampleMIC, nextName(glass ? 'LWX2Glass' : 'LWX2Grey'), level, serialize({ head: objectHead(), tags, tail: p.tail }))
      mics.set(key, ref)
      return ref
    }
    if (inBuilding && settings.buildingParent && look && look.diffuse) {
      // A piece of a building: XCOM 2's building material, EW's textures in each of its three layers.
      const p = parse(pkg.data(sampleMIC), 4)
      const name = (n: string) => bin((x) => { const r = objName(n); x.i32(r.index).i32(r.number) })
      const param = (n: string, value: T) => serialize({ head: new Uint8Array(0), tags: [{ name: 'ParameterName', type: 'NameProperty', arrayIndex: 0, value: name(n) }, value], tail: new Uint8Array(0) })
      const tex: [string, number][] = []
      for (const layer of ['Bottom', 'Mid', 'Top']) {
        tex.push([`${layer}_Diffuse`, importRef(look.diffuse, 'Texture2D')])
        if (look.normal) tex.push([`${layer}_Normal`, importRef(look.normal, 'Texture2D')])
      }
      const tags: T[] = [
        tObj('Parent', importRef(settings.buildingParent, 'Material')),
        tGuid('LightingGuid'),
        { name: 'TextureParameterValues', type: 'ArrayProperty', arrayIndex: 0, value: bin((w) => { w.i32(tex.length); for (const [n, t] of tex) w.bytes(param(n, tObj('ParameterValue', t))) }) },
      ]
      const ref = addExport(sampleMIC, nextName('LWX2Building'), level, serialize({ head: objectHead(), tags, tail: p.tail }))
      mics.set(key, ref)
      return ref
    }
    if (look && look.diffuse && settings.parents[look.kind]) {
      const p = parse(pkg.data(sampleMIC), 4)
      const tags: T[] = [tObj('Parent', importRef(settings.parents[look.kind]!, 'Material')), tGuid('LightingGuid')]
      const texParams: [string, number][] = [['Diffuse', importRef(look.diffuse, 'Texture2D')]]
      if (look.normal) texParams.push(['Normal', importRef(look.normal, 'Texture2D')])
      // The kinds cut out by the diffuse's alpha take it as their masks too: XCOM 2's masked parents read the opacity
      // from one of the two.
      const cutOut = settings.diffuseMasks?.includes(look.kind)
      if (cutOut) texParams.push(['Masks', importRef(look.diffuse, 'Texture2D')])
      for (const [n, t] of settings.textures) if (!(cutOut && n === 'Masks')) texParams.push([n, importRef(t, 'Texture2D')])
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
    mics.set(key, ref)
    return ref
  }

  // --- The pieces ------------------------------------------------------------------------------------------------
  const actorSample = parse(pkg.data(sampleActor), 26)
  const meshSample = parse(pkg.data(sampleMesh), 8)
  // Meshes EW generated inside its own level (its volumes' meshes) are not in the converted package's carried content.
  // (Debugging a plot that crashes the game: LWX2_PLOT_DEBUG=nopieces leaves EW's pieces out, pieces=a-b keeps
  // the a-th to the (b-1)-th, only=MeshA,MeshB those meshes, nomats leaves their stand-ins out.)
  const debug = process.env.LWX2_PLOT_DEBUG ?? ''
  const pieces = debug.includes('nopieces') ? [] : map.pieces.filter(
    (p) => !p.mesh.startsWith('TheWorld.') && !/SkyDome|Skybox/i.test(p.mesh)
      && !(p.materials.length > 0 && p.materials.every((m) => !m || (SKIPPED_MATERIAL.test(m) && !map.looks.get(m)?.diffuse))),
  ).filter((_p, k) => {
    const range = /pieces=(\d+)-(\d+)/.exec(debug)
    return !range || (k >= Number(range[1]) && k < Number(range[2]))
  }).filter((p) => {
    const only = /only=([\w,]+)/.exec(debug)
    return !only || only[1]!.split(',').some((m) => p.mesh.endsWith('.' + m))
  })
  let fracCount = 0
  const fracClass = () => importRef('XComGame.XComFracLevelActor', 'Class', 'Core')
  const fracDefault = () => importRef('XComGame.Default__XComFracLevelActor', 'XComFracLevelActor', 'XComGame')
  for (const piece of pieces) {
    // Its stand-ins first: they are exports too, and the actor's component must come right after the actor.
    const inBuilding = map.buildings.some((b) => [0, 1, 2].every((c) => Math.abs(piece.loc[c]! - b.center[c]!) <= b.extent[c]! + 16))
    const mats = debug.includes('nomats') ? [] : piece.materials.map((m) => micFor(m, inBuilding))
    // A wall that breaks: XCOM 2's fracturable actor with its own class defaults as archetype, EW's fracture data on the
    // component, EW's toughness in its Tag (LWX2T_MASONRY …) for the mod to give it XCOM 2's at the battle's start.
    const frac = settings.fracWalls && piece.fractured && piece.frac ? piece.frac : undefined
    const actorName = nextName(frac ? 'XComFracLevelActor' : 'XComLevelActor')
    const actorRef = exportCount() + 1
    const compRef = actorRef + 1
    const atags = actorSample.tags.map((t) => ({ ...t })).filter((t) => t.name !== 'Tag' && !(frac && t.name === 'StaticMeshComponent'))
    if (frac) {
      set(atags, tObj('FracturedStaticMeshComponent', compRef))
      set(atags, tName('Tag', `LWX2T_${frac.toughness}`))
    } else set(atags, tObj('StaticMeshComponent', compRef))
    set(atags, tObj('CollisionComponent', compRef))
    set(atags, tVec('Location', piece.loc))
    set(atags, tRot('Rotation', piece.rot))
    set(atags, tVec('DrawScale3D', piece.scale))
    // EW's backdrop (its huge pieces: ground beyond the play area, cliffs, the sky) kept out of the buildings' floors:
    // XCOM 2's building visibility would hide it with the floor it overlaps.
    if (piece.backdrop) set(atags, tBool('bExcludeFromBuildingVolume', true))
    // What units may do with it, as in EW (a car's hood, sandbags: not to be stood on).
    for (const c of piece.cover) {
      const [k, val] = c.split('=') as [string, string]
      if (k === 'CoverForce') set(atags, tEnum('CoverForceFlag', 'ECoverForceFlag', val))
      else set(atags, tBool({ ClimbOnto: 'bCanClimbOnto', ClimbOver: 'bCanClimbOver', Destination: 'bIsValidDestination', IgnoreForCover: 'bIgnoreForCover' }[k]!, val === 'true'))
    }
    addExport(sampleActor, actorName, level, serialize({ head: actorHead(actorSample.head), tags: atags, tail: actorSample.tail }),
      frac ? { classIndex: fracClass(), archetype: fracDefault() } : {})
    const ctags = meshSample.tags.map((t) => ({ ...t }))
    set(ctags, tObj('StaticMesh', importRef(piece.mesh, piece.fractured ? 'FracturedStaticMesh' : 'StaticMesh')))
    if (frac) {
      set(ctags, tInt('NumResourceIndices', frac.indices))
      set(ctags, tFloat('FragmentBoundsMinZ', frac.minZ))
      set(ctags, tFloat('FragmentBoundsMaxZ', frac.maxZ))
      set(ctags, tBool('bUseDynamicIndexBuffer', true))
    }
    if (mats.length)
      set(ctags, { name: 'Materials', type: 'ArrayProperty', arrayIndex: 0, value: bin((w) => { w.i32(mats.length); mats.forEach((m) => w.i32(m)) }) })
    if (piece.backdrop)
      for (const b of ['CollideActors', 'BlockActors', 'BlockZeroExtent', 'BlockNonZeroExtent', 'BlockRigidBody']) set(ctags, tBool(b, false))
    if (frac) {
      // The component's head names the class whose template it is: the frac actor's.
      const head = Uint8Array.from(meshSample.head)
      new DataView(head.buffer).setInt32(0, fracClass(), true)
      new DataView(head.buffer).setInt32(4, NONE, true)
      addExport(sampleMesh, nextName('FracturedStaticMeshComponent'), actorRef, serialize({ head, tags: ctags, tail: meshSample.tail }),
        { classIndex: importRef('Engine.FracturedStaticMeshComponent', 'Class', 'Core'), archetype: importRef('XComGame.Default__XComFracLevelActor.FracturedStaticMeshComponent0', 'FracturedStaticMeshComponent') })
      fracCount++
    } else
      addExport(sampleMesh, nextName('StaticMeshComponent'), actorRef, serialize({ head: componentHead(meshSample.head), tags: ctags, tail: meshSample.tail }))
    placed.push(actorRef)
  }

  // --- EW's doors as XCOM 2's interactive level actors ------------------------------------------------------------
  // The class's own defaults as archetype (no XCOM 2 door: EW's mesh, AnimTree and AnimSets, which the map's package
  // carries; their AnimNodeBlendList is named Anim, as XCOM 2's code looks for). The interaction points as EW's, the
  // unit's animation named as XCOM 2's doors name it by facing (EW's was an enum, eAnimAction_OpenDoor).
  const UNIT_DOOR_ANIM: Record<string, string> = { eIF_Left: 'HL_DoorOpenA', eIF_Front: 'NO_DoorOpenA', eIF_Right: 'HR_DoorOpenA' }
  let doorCount = 0
  if (!debug.includes('nodoors') && map.doors.length) {
    const doorClass = importRef('XComGame.XComInteractiveLevelActor', 'Class', 'Core')
    const doorDefault = importRef('XComGame.Default__XComInteractiveLevelActor', 'XComInteractiveLevelActor', 'XComGame')
    const skelClass = importRef('Engine.SkeletalMeshComponent', 'Class', 'Core')
    const skelArch = importRef('XComGame.Default__XComInteractiveLevelActor.SkeletalMeshComponent0', 'SkeletalMeshComponent')
    for (const door of map.doors) {
      // Its stand-ins first (exports too: the component must come right after the actor), as the pieces'.
      const doorMats = door.materials.map((m) => micFor(m, true))
      const actorRef = exportCount() + 1
      const compRef = actorRef + 1
      const points = door.points.map((p) => serialize({
        head: new Uint8Array(0),
        tags: [
          tEnum('SrcSocket', 'EInteractionSocket', p.Src!),
          ...(p.Dest && p.Dest !== 'None' ? [tEnum('DestSocket', 'EInteractionSocket', p.Dest)] : []),
          tName('UnitInteractionAnimName', UNIT_DOOR_ANIM[p.Facing!] ?? 'NO_DoorOpenA'),
          ...(['Anim', 'Destroy', 'Inactive'] as const).filter((k) => p[k] && p[k] !== 'None')
            .map((k) => tEnum({ Anim: 'InteractionAnim', Destroy: 'DestroyAnim', Inactive: 'InactiveIdleAnim' }[k], 'EInteractionAnim', p[k]!)),
          ...(p.Mirror === 'true' ? [tBool('bMirrorAnims', true)] : []),
          tEnum('Facing', 'EInteractionFacing', p.Facing!),
        ],
        tail: new Uint8Array(0),
      }))
      const atags: T[] = [
        { name: 'InteractionPoints', type: 'ArrayProperty', arrayIndex: 0, value: bin((w) => { w.i32(points.length); points.forEach((b) => w.bytes(b)) }) },
        ...(door.idle !== 'None' ? [tEnum('ActiveIdleAnim', 'EInteractionAnim', door.idle)] : []),
        tObj('SkeletalMeshComponent', compRef),
        { name: 'VisibilityBlockingData', type: 'StructProperty', struct: 'VisibilityBlocking', arrayIndex: 0, value: serialize({
          head: new Uint8Array(0),
          tags: [tBool('bBlockUnitVisibility', door.blocksSight), tEnum('eBlockCameraVisibility', 'ECameraVisibilityType', 'eCameraVisibilityType_DoNotBlockCamera'), ...(door.window ? [tBool('bIsWindow', true)] : [])],
          tail: new Uint8Array(0),
        }) },
        tVec('Location', door.loc),
        tRot('Rotation', door.rot),
        tVec('DrawScale3D', door.scale),
        tObj('CollisionComponent', compRef),
      ]
      addExport(sampleActor, nextName('XComInteractiveLevelActor'), level, serialize({ head: actorHead(actorSample.head), tags: atags, tail: actorSample.tail }), { classIndex: doorClass, archetype: doorDefault })
      const ctags: T[] = [tObj('SkeletalMesh', importRef(door.mesh, 'SkeletalMesh'))]
      if (doorMats.some((m) => m)) ctags.push({ name: 'Materials', type: 'ArrayProperty', arrayIndex: 0, value: bin((w) => { w.i32(doorMats.length); doorMats.forEach((m) => w.i32(m)) }) })
      if (door.tree) ctags.push(tObj('AnimTreeTemplate', importRef(door.tree, 'AnimTree')))
      if (door.physics) ctags.push(tObj('PhysicsAsset', importRef(door.physics, 'PhysicsAsset')))
      if (door.sets.length) {
        const sets = door.sets.map((s) => importRef(s, 'AnimSet'))
        ctags.push({ name: 'AnimSets', type: 'ArrayProperty', arrayIndex: 0, value: bin((w) => { w.i32(sets.length); sets.forEach((s) => w.i32(s)) }) })
      }
      // A component's head: the class whose template it is, then its net index.
      const head = bin((w) => w.i32(doorClass).i32(NONE))
      addExport(sampleMesh, nextName('SkeletalMeshComponent'), actorRef, serialize({ head, tags: ctags, tail: new Uint8Array(0) }), { classIndex: skelClass, archetype: skelArch })
      placed.push(actorRef)
      doorCount++
    }
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

  // --- EW's buildings: a building volume each, a floor volume each of its floors (box actors on the template's brush) -----
  // XCOM 2's building visibility cuts a building's roof and upper floors away when a unit is inside or below them.
  const brushComp = byPath('XComLevelVolume_0.BrushComponent_0')
  const boxModel = byPath('XComLevelVolume_0.Model_LV')
  const volumeSample = parse(pkg.data(volume), 26)
  const compSample = parse(pkg.data(brushComp), 8)
  let floorCount = 0
  /** A box volume of an XComGame class (the template's box brush, scaled and placed), with extra tags. */
  const boxVolume = (className: string, name: string, box: { center: number[]; extent: number[] }, extra: T[]): number => {
    const classRef = importRef(`XComGame.${className}`, 'Class', 'Core')
    const defaultRef = importRef(`XComGame.Default__${className}`, className, 'XComGame')
    const compArch = importRef(`XComGame.Default__${className}.BrushComponent0`, 'BrushComponent')
    const s = [box.extent[0]! / BOX.half, box.extent[1]! / BOX.half, box.extent[2]! / ((BOX.z1 - BOX.z0) / 2)]
    const loc = [box.center[0]!, box.center[1]!, box.center[2]! - s[2]! * ((BOX.z0 + BOX.z1) / 2)]
    const actorRef = exportCount() + 1
    const head = actorHead(volumeSample.head)
    new DataView(head.buffer).setInt32(0, classRef, true)
    new DataView(head.buffer).setInt32(4, classRef, true)
    const tags: T[] = [tObj('Brush', boxModel), tObj('BrushComponent', actorRef + 1), tObj('CollisionComponent', actorRef + 1), tVec('Location', loc), tVec('DrawScale3D', s), ...extra]
    addExport(volume, name, level, serialize({ head, tags, tail: volumeSample.tail }), { classIndex: classRef, archetype: defaultRef })
    addExport(brushComp, nextName('BrushComponent'), actorRef, serialize({ head: componentHead(compSample.head), tags: compSample.tags.map((t) => ({ ...t })), tail: compSample.tail }), { archetype: compArch })
    placed.push(actorRef)
    return actorRef
  }
  // XCOM 2 takes a building's floors stacked, one above the other: EW's sorted by height, each one's bottom raised to the
  // top of the one below it (some overlap), those left without height dropped; a building without floors is left out (a
  // plot with overlapping floors crashed the game as it generated the map: URB_OfficePaper_EWI).
  const stacked = (b: EWMap['buildings'][number]) => {
    const out: { center: number[]; extent: number[] }[] = []
    let top = -Infinity
    for (const f of [...b.floors].sort((x, y) => x.center[2]! - y.center[2]!)) {
      const lo = Math.max(f.center[2]! - f.extent[2]!, top)
      const hi = f.center[2]! + f.extent[2]!
      if (hi - lo < 32) continue
      out.push({ center: [f.center[0]!, f.center[1]!, (lo + hi) / 2], extent: [f.extent[0]!, f.extent[1]!, (hi - lo) / 2] })
      top = hi
    }
    return out
  }
  for (const b of settings.buildings ? map.buildings : []) {
    const ewFloors = stacked(b)
    if (!ewFloors.length) continue
    const floors = ewFloors.map((f, k) => {
      floorCount++
      // XCOM 2 numbers a building's floors from 1 (with 0 its building visibility hid the ground floor whole).
      return { ref: boxVolume('XComFloorVolume', nextName('XComFloorVolume'), f, [tInt('FloorNumber', k + 1)]), z: f.center[2]!, extent: f.extent[2]! }
    })
    // Floors: an array of tagged structs (fCenterZ, fExtent, FloorVolumes), each ended by None.
    const floorsTag: T = {
      name: 'Floors', type: 'ArrayProperty', arrayIndex: 0,
      value: bin((w) => {
        w.i32(floors.length)
        for (const f of floors)
          w.bytes(serialize({ head: new Uint8Array(0), tags: [tFloat('fCenterZ', f.z), tFloat('fExtent', f.extent), { name: 'FloorVolumes', type: 'ArrayProperty', arrayIndex: 0, value: bin((x) => { x.i32(1); x.i32(f.ref) }) }], tail: new Uint8Array(0) }))
      }),
    }
    boxVolume('XComBuildingVolume', nextName('XComBuildingVolume'), b, [floorsTag, ...(b.ufo ? [tBool('IsUfo', true)] : [])])
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
    // A plot without a light crashed the game as it generated the map (XCOM 2's light clipping manager, made for the
    // level's lights, read as missing): without EW lights, the template's point light stays, dark, high above the map.
    const keepPoint = lightCount === 0
    if (keepPoint) {
      const a = parse(pkg.data(samplePoint), 26)
      set(a.tags, tVec('Location', [map.playCenter[0]!, map.playCenter[1]!, max[2]! + 2000]))
      data.set(samplePoint, serialize(a))
      const c = parse(pkg.data(samplePointC), 8)
      set(c.tags, tFloat('Brightness', 0))
      set(c.tags, tBool('CastShadows', false))
      data.set(samplePointC, serialize(c))
    }
    const keep = old.filter((r) => r !== 0 && r !== sampleActor && (r !== samplePoint || keepPoint) && r !== sampleSpot)
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
    report: `${map.name}: ${pieces.length} pieces, ${[...mics.values()].filter((r) => r > 0).length} stand-in materials, ${doorCount} doors, ${fracCount} breakable walls, ${lightCount} lights, ${map.dropZones.length} drop zones, ${map.buildings.length} buildings (${floorCount} floors); level volume ${tiles.join(' x ')} tiles; ${(bytes.length / 1024).toFixed(0)} KB`,
  }
}

if (/ew-plot\.ts$/.test(process.argv[1] ?? '')) {
  const [template, section, out] = process.argv.slice(2).filter((a) => a !== '--')
  if (!out) {
    console.error('usage: ew-plot.ts <template .umap> <converted map section .ini> <out .umap>')
    process.exit(2)
  }
  const settings: PlotSettings = {
    parents: { Prop: 'Materials.Approved.Props_SD', Foliage: 'Materials.Approved.Vegetations_VO', Masked: 'Materials.Approved.Props_OpcMask_TC', Alien: 'Materials.Approved.Alien_Props' },
    diffuseMasks: (process.env.LWX2_DIFFUSE_MASKS ?? 'Foliage,Masked').split(',').filter(Boolean),
    scalars: [['SpecularScale', 0]],
    textures: [['Masks', 'EngineResources.WhiteSquareTexture']],
    lightScale: 1,
    lightKinds: ['Point', 'Spot'],
    buildingParent: process.env.LWX2_BUILDING_PARENT ?? '',
    buildings: process.env.LWX2_BUILDINGS === '1',
    fracWalls: process.env.LWX2_FRAC_WALLS === '1',
  }
  const { bytes, report } = writePlot(new Uint8Array(readFileSync(template!)), readSection(readFileSync(section!, 'latin1')), settings)
  writeFileSync(out!, bytes)
  console.log(report)
}
