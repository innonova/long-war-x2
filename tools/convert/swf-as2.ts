// A reader for the Scaleform movies in a UE3 package (EW's and XCOM 2's SwfMovie objects: Flash 8/9 with ActionScript 2),
// for finding out what an EW screen needs in XCOM 2: each movie's imports and exports, the classes its init actions
// define (AS2 classes are global: the first definition of a name wins), and its ActionScript as a readable listing.
//   node tools/convert/swf-as2.ts <package .upk> labels <movie> [filter]    each sprite's frame labels (gotoAndStop's names)
// A development aid; what it prints is the games' own code and stays out of the repository (read it in the terminal).
//   node tools/convert/swf-as2.ts <package .upk> list                       the movies, their imports, exports, classes
//   node tools/convert/swf-as2.ts <package .upk> classes [movie]            the classes each movie defines
//   node tools/convert/swf-as2.ts <package .upk> code <movie> [filter]      its ActionScript (blocks naming filter)
import { readFileSync } from 'node:fs'
import { inflateSync } from 'node:zlib'
import { Package, decompressPackage } from '@innonova/upkit/upk'

/** A movie's SWF bytes (uncompressed, from its signature) out of a SwfMovie export's body. */
export function swfOf(body: Uint8Array): Uint8Array | null {
  for (let i = 0; i + 8 < body.length; i++) {
    const s = String.fromCharCode(body[i]!, body[i + 1]!, body[i + 2]!)
    if (!['GFX', 'CFX', 'FWS', 'CWS'].includes(s)) continue
    const version = body[i + 3]!
    const len = body[i + 4]! | (body[i + 5]! << 8) | (body[i + 6]! << 16) | (body[i + 7]! << 24)
    if (version < 6 || version > 12 || len < 20 || len > 64 * 1024 * 1024) continue
    if (s[0] === 'C') {
      const rest = inflateSync(Buffer.from(body.subarray(i + 8)))
      const out = new Uint8Array(8 + rest.length)
      out.set(body.subarray(i, i + 8))
      out.set(rest, 8)
      return out
    }
    return body.subarray(i, i + len)
  }
  return null
}

export interface Tag { code: number; body: Uint8Array; sprite?: number }

class R {
  o = 0
  b: Uint8Array
  constructor(b: Uint8Array) { this.b = b }
  u8() { return this.b[this.o++]! }
  u16() { const v = this.b[this.o]! | (this.b[this.o + 1]! << 8); this.o += 2; return v }
  s16() { const v = this.u16(); return v >= 0x8000 ? v - 0x10000 : v }
  u32() { const v = new DataView(this.b.buffer, this.b.byteOffset + this.o, 4).getUint32(0, true); this.o += 4; return v }
  f32() { const v = new DataView(this.b.buffer, this.b.byteOffset + this.o, 4).getFloat32(0, true); this.o += 4; return v }
  f64() {
    // SWF's doubles: the two 32-bit halves swapped.
    const t = new Uint8Array(8)
    t.set(this.b.subarray(this.o + 4, this.o + 8), 0)
    t.set(this.b.subarray(this.o, this.o + 4), 4)
    this.o += 8
    return new DataView(t.buffer).getFloat64(0, true)
  }
  str() { let e = this.o; while (e < this.b.length && this.b[e] !== 0) e++; const s = Buffer.from(this.b.subarray(this.o, e)).toString('latin1'); this.o = e + 1; return s }
}

/** The tags of a SWF (sprites' inner tags included, marked with their sprite). */
export function tagsOf(swf: Uint8Array): Tag[] {
  const r = new R(swf)
  r.o = 8
  const nbits = swf[r.o]! >> 3
  r.o += Math.ceil((5 + 4 * nbits) / 8) + 4
  const out: Tag[] = []
  const walk = (end: number, sprite?: number) => {
    while (r.o + 2 <= end) {
      const h = r.u16()
      const code = h >> 6
      let len = h & 0x3f
      if (len === 0x3f) len = r.u32()
      const body = swf.subarray(r.o, r.o + len)
      const next = r.o + len
      if (code === 0) { r.o = next; if (sprite !== undefined) return; continue }
      if (code === 39) {
        const id = body[0]! | (body[1]! << 8)
        out.push({ code, body, sprite })
        r.o += 4
        walk(next, id)
      } else out.push({ code, body, sprite })
      r.o = next
    }
  }
  walk(swf.length)
  return out
}

/** ImportAssets (57, 71): url and names; ExportAssets (56): names. */
export function importsExports(tags: Tag[]) {
  const imports: { url: string; names: string[] }[] = []
  const exports: string[] = []
  for (const t of tags) {
    const r = new R(t.body)
    if (t.code === 57 || t.code === 71) {
      const url = r.str()
      if (t.code === 71) r.o += 2
      const n = r.u16()
      const names: string[] = []
      for (let i = 0; i < n; i++) { r.u16(); names.push(r.str()) }
      imports.push({ url, names })
    } else if (t.code === 56) {
      const n = r.u16()
      for (let i = 0; i < n; i++) { r.u16(); exports.push(r.str()) }
    }
  }
  return { imports, exports }
}

const OPS: Record<number, string> = {
  0x04: 'NextFrame', 0x05: 'PrevFrame', 0x06: 'Play', 0x07: 'Stop', 0x08: 'ToggleQuality', 0x09: 'StopSounds',
  0x0a: 'Add', 0x0b: 'Subtract', 0x0c: 'Multiply', 0x0d: 'Divide', 0x0e: 'Equals', 0x0f: 'Less', 0x10: 'And', 0x11: 'Or',
  0x12: 'Not', 0x13: 'StringEquals', 0x14: 'StringLength', 0x15: 'StringExtract', 0x17: 'Pop', 0x18: 'ToInteger',
  0x1c: 'GetVariable', 0x1d: 'SetVariable', 0x20: 'SetTarget2', 0x21: 'StringAdd', 0x22: 'GetProperty', 0x23: 'SetProperty',
  0x24: 'CloneSprite', 0x25: 'RemoveSprite', 0x26: 'Trace', 0x27: 'StartDrag', 0x28: 'EndDrag', 0x29: 'StringLess',
  0x2a: 'Throw', 0x2b: 'CastOp', 0x2c: 'ImplementsOp', 0x30: 'RandomNumber', 0x34: 'GetTime', 0x3a: 'Delete', 0x3b: 'Delete2',
  0x3c: 'DefineLocal', 0x3d: 'CallFunction', 0x3e: 'Return', 0x3f: 'Modulo', 0x40: 'NewObject', 0x41: 'DefineLocal2',
  0x42: 'InitArray', 0x43: 'InitObject', 0x44: 'TypeOf', 0x45: 'TargetPath', 0x46: 'Enumerate', 0x47: 'Add2', 0x48: 'Less2',
  0x49: 'Equals2', 0x4a: 'ToNumber', 0x4b: 'ToString', 0x4c: 'PushDuplicate', 0x4d: 'StackSwap', 0x4e: 'GetMember',
  0x4f: 'SetMember', 0x50: 'Increment', 0x51: 'Decrement', 0x52: 'CallMethod', 0x53: 'NewMethod', 0x54: 'InstanceOf',
  0x55: 'Enumerate2', 0x60: 'BitAnd', 0x61: 'BitOr', 0x62: 'BitXor', 0x63: 'BitLShift', 0x64: 'BitRShift', 0x65: 'BitURShift',
  0x66: 'StrictEquals', 0x67: 'Greater', 0x68: 'StringGreater', 0x69: 'Extends',
  0x81: 'GotoFrame', 0x83: 'GetURL', 0x87: 'StoreRegister', 0x88: 'ConstantPool', 0x8a: 'WaitForFrame', 0x8b: 'SetTarget',
  0x8c: 'GotoLabel', 0x8d: 'WaitForFrame2', 0x8e: 'DefineFunction2', 0x8f: 'Try', 0x94: 'With', 0x96: 'Push', 0x99: 'Jump',
  0x9a: 'GetURL2', 0x9b: 'DefineFunction', 0x9d: 'If', 0x9e: 'Call', 0x9f: 'GotoFrame2',
}

/** An action block as lines: offset, op and its arguments (pushed constants resolved). */
export function disassemble(code: Uint8Array, pool: string[] = [], indent = ''): string[] {
  const r = new R(code)
  const lines: string[] = []
  while (r.o < code.length) {
    const at = r.o
    const op = r.u8()
    if (op === 0) { lines.push(`${indent}${at}: End`); break }
    let len = 0
    if (op >= 0x80) len = r.u16()
    const end = r.o + len
    const name = OPS[op] ?? `op${op.toString(16)}`
    let args = ''
    if (op === 0x88) {
      const n = r.u16()
      pool = []
      for (let i = 0; i < n; i++) pool.push(r.str())
      args = `(${n} strings)`
    } else if (op === 0x96) {
      const items: string[] = []
      while (r.o < end) {
        const t = r.u8()
        if (t === 0) items.push(JSON.stringify(r.str()))
        else if (t === 1) items.push(String(r.f32()))
        else if (t === 2) items.push('null')
        else if (t === 3) items.push('undefined')
        else if (t === 4) items.push(`r${r.u8()}`)
        else if (t === 5) items.push(r.u8() ? 'true' : 'false')
        else if (t === 6) items.push(String(r.f64()))
        else if (t === 7) items.push(String(r.u32() | 0))
        else if (t === 8) items.push(JSON.stringify(pool[r.u8()] ?? '?'))
        else if (t === 9) items.push(JSON.stringify(pool[r.u16()] ?? '?'))
        else { items.push(`?type${t}`); break }
      }
      args = items.join(', ')
    } else if (op === 0x99 || op === 0x9d) {
      const off = r.s16()
      args = `→ ${end + off}`
    } else if (op === 0x87) args = `r${r.u8()}`
    else if (op === 0x8c || op === 0x8b) args = JSON.stringify(r.str())
    else if (op === 0x8e || op === 0x9b) {
      const fname = r.str()
      const n = r.u16()
      const params: string[] = []
      let regs = 0
      if (op === 0x8e) {
        regs = r.u8()
        r.u16()
        for (let i = 0; i < n; i++) { const reg = r.u8(); params.push(`${r.str()}${reg ? '=r' + reg : ''}`) }
      } else for (let i = 0; i < n; i++) params.push(r.str())
      const size = r.u16()
      lines.push(`${indent}${at}: function ${fname || '(anonymous)'}(${params.join(', ')})${op === 0x8e ? ` regs ${regs}` : ''} {`)
      lines.push(...disassemble(code.subarray(r.o, r.o + size), pool, indent + '  ').filter((l) => !l.endsWith(': End')))
      lines.push(`${indent}}`)
      r.o += size
      continue
    }
    lines.push(`${indent}${at}: ${name}${args ? ' ' + args : ''}`)
    r.o = end
  }
  return lines
}

/** The action blocks of a movie's tags: DoAction (12) and DoInitAction (59, after its sprite id). */
export function actionBlocks(tags: Tag[]) {
  const out: { kind: string; sprite?: number; code: Uint8Array }[] = []
  for (const t of tags) {
    if (t.code === 12) out.push({ kind: 'DoAction', sprite: t.sprite, code: t.body })
    else if (t.code === 59) out.push({ kind: 'DoInitAction', sprite: t.body[0]! | (t.body[1]! << 8), code: t.body.subarray(2) })
  }
  return out
}

/** The classes an init action block defines: the names it sets on _global (and its packages). */
export function classesOf(code: Uint8Array): string[] {
  const lines = disassemble(code)
  const out = new Set<string>()
  // AS2's compiled classes: `_global.<pkg>.<Name> = function…` after `if (!_global.<Name>)`: the names pushed just before
  // a SetMember whose object chain starts at _global.
  for (let i = 0; i < lines.length; i++) {
    if (!/: SetMember$/.test(lines[i]!)) continue
    const back = lines.slice(Math.max(0, i - 12), i).join(' ')
    if (!back.includes('"_global"')) continue
    const m = [...back.matchAll(/Push "([A-Za-z_][\w]*)"/g)].map((x) => x[1]!)
    const name = m.filter((n) => n !== '_global' && n !== 'prototype').pop()
    if (name && /^[A-Z]/.test(name)) out.add(name)
  }
  return [...out]
}

export function movies(path: string) {
  const bytes = decompressPackage(new Uint8Array(readFileSync(path)))
  const pkg = new Package(bytes)
  const out: { name: string; swf: Uint8Array }[] = []
  for (const e of pkg.exports as { type: string; offset: number; size: number; name?: string; objectName?: string }[]) {
    if (e.type !== 'SwfMovie') continue
    const swf = swfOf(bytes.subarray(e.offset, e.offset + e.size))
    if (swf) out.push({ name: String((e as { fullName?: string }).fullName ?? e.name), swf })
  }
  return out
}

if (/swf-as2\.ts$/.test(process.argv[1] ?? '')) {
  const [path, what = 'list', movie, filter] = process.argv.slice(2).filter((a) => a !== '--')
  if (!path) {
    console.error('usage: swf-as2.ts <package .upk> list | classes [movie] | code <movie> [filter] | labels <movie> [filter]')
    process.exit(2)
  }
  for (const m of movies(path)) {
    if (movie && !m.name.toLowerCase().includes(movie.toLowerCase())) continue
    const tags = tagsOf(m.swf)
    if (what === 'list' || what === 'classes') {
      const { imports, exports } = importsExports(tags)
      const classes = actionBlocks(tags).filter((b) => b.kind === 'DoInitAction').flatMap((b) => classesOf(b.code))
      console.log(`${m.name}: ${m.swf.length} bytes`)
      if (what === 'list') {
        for (const i of imports) console.log(`  import ${i.url}: ${i.names.join(', ')}`)
        if (exports.length) console.log(`  export ${exports.join(', ')}`)
      }
      if (classes.length) console.log(`  classes ${classes.join(', ')}`)
    } else if (what === 'labels') {
      // FrameLabel (43) tags, by the sprite (DefineSprite 39) they are in; frames counted by ShowFrame (1).
      const bySprite = new Map<number | undefined, string[]>()
      const frame = new Map<number | undefined, number>()
      for (const t of tags) {
        if (t.code === 1) frame.set(t.sprite, (frame.get(t.sprite) ?? 0) + 1)
        if (t.code !== 43) continue
        const label = new R(t.body).str()
        bySprite.set(t.sprite, [...(bySprite.get(t.sprite) ?? []), `${(frame.get(t.sprite) ?? 0) + 1}:${label}`])
      }
      console.log(`== ${m.name}`)
      for (const [sprite, labels] of bySprite) {
        if (filter && !labels.some((l) => l.toLowerCase().includes(filter.toLowerCase()))) continue
        console.log(`sprite ${sprite ?? 'root'} (${labels.length}): ${labels.join(' ')}`)
      }
    } else if (what === 'code') {
      console.log(`== ${m.name}`)
      for (const b of actionBlocks(tags)) {
        const lines = disassemble(b.code)
        if (filter && !lines.some((l) => l.includes(filter))) continue
        console.log(`-- ${b.kind}${b.sprite !== undefined ? ' sprite ' + b.sprite : ''}`)
        console.log(lines.join('\n'))
      }
    }
  }
}
