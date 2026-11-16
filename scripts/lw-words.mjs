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
    ['NewResearch', inSection('XGResearchUI', 'm_strLabelNewProject')],
    ['BuildItems', inSection('XGEngineeringUI', 'm_strOptBuildBuy')],
    ['BuildItemsHelp', inSection('XGEngineeringUI', 'm_strHelpBuildBuy')],
    ['BuildFacilities', inSection('XGEngineeringUI', 'm_strOptBuildFacilities')],
    ['BuildFacilitiesHelp', inSection('XGEngineeringUI', 'm_strHelpBuildFacilities')],
    ['Foundry', inSection('XGEngineeringUI', 'm_strOptFoundry')],
    ['Augment', inSection('XGEngineeringUI', 'm_strOptCyberneticsLab')],
    ['AugmentHelp', inSection('XGEngineeringUI', 'm_strHelpCyberneticsLab')],
    ['FoundryHelp', inSection('XGEngineeringUI', 'm_strHelpFoundry')],
    ['ViewSoldiers', inSection('XGBarracksUI', 'm_strBaseViewNames[eBarracksView_SoldierList]')],
    ['ViewSoldiersHelp', inSection('XGBarracksUI', 'm_strBaseViewHelp[eBarracksView_SoldierList]')],
    ['PsiLabs', inSection('XGBarracksUI', 'm_strBaseViewNames[eBarracksView_PsiLabs]')],
    ['PsiLabsHelp', inSection('XGBarracksUI', 'm_strBaseViewHelp[eBarracksView_PsiLabs]')],
    ['OTS', inSection('XGBarracksUI', 'm_strBaseViewNames[eBarracksView_OTS]')],
    ['OTSHelp', inSection('XGBarracksUI', 'm_strBaseViewHelp[eBarracksView_OTS]')],
    ['AircraftList', inSection('XGHangarUI', 'm_strHeaderNames[eHangarView_ShipList]')],
    ['AircraftListHelp', inSection('XGHangarUI', 'm_strHeaderHelp[eHangarView_ShipList]')],
    ['SituationRoom', anywhere('m_aFacilityNames[eFacility_SitRoom]')],
    ['GreyMarket', inSection('XGSituationRoomUI', 'm_stdLabelVisitGreyMarket')],
    ['GreyMarketHelp', inSection('XGSituationRoomUI', 'm_stdLabelVisitGreyMarketHelp')],
  ].filter(([, v]) => v)
  return { text: ['[UILWEWHub]', ...words.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
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
  const clues = []
  for (let i = 0; i < 40; i++) {
    const v = inSection('XGExaltSimulation', `m_arrClueText[${i}]`)
    if (v) clues.push([`ClueTexts[${i}]`, v])
  }
  const words = [...sit, ...inf, ...clues].filter(([, v]) => v)
  return { text: ['[UILWEWSituationRoom]', ...[...sit, ...inf].filter(([, v]) => v).map(([k, v]) => `${k}="${v}"`), '', '[LWExalt]', ...clues.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
}

/** The Psi Labs' words (UILWPsiLabs, in the mod's LongWarX2.int): EW's (XGPsiLabsUI), from Long War's strategy text. */
export function makePsiWords({ strategyLoc }) {
  const text = strategyLoc.replace(/\r/g, '')
  const at = text.indexOf('\n[XGPsiLabsUI]\n')
  const end = at < 0 ? -1 : text.indexOf('\n[', at + 2)
  const section = at < 0 ? '' : text.slice(at, end < 0 ? undefined : end)
  const one = (key) => section.match(new RegExp(`^${key}=(.*)$`, 'm'))?.[1].trim().replace(/^"(.*)"$/, '$1')
  const words = [
    ['Title', one('m_strPsiLabsPostHelpTitle')], ['Current', one('m_strLabelCurrentTestSubjects')],
    ['Days', one('m_strLabelDays')], ['Empty', one('m_strItemEmpty')],
  ].filter(([, v]) => v)
  return { text: ['[UILWPsiLabs]', ...words.map(([k, v]) => `${k}="${v}"`), ''].join('\r\n'), named: words.length }
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

/** Mobile cover's name on a shot's breakdown (X2Effect_LWMobileCover): Long War's for the Alloy SHIV's (m_strShivCoverName). */
export function makeMobileCoverWords({ strategyLoc }) {
  const name = strategyLoc.match(/^m_strShivCoverName="(.*)"\s*$/m)?.[1]
  return name ? { text: ['[X2Effect_LWMobileCover]', `MobileCoverReason="${name}"`, ''].join('\r\n'), named: 1 } : { text: '', named: 0 }
}

/** The MECs' words (features/lw-shivs-mecs.md): Long War's item names and summaries for the MEC suits (LWMEC_Suit_<id>) and
 *  weapons (LWMEC_Weapon_<id>, and the Kinetic Strike Module, LWMEC_KineticStrike), from XComLWMECs.ini's Enum= names. */
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
