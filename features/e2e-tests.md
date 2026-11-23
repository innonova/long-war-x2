---
title: End-to-end click tests and seeing motion
status: in-progress
priority: 1
dependsOn: []
---

## Why

aek, 2026-11-22: "the UI is still pretty janky and a few of the views are totally off"; leaving a screen was random (back
button, right click, Esc each working only sometimes), clicks opened the wrong screens, the Sectoids had lost their
animations; "the broken screen should be findable with a systematic walk through and comparison to expectations ... maybe
we should start building some E2E tests? ... tests with the old school clicking instead of the more efficient navigation
tools ... invent some tools that improve your ability to see what is going on".

The agent had been judging stills and navigating by the control port, which skips the player's own input: jank in clicks,
exits and transitions went unseen, and regressions in motion (animations) were not re-checked.

## The tools

- **`tools/test/e2e.sh <journey>`**: a journey of steps run on wingpu as a player plays: `click <label>` (the label found on
  screen by Windows' OCR, `tools/test/ocr.ps1`, clicked with the real mouse, `click-label.ps1`), `tab <room>` (EW's room
  tabs at their places: OCR misses that row in some states), `back` (the corner arrow), `esc`, `rmb` (a right click),
  `expect <screen>` (the top screen's class, from the control port: the check), `shot`, `wait`, `rec <name> <s>` (video),
  `lw <command>` (setup only, never the thing tested). Each step photographed; `logs/e2e/<journey>/run.log`.
- **OCR** (`ocr.ps1`): Windows.Media.Ocr, no install; tries scales, brightening (`-Gain`), inversion (`-Invert`: light text
  on dark is read far better inverted), bands, and words (`-Words`) when labels run together; `click-label.ps1` retries for
  up to three rounds (labels fade in as a screen takes focus).
- **Video** (`record.ps1`, ffmpeg via winget on wingpu): the game window for some seconds; `e2e.sh` fetches it and makes a
  strip of frames every quarter second, which can be looked at like a still.

## Journeys

- `base-menus.txt`: every room's first menu, each left by the corner arrow, Esc and a right click (60 steps). Passes.
- `aek-repro.txt`: Engineering → Facilities → out → Buy Items → Barracks, with each way out (39 steps). Passes.

- `tools/test/e2e-explore.sh`: the systematic walk: each room's menu read off the screen, each entry clicked, the screen
  that opens recorded and photographed (`logs/e2e/explore/`), left by the corner arrow (a dialog by Esc). All 11 entries of
  the five rooms open and close (Research's menu is behind its report on a fresh campaign; one OCR miss on the highlighted
  entry).

- `tools/test/species-check.sh` (in a mission): each Long War species spawned beside the squad (`spawn` now reports the
  unit's id, `anims #<id>` takes it), its mesh finding its idle in a set whose tracks fit its bones: all 23 pass after the
  Sectoid fix. (Some read "still" over a second: their joints sampled the same, an idle that barely moves those bones or a
  pawn out of view; the Sectoid seen in its crouched idle.)

## Report (2026-11-22)

- **Found and fixed:** a right click backed out of only a handful of EW screens (the others ignored it and stayed up while
  the player clicked on: the "random" exits, the wrong screens). Now every EW screen (`UILWEWScreen`) and the hub's rooms
  back out on a right click, once (the hub ignores the click that just closed a screen over it). The room's tab dimmed again
  on return. The Sectoids' animations (`features/lw-ew-units.md`).
- **Found by the explorer and fixed:** on Launch Satellite the corner back arrow did nothing: the arrow sends Esc to the
  screen on top, and there the Situation Room's own HUD (which passes its keys on) swallowed it. The arrow's Esc now goes
  down the stack to the first screen that takes it (`UILWEWStrategyHUD.OnMouseEvent`).
- **Not reproduced on the development build:** Launch Satellite "completely broken", the soldier view without its model
  (asked aek which download and what exactly).
- **Next:** journeys for the strategy screens' own buttons (research, build, hangar, Situation Room's menu), the Geoscape's
  clock and events, squad select and a mission's first turn; a species check (each EW body animates); clips of the
  transitions for review.
- **A setup bug, found from aek's report** (3d59a36 on aek's PC: a new campaign stuck on the loading screen, Launch
  Satellite showing only the countries' bars): the setup keeps EW conversions from earlier setups unless they predate
  converter version 20 (a copy of the number in `ew-maps.ts`, never raised), while the converter has reached 93. A player
  updating kept base levels and maps converted weeks before. wingpu never showed it: its levels are reconverted by hand
  with `--force`. Now one number, `tools/convert/converter-version.ts`, read by both; the next setup reconverts what an
  older converter made. (Whether this was the whole cause there: aek's Launch.log asked for.)

## Report (2026-11-22, the first mission)

- **aek's Launch.log and screenshots** (3d59a36, START pressed once): (1) START had been taken twice, 0.8 s apart (the
  movie's event and the mouse's release), starting the campaign twice; now once (`UILWEWDifficulty.bStarted`). (2) The
  soldier screen and Launch Satellite fell back to flat 2D screens and the mission map was dark: all three from the stale
  conversions above (the base's conversion lacked EW's 3D displays; the map's light map made by an older converter than its material
  expects). (3) The new campaign then stood on the loading screen for ever.
- **The hang, reproduced on wingpu** (every build back to 20 November: never covered, as every test campaign skipped the
  first mission): XCOM 2's new campaign (`XGStrategy`, state `Initing`) prepares the first mission, then waits while any
  movie plays: there, its intro film played as the loading screen, ending or skipped. The port leaves that intro out
  (`UILWEWDifficulty.Start` clears `StartIntroMovie`), so the movie playing was XCOM 2's looping loading screen, which
  never ends and takes no key. `stopmovie` on the hung game launched the mission. **Fix:** `LWX2FirstMissionStart`, set by
  the campaign's start and put on the strategy map by its first screen (`UIScreenListener_LWX2FirstMission`), stops the
  loading screen once the wait has begun (the history past its start state, `Initing`), then removes itself. The control
  port's campaign start with the first mission uses it too.
- **The first-mission journey** (`tools/test/e2e/first-mission.txt`): LONG WAR → START GAME, one click → the drop-ship
  briefing → Space → the squad on the map, XCOM's turn: passes. New steps: `key <name>`; `=LABEL` now exact on OCR's
  word path too (it had clicked LONG WAR: AIR WAR, the development build's demo button).
- **The first mission's briefing** showed XCOM 2's "Operation Gatecrasher": now an EW operation name (`LWOpNames`, set in
  `FirstMissionOnEWMap`). **Left open:** its location is XCOM 2's region text ("Wilderness of East Africa") and its
  briefing and objective are empty: Long War's state does not exist before the first mission, and XCOM HQ's country is
  chosen only after it (EW chooses the base first).

## Report (2026-11-22, after the first mission; clicks on 3D screens)

The first-mission journey carried on past the mission (won by `lw win`, the rest by clicks) found three faults on that
path, never walked before:
- **The start screen skipped:** the debrief (`UILWEWDebrief`) asked for Long War's campaign (`Arrived` → `GetOrCreate`),
  which made it with the United States as home; SELECT BASE LOCATION then never came. Now the debrief leaves it alone
  when there is none yet, and the start screen makes it with the base chosen.
- **The base black:** XCOM 2 comes back from a mission faded to black and fades in from its own after-action screen, which
  this path never shows. The hub clears the camera's fade when it opens (and a cinematic mode, if one is left on).
- **The journey now passes:** LONG WAR → START GAME → briefing → (won) → summary → debrief → SELECT BASE LOCATION → Begin
  Game → EW's base, seen.

The new `soldier-and-rooms` journey (a soldier's screens, Launch Satellite, a craft) seemed to find that **no click
reached the soldier summary's menu** on EW's armory panel (XCOM 2's 3D movie). **It was the test's own fault**, found by
sweeping the mouse over the panel (each mouse-in logged) against a screenshot taken at the same moment: the panel's
clickable rows match its drawn rows exactly, but Windows' OCR gives its boxes in the picture as it straightened it
(`OcrResult.TextAngle`, -1.9 degrees on that slanted panel, about the picture's centre), so the boxes came back up to 28 px
too high and the test clicked the row above (nothing above ABILITIES; ABILITIES for LOADOUT). `ocr.ps1` now turns each box
back. A click forwarding added in between (`UILWEWScreen.ForwardClick3D`, a click the movie "did not report" given to the
clip under the mouse) is taken out again; it is in download 731e83f, where it should only act on a click on a 3D screen
that the movie itself ignores. Also found, and real: a right click on the summary closed the soldier list below too (the
release reached it); now an EW screen closes on the press only.
Control-port aids added for this: `fade [off]` (fade, cinematic mode, the HUD's mouse target, the camera's busy state,
the displays), `click3d`, `closescreen <class>`, `uvadjust <display>`; `start-game.ps1 -Display` (fullscreen as a player's).

## Report (2026-11-22, evening)

- **Download 210f248** on the draft (replacing 3d59a36 by way of 731e83f), installed on wingpu from the zip; on the
  installed build all four journeys pass: first-mission (32 steps), soldier-and-rooms (41), base-menus (60), aek-repro (39).
- **`strategy-actions`** (new, 38 steps): a research project begun by clicks (Alien Weaponry; its requirement seen), an
  item ordered in engineering (MANUFACTURE → START PROJECT, seen in EW's project queue), Mission Control's SCAN FOR
  ACTIVITY with the clock running. **Found and fixed:** the research menu kept START NEW RESEARCH PROJECT after a project
  was begun (EW's CHANGE RESEARCH PROJECT came only on entering the room again): the hub rebuilds the room's menu when it
  gets the focus back.
- **Found, not fixed (EW's notices):** an item built is only noted in Long War's event list; EW shows a notice for it
  (`XGFacility_Engineering.OnItemCompleted`: `PRES().Notify(20, item, quantity)`), as for other events. The port has no
  EW notices yet.
- New steps: `see <text>` (OCR, spaces ignored), `maybe <label>`, `at <x> <y>`, `key <key>`.
- **Left:** squad select and a mission's first turn by clicks; the Geoscape's decisions (an alert answered); the hangar's
  actions; EW's notices.

## Report (2026-11-22, night)

- **Mission Control blank on every visit after the first:** found by opening it twice. Its list's rows had no text and
  no rows could be added: Flash's classes are global and the first movie to define one wins, and EW's Mission Control
  movie defines its list's classes itself; with the first Mission Control's movie unloaded, the next one's list was
  dead (the hangar's and research's lists survive repeat visits). **Fix:** `UILWEWMovieKeeper` keeps one hidden copy of
  that movie loaded beneath the hub. `e2e-explore.sh` now opens every room-menu entry and Mission Control twice and
  compares the text read on screen: all alike.
- **EW's notices** on Mission Control (`features/ew-notices.md`), checked by `strategy-actions` (`waitsee`).
- **`geoscape-mission`** (new, 25 steps): time run to the first abductions (setup, `until`), then by clicks Mission
  Control's alert, EW's site selection, squad select, LAUNCH, the briefing, a soldier moved by XCOM 2's right click, the
  turn ended (Backspace), XCOM's second turn (the state line now has `round=`). Passes. **Found and fixed:** on squad
  select EW's corner arrow sat under XCOM 2's own back button and its BUILD ITEMS label.
- **`e2e-all.sh`**: every journey from the start it needs (main menu or a campaign at the base).
- New steps: `until <cmd>|<text>|<setup>|<n>`, `lwsee <cmd>|<text>`, `waitsee <text> <s>`.

## Report (2026-11-23, early)

- **The base chosen before the first mission** (`features/first-mission-order.md`): `first-mission` now goes LONG WAR →
  START GAME → SELECT BASE LOCATION → Begin Game → briefing ("Alien Abductions - <country of the home continent>") →
  mission → debrief → EW's base.
- **New journeys:** `base-building` (Engineering → BUILD FACILITIES → an excavated tile → EW's facility list → Laboratory
  built), `hangar` (a jet's summary and loadout, an interceptor ordered), `satellite` (one built by setup, then Launch
  Satellite → the country → the confirmation → launched). All pass; `e2e-all.sh` runs ten journeys (about an hour).
- **Found and fixed:** EW's notices from before the session's first Mission Control never showed.
- **Test robustness:** journeys that run time now tolerate what the aliens' plan brings meanwhile (`escto` closes an
  alert, the notice checked as Mission Control opens rather than mid-scan); `lwsee` takes a regex (`~`).
- **Open, not reproduced:** once, in a full run, the hub's room menu ignored clicks for some minutes while the HUD's back
  arrow still worked (2026-11-23 00:17 run); five repeats and a rerun of the same sequence passed. Watched for in later
  full runs.
- **More journeys (2026-11-23, morning):** `psi-labs` (Psi Labs → ADD SOLDIER → EW's list (others greyed) → EW's psi
  tree → Mindfray → NEW TRAINING → CONFIRM → in training), `gray-market` (corpses sold), `foundry` (a project begun). All
  pass. Found on the way: Mindfray's words have holes where EW fills its duration and cooldown from native code
  (`features/lw-psi.md`).
- **`officers`** (new): Barracks → OFFICER TRAINING SCHOOL → Squad Size I → PURCHASE → CONFIRM UPGRADE → YES, the squad
  one larger. **Found and fixed:** under EW's confirmation dialogs the screen vanished and left the base's black cutaway
  (XCOM 2 hides a screen that loses the focus); EW's screens now stay in view under a dialog.
- **The drop-ship briefing** shows EW's situation for the mission (`see abduction in progress`). Development builds get
  Long War's words rewritten after each build (`tools/test/words.mjs`, run by `sync-build.sh`).
- **Downloads tested by all journeys on the installed build:** 0bbceda, af72592, 99e61dd (the draft's now).
- **Seen, not done:** the rubble in an excavated room draws in odd green-yellow colours; Mindfray's description holes.
- **Restart Mission left the mission without aliens** (found while setting up a shooting journey): XCOM 2 restores the
  mission's start into the history after the tactical HUD comes up, and Long War's pods spawned then
  (`LWMissionSquads.SpawnAtEWPods`) were lost; the mission could not be won. Now the tactical listener's two-second check
  (`UIScreenListener_LongWarX2Tactical.CheckSwept`) spawns the squad (and civilians, meld) when no alien was ever in the
  history. `geoscape-mission` restarts its mission and checks the aliens are back.
- **Seen, not a player's path:** after the `spawn` test aid dropped an alien, the mission's world drew black under the
  HUD.
- **`shot`** (new): in a mission, the selected soldier put in view of a pod (`inview` aid), key 1 → Fire Weapon (EW-style
  aim, the hit chance), Enter → the shot (XCOM's action points down by two; the state line now carries `selected_ap` and
  `xcom_ap`). The pod's reveal had XCOM 2's Shen or Tygan talking with a portrait: their sighting lines are cleared on
  Long War's species, and XCOM 2's beginner voice lines are off (decision in the chat).
- **Found in the control port, not a player's path:** passing the drop-ship briefing with `continue` set only the flag
  the key sets; the next key in the mission then ran XCOM 2's drop-ship fade to black, which never lifted. `continue`
  now does what the key does.
