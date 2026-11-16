---
title: "Long War's SHIVs and MECs: robots built in engineering, soldiers augmented in the Cybernetics Lab"
status: in-progress
priority: 35
dependsOn: [lw-base, lw-classes, lw-gear, lw-ew-units, lw-squad-select]
---

# Long War's SHIVs and MECs

The port has neither (STATUS: "MECs, SHIVs, cybernetics: none"). In Long War both are a
large part of the mid game: SHIVs are cheap robots that take the point and soak fire;
MECs are soldiers who give up their limbs for a suit, a heavy weapon and a subsystem, in
eight classes of their own. Aliens and Foundry projects already refer to them (Long War's
damage reduction, the officers' and bonuses' left-open lines).

## What Long War does (stock Long War 1.0, read 2026-11-16)

From its `DefaultGameCore.ini` and the Tree's `data/itemtree.json` (read from
`XGItemTree.BuildItems`); code to be read as each phase needs it.

**SHIVs**
- Three bodies, built in engineering as items (category 3): **SHIV** (§60, 10 days, 15
  engineers), **Alloy SHIV** (§250, 80 alloys, 15 days; the tech `eTech_Placeholder_12`,
  Long War's id 72), **Hover SHIV** (§300, 40 elerium, 60 alloys, 14 days; Archangel Armor).
- Each body is a "deck", an armour (`Armors`, `eAP_Tank`, immune to fire): deck I +2 HP,
  +12 defence, +3 mobility, 3 small items; deck II +4 HP, +8 defence, +2 mobility; deck III
  flies (`eAbility_Fly`, 6 fuel, `eAP_AirEvade`), +2 HP, +12 defence, +5 mobility. Base HP
  bonuses that need repair: Alloy +10, Hover +6 (`ALLOY_SHIV_HP_BONUS`, `HOVER_SHIV_HP_BONUS`).
- The SHIV itself: `Characters` `eChar_Tank`: 8 HP, aim 70, defence 0, mobility 14, sight 27,
  no will.
- Weapons: SHIV Minigun (free), Sentry Gun (§100, 10 elerium, 32 alloys), SHIV Laser (§300),
  SHIV Plasma (§450); Foundry: SHIV Suppression (project 16), SHIV repair in missions
  (project 8), "SHIV" (project 1); bonuses: Ghost in the Machine (aim, two free SHIVs),
  Robotics (aim for new SHIVs and MECs), NeoPanzers (SHIV and MEC weapons cheaper).
- Repair: `BASE_DAYS_INJURED_TANK` 24 hours; SHIVs have no ranks, no will, no fatigue scaler
  (`RAND_DAYS_INJURED_TANK` 100%).

**MECs**
- The Cybernetics Lab (a facility) augments a soldier (meld and cash, days; three at a time,
  `PSI_NUM_TRAINING_SLOTS`); the soldier becomes the MEC class of their own class
  (`MEC subclass = soldier subclass + 20`): Jaeger (Sniper), Pathfinder (Scout), Archer
  (Rocketeer), Goliath (Gunner), Guardian (Medic), Shogun (Engineer), Marauder (Assault),
  Valkyrie (Infantry), each with its stat gains and perk tree.
- Six suits (`Armors`, `eAP_MEC`, immune to poison and fire): MEC-1 Paladin +8 HP +8 def,
  MEC-2 Defender +12 HP, MEC-3 Valiant, MEC-4 Dauntless, MEC-5 Devastator, MEC-6 Vanguard;
  each with large and small item slots.
- Weapons: Minigun, Railgun, Particle Cannon; subsystems: Kinetic Strike, Flamethrower,
  Grenade Launcher, Restorative Mist, Electro Pulse, Proximity Mines.

## Phases

1. **SHIVs as units**: built in engineering, a SHIV joins the barracks as a robot of its
   own (its deck's stats), goes on missions in Enemy Within's SHIV body (converted from the
   player's install, as the aliens' are), with the Minigun; repaired between missions.
2. **SHIV weapons and decks**: the Sentry Gun, Laser and Plasma; the three decks; the
   Hover SHIV's flight; the Foundry projects and bonuses that touch SHIVs.
3. **The Cybernetics Lab and MEC troopers**: augmentation, the eight MEC classes and their
   trees, the suits and EW's MEC bodies.
4. **MEC weapons and subsystems.**

## Plan for phase 1 (2026-11-16)

- A character template `LWSHIV` on XCOM's side: a soldier XCOM 2 can put in a squad
  (as War of the Chosen's SPARKs are: `bIsSoldier`, `bIsRobotic`), a soldier class of its own
  without ranks, its stats Long War's (`eChar_Tank` plus the deck), no will, no panic.
- Its pawn: XCOM 2's ADVENT MEC pawn (a robot's walk, cover and death), with EW's SHIV body
  and animations put on it the way the aliens' are (`ew-units.ts`, `LWX2EWBodies`).
- Engineering: building a SHIV item adds the unit to XCOM's crew.
- In the armory and squad select as XCOM 2 shows any soldier; to be seen what breaks for a
  robot there.

## Report (2026-11-16, phase 1 begun: SHIVs as units)

- **The numbers:** `scripts/shivs-config.mjs` writes `Config/XComLWSHIVs.ini` (`LWSHIVs`) from
  Long War's config: the SHIV's stats, the three bodies with their decks and repair hit points,
  the four weapons, the repair hours. In `config-all.sh`.
- **The units:** `X2Character_LWSHIV` makes a character per body (`LWSHIV`, `LWSHIV_Alloy`,
  `LWSHIV_Hover`): a soldier and a robot on XCOM's side, on the ADVENT MEC's pawn, Long War's
  stats: **SHIV 10 HP, aim 70, defence 12, mobility 17; Alloy SHIV 22 HP, defence 8, mobility 16;
  Hover SHIV 16 HP, defence 12, mobility 19**; no will. Their class, `LWS_SHIV`
  (`classes-config.mjs`), has no ranks, is never dealt to a recruit, carries only SHIV weapons
  and no armour of XCOM 2's.
- **The weapons:** `X2Item_LWSHIVWeapons`, Long War's four (the Minigun 7 damage and 3 shots,
  Sentry Gun 9, Laser 10, Plasma 11) with the ADVENT MEC's gun as their look. Each SHIV comes
  with the Minigun.
- **Engineering** lists the three bodies (Long War's costs and days; the Alloy SHIV after its
  research, the Hover SHIV after Archangel Armor); a finished SHIV joins the crew
  (`LWEngineering.Deliver`, `LWSHIVs.AddSHIV`).
- **Kept out of what is for people:** Long War's recruit stats and bonuses, the Psi Labs, the
  Genetics Lab, officer promotion, EXALT's operatives.

**Checked on wingpu** (the control port's `shiv add`): the three bodies in the crew with the
stats above, ready for duty; two in a mission's squad, on XCOM's side, selectable, the ADVENT
MEC's gun in hand, at full health (Long War's recruit stats had first cut them to 4 and 5).

**Next:** EW's SHIV bodies on them; squad select and the armory with a SHIV; a SHIV built by
engineering on the screen; repair after a mission.

Control port: `shiv` (XCOM's SHIVs and their stats), `shiv add [body] [front]` (one built at
once; front: first in the next mission's squad).

## Report (2026-11-16, EW's SHIV bodies)

The three SHIVs are drawn as Enemy Within's: `ew-units.ts` converts EW's `Unit_XComTank_SF`
(the SHIV), `Unit_XComTank2_SF` (the Alloy SHIV) and `Unit_XComTank3_SF` (the Hover SHIV) from
the player's install, with EW's SHIV Minigun (`Weapon_ShivMinigun_SF`), as it does the aliens'.
Their animations answer to the ADVENT MEC's names (a new `animsAs`: the mod's templates play on
the ADVENT MEC's pawn): 79 of its 81 names from EW's 42 SHIV animations. The setup does this
with the other units, so a player's next setup brings them.

**Seen on wingpu:** the three in a mission's squad in EW's bodies (the two tracked SHIVs and the
round Hover SHIV), at full health. Screenshot (gitignored): `logs/wingpu_shivs_ew_bodies.png`.

**Not looked at yet:** the treads' material (the stand-in takes the body's texture for every
material of the mesh), the gun's place on the body, the animations in motion.

## Report (2026-11-16, SHIVs in the campaign: names, rest, repair)

- **Long War's words:** the bodies' names (SHIV, Alloy SHIV, Hover SHIV), the weapons' (the
  Autocannon, Sentry Gun, Superheavy Pulser, Superheavy Plasma) with Long War's summaries, the
  class and rank "SHIV" (`lw-words.mjs`, `makeSHIVWords`; the setup passes `XComLWSHIVs.ini`).
  A SHIV is named in one part, "SHIV #1", "Hover SHIV #2", since XCOM 2's lists show a last name.
- **Rest after a mission** (`XGFacility_Barracks.DetermineTimeOut`'s tank part): 24 hours plus up
  to 24, whatever it did; never all in. Shown as War of the Chosen's Tired, set directly (a SHIV
  has no will to set it by).
- **Repair** (the same function): 24 hours per hit point lost, twice that per point below a
  quarter of its health, plus up to half of that (at least 96); two thirds of it with the
  Foundry's Vehicle Repair. The numbers are in `XComLWSHIVs.ini` (code numbers marked so).
- **No experience** for SHIVs (Long War's tanks never rank up).

**Checked on wingpu:**
- squad select in EW's hangar with two SHIVs: "SHIV #1" and "HOVER SHIV #2", rank and class
  SHIV, the Autocannon as primary weapon;
- a mission won with an Alloy SHIV down 6 of 22: "out 234 hours" (6 × 24 + 90), resting 26 hours
  after; the unhurt SHIV rested 45 hours and was ready again when they were over;
- engineering: a SHIV begun on the first day ("done in 15 days" with the starting engineers),
  built on day 16, in the crew ready for duty.

### Decisions

- **No cover for SHIVs**: they play on the ADVENT MEC's pawn, which takes none. (Corrected
  2026-11-16: this first said EW's SHIVs took cover; they do not. Long War's `XGUnit.StartProvidingCover`
  has the Alloy SHIV, `ePawnType_Tank2`, give cover to the soldiers beside it, and a MEC with One For
  All; that is left open.)
- **Squad select shows the ADVENT MEC's body**: EW's bodies are put on units in missions only;
  the strategy pawns are XCOM 2's.

## Report (2026-11-16, SHIVs in squad select and the armory)

- **EW's bodies off the battlefield too:** squad select's line-up in EW's hangar and the armory's
  platform show a SHIV in Enemy Within's body (`LWX2EWBodies.ApplyToPawn`), as missions do.
- **The armory for a SHIV:** only the loadout and dismissing; customizing, combat sims, weapon
  upgrades, promotion, the photo booth and bonds are greyed (`UIScreenListener_LWX2SHIVArmory`).
  Framed as XCOM 2's large units (`bIsTooBigForArmory`). The loadout offers the SHIV weapons
  built (the Sentry Gun equipped in place of the Autocannon, checked).
- The armory's platform was empty when opened from squad select (the pawn was made at the world's
  origin while the armory's room was hidden): it is put on its platform now (`LWX2DisplayWatch`),
  soldiers and SHIVs alike.
- Engineering also builds the SHIV weapons (Sentry Gun, Superheavy Pulser, Superheavy Plasma) at
  Long War's costs and with their research; NeoPanzers takes its share off them, as it already did.

Screenshots (gitignored): `logs/wingpu_shivs_squad_select.png`, `logs/wingpu_shiv_armory.png`.

### Left open (SHIVs)

- The Alloy SHIV giving cover to soldiers beside it (Long War's `StartProvidingCover`), and a MEC with One For All.
- The Hover SHIV's flight (its deck's `eAbility_Fly`, 6 fuel).
- ~~The Foundry's SHIV projects~~ (below); the Arc Thrower's field repair (Field Repairs, 8), Ghost
  in the Machine's two free SHIVs and aim, Robotics' aim.
- Engineering's screen shows the bodies by their character names; their pictures are XCOM 2's
  default.

## Report (2026-11-16, the Foundry's SHIV projects)

As Long War's `XGFacility_Barracks.UpdateFoundryPerksForSoldier` gives a tank its Foundry
projects, a SHIV gets in a mission (XCOM 2's `FinalizeUnitAbilitiesForInit` hook,
`LWSHIVs.AddFoundryAbilities`):
- **SHIV Suppression** (16): XCOM 2's Suppression with its primary weapon;
- **Advanced Servomotors** (21): Sprinter (Long War's perk 31);
- **Sentinel Drone** (23): Repair Servos (perk 139; a stand-in without effect yet, as the
  Mechtoid's).

Checked on wingpu: with 16 and 21 done (the control port's `foundry done`), a SHIV in a mission had
Suppression, SuppressionShot and LW_Sprinter beside its shot and overwatch.

## Plan for phase 3, MEC troopers (2026-11-16)

Long War (read from its code, `XGFacility_CyberneticsLab`, `XGStrategySoldier.SetSoldierClass`, and
its config): the Cybernetics Lab augments a soldier for §40 and 60 meld in 10 days
(`m_iModCashCost`, `m_iModMeldCost`, `m_iModDays`), three at a time; the soldier comes out as the
MEC class of their own (`MEC subclass = soldier subclass + 20`: Jaeger, Pathfinder, Archer,
Goliath, Guardian, Shogun, Marauder, Valkyrie), one rank lower, with the soldier's base stats again
(+4 HP), their perk tree that class's (`SoldierPerkTrees` 31-34, 41-44; stat gains
`SoldierStatProgression` of the same ids), never psionic, in a MEC suit (`eAP_MEC`: immune to
poison and fire; MEC-1 Paladin to MEC-6 Vanguard, built in engineering) with a MEC weapon (MEC
Minigun 7, Laser Lance 8, Railgun 9, Pulse Lance 10, Particle Beam 11).

**Decision: a MEC trooper is a unit of its own** (character template `LWMEC`, on the ADVENT MEC's
pawn as the SHIVs are, later in EW's MEC bodies), made when augmentation ends from the soldier
(name, nickname, country, rank less one, kills and missions carried over) in place of the soldier.
XCOM 2 cannot change a unit's character template (`m_TemplateName` is protected), and a soldier's
body is its appearance; the SHIVs show the way that works. XCOM 2's SPARK is in its DLC, which a
player may not have.

Steps: (a) the eight MEC classes in `XComClassData.ini` (`classes-config.mjs`), the suits and
weapons as config and templates; (b) the Cybernetics Lab's augmentation and the MEC unit; (c) EW's
MEC bodies; (d) the subsystems (phase 4).

## Report (2026-11-16, MEC troopers: steps a and b)

- **The eight MEC classes** (`classes-config.mjs`): Jaeger, Pathfinder, Archer, Goliath, Guardian,
  Shogun, Marauder, Valkyrie with Long War's perk trees (`SoldierPerkTrees` 31-34, 41-44) and stat
  gains; never dealt to recruits; MEC weapons and suits only. Their new perks (Automated Threat
  Assessment, Advanced Fire Control, Damage Control …) are named stand-ins for now.
- **Suits and weapons** (`scripts/mecs-config.mjs` → `XComLWMECs.ini`; `X2Item_LWMECGear`,
  `X2Ability_LWMECSuit`): Long War's seven MEC suits (HP, defence, mobility, will; immune to fire
  and poison) and five MEC weapons (Minigun 7 to Particle Beam 11). Engineering builds them at
  Long War's costs, with their research and the suit each upgrades from; the first suit and the
  Minigun come with every MEC.
- **The Cybernetics Lab:** Engineering → **Augment Soldiers** (EW's words, once the lab is built)
  opens XCOM 2's soldier list of those Long War lets be augmented (ready, a Long War class, not an
  officer, not psionic, no gene mods), then a confirmation with the MEC class, §40, 60 meld and 10
  days (`UIPersonnel_LWAugment`, `LWMECs.StartAugment`); three places a lab.
- **The MEC trooper** (`X2Character_LWMEC`, `LWMECs.AugmentDone`): when the days are over, a unit
  of its own in the soldier's place, the soldier's name, nickname, country, kills and missions,
  one rank lower, the MEC class of their own, Long War's soldier base stats with 4 more HP, the
  first suit and the Minigun; the soldier leaves the crew. On the ADVENT MEC's pawn for now.
- Kept out of the recruit stats and bonuses, gear arming (the SHIVs too: they had been given a
  medikit and soldier armour), the Psi Labs, the Genetics Lab and officer promotion.

**Checked on wingpu:** Engineering showed AUGMENT SOLDIERS; the list, the confirmation ("LCPL Ella
Goosens -> Pathfinder, §40, 60 Meld, 10 Days"; `logs/wingpu_mec_augment.png`); confirmed, the lab
held the soldier 240 hours; ten days on: "César Moreno came out of the Cybernetics Lab a Jaeger",
rank 1, his 2 kills and 1 mission kept, suit and Minigun; in a mission, 17 HP (9 and the suit's 8).

Control port: `mec` (the lab and the MECs), `mec can` (who may be augmented and why not),
`mec augment #<id>`, `mec done` (the lab's work finished), `mec make` (a MEC at once, first in the
next squad).

**Next:** EW's MEC bodies (step c); subsystems (phase 4).

## Report (2026-11-16, EW's MEC bodies tried, left out)

The converter learnt what EW's MECs need: a body chosen by the suit worn (`LWX2EWBodies` `Armor`;
Mark I for MEC-1, Mark II for MEC-2 and -3, Mark III from MEC-4) and an AnimSet in another package
(EW keeps the MECs' animations with the MEC Minigun: `setsPkg`). On wingpu the first try turned the
whole picture black once the MEC moved; with its animations re-encoded per track (as the
Cyberdisc's) the picture stayed, but the MEC's mesh came out torn into a disc of spikes on the
ADVENT MEC's pawn (`logs/wingpu_mec_ew_body_broken.png`): EW's MEC skeleton is not the ADVENT
MEC's, and the animations named for it do not drive it whole.

**So the MECs keep XCOM 2's ADVENT MEC body for now**; EW's suits are listed apart in the converter
(`EW_MEC_SUITS`, not converted) for that work. The armour-chosen body and the AnimSet from another
package stay in the converter and `LWX2EWBodies` (a SHIV or alien could use them).

## Report (2026-11-16, phase 4 begun: MEC subsystems)

Five of Long War's six MEC subsystems are small items only the MEC classes carry
(`lw-gear.mjs` `SMALL`, `mec`), with Long War's numbers from their `Weapons=` lines (damage, range
11 tiles, radius) and built in engineering at its costs, each acting as an XCOM 2 item does:
- **Grenade Launcher**: a frag grenade's throw (4 damage, radius 4);
- **Proximity Mine Launcher**: XCOM 2's proximity mine (10 damage);
- **Flamethrower**: a firebomb (5 damage);
- **Electro Pulse**: an EMP grenade (6 damage);
- **Restorative Mist**: a medikit's heal.

A MEC suit gives a second utility slot (a subsystem and an item, or two subsystems).

**Checked on wingpu:** a MEC with the Grenade Launcher had ThrowGrenade and GrenadeFuse in a
mission and threw it at a Sectoid.

### Decisions

- **XCOM 2 items stand in for EW's abilities** (approximations): EW's flamethrower is a cone from
  the MEC, its electro pulse a burst around the MEC that hits robots, its mist heals allies around
  the MEC each turn; here they are thrown or used on one ally. The numbers are Long War's.

### Left open

- **Kinetic Strike** (12 damage, melee): no XCOM 2 counterpart without a melee weapon; not in yet.
- The subsystems' charges by Long War's perks and Foundry projects (one each for now).
- EW's MEC bodies (above).

## Report (2026-11-16, Kinetic Strike)

The **Kinetic Strike Module** is a MEC subsystem now (`LWMEC_KineticStrike`, a utility slot, MEC
classes only): XCOM 2's sword slice (move and strike an adjacent enemy) with Long War's 12 damage,
built in engineering at Long War's cost. Checked on wingpu: a MEC beside a Drone struck it ("SwordSlice
on AdvMEC_M1 hit"). The grey market sells the robots' gear under its own templates now (it had
named items that do not exist for the MEC suits and weapons, the Sentry Gun and the module).

## Report (2026-11-16, MECs' rest and repair)

A MEC trooper rests Long War's own hours after a mission (`DetermineTimeOut`, `IsAugmented`):
144 if it went all in or was hurt, else 120 and up to 24 more; nothing for officer ranks or
perks. Its wounds take four fifths as long once the Foundry's Vehicle Repair is done. Checked on
wingpu: a MEC back from a won mission rested 137 hours (the soldiers beside it 102 and 106).

## Report (2026-11-16, EW's MEC bodies in)

MEC troopers are drawn in **EW's MEC suits** now: Mark I for MEC-1, Mark II for MEC-2 and -3,
Mark III from MEC-4. The suit worn picks the body. The setup converts them with the other EW bodies;
`EW_MEC_SUITS` is in the default conversion.

**The torn mesh** came from XCOM 2's ADVENT MEC animations playing alongside EW's on EW's
skeleton. The two rigs share bone names but not poses. A body can now be set to play **EW's
animations only** (`OwnAnimsOnly`): the pawn's other AnimSets are removed, and removed again
whenever XCOM 2 puts them back.

Three things followed from that:
- **Squad select** gives its pawns back XCOM 2's sets when it starts their idle, which left the MEC
  in its rest pose. `UILWSquadSelect` now re-applies the bodies twice a second.
- **Idles by name:** XCOM 2's strategy screens play idles by name: the personality's in squad
  select and customisation, and "standing still" on the promotion screen. EW's MEC had none of
  these names. The converter now copies EW's idle under them for bodies that play EW's animations
  only (`STRATEGY_IDLES`).
- **The gun:** EW's MEC holds its gun on its `Inven_R_Hand` bone, which EW's animations move.
  XCOM 2's ADVENT MEC gun hangs from the bone of the same name, so it stood at the feet while no
  animation played. It is now drawn as **EW's MEC Minigun** on strategy pawns too
  (`SeatWeapons`, `DressWeapon`). A weapon that hangs from no bone of the body is put in that
  socket; any other loose weapon is hidden.

**MEC suit and weapon names:** squad select had shown "Error! LWMEC_Weapon_28 has no…". They now
carry Long War's names and summaries (`makeMECWords`, 13 words: 7 suits, 5 weapons, Kinetic
Strike). `XComLWMECs.ini` carries each item's `Enum=` for this.

**Checked on wingpu** (Mark I, a new campaign, a MEC made with `mec make`):
- **In a mission:** the MEC walked whole and shot (`StandardShot hit`, before the gun change).
  With the last build it stands in EW's idle, gun arm raised.
- **Armory:** the MEC stood on the platform, posed, menu and header up. That was before the gun
  change.
- **Squad select:** EW's idle, with EW's minigun in its hand.

**Not checked:**
- Mark II and III on screen.
- A shot or Kinetic Strike with the last build.
- The armory after the gun change.

Test aid: `anims -10` (and `-11` …) reads squad select's line-up pawns: their sets, and what
plays.

**A test pitfall, not a fault:** opening the hub, a room and an option in quick succession with
the control port (`'open hub' 'hub 2' 'hub option 0'` in one call) leaves the hub's start-up
timer to show the base again over the soldier list. The armory then opens behind the Avenger's
overview, with no menu. With a moment between the steps, and by mouse, the armory opens right.

## Report (2026-11-16, the Alloy SHIV as cover)

The **Alloy SHIV is high cover** for the soldiers beside it, as in Long War. Long War's
`XGUnit.StartProvidingCover` counts the SHIV's pawn as cover and rebuilds the tiles around it.
XCOM 2 builds cover from the level's geometry only, so here it is **a rule on the shot**
(`X2Ability_LWMobileCover`, `X2Effect_LWMobileCover`, a hidden passive on the soldiers). It applies
to a soldier on a tile beside the SHIV, north, south, east or west on the same floor (not
diagonally), when the shot comes from the SHIV's side (the half-plane cover faces):
- the attacker's aim is lowered by XCOM 2's high cover bonus, less any cover the soldier already
  has from that side;
- a flanked soldier is no longer flanked: the attacker's flanking aim and crit are taken off again;
- Long War's damage reduction counts it as high cover (`CoverReduction`).

Melee and shots that fall from above are not affected, as with cover. The modifier carries Long
War's name, "Armored Shell" (`m_strShivCoverName`, `makeMobileCoverWords`).

**Checked on wingpu** with a Sectoid six tiles east of an Alloy SHIV, on open ground (control
port `hit`):
- the soldier west of the SHIV, and the one south of it, had 38% and 34% to be hit, no crit:
  Armored Shell -40 aim, -33 crit;
- the soldiers diagonal to it or away from it had 73–77%, 33% crit, flanked;
- a 6-damage hit left 5 on the two beside it (cover's 1), 6 on the others.

**Not done:**
- The soldier's cover shields in the HUD still show what the map gives; the rule acts on the
  shot only.
- The AI does not move to the SHIV's side for cover; Long War's aliens never had a SHIV.

**One For All:** it shares Long War's code with the Alloy SHIV's cover, but no Long War MEC tree
has the perk. It is EW's MEC perk, which Long War's trees replaced. My earlier note that a MEC
with One For All gives cover was about a code path no Long War MEC reaches, so there is nothing
of it to port.

Test aid: `hit <attacker #id> <target #id> [ability]` shows a shot's chance, crit and reasons.

## Report (2026-11-16, the Hover SHIV flies)

The **Hover SHIV flies**. Its character uses XCOM 2's flying traversal
(`bCanUse_eTraversal_Flying`, as Archons have), so its paths go up and over what others must
walk round.

**Checked on wingpu:** in a mission it moved eight tiles to a tile five floors up, then down to the
street. The paths completed and the turn went on. Its body is EW's hover SHIV, which looks right
afloat.

### Decision

- **Flight with no fuel.** In EW and Long War the Hover SHIV's deck gives Fly, an activated
  ability with 6 turns of fuel, like Archangel armour. XCOM 2 has no player flight with fuel.
  Here the Hover SHIV may always fly, as XCOM 2's flyers do. It is a simplification: a Long War
  Hover SHIV runs out of fuel and lands. Posted as a decision in the chat.

### Not checked

- How the body looks while climbing. The camera did not follow the move, and EW's hover SHIV
  has no flight animations of its own to play.
