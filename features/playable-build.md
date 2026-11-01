---
title: "A build the person can install on their own PC and give feedback on"
status: review
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

## Report (2026-11-01, the first build)

**The download**: a draft release on GitHub, *Preview 1: Long War's
soldiers* (`LongWarX2-20261101-649a3ac.zip`, 34 MB; visible to the
repository's members until it is published). Inside: the mod as built on
the test machine with the player's config, `LongWarX2-setup.exe` and a
README. Nothing of either game: no converted packages, no Long War words
(`tools/release/package.sh` stops if a `.upk`, `.tfc` or `.png` gets in).

**Checked on wingpu as a player would**: the zip unpacked, the game's copy
of the mod removed, the setup run:
- without Long War (wingpu's Enemy Within is plain EW): installs the mod and
  says the names and words are left out;
- with Long War's three files (from the person's install, in a stand-in EW
  folder): installs the mod and writes the words (57 perks, 8 rank names),
  byte for byte those of the test machine;
- the game started: the main menu shows only the air war preview (no test
  buttons); with two test switches turned on in the installed copy only, to
  reach the barracks without playing the first mission: Long War's classes,
  its rank names as the promotion screen's columns, Lone Wolf with its words.

**The setup program**: `tools/setup/setup.mjs`, one Windows executable of
93 MB (Node's official `node.exe`, its checksum checked, with the bundled
script inside; `npm run setup:bundle`). It finds the games through Steam's
library list, or `--xcom2` and `--ew`. Unsigned: Windows may warn.

**Not checked**: a PC other than wingpu (other Steam library drives, a
first start of the launcher with a new local mod), and playing the first
mission with the mod on.

### Decisions

- **No EW content in the first build**: the classes are the point, and
  they need none. The converted aliens and maps come as an opt-in in the
  setup later.
- **A preview tag (`v0.1.0-preview.1`) on a draft release**: published, it
  becomes a public download of the mod; the person decides when.

## Report (2026-11-01, after the person's first try)

**The person**: "the detection of where either game is installed failed -
adding them manually it did add the mod to I:\Steam\…\Mods but it does not
show up in the list of mods"; and "don't search the drives we solved this
for the tree".

**Fixed**:
- The setup finds the games as the Long War Tech Tree does
  (`desktop/src/game.ts`): Steam's uninstall entry for the app (XCOM 2:
  268500, Enemy Unknown/Within: 200510), both registry views, else the
  library Steam's own `libraryfolders.vdf` says holds the app. It only
  looked under `C:\Program Files` before.
- 2K's launcher has been removed from XCOM 2 (`2kLauncherRemoved.txt` in the
  game folder): Steam starts the game, which loads the mods listed in
  `My Games\XCOM2 War of the Chosen\XComGame\Config\XComModOptions.ini`.
  The setup now adds the mod there itself (the player's other mods kept, a
  copy of the file before kept as `.before-lwx2`); `--uninstall` takes it
  out.
- Checked on wingpu: no paths given, both games found, the mod enabled; the
  game started directly (as Steam does), the mod loaded. (A red "redscreen"
  overlay about a multiplayer test map shows on wingpu with or without the
  mod: wingpu's own, likely from the SDK.)

**Open**: which mod list the person was looking at (a mod launcher such as
AML keeps its own and writes the game's list when it starts the game).

**Then** (the person: "starting xcom2 directly clears the mod list in
XComModOptions.ini … iirc there was always something about enabling mods in
general"): the game rebuilds the My Games copy of its mod options from the
game folder's base file (`XComGame\Config\DefaultModOptions.ini`) whenever
it thinks the copy is out of date, which on the person's PC is every start;
the mod launchers write the base file. Checked on wingpu: with the mod only
in the base file, the game rebuilt the copy with it and loaded the mod. The
setup now writes the base file (other lines kept, the original kept as
`.before-lwx2`), and the copy too; `--uninstall` takes it out of both.

**Then, the real cause** (the person: "the xcom2 mod launcher does not touch
the default mods … maybe worth checking what X2CommunityCore/xcom2-launcher
does"): the Alternative Mod Launcher writes My Games' `XComModOptions.ini`
and sets its `[IniVersion]` stamp to the modification time of the game
folder's `DefaultModOptions.ini`. The game compares the two at start and,
when they differ, rebuilds the file from the default: the active mods are
gone. Reproduced on wingpu (a wrong stamp: the list cleared at start, the
stamp reset). The setup now does what AML does and leaves the game folder's
file alone (the line the previous build added there is taken out again).
Checked on wingpu with a stale stamp: the setup fixed it, the game kept the
list and loaded the mod (the main menu's button, the final shell).

### Decisions

- **AML's way, not the default file**: it is what a launcher does, it does
  not change the game's files, and Steam's file check cannot undo it.

**Then, the folder** (the person's `logs/Launch.log`): the game looked for
local mods only in the base game's `XCOM 2\XcomGame\Mods\` and the
Workshop folder: `ModRootDirs` in My Games' `XComEngine.ini`, set by a mod
launcher, had replaced War of the Chosen's own `..\..\XComGame\Mods\`
(where the setup installed it, and where the SDK puts it on wingpu). The
setup now installs into the first non-Workshop folder listed there (the
game's default when none is), and removes a copy elsewhere. Checked on
wingpu with the person's layout copied (the two folders, absolute): the
mod installed into the base game's Mods folder and loaded.
