---
title: "Long War's council missions, and each mission kind's own objectives"
status: in-progress
priority: 30
dependsOn: [lw-geoscape, lw-missions, lw-exalt]
---

# Long War's council missions, and each mission kind's objectives

The person chose this next on 2026-11-16 ("Long War's objectives per kind", STATUS: Missions). Today every
mission the port plays is won by killing or taking every alien. Long War has more kinds than that, and
the biggest gap is that **the council's missions are not in the port at all**.

## Long War's rules, as read (2026-11-16)

Read from stock Long War 1.0's `XComStrategyGame.upk` (`XGFundingCouncil`), with the Tree's
`upk_script.py`; the decompiled code stays out of the repository. Its numbers come from `DefaultGameData.ini`
(`[XComStrategyGame.XGFundingCouncil]`).

**When a council mission comes** (`XGFundingCouncil.Update`, hourly):
- `m_iFirstRequestCountdown` counts down hours. It starts at 336 + rand(336) (2 to 4 weeks) and is set
  again each month (`SetupMonthlyRequests`). At 0, with no council mission on the Geoscape
  (`GetNumMissionsOfType(11) == 0`), one is made (`DetermineNewFCMission`) and the countdown stops
  (9999) until the month's reset. So there is at most one a month.
- A second countdown (36 + rand(36) hours; Quai d'Orsay shortens it) makes the council's *requests*
  (items wanted for rewards). The requests are a separate part (STATUS: "council requests").
- The country: a random council country where XCOM has a satellite, else any
  (`DetermineFCMissionCountry`, `GetAvailableMissionCountries`).

**Which mission** (`ChooseNextMissionByType`): of the four kinds (Assault, Bomb, Extraction, Rescue),
those with a valid map for the region; of those, the kind played least often; then one of its missions.
Progeny (EW's three-mission chain) and the Chryssalid hive come in where enabled. Slingshot is a DLC.

**The missions** (`BuildMission`, one case per `EFCMission`): each has its own EW map with a mission
variant, for example `URB_PierA` "Assault on Pier", `URB_CemeteryGrand` "Bomb Defusal Grand Cemetery" or
`URB_ResearchOutpost` "Research Outpost Rescue". Each also has its rewards: cash
(`RandMoneyRewardAmount(MIN_MONEY_REWARD 100, MAX_MONEY_REWARD 225, 5)`, sometimes
×`FCM_MONEY_SCALAR` or ×2), the country's panic down (−20 to −60), engineers, scientists, a soldier
(sometimes a named one), alloys, elerium or meld. Each has a panic on failure (`MISSION_FAIL_LOW_PANIC`
20, `HIGH` 40, on the continent).

**Rewards by the campaign's age** (`CreateMission`): before day 21 ×0.5 (`MISSION_REWARD_LOW_DAYS`,
`_MULT`), before day 41 ×0.75. A reward soldier is level 1, 2 or 3 by the same days.

**The mission** is a mission of its own type (11) on the Geoscape, lasting `ABDUCTION_TIMER`. Won,
`GrantFCRewards` pays. Lost or abandoned, `CausePanicOnFailure`.

**The objectives by kind** (EW's map variants carry them; read next):
- **Assault**: clear the map (as today).
- **Bomb**: disarm the bomb's nodes before the timer ends.
- **Extraction**: escort a VIP to the evac zone.
- **Rescue**: reach a VIP held by the aliens, then extract.

And EXALT's covert missions (`lw-exalt.md`): **extraction** (the operative to the evac zone) and
**data recovery** (EW's capture and hold).

## Plan

1. **Council missions on the Geoscape.**
   - Long War's clock, kind rotation, country and per-mission rewards, as config generated from
     Long War's code (numbers and map names only: a Tree script → `data/council.json` →
     `scripts/council-config.mjs`).
   - Offered as a decision with its time, played on its EW map, paid or punished.
   - Every kind first plays as an assault, the rest of its objective following in step 2. Marked as
     an approximation until then.
2. **The objectives on EW's maps.** What each variant places (the bomb's nodes, the VIP, the evac zone),
   read by the map converter, and the rules as our own mission logic: the bomb's nodes and turns, the
   VIP's escort and rescue.
3. **EXALT's covert objectives**: the operative's extraction and the data recovery.
4. Progeny and the Chryssalid hive.

## Report (2026-11-16, step 1: council missions on the Geoscape)

Long War's council missions come to the Geoscape now (`LWCouncil`, `XComLWCouncil.ini`):
- **The data:** `scripts/upk_council.py` (in the Tree) reads Long War's `BuildMission` and its
  `DefaultGameData.ini` into `data/council.json`. From that, `scripts/council-config.mjs` writes
  the 17 missions of the four kinds (map, kind, rewards, panic on failure) and the constants.
- **The clock** (`XGFundingCouncil.Update`, `SetupMonthlyRequests`, `OnEndOfMonth`): 336 + rand(336)
  hours into each month, with no council mission waiting, the month's mission is made.
- **The mission:**
  - of the kind played least among those with a playable mission; with EW's maps on, a mission
    is playable if its map is converted (`ChooseNextMissionByType`);
  - in a council country under a satellite, else any (`GetAvailableMissionCountries`);
  - its rewards rolled as Long War's (`RandMoneyRewardAmount`, the factors) and scaled by the
    campaign's age (×0.5 before day 21, ×0.75 before day 41; a soldier's level by the same days).
- **On the Geoscape:** "COUNCIL: <kind> in <country> (hours; rewards)". It waits as an
  abduction does (`ABDUCTION_TIMER`, 8 hours).
- **Sent:** played on its own EW map when converted; on XCOM 2's plots, as a guerrilla op.
- **Won** (`GrantFCRewards`): the aliens' loot, plus cash, the country's panic, engineers,
  scientists, elerium, or a soldier from the country at the rolled level.
- **Lost or let go** (`CausePanicOnFailure`): its continent's panic.
- **Control port:** `council` (the clock, the missions) and `council now` (the month's mission at
  once). `act` now refreshes the Geoscape first.

**Checked on wingpu:**
- `council now` offered "bomb disposal in United States (§112, 3 scientists, panic −40)",
  scaled ×0.5 on day 1.
- Another, "extraction (§146, panic −10, 2 scientists, a soldier)", sent and won: money 500 →
  646, scientists 10 → 12, "Laurie Moore joins XCOM from United States".
- A Cemetery assault let go: "failed", the United States' panic 23 → 43 (its continent +20).

### Decisions

- **Every kind plays as clearing the map for now.** The bomb's nodes, the VIP's escort and the
  rescue are step 2. APPROXIMATION until then.
- **The aliens are an abduction's squad in that country.** Long War builds its own,
  `DetermineSpecialMissionSquad`: 7 to 15 aliens by the month, the pods by how many council
  missions were taken. APPROXIMATION.
- **Two of Long War's maps are not converted here** (`URB_ResearchOutpost`, `URB_CommercialAlley`):
  with EW's maps on, their missions are not offered, as Long War skips missions without a valid map.
- The Chryssalid hive, the Meld tutorial and Progeny are left for step 4; Slingshot is a DLC.
