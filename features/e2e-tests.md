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

## Report (2026-11-22)

- **Found and fixed:** a right click backed out of only a handful of EW screens (the others ignored it and stayed up while
  the player clicked on: the "random" exits, the wrong screens). Now every EW screen (`UILWEWScreen`) and the hub's rooms
  back out on a right click, once (the hub ignores the click that just closed a screen over it). The room's tab dimmed again
  on return. The Sectoids' animations (`features/lw-ew-units.md`).
- **Not reproduced on the development build:** Launch Satellite "completely broken", the soldier view without its model
  (asked aek which download and what exactly).
- **Next:** journeys for the strategy screens' own buttons (research, build, hangar, Situation Room's menu), the Geoscape's
  clock and events, squad select and a mission's first turn; a species check (each EW body animates); clips of the
  transitions for review.
