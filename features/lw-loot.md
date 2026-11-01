---
title: "Long War's loot: what missions bring back"
status: in-progress
priority: 2
dependsOn:
  - lw-geoscape
  - lw-research
---

## Purpose

Long War's research and engineering are paid for in what missions bring
back:
- alloys and elerium;
- weapon fragments;
- a UFO's artifacts (power sources, navigation computers…);
- corpses and captives.

Without loot the tree stops at its first steps (`lw-research.md`). This
feature brings Long War's loot to the missions the Geoscape sends.

## What the person should see

After a crash site or landed UFO is taken, the salvage lands in XCOM's
stores (XCOM 2's inventory) in Long War's amounts, with a crash leaving
less. After any mission, the aliens killed leave corpses and weapon
fragments in Long War's way. Research that needs them can then start.

## Requirements

- **Long War's numbers, generated** from its `DefaultGameCore.ini` and its
  code (`XGItemTree.DetermineShipSalvage`, `XGStrategyAI.DetermineCrashLoot`,
  and the kill loot's own code).
- **Long War's artifacts become XCOM 2 resource items.** XCOM 2's own
  are used where it has them: alloys, elerium, weapon fragments. Their
  names and texts are Long War's, written on the player's machine.
- **Then enforced in research:** fragments, consumed items, and what
  must have been held or captured.

## Report (2026-11-01, phase 1: UFO salvage)

- **A UFO's salvage** (generated into `XComLWStrategy.ini` as `+Salvage`):
  - each type's artifacts as Long War's `DetermineShipSalvage` gives them
    (a Transport: 4 navigation computers, 4 power sources, 2 surgery, 8
    stasis tanks, 10 food, 2 entertainment);
  - its alloys: `UFOAlloys` by size × `ALLOY_UFO_BALANCE` (by difficulty);
  - its elerium: power sources × `UFO_ELERIUM_PER_POWER_SOURCE`;
  - 20 % more alloys and elerium once its UFO analysis is researched.
- **A crash** (`DetermineCrashLoot`):
  - 30–45 % of the alloys survive;
  - each artifact survives at its own chance (power source 20 %,
    navigation 25 %, stasis 30 %, surgery 30 %, food 50 %, entertainment
    100 %);
  - 70–100 % of a power source's elerium is lost with each power source
    destroyed.
- **Paid** when a crash site or landed UFO is won, from a real mission
  or from `resolve` and `auto`, and noted in the Geoscape's events.
- **The artifacts are XCOM 2 resource items** (`X2Item_LWArtifacts`,
  `LWItem_<Long War's name>`), with names, plurals and summaries from Long
  War's localization (`makeItemWords`).

**Checked** (new campaign, simulated by `auto`):
- After three more months with every mission won, the stores held 420
  alloys, 14 navigation computers, 2 power sources and 6 alien surgery,
  among others.
- Alien Materials, which costs alloys and elerium, became affordable.

### Decisions

- **The salvage table is written out in the generator, with its source,
  rather than parsed from bytecode**, like the ship table. It is short,
  and the parse would be fragile.
- **A landed UFO taken gives its full salvage.** Long War also counts
  what the fight destroyed. Our missions are XCOM 2's maps with XCOM 2's
  aliens, so there is nothing to count yet.

### Left open

- **The rest of the loot:**
  - kills: corpses, captives and weapon fragments;
  - abduction and terror rewards;
  - the damaged artifacts a crash leaves, which only sell.
- **Research gates** (fragments, consumed items, held or captured) are
  still not enforced: next, once kills bring fragments and corpses.
- **Selling artifacts** (Long War's grey market).
