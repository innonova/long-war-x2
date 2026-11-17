---
title: Long War's second-wave options
status: in-progress
priority: 40
dependsOn: [lw-startbonus]
---

# Long War's second-wave options

Long War's campaign options (EW's "second wave", the shell's gameplay toggles: `m_arrGameplayToggleTitle`, `eGO_…`)
are not in the port: a campaign plays as with all of them off. Long War 1.0 has 31, numbered as its text numbers them:

0 Damage Roulette, 1 New Economy, 2 Strict Screening, 3 Hidden Potential, 4 Training Roulette, 5 Save Scum, 6 Red Fog,
7 Absolutely Critical, 8 Liberators, 9 Dynamic War, 10 Results Driven, 11 Cinematic Mode, 12 Diminishing Returns,
13 Wear and Tear, 14 Itchy Trigger Tentacle, 15 War Weariness, 16 Bronzeman Mode, 17 Total Loss, 18 Commander's Choice,
19 Aiming Angles, 20 Mind Hates Matter, 21 Hidden Trees, 22 Durability, 23 United Humanity, 24 The Friendly Skies,
25 We Are Legion, 26 Miracle Workers, 27 Quick and Dirty, 28 Perfect Information, 29 Recon, 30 Green Fog.

(Long War's enum names do not all match the titles: Long War reused EW's slots, e.g. `eGO_Marathon` is Dynamic War,
`eGO_UltraRarePsionics` Wear and Tear.)

## Plan

1. **The choice:** the options chosen as a campaign starts (EW asks for them in its shell, before the start screen), kept
   in the campaign's Long War state, each with Long War's own title and text from the player's install.
2. **Each option's rule,** read from Long War's code where it checks the option (`IsOptionEnabled`, `m_arrSecondWave…`),
   one at a time, starting with those another part of the port already waits on: The Friendly Skies (the Firestorm's
   refits, `lw-air-war`), then the tactical ones that are one rule each (Absolutely Critical, Damage Roulette, Red Fog,
   Aiming Angles), then the strategy ones (New Economy, Results Driven, Diminishing Returns, War Weariness, …), Dynamic War
   last (it rescales the whole campaign).
3. Each option checked on wingpu with it on and off.

## Decisions

- **Where the choice is made: XCOM 2's own new-campaign screen** (its second-wave list, `UIShellDifficulty`). EW's own
  second-wave screen is in its shell movies, which the port does not convert; XCOM 2's list takes options from config, and
  a campaign's choice is kept in its settings (`XComGameState_CampaignSettings`). XCOM 2's own eight options are taken out
  of the list: a Long War campaign has Long War's.

## Report (2026-11-17, the choice; The Friendly Skies)

- **The choice:** `XComUI.ini` removes XCOM 2's eight second-wave options from its new-campaign screen and lists Long War's
  31 in Long War's order (`LWSW_<nn>_<name>`); their lines and tooltips are Long War's own titles and texts ("Damage
  Roulette (#0): Weapons have a much wider range of damage…"), written from the player's install into the mod's
  `XComGame.int` (`makeSecondWaveWords`: 31). `LWX2SecondWave.On(n)` answers with Long War's number, as Long War's
  `IsOptionEnabled`.
- **Test aid:** `secondwave` lists the options on; `secondwave <n> on|off` sets one in a running campaign.
- **#24 The Friendly Skies:** XCOM's aircraft weapons aim 15 better (Long War's `ABDUCTION_REWARD_SCI`, "Friendly Skies bonus
  for XCOM aircraft", added to each weapon's to-hit in `XGItemTree.BuildShipWeapons`, the Foundry's versions too):
  `LWAirWar.WeaponFor`, weapons 1 to 7.
- **Checked on wingpu:** the same Raven-1 against the same small UFO at Balanced: 39% of 1,000 simulated fights downed it with
  the option off, 60% with it on (`logs/wingpu_friendly_skies_off.png`, `…_on.png`).
- **The screen, seen:** XCOM 2's new-campaign screen with Long War's difficulties (Normal, Classic, Brutal, Impossible, with
  Long War's texts: the same fields of `[UIShellDifficulty]`; `logs/wingpu_lw_difficulties.png`) and, under its advanced
  options, Long War's 31 options by their titles with each one's text below the list (`logs/wingpu_second_wave_options.png`).
  A first version put title and text on one line; the list cut them.
- **Corrected:** STATUS's "the Firestorm's refits" waited on this option by a misreading; Firestorms are refitted as
  interceptors are.

## Report (2026-11-17, Absolutely Critical; Long War's flanking crit for everyone)

- **The carrier:** `LWX2_SecondWave` (`X2Ability_LWSecondWave`, on every character as the battle begins) with
  `X2Effect_LWSecondWave`, where the tactical options' effects on a unit go.
- **#7 Absolutely Critical:** a flanking shot's crit bonus Long War's `SW_FLANK_CRIT` (100) in place of
  `FLANKING_CRIT_BONUS` (50): every unit's flanking crit raised by the difference while the option is on (numbers generated
  from Long War's `DefaultGameCore.ini` into `XComLWGear.ini`).
- **Found on the way, fixed:** every unit's flanking crit was XCOM 2's (its soldiers 40 at run time, its aliens 33), not Long
  War's 50 for every shooter (`XGTacticalGameCore.GetFlankingCritBonus`). Every character's is now Long War's, as the
  templates are made.
- **Checked on wingpu** (the control port's `units` now prints the flanking crit): soldiers 50 with the option off, 100 with it
  on (the option set before the mission; before the fix: 40 and 90).

## Report (2026-11-17, Red Fog)

- **#6 Red Fog** (`XGUnit.SetUnitHP`, `ApplyHPStatPenalties`): every unit hurt, XCOM's and the aliens', has its aim and
  mobility down as its health is down: the share of health left (doubled for a robot; else raised by will over 60, ×
  (1 + max(0, 1 − 60/will))), and below one, aim × 35 and mobility × 6 of what is missing (Long War's `SW_ABDUCTION_SITES` and
  `SW_COVER_INCREASE`, the names notwithstanding). Applied as Long War does, to the current stats, the last penalty taken
  back first (`LWX2SecondWave.UpdateRedFog`, twice a second in a mission).
- **A bug caught in testing:** a unit without the stored penalty read the previous unit's (UnrealScript leaves the struct as
  it was), and the first version gave every unhurt unit the hurt one's penalty back as a bonus. Cleared per unit now; the
  other reads of unit values in loops checked (none affected).
- **Not ported:** Long War also shortens a hurt unit's throwing range by the aim penalty's share (`GetMoveModifierCost`).
- **Checked on wingpu:** Red Fog on, a soldier hurt to 2/6: aim −23, mobility 12 → 9; the rest unchanged.

## Report (2026-11-17, Damage Roulette)

- **#0 Damage Roulette** (`XGTacticalGameCore.CalcOverallDamage`): Long War rolls (3D + 1 + rand(2D + 2)) / 4 without it, about
  D ± 1 (the port's spread 1), and (2D + 1 + rand(4D + 2)) / 4 with it, about D ± 2 with a crit about 2D. As a mission
  begins (`LWX2SecondWave.ApplyDamageRoulette`), every weapon with a spread has it one wider (XCOM 2's alien weapons too: Long
  War's roll is every weapon's; their crit stays XCOM 2's), and Long War's own weapons crit D more instead of (D + 1) / 2.
  Without the option, as they were. The templates are shared by every campaign, so a widened one is marked on its damage's
  tag and put back when a campaign without the option plays.
- **Found on the way:** an item keeps the template it first found, and the port's arming pass makes Long War's weapons'
  templates again; the manager's alone were not the ones the soldiers' rifles held. Both are changed.
- **Checked on wingpu** (`units` now prints the primary weapon's damage, spread and crit): with the option the sniper rifle
  read 5 ± 2, crit +5; without, the carbine 4 ± 1, crit +2. **Not seen:** putting it back within one game session (the off
  test was a fresh start).

## Report (2026-11-17, the funding options; Diminishing Returns)

- **One funding** (`XComGameState_LWStrategy.CountryFunding`, as `XGCountry.CalcFunding`), used by the month's payment, the
  Situation Room, the monthly report and the Geoscape panel alike (each had its own copy of the formula): the country's own
  funding (set as the campaign begins: FundingAmounts × FundingBalance, kept per country), then
  - **#15 War Weariness:** 5% less each month, at most 90%;
  - **#10 Results Driven:** less by the country's panic, (100 − panic)%;
  - without a satellite, `BASE_FUNDING`'s share; each step rounded down as Long War's ints are.
- **#1 New Economy** (`XGWorld.RandomizeFunding`): as the campaign begins, the council's funding dealt again at random in
  tens, each country in a random order from half the average left to an average and a half, between the lowest and highest
  of before. (The test aid deals it at once when the option is switched on in a running campaign.)
- **#12 Diminishing Returns** (`XGItemTree.CalcEscalatingSatelliteCost`): a satellite costs `SW_SATELLITE_INCREASE` (1.155)
  times more for each one in the stores, in orbit or being built. Long War also scales the engineers it takes; the port's
  satellites take none.
- **Checked on wingpu** (`geo` now prints each country's funding with and without a satellite, and the satellite's price):
  a new campaign: USA 160/64, Russia 100/40, China 130/52, the satellite §200 with one held; with Results Driven and
  Diminishing Returns: USA (panic 30) 112/44, Russia (21) 79/31, the satellite §231; New Economy then: USA 77, Russia 126,
  China 59. **Not seen:** War Weariness past the first month.

## Report (2026-11-17, Strict Screening, Cinematic Mode; Total Loss)

- **#2 Strict Screening** (`XGFacility_Barracks.RandomizeStats`, rolled only without it): every recruit at the midpoints of
  Long War's rookie stats (its `Characters=` line), no roll (`LWRookieStats.Roll`). **Not seen in the game:** no recruit
  came during the test.
- **#11 Cinematic Mode:** XCOM's units aim 15 better (Long War's `ABDUCTION_REWARD_SCI`, added to every recruit, SHIV, MEC and
  council soldier as they are made); here for the battle, on the second-wave carrier, named on a shot's breakdown as Long War
  names the option. Checked on wingpu: a sniper's shot read "Aim 79, Cinematic Mode 15" (its aim 73 + 15 shown as 88).
- **#17 Total Loss: nothing to port.** Long War loses a dead soldier's gear only when `Roll(BLUESHIRT_HP_MOD)` succeeds; that
  config is set nowhere in Long War 1.0 and defaults to −1, so the roll never does, option or not.

## Report (2026-11-17, Liberators, Mind Hates Matter, United Humanity, Quick and Dirty, Green Fog)

- **#8 Liberators** (`XGFacility_Barracks.HasPotentialVolunteer`, `CanVolunteer`): no volunteer for the Temple Ship while any
  country has left the council: the Temple Ship's decision waits until every country is back. **Not ported:** its psionics
  rule (`XGFacility_Labs.IsResearched(255)`: psi only from interrogating a Sectoid Commander or an Ethereal, not their
  autopsies); the port's psi has no such gate yet. **Not seen in the game.**
- **#20 Mind Hates Matter** (`XGFacility_GeneLabs`, `XGGeneLabUI`): a soldier with a gene mod cannot train psi powers, one with
  a psi power cannot be gene-modded (`PsiSoldierWhy`, `GeneSoldierWhy`). Checked on wingpu: with the option, a soldier given
  Bioelectric Skin was refused the Psi Labs ("needs a soldier without gene mods"); one without was taken.
- **#23 United Humanity** (`XGExaltSimulation.BeginSimulation`): EXALT never begins. **Not seen in the game** (EXALT begins in
  the second month).
- **#27 Quick and Dirty** (`XGStrategyAI`'s squads, `ContBalance_Classic[33]`): a mission's aliens 60% as many, at least 6, at
  most 55 (`LWAlienSquads.SquadFor`; those over the count left off the list's end, its roaming and secondary aliens).
  Checked: an abduction's squad 13 → 7, a landed UFO's 20 → 12. (Long War also keeps at least one a pod.)
- **#30 Green Fog** (`ContBalance_Normal[1]`, `[2]`): XCOM's units lose one aim and one will each of their turns, up to 30
  and 20, back after the mission (`UpdateGreenFog`). Checked: a soldier's aim 66, 65, 64, 63 over three turns.
- With these, 16 of the 31 settled: #0, 1, 2, 6, 7, 8, 10, 11, 12, 15, 17 (nothing to port), 20, 23, 24, 27, 30.

## Report (2026-11-17, We Are Legion; each mission's squad size)

- **The squad size per mission** (`XGShip_Dropship.GetCapacity`; the port had one size for every mission): the Skyranger's
  and the Officer Training School's sizes; **a covert extraction takes 4** (Long War's capacity for the operative's mission;
  data recovery the usual size); with the Foundry's **Super Skyranger** (project 37, not ported until now) an alien base and
  EXALT's base 2 more, the Temple Ship 4 more (`UILWHeadquarters.SquadSize`, by the mission chosen).
- **#25 We Are Legion:** both squad size upgrades had from the campaign's start (`XGFacility_Barracks`), and a covert
  extraction 2 more (6).
- **Checked on wingpu** (`ots`): a new campaign at squad size 6; with We Are Legion, 8, "both bought". **Not seen:** a covert
  extraction's squad, Super Skyranger's.
