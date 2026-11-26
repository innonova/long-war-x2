---
title: The strategy layer as a player meets it, from a new game through every room and dialog
status: in-progress
priority: 5
dependsOn: [lw-base-view, ew-compare]
---

# The strategy layer as a player meets it

## Purpose

The person's (2026-11-18): the base is now the most broken thing for them. A new game still starts on the Avenger, and
many rooms and dialogs are broken one way or another. Without a working strategy layer they cannot play a campaign and
give deeper feedback; perfecting the maps first would leave little feedback for a long time. So: from creating a game,
through every room, menu, screen and dialog of EW's base, close to EW in look and working, before more map work.

## Plan

1. **A player's walk, scripted** (`tools/compare/walk.sh`): a new game by mouse from the main menu, as a player makes it
   (difficulty, second wave, start screen), then every room, every option of every room's menu, every screen and every
   dialog it opens, and back. Each step captured and logged with what came up (the screen on top, errors in the log).
   The same walk in EW from a fresh EW campaign where EW has the room, for the pairs.
2. **The list:** every step that is broken (wrong screen, nothing happens, stuck, an XCOM 2 screen where EW has its own,
   a dialog without its buttons, the Avenger showing), worst first, in this file. The person's own findings go into it
   too.
3. **The Avenger replaced wholesale** (the person, 2026-11-18: not opened over, replaced):
   - **The root:** XCOM 2's HQ presentation layer (`XComHQPresentationLayer.InitUIScreens` pushes `UIAvengerHUD` and
     `UIFacilityGrid`; every "back to the Avenger" path pops to the facility grid) replaced by ours (ModClassOverride),
     whose root is EW's base hub (or Long War's start screen in a new campaign), and whose way back is the hub.
   - **The world:** the strategy map stays `Avenger_Root` (its name is in XCOM 2's script in several places: the
     difficulty screen, the HQ game, the return from a mission), but the Avenger's own levels are not streamed at all;
     EW's base is the strategy world.
   - **What still needs the Avenger's rooms** (the armory, soldier customization, the memorial) gets EW's rooms, as squad
     select already has EW's hangar.
   - First a test that the presentation layer can be overridden at all.
4. **Fix down the list,** walking again after each batch; a download when a batch is done.
5. **Then the maps' lighting** (the middle way the person chose: EW's lightmaps on interiors and night maps, XCOM 2's
   light on daylight exteriors), shown on two maps first.

## Decisions

- Strategy flow before the maps (the person, 2026-11-18). Mission lightmaps: the middle way, after this.
- No opening Long War's screens over the Avenger by timer (tried, reverted): the Avenger is replaced, not covered.
- The walk compares every screen and dialog with EW's, not only the 20 views of `ew-compare`.

## Report (2026-11-18, the Avenger replaced at the root; the armory in EW's)

- **The root** (`UILWFacilityGrid`, a ModClassOverride of XCOM 2's facility grid): it stays the bottom of XCOM 2's screen
  stack, inert and invisible, and opens Long War's root above it once it is on top: the start screen in a campaign not
  yet begun, else EW's hub. XCOM 2 finds its grid by exact class, so its "back to the base view" pops nothing now and its
  popups that wait for an idle base view never show (logged by the hub as they queue: `XCOM 2 popup queued, not shown`).
  The LONG WAR GEOSCAPE button is gone; Escape on the hub's base view opens the pause menu, as in EW.
- **The world:** EW's base stays in view under every strategy screen; nothing of ours brings the Avenger back except the
  fallback switches (`SquadInHangar`, `ArmoryInBase` off). The Avenger's levels are still loaded, hidden: XCOM 2's
  strategy start waits for them (`XGStrategy`: `MinimumAvengerStreamedInAndVisible`).
- **The armory in EW's armory room** (`ArmoryInBase=true`): XCOM 2's armory screens' menus drawn on EW's own soldier
  panels (`LWX2EWBase.ScreenDisplays`: the screen's display tag, EW's panel and camera), the soldier on EW's pad. What
  had stopped it on 2026-11-17: the panels were placed only when asked for, after XCOM 2's armory had asked for its
  display (now placed with the base), and the pawn waited on the Avenger's placement point (now placed without it).
- **EW's hidden actors left out** of the people (converter 23): EW's armory scene had a MEC suit and its weapons on the
  soldier's pad, which EW shows only during a MEC conversion.
- **Seen on wingpu:** new campaign → after-action → SELECT BASE LOCATION → Begin Game → EW's base; barracks → View
  Soldiers → a soldier → Loadout → back, all in EW's rooms, no Avenger.

## The list (2026-11-18, first walk: game creation and the barracks; worst first)

Captures in `logs/compare/ew/` and `x2/`, pairs in `logs/compare/pairs/` (not committed).

1. **Game creation is XCOM 2's:** its main menu and difficulty screen, where EW has LONG WAR → SELECT LONG WAR
   DIFFICULTY (Normal, Classic, Brutal, Impossible) with SECOND WAVE (EW's 22 options in two columns) and ADVANCED
   OPTIONS (tutorial, Progeny, Slingshot, Ironman, beginner VO) (`menu-*`). **Done for the new-game screens** (see the
   report below); XCOM 2's ADVENT broadcast intro after START GAME is gone (EW's own intro is a Bink 1 film XCOM 2
   cannot play). Still XCOM 2's: the main menu, and the Skyranger briefing "Operation Gatecrasher" ("Wilderness of
   South Africa", over an EW map) for the first mission, and every mission's briefing (EW's dropship screen is in
   EW's UICollection_Dropship_SF).
2. **The soldier screens are XCOM 2's where EW has its own** (list, summary, abilities tree, EW's perk icons and
   Gene Mods from the summary: done, reports below; still to do: the psi tree, Report for Duty's ceremony): the soldier list (EW's: Long War's stats per soldier,
   class counts in the title), the soldier's summary menu (EW: Abilities, Gene Mods, Loadout, Customize, Report for
   Duty, Dismiss, and next/previous soldier buttons), the abilities tree (EW's: Long War's ranks as a vertical list
   beside the soldier; XCOM 2's horizontal panel covers the soldier), Gene Mods.
3. ~~The barracks lack EW's View the Memorial and Hire Soldiers~~: both in (reports below).
4. ~~The resource bar stays over the soldier screens~~: EW's resource panel hidden over the barracks' list, the
   armory, customization and the memorial, the back arrow kept (`UILWEWStrategyHUD.ShowForTop`), as in EW.
6b. ~~**Rookies are XCOM 2's "Rk. … (Rookie)"**~~ (done, below); Long War's classless soldier is a "PFC … (Trooper)" (EW's
   `SoldierClassNames[eSC_None]`), as its memorial shows.
5. **XCOM 2's random looks include its DLC's bare-chested torsos and cargo shorts** (one soldier stood so in the armory;
   the armour itself shows: another stood in hers). EW's soldiers never look so; to decide which of XCOM 2's parts a
   Long War recruit may get.
6. **The barracks have no people;** EW's soldiers stand at the bar, train in the gym. They are the roster's own soldiers,
   placed by EW's HQ units event (`SeqEvent_HQUnits`), not scenery: `Anim_Barracks`' own 15 actors are a hidden cinematic.
6c. ~~**Operation names are XCOM 2's**~~ (done, below) ("Operation Gatecrasher" for the first mission). XCOM 2 draws them from the same two
   word lists EW does (`XGMission.m_aFirstOpName`, `m_aSecondOpName`): EW's words written over them would give EW's
   names.
7. **The start screen stands on black;** EW's (after the first mission) not captured yet.
8. Still to walk: research, engineering and hangar second-level screens and their dialogs (EW's order interceptors and
   transfer captured), the Situation Room's, Mission Control's events and dialogs, the post-mission screens.

## Report (2026-11-18, EW's new-game screens)

- **EW's own screens for game creation:** NEW GAME opens EW's SELECT LONG WAR DIFFICULTY (its DifficultyMenu movie,
  `UILWEWDifficulty`), with ADVANCED OPTIONS (Long War's "Disabled" tutorials, Operation Progeny, Operation Slingshot,
  Ironman with EW's confirmation, Reduce Beginner VO) and SECOND WAVE (EW's GameplayToggles movie, `UILWEWSecondWave`:
  Long War's 31 options in EW's two columns). Long War's words from the player's install (`makeShellWords`: EW's
  sections under the mod's classes, the options' enum keys made numbers). The setup now converts EW's shell and common
  UI packages too (`EWShellUI.upk`, `EWCommonUI.upk`). Captured beside EW's: the same layout, words and buttons.
- **XCOM 2 still starts the campaign:** its new-campaign screen stays under EW's, hidden
  (`UIScreenListener_LWEWShell`); START GAME sets its difficulty, Ironman and second-wave checkboxes and calls its
  confirm. Checked: Save Scum ticked on EW's screen arrived in the campaign (`LWSW_05_SaveScum`).
- **Progeny per campaign:** unticked, it is kept in the campaign's options (`LWX2_EWNoProgeny`; `LWCouncil.ProgenyOn`).
  Slingshot's choice is kept too (`LWX2_EWNoSlingshot`), but Slingshot is not in the port.
- **EW's help bars in the converted shell movies make no buttons** (their container's `add` makes nothing for any item,
  while attaching the same symbol works; the cause is not found). `UILWEWScreen.HelpButton` attaches EW's buttons into
  the bar's containers and lays them out as EW's bar does; their clicks are found by position.
- **Not as EW's:** the background is XCOM 2's shell scene (EW's shows its base, dimmed).

## Report (2026-11-18, hiring soldiers)

- **The port had no way to hire soldiers.** Long War's hiring is in now (`LWHiring`, read from stock Long War's
  `XGHeadQuarters.OrderStaff`, `UpdateHiringOrders`, `XGItemTree.SetSoldierStaffCost`, `BuildStaffTypes`,
  `XGBarracksUI`'s hiring view): §25 a soldier (`SOLDIER_COST`, less country bonus 38, which no Long War country has),
  paid at once; the barracks hold 100 (`BARRACKS_CAPACITY`) counting those on order; they arrive after 9 days (the staff
  table in Long War's code), orders for the same arrival merged, as Long War's rookies (`LWBonusEffects.NewSoldier`),
  and time stops for the news. The constants are in `XComLWStrategy.ini` (`strategy-config.mjs`).
- **EW's Hire Soldiers dialog** (its Hiring movie, `UILWEWHiring`) from the barracks' menu, in EW's place in it: the
  count on EW's spinner (its arrows report -1 and -2), the cost and the room in EW's colours, HIRE and CANCEL.
- **The order in EW's event list** with EW's hiring icon and words ("New Soldiers arrive at XCOM HQ"). The event list
  now writes its events in EW's mixed case, as EW's does ("Advanced Repair"), not in capitals.
- **Checked on wingpu:** three hired by clicks (§75; credits 500 → 425), shown in the event list at 9 days, arrived on
  day 10 at 00:00 (216 hours).
- Not yet: EW's notice when they arrive (`PRES().Notify`), shown as an event-log line.

## Report (2026-11-18, the memorial)

- **EW's memorial** (its Memorial movie, `UILWEWMemorial`; clip `theScreen`, as EW's defaults name it) from the barracks'
  menu (View the Memorial, in EW's place), through EW's `Memorial` camera onto the bar's memorial wall, EW's resource
  panel hidden and its back arrow kept, as EW's UIMemorial does. The fallen are XCOM 2's (`DeadCrew`), each line as EW
  writes it: rank and name (class), kills, missions, last operation, date, cause. EW's words copied from its
  `[UIMemorial]` section.
- **Seen on wingpu:** the soldier lost in the simulated first mission listed ("Operation Gatecrasher", XCOM 2's name for
  it). The date came out in XCOM 2's calendar (2035); it is now converted to Long War's (`LongWarDate`: XCOM 2's clock
  runs with Long War's hours from its own start), not yet seen (no one fell in the next campaign's first mission).

## Report (2026-11-18, EW's soldier list)

- **The barracks' View Soldiers opens Long War's soldier list** (its SoldierList movie, `UILWEWSoldierList`), driven as
  Long War's `UISoldierListBase` / `UISoldierList_Barracks` drive it from `XGBarracksUI.BuildSoldierOption`: each row is
  Long War's name line (`XGStrategySoldier.GetName` type 8, "RANK First 'Nick' Last|HP|Mobility|Will|Aim|Defense|
  experience", which Long War's movie splits into its stat icons), the class in Long War's colour, the status in its
  state's colour with the days left (Long War's statuses: wounded, gravely wounded, psionic training, Genetics Lab,
  augmentation, covert operation, fatigued; `GetStatusString`), the rank's and class's frames and the flag. The title
  carries Long War's tally: available of all, then per class with Long War's class icons. Hover selects, a click opens
  the soldier's armory (XCOM 2's, in EW's armory room). EW's resource panel is hidden over it, as Long War hides it.
- **Long War's own package converted** in the setup (`LongWar.upk`: its class icons and flags), for the tally's icons. It
  was made with the UDK (licensee 0), whose textures lack two fields XCOM's have; XCOM 2 stopped with "Error detected
  attempting load of package: LongWar" until the converter added them (`inline-textures.ts`, `padEnd`).
- **Not as EW's yet:** the rows' class icons are EW's four base classes' (Long War's per-class icons show in Game 55's
  rows; how Long War passes them is not found: its row does `classMC.gotoAndStop(label)` and EW's icon clip has only the
  four); eight nationalities have no flag in EW's icon clip (EW's blank); the flag's medal badge shows a placeholder.

## Report (2026-11-18, EW's soldier summary)

- **A soldier chosen in the list opens EW's soldier summary** (its SoldierSummary movie, `UILWEWSoldierSummary`) on EW's
  soldier summary panel in EW's armory, through EW's camera, the soldier on EW's pad with XCOM 2's idle and gear
  (`UIPawnMgr`, as XCOM 2's armory requests its pawn). EW's panels filled as EW's components fill them: the soldier's
  information (name, status, class, rank, missions, kills), Long War's stats line with the gear's bonus ("5+2",
  "12+1") and experience (350/700), the abilities by name. The menu is Long War's: Abilities (Long War's promotion
  screen), Psi-Abilities for psionic soldiers, Loadout and Customize (XCOM 2's, in EW's armory), Dismiss (greyed while
  wounded, with Long War's question).
- **Seen on wingpu:** list → summary → Loadout (XCOM 2's, in EW's armory) → back to the summary.
- **Previous/next soldier:** EW's two buttons in the HUD's bar under it (and the arrow keys), cycling through the list
  it was opened from.
- **Not yet as EW's:** Gene Mods (the mods a soldier has), Report for Duty, EW's
  icons for Long War's perks (the port's perks wear XCOM 2's), the flag and medal badge beside the name.

## Report (2026-11-18, EW's main menu; EW's perk icons)

- **EW's main menu over XCOM 2's** (`UILWEWMainMenu`, EW's Shell movie, Long War's words from the player's
  `XComUIShell.int`): LONG WAR, CHARACTER POOL (in EW's MULTIPLAYER place: the port has no multiplayer, and the
  soldiers' looks are XCOM 2's), LOAD GAME, OPTIONS, EXIT TO DESKTOP, in EW's order. Seen on wingpu by clicks: LONG WAR
  opens EW's SELECT LONG WAR DIFFICULTY, BACK returns; CHARACTER POOL, LOAD GAME and OPTIONS open XCOM 2's screens and
  Escape returns to EW's menu. EW's logo shows as in EW.
- **The air war demo button is development-only now** (it covered EW's logo in the player's build; EW has none): all
  four test buttons follow `ShowTestCampaign` (off with `--player`) and sit below the logo. The test scripts' "menu up"
  line no longer depends on the button (`LongWarX2: main menu up`, `start-game.ps1`).
- **EW's perk icons for Long War's perks:** `classes-config.mjs` writes each ability's EW icon frame
  (`[LongWarX2.LWPerkIcons]` in `XComLWClasses.ini`, 102 abilities), from the perk it stands for and the Tree's
  `data/perks.json` (Long War's `XComPerkManager.BuildPerkTables`, so Lone Wolf wears EW's "HonorExalt" as in Long War).
  The soldier summary's abilities show them (seen: Squadsight). XCOM 2's mechanics without a Long War perk (its pistol
  shot) are left out of EW's list, which lists perks.
- **Still to do here:** EW's main menu stands over XCOM 2's shell scene, where EW shows its Mission Control room
  behind the logo (EW's base levels in the shell map, through EW's shell camera).

## Report (2026-11-18, EW's promotion tree)

- **The summary's Abilities opens EW's promotion screen** (`UILWEWSoldierPromotion`, EW's SoldierPromotion movie on EW's
  promotion panel in the armory, `UIDisplay_SoldierPromote` through `Armory_UIDisplayCam_Promote`, the soldier on the
  pad), driven as EW's `UISoldierPromotion` drives it: the class's title and icon, a row per rank (Specialist to Master
  Sergeant, Long War's names) with its three perks in EW's icons, the rank to choose now highlighted, later unchosen
  ranks faded, chosen ones plain with the soldier's perk lit; Hidden Trees locks the ranks not reached. Selection by
  mouse (hover) and the arrow keys (EW's rows run right to left), the perk's words with Long War's stat bonus for it.
  A click or Enter: EW's NEW TRAINING dialog in Long War's words (and "Prior Training Required" while an earlier rank
  is unchosen); confirmed, the perk is bought as `LWX2PromotionScreen` buys it (XCOM 2's purchase, Long War's stat bonus).
  Previous/next soldier as in the summary, which follows. Seen on wingpu: Lone Wolf chosen at Lance Corporal by clicks,
  Corporal then the rank to choose, the summary listing Lone Wolf with its EW icon.
- **Found on the way, fixed in the converter (`ew-ui.ts`):** the perk's words stayed EW's placeholder. EW's movie binds
  its text clip's symbol (`VerticalScrollMC`) to its own `VerticalAutoScrollText`; XCOM 2's movies bind a symbol of the
  same name to theirs, and XCOM 2's binding won, so EW's cast to its own class failed. The class renaming of 2026-11-15
  now covers such symbols: each EW symbol of a name XCOM 2 registers gets a name of its own, the same in every converted
  package (they import from one another). XCOM 2's names come from the SDK's uncooked UI packages, read once by
  `tools/convert/x2-ui-symbols-read.ts` into `x2-ui-symbols.ts` (865 names; the game's cooked packages use a compression
  upkit does not read). A symbol that is also an instance name on a timeline (`theScreen`, `imageContainer`, `theClock`)
  is renamed only in the tables and registrations, as code and our paths name the instance. Research, build facilities,
  Mission Control, the soldier list and summary, and the new-game and Second Wave screens checked after it.
- **Not yet:** the psi tree (Psi-Abilities still opens XCOM 2's screen) and MEC promotion; EW's flag and medals in the
  header. While EW's dialog is up the tree's panel hides and the resource panel shows (XCOM 2's dialog over a 3D screen).
- **A risk noted, not seen:** classes renamed in 2026-11-15's change whose names are also instance names (`Debrief`,
  `Inventory`, `PauseMenu`, `ClassIcon` …) have their instance references in code renamed too; screens using those
  (EW's debriefs, inventory) should be checked when they are ported.

## Report (2026-11-18, the summary's Gene Mods and flag)

- **Gene Mods in the soldier summary**, in Long War's place and on its terms (`XGSoldierUI.UpdateMainMenu`: once a
  Genetics Lab is built; not for MECs and SHIVs): EW's Gene Mods screen on that soldier (`UILWEWGeneMods.OpenFor`, no list
  first), the mods ordered as in the lab while the soldier can go into a tank (else shown only, without the confirm
  button); Escape and a confirmed order return to the summary. Seen on wingpu.
- **The summary's flag** shows: its panel goes to EW's flag clip's frame directly (`flagIconMC.gotoAndStop`), which wants
  the underscored label; that clip (XComIcons' larger set) also has Belgium, the Netherlands, Norway, Poland, Scotland
  and Sweden (Indonesia and Iran show EW's unknown flag). Long War's own flag pictures (`LongWar.Flags_Strategy`) were
  tried and dropped: EW's flag clips take only frame labels.
- **Not as Long War:** REPORT FOR DUTY (Long War's word for EW's medals option, shown for officers) plays EW's award
  ceremony, a narrative scene (`XGFacility_Barracks.AwardCeremony`); not ported. The psi tree waits for Long War's psi
  ranks (`features/lw-psi.md`, left open).
- **Open:** an intermittent crash at campaign start while EW's base levels stream in (1 start in 13 today, crash handler
  at "GettingNameData"; the dump kept on wingpu, `XCom-HTPC-NUC-CL469133-2026.11.18-11.26.52-Crash`).

## Report (2026-11-18, rookies' ranks, operation names)

- **Rookies in Long War's words:** XCOM 2's classless soldier (its Rookie class) gets Long War's rank names (PFC, Private
  1st Class, then Long War's ranks) and its class name for it (`m_aSoldierClassNames[eSC_None]`, "Rookie": the list's
  6b had "Trooper", which is not Long War's), written by `lw-words.mjs` with the classes' words.
- **EW's operation names** for every mission the Long War headquarters makes (`LWOpNames`, as `XGMission.GenerateOpName`:
  "Operation" with one of EW's 53 first and 76 second words; the Temple Ship Operation Avenger, the HQ assault Operation
  Ashes and Temples, the meld tutorial council mission its own pair). EW's `[XGMission]` words are copied from the
  player's install (`makeOpNameWords`). Seen on wingpu: the first abduction was "Operation Rotting Crown", both EW's
  words. The briefing that shows it is still XCOM 2's (item 1).

## Report (2026-11-18, the labs on EW's screens)

- **The Psi Labs, Genetics Lab and Cybernetics Lab open on EW's lab screen** (`UILWEWSoldierSlots`, EW's SoldierSlots
  movie, in the lab's room), with Long War's rows and words (`UILWEWPsiLabs`, `UILWEWGeneLab`, `UILWEWCyberneticsLab`, as
  `XGPsiLabsUI`, `XGGeneLabUI`, `XGCyberneticsUI` build them): a row a place ("Current Psionic Training:", "Gene Mod
  Subjects", "Soldiers Being Augmented"), each soldier there with the time left; a psi trainee as "LCPL Christine Kohler
  (Neural Feedback) (47%)" with REMOVE SOLDIER and Long War's CONFIRM REMOVAL (training stopped,
  `XComGameState_LWStrategy.StopPsi`); (EMPTY) with ADD SOLDIER (the Genetics and Cybernetics Labs: on the first free
  place only, as Long War).
- **ADD SOLDIER opens EW's soldier list for the lab** (`UILWEWSoldierList.OpenFor`, EW's `UISoldierList_PsiLabs` and
  the others): no SHIVs or MECs, those the lab cannot take greyed (each lab's rule: `PsiSoldierWhy`, `GeneSoldierWhy`,
  `LWMECs.CanAugment` with the price aside). The soldier chosen: the Psi Labs' powers (the port's power step, until EW's psi
  tree takes it), EW's Gene Mods screen on them, or Long War's augmentation price in a confirmation.
- **Seen on wingpu by clicks:** the three labs' screens; ADD SOLDIER → EW's list over the lab → a soldier → Neural
  Feedback trained → the row as above → REMOVE SOLDIER → CONFIRM → the place free again.
- **Next here:** the psi powers on EW's promotion screen in its psi mode (Long War's psi tree, `GetPerkInTreePsi`), and
  EW's augmentation screen (AugmentSoldier) in place of the confirmation.
- **The reviewer's round on all 29 views** (`logs/compare/review/_summary.md`, not committed) ranks next: the
  satellite view's wall screen and its country columns, the Situation Room's blank wall map, the soldier too large in
  the armory's frame, the OTS's and officers' cameras, Vahlen's untextured look and Shen's absence, blank monitors, the
  Repair Bay's room, and smaller layout overlaps.

## Report (2026-11-18, EW's cameras for the facilities' screens)

- **Each screen through EW's own camera**, read from EW's screens' `m_strCameraTag` defaults and its `LookAtFacility`
  calls: the Officer Training School into the school (`XGOTSUI.Init`: its tile's camera), the Psi Labs into theirs, the
  Genetics Lab through `GeneLab_FacilityCamera`, the Cybernetics Lab through `CyberneticsLab_FacilityCamera`, the Repair
  Bay (EW's MEC inventory) at the Cybernetics Lab's MEC plinth (`CyberneticsLab_UIDisplayCam`). Long War's officer screen
  looks at the barracks, as `XGMedalsUI` does (the reviewer's EW capture of it had kept the previous camera).
- **Facility cameras:** they are in the facility levels, not Command1; `LWX2EWBase.LookAt` now finds them in the level of
  the first facility of their kind and places them with it (`FacilityCameraOf`).
- **EW's cut surfaces out of their way:** the Genetics Lab's camera looks from behind the base's black cut surfaces and
  drew black. They are now hidden while a facility's own camera is used and shown again for the base and room views
  (`ShowCutaway`). Seen on wingpu: the Genetics Lab as in EW's capture, then the base view's black between the rooms back.
- **Not yet:** EW's holographic MEC on the plinth (`XGCyberneticsUI.PutMecOnPlinth`); the Gene Mods screen in the armory
  (EW's `UISoldierGeneMods` uses `Armory_UIDisplayCam_Promote`, the soldier on the pad).

## Report (2026-11-18, the soldier on EW's plinths)

- **The soldier stands on EW's plinths:** EW stands a soldier for its screens on a plinth (`XGStrategySoldier.PlaceOnPlinth`:
  `SkeletalMeshActor`s tagged `ArmorySoldierPlinth`, `GeneLabSoldierPlinth`, `CyberneticsLabMecPlinth`). The converter now
  keeps them (version 24: `Spots`), and the armory's screens stand the soldier on EW's (in `Anim_Armory`, 368 units from
  the summary's camera, where we had put him 250 in front of it): the size and place EW shows (the reviewer's ninth item).
- **Gene Mods in the Genetics Lab, as EW:** the soldier on the lab's plinth, the view put to it as the armory's promotion
  view is to the armory's plinth, with that view's field of view (`LWX2EWBase.LookAtMatched`, EW's
  `UISoldierGeneMods.MatchCameras`). Seen on wingpu beside EW's capture.
- **Fixed on the way:** the Situation Room's live wall showed on other screens' 3D panels (XCOM 2's 3D movie is one picture
  for all its panels): it is hidden while the hub is not on top. A camera test aid, `pov`.
- **Not yet:** EW's X-ray look of the soldier in Gene Mods with the chosen part lit (`ShowXRayView`), its panels in 3D, its
  GO TO GENE LAB button and previous/next soldier.

## Report (2026-11-18, the HUD's stray parts)

- **XCOM 2's navigation help hidden under EW's screens:** its small back and geoscape icons sat over EW's back arrow
  (the reviewer's facilities, engineering and soldier screens); hidden while an EW screen is on top, shown for XCOM 2's
  own (the armory's loadout) (`UILWEWStrategyHUD.ShowNavHelpFor`).
- **The line across the top is gone:** it was the room tabs' bracket in our strategy HUD's instance of EW's HUD movie,
  whose tabs are empty there (the hub's instance has the tabs); it drew alone over every screen. Hidden in that instance;
  the base view keeps the hub's tabs with their bracket.
- Test aids: `ewset abs:<path>` sets a variable from the movie's root.

## Report (2026-11-18, the reviewer's second round; a tile's old level; the barracks crash)

- **The reviewer's second round** (all 29 views captured again): fixed since the morning, by its account, the satellites'
  view, the live Situation Room wall, the soldier's size on the plinth, the small navigation icons and the line across the
  top; partly, the labs, the Repair Bay, Vahlen. Its new top items, and what they turned out to be:
  - **Psi Labs black, Repair Bay rock:** a real bug. When a tile changed (excavated, built, removed), `LWX2EWBase.Refresh`
    placed the new level and left the old one's actors until the next load: the rock stayed over a new facility, a removed
    facility stayed drawn. Each tile's actors are now kept with it (`TileOf`) and taken away when it is placed again. Seen:
    the Psi Labs tile shows the lab as EW's capture does, the OTS tile the school. (The capture had also put the Psi Labs
    on column 4, the shaft: moved.) The Repair Bay's rock beside the plinth is the fresh campaign's unexcavated tiles.
  - **The OTS over the barracks:** its own `ShowBase` kept the barracks' camera; now the school's (EW's `LookAtFacility`).
  - **The Repair Bay's resources:** engineering's lines and engineers, as EW shows them.
- **The intermittent crash at a campaign's start (open):** XCOM 2 crashes as EW's `Static_Barracks` level loads (about 1
  start in 13). Placing the base's fixed rooms in the shell made it happen every time, which gave a test:
  - It is the static meshes: with all of the level's meshes made inert, 3 of 3 starts clean. But no one mesh or small group
    is it: halves of them help (any 50 or so), single packages do not. The dump (read with a Python minidump parser; WinDbg's
    `cdb`, installed on wingpu, could not open it): an access violation reading a vertex position buffer, 709 positions
    (`Barracks_Gym_Border`), at index 0, its data pointer at an unmapped page: data freed or never there, the mesh in hand
    being whichever is being read when it happens. That points to memory corrupted earlier, or a limit crossed.
  - Not the cause: the level's cube texture; the thousands of "invalid NetIndex" errors per run (raising the packages'
    net object counts moved the maximum but not the crash). Those experiments are not kept.
  - Next: the faulting code's caller (`XCom2.exe+0x70eec8`, called from around `+0x7534c4`), to know who reads the positions
    and when they are freed; and whether XCOM 2 keeps a mesh's CPU copy of its vertices only when asked (EW's cooked meshes
    may not ask).

## Report (2026-11-18, Mission Control's list and back arrow; the wall under 2D screens)

- **Mission Control's UPCOMING EVENTS:** its movie's own event list (EW's `UIMissionControl.m_kEventList`, which we had
  hidden), filled by the HUD: up to EW's ten, soonest at the top, growing upward from the bottom right as EW's does (EW's
  default `m_iMaxEventsPerRow` 10, not expanding vertically). The base view keeps its single NEXT EVENT.
- **Mission Control's back arrow:** in its movie's own help bar, as EW's `UpdateButtonHelp` puts it (the HUD's beneath
  was covered by this movie; it is hidden there now); a click returns to the base. EW's hologlobe button beside it leads
  to EW's space view of the earth, which the port does not have.
- **The Situation Room's wall** stays live under 2D screens (soldier list, hiring, building) and is hidden only while
  another screen is drawn in 3D (it had shown on the soldier summary's panel).
- Seen on wingpu: Excavation, Xenobiology and the Council Report listed; the arrow clicked back to the hub.

## Report (2026-11-18, the Situation Room's, research's and hangar's menus and screens)

Each walked against EW's code (decompiled from stock Long War into scratch) and checked by clicks on wingpu; screenshots
in `logs/` (`fin1`, `bonuses`, `pending`, `research`, `research_alert`, `report`, `archives`, `hangar`, `order`,
`transfer`, `shipsummary2`, `shiploadout`).

- **Situation Room menu** in EW's order (`XGSituationRoomUI.UpdateMainMenu`): Launch Satellite, **Bonuses** (EW's
  satellite-bonus dialog: every bonus type held, its sum in its text, then EW's words on satellites), Covert Operations
  (once EXALT is active), **View XCOM Finances** (EW's BaseFinances: gross, craft and facility maintenance, salaries,
  net, from Long War's numbers), Visit the Gray Market, **Pending Requests (n)** (EW's list, EW's statuses; an item
  request opens EW's request screen). The menu's extra "Situation Room" entry is gone (the wall is live behind it).
- **Research room** (`XGResearchUI.UpdateMainMenu`): Start/Change Research Project (greyed with EW's "No new research
  projects" when there are none), **Access Research Archives** (greyed until two techs are done; EW's ScienceLabs: the
  list, then each tech's report: codename, month, Long War's text, what it opened, the credit it earned), Visit the Gene
  Lab, **Review Research Credits** (EW's tech list in its credits mode).
- **The research list** reads as EW's `UIChooseTech`: CHOOSE RESEARCH, Long War's order (`SortTechs`: priority first,
  then by time, autopsies and interrogations last), `-**Priority**` on `IsPriorityTech`'s, FAST/NORMAL/SLOW with days,
  REQUIREMENTS (red where short, EW's "Insufficient …" over the summary; such a tech refused), the credits that cut it,
  BEGIN PROJECT. Long War's two story-objective priorities (Alien Propulsion while the Overseer is to be shot down,
  Xenogenetics while an Outsider is to be captured) are left out: the port has no story objectives to ask.
- **Research done, as EW** (decision, logged here): XCOM 2's popup no longer comes (Long War's techs carry
  `bJumpToLabs`, the flag's only use being to skip that popup); EW's RESEARCH COMPLETE alert opens over Mission Control
  (Assign New Research / Carry On, `XGMissionControlUI` alert 28), the report waits in the labs until read, and after
  Assign New Research the research list follows it.
- **A rule fix:** time stops at the hour XCOM 2's research project completes. Before, Mission Control's scan ran its whole
  stretch first (the Long War clock, then XCOM 2's clock in one step), so research done early in a scan completed only at
  its end and the scientists idled in between.
- **Alerts over Mission Control:** a waiting alert opened over the Geoscape panel in the moment before Mission Control
  came up (so over the base); it now opens over Mission Control.
- **Engineering:** menu in EW's order (Repair Bay, then Augment Soldiers once Alien Biocybernetics is done, as
  `XGEngineeringUI` gates it); Long War's FRAGMENTS line in its HUD.
- **Hangar** (`UIShipList`): AIRCRAFT LIST in EW's words and colours, Long War's Raven/Firestorm icons before callsigns,
  statuses as `GetStatusString`, mixed-case continents; ORDER INTERCEPTORS on EW's own order dialog (`UIHiring_Hangar`:
  initial and monthly cost, hangar capacity, a count); CANCEL ORDER (Long War's refund, one at a time); EW's CONFIRM
  TRANSFER; the list stays under its dialogs; a craft in transit listed at its new home; EW's notices when no hangar has
  room or Long War's ferry restriction holds (`XGStrategyAI.CostAlienSquad`: no transfer or loadout change while a
  retaliation UFO flies).
- **The craft's own screens:** EW's `UIShipSummary` first (callsign, status, kills, weapon and picture, EDIT LOADOUT,
  DISMISS SHIP with EW's confirmation, Long War's RENAME: a pilot from its list of 245), then EW's `UIShipLoadout`
  (CHOOSE LOADOUT, stores counts, EW's ratings from Long War's numbers). Pilots are ranked by kills after each kill, as
  `XGInterception` does (Lt., Capt. 3, Maj. 5, Col. 7, Cmdr. 10).

**Still open from this batch:**
- The hangar's craft in their bays (EW draws the jets and the Skyranger; ours are empty), and the summary's camera on the
  craft (`Hangar_UIDisplayCam_Summary`).
- The craft summary's WEAPON INFO / SHIP INFO item cards.
- The back arrow under the craft summary and loadout (the HUD's help bar reports visible but draws nothing there).
- EW's Situation Room research report also shows the tactical summary card for autopsies (`btxtInfo`); not done.

## Report (2026-11-18 evening, the reviewer's third round)

The reviewer's round 3 (33 pairs, `logs/compare/review/_summary.md`) and what came of it:

- **Back arrows** (its #7): under a second EW screen of the same kind (the craft summary over the aircraft list, the order
  dialog, the satellite view over the Situation Room) the HUD's arrow sat below the screen's edge. The HUD lays its help
  bar out only as its buttons are added (when the kind of screen changes), and an opening EW movie moves the view the bar
  is placed by; the bar is now laid out again as each EW screen opens. Checked on all five views.
- **WEAPON INFO / SHIP INFO** (its #13): EW's item cards (`UIItemCards`, a new `UILWEWItemCard`) for a craft weapon (to
  hit at D/B/A, range, fire rate, damage, armour penetration, its tactical info and picture) and for a craft (Long War's
  text about interceptors or Firestorms), opened from the craft summary's help bar where EW has the two buttons.
- **The Repair Bay** (its #12): on EW's panel in the Cybernetics Lab (`UIDisplay_CyberneticsLab`, as `UIMECInventory`),
  with EW's lines (credits, meld, elerium, alloys) and the engineers, no engineering queue. Facility levels' own panels
  are now placed with their tiles (they had been looked for only in the main level), and the tiles are brought up to date
  before a panel is looked for.
- **Officer Billets** (its #4): EW's code moves no camera for it (`XGBarracksUI` → `UIMedals`), so the room stays; the
  EW capture's school view was left from an earlier visit. EW hides the resource lines there; so do we now.
- **The soldier summary's previous/next buttons** (part of its #15): EW's navigation help pads its containers (left 20,
  right 20, centre 60); ours now does too.
- **Tried, reverted, then done properly (the wall):** see the next report.
- **Tried and reverted:**
  - Hiding the Situation Room's wall under its own screens (Gray Market, Pending Requests, Finances), as EW's room screen
    hides on losing focus. In EW the map stays (a 3D material); ours is drawn by the movie, so the wall went blank. The
    proper fix: hide only the country panels, the panic bar and the objectives there.
  - Placing Anim_Hangar's one static piece (a grounded Skyranger): wrong place and no body texture; EW's visible craft
    are the hangar's matinee-driven ships (`XGFacility_Hangar.SetHangarShipsForKismet`, `SeqEvent_ShipToKismet`).

**Still open from round 3:** the soldier loadout (XCOM 2's, by decision), the craft in the hangar's bays, the front end's
scenes (EW's shell; waits on the crash below), Shen and the dark staff, the Gene Lab's tanks, monitors and globe effects,
surface detail and lighting, the soldier summary's right-hand header width, the Gray Market's second portrait.

## Report (2026-11-18 evening, the campaign-start crash: two hypotheses ruled out)

- **A reproducer kept as a test aid:** `PlaceInShell` (`XComLWEWMaps.ini`, off) places the base's fixed rooms at the main
  menu; with it on, 0 of 3 starts reach the menu, each an access violation right after the rooms are placed.
- **Not collision:** the base's pieces made with rigid-body, actor and trace blocking off before their mesh was set (so no
  PhysX collision is built from their vertices): still 0 of 3.
- **Not dynamic shadows:** the pieces made without shadow casting: still 0 of 3.
- Both changes reverted. Next remains the engine's own code at the faulting address and its caller, to learn who reads
  the positions after they are freed.
- **The wall under the Situation Room's own screens, done:** the countries, the UFO and satellite counters, the objectives
  and the ticker hidden (and kept hidden through the wall's refresh), the map kept; back in full on leaving them.

## Report (2026-11-18 evening, the campaign-start crash found and fixed)

- **What it was:** the engine's runtime collision cooking. Its strings name the faulting function's caller:
  `UStaticMeshComponent::InitComponentRBPhys` ("No Cached Per-Tri StaticMesh Physics Data Found Or Out Of Date (%s) (Owner:
  %s) - Cooking …"); the faulting loop reads a mesh's vertex positions and scales them by the actor's 3D scale for the
  physics engine. The converted EW meshes carry no cooked physics data, so each base piece's was cooked at runtime from
  vertex data that was not always still held: a crash now and then at a campaign's start, every time with the base's rooms
  placed at the main menu.
- **The fix:** EW's base is placed as `LWX2BasePiece`, XCOM 2's spawnable mesh actor with `bDisableAllRigidBody` (and no
  collision) in its component's defaults: no physics representation is ever made, so nothing is cooked. The base needs none
  (the earlier tries turned blocking off at runtime, after the component's physics had been set up as it spawned).
- **Checked:** the reproducer (`PlaceInShell`) from 0 of 3 starts to 3 of 3; ten ordinary campaign starts (below).
- **Unblocked:** EW's main menu scene (the shell's base view), parked because placing the base in the shell crashed.
- Ten ordinary campaign starts in a row reached the base (10 of 10); the base view, Build Facilities and engineering
  look as before.

## Report (2026-11-18 evening, EW's scene behind the main menu)

- EW's main menu shows its own shell map (`XComShell.upk`: a Mission Control room of its own, with the globe and an
  officer at the rail), seen through `XComHeadquartersCamera.StartStrategyShellView`. The setup now converts that map with
  the base (`BaseLevels`), and `LWX2EWBase.ShowShell` places it far below the shell's world (`ShellOffset`) when EW's
  main menu comes up: its pieces (as physics-free base pieces, with EW's baked lighting), its 256 lights and its people;
  the shell's own scene hidden, the base's lighting level beneath for the ambient light, and the camera on the map's first
  camera. The hologlobe takes the same teal earth as the base's (a `LookOverrides` line). Side by side:
  `logs/main_menu_ew_scene.png` (EW left).
- Placing this in the shell is what used to crash every start; with the base's pieces physics-free it starts cleanly.
- **Not yet as EW's:** the framing (EW's view is from further back and left: its shell likely moves the camera by a
  matinee from the map's Kismet), EW's lens flare, and a bright gap at the right where a few pieces are skipped.

## Report (2026-11-18 evening, after a mission: EW's debrief, back to EW's base)

Found by playing a mission through: after it, XCOM 2's whole Avenger sequence still ran (its After Action Report with
the squad on the Avenger's walkway, its loot screen, a soldier-bond alert, "New Objective: Contact the Resistance in the
Blacksite Region" from XCOM 2's story, its rewards recap) and ended in XCOM 2's Commander's Quarters, not EW's base.
Now (checked by a council mission won, `logs/ew_debrief.png`):

- **EW's debrief** (`UILWEWDebrief` on EW's Debrief movie, through EW's Cargo camera, in place of XCOM 2's
  `UIAfterAction`: a ModClassOverride, `UILWAfterAction`, which keeps XCOM 2's own bookkeeping after it):
  - **After Action Report:** the operation's name, a row per soldier (rank and class icons, name, kills, missions, the
    promotion due, Long War's status: Active, Fatigued or Wounded with the days, KIA); SHIVs and MECs in their kind of row.
  - **Artifacts Recovered** (when anything was): each item and how many, with EW's and Long War's pictures. The debrief
    applies Long War's result of the mission itself (its loot, wounds and fatigue; `XComGameState_LWStrategy.Arrived`,
    which the hub would otherwise apply) and shows the stores' difference.
- **XCOM 2's loot screen** keeps its opening of the mission's caches and closes at once, straight into the return to the
  base (`UILWLootRecovered`): no research-unlocked screen, no rewards recap.
- **XCOM 2's story silenced:** its objectives keep running (some of XCOM 2's code asks after them), but their narrative
  triggers are removed at start-up: no "New Objective" alerts, advisor lines or the rooms they opened.
- **No soldier bonds** (Long War has none): XCOM 2's per-mission cohesion set to 0 in config, so no bond alert.
- **The Situation Room's wall** is put just under the hub when it opens (it had stayed over the hub when a popup was on top
  at that moment), so the hub's menu and HUD are there on return.
- **The loading briefing** (XCOM 2's dropship, `UILWDropShipBriefing`): Long War's country as the location (it named the
  XCOM 2 plot's "Wilderness of Eastern U.S." for a mission in Argentina) and Long War's objective; to be checked by eye.

- **EW's council debrief** (the debrief's third view, for abductions, terror, an alien base and council missions): the
  council's words for the result (EW's), the rewards (a soldier, scientists, engineers, credits) and each country's panic
  up or down or its withdrawal, read across Long War's result as the loot is; through the Situation Room's camera
  (`logs/ew_debrief_council.png`).

**Still open here:** the Situation Room's wall is blank behind the council view (EW shows its council there); EW's council missions' own completion texts.

## Report (2026-11-18 night, the hangar's craft and the Skyranger)

- **The hangar's bays as EW's** (`logs/hangar_bays_pair.png`, EW's Game 55 on the left): EW keeps them in a level of its
  own, `Anim_Hangar_LaunchBays`, which the port had not converted. Per bay (four, around the Skyranger's pad) and state, a
  matinee `Base_Bay<n>_<Open|Repair|Closed>` poses the bay's launch pad (a skeletal mesh: the arm, the pad, the bay's doors)
  by a loop and puts the Interceptor or Firestorm where it stands (`XGFacility_Hangar.UpdateHangarBays`,
  `SetHangarShipsForKismet`).
  - **The setup** converts that level with the base; `ew-people.ts` reads each matinee's pad (where it stands, its loop) and
    craft (the group's first key, its loop) as people records with `Bay`, `BayState` and `BayPart` (converter 25).
  - **The mod** (`LWX2EWBase.RefreshBays`, with each `Refresh`): Open for a ready craft (doors up, the pad out with the craft
    on it), Repair for one refuelling, repairing or refitting (the pad back, doors almost shut), Closed for an empty bay;
    placed again when that changes. The meshes are held while the base lives (a Firestorm's had been collected with the
    level's package before one came to a bay).
  - **The bays are Long War's:** each jet keeps its bay (`LWJet.Bay`, `LWHangar.AssignBays`, as `GetAvailableBay`: the
    lowest free bay as a jet arrives, is built or comes back; none while based elsewhere or on its way). A jet lost or sent
    away leaves its bay empty; the others stay where they were. Campaigns from before get their bays at the next hour.
  - **The pads' turn:** the pad's arm runs along its bones' −Y; EW's matinee turns it by its key (yaw 90). Seen in XCOM 2,
    the arm reaches the bay with the key's yaw taken off its own, and that is what the converter writes (measured by the
    pads' bone positions against the craft's places).
  - Checked on wingpu: two Interceptors in bays 1 and 2 of a new campaign, a Firestorm ready in bay 2, a Firestorm under
    repair (bay 2 shut), one sent to Europe (bay 1 shut, bay 2 kept).
- **The Skyranger** stands on its pad (Anim_Hangar's one placed mesh, now placed with the fixed rooms) with its body
  texture: its diffuse is named plain `diff`, which the converter's name test did not take for one.
- **The mission's name** in squad select and the loading briefing (`PendingWords`) is EW's mission title (Mission
  Control's: crash site, landed UFO, abductions, terror, alien base, Temple Ship, the HQ, council) and the country, in
  place of English of ours; compiled, not yet seen on screen.
- **Test aids:** `basehide <text> [show] | <text> yaw|z <add>` (the base's pieces and people by mesh path), `jet <i>
  <status> <hours> [kind]`.

**Still open here:** the craft's weapons on their hardpoints (`XGHangarShip.UpdateWeapon`: EW's jet weapon meshes on the
sockets); the hangar's orange ramp strips draw grey (the light strips); `HQ_RoomBorderFX.Meshes.RoomBorderGlowRing`, a
piece of 17 facility levels, is not found (an EW package the setup does not carry; EW's hover glow around a room).

## Report (2026-11-18 night, glass and lamps)

- **The labs' windows:** EW's base glass kept EW's own material (XCOM 2's translucent parent, `Translucent_SD`, is not
  loaded in the strategy layer, so no stand-in was made) and drew opaque and dark blue over the autopsy and weapons labs'
  windows. In the base it is now left out (`BaseGlass=false`); the lit labs show through as in EW. A translucent material
  of our own would bring back the panes' faint reflections.
- **EW's palette lamps glow:** `HQ_EmissivePallete` and `HQ_Master_EmissiveComboPallet` (the hangar's bay lamps and ramp
  lights, engineering's) are glowing parts now, in their `Colorize A`. The hangar ramps' long orange stripes
  (`HANGAR.StripeTest`, a material with no parameters) are still grey.
- **Test aid:** `basenear <radius>`: the base's pieces and people near the camera, with their materials.

## Report (2026-11-18 night, the craft summary's view)

- **The craft summary shows the craft as EW does** (`XGFacility_Hangar.SetupWeaponView`; the reviewer's round 4, #2):
  every bay's craft away, bay 1's pad open with the chosen craft on it in the pose of bay 1's `ViewWeapons` matinee,
  through that matinee's camera (`Hangar_Bay1_ViewWeapons`: its place in its base's frame, its field of view 55 from the
  camera's float track). The converter writes the matinee's camera into the level's cameras and its pad and craft as bay
  records of the state `ViewWeapons`; `LWX2EWBase.ViewCraft` shows it, `LookAt` finds cameras of the people's levels too.
  Back in the aircraft list, the bays are as they were. Seen side by side with EW's (`logs/compare/pairs/scr-shiploadout.png`).
- **Lamps:** the combined palette lamps (`HQ_Master_EmissiveComboPallet`: housing and light in one material, the light
  picked out by something cooked away) are lit surfaces again; glowing whole, the lamp over bay 1 was a solid orange block
  in the craft view. The pure emissive palette lamps still glow.
- **Still open:** the craft's weapon under its wing (EW's jet weapon meshes are in `StrategyResources_SF`, a package of
  EW's whole strategy content that XCOM 2 cannot load as it is: the six meshes would need a package of their own); the
  pad lit brighter than EW's.

## Report (2026-11-18 late, a glass material of our own)

- **`LWX2Lightmap.M_EWGlass`**, made in the SDK editor beside `M_EWLightmapped`: unlit, translucent, two-sided, a `Tint`
  (emissive) and an `Opacity`. EW's base's glass gets it where XCOM 2's translucent parent is not loaded (the strategy
  layer): `GlassOwnParent`, `GlassTint` (a pale blue-grey), `GlassOwnOpacity` 0.12 in `XComLWEWMaps.ini`. The labs'
  windows and guard rails are faint panes again, with the lit autopsy and weapons labs behind (`BaseGlass` back on).
- **Editor session notes** (as the learnings have them): the mod's lines stripped from the SDK's `Manifest.txt` and the
  mod's SDK folder moved aside for the session, both restored after; the package saved from the Content Browser, the
  editor closed by its process once saved.

## Report (2026-11-18 late, screens and light cards)

- **EW's custom screens glow in their hue** (`HQ_CustomScreens`: the Genetics Lab's wall monitors among them): glowing
  parts now, their HDR `TintColor` scaled to a brightest channel of 1, since the picture they tint is cooked away (whole,
  they drew white). Seen on the Genetics Lab: the wall monitor blue, the hanging one amber, as EW's.
- **EW's light cards** (`HQ_ColorizedLight_PureVertexColor`, coloured and faded by the mesh's vertex colours: the Genetics
  Lab's yellow tank glow): a material of ours made in the SDK editor, `LWX2Lightmap.M_EWLightCard` (additive, unlit,
  two-sided, vertex colour × alpha × `Tint`), given to them (`LightCardParent`). **Not seen working:** the tanks stay dark
  even at 8× (`LightCardScale`). The mesh does carry vertex colours in EW (yellow, alpha 0/255 per card); whether XCOM 2
  reads them from EW's mesh is the next thing to check.
- **The resource lines** hide over the research list, the archives and reports, the Gene Lab and gene mods, as EW's
  science HUD hides them for each of its views but the room's menu (`UIStrategyHUD_FSM_Science.GoToView`,
  `UISoldierGeneMods`); back in the room they show again (the reviewer's round 4, #14, in part: EW's code hides nothing
  over the Situation Room's screens or the Gray Market).
- **The Situation Room's wall is bare everywhere but in the room** (its satellite view included): from the base's view,
  Mission Control and the barracks it shows the map alone, its side panels dark, as EW's (the reviewer's round 4, #11:
  the country columns at Mission Control's edge are gone).
- **Looked at and left:** the Gray Market's Sectoid Corpse shows EW's own picture for it, by Long War's table (two figures
  in one picture; not a mix-up of ours). Pending Requests' map ends above EW's (black below): our wall's map is the room
  movie's clip, shorter than EW's 3D map material; the soldier summary's right-hand panels are as wide as their content
  ("MASTER SERGEANT"), as EW's ResizeContents makes them, their right-hand outline not closing (art detail, open).

## Report (2026-11-19, from the reviewer's round 5)

- **The satellites' counters** (AVAILABLE / IN ORBIT) only in the satellite view, as EW's `UISituationRoom.GoToView`
  shows them for that view and hides them for the room's main view; they had sat over the room's menu (round 5, #9).
- **Mission Control without the resource lines:** EW's Mission Control hides the whole strategy HUD
  (`UIMissionControl.GoToView`); ours hides the resource lines (the HUD carries our back arrow there) (round 5, #12, in part).
- Still from round 5: the room's objectives panel and ticker in the Situation Room's main view (EW shows them there).

## Notes (2026-11-19, the soldier summary's right-hand panels)

The reviewer's "open right borders": the panels run off the screen's right edge. The summary is on EW's 3D panel
(`UIDisplay_SoldierSummary`, EW's own mesh at EW's scale, through EW's camera; the soldier is EW's size), but the movie on
it is spread about 1/0.878 wider than EW's (the options list further left, the header's right edge, its origin, past the
screen). The 3D movie's stage is 1920 x 1080, exact fit; nothing in the movie lays out by stage width. EW's 3D display
material has a `UVAdjust` parameter (`UIDisplayMovie.ScaleUVs`; no screen calls it), so the difference is likely its
default in `HQ_UI.Materials.UIDisplayMaterial`, which the summary's panel uses (no instance of its own) and the port
replaces with XCOM 2's. Read since (it is in EW's XComStrategyGame.upk): `UVAdjust` defaults to (1, 1), so not that. What
remains is how EW's 3D movie maps its 1280 x 720 stage onto its render target (EW sets SetViewScaleMode(2) on it,
`UIDisplayMovie.InitMovie`) against XCOM 2's 1920 x 1080 exact fit. Open.

## Report (2026-11-19, the main menu's framing)

- **EW's main menu camera is posed by its matinee**, not where its camera actor stands: XComShell's LeftShoulder moves
  CameraActor_0 by separate axes (`InterpTrackMoveAxis`) to (2389.5, 812.8, -1626.9), yaw -72.1°, pitch 8.7°, roll 3.9°
  (the actor stands at yaw -62.4°). The converter now reads such matinees and writes a camera where its matinee leaves it
  (`ew-people.ts matineeAxisPoses`, converter 29). The main menu now frames as EW's: the globe right of centre, the
  monitors on the left (`logs/compare/x2/menu-main.png` beside EW's); its globe turns once in 200 seconds, westward, as EW's matinee turns it (`ShellGlobeSeconds`). `ShellCamera` (`XComLWEWMaps.ini`, 0) picks the
  shell's camera. Still: EW's glow and lens flare on the globe.

## Report (2026-11-20, the soldier summary's right-hand borders)

- **Found and fixed:** the summary's movie came up with its root at x 993.65 of the 1920 stage (at 150%, 1909 wide),
  so its right edge reached 1947: the right-hand panels' closing borders were past the stage, cut off. Centred on the
  stage (`UILWEWSoldierSummary.Centre`), every border closes and the layout matches EW's capture. The earlier note's
  "spread 1/0.878" was this shift.
- **The promotion screen** (it inherits the centring) still runs off on the right: its movie places the soldier's
  panels about 80 units further right than the summary's (`soldierInfoMC._x` 694 against 612.75, `soldierStatsMC._x`
  875 against 795), where EW's capture shows them in the summary's place. EW's promote camera and panel both hang on a
  rig (`UICameraRig_SoldierPromote`), the camera 133 to the side of the panel's centre (the summary's 13): EW looks at
  that panel from aside, which may be what keeps its panels in view. `sumvar <path> [value]` reads and sets the
  summary's or promotion's movie variables. **Done:** the promotion's root 35 left of the stage's centre and its two
  soldier panels at the summary's places (`UILWEWSoldierPromotion.Centre`), measured against EW's capture: the tree, the
  header and the stats now stand where EW's do, every border closed.


## Notes (2026-11-22, the campaign's first mission and the base's place)

- **EW's order** (`XGStrategyAI.CreateFirstMission`, without the tutorial): the base's place is chosen first, then the first
  mission is an abduction (`XGMission_Abduction`) in a random city of the base's continent, its squad
  `DetermineFirstMissionSquad`, its timer `ABDUCTION_TIMER`.
- **The port's order:** XCOM 2's new campaign launches its first mission straight from the strategy map's start
  (`XGStrategy`, `Initing`), played on an EW abduction map (`FirstMissionOnEWMap`); Long War's start screen (SELECT BASE
  LOCATION) comes after it. So the first mission's briefing can name no country, and its location stays XCOM 2's region
  text. Since 2026-11-22 it has an EW operation name.
- **To make it EW's:** hold XCOM 2's launch (its wait on the movie in `Initing` is the place: `LWX2FirstMissionStart`
  already ends it) until Long War's start screen has chosen the base, then make the first mission an abduction in that
  continent (city, country, briefing in Long War's words). Not started.

## Report (2026-11-25, Customize zoomed out, squad select's soldiers small)

aek, 2026-11-25: "the soldiers on the squad setup screen are oddly small" (logs/squad.png), "and customize is zoomed way
out" (logs/customize.png).

- **Customize:** XCOM 2's customize screens move the view themselves, to a camera by their own name
  (`UIBlueprint_CustomizeMenu`, UIUtilities.DisplayUI3D; XComCamState_HQ_BaseRoomView.GetViewFromCameraName looks it up
  by tag). EW's base has no camera of that name, so the lookup fell through to the last camera found, with XCOM 2's
  default field of view, 90 where EW's armory cameras have 50. EW's cameras for the armory screens (ScreenDisplays) now
  also stand under XCOM 2's names (LWX2EWBase.ScreenCameras), so Customize looks through EW's customize camera: the
  soldier large, XCOM 2's menu readable on EW's panel (logs/compare/customize-fixed.png). The soldier-and-rooms
  journey opens Customize and checks the view's field of view (50).
- **Squad select:** the soldiers stood 600 units in front of EW's AwayTeam camera, 80 apart: a small huddle in the middle
  over the cards. Now 380 in front, and each soldier stands over their own card: the spacing is the cards' pitch on
  the screen at that distance through the camera's field of view (scaled with the cards when a big squad shrinks them;
  `SquadSpacing=0`) (logs/compare/squad-fixed.png).
- **Not yet:** XCOM 2's head customization has its own close camera on the face (`UIBlueprint_CustomizeHead`); here it
  takes EW's customize view, which shows the whole soldier.
- **Head customization** (later the same day): nearer the face, EW's panel still in view (`ScreenCameraShifts`, tuned with
  the control port's `screencam` aid). Explained since: the soldiers "without armour" (vest, bare arms, shorts) wear XCOM 2's own Anarchy's Children parts
  (DLC_30_SldCnv: torso, arms, legs), which XCOM 2's generator gives recruits when that pack is installed; the summary
  and Customize show the same parts (four soldiers compared; `parts` aid), and the crew manager's underlay flag is off.
  Not the port's. Still not traced: a
  portrait of XCOM 2's Central appeared top right while customizing (an XCOM 2 narrative line, not yet traced).

## Report (2026-11-26, Customize and XCOM 2's voices at the base)

- **Customize showed XCOM 2's character pool menu** (Change Soldier Type, Can Appear as VIP / Dark VIP, Created at):
  XCOM 2 takes it for its armory only with its own armory screen on the stack (UICustomize.InitScreen: bInArmory), and
  EW's soldier summary replaces that screen. A listener (UIScreenListener_LWX2CustomizeInArmory) tells it it is in the
  armory and rebuilds its menu: Character Info, Head, Body, Weapon, Save to Character Pool. The soldier-and-rooms journey
  checks for "Save to Character Pool" and against "Can Appear as VIP".
- **Two back arrows over Customize**, EW's and XCOM 2's: EW's corner arrow is hidden over it, as over the armory and squad
  select (UILWEWStrategyHUD.bNavHelpShown).
- **Central over Customize** (aek, 2026-11-25) reproduced: XCOM 2's base ambient lines (S_Ambient_Burger_Contraband_Central,
  Avenger_Ambient_Quick10/11_Central) start on the timers of its base's ambient voice manager (XGBaseAmbientVOMgr: Central's,
  Shen's and Tygan's musings, the radio, the facilities' callouts), about 20 s into a screen. Those timers are now cleared
  while EW's base runs (LWX2EWBase.SilenceNarrative, each quarter second); any other conversation XCOM 2's narrative
  manager starts at headquarters is stopped and logged (UIScreenListener_LWX2NoHQNarrative.StopAll). Checked: a minute in
  Customize on a new campaign, no line, nothing to stop.
- **Open:** straight from EW's soldier summary, Customize's own navigation (its back button and the previous/next soldier
  buttons, on XCOM 2's HUD's helpBarMC) is not drawn, though the help and every clip above it report visible; reached
  after XCOM 2's loadout it is drawn. Esc and the right click still leave it. EW's HUD has a help bar of the same name; the
  lead is EW's layout classes taking XCOM 2's help bar over on that path.
