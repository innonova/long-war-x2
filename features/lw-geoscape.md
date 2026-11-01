---
title: "Long War's Geoscape: the council's countries, panic, satellites, UFOs and the month"
status: in-progress
priority: 2
dependsOn:
  - hard-parts
---

## Purpose

The strategy layer is replaced whole (the person, 2026-10-31), and it is
what the person sees in the first hour of a campaign: Long War rather than
XCOM 2. This feature is its first part, the Geoscape: the sixteen council
countries with their panic, satellites and funding; time passing; the
aliens' UFOs over the month, detected or not, intercepted (the air war) or
ignored; crash sites, landed UFOs and abductions as missions; the monthly
council report with funding and defections. Research, engineering and the
base come later (`port-plan.md`).

## What the person should see

A campaign starts on our Geoscape screen (opened from the Avenger for now):
the date, the money, the council's countries by continent with their panic
and satellites; time runs at a pace the player sets, and stops when
something needs a decision: a UFO detected (intercept it or not), a UFO
shot down or landed (send the squad or not), abductions (pick one), the end
of the month (the council report). Long War's own numbers throughout.

## Requirements

- **Long War's numbers, generated from its config** (`DefaultGameCore.ini`,
  read by `scripts/strategy-config.mjs`, as the classes and the air war
  are): the council countries' funding, starting panic, panic from ignored
  UFOs, abductions, shoot-downs and satellites, defection thresholds and
  chances, satellite panic relief, mission timers, satellite price and
  build time, interceptor detection chance. Per XCOM 2 difficulty mapped
  to Long War's (Rookie → Normal, Veteran → Classic, Commander → Brutal,
  Legend → Impossible).
- **The aliens' monthly plan as Long War makes it** (XGStrategyAI, read
  from the player's `XComStrategyGame.upk`): how many UFOs of which kind,
  abductions and terror missions, by the aliens' resources and the month.
  Approximations are marked as such in the code and the report until they
  are Long War's own.
- The state lives in XCOM 2's game state (`XComGameState_LWStrategy`) and
  survives saves; money is XCOM 2's supplies.
- Missions go through XCOM 2's mission path (experiment 4), on EW maps when
  the player has converted them.
- Not yet: research, Foundry, engineering, the base, alien bases, EXALT,
  council missions, the alien research clock's effects on aliens.

## Hard to verify

A month's worth of play in the game: the clock, the events, the decisions,
the report. Checked by running time on the test machine with the log of
every event, and by screenshots at each decision.

## Facts

- Long War's panic is 0–100 per country (five levels of 20 shown);
  defection rolls at month end above 95.
- Funding: each council country's amount (`FundingAmounts`, 16 marked
  "fc") × `FundingBalance`; a country without a satellite gives
  `BASE_FUNDING`% of it.
- Council countries by continent: North America (USA, Canada, Mexico),
  South America (Brazil, Argentina), Europe (UK, France, Germany, Russia),
  Asia (China, Japan, India, Australia), Africa (Egypt, Nigeria, South
  Africa).
