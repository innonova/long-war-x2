---
title: Comparing the port's look with Enemy Within's, view by view
status: in-progress
priority: 12
dependsOn: [ew-harness]
---

# Comparing the port's look with Enemy Within's

## Purpose

The person's (2026-11-17): a better way to compare the visuals of the two games than eyeballing the port against memories
of EW. The same view captured in both games, put side by side, with the differences found by tools and by a second model,
so the fixes are driven by evidence and the person is not needed on every round.

## Plan

1. **Views:** a catalog of named views. Each says how to reach it in the port (the control port) and in EW (the harness:
   a save loaded, clicks). It starts with the base overview, each room, and EW's strategy screens (research,
   engineering, build facilities, the hangar, the Situation Room, Mission Control and its alerts). Tactical spots on EW's
   maps come once the harness has the keyboard. The base rooms align almost for free: the port looks through EW's own room
   cameras.
2. **Pairs:** one script drives both games to a view and writes a side-by-side image (`logs/compare/<view>.png`), both at
   1600 × 900.
3. **Hints:** per-region differences (both images downscaled, cell by cell: brightness, saturation, edge density, SSIM),
   ranked, with crops. Plus a non-visual inventory: EW materials that fell back to grey or were skipped by the converter.
4. **A reviewer:** a Codex helper (gpt-6-astra) gets each pair, its hints and a short description of the view. It returns a
   ranked list of differences that matter (not fonts or the UI's own differences), which the fixes are worked from.
5. **A gallery** of the pairs (local, never published: game art) for the person to look at when they like.

## Decisions

- **EW's state comes from the person's own saves on wingpu,** synced by Steam:
  - Game 55: 94 saves, 26 October to 1 November 2025, stock Long War 1.0, 29 of them in missions.
  - Game 56: 24 saves, stock Long War 1.0.
  - Game 58: 3 saves, Long War Rebalance, which writes "[LWR v2.06.00]" into a save's description.
- **The image tools** are a Python venv on this machine (`~/.cache/lwx2-compare`: numpy, Pillow, scikit-image) and
  ImageMagick. Nothing is installed on wingpu.
- **Screenshots to OpenAI** through the person's Codex account: fine by the person (2026-11-17). Nothing goes into a
  repository.

## Report (2026-11-17, the tools and the first two rounds)

**The pipeline works end to end** (`tools/compare/README.md`):
- **EW** in the harness, loaded from the person's Game 55 (December 2016, a built base): 20 views by clicks
  (`capture-ew.sh`): the base, the five rooms, research, Gene Lab, build items and facilities, the Foundry, the Repair
  Bay, the OTS, Psi Labs, Officer Billets, the aircraft list, satellites, the grey market, council requests, Mission
  Control. The other saves are held aside on wingpu (`SaveData-held`) while comparing: EW lists every save, and the
  person's 2025 campaign sits far down that list.
- **The port**: 14 views through the control port (`capture-x2.sh`) from a campaign just made.
- **Pairs and hints** (`pairs.sh`, `pair.py`), a local gallery (`logs/compare/index.html`).
- **The reviewer** (Codex, gpt-6-astra, agent `ewreview`): round one, 13 views and about 45 findings; round two, 9 fixed,
  6 partly, 30 open.

**Fixed from the comparisons:**
- **EW's screens at two-thirds of EW's size** (the hub, the hangar's list, the HUD): every EW screen is now drawn 1.5
  times larger and EW's framework told a 1280 × 720 stage, as EW scaled its whole stage. The room menus then needed
  their tabs' anchors taken back into the HUD's units (`UILWEWHub.TabAnchorsToHUD`).
- **Mission Control empty at a campaign's start**: a garbage collection purged the converted package before Flash
  found the movie; every EW screen now holds its movie (`UILWEWScreen.HoldMovie`).
- **The HUD follows EW's rooms** (`UILWEWStrategyHUD`, after EW's `UIStrategyHUD` and its `UIStrategyHUD_FSM_*`): the
  clock, event list (NEXT EVENT) and MISSION CONTROL on the base's view and in Mission Control only; EW's back arrow
  elsewhere (clickable); SCIENTISTS and CURRENT RESEARCH in the lab, ENGINEERS in engineering; EW's resource lines
  (CREDITS/MONTHLY/MELD; engineering's; Build Facilities').
- **The research room's menu** as EW's (Change Research Project while one runs, EW's help lines, the Gene Lab there).
- **The hub coming back** after Mission Control kept Mission Control's camera.

**Ruled out (so it isn't looked at again):**
- The base's "smeared" surfaces are not the diffuse: EW's master trim sheet (`HQ_MasterMaterial_DIFF`) is a normal
  grey diffuse with the panel detail in its colour channels; its alpha is a gloss mask. The rooms' palettes (EW's
  `Colorize A`–`D` on `HQ_Master_*Palette`) only tint, and the material graph that mixes them was stripped in cooking.
- The washed-out look is not the lighting level's choice (Day_Arid, Facility, Cave, NatureNight and none look alike),
  not the world ambient override (`WorldAmbientIntensity` 0 changes nothing), and not the stand-ins' white mask.

**Open, ranked by the reviewer, with what is known:**
1. **Light where EW has none.** With EW's placed lights at zero the lab still renders evenly lit: something fills
   every surface. In EW the rooms' outer shells and most of the base are black, because EW's light is baked into
   lightmaps (`Lighting.tfc`) and nothing reaches them. The same cause makes the cutaway's shells show (the reviewer's
   first item) and the rooms look flat (its third). The faithful fix is EW's lightmaps; first find the fill's source.
2. **EW's 3D screens drawn flat.** EW draws the Situation Room's map on the room's wall screen, the research and build
   panels at a slant in the room, and Mission Control as the 3D Earth. EW's base has `UIDisplay_LevelActor`s for this
   (`UISituationDisplayLevelActor_Right` in its log), as XCOM 2's Avenger has.
3. **Vahlen and Shen** stand in EW's research and engineering close-ups; the staff fill the rooms.
4. **Blank monitors and unlit lamps** (EW's `HQ_ConsoleScreen`, `HQ_CustomScreens`, `HQ_ColorizedLight_*`).
5. Smaller: the grey market's picture cropped; the satellite view's country columns too large; EW's Research Archives
   and Research Credits screens not in the port.

## Notes (2026-11-19, round 6)

- **menu-advanced, menu-secondwave** (round 6 #1): the port's captures were from 2026-11-18 07:59, before EW's menu
  scene; captured again by clicks, both now stand in EW's room (and EW's Advanced Options also reads "Disabled" for the
  first two rows).
- **scr-officers** (round 6 #2): not a difference to fix. Long War's Officer Billets (UIMedals, opened by
  XGBarracksUI.OnChooseMainMenuOption) moves no camera; EW's capture shows the Psi Labs' room only because
  `capture-ew.sh` opens it right after `scr-psilabs`. From the barracks menu the camera is the barracks', as the port has.
- **Round 6, fixed:** the Situation Room's ticker on EW's strip below the map, in EW's small type; the armory scene's
  grapple rope (EW shows it only with its animation) no longer hanging across the Situation Room's view
  (`PeopleSkipMeshes`); the Situation Room's screens with credits and the month's net only, the Grey Market with credits
  only, its title and total EW's; Command1's stray sidewalk tile, hidden in EW (its component's HiddenGame), no longer a
  black block over the hangar's bridge (converter 30); the wall's map behind other 3D screens (EW's map plane with its
  holographic earth; its council video plane and dark overlay, grey slabs over it, left out).
- **Round 6, open:** the soldier list's frame is about 8% narrower than EW's, while the summary's right panels are wider
  than EW's: not one cause. The Genetics Lab's four tanks (features/ew-base-people.md).
- **Round 7, fixed** (2026-11-19 night): room effects off the base's cutaway and out of the armory (emitters' off and
  frozen state, draw distances; effects only in a room's view); monitors with EW's UI panels; the soldier summary
  centred, its borders closed; no ticker in the satellite view; the bare wall as EW's map plane; resource lines in EW's
  colours with its meld symbol; people baked brighter; more of EW's texture tiling. **Open:** the promotion screen's
  right panels (its movie places them 80 units further right; notes in strategy-flow.md); the Genetics Lab's tanks;
  the roster frame's width (EW widens it for its medals column); a soldier item card for engineering's "?".
- **Roster width, settled 2026-11-20 (not a defect):** EW's soldier list sizes each of its compartments to the widest
  row's content (`SoldierListItem`: the name and nickname's text width, the promotion and psi-promotion icons where
  shown, the class text, with `SoldierList` taking the largest per compartment), and the frame follows. EW's capture
  has long nicknamed Master Sergeants with psi icons; the port's test campaign has Lance Corporals without nicknames or
  psi, so the same movie lays itself out narrower. A campaign-content difference, as the reviewer's exclusions have it.
- **The Genetics Lab's tanks, fixed 2026-11-20:** EW's canisters on their conveyor (features/ew-base-people.md); their
  glass's tone and the caps' colour still differ.
- **Grey Market's Sectoid Corpse picture, settled 2026-11-20 (not a defect):** the yellow-suited figure beside the
  Sectoid is in EW's own picture for that item (Long War's table, item 134: EW's `CorpseIcons.Corpse_Sectoid`, from the
  player's converted base); the round had no EW shot of the same item to compare with.
- **Round 8, fixed** (2026-11-20 night): Vahlen's black squares (converter 43: the brightened textures re-encoded); the
  mist fainter (0.2); the ticker in the strip below the map, EW's map plane only on the bare wall; the bare wall map
  brighter; engineering's "?" opens EW's item card for the selected weapon (range, Long War's damage and crit ranges:
  (3D+1)/4 to (5D+2)/4, crit (5D+1)/4 to (7D+2)/4, Damage Roulette's wider), armour (HP bonus) or small item (charges),
  its text and picture (`UILWEWItemCard.FillGear`). Tried and taken back: the custom screens' decal sheet (the whole
  sheet showed; converter 45).
- **Round 9** (2026-11-20 evening): fixed since round 8 by its account: Vahlen's black squares, the promotion screen's
  panels, Build Items' "?"; partly: the Gene Lab's tanks, the people's colours, the mist, the ticker. Its new #1 was
  mine: the people's emissive share had also gone onto EW's animated props (the hangar's craft and pads,
  engineering's robots), pale white; now characters only (`PeopleLitMeshes`). Also done after it: the ticker in EW's
  green (measured: 87 183 106 against EW's 91 183 105); no separate back arrow over hiring and the pending requests
  (their own Cancel, as EW); the tank glass dimmed and greyed toward EW's olive (81 75 40). **Open from round 9:**
  coarse metal and grilles (#2), the Repair Bay hologram (#3), blank or indistinct screens and the globe's halo (#5),
  room exposure and lamp colours (#6), the bare map (#7), the Repair Bay mist (#8), the menu's pale rear openings
  (#10), the research veil and Memorial glasses (#11), the transfer row's chevrons (#14), the main menu's buttons (#15).

