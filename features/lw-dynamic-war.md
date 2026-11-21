---
title: Dynamic War (second wave #9)
status: review
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

## Report (2026-11-17, the alien AI)

- **Dynamic War's own monthly branch** (`XComGameState_LWStrategy.PlanMonth`, from Long War's `else` after its table):
  no table of UFOs, abductions and terror. At tier 4 with aggression below 4, an infiltration. At tier 3 or 4 with aggression
  4 or more, the HQ assault's count (every third such month). The aggression is not lowered each month. The resources'
  growth, the first month's infiltration, month 12's HQ assault and the Overseers are as before.
- **The passes** (`DynamicWar`, run twice in each hour of Long War's clock as Long War's two half-hour updates; `WarPasses`,
  started by `StartWar` at Long War's fractions): each kind's cost line from the resources and aggression, the pass roll,
  and on the 40th pass the mission at once (`AddUfos(…, bNow)`, `AddObjective(…, Hours, 0, …)`):
  - a UFO of objective 0, 1, 2, 4 or 8;
  - an abduction in a council country not under terror;
  - terror (a quarter of the time anywhere, else the terror target);
  - aggression one lower.
- **Not in the port, here as in the standard plan:** Long War's late mission (`AddLateMission`, its `eObjective_Infiltrate_2`
  over a continent where XCOM flies Firestorms). Its passes count and fire to nothing.
- **The numbers** in `XComLWGear.ini` (`Marathon=0.5`, `MarathonPasses=40`; `scripts/gear-config.mjs`).
- **Checked on wingpu** (new test aid `war`: the passes, resources, aggression, the objectives in the plan by kind):
  - **Standard Long War, days 30 to 59:** 4 scouting, 2 harvest, 5 abductions, 1 terror.
  - **Dynamic War, the same days:** 1 recon, 2 scouting, 3 abductions, 1 terror. About half, as `SW_MARATHON` 0.5 means.
  - The passes rose and fell back to 0 as missions came: abduction 33 → 39 → 2.
- **Next:** phase 2, the economy's scalars.

## Report (2026-11-17, the economy)

- **Fewer missions, each worth more.** Long War's "÷ `SW_MARATHON`" (× 2 at 0.5) applies where the port has each rule
  (`LWX2SecondWave.War`):
  - **Experience:** each soldier's gain from a mission (`LWExperience`; `XGCharacter_Soldier.AddXP`).
  - **Salvage:** a UFO's alloys and elerium (`GiveSalvage`; `XGItemTree.Alloys`, `Elerium`).
  - **The aliens' resources:** what a successful UFO brings them, and what a downed one costs them (`XGStrategyAI`).
  - **An abduction's reward cash** (`AbductionReward`; `DetermineAbductionReward`).
  - **Panic:** a country's change after the first day (`AddPanic`; `XGCountry.AddPanic`).
  - **A meld canister's meld** (`LWMeld`; `GetMeldAmount`).
  - **The terror missions taken,** by which the terror squads grow (`LWAlienSquads`).
- **Longer, as Long War has them:**
  - **Time out after a mission,** wounds and fatigue: ÷ ((0.5 + 1) / 2), a third longer (`LWWounds`, `LWFatigue`;
    `DetermineTimeOut`).
  - **An interceptor's repair:** ÷ 0.5 (`LWHangar`).
  - **EXALT:** a new cell's days to its first operation and the wait between cells ÷ 0.5 (`LWExalt`).
- **Smaller:**
  - **The council's corpse requests:** (1 + rand 4) × month × 0.5, 4 to 10.
  - **The items an engineering project needs,** above one: × 0.5, at least 1 (`LWEngineering.ReqCount`; `ItemAmount`).
- **Left out:**
  - ~~The mission summary's own ÷ `SW_MARATHON` on artifacts 161–164.~~ Done 2026-11-21: those are elerium, alloys,
    weapon fragments and meld (`data/itemtree.json`); `XGSummaryUI.CollectArtifactsFromDeadAliens` divides the dead
    aliens' (counted in tenths) by `SW_MARATHON` before each unit's roll, so with Dynamic War they double, as the
    experience does. The port's kill loot (`GiveKillLoot`) does the same.
  - The Medal of Honor's missions (medals not ported) and a colonel's roll every 10 × 0.5 missions (not in the port).
- **Checked on wingpu** (`war` now also prints six soldiers' experience): a mission won with Dynamic War gave each soldier
  +200 (350 → 550), where standard Long War gives +100. The other scalars are each a line where the port's rule is; not each
  seen.

## Report (2026-11-17, Long War's late mission, in both plans)

- **Long War's late mission** (`XGStrategyAI.AddLateMission`, its `eObjective_Infiltrate_2`) was missing from the port's
  standard monthly plan as well. It is in both now, as the port's objective 10 ("Overseer landing"):
  - **Where:** over a continent other than XCOM's where XCOM flies a Firestorm (`IsGoodOverseerTarget`), at the continent's
    headquarters country (the USA, Brazil, Germany, Japan, Nigeria). None without such a continent.
  - **What:** one Overseer coming down directly on day 2, give or take a day (`AddUFOMission(eObjective_Infiltrate_2, 2,
    eShip_UFOEthereal, eUM_Direct, 0, 1)`). Landed, it is a crash site (`OnObjectiveEnded`: `CheatCrash`), with no
    shoot-down's aggression or panic.
  - **When:** in the standard plan, under a 50% roll in nine of the table's cells (tiers 2 to 4; `scripts/strategy-config.mjs`
    now reads `AddLateMission` out of Long War's code into `MaybeUfos` as 10). In Dynamic War, from its pass kind 9,
    1 to 26 days on.
- **Checked on wingpu** (test aid `war late`: a Firestorm on the next continent, the late mission planned at once): an
  Overseer for Brazil at hour 47, "Day 3: an unidentified medium UFO has come down in Brazil: a crash site for 36 hours".
