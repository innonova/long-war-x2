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
