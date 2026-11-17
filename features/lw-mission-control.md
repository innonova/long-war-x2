---
title: Mission Control on Enemy Within's own screen
status: in-progress
priority: 30
dependsOn: [lw-ew-screens, lw-geoscape]
---

# Mission Control on Enemy Within's own screen

The Long War Geoscape (the hub's MISSION CONTROL) is still the port's plain panel: countries, decisions as buttons, run-time
buttons, events. Enemy Within's Mission Control is its `MissionControl` movie (`gfxMissionControl`, converted with the rest
of `UICollection_Strategy_SF` as `ewxMissionControl`): the mission list, the clock, and its alert popups, which are how EW
asks for every strategic decision (UFO contact with the jets to send, abductions to choose from, terror, crash and landed
UFOs, council missions, EXALT, the alien base, the Temple Ship, a satellite lost, a country's panic, a project done).

## Plan

1. The alerts first, over whatever strategy screen is up when the Geoscape stops for a decision: the right alert for the
   decision's kind, filled from Long War's state, its accept button taking the decision (`UILWGeoscape.Act`), back
   deferring it.
2. Then the screen itself: the mission list (`theMissionList`: `SetTitle`, `AddOption(index, text, state, icon)`,
   `clear`, `setFocus`) with Long War's pending missions, the clock, a scan (run time until something happens) in place of
   the panel's run buttons; the panel's country lines go to the Situation Room, which already has them.

## Findings (2026-11-17)

- **How EW drives an alert** (`UIMissionControl.GoToView`, `UIMissionControl_AlertBase`): the screen invokes
  `Load<Name>Alert` (`LoadRadarContactAlert`, `LoadUFOCrashAlert`, `LoadAbductionAlert` …), which attaches the library
  symbol into `theAlertContainer` as `<Name>MC`; the alert is then filled (`SetTitle`, `SetText`, `SetButtonText`, and
  per kind `SetContact`/`SetLocation`/`SetSize`/`SetClass` for a UFO contact, `AddShip`/`ActivateShipList` for its jets),
  and `AlertFullyLoaded` is invoked. Button clicks come back as mouse events on `button<N>`; back is decline.
- **The converter's class renaming reaches the alerts' names:** `ew-ui.ts` gives EW's AS2 classes names of their own
  (first letter Q) and renames every string that is such a name; the alert symbols share their classes' names, so the
  instance is `theAlertContainer.QadarContactAlertMC`, not `RadarContactAlertMC`. The mod must use the renamed names.
- **Tried on wingpu** (`ewscreen MissionControl theScreen`, `ewcall LoadRadarContactAlert`, setters by `ewcall`): the
  alert attaches but showed only its warning icon and rule after `SetTitle`, `SetContact` and `AlertFullyLoaded`; its
  text and frame did not appear. Next: read the RadarContactAlert/UFOAlert ActionScript for what else it waits on (the
  other setters, an intro animation, `_visible` set by its own code).
