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

## Report (2026-11-15, the hub)

- **`UILWEWHub`**: the Long War hub on EW's layout. EW's base is in view behind it, and EW's
  strategy HUD movie (`StrategyHUD`) provides the room menu, filled the way EW's
  `UIStrategyHUD_FacilityMenu` fills it (`AddMenuOption`). The rooms are Mission Control
  (the Long War Geoscape: time, decisions, countries), Situation Room, Research,
  Engineering, Foundry, Barracks (XCOM 2's armory list, then its armory on the soldier),
  Hangar, Base and Grey Market. Escape closes the hub, back to the Avenger. The resources,
  clock and events stay on `UILWEWStrategyHUD` beside it, so the hub hides its own copies.
  - EW lays its menu out when its items load, which doesn't happen here, so every item
    sat at x 0. The hub lays them out itself in a centred row across the top.
  - EW's menu items don't report clicks to XCOM 2. The hub asks each item's clip where
    the mouse is (`_xmouse`, `_ymouse`), as the research screen does. The tab is drawn a
    little above its clip's box, so half its height above the box counts too.
  - A screen closed just before (the start screen) sends XCOM 2's camera back to the
    Avenger afterwards, so the hub asks for the base's view again 0.6 s later.
- **The height fog:** the base lies 60 000 units below the Avenger, inside the strategy
  world's height fog, which drowned it in the sky colour (red, nothing else visible).
  `LWX2EWBase.Fog` switches the world's `HeightFog` and `ExponentialHeightFog` off while
  the base is shown, and back on when the Avenger's view returns. With it off, the tiles
  show: caves, dug rooms, the uplink, the shaft.
- **Gated:** `[LongWarX2.UILWEWHub] Enabled=false` (XComLWEWMaps.ini) until it looks right.
  On, `UILWStartSelect.OpenGeoscape` opens the hub in place of the Geoscape; the Avenger's
  screen listener and the strategy-map redirect go there too.

Seen on wingpu (`logs/wingpu_ew_hub.png`, not committed): the menu across the top, the
HUD, and EW's base behind. Mission Control opens the Geoscape, and closing it returns to
the hub with the base in view.

### Left open (next)

- **Colour:** a red/purple cast over the whole base. The fog is off, so it comes from
  the Avenger world's light or post-process.
- **The fixed rooms** at the top barely show.
- **Materials:** EW's base palette materials (`HQ_Master`) draw as checkerboards. EW's
  shared tile-border glow mesh (`HQ_RoomBorderFX`) isn't converted. Solid rock draws black.
- The base's levels converted by the player's setup.
- Squad select and the armory in EW's rooms (plan step 4), and the Avenger not loaded
  (step 5).

## Report (2026-11-15, the base's light and the Avenger hidden)

The cast over the base (red, purple, blue, orange or green from one campaign to the next)
is gone, and the base looks the same in every campaign: EW's rooms in their own colours.

- **The cause:** XCOM 2's ambient light comes from a cube in the visible lighting level,
  here the Avenger's sky-and-light level for its region and hour (`XGBase.GetTimeOfDayMap`).
  The base is placed far below the Avenger, in the same world, so it took that colour. Found
  with `viewmode unlit`/`lightingonly` (neutral unlit; flat colours by facing in the light)
  and the engine's ambient colour (`GetNonDirectionalAmbientCubeLighting`), which matched
  the cast in each campaign.
- **The fix:**
  - while EW's base is in view, the Avenger is hidden as XCOM 2 hides it for its globe
    (`XGBase.SetAvengerVisibility(false)`: its rooms, terrain and sky-and-light level);
  - a fixed lighting level of XCOM 2's own is streamed in at the base for its ambient light
    (`BaseLighting`, the EW map plots' clear day, `EnvLighting_Day_Arid`), and removed
    again with the base;
  - its sun and fog are switched off with the world's, as are the Avenger's (only lights
    that aren't the base's own: EW's sky lights had been switched off too, as "the world's").
- **Given back for XCOM 2's soldier screens:** squad select and the armory stand their
  soldiers in the Avenger's rooms as they open, so the Geoscape and the hub give the
  Avenger back before opening them, and whenever another screen takes the focus. EW's
  screens put their own backdrop over it.
- **The base's camera** takes a neutral colour grade and no fog of its own
  (`CamOverridePostProcess`, which XCOM 2's HQ camera takes from the camera it views
  through).
- **Materials without a texture** (EW's vertex-coloured walls and lights, its screens) were
  drawn as XCOM 2's checkerboard. The runtime placer now treats them as the plot writer
  does: glass a translucent pane, markers, skies and decals left out, the rest plain grey.
- **Fixed rooms missing:** the generated config had put the fixed rooms' list under the
  hub's section, so none were placed. `maps-config.mjs` writes it under the base's.

Checked on wingpu: the same colours in two new campaigns (pixel for pixel at the sampled
points); Mission Control out to the Geoscape and back; the barracks list over the Avenger;
squad select from the Geoscape with the soldiers in the launch bay, and back to the Geoscape
with the base behind. Screenshot `logs/wingpu_ew_hub.png` (not committed).

Test aids on the control port: `open hub`, `lights` (the world's lights and lighting
actors), `lightoff <class> [on] [min radius]`, `ambient` (the engine's ambient colour).

### Tried and dropped

- Neutral post-process alone, the world's ambient variables (`WorldInfo.WorldAmbientCubemap`,
  unused by the renderer), shadowless lights, lights without light environments: none
  changed the cast. Shadowless light classes and direct lighting are kept for the base all
  the same (`LWX2BaseSpotLight`, `LWX2BasePointLight`; hundreds of shadowing movable lights
  are more than the renderer should carry, and EW baked its shadows).

### Left open (next)

- **The excavated walls and solid rock** draw plain grey: EW colours them by vertex colour
  (`HQ_ColorizedLight_*`), which XCOM 2's prop parent doesn't read. EW's earth cross-section
  look needs a parent that takes vertex colour, or the colour read into the look.
- EW's shared tile-border glow mesh (`HQ_RoomBorderFX`) isn't converted.
- The base's levels converted by the player's setup; the hub on by default.
- Squad select and the armory in EW's rooms (plan step 4).
