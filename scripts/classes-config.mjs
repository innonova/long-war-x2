// Long War 1.0's eight subclasses as XCOM 2 soldier classes (features/lw-classes.md), from the
// player's own Long War install:
//   - LongWarX2/Config/XComClassData.ini: the classes (their perk trees, three choices a
//     rank, Corporal to Colonel; their stat gains; weapons), Long War's perks as XCOM 2's
//     abilities where XCOM 2 has the same perk, else as stand-ins (LW_<Name>);
//   - LongWarX2/Config/XComLWClasses.ini: Long War's own perks, for X2Ability_LWStandins: those
//     whose bonuses are known working (X2Effect_LWModifiers), the others stand-ins;
//   - LongWarX2/Localization/XComGame.int: the classes' names and the stand-ins' names and
//     descriptions, Long War's own words: written on the player's machine, not in the
//     repository (.gitignore).
//
// With Long War's XComGame.upk as well, the numbers in the perks' words are filled in (EW
// fills them at run time: <XGAbility:ExecutionerAimBonus/>), from EW's constants (read with
// upkit: $UPKIT, else the Long War Tech Tree's beside this checkout) and Long War's ini.
//
//   node scripts/classes-config.mjs <Long War's DefaultGameCore.ini> <Long War's XComGame.int> [<XComGame.upk>]
import { readFileSync, writeFileSync } from 'node:fs'
import { execFileSync } from 'node:child_process'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const [coreIni, gameInt, gameUpk] = process.argv.slice(2)
if (!gameInt) {
  console.error('usage: classes-config.mjs <DefaultGameCore.ini> <XComGame.int>')
  process.exit(2)
}
const here = dirname(fileURLToPath(import.meta.url))
const mod = join(here, '..', 'LongWarX2')
const lines = (p) => readFileSync(join(here, 'x2-names', p), 'utf8').split(/\r?\n/).filter(Boolean)
const x2Abilities = new Set(lines('abilities.txt'))
const x2Icons = new Map(lines('perk-icons.txt').map((n) => [n.toLowerCase(), n]))
const core = readFileSync(coreIni, 'latin1')
const loc = readFileSync(gameInt, 'latin1')

/** The subclasses: Long War's tree ids, its squaddie perk (from the base class's tree), XCOM 2's look. */
const CLASSES = [
  { id: 11, name: 'Sniper', squaddie: 'ePerk_SquadSight', weapons: ['sniper_rifle'], loadout: 'Sniper', icon: 'class_sharpshooter' },
  { id: 21, name: 'Scout', squaddie: 'ePerk_LightningReflexes', weapons: ['sniper_rifle', 'rifle'], loadout: 'Rifle', icon: 'class_sharpshooter' },
  { id: 12, name: 'Rocketeer', squaddie: 'ePerk_FireRocket', weapons: ['rifle'], loadout: 'Rifle', icon: 'class_grenadier' },
  { id: 22, name: 'Gunner', squaddie: 'ePerk_FocusedSuppression', weapons: ['cannon'], loadout: 'Gunner', icon: 'class_grenadier' },
  { id: 13, name: 'Medic', squaddie: 'ePerk_FieldMedic', weapons: ['rifle'], loadout: 'Rifle', icon: 'class_specialist' },
  { id: 23, name: 'Engineer', squaddie: 'ePerk_Grenadier', weapons: ['rifle'], loadout: 'Rifle', icon: 'class_specialist' },
  { id: 14, name: 'Assault', squaddie: 'ePerk_RunAndGun', weapons: ['shotgun', 'rifle'], loadout: 'Shotgun', icon: 'class_ranger' },
  { id: 24, name: 'Infantry', squaddie: 'ePerk_PlasmaBarrage', weapons: ['rifle'], loadout: 'Rifle', icon: 'class_ranger' },
]
const LOADOUTS = {
  Sniper: ['SniperRifle_CV', 'Pistol_CV'],
  Rifle: ['AssaultRifle_CV', 'Pistol_CV'],
  Gunner: ['Cannon_CV', 'Pistol_CV'],
  Shotgun: ['Shotgun_CV', 'Pistol_CV'],
}
/**
 * Long War's perks that are XCOM 2's perks by the same name and the same idea (XCOM 2's
 * numbers, for now). Everything else becomes a stand-in.
 */
const SAME = {
  ePerk_SquadSight: 'Squadsight',
  ePerk_LightningReflexes: 'LightningReflexes',
  ePerk_RunAndGun: 'RunAndGun',
  ePerk_InTheZone: 'InTheZone',
  ePerk_CoveringFire: 'CoveringFire',
  ePerk_Sentinel: 'Sentinel',
  ePerk_RapidFire: 'RapidFire',
  ePerk_TracerBeams: 'HoloTargeting',
  ePerk_FieldMedic: 'FieldMedic',
}
const RANKS = ['Corporal1', 'Sergeant1', 'Lieutenant1', 'Captain1', 'Major', 'Colonel1']
const RANK_NAMES = ['eRank_Squaddie', 'eRank_Corporal', 'eRank_Sergeant', 'eRank_Lieutenant', 'eRank_Captain', 'eRank_Major', 'eRank_Colonel']

// --- Long War's data ---------------------------------------------------------------
const trees = new Map()
for (const m of core.matchAll(/^SoldierPerkTrees=\(SoldierType=(\d+),\s*(.*)\)\s*$/gm)) {
  const id = Number(m[1])
  trees.set(id, [...(trees.get(id) ?? []), Object.fromEntries([...m[2].matchAll(/(\w+)=(\w+)/g)].map((x) => [x[1], x[2]]))])
}
const progression = new Map()
for (const m of core.matchAll(/^SoldierStatProgression=\(eClass=(\d+),\s*eRank=(\w+),\s*iHP=(\d+),\s*iAim=(\d+),\s*iWill=(\d+)\)/gm)) {
  // Under normal settings the gain is the last two digits (the others are for randomised gains).
  progression.set(`${m[1]}:${m[2]}`, { hp: Number(m[3]) % 100, aim: Number(m[4]) % 100, will: Number(m[5]) % 100 })
}
const locOf = (key, perk) => {
  const m = loc.match(new RegExp(`^${key}\\[${perk}\\]="(.*)"\\s*$`, 'm'))
  return m ? m[1] : ''
}
// Long War reused EW's perk slots under new names; its ini lists the ones not obvious ("; Lock N' Load:  ePerk_Disabled_DEPRECATED").
const renamed = new Map([...core.matchAll(/^;\s*([^;:\n]+?):?\s+(ePerk_\w+)\s*$/gm)].map((m) => [m[2], m[1].trim()]))
const titleOf = (perk) => locOf('m_strPassiveTitle', perk) || renamed.get(perk) || perk.replace(/^ePerk_/, '')

// --- The numbers in the words -----------------------------------------------------------
// EW's text expansion is native; these are the values it shows: its constants
// (XGTacticalGameCoreNativeBase) and, where Long War made them settings, Long War's ini.
const consts = new Map()
if (gameUpk) {
  const upkit = process.env.UPKIT ?? join(here, '..', '..', 'xcom-ew-lw-tree', 'node_modules', '@innonova', 'upkit', 'dist', 'upkit.mjs')
  const src = execFileSync(process.execPath, [upkit, 'class', gameUpk, 'XGTacticalGameCoreNativeBase'], { encoding: 'utf8', maxBuffer: 64 << 20 })
  for (const m of src.matchAll(/^const (\w+) = ([-\d.]+)f?;/gm)) consts.set(m[1], Number(m[2]))
}
const ini = (key) => {
  const m = core.match(new RegExp(`^${key}=([-\\d.]+)`, 'm'))
  return m ? Number(m[1]) : undefined
}
const c = (name, times = 1) => (consts.has(name) ? Math.round(consts.get(name) * times) : undefined)
const TAGS = {
  SmokeBombDefenseBonus: () => c('SMOKE_BOMB_DEFENSE_BONUS'),
  DenseSmokeDefenseBonus: () => c('DENSE_SMOKE_DEFENSE_BONUS'),
  ExecutionerAimBonus: () => c('EXECUTIONER_AIM_BONUS'),
  ExecutionerHealthThreshold: () => c('EXECUTIONER_HP_MIN', 100),
  TacticalSenseDefenseBonusPerEnemy: () => c('TACTICALSENSE_DEFENSE_BONUS'),
  TacticalSenseDefenseBonusMax: () => (consts.has('TACTICALSENSE_DEFENSE_BONUS') ? c('TACTICALSENSE_DEFENSE_BONUS') * c('TACTICALSENSE_MAX_ENEMIES') : undefined),
  AggressionCritBonusPerEnemy: () => c('AGGRESSION_CRIT_BONUS'),
  AggressionCritBonusMax: () => (consts.has('AGGRESSION_CRIT_BONUS') ? c('AGGRESSION_CRIT_BONUS') * c('AGGRESSION_MAX_ENEMIES') : undefined),
  SnapShotAimPenalty: () => c('SNAP_SHOT_AIM_PENALTY'),
  ShredderRocketDamageEffectDuration: () => c('SHREDDER_ROCKET_DURATION'),
  RocketeerExtraRockets: () => c('ROCKETEER_BONUS_ROCKETS'),
  ReviveHealthPercent: () => c('REVIVE_HEALTH_AMOUNT', 100),
  PlatformStabilityAim: () => c('PLATFORMSTABILITY_AIM'),
  PlatformStabilityCrit: () => c('PLATFORMSTABILITY_CRIT'),
  KillerInstinctCritDamageBonus: () => c('KILLERINSTINCT_CRIT_DMG_MULT', 100),
  GrenadierCharges: () => c('GRENADIER_CHARGES'),
  DoubleTapCooldown: () => c('DOUBLETAP_COOLDOWN'),
  DamnGoodGroundAimBonus: () => c('DAMN_GOOD_GROUND_OFFENSE_BONUS'),
  DamnGoodGroundDefenseBonus: () => c('DAMN_GOOD_GROUND_DEFENSE_BONUS'),
  CombatDrugsWillBonus: () => c('COMBAT_DRUGS_WILL_BONUS'),
  CloseAndPersonalDist: () => c('CLOSEANDPERSONAL_MAX_DIST'),
  BattleScannerDuration: () => c('BATTLE_SCANNER_DURATION'),
  CalcSuppression: () => c('SUPPRESSION_AIM_PENALTY'),
  UrbanAim: () => ini('URBAN_AIM'),
  CouncilMedalFightBonus: () => ini('COUNCIL_FIGHT_BONUS'),
  CouncilMedalFightTiles: () => ini('COUNCIL_FIGHT_TILES'),
}
const unfilled = new Set()
const fill = (text) =>
  text.replace(/<XGAbility:(\w+)\/>/g, (all, tag) => {
    const v = TAGS[tag]?.()
    if (v === undefined) unfilled.add(tag)
    return v === undefined ? '' : String(v)
  })

// --- Perks to abilities ---------------------------------------------------------------
const standins = new Map() // name -> { perk, icon }
function abilityFor(perk) {
  if (SAME[perk] && x2Abilities.has(SAME[perk])) return SAME[perk]
  const title = titleOf(perk)
  const name = 'LW_' + title.replace(/[^A-Za-z0-9]+/g, ' ').trim().split(' ').map((w) => w[0].toUpperCase() + w.slice(1)).join('')
  if (!standins.has(name)) {
    const candidates = [title.replace(/[^A-Za-z0-9]/g, ''), perk.replace(/^ePerk_/, '')].map((c) => `uiperk_${c.toLowerCase()}`)
    const icon = candidates.map((c) => x2Icons.get(c)).find(Boolean) ?? 'UIPerk_standard'
    standins.set(name, { perk, icon })
  }
  return name
}

// --- The perks that work already ------------------------------------------------------
// Bonuses under a condition (X2Effect_LWModifiers), with Long War's numbers: EW's constants,
// Long War's ini, else the number its own words give. Undefined values leave a perk a stand-in.
const REAL = {
  LW_LoneWolf: () => ({ Aim: ini('COUNCIL_FIGHT_BONUS'), AimIf: 'NoAllyWithin', Crit: ini('COUNCIL_FIGHT_BONUS'), CritIf: 'NoAllyWithin', Param: ini('COUNCIL_FIGHT_TILES') }),
  LW_Sharpshooter: () => ({ Crit: 10, Aim: ini('URBAN_AIM'), AimIf: 'TargetInFullCover' }),
  LW_Executioner: () => ({ Aim: c('EXECUTIONER_AIM_BONUS'), AimIf: 'TargetHealthBelow', Crit: c('EXECUTIONER_AIM_BONUS'), CritIf: 'TargetHealthBelow', Param: consts.get('EXECUTIONER_HP_MIN') }),
  LW_Aggression: () => ({ Crit: c('AGGRESSION_CRIT_BONUS'), CritIf: 'PerVisibleEnemy', MaxStacks: c('AGGRESSION_MAX_ENEMIES') }),
  LW_TacticalSense: () => ({ Defense: c('TACTICALSENSE_DEFENSE_BONUS'), DefenseIf: 'PerVisibleEnemy', MaxStacks: c('TACTICALSENSE_MAX_ENEMIES') }),
  LW_DamnGoodGround: () => ({ Aim: c('DAMN_GOOD_GROUND_OFFENSE_BONUS'), AimIf: 'HeightAdvantage', Defense: c('DAMN_GOOD_GROUND_DEFENSE_BONUS'), DefenseIf: 'HeightAdvantage' }),
  LW_PlatformStability: () => ({ Aim: c('PLATFORMSTABILITY_AIM'), AimIf: 'NoActionTaken', Crit: c('PLATFORMSTABILITY_CRIT'), CritIf: 'NoActionTaken' }),
  LW_Sprinter: () => ({ Mobility: 4 }),
  LW_Resilience: () => ({ CritAgainst: 100 }),
  // XCOM 2's low cover gives 20 defence, its full cover 40.
  LW_LowProfile: () => ({ Defense: 20, DefenseIf: 'InLowCover' }),
  LW_Ranger: () => ({ Damage: 1, DamageIf: 'PrimaryOrPistol' }),
}
const realFields = (name) => {
  const f = REAL[name]?.()
  if (!f || Object.values(f).some((v) => v === undefined)) return ''
  return Object.entries(f).map(([k, v]) => `, ${k}=${typeof v === 'string' ? v : v}`).join('')
}

// --- The classes -----------------------------------------------------------------------
const q = (s) => `"${s}"`
const out = [
  "; Long War 1.0's eight subclasses, generated by scripts/classes-config.mjs from Long War's",
  "; DefaultGameCore.ini (its perk trees and stat gains). Do not edit by hand.",
  '',
  '[XComGame.X2SoldierClass_DefaultClasses]',
  ...CLASSES.map((c) => `+SoldierClasses=${q('LWS_' + c.name)}`),
  '',
  "; Recruits become Long War's classes, not XCOM 2's.",
  ...['Ranger', 'Sharpshooter', 'Grenadier', 'Specialist'].flatMap((n) => [`[${n} X2SoldierClassTemplate]`, 'NumInForcedDeck=0', 'NumInDeck=0']),
  '',
  '[XComGame.X2ItemTemplateManager]',
  ...Object.entries(LOADOUTS).map(([n, items]) => `+Loadouts=(LoadoutName=${q('LWS_Squaddie' + n)}, ${items.map((it, k) => `Items[${k}]=(Item=${q(it)})`).join(', ')})`),
]
const stats = (id, rank) => {
  const p = progression.get(`${id}:${rank}`) ?? { hp: 0, aim: 0, will: 0 }
  return `aStatProgression=((StatType=eStat_HP,StatAmount=${p.hp}), (StatType=eStat_Offense,StatAmount=${p.aim}), (StatType=eStat_Will,StatAmount=${p.will}))`
}
const slot = (ability, weaponSlot) => `(AbilityType=(AbilityName=${q(ability)}${weaponSlot ? `, ApplyToWeaponSlot=${weaponSlot}` : ''}))`
for (const c of CLASSES) {
  const rows = trees.get(c.id) ?? []
  if (rows.length !== 3) throw new Error(`${c.name}: ${rows.length} perk rows in the tree, expected 3`)
  out.push(
    '',
    `[LWS_${c.name} X2SoldierClassTemplate]`,
    'bMultiplayerOnly=0',
    'ClassPoints=4',
    `IconImage="img:///UILibrary_Common.${c.icon}"`,
    'NumInForcedDeck=1',
    'NumInDeck=4',
    'KillAssistsPerKill=5',
    `SquaddieLoadout=${q('LWS_Squaddie' + c.loadout)}`,
    ...c.weapons.map((w) => `+AllowedWeapons=(SlotType=eInvSlot_PrimaryWeapon, WeaponType=${q(w)})`),
    '+AllowedWeapons=(SlotType=eInvSlot_SecondaryWeapon, WeaponType="pistol")',
    '+AllowedArmors="soldier"',
    'bAllowAWCAbilities=0',
    'bHasClassMovie=false',
    'bCanHaveBonds=true',
    'BaseAbilityPointsPerPromotion=3',
    `; squaddie: ${titleOf(c.squaddie)}`,
    `+SoldierRanks=(AbilitySlots=(${slot(abilityFor(c.squaddie))}, ${slot('PistolStandardShot', 'eInvSlot_SecondaryWeapon')}), ${stats(c.id, RANK_NAMES[0])})`,
  )
  RANKS.forEach((rank, k) => {
    const perks = rows.map((r) => r[rank]).filter((p) => p && p !== '0')
    out.push(
      `; ${RANK_NAMES[k + 1].replace('eRank_', '').toLowerCase()}: ${perks.map(titleOf).join(' / ')}`,
      `+SoldierRanks=(AbilitySlots=(${perks.map((p) => slot(abilityFor(p))).join(', ')}), ${stats(c.id, RANK_NAMES[k + 1])})`,
    )
  })
}
writeFileSync(join(mod, 'Config', 'XComClassData.ini'), out.join('\r\n') + '\r\n')

// --- The stand-ins ---------------------------------------------------------------------
writeFileSync(
  join(mod, 'Config', 'XComLWClasses.ini'),
  [
    "; Long War's perks that XCOM 2 has no ability for yet, as passive stand-ins (named, with an",
    '; icon, no effect), generated by scripts/classes-config.mjs. Do not edit by hand.',
    '[LongWarX2.X2Ability_LWStandins]',
    ...[...standins].map(([name, s]) => `+Standins=(Name=${q(name)}, Icon=${q('img:///UILibrary_PerkIcons.' + s.icon)}${realFields(name)})`),
  ].join('\r\n') + '\r\n',
)

// --- The words (the player's machine only) ---------------------------------------------
const clean = (s) => s.replace(/"/g, "'")
const words = [
  "; Long War's own words for its classes' perks, written from the player's install by",
  '; scripts/classes-config.mjs. Not in the repository.',
  ...CLASSES.flatMap((c) => [
    '',
    `[LWS_${c.name} X2SoldierClassTemplate]`,
    `DisplayName=${q(c.name)}`,
    `ClassSummary=${q(`Long War's ${c.name}.`)}`,
    `LeftAbilityTreeTitle=${q('')}`,
    `RightAbilityTreeTitle=${q('')}`,
  ]),
  ...[...standins].flatMap(([name, s]) => {
    const title = clean(titleOf(s.perk))
    const text = clean(fill(locOf('m_strPassiveTxt', s.perk)))
    return ['', `[${name} X2AbilityTemplate]`, `LocFriendlyName=${q(title)}`, `LocLongDescription=${q(text)}`, `LocHelpText=${q(text)}`, `LocPromotionPopupText=${q(text)}`, `LocFlyOverText=${q(title)}`]
  }),
]
writeFileSync(join(mod, 'Localization', 'XComGame.int'), words.join('\r\n') + '\r\n')
const same = new Set(Object.values(SAME))
if (unfilled.size) console.log(`numbers not filled in (no value known): ${[...unfilled].join(', ')}`)
const working = [...standins.keys()].filter((n) => realFields(n))
console.log(`${CLASSES.length} classes; ${[...trees.keys()].filter((k) => CLASSES.some((c) => c.id === k)).length} trees; ${same.size} perks as XCOM 2's own abilities, ${working.length} of Long War's own working (${working.join(', ')}), ${standins.size - working.length} stand-ins; ${[...standins.values()].filter((s) => s.icon !== 'UIPerk_standard').length} with their own icon`)
