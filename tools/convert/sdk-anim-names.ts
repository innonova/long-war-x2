// For development (features/lw-ew-units.md): the animation names each XCOM 2 alien template's pawn asks for, read from
// the SDK's uncooked animation packages (XComGame/Content/XCOM_2/Packages/Characters/Aliens/<X>_ANIM.upk), written as
// tools/convert/x2-anim-names.ts. Names only. The player's machine has no SDK: the list ships with the converter.
//
//   node tools/convert/sdk-anim-names.ts <folder with the SDK's *_ANIM.upk> > tools/convert/x2-anim-names.ts
import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { openPackage } from '@innonova/upkit/package'
import { Reader } from '@innonova/upkit/bytes'
import { readTags } from '@innonova/upkit/objects'

/** Each template's package and the AnimSets its pawn plays from (its main set, its weapon's, its pod's). */
const TEMPLATES: Record<string, [string, RegExp]> = {
  Sectoid: ['Sectoid', /\.AS_(Sectoid|Pod)$/],
  Archon: ['Archon', /\.AS_(Archon|ArchonRifle|ArchonPod)$/],
  Viper: ['Viper', /\.AS_(Viper|Pod)$/],
  Faceless: ['Faceless', /\.AS_(Faceless|FacelessPod)$/],
  Gatekeeper: ['Gatekeeper', /\.AS_Gatekeeper(Closed|Opened|Closed_Pod|Opened_Pod)$/],
  Muton: ['Muton', /\.AS_(Muton|Muton_Rifle|Muton_Grenade|Muton_Bayonet|Pod)$/],
  Chryssalid: ['Cryssalid', /\.AS_(CryssalidDefault|ChryssalidPod)$/],
  PsiZombie: ['Zombie', /\.AS_(Zombie|Pod)$/],
  Codex: ['Cyberus', /\.AS_(Cyberus|Pod)$/],
  AdvMEC_M1: ['AdventMec', /\.AS_(AdventMec|AdventMecRifle|Pod)$/],
  AdvMEC_M2: ['AdventMec', /\.AS_(AdventMec|AdventMecRifle|Pod)$/],
  Andromedon: ['Andromedon', /AS_(Andromedon|AndromedonRifle|AndromedonPOD)$/],
  Berserker: ['Berserker', /AS_(Berserker|Pod)$/],
  Sectopod: ['Sectopod', /\.AS_Sectopod(High|Low|HighPod|LowPod)$/],
}

const folder = process.argv[2]!
const out: string[] = []
for (const [template, [file, sets]] of Object.entries(TEMPLATES)) {
  const bytes = decompressPackage(new Uint8Array(readFileSync(join(folder, `${file}_ANIM.upk`))))
  const meta: any = new Package(bytes)
  const pkg: any = openPackage(bytes)
  const names = new Set<string>()
  meta.exports.forEach((e: any, k: number) => {
    if (e.type !== 'AnimSequence' || !sets.test(e.fullName.split('.').slice(0, -1).join('.'))) return
    try {
      const t = (readTags(new Reader(pkg.data(k + 1).subarray(4)), pkg) as any[]).find((x) => x.name === 'SequenceName')
      if (t) names.add(String(pkg.names[new DataView(t.value.buffer, t.value.byteOffset).getInt32(0, true)].name))
    } catch {
      // not an animation's properties
    }
  })
  out.push(`  ${template}: ${JSON.stringify([...names].sort())},`)
}
console.log([
  '// The animation names each XCOM 2 alien template asks for (from the SDK by sdk-anim-names.ts; names only). Generated: do not edit.',
  'export const X2_ANIM_NAMES: Record<string, string[]> = {',
  ...out,
  '}',
].join('\n'))
