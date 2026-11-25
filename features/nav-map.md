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
mission lost a soldier), the soldiers' ranks (the port's start makes Long War's Lance Corporals).
