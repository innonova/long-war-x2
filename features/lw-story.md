---
title: "Long War's story: alien bases, Overseers, the Temple Ship"
status: review
priority: 2
dependsOn:
  - lw-geoscape
  - lw-base
  - lw-loot
---

## Purpose

Until now a campaign could only be lost. Long War's war is won through
its story:
- **the Outsider's shard** makes a Skeleton Key;
- **the key opens an alien base**, built in a country that left, and
  taking it brings the country back and yields the Hyperwave Beacon;
- **the Overseers** that fly over the world carry the Ethereal Device;
- **the Gollop Chamber** built from it leads to the Temple Ship, whose
  fall ends the war.

This brings that chain into the Long War Geoscape, so a campaign can be
won.

## What the person should see

- **On the Geoscape:**
  - a note when the aliens build a base in a country that has left;
  - with a Skeleton Key in the stores, an ASSAULT decision for each
    alien base;
  - Overseer UFOs passing over watched countries each month;
  - once the Gollop Chamber stands, ASSAULT: the Temple Ship.
- **Engineering** builds the Skeleton Key once the Outsider Shard is
  researched.
- **Winning the Temple Ship** brings XCOM 2's victory screen; losing it
  loses the campaign.

## Report (2026-11-01)

The rules, read from Long War's code:
- **The Outsider Shard:** a downed Outsider (the UFO crews' commander
  before act 3) leaves its shard (`XGUnit`; it has no corpse). It comes
  with the kill loot.
- **The Skeleton Key** is built in engineering once the Outsider Shard
  research (tech 3) is done: §200, 40 elerium, 10 alloys, 10 meld, 20
  days at 25 engineers, and the shard (`GetItemProjectCost`).
- **Alien bases** (`AddToAssets`, `CreateAlienBase`): a country that
  signs the pact gets one.
  - **An assault takes a Skeleton Key**, whatever comes of it
    (`XGStrategy`: `RemoveItem(184)`).
  - **Taken:**
    - the country rejoins the council, at 98 panic less 20; its
      continent loses 5 panic (`CostTest`, the mission's results);
    - the base's artifacts come home: 100 alloys, 3 power sources and
      their elerium, 4 surgery tables, 15 stasis tanks, 10 food, 1
      entertainment;
    - the first base also holds the Hyperwave Beacon.
- **Overseers** (`AddNewOverseers`): until XCOM has an Ethereal Device,
  up to three Overseers fly over watched countries each month (days 5,
  15 and 25), and one over each country that has left.
  - They fly over and leave (`eUM_Flyby`).
  - Brought down, their salvage holds the Ethereal Device (`PsiLink`), as
    the salvage table had it.
  - The infiltration's Overseer, which lands, was already there.
- **The research and facilities** were already Long War's: Hyperwave
  (with the beacon) → the Hyperwave Relay; Interrogate Ethereal and the
  Ethereal Device → Psi Link → the Gollop Chamber.
  - An Ethereal can be taken alive from an Overseer's crew
    (`lw-loot.md`).
- **The Temple Ship:** once the Gollop Chamber stands. Won, XCOM has won
  (XCOM 2's `UIYouWin`); lost, the campaign is lost (`YouWin`,
  `YouLose`).

**Checked in the game** (control port):
- a month in, an Overseer was seen over the United States ("Overseer,
  Flyby") and left three hours later;
- China signed the pact and "The aliens are building a base in China";
- with a Skeleton Key given, the assault was offered and won: "In the
  alien base: a Hyperwave Beacon", and "China rejoins the council";
- with a Gollop Chamber placed (the new test aid `base set`), the Temple
  Ship was offered, and its win brought XCOM 2's VICTORY screen.

### Decisions

- **A Battleship's crew stands in for the alien base's squad** in its
  kill loot (APPROXIMATION in the code): Long War's
  `DetermineAlienBaseSquad` is a 36-alien build of its own.
- **The Temple Ship needs only the Gollop Chamber.** Long War also has
  a psionic volunteer go through the chamber first; that waits for psi
  soldiers.
- **The base is in the country that left**, not on a map location.

### Left open

- The volunteer and psi soldiers; the XCOM HQ assault (Long War's base
  defence, from month 4); the council's own missions.
- Act 3 (no more Outsider commanders once the Overseer is down) and the
  EXALT story.
