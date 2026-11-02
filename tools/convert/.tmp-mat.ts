import { readFileSync } from 'node:fs'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { openPackage } from '@innonova/upkit/package'
import { Reader } from '@innonova/upkit/bytes'
import { readTags } from '@innonova/upkit/objects'
const bytes = decompressPackage(new Uint8Array(readFileSync(process.argv[2]!)))
const meta: any = new Package(bytes); const pkg: any = openPackage(bytes)
const want = process.argv[3]!
const pathOf = (r: number): string => r > 0 ? meta.exports[r - 1].fullName : r < 0 ? meta.imports[-r - 1].fullName : ''
meta.exports.forEach((e: any, i: number) => {
  if (!e.fullName.startsWith(want + '.') || !/MaterialExpression(Texture|Scalar|Vector|StaticSwitch|StaticBool)/.test(e.type)) return
  const data = pkg.data(i + 1)
  for (let s = 0; s < 40; s++) { try { const tags = readTags(new Reader(data.subarray(s)), pkg); if (!tags.some((t: any) => t.name === 'ParameterName' || t.name === 'Texture')) continue
    const out: string[] = []
    for (const t of tags) {
      const dv = new DataView(t.value.buffer, t.value.byteOffset, t.value.byteLength)
      if (t.name === 'ParameterName') out.push('name=' + (typeof meta.names[dv.getInt32(0, true)] === 'string' ? meta.names[dv.getInt32(0, true)] : JSON.stringify(meta.names[dv.getInt32(0, true)])))
      else if (t.name === 'Texture') out.push('tex=' + pathOf(dv.getInt32(0, true)))
      else if (t.name === 'DefaultValue' && t.value.byteLength === 4) out.push('def=' + dv.getFloat32(0, true).toFixed(3))
      else if (t.name === 'DefaultValue' && t.value.byteLength === 16) out.push('def=(' + [0,1,2,3].map(k => dv.getFloat32(4*k, true).toFixed(2)).join(',') + ')')
    }
    console.log(e.type.replace('MaterialExpression', ''), out.join(' ')); break } catch {} }
})
