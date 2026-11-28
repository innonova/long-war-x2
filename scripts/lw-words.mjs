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

/** The mod's alien abilities and the EW perks whose words they take. */
const ALIEN_PERKS = {
  LW_BloodCall: 'ePerk_BloodCall', LW_Repair: 'ePerk_Repair', LW_DeathBlossom: 'ePerk_DeathBlossom', LW_Launch: 'ePerk_Launch',
  LW_Strangle: 'ePerk_SeekerStrangle', LW_StrangleSustained: 'ePerk_SeekerStrangle', LW_SeekerCloak: 'ePerk_SeekerStealth',
  LW_Intimidate: 'ePerk_Intimidate', LW_IntimidateBerserker: 'ePerk_Intimidate', LW_PsiDrain: 'ePerk_PsiDrain',
  // The Drone's Overload; the Berserker's charge and blow, XCOM 2's Berserker's own, as EW's Bull Rush.
  LW_Overload: 'ePerk_Overload', DevastatingPunch: 'ePerk_BullRush',
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
    // XCOM 2's classless soldier as Long War names it: its class (m_aSoldierClassNames[eSC_None]) and ranks ("PFC").
    '',
    '[Rookie X2SoldierClassTemplate]',
    ...(loc.match(/^m_aSoldierClassNames\[eSC_None\]="(.*)"/m) ? [`DisplayName=${q(loc.match(/^m_aSoldierClassNames\[eSC_None\]="(.*)"/m)[1])}`] : []),
    ...rankNames.flatMap(([n, abbr], k) => [`RankNames[${k}]=${q(n)}`, `ShortNames[${k}]=${q(abbr)}`]),
    ...plan.standins.flatMap(({ name, perk }) => {
      const title = clean(titleOf(perk))
      const text = clean(fill(locOf('m_strPassiveTxt', perk)))
      return ['', `[${name} X2AbilityTemplate]`, `LocFriendlyName=${q(title)}`, `LocLongDescription=${q(text)}`, `LocHelpText=${q(text)}`, `LocPromotionPopupText=${q(text)}`, `LocFlyOverText=${q(title)}`]
    }),
    // The aliens' own abilities (X2Ability_LWAliens), named and described as EW's perks for them are: the enemy's info
    // panel and the flyovers show these.
    ...Object.entries(ALIEN_PERKS).flatMap(([name, perk]) => {
      const title = clean(titleOf(perk))
      const text = clean(fill(locOf('m_strPassiveTxt', perk)))
      return ['', `[${name} X2AbilityTemplate]`, `LocFriendlyName=${q(title)}`, `LocLongDescription=${q(text)}`, `LocHelpText=${q(text)}`, `LocFlyOverText=${q(title)}`]
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
  // (XCOM 2's resources Long War keeps, named as EW names them: its elerium is "Elerium", where XCOM 2 says "Elerium
  // Crystals"; the navigation map against EW, 2026-11-25.)
  for (const [x2, ew] of [['EleriumDust', 'Elerium115'], ['AlienAlloy', 'AlienAlloys']]) {
    const name = one(loc, 'm_aItemNames', `eItem_${ew}`)
    if (!name) continue
    named++
    out.push(`[${x2} X2ItemTemplate]`, `FriendlyName="${name}"`)
    const plural = one(loc, 'm_aItemNamesPlural', `eItem_${ew}`)
    if (plural) out.push(`FriendlyNamePlural="${plural}"`)
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

/**
 * Long War's bonuses' words (features/lw-startbonus.md) for the mod's own LongWarX2.int: each type's name and description
 * (ContinentBonusNames, ContinentBonusDesc: <XGParam:IntValue0> stands for its number), and the start screen's labels
 * (XGContinentUI), under the class that reads them ([LWBonuses]).
 */
export function makeBonusWords({ strategyLoc, types }) {
  const one = (key, k) => strategyLoc.match(new RegExp(`^${key}\\[${k}\\]="(.*)"\\s*$`, 'm'))?.[1]
  const label = (key) => strategyLoc.match(new RegExp(`^\\[XGContinentUI\\][^\\[]*?^${key}="([^\\r\\n]*)"\\s*$`, 'ms'))?.[1]
  const out = ['[LWBonuses]']
  let named = 0
  for (const t of types) {
    const name = one('ContinentBonusNames', t)
    if (!name) continue
    named++
    out.push(`Names[${t}]="${name}"`)
    const desc = one('ContinentBonusDesc', t)
    if (desc) out.push(`Descs[${t}]="${desc}"`)
  }
  for (const [ours, theirs] of [['LabelBaseLocation', 'm_strLabelBaseLocation'], ['LabelBegin', 'm_strlabelBeginGame'], ['LabelStarting', 'm_strLabelReturnToContinent'], ['LabelContinentBonus', 'm_strLabelBonus']]) {
    const v = label(theirs)
    if (v !== undefined) out.push(`${ours}="${v}"`)
  }
  out.push('')
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
    // (Its description as EW's chooser shows it: FacilityTypeSummary, its \n a line break.)
    const summary = strategyLoc.match(new RegExp(`^FacilityTypeSummary\\[${f.enum}\\]="(.*)"\\s*$`, 'm'))?.[1]
    out.push(`[LWFacility_${f.id} X2TechTemplate]`, `DisplayName="${name}"`, ...(summary ? [`Summary="${summary}"`] : []), '')
  }
  return { text: out.join('\r\n'), named }
}

/** Long War's small items' names (by enum or item number) for the mod's LWSmall_ templates, each under its template class. */
export function makeSmallWords({ loc, strategyLoc, items }) {
  // (A closing quote may be missing: Long War's own ItemTypeSummary[222], the Motion Tracker's, has none.)
  const one = (text, key, k) => text.match(new RegExp(`^${key}\\[${k}\\]="(.*?)"?\\s*$`, 'm'))?.[1]
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
    // A grenade's throw on the soldier's ability bar, as EW names it (its ability bears the grenade's name, "HE Grenade";
    // XGAbility.GetName), its words the item's: XCOM 2 takes both from the grenade (XComGameState_Ability.GetMyFriendlyName,
    // GetMyHelpText), and without them showed no name and "Missing 'LocHelpText'" (the click tests, 2026-11-23).
    if (cls === 'X2GrenadeTemplate') {
      out.push(`ThrownAbilityName="${name}"`, `LaunchedAbilityName="${name}"`)
      // (EW's help for it, "Does <XGAbility:PossibleDamage/> damage." (HelpMessages[eAbility_<…>Grenade]), its damage put in;
      // else the item's summary.)
      const ability = { eItem_FragGrenade: 'FragGrenade', eItem_AlienGrenade: 'AlienGrenade', eItem_SmokeGrenade: 'SmokeGrenade',
        eItem_GasGrenade: 'GasGrenade', eItem_FlashBang: 'FlashBang', eItem_NeedleGrenade: 'NeedleGrenade', eItem_GhostGrenade: 'GhostGrenade' }[x.enum]
      const ewHelp = ability && loc.match(new RegExp(`^HelpMessages\\[eAbility_${ability}\\]="(.*)"\\s*$`, 'm'))?.[1]
      const help = ewHelp ? ewHelp.replace(/<XGAbility:PossibleDamage\/>/g, String(x.damage ?? '')) : summary
      if (help) out.push(`ThrownAbilityHelpText="${help}"`, `LaunchedAbilityHelpText="${help}"`)
    }
    out.push('')
  }
  // (The Motion Tracker's ability, as EW names it: eAbility_TooCloseForComfort's name, help and the flyover's words.)
  const mt = (k) => loc.match(new RegExp(`^${k}\\[eAbility_TooCloseForComfort\\]="(.*)"\\s*$`, 'm'))?.[1]
  if (mt('AbilityNames'))
    out.push('[LW_MotionTracker X2AbilityTemplate]', `LocFriendlyName="${mt('AbilityNames')}"`, `LocHelpText="${mt('HelpMessages') ?? ''}"`,
      `LocLongDescription="${mt('HelpMessages') ?? ''}"`, `LocFlyOverText="${mt('TargetMessages') ?? mt('AbilityNames')}"`, '')
  return { text: out.join('\r\n'), named }
}

/** The hub's words (UILWEWHub, in the mod's LongWarX2.int): EW's room names as its top menu shows them and its rooms'
 *  menu options with their help lines, from the strategy text (sections XGEngineeringUI, XGResearchUI, XGBarracksUI,
 *  XGHangarUI, XGSituationRoomUI, XGLocalizedData). */
export function makeHubWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const inSection = (section, key) => {
    const at = text.indexOf(`\n[${section}]\n`)
    if (at < 0) return undefined
    const end = text.indexOf('\n[', at + 2)
    const body = text.slice(at, end < 0 ? undefined : end)
    const m = body.match(new RegExp(`^${key.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))
    return m ? m[1].trim().replace(/^"(.*)"$/, '$1') : undefined
  }
  const anywhere = (key) => text.match(new RegExp(`^${key.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const words = [
    ['RoomNames[0]', anywhere('m_aFacilityNamesCaps[eFacility_Research]')],
    ['RoomNames[1]', anywhere('m_aFacilityNamesCaps[eFacility_Engineering]')],
    ['RoomNames[2]', anywhere('m_aFacilityNamesCaps[eFacility_Barracks]')],
    ['RoomNames[3]', anywhere('m_aFacilityNamesCaps[eFacility_Hangar]')],
    ['RoomNames[4]', anywhere('m_aFacilityNamesCaps[eFacility_SitRoom]')],
    ['MissionControlName', anywhere('m_aFacilityNamesCaps[eFacility_MissionControl]')],
    ['GreyMarketTitle', anywhere('m_aFacilityNamesCaps[eFacility_GreyMarket]')],
    ['NewResearch', inSection('XGResearchUI', 'm_strLabelNewProject')],
    ['NewResearchHelp', inSection('XGResearchUI', 'm_strHelpNewProject')],
    ['ChangeResearch', inSection('XGResearchUI', 'm_strLabelChangeProject')],
    ['ChangeResearchHelp', inSection('XGResearchUI', 'm_strHelpChangeProject')],
    ['GeneLab', inSection('XGResearchUI', 'm_strLabelGeneLab')],
    ['GeneLabHelp', inSection('XGResearchUI', 'm_strHelpGeneLab')],
    ['BuildItems', inSection('XGEngineeringUI', 'm_strOptBuildBuy')],
    ['BuildItemsHelp', inSection('XGEngineeringUI', 'm_strHelpBuildBuy')],
    ['BuildFacilities', inSection('XGEngineeringUI', 'm_strOptBuildFacilities')],
    ['BuildFacilitiesHelp', inSection('XGEngineeringUI', 'm_strHelpBuildFacilities')],
    ['Foundry', inSection('XGEngineeringUI', 'm_strOptFoundry')],
    ['Augment', inSection('XGEngineeringUI', 'm_strOptCyberneticsLab')],
    ['AugmentHelp', inSection('XGEngineeringUI', 'm_strHelpCyberneticsLab')],
    ['FoundryHelp', inSection('XGEngineeringUI', 'm_strHelpFoundry')],
    ['RepairBay', inSection('XGEngineeringUI', 'm_strOptManufactureMec')],
    ['RepairBayHelp', inSection('XGEngineeringUI', 'm_strHelpMecManufacture')],
    ['ViewSoldiers', inSection('XGBarracksUI', 'm_strBaseViewNames[eBarracksView_SoldierList]')],
    ['ViewSoldiersHelp', inSection('XGBarracksUI', 'm_strBaseViewHelp[eBarracksView_SoldierList]')],
    ['PsiLabs', inSection('XGBarracksUI', 'm_strBaseViewNames[eBarracksView_PsiLabs]')],
    ['PsiLabsHelp', inSection('XGBarracksUI', 'm_strBaseViewHelp[eBarracksView_PsiLabs]')],
    ['Hire', inSection('XGBarracksUI', 'm_strBaseViewNames[eBarracksView_Hire]')],
    ['HireHelp', inSection('XGBarracksUI', 'm_strBaseViewHelp[eBarracksView_Hire]')],
    ['Memorial', inSection('XGBarracksUI', 'm_strBaseViewNames[eBarracksView_Morgue]')],
    ['MemorialHelp', inSection('XGBarracksUI', 'm_strBaseViewHelp[eBarracksView_Morgue]')],
    ['OTS', inSection('XGBarracksUI', 'm_strBaseViewNames[eBarracksView_OTS]')],
    ['OTSHelp', inSection('XGBarracksUI', 'm_strBaseViewHelp[eBarracksView_OTS]')],
    ['AircraftList', inSection('XGHangarUI', 'm_strHeaderNames[eHangarView_ShipList]')],
    ['AircraftListHelp', inSection('XGHangarUI', 'm_strHeaderHelp[eHangarView_ShipList]')],
    ['SituationRoom', anywhere('m_aFacilityNames[eFacility_SitRoom]')],
    ['GreyMarket', inSection('XGSituationRoomUI', 'm_stdLabelVisitGreyMarket')],
    ['GreyMarketHelp', inSection('XGSituationRoomUI', 'm_stdLabelVisitGreyMarketHelp')],
    ['LaunchSatellite', inSection('XGSituationRoomUI', 'm_strLabelLaunchSatellite')],
    ['LaunchSatelliteHelp', inSection('XGSituationRoomUI', 'm_strLabelMonitorUFO')],
    ['Archives', inSection('XGResearchUI', 'm_strLabelResearchArchives')],
    ['ArchivesHelp', inSection('XGResearchUI', 'm_strHelpResearchArchives')],
    ['Credits', inSection('XGResearchUI', 'm_strLabelCreditArchives')],
    ['CreditsHelp', inSection('XGResearchUI', 'm_strHelpCreditArchives')],
    ['NoProjectsHelp', inSection('XGResearchUI', 'm_strHelpNoProjects')],
    ['Finances', inSection('XGSituationRoomUI', 'm_strLabelViewFinances')],
    ['FinancesHelp', inSection('XGSituationRoomUI', 'm_strLabelViewExpenditures')],
    ['Bonuses', inSection('XGSituationRoomUI', 'm_strLabelCodeDecryption')],
    ['BonusesHelp', inSection('XGSituationRoomUI', 'm_strLabelCodeDecrypted')],
    ['Requests', inSection('XGSituationRoomUI', 'm_strLabelPendingRequests')],
    ['RequestsHelp', inSection('XGSituationRoomUI', 'm_strLabelPendingRequestsHelp')],
    ['CovertOps', inSection('XGSituationRoomUI', 'm_strLabelInfiltratorMode')],
    ['CovertOpsHelp', inSection('XGSituationRoomUI', 'm_strLabelInfiltratorHelp')],
    ['BonusesTitle', inSection('XGSatelliteSitRoomUI', 'm_strLabelSatelliteTitle')],
    ['BonusesBody', inSection('XGSatelliteSitRoomUI', 'm_strLabelSatelliteBody')],
    ['BonusesContinue', inSection('XGSatelliteSitRoomUI', 'm_strLabelContinue')],
  ].filter(([, v]) => v)
  // EW's strategy HUD around the hub (UILWEWStrategyHUD): its resource labels, the research panel, the event list's title.
  const hud = [
    ['ResourceNames[0]', inSection('XGScreenMgr', 'm_aResourceTypeNames[eResource_Money]')],
    ['ResourceNames[1]', inSection('XGScreenMgr', 'm_aResourceTypeNames[eResource_Elerium]')],
    ['ResourceNames[2]', inSection('XGScreenMgr', 'm_aResourceTypeNames[eResource_Alloys]')],
    ['ResourceNames[3]', inSection('XGScreenMgr', 'm_aResourceTypeNames[eResource_Engineers]')],
    ['ResourceNames[4]', inSection('XGScreenMgr', 'm_aResourceTypeNames[eResource_Scientists]')],
    ['ResourceNames[5]', inSection('XGScreenMgr', 'm_aResourceTypeNames[eResource_Power]')],
    ['ResourceNames[6]', inSection('XGScreenMgr', 'm_aResourceTypeNames[eResource_MonthlyNet]')],
    ['ResourceNames[7]', inSection('XGScreenMgr', 'm_aResourceTypeNames[eResource_Meld]')],
    ['CurrentResearch', inSection('XGResearchUI', 'm_strCurrentResearchTitle')],
    ['NoResearch', inSection('XGResearchUI', 'm_strNoCurrentResearchTitle')],
    ['Speeds[0]', inSection('XGFacility_Labs', 'm_arrResearchProgress[eResearchProgress_Fast]')],
    ['Speeds[1]', inSection('XGFacility_Labs', 'm_arrResearchProgress[eResearchProgress_Normal]')],
    ['Speeds[2]', inSection('XGFacility_Labs', 'm_arrResearchProgress[eResearchProgress_Slow]')],
    ['OneDay', inSection('XGFacility_Labs', 'm_strETADay')?.replace('<XGParam:IntValue0/>', '%d')],
    ['ManyDays', inSection('XGFacility_Labs', 'm_strETADays')?.replace('<XGParam:IntValue0/>', '%d')],
    ['NextEvent', anywhere('m_strSingleEventListTitle')],
    ['UpcomingEvents', anywhere('m_strEventListTitle')],
    ['QueueTitle', inSection('XGEngineeringUI', 'm_strProjectsTitle')],
    ['QueueEmpty', inSection('XGEngineeringUI', 'm_strProjectsTitleEmpty')],
    ['EtaLabel', inSection('XGEngineeringUI', 'm_strEtaLabel')],
    ['ProjectLabel', inSection('XGEngineeringUI', 'm_strProjectNameLabel')],
    ['QtyLabel', inSection('XGEngineeringUI', 'm_strQtyLabel')],
    ['FoundryPrefix', inSection('XGEngineeringUI', 'm_strFoundryPrefix')],
    ['EtaHour', inSection('XGFacility_Engineering', 'm_strETAHour')?.replace('<XGParam:IntValue0/>', '%d')],
    ['EtaDay', inSection('XGFacility_Engineering', 'm_strETADay')?.replace('<XGParam:IntValue0/>', '%d')],
    ['DaysTitle', anywhere('m_strDays')],
  ].filter(([, v]) => v)
  // EW's soldier list (UILWEWSoldierList: UISoldierListBase's labels, Long War's statuses from XGStrategySoldier).
  const list = [
    ['Title', inSection('UISoldierListBase', 'm_strSoldierListBaseTitle')],
    ['ClassLabel', inSection('UISoldierListBase', 'm_strSoldierListBaseClassLabel')],
    ['StatusLabel', inSection('UISoldierListBase', 'm_strSoldierListBaseStatusLabel')],
    ['Active', inSection('XGStrategySoldier', 'm_arrSoldierStatus[eStatus_Active]')],
    ['OnMission', inSection('XGStrategySoldier', 'm_arrSoldierStatus[eStatus_OnMission]')],
    ['PsiTesting', inSection('XGStrategySoldier', 'm_arrSoldierStatus[eStatus_PsiTesting]')],
    ['CovertOps', inSection('XGStrategySoldier', 'm_arrSoldierStatus[eStatus_CovertOps]')],
    ['GeneMod', inSection('XGStrategySoldier', 'm_arrSoldierStatus[eStatus_GeneMod]')],
    ['Augmenting', inSection('XGStrategySoldier', 'm_arrSoldierStatus[eStatus_Augmenting]')],
    ['Healing', inSection('XGStrategySoldier', 'm_arrSoldierStatus[eStatus_Healing]')],
    ['Fatigued', inSection('XGStrategySoldier', 'm_arrSoldierStatus[eStatus_Dead]')],
    ['Wounded', inSection('XGStrategySoldier', 'm_strHumanWounded')],
    ['GravelyWounded', inSection('XGStrategySoldier', 'm_strHumanGravelyWounded')],
    ['Dead', inSection('XGStrategySoldier', 'm_strHumanDead')],
  ].filter(([, v]) => v)
  // EW's soldier summary (UILWEWSoldierSummary: XGSoldierUI's menu, the components' labels).
  const summary = [
    ['StatusLabel', inSection('UIStrategyComponent_SoldierInfo', 'm_strStatusLabel')],
    ['MissionsLabel', inSection('UIStrategyComponent_SoldierInfo', 'm_strMissionsLabel')],
    ['KillsLabel', inSection('UIStrategyComponent_SoldierInfo', 'm_strKillsLabel')],
    ['AbilitiesTitle', inSection('UIStrategyComponent_SoldierAbilityList', 'm_strAbilitiesTitle')],
    ['Abilities', inSection('XGSoldierUI', 'm_strLabelAbilities')],
    ['AbilitiesHelp', inSection('XGSoldierUI', 'm_strLabelAbilityHelp')],
    ['PsiAbilities', inSection('XGSoldierUI', 'm_strLabelPsiAbilities')],
    ['PsiAbilitiesHelp', inSection('XGSoldierUI', 'm_strLabelPsiAbilityHelp')],
    ['GeneMods', inSection('XGSoldierUI', 'm_strLabelGeneView')],
    ['GeneModsHelp', inSection('XGSoldierUI', 'm_strLabelGeneViewHelp')],
    ['Loadout', inSection('XGSoldierUI', 'm_strLoadout')],
    ['LoadoutHelp', inSection('XGSoldierUI', 'm_strChooseEquipGoop')],
    ['Customize', inSection('XGSoldierUI', 'm_strLabelCustomize')],
    ['CustomizeHelp', inSection('XGSoldierUI', 'm_strLabelCustomizeHelp')],
    ['Dismiss', inSection('XGSoldierUI', 'm_strLabelDismiss')],
    ['DismissHelp', inSection('XGSoldierUI', 'm_strLabelDismissHelp')],
    ['DismissTitle', inSection('XGSoldierUI', 'm_strDismissSoldierDialogTitle')],
    ['DismissText', inSection('XGSoldierUI', 'm_strDismissSoldierDialogText')],
  ].filter(([, v]) => v)
  // EW's promotion screen (UILWEWSoldierPromotion: UISoldierPromotion's words; the soldier's panels as the summary's).
  const promotion = [
    ...summary.filter(([k]) => ['StatusLabel', 'MissionsLabel', 'KillsLabel'].includes(k)),
    ['Title', inSection('UISoldierPromotion', 'm_strNormalAbilitiesTitle')],
    ['ConfirmTitle', inSection('UISoldierPromotion', 'm_strTitleConfirmPromotion')],
    ['ConfirmText', inSection('UISoldierPromotion', 'm_strConfirmBodyText')],
    ['OKPromote', inSection('UISoldierPromotion', 'm_strOKPromote')],
    ['CancelPromote', inSection('UISoldierPromotion', 'm_strCancelPromote')],
    ['CantTitle', inSection('UISoldierPromotion', 'm_strTitleCannotDoPromotion')],
    ['CantText', inSection('UISoldierPromotion', 'm_strCantConfirmBodyText')],
    ['OKCant', inSection('UISoldierPromotion', 'm_strOKCantPromote')],
  ].filter(([, v]) => v)
  // EW's hiring dialog (UILWEWHiring: UIHiring, XGBarracksUI's hiring view) and its event (XGMissionControlUI).
  const hire = [
    ['Title', inSection('XGBarracksUI', 'm_strBaseViewNames[eBarracksView_Hire]')],
    ['CostLabel', inSection('XGBarracksUI', 'm_strLabelHiringCost')],
    ['CapacityLabel', inSection('XGBarracksUI', 'm_strLabelBarracksCapacity')],
    ['HireLabel', inSection('UIHiring', 'm_strHelpHire')],
    ['NoMoney', inSection('XGBarracksUI', 'm_strErrNoMoneyForSoldiers')],
    ['Full', inSection('XGBarracksUI', 'm_strErrOTRRequired')],
    ['Event', inSection('XGMissionControlUI', 'm_strNewSoldierEvent')],
    ['OrderTitle', inSection('XGHangarUI', 'm_strLabelHireInterceptors')],
    ['OrderCostLabel', inSection('XGHangarUI', 'm_strLabelHireCost')],
    ['MonthlyCostLabel', inSection('XGHangarUI', 'm_strLabelHireMonthlyCost')],
    ['HangarCapacityLabel', inSection('XGHangarUI', 'm_strLabelHangarCap')],
    ['OrderLabel', inSection('UIHiring', 'm_strHelpOrder')],
  ].filter(([, v]) => v)
  return {
    text: ['[UILWEWHub]', ...words.map(([k, v]) => `${k}="${v}"`), '', '[UILWEWStrategyHUD]', ...hud.map(([k, v]) => `${k}="${v}"`), '', '[UILWEWHiring]', ...hire.map(([k, v]) => `${k}="${v}"`), '', '[UILWEWSoldierList]', ...list.map(([k, v]) => `${k}="${v}"`), '', '[UILWEWSoldierSummary]', ...summary.map(([k, v]) => `${k}="${v}"`), '', '[UILWEWSoldierPromotion]', ...promotion.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'),
    named: words.length + hud.length + hire.length + list.length + summary.length,
  }
}

/** The base building screens' words (UILWEWBuildFacilities, UILWEWChooseFacility, in the mod's LongWarX2.int): EW's, from
 *  its strategy text (sections XGBuildUI, UIBuildFacilities, UIChooseFacility). */
export function makeBuildWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const inSection = (section, key) => {
    const at = text.indexOf(`\n[${section}]\n`)
    if (at < 0) return undefined
    const end = text.indexOf('\n[', at + 2)
    const m = text.slice(at, end < 0 ? undefined : end).match(new RegExp(`^${key}=(.*)$`, 'm'))
    return m ? m[1].trim().replace(/^"(.*)"$/, '$1') : undefined
  }
  const words = [
    ['Title', inSection('UIBuildFacilities', 'm_strBuildFacilityTitle')],
    ['Excavate', inSection('XGBuildUI', 'm_strLabelExcavate')],
    ['Excavating', inSection('XGBuildUI', 'm_strLabelExcavating')],
    ['BuildLift', inSection('XGBuildUI', 'm_strLabelBuildLift')],
    ['BuildFacility', inSection('XGBuildUI', 'm_strLabelBuildFacility')],
    ['Steam', inSection('XGBuildUI', 'm_strLabelSteam')],
    ['Days', inSection('XGBuildUI', 'm_strLabelDays')],
    ['Cost', inSection('XGBuildUI', 'm_strLabelCost')],
    ['RequiredBuild', inSection('XGBuildUI', 'm_strLabelRequiredBuild')],
    ['ErrNeedLift', inSection('XGBuildUI', 'm_strErrNeedLift')],
    ['ErrNeedExcavating', inSection('XGBuildUI', 'm_strErrNeedExcavating')],
    ['ErrNeedFunds', inSection('XGBuildUI', 'm_strErrNeedFunds')],
    ['ErrNeedPower', inSection('XGBuildUI', 'm_strErrNeedPower')],
    ['ErrNeedSteam', inSection('XGBuildUI', 'm_strErrNeedSteam')],
    ['NoRequirements', inSection('UIChooseFacility', 'm_strNoReqLabel')],
    // (The chooser's requirements as EW lists them, XGFacility_Engineering.GetFacilityCostSummary.)
    ['CostPower', inSection('XGFacility_Engineering', 'm_strCostPower')],
    ['CostScientists', inSection('XGFacility_Engineering', 'm_strCostScientists')],
    ['CostEngineers', inSection('XGFacility_Engineering', 'm_strCostEngineers')],
    ['CostSoldier', inSection('XGFacility_Engineering', 'm_strCostSoldier')],
    ['CostElerium', inSection('XGFacility_Engineering', 'm_strCostElerium')],
    ['CostAlloys', inSection('XGFacility_Engineering', 'm_strCostAlloys')],
    ['ErrPower', inSection('XGFacility_Engineering', 'm_strErrInsufficientPower')],
    ['ErrScientists', inSection('XGFacility_Engineering', 'm_strErrInsufficientScientists')],
    ['ErrEngineers', inSection('XGFacility_Engineering', 'm_strErrInsufficientEngineers')],
    ['ErrFunds', inSection('XGFacility_Engineering', 'm_strErrInsufficientFunds')],
    ['ErrExperience', inSection('XGFacility_Engineering', 'm_strErrInsufficientExperience')],
    ['BackLabel', inSection('UIChooseFacility', 'm_strBackLabel')],
    // (The chooser's BEGIN BUILD on the help bar, UIChooseFacility.UpdateButtonHelp: XGManufacturingUI's label.)
    ['BeginBuild', inSection('XGManufacturingUI', 'm_strLabelModifyBeginBuild')],
    // Removing a facility (XGBuildUI.UpdateCursor, ConfirmRemovalDialogue): the reasons by LWBase.RemoveBlock's codes.
    ['Remove', inSection('XGBuildUI', 'm_strLabelRemove')],
    ['RemoveTitle', inSection('XGBuildUI', 'm_strRemoveTitle')],
    ['RemoveBody', inSection('XGBuildUI', 'm_strRemoveBody')],
    ['RemoveOK', inSection('XGBuildUI', 'm_strRemoveOK')],
    ['RemoveCancel', inSection('XGBuildUI', 'm_strRemoveCancel')],
    ['CantRemoveTitle', inSection('XGBuildUI', 'm_strCantRemoveTitle')],
    ['OK', inSection('XGBuildUI', 'm_strOk')],
    ['CaptiveRemoveBody', inSection('XGBuildUI', 'm_strCaptiveRemoveBody')],
    ['CantRemove[1]', inSection('XGBuildUI', 'm_strPowerCantRemoveBody')],
    ['CantRemove[2]', inSection('XGBuildUI', 'm_strCaptiveCantRemoveBody')],
    ['CantRemove[3]', inSection('XGBuildUI', 'm_strWorkshopCantRemoveBody')],
    ['CantRemove[4]', inSection('XGBuildUI', 'm_strUplinkCantRemoveBody')],
    ['CantRemove[6]', inSection('XGBuildUI', 'm_strPsiLabsCantRemoveBody')],
    ['CantRemove[7]', inSection('XGBuildUI', 'm_strGeneLabsCantRemoveBody')],
    ['CantRemove[8]', inSection('XGBuildUI', 'm_strCyberneticsLabsCantRemoveBody')],
    ['CantRemove[9]', inSection('XGBuildUI', 'm_strCyberneticsLabsCantRemoveMecs')],
  ].filter(([, v]) => v)
  return { text: ['[UILWEWBuildFacilities]', ...words.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
}

/** The Officer Training School screen's words (UILWEWOTS, in the mod's LongWarX2.int): EW's (XGOTSUI, UIOTS) and Long War's
 *  projects' names and summaries (XGLocalizedData's OTSTechNames, OTSTechSummary), in the order squad sizes I and II, then
 *  the officer projects. */
export function makeOTSWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const inSection = (section, key) => {
    const at = text.indexOf(`\n[${section}]\n`)
    if (at < 0) return undefined
    const end = text.indexOf('\n[', at + 2)
    const m = text.slice(at, end < 0 ? undefined : end).match(new RegExp(`^${key.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))
    return m ? m[1].trim().replace(/^"(.*)"$/, '$1') : undefined
  }
  const anywhere = (key) => text.match(new RegExp(`^${key.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const techs = ['eOTS_SquadSize_I', 'eOTS_SquadSize_II', 'eOTS_XP_II', 'eOTS_HP_I', 'eOTS_Leader', 'eOTS_XP_I', 'eOTS_Will_I']
  const words = [
    ['Title', inSection('XGOTSUI', 'm_strLabelOTS')],
    ['TotalRanks', inSection('UIOTS', 'm_strTactic')],
    ['Cost', inSection('UIOTS', 'm_strCost')],
    ['Purchase', inSection('UIOTS', 'm_strPurchaseButtonText_PC')],
    ['ConfirmTitle', inSection('UIOTS', 'm_strConfirmUpgradeTitle')],
    ['ConfirmBody', inSection('UIOTS', 'm_strConfirmUpgradeBody')],
    ...techs.map((t, i) => [`Names[${i}]`, anywhere(`OTSTechNames[${t}]`)]),
    ...techs.map((t, i) => [`Summaries[${i}]`, anywhere(`OTSTechSummary[${t}]`)]),
  ].filter(([, v]) => v)
  return { text: ['[UILWEWOTS]', ...words.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
}

/** The officers' words (LWOfficers, in the mod's LongWarX2.int): Long War's officer ranks (XGFacility_Barracks.
 *  m_arrMedalNames) from its strategy text, and its officer powers' names and descriptions (their perks' passive title and
 *  text, XComPerkManager) from its game text, the powers in LWOfficers' order. */
export function makeOfficerWords({ strategyLoc, loc }) {
  const strat = strategyLoc.replace(/\r/g, '')
  const game = loc.replace(/\r/g, '')
  const one = (text, key) => text.match(new RegExp(`^${key.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const medals = ['eMedal_UrbanCombat', 'eMedal_Defender', 'eMedal_InternationalService', 'eMedal_Council', 'eMedal_Terra']
  const perks = ['Medal_InternationalA', 'Foundry_AdvancedServomotors', 'Overdrive', 'Medal_UrbanA', 'Medal_TerraB', 'OTS_XP', 'Medal_InternationalB', 'Medal_TerraA', 'ExpandedStorage', 'Medal_CouncilA']
  // (The powers' descriptions keep EW's live numbers as tags, <XGAbility:UrbanDefense/>: LWOfficers fills them.)
  const words = [
    ...medals.map((m, i) => [`RankNames[${i}]`, one(strat, `m_arrMedalNames[${m}]`)]),
    ...medals.map((m, i) => [`RankShort[${i}]`, one(strat, `m_arrMedalNames[${6 + i}]`)]),
    ...perks.map((p, i) => [`PowerNames[${i}]`, one(game, `m_strPassiveTitle[ePerk_${p}]`)]),
    ...perks.map((p, i) => [`PowerDescs[${i}]`, one(game, `m_strPassiveTxt[ePerk_${p}]`)]),
    ['LeadByExample', one(game, 'm_strPassiveTitle[ePerk_OTS_Leader_TheLeader]')],
    ['LeadByExampleDesc', one(game, 'm_strPassiveTxt[ePerk_OTS_Leader_TheLeader]')],
    ['Command', one(game, 'AbilityNames[eAbility_WarCry]')],
    ['CommandDesc', one(game, 'HelpMessages[eAbility_WarCry]')],
  ].filter(([, v]) => v)
  // The promotion screen's words (UILWOfficers), EW's medals screen's (XGMedalsUI).
  const inSection = (section, key) => {
    const at = strat.indexOf(`\n[${section}]\n`)
    if (at < 0) return undefined
    const end = strat.indexOf('\n[', at + 2)
    const m = strat.slice(at, end < 0 ? undefined : end).match(new RegExp(`^${key}=(.*)$`, 'm'))
    return m ? m[1].trim().replace(/^"(.*)"$/, '$1') : undefined
  }
  const screen = [
    ['BilletsTitle', inSection('XGMedalsUI', 'm_strTitleCurrentMedals')],
    ['OpenBillets', inSection('XGMedalsUI', 'm_strMedalMainMenuStatus')],
    ['Locked', inSection('XGMedalsUI', 'm_strMedalMainMenuLocked')],
    ['AssignAbility', inSection('XGMedalsUI', 'm_strTitleAssignPower')],
    ['ConfirmTitle', inSection('XGMedalsUI', 'm_sConfirmAssignMedalTitle')],
    ['ConfirmBody', inSection('XGMedalsUI', 'm_sConfirmAssignMedalBody')],
    ['Promotions', inSection('XGBarracksUI', 'm_strBaseViewNames\\[eBarracksView_Medals\\]')],
    ['PromotionsHelp', inSection('XGBarracksUI', 'm_strBaseViewHelp\\[eBarracksView_Medals\\]')],
  ].filter(([, v]) => v)
  return {
    text: ['[LWOfficers]', ...words.map(([k, v]) => `${k}="${v}"`), '', '[UILWOfficers]', ...screen.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'),
    named: words.length + screen.length,
  }
}

/** EXALT's words (features/lw-exalt.md; UILWEWSituationRoom's covert operations and LWExalt's clues, in the mod's
 *  LongWarX2.int): EW's Situation Room's scan and its labels (UISituationRoom, XGInfiltratorSitRoomUI), and Long War's
 *  clue texts (XGExaltSimulation.m_arrClueText), from its strategy text. */
export function makeExaltWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const inSection = (section, key) => {
    const at = text.indexOf(`\n[${section}]\n`)
    if (at < 0) return undefined
    const end = text.indexOf('\n[', at + 2)
    const m = text.slice(at, end < 0 ? undefined : end).match(new RegExp(`^${key.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))
    return m ? m[1].trim().replace(/^"(.*)"$/, '$1') : undefined
  }
  const sit = ['SweepButton', 'SweepDesc', 'SweepDisabled', 'SweepCantAfford', 'SweepFailed'].map((k) => [k, inSection('UISituationRoom', `m_str${k}`)])
  const inf = [
    ['RuledOut', 'm_strLabelIsRuledOut'], ['AccuseLabel', 'm_strLabelAccuseCountry'], ['RaidLabel', 'm_strLabelBeginRaid'], ['LaunchLabel', 'm_strLabelLaunchMission'],
    ['SweepTitle', 'm_strLabelSweepTitle'], ['SweepBody', 'm_strLabelSweepBody'], ['SweepConfirm', 'm_strLabelSweepConfirm'],
    ['SweepDecline', 'm_strLabelSweepDecline'], ['CluesTitle', 'm_strCluesTitle'], ['CluesNone', 'm_strCluesNoneHelp'],
    ['CluesFew', 'm_strCluesOneOrTwo'], ['CluesEnough', 'm_strCluesThreeOrMore'], ['StatusNoCell', 'm_strStatusNoCell'],
    ['StatusUnknown', 'm_strStatusUnknownStatus'], ['StatusExposed', 'm_strStatusExposedCell'], ['NotScanned', 'm_strHelpWhileNotYetScanned'],
    ['FailTitle', 'm_strResultsFailSubtitle'], ['FailBody', 'm_strResultsFailBody'], ['FailLeftTitle', 'm_strResultsFailAlreadyLeftSubtitle'],
    ['FailLeftBody', 'm_strResultsFailAlreadyLeftBody'], ['SuccessTitle', 'm_strResultsSuccessSubtitle'], ['SuccessBody', 'm_strResultsSuccessBody'],
  ].map(([k, key]) => [k, inSection('XGInfiltratorSitRoomUI', key)])
  // The satellites' view (UILWEWSituationRoom with bSatellite; XGSatelliteSitRoomUI, UISituationRoom's uplinks).
  const sat = [
    ['SatLaunch', 'm_strLabelLaunchSatellite'], ['SatHas', 'm_strLabelHasSatellite'], ['SatNone', 'm_strLabelNoSatellites'],
    ['SatNoCapacity', 'm_strLabelNoCapacity'], ['SatLeft', 'm_strLabelLeftXCom'], ['SatPerMonth', 'm_strLabelPerMonth'],
    ['SatStaff', 'm_strLabelBonus'], ['SatScientist', 'm_strLabelScientist'], ['SatScientists', 'm_strLabelScientists'],
    ['SatEngineer', 'm_strLabelEngineer'], ['SatEngineers', 'm_strLabelEngineers'], ['SatConfirmTitle', 'm_strLabelConfirmLaunch'],
    ['SatCountry', 'm_strLabelCountry'], ['SatFunding', 'm_strLabelFundingIncrease'], ['SatMonitoring', 'm_strLabelMonitoring'],
    ['SatReward', 'm_strLabelReward'], ['SatLaunchLower', 'm_strLabelLaunchSatelliteLower'], ['SatCancelLower', 'm_strLabelCancelSatelliteLower'],
  ].map(([k, key]) => [k, inSection('XGSatelliteSitRoomUI', key)])
  sit.push(['SatAvailable', inSection('UISituationRoom', 'm_strAvailable')], ['SatInOrbit', inSection('UISituationRoom', 'm_strInOrbit')], ...sat)
  const clues = []
  for (let i = 0; i < 40; i++) {
    const v = inSection('XGExaltSimulation', `m_arrClueText[${i}]`)
    if (v) clues.push([`ClueTexts[${i}]`, v])
  }
  const words = [...sit, ...inf, ...clues].filter(([, v]) => v)
  return { text: ['[UILWEWSituationRoom]', ...[...sit, ...inf].filter(([, v]) => v).map(([k, v]) => `${k}="${v}"`), '', '[LWExalt]', ...clues.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
}

/** The Psi Labs' words (UILWPsiLabs, in the mod's LongWarX2.int): EW's (XGPsiLabsUI), from Long War's strategy text. */
export function makePsiWords({ strategyLoc, loc = '' }) {
  const text = strategyLoc.replace(/\r/g, '')
  // (EW's promotion screen in psi mode, UILWEWPsiPromotion: its title, and Long War's psi ranks' names, m_aPsiRankNames
  // 0-4 then m_aPsiRankAbbr 1-3, where Long War put Psion, Master and Volunteer.)
  const game = loc.replace(/\r/g, '')
  const gameOne = (key) => game.match(new RegExp(`^${key.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const promo = (() => { const a = text.indexOf('\n[UISoldierPromotion]\n'); const e = a < 0 ? -1 : text.indexOf('\n[', a + 2); return a < 0 ? '' : text.slice(a, e < 0 ? undefined : e) })()
  const psiTitle = promo.match(/^m_strPsiAbilitiesTitle=(.*)$/m)?.[1].trim().replace(/^"(.*)"$/, '$1')
  const ranks = [0, 1, 2, 3, 4].map((k) => gameOne(`m_aPsiRankNames[${k}]`)).concat([1, 2, 3].map((k) => gameOne(`m_aPsiRankAbbr[${k}]`)))
  const psiPromotion = [
    ...(psiTitle ? [['PsiTitle', psiTitle]] : []),
    ...ranks.map((v, k) => [`PsiRankNames[${k}]`, v ?? '']),
  ]
  const at = text.indexOf('\n[XGPsiLabsUI]\n')
  const end = at < 0 ? -1 : text.indexOf('\n[', at + 2)
  const section = at < 0 ? '' : text.slice(at, end < 0 ? undefined : end)
  const one = (key) => section.match(new RegExp(`^${key}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const words = [
    ['Title', one('m_strPsiLabsPostHelpTitle')], ['Current', one('m_strLabelCurrentTestSubjects')],
    ['Days', one('m_strLabelDays')], ['Empty', one('m_strItemEmpty')],
  ].filter(([, v]) => v)
  return { text: ['[UILWPsiLabs]', ...words.map(([k, v]) => `${k}="${v}"`), '', '[UILWEWPsiPromotion]', ...psiPromotion.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length + psiPromotion.length }
}

/** The Gene Mods screen's words (UILWEWGeneMods, in the mod's LongWarX2.int): Long War's (UISoldierGeneMods, XGSoldierUI,
 *  UIStrategyComponent_SoldierInfo),
 *  from its strategy text. */
export function makeGeneWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const section = (name) => {
    const at = text.indexOf(`\n[${name}]\n`)
    const end = at < 0 ? -1 : text.indexOf('\n[', at + 2)
    return at < 0 ? '' : text.slice(at, end < 0 ? undefined : end)
  }
  const gene = section('UISoldierGeneMods')
  const soldier = section('XGSoldierUI')
  const info = section('UIStrategyComponent_SoldierInfo')
  const one = (sec, key) => sec.match(new RegExp(`^${key.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const words = [
    ['Title', one(gene, 'm_strScreenTitle')], ['ImplantLabel', one(gene, 'm_strImplantActionLabelPC')],
    ['RemoveLabel', one(gene, 'm_strRemoveActionLabelPC')], ['Insufficient', one(gene, 'm_strInsufficientResourcesActionLabel')],
    ['ConfirmTitle', one(gene, 'm_strConfirmNotificationTitle')], ['ConfirmBody', one(gene, 'm_strConfirmNotificationDescription')],
    ['ConfirmBodyRemoved', one(gene, 'm_strConfirmNotificationDescriptionWithRemovedGenes')],
    ['NoTanks', one(gene, 'm_strViewOnlyNotificationNoSlotsDescription')],
    ...[0, 1, 2, 3, 4].map((i) => [`Rows[${i}]`, one(gene, `m_strCategoryTitles[${i}]`)]),
    ['LockedLabel', one(soldier, 'm_strLockedAbilityLabel')], ['LockedDesc', one(soldier, 'm_strLockedGeneModDescription')],
    ['ConfirmButton', one(soldier, 'm_strLabelGeneModConfirm')],
    ['StatusLabel', one(info, 'm_strStatusLabel')], ['MissionsLabel', one(info, 'm_strMissionsLabel')], ['KillsLabel', one(info, 'm_strKillsLabel')],
  ].filter(([, v]) => v)
  return { text: ['[UILWEWGeneMods]', ...words.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
}

/** The council's monthly report's words (UILWEWEndOfMonth, in the mod's LongWarX2.int): EW's (XGWorldReportUI,
 *  UIEndOfMonthReport, UIWorldReport) from Long War's strategy text. Its grades by EGrade's names (A, B, C, D, F). */
export function makeReportWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const sectionOf = (name) => {
    const at = text.indexOf(`\n[${name}]\n`)
    if (at < 0) return ''
    const end = text.indexOf('\n[', at + 2)
    return text.slice(at, end < 0 ? undefined : end)
  }
  const from = (name, key) => sectionOf(name).match(new RegExp(`^${key.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const wr = (key) => from('XGWorldReportUI', key)
  const grades = ['A', 'B', 'C', 'D', 'F']
  const words = [
    ['MonthlyReport', wr('m_strLabelMonthlyReport')], ['FundingAwarded', wr('m_strLabelFundingAwarded')],
    ['MilitaryGrade', wr('m_strLabelMilitaryGrade')], ['XComActivity', wr('m_strLabelXComActivity')],
    ['SpecialistsAwarded', wr('m_strLabelSpecialistsAwarded')], ['NumScientists', wr('m_strNumScientists')],
    ['NumEngineers', wr('m_strNumEngineers')],
    ...grades.map((g, i) => [`GradeNames[${i}]`, wr(`m_arrGradeNames[eGrade_${g}]`)]),
    ['UFOShotDown', wr('m_strLabelUFOShotDown')], ['TerrorStopped', wr('m_strLabelTerrorStopped')],
    ['AbductionsStopped', wr('m_strLabelAbductionsStopped')], ['SatellitesLaunched', wr('m_strLabelSatellitesLaunched')],
    ['ResearchCompleted', wr('m_strLabelResearchCompleted')], ['UFORaided', wr('m_strLabelUFORaided')],
    ['SatellitesLost', wr('m_strLabelSatellitesLost')], ['UFOsEscaped', wr('m_strLabelUFOsEscaped')],
    ['MismanagedResources', wr('m_strLabelMismanagedResources')], ['NoSatelliteCoverage', wr('m_strLabelNoSatelliteCoverage')],
    ['Withdrawn', wr('m_strLabelWithdrawn')], ['BaseAssaulted', wr('m_strLabelBaseAssaulted')], ['FCMissions', wr('m_strLabelFCMissions')],
    ['TerrorFailed', wr('m_strLabelTerrorFailed')], ['TerrorIgnored', wr('m_strLabelTerrorIgnored')],
    ['AbductionsFailed', wr('m_strLabelAbductionsFailed')], ['AbductionsIgnored', wr('m_strLabelAbductionsIgnored')],
    ['LinkStatus', wr('m_strLinkStatus')], ['AndAppend', wr('m_strAndAppend')],
    ['OneWithdrawn', wr('m_strOneWithdrawn')], ['ManyWithdrawn', wr('m_strManyWithdrawn')],
    ['MonthlyReward', from('UIEndOfMonthReport', 'm_strMonthlyReward')], ['CarryOn', from('UIEndOfMonthReport', 'm_strLabelCarryOn')],
    ['Decoded', from('UIWorldReport', 'm_strDecoded')], ['Next', from('UIWorldReport', 'm_strNext')],
  ].filter(([, v]) => v)
  return { text: ['[UILWEWEndOfMonth]', ...words.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
}

/** EW's Mission Control alerts' words (UILWEWAlert), from its [XGMissionControlUI]. */
export function makeAlertWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  // (The section comes more than once in the file: every one of them read.)
  const sections = (name) => {
    const out = []
    for (let at = text.indexOf(`\n[${name}]\n`); at >= 0; at = text.indexOf(`\n[${name}]\n`, at + 2)) {
      const end = text.indexOf('\n[', at + 2)
      out.push(text.slice(at, end < 0 ? undefined : end))
    }
    return out.join('\n')
  }
  const section = sections('XGMissionControlUI')
  if (!section) return { text: '', named: 0 }
  const data = sections('XGLocalizedData')
  const esc = (k) => k.replace(/[[\]]/g, '\\$&')
  const one = (from, key) => from.match(new RegExp(`^${esc(key)}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const mc = (key) => one(section, key)
  const words = [
    ['RadarContact', mc('m_strLabelRadarContact')], ['Contact', mc('m_strLabelContact')], ['Location', mc('m_strLabelLocation')],
    ['UFOClass', mc('m_strLabelUFOClass')], ['Unidentified', mc('m_strLabelUnidentified')], ['Scramble', mc('m_strLabelScrambleInterceptors')],
    ['IgnoreContact', mc('m_strLabelIgnoreContact')], ['SendSkyranger', mc('m_strLabelSendSkyranger')], ['Ignore', mc('m_strLabelIgnore')],
    ['CrashSite', mc('m_strLabelUFOCrashSite')], ['HasLanded', mc('m_strLabelUFOHasLanded')],
    ['AbductionsReported', mc('m_strLabelAbductionsReported')], ['ViewAbductionSites', mc('m_strLabelViewAbductionSites')],
    ['TerrorCity', mc('m_strLabelTerrorCity')], ['PanicLevel', mc('m_strLabelPanicLevel')], ['Difficulty', mc('m_strLabelDifficulty')],
    ...['Easy', 'Moderate', 'Hard', 'VeryHard'].map((d, i) => [`DifficultyNames[${i}]`, one(data, `MissionDifficultyNames[eMissionDiff_${d}]`)]),
    ['FCMission', mc('m_strLabelFCMission')], ['AbductionSites', mc('m_strLabelAbductionSites')], ['Reward', mc('m_strLabelReward')],
    ['Confirm', one(sections('UIMissionControl_AbductionSelection'), 'm_strConfirmLabel')],
    ['UFOPrefix', mc('m_strLabelUFOPrefix')], ['SizeLabel', mc('m_strLabelSize')], ['ObjectiveLabel', mc('m_strLabelAlienObjective')],
    ['HyperwaveTitle', one(sections('UIMissionControl_UFOAlert'), 'm_strHyperwavePanelTitle')],
    ['ResearchCompleteSub', one(sections('UIMissionControl_ScienceAlert'), 'm_strResearchCompleteSubTitle')],
    ['ResearchComplete', mc('m_strLabelTechResearchComplete')], ['AssignResearch', mc('m_strLabelAssignNewResearch')], ['CarryOn', mc('m_strLabelCarryOn')],
    ...['Small', 'Medium', 'Large', 'VeryLarge'].map((k, i) => [`SizeNames[${i}]`, one(sections('XGItemTree'), `m_strSize${k}`)]),
    // (EW's altitudes begin with a space, " (NOE)": kept, as EW appends them to the country.)
    ...['Low', 'High', 'VeryHigh'].map((k, i) => [`AltitudeNames[${i}]`, one(sections('XGShip_UFO'), `m_strAltitude${k}`)]),
    ...Array.from({ length: 11 }, (_, i) => [`ObjectiveNames[${i}]`, one(sections('XGStrategyAI'), `m_arrObjectiveNames[${i}]`)]),
    ['LaunchStances', one(sections('XGInterceptionUI'), 'm_strLabelLaunchFightersPC')], ['Kills', one(sections('XGInterceptionUI'), 'm_strLabelMaxSpeed')],
    ['ValueHours', one(sections('XGShip_Interceptor'), 'm_strValueHours')], ['ValueDays', one(sections('XGShip_Interceptor'), 'm_strValueDays')],
    ...['Ready', 'OnMission', 'Refuelling', 'Damaged', 'Repairing', 'Destroyed', 'Transfer', 'Rearming'].map((k, i) => [`StatusNames[${i}]`, one(data, `ShipStatusNames[eShipStatus_${k}]`)]),
    // Mission Control's list (UILWEWMissionControl).
    ['MissionsTitle', one(sections('UIMissionControl_MissionList'), 'm_strMissionListTitle')], ['ScanForActivity', mc('m_strLabelScanUFO')],
    ['HoursLeft', mc('m_strLabelHours')],
    ...[['TitleAbductions', 'Abduction'], ['TitleTerror', 'Terror'], ['TitleCrash', 'UFOCrash'], ['TitleLanded', 'UFOLanded'],
      ['TitleAlienBase', 'AlienBase'], ['TitleTempleShip', 'TempleShip'], ['TitleHQ', 'HQAssault'], ['TitleCovertExtraction', 'CovertOpsExtraction'],
      ['TitleDataRecovery', 'CaptureAndHold'], ['TitleExaltRaid', 'ExaltRaid']].map(([k, m]) => [k, one(sections(`XGMission_${m}`), 'm_strTitle')]),
    // Each mission's situation, by Long War's kind of mission sent (XComGameState_LWStrategy.PendingKind), for the drop-ship
    // briefing (UILWDropShipBriefing).
    ...[[1, 'UFOCrash'], [2, 'UFOLanded'], [3, 'Abduction'], [4, 'Terror'], [5, 'AlienBase'], [6, 'TempleShip'], [7, 'HQAssault'],
      [9, 'ExaltRaid']].map(([k, m]) => [`Situations[${k}]`, one(sections(`XGMission_${m}`), 'm_strSituation')]),
    ['AssaultAlienBase', mc('m_strLabelAssaultAlienBase')], ['AssaultTempleShip', mc('m_strLabelAssaultTempleShip')],
    ['TempleShipText', mc('m_strLabelTempleShip')], ['Assault', mc('m_strLabelAssault')], ['Wait', mc('m_strlabelWait')],
    ['ExaltTitle', mc('m_strLabelExaltAlertTitle')], ['ExaltBody', mc('m_strLabelExaltAlertBody')],
    ['ExaltSend', mc('m_strLabelExaltAlertSendSquad')], ['ExaltNotNow', mc('m_strLabelExaltAlertNotNow')],
    // EW's notices (features/ew-notices.md).
    ['NoticeItemBuilt', mc('m_strLabelItemBuilt')], ['NoticeExcavation', mc('m_strLabelExcavationComplete')],
    ['NoticeFacilityRemoved', mc('m_strLabelFacilityRemoved')], ['NoticeNewSoldiers', mc('m_strLabelNewSoldiers')],
    ['NoticeInterceptorArrival', mc('m_strLabelNewInterceptorArrival')], ['NoticeShipOnline', mc('m_strLabelShipOnline')],
    ['NoticeShipTransfer', mc('m_strLabelShipTransferArrival')], ['NoticeSatOnline', mc('m_strLabelSatOnline')],
    ['NoticeRequestExpired', mc('m_strLabelFCRequestExpired')],
  ].filter(([, v]) => v)
  return { text: ['[UILWEWAlert]', ...words.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
}

/** EW's council request screen's words (UILWEWCouncilRequest, from [XGPendingRequestsUI] and XGFundingCouncil's request
 *  intros), and the council countries' names in EW's forms (with the article, the adjective, the possessive) for the
 *  intros' <XGCountry:…/> tags, by the mod's country order (countryIds: XComLWStrategy.ini's +Countries Id, EW's
 *  eCountry_<Id>). */
export function makeRequestWords({ strategyLoc, countryIds }) {
  const text = strategyLoc.replace(/\r/g, '')
  const sections = (name) => {
    const out = []
    for (let at = text.indexOf(`\n[${name}]\n`); at >= 0; at = text.indexOf(`\n[${name}]\n`, at + 2)) {
      const end = text.indexOf('\n[', at + 2)
      out.push(text.slice(at, end < 0 ? undefined : end))
    }
    return out.join('\n')
  }
  const esc = (k) => k.replace(/[[\]]/g, '\\$&')
  const one = (from, key) => from.match(new RegExp(`^${esc(key)}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const ui = sections('XGPendingRequestsUI')
  if (!ui) return { text: '', named: 0 }
  const council = sections('XGFundingCouncil')
  const data = sections('XGLocalizedData')
  const words = [
    ['TitleLabel', 'm_strTitleLabel'], ['Requested', 'm_strLabelRequested'], ['ValueRequested', 'm_strValueRequested'],
    ['InStorage', 'm_strLabelInStorage'], ['TimeLimit', 'm_strLabelTimeLimit'], ['TimeLimitDays', 'm_strTimeLimitDays'],
    ['RewardsLabel', 'm_strLabelRewards'], ['SellItems', 'm_strLabelSellItems'], ['NotNow', 'm_strLabelIgnoreRequest'],
    ['NumPanic', 'm_strNumCodePieces'], ['NumEngineers', 'm_strNumEngineers'], ['NumScientists', 'm_strNumScientist'], ['NewRecruit', 'm_strNewRecruit'],
  ].map(([k, key]) => [k, one(ui, key)])
  for (let i = 0; i < 42; i++) words.push([`Intro[${i}]`, one(council, `m_strRequestIntro[${i}]`)])
  countryIds.forEach((id, k) => {
    words.push([`ArticleUpper[${k}]`, one(data, `CountryNamesWithArticle[eCountry_${id}]`)])
    words.push([`ArticleLower[${k}]`, one(data, `CountryNamesWithArticleLower[eCountry_${id}]`)])
    words.push([`Adjective[${k}]`, one(data, `CountryAdjective[eCountry_${id}]`)])
    words.push([`Possessive[${k}]`, one(data, `CountryPossessive[eCountry_${id}]`)])
  })
  const found = words.filter(([, v]) => v)
  return { text: ['[UILWEWCouncilRequest]', ...found.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: found.length }
}

/** The Situation Room's news ticker (features/ew-sitroom-ticker.md): EW's headlines ([XGFacility_SituationRoom] Ticker*, the
 *  title [UISituationRoom] m_strTickerTitle) as one list, each line its family and its text: "Panic:<country id>:<level>",
 *  "Ambient:<act>", "AbductionWon" …, "Narrative:<name>"; read by LWTicker. */
export function makeTickerWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const at = text.indexOf('\n[XGFacility_SituationRoom]')
  if (at < 0) return { text: '', named: 0 }
  const end = text.indexOf('\n[', at + 2)
  const body = text.slice(at, end < 0 ? undefined : end)
  const lines = []
  for (const m of body.matchAll(/^Ticker(\w+?)\[(\w+)\]="(.*)"\s*$/gm)) {
    const [, name, index, value] = m
    let family = name
    const panic = /^(\w+)Panic(\d)$/.exec(name)
    const ambient = /^AmbientAct(\d)$/.exec(name)
    if (panic) family = `Panic:${panic[1]}:${panic[2]}`
    else if (ambient) family = `Ambient:${ambient[1]}`
    else if (name === 'Narratives') family = `Narrative:${index.replace(/^eTickerNarrative_/, '')}`
    lines.push(`Lines[${lines.length}]="${family}|${value}"`)
  }
  // The council's (XGFundingCouncil: a request met or ignored, by its number; a council mission won, failed or ignored, by
  // its EFCMission name): "Request:<n>:Success" …, "Mission:<eFCM_…>:Fail" ….
  for (const m of text.matchAll(/^m_strRequest(Success|Ignore)\[(\d+)\]="(.*)"\s*$/gm)) lines.push(`Lines[${lines.length}]="Request:${m[2]}:${m[1]}|${m[3]}"`)
  for (const m of text.matchAll(/^m_strMission(Success|Fail|Ignore)\[(eFCM_\w+)\]="(.*)"\s*$/gm)) lines.push(`Lines[${lines.length}]="Mission:${m[2]}:${m[1]}|${m[3]}"`)
  const title = text.match(/^\[UISituationRoom\][\s\S]*?^m_strTickerTitle=(.*)$/m)?.[1]?.trim().replace(/^"(.*)"$/, '$1')
  return { text: ['[LWTicker]', ...(title ? [`Title="${title}"`] : []), ...lines, ''].join('\r\n'), named: lines.length }
}

/** The Situation Room's objectives (features/ew-sitroom-ticker.md): EW's story objectives and their steps, by name
 *  ("Obj|CaptureAlien|…", "Sub|BuildAlienContainment|…", "Deep|…"), and [XGSituationRoomUI]'s labels; read by LWObjectives. */
export function makeObjectiveWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const lines = []
  for (const m of text.matchAll(/^(GameObjectiveNames|SubObjectiveNames|SubObjectiveInDepth)\[e(?:Sub)?Obj_(\w+)\]="(.*)"\s*$/gm)) {
    const kind = m[1] === 'GameObjectiveNames' ? 'Obj' : m[1] === 'SubObjectiveNames' ? 'Sub' : 'Deep'
    lines.push(`Lines[${lines.length}]="${kind}|${m[2]}|${m[3]}"`)
  }
  const at = text.indexOf('\n[XGSituationRoomUI]')
  const ui = at < 0 ? '' : text.slice(at, text.indexOf('\n[', at + 2))
  const one = (k) => ui.match(new RegExp(`^${k}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const at2 = text.indexOf('\n[UIObjectivesScreen]')
  const screen = at2 < 0 ? '' : text.slice(at2, text.indexOf('\n[', at2 + 2))
  const two = (k) => screen.match(new RegExp(`^${k}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const words = [['Title', one('m_strLabelObjectives')], ['Complete', one('m_strComplete')], ['InProgress', one('m_strInProgress')],
    ['Header', two('m_strObjectives')], ['MoreInfo', two('m_strMoreInfo')], ['Back', two('m_strBack')]].filter(([, v]) => v)
  return { text: ['[LWObjectives]', ...words.map(([k, v]) => `${k}="${v}"`), ...lines, ''].join('\r\n'), named: lines.length }
}

/** XCOM 2's new-campaign screen (UIShellDifficulty) in Long War's words: its difficulties' names and texts (Long War's
 *  own [UIShellDifficulty], the same fields: Normal, Classic, Brutal, Impossible, which the port's four are), and Long War's
 *  second-wave options (features/lw-second-wave.md; XComUI.ini sets the screen's list to Long War's 31 in its order): each
 *  option's line its title ("Damage Roulette (#0)"), its text the description shown under the list, by the number Long War's
 *  title carries ([UIGameplayToggles]). */
export function makeSecondWaveWords({ loc }) {
  const text = loc.replace(/\r/g, '')
  const titles = new Map()
  const descs = new Map()
  for (const m of text.matchAll(/^m_arrGameplayToggleTitle\[([^\]]+)\]="(.*)"\s*$/gm)) titles.set(m[1], m[2])
  for (const m of text.matchAll(/^m_arrGameplayToggleDesc\[([^\]]+)\]="(.*)"\s*$/gm)) descs.set(m[1], m[2])
  const lines = []
  let options = 0
  for (const [key, title] of titles) {
    const n = title.match(/\(#(\d+)\)/)?.[1]
    if (n === undefined) continue
    lines.push(`SecondWaveDescriptions[${n}]="${title}"`)
    lines.push(`SecondWaveTooltips[${n}]="${descs.get(key) ?? ''}"`)
    options++
  }
  // (EW's new-game choices kept with the campaign, XComUI.ini's LWX2_EWNoProgeny and LWX2_EWNoSlingshot: not shown, EW's
  // screen stands over XCOM 2's, but XCOM 2 wants a description for each option.)
  for (const [n, key] of [[31, 'm_strDifficultyEnableProgeny'], [32, 'm_strDifficultyEnableSlingshot']]) {
    const label = text.match(new RegExp(`^${key}="(.*)"\\s*$`, 'm'))?.[1] ?? ''
    lines.push(`SecondWaveDescriptions[${n}]="${label} (off)"`)
    lines.push(`SecondWaveTooltips[${n}]=""`)
  }
  let difficulties = 0
  for (const m of text.matchAll(/^(m_arrDifficultyTypeStrings|m_arrDifficultyDescStrings)\[([0-3])\]="(.*)"\s*$/gm)) {
    lines.push(`${m[1]}[${m[2]}]="${m[3]}"`)
    if (m[1] === 'm_arrDifficultyTypeStrings') difficulties++
  }
  return { text: lines.length ? ['[UIShellDifficulty]', ...lines, ''].join('\r\n') : '', named: options, difficulties }
}

/**
 * EW's game creation screens (UILWEWDifficulty, UILWEWSecondWave: EW's own movies, driven as EW drives them): EW's
 * [UIShellDifficulty] and [UIGameplayToggles] sections of the player's XComGame.int, Long War's words, under the mod's
 * classes, as they are.
 */
export function makeShellWords({ loc }) {
  return copySections(loc, [['UIShellDifficulty', 'UILWEWDifficulty'], ['UIGameplayToggles', 'UILWEWSecondWave']])
}

/** EW's main menu (UILWEWMainMenu): its [UIFinalShell] section of the player's XComUIShell.int, under the mod's class. */
export function makeMainMenuWords({ shellLoc }) {
  // (Its Load and Options are its base class's, [UIShell]: both under the one section.)
  const r = copySections(shellLoc, [['UIFinalShell', 'UILWEWMainMenu'], ['UIShell', 'UILWEWMainMenu']])
  const lines = r.text.split('\r\n')
  return { text: lines.filter((l, i) => l !== '[UILWEWMainMenu]' || lines.indexOf(l) === i).join('\r\n'), named: r.named }
}

/** EW's memorial (UILWEWMemorial): its [UIMemorial] section of the strategy text, under the mod's class. */
/** Long War's words for its labs on EW's lab screen (UILWEWPsiLabs, UILWEWGeneLab, UILWEWCyberneticsLab: XGPsiLabsUI,
 *  XGGeneLabUI, XGCyberneticsUI; UISoldierSlots' STATUS). */
export function makeLabWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const section = (name) => text.match(new RegExp(`^\\[${name}\\]\\n([\\s\\S]*?)(?=^\\[|(?![\\s\\S]))`, 'm'))?.[1] ?? ''
  const key = (sec, k) => section(sec).match(new RegExp(`^${k.replace(/[\[\]]/g, '\\$&')}=(.*)$`, 'm'))?.[1]?.trim().replace(/^"(.*)"$/, '$1') ?? ''
  const status = key('UISoldierSlots', 'm_strSoldierSlotBaseStatusLabel')
  const labs = [
    ['UILWEWPsiLabs', 'XGPsiLabsUI', [['Title', 'm_strLabelCurrentTestSubjects'], ['Empty', 'm_strItemEmpty'], ['AddSoldier', 'm_strLabelAddSoldier'], ['RemoveSoldier', 'm_strLabelRemoveSoldier'], ['Days', 'm_strLabelDays'], ['Hours', 'm_strLabelHours'], ['RemoveTitle', 'm_strConfirmRemovalDialogTitle'], ['RemoveText', 'm_strConfirmRemovalDialogText'], ['RemoveAccept', 'm_strConfirmRemovalDialogAcceptText']]],
    ['UILWEWGeneLab', 'XGGeneLabUI', [['Title', 'm_strLabelCurrentPatients'], ['Empty', 'm_strLabelEmpty'], ['AddSoldier', 'm_strLabelAddSoldier'], ['Days', 'm_strLabelDays'], ['Hours', 'm_strLabelHours']]],
    ['UILWEWCyberneticsLab', 'XGCyberneticsUI', [['Title', 'm_strLabelCurrentPatients'], ['Empty', 'm_strLabelEmpty'], ['AddSoldier', 'm_strLabelAddSoldier'], ['Days', 'm_strLabelDays'], ['Hours', 'm_strLabelHours']]],
  ]
  const out = []
  let named = 0
  for (const [to, from, keys] of labs) {
    const lines = [...(status ? [['StatusLabel', status]] : []), ...keys.map(([k, ew]) => [k, key(from, ew)])].filter(([, v]) => v)
    named += lines.length
    out.push(`[${to}]`, ...lines.map(([k, v]) => `${k}="${v.replace(/"/g, "'")}"`), '')
  }
  return { text: out.join('\r\n'), named }
}

/** EW's manufacture dialog's words (UILWEWManufacturing: XGManufacturingUI's labels, XGFacility_Engineering's ETA). */
export function makeManufactureWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const section = (name) => text.match(new RegExp(`^\\[${name}\\]\\n([\\s\\S]*?)(?=^\\[|(?![\\s\\S]))`, 'm'))?.[1] ?? ''
  const key = (sec, k) => section(sec).match(new RegExp(`^${k}\\s*=(.*)$`, 'm'))?.[1]?.trim().replace(/^"(.*)"$/, '$1') ?? ''
  const words = [
    ['Duration', key('XGManufacturingUI', 'm_strLabelProjectDuration')],
    ['Immediate', key('XGManufacturingUI', 'm_strLabelImmediate')],
    ['Requirements', key('XGManufacturingUI', 'm_strLabelProjectCost')],
    ['EngineersNeeded', key('XGManufacturingUI', 'm_strLabelEngineersAssigned')],
    ['QuantityLabel', key('XGManufacturingUI', 'm_strLabelQuantity')],
    ['Notes', key('XGManufacturingUI', 'm_strLabelNotes')],
    ['CostHelp', key('XGManufacturingUI', 'm_strHelp')],
    ['SubmitOrder', key('XGManufacturingUI', 'm_strLabelSubmitOrder')],
    ['BeginProject', key('XGManufacturingUI', 'm_strLabelBeginProject')],
    ['BackLabel', key('XGManufacturingUI', 'm_strBackLabel')],
    ['ErrEngineers', key('XGManufacturingUI', 'm_strErrEngineers')],
    ['ETADay', key('XGFacility_Engineering', 'm_strETADay')],
    ['ETAHour', key('XGFacility_Engineering', 'm_strETAHour')],
    // (A facility's dialog, XGManufacturingUI.UpdateManufactureFacility.)
    ['TimeToBuild', key('XGManufacturingUI', 'm_strLabelTimeToBuild')],
    ['ETADays', key('XGManufacturingUI', 'm_strETADays')],
    ['NoteMaintenance', key('XGManufacturingUI', 'm_strNoteMaintenanceCost')],
    ['BeginBuild', key('XGManufacturingUI', 'm_strLabelModifyBeginBuild')],
  ].filter(([, v]) => v)
  return { text: ['[UILWEWManufacturing]', ...words.map(([k, v]) => `${k}="${v.replace(/"/g, "'")}"`), ''].join('\r\n'), named: words.length }
}

/** EW's operation names (LWOpNames: XGMission's two word lists, its "Operation …" and the story missions' own). */
export function makeOpNameWords({ strategyLoc }) {
  return copySections(strategyLoc, [['XGMission', 'LWOpNames']])
}

/** EW's research screens (UILWEWResearch: UIChooseTech, XGResearchUI, XGFacility_Labs, XGLocalizedData's research credits;
 *  UILWEWScienceLabs: UIScienceLabs and XGResearchUI's report). */
export function makeResearchWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const section = (name) => text.match(new RegExp(`^\\[${name}\\]\\n([\\s\\S]*?)(?=^\\[|(?![\\s\\S]))`, 'm'))?.[1] ?? ''
  const key = (sec, k) => section(sec).match(new RegExp(`^${k.replace(/[[\]]/g, '\\$&')}\\s*=(.*)$`, 'm'))?.[1]?.trim().replace(/^"(.*)"$/, '$1') ?? ''
  const credits = ['', 'Weapons_I', 'PlasmaWeapons', 'AllWeapons', 'Armor_I', 'AllArmor', 'UFOTech', 'Flight', 'Psionics', 'AllTech']
  const research = [
    ['Title', key('UIChooseTech', 'm_strScienceTechSelectTitle')],
    ['CreditTitle', key('UIChooseTech', 'm_strCreditArchiveTitle')],
    ['Confirm', key('UIChooseTech', 'm_strConfirm')],
    ['Priority', key('XGResearchUI', 'm_strLabelPriority')],
    ['CostLabel', key('XGResearchUI', 'm_strCostLabel')],
    ['CreditApplies', key('XGResearchUI', 'm_strResearchCreditApplies')],
    ['ETAInstant', key('XGFacility_Labs', 'm_strETAInstant')],
    ['ETADay', key('XGFacility_Labs', 'm_strETADay')],
    ['ETADays', key('XGFacility_Labs', 'm_strETADays')],
    ['CostAmount', key('XGFacility_Labs', 'm_strCostLabel')],
    ['CostElerium', key('XGFacility_Labs', 'm_strCostElerium')],
    ['CostAlloys', key('XGFacility_Labs', 'm_strCostAlloys')],
    ['ErrFunds', key('XGFacility_Labs', 'm_strErrInsufficientFunds')],
    ['ErrElerium', key('XGFacility_Labs', 'm_strErrInsufficientElerium')],
    ['ErrAlloys', key('XGFacility_Labs', 'm_strErrInsufficientAlloys')],
    ['ErrResources', key('XGFacility_Labs', 'm_strErrInsufficientResources')],
    ['Progress[0]', key('XGFacility_Labs', 'm_arrResearchProgress[eResearchProgress_Fast]')],
    ['Progress[1]', key('XGFacility_Labs', 'm_arrResearchProgress[eResearchProgress_Normal]')],
    ['Progress[2]', key('XGFacility_Labs', 'm_arrResearchProgress[eResearchProgress_Slow]')],
    ...credits.flatMap((c, i) => (c ? [[`CreditNames[${i}]`, key('XGLocalizedData', `ResearchCreditNames[eResearchCredit_${c}]`)], [`CreditSummary[${i}]`, key('XGLocalizedData', `ResearchCreditSummary[eResearchCredit_${c}]`)]] : [])),
  ].filter(([, v]) => v)
  const labs = [
    ['m_strScienceLabsArchiveTitle', key('UIScienceLabs', 'm_strScienceLabsArchiveTitle')],
    ['m_strScienceLabsReportTitle', key('UIScienceLabs', 'm_strScienceLabsReportTitle')],
    ['m_strTopSecret', key('UIScienceLabs', 'm_strTopSecret')],
    ['ReportTitle', key('XGResearchUI', 'm_strLabelResearchReport')],
    ['CodeName', key('XGResearchUI', 'm_strLabelCodeName')],
    ['FacilityAvailable', key('XGResearchUI', 'm_strFacilityBuildAvailable')],
    ['ItemAvailable', key('XGResearchUI', 'm_strItemBuildAvailable')],
    ['GeneModAvailable', key('XGResearchUI', 'm_strGeneModAvailable')],
    ['FoundryAvailable', key('XGResearchUI', 'm_strFoundryBuildAvailable')],
    ['CreditEarned', key('XGResearchUI', 'm_strResearchCreditEarned')],
    ['BonusMeld', key('XGResearchUI', 'm_strBonusMeld')],
  ].filter(([, v]) => v)
  const line = ([k, v]) => `${k}="${v.replace(/\\"/g, "'").replace(/"/g, "'")}"`
  return { text: ['[UILWEWResearch]', ...research.map(line), '', '[UILWEWScienceLabs]', ...labs.map(line), ''].join('\r\n'), named: research.length + labs.length }
}

/** EW's ship loadout (UILWEWShipLoadout): its [UIShipLoadout] words, and UIItemCards' labels and ratings (XComGame.int). */
export function makeShipLoadoutWords({ strategyLoc, loc }) {
  const copied = copySections(strategyLoc, [['UIShipLoadout', 'UILWEWShipLoadout']])
  const cards = loc.replace(/\r/g, '').match(/^\[UIItemCards\]\n([\s\S]*?)(?=^\[|(?![\s\S]))/m)?.[1] ?? ''
  const keys = ['m_strHitChanceLabel', 'm_strRangeLabel', 'm_strFireRateLabel', 'm_strDamageLabel', 'm_strArmorPenetrationLabel', 'm_strRangeShort', 'm_strRangeMedium', 'm_strRangeLong', 'm_strRateSlow', 'm_strRateMedium', 'm_strRateRapid', 'm_strGenericScaleLow', 'm_strGenericScaleMedium', 'm_strGenericScaleHigh']
  const lines = keys.map((k) => [k, cards.match(new RegExp(`^${k}\\s*=(.*)$`, 'm'))?.[1]?.trim() ?? '']).filter(([, v]) => v).map(([k, v]) => `${k}=${v}`)
  // (The item card, UILWEWItemCard: UIItemCards' header and close label, the craft weapons' texts (XGLocalizedData's), the
  // craft types' texts and names (XGItemTree's), by EShipWeapon and EShipType.)
  // (The section comes more than once in the file: every one of them read.)
  const tree = [...strategyLoc.replace(/\r/g, '').matchAll(/^\[(?:XGItemTree|XGLocalizedData)\]\n([\s\S]*?)(?=^\[|(?![\s\S]))/gm)].map((m) => m[1]).join('\n')
  const one = (k) => tree.match(new RegExp(`^${k.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))?.[1]?.trim() ?? ''
  const weapons = ['None', 'Cannon', 'Stingray', 'Avalanche', 'Laser', 'Plasma', 'EMP', 'Fusion']
  const card = [
    ...['m_strTacticalInfoHeader', 'm_strCloseCardLabel', 'm_strEffectiveRangeLabel', 'm_strBaseDamageLabel', 'm_strBaseCriticalDamageLabel', 'm_strCriticalDamageLabel', 'm_strChargesLabel', 'm_strHealthBonusLabel', 'm_strRangeShort', 'm_strRangeMedium', 'm_strRangeLong'].map((k) => [k, cards.match(new RegExp(`^${k}\\s*=(.*)$`, 'm'))?.[1]?.trim() ?? '']),
    ...weapons.map((w, i) => [`WeaponText[${i}]`, one(`ShipWeaponFlavorTxt[eShipWeapon_${w}]`)]),
    ...[[1, 'Interceptor'], [3, 'Firestorm']].flatMap(([i, t]) => [[`CraftName[${i}]`, one(`ShipTypeNames[eShip_${t}]`)], [`CraftText[${i}]`, one(`ShipTypeFlavorTxt[eShip_${t}]`)]]),
  ].filter(([, v]) => v).map(([k, v]) => `${k}=${v}`)
  // (The loadout's description of each craft weapon, as EW's: the item's ItemTypeSummary by its number,
  // UILWEWShipSummary.WeaponItemNumber: weapon 1 the cannon (117), 2 the Stingray (116), 3 on 118 onwards.)
  const itemNumber = (w) => (w === 2 ? 116 : w === 1 ? 117 : 115 + w)
  const summaries = weapons.map((_, i) => [`WeaponSummary[${i}]`, strategyLoc.replace(/\r/g, '').match(new RegExp(`^ItemTypeSummary\\[${itemNumber(i)}\\]=(.*)$`, 'm'))?.[1]?.trim() ?? '']).filter(([, v], i) => i > 0 && v)
  card.push(...summaries.map(([k, v]) => `${k}=${v}`))
  const cardText = ['[UILWEWItemCard]', ...card, ''].join('\r\n')
  const text0 = copied.text.includes('[UILWEWShipLoadout]') ? copied.text.replace('[UILWEWShipLoadout]\r\n', `[UILWEWShipLoadout]\r\n${lines.map((l) => l + '\r\n').join('')}`) : ['[UILWEWShipLoadout]', ...lines, ''].join('\r\n')
  return { text: text0 + '\r\n' + cardText, named: copied.named + lines.length + card.length }
}

/** EW's finances (UILWEWFinances): XGFinanceUI's labels and the craft's names (ShipTypeNames). */
export function makeFinanceWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const section = text.match(/^\[XGFinanceUI\]\n([\s\S]*?)(?=^\[|(?![\s\S]))/m)?.[1] ?? ''
  const value = (body, k) => body.match(new RegExp(`^${k.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))?.[1]?.trim().replace(/^"(.*)"$/, '$1') ?? ''
  const lines = [
    ['Title', value(section, 'm_strLabelCashFlowTitle')],
    ['Net', value(section, 'm_strLabelNet')],
    ['Gross', value(section, 'm_strLabelMonthlyGross')],
    ['Salary', value(section, 'm_strSalary')],
    ['Craft', value(section, 'm_strCraftMaintenance')],
    ['Facilities', value(section, 'm_strFacilityMaintenance')],
    ['Interceptor', value(text, 'ShipTypeNames[eShip_Interceptor]')],
    ['Firestorm', value(text, 'ShipTypeNames[eShip_Firestorm]')],
    ['Skyranger', value(text, 'ShipTypeNames[eShip_Skyranger]')],
  ].filter(([, v]) => v)
  return { text: ['[UILWEWFinances]', ...lines.map(([k, v]) => `${k}="${v.replace(/"/g, "'")}"`), ''].join('\r\n'), named: lines.length }
}

export function makeMemorialWords({ strategyLoc }) {
  const copied = copySections(strategyLoc, [['UIMemorial', 'UILWEWMemorial'], ['UIPendingRequests', 'UILWEWPendingRequests'], ['UIShipList', 'UILWEWHangar'], ['UIDebrief', 'UILWEWDebrief'], ['XGGreyMarketUI', 'UILWEWGreyMarket']])
  // (The debrief's titles: XGDebriefUI's.)
  const deb = strategyLoc.replace(/\r/g, '').match(/^\[XGDebriefUI\]\n([\s\S]*?)(?=^\[|(?![\s\S]))/m)?.[1] ?? ''
  const dk = (k) => deb.match(new RegExp(`^${k}\\s*=(.*)$`, 'm'))?.[1]?.trim() ?? ''
  const debKeys = ['m_strAbductionStopped', 'm_strAbductionFeedback', 'm_strAbductionLoss', 'm_strTerrorFeedback', 'm_strTerrorLoss', 'm_strCountryWithdraw', 'm_strAlienBaseFeedback', 'm_strAlienBaseLoss', 'm_strReward', 'm_strPanicIncreaseCountry', 'm_strPanicDecreaseCountry', 'm_strScientists', 'm_strEngineers']
  const debExtra = [['AfterReport', dk('m_strLabelAfterReport')], ['ArtifactsRecovered', dk('m_strLabelArtifactsRecovered')], ['CouncilTransmission', dk('m_strLabelFundingCouncil')], ...debKeys.map((k) => [k, dk(k)])].filter(([, v]) => v)
  // (The build screen's: UIBuildItem's column labels, XGEngineeringUI's cost label and tab names, under one section.)
  const eng = strategyLoc.replace(/\r/g, '').match(/^\[XGEngineeringUI\]\n([\s\S]*?)(?=^\[|(?![\s\S]))/m)?.[1] ?? ''
  const bui = strategyLoc.replace(/\r/g, '').match(/^\[UIBuildItem\]\n([\s\S]*?)(?=^\[|(?![\s\S]))/m)?.[1] ?? ''
  const fac = strategyLoc.replace(/\r/g, '').match(/^\[XGFacility_Engineering\]\n([\s\S]*?)(?=^\[|(?![\s\S]))/m)?.[1] ?? ''
  const tree = strategyLoc.replace(/\r/g, '').match(/^\[XGItemTree\]\n([\s\S]*?)(?=^\[|(?![\s\S]))/m)?.[1] ?? ''
  const kv = (sec, k) => sec.match(new RegExp(`^${k}\\s*=(.*)$`, 'm'))?.[1]?.trim().replace(/^"(.*)"$/, '$1') ?? ''
  const build = [['ItemLabel', kv(bui, 'm_strItemLabel')], ['BuiltLabel', kv(bui, 'm_strQuantityLabel')], ['CostLabel', kv(eng, 'm_strBuildCost')],
    ['BuildHeader', kv(eng, 'm_strHeaderBuildItems')], ['TabItems', kv(eng, 'm_strCatWeapons')], ['TabArmor', kv(eng, 'm_strCatArmor')],
    ['TabVehicles', kv(eng, 'm_strCatVehicles')], ['TabAll', kv(eng, 'm_strCatAll')],
    // (A SHIV's description and its cost in barracks room, as EW's build screen shows them: XGItemTree's ItemTypeSummary,
    // XGFacility_Engineering's m_strCostBarracks. A SHIV is built as a unit, with no item template to carry them.)
    ['CostBarracks', kv(fac, 'm_strCostBarracks')],
    ...['eItem_SHIV', 'eItem_SHIV_Alloy', 'eItem_SHIV_Hover'].map((e, k) => [`ShivSummary[${k}]`, tree.match(new RegExp(`^ItemTypeSummary\\[${e}\\]\\s*=(.*)$`, 'm'))?.[1]?.trim().replace(/^"(.*)"$/, '$1') ?? ''])].filter(([, v]) => v)
  if (build.length) {
    copied.text += `[UILWEWEngineering]\r\n${build.map(([k, v]) => `${k}="${v}"\r\n`).join('')}\r\n`
    copied.named += build.length
  }
  copied.text = copied.text.replace('[UILWEWDebrief]\r\n', `[UILWEWDebrief]\r\n${debExtra.map(([k, v]) => `${k}=${v}\r\n`).join('')}`)
  copied.named += debExtra.length
  // (The craft summary: its words, and Long War's pilots for its RENAME, XGLocalizedData.ShipWeaponFlavorTxt[11..255].)
  const summary = copySections(strategyLoc, [['UIShipSummary', 'UILWEWShipSummary']])
  // (Indexed, as a localized array is written; the names keep EW's escaped quotes, "Mad Dog".)
  const pilots = [...strategyLoc.replace(/\r/g, '').matchAll(/^ShipWeaponFlavorTxt\[(\d+)\]="(.*)"\s*$/gm)].filter((m) => Number(m[1]) >= 11 && Number(m[1]) <= 255).map((m, i) => `Pilots[${i}]="${m[2]}"`)
  copied.text += '\r\n' + summary.text.replace(/\r\n$/, '') + '\r\n' + pilots.join('\r\n') + '\r\n'
  copied.named += summary.named + pilots.length
  // (The hangar's cancel-order confirmation, XGHangarUI's, under the same section.)
  const hangar = strategyLoc.replace(/\r/g, '').match(/^\[XGHangarUI\]\n([\s\S]*?)(?=^\[|(?![\s\S]))/m)?.[1] ?? ''
  const key = (k) => hangar.match(new RegExp(`^${k}\\s*=(.*)$`, 'm'))?.[1]?.trim().replace(/^"(.*)"$/, '$1') ?? ''
  // (And the craft's callsigns, XGFacility_Hangar's: RAVEN, DEMON.)
  const fh = strategyLoc.replace(/\r/g, '').match(/^\[XGFacility_Hangar\]\n([\s\S]*?)(?=^\[|(?![\s\S]))/m)?.[1] ?? ''
  const fk = (k) => fh.match(new RegExp(`^${k}\\s*=(.*)$`, 'm'))?.[1]?.trim().replace(/^"(.*)"$/, '$1') ?? ''
  const extra = [['CancelOrderTitle', key('m_strCancelPendingOrderTitle')], ['CancelOrderText', key('m_strCancelPendingOrderText_Interceptor')],
    ['CallsignInterceptor', fk('m_strCallsignInterceptor')], ['CallsignFirestorm', fk('m_strCallsignFireStorm')]].filter(([, v]) => v)
  const text = copied.text.replace('[UILWEWHangar]\r\n', `[UILWEWHangar]\r\n${extra.map(([k, v]) => `${k}="${v}"\r\n`).join('')}`)
  return { text, named: copied.named + extra.length }
}

/** Sections of an EW text file under the mod's classes, as they are ([from] → [to]). */
function copySections(loc, pairs) {
  const text = loc.replace(/\r/g, '')
  const out = []
  let named = 0
  for (const [from, to] of pairs) {
    const m = text.match(new RegExp(`^\\[${from}\\]\\n([\\s\\S]*?)(?=^\\[|(?![\\s\\S]))`, 'm'))
    if (!m) continue
    // (Keys by EW's enum names, [eGO_RandomDamage], made numbers: the option's own number in its title, "(#0)".)
    const num = new Map()
    for (const t of m[1].matchAll(/^\w+\[(\w+)\]="[^"]*\(#(\d+)\)"/gm)) num.set(t[1], t[2])
    const lines = m[1]
      .split('\n')
      // (Some of EW's sections space their keys: "m_strX = …".)
      .map((l) => l.replace(/^(\w+(?:\[\w+\])?)\s+=\s*/, '$1='))
      .map((l) => l.replace(/^(\w+)\[(\w+)\]=/, (all, k, i) => (/^\d+$/.test(i) ? all : num.has(i) ? `${k}[${num.get(i)}]=` : '')))
      .filter((l) => /^\w+(\[\d+\])?=/.test(l))
    named += lines.length
    out.push(`[${to}]`, ...lines, '')
  }
  return { text: out.join('\r\n'), named }
}

/** Mobile cover's name on a shot's breakdown (X2Effect_LWMobileCover): Long War's for the Alloy SHIV's (m_strShivCoverName). */
export function makeMobileCoverWords({ strategyLoc }) {
  const name = strategyLoc.match(/^m_strShivCoverName="(.*)"\s*$/m)?.[1]
  return name ? { text: ['[X2Effect_LWMobileCover]', `MobileCoverReason="${name}"`, ''].join('\r\n'), named: 1 } : { text: '', named: 0 }
}

/** The council's bomb disposal's words (features/lw-council-missions.md), from EW's own [XSpecialMissions]: the objectives
 *  and the countdown for LWX2CouncilBomb (the mod's package), and the two actions' help (XComGame.int): "Deactivate power
 *  nodes to delay explosion.", "Approach and defuse the bomb." The actions' names are the mod's. */
export function makeBombWords({ loc }) {
  const text = loc.replace(/\r/g, '')
  const at = text.indexOf('\n[XSpecialMissions]\n')
  if (at < 0) return { modText: '', text: '', named: 0 }
  const end = text.indexOf('\n[', at + 2)
  const section = text.slice(at, end < 0 ? undefined : end)
  const one = (key) => section.match(new RegExp(`^${key}="(.*)"\\s*$`, 'm'))?.[1]
  const words = { FindBomb: one('m_strBombObj1'), NodesDelay: one('m_strBombObj1A'), Defuse: one('m_strBombObj2'), KillRest: one('m_strBombObj3'), Countdown: one('m_strBombCountdown1')?.replace(/:\s*$/, '') }
  const named = Object.values(words).filter(Boolean).length
  const q = (t) => `"${t}"`
  const modText = ['[LWX2CouncilBomb]', ...Object.entries(words).filter(([, v]) => v).map(([k, v]) => `${k}=${q(v)}`), ''].join('\r\n')
  const ability = (name, title, help) => (help ? ['', `[${name} X2AbilityTemplate]`, `LocFriendlyName=${q(title)}`, `LocHelpText=${q(help)}`, `LocLongDescription=${q(help)}`, `LocFlyOverText=${q(title)}`] : [])
  const abilities = [...ability('LWX2_DeactivateNode', 'Deactivate Power Node', words.NodesDelay), ...ability('LWX2_DisarmBomb', 'Defuse Bomb', words.Defuse), '']
  return { modText, text: abilities.join('\r\n'), named }
}

/** The Chryssalid hive's transponder action (LWX2ChryssalidHive): its help EW's own objective, from [EWIMissions]
 *  ("Reactivate the ship's transponder to initiate airstrike then report to EVAC"); its name the mod's. */
export function makeHiveWords({ loc }) {
  const text = loc.replace(/\r/g, '')
  const at = text.indexOf('\n[EWIMissions]\n')
  if (at < 0) return { text: '', named: 0 }
  const end = text.indexOf('\n[', at + 2)
  const help = text.slice(at, end < 0 ? undefined : end).match(/^m_strChrysObj3="(.*)"\s*$/m)?.[1]
  if (!help) return { text: '', named: 0 }
  const title = 'Reactivate Transponder'
  return { text: ['', '[LWX2_ActivateTransponder X2AbilityTemplate]', `LocFriendlyName="${title}"`, `LocHelpText="${help}"`, `LocLongDescription="${help}"`, `LocFlyOverText="${title}"`, ''].join('\r\n'), named: 1 }
}

/** Deluge's valve action (LWX2Deluge) and Furies' console action (LWX2Furies): its help EW's own objective, from the strategy text's [DLC2_2Objectives]
 *  ("Open the bypass valves to delay the dam's collapse."); its name the mod's. */
export function makeDelugeWords({ strategyLoc }) {
  const help = strategyLoc?.match(/^m_strDLC2_2Obj2="(.*)"\s*$/m)?.[1]
  if (!help) return { text: '', named: 0 }
  const title = 'Open Valve'
  const lines = ['', '[LWX2_OpenValve X2AbilityTemplate]', `LocFriendlyName="${title}"`, `LocHelpText="${help}"`, `LocLongDescription="${help}"`, `LocFlyOverText="${title}"`, '']
  // Furies' console (LWX2Furies): its help EW's own objective, [DLC2_3Objectives] ("Destroy or disarm the command console.").
  const console = strategyLoc?.match(/^m_strDLC2_3Obj2="(.*)"\s*$/m)?.[1]
  if (console) lines.push('[LWX2_DisarmConsole X2AbilityTemplate]', 'LocFriendlyName="Disarm Console"', `LocHelpText="${console}"`, `LocLongDescription="${console}"`, 'LocFlyOverText="Disarm Console"', '')
  return { text: lines.join('\r\n'), named: console ? 2 : 1 }
}

/** The MECs' words (features/lw-shivs-mecs.md): Long War's item names and summaries for the MEC suits (LWMEC_Suit_<id>) and
 *  weapons (LWMEC_Weapon_<id>, and the Kinetic Strike Module, LWMEC_KineticStrike), from XComLWMECs.ini's Enum= names. */
/** Perfect Information's words (second wave #28; X2Effect_LWSecondWave): Long War's for a shot it announces with its chance
 *  (XComPresentationLayer's m_strArmorExplodeFragments, which it rewrote, and the reaction shot's expanded string). */
export function makePerfectInfoWords({ loc }) {
  const one = (key) => loc.match(new RegExp(`^${key.replace(/[[\]]/g, '\\$&')}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const words = [
    ['UsesOn', one('m_strArmorExplodeFragments')],
    ['ReactionShot', one('m_aExpandedLocalizedStrings[eELS_UnitReactionShot]')],
  ].filter(([, v]) => v)
  return { text: ['[X2Effect_LWSecondWave]', ...words.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
}

/** The Repair Bay's words (UILWEWRepairBay, features/lw-gear-repair.md): Long War's, which it wrote over EW's MEC inventory
 *  (sections UIMECInventory and XGCyberneticsUI of its strategy text). */
export function makeRepairWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const inSection = (section, key) => {
    const at = text.indexOf(`\n[${section}]\n`)
    if (at < 0) return undefined
    const end = text.indexOf('\n[', at + 2)
    const body = text.slice(at, end < 0 ? undefined : end)
    const m = body.match(new RegExp(`^${key}=(.*)$`, 'm'))
    return m ? m[1].trim().replace(/^"(.*)"$/, '$1') : undefined
  }
  const words = [
    ['Title', inSection('UIMECInventory', 'm_strMECInventoryTitle')],
    ['SubTitle', inSection('UIMECInventory', 'm_strMECInventorySubTitle')],
    ['RepairItem', inSection('UIMECInventory', 'm_strButtonRepair')],
    ['Description', inSection('UIMECInventory', 'm_strDescBuildNewMec')],
    ['RepairsNeeded', inSection('UIMECInventory', 'm_strMECUnequipped')],
    ['Damaged', inSection('XGCyberneticsUI', 'm_strLabelDamaged')],
    ['Repairing', inSection('XGCyberneticsUI', 'm_strLabelRepairing')],
    ['RepairAll', inSection('XGCyberneticsUI', 'm_strBuildNewMEC')],
    ['RepairTitle', inSection('XGCyberneticsUI', 'm_strRepairTitle')],
    ['RepairCost', inSection('XGCyberneticsUI', 'm_strRepairCost')],
    ['RepairWarning', inSection('XGCyberneticsUI', 'm_strRepairWarning')],
    ['Confirm', inSection('XGCyberneticsUI', 'm_strRepairButtonConfirm')],
    ['NotNow', inSection('XGCyberneticsUI', 'm_strRepairButtonWait')],
    ['CostLabel', inSection('XGCyberneticsUI', 'm_strRepairCostLabel')],
    ['StartedTitle', inSection('XGCyberneticsUI', 'm_strNewMecRepairingDialogTitle')],
    ['StartedText', inSection('XGCyberneticsUI', 'm_strNewMecRepairingDialogDescription')],
  ].filter(([, v]) => v)
  return { text: ['[UILWEWRepairBay]', ...words.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
}

export function makeMECWords({ loc, strategyLoc, mecsIni }) {
  const one = (text, key, k) => (text ? text.match(new RegExp(`^${key}\\[${k}\\]="(.*)"\\s*$`, 'm'))?.[1] : undefined)
  const out = []
  let named = 0
  const lines = [
    ...[...mecsIni.matchAll(/^\+Suits=\(Item=(\d+), Enum=(\w+), HP=(-?\d+)/gm)].map((m) => ({ template: `LWMEC_Suit_${m[1]}`, kind: 'X2ArmorTemplate', item: m[1], enum: m[2], fallback: `+${m[3]} HP.` })),
    ...[...mecsIni.matchAll(/^\+Weapons=\(Item=(\d+), Enum=(\w+), Damage=(\d+)/gm)].map((m) => ({ template: `LWMEC_Weapon_${m[1]}`, kind: 'X2WeaponTemplate', item: m[1], enum: m[2], fallback: `${m[3]} damage.` })),
    ...[...mecsIni.matchAll(/^KineticStrike=\(Item=(\d+), Enum=(\w+), Damage=(\d+)/gm)].map((m) => ({ template: 'LWMEC_KineticStrike', kind: 'X2WeaponTemplate', item: m[1], enum: m[2], fallback: `${m[3]} damage.` })),
  ]
  for (const l of lines) {
    const n = one(loc, 'm_aItemNames', l.enum) ?? one(loc, 'm_aItemNames', l.item)
    if (!n) continue
    named++
    const summary = one(strategyLoc, 'ItemTypeSummary', l.enum) ?? one(strategyLoc, 'ItemTypeSummary', l.item)
    out.push(`[${l.template} ${l.kind}]`, `FriendlyName="${n}"`, ...(summary ? [`BriefSummary="${summary}"`] : []), `TacticalText="${summary ?? `${n}: ${l.fallback}`}"`, '')
  }
  return { text: out.join('\r\n'), named }
}

/** The SHIVs' words (features/lw-shivs-mecs.md): Long War's item names for the bodies (the mod's characters), their weapons
 *  (with Long War's summaries) and the SHIVs' class. */
export function makeSHIVWords({ loc, strategyLoc, shivsIni }) {
  const one = (text, key, k) => text.match(new RegExp(`^${key}\\[${k}\\]="(.*)"\\s*$`, 'm'))?.[1]
  const name = (e) => one(loc, 'm_aItemNames', e)
  const out = []
  let named = 0
  const bodies = [...shivsIni.matchAll(/^\+Bodies=\(Item=(\d+), Template=(\w+)/gm)].map((m) => ({ item: Number(m[1]), template: m[2] }))
  const enums = { 100: 'eItem_SHIV', 101: 'eItem_SHIV_Alloy', 102: 'eItem_SHIV_Hover' }
  for (const b of bodies) {
    const n = name(enums[b.item] ?? b.item) ?? name(b.item)
    if (!n) continue
    named++
    out.push(`[${b.template} X2CharacterTemplate]`, `strCharacterName="${n}"`, '')
  }
  for (const m of shivsIni.matchAll(/^\+Weapons=\(Item=(\d+), Enum=(\w+), Template=(\w+), Damage=(\d+)/gm)) {
    const n = name(m[2]) ?? name(m[1])
    if (!n) continue
    named++
    const summary = strategyLoc ? one(strategyLoc, 'ItemTypeSummary', m[2]) ?? one(strategyLoc, 'ItemTypeSummary', m[1]) : undefined
    out.push(`[${m[3]} X2WeaponTemplate]`, `FriendlyName="${n}"`, ...(summary ? [`BriefSummary="${summary}"`] : []), `TacticalText="${summary ?? `${n}: ${m[4]} damage.`}"`, '')
  }
  const shiv = name('eItem_SHIV')
  if (shiv) out.push('[LWS_SHIV X2SoldierClassTemplate]', `DisplayName="${shiv}"`, ...[0, 1].flatMap((k) => [`RankNames[${k}]="${shiv}"`, `ShortNames[${k}]="${shiv}"`]), '')
  return { text: out.join('\r\n'), named }
}

/** EW's species' names (features/lw-species-names.md): XLocalizedData.m_aCharacterName[eChar_…], by ECharacter number, for
 *  LWX2Species.Names (each species' own template's name on the field). */
export const ECHARACTER = ['None', 'Civilian', 'Soldier', 'Tank', 'Sectoid', 'Floater', 'Thinman', 'Muton', 'Cyberdisc', 'SectoidCommander', 'FloaterHeavy', 'MutonElite', 'Ethereal', 'Chryssalid', 'Zombie', 'MutonBerserker', 'Sectopod', 'Drone', 'Outsider', 'EtherealUber', 'BattleScanner', 'Mechtoid', 'Mechtoid_Alt', 'Seeker', 'ExaltOperative', 'ExaltSniper', 'ExaltHeavy', 'ExaltMedic', 'ExaltEliteOperative', 'ExaltEliteSniper', 'ExaltEliteHeavy', 'ExaltEliteMedic']
export function makeSpeciesWords({ loc }) {
  const lines = []
  // (Every index written, the unnamed empty: a localized array read with gaps came out empty in the game.)
  let named = 0
  ECHARACTER.forEach((e, k) => {
    const m = new RegExp(`^m_aCharacterName\\[eChar_${e}\\]="(.*)"\\s*$`, 'm').exec(loc)
    const name = m && k >= 4 ? m[1] : ''
    if (name) named++
    lines.push(`Names[${k}]="${name}"`)
  })
  return { text: ['[LWX2Species]', ...lines, ''].join('\r\n'), named }
}

