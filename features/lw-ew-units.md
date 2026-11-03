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
- **EW's animations under XCOM 2's names:** `tools/convert/ew-unit-anims.ts` gives the
  unit's AnimSet a copy of an EW sequence for each XCOM 2 name it stands for (the same
  name, its `AC_` form, a table, the turns): for the Sectoid 150 copies, every one of
  XCOM 2's 164 names answered but `Zero`/`ADD_Zero` (XCOM 2's own sets, kept under ours).
  Seen: EW's Sectoid in an idle where it stood in a T-pose.
- **In the game by itself:** `LWX2EWBodies` (config `XComLWEWUnits.ini`): at template
  creation the body's AnimSet goes into the template's `AdditionalAnimSets` (XCOM 2's
  pawn adds them after its own; War of the Chosen has no animation hook for mods
  without the Community Highlander); each pod's pawns get EW's mesh and a stand-in
  material as the pod is shown (all of a Long War mission's aliens come from our pods),
  and every unit again at the battle's start (a loaded battle). Seen: EW's Sectoids
  standing, walking about the store in the aliens' turn.
- **The setup** converts EW's Sectoid package and renames its animations before its
  textures are inlined (a package written again would lose them); `ew-package.ts
  --anims <AnimSet>` does the same by hand.
- **Release** `LongWarX2-20261103-261ba7f.zip`, checked from the zip: the setup converted
  the Sectoid; a mission's 11 Sectoids all in EW's body.
- **Open:** XCOM 2's first-sighting scene (Tygan's "first time" moment) showed XCOM 2's
  Sectoid in close-up: a cinematic pawn of its own, not the unit's; EW's other aliens
  (Floater, Thin Man, Muton …) the same way, each with its table where names differ;
  the Sectoid's weapon and its psionic effects not looked at.

## Report (2026-11-03 night, thirteen species)

- **Generalized:** `tools/convert/ew-units.ts` lists Long War's species by the XCOM 2
  template they fight as (`FightAs` in `XComLWStrategy.ini`): Sectoid, Floater (Archon),
  Thin Man (Viper), Seeker (Faceless), Cyberdisc (Gatekeeper), Muton, Chryssalid, Zombie
  (PsiZombie), Outsider (Codex), Muton Elite (Andromedon), Berserker, Drone (AdvMEC_M1),
  Mechtoid (AdvMEC_M2). For each it finds the EW package's mesh, AnimSets and textures,
  converts the package with its animations under the template's names, and writes the
  bodies' list (`Config/XComLWX2EWUnits.ini`, gitignored, left out of releases: it names
  the player's conversions). The setup runs it.
- **XCOM 2's names per template** (`x2-anim-names.ts`, names only) generated from the
  SDK's animation packages by `sdk-anim-names.ts` (for development; a player has no SDK):
  the template's main set, its weapon's and its pod's.
- **Coverage** (XCOM 2 names answered / without an EW animation): Sectoid 153/2, Thin
  Man 117/23, Muton 124/12, Muton Elite 86/7, Berserker 61/14, Floater 48/20, Chryssalid
  42/28, Zombie 45/40, Seeker 39/19, Outsider 36/7, Cyberdisc 25/23, Drone 44/33, Mechtoid
  44/33. Where none answers, XCOM 2's own animation is asked for and does nothing on EW's
  skeleton: the unit holds its pose for that action. The tables for the non-humanoid
  species (flying, crawling) are the next refinement, by watching them play.
- **Seen:** a Muton, a Thin Man and a Floater spawned beside the squad in EW's bodies,
  standing in their idles; they still carry XCOM 2's weapons (the templates').
- Two species on one template share the first's body (Sectoid Commander as Sectoid,
  Heavy Floater as Floater).
- **Release** `LongWarX2-20261103-1976635.zip`, checked from the zip: the setup converted
  13 species; the office's Drones and Sectoids in EW's bodies (the Drone sits low: EW's
  hover may come from an animation not yet answered).
- **Gaps closed by what an animation does** (a fallback after the table: flying up and
  down from EW's jets, melee from EW's attacks and the Muton's bull rush, deaths, hurts,
  suppression, stuns, panic, reloads, signals): the gaps left are XCOM 2's own abilities
  (Bind, Anima Gate, Blazing Pinions, burrowing …). Seen: the EW Muton firing on a
  soldier (6 damage, disoriented), the Thin Man and the Sectoids moving in the aliens'
  turn.
- **XCOM 2's reveal close-ups** came with their own model of the alien (the template's
  cinematic packages): for a template with an EW body the mod drops those packages and
  the reveal prefix and the first-sighting scene; XCOM 2 then reveals the unit itself.
  Seen: the reveal camera on an EW Sectoid by a car.
- The mod's own reader of the map sections (`LWX2EWMapPieces`) did not know the pieces'
  new cover fields and logged a redscreen per piece; its struct has them now.
