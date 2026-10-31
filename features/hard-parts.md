---
title: "The hard parts first: Enemy Within's content, one of its maps, and one Long War strategy system, each in XCOM 2"
status: in-progress
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
