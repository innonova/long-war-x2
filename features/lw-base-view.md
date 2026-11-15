---
title: "Enemy Within's base as the strategy layer's scene, in place of the Avenger"
status: in-progress
priority: 5
dependsOn:
  - lw-base
  - lw-ew-screens
  - hard-parts
---

## Purpose

The Long War screens sit over XCOM 2's Avenger, which was only ever temporary. The person
(2026-11-15): the strategy layer moves mostly to EW's own screens. EW's own scene behind
them is its base, the cross-section of rooms, the "ant farm". Squad select and the armory
stay XCOM 2's screens (lw-squad-select). They need a room of their own with spots for the
soldiers.

## What EW's base is (read from its packages and code)

- **`Command1`**, the base's map: its shell (20 placed pieces, 4 lights) and 16 always
  loaded levels.
  - The fixed rooms' geometry: `Static_SituationRoom`, `Static_Infirmary`,
    `Static_ScienceLabs`, `Static_Barracks`, `Static_Hangar` and `Static_Hangar_CAP`,
    `Static_MissionControl`, `Static_Armory`, `Static_Engineering`.
  - Their animated parts: `Anim_MissionControl`, `Anim_Barracks`, `Anim_Armory`,
    `Anim_Hangar`, `Anim_Hangar_LaunchBays`, `Anim_ScienceLabs`, `Anim_Engineering`.
- **The base's grid:** each tile below the top row gets a level streamed at its room location
  (`XGBase.StreamInRoom`, `GetRoomLocation`). The location is the `XComHQ_RoomLocation`
  actor tagged `R<row>_C<column>` in `Command1`. Which level depends on the tile:
  - a facility's: `Addon_Laboratory`, `Addon_Workshop`, `Addon_Foundry`,
    `Addon_PowerGenerator` …, by the native `FacilityToMap`;
  - else the terrain's: `Addon_SolidRock`, `Addon_Excavated`, `Addon_Excavated_Thermal`,
    `Addon_ThermalCave`, `Addon_Cave`;
  - an access lift in the shaft: `Addon_AccessLift_Excavated`.
- **The cameras:** the base's view and each tile's (`AddonCam_R<row>_C<column>`), and each
  room's display tags (`UIDisplay_LevelActor`).
- The existing map converter (`tools/convert/ew-map.ts`) reads these levels as it reads a
  mission map: barracks 342 pieces and 133 lights, Mission Control 66 and 239, a lab
  64 and 36, an excavated tile 27 and 21.

## Plan

1. **Converter:** read the room locations (`R<row>_C<column>`) and cameras from `Command1`
   into the map's section. Convert `Command1`, its `Static_` levels and the `Addon_`
   levels in the setup, like the mission maps.
2. **Maps:** each written as a real XCOM 2 map by the plot writer (`ew-plot.ts`). The base
   is our own map type, without a level volume or tile grid.
3. **In the game:** the base's levels streamed into the strategy world, away from the
   Avenger, with the facilities the Long War base has (`LWBase`'s tiles) at their room
   locations, streamed again as they change. The camera on EW's base view while the Long
   War screens are up.
4. **A room for XCOM 2's soldier screens:** squad select and the armory with stand spots
   in EW's hangar and barracks (eight for squad select, so that Long War's squad of 8 can
   be picked), in place of the Avenger's launch bay and armory.
5. **The Avenger not loaded,** once nothing needs it.

## Report (2026-11-15, the first look)

- **The converter** (`ew-map.ts`) writes a level's room locations and cameras by their tags
  (`+Rooms`, `+Cameras`). Levels without a `PhysicalMaterial` (most of the base's) now
  borrow a carried package's class to neutralise their world. Before, 14 of the 32 base
  levels failed with "no PhysicalMaterial".
- **On wingpu** all 32 base levels are converted with `ew-maps.ts` (named on its command
  line): `Command1`, the nine `Static_` rooms, and every `Addon_` facility and terrain
  level. The player's setup doesn't convert them yet.
- **`LWX2EWBase`** (an actor of the strategy world):
  - places `Command1`'s shell and the fixed rooms, 60 000 units below the Avenger, from the
    converted levels, with the runtime placer of the early map experiments, now able to
    place any converted level (`PlaceOf`, `PlaceLightsOf`, `MaterialFor` taking the level);
  - places each base tile below the top row with EW's level for what the Long War base has
    there (`LevelFor`: a facility's `Addon_` level, an access lift's, else the terrain's) at
    the tile's room location, and places it again when the tile changes (`Refresh`);
  - shows it through XCOM 2's own room camera: a camera actor of ours tagged
    `LWX2EWBase`, which `CAMLookAtNamedLocation` takes the view from, as it does from the
    Avenger's. Closing gives the view back to the Avenger's `Base`. (A `CameraActor` can't
    be spawned at run time, hence `DynamicCameraActor`. A plain `SetViewTarget` is
    overridden by the HQ camera.)
- The Long War Geoscape shows it when it opens and when it gets focus back. Control port:
  `basecam` asks for the view again and reports the camera, `peek` hides the Geoscape for
  a look.
- **Framing:** EW's own camera (`Base`, field of view 45) shows part of the base, framed
  for 4:3 and panned. `ViewLoc` and `ViewFOV` (XComLWEWMaps.ini) set a view of the whole
  base for 16:9: standing at (1100, 9000, −3600) in EW's coordinates, field of view 70.

Seen on wingpu (screenshot `logs/wingpu_ew_base_first.png`, not committed): EW's cross
section with its round cut through the earth, the fixed rooms at the top, the four rows of
tiles with the shaft, dug-out caves and rock, and the starting satellite uplink at row 1.

### Left open (next)

- **Materials:** several surfaces show the checkerboard of a missing texture. Their
  parameters are named otherwise than the mission maps', so the converter finds no diffuse
  map (`Command1`: 5 of 6 materials).
- **Light:** a blue cast over everything, from the Avenger world's own light or ours. Solid
  rock draws black.
- The base's levels converted by the player's setup.
- The scene behind the other Long War screens (each EW screen still puts the black
  backdrop over it), and the Geoscape's own background box, which covers it.
- Squad select and the armory in EW's rooms (plan step 4), and the Avenger not loaded
  (step 5).
