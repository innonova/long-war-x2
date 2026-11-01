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
import { readConsts, makeWords } from './lw-words.mjs'
import { classCategories, readWeapons, startingKit, weaponTemplate } from './lw-gear.mjs'
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
// Long War's weapons (features/lw-gear.md): who may carry what, and the starting kit.
const ITEM_NAMES = JSON.parse(readFileSync(join(here, '..', '..', 'xcom-ew-lw-tree', 'data', 'enums.json'), 'utf8')).enums.EItemType
const weapons = readWeapons(core, ITEM_NAMES)
const loc = readFileSync(gameInt, 'latin1')

/** The subclasses: Long War's tree ids, its squaddie perk (from the base class's tree), XCOM 2's look. */
/** In War of the Chosen's Skirmish Mode, which XCOM 2 class's weapons a Long War class carries (primary, secondary). */
const SKIRMISH_LIKE = { Sniper: 'Sharpshooter', Scout: 'Sharpshooter', Gunner: 'Grenadier', Assault: 'Ranger' }
const CLASSES = [
  { id: 11, name: 'Sniper', squaddie: 'ePerk_SquadSight', icon: 'class_sharpshooter' },
  { id: 21, name: 'Scout', squaddie: 'ePerk_LightningReflexes', icon: 'class_sharpshooter' },
  { id: 12, name: 'Rocketeer', squaddie: 'ePerk_FireRocket', icon: 'class_grenadier' },
  { id: 22, name: 'Gunner', squaddie: 'ePerk_FocusedSuppression', icon: 'class_grenadier' },
  { id: 13, name: 'Medic', squaddie: 'ePerk_FieldMedic', icon: 'class_specialist' },
  { id: 23, name: 'Engineer', squaddie: 'ePerk_Grenadier', icon: 'class_specialist' },
  { id: 14, name: 'Assault', squaddie: 'ePerk_RunAndGun', icon: 'class_ranger' },
  { id: 24, name: 'Infantry', squaddie: 'ePerk_PlasmaBarrage', icon: 'class_ranger' },
]
/** Each class's starting kit: Long War's (GetInfinitePrimary; a pistol where the class may carry one). */
const LOADOUTS = Object.fromEntries(CLASSES.map((c) => [c.name, startingKit(c.name).map(weaponTemplate)]))
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
  ePerk_FocusedSuppression: 'Suppression', // Long War's Suppression is EW's Focused Suppression slot
  // Reaction shots can crit and lose their penalty; XCOM 2's Cool Under Pressure: can crit and +10 aim (APPROXIMATION).
  ePerk_Opportunist: 'CoolUnderPressure',
}
/** XCOM 2's abilities that work through a weapon: given with it, as XCOM 2's own classes give them (DefaultClassData.ini). */
const WEAPON_SLOT = { LW_SnapShot: 'eInvSlot_PrimaryWeapon', LW_PrecisionShot: 'eInvSlot_PrimaryWeapon', LW_DisablingShot: 'eInvSlot_PrimaryWeapon', InTheZone: 'eInvSlot_PrimaryWeapon', CoveringFire: 'eInvSlot_PrimaryWeapon', RapidFire: 'eInvSlot_PrimaryWeapon', HoloTargeting: 'eInvSlot_PrimaryWeapon', Suppression: 'eInvSlot_PrimaryWeapon' }
const RANKS = ['Corporal1', 'Sergeant1', 'Lieutenant1', 'Captain1', 'Major', 'Colonel1']
const RANK_NAMES = ['eRank_Squaddie', 'eRank_Corporal', 'eRank_Sergeant', 'eRank_Lieutenant', 'eRank_Captain', 'eRank_Major', 'eRank_Colonel']

/** A perk in a class's tree: as abilityFor, but Snap Shot is the sniper classes' shot only (for a Rocketeer it is about rockets). */
function abilityForClass(perk, cls) {
  if (perk !== 'ePerk_SnapShot' || cls.name === 'Sniper' || cls.name === 'Scout') return abilityFor(perk) // the classes that carry sniper and marksman's rifles
  const name = 'LW_SnapShotRocket'
  if (!standins.has(name)) standins.set(name, { perk, icon: 'UIPerk_standard' })
  return name
}

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
const consts = gameUpk ? readConsts(new Uint8Array(readFileSync(gameUpk))) : new Map()
const ini = (key) => {
  const m = core.match(new RegExp(`^${key}=([-\\d.]+)`, 'm'))
  return m ? Number(m[1]) : undefined
}
const c = (name, times = 1) => (consts.has(name) ? Math.round(consts.get(name) * times) : undefined)
// --- Perks to abilities ---------------------------------------------------------------
const standins = new Map() // name -> { perk, icon }
function abilityFor(perk) {
  if (SAME[perk] && x2Abilities.has(SAME[perk])) return SAME[perk]
  const title = titleOf(perk)
  const name = 'LW_' + title.replace(/[^A-Za-z0-9]+/g, ' ').trim().split(' ').map((w) => w[0].toUpperCase() + w.slice(1)).join('')
  if (!standins.has(name)) {
    // By Long War's name; by EW's slot only where Long War kept the perk (a renamed slot's icon is another perk's).
    const names = [title.replace(/[^A-Za-z0-9]/g, ''), ...(renamed.has(perk) ? [] : [perk.replace(/^ePerk_/, '')])]
    const candidates = names.map((c) => `uiperk_${c.toLowerCase()}`)
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
  // The autopsy condition is not modelled yet: +2 with primary weapons against everyone (sidearms' +1 left out).
  LW_VitalPointTargeting: () => ({ Damage: 2, DamageIf: 'Primary' }),
  LW_HEATAmmo: () => ({ DamagePct: 50, DamageIf: 'TargetRobotic' }),
  // Its words: +2 for explosive grenades and rockets, +2 for SAWs' and LMGs' standard and Rapid Fire shots (suppression and Flush not yet).
  LW_Mayhem: () => ({ Damage: 2, DamageIf: 'Explosive', Damage2: 2, Damage2If: 'GunnerShot' }),
  // EW's constants: damage taken less in cover and not flanked; crit damage more on a Run and Gun turn; rockets' radius more (tiles).
  LW_WilltoSurvive: () => ({ DamageTaken: c('WILLTOSURVIVE_DMG_REDUCTION'), DamageTakenIf: 'InCover' }),
  LW_KillerInstinct: () => ({ CritDamagePct: c('KILLERINSTINCT_CRIT_DMG_MULT', 100), CritDamageIf: 'AfterRunAndGun' }),
  LW_DangerZone: () => ({ BonusRadius: c('DANGER_ZONE_RADIUS_BONUS') / 96 }),
  // Free standard shots, once a turn (X2Effect_LWFreeShot).
  LW_HitAndRun: () => ({ FreeShotIf: 'TargetExposed' }),
  LW_CloseEncounters: () => ({ FreeShotIf: 'Within', Param: 6 }),
  LW_LightEmUp: () => ({ FreeShotIf: 'FirstAction', KeepOne: true }),
  // The sniper classes' Snap Shot: a one-action shot at Long War's penalty (the Rocketeer's is another perk: LW_SnapShotRocket).
  LW_SnapShot: () => ({ Kind: 'SnapShot', Aim: consts.has('SNAP_SHOT_AIM_PENALTY') ? -c('SNAP_SHOT_AIM_PENALTY') : undefined }),
  LW_Steadfast: () => ({ ImmuneTo: ['Panic'] }),
  // Active shots with the primary weapon. EW's BuildAbility gives both a cooldown of 5, counted on every side's
  // turn: 2 of the soldier's own (APPROXIMATION). Precision Shot's crit damage grows with the weapon's tech in
  // Long War; its constant (2) is used for every weapon.
  LW_PrecisionShot: () => ({ Kind: 'PrecisionShot', Crit: c('PRECISION_SHOT_CRITICAL_CHANCE_BONUS'), Damage: c('PRECISION_SHOT_DAMAGE_BONUS'), Param: 2 }),
  LW_DisablingShot: () => ({ Kind: 'DisablingShot', Aim: consts.has('DISABLINGSHOT_AIM_PENALTY') ? -c('DISABLINGSHOT_AIM_PENALTY') : undefined, Param: 2 }),
  // "Once per turn, this unit may use a medikit without spending an action."
  LW_Paramedic: () => ({ FreeShotIf: 'Medikit' }),
  // "Medikits restore four more health per use" (and two more charges: X2Effect_LWCharges).
  LW_Savior: () => ({ Heal: c('MEDIKIT_SAVIOR_BONUS') }),
  // "Gain +15 aim against flying targets."
  LW_Deadeye: () => ({ Aim: 15, AimIf: 'TargetFlying' }),
  // "Allows both actions to be used for Standard Shot, Precision Shot, or Disabling Shot, provided no costly actions
  // were taken. <DoubleTapCooldown> turn cooldown."
  LW_DoubleTap: () => ({ FreeShotIf: 'DoubleTap', Param: c('DOUBLETAP_COOLDOWN') }),
  // "If on Overwatch, confers a bonus reaction shot (to a maximum three shots total) for every reaction shot that is a hit."
  LW_RapidReaction: () => ({ FreeShotIf: 'OverwatchHit', Param: 2 }),
  // "If the unit fires without taking any other costly actions, it automatically enters overwatch at the end of its turn."
  LW_ReadyForAnything: () => ({ FreeShotIf: 'ReadyForAnything' }),
  // In the cloud of the soldier's smoke grenades (X2Effect_LWSmoke, added to them: AddSmokeBonuses). Combat Drugs'
  // text says +20 critical chance; its constant (used here) is 10.
  LW_DenseSmoke: () => ({ SmokeDefense: c('DENSE_SMOKE_DEFENSE_BONUS') }),
  LW_CombatDrugs: () => ({ SmokeCrit: c('COMBAT_DRUGS_CRITICAL_CHANCE_BONUS'), SmokeWill: c('COMBAT_DRUGS_WILL_BONUS') }),
  // "Bonus damage on critical hits, with additional bonuses (up to +6) based on how many enemies your squad can see."
  LW_BringEmOn: () => ({ Damage: 1, DamageIf: 'CritPerSquadVisibleEnemy', MaxStacks: 6 }),
}
const realFields = (name) => {
  const f = REAL[name]?.()
  if (!f || Object.values(f).some((v) => v === undefined)) return ''
  return Object.entries(f).map(([k, v]) => `, ${k}=${Array.isArray(v) ? `(${v.join(',')})` : v === true ? 'true' : v}`).join('')
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
]
// The classes' starting kits: the item manager reads GameData (XComGameData.ini), not ClassData.
writeFileSync(
  join(mod, 'Config', 'XComGameData.ini'),
  [
    "; Long War's starting kit for each of its classes (their SquaddieLoadout), generated by scripts/classes-config.mjs",
    '; from scripts/lw-gear.mjs (GetInfinitePrimary). Do not edit by hand.',
    '[XComGame.X2ItemTemplateManager]',
    ...Object.entries(LOADOUTS).map(([n, items]) => `+Loadouts=(LoadoutName=${q('LWS_Squaddie' + n)}, ${items.map((it, k) => `Items[${k}]=(Item=${q(it)})`).join(', ')})`),
    "; Long War's soldiers carry as many grenades and medikits as they have small slots (a charge each): XCOM 2's one-each rule lifted.",
    '-UniqueEquipCategories=grenade',
    '-UniqueEquipCategories=heal',
    "; A recruit costs Long War's SOLDIER_COST on every difficulty (XCOM 2 asks more on Legend).",
    '[XComGame.XComGameState_HeadquartersResistance]',
    ...[0, 1, 2, 3].map((d) => `RecruitSupplyCosts[${d}]=${Number(core.match(/^SOLDIER_COST\s*=\s*(\d+)/m)[1])}`),
  ].join('\r\n') + '\r\n',
)
const decode = (v) => {
  const n = Number(v)
  if (!Number.isFinite(n) || n === 0) return undefined
  const mob = Math.floor(n / 100) % 10
  return { Mobility: mob === 2 ? -1 : mob, Aim: Math.floor(n / 10) % 10, Will: n % 10 }
}
const stats = (id, rank) => {
  const p = progression.get(`${id}:${rank}`) ?? { hp: 0, aim: 0, will: 0 }
  const sq = rank === 'eRank_Squaddie' ? decode((trees.get(id + 4) ?? [])[0]?.Squaddie) : undefined
  const mob = sq?.Mobility ? `, (StatType=eStat_Mobility,StatAmount=${sq.Mobility})` : ''
  return `aStatProgression=((StatType=eStat_HP,StatAmount=${p.hp}), (StatType=eStat_Offense,StatAmount=${p.aim + (sq?.Aim ?? 0)}), (StatType=eStat_Will,StatAmount=${p.will + (sq?.Will ?? 0)})${mob})`
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
    `SquaddieLoadout=${q('LWS_Squaddie' + c.name)}`,
    // Long War's categories (lw-gear.mjs): the weapons the class may carry, by slot.
    ...Object.entries(classCategories(c.name, weapons)).flatMap(([slotType, cats]) =>
      [...cats].map((w) => `+AllowedWeapons=(SlotType=${slotType}, WeaponType=${q(w)})`),
    ),
    '+AllowedArmors="soldier"',
    'bAllowAWCAbilities=0',
    'bHasClassMovie=false',
    'bCanHaveBonds=true',
    'BaseAbilityPointsPerPromotion=3',
    `; squaddie: ${titleOf(c.squaddie)}`,
    `+SoldierRanks=(AbilitySlots=(${slot(abilityForClass(c.squaddie, c), WEAPON_SLOT[abilityForClass(c.squaddie, c)])}` +
      `${startingKit(c.name).includes(2) ? `, ${slot('PistolStandardShot', 'eInvSlot_SecondaryWeapon')}` : ''}), ${stats(c.id, RANK_NAMES[0])})`,
  )
  RANKS.forEach((rank, k) => {
    const perks = rows.map((r) => r[rank]).filter((p) => p && p !== '0')
    out.push(
      `; ${RANK_NAMES[k + 1].replace('eRank_', '').toLowerCase()}: ${perks.map(titleOf).join(' / ')}`,
      `+SoldierRanks=(AbilitySlots=(${perks.map((p) => slot(abilityForClass(p, c), WEAPON_SLOT[abilityForClass(p, c)])).join(', ')}), ${stats(c.id, RANK_NAMES[k + 1])})`,
    )
  })
}
writeFileSync(join(mod, 'Config', 'XComClassData.ini'), out.join('\r\n') + '\r\n')

// --- Long War's stat bonuses for perk choices ---------------------------------------------
// Tree types 15-18 and 25-28 (a class's id + 4): per rank and row, "xyz" = mobility (0, 1, 2 for -1),
// aim, will. The Squaddie column is the same for every row: it goes into the class's Squaddie stats.
const bonusLines = []
for (const c of CLASSES) {
  const rows = trees.get(c.id + 4) ?? []
  rows.forEach((r, branch) => {
    RANKS.forEach((rank, k) => {
      const b = decode(r[rank])
      if (b) bonusLines.push(`+Bonuses=(ClassName=LWS_${c.name}, Rank=${k + 1}, Branch=${branch}, Mobility=${b.Mobility}, Aim=${b.Aim}, Will=${b.Will})`)
    })
  })
}

// --- The stand-ins ---------------------------------------------------------------------
writeFileSync(
  join(mod, 'Config', 'XComLWClasses.ini'),
  [
    "; Long War's perks that XCOM 2 has no ability for yet, as passive stand-ins (named, with an",
    '; icon, no effect), generated by scripts/classes-config.mjs. Do not edit by hand.',
    '[LongWarX2.X2Ability_LWStandins]',
    ...[...standins].map(([name, s]) => `+Standins=(Name=${q(name)}, Icon=${q('img:///UILibrary_PerkIcons.' + s.icon)}${realFields(name)})`),
    '',
    "; War of the Chosen's Skirmish Mode: Long War's classes armed like these XCOM 2 classes (LWX2SkirmishWeapons).",
    '[LongWarX2.LWX2SkirmishWeapons]',
    ...CLASSES.map((c) => `+Arms=(ClassName=LWS_${c.name}, PrimaryLike=${SKIRMISH_LIKE[c.name] ?? 'Specialist'}, SecondaryLike=Sharpshooter)`),
    '',
    "; Long War's stat bonuses for a perk choice, by class, rank and which of the rank's perks (LWX2PerkBonuses).",
    '[LongWarX2.LWX2PerkBonuses]',
    ...bonusLines,
  ].join('\r\n') + '\r\n',
)

// --- The words (the player's machine only) ---------------------------------------------
// Which classes and perks get words: committed, for the setup program to write the same words on a player's machine.
const plan = { classes: CLASSES.map((c) => c.name), standins: [...standins].map(([name, s]) => ({ name, perk: s.perk })) }
writeFileSync(join(here, 'words-plan.json'), JSON.stringify(plan, null, 1) + '\n')
const words = makeWords({ plan, core, loc, consts })
writeFileSync(join(mod, 'Localization', 'XComGame.int'), words.text)
const same = new Set(Object.values(SAME))
if (words.unfilled.length) console.log(`numbers not filled in (no value known): ${words.unfilled.join(', ')}`)
const working = [...standins.keys()].filter((n) => realFields(n))
console.log(`${bonusLines.length} stat bonuses for perk choices`)
console.log(`${CLASSES.length} classes; ${[...trees.keys()].filter((k) => CLASSES.some((c) => c.id === k)).length} trees; ${same.size} perks as XCOM 2's own abilities, ${working.length} of Long War's own working (${working.join(', ')}), ${standins.size - working.length} stand-ins; ${[...standins.values()].filter((s) => s.icon !== 'UIPerk_standard').length} with their own icon`)
