// EW's right-side cover animations (features/lw-ew-units.md): EW has its units' cover animations for the left side only
// (AC_LL_*, AC_HL_*) and plays the right side by mirroring them (its AnimTree's mirror node, the mesh's SkelMirrorTable).
// XCOM 2 asks for each side by name (LL_/LR_, HL_/HR_), so a right-side name gets a mirrored copy of EW's left-side
// animation: each frame decoded, mirrored through the skeleton as UE3 mirrors (in component space: the mirror axis
// reflected, each bone's flip axis turned back), and written per track with a key a frame.
//
// The compressed formats as UE Viewer (MIT) documents them for package version 845; nothing copied.
import { Package } from '@innonova/upkit/upk'

export type Quat = [number, number, number, number]
export type Vec3 = [number, number, number]
/** A track's keys, spread evenly over the sequence's frames unless frames are given. */
interface Keys<T> {
  values: T[]
  frames?: number[]
}
export interface Track {
  position: Keys<Vec3> | null
  rotation: Keys<Quat> | null
}
export interface Sequence {
  frames: number
  tracks: Track[]
}

const FORMATS = ['ACF_None', 'ACF_Float96NoW', 'ACF_Fixed48NoW', 'ACF_IntervalFixed32NoW', 'ACF_Fixed32NoW', 'ACF_Float32NoW', 'ACF_Identity']
const withW = (x: number, y: number, z: number): Quat => [x, y, z, Math.sqrt(Math.max(0, 1 - x * x - y * y - z * z))]
const unit = (x: number, bits: number) => {
  const half = (1 << (bits - 1)) - 1
  return (x - half) / half
}
const fixed32 = (p: number): Vec3 => [unit(p >>> 21, 11), unit((p >>> 10) & 2047, 11), unit(p & 1023, 10)]

/** A tagged property: its name, type, enum or struct name, and where its value is (within the object's data). */
export interface Prop {
  name: string
  type: string
  sub: string
  /** Where the tag starts and its value, and the value's size. */
  start: number
  at: number
  size: number
}
/** An object's tagged properties (after its net index); returns them and where they end (after None). */
export function readProps(pkg: Package, d: Uint8Array): { props: Prop[]; end: number } {
  const v = new DataView(d.buffer, d.byteOffset, d.byteLength)
  const props: Prop[] = []
  let o = 4
  const name = () => {
    const s = pkg.names[v.getInt32(o, true)] ?? ''
    o += 8
    return s
  }
  for (;;) {
    const start = o
    const p = name()
    if (p === 'None') return { props, end: o }
    const type = name()
    const size = v.getInt32(o, true)
    o += 8
    if (type === 'BoolProperty') {
      props.push({ name: p, type, sub: '', start, at: o, size: 1 })
      o += 1
      continue
    }
    const sub = type === 'StructProperty' || type === 'ByteProperty' ? name() : ''
    props.push({ name: p, type, sub, start, at: o, size })
    o += size
  }
}

/** A sequence's header properties and where its compressed bytes are. */
export function sequenceHeader(pkg: Package, index: number) {
  const e = pkg.exports[index]!
  const d = pkg.bytes.subarray(e.offset, e.offset + e.size)
  const v = new DataView(d.buffer, d.byteOffset, d.byteLength)
  const { props, end: propsEnd } = readProps(pkg, d)
  const find = (n: string) => props.find((t) => t.name === n)
  const name = (t?: Prop) => (t ? pkg.names[v.getInt32(t.at + t.size - 8, true)]! : '')
  const int = (t?: Prop) => (t ? v.getInt32(t.at, true) : 0)
  const off = find('CompressedTrackOffsets')
  const offsets = off ? Array.from({ length: int(off) }, (_, k) => v.getInt32(off.at + 4 + 4 * k, true)) : []
  // After the properties: the raw animation (empty when cooked) and the compressed bytes, the array that ends the object.
  let stream = -1
  let streamSize = 0
  for (let o = propsEnd; o + 4 <= d.length; o++) {
    const n = v.getInt32(o, true)
    if (n >= 0 && o + 4 + n === d.length) {
      stream = o + 4
      streamSize = n
      break
    }
  }
  return {
    props,
    propsEnd,
    frames: int(find('NumFrames')),
    keyFormat: name(find('KeyEncodingFormat')) || 'AKF_ConstantKeyLerp',
    rotationFormat: name(find('RotationCompressionFormat')) || 'ACF_Float96NoW',
    translationFormat: name(find('TranslationCompressionFormat')) || 'ACF_None',
    offsets,
    data: d,
    stream,
    streamSize,
  }
}

/** Every key of every track of a sequence (tracks in the AnimSet's TrackBoneNames order). */
export function decodeSequence(pkg: Package, index: number, trackCount: number): Sequence {
  const h = sequenceHeader(pkg, index)
  const out: Sequence = { frames: h.frames, tracks: [] }
  if (h.stream < 0) {
    for (let j = 0; j < trackCount; j++) out.tracks.push({ position: null, rotation: null })
    return out
  }
  const v = new DataView(h.data.buffer, h.data.byteOffset + h.stream, h.streamSize)
  const f32 = (o: number) => v.getFloat32(o, true)
  const u16 = (o: number) => v.getUint16(o, true)
  const u32 = (o: number) => v.getUint32(o, true)
  if (h.keyFormat === 'AKF_PerTrackCompression') {
    for (let j = 0; j < trackCount; j++) {
      const tOff = h.offsets[2 * j]!
      const rOff = h.offsets[2 * j + 1]!
      out.tracks.push({
        position: tOff >= 0 ? (perTrack(v, tOff, false, h.frames) as Keys<Vec3>) : null,
        rotation: rOff >= 0 ? (perTrack(v, rOff, true, h.frames) as Keys<Quat>) : null,
      })
    }
    return out
  }
  for (let j = 0; j < trackCount; j++) {
    const [tOff, tKeys, rOff, rKeys] = h.offsets.slice(4 * j, 4 * j + 4) as [number, number, number, number]
    let position: Keys<Vec3> | null = null
    if (tKeys > 0 && tOff >= 0) {
      const fmt = tKeys === 1 ? 'ACF_None' : h.translationFormat
      let o = tOff
      let mins = [0, 0, 0]
      let ranges = [0, 0, 0]
      if (fmt === 'ACF_IntervalFixed32NoW') {
        mins = [f32(o), f32(o + 4), f32(o + 8)]
        ranges = [f32(o + 12), f32(o + 16), f32(o + 20)]
        o += 24
      }
      const values: Vec3[] = []
      for (let k = 0; k < tKeys; k++) {
        if (fmt === 'ACF_IntervalFixed32NoW') {
          const q = fixed32(u32(o))
          values.push([q[0] * ranges[0]! + mins[0]!, q[1] * ranges[1]! + mins[1]!, q[2] * ranges[2]! + mins[2]!])
          o += 4
        } else if (fmt === 'ACF_Fixed48NoW') {
          values.push([unit(u16(o), 16), unit(u16(o + 2), 16), unit(u16(o + 4), 16)])
          o += 6
        } else if (fmt === 'ACF_Identity') values.push([0, 0, 0])
        else {
          values.push([f32(o), f32(o + 4), f32(o + 8)])
          o += 12
        }
      }
      position = { values }
    }
    let rotation: Keys<Quat> | null = null
    if (rKeys > 0 && rOff >= 0) {
      const fmt = rKeys === 1 ? 'ACF_Float96NoW' : h.rotationFormat
      let o = rOff
      let mins = [0, 0, 0]
      let ranges = [1, 1, 1]
      if (rKeys > 1 && fmt === 'ACF_IntervalFixed32NoW') {
        mins = [f32(o), f32(o + 4), f32(o + 8)]
        ranges = [f32(o + 12), f32(o + 16), f32(o + 20)]
        o += 24
      }
      const values: Quat[] = []
      for (let k = 0; k < rKeys; k++) {
        if (fmt === 'ACF_None') {
          values.push([f32(o), f32(o + 4), f32(o + 8), f32(o + 12)])
          o += 16
        } else if (fmt === 'ACF_Float96NoW') {
          values.push(withW(f32(o), f32(o + 4), f32(o + 8)))
          o += 12
        } else if (fmt === 'ACF_Fixed48NoW') {
          values.push(withW(unit(u16(o), 16), unit(u16(o + 2), 16), unit(u16(o + 4), 16)))
          o += 6
        } else if (fmt === 'ACF_Fixed32NoW' || fmt === 'ACF_IntervalFixed32NoW') {
          const q = fixed32(u32(o))
          values.push(withW(q[0] * ranges[0]! + mins[0]!, q[1] * ranges[1]! + mins[1]!, q[2] * ranges[2]! + mins[2]!))
          o += 4
        } else if (fmt === 'ACF_Identity') values.push([0, 0, 0, 1])
        else throw new Error(`rotation format ${fmt} not read`)
      }
      rotation = { values }
    }
    out.tracks.push({ position, rotation })
  }
  return out
}

/** A per-track compressed track at o: its header (format, component flags, key count), then its keys and frame table. */
function perTrack(v: DataView, at: number, rotation: boolean, seqFrames: number): Keys<number[]> {
  const w = v.getUint32(at, true)
  const format = FORMATS[w >>> 28] ?? '?'
  const flags = (w >>> 24) & 0xf
  const n = Math.max(1, w & 0xffffff)
  let o = at + 4
  const has = (k: number) => (flags & (1 << k)) !== 0
  const f32 = (x: number) => v.getFloat32(x, true)
  const mins = [0, 0, 0]
  const ranges = [0, 0, 0]
  if (format === 'ACF_IntervalFixed32NoW')
    for (let k = 0; k < 3; k++)
      if (has(k)) {
        mins[k] = f32(o)
        ranges[k] = f32(o + 4)
        o += 8
      }
  const key = (): number[] => {
    if (format === 'ACF_Float96NoW') {
      if (rotation) {
        const q = withW(f32(o), f32(o + 4), f32(o + 8))
        o += 12
        return q
      }
      if (!(flags & 7)) {
        const p = [f32(o), f32(o + 4), f32(o + 8)]
        o += 12
        return p
      }
      return [0, 1, 2].map((k) => {
        if (!has(k)) return 0
        o += 4
        return f32(o - 4)
      })
    }
    if (format === 'ACF_Fixed48NoW') {
      const c = [0, 1, 2].map((k) => {
        if (!has(k)) return 0
        o += 2
        const x = v.getUint16(o - 2, true)
        return rotation ? (x - 32767) / 32767 : x - 255
      })
      return rotation ? withW(c[0]!, c[1]!, c[2]!) : c
    }
    if (format === 'ACF_Fixed32NoW' || format === 'ACF_IntervalFixed32NoW') {
      const q = fixed32(v.getUint32(o, true))
      o += 4
      const c = format === 'ACF_Fixed32NoW' ? q : ([0, 1, 2].map((k) => q[k]! * ranges[k]! + mins[k]!) as Vec3)
      return rotation ? withW(...c) : c
    }
    if (format === 'ACF_Identity') return rotation ? [0, 0, 0, 1] : [0, 0, 0]
    throw new Error(`per-track format ${format} not read`)
  }
  const values = Array.from({ length: n }, key)
  let frames: number[] | undefined
  if (values.length > 1 && flags & 8) {
    o = (o + 3) & ~3
    const wide = seqFrames > 0xff
    frames = values.map((_, i) => (wide ? v.getUint16(o + 2 * i, true) : v.getUint8(o + i)))
  }
  return { values, frames }
}

/** A track's value at a frame (keys spread evenly over the frames unless the track says where). */
export function sampleKeys<T extends number[]>(k: Keys<T>, frame: number, frames: number, lerp: (a: T, b: T, t: number) => T): T {
  const n = k.values.length
  if (n === 1) return k.values[0]!
  const at = k.frames ?? k.values.map((_, i) => (i * Math.max(0, frames - 1)) / (n - 1))
  if (frame <= at[0]!) return k.values[0]!
  for (let i = 1; i < n; i++)
    if (frame <= at[i]!) {
      const t = (frame - at[i - 1]!) / Math.max(1e-6, at[i]! - at[i - 1]!)
      return lerp(k.values[i - 1]!, k.values[i]!, t)
    }
  return k.values[n - 1]!
}
export const lerp3 = (a: Vec3, b: Vec3, t: number): Vec3 => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t]
export const nlerp = (a: Quat, b: Quat, t: number): Quat => {
  const s = a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3] < 0 ? -1 : 1
  const q = [0, 1, 2, 3].map((k) => a[k]! + (s * b[k]! - a[k]!) * t) as Quat
  const l = Math.hypot(...q) || 1
  return q.map((x) => x / l) as Quat
}

// --- The mirror (UE3's AnimNodeMirror): in component space, each bone takes its mirror source's transform, reflected on the
// mesh's mirror axis (the axis's column negated) and its flip axis turned back (that row negated); then local again. -----

/** A row-vector 4x4 matrix, as UE3's FMatrix (rows 0-2 the axes, row 3 the origin). */
type M4 = number[][]
const AXES: Record<string, number> = { AXIS_X: 0, AXIS_Y: 1, AXIS_Z: 2 }

function quatMatrix(q: Quat, t: Vec3): M4 {
  const [x, y, z, w] = q
  const x2 = x + x, y2 = y + y, z2 = z + z
  const xx = x * x2, xy = x * y2, xz = x * z2, yy = y * y2, yz = y * z2, zz = z * z2
  const wx = w * x2, wy = w * y2, wz = w * z2
  return [
    [1 - (yy + zz), xy + wz, xz - wy, 0],
    [xy - wz, 1 - (xx + zz), yz + wx, 0],
    [xz + wy, yz - wx, 1 - (xx + yy), 0],
    [t[0], t[1], t[2], 1],
  ]
}
function mul(a: M4, b: M4): M4 {
  return a.map((row) => [0, 1, 2, 3].map((j) => row[0]! * b[0]![j]! + row[1]! * b[1]![j]! + row[2]! * b[2]![j]! + row[3]! * b[3]![j]!))
}
/** The inverse of a rigid transform (rotation rows orthonormal, possibly with a reflection's sign). */
function inverseRigid(m: M4): M4 {
  // The 3x3 part's inverse is its transpose (orthonormal); the origin is moved back through it.
  const r = [0, 1, 2].map((i) => [0, 1, 2].map((j) => m[j]![i]!))
  const t = [0, 1, 2].map((j) => -(m[3]![0]! * r[0]![j]! + m[3]![1]! * r[1]![j]! + m[3]![2]! * r[2]![j]!))
  return [[...r[0]!, 0], [...r[1]!, 0], [...r[2]!, 0], [t[0]!, t[1]!, t[2]!, 1]]
}
/** A rotation's quaternion and the origin (UE3's FQuat(FMatrix)), w kept positive. */
function matrixQuat(m: M4): { q: Quat; t: Vec3 } {
  // Rows normalized (the mirror keeps them unit, but rounding drifts).
  const r = [0, 1, 2].map((i) => {
    const l = Math.hypot(m[i]![0]!, m[i]![1]!, m[i]![2]!) || 1
    return [m[i]![0]! / l, m[i]![1]! / l, m[i]![2]! / l]
  })
  const tr = r[0]![0]! + r[1]![1]! + r[2]![2]!
  let q: Quat
  if (tr > 0) {
    const inv = 1 / Math.sqrt(tr + 1)
    const s = 0.5 * inv
    q = [(r[1]![2]! - r[2]![1]!) * s, (r[2]![0]! - r[0]![2]!) * s, (r[0]![1]! - r[1]![0]!) * s, 0.5 / inv]
  } else {
    let i = 0
    if (r[1]![1]! > r[0]![0]!) i = 1
    if (r[2]![2]! > r[i]![i]!) i = 2
    const j = (i + 1) % 3, k = (j + 1) % 3
    let s = r[i]![i]! - r[j]![j]! - r[k]![k]! + 1
    const inv = 1 / Math.sqrt(s)
    const qq = [0, 0, 0, 0]
    qq[i] = 0.5 / inv
    s = 0.5 * inv
    qq[3] = (r[j]![k]! - r[k]![j]!) * s
    qq[j] = (r[i]![j]! + r[j]![i]!) * s
    qq[k] = (r[i]![k]! + r[k]![i]!) * s
    q = qq as Quat
  }
  const l = Math.hypot(...q) || 1
  q = q.map((x) => x / l) as Quat
  if (q[3] < 0) q = q.map((x) => -x) as Quat
  return { q, t: [m[3]![0]!, m[3]![1]!, m[3]![2]!] }
}

export interface Skeleton {
  /** Per mesh bone: its name, parent (-1 for the root), reference rotation and position. */
  bones: { name: string; parent: number; rotation: Quat; position: Vec3 }[]
  /** Per mesh bone: the bone it takes its pose from, and the axis turned back (an AXIS_ name, '' for the mesh's). */
  mirror: { source: number; flip: string }[]
  mirrorAxis: string
  flipAxis: string
}

/**
 * A sequence mirrored: each frame's pose (the tracks sampled, the reference pose where a track has nothing), mirrored, as
 * a key a frame per track. Tracks are in the AnimSet's order (trackBones: each track's mesh bone).
 */
export function mirrorSequence(seq: Sequence, skeleton: Skeleton, trackBones: number[]): { rotations: Quat[][]; positions: Vec3[][] } {
  const n = skeleton.bones.length
  const frames = Math.max(1, seq.frames)
  const trackOf = new Array<number>(n).fill(-1)
  trackBones.forEach((b, j) => { if (b >= 0) trackOf[b] = j })
  const rotations: Quat[][] = trackBones.map(() => [])
  const positions: Vec3[][] = trackBones.map(() => [])
  const mAxis = AXES[skeleton.mirrorAxis] ?? 0
  for (let f = 0; f < frames; f++) {
    // The pose, local, then in component space.
    const world: M4[] = []
    for (let b = 0; b < n; b++) {
      const bone = skeleton.bones[b]!
      const t = trackOf[b]! >= 0 ? seq.tracks[trackOf[b]!] : undefined
      const q = t?.rotation ? sampleKeys(t.rotation, f, frames, nlerp) : bone.rotation
      const p = t?.position ? sampleKeys(t.position, f, frames, lerp3) : bone.position
      const local = quatMatrix(q, p)
      world.push(bone.parent >= 0 ? mul(local, world[bone.parent]!) : local)
    }
    // Mirrored.
    const mirrored: M4[] = []
    for (let b = 0; b < n; b++) {
      const m = world[skeleton.mirror[b]?.source ?? b]!.map((row) => [...row])
      for (let r = 0; r < 4; r++) m[r]![mAxis] = -m[r]![mAxis]!
      const flip = AXES[skeleton.mirror[b]?.flip || skeleton.flipAxis] ?? 2
      for (let c = 0; c < 3; c++) m[flip]![c] = -m[flip]![c]!
      mirrored.push(m)
    }
    // Local again, per track.
    trackBones.forEach((b, j) => {
      if (b < 0) {
        rotations[j]!.push([0, 0, 0, 1])
        positions[j]!.push([0, 0, 0])
        return
      }
      const parent = skeleton.bones[b]!.parent
      const local = parent >= 0 ? mul(mirrored[b]!, inverseRigid(mirrored[parent]!)) : mirrored[b]!
      const { q, t } = matrixQuat(local)
      rotations[j]!.push(q)
      positions[j]!.push(t)
    })
  }
  return { rotations, positions }
}

/**
 * A sequence as it is, a key a frame per track (the tracks sampled, the reference pose where a track has nothing), for
 * writing it again per track (encodePerTrack): the form the converter's mirrored copies take, which XCOM 2 plays in full.
 */
export function sampleSequence(seq: Sequence, skeleton: Skeleton, trackBones: number[]): { rotations: Quat[][]; positions: Vec3[][] } {
  const frames = Math.max(1, seq.frames)
  const rotations: Quat[][] = trackBones.map(() => [])
  const positions: Vec3[][] = trackBones.map(() => [])
  for (let f = 0; f < frames; f++)
    trackBones.forEach((b, j) => {
      const t = seq.tracks[j]
      const bone = b >= 0 ? skeleton.bones[b] : undefined
      rotations[j]!.push(t?.rotation ? sampleKeys(t.rotation, f, frames, nlerp) : bone?.rotation ?? [0, 0, 0, 1])
      positions[j]!.push(t?.position ? sampleKeys(t.position, f, frames, lerp3) : bone?.position ?? [0, 0, 0])
    })
  return { rotations, positions }
}

/** Per-track compressed bytes for a key a frame (three floats each, w rebuilt) and the offsets: two per track. */
export function encodePerTrack(rotations: Quat[][], positions: Vec3[][]): { stream: Uint8Array; offsets: number[] } {
  const parts: number[] = []
  const offsets: number[] = []
  const words: { kind: 'u32' | 'f32'; v: number }[] = []
  const header = (format: number, flags: number, keys: number) => ((format << 28) | (flags << 24) | keys) >>> 0
  const at = () => words.length * 4
  for (let j = 0; j < rotations.length; j++) {
    offsets.push(at())
    words.push({ kind: 'u32', v: header(1, 7, positions[j]!.length) })
    for (const p of positions[j]!) for (const x of p) words.push({ kind: 'f32', v: x })
    offsets.push(at())
    words.push({ kind: 'u32', v: header(1, 7, rotations[j]!.length) })
    for (const q of rotations[j]!) for (const x of q.slice(0, 3)) words.push({ kind: 'f32', v: x })
  }
  void parts
  const stream = new Uint8Array(words.length * 4)
  const v = new DataView(stream.buffer)
  words.forEach((w, i) => (w.kind === 'u32' ? v.setUint32(4 * i, w.v, true) : v.setFloat32(4 * i, w.v, true)))
  return { stream, offsets }
}

/** The unit's skeleton and mirror table, from its SkeletalMesh (reference pose by the Tree's reader). */
export function readSkeleton(pkg: Package, meshIndex: number, readBones: (pkg: Package, index: number) => { name: string; parent: number; rotation: Quat; position: Vec3 }[]): Skeleton {
  const e = pkg.exports[meshIndex]!
  const d = pkg.bytes.subarray(e.offset, e.offset + e.size)
  const v = new DataView(d.buffer, d.byteOffset, d.byteLength)
  const { props } = readProps(pkg, d)
  const name = (at: number) => pkg.names[v.getInt32(at, true)] ?? ''
  const mirror: { source: number; flip: string }[] = []
  const table = props.find((p) => p.name === 'SkelMirrorTable')
  if (table) {
    const count = v.getInt32(table.at, true)
    let o = table.at + 4
    for (let k = 0; k < count; k++) {
      let source = k
      let flip = ''
      // Each element: tagged properties to None (SourceIndex, BoneFlipAxis).
      for (;;) {
        const p = name(o)
        o += 8
        if (p === 'None') break
        const type = name(o)
        o += 8
        const size = v.getInt32(o, true)
        o += 8
        if (type === 'ByteProperty') {
          o += 8 // the enum's name
          if (p === 'BoneFlipAxis') flip = size === 8 ? name(o) : ''
        } else if (type === 'BoolProperty') {
          o += 1
          continue
        } else if (type === 'StructProperty') o += 8
        if (p === 'SourceIndex') source = v.getInt32(o, true)
        o += size
      }
      mirror.push({ source, flip: flip === 'AXIS_None' ? '' : flip })
    }
  }
  const axis = (n: string, d0: string) => {
    const p = props.find((x) => x.name === n)
    return p ? name(p.at + p.size - 8) : d0
  }
  return { bones: readBones(pkg, meshIndex), mirror, mirrorAxis: axis('SkelMirrorAxis', 'AXIS_X'), flipAxis: axis('SkelMirrorFlipAxis', 'AXIS_Z') }
}

/** A skeletal mesh's reference skeleton: after its properties, its bounds, materials, origin and rotation, then the bones
 *  (name, flags, rotation, position, child count, parent, colour). The root is its own parent in UE3: -1 here. */
export function readBones(pkg: Package, meshIndex: number): Skeleton['bones'] {
  const e = pkg.exports[meshIndex]!
  const d = pkg.bytes.subarray(e.offset, e.offset + e.size)
  const v = new DataView(d.buffer, d.byteOffset, d.byteLength)
  let o = readProps(pkg, d).end + 28
  o += 4 + 4 * v.getInt32(o, true)
  o += 24
  const n = v.getInt32(o, true)
  o += 4
  const bones: Skeleton['bones'] = []
  for (let i = 0; i < n; i++) {
    const name = pkg.names[v.getInt32(o, true)] ?? ''
    o += 12
    const rotation: Quat = [v.getFloat32(o, true), v.getFloat32(o + 4, true), v.getFloat32(o + 8, true), v.getFloat32(o + 12, true)]
    const position: Vec3 = [v.getFloat32(o + 16, true), v.getFloat32(o + 20, true), v.getFloat32(o + 24, true)]
    o += 28 + 4
    const parent = v.getInt32(o, true)
    o += 8
    bones.push({ name, parent: i === 0 || parent === i ? -1 : parent, rotation, position })
  }
  return bones
}
