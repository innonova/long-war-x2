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
