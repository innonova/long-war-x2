---
title: "Long War's fatigue: soldiers out of action after a mission"
status: planned
priority: 3
dependsOn:
  - lw-classes
---

## Purpose

Long War's campaign turns on rotating squads: after a mission every soldier who came back
is fatigued for days, can still be sent, and pays for it. The port has none of this yet
(STATUS: Fatigue, none); XCOM 2 War of the Chosen has a fatigue of its own (will lost on
missions, Tired and Shaken), which is not Long War's.

## Long War's rules, as read (2026-11-04)

From Long War's code (`XGFacility_Barracks.DetermineTimeOut`, `HealAndRest`; read with upkit's
decompiler, kept out of the repository) and its `DefaultGameCore.ini`:
- After a mission, each soldier back unhurt is out of action (`m_iTurnsOut`, hours):
  - 96 + a roll of 0 to 47 hours; 144 if they were already fatigued when sent ("all in", who also
    lose 1 maximum HP, down to 1) or were hurt;
  - plus 12 hours per officer rank (`SPECIES_POINT_LIMIT`, by the medal count);
  - plus each psi power's and gene mod's own hours (the `iEng` column of their `ItemBalance_Easy`
    lines: 24, 6 or 12 for the powers, 3 to 12 for the mods), lessened by the country bonuses
    that say so;
  - plus 24 hours per critical wound the soldier ever had (`CB_AIRANDSPACE_BONUS`);
  - the total scaled by `RAND_DAYS_INJURED_TANK` per cent (100);
  - 24 hours less with one perk (perk 122), none at all in one armour (item 65).
  - SHIVs: 24 + a roll of 0 to 23. MEC troopers: 120 + a roll of 0 to 23 (144 if all in or hurt).
- Each hour counts down; at 0 the soldier is active again (`HealAndRest`).
- Sending a fatigued soldier ("all in") costs 1 maximum HP each time (a stat modifier, down to
  1 HP) and the longer rest afterwards. `XGUnitNativeBase.GetBattleFatigueWillPenalty`, despite its
  name, is about wounds in battle (will −5 below full health, −10 below half), not this fatigue.

## To decide

- **Long War's fatigue in place of War of the Chosen's,** or beside it. XCOM 2's own (will
  lost per mission, Tired soldiers) would double the cost of a mission if kept; Long War's is
  what Long War is balanced around.
- Where the player sees it: the squad selection (a fatigued soldier marked, with the hours
  left), the barracks' list and the soldier's screen.

## Plan (proposed)

1. Each soldier's fatigue as a value on the unit (hours until rested, and whether all in),
   set when a mission is back (where the mission's loot and wounds are handled), counted down
   with the campaign's hours.
2. The squad selection marks fatigued soldiers; sending one makes them all in.
3. The all-in cost (1 maximum HP).
4. War of the Chosen's own fatigue switched off (its will loss on missions), if so decided.
