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

## Report (2026-11-04 night, the aliens' perks)

- **The perks given:** `scripts/classes-config.mjs` reads the perk numbers of the `+Leader`
  lines, names them by EW's `EPerkType` (read from `XComGame.upk`, `lw-words.readEnum`) and
  maps each as it maps a soldier's perk: XCOM 2's own ability where it is the same, else Long
  War's (`LW_…`, working where the soldiers' already works, else a named stand-in). 51 perks,
  `+AlienAbilities` in `XComLWClasses.ini`. As a pod spawns, each perk a leader or navigator
  line gives is added to the alien in the spawning game state
  (`X2TacticalGameRuleset.InitAbilityForUnit`, which activates passives then).
- EW's Gunslinger slot is Long War's **Ranger** (+1 damage with primary weapons and pistols),
  so that is what the Sectoids' 99% navigator line gives.
- **Seen** (the store, day 1): the Sectoids with `LW_Ranger`, the Drones' navigator line at
  −20% scale; a Thin Man spawned as a leader of level 7 with its seven perks (Executioner,
  Sharpshooter, Bombard, Squadsight, Rapid Reaction, Sprinter, Lightning Reflexes), mobility
  18 with Sprinter's +4. The control aid `spawn <template> <tiles> <species> <leader level>`
  makes such a leader; `enemies` lists an alien's Long War perks and scale.
- **Stand-ins only so far:** perks that are Long War's own and not yet working for soldiers
  either (Combined Arms, Repair Servos, Damage Control, Advanced Fire Control …) are named
  and do nothing, as on soldiers; they work when the soldiers' do.
- **Release** `LongWarX2-20261104-041a0b4.zip`, checked from the zip: the store's 7 Sectoids at
  3 HP, each with Ranger.

## Report (2026-11-04 day, the species' own abilities: the Sectoid's psionics)

- `scripts/aliens-config.mjs` reads each species' Long War abilities (`Characters=`
  `ABILITIES[]`) and writes those the mod has as `+SpeciesAbilities` (`XComLWAliens.ini`): Long
  War's psi powers, which its psi soldiers use (`X2Ability_LWStandins`): the Sectoid's Mind Merge,
  Psi Panic and Mindfray; the Sectoid Commander's Mind Control, Mindfray, (Greater) Mind Merge
  and Psi Panic; the Ethereals' Rift, Mind Control and Mindfray. Given as the pod spawns
  (`LWAlienStats.Give`, as the perks).
- Mind Merge's target is an ally of the psion's side, not a civilian (it required XCOM's squad).
- **XCOM 2's AI** uses an ability only where its behaviour tree names it: `Config/XComAI.ini`
  redefines the Sectoid tree's psionics node (`TryPsiReanimationOrMindSpinOption`, whose
  abilities Long War's Sectoids no longer have) as Mind Merge on an ally, else Psi Panic or
  Mindfray (even odds) on a soldier, the target chosen as XCOM 2 chose its Mindspin's.
- **Seen** (a pod spawned beside the squad, one alien turn; a new control aid `history [n]`
  lists the last abilities used): the two Sectoids Mind Merged with each other.
- **The Muton's Blood Call** (`LW_BloodCall`, `X2Ability_LWAliens`): the Muton and its allies
  within 8 tiles gain EW's +10 aim, +10 will, +4 mobility for its turn and the next; once a
  battle (an approximation: EW's rule for how often was not read). Used where the Muton's tree
  tried its bayonet. Seen: two Mutons beside the squad each Blood Called, then shot.
- **The Drone's repair** (`LW_Repair`): a damaged robotic ally within 8 tiles and in sight
  regains EW's 3 HP (`DRONE_REPAIR_HP`); EW's Drone repairs by its behaviour, not an `ABILITIES[]`
  entry. Used where the MEC tree tried its micro missiles. Seen: a Drone repaired a hurt one,
  which then shot. (`hurt` takes an alien's template or `#<object id>` now.)
- Not yet: the Floater's Launch, the Muton's Intimidate, the Berserker's Bull Rush and
  Bloodlust, the Drone's Overload, the Seeker's Stealth (and its strangling), the Cyberdisc's
  closing, the Ethereals' Psi Drain; the Commander's Mind Control and the Ethereals' powers in
  their AI.

## Report (2026-11-04 day, the aliens' research clock)

- **Read from Long War's code** (upkit's decompiler; kept out of the repository): Long War keeps
  the aliens' research in a repurposed recap stat, set each day to the campaign's days plus a
  bonus (`XGFacility_Barracks.HealAndRest`: `eRecap_Score`); the bonus starts at
  `INTERCEPTOR_REFUEL_HOURS` (−90, a repurposed setting; `XGWorld`) and grows: +20 each month
  (`FillUFOPool`), +2 a month for each country gone (`MakeMonthlyPlan`), and for each UFO that
  finishes its flight (`LogUFORecord`; not the Ethereals', not a hunt): +1 back whole, +0 or 1
  above half its hull (not a pact's), and a research flight by its size (small scout 3, large
  scout 5, abductor 8, larger 10); +1 for each soldier missing in action (not ported: no MIA yet).
- **Ported:** `XComGameState_LWStrategy.AlienResearch()` (the days, or the days and the bonus when
  more), the bonus kept as above; `LWAlienStats.ResearchLevel` uses it in place of the days
  (the approximation noted before). `AlienResearchStart` in `XComLWStrategy.ini`.
- **Seen** (a campaign run four months automatically, no satellites bought, so every UFO got
  away): research 1 on day 1, 31 on day 31, 61 on day 61, 124 on day 91, 211 on day 121.
- **The Sectoid Commander's Mind Control** in its AI (the Sectoid's tree, which it shares): tried
  before Mind Merge, a plain Sectoid having none. Seen: a Commander spawned beside the squad moved
  and shot for two turns and mind-controlled a soldier on the third.
- **The Cyberdisc's Death Blossom, tried and taken out:** an ability around the Cyberdisc (EW's
  four tiles, 4 to 6 damage, cooldown 4), usable only with an enemy within reach (a condition of
  its own), used where the Gatekeeper's tree tried its Anima Consume. Each time a Cyberdisc used
  it the game crashed showing it: with the scenery damaged and allies hit, with neither (as
  XCOM 2's Sectopod's Lightning Field, the same kind of ability), and played as a shot. Without
  the ability the same test runs. Not in the mod; to come back to (the visualisation of a
  radius attack by a unit with an EW body is the suspect).

