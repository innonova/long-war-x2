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
