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
