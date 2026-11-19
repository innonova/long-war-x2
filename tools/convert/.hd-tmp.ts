import { readFileSync, writeFileSync } from 'node:fs'
import { dirname } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { inlineTextures } from './inline-textures.ts'
const src = process.argv[2]!
const bytes = decompressPackage(new Uint8Array(readFileSync(src)))
const meta: any = new Package(bytes)
let best = 0
inlineTextures(bytes, meta.exports, meta.names, dirname(src), bytes.length, (e) => !new RegExp(process.argv[3]!).test(e.fullName), (e, format, mip, w, h) => {
  if (w > best && w <= 512) { best = w; writeFileSync(process.argv[4]!, mip); console.log(e.fullName, format, w, h) }
  return undefined
})
