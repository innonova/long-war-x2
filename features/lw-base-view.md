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

## Report (2026-11-16, EW's screens on EW's own Flash framework; the room submenu solved)

**The cause** of the submenu that made no options (and of EW's Officer Billets rows): ActionScript 2
classes are global, the first definition of a name wins, and XCOM 2's Flash framework, which grew
from EW's, loads its own classes of the same names first (`Container`, `XComList`, `Navigator`,
`XComButton`, `Environment` …). EW's movies each compile the framework in (their
`__Packages.<name>` exports), but ran on XCOM 2's, which takes other calls. The earlier attempt
renamed ten of them, which left EW's classes building on XCOM 2's others (and matched names by
the byte before them, which misses export names whose symbol id is 256 or more).

**The fix** (`tools/convert/ew-ui.ts`): every class EW's movies compile in (260) gets a name of
its own, the same length (first letter Q; `Colors` stays `EWClrs`), in all 57 movies alike, by
the SWF's structure: the export and import tables and the ActionScript's strings (constant pools,
pushed strings, each dotted segment). Read with `tools/convert/swf-as2.ts`, a reader for a
package's movies (imports, exports, classes, ActionScript listing; its output is the games'
code and stays in the terminal).

What running on EW's framework needed besides:
- **The stage**: EW's `Environment` anchors screens by what `SetView` last said, which EW's game
  sent; XCOM 2 tells only its own. Each EW screen now tells EW's the same numbers XCOM 2 tells
  its own (`UILWEWScreen.SetEWView`), and makes the mouse active.
- **XCOM 2 widgets inside EW clips** (the Situation Room's earth, test lists): XCOM 2 makes a
  widget's clip by calling `spawnChildPanel` on the parent clip, which EW's clips had only
  through the clash. XCOM 2's own `spawnChildPanel` is lent to every movie clip without one
  (`MovieClip.prototype`; once a session, `UILWEWScreen.LendXCom2Spawning`).
- **The room row** is laid out by EW's framework, top right beside the resources as in EW; the
  hub's hand layout is gone.
- **The room menu is EW's own submenu** (`subMenuMC`, a clip at the HUD's root): attached to the
  room's tab (`facilityMenu.setFocus` with the tab's id as a string), `clear`, `AddOption`,
  `Show`, `UpdateLocation`, `setFocus`, `SetHelpText`, as EW's `UIStrategyHUD_FacilitySubMenu`
  drives it. Its `Show` waits for a frame on a hidden clip, which XCOM 2's Flash does not
  advance, so `onInvalidate` is called after it. The calls go at once (`Movie.Invoke`): queued
  through `MC`, `setFocus` found no tab. Hover selects (the mouse polled while a room is open:
  the submenu's own mouse events name no XCOM 2 panel and are dropped), arrows and Enter work, a
  click opens. XCOM 2's list stand-in is gone.

**Checked on wingpu** after the change: the hub (screenshot `logs/wingpu_ew_hub_submenu.png`),
research, Build Items, Build Facilities, the Officer Training School, the Foundry, the Situation
Room (its earth back after the spawnChildPanel loan), the grey market, the hangar.

Test aids: `ewset <path> <value>`, `ewinvoke <function> [args]` (at once, its result printed),
`ewcall`'s `s:<text>` for a string; `click.ps1 -Move` hovers.

## Report (2026-11-16, the armory in EW's rooms: tried, off for now)

- **EW's base has its own armory cameras** (Command1: `Armory`, `Armory_UIDisplayCam_Loadout`, `_Customize`, `_Promote`,
  `_Summary`). `UIScreenListener_LWArmory` keeps the base in view while XCOM 2's armory screens are up, looks through
  EW's camera for the screen and moves the armory's placement point (XCOM 2 stands its pawn there) in front of it on
  EW's floor (`LWX2EWBase.ArmorySpot`, `ArmoryDistance`).
- **Seen on wingpu:** the armory opened in EW's armory room, the soldier standing on EW's own round pad between its
  weapon racks and panels. Two things not solved:
  - **The menu is not there.** XCOM 2's armory screens are 3D: their menu is drawn on a display mesh in the
    armory's blueprint in the Avenger (`UIDisplay_LevelActor`), which does not follow when moved (its location read
    back far below the world).
  - **The soldier faces away from the camera**, whichever way the placement is turned.
- So `ArmoryInBase=false` (the armory stands the soldier in the Avenger's armory, as before); the code stays for the
  next try. A way forward: the armory screens drawn in 2D over EW's room, or a display mesh of our own in it.

## Report (2026-11-17, the armory in EW's rooms: a second try, still off)

- **The soldier now faces the camera.** The cause was not the placement: XCOM 2's armory hands its pawn to a mouse guard
  (`UIMouseGuard_RotatePawn`, the drag-to-turn), which sets the pawn to its own stored rotation every tick. The
  listener now gives the guard our rotation. (The Avenger's placement point does not move at all: it is static; the
  pawn is put in place directly.)
- **A display of our own** (`OwnDisplay`): XCOM 2's 3D movie draws on every `UIDisplay_LevelActor` with the screen's
  tag (`UIMovie_3D.ShowDisplayByTag`), so the listener spawns one with the blueprint's mesh and material beside the
  soldier as EW's camera sees it (`ArmoryDisplayForward`, `Side`, `Up`, `Yaw`, `Scale` in `XComLWEWMaps.ini`). The
  blueprint's display was not unreadable after all: EW's base stands at an offset far below the world (`BaseOffset`).
  **Not seen on screen yet:** the menu did not appear where it was put. A second look put it straight between the
  camera and the soldier: it is shown (not hidden), with the Avenger's display material, and still nothing is drawn
  there. Left: whether XCOM 2 draws its 3D UI meshes only through its own UI cameras or render pass, which the
  next try should start from.
- **Two things in the way of the look,** seen on wingpu: big grey curved panels fill EW's armory behind the soldier
  (EW's own room geometry, not our display: they stayed with our display moved far away), and EW's HUD (the clock, the
  council report, the resources) stays over the armory.
- `ArmoryInBase` stays `false`: the armory stands the soldier in the Avenger, as before.

## Notes (2026-11-17, EW's light strips: what a stand-in needs)

- **EW's strips** are many materials, `HQ_ColorizedLight_*` (in the converted base data's `+Looks`):
  - `PureVertexColor` and `VertexColor`: the glow's colour comes from the mesh's vertex colours;
  - `…_NoTint_Warm_A/B/C`, `…_NoTint_Cool_A`: fixed warm and cool ones;
  - a few per room (`_Excavated`, `_AC`).
- **An XCOM 2 parent that glows through a colour parameter alone,** with no static switch (switches cannot be set at run
  time), read from the SDK's uncooked `Materials.upk` (the cooked packages are Oodle-compressed, which upkit does not read):
  `Materials.Approved.Objective_UI` (`ObjectiveUIColor`, `Diffuse`, `Normal`). `Hologram_Props` (`HoloColor`) is made
  for units, and `Hologram_Translucent` has no colour. `Props_SD`'s emissive is behind `UseEmissive`, a static switch.
- **Next try:** strips as `Objective_UI` stand-ins with a white `Diffuse`: warm and cool by name, the vertex-coloured ones in
  EW's base teal until the colour can be read from the meshes. Then check against EW's own base in the EW harness.
