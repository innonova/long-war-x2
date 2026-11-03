// Enemy Within's aliens' bodies for XCOM 2's alien templates (features/lw-ew-units.md), on the player's machine: each EW
// unit package converted (ew-package.ts) with its animations also under the names its XCOM 2 template asks for
// (ew-unit-anims.ts), and the mod's list of bodies written (Config/XComLWX2EWUnits.ini, never shipped: it names the
// player's conversions). Long War's species fight as XCOM 2 templates (XComLWStrategy.ini, FightAs): the body goes on the
// template, so two species on one template (Sectoid and Sectoid Commander) share the first's.
//
//   node tools/convert/ew-units.ts <EW>/CookedPCConsole <mod folder> [content folder, default <mod>/Content]
import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { Package, decompressPackage } from '@innonova/upkit/upk'
import { convertPackage } from './ew-package.ts'
import { renameAnims } from './ew-unit-anims.ts'
import { X2_ANIM_NAMES } from './x2-anim-names.ts'

/** XCOM 2's template, EW's package, its mesh and AnimSets (the first takes the renamed copies), its textures by name. */
/** EW's weapon for it: its package, mesh, textures by name. */
export interface EWWeapon { pkg: string; mesh: string; diffuse: RegExp; normal: RegExp }
/** species: Long War's species (EW's ECharacter) when it shares its template with another (its own body before the template's). */
export interface EWUnit { template: string; species?: number; pkg: string; mesh: string; sets: string[]; diffuse: RegExp; normal: RegExp; weapon?: EWWeapon }
const PLASMA_LIGHT: EWWeapon = { pkg: 'Weapon_PlasmaRifle_ThinMan_SF', mesh: 'SM_LightPlasmaRifle', diffuse: /^LightAssaultRiflePlasma_DIF$/, normal: /^LightAssaultRiflePlasma_NRM$/ }
export const EW_UNITS: EWUnit[] = [
  { template: 'Sectoid', pkg: 'GameUnit_XComSectoid_SF', mesh: 'SM_SectoidSoldier', sets: ['AS_SectoidPistol'], diffuse: /^SectoidSoldier_DIF$/, normal: /^SectoidSoldier_NRM$/,
    weapon: { pkg: 'Weapon_PlasmaPistolSectoid_SF', mesh: 'SM_PistolPlasmaSectoid', diffuse: /^T_PistolPlasma_DIF$/, normal: /^T_PistolPlasma_NRM$/ } },
  { template: 'Archon', pkg: 'GameUnit_XComFloater_SF', mesh: 'SM_MedFloater', sets: ['AS_HeavyFloaterRifle', 'AS_HeavyFloaterJetRifle'], diffuse: /^MedFloater_DIF$/, normal: /^MedFloater_NRM$/,
    weapon: { ...PLASMA_LIGHT, pkg: 'Weapon_PlasmaRifle_Floater_SF' } },
  { template: 'Sectoid', species: 9, pkg: 'GameUnit_XComSectoidCom_SF', mesh: 'SM_SectoidCom', sets: ['AS_SectoidPistol'], diffuse: /^SectoidCom_DIF$/, normal: /^SectoidCom_NRM$/,
    weapon: { pkg: 'Weapon_PlasmaPistolSectoid_SF', mesh: 'SM_PistolPlasmaSectoid', diffuse: /^T_PistolPlasma_DIF$/, normal: /^T_PistolPlasma_NRM$/ } },
  { template: 'Archon', species: 10, pkg: 'GameUnit_XComFloaterHeavy_SF', mesh: 'SM_HeavyFloater', sets: ['AS_HeavyFloaterRifle', 'AS_HeavyFloaterJetRifle'], diffuse: /^HeavyFloater_DIF$/, normal: /^HeavyFloater_NRM$/,
    weapon: { pkg: 'Weapon_HeavyPlasmaFloater_SF', mesh: 'SM_AssaultRiflePlasma', diffuse: /^AssaultRiflePlasma_DIF$/, normal: /^AssaultRiflePlasma_NRM$/ } },
  { template: 'Viper', pkg: 'GameUnit_XComThinMan_SF', mesh: 'SM_ThinMan', sets: ['AS_ThinManPistol'], diffuse: /^ThinMan_DIF/, normal: /^ThinMan_NRM/, weapon: PLASMA_LIGHT },
  { template: 'Faceless', pkg: 'GameUnit_Seeker_SF', mesh: 'SM_Seeker', sets: ['AS_SeekerDefault'], diffuse: /^Seeker_DIF/, normal: /^Seeker_NRM/ },
  { template: 'Gatekeeper', pkg: 'GameUnit_XComCyberDisc_SF', mesh: 'SM_Cyberdisc', sets: ['AS_Cyberdisc'], diffuse: /^T_Cyberdisc_DIF$/, normal: /^T_Cyberdisc_NRM$/ },
  { template: 'Muton', pkg: 'GameUnit_XComMuton_SF', mesh: 'SM_MutonSoldier', sets: ['AS_MutonRifle'], diffuse: /^MutonSoldier_DIF/, normal: /^MutonSoldier_NRM/,
    weapon: { pkg: 'Weapon_PlasmaRifleMuton_SF', mesh: 'SM_AssaultRiflePlasmaMuton', diffuse: /^AssaultRiflePlasma_DIF$/, normal: /^AssaultRiflePlasma_NRM$/ } },
  { template: 'Chryssalid', pkg: 'GameUnit_XComChryssalid_SF', mesh: 'SM_Cryssalid', sets: ['AS_CryssalidDefault'], diffuse: /^CHA_Cryssalid_DIF$/, normal: /^CHA_Cryssalid_NRM$/ },
  { template: 'PsiZombie', pkg: 'GameUnit_XComZombie_SF', mesh: 'SM_CivMale_Zombie', sets: ['AS_ZombieMaleDefault'], diffuse: /^CivMaleZombie_DIF$/, normal: /^T_CivilianMaleThinA_Body_NRM$/ },
  { template: 'Codex', pkg: 'GameUnit_XComOutsider_SF', mesh: 'SM_Outsider', sets: ['AS_Outsider', 'AS_SoldierRifle'], diffuse: /^Outsider_DIF/, normal: /^Outsider_NRM/,
    weapon: { ...PLASMA_LIGHT, pkg: 'Weapon_PlasmaRfLtOutsider_SF' } },
  { template: 'Andromedon', pkg: 'GameUnit_XComMutonElite_SF', mesh: 'SM_MutonElite', sets: ['AS_MutonRifle'], diffuse: /^MutonElite_DIF/, normal: /^MutonElite_NRM/,
    weapon: { pkg: 'Weapon_HeavyPlasmaMuton_SF', mesh: 'SM_BPHeavyPlasmaMuton', diffuse: /^WP_BPHeavyPlasma_DIF$/, normal: /^WP_BPHeavyPlasma_NRM$/ } },
  { template: 'Berserker', pkg: 'GameUnit_XComMutonCom_SF', mesh: 'SM_MutonBerserker', sets: ['AS_MutonRifle', 'AS_MutonBlade'], diffuse: /^MutonBerserker_DIF/, normal: /^MutonBerserker_NRM/ },
  { template: 'AdvMEC_M1', pkg: 'GameUnit_XComSectopodDrone_SF', mesh: 'SM_Drone', sets: ['AS_DroneDefault'], diffuse: /^Drone_DIF1$/, normal: /^Drone_NRM1$/ },
  { template: 'AdvMEC_M2', pkg: 'GameUnit_XComMechtoid_SF', mesh: 'SM_Mechtoid', sets: ['AS_Mechtoid'], diffuse: /^Mechtoid_DIF/, normal: /^Mechtoid_NRM/ },
]

/** An EW unit package's objects by name: its mesh's, its sets' and its textures' full paths (forced exports). */
function find(bytes: Uint8Array, u: EWUnit): { mesh: string; sets: string[]; diffuse: string; normal: string } {
  const meta: any = new Package(bytes)
  const byType = (type: string, test: (name: string) => boolean) =>
    meta.exports.find((e: any) => e.type === type && test(e.fullName.split('.').pop()))?.fullName ?? ''
  return {
    mesh: byType('SkeletalMesh', (n) => n === u.mesh),
    sets: u.sets.map((s) => byType('AnimSet', (n) => n === s)).filter(Boolean),
    diffuse: byType('Texture2D', (n) => u.diffuse.test(n)),
    normal: byType('Texture2D', (n) => u.normal.test(n)),
  }
}

/** Each EW unit converted into content and the mod's list of bodies written; returns report lines. */
export function convertUnits(cooked: string, mod: string, content: string, say: (line: string) => void = console.log): number {
  const lines = [
    "; Enemy Within's aliens' bodies on XCOM 2's templates, from the packages converted on this machine",
    '; (tools/convert/ew-units.ts, features/lw-ew-units.md). Not in the repository: it names the player\'s own conversions.',
    '[LongWarX2.LWX2EWBodies]',
    'MaterialParent="Materials.Approved.AlienUnit_TC"',
  ]
  let n = 0
  for (const u of EW_UNITS) {
    const src = join(cooked, `${u.pkg}.upk`)
    if (!existsSync(src)) { say(`${u.pkg}: not in this Enemy Within install, XCOM 2's ${u.template} kept`); continue }
    try {
      let found = find(decompressPackage(new Uint8Array(readFileSync(src))), u)
      if (!found.mesh || !found.sets.length) { say(`${u.pkg}: no ${u.mesh} or ${u.sets.join('/')}, XCOM 2's ${u.template} kept`); continue }
      const report = convertPackage(src, join(content, `${u.pkg}.upk`), (bytes) => renameAnims(bytes, found.sets, X2_ANIM_NAMES[u.template] ?? []))
      const leaf = (p: string, pkg = u.pkg) => (p ? `${pkg}.${p.split('.').pop()}` : '')
      // Its weapon: EW's, converted as it is (textures inlined), in place of the XCOM 2 weapon's mesh; a species with none in
      // its hands (the Drone, the Seeker, the Cyberdisc …) has the XCOM 2 weapon hidden (WeaponMesh="none").
      let weapon = ', WeaponMesh="none"'
      const w = u.weapon
      if (w && existsSync(join(cooked, `${w.pkg}.upk`))) {
        const wb = decompressPackage(new Uint8Array(readFileSync(join(cooked, `${w.pkg}.upk`))))
        const wf = find(wb, { ...u, mesh: w.mesh, sets: [], diffuse: w.diffuse, normal: w.normal })
        if (wf.mesh) {
          convertPackage(join(cooked, `${w.pkg}.upk`), join(content, `${w.pkg}.upk`))
          weapon = `, WeaponMesh="${leaf(wf.mesh, w.pkg)}", WeaponDiffuse="${leaf(wf.diffuse, w.pkg)}", WeaponNormal="${leaf(wf.normal, w.pkg)}"`
        }
      }
      lines.push(`+Bodies=(Template=${u.template},${u.species ? ` Species=${u.species},` : ''} Mesh="${leaf(found.mesh)}", AnimSet="${leaf(found.sets[0]!)}", Diffuse="${leaf(found.diffuse)}", Normal="${leaf(found.normal)}"${weapon})`)
      say(`${u.template} as Enemy Within's (${u.pkg}): ${report.split('; ').slice(-1)[0]}`)
      n++
    } catch (e: any) {
      say(`${u.pkg}: could not be converted (${e?.message ?? e}), XCOM 2's ${u.template} kept`)
    }
  }
  writeFileSync(join(mod, 'Config', 'XComLWX2EWUnits.ini'), lines.join('\r\n') + '\r\n')
  return n
}

if (/ew-units\.ts$/.test(process.argv[1] ?? '')) {
  const [cooked, mod, content] = process.argv.slice(2).filter((a) => a !== '--')
  if (!mod) {
    console.error('usage: ew-units.ts <EW>/CookedPCConsole <mod folder> [content folder]')
    process.exit(2)
  }
  console.log(`${convertUnits(cooked!, mod!, content ?? join(mod!, 'Content'))} of ${EW_UNITS.length} units converted`)
}
