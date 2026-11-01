// Long War's words for the mod's classes (features/lw-classes.md, features/playable-build.md):
// the classes' rank names, the stand-in perks' names and descriptions, with the numbers EW fills
// in at run time filled in here. They are Long War's text, so they are written on the player's
// machine from their own Long War install, never committed: by scripts/classes-config.mjs on
// the test machine, by the setup program (tools/setup/) for a player. Which classes and which
// perks is the committed plan (scripts/words-plan.json, written by classes-config.mjs), so the
// words match the shipped config.
import { Package, decompressPackage } from '@innonova/upkit/upk'

/**
 * EW's constants of its tactical rules (XGTacticalGameCoreNativeBase), from its XComGame.upk:
 * each a Const export whose data ends with its value as a string ("192.0f").
 */
export function readConsts(upkBytes) {
  const bytes = decompressPackage(upkBytes)
  const pkg = new Package(bytes)
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  const consts = new Map()
  for (const e of pkg.exports) {
    if (e.type !== 'Const' || !e.fullName.startsWith('XGTacticalGameCoreNativeBase.')) continue
    const end = e.offset + e.size
    // The value: an FString (int32 length with the trailing NUL, then the characters) at the end.
    for (let len = 1; len < e.size - 4; len++) {
      if (v.getInt32(end - len - 4, true) !== len) continue
      const text = new TextDecoder('latin1').decode(bytes.subarray(end - len, end - 1))
      const n = Number(text.replace(/f$/, ''))
      if (Number.isFinite(n)) consts.set(e.name, n)
      break
    }
  }
  return consts
}

/** The words file, from Long War's DefaultGameCore.ini and XComGame.int texts and EW's constants. */
export function makeWords({ plan, core, loc, consts }) {
  const locOf = (key, perk) => loc.match(new RegExp(`^${key}\\[${perk}\\]="(.*)"\\s*$`, 'm'))?.[1] ?? ''
  // Long War reused EW's perk slots under new names; its ini lists the ones not obvious ("; Lock N' Load:  ePerk_Disabled_DEPRECATED").
  const renamed = new Map([...core.matchAll(/^;\s*([^;:\n]+?):?\s+(ePerk_\w+)\s*$/gm)].map((m) => [m[2], m[1].trim()]))
  const titleOf = (perk) => locOf('m_strPassiveTitle', perk) || renamed.get(perk) || perk.replace(/^ePerk_/, '')
  const ini = (key) => {
    const m = core.match(new RegExp(`^${key}=([-\\d.]+)`, 'm'))
    return m ? Number(m[1]) : undefined
  }
  const c = (name, times = 1) => (consts.has(name) ? Math.round(consts.get(name) * times) : undefined)
  const mul = (a, b) => (consts.has(a) && consts.has(b) ? c(a) * c(b) : undefined)
  // EW's text expansion is native; these are the values it shows.
  const TAGS = {
    SmokeBombDefenseBonus: () => c('SMOKE_BOMB_DEFENSE_BONUS'),
    DenseSmokeDefenseBonus: () => c('DENSE_SMOKE_DEFENSE_BONUS'),
    ExecutionerAimBonus: () => c('EXECUTIONER_AIM_BONUS'),
    ExecutionerHealthThreshold: () => c('EXECUTIONER_HP_MIN', 100),
    TacticalSenseDefenseBonusPerEnemy: () => c('TACTICALSENSE_DEFENSE_BONUS'),
    TacticalSenseDefenseBonusMax: () => mul('TACTICALSENSE_DEFENSE_BONUS', 'TACTICALSENSE_MAX_ENEMIES'),
    AggressionCritBonusPerEnemy: () => c('AGGRESSION_CRIT_BONUS'),
    AggressionCritBonusMax: () => mul('AGGRESSION_CRIT_BONUS', 'AGGRESSION_MAX_ENEMIES'),
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
  // Long War's rank names (Private 1st Class … Master Sergeant), rank for rank.
  const rankNames = Array.from({ length: 8 }, (_, k) => [
    loc.match(new RegExp(`^m_aRankNames\\[${k}\\]="(.*)"`, 'm'))?.[1] ?? '',
    loc.match(new RegExp(`^m_aRankAbbr\\[${k}\\]="(.*)"`, 'm'))?.[1] ?? '',
  ]).filter(([n]) => n)
  const q = (s) => `"${s}"`
  const clean = (s) => s.replace(/"/g, "'")
  const lines = [
    "; Long War's own words for its classes and perks, written from the player's Long War",
    '; install (scripts/lw-words.mjs). Not in the repository.',
    ...plan.classes.flatMap((name) => [
      '',
      `[LWS_${name} X2SoldierClassTemplate]`,
      `DisplayName=${q(name)}`,
      `ClassSummary=${q(`Long War's ${name}.`)}`,
      `LeftAbilityTreeTitle=${q('')}`,
      `RightAbilityTreeTitle=${q('')}`,
      ...rankNames.flatMap(([n, abbr], k) => [`RankNames[${k}]=${q(n)}`, `ShortNames[${k}]=${q(abbr)}`]),
    ]),
    ...plan.standins.flatMap(({ name, perk }) => {
      const title = clean(titleOf(perk))
      const text = clean(fill(locOf('m_strPassiveTxt', perk)))
      return ['', `[${name} X2AbilityTemplate]`, `LocFriendlyName=${q(title)}`, `LocLongDescription=${q(text)}`, `LocHelpText=${q(text)}`, `LocPromotionPopupText=${q(text)}`, `LocFlyOverText=${q(title)}`]
    }),
  ]
  return { text: lines.join('\r\n') + '\r\n', unfilled: [...unfilled], perks: plan.standins.length, ranks: rankNames.length }
}
