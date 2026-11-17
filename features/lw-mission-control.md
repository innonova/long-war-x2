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

## Report (2026-11-17, the other decisions' alerts)

Every Geoscape decision EW asks with a Mission Control alert now opens EW's alert, filled as EW's alert classes fill it
from `XGMissionControlUI.UpdateAlert` (read from Long War's own package, decompiled outside the repository):

| Decision | EW's alert | What it shows | First button | Second / Esc |
|---|---|---|---|---|
| 4 abductions | `AbductionAlert` | ALIEN ABDUCTIONS REPORTED | VIEW ABDUCTION SITE: the alert closes on the Geoscape's list of sites (EW's site selection, for now) | IGNORE |
| 5 terror | `TerrorAlert` | ALIENS TERRORIZING, the country (EW: the city; the port has none), PANIC with Long War's bar (`GetPanicBlocks`), ALIEN ACTIVITY: Swarming (EW's `eMissionDiff_VeryHard`) | SEND SKYRANGER: squad select | IGNORE |
| 6 alien base | `AlienBaseAlert` | ASSAULT THE ALIEN BASE, LOCATION: the country | ASSAULT | WAIT |
| 7 Temple Ship | `TempleShipAlert` | ASSAULT THE TEMPLE SHIP, EW's line under it | ASSAULT | WAIT |
| 9 operative ready | `ExaltAlert` | OPERATIVE READY, EW's warning that the operative is lost if ignored | SEND EXTRACTION SQUAD | NOT NOW |
| 11 council mission | `FundingCouncilAlert` (a `SimpleAlert`, one button) | COUNCIL MISSION: its kind, Location: the country | SEND SKYRANGER | Esc |

Abductions that come together get one alert, as in EW. The HQ's defence, EXALT's base and the council's requests stay on the
panel: EW has no Mission Control alert for them (a cinematic, the Situation Room, the council's request screen).

- **Words:** EW's own (`makeAlertWords`): every `[XGMissionControlUI]` section of the player's `XComStrategyGame.int` (the
  file has more than one; the first version read only the first) and `[XGLocalizedData]` for the activity's name: 27 words.
- **Clicks:** as EW's `AlertWithMultipleButtons.OnMouseEvent`: the clicked clip `button_<N>` (or a simple alert's single
  `button`); the second button leaves the alert.
- **Names:** the alert's clip is `<Name>MC` (the UFO landing's `UFOLandingAlertMC`), under the converter's name when the
  alert has a class of its own (`QerrorAlertMC`, `QempleShipAlertMC`); `FindAlert` takes whichever the movie has.
- **The Temple Ship's title:** XCOM 2's font standing in for EW's runs wider, and the title was cut at the alert's frame
  (its field runs past the frame). Scaleform's `textAutoSize` and scaling the field did not help; the title is now set at the
  size that fits (measured at a known size by `textWidth`). Only this alert's title was seen to overflow.
- **Test aid:** `ewinvoke`'s `s:` strings take `_` for a space.
- **Checked on wingpu** (new campaigns, time run): abductions (`logs/wingpu_ew_alert_abductions.png`), the council's bomb
  disposal (`logs/wingpu_ew_alert_council.png`), terror in the United States after the month's report
  (`logs/wingpu_ew_alert_terror.png`), the Temple Ship with a Gollop Chamber placed by the test aid
  (`logs/wingpu_ew_alert_temple.png`); ASSAULT clicked opened squad select. **Not seen:** the alien base and the operative
  alerts (no quick way to an alien base or a ready operative yet); written the same way, from EW's classes.
- **Open:** EW's abduction site selection (`LoadAbductionSelection`) in place of the panel's list; the UFO contact's other
  rows (size, altitude, objective with the Hyperwave Relay) and its jet list; the Mission Control screen itself (plan 2).

## Report (2026-11-17, the abduction site selection)

- **EW's `AbductionSelection`:** the abduction alert's VIEW ABDUCTION SITE now replaces the alert with EW's site selection, in the
  same movie, as `UIMissionControl_AbductionSelection` fills it from `XGMissionControlUI.UpdateAbduction`: up to three sites
  as its buttons (EW's widget helper: `widgetHelper.SetButtonLabel`, `SetActive`, `SetSelected`; clicks on `option<N>`,
  arrow keys), and for the chosen one the country, its panic bar, ALIEN ACTIVITY in EW's colours (Light green, Moderate yellow,
  Heavy and Swarming red; EW's `MissionDifficultyNames`) and the REWARD; Confirm (or Enter) opens squad select for it, Esc
  leaves the abductions on the list.
- **A fix underneath:** an abduction's difficulty was rolled again each time it was asked for (once for the alien squad, once
  more for the reward), so the two could disagree. Long War fixes it when the mission is made (`m_eDifficulty`); the port now
  does too (`LWSite.Difficulty`, set as an abduction or council mission comes), and the squad, the reward
  (`AbductionReward`) and the selection read it. Sites from a save made before this read as Light.
- **Words:** six more of EW's (`m_strLabelAbductionSites`, `m_strLabelReward`, the selection's Confirm, the four difficulty
  names): 33 alert words.
- **Checked on wingpu:** abductions in Japan: the alert, VIEW ABDUCTION SITE clicked, the selection (JAPAN, panic, Moderate,
  §90; `logs/wingpu_ew_abduction_selection.png`), Confirm clicked: squad select. **Not seen:** a selection with more than one
  site (this campaign's abductions came one at a time).

## Report (2026-11-17, the UFO alerts' rows)

- **As EW's `UIMissionControl_UFORadarContactAlert` and `UIMissionControl_UFOAlert` fill them:** CONTACT is EW's `UFO-<n>`
  (here the UFO's number in the campaign's list; EW counts the UFOs it has made), LOCATION the country with the altitude by
  the UFO's mission (`XGShip_UFO.GetAltitudeString`: NOE for research, harvest, abductions, terror, infiltration; High for a
  hunt; Low otherwise), SIZE the class's size (the air war's: `XGItemTree.BuildShips` with Long War's changes by research
  category), UFO CLASS the class when known. With the Hyperwave Relay the labels turn orange and EW's HYPERWAVE RELAY panel
  shows the UFO's objective (`XGStrategyAI.m_arrObjectiveNames`). A landed UFO's title is EW's "UFO-<n> Has Landed".
- **Words:** 22 more of EW's (`m_strLabelUFOPrefix`, `m_strLabelSize`, `m_strLabelAlienObjective`, the Hyperwave panel's
  title, the four sizes, the three altitudes, the eleven objective names): 55 alert words.
- **Build scripts:** XCOM 2's script compiler crashed on this round's first version (a minidump, no error) and the build
  scripts printed only the first compile's `Success`, so the crash looked like a pass and the old script stayed installed.
  `build.ps1` and `sync-build.sh` now print "Crash detected". The crash went away with the size read into a local struct
  first (no `switch` over a returned struct's member) and the function renamed; which of the two caused it was not isolated.
- **Checked on wingpu:** a small UFO (`UFO-3`, United States (Low), Small, UNIDENTIFIED); with a Hyperwave Relay placed by the
  test aid, an Overseer (`UFO-10`, Medium, Overseer, objective Command Overwatch, orange;
  `logs/wingpu_ew_ufo_alert_hyperwave.png`).
- **Open:** a landed or crashed UFO's crew size and species under the Hyperwave Relay (EW shows them; the port makes the
  alien squad only when the mission is launched, so there is nothing true to show yet). The contact alert's jet list: next
  report.

## Report (2026-11-17, the contact alert's jets)

- **Long War's jet list in the alert** (`UIMissionControl_UFORadarContactAlert`, state `ShipSelection`, data from
  `XGInterceptionUI.UpdateSquadron`): SCRAMBLE INTERCEPTORS now turns the alert into EW's list of the jets based on the UFO's
  continent: callsign, weapon and kills ("Avalanche Missiles (0 kills)"), status in EW's words and colour (Ready green;
  Refuelling, Repairing, In Transit, Arming Weapon with their hours or days, red; such a jet greyed and refused), the
  Firestorm's or Interceptor's icon, and under the chosen jet Long War's stance buttons DEF, BAL, AGG
  (`m_strLabelLaunchFightersPC`). The healthiest ready jet starts chosen at BAL. Pointing at a jet chooses it; clicking a
  stance launches it at that stance; the arrows move between jets and stances, Enter launches, Esc ignores the contact.
- **The air war** opens on that jet at that stance (`UILWGeoscape.Intercept`; `UILWInterception.PresetStance`), Long War's
  stances in the air war's numbering (balanced 1, aggressive 2, defensive 0, as `ToggleInterceptor` takes them from the
  stance the alert sets).
- **Words:** 12 more of EW's/Long War's (the stance buttons, "kills)", the statuses, hours and days): 67 alert words.
- **Checked on wingpu:** a small UFO over the United States: SCRAMBLE clicked, the list (Raven-1 and Raven-2, Avalanche
  Missiles, Ready; `logs/wingpu_ew_ufo_alert_jets.png`), AGG on Raven-1 clicked: the air war on Raven-1, [AGGRESSIVE].
- **Seen, not fixed:** the jet list runs down over the movie's event list (COUNCIL REPORT) at the bottom right; EW's own
  `HideNonAlertComponents` is called but leaves it.
