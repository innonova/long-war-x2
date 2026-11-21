---
title: The Situation Room's map in each country's panic colour, as EW's
status: planned
priority: 5
dependsOn: [ew-compare]
---

## The problem

EW's Situation Room wall map (and the hologlobe) colours every council country by its panic; the port draws EW's plain
globe texture, recoloured once by the converter (`earthWallMip`), so the map is flat teal and grey (the reviewer's "bare
map", round 10 #3, open since round 6).

## What EW does (read from its compiled shader, `tools/convert/ew-shaders.ts M_Globe_Holo`)

`M_Globe_Holo` (and its instance `MI_Globe_Holo_Dark` on the wall) samples twelve textures. Among them:
- `Nation_Index`: per pixel the country's index (its red channel);
- `earthColorTextureParam`, `earthIndexTextureParam`, `earthSatelliteTextureParam`: one texture EW's code fills, read at
  the country's index: its panic colour, a highlight, its satellite coverage (the shader multiplies the last by 50000 into
  a mask);
- the earth's own texture, scan-line and noise textures panned by time (`Time` × 100, × 91, × −0.3, × −0.4), `Color`,
  `ColorRamp`, `Spread`, `Pan`.
EW's code writes the colour texture per country (`XGGeoscape.UpdateCountryColors`, from each country's panic and
satellite) whenever they change.

## The way

- **The setup** carries `Nation_Index` and the scan-line and noise textures from the player's install (in the converted
  `Static_SituationRoom`), as it carries the globe texture today.
- **A material of ours** (SDK editor): the earth texture, the country index, a lookup into a small per-country colour
  texture by that index, the panned scan lines; unlit, the wall plane's and the hologlobe's.
- **The colour table at run time**: a `ScriptedTexture` (UE3's canvas-drawn render target) of 256 × 1, one pixel per
  country index, redrawn in EW's colours from Long War's panic and satellites when they change (EW's `UpdateCountryColors`
  rules, read from its script). The material reads it by index.
- **Checked** against EW's Situation Room capture (`tools/compare`): countries in their panic colours, satellites marked.
