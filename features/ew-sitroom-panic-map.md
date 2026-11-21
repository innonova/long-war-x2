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

## Notes (2026-11-21, EW's rules read)

- **`XGGeoscape.UpdateCountryColors`**: for each council member, `ColorCountry(its id, XGCountry.GetPanicColor())`, which
  goes to `XComEarth.HighlightCountry` → `XComHQCountryBorderToggles.ColorCountry_SpecificIndex(m_CountryToIndex[id],
  colour)` (and `ToggleCountry_SpecificIndex(…, true)`); satellites by `ColorSatellite_SpecificIndex(…, coverage)`. The
  border toggles' texture is native (C++): the port's own table replaces it.
- **`XGCountry.GetPanicColor`**: panic < 0 → (100, 0, 0); else by panic ÷ 20: 0 (92, 209, 108) green, 1 (103, 232,
  237) cyan, 2 (255, 209, 56) yellow, 3 (246, 116, 32) orange, 4 (238, 28, 37) red, otherwise (255, 0, 0).
- **`XComEarth.m_CountryToIndex`** (each `ECountry` to its index in `Nation_Index`): 0 208, 1 174, 2 29, 3 140, 4 71,
  5 64, 6 88, 7 82, 8 45, 9 244, 10 97, 11 232, 12 97, 13 232, 14 97, 15 98, 16 97, 17 97, 18 49, 19 20, 20 7, 21 119,
  22 179, 23 97, 24 232, 25 152, 26 161, 27 232, 28 161 (97 and 232 look like "no country of its own").
