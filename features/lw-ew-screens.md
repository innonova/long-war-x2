---
title: "Enemy Within's own strategy screens in XCOM 2: its Flash movies, driven by Long War's state"
status: in-progress
priority: 10
dependsOn: [lw-geoscape, lw-base, lw-research]
---

# Enemy Within's own strategy screens

## Purpose

The person wants to play the port to give feedback, and the strategy layer
is today our own plain buttons and text (`STATUS.md`, Looks: plain). Long
War's strategy screens are Enemy Within's Flash movies. If XCOM 2 can show
them, the port can look like Long War's strategy game instead of a debug
panel, with EW's screens driven by the port's Long War state, the way
EW's own script drove them. Nothing of EW is committed: the movies are
converted on the player's machine, as the maps are.

## Report (2026-11-02, the experiment)

**XCOM 2 shows Enemy Within's strategy screens, takes EW's own calls into
them, and gets the player's clicks back.**

What the two games have:
- EW's screens are `SwfMovie` objects in `UICollection_Strategy_SF.upk`
  (57 of them: Mission Control, the Situation Room, research, engineering,
  the Foundry, the barracks, the hangar, the month's report …), Scaleform
  movies of Flash 8 with ActionScript 2.
- XCOM 2's are the same kind (`SwfMovie`, Flash 9, ActionScript 2), one
  per package, named the same way (`gfxChooseFacility.ChooseFacility`), and
  a screen names its movie by path (`UIScreen.Package = "/ package/<group>/<movie>"`).
- Several names exist in both games (`gfxChooseFacility`, `gfxComponents`),
  and EW's movies import shared libraries by relative path
  (`../gfxComponents/components.swf`, `..\gfxStrategyComponents\…`).

What was built:
- **`tools/convert/ew-ui.ts`**: an EW UI package made loadable beside
  XCOM 2's. Every `gfx<Name>` group becomes `ewx<Name>` (the same length,
  so nothing moves), in the name table and inside the movies, where the
  imports name their libraries; fonts stay XCOM 2's (`gfxfontlib`). The
  textures are rewritten uncompressed, as for EW's other packages.
  Result: `EWStrategyUI.upk`, 30 MB, 57 groups renamed, 433 names changed
  inside the movies, 871 textures. It goes in the mod's `Content` (on the
  test machine; not committed).
- **`UILWEWScreen`**: a bare XCOM 2 screen whose `Package` points at an EW
  movie, with `MCName` set to the movie's own instance. EW names the clip
  on each movie's stage per screen (`theScreen`, `theStrategyHUD`,
  `theChooseResearch`, `theBuildFacilitiesScreen`); XCOM 2 sends calls
  to that clip.
- Test aids: `ewscreen <movie> [instance]` opens one, `ewcall <function>
  [arguments]` calls a function of the open movie, as EW's `AS_`
  functions do.

**Checked:**
- Mission Control's movie drew EW's clock ("00:00 AM, Month & Day,
  Year") and its labels, with EW's placeholder text, over XCOM 2's
  Avenger.
- The research screen (`ChooseTech`, instance `theChooseResearch`), filled
  with EW's own calls, as read from EW's `UIChooseTech` (`SetTitle`,
  `AddOption(index, text, state)`, `UpdateInfo(name, info, description,
  image)`, `SetConfirmButtonHelp`): the title, a list of three techs with
  the first selected, the info panel with the name, "10 days" and the
  description, and the confirm button. The picture was missing: the path
  given was made up; EW's tech pictures are in another EW package, not
  converted yet.
- A click on the confirm button reached the screen as mouse events 391
  and 400 for `theChooseResearch.theConfirmButton`. A click aimed at the
  list missed (coordinates), not tried again.
- Without the instance name, the calls went to `theScreen` and did
  nothing.

### Decisions

- **Rename EW's groups rather than replace XCOM 2's.** XCOM 2's own
  screens keep working beside EW's, and EW's movies load EW's libraries.
- **Fonts are XCOM 2's.** EW's movies ask for `$TitleFont` and
  `$NormalFont`, which XCOM 2's font library has; the text looked right.

### Found, left open

- EW's 3D behind the screens (the Geoscape's globe, the base's cutaway) is
  not in these movies; XCOM 2's Avenger shows behind them. The globe and
  the base are EW levels and meshes, which the map converter's route
  could bring.
- EW's pictures (techs, items, facilities, soldiers' portraits) are in
  other EW packages (`UILibrary_*`), to convert with them.
- The setup program does not run the converter yet; the package was made
  here and copied to the test machine.

## Plan (proposed)

1. **The screens the player uses most, one at a time, in place of ours**,
   each driven as EW's script drove it (EW's `UI…` classes are readable in
   `XComStrategyGame.upk`), with the port's Long War state: the strategy
   HUD (clock, money, resources), research, engineering, the Foundry, the
   Situation Room (panic, the council), the base, the hangar, the month's
   report.
2. EW's pictures converted with the screens.
3. The setup program runs `ew-ui.ts` on the player's install.
4. The 3D: the globe for the Geoscape, the base's cutaway, with the map
   converter.

## Report (2026-11-02, the first screen wired: research)

**EW's research screen chooses XCOM's research**, with Long War's techs
as the port runs them (`UILWEWResearch`). It is driven as EW's
`UIChooseTech` drives the movie (read from EW's code): `SetTitle`,
`clear`, `AddOption`, `setFocus`, `UpdateInfo`, `SetConfirmButtonHelp`.
EW's clicks are 400 to select an option, 398 to select and accept, and
391 on the confirm button to accept. The project starts as XCOM 2's
research screen starts one (`SetNewResearchProject`).
- **XCOM 2's research screen is replaced by it** wherever the converted
  package is present (`UIScreenListener_LWEWScreens`; the Shadow Chamber
  is left alone). Without the package, XCOM 2's stays.
- The test aid `ewresearch` opens it.
- **Checked** (a new campaign): the four opening techs in EW's list,
  Xenobiology selected with "18 Days", Long War's summary and XCOM 2's
  tech picture; Enter started it ("research begun: LWTech_Xenobiology")
  and the screen closed.
- **Not yet right**: the Down key did not move the selection; EW's
  movie seems to take it and move its own focus to the confirm button.
  The title and button labels are our own words ("RESEARCH", "START
  RESEARCH") until EW's are written by the setup program.

### Decisions

- **No confirmation popup** when switching projects. XCOM 2 asks; EW's
  screen did not ask either.
