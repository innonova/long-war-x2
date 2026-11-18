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
2. **The soldier screens are XCOM 2's where EW has its own** (list and summary: done, reports below; still to do: the
   abilities tree, Gene Mods, Report for Duty, EW's icons for Long War's perks): the soldier list (EW's: Long War's stats per soldier,
   class counts in the title), the soldier's summary menu (EW: Abilities, Gene Mods, Loadout, Customize, Report for
   Duty, Dismiss, and next/previous soldier buttons), the abilities tree (EW's: Long War's ranks as a vertical list
   beside the soldier; XCOM 2's horizontal panel covers the soldier), Gene Mods.
3. ~~The barracks lack EW's View the Memorial and Hire Soldiers~~: both in (reports below).
4. ~~The resource bar stays over the soldier screens~~: EW's resource panel hidden over the barracks' list, the
   armory, customization and the memorial, the back arrow kept (`UILWEWStrategyHUD.ShowForTop`), as in EW.
6b. **Rookies are XCOM 2's "Rk. … (Rookie)"**; Long War's classless soldier is a "PFC … (Trooper)" (EW's
   `SoldierClassNames[eSC_None]`), as its memorial shows.
5. **XCOM 2's random looks include its DLC's bare-chested torsos and cargo shorts** (one soldier stood so in the armory;
   the armour itself shows: another stood in hers). EW's soldiers never look so; to decide which of XCOM 2's parts a
   Long War recruit may get.
6. **The barracks have no people;** EW's soldiers stand at the bar, train in the gym. They are the roster's own soldiers,
   placed by EW's HQ units event (`SeqEvent_HQUnits`), not scenery: `Anim_Barracks`' own 15 actors are a hidden cinematic.
6c. **Operation names are XCOM 2's** ("Operation Gatecrasher" for the first mission). XCOM 2 draws them from the same two
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
