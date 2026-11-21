// EW's compiled material shaders, read from the player's own install (a development aid: prints, writes nothing).
//
// EW's cooked materials keep only their parameters; the graph that combines them is compiled away. The compiled shaders
// are in the install's RefShaderCache-PC-D3D-SM3.upk: per material a shader map (its shaders by type and id, its name,
// its uniform expressions, which say which parameter feeds which UniformPixelVector), and each shader's Direct3D 9 code.
// This finds a material's map, names its uniform vectors and disassembles one of its pixel shaders (shader model 3), so
// what EW does with a parameter can be read rather than guessed (features/ew-compare.md: HQ_Master's palette and 8×1
// tiling, read this way).
//
//   node tools/convert/ew-shaders.ts <CookedPCConsole> <material name> [shader type part]
//
// The shader type part picks which of the map's pixel shaders (default: the static-mesh base pass with a directional
// lightmap). Nothing of the game is kept: the package is read in memory and the disassembly printed.
import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'

const OPS: Record<number, string> = {
  0: 'nop', 1: 'mov', 2: 'add', 3: 'sub', 4: 'mad', 5: 'mul', 6: 'rcp', 7: 'rsq', 8: 'dp3', 9: 'dp4', 10: 'min', 11: 'max',
  12: 'slt', 13: 'sge', 14: 'exp', 15: 'log', 16: 'lit', 17: 'dst', 18: 'lrp', 19: 'frc', 20: 'm4x4', 21: 'm4x3', 22: 'm3x4',
  23: 'm3x3', 24: 'm3x2', 25: 'call', 26: 'callnz', 27: 'loop', 28: 'ret', 29: 'endloop', 30: 'label', 31: 'dcl', 32: 'pow',
  33: 'crs', 34: 'sgn', 35: 'abs', 36: 'nrm', 37: 'sincos', 38: 'rep', 39: 'endrep', 40: 'if', 41: 'ifc', 42: 'else',
  43: 'endif', 44: 'break', 45: 'breakc', 46: 'mova', 47: 'defb', 48: 'defi', 64: 'texcoord', 65: 'texkill', 66: 'texld',
  78: 'expp', 79: 'logp', 80: 'cnd', 81: 'def', 88: 'cmp', 90: 'dp2add', 91: 'dsx', 92: 'dsy', 93: 'texldd', 94: 'setp',
  95: 'texldl', 96: 'breakp',
}
const REG: Record<number, string> = { 0: 'r', 1: 'v', 2: 'c', 3: 't', 4: 'oPos', 5: 'oD', 6: 'oT', 7: 'i', 8: 'oC', 9: 'oDepth', 10: 's', 14: 'b', 15: 'aL', 19: 'p' }
const USAGE: Record<number, string> = { 0: 'position', 3: 'normal', 5: 'texcoord', 6: 'tangent', 7: 'binormal', 10: 'color', 11: 'fog', 12: 'depth' }
const MODS: Record<number, (r: string) => string> = { 0: (r) => r, 1: (r) => `-${r}`, 6: (r) => `1-${r}`, 7: (r) => `${r}_x2`, 11: (r) => `abs(${r})`, 12: (r) => `-abs(${r})`, 13: (r) => `!${r}` }

const rtype = (t: number) => ((t >>> 28) & 7) | (((t >>> 11) & 3) << 3)
const reg = (t: number) => (rtype(t) === 17 ? (['vPos', 'vFace'][t & 0x7ff] ?? `misc${t & 0x7ff}`) : `${REG[rtype(t)] ?? `?${rtype(t)}`}${t & 0x7ff}`)
function dst(t: number): string {
  const m = (t >>> 16) & 15
  return ((t >>> 20) & 1 ? '_sat ' : ' ') + reg(t) + (m === 15 ? '' : '.' + [0, 1, 2, 3].filter((i) => m & (1 << i)).map((i) => 'xyzw'[i]).join(''))
}
function src(t: number): string {
  const sw = (t >>> 16) & 255
  let s = [0, 1, 2, 3].map((i) => 'xyzw'[(sw >>> (2 * i)) & 3]).join('')
  s = s === 'xyzw' ? '' : new Set(s).size === 1 ? s[0]! : s
  const r = reg(t) + (s ? `.${s}` : '') + (t & (1 << 13) ? '[a0]' : '')
  return (MODS[(t >>> 24) & 15] ?? ((x: string) => `${x}_m${(t >>> 24) & 15}`))(r)
}

/** A shader's constant table (its CTAB comment): each constant's name, register and count. */
function ctab(words: Uint32Array): string[] {
  const b = new Uint8Array(words.buffer, words.byteOffset, words.byteLength)
  if (String.fromCharCode(...b.subarray(0, 4)) !== 'CTAB') return []
  const d = new DataView(b.buffer, b.byteOffset + 4, b.byteLength - 4)
  const n = d.getUint32(12, true), info = d.getUint32(16, true)
  const cstr = (o: number) => { let s = ''; while (d.getUint8(o)) s += String.fromCharCode(d.getUint8(o++)); return s }
  return Array.from({ length: n }, (_, k) => {
    const o = info + 20 * k
    return `// ${cstr(d.getUint32(o, true))}: ${'bics'[d.getUint16(o + 4, true)]}${d.getUint16(o + 6, true)} (${d.getUint16(o + 8, true)})`
  })
}

/** A Direct3D 9 shader (from its version token) as text. */
export function disassemble(code: Uint8Array): string[] {
  const w = new Uint32Array(code.buffer.slice(code.byteOffset, code.byteOffset + (code.byteLength & ~3)))
  const out: string[] = [`// version ${w[0]!.toString(16)}`]
  for (let i = 1; i < w.length; ) {
    const t = w[i]!
    if (t === 0x0000ffff) break
    const op = t & 0xffff
    if (op === 0xfffe) {
      const n = (t >>> 16) & 0x7fff
      out.push(...ctab(w.subarray(i + 1, i + 1 + n)))
      i += 1 + n
      continue
    }
    const ln = (t >>> 24) & 15, a = [...w.subarray(i + 1, i + 1 + ln)], name = OPS[op] ?? `op${op}`
    if (op === 31) out.push(rtype(a[1]!) === 10 ? `dcl_2d ${reg(a[1]!)}` : `dcl_${USAGE[a[0]! & 31] ?? a[0]! & 31}${(a[0]! >>> 16) & 15 || ''}${dst(a[1]!)}`)
    else if (op === 81) out.push(`def ${reg(a[0]!)}, ${[...new Float32Array(new Uint32Array(a.slice(1, 5)).buffer)].map((x) => +x.toPrecision(4)).join(', ')}`)
    else if (op === 41 || op === 45 || op === 94) out.push(`${name}_${['', 'gt', 'eq', 'ge', 'lt', 'ne', 'le'][(t >>> 16) & 7]} ${a.map(src).join(', ')}`)
    else out.push(a.length ? name + dst(a[0]!) + (a.length > 1 ? ', ' + a.slice(1).map(src).join(', ') : '') : name)
    i += 1 + ln
  }
  return out
}

if (/ew-shaders\.ts$/.test(process.argv[1] ?? '')) {
  const [cooked, material, want = 'DirectionalLightMapTexturePolicyNoSkyLight'] = process.argv.slice(2).filter((a) => a !== '--')
  if (!material) {
    console.error('usage: ew-shaders.ts <CookedPCConsole> <material name> [shader type part]')
    process.exit(2)
  }
  const d = decompressPackage(new Uint8Array(readFileSync(join(cooked!, 'RefShaderCache-PC-D3D-SM3.upk'))))
  const v = new DataView(d.buffer, d.byteOffset, d.byteLength)
  const names: string[] = (new Package(d) as any).names.map((n: any) => n.name ?? n)
  const nameAt = (p: number) => { const a = v.getInt32(p, true); return a > 0 && a < names.length && v.getInt32(p + 4, true) === 0 ? names[a]! : '' }
  const buf = Buffer.from(d.buffer, d.byteOffset, d.byteLength)
  // The material's name (an FString: its length, then the text and a zero) in its shader map.
  const needle = Buffer.from(material + '\0', 'latin1')
  let at = buf.indexOf(needle)
  while (at >= 0 && v.getInt32(at - 4, true) !== needle.length) at = buf.indexOf(needle, at + 1)
  if (at < 0) throw new Error(`no shader map named ${material}`)
  // Its shaders, listed before the name as (type, id, type) entries; the last of the wanted kind (the static mesh
  // vertex factory's list comes before the skinned one's).
  const shaders: { type: string; id: Buffer }[] = []
  for (let p = at - 20000; p < at; ) {
    const t = nameAt(p)
    if (t.startsWith('T') && nameAt(p + 24) === t) {
      shaders.push({ type: t, id: buf.subarray(p + 8, p + 24) })
      p += 32
    } else p++
  }
  const pick = shaders.filter((s) => s.type.includes(want) && s.type.includes('PixelShader')).pop()
  if (!pick) throw new Error(`no ${want} pixel shader near ${material}`)
  // Its uniform expressions, after the name and the material's id: the vector parameters in order are UniformPixelVector_n.
  const vectors: string[] = []
  for (let q = at + needle.length + 16; q < at + needle.length + 4000; q += 4) {
    const t = nameAt(q)
    if (t === 'FMaterialUniformExpressionVectorParameter') vectors.push(nameAt(q + 8))
    if (t.startsWith('TBasePass') || t.startsWith('TLight')) break
  }
  const ps = buf.indexOf(Buffer.from([0x00, 0x03, 0xff, 0xff]), buf.indexOf(pick.id))
  console.log(`// ${material}: ${pick.type}`)
  console.log(`// UniformPixelVector_n: ${vectors.map((x, k) => `${k} ${x}`).join(', ')}`)
  console.log(disassemble(d.subarray(ps, ps + v.getUint32(ps - 4, true))).join('\n'))
}
