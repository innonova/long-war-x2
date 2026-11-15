---
title: "Squad selection and loadout on XCOM 2's screens, missions launched by Long War"
status: in-progress
priority: 4
dependsOn:
  - lw-geoscape
  - lw-fatigue
---

## Purpose

The Long War Geoscape sends the first soldiers able to go, picked by the mod: the player
can't choose the squad, change its kit before a mission, or send a tired soldier "all in"
on purpose. The person (2026-11-15): the strategy layer moves mostly to Enemy Within's own
screens, but **soldier selection and loadout use XCOM 2's**, since they carry the soldier
customization that is the reason for the port.

## What it should do

- Choosing a mission on the Geoscape opens XCOM 2's squad select on it, with Long War's
  squad size (6, then 7 and 8 from the Officer Training School). The slots start filled
  with the first able to go, rested soldiers first, as before.
- From squad select the player changes soldiers and opens their loadout in XCOM 2's armory,
  as in XCOM 2.
- Launching sends the mission through Long War's launch path (Long War's aliens for it, the
  EW map, the map loaded after voices and cinematics stop). It does not go through XCOM 2's
  Skyranger flight over its world map.
- Backing out leaves the mission on the Geoscape as it was. Nothing is spent, and no UFO or
  site is marked as taken.
- A soldier still resting can be sent, and goes all in (`lw-fatigue.md`, as before).

Later, with the base map (the Avenger retired): the same screens in a room of our own.

## Report (2026-11-15)

Seen in the game on wingpu, in a fresh campaign:

- **Squad select opens on Long War's mission.** An abduction in Australia, answered on the
  Geoscape, opened XCOM 2's squad select. Its six slots held the first soldiers able to go,
  each in their Long War class and kit (assault rifle, sniper rifle, SAW, frag grenade).
- **Launch** went through Long War's path. The launch bay's departure cinematic sent
  `PreM_Exit`, ours took over, and the mission loaded with 6 soldiers. Won with `win`, it
  came back to the Geoscape with the abduction's §80, and nothing was left pending.
- **Backing out** with Escape left the next abduction (Egypt) on the Geoscape as a
  decision. Nothing was marked as taken and nothing stayed pending.
- **The mission panel** shows Long War's mission and what it brings home ("Abductions in
  France", "Cash, and the country's panic down"), not the XCOM 2 mission it is fought as. The
  first look showed XCOM 2's "Recover Item from ADVENT Train". The panel has one line for the
  objective, so "Kill or capture every alien" is left to the mission's own objectives list.

How it is built:

- `UILWSquadSelect`, a subclass of XCOM 2's `UISquadSelect`. XCOM 2's screen ends in
  `GoToGeoscape` once the launch bay's cinematic sends `PreM_Exit`. Ours takes over there:
  on launch it calls `UILWGeoscape.LaunchChosen`, on backing out `ForgetChosen`. A 20 s
  fallback timer does the same if the cinematic never sends the event.
- The launch is split into steps:
  - **Chosen:** `XComGameState_LWStrategy.MissionChosen` records the pending kind and
    target only.
  - **Prepared:** `UILWHeadquarters.PrepareMission` makes the mission site with Long War's
    aliens. It sets `XComHQ.MissionRef`, the pre-filled squad and the mission's
    `MaxSoldiers`.
  - **Committed:** `MissionCommitted` takes up the UFO or site and spends the Skeleton Key.
  - **Launched:** `LaunchMission`.

  Backing out removes the site and clears what's pending (`MissionCancelled`).
  `MissionSent` (chosen and committed together) stays for the WIN buttons and the control
  port's `resolve`.
- `UseSquadSelect` (XComLWAirWar.ini, `[LongWarX2.UILWGeoscape]`) switches back to the old
  direct launch.
- Control port: `continue` on squad select presses its launch with the squad as it stands.

### Decisions

- XCOM 2's screen shows at most 6 slots (`MaxDisplayedSlots`). Squads of 7 and 8 get the
  extra soldiers added by XCOM 2's own `AddHiddenSoldiersToSquad`, not picked. The launch
  bay has stand spots for 6 pawns. Showing 8 needs spots of our own, which the base map's
  soldier room will have.
- Soldiers in Long War's psi training are taken out of the squad at launch, with a log
  line. XCOM 2's screen offers them, because the training is ours, not XCOM 2's. Filtering
  XCOM 2's personnel list would take a subclass of its list screen, which is more than this
  case is worth for now.
- The launch bay's walk-up and departure cinematics stay, since the Avenger is still the
  scene. They go when the Avenger does.
