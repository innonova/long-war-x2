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

## Report (2026-11-01, phase 2: the aliens, their loot; research's gates enforced)

**Long War's squads** (`LWAlienSquads`, ported from `XGStrategyAI` and
XComGame's `XGBattleDesc`):
- **The squad code:**
  - every UFO type's crew (`DetermineSmallScoutSquad` …
    `DetermineOverseerSquad`), abductions by difficulty, terror by the
    terror missions taken;
  - the pods, the aliens shared out over them, the species chosen by pod
    type from Long War's table by month (`GetPossibleAliens`);
  - each pod's supports (`GetSupportingAlien`, with the month-dependent
    "+32" sets, and `GetSupportAlien`).
- **A landed UFO's crew is chosen a month ahead**, as in Long War.
- **Long War's hand-patched code packs counts into its pods' fields.**
  Read here as: the main alien, one more of it when its flag is set,
  then up to two kinds of support. Each step adds one alien, so the
  pod's size comes out right.
- **What is not kept yet:** the act (1, so Outsider commanders) and
  alien bases assaulted (none).
- **Abduction difficulty** is Long War's: act, the country's panic,
  chance.

**What the aliens leave** (`XGSummaryUI.CollectArtifactsFromDeadAliens`,
`XGUnit`, `GenerateWeaponFragments`; a species table generated into
`XComLWStrategy.ini`):
- each one's corpse;
- each weapon's fragments × `FragmentBalance`, at least one;
- the mechanical aliens' elerium, alloys and meld;
- 0.3 meld for every other kill;
- an abduction pays Long War's cash × its difficulty.

On a mission won (real, or `resolve` and `auto`), every alien of the
squad counts as killed, none by an explosion and none taken alive, since
our missions do not tell yet. The squad is drawn when the mission comes
back, not when it appears. Corpses are items with Long War's names.

**Research's gates, enforced** (`X2StrategyElement_LWTechs`):
- weapon fragments, and the items a tech consumes (its `eItemReq` ×
  `iNumItems`: Xenobiology, 5 Sectoid corpses), are costs;
- "one of these in stores" and "one of these techs" become XCOM 2's
  alternate requirements, crossed;
- the UFO analyses ask for their UFO type captured: a hidden marker item,
  given when a crash site or landed UFO of it is taken;
- "must have been held" is asked as "held now", since XCOM 2 keeps no
  archive. The two are the same whenever the tech consumes the item.

**Checked** (new campaign without its first mission, control port):
- **Sample squads:**
  - an early Scout crash: an Outsider with 6 Sectoids and Drones;
  - landed (a month ahead): Floaters, Thin Men, a Seeker;
  - a landed Battleship on day 100: 30 aliens;
  - the first terror site: 4 Chryssalids and 8 Floaters, as Long War's
    code sets.
- **Loot:** three months with every mission won left, among others, 54
  Sectoid and 58 Floater corpses, 185 weapon fragments, 49 meld and 249
  elerium.
- **Research:**
  - at the start only Alien Weaponry, Alien Materials and Alien Computers
    show, none affordable, and Xenobiology is hidden until a corpse is
    held;
  - after a month of missions won, Xenobiology shows, and Weaponry and
    Materials can be paid for;
  - Alien Computers waits for a navigation computer.

### Decisions

- **Every alien of the squad counts as killed on a win.** Until our
  missions are Long War's (its aliens on its maps), the squad is Long
  War's strategic answer to "who was there", and the fight's details
  (explosions, stuns, retreats) are not ours to read yet.
- **Long War's code, ported literally where it is odd.**
  - Chryssalids are possible in secondary pods from month 0.
  - An upgraded Sectoid pod can bring an EXALT Elite.
  - The minimum pod count uses Long War's `(n % f) * 2`.
  - The person's memory of playing is the check.

### Left open

- **Captives and alien weapons** (from aliens taken alive): the
  interrogations and the plasma research that ask for them stay locked
  until missions can stun.
- **The tactical side:** explosions destroying corpses and weapons, and
  aliens left behind.
- **Terror rewards.**
- **The first mission:** a Long War campaign now begins with what Long
  War's first mission left (`DetermineFirstMissionSquad`: 10 Sectoids, so
  10 corpses, 10 fragments and some meld). XCOM 2's own first mission,
  played or skipped, leaves nothing of Long War's. Xenobiology and Alien
  Weaponry can start at once, as in Long War.
- **What only sells:** damaged artifacts, and the grey market.
