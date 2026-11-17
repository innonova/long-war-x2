---
title: EW's and Long War's pictures on EW's strategy screens
status: in-progress
priority: 30
dependsOn: [lw-ew-screens]
---

# EW's and Long War's pictures on EW's strategy screens

EW's strategy screens run on EW's own movies, but their pictures are XCOM 2's (research shows XCOM 2's tech pictures,
the council request screen none). Long War keeps its pictures' paths in config: `DefaultContent.ini`'s
`MultiplayerLoadoutSlots`, which Long War's patched `UIUtilities` reads (`GetItemImagePath`: `iPointValue=0` and the item's
number; `GetTechImagePath`: 2 and the tech's; `GetFoundryImagePath`: 3 and the project's; Long War's `BuildTech` and
`BuildFoundryTech` set each image number to the tech's or project's own). Of 617 entries, the items', techs' and projects'
point either into EW's `UILibrary_StrategyImages` (128 items, 67 techs, 24 projects) or into Long War's own `LongWar.upk`
(106, 17, 24), a package of 389 textures and nothing else.

## Plan

1. **The table, on the player's machine:** the setup reads the player's `DefaultContent.ini` and writes
   `XComLWX2Images.ini` (gitignored): each item's, tech's and project's picture path, EW's moved to where the converted base
   carries them (`Command1.QILibrary_StrategyImages…`, `tools/convert/ew-images.ts`), Long War's kept.
2. **Long War's pictures:** the setup converts `LongWar.upk` into the mod's Content as it is (`tools/convert/ew-package.ts`,
   as the Situation Room's earth), so `LongWar.InventoryImages.…` load.
3. **The screens:** research (the tech's picture), engineering (the item's), the Foundry (the project's), the council
   request screen (the item's), then the rest that show items (grey market, hangar).

## Decisions

- The table is generated from the player's install rather than committed: it is Long War's config (paths only, but read
  from Long War's own file), as the other generated configs are.

## Report (2026-11-17, EW's pictures)

- **The list** (`tools/convert/ew-pictures.ts`, run by the setup): the player's `DefaultContent.ini` read, and each item's,
  tech's and Foundry project's EW picture written to the mod's `XComLWX2Images.ini` (gitignored) under the path the
  converted base carries it at (`Command1.QILibrary_StrategyImages…`): 210 pictures. `LWX2Pictures` reads it
  (`Item`, `Tech`, `Project`: the picture, else the XCOM 2 one the screen had).
- **On the screens:** research (the tech's picture, by the tech's Long War number), engineering and its build screen (the
  item's, the Foundry project's), the grey market (the item's), the council request screen (the requested item's).
- **Long War's own pictures are left out** (106 items, 17 techs, 24 projects, in its `LongWar.upk`): converted as it is
  (`ew-package.ts`), the package loaded, but the first of its textures asked for crashed XCOM 2 ("Serial size mismatch" on
  `LongWar.InventoryImages.Inv_SawedOffShotgun`: 394 bytes more read than the export holds), so the texture rewrite does not
  yet fit that package's textures. Those keep XCOM 2's pictures. Next: the rewrite for that package.
- **Found on the way:** Mission Control, opened by the Geoscape a moment after it opens, pushed itself over a screen opened
  from the Geoscape at once (the control port's test aids); it now opens only while the Geoscape is on top.
- **Checked on wingpu:** research with EW's Xenobiology picture (`logs/wingpu_ew_research_picture.png`); engineering with a
  Long War weapon (XCOM 2's picture, as expected) and no crash.
- **Not checked:** the grey market's, the Foundry's and the request screen's pictures on screen.

## Report (2026-11-17, Long War's own pictures)

- **Why the package crashed:** Long War saved its `LongWar.upk` uncooked (package flags 0x1, licensee version 0), each
  texture with its source art inline (the shotgun's: 14,834 bytes) and with only the GUID and one count after its mips. EW's
  cooked textures have no source art and the GUID followed by 0, 1, 0, in a package marked cooked with licensee version
  64. XCOM 2 read the uncooked layout wrongly and stopped.
- **`cookPictures`** (`tools/convert/ew-pictures.ts`, run by the setup) writes each of its 389 textures again in EW's cooked
  layout (its properties, no source art, its mips inline as they were, the GUID and EW's tail), and marks the package cooked
  with EW's licensee version. Into the mod's Content as `LongWar.upk`; the list then takes Long War's pictures too: 357.
- **Checked on wingpu:** engineering's Sawed-Off Shotgun with Long War's own picture (`logs/wingpu_lw_picture_sawedoff.png`),
  the grey market's Sectoid corpse with EW's (`logs/wingpu_ew_greymarket_picture.png`), research's Xenobiology with EW's;
  no crash. Converted on this machine by hand (the package copied in); the setup's run of it is checked with the next
  download.
- **Not checked:** the Foundry's and the council request screen's pictures on screen; the hangar's.
