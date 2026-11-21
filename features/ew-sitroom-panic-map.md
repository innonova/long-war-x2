---
title: The Situation Room's map in each country's panic colour, as EW's
status: in-progress
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

## Report (2026-11-21, first cut; not yet seen in the game)

- **The colour table** (`LWX2EWBase.PanicTexture`, `RenderPanic`): a `ScriptedTexture` of 256 × 1, cleared to
  transparent black, each council country's pixel (`PanicMapIndex`, EW's `m_CountryToIndex` in Long War's order) drawn
  in EW's `GetPanicColor` colour from its panic, withdrawn countries EW's (100, 0, 0). Redrawn whenever the base shows.
- **Our material** (`LWX2Lightmap.M_EWPanicMap`, SDK editor; unlit): the earth picture (`Diffuse`), EW's country index
  (`Index`, `T_Earth_Holo_Index`, G8), the table (`Colours`) read at u = index / 256; where the table has a colour, the
  earth mixed toward it by `Strength` (0.7), the country's own brightness kept (colour × (0.35 + 1.3 × the earth's
  luminance)); × `Tint`.
- **Wired** (`LWX2EWMapPieces.PanicMapStandin`, `PanicMapMaterials`): the Situation Room's wall map plane. The index
  texture is found beside the look's earth (`_LWX2Wall` → `_Index`); without it, the plain look stays.
- **Left:** satellites (EW's `ColorSatellite_SpecificIndex`: coverage marks), the hologlobes (they could take the same
  material), redrawing on a panic change while the map is in view.

## Notes (2026-11-21, where EW's panic colours are)

Seen in the game and in EW's captures: EW's base view shows the wall's map plane in its plain cyan, no panic colours;
EW's panic tints are on the Situation Room screen's own map (Argentina red in EW's capture), which in the port is the
earth image `UILWEWSituationRoom.AddEarth` puts into the movie's map area. So the plane is not the place: the material
and the colour table are kept, `PanicMapMaterials` left empty. Next: the screen's map in panic colours, e.g. the earth
drawn with the countries' colours into a `ScriptedTexture` (the earth texture, then each country tinted through the
index) that the map area's image shows in place of the plain earth.
- **Tried (2026-11-21):** the panic map drawn into a `ScriptedTexture` by `Canvas.DrawMaterialTile`
  (`LWX2EWBase.PanicEarthTexture`) and given to the screen's map image by `img://`: XCOM 2's movie loads only `Texture2D`
  through `img://` ("Failed to load 'Texture2D Engine.ScriptedTexture_1'"), so a render target cannot be shown that way.
  The route left: `GFxMoviePlayer.SetExternalTexture(resource, texture)` on an image the movie imports (EW's Situation
  Room movie's earth placeholder, or one of ours). The screen's map is the plain earth meanwhile.
- **EW's own design, likely:** EW's Situation Room movie leaves its map area clear and the 3D map plane behind it
  (`SituationRm_WorldMapPlane`, `M_Globe_Holo` with `Nation_Index` and the country colour texture) shows through, coloured
  by panic only while the room is up (`XComEarth.HighlightCountry` toggles each council country on). In the port the
  movie is drawn on EW's wall meshes through a render target, opaque where the movie is clear, so the plane behind is
  hidden and the earth is put into the movie as an image instead. Two routes: the wall screen's material translucent where
  the movie is clear (the plane, with our panic material, behind it), or `UIMovie.SetExternalTexture` (UIMovie extends
  GFxMoviePlayer) on an image with a linkage name in the converted movie, given the render target.
