---
title: "The port after the hard parts: its shape and its order"
status: planned
priority: 2
dependsOn:
  - hard-parts
---

## Purpose

The end goal is Long War 1.0 played in XCOM 2: "not the cheap way but
building the actual strategic layer", with "the customizable soldiers and
the looks" as the draw (the person, 2026-10-31). The hard parts are answered
(`hard-parts.md`): Enemy Within's aliens and maps come across from the
player's own install, and a Long War strategy system runs as an XCOM 2
screen on XCOM 2's game state. This file is the map of what follows, so
each piece can be taken up as its own feature in a sensible order. It is a
proposal: the person reorders or cuts.

## The shape (what the hard parts decided)

- **Tactical**: XCOM 2's tactical game, with Long War's rules on top: its
  soldier classes and perks in XCOM 2's ability system, its weapons and
  items with Long War's numbers, its aliens (XCOM 2's where XCOM 2 has
  them, Enemy Within's converted where it does not: Floater, Thin Man,
  Cyberdisc, Drone, Seeker, Mechtoid …), on Enemy Within's handmade maps
  (converted) and XCOM 2's own.
- **Strategy**: replaced whole, as the person said ("i can't really think of
  any part that maps to the old one"): the Geoscape with the council,
  funding and the monthly report, satellites and the air war, UFOs,
  abductions and terror; the base grid; research, the Foundry and
  engineering (Long War's tree, which the Long War Tech Tree already reads
  and checks); fatigue, MECs and gene mods, psionics.
- **Content**: nothing of either game shipped; the converter runs on the
  player's machine (the pattern of experiments 1 and 2).

## The order (proposed)

1. **Soldiers**: Long War's eight subclasses and their perk trees as XCOM 2
   classes (`lw-classes.md`). The draw, and the part that shows soonest.
2. **Weapons and items** with Long War's stats and slots.
3. **The strategy skeleton**: Long War's campaign state and a Geoscape of
   our own (time, the month, funding, the council report), replacing XCOM
   2's from the first day of a campaign.
4. **Research, Foundry, engineering** from the tree's data
   (`../xcom-ew-lw-tree/data/techtree.json`, `economy.json`).
5. **The air war** in that Geoscape (experiment 3's rules and screen).
6. **Maps as missions**: a host plot of our own, EW's lighting, EW's
   mission contents (pods, spawns, objectives), every EW map converted.
7. **EW's aliens as units**: pawns, animations through XCOM 2's anim tree,
   abilities, AI.

## What is worth what

Each step is days of agent time, not hours; the tail (every perk, every
alien ability, every map's quirks) is long. The order puts what the
person can see and judge first.
