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

- **Solid rock and the space behind the tiles** are empty black. The grey slabs over the
  tiles were EW's `DoNothing` pieces (a material that draws nothing; with the grey rule they
  drew grey): now skipped. EW's earth cross-section behind the tiles still needs finding,
  best against a screenshot of EW's own base (the EW harness).
- EW's emissive light strips (`HQ_ColorizedLight_*`, an HDR `TintColor`) draw grey: they
  want an emissive stand-in in their colour.
- EW's shared tile-border glow mesh (`HQ_RoomBorderFX`) isn't converted.
- The base's levels converted by the player's setup; the hub on by default.
- Squad select and the armory in EW's rooms (plan step 4).

## Report (2026-11-15, the hub on EW's layout)

A screenshot of EW's own base, from the EW harness (a Long War 1.0 Geoscape save loaded on
wingpu; `logs/wingpu_ew_original_base_top.png`, not committed), showed what the hub had
wrong. EW shows its base close, through its own camera, with black between the rooms; its
top menu has five rooms; MISSION CONTROL sits above the clock; and choosing a room moves the
camera into it and shows the room's own menu. The hub now does the same:

- **The base's view** is EW's own camera (`Base`, field of view 45): the rooms at the top,
  close, as in EW. `ViewFOV=0`; the whole-base view stays in the config.
- **The top menu** has EW's rooms: Research, Engineering, Barracks, Hangar, Situation Room.
  **MISSION CONTROL** is EW's own button above the clock (`SetHotlink`, its
  `missionControlButton`), opening the Long War Geoscape.
- **Entering a room:** the camera moves over a second into the room through EW's camera for
  it (`ScienceLab`, `ENGINEERING`, `BARRACKS`, `HANGAR`, `Cam_SituationRoom`;
  `LWX2EWBase.LookAt`, a camera actor of ours per EW camera), and the room's menu shows,
  with EW's options and help lines:
  - Research: Start New Research Project;
  - Engineering: Build/Buy Items, Build Facilities, and The Foundry once the Foundry is
    built (as EW's `XGEngineeringUI.UpdateMainMenu`; it was a button of its own);
  - Barracks: View Soldiers (XCOM 2's soldier list and armory, the Avenger given back);
  - Hangar: View Aircraft List;
  - Situation Room: the Situation Room, Visit the Gray Market (where EW has it).
  Escape, or choosing the room again, goes back to the base's view; Escape there closes
  the hub. A screen opened from a room returns to the room.
- **EW's words** for the rooms and options come from the player's install, written by the
  setup into `LongWarX2.int` (`makeHubWords`, 20 words), with plain fallbacks.
- **The lighting level** is now loaded once and only shown and hidden with the base.
  Removed and added again at once (a screen over the hub hides the base and the next shows
  it), it came back unseen, and the Avenger's red ambient light with it.

Checked on wingpu: the base's view (`logs/wingpu_ew_hub.png`, not committed) next to EW's own
screenshot; Engineering's room and menu (`logs/wingpu_ew_hub_engineering.png`); Build/Buy
Items and back into the room; View Soldiers and back to the barracks' view; Mission Control.
The ambient colour stayed neutral (255, 255, 243) throughout.

Control port: `hub <room 0-4>`, `hub option <n>`, `hub back`, `hub mc`.

### Decisions

- The room's menu is XCOM 2's list (`UIList`) at EW's submenu place, not EW's own submenu
  clip: `subMenuMC` takes `AddOption` but creates no options; its option symbol
  (`StrategyHUD_FacilitySubMenuOption`) comes from EW's shared components movie, which
  doesn't resolve in XCOM 2. Fixing that in the UI converter would let EW's clip be used.
- Of EW's room options, those Long War's port has no screen for yet are left out (the
  research archives and credits, the memorial, hiring, the psi labs, the repair bay and
  augmentation, the Situation Room's finances, requests and bonuses).

## Report (2026-11-15, the setup converts the base)

- **The setup converts EW's base** for the player on every run, like the strategy screens:
  its 31 levels (`Command1`, the nine fixed rooms, every tile's `Addon_` level), listed as
  `+BaseLevels` in `XComLWEWMaps.ini` (generated by `maps-config.mjs`). They go through the
  map converter like the mission maps, into the same `XComLWX2EWMap.ini`, but get no plots
  (`writePlots` leaves them out), and the count that switches missions to EW's maps counts
  only mission maps (`missionSections`): a player who converts no maps still gets XCOM 2's.
- `ew-maps.ts --base` converts them on the test machine.
- The hub opens only where the base is converted (`LWX2EWBase.Converted`).

## Report (2026-11-15, the hub on by default; the Avenger's light fixed)

- **The hub is the strategy layer's root** (`[LongWarX2.UILWEWHub] Enabled=true`) wherever
  EW's base is converted, which the setup now does; elsewhere the Long War Geoscape as
  before. Checked from a release zip (a90a3a1) installed by its own setup on wingpu: the
  base's 31 levels converted (two seconds or less each) and the hub showed it.
- **The Avenger's sky-and-light level is one daylight level at every hour**
  (`XComGameData.ini`, `XGBase.GenericTimeOfDayMaps` all `EnvLighting_Day_AVG`, no biome
  levels). Hiding the Avenger while the base is in view did not hold on every path: on the
  player's (the Geoscape closed to the Avenger, then the Avenger's LONG WAR GEOSCAPE button),
  its levels stayed visible whatever was asked, even of the map manager directly, and
  their ambient light of the hour (red at sunrise, blue at night) lit the base. With one
  level the light is the same in every campaign and at every hour: (255, 224, 160) on that
  path, (255, 255, 243) where the hiding holds. The Avenger itself, seen less and less,
  now always looks like daytime.
- The base's camera hides the Avenger after its move, not before: XCOM 2's HQ camera shows
  it again as it leaves its globe view for a room view.
- The engine takes the ambient light again (`bRefreshAmbientCubeRequested`) whenever the
  base's lighting level is shown or hidden.
- **The setup's map child has a time limit** (10 minutes): once, on wingpu, it wrote
  `Addon_Genelab`'s files and never exited, and the setup waited. The next run converted
  it in two seconds; a map that hangs now fails and is converted on the next run.

Checked on wingpu along the player's path: the Avenger's button opens the hub; Engineering;
Mission Control; a mission answered there opens squad select with the soldiers in the
Avenger's launch bay.

## Report (2026-11-16, squad select in EW's hangar; the base's light settled)

**Squad select stands the squad in EW's hangar** (plan step 4, the squad half), where EW
lined it up in front of the Skyranger, in place of the Avenger's launch bay:
- through EW's own camera for it (`AwayTeam`), a camera actor of ours that
  `UISquadSelect.UIDisplayCam` names;
- the soldiers in a row in front of it, facing it, in the order of the slots on screen
  (`LWX2EWBase.SquadSpot`; `SquadDistance` 600, `SquadSpacing` 80, `SquadFloorZ` −1714, the
  floor's surface: the floor mesh's origin, −1922, lies below it);
- no cinematic: the launch bay's walk-up and lineup are XCOM 2's Kismet in the Avenger. The
  soldiers stand idle (`CharacterCustomization`), shown (XCOM 2 makes cinematic pawns
  hidden), the screen shows at once, as the lineup's `PreM_LineupUI` shows it, and launching
  or backing out goes straight on (no `PreM_Exit` to wait for; the 20 s fallback stays for
  the launch bay);
- the Avenger comes back while the armory or a soldier's screens are over squad select
  (they stand the soldier in its armory), and the hangar again when it has focus back.
Checked on wingpu: a mission answered on the Geoscape opens squad select in EW's hangar with
six soldiers (`logs/wingpu_squad_ew_hangar.png`, not committed); backing out leaves the
mission on the Geoscape; launching loads the mission at once.

**The base's light, settled.** Three causes, each found by switching things off:
- **EW's sky lights.** Spawned in XCOM 2's strategy world they lit the base saturated red at
  times (lighting-only view: flat red by facing; off, gone). Left out of the base
  (`PlaceLightsOf ... bNoSky`).
- **The ambient cube is captured**: taken while the camera was still at the Avenger, it
  kept the Avenger's light. Taken again once the camera has arrived (0.5 s and 1.5 s).
- **The Avenger's levels stayed visible** where XCOM 2's own hiding did not hold. Now every
  streamed level but the base's lighting level is hidden while the base is in view, asked
  of the engine directly (`ClientUpdateLevelStreamingStatus`), and exactly those shown again
  after (`HideWorld`, `ShowWorld`). In view of the base only its lighting level is visible
  (`ambient` lists them).
- EW's lights in the base at three times EW's brightness (`BaseLightScale`), as before.
The hub and squad select came out the same in repeated campaigns. The base is darker than
with the sky lights, as EW's own gaps between rooms are.

Test aids: `lights near <radius>` (the lights on near the camera), `ambient` (with the
visible streamed levels).

### Left open (next)

- Squad select's slots 7 and 8 (Long War's squad of eight; the hangar has room).
- The armory in EW's rooms (its loadout and soldier screens still stand the soldier in the
  Avenger's armory).
- EW's glowing light strips; EW's own submenu clip.

### EW's own room submenu: tried (2026-11-16), not solved

The strategy HUD's `subMenuMC` takes `AddOption`, `SetHelpText`, `Show` and `setFocus` but
creates no option clips. Its `AddOption` comes from a class of EW's shared components movie
(only the movie's sample code names it), so that class isn't there. Ruled out:
- the components movie not loaded: it is in the converted package (`ewxComponents.Components`,
  `ewxStrategyComponents.StrategyComponents`), and loading both before the HUD changed nothing;
- the import paths: some are written with backslashes (`..\gfxComponents\components.swf`);
  all 472 rewritten with forward slashes changed nothing (reverted).
Next to try: whether EW's component classes clash with XCOM 2's of the same names (as `Colors`
did, which the converter renames), by dumping which classes the components movie defines.
XCOM 2's list stands in meanwhile.

## Report (2026-11-16, building the base on EW's own screens)

**Build Facilities** (the hub's Engineering room) is now Enemy Within's own screen over its
base, in place of the plain grid (`UILWEWBuildFacilities`, its `BuildFacilities` movie, driven
as EW's `UIBuildFacilities` drives it):
- seen through EW's camera for building (`Expansion`: the whole base);
- a card per tile below the top row (`UpdateFacilityCard`): EW's icon for each facility
  (`UIUtilities.GetFacilityLabel`'s frames by Long War's facility numbers), rock, steam,
  dug, and work under way with EW's "Days remaining: N";
- EW's cursor (`SetCursor`) with what choosing the tile does, in EW's words (EXCAVATE and its
  cost, BUILD FACILITY, BUILD ACCESS LIFT) or why it can't (EW's "You must first build an
  access lift …", "You cannot reach this area without excavating.");
- choosing (Enter, or a click: the cards are clips `card_<column>_<row>`, found under the
  mouse as EW's clicks don't reach XCOM 2) excavates rock, begins an access lift in the
  shaft, or on an empty tile opens EW's **ChooseFacility** (`UILWEWChooseFacility`): the
  facilities Long War can build there, those it can't greyed with what they need, the cost,
  power, upkeep and days in the info panel, while the camera looks into the tile through EW's
  camera for it (`AddonCam_R<row>_C<column>`). Chosen, it is begun and the screen closes
  back to the base.
- The rules are Long War's base (`LWBase.Work`, `CanBuild`), as the plain screen's were.
- EW's words for both screens from the player's install (`makeBuildWords`, 15 words).
- Screens that show the base themselves (`UILWEWScreen.bShowsBase`) keep it in view: the hub
  and the Geoscape don't hide it under them.

The Officer Training School, the Psi Labs and the Genetics Lab are options of the hub's
Barracks room once built, as in EW (EW's words for the first two). They open the plain base
screen's panels until each has EW's own screen.

Checked on wingpu: rock excavated (cash 500 → 490, "EXCAVATING, Days remaining: 5", the
event list's EXCAVATION 5); a Laboratory chosen on an empty tile and begun (21 days); an
access lift begun by a click on the shaft's card; the Barracks room listing the Officer
Training School once one was placed. Screenshots `logs/wingpu_ew_build_facilities.png`,
`logs/wingpu_ew_choose_facility.png` (not committed).

### Left open

- Removing a facility and cancelling work (EW's REMOVE and CANCEL on the cursor).
- The facilities' descriptions in ChooseFacility (EW's text carries live numbers,
  `<XGStrategyActor:…/>`, to fill from Long War's).
- The adjacency markers on the cards (EW's `bAdjacencyBonusLeft/Top`).
