// Builds the player's setup program (tools/setup/setup.mjs) as one Windows executable, so the
// player needs no Node: esbuild bundles it with upkit into one file, and Node's single
// executable support puts that into the official node.exe of the same version as the Node
// running this (downloaded once into dist/, checked against nodejs.org's SHASUMS256).
//   npm run setup:bundle        → dist/LongWarX2-setup.exe
import { build } from 'esbuild'
import { execFileSync } from 'node:child_process'
import { createHash } from 'node:crypto'
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..')
const dist = join(root, 'dist')
mkdirSync(dist, { recursive: true })

await build({
  entryPoints: [join(root, 'tools', 'setup', 'setup.mjs')],
  bundle: true,
  platform: 'node',
  target: 'node24',
  format: 'cjs',
  outfile: join(dist, 'setup.cjs'),
  logLevel: 'warning',
})

const version = process.version // e.g. v24.18.0
const nodeExe = join(dist, `node-${version}-win-x64.exe`)
if (!existsSync(nodeExe)) {
  const base = `https://nodejs.org/dist/${version}`
  const sums = await (await fetch(`${base}/SHASUMS256.txt`)).text()
  const want = sums.split('\n').find((l) => l.endsWith(' win-x64/node.exe'))?.split(/\s+/)[0]
  const bin = Buffer.from(await (await fetch(`${base}/win-x64/node.exe`)).arrayBuffer())
  const got = createHash('sha256').update(bin).digest('hex')
  if (!want || want !== got) throw new Error(`node.exe ${version}: checksum ${got} does not match ${want}`)
  writeFileSync(nodeExe, bin)
}

const config = join(dist, 'sea-config.json')
writeFileSync(config, JSON.stringify({ main: join(dist, 'setup.cjs'), output: join(dist, 'sea-prep.blob'), disableExperimentalSEAWarning: true, useCodeCache: false, useSnapshot: false }))
execFileSync(process.execPath, ['--experimental-sea-config', config], { stdio: 'inherit' })
const out = join(dist, 'LongWarX2-setup.exe')
copyFileSync(nodeExe, out)
execFileSync(process.execPath, [join(root, 'node_modules', 'postject', 'dist', 'cli.js'), out, 'NODE_SEA_BLOB', join(dist, 'sea-prep.blob'), '--sentinel-fuse', 'NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2'], { stdio: 'inherit' })
console.log(`${out}: ${(readFileSync(out).length / 1e6).toFixed(0)} MB`)
