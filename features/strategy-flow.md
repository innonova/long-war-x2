---
title: The strategy layer as a player meets it, from a new game through every room and dialog
status: in-progress
priority: 5
dependsOn: [lw-base-view, ew-compare]
---

# The strategy layer as a player meets it

## Purpose

The person's (2026-11-18): the base is now the most broken thing for them. A new game still starts on the Avenger, and
many rooms and dialogs are broken one way or another. Without a working strategy layer they cannot play a campaign and
give deeper feedback; perfecting the maps first would leave little feedback for a long time. So: from creating a game,
through every room, menu, screen and dialog of EW's base, close to EW in look and working, before more map work.

## Plan

1. **A player's walk, scripted** (`tools/compare/walk.sh`): a new game by mouse from the main menu, as a player makes it
   (difficulty, second wave, start screen), then every room, every option of every room's menu, every screen and every
   dialog it opens, and back. Each step captured and logged with what came up (the screen on top, errors in the log).
   The same walk in EW from a fresh EW campaign where EW has the room, for the pairs.
2. **The list:** every step that is broken (wrong screen, nothing happens, stuck, an XCOM 2 screen where EW has its own,
   a dialog without its buttons, the Avenger showing), worst first, in this file. The person's own findings go into it
   too.
3. **The Avenger replaced wholesale** (the person, 2026-11-18: not opened over, replaced):
   - **The root:** XCOM 2's HQ presentation layer (`XComHQPresentationLayer.InitUIScreens` pushes `UIAvengerHUD` and
     `UIFacilityGrid`; every "back to the Avenger" path pops to the facility grid) replaced by ours (ModClassOverride),
     whose root is EW's base hub (or Long War's start screen in a new campaign), and whose way back is the hub.
   - **The world:** the strategy map stays `Avenger_Root` (its name is in XCOM 2's script in several places: the
     difficulty screen, the HQ game, the return from a mission), but the Avenger's own levels are not streamed at all;
     EW's base is the strategy world.
   - **What still needs the Avenger's rooms** (the armory, soldier customization, the memorial) gets EW's rooms, as squad
     select already has EW's hangar.
   - First a test that the presentation layer can be overridden at all.
4. **Fix down the list,** walking again after each batch; a download when a batch is done.
5. **Then the maps' lighting** (the middle way the person chose: EW's lightmaps on interiors and night maps, XCOM 2's
   light on daylight exteriors), shown on two maps first.

## Decisions

- Strategy flow before the maps (the person, 2026-11-18). Mission lightmaps: the middle way, after this.
- No opening Long War's screens over the Avenger by timer (tried, reverted): the Avenger is replaced, not covered.
- The walk compares every screen and dialog with EW's, not only the 20 views of `ew-compare`.
