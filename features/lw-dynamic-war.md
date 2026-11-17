---
title: Dynamic War (second wave #9)
status: in-progress
priority: 40
dependsOn: [lw-second-wave, lw-geoscape]
---

# Dynamic War (second wave #9)

Long War's text: "A tunable version of Long War with a new alien strategic AI, scaled number of missions and an adjusted
economy. Default is 50% of standard Long War, but this can be changed by modding DefaultGameCore.ini." The last of the 31
options (features/lw-second-wave.md), and big enough to be a feature of its own. `SW_MARATHON` (0.5) is the master
coefficient, `SW_ELERIUM_LOSS` (40) the passes a mission needs.

## Long War's code (1.0), what the option changes

Five of the checks are dead code: Long War jumps over them (`goto` before the test). Under the option, research time
(`TechCost`), facility and item costs (`GetFacilityCost`, `GetItemCost`), an item's engineers and its cash are unchanged.
The live ones:

**The alien strategy AI (XGStrategyAI)**
- **The monthly plan** (`AIAddNewObjectives`): its table of UFOs, abductions and terror missions by the aliens'
  resources and month is skipped. Kept: the alien resources' growth and clamp, the first month's infiltration, month 12's HQ
  assault, the Overseers, the council mission.
- **The new AI** (`TallySquadCost`, run at each update, every half hour):
  - **Each half hour:** eleven mission kinds each have a cost from the aliens' resources R (`eRecap_FundingCountries`,
    clamped to 9 × month … 300) and their assets A (`eRecap_ContinentBonuses`, 0 … 8), times `SW_MARATHON`. Each gains a
    pass with chance cost / (10000 / `SW_ELERIUM_LOSS`).
  - **On its `SW_ELERIUM_LOSS`-th pass a kind fires**, and its count starts again:
    - 0, 1, 2, 4, 8: a UFO of that objective (`AddUFOs`);
    - 5: an abduction;
    - 6: a terror mission (a quarter of the time in a random council country, else the best target);
    - 9: a late mission (`AddLateMission`);
    - 10: one asset fewer.
  - **The cost lines:**
    - 0: 0.07R
    - 1: 21 + 0.05R + A
    - 2: 21 − 0.07R
    - 4: −3 + 0.025R + 2A
    - 5: 27 + 0.034R − 1.5A
    - 6: 0.03R + 1.5A
    - 8: 0.05R + A
    - 9: 0.01R + 0.5A
    - 10: 5A
  - **The starting counts** (`XGStrategy`): kinds 0, 1, 2, 5, 6 at 0.2, 0.7, 0.4, 0.7, 0.5 of `SW_ELERIUM_LOSS`.
- **Objectives' start days:** the UFOs' and abductions' are 0 (at once) instead of a random day of the month. The second
  infiltration's is 1 + Rand(26).
- **Squads:** the alien base's count of missions taken is divided by `SW_MARATHON` (`BuildPod`'s choice).
- **Alien resources:** what the aliens gain from a mission, and lose from a downed UFO, ÷ `SW_MARATHON`.
- **A council mission's reward credits** ÷ `SW_MARATHON`.

**XCOM's side**
- **Experience:** a soldier's mission and kill experience ÷ `SW_MARATHON` (`XGCharacter_Soldier`).
- **Loot:** the mission's artifacts ÷ `SW_MARATHON` (`XGSummaryUI`); a meld canister's meld likewise (`GetMeldAmount`).
- **UFO alloys** ÷ `SW_MARATHON` (`XGItemTree`), and the salvage category ÷ `SW_MARATHON`.
- **Item amounts:** `ItemAmount` × `SW_MARATHON` (at least 1) for amounts above 1. To be found: what calls it.
- **Wounds:** a soldier's time out ÷ ((`SW_MARATHON` + 1) / 2) (`XGFacility_Barracks`).
- **Interceptors:** their repair hours ÷ `SW_MARATHON` (`XGFacility_Hangar`).
- **Panic:** a country's panic change ÷ `SW_MARATHON` (`XGCountry`).
- **EXALT:** its days until the next activity and its cell placement cooldown ÷ `SW_MARATHON`.
- **The council:** a request's amount from 4 to 20 × `SW_MARATHON` by month (`XGFundingCouncil`); one other check there.
- **Medals and the colonel's bonus:** missions for the Medal of Honor × `SW_MARATHON`, the colonel's roll every
  `HQ_STARTING_MONEY` × `SW_MARATHON` missions.

## Plan

1. **The new alien AI:** the passes and the half-hour roll, the starting counts, the monthly plan's table skipped, start
   day 0. The port's `XComGameState_LWStrategy.PlanMonth` and `AddUfos` follow `AIAddNewObjectives` and `AddUFOs`. A test
   aid shows the counts and the costs.
2. **The economy's scalars**, each where the port has the rule: experience, loot and meld, alloys, alien resources,
   rewards, wounds, interceptor repair, panic, EXALT, council requests, medals.
3. **Checked** by running a campaign's months with the option, comparing the missions' count with standard Long War's.

## Decisions

- Its own feature: it is a variant of the whole strategy layer, not one rule.
