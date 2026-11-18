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
  - **The Situation Room's wall:** pushed onto `UIDisplay_CountryPanels`, EW's wall meshes (`UI_situationroom_*`, at
    EW's place, rotation and scale; the three panels without an EW mesh left out) show only slivers of the movie: small
    regions of it, as if the movie's layout in XCOM 2's 3D render target were not EW's. Next: the render target's size
    and the movie's stage there, against EW's wall meshes' UVs. Left flat until then.
  - **Vahlen and Shen** beside the panels (EW's characters in its base, not converted).
  - The Repair Bay, the Gene Lab, the soldier screens' own panels.
