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

## Report (2026-11-17, the first alerts)

- **`UILWEWAlert`**: when the Long War Geoscape (the panel) refreshes with a new decision of a kind it handles, EW's alert opens
  over it on the MissionControl movie: a UFO detected (`RadarContactAlert`: UFO Contact, Contact, Location, UFO Class,
  Scramble Interceptors / Ignore Contact), a crash site (`UFOCrashAlert`) and a landed UFO (`UFOLandedAlert`: Send Skyranger /
  Ignore). Words are EW's own (`[XGMissionControlUI]`, `makeAlertWords`, written on the player's machine). Accept takes the
  decision (`UILWGeoscape.ActOn`: the air war, or squad select); ignore leaves it on the panel's list. Each decision is
  alerted once while the Geoscape is open.
- **The movie's calls:** everything by `Movie.Invoke` (XCOM 2's queued `MC` calls never ran on the alert); the alert's own
  `onLoad` hides its fields a frame after it is attached, so it is filled 0.2 s later; then `UFOAlertFinishedLoading` and
  `AlertFullyLoaded` show its frame.
- **Checked on wingpu:** a new campaign, time run on the Geoscape: at the first detected UFO the alert opened ("UFO CONTACT",
  "unidentified small UFO", "United States", "UNIDENTIFIED", SCRAMBLE INTERCEPTORS / IGNORE CONTACT); Enter opened the air war
  on that UFO. Screenshot: `logs/wingpu_ew_ufo_alert.png`.
- **Clicks:** solved the same day, below (*The clicks*). Enter and Esc work too.
  Behind the alert is whatever the camera shows (the Avenger); the other decisions still use the panel's buttons.

### The clicks (2026-11-17, solved)

The cause: EW's `AlertBase.OnChildMouseEvent` raises its buttons' events (`FlashRaiseMouseEvent`) under the alert's own
clip path (`…theScreen.theAlertContainer.QadarContactAlertMC`), and XCOM 2's `UIMovie.FlashRaiseMouseEvent` hands an event
only to a panel whose `MCPath` is exactly that path; there was none, so every event (hover and click) was dropped without a
log line. The Flash side was fine all along (the earlier guesses about `isMouseHit` and the topmost entity were wrong:
`isMouseHit` only refuses under a `mouseShield`, which this movie never sets).

The fix: `UILWEWAlertTarget`, a panel that stands at the alert's path (bound to its existing clip, made nothing in Flash) as
one of the alert screen's panels and passes the events to it; removed again as the alert closes. The buttons now show EW's
labels alone (the `[ENTER]`/`[ESC]` hints are gone).

Checked on wingpu, new campaigns: hovering `SCRAMBLE INTERCEPTORS` sends `MOUSE_IN` on `button_0`, clicking it opened the
air war on the UFO; clicking `IGNORE CONTACT` closed the alert and left the UFO on the Geoscape's list. Screenshot:
`logs/wingpu_ew_ufo_alert_clicks.png`. Not seen: a hover highlight on EW's buttons (none visible in the screenshot).
