---
title: "The hard parts first: Enemy Within's content, one of its maps, and one Long War strategy system, each in XCOM 2"
status: review
priority: 1
dependsOn: []
---

## Purpose

The person, 2026-10-31: "porting long war 1.0 to the xcom 2 engine, and not
the cheap way but building the actual strategic layer with new SWFs or
whatever it is, and the air war and porting the handmade maps". The draw is
"the customizable soldiers and the looks - i recognize that we may have to
accept xcom 1 looks for a lot of things but we can iterate". XCOM 2 rather
than UE5 as "the less radical move"; and "i like the idea of validating the
hard parts first".

The soldiers are what XCOM 2 does well, and Long War's classes and perks fit
its ability system; that part is not in doubt. Three things are: whether
Enemy Within's content can come across at all, whether its handmade maps
can, and whether a Long War strategy system can be rebuilt with XCOM 2's
UI. Each gets one small experiment here. What they find decides whether,
and how, the port goes on.

## Facts (2026-10-31)

- **The test machine** is wingpu (ssh wingpu, Windows): XCOM 2 with War of
  the Chosen (Steam), the War of the Chosen SDK (ModBuddy, the editor; the
  Visual Studio 2013 isolated shell), an Intel Arc integrated GPU, 31 GB.
  The SDK is on Steam's default branch (1.6 GB): the editor starts, without
  the game's editor content (materials, effects, sounds), which the
  `full_content` branch brings.
- **XCOM 2's SDK** ships the game's whole UnrealScript source
  (`Development/SrcOrig`); mods are built with ModBuddy and shared on the
  Workshop.
- **Enemy Within's packages** are read by upkit and by the Long War Tech
  Tree: textures, materials, skeletal meshes and animations (its 3D
  soldier), and every script. Its maps ship cooked.
- **Content:** a mod may ship our code and use XCOM 2's content. Enemy
  Within's content (the aliens XCOM 2 lacks, its maps) is Firaxis's and 2K's
  and is not shipped: it is converted from the player's own install, on
  their machine.

## The experiments

1. **An alien XCOM 2 lacks.** A Floater (or a Thin Man): its mesh,
   textures and one animation, read from an Enemy Within install, written
   as something XCOM 2's editor imports, and seen there, then in the game
   on a tactical map. Answers: can EW's content come across, and how much
   does a player have to do for it.
2. **One handmade map.** A small one (a crash site): from the cooked
   package to something XCOM 2 can load and play on, with cover and
   pathing. Answers: can the maps come across, and as what (a whole plot,
   or rebuilt).
3. **One strategy system.** The air war: Long War's exact rules
   (`XGInterceptionEngagement`, as the Long War Tech Tree models and checks
   them), as an XCOM 2 screen started from an XCOM 2 campaign, with a jet
   and a UFO. Answers: can a Long War strategy screen be built with XCOM 2's
   UI, and does its state live well in XCOM 2's game state.

## Verification

Each experiment ends with what was seen in the game or the editor on
wingpu (a screenshot), what it took, what it would take to do for all of
it, and what stands in the way.

## Report (2026-10-31, the toolchain)

Before experiment 3, the toolchain on its own: a mod (`LongWarX2/`) whose
screen opens on the main menu, built from XCOM 2's UI pieces (a background
box, a panel header, text, a button). Built over ssh on wingpu with
X2ModBuildCommon v1.2.1 (`.scripts/`), loaded by War of the Chosen, seen on
the main menu (screenshot in the conversation). Our UnrealScript compiled
with no errors or warnings the first time it was compiled at all.

What it took, for whoever builds next:
- **Windows PowerShell 5.1** (`powershell.exe`) runs the build, as ModBuddy
  does; under PowerShell 7 a folder becomes its full path where the script
  wants its name.
- **The mod's own package** in `Config/XComEngine.ini` under
  `[UnrealEd.EditorEngine] +ModEditPackages`: without it the SDK's
  `make -mods` compiles nothing of ours and still says "Success".
- **Enabling it for a test**: `ActiveMods="LongWarX2"` under
  `[Engine.XComModOptions]` in `My Games\XCOM2 War of the Chosen\XComGame\Config\XComModOptions.ini`,
  keeping the file's `[IniVersion]`; without it the game regenerates the
  file and the mod is not loaded. Backed up before, restored after.
- **The game over ssh**: started as a scheduled task in the desktop session;
  its menus draw only once its window has focus. `-review -noRedScreens
  -nostartupmovies`. A mod's `` `log `` lines are in `Launch.log`.

Left on the screen: the panel header's title does not draw (only its
stripes); the air war's screen uses a title-font text instead.

## Report (2026-10-31, experiment 3: the air war) — answered: yes

**What was built** (`LongWarX2/`):
- `LWAirWar`: Long War 1.0's interception rules in UnrealScript, ported from
  the Long War Tech Tree's model of `XGInterceptionEngagement` and
  `UIInterceptionEngagement`: every shot of the first 60 seconds rolled
  before anything is shown, then played back with hits landing 0.3 s late,
  Aim (the next two missed shots of the jet's own weapon hit), Dodge (the
  next two hits on the jet miss), Boost (keeping up longer), breaking off;
  stances (−15/0/+15 aim, no Aim when defensive, no Dodge when aggressive),
  armour against penetration, crits, kills' aim and damage, crashed or
  broken up by overkill.
- Its data generated from the Long War Tech Tree's (`scripts/airwar-config.mjs`
  → `Config/XComLWAirWar.ini`): ships, weapons, growth per category, UFOs
  re-armed past categories. Foundry projects and Friendly Skies not yet.
- `XComGameState_LWAirWar`: the campaign's jets in XCOM 2's game state,
  made when a campaign starts (or is first loaded with the mod).
- `UILWInterception`: the screen, from XCOM 2's UI pieces (background, text,
  progress bars, buttons): the jet and the UFO, stance, the odds from 1000
  fights, ENGAGE, AIM / DODGE / BOOST / BREAK OFF during the fight, a log.
  Opened from the geoscape with the campaign's jets and the month's
  category, or from the main menu as a demo.

**Seen on wingpu** (screenshots in the conversation):
- The demo: Interceptor with Avalanche Missiles against a Scout at
  category 4; a fight played out (two hits, the Scout broke up).
- The rules against the Long War Tech Tree's model, same jet, UFO and
  stance (balanced): the game's odds from 1000 fights, down 11 % (broke up
  5 %), jet lost 6 %, keeps up for 7 s; the model's from 20000, 11.8 %
  (5.7 %), 5.3 %, 7.1 s.
- A campaign (a test one, `tools/test/`): the button on the geoscape; the
  campaign's Raven-1; aggressive against a Destroyer, Aim used mid-fight
  (a miss turned into a 33-point hit through 18 armour); the Destroyer got
  away, Raven-1 at 1955 of 2500 HP, recorded. The screen reopened read
  1955 from the game state; saved, exited to the main menu, loaded: 1955.

**What it took**: the rules are about 600 lines and compiled on the
second try (one name clash with `UIPanel.Show`); the screen and state
about 400. The time went into the toolchain and driving the game over ssh
(`tools/test/`), which the next experiments reuse.

**What the whole strategy layer would take**, by this measure: each Long War
system is rules we already have modelled and checked (research, Foundry,
council, funding, the air war), a game-state object, and screens built
from XCOM 2's pieces. The air war is among the harder ones (real-time
playback); most are lists, numbers and choices. What does not exist in XCOM
2 at all is the scaffolding around them: UFOs appearing over countries,
interceptors based on continents, satellites and panic, the base grid. Those
are design choices about how much of XCOM 2's strategy to replace, more
than technical questions.

**What stands in the way**: nothing technical found. Plain screens look
plain: a real one wants the jet's and UFO's pictures and an animated view
of the fight, which is art (Flash movies or our own), not code. XCOM 2 has
no interceptor or EW UFO models of its own (experiment 1's question).

**Left**: experiments 1 (an EW alien into XCOM 2) and 2 (an EW map), which
need the SDK's `full_content` branch.

## Report (2026-10-31, experiment 1: an alien, so far)

**Converted** (`tools/convert/`, run on this machine from the player's EW
install; nothing of the game's in the repository):
- `ew-to-gltf.ts`: an Enemy Within unit as glTF, with the Long War Tech
  Tree's readers: the Floater (`SM_MedFloater`, 87 bones, 3286 vertices,
  4852 triangles), its diffuse and normal textures (2048², from the texture
  cache), and the 154 animations of its rifle set. Checked by rendering:
  the mesh matches the Tech Tree's own skinning; the winding agrees with
  the stored normals once the axis swap is the only flip.
- `gltf-to-fbx.py` (Blender, headless): FBX for the editor, in Unreal's units
  (Blender writes metres, Unreal reads centimetres: scaled by 0.01, seen in
  the editor as a pelvis at 9264 before and 92.6 after).

**In XCOM 2's editor** on wingpu: the FBX imports as a skeletal mesh (88
bones with our Root, 4852 triangles, sizes right), the textures import
(the normal map as TC_Normalmap), and the mesh shows in the AnimSet
editor. XCOM 2's aliens use a material instance of
`Materials.Approved.Alien_SD_SSS` with Diffuse, Masks and Normal
(read from the SDK's uncooked `Sectoid.upk`); an instance of it is made
for the Floater. Saved as a package outside the repository.

**In the way, for now**: this editor on this machine does not render
XCOM 2's character materials: our material shows magenta, and XCOM 2's
own Sectoid shows flat blue. Its renderer is DX10 (SM4; the SDK ships SM4
shader caches only; `AllowD3D11` and `-d3d11` do not change it). In the
first editor session a plain diffuse material did render the Floater
textured; why it stopped is not known yet. The real check is the game,
which renders through DX11.

**Next**: the animations as an AnimSet (EW's skeleton is the Floater's
own, so they import onto it), a pawn archetype, a character template, and
the Floater spawned in a tactical mission in the game.

**Tooling learnt**: the editor is not DPI-aware (wingpu now runs 1920x1080
at 100 %); `am exec` runs in the desktop session, where typing into file
dialogs works; windows are closed by title, never with Alt+F4 (that once
closed the editor with an import unsaved).

## Report (2026-10-31 evening, experiment 1: the Floater in the game) — answered: yes, for the content

**Seen in War of the Chosen** on wingpu: in a tactical mission (the game's
Tactical Quick Launch, a test button on the main menu), Enemy Within's
Floater stands beside the squad, in its own textures (the glowing thruster
eye, the armour), lit by XCOM 2's renderer, at the right size against a
soldier. From the log: `mesh LWX2_Floater.SM_MedFloater loaded`, `material
… loaded`, `shown at …`. Screenshots in the conversation (game art: not in
the repository).

**The way through**: EW package → glTF (`ew-to-gltf.ts`) → FBX (Blender,
`gltf-to-fbx.py`) → the SDK editor's import (mesh, textures, a material) →
saved as a package in the mod's `Content/` (git-ignored) → the mod build
compiles its shader cache → `LWX2EWUnitDisplay` loads it by name at run time.

**Not yet**: the animations. The editor's FBX animation import crashes every
time (an assertion, `InSynchObject`, after "Default Mesh is NULL!
PreviewSkelMeshName: None": it compresses the new sequence against a preview
mesh the new AnimSet does not have). Tried: one FBX with all takes, one per
animation, the mesh import's "Import Animations"; same crash. The Floater
stands in its rest pose.

### Decisions

- **The rest pose first, animations after**: the question was whether EW's
  content can come across and draw; it can. Spending the night on the
  editor's animation import was not the best use of it.
- **Units converted in the glTF step** (lengths / 100), not by a scale on the
  FBX: XCOM 2's importer ignores a skeleton's scale for animations.
- **One animation per FBX**, named after it: the editor names a sequence after
  its file.
- **The package lives in the SDK's `Content/Mods/LongWarX2`** while editing
  and is copied to the mod's `Content/` to build. Neither is in git.
- **A plain diffuse material for now** (the editor's "Create Material" from
  the texture). XCOM 2's alien material (`Alien_SD_SSS` with Diffuse, Masks,
  Normal) wants a Masks texture EW does not have; a later step.
- **Test buttons on the main menu** (test campaign, test tactical) behind a
  config switch; they never ship.

**Next**: animations by another route (candidates: the editor's COLLADA
import; setting the AnimSet's preview mesh before importing, through the
editor's console or a property the viewer exposes; or writing the AnimSet
object ourselves with upkit, since both games' packages are version 845),
then the Floater as a unit (archetype, character template) that moves and
fights.

## Report (2026-10-31 night, experiment 1: EW's own package, animated) — the better way

**Seen in the game**: the Floater in a tactical mission, **animated** (its
idle; two frames 0.7 s apart differ), with Enemy Within's own particle
effects (its thruster flames and jet trail, fired by the animation's
notifies). Mesh and animations come straight from EW's package, not
through the editor. Screenshots in the conversation.

**What XCOM 2 reads of an EW package** (same package version, 845; EW's
licensee version 64, XCOM 2's 120): its SkeletalMesh, its AnimSet (154
sequences), its particle systems: loaded in milliseconds. What it cannot
use: EW's materials (their compiled shaders are EW's); the Floater wears the
material made in the editor (`LWX2_Floater.MedFloater_DIF_Mat`), and one
particle material shows as a checkered square.

**The patch** (`tools/convert/ew-package.ts`, upkit), on the player's
machine:
- decompressed, with the header fixed (see below);
- its texture caches renamed (`CharTextures` → `EWCharTextrs`, `Textures`
  → `EWTextrs`: same lengths, only the name table changes) and the player's
  EW cache files hard-linked into the mod's `Content` under those names (no
  copy: a link on the same disk). Without it, an EW texture is read from
  XCOM 2's own `CharTextures.tfc` and the game stops ("I/O failure").

**A bug found in upkit**: `decompressPackage` zeroes the chunk count but
leaves the chunk entries in the header, so a reader takes the fields after
the table (package source, packages to cook, texture allocations) from them.
XCOM 2 hung on it. Fixed in the converter; to fix in upkit itself (with a
test), since the Long War Tech Tree writes decompressed packages too (EW
read those, so far).

### Decisions

- **EW's packages, patched, over the editor's import**: no SDK needed on a
  player's machine (60 GB, and its animation import crashes), every
  animation as EW made it, and conversion is a small upkit step. The editor
  remains for what EW's packages cannot give: materials XCOM 2 can render.
- **Hard links for the texture caches** rather than copies (0.5 and 1.7 GB).
  A player's EW and XCOM 2 on different disks would need copies; a later
  detail.
- **Our editor-made material on EW's mesh**: until materials are converted
  (next: build an XCOM 2 material from EW's textures automatically, or one
  material in the mod that takes EW's textures as parameters).

**So experiment 1 is answered**: EW's aliens come across, animated, with
their effects, from the player's own install, by a step a mod can run.

## Report (2026-10-31 night, experiment 2: a map's geometry and textures) — seen

**Seen in the game**: Enemy Within's `CSmallScout_Badlands` (the small scout
crash site on the badlands) on XCOM 2's Tactical Quick Launch screen: its
ground, rocks, plateaus, bushes, trees, rubble, the three Skyranger drop
zones and the crashed Small Scout, 1312 of its 1313 placed meshes, where EW
put them, **with EW's own textures** on XCOM 2 materials. Screenshots in the
conversation (game art: not in the repository). Not yet: EW's lighting,
collision, cover, pathing.

**What did not work, and why**
- *The map as a map*: XCOM 2 loads EW's map package but cannot read its
  level ("Bad export index"); the copies of shared packages it carries
  (`FX_Shared` …) also clash with XCOM 2's packages of the same names.
- *The world given no data* (serial size 0): XCOM 2 still reads every object
  of a package it loads ("Serial size mismatch").
- *EW's materials*: XCOM 2 has no shaders for them and the retail game does
  not compile any; the SDK's shader precompiler cannot load the converted
  package at all ("Invalid linker index"). And XCOM 2 reads no material from
  EW's static meshes (their element data differs): the pieces drew XCOM 2's
  checker.
- *EW's textures as they are*: XCOM 2 reads the same mip records but not
  EW's LZO compression: colourful noise.

**What works** (`tools/convert/ew-map.ts`, on the player's machine, then the
mod's `LWX2EWMapPieces`):
- the map package becomes a content package: every object of its world is
  turned into an empty object of a simple class (a `PhysicalMaterial`
  header, 12 bytes of data appended to the file), the carried packages
  renamed (first letter `Q`: `Qush_A_Dry` …);
- every placed static mesh written as config (mesh path, location, rotation,
  scale, and its materials, which EW keeps on the placed component or its
  archetype, not on the mesh); the mod spawns them;
- each material's diffuse and normal maps read (an instance's parameters,
  its parents' for those it leaves, a material's texture expressions; EW's
  ground blends give their main layer); the mod makes an instance of an
  XCOM 2 parent (`Materials.Approved.Props_SD`, `Vegetations_VO`,
  `Alien_Props`, by kind) with them;
- every texture rewritten with its mips uncompressed in the package
  (`tools/convert/inline-textures.ts`; 117 MB for this map), its texture
  cache name cleared: XCOM 2 then needs no EW cache file for the map.

**Driving the screen** took two finds: the screen's debug camera toggle does
nothing in the retail game (it needs the console), and the tactical camera
is an `XComCamera`, not the `XComBaseCamera` the toggle casts to. The mod
holds the camera itself (`LWX2CameraHold`, free-look state, a configured
view). The screen draws the world only once it has generated a map, so the
EW map sits beside it (`Origin`), under its light.

### Decisions

- **Rebuild the map from its pieces, not convert the level**: the level's
  data is what XCOM 2 cannot read; the pieces (meshes, materials, textures)
  are what it can. EW's level-only data (lighting, BSP, volumes, kismet)
  will have to be rebuilt from XCOM 2's.
- **Stand-in materials made at run time from XCOM 2's parents** rather than
  materials converted or made in the editor: no SDK on a player's machine,
  every EW material covered by three parents. Lost: EW's specular and
  emissive maps, its vertex-colour ground blends (one layer shown), its
  decals and glass (13 materials kept as EW's, shown as XCOM 2's checker).
  To improve with more parents and parameters.
- **Textures inline and uncompressed** rather than a new texture cache:
  simplest that works; the package is larger (136 MB). A cache of our own
  (uncompressed or in XCOM 2's compression) is the later, smaller form.
- **The Quick Launch screen for looking**, rather than a mission: it starts
  in a minute and the camera can be held anywhere. Playability needs a
  mission (next).

**Left for experiment 2** then: collision on the pieces, XCOM 2's tile data
(cover, pathing) built over them, a unit walking there; then lighting. Done
in the next report.

## Report (2026-11-01 night, experiment 2: the EW map as a mission's ground) — answered: yes

**Seen in the game**: a Tactical Quick Launch mission (XCOM 2's own mission
and enemies) played on Enemy Within's `CSmallScout_Badlands`: the squad
starts at an EW drop zone beside EW's grounded Skyranger, in cover (XCOM 2's
shields, from EW's rocks), the movement range drawn over EW's ground with
holes around its rocks and plateaus, a soldier moved across it (right
click; the range then turns to the dash range). Logged: each soldier can
reach 429 to 533 tiles, 110 of the 120 tiles around it. Screenshots in the
conversation.

**How** (the mod, behind switches in `Config/XComLWAirWar.ini`; the
converter as before plus the play area, the drop zones and each mesh's
bounds):
- the screen generates one of XCOM 2's maps as usual (it brings the light,
  the mission, the enemies); then `LWX2PartPlacer` hides that map's geometry
  and takes away its collision, places the EW map as `LWX2LevelActor`s
  (XCOM 2's `XComLevelActor`: cover, the building visibility system) with
  EW's play area (its level volume, read from the brush's bounds) centred in
  the generated map's level volume, moves the soldiers' spawn to the first
  EW drop zone (its player starts) inside it, and tells the screen to
  rebuild the tile data when the battle starts;
- XCOM 2 builds its tiles, cover and paths over EW's meshes as over its own.

**What it took**
- The tile data rebuilt *before* units exist: rebuilding it once the
  mission had started crashed the game at the end of the intro.
  `AddActorTileData` alone changed nothing.
- Collision off the backdrop: EW's sky dome has a collision box that holds
  the whole map, and no tile could be entered inside it. The converter reads
  every mesh's bounds; the huge ones are marked `Backdrop` and the mod turns
  their collision and trace blocking off.
- The hidden map's actors still blocked traces through their components:
  each primitive component's trace blocking and collision is turned off.
- A drop zone inside the generated map's volume: units spawn on its floor
  tiles; outside it they were put elsewhere.
- (A false alarm: the soldiers' reach read from script is 1 until XCOM's
  turn has begun; the first measurements were taken during the intro.)

**Not yet** (the next steps of a real map port, none of them a doubt):
- *Lighting*: the generated map's lights and time of day, not EW's (the map
  is dark; EW's lights are in the converted package's world, unread).
- *A host map of our own*: the generated map's level volume is 76 x 52
  tiles here, EW's play area 73 x 74: the rest of EW's map is drawn but not
  playable. A plot of our own (a map with only a level volume, light and a
  spawn, made once in the editor and shipped in the mod) removes the generated
  map entirely.
- *The mission's contents at EW's places*: objectives and enemy pods stand
  where XCOM 2's map had them. EW's map has its own (`XComAlienPod`,
  `XComSpawnPoint`, the UFO's power source …) to read and use.
- *Destructibility*: EW's destructible pieces are placed as plain level
  actors.

### Decisions

- **The EW map placed into an XCOM 2 mission at run time**, rather than
  converted to an XCOM 2 map file: what XCOM 2 needs from a map (tiles,
  cover, paths) it builds itself from geometry, so geometry is enough; no
  editor step, every EW map by the same converter.
- **XCOM 2's generated map as the host for now**, hidden: it gives a
  working mission (light, enemies, objectives) without any authoring. A
  host plot of our own is the next step (above).
- **`XComLevelActor` for the pieces**: XCOM 2's class for level geometry,
  spawnable (not static), so cover and building visibility come with it.
- **Backdrop by size** (half sizes over 24 tiles across or 12 high): simple
  and covers the sky dome and the mountains here; to revisit per map.

**So experiment 2 is answered**: Enemy Within's handmade maps come across as
the ground of XCOM 2 missions, playable, from the player's own install, by
the converter and the mod. With experiments 1 and 3 answered too, the hard
parts are validated.
