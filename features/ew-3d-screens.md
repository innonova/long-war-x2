---
title: Enemy Within's strategy screens on their 3D panels in the rooms, as EW draws them
status: planned
priority: 13
dependsOn: [ew-compare, lw-base-view, lw-ew-screens]
---

# EW's screens on their panels in the rooms

## Purpose

The comparison with EW (features/ew-compare.md) ranks it second and third: EW draws its research, engineering,
Foundry and Situation Room screens on panels standing in the room, in perspective, through a camera of their own
(Vahlen and Shen beside them); the port draws them flat over the room. And the Situation Room's wall shows nothing
where EW's country panels stand.

## What EW has (read from EW's code and Command1)

- **Each screen names a display and a camera:** `UIChooseTech` `UIDisplay_ScienceLabs` through
  `ScienceLab_UIDisplayCam`; `UIBuildItem`, `UIManufacturing`, `UIFoundry` `UIDisplay_Engineering` through
  `Engineering_UIDisplayCam`; `UIScienceLabs` `UIDisplay_Report`; `UISituationRoom` `UIDisplay_CountryPanels` through
  `Cam_SituationRoom`; the soldier screens and the interception their own.
- **Command1 places 17 `UIDisplay_LevelActor`s** with those tags (location, rotation, scale 2): ScienceLabs at
  (2713, -484, -2353), Engineering at (-321, -766, -2680), Report, Interception, the soldier screens, and eight
  CountryPanels pieces on the Situation Room's wall. The Cybernetics Lab and the Gene Lab have their own.
- **XCOM 2 has the same mechanism:** a screen with `bIsIn3D` and a `DisplayTag` draws into the 3D movie, which
  `UIDisplay_LevelActor`s with that tag show (the port already keeps the Avenger's armory displays attached:
  `LWX2DisplayWatch`).

## Plan

1. **The converter** writes each level's displays (`+Displays=(Tag, Loc, Rot, Scale)`) and its cameras' tags.
2. **The base** spawns an XCOM 2 `UIDisplay_LevelActor` per display, tagged as EW's, at EW's place.
3. **EW's screens** get EW's display tag and camera (`bIsIn3D`), drawing into XCOM 2's 3D movie, which those displays
   show.
4. **Checked** against EW's captures (`tools/compare`): research, build items, the Situation Room.

## Report (2026-11-17, research and engineering on their panels)

- **The converter** writes each level's 3D panels: tag, place, rotation, scale and EW's own panel mesh
  (`+Displays=`; Command1 has 17: `UIDisplayMesh` for most, `UI_situationroom_center/left/right/top/objectives` for the
  Situation Room's wall, `UIInterceptionDisplayMesh`).
- **The base** places a display actor of ours (`LWX2UIDisplay`, a spawnable `UIDisplay_LevelActor`) at each, with EW's
  mesh and XCOM 2's display material (`Strat_Overworld.Materials.UIDisplayMaterial_Overworld`, an instance per panel:
  XCOM 2's 3D movie sets its `Movie` texture on the panel's instance). Where no EW mesh was found, XCOM 2's plate
  (`UI_Plate_A`), turned and scaled to EW's 141 × 84 panel (`DisplayTurn`, `DisplayScale`).
- **EW's research and build/Foundry screens** go into XCOM 2's 3D movie (`UILWEWScreen.Push3D`) and show on
  `UIDisplay_ScienceLabs` and `UIDisplay_Engineering`, through EW's `ScienceLab_UIDisplayCam` and
  `Engineering_UIDisplayCam`: in place and size as in EW's captures. **Clicks reach them** (a research project chosen
  on the panel). Switch: `ScreensIn3D` in `XComLWEWMaps.ini`.
- **The engineering queue** (EW's CURRENT PROJECTS) beside it, from the HUD.
- **Not yet:**
  - **The Situation Room's wall:** see the next report.
  - **Vahlen and Shen** beside the panels (EW's characters in its base, not converted).
  - The Repair Bay, the Gene Lab, the soldier screens' own panels.

## Report (2026-11-18, the Situation Room on its wall)

- **EW's wall meshes** (`UI_situationroom_*`) showed only slivers of the movie: they take slices of EW's movie layout,
  which XCOM 2's 3D movie does not reproduce. In their place **one XCOM 2 plate across the wall**
  (`LWX2EWBase.PlateDisplays`: centre of EW's wall panels, facing the room, scale 1150), and the Situation Room pushed
  onto it through EW's `Cam_SituationRoom`: the countries, funding, the earth on the room's wall as in EW.
- **Clicks work there:** in EXALT's view a click on a country with an exposed cell opened the covert operative list.
- **Not as EW's:** EW's wall is curved and in panels, ours one flat plate; EW's objectives panel below it is not shown.
- **The satellites' view stays flat:** EW's Situation Room HUD over it is a 2D screen, as in EW, and its movie took the
  clicks meant for the wall's countries (XCOM 2 gives a click to the 3D movie only when no 2D Flash is under the mouse,
  `XComHeadquartersInput.LMouse`). Choosing a country works flat. To put it on the wall, the HUD's movie must stop
  catching clicks outside its panels.

## Report (2026-11-18, the wall live; the satellites' view on it)

- **The Situation Room's wall is live, as in EW:** EW keeps its UISituationRoom on the room's wall while at the base; the
  port's wall was blank until the Situation Room was opened (the reviewer's third item). The hub now opens it on the
  wall under itself (`UILWEWSituationRoom.OpenWall`, bWall: the countries, funding, the earth; no input, no camera of its
  own, kept drawn when it loses the focus), from the start and again whenever the hub has the focus back. The Situation
  Room itself, EXALT's view and the satellites' view take its place on the wall while open (`CloseWall`). Seen on wingpu:
  the wall in the room view and, small, from the base view; the Situation Room and the satellites' view opened and
  closed over it, the wall back after.
- **The satellites' view on the wall too** (`SatellitesOnWall`): clicks on the wall's countries now reach it under the
  HUD (a click on Canada chose Canada), so the earlier reason to keep it flat is gone.
- **Still not as EW:** EW's wall is curved panels each showing its slice of the movie (the lists narrow at the sides, the
  map wide in the middle: about 59 % of the wall against our single plate's 37 %), and its satellites' camera
  (`SituationRoom_UIDisplayCam_MainScreen`, read from EW's code) frames it closer. With our flat plate that camera cuts
  the lists, and `Cam_SituationRoom` leaves the HUD's lower panel over the last rows. Next: EW's own wall meshes and their
  UV slices (why they showed only slivers), then its camera.
