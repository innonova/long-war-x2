---
title: Enemy Within's emitters in its base (steam, mist, light beams, blinking lights)
status: in-progress
priority: 13
dependsOn: [ew-lightmaps, ew-compare]
---

# EW's emitters

## Purpose

The comparison's lighting items (round 6, #7 and #12) are partly EW's level effects: the autopsy room's mist behind the
research glass, the Gene Lab's steam, light cones under its lamps, consoles' blinking lights. EW places them as Emitter
actors in its base's levels; the port placed none.

## What is done (2026-11-19)

- **The converter** (`ew-map.ts`, converter 36) lists each level's placed emitters (`+Emitters`: the particle system,
  where it stands, its scale) and, per particle system, each emitter's sprite: its material's texture, whether EW's
  material adds (BLEND_Additive), its sub-image grid (`+ParticleLooks`).
- **Our particle materials** (`LWX2Lightmap.M_EWParticle`, translucent; `M_EWParticleAdd`, additive; made in the SDK
  editor): a SubUV texture parameter `Texture` × the particles' colour (emissive), its red × the particles' alpha as
  opacity; usable on particle sprites and SubUV.
- **The base** spawns EW's particle systems where EW places them, in the fixed rooms and the facility tiles
  (`LWX2EWMapPieces.PlaceEmittersOf`), each emitter's material replaced by an instance of ours with its sprite.
- **Seen on wingpu:** the autopsy room's mist behind the research room's windows; the Gene Lab's mist and steam.

## Report (2026-11-19 night, round 7's spill)

- The reviewer's round 7 (#3): mist patches over the base's black cutaway and a column of steam veiling the armory. Now:
  EW's emitters it keeps off or still are left out, their draw distance (`MaxDrawDistance`, 6000 where set) and time
  dilation (its slow steam, 0.3) kept (converters 38, 39); the armory's veil was one of those. From the base's whole
  view (its Base and Expansion cameras) the room effects are hidden, as EW shows none there; a room's view shows them
  (`LWX2EWBase.ShowRoomEffects`). A cull distance alone did not do it: the particle systems' bounds are large.

## Open

- **Density:** EW's cooked mist material keeps no expressions to read which channel its opacity takes (its
  "3Channel" textures pack three masks); ours takes red. Our particle materials now have an `OpacityScale` (SDK editor),
  set from `ParticleOpacity` (0.35, by eye against EW's capture) and `ParticleAddOpacity` (1): the mist now drifts in
  wisps as EW's. Still: the channel per texture.
- **Mesh emitters** (the Gene Lab's light cones, `Fog_Cones.HeadLight_Beam_NorDepth`) need a material for meshes, not
  sprites; not drawn yet.
- **Lens flares:** placed (converter 37 lists each source and its elements' textures; `LWX2LensFlare`, a spawnable
  LensFlareSource, as Unreal's is bNoDelete), each element on our additive material (now usable with lens flares). They
  draw, but at full strength they washed the room white: EW gives each element its own colour, alpha and distance
  maps (`Color`, `Alpha`, `DistMap_*`), which our flat material ignores. At `FlareOpacity` 0.08 they are a faint haze,
  not EW's warm autopsy lamp. The elements' colours and alphas are EW's own distributions, kept in the flare and
  handed to the material as the vertex colour (which ours uses); what ours lacks are EW's flare materials' intensity
  terms (`MI_Dot_Glow_*`: the source's distance and occlusion, Unreal's LensFlareIntensity/RadialDistance
  expressions). Next: a flare material of ours with those (SDK editor), then `FlareOpacity` back towards 1.
- **The mission maps:** the plot writer could place the same (rain, smoke, fires); not yet.
