---
title: "A build the person can install on their own PC and give feedback on"
status: in-progress
priority: 2
dependsOn:
  - lw-classes
---

## Purpose

The person, 2026-11-01: "at some point it might be worth making something i
can install on my main pc and try so i can start giving you feedback". The
soldiers are the draw, and Long War's classes already play in XCOM 2 without
any Enemy Within content; the person's eye on them (the classes, the trees,
the promotion screen, the feel of a campaign start) is worth more than more
work in the dark. So: a first build of what exists, installed the way a
player would install a local mod, on a PC that is not the test machine.

## What the person should be able to do

1. Download one file, unpack it, run one program (or one command).
2. Start XCOM 2: War of the Chosen with the mod enabled in its launcher.
3. Start an ordinary campaign: the recruits are Long War's classes with Long
   War's names and words, promotions follow Long War's rules; the Long War
   HQ button and the air war are there as previews. No test buttons, no
   development switches on.
4. Optionally, with Enemy Within installed: the converted content (the
   Floater, the EW map in missions) as an opt-in.
5. Tell me what they see.

## Requirements

- **Nothing of either game in the download.** The mod's code, its config
  (structure and Long War's numbers, as committed), no converted packages,
  no Long War text. Long War's words (perk names and descriptions, rank
  names) are written on the person's machine from their own Long War
  install, as on the test machine.
- **The development switches off** in the build (test campaign button,
  rookies promoted, test end-mission button, quick launch helpers, the EW
  map and unit unless converted).
- **Installs and uninstalls cleanly**: one folder in the game's `Mods`, the
  words file inside it; removing the folder removes the mod.
- Works when Enemy Within is not installed (no words then: says so, and the
  classes show their internal names).

## Hard to verify

That it works on a machine other than wingpu: paths (Steam libraries on
other drives), a game without the SDK, no Node. Checked on wingpu with the
SDK's mod folder removed from the game, running the build as downloaded.

## Facts

- XCOM 2 loads local mods from `XCom2-WarOfTheChosen/XComGame/Mods/<Name>`
  (a `.XComMod` file and the built folder); the launcher lists them.
- The words come from `scripts/classes-config.mjs` (Long War's
  `DefaultGameCore.ini`, `XComGame.int`, its `XComGame.upk` for the numbers
  in the texts, read with upkit).

## Report (2026-11-01, plan)

### Decisions

- **Now, not later**: the classes need no EW content and are the part the
  person cares most about; feedback on them steers the next weeks.
- **A setup program for the words** rather than shipping them: they are Long
  War's text. One Windows executable (Node's single-executable form, so the
  person needs no Node), built here, that finds the installs, writes the
  words and, if asked, converts EW content.
- **Packaged from the test machine's build**, the staged mod folder with
  the player's config and nothing of the games.
- **Delivered as a draft GitHub release** (visible to the repository's
  members only) until the person says it may be public.
