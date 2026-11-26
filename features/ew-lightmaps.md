---
title: Enemy Within's baked lighting on its base (and its maps), through its own lightmaps
status: in-progress
priority: 12
dependsOn: [ew-compare, lw-base-view]
---

# Enemy Within's baked lighting

## Purpose

The comparison with EW (features/ew-compare.md) ranked one difference first: the port lights EW's base everywhere EW
has none. The rooms look flat and washed out, and the cutaway's outer shells, black in EW, show lit. The cause: EW baked
its base's lighting, shadows included, into lightmaps; the port spawns EW's 717 placed lights instead, at three times
their brightness and without shadows (XCOM 2 shadows only a few movable lights, and which ones changes). Turned to zero,
the rooms go black: all their light is those lights.

## What EW stores (read from Static_ScienceLabs)

- **Atlases:** `LightMapTexture2D` exports in the level's package, pairs named `NormalizedAverageColor<n>` (colour,
  DXT1) and `DirectionalMaxComponent<n>` (directional intensity), their mips in `Lighting.tfc`.
- **Per static mesh component**, after its properties: its LODs (1); per LOD the shadow maps (0), shadow vertex buffers
  (0), the light map: type (2: 2D), the light GUIDs (count, 16 bytes each), three coefficients (a texture reference and
  a scale, three floats each: the colour atlas × (1, 1, 1), the directional atlas × (1.31, 1.13, 1.00), none ×
  (2, 2, 2)), then the atlas placement: scale (0.0606, 0.0606) and bias (0.563, 0.751). The lightmap's UV is the mesh's
  lightmap UV set × scale + bias.
- **XCOM 2 has no baked lighting:** its Avenger is lit by movable lights only, and none of its materials samples the
  second UV set (only a hologram). So the lightmaps cannot be handed to the engine as they are.

## Plan

1. **The converter** (`tools/convert/ew-map.ts`, run on the player's machine): each piece gets its lightmap (the two
   atlases, their scales, the placement); the atlases are written into the converted package as textures, as the
   other textures are.
2. **A parent material of ours**, made once in the SDK editor and shipped in the mod (our own content, no game asset in
   it): unlit, its colour the EW diffuse × the lightmap (colour × scale × the directional intensity), sampled on the
   second UV set with the placement as a parameter.
3. **The base's pieces** get an instance of it each (`LWX2EWMapPieces`), where their EW material has a diffuse; EW's
   placed lights then only where the lightmaps cannot carry it (none, to begin with).
4. **Checked** against EW's captures (`tools/compare`), then the mission maps.

## Decisions

- Lightmaps over tuning dynamic lights (posted 2026-11-17): the dark shells and corners are shadows, which only the
  baked lighting has.

## Report (2026-11-17, first pass: converter, material, run time)

- **The converter** reads each piece's lightmap (`ew-map.ts`, `lightmapOf`): 95 of the lab's 96 pieces, 1374 in the
  base. The colour atlas's mips are rewritten as colour × the mean of the directional atlas's channels
  (`lightmap-bake.ts`: DXT1 decoded and encoded again), and written as a plain `Texture2D`: bound as
  `LightMapTexture2D`, XCOM 2 crashed with heap corruption as the base came into view.
- **The material** (`LongWarX2/Content/LWX2Lightmap.upk`, `M_EWLightmapped`): unlit, Diffuse (UV0) × LightMap (UV1 ×
  LMScaleBias.xy + .zw) × LMBrightness. Made by hand in the SDK editor: pasting expressions as text into the material
  editor did nothing (its paste reads its own buffer), so the nodes were placed from the expression list and wired by
  mouse. The build precompiles its shaders (`LongWarX2_ModShaderCache.upk`). The editor first had to be freed of the
  mod's classes: every build writes them into the SDK's `Script\Manifest.txt`, and the editor asserts on them.
- **At run time** (`LWX2EWMapPieces.Lightmapped`): each lightmapped piece of a Prop look with a diffuse gets its own
  instance; its scales become one brightness (mean colour scale × mean directional scale × √3).
- **Checked on wingpu** (a new campaign, `tools/compare`): the research room, engineering and the base's view now
  show EW's light: dark perimeters and outer shells, lit work areas, the same pools of light
  (`logs/compare/lightmaps-first.png`, EW left, the port right; not committed). Still to come: EW's glowing parts (light
  rings, strips, monitors: emissive materials without a diffuse, not lightmapped), the brightness checked against EW's
  pixels, then the mission maps (`LightmapMaps`).

## Report (2026-11-17, EW's glowing parts)

- **The converter** marks EW's glowing looks `Kind=Glow` (`HQ_ColorizedLight*`, `HQ_ConsoleScreen*`) with their
  `TintColor` and a console's screen picture: 199 in the base. They get XCOM 2's `Objective_UI` in that colour, the
  base's teal where EW colours by the mesh's vertices (`GlowParent`, `GlowDefault` in `XComLWEWMaps.ini`).
- **Seen on wingpu** (`logs/compare/lightmaps-glow.png`, not committed): the lab's light rings and hanging lamps glow
  in EW's blue, its monitors are lit, the barracks' cutaway shells are dark as in EW.
- **Found on the way:** the base's conversion fails level by level while the game is running (it holds the converted
  packages through the build's hard links); `tools/test/on.sh` calls longer than its timeout report "fetch failed" and
  leave the conversion's joining step undone. Run it with the game stopped, detached (a batch file), and poll its log.
- **Left:** the consoles' screens show EW's test pattern (`HQscreens_test`, in green) where EW's show pictures EW's
  code sets; the Situation Room's wall map; the mission maps (`LightmapMaps`).

## Report (2026-11-17, the crash, and EW's cutaway)

- **An intermittent crash at a campaign's start** (heap corruption, 2 of 5 starts with the lightmaps): several of EW's
  lightmap atlases are not square (Barracks 1024 × 256, Engineering and Hangar 1024 × 512, 256 × 128), and the combined
  mips were made as squares, a different size in bytes than their headers say, read past their end as uploaded. Now made
  at their real width and height, and kept as they were unless the result has exactly their size. **6 of 6 starts
  clean** afterwards.
- **EW's cutaway:** EW's `DoNothing` material has no colour input, so EW draws those pieces opaque and black: the cut
  surfaces between the base's rooms and floors. The port skipped them, which left the rooms' outer shells in view. In
  the base they are now drawn black (`BaseBlackMaterials`): the barracks' view is close to EW's
  (`logs/compare/lightmaps-cutaway.png`, not committed).

## Report (2026-11-18, the glows on our own material)

- **Our material has a colour** (`Tint`, added in the SDK editor; the lightmapped instances set it white): EW's glowing
  parts now use it too, unlit as EW's are, in EW's own HDR colour (`GlowParent` = our material). The lab's light rings
  glow white-blue as EW's.
- **The consoles' screens** in EW's tint alone: EW's picture for them (`HQscreens_test`) is a green pattern EW's material
  uses as a mask; multiplied by the tint, as ours does, it came out green dots.
- **Hangar:** `Static_Hangar_CAP` left out of the fixed rooms: its dark beam crossed the hangar's view, open in EW's.

## Plan (2026-11-19, the mission maps: the middle way)

The person chose the middle way (2026-11-18): EW's baked lighting on interiors and on night maps, XCOM 2's lighting on
daylight exteriors; two maps tried first, with screenshots, before it goes into a download.

- **Not the base's material.** `M_EWLightmapped` is unlit: on a mission it would take no flashlight, explosion or
  unit shadow, and none of XCOM 2's building visibility (the roofs cut away) or fog, which its own parents' shaders
  carry. Interiors and night maps are exactly where those matter.
- **A lit stand-in with EW's light in it:** a copy of XCOM 2's `Props_SD` made in the SDK editor (so its building
  visibility and fog stay), with EW's lightmap (UV1 × `LMScaleBias`) added: emissive = diffuse × lightmap ×
  `LMBrightness`, the lit diffuse kept (dimmed by a scalar), so dynamic lights still add to it.
- **The plot** (`ew-plot.ts`) writes one instance per lightmapped piece where the middle way applies (a piece inside
  an EW building volume, or every piece on a night map), each with its atlas and placement; EW's placed lights stay
  for dynamic light, at a lower scale where the lightmaps carry the light.
- **First maps:** a night town map and a daylight one with interiors; captured beside EW's in the harness.

## Report (2026-11-19, the middle way tried on two maps)

- **Our lit material** (`LWX2Lightmap.M_EWLightmappedLit`, made in the SDK editor from `M_EWLightmapped`): lit, EW's
  diffuse into Diffuse (dynamic lights still add to it), EW's diffuse × lightmap × `LMBrightness` into Emissive; also
  usable on fractured meshes (the plots' breakable walls).
- **The plot writer** gives each lightmapped piece inside an EW building, and every piece of a night map, its own
  instance (`ew-plot.ts`, `PlotLightmapParent`), for the maps listed in `PlotLightmapMaps` while it is tried out:
  URB_Bar (night; 923 pieces) and URB_ConvienienceStore_EWI (day; its interiors).
- **Found on the way:** EW's lightmap atlases are private objects; the plots could not import them ("Can't import
  private object", the map failed to load). The converter now makes them public (converter 31).
- **Seen on wingpu** (`logs/compare/bar-lightmapped-*.png`, `store-lightmapped-*.png`, not committed): the bar's warm
  pools of light inside, the neon's red on the pavement, the roofs still cut away by XCOM 2's building visibility, the
  squad's flashlights still lighting the ground; the store's interior with EW's baked shadows. Daylight exteriors keep
  XCOM 2's sun. Bright white surfaces (the van's roof, the cars) read hot: lit and baked light add up there.
- **Waiting on the person:** whether this goes to every map (`PlotLightmapMaps` emptied), and whether the lit share
  should be lowered.

## Notes (2026-11-19, the rock's tiling)

- **The reviewer's "coarse, stretched rock"** (round 6 #6): EW's cave material (`HQ_Caves_Simple`) tiles its texture
  twice (`MainTile_U/V` 2, with `MainOffset` and `MainRotation`) and a detail layer six times; our lightmapped stand-in
  draws the texture once, so the base's rock reads twice as coarse. The fix: a `DiffuseScaleBias` parameter on our
  materials (UV0 × .xy + .zw, as the lightmap's UV1 already is), set from EW's tiling by the converter. It needs the
  material editor; a first try at copying the lightmap's UV nodes lost the graph's view (panning in that editor) and was
  left unsaved. **Done:** `DiffuseTile` (a scalar, UV0 × it) on both lightmap materials (SDK editor), the converter
  writes a look's `Tile` from EW's `MainTile_U` (or its parent's default; converter 33), the base and the plots set it.
  The hangar's rock now has EW's grain (`logs/compare/x2/room-hangar.png`). Not carried: EW's detail layer (×6) and its
  sparkle (specular), which our unlit stand-in has no input for.

## Notes (2026-11-19, the base's haze, beams and flares)

- **What the research room lacks against EW** (round 6 #7 and #12): the autopsy room's warm lamp, its beam and the haze
  behind the windows. These are not glass (hidden live, nothing changed) nor lightmaps: they are EW's level effects, 8
  emitters (`FX_SmokeB.Misc.Freezer_Mist`, `Steam_Small_*`, `FX_Environmental.P_Blinking_Light`) and 4
  `LensFlareSource`s in `Static_ScienceLabs`, which the converter does not list and the base does not place.
- **The way to bring them:** EW's particle systems load in XCOM 2 (the units' do), but their materials are EW's, which
  XCOM 2 cannot draw (`stub-materials.ts`). So: the converter lists each level's emitters (template, place, scale) and
  their sprites' textures; one additive particle material of ours (SDK editor: texture × particle colour, unlit,
  translucent, used with particle sprites) stands in, its instances given each emitter's texture by the converter
  rewriting the emitters' material references; the base spawns them. Lens flares likewise (XCOM 2 has
  `LensFlareSource`). A feature of its own; planned.

## Report (2026-11-19 night, the monitors)

- **EW's console screens** (round 7 #2): their picture `HQscreens_test` is a sheet of UI panels drawn in its green
  channel (accents in red and blue) that EW's material tints; tinted as a picture it came out green, so the port had
  drawn the screens in the tint alone, blank. The converter now adds a whitened copy (`_LWX2White`: each texel's
  brightest channel, `tint-textures.ts whiteMip`; converter 40) and our glow tints it: the research room's monitors show
  EW's UI panels in their cyan. `basenear` lists each slot's picture now.

## Decision (2026-11-20): lightmaps everywhere

The person found the road right only in "everywhere" (the store) and in the bar's middle way (a night map: there the
middle way is everywhere), and could not weigh the rest: decided on their behalf (chat decision #527),
`PlotLightmapEverywhere=true`, every piece of every mission map in EW's lightmaps, XCOM 2's dynamic lights still adding.
All 169 maps converted with it on wingpu.

**EW originals** (`logs/compare/lm-ew/`, not committed): two of the person's Long War missions loaded in EW on wingpu
(save314, Game 28, `URB_ConvienienceStore_EWI`; save1475, Game 55, `URB_Bar_Terror`; the other saves held aside and put
back), four camera turns each, and the port at the same spots (its pieces' places in `BuildCache\ewmaps\<map>.ini`;
`ForceMap`; the control port's new `yaw`): `pair-store.png`, `pair-bar.png`.

**What they show:** the biggest difference is not the lightmaps at all. The port is bright, white and blue in all three
modes alike; EW is darker and warm, its terror bar under a brown-orange smoke haze by day where the port shows a blue
night. Also: the store's SUV red in EW (an instance colour), white in the port; the wall by the bench tan stucco in EW,
blue-grey brick in the port. Next: EW's own atmosphere on its maps (its sun's colour and strength, its sky light, height
fog and post-process, from each level) in place of XCOM 2's.

## Report (2026-11-20, EW's atmosphere on its maps)

Found by switching XCOM 2's environment off piece by piece on the store map (the control port's new `env`, `env
ambient`): the port's blue-white was XCOM 2's environment, not EW's lightmaps.
- **The blue:** XCOM 2's environment level (`EnvLighting_Day_Arid*`) has an environment map capture
  (`X2EnvMapCaptureActor`) whose diffuse light, its sky's blue, falls on every lit surface; and its white sun at
  brightness 8, and its height fog.
- **EW's lightmaps are right:** with all of XCOM 2's off, the store's sidewalk is EW's warm hue (65,59,50) at half EW's
  brightness (138,127,92); EW's lightmap atlases are neutral to warm (decoded). The other half is EW's sun: UE3 never
  baked a dominant light into the lightmaps, it drew it live over them with baked shadows.
- **Now** (`LWX2EWMapPieces.UseEWAtmosphere`, at the battle's start on an EW map's own plot, `EWAtmosphere=true`): XCOM 2's
  sun and fog off, its environment light's diffuse 0 and specular 0.3, EW's own sun placed (each map's colour and
  direction: the store's warm, the terror bar's dim smoky brown, the night bar's blue moon), its brightness ×
  `EWSunScale` 2.2, measured on the store's sidewalk against EW (158,151,109 against 138,127,92).

Seen on wingpu (`logs/compare/lm-ew/pair-store-ew-atmosphere.png`, `pair-bar-ew-atmosphere.png`): both maps in EW's
tones. **Left:** the cars' own colours; EW's camera stands higher and farther than the port's.

**EW's fog and colour grading** (converter 50): each level's WorldInfo's `XComHeightFog` and default post-process
(`Scene_Colorize`, `_Shadows`, `_HighLights`, `_MidTones`, `_Desaturation`) written per map (`Fog=`, `Grade=`); at the
battle's start EW's fog on XCOM 2's height fog (its properties are const to script: set as the console's `set` does, the
fog switched off and on so the renderer takes them; density × `EWFogScale` 1) and the grading on the world's default
post-process (`EWGrade`). Seen on the terror bar (`logs/compare/lm-ew/pair-bar-fog-grade.png`): a slight change only.
EW's terror bar's fog is a thin dark blue-grey; its brown haze is its brown sun and its own smoke, and it is darker
than the port's (by eye, about half). Still open: that darkness (per map, or EW's night and terror lighting as a kind),
and EW's smoke emitters on mission maps.

**The cars' colours** (converters 51, 52): EW's vehicles' master material paints a car's `TintColor` (its own per car)
over the part its `Spc_Ems_Mod_Ref`'s blue marks; the converter bakes a tinted copy of the diffuse per colour, as for
the people, the tint taken as a linear colour made sRGB (EW's red SUV, 0.49 0.08 0.08, draws 171 82 68 in EW; ours now
195 88 57). A car without its own colour takes the master's default, as in EW. Seen on the store
(`logs/compare/lm-ew/pair-store-cars.png`). The people's colour mods use ×2 for the same conversion, by eye; to be
looked at again with this.
- Fog tried live on the terror bar (density 0.015 to 1.5, `set`): it only touches the far distance at the port's camera
  height; it does not give EW's grey haze. The terror bar stays pinker than EW's grey-brown; not pursued further for now.


## Notes (2026-11-20, the base's palette materials; round 9 #6)

EW's base pieces mostly use `HQ_Master` instances per room (`HQ_Master_HangarPalette`, `_EngPalette`, `_SciencePalette`
…) with four colours, `Colorize A` … `D` (the hangar's also a `TintColor`, cyan), over the shared
`HQ_MasterMaterial_DIFF`. That texture is greyscale (mean saturation 6 of 255), its alpha continuous (a mask, not a
palette index: no steps in its histogram). `HQ_Master` cooked keeps only its parameters (no graph) and has no emissive
input: EW's lamps glow through the lightmaps and light cards, not through it. Where the colours go is likely the
meshes' vertex colours (the HQ meshes have them) weighting A-D. The port draws the grey diffuse × EW's lightmap, which
already carries the rooms' warm and orange light; whether the palette adds much is not established. Next, if pursued:
a mesh's vertex colours read, then `Colorize` × vertex colour in our lightmapped material (SDK editor).

## Report (2026-11-25, a night map "still broken")

aek, 2026-11-25, after a full reconversion: the night map (URB_HighwayConstruction, his first mission) deep blue, with
glowing lavender patches, white spiky shapes, hard white pools and speckled discs (logs/map-lighting-1.png, -2.png).
Compared with EW's own view of its _EWI variant (his save1669, Covert Extraction; logs/compare/night/ew-highway.png).

Found and fixed (converter 95, every map plotted again; development build):

- **The moonlight counted twice.** EW lights its night maps with a static DirectionalLight already baked into the
  light maps and a DominantDirectionalLight drawn live; the port placed both as live lights. Converter 94 marks EW's
  static lights (`Baked=true`); on light-mapped plots the mod swaps them for lights on the units' channels only
  (LWX2UnitsSunLight, LWX2UnitsPointLight, LWX2UnitsSpotLight: a light's channels are const to script, so they are
  classes), so their light reaches the soldiers and aliens, not the ground a second time (30 of 32 lights on that map).
- **The glowing lavender patches were EW's rain runoff,** drawn with the plain grey stand-in (its materials have no diffuse
  map; only "Puddle" names were left out) and lit by the moon. EW's water (its X_Water package) is now a dark translucent
  film (XCOM 2's Translucent_SD, black at 0.35, specular 0.15); rain runoff always, whatever texture was found for it (a
  puddle's ripple noise drew as an opaque speckled disc). At specular 1 the moon's highlight made blue blotches.
- **The white spiky shapes were EW's alien webbing** over abductees (P_Fogged_Body_Webbing): EW colours each placement
  black at half brightness, which our particle stand-in does not take, so they drew white. Left out for now
  (`SkipEmitters`); to come back with a particle material that takes the instance colour.
- **XCOM 2's filmic tonemapper is off on EW's maps** (`EWTonemapperOff`), as over the base (EW had none): it deepened and
  saturated the blue (ground saturation 0.69 with it, 0.58 without; EW's 0.27).
- **A probe aid** (`probe x y`): what is drawn under a point of the screen, nearest first, with mesh, material and parent;
  no collision needed. It named the speckled discs and the blue blotches.
- **ewlook** (a test aid): EW's suns' scale, the light maps' factor and the fog's density set live, to tune a map's look.

Left open, measured:

- **The light maps contribute almost nothing on this map.** With the moon off, the light maps at 10× their brightness
  changed the ground from 14,27,38 to 17,30,41. The instances carry their atlases and LMBrightness (obj dump), so either
  this map's light maps are nearly black (its light is mostly the live moon) or our lit material's light-map term is
  weak; to be settled on a map whose EW view shows baked light (the Bar at night).
- **EW's fog has no effect in XCOM 2:** density 0.01 to 0.3 on XCOM 2's height fog changed nothing on screen. EW's fog
  there is warm (77,50,45), which is part of why EW's night reads grey-green rather than blue. *Corrected 2026-11-26:*
  that colour was read the wrong way round. A Color is B, G, R, A in memory (the lights' were read so, the fog's not):
  the highway's inscattering is (45,50,77), a blue-grey, so the fog would not warm the night; the converter now reads
  it as the lights'. Why XCOM 2's fog shows so little at EW's values stays open.
- **No rain:** EW's night highway has rain streaks and splashes, which lighten and grey its view.
  *2026-11-26:* EW sets a storm level per map (its WorldInfo's StormIntensity; the highway's LightRain) for its weather
  actor (XComWeatherControl), and XCOM 2 has the same actor in its lighting levels. The converter (97) writes the level
  (`Weather=(Storm=2,RainOpacity=0.5)`), and the mod sets XCOM 2's weather actor to it at the battle's start and wets the
  ground (LWX2EWMapPieces.SetStorm: the level by the console's set, the actor's enum being out of the mod's reach). Seen
  on the highway: thin rain streaks, as faint as EW's own there (`logs/compare/night/x2-highway-rain.png`, EW's
  `ew-highway.png`); XCOM 2's rain is lit by its sun, which is off on EW's maps. Test aid: `storm <0-7>`.
- **The soldiers' flashlight pools** (XCOM 2's at night) are XCOM 2's, not EW's.
- After these, the port's ground on the _EWI map measures 21,35,53 (saturation 0.49) against EW's 29,37,49 (0.25).
