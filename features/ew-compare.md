---
title: Comparing the port's look with Enemy Within's, view by view
status: in-progress
priority: 12
dependsOn: [ew-harness]
---

# Comparing the port's look with Enemy Within's

## Purpose

The person's (2026-11-17): a better way to compare the visuals of the two games than eyeballing the port against memories
of EW. The same view captured in both games, put side by side, with the differences found by tools and by a second model,
so the fixes are driven by evidence and the person is not needed on every round.

## Plan

1. **Views:** a catalog of named views. Each says how to reach it in the port (the control port) and in EW (the harness:
   a save loaded, clicks). It starts with the base overview, each room, and EW's strategy screens (research,
   engineering, build facilities, the hangar, the Situation Room, Mission Control and its alerts). Tactical spots on EW's
   maps come once the harness has the keyboard. The base rooms align almost for free: the port looks through EW's own room
   cameras.
2. **Pairs:** one script drives both games to a view and writes a side-by-side image (`logs/compare/<view>.png`), both at
   1600 × 900.
3. **Hints:** per-region differences (both images downscaled, cell by cell: brightness, saturation, edge density, SSIM),
   ranked, with crops. Plus a non-visual inventory: EW materials that fell back to grey or were skipped by the converter.
4. **A reviewer:** a Codex helper (gpt-6-astra) gets each pair, its hints and a short description of the view. It returns a
   ranked list of differences that matter (not fonts or the UI's own differences), which the fixes are worked from.
5. **A gallery** of the pairs (local, never published: game art) for the person to look at when they like.

## Decisions

- **EW's state comes from the person's own saves on wingpu,** synced by Steam:
  - Game 55: 94 saves, 26 October to 1 November 2025, stock Long War 1.0, 29 of them in missions.
  - Game 56: 24 saves, stock Long War 1.0.
  - Game 58: 3 saves, Long War Rebalance, which writes "[LWR v2.06.00]" into a save's description.
- **The image tools** are a Python venv on this machine (`~/.cache/lwx2-compare`: numpy, Pillow, scikit-image) and
  ImageMagick. Nothing is installed on wingpu.
- **Screenshots to OpenAI** through the person's Codex account: fine by the person (2026-11-17). Nothing goes into a
  repository.

## Report (2026-11-17, the tools and the first two rounds)

**The pipeline works end to end** (`tools/compare/README.md`):
- **EW** in the harness, loaded from the person's Game 55 (December 2016, a built base): 20 views by clicks
  (`capture-ew.sh`): the base, the five rooms, research, Gene Lab, build items and facilities, the Foundry, the Repair
  Bay, the OTS, Psi Labs, Officer Billets, the aircraft list, satellites, the grey market, council requests, Mission
  Control. The other saves are held aside on wingpu (`SaveData-held`) while comparing: EW lists every save, and the
  person's 2025 campaign sits far down that list.
- **The port**: 14 views through the control port (`capture-x2.sh`) from a campaign just made.
- **Pairs and hints** (`pairs.sh`, `pair.py`), a local gallery (`logs/compare/index.html`).
- **The reviewer** (Codex, gpt-6-astra, agent `ewreview`): round one, 13 views and about 45 findings; round two, 9 fixed,
  6 partly, 30 open.

**Fixed from the comparisons:**
- **EW's screens at two-thirds of EW's size** (the hub, the hangar's list, the HUD): every EW screen is now drawn 1.5
  times larger and EW's framework told a 1280 × 720 stage, as EW scaled its whole stage. The room menus then needed
  their tabs' anchors taken back into the HUD's units (`UILWEWHub.TabAnchorsToHUD`).
- **Mission Control empty at a campaign's start**: a garbage collection purged the converted package before Flash
  found the movie; every EW screen now holds its movie (`UILWEWScreen.HoldMovie`).
- **The HUD follows EW's rooms** (`UILWEWStrategyHUD`, after EW's `UIStrategyHUD` and its `UIStrategyHUD_FSM_*`): the
  clock, event list (NEXT EVENT) and MISSION CONTROL on the base's view and in Mission Control only; EW's back arrow
  elsewhere (clickable); SCIENTISTS and CURRENT RESEARCH in the lab, ENGINEERS in engineering; EW's resource lines
  (CREDITS/MONTHLY/MELD; engineering's; Build Facilities').
- **The research room's menu** as EW's (Change Research Project while one runs, EW's help lines, the Gene Lab there).
- **The hub coming back** after Mission Control kept Mission Control's camera.

**Ruled out (so it isn't looked at again):**
- The base's "smeared" surfaces are not the diffuse: EW's master trim sheet (`HQ_MasterMaterial_DIFF`) is a normal
  grey diffuse with the panel detail in its colour channels; its alpha is a gloss mask. The rooms' palettes (EW's
  `Colorize A`–`D` on `HQ_Master_*Palette`) only tint, and the material graph that mixes them was stripped in cooking.
- The washed-out look is not the lighting level's choice (Day_Arid, Facility, Cave, NatureNight and none look alike),
  not the world ambient override (`WorldAmbientIntensity` 0 changes nothing), and not the stand-ins' white mask.

**Open, ranked by the reviewer, with what is known:**
1. **Light where EW has none.** With EW's placed lights at zero the lab still renders evenly lit: something fills
   every surface. In EW the rooms' outer shells and most of the base are black, because EW's light is baked into
   lightmaps (`Lighting.tfc`) and nothing reaches them. The same cause makes the cutaway's shells show (the reviewer's
   first item) and the rooms look flat (its third). The faithful fix is EW's lightmaps; first find the fill's source.
2. **EW's 3D screens drawn flat.** EW draws the Situation Room's map on the room's wall screen, the research and build
   panels at a slant in the room, and Mission Control as the 3D Earth. EW's base has `UIDisplay_LevelActor`s for this
   (`UISituationDisplayLevelActor_Right` in its log), as XCOM 2's Avenger has.
3. **Vahlen and Shen** stand in EW's research and engineering close-ups; the staff fill the rooms.
4. **Blank monitors and unlit lamps** (EW's `HQ_ConsoleScreen`, `HQ_CustomScreens`, `HQ_ColorizedLight_*`).
5. Smaller: the grey market's picture cropped; the satellite view's country columns too large; EW's Research Archives
   and Research Credits screens not in the port.

## Notes (2026-11-19, round 6)

- **menu-advanced, menu-secondwave** (round 6 #1): the port's captures were from 2026-11-18 07:59, before EW's menu
  scene; captured again by clicks, both now stand in EW's room (and EW's Advanced Options also reads "Disabled" for the
  first two rows).
- **scr-officers** (round 6 #2): not a difference to fix. Long War's Officer Billets (UIMedals, opened by
  XGBarracksUI.OnChooseMainMenuOption) moves no camera; EW's capture shows the Psi Labs' room only because
  `capture-ew.sh` opens it right after `scr-psilabs`. From the barracks menu the camera is the barracks', as the port has.
- **Round 6, fixed:** the Situation Room's ticker on EW's strip below the map, in EW's small type; the armory scene's
  grapple rope (EW shows it only with its animation) no longer hanging across the Situation Room's view
  (`PeopleSkipMeshes`); the Situation Room's screens with credits and the month's net only, the Grey Market with credits
  only, its title and total EW's; Command1's stray sidewalk tile, hidden in EW (its component's HiddenGame), no longer a
  black block over the hangar's bridge (converter 30); the wall's map behind other 3D screens (EW's map plane with its
  holographic earth; its council video plane and dark overlay, grey slabs over it, left out).
- **Round 6, open:** the soldier list's frame is about 8% narrower than EW's, while the summary's right panels are wider
  than EW's: not one cause. The Genetics Lab's four tanks (features/ew-base-people.md).
- **Round 7, fixed** (2026-11-19 night): room effects off the base's cutaway and out of the armory (emitters' off and
  frozen state, draw distances; effects only in a room's view); monitors with EW's UI panels; the soldier summary
  centred, its borders closed; no ticker in the satellite view; the bare wall as EW's map plane; resource lines in EW's
  colours with its meld symbol; people baked brighter; more of EW's texture tiling. **Open:** the promotion screen's
  right panels (its movie places them 80 units further right; notes in strategy-flow.md); the Genetics Lab's tanks;
  the roster frame's width (EW widens it for its medals column); a soldier item card for engineering's "?".
- **Roster width, settled 2026-11-20 (not a defect):** EW's soldier list sizes each of its compartments to the widest
  row's content (`SoldierListItem`: the name and nickname's text width, the promotion and psi-promotion icons where
  shown, the class text, with `SoldierList` taking the largest per compartment), and the frame follows. EW's capture
  has long nicknamed Master Sergeants with psi icons; the port's test campaign has Lance Corporals without nicknames or
  psi, so the same movie lays itself out narrower. A campaign-content difference, as the reviewer's exclusions have it.
- **The Genetics Lab's tanks, fixed 2026-11-20:** EW's canisters on their conveyor (features/ew-base-people.md); their
  glass's tone and the caps' colour still differ.
- **Grey Market's Sectoid Corpse picture, settled 2026-11-20 (not a defect):** the yellow-suited figure beside the
  Sectoid is in EW's own picture for that item (Long War's table, item 134: EW's `CorpseIcons.Corpse_Sectoid`, from the
  player's converted base); the round had no EW shot of the same item to compare with.
- **Round 8, fixed** (2026-11-20 night): Vahlen's black squares (converter 43: the brightened textures re-encoded); the
  mist fainter (0.2); the ticker in the strip below the map, EW's map plane only on the bare wall; the bare wall map
  brighter; engineering's "?" opens EW's item card for the selected weapon (range, Long War's damage and crit ranges:
  (3D+1)/4 to (5D+2)/4, crit (5D+1)/4 to (7D+2)/4, Damage Roulette's wider), armour (HP bonus) or small item (charges),
  its text and picture (`UILWEWItemCard.FillGear`). Tried and taken back: the custom screens' decal sheet (the whole
  sheet showed; converter 45).
- **Round 9** (2026-11-20 evening): fixed since round 8 by its account: Vahlen's black squares, the promotion screen's
  panels, Build Items' "?"; partly: the Gene Lab's tanks, the people's colours, the mist, the ticker. Its new #1 was
  mine: the people's emissive share had also gone onto EW's animated props (the hangar's craft and pads,
  engineering's robots), pale white; now characters only (`PeopleLitMeshes`). Also done after it: the ticker in EW's
  green (measured: 87 183 106 against EW's 91 183 105); no separate back arrow over hiring and the pending requests
  (their own Cancel, as EW); the tank glass dimmed and greyed toward EW's olive (81 75 40). **Open from round 9:**
  coarse metal and grilles (#2), the Repair Bay hologram (#3), blank or indistinct screens and the globe's halo (#5),
  room exposure and lamp colours (#6), the bare map (#7), the Repair Bay mist (#8), the menu's pale rear openings
  (#10), the research veil and Memorial glasses (#11), the transfer row's chevrons (#14), the main menu's buttons (#15).

- **Round 9 #10, the menu's pale rear openings** (tried, not fixed): they are bright sky through gaps in EW's shell
  room. Hiding the environment level's sky dome (`sm_sky_latlong`, the control port's `env sky off`) changed nothing.
  EW's own shell emitters (the globe's projection cones and haze) and its lens flares, placed with the scene, drew as
  large dark translucent panels across the view, so both are left out again. Open.
- **Round 9 #14, the transfer row's chevrons:** likely a capture-state difference. EW's capture shows the row focused
  before TRANSFER is pressed (its button reads TRANSFER, the chevron strip is the focused row's highlight); the port's
  capture is one step later (CANCEL TRANSFER). The rows' states sent to EW's movie match EW's (`AddShip`'s ship state:
  0 ready, 1 down, as `UIShipList.UpdateData`). To recapture both at the same step before changing anything.
- **Round 9 #11, the Memorial's glasses** (fixed): the coffee tables' second slot is left by EW to the mesh's own glass
  material, which the converted mesh does not carry, so XCOM 2 drew it with its default, white. Such slots are now
  given our glass pane by config (`GlassSlots`: `CoffeeTable_B:1`, `QabBeaker_A:1`). Other pieces with an empty slot
  (concrete piles, chairs, banners) are left as they are: not glass. Also fixed after round 9: the Repair Bay's
  freezer mist left out (`SkipEmitters`, #8); Vahlen's eye shade and hair.
- **Round 10** (2026-11-20 night): of round 9's top 15, fixed or withdrawn: the Repair Bay mist, hiring's and the
  requests' back arrow, the transfer chevrons (capture state); partly: the hangar whitening, the Gene Lab's tanks, the
  people, the ticker. Its new top 15 is mostly the long-standing material and lighting gaps: coarse metal (#1), the
  Repair Bay hologram (#2), the bare map (#3), blank and blurred screens (#4), the globe's halo (#5), the tanks' depth
  (#6), exposure (#7), lamps (#8), Shen's skin and Vahlen's flat coat (#9), the menu's rear openings (#10), the
  Memorial's wall colour and glasses (#11, #12), the hangar rock's blotches (#13), the research veil (#14), Mission
  Control's globe button (#15).
- **Round 10 #3, the bare wall map** (partly): the map plane had drawn EW's raw hologram texture (red borders, blue
  land, grey sea), so its land read darker than its sea; a copy in EW's wall colours is now made for it (converter 66,
  `earthWallMip`): land lighter than sea, light borders. It stays dimmer than EW's: raising its colour live (the
  control port's `basemat`, now with texture parameters) brightened it only toward a mid grey, with our unlit and our
  additive material alike, and hiding the wall's own 3D screen (`wall hide`) changed nothing. Likely the strategy view's
  tone mapping and exposure (round 10 #7), not the plane; to be taken up with that.
- **Round 10 #7, exposure** (partly): the port's darks were lifted (the research room's wall 32 38 39 against EW's 15 22
  21). XCOM 2 ignores the world's default post-process here (tried live, no effect: so the missions' EW grading,
  `EWGrade`, had done nothing either); the local player's override works. The base now darkens its shadows with it
  (`BaseShadows` 0.07: the wall 15 21 22, a console 82 147 146 against EW's 85 155 155), and EW's maps' grading goes
  through the same override, cleared at every battle's start (it outlives the map). The control port's `grade` sets it
  live. Seen: `logs/compare/base-grade.png`; a mission on the gas station with EW's grading.
- **Round 10 #8, lamp faces** (tried): EW's coloured lamps (`HQ_ColorizedLight`, blue 0.42 1.18 2.0) clip in our
  unlit material to a pale cyan-white; they are now at half strength (`LampGlowScale` 0.5) so their hue stays. EW's
  halos are bloom on colours over 1, which our clamped material cannot give. Not yet judged by the reviewer.
- **Round 10 #5, the globe's projection** (partly): EW's projection emitters (`P_Projection_Cone`, `_Secondary`,
  `P_Holo_Dots`, `P_Projector_Glass`) had drawn as large dark panels with our blended particle material; they are now
  forced additive (`AdditiveEmitters`), and the main menu scene places its emitters again: the globe has its light
  column above and below, no panels. Its halo is still weaker than EW's (bloom).
- **Round 10 #10, the menu's rear openings** (fixed): two causes. The streamed lighting level's own height fog (density
  0.025) sat in front of the gaps, and nothing closed the room behind them. A black backdrop sphere round the scene
  (`ShellBackdrop`, radius 60 units × scale) in our two-sided glass pane at full opacity (the lightmapped black, one-
  sided, was culled from inside even turned inside out), and the lighting level's `ExponentialHeightFog` switched off
  under the menu scene. The gaps measure 18 23 26 against EW's 16 29 34 (before: 80 93 118).
- **Round 10 #15, Mission Control's globe button** (left out, decision): EW's button beside Back
  (`UIMissionControl.OnMouseHologlobe`) toggles `XGGeoscape.ShowRealEarth` / `ShowHoloEarth`, which fire the Geoscape
  level's Kismet to switch EW's *space* Earth between its real and its hologram look (country colours by panic). The
  port's Mission Control stands in EW's room with the room's hologlobe, and has no space Earth; the button would have
  nothing of EW's to do. It comes with the space Earth, if that is ever ported.
- **Round 10 #1, coarse metal** (looked into, open): not texture size. EW's base metal (`HQ_Master`, a 1024×8192 trim
  atlas, `TEXTUREGROUP_Cinematic`) and its world textures meet the same group limits in XCOM 2 as in EW (World 1024,
  Cinematic 4096; EW's `DefaultEngine.ini` and WotC's agree), and the converter carries every mip. `HQ_Master` is a
  palette material (`Colorize A`–`D` per room: the hangar's greys and a blue 0.23 0.24 0.34) whose graph is stripped in
  the cooked package, so how EW picks a palette colour per surface is not readable; the atlas itself is grey with the
  alpha as a variation mask. What our stand-in lacks against EW is the specular and the normal map's relief under
  lighting (baked light only), which is likely what reads as flat and coarse. Left open.
- **Round 10 #13, the hangar rock's blotches** (fixed): the converter had taken EW's rock *detail* layer
  (`Rock_Detail_A_DIF`, which `HQ_Caves_Simple` tiles ×6) as the main diffuse, where the main is `Rock_A_DIF` (×2): a
  detail layer now comes last when picking a look's diffuse (converter 67). Drawn alone, the main layer is dark brown
  (the rock near black: 1 against EW's 21), as EW reads its grey grain from the detail: the two are now baked into one
  copy (`<main>_LWX2Detail`, `detailMip`): the detail tiled at the ratio of the tilings (3), shaded by the main's
  brightness at 60% and a quarter of its hue (APPROXIMATION, EW's blend is in its compiled shader; matched against EW's
  hangar: 12–32 against 21–32, grey-brown, EW's broad rock forms). Only the hangar's rock has a detail layer among the
  base's looks. `logs/compare/hangar-rock.png`.
- **Found on the way:** EW's persistent base level (`Command1`) has a SkyLight (166 165 149), a movable directional light
  (brightness 3) and four movable spots, all on the Cinematic_1 / Unnamed_2 lighting channels, none on static geometry:
  EW lights its base people with them, live. For the people's lighting (`features/ew-base-people.md`).

## Report (2026-11-21, EW's compiled shaders read)

EW's cooked materials keep their parameters only; what they do with them was guessed until now. Their compiled shaders
are in the player's `RefShaderCache-PC-D3D-SM3.upk` (each material's shader map: its shaders by type and id, its name,
its uniform expressions naming which parameter feeds which `UniformPixelVector_n`, and the Direct3D 9 code).
**`tools/convert/ew-shaders.ts`** finds a material's map, names its uniform vectors and disassembles a pixel shader
(shader model 3; a small disassembler of ours). Read so far:

- **`HQ_Master`** (most of the base's walls, floors and machinery): the trim atlas is sampled at UV0 × **(8, 1)** (the port
  drew it once: stretched eightfold, the reviewer's "coarse, stretched metal", round 10 #1) and **multiplied by one of its
  four palette colours** by the face's UV0 quadrant: Colorize A (u < 1, v < 1), B (u ≥ 1, v < 1), C (u < 1, v ≥ 1),
  D (u ≥ 1, v ≥ 1); the colours' w weights only the specular tint. Per room: the bar's beige and orange, the hangar's
  0.41 grey, the command rooms' greys (the port drew them white: the memorial wall cream, round 10 #11; the rooms pale,
  #7). **Done:** our lightmapped material (SDK editor) now has `PaletteA`–`D` and the quadrant choice in a Custom (HLSL)
  node, and `DiffuseUVTile` on its UVs; the converter writes each look's Colorize A–D and the 8×1 tile (converter 68).
- **`HQ_Master_EmissiveCombo_Vector`, `_EmissiveComboPallet`**: the same atlas at (8, 1) (now tiled too); their
  `TintColor` or palette colours only the strips the mesh's **vertex alpha** marks, emissive (×2): EW's coloured light
  strips (the hangar ramps' orange). **Open:** needs the vertex colour in our material.
- **`HQ_Caves_Simple`** (the cave rock): diffuse = (main × detail)^0.65 in linear light, specular colour √(main × detail).
  The baked copy (`detailMip`) now uses that formula, with the specular colour folded in at an average share (1.7,
  measured on EW's hangar), since our stand-in has no specular input (converter 69). The main layer's own rotation and
  offset are not carried.
- **`HQ_CustomScreens_B`** (the labs' and Gene Lab's wall screens): its `TintColor` is no colour but the decal sheet's
  region, UV = (UV0 + TintColor.xy) × TintColor.zw; the picture is the sheet's blue channel, × `Color`. Each screen now
  gets a copy of the sheet resampled to its region (`screenMip`), coloured by `Color` (converter 70; the earlier
  "TintColor hue" was the wrong parameter). The research wall's screen shows its grid of file icons over a world map.
  `HQ_CustomScreens_A` is another shader (three textures), not read yet.
- **After the palette** (captured): the memorial wall in EW's warm orange (147 109 33 against EW's 180 132 50, before
  147 114 76 cream), engineering and the bar warmer. The rooms read darker than EW's, by a median 1.73× in linear light
  over 15 views, cell by cell (the OTS 1.1×, the research room 1.5×, the hangar 3.4×): EW's specular, which our unlit
  stand-in has no term for, had been stood in for by the white palette. **Decision:** `LightmapBrightness` 1.7 (was 1.0)
  until a specular is carried; the hangar stays darker than EW's.
- **The custom screens' pictures** needed the glow stand-in to keep them (`GlowStandin` kept `_LWX2White` diffuses only).
- **Light strips and lamp faces** (converter 71, the material's part in progress): EW's lamp meshes carry vertex colours
  (`HQ_Light_LO_A`: alpha 255 on 12 of its 98 vertices, the lamp's face). The converter writes each emissive variant's
  `Strip` colour and `PaletteMode`; our material is to darken the atlas under a strip by the vertex alpha and add the glow
  (TintColor × 2, or the palette colour × TintColor × alpha²) to its emissive, its hue kept with the brightest channel
  capped at 1.
- **`HQ_CustomScreens_A`** (the hangar's floating holograms): translucent, s0 at UV0 × 0.5 + `Color`.xy, s1 at UV0;
  value = s0.r × s1.g + 0.3 × s1.r, × the vertex alpha as opacity, the vertex colour as its colour. A case for our light
  card material (vertex colour × alpha); not done yet.
- **Light strips** (material done, SDK editor): our lightmapped material darkens the atlas under a strip by the vertex
  alpha and adds the strip's glow (EW's TintColor × 2, or the palette colour × TintColor × alpha²), its hue kept with the
  brightest channel at most 1; the converter writes each emissive variant's `Strip` and `PaletteMode`.
- **The custom screens' pictures, sharp** (converter 72): each mip of a screen's copy is now made from a source mip as
  many times larger as its region magnifies the sheet (they had been resampled from the same-size mip: blocky at a
  distance). The research room's wall screen shows EW's two rows of file icons, the subroutine panel and the stripes.
- **The hangar's floor stripes** (`StripeTest`, read from its shader: the mesh's vertex colour, translucent through a
  ragged mask, lit): their orange is painted per placement in EW (`StaticMeshComponentLODInfo.OverrideVertexColors`;
  the mesh's own colours are white). The converter now writes a placement's painted colours into its mesh where every
  placement shares them (converter 73; in the base only this mesh). Drawn with our light card (vertex colour, additive),
  its strength by material (`LightCardScaleBy`, 0.3): 153 117 77 against EW's 157 104 47. The mask is not carried.
  `logs/compare/hangar-stripes.png`.

## Report (2026-11-21, reviewer round 11 and after)

- **Round 11** (`logs/compare/review/_summary.md`): improvements seen: texture detail (the trim tiling), the research
  wall screen; rock "much closer". New #1: deep shadows nearly black. Its menu findings (#6, pale openings) were judged on
  menu captures from 20 November: `capture-x2.sh` takes the hub's views only; the menus are now recaptured by hand.
- **#1, deep shadows** (fixed): `BaseShadows` 0.07 had cut everything below it to black once EW's palette darkened the
  surfaces. The base's grade is now set whole, matched by brightness percentiles against EW in three rooms: Shadows 0,
  HighLights 1.4, MidTones 0.9 (`BaseHighlights`, `BaseMidtones`): engineering 2 7 25 65 115 against EW's 9 16 33 67 107
  (before 0 0 10 59 128), the research room 19 30 49 84 113 against 22 29 44 71 112.
- **#6, the menu's pale openings** (fixed): a glass pane of the shell scene drawn with XCOM 2's translucent parent (loaded
  in the main menu, not in the base) and its white texture. EW's base and menu scene now always take our pane.
- **#4, the hologlobes** (partly): EW's `M_Globe_Holo` is a translucent glowing hologram; ours had been a pale opaque
  sphere. Our glass now takes an optional picture (`Diffuse`, `UseTexture`; SDK editor): its colour the glow, its green
  the opacity. The globes in the main menu and Mission Control are that glass with the converter's teal earth
  (`AdditiveGlowMaterials`, `HoloTint`, `HoloOpacity`): seas 30 83 93 and land 137 251 254 against EW's 38 121 135 and
  117 235 245. EW's halo and projection beams (bloom) are not carried. `logs/compare/menu-globe.png`.
- **Round 11 #3, blank screens** (fixed in the Gene Lab and the Repair Bay): EW's `HQ_CustomScreens_F` screens (instances
  A–E, placed small screens and the Gene Lab's big one) draw a region of the same decal sheet, its **alpha**, in a colour.
  Their roles are swapped against `_B`: `Color` holds the region (a grid: offsets 0–2, cells 0.5 × 0.28) and
  `TintColor`, set per placement, the colour (the instances' values show it; the shader tool's expression list had them
  the other way, see its caveat). Converter 74–75. The Repair Bay's monitor shows EW's white circuit picture, the Gene
  Lab's small screen its amber one and the big right screen EW's map picture.
- **Round 11 #5, the tanks** (partly): the tank glass is now our glass with EW's froth as its picture (its colour the glow,
  its green the opacity; `TankGlassMatch`, `TankGlassOpacity` 0.9, `TankGlassTintScale` 1.15): see-through between the
  froth, the column behind visible, 100 95 55 against EW's 83 77 42. Not carried: EW's fresnel edge (its colour where
  the glass turns away) and its fine honeycomb (the meld hexes over the froth); the hue a little greener than EW's.
- **Round 11 #9, the bright craft pad** (cause found, open): the launch pads are EW's skeletal bay pieces
  (`SM_Launchpad`, animated by the bay's matinee), drawn on the people's stand-in with `HQ_MasterMaterial_DIFF` (the
  brightened copy): no 8×1 tiling and no palette, which only our lightmapped material (static pieces) applies; so the pad
  shows the trim atlas stretched and untinted, under the bay's warm lamp. To do: the palette and tiling for skeletal
  slots of `HQ_Master` looks (the converter's `PersonSlot` with Palette/UVTile, and a lit skeletal material of ours that
  takes them), or our lightmapped material on the pad with a white light map.
- **Lamp halos (round 11 #7), tried:** EW's `HQ_ColorizedLight` is a flat HDR colour (its compiled shader: TintColor
  alone), its halo the renderer's bloom. The local player's post-process bloom (`bEnableBloom`, `Bloom_Scale` 1–3,
  `Bloom_Threshold` 0.6–0.3; the control port's new `bloom`) changed nothing visible in the strategy view: XCOM 2 does not
  bloom there through that override. Open; a halo would need geometry of its own (a soft card per lamp face).
- **Round 12** (`logs/compare/review/_summary.md`): confirmed improved: shadow readability, the restored screen pictures,
  the main menu's globe and openings, the craft pad's trim. Its #3 (pale openings in the New Game menus) was judged on
  captures from 20 November (only the main menu is recaptured by hand; the New Game screens need clicking into).
  **#4, the consoles' banded screens:** EW's `HQ_ConsoleScreen` samples its sheet at (u, v/4 + TintColor.w): each console
  shows one quarter-height panel, its picture the red + green + blue sum; we had drawn the whole sheet (four designs
  squashed). Each console now gets a copy of its band (converter 77). **#5, the tanks' streaks:** EW samples the froth at
  UV0 × 8 (red + green); an eightfold tiled copy now (converter 78). **#2, hard menu shading:** EW's menu scene is soft by
  depth of field and its haze; ours is crisp. Post-processing, which XCOM 2's strategy view did not take through the
  local player's override (bloom tried); open.
- **Round 12 #1, the Repair Bay** (partly): its room read 2.26× darker than EW's (median, linear light), the research
  room 1.0, engineering 1.4: a level-wide difference, likely EW's live lights in that lab. The lightmap brightness can now
  be set by level (`LightmapBrightnessBy`); the Cybernetics Lab at 2.0 brings it to 1.25×. The far corridor behind the
  panel stays darker (other levels), and the plinth paler than EW's.
- **Round 12 #3** (withdrawn): the New Game, Advanced Options and Second Wave captures recaptured by clicks (main menu
  LONG WAR at 216 1042, ADVANCED OPTIONS 965 775, SECOND WAVE 547 845 in the game's 1920 × 1080): all three in EW's room
  with the translucent globe and no pale openings; the round's images were from 20 November.
- **Round 12 #8, lamp colours** (partly): EW's `HQ_EmissivePallete` lamps (the Situation Room's side lamps among them)
  glow in one of four palette colours by UV0 quadrant × the vertex alpha (its compiled shader); we drew the whole lamp in
  Colorize A (orange, clipped cream). Now our strip glow with the palette (converter 81), each HDR colour softly tonemapped
  (1 − e^−c: EW's blue is 0, 0.64, 13.9): the side lamps cyan, 0 140 161 against EW's 2 214 255. The stair strips stay
  pale tan (159 129 103 against EW's orange 103 232 237 … their mesh not yet found).
- **Why glows read dull after the grade:** the base's grade (`BaseHighlights` 1.4: UE3's highlights divide the scene)
  darkens every glow by 1/1.4, and our material's palette glow is normalised to at most 1 before it (`g / max(1, …)` in
  its glow node), so no scale can make up for it: the Situation Room's stair strips (`SituationRm_LightCards`, quadrant A,
  vertex alpha 255) 159 129 103 against EW's 244 184 141. To do at the next editor pass: the glow node's normalisation
  replaced by a soft tonemap with headroom (the palette colours are already tonemapped in the mod, `SoftTone`), so the
  glows can be raised by the grade's factor.
- **The grade changed for the glows (decision):** `BaseHighlights` 1.0 (was 1.4) with `LightmapBrightness` 1.2 (was
  1.7): the Situation Room's stair strips 216 174 139 against EW's 244 184 141 (were 159 129 103); room medians against EW
  research 61/44, engineering 26/33, barracks 10/22, Situation Room 54/48, Gene Lab 36/40, Repair Bay 11/21 (mixed, about
  as before). Lightmaps at 1.0 tried: darker dark rooms, the bright ones unchanged.
- **Round 13** (`logs/compare/review/_summary.md`): seen fixed: the New Game screens' scene, the menu's monitor graphs,
  the Repair Bay's brightness, the Situation Room's lamp colours, the stair lights. **#2, engineering's robots flat white**
  (my regression, fixed): converter 76 had put every palette slot of an animated piece on our unlit material, meant for the
  launch pads; now only for `PaletteSlotMeshes` (`SM_Launchpad`). The people's light is also limited to characters.
- **Round 13 #12, the Psi Lab's lights** (open): EW's overhead light shafts are light cards (`PsiRoom_LightCards`,
  `HQ_ColorizedLight_VertexColor`: TintColor 0.51 0.55 2.03 × the vertex alpha², read from the shader); the converter
  now reads their unnamed TintColor (converter 83) and gives them our light-card material in that colour, softly
  tonemapped. They still draw nothing, as the Gene Lab's cards before: our light-card material itself is the open
  question (`features/ew-base-people.md`).
  **Fixed (2026-11-21):** the shafts were never the light cards (that mesh is flat at the ceiling: the lamp discs). They
  are six `Fog_Cones.HeadLight_Beam_Cheap` emitters, which the port left out as axis-locked (axis-locked fires once
  crashed mission maps); now drawn by name (`AxisLockEmitters`). Their violet is EW's per placed emitter: the
  components' instance parameters (`Color` 0.3 0.2 1.0, `Opacity` 0.4 / 0.2), which the converter now carries
  (converter 84, `Params=`) and the mod sets on each emitter. Every base emitter takes its own settings now (the Psi
  Lab's steam is EW's faint blue). `logs/compare/pairs/scr-psilabs.png`.
- **Lamp colours, second step:** `SoftTone` now takes per channel the greater of the colour scaled to its brightest
  channel and 1 − e^−c: the Situation Room's side lamps 0 190 218 against EW's 2 214 255 (were 0 140 161). The hangar's
  bridge-edge stripes stay cream: not its light cards (those are the palette lamps); their material still to find.

- **Round 14** (`logs/compare/review/_summary.md`): seen fixed: engineering's robots (#2), Shen's yellow cast (#4
  partly: his skin a little pale), the Psi Lab's violet shafts and discs (#12 partly). **New #1, my regression:** the
  lens flares at strength 8 drew oversized white streaks across lamps and fixtures, one over the loadout's name header.
  `FlareOpacity` 2 now: no streaks, the loadout header clear, the lamps a slight glow (seen on wingpu, four views).
- **Round 14 #3, the Gene Lab's tanks** (partly): `TankGlassTintScale` 0.85 → 0.6 brings the faces from 123 97 59 to
  117 97 58 against EW's 90 72 42 (measured on the same crop); the rest of the difference is the pale caps and what
  shows through, not the froth's tint. The caps are `SM_Canister`'s slot 0, EW's master sheet on XCOM 2's staff material; tried on
  our palette material (`PaletteSlotMeshes`, as the launch pads): no change, the slot carries no palette data. **Fixed:** its
  material is `HQ_Master_2Sided`, HQ_Master's two-sided twin, which the converter did not give HQ_Master's palette and
  8×1 tile; now it does (converter 85), and `SM_Canister` is in `PaletteSlotMeshes`. The caps are EW's dark grey metal;
  the faces measure 101 89 53 (EW 85 72 42). Left: the faces' yellow-gold mottle (ours greener and smoother).
- **Round 14 #5, Vahlen's coat** (partly): EW's people levels' own lights placed (`features/ew-base-people.md`).
- **Round 14 #9, the hangar bridge's edge paint** (fixed): the stripes are not the bridge's (`Hangar_RimSupport`, a grey
  palette over a grey atlas) but `Hangar_Floor_Stripes` (`StripeTest`: lit, translucent, its diffuse the vertex colour,
  painted orange 255 100 9 on its placement), which the port drew as a faint additive card over the grey: cream. Found
  by `basehide` in the settled view (a first test mid camera move had misled). Now the converter gives an untextured
  material its placements' painted colour as its look's tint (converter 86) and the mod draws `PaintCardMaterials` as
  solid paint on our translucent material at `PaintCardScale` 0.45: the stripes measure 187 139 35 against EW's 163 106
  45 (were cream, about 230 190 140).
- **XCOM 2's tonemapper off over EW's base** (round 14 #8 and the warm colours generally): the local player's post-process
  chain runs XCOM 2's filmic tonemapper (`UberPostProcessEffect.TonemapperType`, seen with the control port's
  `tonemap`); EW's renderer had none. Under it the warm highlights went pale: the memorial's lamp-lit wall 213 195 96
  for EW's 255 203 73. Now off while EW's base shows (`BaseTonemapperOff`, restored when the base hides) and the light
  maps lowered to match (`LightmapBrightness` 1.2 → 0.95): the wall 246 224 91 at 1.05; six views' mean brightness
  1.01–1.10× EW's (were 1.13–1.19× with the tonemapper off at 1.2). The Gene Lab's tanks read yellow-gold with it.
- **Round 15 #2, grilles as solid tan panels** (fixed): EW's `HQ_Grating` has no diffuse (DiffuseColor 0.04, a cut-out grid
  'Alpha Mask' tiled 'Tiling' times); the port fell back to a plain panel. Now the converter gives such a look its grid
  mask, darkened (×0.35), as the diffuse and EW's tiling (converter 87). APPROXIMATION: opaque, no cut-out. The armoury's
  tall grille behind the promotion panel reads as EW's dark grid.
- **Round 15 #1, hard colour patches** (cause, likely): the converter multiplies EW's two light-map atlases into one
  DXT1 texture (`lightmap-bake.ts`); in dark areas the re-encode posterises into green and violet steps, where EW multiplies
  them in its shader. Next: our lit material sampling both, the converter keeping them as EW has them (SDK editor).
- **Round 15 #1, the hard colour patches** (partly fixed): with a plain white light map on the research room's pieces
  (`basemat <text> self LightMap …`, a new form of the aid keeping each piece's own material) the green, violet and
  blue patches vanished: they were the converter's combined light map, EW's two atlases (colour × the directions' mean)
  re-encoded as one DXT1, whose dark texels lost their hue (8.6% mean hue error, measured offline). Now EW's atlases are
  kept apart (converter 88, `Split=true` on the pieces' light maps) and our material multiplies them per pixel as EW's
  shader does (`M_EWLightmapped`, SDK editor: `LightMapDir` and a Custom node, C × dot(D, ⅓)); the mod and the plot
  writer set `LightMapDir` where a level says `Split`. Seen on wingpu: the research room's ceiling without the coloured
  blotches; eight views' brightness as before (1.00–1.16× EW's). Left: some value banding in the darkest areas, likely
  the atlases sampled as sRGB (our copies are plain Texture2D, sRGB by default; EW's light maps are linear).
- **The light maps' curve** (converter 89, `LightmapGamma`): EW's compiled shader samples its two atlases raw and
  multiplies them (colour × LightMapScale × the directions weighted by the normal); its atlases carry no SRGB tag, so
  they take the class default, sRGB. Read linear (SRGB=False written by the converter) the remaining value banding of
  the darks vanished, but the rooms read twice as bright with lifted darks; with the sRGB curve applied in our shader
  instead (`LMGamma`, a parameter of both lit materials, SDK editor) EW's tones return and so does the banding. So the
  banding comes from how XCOM 2 stores very dark scene values, not from the texture. Chosen: `LightmapGamma` 1.6,
  `LightmapBrightness` 0.4 (six views' 10th/50th/90th percentiles 0.79/1.17/1.03 of EW's; at 2.2 and 0.95 about
  0.5/1.05/1.1); some banding in the darkest areas stays. Next, if it matters: a dither in our lit materials. Mission
  maps take the curve when converted again (the plot writer sets `LMGamma` from the config).
- **Round 16 #1, the remaining blotches** (fixed, by the curve): with `LMGamma` set live on engineering's pieces
  (`basemat … self LMGamma <g>`), red and olive blotches appear in the dark corners at 1.6 and strongly at 2.6, none at
  1.0: raising EW's colour atlas (normalized colour, noisy in dark texels) to a power exaggerates its colour noise. So the
  light maps stay linear (`LightmapGamma` 1.0), and EW's darker mid-tones come from the base's grade instead
  (`BaseMidtones` 0.9 → 1.25; higher darkens: at 0.75 everything read 2× EW's, at 1.5 0.6×). With `LightmapBrightness`
  0.4, seven views' 10th/25th/50th/75th/90th percentiles measure 1.06/1.00/1.03/1.00/0.89 of EW's; no blotches on the
  workshop's left, no banding on the research ceiling.
- **Round 16 #3, the Gene Lab tanks' caps** (fixed): their palette slot is drawn unlit at `PaletteSlotBrightness`; at
  0.6 (set for the launch pads under the old grade) the caps read light grey under the new base grade. At 0.2 they are
  EW's dark metal and the hangar's launch pads still read as EW's. Left: the faces' gold mottling (ours smooth olive).
- **Round 17 #1, the console pictures** (partly): EW's `HQ_ConsoleScreen` shader read again: with TintColor.w ≥ 1 it draws
  green + 4 × (red × a wave sweeping across in time) + blue × a scalar, at (u, v/4 + w); below 1, red + green + blue. The
  converter knew only the second; now both (converter 90, channel 7: green + 2 × red). The research room's desk
  terminals still show streaks where EW shows one crisp panel: their screens' UV range is not known (the live probes,
  `basemat`, did not change that view; likely another piece than the ones tried). Left open.
- **Round 17 #3, the Repair Bay plinth** (fixed): the plinth is `CyberneticsLab_I`, a piece of EW's palette material with
  no light map of its own, so it fell to XCOM 2's props material, which drew EW's trim atlas unmapped: pale streaks. Such
  pieces now take our lightmapped material with a white light map, the look's palette and 8 × 1 tile
  (`UnlitPaletteStandin`, `UnlitPaletteBrightness` 2.0, measured: the plinth top 84 115 150 against EW's 97 120 142).
  Its ring markings and blue-grey finish now as EW's; the hangar, engineering and base views unchanged.
- **Round 17 #4, the Gene Lab tank faces** (tried, reverted): EW's tank glass shader read
  (`ew-shaders.ts GeneLabTankGlassMaster`): it glows the froth (×8, red + green) in its `Color` (the instance's orange
  0.83 0.28 0) by a fresnel term, adds 0.05 × Color and a reflection, over the scene behind (the tank's olive fluid). The
  froth tinted in that orange alone read as orange tanks (84 60 31 against EW's 82 72 41, and visibly orange); EW's
  gold is that orange glow over the olive behind. Kept the olive tint (converter 90's); the gold mottling needs our
  glass to add a coloured froth glow over its own olive: a material change (SDK editor), next time.
  Also tried (same night): the froth copy baked in colour (EW's olive + its brightest froth × the orange); our glass takes
  its opacity from the picture's brightness, so the darker coloured copy made the tanks nearly transparent. Reverted. The
  way: a tank glass material of ours (SDK editor) with the froth as a glow mask over a tint, its opacity its own.
  Third try (same night): our own tank glass (`LWX2Lightmap.M_EWTankGlass`, SDK editor: `M_EWGlass` with the Opacity
  parameter wired straight to opacity) with the froth copy baked in colour, base and crest glow measured from EW's capture
  (body 58 53 32, crests 120 97 58). The tanks showed, mottled, but tan and in coarse blotches against EW's fine olive-gold
  veins (crests 184 144 77, body 43 41 31 against EW's 209 76 61 / 60 55 33: EW's crests are orange-red, the fresnel
  rim). Reverted to the olive tanks; the material stays in the package, unused. Next time: the froth's own detail
  (our copy reads blurred) and EW's fresnel rim.
- **Round 17 #8 and #9** (partly): the launch pads back at `PaletteSlotBrightness` 0.6 with the Gene Lab's canister caps
  at 0.2 by mesh (`PaletteSlotBrightnessBy`, a new setting): the craft pad lighter, nearer EW's lit grey; the caps stay
  dark. `FlareOpacity` 2 → 1.2: the thin white lamp streaks fainter, the loadout header clearer.
- **Round 17 #7, the hangar's rock** (partly): `LightmapMaterialScale` (new: a lightmapped material's brightness by a
  part of its path), `HQ_Caves` at 0.65: the hangar's rock 37 27 23 against EW's 28 20 19 (was 44 33 28).
- **Round 18 #2, the menu scene too bright** (fixed): the base's grade and the tonemapper switch were applied only when
  the base showed, not to the main menu's copy of EW's room, which read 1.6-1.9× EW's after the light maps went linear.
  Now `LWX2EWBase.ApplyBaseGrade`, called by `Show` and `ShowShell`: the main menu's 10th-90th percentiles 1.09/1.16/
  1.03/0.94/0.83 of EW's, the New Game screen's 0.89/0.79/0.97/1.02/0.86.
- **Round 18 #10, the menu globe's projector beams** (partly): `P_Projection_Cone_Secondary` (EW's colour (0, 0.55, 1)
  × 2 over life, read from its colour modules); at full strength on our additive material they were hard white shafts.
  `EmitterOpacityBy` (new: an emitter's strength by template), the cones at 0.35: fainter; still white rather than EW's
  cyan-blue, so the particles' own colour does not seem to reach our material for these (to look at: the cooked colour
  distributions' lookup tables as XCOM 2 reads them).
  Fourth look: `M_EWTankGlass` with the grey froth and the olive tint at 1.0 (config only, not kept): the faces' mean
  84 74 48 matches EW's 85 72 42, but greener and still cloudy, not EW's yellow-gold veins; left as committed.
