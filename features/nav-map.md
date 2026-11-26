---
title: A map of the base's navigation, EW's against the port's
status: in-progress
priority: 1
dependsOn: [e2e-tests]
---

## Why

aek, 2026-11-25: "i also noticed that there seemed to be no way to actually build a facility" (EW's chooser builds from
its help bar's Begin Construction, which the port's lacked), and: "are you able to and would it be worth building a
complete map of base navigation based on what interactive elements there are and verifying that between the two games
perhaps". The click journeys check what was thought of; a map of every screen's elements, compared with EW's, finds
what is missing.

## What

- **The port's map:** every room, its menu entries, the screen each opens, and on each screen the elements a player can
  use (its labels and buttons, read by OCR), the way in and every way out (corner arrow, Esc, right click). Walked by
  clicks (tools/test/e2e-explore.sh, one level deeper than now), written as data (logs/nav/port.json, not committed:
  it holds EW's words).
- **EW's map:** the same walk in the EW harness (tools/ew-test) on the person's saves, read the same way
  (logs/nav/ew.json).
- **EW's code as a cross-check:** the buttons EW's screens put on their help bars (each UI class's UpdateButtonHelp and
  the like, read from XComStrategyGame), which a walk can miss (a button shown only in some states).
- **The comparison:** per screen, EW against the port: entries or buttons missing, extra or labelled differently; screens
  that open from somewhere else; dead ends. Fixed down the list. The port's walk then stays as a regression check.

## Plan

1. EW's help bars from its code (below), checked against the port by hand now.
2. The port's walk extended: per screen its OCR'd elements, written as JSON.
3. EW's walk with the same reader, on the person's Game 55 base (saves copied in from "My Games - Copy").
4. A comparison script and its table; the differences fixed or explained, here.

## EW's help bars, from its code (2026-11-25)

Read with xcom-ew-lw-tree/scripts/upk_script.py over Long War's XComStrategyGame.upk (every function adding a help-bar
button). Against the port:

| EW's screen | EW's help-bar buttons | The port |
|---|---|---|
| UIChooseFacility | Cancel; Begin Construction (right) | **was missing** Begin Construction: added 2026-11-25 |
| UIGreyMarket | the sale's Confirm (centre) | to check |
| UIHiring | Cancel; Confirm (right) | HIRE and CANCEL in the dialog |
| UIMissionControl | the hologlobe toggle | left out on purpose (no space Earth; ew-compare.md) |
| UIShipSummary | Weapon Info; Ship Info | in |
| UISoldierSummary, UISoldierPromotion, UISoldierLoadout | previous and next soldier (centre) | summary: in; promotion: to check; loadout is XCOM 2's |
| UISoldierGeneMods | previous and next soldier; the gene mod hotlink or Confirm (right) | to check |
| UISquadSelect | back to the briefing; strip gear; Launch | XCOM 2's own squad select |
| UIStrategyHUD | back; zoom and move camera (the base view) | back: in; zoom: to check |
| UIStrategyComponent_EventList | the event list's hotlink (right) | to check |

## Report (2026-11-25)

- **Begin Construction:** EW's chooser has it on the help bar (UIChooseFacility.UpdateButtonHelp: Cancel left, Begin
  Construction right, XGManufacturingUI's label); the port's chooser had no button, and only a second click on the chosen
  facility built it. Now the help bar has it, a click on a facility builds it, and the mouse over a facility selects it,
  as EW's list does (its OnMouseEvent: mouse-in selects; a click selects and builds). The base-building journey builds by
  the button.

## Report (2026-11-25, the first comparison)

Built: `tools/test/nav-walk.sh <port|ew> [room …]` (each room's menu read by OCR, every entry clicked, the screen read,
photographed and left; the scripts take EW's window when XCOM 2 is not running), `tools/test/nav-compare.mjs` (per room
and screen, the labels in one game and not the other, the HUD's own and OCR's variants dropped) and
`tools/test/mirror-ew-save.sh <save>` (a port campaign brought to an EW save's base and research, so both are walked at
the same state). EW walked on the person's Game 55 base (save1753, December 2016), the port on a campaign mirrored from
it; the table is logs/nav/compare.md (not committed: the games' words).

Every menu entry of every room opens the matching screen in the port, and every way back worked. Differences found and
fixed:

- **The cash flow statement** (View XCOM Finances): EW lists every kind of facility in its own order (XGFinanceUI.
  BuildFacilityUI: 0 to 23, the starting rooms at §0), writes costs negative ("-§420", the titles too), and its salaries'
  section is empty (BuildSalaryUI); the port listed only paid kinds in another order, positive, and a "Staff Salaries §0"
  line. Now as EW's (logs/compare/finances-fixed.png).
- **Money** everywhere as EW's ConvertCashToString writes it in English: the sign before the §, thousands with commas
  ("+§1,006"); the port wrote "§-1006".
- **The rooms' menus** opened with the first entry selected and its help shown; EW's submenu selects nothing until the
  mouse comes over an entry or a key moves (UIStrategyHUD_FacilitySubMenu.RealizeSelected only from those). Now as EW's.
- **Build Facilities' tiles** named in capitals; EW writes the facilities' names as they are (XGBuildUI.
  BuildFacilityTile). Now as EW's.

Seen and explained by the two campaigns' states (not the port): the research menu's Change/Start and Review Research
Credits (EW's save has a project and credits), the barracks' Officer Promotions (promotions due), the OTS's officer
projects (EW's soldiers are Master Sergeants), the Bonuses held (EW's 16 satellites), the gray market's stock.

Next: the walk one level deeper (each screen's own buttons and lists, without buying or launching), and the comparison
kept as a check after changes to the base's screens.

## Report (2026-11-25, the early-campaign comparison)

The first comparison was on a late-game save, and most of its differences came from the two campaigns' states. This one
is EW on the person's Game 56 at 1 March 2016 (save1755, just after the first mission) and a fresh port campaign. The walk
now starts each room from the base's view (EW's had drifted: Engineering read no entries, Barracks Engineering's).
Found and fixed:

- **EW's attention markers** ("!" on a room tab or on Mission Control: a new game, research done, a council mission;
  cleared by entering the room; XGFacility.m_bRequiresAttention): the port had none. Now in Long War's state (Attention).
- **The Situation Room's wall stayed black** in the room's view from a campaign's start until something showed its panels
  again; now shown on entering the room (its 4 panels were found hidden; the cause of their hiding not found yet, logged).
- **The year:** Long War's campaigns begin on 1 March 2016 (the person's saves), the port said 2015.
- **The gray market:** EW's "In Storage" / "Sell" / "Complete Transaction"; elerium and alloys named as EW names them
  ("Elerium", not XCOM 2's "Elerium Crystals").
- **The build screen:** EW's "BUILD ITEMS", "ITEM / BUILT", and "Cost:" with each requirement on its line in its colour
  (red when short), no time line; the port had "BUILD WEAPONS", "HELD", "BUILD COST: §0, 1 Shotgun / TIME: …".

Found and written up, not done: **the Motion Tracker** is missing from the port (EW's build list has it at the start;
lw-gear.md).

Still different, explained: the research menu's Change (EW's save has a project running), the memorial (the port's first
mission lost a soldier), the soldiers' ranks (development builds promote the starting rookies, a test switch; the release keeps them PFCs as EW).

## Report (2026-11-26, from the hangar's list)

- **Four interceptors at the start, not two:** Long War grants four (XGFacility_Engineering.GrantInitialStores:
  eItem_Interceptor x 4, +2 more with one start bonus, which the port had); the port gave two. EW's list on the person's
  Game 56 at 1 March 2016 has RAVEN-1 to RAVEN-4. Now four.
- **The craft's names as EW's:** RAVEN-<n> (XGFacility_Hangar's m_strCallsignInterceptor, its own counter); a Firestorm
  takes the callsign and kills of the interceptor with the most kills, which gets a new RAVEN-<n> and none (AddFirestorm:
  the pilot moves up), DEMON-<n> when there is no interceptor. The port had "Raven-<n>" and "Firestorm-<n>".

## Report (2026-11-26, the next level)

`tools/test/nav-deep.sh <port|ew>` walks the screens behind the rooms' screens (a soldier's summary and abilities, a
craft's summary and loadout, a country on Launch Satellite, the research list, a tile's facility list) the same way in
both games; nav-compare.mjs sets them side by side. On the person's Game 56 at 1 March 2016 against a fresh port campaign:

- **The facility chooser** differed most: EW lists "Required to Build: 4 Power, 10 Scientists, §200" (each in its colour,
  red when short: XGFacility_Engineering.GetFacilityCostSummary) and each facility's description (FacilityTypeSummary),
  in EW's order, with BACK and BEGIN CONSTRUCTION in its panel. Now as EW's (logs/compare/facility-chooser.png). Still
  missing: EW's holographic blueprint of the facility over the room (XComHQHUD.ShowFacilityTexture: Command1's
  ChooseFacilities.Materials.M_<facility>, a texture channel each of Facility_1..9 in a material of its own).
- **The research list** showed Alien Computers, which EW does not list until a UFO Flight Computer has ever been held
  (Long War's EverHad: the port only asked for it on techs that cost no items). Now listed as Long War lists it.
- **The craft loadout** lacks the weapon's description under its numbers (EW: "Stingray Missiles are small, fast
  air-to-air missiles…"), and selects the craft's own weapon where EW selects the first; open.
- Explained by the campaigns: names, ranks (development builds promote the starting rookies), the research in progress.

## Report (2026-11-26, the next level, continued)

From the pairs' pictures and EW's code (development build; built and checked on wingpu where marked):

- **The craft loadout** now selects the first weapon and shows its description, as EW's (92266f5).
- **Launch Satellite:** EW writes "+" before the funding of a country *without* a satellite (XGSituationRoomUI.BuildSitCountry:
  `if (!HasSatelliteCoverage) "+"`); the port wrote it on the countries with one, and the movie, which lights a row's
  satellite icon by it, lit the icons the wrong way round too. The chosen country's lines are in EW's colours
  (XGSatelliteSitRoomUI.UpdateCountry, UpdateCountryHelp; UIUtilities.GetHTMLColoredText's states): the funding green when
  a launch can be made, pale otherwise, grey for a country that has left; why not in red ("Build More Uplinks."), "HAS
  SATELLITE" grey. The staff bonus ends with EW's "per month" (BuildBonusString).
- **The research list's time** is coloured whole ("SLOW (18 days)" red), as EW adds the days to GetProgressText's
  coloured text in BuildTechSummary; the port had coloured the word only.
- **The soldier summary's sixth stat** is Long War's damage reduction from gear, "0.0" (XGSoldierUI.UpdateHeader: its
  txtStrength, aModifiers[4] in tenths); the port left it empty.
- **EW's facility blueprints** (XComHQHUD.DrawHUD): the chosen facility's blueprint across the top of the screen in EW's
  gridded frame (the frame 80% of the screen wide and 55% high, 20 down; the blueprint 70% by 57.5%). EW keeps them two
  to a texture (Facility_1..9, channel_test), each facility's material taking the green channel or the alpha (its
  GreenChannel switch, the flag at the end of each instance): green the Laboratory, the Satellite Uplink, the Foundry,
  Alien Containment, Thermal Power, the Psi Labs, the Gollop Chamber and the two labs; alpha the Workshop, the Fission
  Generator, the OTS, the Satellite Nexus, Elerium Power and the Hyperwave Relay. The converter (97) makes a cyan copy per
  facility (TintColor 0.14, 0.81, 0.85, brightened, black where nothing is drawn); the chooser shows the frame and adds
  the blueprint over the scene. Unchecked in the game until the base is converted again.
- **The hangar's jets** read pale cyan-white in the port, grey in EW, on all three hangar pairs: the craft are placed as
  EW's people are and so take the people's lights. Measured live (`lightoff`): the cyan comes from Command1's directional
  people light (LWX2PeopleLight); without it the jet turns warm brown, without the spot or point people lights it is
  unchanged (logs/compare/hangar-jet-lights.png: as is, then each kind off). EW's grey lies between; open.
- `nav-deep.sh` has six more screens for the next walk: an item's manufacture dialog, a gray market item, the craft's
  weapon and ship cards, the order and transfer dialogs.

## Report (2026-11-26, six more screens)

Walked in both games (EW on the person's Game 56 at 1 March 2016; the port on a fresh campaign): an item's manufacture
dialog, a gray market item, a craft's weapon and ship cards, the order dialog, transfer mode.

- **The manufacture dialog** was the port's own form (TIME, COST, the item's description, ENGINEERS with XCOM's count,
  a fixed quantity, START PROJECT, a stray "10 ENGINEERS" at its foot, and the corner arrow beside its BACK). Now as EW's
  (UIManufacturing.DrawItemProject, XGManufacturingUI.UpdateManufactureItem, UpdateManButtons): "Project Duration: 1d"
  (EW's ETA: hours under a day, else days), "Requirements:" with what the quantity takes in their colours (red when short),
  "ENGINEERS NEEDED" with the order's engineers (EW's m_strErrEngineers in red when XCOM has fewer), "QUANTITY:",
  "Note(s): To reduce the cost of items, build more workshops.", SUBMIT ORDER (BEGIN PROJECT for the Foundry), no corner
  arrow (logs/compare/manufacture.png). EW's words (lw-words.mjs, makeManufactureWords). Open: EW shows the quantity on
  its spinner with arrows (driven as its widget helper drives it, it did not show; the arrow keys and the wheel change
  it); the engineering room's ENGINEERS count peeks under the dialog's foot. Not carried: Long War's Build Quickly.
- **The item cards** (WEAPON INFO, SHIP INFO) had no CLOSE: the port called a SetHelp the card's movie does not have
  (EW's: SetButtonNavHelp, UIItemCards.RefreshNavigationHelp). And EW keeps the craft summary in view behind the card;
  the port hid it. Both fixed.
- **Order Interceptors, transfer mode, the gray market's item:** as EW's (in transfer mode EW's code labels the craft
  CANCEL TRANSFER too, UIShipList.UpdateData; its capture showed TRANSFER before its list redrew). Left: EW keeps its
  corner arrow under the order dialog.
