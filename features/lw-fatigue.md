---
title: "Long War's fatigue: soldiers out of action after a mission"
status: review
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
- **A way to have both answered at once** (proposed 2026-11-04): Long War's hours shown through War
  of the Chosen's own "Tired" state. XCOM 2's squad selection, barracks and soldier screens already
  show Tired and let a Tired soldier be sent, as Long War lets a fatigued one go "all in". Long War's
  rules decide who is Tired and for how long; XCOM 2's will loss per mission stops driving it.
  That is "in place of", with XCOM 2's screens; "beside" would need marks of the mod's own.

## Plan (proposed)

1. Each soldier's fatigue as a value on the unit (hours until rested, and whether all in),
   set when a mission is back (where the mission's loot and wounds are handled), counted down
   with the campaign's hours.
2. The squad selection marks fatigued soldiers; sending one makes them all in.
3. The all-in cost (1 maximum HP).
4. War of the Chosen's own fatigue switched off (its will loss on missions), if so decided.

## Response (2026-11-04)

The person: Long War's fatigue **in place of** War of the Chosen's (the proposal: Long War's
hours shown as War of the Chosen's "Tired").

## Report (2026-11-04 night, Long War's fatigue in place of War of the Chosen's)

- **Built** (`LWFatigue`), as the Response chose: when the Geoscape opens after a mission, each soldier
  who came back rests Long War's hours (96 and a roll up to 47 more; 144 if hurt or all in; a wounded
  soldier's healing on top), shown as War of the Chosen's **Tired**: the will set to the top of the
  Tired band (so the squad screens show Tired and still let the soldier be sent), XCOM 2's own will
  recovery taken off; each hour of Long War's clock, a soldier whose hours are over has full will
  again (Ready). A soldier still resting when a mission starts goes **all in**: one point of maximum
  health lost (down to 1) and the longer rest. XCOM 2's will loss over a mission is overwritten (in
  place of it); its in-mission will tests stay.
- **Seen** (a new campaign; the squad tired by a test aid, `tire <hours>`; an abduction won):
  "Killian Daly goes all in", back "rests 144 hours, went all in (maximum health now 4)"; the others
  102 to 141 hours; each "rested, ready again" at their hour, once; a soldier tired but not sent still
  Tired eight days on. Before that, a plain mission: the six of the squad Tired, a hurt one "rests 144
  hours after 237 of healing".
- **Psi powers and gene mods** add their own hours (`ItemBalance_Easy`'s `iEng`: 24, 6 or 12 a power,
  3 to 12 a mod; 22 lines generated into `XComLWStrategy.ini`, `+PerkHours`), each the soldier has
  (`HasSoldierAbility`, as the wounds' Bone Marrow check). Not seen in a game yet (a soldier with a
  power or a mod needs the labs).
- **Not yet:** officers' and critical wounds' hours, the psi armour's none, the country bonuses that
  lessen the powers' hours.
- **The days shown:** XCOM 2's Tired label takes its days from any will-recovery project naming the
  soldier; one is kept for each resting soldier, outside the headquarters' projects (XCOM 2 neither
  advances nor completes it), completing at Long War's hour. Seen (control aid `crew`, XCOM 2's own
  label): "Tired 6 Days", "Tired 4 Days" after a mission; none Tired eight days on.
