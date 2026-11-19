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

## Report (2026-11-18, the people in)

- **The converter** (`ew-people.ts`, called by `ew-map.ts` for a level with people): each person's mesh, place, the
  AnimSets and loops of its matinee group (bound through the level's `SeqAct_Interp`), and each material slot's diffuse
  and normal (the component's slots, else the skeletal mesh's native list), as `+People=` lines. In such a package:
  the skeletal meshes' own material and FaceFX references cleared, EW's FaceFX, cinematic anim tree and IK notifies made
  inert, the sequences' notifies cleared. Each of these crashed XCOM 2 as the level loaded, a person was spawned, or an
  animation played; a native crash at each step, found by logging each step.
- **At run time** (`LWX2EWBase.PlacePeople`, `LWX2BasePerson`): 59 people in the fixed rooms' six `Anim_` levels
  (`PeopleLevels`), each looping EW's first sequence; XCOM 2's skeletal stand-in (`AlienUnit_TC`) per slot, with the
  props' white `Masks` (the placeholder had darkened the white coats). Hair takes EW's hair mask (grey: EW tints it by a
  colour parameter).
- **Seen on wingpu:** Vahlen beside the research panel holding her tablet, the clerks at the lab's consoles, the
  engineers and the welding robots working in engineering.
- **Not yet:** Shen is not visible beside the build panel (a robot arm shows where EW has him); hair colour; only the
  first of each person's sequences plays; the facility rooms' own `Anim_` levels (laboratory, workshop …).

## Notes (2026-11-18, where EW's matinee puts them)

Each group's move track (`InterpTrackMove`, no `MoveFrame` property: EW's default) holds positions in another frame
than the actors' own places (first key minus actor's place):
- **Anim_ScienceLabs:** Z +2498 for all four; X −3025 to −3956, Y +163 to +1668. The keys are small (Vahlen's
  (−195, 320, 47)), as if relative to something.
- **Anim_Engineering:** the conveyor arms (−2090, 0…144, +1922), the overhead arms (−2010, 32…144, +1842), the engineers
  (−1646…−2191, …, +1704…+1921), Shen (−2344, −462, +1853).
- Taking engineering's frame as the conveyor arms' (key + (2090, 0, −1922)) puts Shen at (−194, −582, −2786), right
  beside the build panel (−321, −766, −2680), where EW shows him, and the arms on the conveyor line. But the lab's keys
  don't fit the same reading, and Vahlen already stands right at her actor's place. To settle: EW's
  `SeqAct_Interp`/`InterpData` for a frame or anchor, or the level's own offset in EW's streaming; then read
  `ew-people.ts`'s `key`/`keyRot`, now written per person (`Key=` on `+People=`; `LWX2EWBase.PeopleFrames` places a
  level's people at key + offset: tried for Anim_Engineering with (2090, 0, −1922), no visible change).

## Report (2026-11-18, their colours)

- **EW's people in their own colours:** their stand-ins were instances of the aliens' parent (`AlienUnit_TC`), which drew
  them blue-grey (the reviewer: "Vahlen largely untextured"); the textures were found and loaded all along (logged per
  slot). Now XCOM 2's material for its own base's staff, `Materials.Approved.AvengerStaff_SD` (`PeopleMaterialParent`;
  found in the SDK's Materials package): Vahlen's white coat, green collar and skin as in EW's capture, the engineers
  and clerks likewise.
- **Still:** her hair draws dark (EW tints hair by a colour parameter it sets on the instance); Shen's place.

## Report (2026-11-18, the facilities' people)

- **The facilities' own people and animated props are placed with their tile** (`LWX2EWBase.PlacePeopleOf`, called for
  each tile as `Refresh` places its level, and taken away with it): the converter had them all along (15 in the Genetics
  Lab: scientists, clerks, the canisters; the Foundry, workshop, laboratory, radars, Cybernetics Lab). Seen: the Genetics
  Lab's scientist and clerk where EW's capture has them.
- **Not yet:** the Genetics Lab's three central tanks' glass (EW's `CIN_XEW_FX.GeneLabTankGlassMaster_Opaque`, a material
  of a cinematic package the converter does not describe; the tank frames are there).
- **Dark people (open):** the lab's clerks draw almost black under either XCOM 2 parent (`AvengerStaff_SD`,
  `Alien_SD_Cloth`): they are the only dynamic objects in rooms lit by EW's baked light, and the placed movable lights do not
  reach them; EW lit its people from its baked light (a light environment sampling the lightmaps). To do properly: the
  people lit from the room's baked light (an ambient for them from the lightmaps around them, or XCOM 2's own way of
  lighting dynamic objects in a baked room), not a lamp each. Also their chairs are missing (EW's chairs in that scene).
- **Tried and dropped:** the walls' custom screens as glowing screens with their picture sheet (`HQ_DecalSheet_A`): they
  drew flat cream, EW's parent applying its own UV transform and colour to the sheet.

## Report (2026-11-18 night, their places: the base's frame)

- **Where EW's matinee puts them:** EW hangs a scene's people and props on a hidden `CineDummy` (their `Base`), and their
  move keys are in that base's frame; the dummy itself is placed by its own group's key (Anim_Engineering's at
  (2042, 0, −1922)), else where it stands, turned by its yaw. `ew-people.ts` now places them so (converter 26); an actor on
  its own keeps its place. The per-level `PeopleFrames` guess (the earlier notes) is not needed.
- **Seen on wingpu:** engineering as EW's (the engineer in the middle, the welding arms on the conveyor line, one at the
  front right); **Shen stands beside the build panel**, as in EW (`logs/eng_build.png`); the lab unchanged but for Vahlen's
  turn. The hangar's launch pads follow the same rule (bays 2 and 3's pads sit 560 nearer their bay, under their craft).
- **Still:** the lab's two clerks stand where EW seats them (EW's chairs are not there); hair colour; the barracks' soldiers
  (EW puts the campaign's own soldiers in its barracks scenes, `Soldier01`… groups bound at run time).

## Notes (2026-11-18 late, the black clerks)

The labs' clerks draw almost black, and not for want of light (an ambient glow of 0.35 on every person's light
environment left them black). Their material is EW's `MInst_ComClerkMaleBase_SCI` on `CHH_Soldiers`, whose `CMOD`
(0.48, 0.50, 0.54 for the labs; 0.05, 0.07, 0 elsewhere) colours the uniform the diffuse leaves dark green-black. The
stand-in (`AvengerStaff_SD`) takes the diffuse only. The fix is a stand-in that applies `CMOD` where EW's mask says
(read the mask's channel from `CHH_Soldiers`), a material of ours as for the glass and light cards.

## Report (2026-11-18 late, glowing slots)

- **A person's or prop's slot of EW's unlit glowing materials** (`GeneLabTankGlassMaster`, the Genetics Lab's canisters'
  fluid; colorized lights, palette lamps) is written as `Glow=true, Tint=` (its `Color` or `TintColor`; converter 27) and
  placed as a glow in that colour (`LWX2EWMapPieces.GlowStandin`), not as a body stand-in with EW's hex pattern for a
  diffuse. The canisters' rack is not in the Genetics Lab's screen view, so this is not yet seen; the lab's yellow tank
  faces are something else again (still dark).

## Notes (2026-11-19, the Genetics Lab's tanks)

- EW's yellow tank faces are its light cards (`GeneLab_Lightcards`, `HQ_ColorizedLight_PureVertexColor`: the cards' vertex
  colour 253, 172, 30 is the faces' yellow). **XCOM 2 draws that mesh not at all:** placed, not hidden, one element, its
  vertices inside the room (x 96-1575, y -1220 to -393, z 312-530); with the room's walls hidden, and with an opaque, a
  translucent (our glass, opacity 0.8) or our additive vertex-colour material (`M_EWLightCard`) on it, nothing shows. The
  same likely holds for the research room's light beam and the Psi Labs' and hangar's light cards. Next: what in the light
  cards' mesh XCOM 2 rejects (its vertex colour buffer, its UV sets), by comparing a light-card mesh's data with a lamp's
  (`HQ_Light_LO_A` also has vertex colours and draws). Compared since: the same vertex layout (two UV sets, the same
  strides), the same property tags but for the light cards having no lightmap UV set; the glowing light rings (also
  vertex-coloured, Kind Glow) draw. The research room's light beam and the other rooms' light cards are missing the same
  way. Still open.
- The canisters (the yellow row along the top, Anim and Addon people records) draw, and their fluid slot is a glow.
- `M_EWLightmapped` lacks *Used with Skeletal Mesh* (the log warns once per prop); glowing slots on skeletal props draw
  with the engine's default material until it is ticked in the SDK editor.

## Report (2026-11-19, the clerks' colours)

- **The black clerks:** EW's character parent recolours the part of a body its `Spc_Ems_Ref_Opc` texture's alpha marks
  (the uniform) with the instance's `CMOD` (light grey in the labs, dark green in engineering); the stand-in took the bare
  diffuse, dark olive there. The converter now bakes a tinted copy of the diffuse per colour mod (`tint-textures.ts`,
  `<diffuse>_LWX2Tint<r>_<g>_<b>`, converter 28): where the mask is, the mod's colour shaded by the texture's own brightness
  (APPROXIMATION of EW's blend). Seen on wingpu: the lab's clerks in grey-blue uniforms, no longer black
  (`logs/compare/pairs/room-research.png`).

## Notes (2026-11-19 evening, the Genetics Lab's tanks again)

- **The light cards draw** (`basemesh`: rendered every frame; `basemat`: magenta when given another material) and glow
  as EW's with `M_EWLightCard`: the white ring over the column and the porthole's yellow crescents. They were never
  the missing part.
- **EW's four yellow tanks around the central column** are still missing, and are none of: the lab's static pieces
  (no tank material on any), the nine canisters (`SM_Canister`, a rack behind the wall; their scene slides them along
  it), or the station of EW's first gene mod scene (`CIN_XEW_1stGeneMod`, `SM_GeneLab_Station` with the yellow
  `GeneLabTankGlassMaster`: one tank, raised into the column over its 21 s; tried placed with the lab and taken out
  again). Next: what EW's code puts there (XGFacility_GeneLabs / the gene lab's 3D UI), or another streamed level.

## Notes (2026-11-19 evening, hair and skin)

- **Hair** (round 6 #5): Vahlen's is olive-blonde in EW, near black in the port. Her hair slot is `HeadSci_HAIR` on
  `CHH_MaleHairTemplates.Materials.CHH_HairMaskNrm`, whose only colour parameter, `ColorMod`, is white by default and not
  set by the instance. Decoded: the hairstyle texture is plain dark brown (its colour channels about a quarter of full,
  its alpha the strands' cut-out), so EW's parent lightens it. **Done (converter 32):** a brightened copy of each hair
  slot's texture (`tint-textures.ts scaleMip`: each DXT block's colour endpoints × 2.6, alpha kept; APPROXIMATION, the
  factor by eye against EW's capture). Vahlen's hair now reads olive-blonde as in EW.
- **Skin:** the head's `SkinColor` (1, 0.77, 0.55 for Vahlen) tints the skin mask (`Spc_dNrm_Skn_iBrw`, by its name the
  blue channel); not applied yet; the faces read a little dark.
