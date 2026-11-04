---
title: Long War's aliens in missions (stats, upgrades, leaders, abilities)
status: in-progress
priority: 3
dependsOn: [lw-missions, lw-ew-units]
---

Long War's aliens fight as XCOM 2 templates (`FightAs` in `XComLWStrategy.ini`), and until
now with those templates' stats: an XCOM 2 Sectoid has 8 HP where Long War's has 3, against
Long War's weapons and soldiers. Long War's aliens should have Long War's numbers.

What Long War sets (stock `DefaultGameCore.ini`, `XGTacticalGameCore`; its own comments
document the encodings):
- **Characters=**: each species' base HP, aim, defense, mobility, sight, will, crit.
- **BalanceMods_Easy**: the difficulty's adjustments (`iCritHit` is the difficulty, 0-3:
  Long War's Normal, Classic, Brutal, Impossible).
- **BalanceMods_Normal**: automatic upgrades as the aliens' research passes a level
  (`iCritHit`); aim, defense, HP and will packed as `xxyy` (crit and aim, damage reduction
  in tenths and defense, shield and HP, regeneration and will).
- **BalanceMods_Hard**: pod leaders and navigators: a leader level rolled by research,
  stat upgrades, a perk granted (`iMobility` is the perk), the pawn's scale.

## Report (2026-11-04 night, the stats)

- `scripts/aliens-config.mjs` writes `Config/XComLWAliens.ini` from stock Long War (numbers
  by species: 19 base lines, 69 difficulty lines, 165 upgrades); `config-all.sh` runs it.
- `LWAlienStats.ApplyTo` sets a pod alien's HP, aim, defense, mobility, will, crit, shield and
  damage reduction from its species' base, the campaign difficulty's line and every upgrade
  whose research level has been reached, as the pod spawns (`LWMissionSquads.SpawnPod`, where
  the species is known).
- **Approximation:** the aliens' research level is the campaign's day (Long War: "roughly
  days passed"), until the aliens' research clock is Long War's own.
- **Not yet:** the damage bonus (an effect on the alien's shots), leaders and navigators,
  regeneration; each species' own abilities and AI (it still fights with its XCOM 2
  template's: the Floater used Blazing Pinions).
- **The damage bonus** (the difficulty's and the upgrades' iDamage): set on the alien as a
  unit value; a passive (`LWX2_AlienDamage`, `X2Ability_LWAliens`) on every template Long
  War's species fight as adds it to each damaging attack.
- **Checked on wingpu** (the convenience store, Classic, day 1): 8 Sectoids at 3 HP, aim 60
  (65 less Classic's 5), mobility 12; 2 Drones at 3 HP, aim 55; each with the passive; and
  across twelve maps the aliens at Long War's HP.
- **Release** `LongWarX2-20261103-b82cf5d.zip` (with the breakable walls), checked from the
  zip: the store's Sectoids and Drones at Long War's HP in EW's bodies, with the passive;
  79 walls given toughness; no redscreens from the map's config.

## Report (2026-11-04 night, weapons and abilities)

- **Weapon damage:** each species' weapon in EW (the Sectoid's plasma pistol 3, the
  Floater's light plasma rifle 5, the Muton's plasma rifle 8, the Cyberdisc's 9 …) is read
  from Long War's `Weapons=` lines (`XComLWAliens.ini`, `+Weapon`); the alien's shots with
  its own weapon are shifted from the XCOM 2 weapon's base damage to it (XCOM 2's spread
  and crit damage kept), the upgrades' bonus on every attack. Seen: a Floater's hit for 5
  where the Archon's gun did 11 and killed a soldier outright.
- **XCOM 2's abilities no Long War alien has** taken off the templates and their weapons
  (140 entries over the templates' difficulty variants): the Sectoid's Psi Reanimation and
  Mindspin and its weakness to blades, the Archon's Blazing Pinions, frenzy and melee, the
  Viper's Bind and tongue, the Gatekeeper's Anima abilities, the Codex's teleport, clones
  and psi bomb, the Andromedon's robot suit, punch, wall smashing and acid launcher, the
  Muton's counterattack, bayonet and execute, the Berserker's rage, the Chryssalid's
  burrowing, the MECs' micro missiles. What stays is shooting, overwatch, suppression,
  melee where EW's species has it, the Thin Man's poison spit, the Chryssalid's poison.
  Seen: no Blazing Pinions or tongue; the Thin Man spat poison.
- **Not yet:** the species' own EW abilities (Mind Merge, the Floater's Launch, the Muton's
  Blood Call, the Cyberdisc's Death Blossom, the Seeker's cloak and strangle, the Drone's
  repair …); the Sectoid Commander lost Mindspin with the Sectoid (one template) and has no
  psionics until its own.

## Report (2026-11-04 night, leaders and navigators)

- **Read from Long War's code:** a pod's leader level is rolled when the strategy layer
  builds the pod (`XGStrategyAI.BuildPod`: out of research / 40 + 1, clamped 1 to 15; above 7
  folded back as 7 less a roll out of 16 less that; 0 to 7) and carried in the pod's
  `eMainAltWeapon`; the pod's first alien gets it, the others 0 (`XComAlienPodManager`); each
  alien then applies every `BalanceMods_Hard` line of its species whose research level is
  reached: a leader line when its level is at least the line's, a navigator line at its
  chance in 100 (out of 50 at an alien base) (`XGUnit`, Long War's patch in `DebugAnims`):
  HP, aim, damage, will, a perk, the pawn's scale. HQ assaults roll a level for every alien,
  the Temple Ship makes them all level 8 (not yet: no such missions).
- **Ported:** `+Leader` lines (244) in `XComLWAliens.ini`; the first alien of each pod rolls its
  level (`LWAlienStats.LeaderLevel`), every alien its navigator chances; stats added, the scale
  set on the pawn (`LWX2EWBodies.Scale`), the perks noted on the unit (`LWX2Perk0…`) and logged.
- **Seen** (day 1): every leader at level 0, as Long War's roll gives that early; the Sectoids'
  99% navigator line noted Gunslinger (perk 94) on each.
- **Next:** the perks given (EW's perk number → the mod's ability, as the classes' generator
  maps soldiers' perks; added to the alien as its pod spawns), Gunslinger first.
