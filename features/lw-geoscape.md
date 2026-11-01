---
title: "Long War's Geoscape: the council's countries, panic, satellites, UFOs and the month"
status: review
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

## Report (2026-11-01, the Geoscape runs on Long War's own rules)

The Geoscape now plays a campaign month the way Long War's code does.
I read the rules from Long War's `XComStrategyGame.upk` (decompiled into
scratch only, never into the repository). What was a guess in the first
version is now Long War's own rule, except the items listed under "Left
open".

**What it does, all checked in the game on wingpu:**

- **The start** (`XGWorld.AddInitialPanic`, `SetStartingContinent`):
  - The starting panic goes out in steps of 3 to random council countries.
    A country stops receiving it at 84. In the game: 402 points on Classic,
    where Long War's number is 400.
  - A satellite over the home country (the United States until a choice
    of home exists).
  - Long War's starting money: $500 on Classic, in place of XCOM 2's
    $175.
- **The aliens' month** (`AIAddNewObjectives`, `AddUFOs`, `GetNumOutsiders`,
  `BuildObjectives`, `GetFlightPlan`):
  - The plan cells as before. Each objective now picks its ship by Long
    War's table, from the aliens' resources and the campaign's day.
  - Each objective sends Long War's sequence of UFOs. Each UFO launches
    on Long War's day, give or take Long War's random days, and flies its
    flight plan:
    - specimen flights land for the landed timer (recon, harvest);
    - scouts and hunts circle for 4 or 6 hours;
    - drop-offs fly over;
    - direct flights complete their objective on touchdown.
  - Abductions and terror now come by UFO: an Abductor, or a Terror Ship
    followed by an Assault Carrier. The site appears when the last one
    lands, so shooting it down prevents the site.
- **Targets** (`DetermineBestVisibleTargets`, `DetermineBestTerrorTarget`,
  `DetermineBestAbductionTargets`, `DetermineBestOverseerTargets`):
  - Recon and scouting go to countries XCOM watches.
  - Harvests avoid watched countries when the aliens are aggressive.
  - Terror strikes the most panicked candidate (85%) or one of the top
    three.
  - Once a country has left, terror strikes its neighbours. Long War's
    neighbour table is generated from its code into the config
    (`Neighbours=` on each country).
  - Abductions hit distinct countries.
- **The first month's infiltration**: in March Long War sends a
  Battleship, a Transport and an Overseer against a council country off
  XCOM's continent. When the Overseer lands, that country signs a pact and
  leaves the council. Only shooting down the Overseer prevents it.
  `LeaveXComProject`'s special case for month 0 shows Long War means
  this. It happened in every test run (France once, Australia twice).
- **Results** (`LogUFORecord`, `OnObjectiveEnded`, `ApplyMissionPanic`,
  `FoundSatellite`, `LeaveXComProject`):
  - **Panic from UFOs.** A finished UFO adds Long War's panic, scaled by
    the damage it took. Hunts and Overseers add none. An air raid adds its
    own, larger number in place of the usual one.
  - **Alien resources.** A harvest brings the aliens resources (+0 to 4
    at random).
  - **Downed UFOs.** A UFO brought down raises the aliens' aggression,
    by 2 for large ships (the Harvester was missing before). Taking a
    landed UFO counts the same. Losing that assault lets it escape with
    its harvest.
  - **Hunts.** A hunt finds the satellite by its UFO's damage, more easily
    on a second pass.
  - **Abductions.** Unanswered: panic in the country and on its continent.
  - **Terror.** Unanswered: the country leaves the council (it only added
    continent panic before).
  - **Leaving.** A country that leaves costs the aliens 50 resources
    after the first month.
- **The council meeting** (`XGContinent.WhoIsLeaving`,
  `XGWorld.ReducePanic`): Long War's exact defection roll replaces my
  stand-in.
  - A country rolls to leave from panic 94 (95 "blocks"), with a chance
    of blocks × 1%.
  - A country XCOM left alone this month (abductions or terror
    unanswered or lost) rolls blocks²/100%.
  - A satellite over the country halves the chance, and one elsewhere on
    its continent cuts it.
  - Countries with abductions under way stay.
  - After that come the funding and the satellites' panic relief, in
    Long War's order.
- **Interception from the Geoscape**: tested.
  - INTERCEPT on a detected Scout opens the air war on that Scout.
  - On Aggressive it broke up, and the Geoscape recorded it.
- **A mission from the Geoscape**: RESPOND to abductions sends the squad
  through XCOM 2's mission path and takes the result back.
  - The first run counted as lost, because the development END MISSION
    button did not complete the mission's objectives, and XCOM 2 judges
    a guerrilla op by them. The button now completes them first.
  - With that fix, the second run came back as "The mission in France
    succeeded", with France's panic down by Long War's 2.
  - `tools/test/geoscape-mission.sh` runs the round trip. It now clicks
    through late first-time tips; that fix is not yet proven in a full
    run, because I finished this run by hand.

**What a month looks like when the player answers nothing.** Three
abductions in Europe drive Russia, the United Kingdom and France past 94,
and all three leave at the month's end. The aliens' three harvests
(Transports, which is what Long War's table gives a harvest at zero
resources) and the four defectors put them at tier 3 by April. That is
Long War being Long War when ignored, not a fault in the port, as far as
the code says.

### Decisions

- **Long War's code over memory or the wiki.** Where the two might
  disagree (a Transport harvesting in March, a country lost to
  infiltration every March), the code wins, and the person's memory of
  playing Long War is the check.
- **One UFO per phase.** An objective with several ships (terror,
  infiltration) is several entries sharing a group. Only the last one's
  success completes the objective, as in Long War.
- **No globe**: each leg of a flight (arrival, fly-over, departure) takes
  one hour. Long War flies these across the globe at the ship's speed.
  Marked APPROXIMATION in `LWStrategyRules.LegHours`.
- **The neighbour table comes from Long War's code**
  (`DetermineBestTerrorTarget`, where Long War wrote country numbers in
  place of aliens), generated like the plan. The ship table and the
  flight phases are written into `LWStrategyRules` with their source.
  They are short, and parsing them from bytecode would be fragile.

### Left open

- **Things that stay approximate:**
  - Jets detect only on the home continent: there are no bases yet.
  - The flight legs (above).
  - A UFO is seen or not when it launches, rather than as it crosses
    watched countries.
- **A terror mission won** changes no panic. Long War's result depends
  on the civilians saved, which XCOM 2's missions do not count yet.
- **Scout hunts and the alien base:** Long War's follow-up hunts after
  scouting (`ShouldHunt`, `AddHuntTarget`), and the alien base and HQ
  assault missions, are not in yet.
- **Choices not offered yet:** the choice of home continent, and its
  bonus.
- **Mission rewards and maps:**
  - A mission still pays XCOM 2's guerrilla-op reward (+$150 in the
    test) and plays XCOM 2's mission type. Long War's rewards per
    mission kind, and its maps and objectives per kind (abduction, crash
    site, landed UFO, terror), come with the missions feature.
  - The squad takes no time to fly out: the clock does not move while
    it is away.
