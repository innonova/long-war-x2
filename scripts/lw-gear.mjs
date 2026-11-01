// Long War's gear rules, shared by the config generators (features/lw-gear.md): the weapon families
// by tier, who may carry what (XGStorage.IsClassEquippable with the classes' eWeaponType), the starting
// kit (GetInfinitePrimary), and how each weapon looks in XCOM 2 (a taste decision, in the feature's report).

export const TIERS = ['Ballistic', 'Laser', 'Gauss', 'Pulse', 'Plasma']

/** Long War's item numbers of each family, ballistic to plasma (null: no such tier). */
export const FAMILIES = {
  Pistol: [2, 8, null, null, 13],
  MachinePistol: [236, 237, 238, 239, 240],
  SMG: [231, 232, 233, 234, 235],
  Carbine: [32, 251, 53, 252, 14],
  Rifle: [212, 215, 3, 9, 15],
  BattleRifle: [241, 242, 243, 244, 245],
  Marksman: [226, 227, 228, 229, 230],
  Sniper: [213, 216, 6, 12, 18],
  Shotgun: [4, 10, 16, 1, 99],
  Autorifle: [214, 217, 5, 11, 17],
  LMG: [246, 247, 248, 249, 250],
  SawedOff: [254, null, null, null, null],
  ArcRifle: [null, 253, null, null, null],
}

/** Each family's XCOM 2 look by tier: the XCOM 2 weapon whose model, attachments, images and sounds it
 * takes. War of the Chosen's Legacy weapons (TLE_*: the originals' ballistic, laser and plasma) where it
 * has them, else conventional, magnetic, beam; the Vektor rifle for marksman's rifles, the Templar's
 * autopistol for machine pistols. */
const tiers3 = (t) => [`${t}_CV`, `${t}_MG`, `${t}_MG`, `${t}_BM`, `${t}_BM`]
const legacy = (tle, x2) => [`TLE_${tle}_CV`, `TLE_${tle}_MG`, `${x2}_MG`, `${x2}_BM`, `TLE_${tle}_BM`]
const LOOKS = {
  Pistol: legacy('Pistol', 'Pistol'),
  MachinePistol: tiers3('Sidearm'),
  SMG: tiers3('AssaultRifle'),
  Carbine: tiers3('AssaultRifle'),
  Rifle: legacy('AssaultRifle', 'AssaultRifle'),
  BattleRifle: tiers3('AssaultRifle'),
  Marksman: tiers3('VektorRifle'),
  Sniper: legacy('SniperRifle', 'SniperRifle'),
  Shotgun: legacy('Shotgun', 'Shotgun'),
  Autorifle: tiers3('Cannon'),
  LMG: legacy('Cannon', 'Cannon'),
  SawedOff: ['Shotgun_CV'],
  ArcRifle: [null, 'AssaultRifle_MG'],
}

/** XCOM 2's weapon tech by tier (its upgrade slots, its UI). */
export const TECH = ['conventional', 'magnetic', 'magnetic', 'beam', 'beam']

/** XCOM 2's range table by family (X2Item_DefaultWeapons' config arrays). */
export const RANGE = {
  Pistol: 'SHORT', MachinePistol: 'SHORT', SMG: 'SHORT', Carbine: 'MEDIUM', Rifle: 'MEDIUM', BattleRifle: 'MEDIUM', Marksman: 'LONG', Sniper: 'LONG',
  Shotgun: 'SHORT', Autorifle: 'MEDIUM', LMG: 'MEDIUM', SawedOff: 'SHORT', ArcRifle: 'MEDIUM',
}

/** The mod's classes (classes-config.mjs CLASSES) and their weapon property (XGStrategySoldier, eWeaponType). */
export const CLASS_PROPERTY = { Sniper: 'Sniper', Scout: 'Overheats', Rocketeer: 'Heavy', Gunner: 'Support', Medic: 'Rifle', Engineer: 'UnlimitedAmmo', Assault: 'Assault', Infantry: 'Rifle' }

/** XGStorage.IsClassEquippable: can a class with this weapon property carry a weapon with these properties (item: Long War's number). */
export function equippable(classProperty, props, item) {
  if (props.includes('AnyClass')) return true
  if (['Assault', 'Overheats', 'UnlimitedAmmo'].includes(classProperty) && props.includes('Rifle')) return true
  if (props.includes('Pistol')) {
    if (item === 254) return ['Rifle', 'Assault', 'Overheats', 'UnlimitedAmmo'].includes(classProperty)
    return classProperty !== 'Heavy' && classProperty !== 'Support'
  }
  return props.includes(classProperty)
}

/** XCOM 2's weapon category for a weapon: the classes that may carry it (XCOM 2 allows by category). */
export function categoryFor(props, item) {
  const classes = Object.entries(CLASS_PROPERTY).filter(([, p]) => equippable(p, props, item)).map(([c]) => c)
  return 'lw_' + classes.map((c) => c.toLowerCase()).join('_')
}

/** A weapon's family and tier by Long War's number. */
export function familyOf(item) {
  for (const [family, items] of Object.entries(FAMILIES)) {
    const tier = items.indexOf(item)
    if (tier >= 0) return { family, tier, look: LOOKS[family][tier] }
  }
  return undefined
}

/** The mod's template for a Long War weapon. */
export const weaponTemplate = (item) => `LWWeapon_${item}`

/** Long War's soldier armours (Armors= lines, MEC and SHIV left out) and the XCOM 2 armour each looks like (a
 * taste decision: Kevlar, plated and powered by tier and weight). Those Long War never builds (Tac Vest, Tac
 * Armor) are unlimited; new soldiers wear Tac Armor. */
export const ARMOURS = {
  57: 'KevlarArmor', 59: 'KevlarArmor',
  159: 'MediumPlatedArmor', 60: 'MediumPlatedArmor', 182: 'LightPlatedArmor',
  160: 'HeavyPlatedArmor', 58: 'LightPlatedArmor', 61: 'LightPoweredArmor',
  62: 'HeavyPoweredArmor', 67: 'LightPoweredArmor', 63: 'MediumPoweredArmor', 64: 'LightPoweredArmor',
  68: 'MediumPoweredArmor', 65: 'MediumPoweredArmor',
}
export const STARTING_ARMOUR = 59
export const armourTemplate = (item) => `LWArmor_${item}`

/** Long War's Armors= lines by item number: their fields, properties without eAP_ and abilities without eAbility_. */
export function readArmours(core, ITEMS) {
  const out = new Map()
  for (const m of core.matchAll(/^Armors=\((.*)\)/gm)) {
    const f = Object.fromEntries(m[1].split(',').filter((p) => p.includes('=')).map((p) => p.split('=').map((s) => s.trim())))
    const id = /^\d+$/.test(f.iType) ? Number(f.iType) : ITEMS.indexOf(f.iType)
    const list = (k, pre) => Object.entries(f).filter(([key, v]) => key.startsWith(k) && v !== '0').map(([, v]) => v.replace(pre, ''))
    out.set(id, { ...f, props: list('Properties', /^eAP_/), abilities: list('ABILITIES', /^eAbility_/) })
  }
  return out
}

/** The items Long War's stores hold without limit (XGStorage.Init, m_arrInfiniteItems): every ballistic weapon,
 * the basic armours and small items, the interceptors' missiles. */
export const INFINITE = [2, 4, 28, 32, 57, 59, 66, 69, 77, 79, 80, 81, 82, 83, 87, 89, 95, 98, 97, 109, 116, 118, 123, 212, 213, 214, 218, 226, 231, 236, 241, 246]

/** GetInfinitePrimary by the class's weapon property; everyone with a pistol slot a pistol (2). */
export function startingKit(cls) {
  const p = CLASS_PROPERTY[cls]
  const primary = p === 'Support' ? 214 : p === 'Assault' ? 4 : p === 'Sniper' ? 213 : 212
  return equippable(p, ['Pistol'], 2) ? [primary, 2] : [primary]
}

/** Long War's Weapons= lines by item number: their fields, and properties without eWP_ (items: EItemType names). */
export function readWeapons(core, ITEMS) {
  const weapons = new Map()
  for (const m of core.matchAll(/^Weapons=\((.*)\)/gm)) {
    const f = Object.fromEntries(m[1].split(',').filter((p) => p.includes('=')).map((p) => p.split('=').map((s) => s.trim())))
    const id = /^\d+$/.test(f.iType) ? Number(f.iType) : ITEMS.indexOf(f.iType)
    const props = Object.entries(f).filter(([k, v]) => k.startsWith('Properties') && v !== '0').map(([, v]) => v.replace(/^eWP_/, ''))
    weapons.set(id, { ...f, props })
  }
  return weapons
}

/** A class's weapon categories by slot: every family weapon it may carry, by its slot (Pistol: the secondary). */
export function classCategories(cls, weapons) {
  const out = { eInvSlot_PrimaryWeapon: new Set(), eInvSlot_SecondaryWeapon: new Set() }
  for (const items of Object.values(FAMILIES))
    for (const item of items) {
      const w = item !== null && weapons.get(item)
      if (!w || !equippable(CLASS_PROPERTY[cls], w.props, item)) continue
      out[w.props.includes('Pistol') ? 'eInvSlot_SecondaryWeapon' : 'eInvSlot_PrimaryWeapon'].add(categoryFor(w.props, item))
    }
  return out
}

/** Long War's ItemBalance_Normal lines by item number (BalanceItems): cash, elerium (low) and meld (high: / 1000),
 * alloys (low; the high part is not a cost), days and engineers. The INI's keys are not case-sensitive. */
export function readBalance(core, ITEMS) {
  const out = new Map()
  for (const m of core.matchAll(/^ItemBalance_Normal=\((.*?)\)/gim)) {
    const f = Object.fromEntries(m[1].split(',').filter((p) => p.includes('=')).map((p) => p.split('=').map((s) => s.trim())))
    const id = /^\d+$/.test(f.eItem) ? Number(f.eItem) : ITEMS.findIndex((e) => e.toLowerCase() === f.eItem.toLowerCase())
    const n = (k) => Number(f[k])
    out.set(id, { cash: n('iCash'), elerium: n('iElerium') % 1000, meld: Math.trunc(n('iElerium') / 1000), alloys: n('iAlloys') % 1000, days: n('iTime'), engineers: n('iEng') })
  }
  return out
}

/** The mod's XCOM 2 item for a Long War item: its weapon or armour, else an item of its own (X2Item_LWArtifacts). */
export function itemTemplate(item, ITEMS) {
  if (familyOf(item)) return weaponTemplate(item)
  if (ARMOURS[item]) return armourTemplate(item)
  return `LWItem_${ITEMS[item].replace(/^eItem_/, '')}`
}
