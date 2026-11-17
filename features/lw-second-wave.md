---
title: Long War's second-wave options
status: review
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

## Report (2026-11-17, Hidden Potential; the random will every level)

- **Gains on promotion as Long War's** (`XGStrategySoldier.LevelUpStats`; new `LWX2StatGains`): XCOM 2's class data gives
  each rank Long War's fixed gains (the last digits of its `SoldierStatProgression`). As XCOM 2 ranks a soldier up (its
  `UnitRankUp` event), the port now makes them Long War's in a game state of its own. Long War's packed numbers
  (`XComLWClasses.ini`'s `[LongWarX2.LWX2StatGains]`, 112 rows from `scripts/classes-config.mjs`) drive it:
  - **Normally:** will also gets Rand(`iRandWillIncrease`) = 0 or 1 more every level. The port had left this out until now.
  - **#3 Hidden Potential:** each gain is rolled instead: HP +1 with the chance of its xx (of xxyy), aim and will
    xx + Rand(yy) (of xxyyzz), and no random will on top.
  - The perk-choice bonuses (`LWX2PerkBonuses`) stay apart from these, as in Long War.
- **Found on the way, fixed:** XCOM 2 registers its strategy event listener templates only on the way back from a mission
  (`XGStrategy`'s return from tactical). A new campaign or a loaded save had none until the first mission. They are now
  registered as the Avenger's HUD comes up (`UIScreenListener_LWX2StrategyEvents`); the manager unregisters them all first,
  so this does not double them.
- **Decision:** the listener runs after the promotion's game state is submitted, as XCOM 2's templates do. A listener
  registered on the event's own game state (`ELD_Immediate`, from a template) was listed by the event manager but never
  called during the promotion. One state can hold several rank-ups (start bonuses, test aids): each rank since the
  unit's rank before that state is rolled once (the unit's `LWX2GainsRank` marks the last).
- **Checked on wingpu** (new test aid `rankup <soldier> [times]`, with the gains XCOM 2 gave and the stats after):
  - **Option off:** fixed gains plus 0–1 will a level. A sniper's three ranks gave +3 will over the fixed 6.
  - **Hidden Potential on:** every roll within Long War's ranges. A scout's rank 5: aim +6 (2+Rand(5)), will +6 (1+Rand(6)).
    A rocketeer's five ranks: aim +15 (5–25), will +25 (5–30), HP +1.
- **Not seen:** a promotion after a real mission with the option on (the same event; the test aid ranks up as XCOM 2 does).

## Report (2026-11-17, Training Roulette)

- **#4 Training Roulette** (`XGStrategySoldier.AssignRandomPerks`; new `LWX2TrainingRoulette`): as a soldier of one of Long
  War's eight classes gets the class (not a MEC), every perk in the tree that is on Long War's `RandomPerks` list is dealt
  again at random from that list, none twice. The other perks stay where they are. The list is Long War's 26 (from Tactical
  Sense to Platform Stability), as the abilities the port gives them, in `XComLWClasses.ini`'s
  `[LongWarX2.LWX2TrainingRoulette]` (from `scripts/classes-config.mjs`). It runs in the promotion listener above.
- **No perk-tree stat bonuses with it** (`LevelUpStats` and `XGSoldierUI` skip them under the option): neither the perk
  choices' bonuses (`LWX2PerkBonuses.Find` finds none, so the promotion screen shows none either) nor the squaddie's. XCOM 2's
  class data holds the squaddie bonus, which is now taken off again (the rank-1 rows' `TreeMobility`, `TreeAim`, `TreeWill`).
- **The squaddie rank is not dealt:** XCOM 2 buys it as it gives the class, and no class's squaddie perk is on the list.
- **Checked on wingpu** (test aid `rankup new [times]`: a new recruit promoted, its tree printed):
  - **Option off:** the trees as the class data has them.
  - **Option on:** a rocketeer's eight list perks (Holo-Targeting, Damn Good Ground, Lock N' Load, Vital Point Targeting, Low
    Profile, Aggression, Steadfast, Ranger) were dealt in place of its own. Its rockets, Suppression, Mayhem, Shock and Awe,
    Double Tap and Danger Zone stayed in their slots. A sniper's twelve dealt perks were all different.
  - **The squaddie bonus:** a Scout's squaddie +1 mobility without the option (12 → 13), none for a Medic with it (12 → 12).

## Report (2026-11-17, Aiming Angles; XCOM 2's good-angle bonus off)

- **Found on the way, fixed:** XCOM 2 gives XCOM's shots a bonus for a good angle on a target in cover (up to half the
  cover's value, under 44°, "Good Angle"). Long War has none without its option, and the port had kept XCOM 2's. It is off now
  (`XComGameCore.ini`: `MAX_ANGLE_BONUS_MOD=0`, from `scripts/classes-config.mjs`).
- **#19 Aiming Angles** (`XGTacticalGameCore.CalcAimingAngleMod`, native; Long War's ini describes it): a shot at a unit in
  cover gains aim the nearer the shooter is to flanking it. Along the cover it gains the cover's bonus plus
  `SW_AIMING_ANGLE_MAXBONUS` (−5), at `SW_AIMING_ANGLE_THRESHOLD` (30°) `SW_AIMING_ANGLE_MINBONUS` (5), in a line in between,
  and nothing beyond. It applies to every unit's shots, under XCOM 2's name for it ("Good Angle")
  (`X2Effect_LWSecondWave.GetToHitModifiers`).
- **The angle is asked of the world** (`XComWorldData.GetCoverTypeForTarget`, as XCOM 2's AI does): the visibility cache's
  angle stayed −1 throughout.
- **Checked on wingpu** (new test aid `coverscan <shooter> <target> [radius]`: the tiles near the target with cover from the
  shooter, and their angles; `hit` now prints the cover and its angle):
  - **An alien's shot:** at a soldier in low cover at 12°, +11 (15 − 10 × 0.4); in high cover at 26°, +9; at 63°, none.
  - **A soldier's shot:** at an alien in high cover at 20°, +15 with the option and nothing without it (XCOM 2's own
    would have been about +14).

## Report (2026-11-17, Hidden Trees; Wear and Tear, Durability, Miracle Workers)

- **#21 Hidden Trees** (`UISoldierPromotion`: the columns from the soldier's rank on locked): on the promotion screen,
  the ranks not reached yet show XCOM 2's own locked perk ("?", its locked title), and pointing at one describes nothing
  (`LWX2PromotionScreen.Hidden`). Perks a soldier holds stay shown.
- **#13 Wear and Tear, #22 Durability, #26 Miracle Workers:** in Long War's damaged gear and its repair, now ported
  (`features/lw-gear-repair.md`, with their checks).
- **Checked on wingpu** (new test aid `open promotion`; from the hub's barracks, the soldier list, the armory): a rank-2
  sniper sees the squaddie perks and the Lance Corporal choice, and a locked "?" for every perk from Corporal on
  (`logs/wingpu_hidden_trees.png`).

## Report (2026-11-17, Commander's Choice)

- **#18 Commander's Choice** (`XGSoldierUI` with `eGO_MorePower`: the class chosen for each soldier on promotion from
  rookie): the armory's PROMOTE SOLDIER for a rookie ready to rank up opens XCOM 2's own class chooser (the training
  centre's "Choose Soldier Class") with Long War's eight classes, in place of XCOM 2's draw from its class deck.
  - **The class chosen** is the soldier's at once, as XCOM 2's `PromoteSoldier` gives one: the rank, the squaddie's kit,
    the best gear, its `PromotionEvent`. XCOM 2's promotion screen follows as usual.
  - **The chooser's rows** show no training time, and their button is XCOM 2's PROMOTE SOLDIER (`UILWChooseClass`,
    `UILWClassListItem`).
  - **The armory menu** is XCOM 2's, overridden only for that choice (`UIArmory_LWMainMenu`, a `ModClassOverride` in
    `XComEngine.ini`).
- **Checked on wingpu** (test aid `rankup new 0`: a recruit with the experience for the first promotion): from the hub's
  barracks, the soldier list, the rookie's armory and PROMOTE SOLDIER, the chooser opened with Long War's classes
  (`logs/wingpu_commanders_choice.png`). Choosing Gunner made her a Gunner specialist with the Gunner's kit, on XCOM 2's
  promotion screen (`logs/wingpu_commanders_choice_promoted.png`).

## Report (2026-11-17, Perfect Information)

- **#28 Perfect Information** (`XComPresentationLayer.MSGArmorFragments` and `MSGOverwatchShot`, which Long War rewrote
  for it): as an enemy's shot is shown, its chance to hit is announced over the shooter in Long War's words ("<shooter> uses
  <shot> on <target>: n%"; for a reaction shot "<shooter> takes a reaction shot: n%"; `makePerfectInfoWords`, written on the
  player's machine).
  - **How:** the second-wave effect every unit carries listens for its unit's shots as their visualization begins
    (`ELD_OnVisualizationBlockStarted`) and shows XCOM 2's world message at once. Queued, as XCOM 2 queues one by default, it
    waited for the visualization to end and was not seen.
  - **The chance** is the one the shot was rolled with (its context's `CalculatedHitChance`).
- **Not ported:** Long War also shows Lightning Reflexes' chance when it is used.
- **Checked on wingpu** (new test aids: `use #<unit id> <ability> [target]` lets any unit act, an alien too, given an action
  point; `perfectinfo` counts and shows a test message): a Sectoid's shot announced "Sectoid uses Fire Weapon on Ayaka Tanaka:
  76%" over it (`logs/wingpu_perfect_information.png`).

## Report (2026-11-17, Itchy Trigger Tentacle; not yet seen)

- **#14 Itchy Trigger Tentacle** (`XComAlienPod`: on a pod's reveal, an alien that cannot take cover, is not melee only and
  sees a soldier shoots instead of moving, with a chance of 50 with the option): XCOM 2's scamper for aliens without cover
  (`ScamperRoot_NoCover`, `ScamperRoot_Overwatch`: the ADVENT MEC, Sectopod, Gatekeeper, Archon and the like, which stand
  in for Long War's drones, cyberdisks, floaters …) is given the shot first.
  - **The trees** are the port's own (`XComAI.ini`): `LWX2ScamperRoot_NoCover` and `_Overwatch` try `LWX2ItchyTriggerShot`
    first, then XCOM 2's root. That shot is XCOM 2's own second-wave condition (`SecondWaveOptionEnabled-
    LWSW_14_ItchyTriggerTentacle`), a 50% `RandFilter` and XCOM 2's `ShootIfAvailable`.
  - **The characters** that scampered with XCOM 2's roots are pointed at them (`strScamperBT`, which XCOM 2's AI player runs
    on a reveal: `XGAIPlayer`). The scamper's action point is a standard one, so a shot is possible.
- **Not seen in a mission yet.** A reveal could not be brought about by the control port:
  - a unit set on a tile in view is marked seen without a scamper;
  - XCOM 2's reveal call waits on a moving soldier;
  - a queued behaviour tree runs only in the aliens' turn.
  
  A real reveal of a no-cover pod needs the squad walked up to one over a few turns. Next time a mission meets one, the
  shot (and its Perfect Information line) is the check.
- **New test aids** (kept): `scamper #<group>` (a group's reveal), `bt #<unit> <tree>` (a tree queued for a unit), both
  limited as above.

## Report (2026-11-17, Recon; meld hidden in the fog without it)

- **#29 Recon** ("You will see meld cans and bomb nodes in the fog"; EW does this natively, no script reads the option).
  XCOM 2 shows a loot drop's marker anywhere, fog or not. So the port had always shown Long War's meld canisters from the
  start, as Recon does, while Long War without it hides them until seen.
  - **Without Recon:** a canister now waits unmade (`XComGameState_LWX2Meld`) until XCOM has seen its tile (its fog status,
    checked every two seconds with the mission's other updates: `LWMeld.Reveal`). It is then made with the turns it has
    left; one whose turn has passed unseen is gone.
  - **With Recon:** made at the start, as before.
  - **Bomb nodes** are pieces of EW's map in the port, seen through the fog either way; unchanged.
- **Checked on wingpu** (new test aid `meld`: the canisters made and those still hidden, with their fog): an abduction
  without Recon held its canister back ("hidden at 10 14 1, turns 5, fog NeverSeen"). When a soldier came into view of the
  tile it was made, "turns left 5", on turn 1. **Not seen:** Recon on (the code path that made them at the start, as before).

## Report (2026-11-17, Save Scum; not seen)

- **#5 Save Scum** ("Loading a save game will reset the random number seed, so taking an identical action may yield different
  results"; EW does this natively). XCOM 2 restores the random seed a save was made with (`Checkpoint.PostLoadCheckpoint`),
  so a reload replays the same rolls. With the option a new seed is drawn (`GetARandomSeed`) as the game comes up again:
  the Avenger's HUD in strategy, the tactical HUD in a mission (`LWX2SecondWave.SaveScum`). Both come up after the load, and
  at a mission's start too, where a new seed changes nothing already decided.
- **Not seen:** the check needs a quicksave and a quickload. XCOM 2's F5/F9 sent from here left the screen black and never
  reloaded (the soldier's action points stayed spent), so neither the option's effect nor XCOM 2's own replay was observed.
  To check by hand: in a mission, quicksave before a shot of about 50%, shoot, quickload, shoot again a few times. Without
  the option the result repeats; with it, it varies.

## Report (2026-11-17, Bronzeman Mode; mission restarts as Long War's)

- **Restart Mission as Long War offers it:** XCOM 2's pause menu has Restart Mission only in its first and final missions
  and never in Ironman. Long War offers it in every mission of a game not in Ironman ("Restarts are automatically enabled
  for non-Ironman games"). The port now adds XCOM 2's own item where XCOM 2 left it out, with XCOM 2's own question and
  restart (`UIScreenListener_LWX2PauseMenu`).
- **#16 Bronzeman Mode** ("Allows restart of tactical missions via pause menu in Ironman mode"): the same in Ironman. Its
  click goes to XCOM 2's question directly, since XCOM 2's own handler refuses a restart in Ironman.
- **A crash caught in testing:** the first version kept the pause menu in a variable of the listener. A screen listener is
  a default object outside the world, so that kept the mission's world alive through the restart's map change ("World …
  not cleaned up by garbage collection", the game closed). The listener now keeps nothing and looks the menu up when it
  needs it. The port's other listeners hold no such reference.
- **Checked on wingpu** (an abduction, not the campaign's first mission, not Ironman): the pause menu ends with Restart Mission
  (`logs/wingpu_pause_restart.png`). Its question is XCOM 2's (`logs/wingpu_restart_question.png`). Accepted, the mission
  restarted: a soldier moved four tiles was back where she began with both action points.
- **Not seen:** an Ironman campaign with Bronzeman (the same item and path).
