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
