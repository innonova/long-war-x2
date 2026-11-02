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

## Where each step stands (2026-11-02, morning: the night's work)

The night after "keep going till 7am". Each feature's report has the details
and a Decisions list to review.

- **Missions on Enemy Within's maps** (`lw-missions.md`, step 2): the whole
  loop works, from the Geoscape to Long War's result:
  - Long War's squad spawns at EW's pods and patrols (the AI's data made for
    it). Pods are read from a map's sub-levels too (the truck stop keeps
    them there).
  - EW's lights are placed (point, spot, sun, sky).
  - Soldiers boxed in at landing are moved out.
  - A Long War mission is won when its aliens are all dead or taken, on
    XCOM 2's maps too.
  - No squad concealment; no faction soldier in a Long War campaign.
- **Perks** (`lw-classes.md`): Precision and Disabling Shot, Double Tap,
  Rapid Reaction, Ready for Anything, Close Combat Specialist, Paramedic,
  Savior, Deadeye, Dense Smoke, Combat Drugs, Shredder Ammo, Sapper, HEAT
  Warheads. Long War's numbers come from EW's constants and its ability
  table.
- **Psionics** (`lw-psi.md`, new): the twelve powers trained in the Psi
  Labs at Long War's hours and chance. Mindfray, Panic, Mind Control and
  Inspiration work in missions. A Psi Labs line in the base screen.
- **Gene mods** (`lw-genemods.md`, new): the ten mods in five slots, made
  in the Genetics Lab. Six work in missions. A Genetics Lab line in the
  base screen.
- **The Foundry in missions** (`lw-research.md`): the pistol projects,
  Improved Medikit, Ammo Conservation.
- **Which Long War the config follows** (`lw-psi.md`, the correction): for
  part of the night I generated config from the test machine's Long War
  install, not the Tree's samples (1.0d) as before. Regenerated from the
  samples, everything came out the same except the Psi Labs' base chance
  (0.65 in the samples, 0.45 installed). Which Long War the port follows
  is a question for the person.
- **Fixed**: XCOM 2 stopped when leaving a mission. A screen listener held
  the HUD; it would have hit any player with the development EW map on.
- **Open, worth the person's eye**:
  - XCOM 2 sometimes crashes while loading a mission map, about 3 in 25
    loads that night, always at the same address. Not yet known whether
    it happens with the mod off (`lw-missions.md`).
  - Several numbers are approximations, marked so in the Decisions lists:
    the psi will check's base, Shredder's +33 %, the two-turn cooldowns.
- **Preview build**: replaced at 23:41 UTC with the work up to the Sapper
  perk. A later one follows if the night allows.

## Where each step stood (2026-11-01, evening)

1. **Soldiers**: as in the morning, below.
2. **Weapons and items** (`lw-gear.md`): Long War's 55 soldier weapons and
   14 armours, with their numbers, the classes' rules and starting kit.
   Small items, MECs and SHIVs are not done.
3. **The strategy skeleton** (`lw-geoscape.md`, `lw-base.md`, `lw-loot.md`):
   - Long War's Geoscape replaces XCOM 2's world map: the council, panic,
     the aliens' months, UFOs, abductions, terror and missions;
   - salvage and kill loot;
   - the base: its grid, facilities, power and upkeep.
4. **Research, Foundry, engineering** (`lw-research.md`, `lw-gear.md`):
   Long War's techs on XCOM 2's research screen at Long War's rate;
   engineering and the Foundry at Long War's costs and pace. The Foundry
   projects' effects are not done.
5. **The air war** (`lw-hangar.md`): Long War's rules and its hangar:
   - jets by continent, with repair, refits, orders and transfers;
   - the Foundry's air projects.
6. and 7.: as in the morning.

Beyond the plan's steps, also done that evening:
- **the story** (`lw-story.md`): Outsider Shards, the Skeleton Key, alien
  bases in countries that left, Overseers, the HQ assault and the Temple
  Ship, so a campaign can be won;
- **aliens taken alive** (`lw-loot.md`);
- Long War's soldier price.

What is still XCOM 2's: the missions themselves (maps, aliens, the
tactical rules beyond the perks), and with them the arc thrower.

## Where each step stood (2026-11-01, morning)

1. **Soldiers** (`lw-classes.md`, in progress): the eight classes with Long
   War's trees, one free perk a rank, its stat gains and perk-choice
   bonuses, generated from Long War's config; 25 of 66 perks with effects
   (9 as XCOM 2's own, 16 of Long War's own), the rest named stand-ins.
2. **Weapons and items**: not started.
3. **The strategy skeleton**: a first seam proven (experiment 4): a Long War
   headquarters screen sends a squad through XCOM 2's mission path and reads
   the outcome; it opens from the Avenger for now.
4. **Research, Foundry, engineering**: not started (the data is in the Long
   War Tech Tree).
5. **The air war**: experiment 3's screen, opened from the headquarters with
   the campaign's jets.
6. **Maps as missions**: EW maps placed as a mission's ground, in quick
   launch and in campaign missions, two maps converted by the same tools;
   next: the squad's landing spot, EW's lights, smaller packages, EW's
   mission contents.
7. **EW's aliens as units**: the Floater shown, animated, with a material
   made in the game (no editor); next: a pawn and character template.

## What is worth what

Each step is days of agent time, not hours; the tail (every perk, every
alien ability, every map's quirks) is long. The order puts what the
person can see and judge first.
