---
title: "Long War's officers: the Officer Training School's officer ranks and their abilities"
status: planned
priority: 33
dependsOn: [lw-base, lw-classes, lw-missions]
---

# Long War's officers

The Officer Training School's squad sizes are in (`lw-missions.md`). Its
other five projects make officers. A soldier promoted to an officer rank
gains officer abilities, and a squad's officers bring their bonuses to the
mission.

## What Long War keeps (stock Long War 1.0)

- **The projects** (`OTSBalance`, eTech 3 to 7): Lieutenant §100, Captain
  §200, Major §300, Colonel §400, Field Commander §500. Each is available
  once the barracks' ranks add up to 20, 45, 75, 110 and 150.
- **Officers per rank** (`ContBalance_Classic[0]`, a reused array; its
  comment names the columns): 3 lieutenants, 2 captains, 2 majors,
  2 colonels, 1 field commander.
- **The abilities** (its `XComStrategyGame.int`, `OTSTechSummary`):
  - Lieutenant: Lead By Example (the officer's will to nearby soldiers,
    and the Command ability), and Legio Patria Nostra (will:
    `INTERNATIONAL_WILL`, 1 per nationality) or Stay Frosty (fatigue);
  - Captain: Semper Vigilans (defence) or Fortiores Una (cover damage
    reduction near the officer); +1 Command charge;
  - Major: Into the Breach (mission XP for lower ranks) or So Shall You
    Fight (kill XP); +1 Command charge;
  - Colonel: Band of Warriors (aim for continent bonuses) or Esprit de
    Corps (will and defence); +1 Command charge;
  - Field Commander: So Others May Live (aim and will after missions with
    no deaths) or Combined Arms (lower enemy damage reduction); +1 Command
    charge.

## Questions before building it

- How a soldier becomes an officer: a promotion chosen by the player,
  limited by the counts above?
- The abilities' numbers, beyond `INTERNATIONAL_WILL`: from Long War's code
  (as was done for psi and the bonuses), or its constants.
- How this sits with XCOM 2's ranks, which the classes already use.

## Note (2026-11-15, read from Long War's code)

Long War's officers are Enemy Within's medals, repurposed:
- Its officer abilities are EW's medal perks (`XGTacticalGameCoreNativeBase.IsMedalPerk`).
- The Officer Training School's officer projects unlock them, gated by the barracks' ranks
  (`XGTechTree.HasOTSPrereqs`, `GetNumMedalsAvailable`), with Sandhurst's cut.
- A soldier is made an officer on EW's medal screen (`UIMedals`,
  `UISoldierList_AssignMedal`).
- An officer's fatigue carries `SPECIES_POINT_LIMIT` hours per medal
  (`DetermineTimeOut`), with Gift of Osiris's cut.

So building this means porting the medal screen, each officer ability as a tactical ability,
and the medal count's place in fatigue. The person (2026-11-15) wants Long War's code
followed, so nothing here waits on him. Left for after the strategy screens (playability
first).

## Report (2026-11-16, the Officer Training School on EW's own screen)

The school's screen is Enemy Within's own (`UILWEWOTS`, its `OfficerTrainingSchool` movie,
driven as EW's `UIOTS` drives it), from the hub's Barracks room once the school is built,
with EW's base behind it through the barracks' camera.
- Long War's seven projects in its order, with Long War's names and summaries from the
  player's install (`makeOTSWords`, 20 words): Squad Size I and II, Tactical, Company,
  Field and Regimental Officers, Commanding Officer.
- The barracks' total ranks in the header (EW's "TOTAL RANKS"), each project's cost, in red
  where it can't be bought; the selected one's reason, the ranks it needs and its summary in
  the info panel.
- Squad Size I and II are bought there, in order, after EW's own confirmation ("Acquire the
  Squad Size I upgrade for §200?"), on the rules that were already in (cost, ranks, Special
  Warfare School, Sandhurst).
- The officer projects' prices and ranks come from stock Long War's `OTSBalance` (eTech 3 to
  7: §100/20 ranks, §200/45, §300/75, §400/110, §500/150), now in `XComLWStrategy.ini` as
  `OfficerProjects`.

Checked on wingpu: Squad Size I bought from the screen (§500 → §300, squad size 7, the row's
cost cleared and "Bought."); the officer projects listed in red with their reason
(`logs/wingpu_ew_ots.png`, not committed).

### Decisions

- The five officer projects show but can't be bought until officers are in ("Officers are
  not in the port yet."): the school reads as Long War's, and nothing is sold that does
  nothing.
