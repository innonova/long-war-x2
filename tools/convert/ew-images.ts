// Enemy Within's strategy pictures (features/lw-ew-screens.md: tech, item, facility, gene mod, medal and craft pictures),
// from the player's own install. EW cooks them into its base's map package as forced exports of UILibrary_StrategyImages
// (Command1.upk: 303 textures in ten groups, GeneMods, ScienceIcons, InventoryIcons …), and its screens ask for them as
// img:///UILibrary_StrategyImages.<Group>.<Name>. The setup converts that package with EW's base (ew-map.ts): the
// carried package renamed QILibrary_StrategyImages (XCOM 2 has a UILibrary_StrategyImages of its own) and nested in the
// map's package (its forced-export flag cleared). Its groups and textures keep that flag, and a picture asked for by its
// path, Command1.QILibrary_StrategyImages.<Group>.<Name>, was not found; with it cleared on them too, it loads, and the
// screens show it as img:///Command1.QILibrary_StrategyImages.<Group>.<Name> (UILWEWScreen.EW_IMAGES). Done in place,
// again on each run (nothing to do the second time). (Converting EW's shell package, which carries the same pictures,
// crashed XCOM 2 as it loaded it.)
//   node tools/convert/ew-images.ts <converted Command1.upk>
import { readFileSync, writeFileSync } from 'node:fs'
import { Package } from '@innonova/upkit/upk'

export const EW_IMAGES = 'QILibrary_StrategyImages'
/** The carried packages opened so: EW's pictures, and its facility chooser's (ChooseFacilities, renamed as the converter
 *  renames carried packages: the blueprints ew-map.ts copies, LWX2Blueprint_*, and their frame; converter 97). */
const OPENED = [EW_IMAGES, 'QhooseFacilities']

/** The pictures in the converted base package made loadable by their paths; returns how many were changed. */
export function openImages(base: string): number {
  const bytes = new Uint8Array(readFileSync(base))
  const pkg = new Package(bytes)
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  let n = 0
  for (const e of pkg.exports as { fullName: string; entryOffset: number }[]) {
    if (!OPENED.some((p) => e.fullName === p || e.fullName.startsWith(p + '.'))) continue
    // (The export flags: an entry's 41st byte; EF_ForcedExport = 1.)
    const at = e.entryOffset + 40
    const flags = v.getUint32(at, true)
    if (flags & 1) {
      v.setUint32(at, flags & ~1, true)
      n++
    }
  }
  if (n > 0) writeFileSync(base, bytes)
  return n
}

if (/ew-images\.ts$/.test(process.argv[1] ?? '')) {
  const [base] = process.argv.slice(2).filter((a) => a !== '--')
  if (!base) {
    console.error('usage: ew-images.ts <converted Command1.upk>')
    process.exit(2)
  }
  console.log(`${openImages(base)} pictures made loadable in ${base}`)
}
