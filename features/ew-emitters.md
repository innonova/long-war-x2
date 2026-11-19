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

## Open

- **Density:** EW's cooked mist material keeps no expressions to read which channel its opacity takes (its
  "3Channel" textures pack three masks); ours takes red. Our particle materials now have an `OpacityScale` (SDK editor),
  set from `ParticleOpacity` (0.35, by eye against EW's capture) and `ParticleAddOpacity` (1): the mist now drifts in
  wisps as EW's. Still: the channel per texture.
- **Mesh emitters** (the Gene Lab's light cones, `Fog_Cones.HeadLight_Beam_NorDepth`) need a material for meshes, not
  sprites; not drawn yet.
- **Lens flares** (`LensFlareSource`, 4 in each lab) not placed yet.
- **The mission maps:** the plot writer could place the same (rain, smoke, fires); not yet.
