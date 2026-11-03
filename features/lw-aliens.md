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
