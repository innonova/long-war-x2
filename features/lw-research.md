---
title: "Long War's research, Foundry and engineering"
status: in-progress
priority: 2
dependsOn:
  - lw-geoscape
---

## Purpose

The strategy layer's choices: what to research, what to build, what the
Foundry improves. Long War's tree, which the Long War Tech Tree already
reads from Long War's own code and has checked against the person's saves,
with Long War's numbers, so a campaign's pace is Long War's. Step 4 of
`port-plan.md`.

## What the person should see

XCOM 2's research screen listing Long War's techs, by Long War's names
and texts, opening in Long War's order. Each takes Long War's time at
Long War's research rate (scientists, and labs once there are labs) and
costs Long War's alloys, elerium, weapon fragments and items. Research
credits from interrogations make the techs they cover cheaper. Then the
Foundry's projects, and engineering: items and facilities, with Long
War's costs and engineers.

## Requirements

- **Long War's rules, generated.**
  - The techs' requirements, credits and gates come from the Long War
    Tech Tree's `data/techtree.json`, which is read from Long War's
    package.
  - Times and costs come from the player's `DefaultGameCore.ini`
    (`TechBalance`, `FoundryBalance`, `ItemBalance`), via
    `scripts/research-config.mjs`.
- **The names and texts are Long War's.** They are written on the
  player's machine (setup, `scripts/write-words.mjs`) and never
  committed.
- **XCOM 2's own techs are hidden.** Nothing of XCOM 2's research
  machinery that Long War lacks (inspirations, breakthroughs) is left.
- **The phases:**
  1. Research: in this report.
  2. Engineering: the items Long War's techs unlock, with Long War's
     costs. This needs Long War's weapons and items as XCOM 2's
     (`port-plan.md` step 2).
  3. The Foundry's projects.
  4. The base's facilities: labs (the research bonus), workshops,
     power, uplinks.

## Report (2026-11-01, phase 1: research)

**Long War's research runs on XCOM 2's research screen.**

- **The techs** (`X2StrategyElement_LWTechs`, config `XComLWResearch.ini`):
  - Each of Long War's 75 techs is an XCOM 2 tech template.
  - Its points are Long War's: `TechBalance` days × `TECH_TIME_BALANCE`
    × 72, the Tree's base days × 720.
  - It requires Long War's techs: all of `Requires`, one of `AnyOf` (as
    XCOM 2's alternate requirements).
  - It costs Long War's alloys and elerium, in XCOM 2's own resources.
  - It has a picture from XCOM 2's research by kind of tech (autopsy,
    interrogation, weapons, armour…).
- **XCOM 2's 125 techs are hidden** (a requirement that never holds, at
  every difficulty).
- **XCOM 2's inspirations and breakthroughs are switched off**: their
  timers never run out, and one already given is taken back.
- **The rate is Long War's** (`XGFacility_Labs.GetResearchPerHour`):
  scientists × (1 + labs' bonus), with no labs yet.
  - XCOM 2's science score is its research points an hour, so the
    Geoscape sets its bonus to make up the difference from XCOM 2's own
    staff (`SyncResearch`, after every run of time).
  - Long War's starting staff: 10 scientists and 10 engineers.
  - Each country under a satellite sends its `ContBalance` scientist or
    engineer at the council meeting (the strategy config's countries now
    carry them).
- **Research credits**: an interrogation done holds its credit, and every
  tech it covers costs its share less (25 %, the Ethereal's "All" 20 %),
  credits stacking by multiplying, through XCOM 2's own
  `TimeReductionScalar`.
- **The words** (`makeTechWords`, `scripts/write-words.mjs`, used by setup
  too): name, summary, code name and research report from Long War's
  `XComStrategyGame.int`. Long War's own techs (the UFO analyses, the
  armours) are keyed there by number.

**Checked in the game** (new campaign, by the control port's new
`research` command and on screen):

- The research screen lists Long War's opening techs with Long War's
  words: Xenobiology, Alien Weaponry, Alien Materials, Alien Computers.
- Xenobiology takes 18 days (432 h at 10 scientists).
- Alien Materials is shown in red, since it costs alloys and elerium XCOM
  has none of.
- Xenobiology completes on its day with XCOM 2's research-complete
  screen, and opens Long War's next techs: Xenoneurology, Xenogenetics,
  the Sectoid, Thin Man and Muton autopsies (288, 432, 576 h).
- No inspirations.

**A trap found:** UE3's config reader stops reading a struct at an empty
array (`AnyOf=()`). Every field after it was 0, which made the first
build's techs "instant". The generators now leave empty arrays out.

### Decisions

- **XCOM 2's research machinery with Long War's content and numbers,
  not a screen of our own.** XCOM 2's research is one project at a time
  on a points-per-hour rate, as Long War's is. Its science score can be
  set to Long War's rate exactly, so its research screen, reports, alerts
  and saved state come for free, and only the content is ours.
- **The rules come from the Tree's data** rather than from decompiling
  Long War's package again. The Tree read them from that package and
  checked them against 1,711 saves. It is the same code, read once.
- **Gates that need loot are recorded but not enforced yet.** Weapon
  fragments, the items a tech consumes (corpses, captives) and what must
  have been held or captured first are all in `XComLWResearch.ini`.
  Missions bring no loot yet, so enforcing them now would close most of
  the tree. They come with the missions' loot.

### Left open

- **Loot.** Fragments, items and gates are not enforced. Alloys and
  elerium are, but nothing brings them yet: the missions' loot is next.
- **Labs** (`LAB_BONUS` 20 % each, adjacency) wait for the base.
- **XCOM 2's research room** still shows "SCIENTISTS 0", XCOM 2's own
  staff count; Long War's scientists are in the Geoscape's state.
- **What a tech unlocks** (items, Foundry projects, facilities) comes
  with phases 2 to 4.
- **Existing campaigns** started before this build have no state for
  Long War's techs; only new campaigns do.

## Report (2026-11-01, research's gates)

Weapon fragments, consumed items, "one of these in stores", UFO types
captured, and "held" (asked as "held now") are now enforced, since
missions bring loot. See `lw-loot.md`, phase 2.
