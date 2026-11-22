---
title: EW's notices on Mission Control (item built, soldiers arrived, ship online ...)
status: planned
priority: 2
dependsOn: [lw-geoscape]
---

## The problem

Found by the click tests (2026-11-22, `strategy-actions`): an item built in engineering is only written into Long War's
event list. EW tells the player as it happens: a short notice on Mission Control, with a sound, for six seconds. The
port shows nothing, so things finishing pass unseen unless the player reads the event list.

## What EW does (read from its script)

- `XGFacility_Engineering.OnItemCompleted` (and the other systems) call `PRES().Notify(kind, data1, data2, data3)`;
  `XComHQPresentationLayer.Notify` hands it to `XGMissionControlUI.AddNotice` when Mission Control's UI exists.
- `AddNotice`: a notice of 6 s (`fTimer`), its text from `XGMissionControlUI`'s words with the data put in
  (`XGParamTag`), a text state and an image number, a sound for some. The kinds it knows: 20 item built
  (`m_strLabelItemBuilt`), 22 excavation complete, 23 facility removed, 17 new scientists, 16 new engineers,
  14 new soldiers, 15 soldier healed, 18 new interceptor arrived, 32 ship online, 31 ship rearmed, 30 ship transfer
  arrived, 40 council request expired, 41 request delayed, 33 satellite online, 24 UFO on the ground, 10 contact lost,
  52 signature not identified, and a few more (47, 48, 54, 37 days).
- `XGMissionControlUI.UpdateNotices` counts each down and drops it at 0; `UIMissionControl.UpdateNotices` shows them, the
  newest last, as one string with line breaks, through the movie's `DisplayNotifications`.

## The way

- A short list of notices kept beside the Geoscape (not saved: six seconds each), filled where Long War's rules note
  the same events (`XComGameState_LWStrategy.Note` callers: engineering built, soldiers arrived, facility done, jets
  arrived or repaired, satellites online, requests expired ...), each with EW's words from the player's install
  (`XGMissionControlUI` section, written by the setup like the other words).
- Shown on EW's Mission Control (`UILWEWMissionControl`) through its movie's `DisplayNotifications`, counted down by
  real time while it is open, as EW's.
- Checked with a click journey: an item ordered, the scan run, the notice seen (`see`).
