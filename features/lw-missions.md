---
title: "Long War's missions: its alien squads, Enemy Within's maps and aliens"
status: in-progress
priority: 2
dependsOn:
  - lw-loot
  - hard-parts
---

## Purpose

A Long War mission is the aliens Long War's strategy sent, on Enemy Within's
maps, as Enemy Within's aliens. The hard parts are proven (`hard-parts.md`):
- Enemy Within's maps can be the ground of XCOM 2's missions;
- its aliens come across animated.

This feature makes the missions Long War's, in steps:
1. **Long War's alien squads in XCOM 2's missions**: the composition
   Long War's strategy gives each mission, as XCOM 2's nearest aliens.
2. **Enemy Within's maps** as the missions' ground, with the pods and
   objectives at Enemy Within's places, its lights, the squad landing in the
   open.
3. **Enemy Within's aliens as units:** pawns, animations through XCOM 2's
   systems, abilities, AI.

## Report (2026-11-01, step 1: Long War's squads)

**A mission sent from the Long War Geoscape is fought against Long War's
squad for it** (`LWMissionSquads`, from `UILWHeadquarters.OnLaunch`).
- **The squad** is `LWAlienSquads`' for the mission, by UFO, kind of
  mission, day, the aliens' resources and aggression. For the story's
  missions it is a Battleship's or Assault Carrier's crew.
- **The species** are fought as XCOM 2's nearest aliens (`+FightAs` in
  `XComLWStrategy.ini`, APPROXIMATION):
  - Sectoid and Sectoid Commander: Sectoid;
  - Floater and Heavy Floater: Archon;
  - Thin Man: Viper;
  - Muton: Muton; Muton Elite: Andromedon; Berserker: Berserker;
  - Cyberdisc: Gatekeeper; Drone: ADVENT MEC; Mechtoid: MEC Mk II;
  - Sectopod, Chryssalid: themselves; Zombie: Psi Zombie;
  - Outsider: Codex; Seeker: Faceless;
  - Ethereal and the Uber Ethereal: the Avatar;
  - EXALT: ADVENT.
- **The pods:** XCOM 2's mission keeps its pods' number and places. Long
  War's aliens are shared out among them, the first in the first pod; a
  VIP's or strategy unit's pod is left as it is.
- **The kill loot** of a mission played is that squad's, the one it was
  given (`PendingSquad`), not a fresh roll.

**Checked in the game:** an abduction in the first month launched with
"Long War's squad of 11 in 3 pods", and the mission held 7 Sectoids and 4
drones (as ADVENT MECs), Long War's early abduction crew.

**Found on the way:**
- The development build's EW-map experiment (`PlaceEWMapWhole`) left
  missions without any alien. The pods spawn where the hidden XCOM 2 map
  had them, and none did.
- It was also why units dropped in for testing never became visible.
- The experiment and the EW unit display are now off by default, in
  development too, until step 2 places the pods on Enemy Within's maps.
- With them off, the arc thrower was fired for real at a visible Sectoid:
  charge spent, "42 % → miss" (`lw-gear.md`).

### Decisions

- **XCOM 2's pods' number and places**, not Long War's pod structure. The
  maps are still XCOM 2's, and its pods sit where the map has room.
- **The mapping above is a stand-in** to judge in play. It goes when Enemy
  Within's aliens are units (step 3).

### Left open

- XCOM 2's own mission rules on top: its objectives, timers and sitreps, the
  Chosen and the Alien Rulers (the DLCs are installed).
- Kill loot from what was actually killed (now: the whole squad when the
  mission is won).
- Steps 2 and 3.
