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
    HeadshotCritBonus: () => c('PRECISION_SHOT_CRITICAL_CHANCE_BONUS'),
    // Gene mods (features/lw-genemods.md).
    GeneModPupilsBonus: () => c('GENEMOD_PUPILS_BONUS'),
    RegenPheromoneRegen: () => c('GENEMOD_REGENPHEROMONES'),
    GeneModDepthPerceptionAim: () => c('GENEMOD_DEPTHPERCEPTION_AIM'),
    GeneModDepthPerceptionCrit: () => c('GENEMOD_DEPTHPERCEPTION_CRIT'),
    GeneModBrainDampingWill: () => c('GENEMOD_BRAINDAMPING_WILL'),
    SecondaryHeartBleedTimerBonus: () => c('GENEMOD_SECONDHEART_BLEEDOUT'),
    // Psi powers (features/lw-psi.md): EW's ability table's cooldowns and durations, counted on every side's turn,
    // as the soldier's own turns ((n - 1) / 2), as the mod's abilities count them.
    PsiInspirationWillBonus: () => c('PSIINSPIRED_WILL_BONUS'),
    PsiInspirationDuration: () => 2,
    PsiInspirationCooldown: () => 4,
    PsiPanicCooldown: () => 2,
    MindControlDuration: () => 3,
    MindControlCooldown: () => 5,
    TelekineticFieldCooldown: () => 4,
    RiftCooldown: () => 4,
    TKFieldDefenseBonus: () => c('TELEKINETIC_FIELD_DEFENSE_BONUS'),
    MindMergeCritBonus: () => c('MINDMERGE_CRIT_BONUS'),
    // EW's BuildAbility gives Precision and Disabling Shot a cooldown of 5, counted on every side's turn: the
    // soldier's own turns, as the mod's abilities count them (X2Ability_LWStandins.ActiveShot), 2.
    HeadshotCooldown: () => 2,
    DisablingShotCooldown: () => 2,
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

/** An Unreal .int file's text: UTF-16 (with its byte order mark) or 8-bit. */
export function decodeInt(bytes) {
  if (bytes[0] === 0xff && bytes[1] === 0xfe) return new TextDecoder('utf-16le').decode(bytes.subarray(2))
  return new TextDecoder('latin1').decode(bytes)
}

/**
 * The mod's tech template for a Long War tech (X2StrategyElement_LWTechs.TemplateFor): LWTech_ and the
 * enum's name; Long War's own techs (enum eTech_Placeholder…, keyed by number in its words): LWTech_ and the id.
 */
export const techTemplate = (techEnum, id) => 'LWTech_' + (/Placeholder/.test(techEnum) ? id : techEnum.replace(/^eTech_/, ''))

/**
 * Long War's words for its techs (features/lw-research.md), from its XComStrategyGame.int
 * ([XGLocalizedData] TechTypeNames, TechTypeSummary, TechTypeCodeName, TechTypeReport) as the
 * localization of the mod's tech templates. `techs`: { id, enum } (XComLWResearch.ini). Long War's
 * own techs are keyed by number.
 */
export function makeTechWords({ strategyLoc, techs }) {
  const one = (key, k) => strategyLoc.match(new RegExp(`^${key}\\[${k}\\]="(.*)"\\s*$`, 'm'))?.[1]
  const out = []
  let named = 0
  for (const t of techs) {
    const of = (key) => one(key, t.enum) ?? one(key, t.id)
    const name = of('TechTypeNames')
    if (!name) continue
    named++
    out.push(`[${techTemplate(t.enum, t.id)} X2TechTemplate]`, `DisplayName="${name}"`)
    for (const [field, key] of [['Summary', 'TechTypeSummary'], ['CodeName', 'TechTypeCodeName'], ['LongDescription', 'TechTypeReport']]) {
      const v = of(key)
      if (v) out.push(`${field}="${v}"`)
    }
    out.push('')
  }
  return { text: out.join('\r\n'), named }
}

/** Long War's artifacts the mod has as items of its own (X2Item_LWArtifacts.Artifacts). */
export const ARTIFACTS = ['UFONavigation', 'UFOPowerSource', 'AlienSurgery', 'AlienStasisTank', 'AlienFood', 'AlienEntertainment', 'UFOFusionLauncher', 'PsiLink', 'HyperwaveBeacon', 'Meld', 'WeaponFragment']

/**
 * Long War's words for its artifacts and, in `more`, its corpses (features/lw-loot.md): names from its XComGame.int
 * (m_aItemNames, m_aItemNamesPlural), summaries from its XComStrategyGame.int (ItemTypeSummary).
 */
export function makeItemWords({ loc, strategyLoc, more = [] }) {
  const one = (text, key, k) => text.match(new RegExp(`^${key}\\[${k}\\]="(.*)"\\s*$`, 'm'))?.[1]
  const out = []
  let named = 0
  for (const a of [...ARTIFACTS, ...more.filter((m) => !ARTIFACTS.includes(m))]) {
    const name = one(loc, 'm_aItemNames', `eItem_${a}`)
    if (!name) continue
    named++
    out.push(`[LWItem_${a} X2ItemTemplate]`, `FriendlyName="${name}"`)
    const plural = one(loc, 'm_aItemNamesPlural', `eItem_${a}`)
    if (plural) out.push(`FriendlyNamePlural="${plural}"`)
    const summary = strategyLoc && one(strategyLoc, 'ItemTypeSummary', `eItem_${a}`)
    if (summary) out.push(`BriefSummary="${summary}"`)
    out.push('')
  }
  return { text: out.join('\r\n'), named }
}

/**
 * Long War's words for its soldier weapons (features/lw-gear.md): names from its XComGame.int
 * (m_aItemNames, by enum name or, for Long War's own, by number), summaries from XComStrategyGame.int.
 * `weapons`: { item, enum } (XComLWGear.ini).
 */
export function makeWeaponWords({ loc, strategyLoc, weapons }) {
  const one = (text, key, k) => text.match(new RegExp(`^${key}\\[${k}\\]="(.*)"\\s*$`, 'm'))?.[1]
  const out = []
  let named = 0
  for (const w of weapons) {
    const of = (text, key) => (text ? one(text, key, w.enum) ?? one(text, key, w.item) : undefined)
    const name = of(loc, 'm_aItemNames')
    if (!name) continue
    named++
    out.push(`[LWWeapon_${w.item} X2WeaponTemplate]`, `FriendlyName="${name}"`)
    const plural = of(loc, 'm_aItemNamesPlural')
    if (plural) out.push(`FriendlyNamePlural="${plural}"`)
    const summary = of(strategyLoc, 'ItemTypeSummary')
    if (summary) out.push(`BriefSummary="${summary}"`)
    // The loadout's tactical info: Long War's summary, else a line from the numbers.
    out.push(`TacticalText="${summary ?? `${w.tier} ${w.family}: ${w.damage} damage, ${w.crit}% critical chance, ${w.aim >= 0 ? '+' : ''}${w.aim} aim, ${w.ammo} shots between reloads.`}"`)
    out.push('')
  }
  return { text: out.join('\r\n'), named }
}

/** Long War's armour names (by item number or enum) for the mod's LWArmor_ templates; the summary as its tactical
 * info, else a line from its numbers. */
export function makeArmourWords({ loc, strategyLoc, armours }) {
  const one = (text, key, k) => text.match(new RegExp(`^${key}\\[${k}\\]="(.*)"\\s*$`, 'm'))?.[1]
  const out = []
  let named = 0
  for (const a of armours) {
    const of = (text, key) => (text ? one(text, key, a.enum) ?? one(text, key, a.item) : undefined)
    const name = of(loc, 'm_aItemNames')
    if (!name) continue
    named++
    out.push(`[LWArmor_${a.item} X2ArmorTemplate]`, `FriendlyName="${name}"`)
    const plural = of(loc, 'm_aItemNamesPlural')
    if (plural) out.push(`FriendlyNamePlural="${plural}"`)
    const summary = of(strategyLoc, 'ItemTypeSummary')
    if (summary) out.push(`BriefSummary="${summary}"`)
    out.push(`TacticalText="${summary ?? `+${a.hp} HP, ${a.defense} defense, ${a.mobility} mobility.`}"`)
    out.push('')
  }
  return { text: out.join('\r\n'), named }
}

/** Long War's Foundry projects' names and summaries (FoundryTechNames, FoundryTechSummary, by number or enum) for the
 * templates that carry them (LWFoundry_<id>, X2TechTemplate). */
export function makeFoundryWords({ strategyLoc, projects }) {
  const one = (key, k) => strategyLoc.match(new RegExp(`^${key}\\[${k}\\]="(.*)"\\s*$`, 'm'))?.[1]
  const out = []
  let named = 0
  for (const p of projects) {
    const of = (key) => (p.enum ? one(key, p.enum) : undefined) ?? one(key, p.id)
    const name = of('FoundryTechNames')
    if (!name) continue
    named++
    out.push(`[LWFoundry_${p.id} X2TechTemplate]`, `DisplayName="${name}"`)
    const summary = of('FoundryTechSummary')
    if (summary) out.push(`Summary="${summary}"`)
    out.push('')
  }
  return { text: out.join('\r\n'), named }
}

/** Long War's facility names (m_aFacilityNames, by enum) for the templates that carry them (LWFacility_<id>). */
export function makeFacilityWords({ strategyLoc, facilities }) {
  const out = []
  let named = 0
  for (const f of facilities) {
    const name = strategyLoc.match(new RegExp(`^m_aFacilityNames\\[${f.enum}\\]="(.*)"\\s*$`, 'm'))?.[1]
    if (!name) continue
    named++
    out.push(`[LWFacility_${f.id} X2TechTemplate]`, `DisplayName="${name}"`, '')
  }
  return { text: out.join('\r\n'), named }
}

/** Long War's small items' names (by enum or item number) for the mod's LWSmall_ templates, each under its template class. */
export function makeSmallWords({ loc, strategyLoc, items }) {
  const one = (text, key, k) => text.match(new RegExp(`^${key}\\[${k}\\]="(.*)"\\s*$`, 'm'))?.[1]
  const weaponLook = ['BattleScanner', 'MimicBeacon', 'Medikit', 'RocketLauncher']
  const out = []
  let named = 0
  for (const x of items) {
    const of = (text, key) => (text ? one(text, key, x.enum) ?? one(text, key, x.item) : undefined)
    const name = of(loc, 'm_aItemNames')
    if (!name) continue
    named++
    const cls = x.kind === 'Passive' || x.kind === 'Rocket' ? 'X2EquipmentTemplate' : x.kind === 'Grenade' && !weaponLook.includes(x.look) ? 'X2GrenadeTemplate' : 'X2WeaponTemplate'
    out.push(`[LWSmall_${x.item} ${cls}]`, `FriendlyName="${name}"`)
    const plural = of(loc, 'm_aItemNamesPlural')
    if (plural) out.push(`FriendlyNamePlural="${plural}"`)
    const summary = of(strategyLoc, 'ItemTypeSummary')
    if (summary) out.push(`BriefSummary="${summary}"`, `TacticalText="${summary}"`)
    out.push('')
  }
  return { text: out.join('\r\n'), named }
}
