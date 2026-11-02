# Working in long-war-x2

## How the person wants work done here

- **Carry on without asking.** Once a direction is agreed (the features/
  files), work through it without stopping for a go-ahead between steps.
  The person, 2026-10-31, before an overnight session: "if you document any
  decisions along the way please keep going ... get as far as you can
  towards the end goal".
- **Log decisions as they are made**, in the feature file being worked on:
  a `### Decisions` list in the day's report, each one line with its reason
  ("Floater shown as a plain actor first, not a unit: proves the content in
  the game before the archetype work"). The person reads these and may
  overrule them; make each easy to undo.
- **Reports** go in the feature file as dated `## Report (YYYY-MM-DD, …)`
  sections: what was done, what was seen (in the game or editor, with
  screenshots taken), what is left, what stands in the way.

## Hard rules

- **Nothing of either game in the repository**: no Enemy Within or XCOM 2
  assets, decompiled code, converted packages or screenshots of game art.
  Converted content lives outside the checkout (`C:\Users\aekms\lwx2-work` on
  the test machine, `/tmp/lwtree-x2conv` here). Hashes and names are fine.
- Our code is MIT (`LICENSE`).

## The test machine: wingpu

- `ssh wingpu` (Windows 11, Intel Arc, display 1920x1080 at 100 %: the SDK
  editor is not DPI-aware). Its Steam games and the SDK were installed for
  this work only: saves, settings and mod lists there need not be kept.
- Anything that shows or clicks runs in the desktop session:
  `tools/test/on.sh '<PowerShell line>' …` (through `am exec`). The tools
  are in `tools/test/` (README there); the game is started with
  `tools/test/start-game.ps1`, the editor with `start-editor.ps1`.
- Build: `pwsh tools\test\build.ps1` on wingpu (X2ModBuildCommon under
  Windows PowerShell 5.1).
- In the editor: close windows by title (`window.ps1 <title> -Close`),
  never Alt+F4; save a package right after changing it.

## XCOM 2 modding: what cost time here

- **Mod config arrays add with `+`** (`+AllowedWeapons=`, `+Pieces=`): plain
  lines replace each other and only the last one stays.
- **UnrealScript**: `State` and `Local` are reserved (not variable names);
  `a && b ? x : y` needs parentheses round the condition; enum values in a
  `?:` do not parse; only `config` variables' defaults can be set at run
  time (`default.X = …`).
- **A screen listener must not keep an actor** (or anything of the current
  world) in a variable: the old world cannot be unloaded and the game stops
  at the next map change. Leave a marker actor in the world instead
  (`LWX2SessionMarker`).
- **XCOM 2's popups take screens above the base view off the stack**: a
  screen of ours pushed back whenever the base view is on top loops. Open
  ours from a button.
- **The Tactical Quick Launch screen** draws the world only once it has
  generated a map; its debug camera toggle does nothing in the retail game
  (`LWX2CameraHold` holds the camera instead).
- **Tile data** (cover, paths) is rebuilt by XCOM 2 from geometry, but only
  before units are positioned: rebuilding it during a mission crashed the
  game. Place geometry while the dropship briefing waits (campaign) or on
  the quick launch screen (`LWX2PartPlacer`).
- **EW content**: XCOM 2 reads EW's meshes, animations and particles as they
  are, but not EW's materials (no shaders) and not EW's texture compression
  (noise): `tools/convert/` rewrites textures uncompressed and the mod makes
  materials from XCOM 2's parents at run time.
- **Driving the game**: right click moves a unit; clicks in the 1600x900
  window are screen pixels (`click-screen.ps1`) or the UI's 1920x1080
  coordinates (`click.ps1`); a soldier's reach read from script is 1 until
  XCOM's turn has begun.
- **Units spawned mid-mission** (`XComAISpawnManager.SpawnPodAtLocation`) get
  no AI unit data: make an `XComGameState_AIUnitData` for each, or the AI
  never moves them (as XCOM 2's reinforcement spawner does).
- **A single-target ability measures its reach by its weapon**: unbound
  (`ApplyToWeaponSlot` unset), every target is "not in range". XCOM 2's psi
  powers use the psi amp; ours are bound to the primary weapon.
- **Long War's numbers follow stock Long War 1.0**, never one player's
  changes. `scripts/config-all.sh` regenerates every config from the stock
  installer's files in the Tree's samples (`samples/Long War Mod Manager
  1.0d-620-1-0d/LongWarFiles/_Long War EW 1.0 for PC-88-1-0.exe/{app}/XComGame`),
  with the full game's packages under them for upkit. `samples/Config` and
  `samples/CookedPCConsole` are the person's **modified** Long War (listed in
  `samples/additional_mods/manual.changes.txt` and `additional_mods/Mods`):
  read code from the stock packages (`upk_script.py <stock>/XComGame.upk …`).
  The Long War installed on wingpu matches stock (PSI_GIFT_CHANCE 0.45).
  EW's code constants (`readConsts`) and its compiled script
  (`xcom-ew-lw-tree/scripts/upk_script.py`) give what the ini does not;
  decompiled output stays in the terminal or /tmp.
- **Test aids for aimed abilities** must gather the area's units
  (`AbilityMultiTargetStyle.GetMultiTargetsForLocation`) before
  `ActivateAbility`, as the targeting UI does; without it only world effects
  apply.
