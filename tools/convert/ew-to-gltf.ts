// An Enemy Within unit, from the player's own install, as a glTF 2.0 binary
// (.glb): its skeletal mesh (bones, the first level of detail, skin weights),
// its diffuse and normal textures, and the animations of an AnimSet. For
// experiment 1 (features/hard-parts.md): what XCOM 2's editor can take in.
//
// Uses the Long War Tech Tree's readers of Enemy Within's packages
// (innonova/xcom-ew-lw-tree, src/model/: skelmesh, anim, texture), from a
// checkout beside this one. Run from that checkout, which has the packages they
// need:
//
//   cd ../xcom-ew-lw-tree
//   npx vite-node ../long-war-x2/tools/convert/ew-to-gltf.ts -- \
//     <CookedPCConsole> GameUnit_XComFloater_SF.upk SM_MedFloater MedFloater_DIF MedFloater_NRM AS_HeavyFloaterRifle out.glb [sequence …]
//
// Unreal is left-handed with Z up, glTF right-handed with Y up: positions and
// normals go (x, y, z) → (x, z, y), rotations (x, y, z, w) → (−x, −z, −y, w).
// Lengths are divided by 100: glTF's unit is the metre and Unreal's the centimetre,
// so Blender exports FBX in Unreal's units with no scale on the skeleton (XCOM 2's
// animation importer ignores such a scale).
import { readFileSync, writeFileSync } from 'node:fs'
import { deflateSync } from 'node:zlib'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { unchunk } from '@innonova/upkit/lzo'
import { readSkelMesh, boneWorld, type SkelMesh } from '../../../xcom-ew-lw-tree/src/model/skelmesh.ts'
import { readAnimSet, readClip, sampleClip } from '../../../xcom-ew-lw-tree/src/model/anim.ts'
import { decodeImage, largestMip, readTexture } from '../../../xcom-ew-lw-tree/src/model/texture.ts'

type Quat = [number, number, number, number]
type Vec3 = [number, number, number]

const [dir, pkgName, meshName, difName, nrmName, animSetName, out, ...wanted] = process.argv.slice(2).filter((a) => a !== '--')
if (!out) {
  console.error('usage: ew-to-gltf.ts <CookedPCConsole> <package> <mesh> <diffuse> <normal> <animset> <out.glb> [sequence …]')
  process.exit(2)
}

const pkg = new Package(decompressPackage(new Uint8Array(readFileSync(`${dir}/${pkgName}`))))
const find = (type: string, name: string) => {
  const i = pkg.exports.findIndex((e) => e.type === type && e.name === name)
  if (i < 0) throw new Error(`no ${type} ${name} in ${pkgName}`)
  return i
}

const UNIT = 0.01
const v3 = (x: number, y: number, z: number): Vec3 => [x * UNIT, z * UNIT, y * UNIT]
const dir3 = (x: number, y: number, z: number): Vec3 => [x, z, y]
const q4 = (q: Quat): Quat => [-q[0], -q[2], -q[1], q[3]]

// --- The mesh -----------------------------------------------------------------------
const mesh: SkelMesh = readSkelMesh(pkg, find('SkeletalMesh', meshName))
const n = mesh.vertexCount
const positions = new Float32Array(3 * n)
const normals = new Float32Array(3 * n)
const tangents = new Float32Array(4 * n)
const uvs = new Float32Array(mesh.uvs)
const joints = new Uint16Array(4 * n)
const weights = new Float32Array(4 * n)
for (let i = 0; i < n; i++) {
  positions.set(v3(mesh.positions[3 * i]!, mesh.positions[3 * i + 1]!, mesh.positions[3 * i + 2]!), 3 * i)
  const nm = dir3(mesh.normals[3 * i]!, mesh.normals[3 * i + 1]!, mesh.normals[3 * i + 2]!)
  const len = Math.hypot(...nm) || 1
  normals.set(nm.map((c) => c / len), 3 * i)
  const t = dir3(mesh.tangents[4 * i]!, mesh.tangents[4 * i + 1]!, mesh.tangents[4 * i + 2]!)
  const tl = Math.hypot(...t) || 1
  tangents.set([...t.map((c) => c / tl), -(mesh.tangents[4 * i + 3]! < 0 ? -1 : 1)], 4 * i)
  let sum = 0
  for (let k = 0; k < 4; k++) sum += mesh.influences.weights[4 * i + k]!
  for (let k = 0; k < 4; k++) {
    const w = mesh.influences.weights[4 * i + k]!
    joints[4 * i + k] = w ? mesh.influences.bones[4 * i + k]! : 0
    weights[4 * i + k] = sum ? w / sum : k === 0 ? 1 : 0
  }
}
// One primitive per section (its own material). The triangles keep their order: the
// axis swap turns Unreal's clockwise front faces into glTF's counter-clockwise ones
// (checked: the faces then agree with the stored normals).
const sections = mesh.sections.map((s) => ({
  material: s.material,
  idx: Uint32Array.from(mesh.indices.subarray(s.firstIndex, s.firstIndex + 3 * s.triangles)),
}))

// --- The skeleton: local transforms for the nodes, the rest pose's inverse for the skin --
const world = boneWorld(mesh.bones)
function matrix(q: Quat, t: Vec3): number[] {
  const [x, y, z, w] = q
  // Column-major, as glTF has it.
  return [
    1 - 2 * (y * y + z * z), 2 * (x * y + z * w), 2 * (x * z - y * w), 0,
    2 * (x * y - z * w), 1 - 2 * (x * x + z * z), 2 * (y * z + x * w), 0,
    2 * (x * z + y * w), 2 * (y * z - x * w), 1 - 2 * (x * x + y * y), 0,
    t[0], t[1], t[2], 1,
  ]
}
function inverseRigid(m: number[]): number[] {
  // [R t; 0 1]⁻¹ = [Rᵀ −Rᵀt; 0 1]
  const r = [m[0]!, m[1]!, m[2]!, m[4]!, m[5]!, m[6]!, m[8]!, m[9]!, m[10]!]
  const t = [m[12]!, m[13]!, m[14]!]
  const rt = [r[0]!, r[3]!, r[6]!, r[1]!, r[4]!, r[7]!, r[2]!, r[5]!, r[8]!]
  const it = [
    -(rt[0]! * t[0]! + rt[3]! * t[1]! + rt[6]! * t[2]!),
    -(rt[1]! * t[0]! + rt[4]! * t[1]! + rt[7]! * t[2]!),
    -(rt[2]! * t[0]! + rt[5]! * t[1]! + rt[8]! * t[2]!),
  ]
  return [rt[0]!, rt[1]!, rt[2]!, 0, rt[3]!, rt[4]!, rt[5]!, 0, rt[6]!, rt[7]!, rt[8]!, 0, it[0]!, it[1]!, it[2]!, 1]
}
const inverseBind = new Float32Array(16 * mesh.bones.length)
world.forEach((w, i) => inverseBind.set(inverseRigid(matrix(q4(w.rotation), v3(...w.position))), 16 * i))

// --- Textures ------------------------------------------------------------------------
function texturePng(name: string): Uint8Array | undefined {
  const tex = readTexture(pkg, find('Texture2D', name))
  const mip = largestMip(tex)
  if (!mip) return undefined
  let data = mip.data
  if (!data && mip.where === 'cache') {
    const tfc = readFileSync(`${dir}/${tex.cache}.tfc`)
    const raw = new Uint8Array(tfc.buffer, tfc.byteOffset + mip.offset, mip.sizeOnDisk)
    data = mip.lzo ? unchunk(raw, mip.size) : raw
  }
  if (!data) return undefined
  try {
    return png(decodeImage(tex.format, data, mip.width, mip.height), mip.width, mip.height)
  } catch (e) {
    console.error(`${name}: ${(e as Error).message}`)
    return undefined
  }
}
function png(rgba: Uint8Array, w: number, h: number): Uint8Array {
  const crcTable = Array.from({ length: 256 }, (_, k) => {
    let c = k
    for (let j = 0; j < 8; j++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1
    return c >>> 0
  })
  const crc = (b: Uint8Array) => {
    let c = 0xffffffff
    for (const x of b) c = crcTable[(c ^ x) & 0xff]! ^ (c >>> 8)
    return (c ^ 0xffffffff) >>> 0
  }
  const chunk = (type: string, body: Uint8Array) => {
    const out = new Uint8Array(12 + body.length)
    const dv = new DataView(out.buffer)
    dv.setUint32(0, body.length)
    out.set(Buffer.from(type, 'ascii'), 4)
    out.set(body, 8)
    dv.setUint32(8 + body.length, crc(out.subarray(4, 8 + body.length)))
    return out
  }
  const ihdr = new Uint8Array(13)
  const dv = new DataView(ihdr.buffer)
  dv.setUint32(0, w)
  dv.setUint32(4, h)
  ihdr.set([8, 6, 0, 0, 0], 8)
  const rows = new Uint8Array(h * (4 * w + 1))
  for (let y = 0; y < h; y++) rows.set(rgba.subarray(4 * w * y, 4 * w * (y + 1)), y * (4 * w + 1) + 1)
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(rows)),
    chunk('IEND', new Uint8Array()),
  ])
}
const difPng = texturePng(difName)
const nrmPng = texturePng(nrmName)

// --- Animations: each sequence sampled at 30 frames a second, every bone it moves ----
const animPkgIndex = find('AnimSet', animSetName)
const set = readAnimSet(pkg, animPkgIndex)
const sequences = set.sequences.filter((s) => wanted.length === 0 || wanted.includes(s.name))

// --- The glTF ------------------------------------------------------------------------
const chunks: Uint8Array[] = []
let byteLength = 0
const bufferViews: object[] = []
const accessors: object[] = []
function view(bytes: Uint8Array, target?: number): number {
  const pad = (4 - (byteLength % 4)) % 4
  if (pad) {
    chunks.push(new Uint8Array(pad))
    byteLength += pad
  }
  bufferViews.push({ buffer: 0, byteOffset: byteLength, byteLength: bytes.byteLength, ...(target ? { target } : {}) })
  chunks.push(bytes)
  byteLength += bytes.byteLength
  return bufferViews.length - 1
}
function accessor(data: Float32Array | Uint16Array | Uint32Array, type: string, componentType: number, count: number, target?: number, minmax = false): number {
  const bv = view(new Uint8Array(data.buffer, data.byteOffset, data.byteLength), target)
  const a: Record<string, unknown> = { bufferView: bv, componentType, count, type }
  if (minmax) {
    const k = type === 'SCALAR' ? 1 : type === 'VEC3' ? 3 : 4
    const min = Array(k).fill(Infinity)
    const max = Array(k).fill(-Infinity)
    for (let i = 0; i < count; i++)
      for (let c = 0; c < k; c++) {
        min[c] = Math.min(min[c], data[k * i + c]!)
        max[c] = Math.max(max[c], data[k * i + c]!)
      }
    a.min = min
    a.max = max
  }
  accessors.push(a)
  return accessors.length - 1
}
const FLOAT = 5126, USHORT = 5123, UINT = 5125, ARRAY = 34962, ELEMENTS = 34963

const aPos = accessor(positions, 'VEC3', FLOAT, n, ARRAY, true)
const aNrm = accessor(normals, 'VEC3', FLOAT, n, ARRAY)
const aTan = accessor(tangents, 'VEC4', FLOAT, n, ARRAY)
const aUv = accessor(uvs, 'VEC2', FLOAT, n, ARRAY)
const aJoints = accessor(joints, 'VEC4', USHORT, n, ARRAY)
const aWeights = accessor(weights, 'VEC4', FLOAT, n, ARRAY)
const aIbm = accessor(inverseBind, 'MAT4', FLOAT, mesh.bones.length)

const images: object[] = []
const textures: object[] = []
const imageTexture = (bytes: Uint8Array | undefined, name: string) => {
  if (!bytes) return undefined
  images.push({ name, mimeType: 'image/png', bufferView: view(bytes) })
  textures.push({ source: images.length - 1 })
  return textures.length - 1
}
const tDif = imageTexture(difPng, difName)
const tNrm = imageTexture(nrmPng, nrmName)
const materials = [...new Set(sections.map((s) => s.material))].map((m) => ({
  name: `${meshName}_M${m}`,
  pbrMetallicRoughness: { ...(tDif !== undefined ? { baseColorTexture: { index: tDif } } : {}), metallicFactor: 0, roughnessFactor: 0.8 },
  ...(tNrm !== undefined ? { normalTexture: { index: tNrm } } : {}),
}))
const matIndex = (m: number) => [...new Set(sections.map((s) => s.material))].indexOf(m)

const primitives = sections.map((s) => ({
  attributes: { POSITION: aPos, NORMAL: aNrm, TANGENT: aTan, TEXCOORD_0: aUv, JOINTS_0: aJoints, WEIGHTS_0: aWeights },
  indices: accessor(s.idx, 'SCALAR', UINT, s.idx.length, ELEMENTS),
  material: matIndex(s.material),
}))

// Nodes: the bones (0 … n−1, local transforms), then the mesh's node.
const nodes: Record<string, unknown>[] = mesh.bones.map((b, i) => {
  const children = mesh.bones.map((c, j) => (j > 0 && c.parent === i ? j : -1)).filter((j) => j >= 0)
  return {
    name: b.name,
    rotation: q4(b.rotation),
    translation: v3(...b.position),
    ...(children.length ? { children } : {}),
  }
})
nodes.push({ name: meshName, mesh: 0, skin: 0 })
const skin = { name: meshName, joints: mesh.bones.map((_, i) => i), inverseBindMatrices: aIbm, skeleton: 0 }

const animations = sequences.map((s) => {
  const clip = readClip(pkg, set, s.index)
  const fps = 30
  const frames = Math.max(2, Math.round(clip.length * fps) + 1)
  const times = new Float32Array(frames).map((_, f) => Math.min(clip.length, f / fps))
  const samplers: object[] = []
  const channels: object[] = []
  const tIn = accessor(times, 'SCALAR', FLOAT, frames, undefined, true)
  const poses = Array.from({ length: frames }, (_, f) => sampleClip(clip, times[f]!))
  mesh.bones.forEach((b, i) => {
    if (!clip.tracks.has(b.name)) return
    const rot = new Float32Array(4 * frames)
    const pos = new Float32Array(3 * frames)
    let moves = false
    poses.forEach((p, f) => {
      const bp = p.get(b.name)!
      rot.set(q4(bp.rotation as Quat), 4 * f)
      const t = bp.position ? v3(...(bp.position as Vec3)) : v3(...b.position)
      pos.set(t, 3 * f)
      if (bp.position) moves = true
    })
    samplers.push({ input: tIn, output: accessor(rot, 'VEC4', FLOAT, frames), interpolation: 'LINEAR' })
    channels.push({ sampler: samplers.length - 1, target: { node: i, path: 'rotation' } })
    if (moves) {
      samplers.push({ input: tIn, output: accessor(pos, 'VEC3', FLOAT, frames), interpolation: 'LINEAR' })
      channels.push({ sampler: samplers.length - 1, target: { node: i, path: 'translation' } })
    }
  })
  return { name: s.name, samplers, channels }
})

const gltf = {
  asset: { version: '2.0', generator: 'long-war-x2 tools/convert/ew-to-gltf.ts' },
  scene: 0,
  scenes: [{ nodes: [0, nodes.length - 1] }],
  nodes,
  meshes: [{ name: meshName, primitives }],
  skins: [skin],
  materials,
  ...(images.length ? { images, textures, samplers: [{}] } : {}),
  animations,
  accessors,
  bufferViews,
  buffers: [{ byteLength }],
}
for (const t of textures as Record<string, unknown>[]) t.sampler = 0

const json = Buffer.from(JSON.stringify(gltf))
const jsonPadded = Buffer.concat([json, Buffer.alloc((4 - (json.length % 4)) % 4, 0x20)])
const bin = Buffer.concat(chunks.map((c) => Buffer.from(c.buffer, c.byteOffset, c.byteLength)))
const binPadded = Buffer.concat([bin, Buffer.alloc((4 - (bin.length % 4)) % 4)])
const header = Buffer.alloc(12)
header.writeUInt32LE(0x46546c67, 0)
header.writeUInt32LE(2, 4)
header.writeUInt32LE(12 + 8 + jsonPadded.length + 8 + binPadded.length, 8)
const jh = Buffer.alloc(8)
jh.writeUInt32LE(jsonPadded.length, 0)
jh.writeUInt32LE(0x4e4f534a, 4)
const bh = Buffer.alloc(8)
bh.writeUInt32LE(binPadded.length, 0)
bh.writeUInt32LE(0x004e4942, 4)
writeFileSync(out, Buffer.concat([header, jh, jsonPadded, bh, binPadded]))
console.log(`${out}: ${meshName}, ${mesh.bones.length} bones, ${n} vertices, ${sections.reduce((a, s) => a + s.idx.length / 3, 0)} triangles, textures ${[difPng && difName, nrmPng && nrmName].filter(Boolean).join(', ') || 'none'}, ${animations.length} animations (${animations.map((a) => a.name).slice(0, 6).join(', ')}${animations.length > 6 ? ', …' : ''})`)
