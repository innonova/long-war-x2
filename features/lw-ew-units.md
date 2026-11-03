---
title: Enemy Within's aliens in XCOM 2's missions (bodies and animations)
status: in-progress
priority: 3
dependsOn: [lw-missions]
---

The aliens of a Long War mission look like Enemy Within's: its small grey Sectoid, not
XCOM 2's tall one (the person, 2026-11-03: "i don't think i will be trying to win till we
have walls and the less big sectoids"). XCOM 2's units stay what plays them (their
abilities, AI, the HUD); what changes is the body: EW's mesh, EW's animations, a material
made in the game from EW's textures.

Everything converted on the player's machine from their own EW install, as the maps are
(`features/hard-parts.md`, experiment 1: XCOM 2 loads EW's skeletal meshes, AnimSets and
particle systems as they are; its materials it cannot draw).

## How

- **The body:** XCOM 2's `X2DownloadableContentInfo.UpdateAnimations` hook, when a pawn
  sets up its animations: EW's skeletal mesh, a stand-in material (an instance of
  `Materials.Approved.AlienUnit_TC` with EW's diffuse and normal maps), and EW's AnimSet
  after XCOM 2's own.
- **The animations:** XCOM 2's unit code plays animations by name (`NO_IdleGunUpA`,
  `MV_RunFwd_StartA`, `HL_StepOutA` …). EW's skeleton has other bone names (`hips_b`,
  `forearmL_b` …), so XCOM 2's animations cannot drive EW's body; EW's own animations
  must answer to XCOM 2's names. EW names them the same way with an `AC_` prefix
  (`AC_HL_IdleA`), and differently where the two games differ. A table (numbers and
  names only) says which EW animation stands for each XCOM 2 name; the converter writes
  a copy of the unit's AnimSet in which each sequence carries its XCOM 2 name (copies
  where one EW animation stands for several).

## Report (2026-11-03 night, first look)

- **Seen:** XCOM 2's Sectoids in a mission given EW's Sectoid body live (a control aid,
  `ewbody`): EW's small grey Sectoid, its stand-in material drawn, in a T-pose: none of
  the animation names XCOM 2 asked for were in EW's set.
- EW's Sectoid: 178 animations; XCOM 2's (`AS_Sectoid`): 164; 12 names shared (the runs'
  loop, the turns, `FF_FireA`, the climbs' loops).
