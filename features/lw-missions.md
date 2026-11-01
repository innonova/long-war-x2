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

## Report (2026-11-01, step 2 begun: Enemy Within's pods read)

**The map converter now exports Enemy Within's pods and spawn points**
(`tools/convert/ew-map.ts` → the map's ini, `LWX2EWMapPieces.Pods`,
`SpawnPoints`). Each `XComAlienPod` comes with its location, the commander
flag and its min and max aliens; each `XComSpawnPoint` with its location.
- Run on wingpu on `CSmallScout_Badlands`: 4 pods (the commander's beside
  the crashed Small Scout, 1 to 3 aliens each) and 18 spawn points.
- The same map also holds its lights (47 point, 13 spot, a directional, a
  sky light), not yet read.

**Next (the plan, with what XCOM 2 offers):**
1. **Spawn Long War's pods at Enemy Within's pods** once the mission has
   begun on the EW map, the commander's pod first.
   - XCOM 2's `XComAISpawnManager.SpawnPodAtLocation(NewGameState,
     SpawnInfo, …)` spawns a pod of the given templates at a location.
     `XComGameState_AIReinforcementSpawner.SpawnReinforcements` shows the
     rest: a change with `BuildVisualizationForUnitSpawning` for the units'
     visuals.
   - Its alert step (`AlertAndScamperUnits`) is to be left out: a pod at
     the start doesn't know where XCOM is. The group's turn starts with
     `XGAIGroup.InitTurn`.
   - The EW coordinates are shifted by the placer's offset (the EW play
     area centred in the generated map's level volume).
2. **EW's lights** as movable XCOM 2 lights (point, spot), for the map's
   darkness.
3. **The landing spot** (two soldiers walled in on the truck stop) and a
   host plot of our own, as `hard-parts.md` left them.

## Report (2026-11-01, step 2: Long War's pods at Enemy Within's pods)

**When the whole EW map is placed in a mission, Long War's squad now
spawns at Enemy Within's pods** (`LWMissionSquads.SpawnAtEWPods`, called
by the tactical listener once the HUD is up).
- The placer keeps its shift from EW's coordinates to the mission's
  (`LWX2PartPlacer.EWShift`); each pod's location is shifted by it and put
  on the floor there.
- The aliens are those of the squad sent (`PendingSquad`), shared out over
  the pods in order, the commander's pod first.
- Each pod is spawned by XCOM 2's `SpawnPodAtLocation`, made visible by a
  visualization of our own (each unit's visualizer made and synced), and
  given its first turn by `XGAIGroup.InitTurn`.

**Checked in the game** (wingpu, `CSmallScout_Badlands`, a first-month
abduction): "pod LWX2_EWPod0 of 3 … spawned", Pod1 of 3, Pod2 of 2; the
enemies list showed 6 Sectoids and 2 ADVENT MECs, 17 to 39 tiles from the
squad. A screenshot showed the squad on the (dark) EW map.

### Decisions

- **Only pods with a Max above 0 are used**; all the map's pods if none
  has. EW's empty pods (Max 0) are placeholders its level designers left.
- **The commander's pod is first**, so it gets the squad's first alien, as
  Long War's squad lists its commander first.
- **No alert step**: a pod at the start does not know where XCOM is. This
  leaves out XCOM 2's reinforcement scamper (`AlertAndScamperUnits`).
- **Only once a mission, and only when no alien is alive on the field**, so
  a reloaded save or a second HUD init does not spawn a second squad.
- **The EW map stays off by default, in development too.** Pods spawn now,
  but the map is still dark and the drop spot can wall the squad in. The
  test machine's installed config turns it on for testing. It goes back on
  in development when the lights and the landing spot are done.

### Left open

- EW's lights; the landing spot; objectives at EW places.
- Pods use XCOM 2's stand-in templates until step 3.
