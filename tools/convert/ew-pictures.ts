// Long War's pictures for EW's strategy screens (features/lw-ew-pictures.md), from the player's own install. Long War keeps
// each item's, tech's and Foundry project's picture in DefaultContent.ini's MultiplayerLoadoutSlots, which its patched
// UIUtilities reads (GetItemImagePath: iPointValue 0 and the item's number; GetTechImagePath: 2 and the tech's;
// GetFoundryImagePath: 3 and the project's). The paths go into the mod's XComLWX2Images.ini (written on the player's
// machine, never committed), EW's own moved to where the converted base carries them (ew-images.ts:
// Command1.QILibrary_StrategyImages). Long War's own pictures (its LongWar.upk) are left out for now: converted as it is
// (ew-package.ts), one of its textures crashed XCOM 2 as it loaded ("Serial size mismatch", 394 bytes more read than the
// export holds); those items, techs and projects keep XCOM 2's pictures.
//   node tools/convert/ew-pictures.ts <EW's XEW folder> <the mod's folder>
import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'

const KINDS: Record<string, string> = { '0': 'Items', '2': 'Techs', '3': 'Foundry' }

/** The ini text for a DefaultContent.ini's text: [LongWarX2.LWX2Pictures] +Items=(Id=…, Path="…"), +Techs, +Foundry. */
export function picturesIni(content: string): { text: string; count: number } {
  const lines: string[] = []
  const seen = new Set<string>()
  for (const m of content.matchAll(/^MultiplayerLoadoutSlots=\(strUnitName="([^"]+)",\s*iPointValue=(\d+),\s*iIconType=(\d+)\)/gm)) {
    const kind = KINDS[m[2]!]
    if (!kind) continue
    const key = `${kind}:${m[3]}`
    if (seen.has(key)) continue
    seen.add(key)
    if (!m[1]!.startsWith('UILibrary_StrategyImages.')) continue
    const path = m[1]!.replace(/^UILibrary_StrategyImages\./, 'Command1.QILibrary_StrategyImages.')
    lines.push(`+${kind}=(Id=${m[3]}, Path="${path}")`)
  }
  return { text: ['[LongWarX2.LWX2Pictures]', ...lines, ''].join('\r\n'), count: lines.length }
}

/** XComLWX2Images.ini written into the mod's Config from the player's EW install; how many pictures. */
export function writePictures(ew: string, mod: string): number {
  const ini = join(ew, 'XComGame', 'Config', 'DefaultContent.ini')
  if (!existsSync(ini)) throw new Error('no DefaultContent.ini in the Enemy Within install')
  const { text, count } = picturesIni(readFileSync(ini, 'latin1'))
  writeFileSync(join(mod, 'Config', 'XComLWX2Images.ini'), text)
  return count
}

/** Long War's own pictures package (LongWar.upk: textures only) converted into the mod's Content as it is, by the given
 *  converter (ew-package.ts), so that LongWar.<Group>.<Name> loads. Not used yet: see the head of this file. */
export function convertLongWarPictures(ew: string, content: string, convert: (src: string, out: string) => string): string {
  const src = join(ew, 'XComGame', 'CookedPCConsole', 'LongWar.upk')
  if (!existsSync(src)) return "Long War's pictures package not found"
  return convert(src, join(content, 'LongWar.upk'))
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const [ew, mod] = process.argv.slice(2)
  if (!ew || !mod) {
    console.error('node tools/convert/ew-pictures.ts <EW XEW folder> <mod folder>')
    process.exit(1)
  }
  console.log(`${writePictures(ew, mod)} pictures in Config/XComLWX2Images.ini`)
}
