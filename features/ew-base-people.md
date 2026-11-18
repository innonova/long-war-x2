---
title: Enemy Within's people in its base (Vahlen, Shen, the scientists and engineers at work)
status: planned
priority: 14
dependsOn: [ew-compare, lw-base-view, ew-3d-screens]
---

# EW's people in its base

## Purpose

The comparison with EW (features/ew-compare.md) ranks it third: EW's rooms have people. Vahlen stands beside the
research panel, Shen beside the build panel, clerks and engineers work in the rooms. The port's rooms are empty.

## What EW has (read from its packages)

- **Per room an animation level,** `Anim_<room>` (22: ScienceLabs, Engineering, Barracks, Hangar, MissionControl,
  Foundry, Laboratory, Workshop …), streamed with the room.
- **In it, `SkeletalMeshActorMAT`s:** Anim_ScienceLabs has `SM_HeadScientist` (Vahlen) and three `SM_ComClerkMaleBase`;
  Anim_Engineering `SM_HeadEngineer` (Shen), engineers, clerks, the robot welding arms. Each with
  `CIN_FullSoldier.AT_CinematicSoldier` as its anim tree, materials of its own, no AnimSets on the component.
- **Their motion comes from the level's matinee** (`Sequence`, an `InterpData` whose groups carry the AnimSets and an
  anim track of sequence names, each group bound to its actor through the Kismet `SeqAct_Interp`'s variable links),
  looped.

## Plan

1. **The converter:** each `Anim_` level's actors (mesh, place, materials) and, from its matinee, each one's AnimSets and
   the sequences it plays (and their loop), into the base's data.
2. **The setup converts the `Anim_` levels** with the base (the meshes and AnimSets load in XCOM 2 as EW's units' do).
3. **The base spawns them** as skeletal mesh actors with EW's meshes, materials and a looping sequence, lit like the room.
4. **Checked** against EW's captures: the lab with Vahlen, engineering with Shen, then the other rooms.
