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

## Report (2026-11-02, EW's strategy HUD)

**EW's strategy HUD shows over the Avenger and the port's strategy
screens** (`UILWEWStrategyHUD`).
- **The resource bar**: Long War's cash, alloys, elerium and meld, as EW's
  `UIStrategyHUD` fills it (`ClearResources`, one `AddResource` each,
  coloured).
- **EW's clock** with Long War's date and hour (`theClock.SetDateTime`, as
  EW's `UIStrategyComponent_Clock` sets it for English): "00:00 AM,
  1 March 2015" on a new campaign.
- **Refreshed every second.**
- **Loaded into the movie without joining the screen stack.** Pushed, it
  took the focus, and XCOM 2's screens hide when they lose it (our
  Geoscape vanished, and XCOM 2's Avenger HUD with it). A movie draws over
  those loaded before it, so whenever one of the port's strategy screens
  opens, the HUD is loaded again above it (`UIScreenListener_LWEWScreens`).
- Test aid: `ewhud`.

**Checked**: over the Geoscape screen, the bar at the top right (CASH
§500, ALLOYS 1, ELERIUM 1, MELD 2) and the clock at the bottom, with the
Geoscape still working under them (the control port's top screen
`UILWGeoscape`).

### Left open

- The bottom-right panel (EW's project queue) still shows a placeholder
  line; `SetCurrentResearch` fills only part of it, and the rest is not
  read yet.
- The bar overlaps the Geoscape screen's ENGINEERING button; the plain
  screens go as EW's take their place.
- Labels are our own words ("CASH", "ALLOYS") until EW's are written by
  the setup program.

## Report (2026-11-02, the Situation Room)

**EW's Situation Room shows Long War's world** (`UILWEWSituationRoom`,
opened from the Geoscape screen's new SITUATION ROOM button, or `ewsitroom`).
- **The council's countries** in EW's order (read from EW's code:
  `XGSituationRoomUI.SortSitCountries`, `XGWorld.CreateCountries`), each
  with its name, its funding ("+" when a satellite watches) and Long War's
  panic in its bars; the doom tracker (countries gone).
- **The map**: XCOM's headquarters, the satellites and the UFOs seen, at
  each country's place on EW's map. The places are generated from EW's
  code (`XGWorld.CreateSatNodes`, `+MapPlaces` in `XComLWStrategy.ini`,
  numbers only).
- **EW's screens are now scaled to XCOM 2's stage** (`bScaleToStage`:
  EW laid them out for 1280 × 720, XCOM 2's stage is 1920 × 1080). Those
  that place themselves by the stage's edges, as the HUD, are not.

**What it took** (read from the movie's own ActionScript, with a small
disassembler of ours in /tmp; not kept):
- EW's movies carry their own `Colors` class, and XCOM 2's Flash has one
  of the same name, loaded first; ActionScript 2's classes are global, so
  EW's movies used XCOM 2's. `ew-ui.ts` now renames EW's to `EWClrs` (275
  names in the movies).
- The country name and funding are coloured by panic level 0 to 5
  (`Colors.wrapInPanicLevelHtml`); any other value gives no colour, and
  XCOM 2's Flash then draws nothing. Long War's version of the movie draws
  the bars from the same number over about a hundred frames. So the level
  (panic ÷ 20) goes to `SetCountryInfo`, and each bar is set to Long War's
  panic afterwards, queued after it (`MC.ChildFunctionNum`: calls through
  `MC` run in order at the end of the frame, `Movie.Invoke` at once, before
  them).

**Checked** (a new campaign, three days on): the sixteen countries with
their names and funding (UNITED STATES +§160, CANADA §36 …), their panic
bars (Russia's higher, in yellow), the HQ on the map, the HUD over it.

### Left open

- ~~The map behind is empty~~: done the same day, next report.
- EW's satellite launching from the room (its satellite mode and uplinks)
  is not wired; satellites are launched from the Geoscape screen.

## Report (2026-11-02, the earth behind the Situation Room)

In EW the Situation Room's Flash lies over a 3D world map in the room.
**Now EW's own holographic earth is drawn under the movie's map**
(`UILWEWMapBackdrop`): `FX_Globe.T_Earth_Holo`, from EW's
`Static_SituationRoom.upk`, converted by the existing `ew-package.ts` as
`EWSitRoomMap.upk` (26 MB with its textures inlined).
- EW's map coordinates are longitude and latitude scaled to 0 to 1 (the
  United States' place is x 0.217: −100°), so the earth picture lines up
  when stretched over the movie's map area. Its corners were measured by
  placing markers at (0.5, 0.5) beside the HQ at (0.217, 0.283): x 590,
  y 158, 750 × 498 on XCOM 2's stage.
- Loaded into the movie without joining the stack, just before the
  Situation Room, so it lies below; removed when the room closes.

**Checked**: the continents behind the map, the HQ marker on the United
States.

### Left open

- ~~The setup program converts neither package yet~~: it does since, next
  report.

## Report (2026-11-02, in the player's build)

**The setup program now converts Enemy Within's content from the player's
install** (`tools/setup/setup.mjs`): the strategy screens (`ew-ui.ts`) and
the earth (`ew-package.ts`) always; the maps (`ew-map.ts`, one child process
of the setup program each, with a 12 GB heap) when the player says yes, or
with `--maps`; then the missions play on Enemy Within's maps
(`PlaceEWMapWhole`). Converted content is kept when a newer build's setup
reinstalls the mod. The converters are now functions the setup program
calls (and still command-line scripts).

**Checked** (the release zip unpacked on the test machine, its setup run
with `--maps`; then the game with only the control port turned on): words,
screens, earth and 83 maps converted in under 4 minutes, none failed;
"Missions play on Enemy Within's maps (83 converted)". In a new campaign the
HUD, the Situation Room with its countries and the earth behind it. A second
run kept the maps ("converted already").
- Found on the way: the backdrop looked the earth up by its short path
  first, and in the release that found nothing visible; it now loads its
  package first (and logs where the earth came from).

## Report (2026-11-02, the person's first look)

The person: "i see the situation room sort of and the research selection
screen doesn't actually let me select".

**Research now selects, by mouse and by keyboard** (`UILWEWResearch`).
EW's list does not report its clicks to UnrealScript: they arrive only as
the raw mouse commands (`FXS_L_MOUSE_UP_DELAYED`, `…_DOUBLE_UP`) and the
row under the mouse is found by asking each row of
`itemList.theItems.<i>` for its size and the mouse's place in it
(`_width`, `_height`, `_xmouse`, `_ymouse`). A click selects (the row
lights, the panel shows the tech's days, summary and image), a double
click starts it, Up and Down (arrows and the numpad) move, Enter starts.
- `tools/test/key.ps1` now sends the arrows (and Home, End, Insert,
  Delete, Page Up and Down) as extended keys; without it Down arrived as
  numpad 2. And digits as `D<n>`.
- A new control-port aid, `ewvar <path>`, reads a variable of an EW movie.

**Checked**: a click on ALIEN MATERIALS selected it, Down moved to ALIEN
COMPUTERS, Enter started the research and closed the screen.

**The Situation Room sits on black, with the earth over its map**
(`UILWEWMapBackdrop`, now two of them): a black background loaded before
the room (the Avenger no longer shows through, as in the person's
screenshot), and the earth loaded after it at half opacity: under it, the
movie's tinted map panel left it too dark to read.

**Checked** (screenshot): black around the room, the continents clear in
the map panel, the HQ marker on the United States.

### Left open

- The selected research row's text is dark on its dark bar.
- The room's top-right box (EW's alien activity readout) is empty.
- The HUD's project queue is still a placeholder.

## Night log (2026-11-03)

- **The Situation Room's map colour.** EW's map is its holographic earth
  drawn through a teal material (the earth, a country index, clouds, line
  noise: `FX_Globe.MI_Globe_Holo_Dark`); ours is the bare earth texture. A
  tint through Flash's `setColor` (UIPanel.SetColor) was tried: it fills
  the image with the colour, the continents gone. **Decision:** no tint
  (`EarthTint` empty, opacity 50 as before). A first release went out with
  the fill for about ten minutes and was replaced. To do properly: a teal
  texture made by the converter from EW's earth and index textures, or a
  material on a 3D plane behind the movie.
