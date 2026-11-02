import { readFileSync } from 'node:fs'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { openPackage } from '@innonova/upkit/package'
import { Reader } from '@innonova/upkit/bytes'
import { readTags } from '@innonova/upkit/objects'
const bytes = decompressPackage(new Uint8Array(readFileSync(process.argv[2]!)))
const meta: any = new Package(bytes); const pkg: any = openPackage(bytes)
const want = process.argv[3]!
const tagsOf = (i: number) => { const d = pkg.data(i + 1); for (let s = 0; s < 40; s++) { try { const t = readTags(new Reader(d.subarray(s)), pkg); if (t.length) return t } catch {} } return [] }
const label = new Map<number, string>()
const idx: number[] = []
meta.exports.forEach((e: any, i: number) => { if (e.fullName === want || e.fullName.startsWith(want + '.')) idx.push(i) })
for (const i of idx) {
  const e = meta.exports[i]; let l = e.type.replace('MaterialExpression', '') + '#' + (i + 1)
  for (const t of tagsOf(i)) if (t.name === 'ParameterName') l += ':' + meta.names[new DataView(t.value.buffer, t.value.byteOffset).getInt32(0, true)]
  label.set(i + 1, l)
}
// Each expression's (or the material's) inputs: struct tags whose first int is an expression of this material.
for (const i of idx) {
  const ins: string[] = []
  for (const t of tagsOf(i)) {
    if (t.type !== 'StructProperty' || t.value.byteLength < 4) continue
    const dv = new DataView(t.value.buffer, t.value.byteOffset, t.value.byteLength)
    // ExpressionInput: Expression (object), OutputIndex?, InputName, Mask, MaskR,G,B,A ... as tagged struct or native; find refs.
    for (let o = 0; o + 4 <= t.value.byteLength; o += 4) { const r = dv.getInt32(o, true); if (label.has(r) && r !== i + 1) { ins.push(`${t.name}<-${label.get(r)} [${Buffer.from(t.value.subarray(o + 4, Math.min(t.value.byteLength, o + 40))).toString('hex')}]`); break } }
  }
  if (ins.length) console.log(label.get(i + 1) ?? meta.exports[i].fullName, '\n   ', ins.join('\n    '))
}
