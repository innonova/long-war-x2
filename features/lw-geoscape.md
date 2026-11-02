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
- **A terror mission won** now moves panic by the civilians lost, as Long
  War does (`lw-missions.md`, 2026-11-02). One won without playing it
  (WIN, resolve) still changes none.
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

## Report (2026-11-01, the person's first try; the control port)

What the person saw on their machine, and what changed:

- **Money is written §** (Long War's sign, and XCOM 2's too), through
  `LWStrategyRules.Money`, which writes the sign with `Chr(167)` so the
  source stays ASCII.
- **"Cash stays at 175"**: I could not reproduce it.
  - An ordinary new campaign on wingpu (Gatecrasher won, then the
    Geoscape) gives §500 in the Geoscape and on the Avenger's resource
    bar.
  - The bar did not refresh until something else changed it; it now
    refreshes when the Geoscape opens.
  - The bar also shows XCOM 2's own "INCOME (+§175)" and its supply drop
    countdown. **XCOM 2's economy still runs beside Long War's council
    funding.** It has to go when the strategy layer is replaced (next
    under the Geoscape), and is the likely source of the 175.
- **WIN THIS MISSION** (the person's request): the button that ends a
  campaign mission as won is in the player's build now (it was
  development only), so the strategy layer can be tried without playing
  every mission. It marks the mission's objectives done first, since XCOM
  2 judges a mission by them.
- **The control port** (`LWX2Control`, development builds only): the game
  driven from here without the mouse. It covers the Geoscape's state,
  running time, taking decisions, interception results, satellites,
  winning a mission and console commands, and the whole game state as a
  text file to grep (`tools/test/lw-dump.sh`: about a thousand objects,
  every field). See `tools/test/README.md`. Gatecrasher was won with one
  command, `win`.

### Decisions

- **The control port is TCP** (`TcpLink`, which the game ships in
  IpDrv), bound only in development builds. A text protocol (a command a
  line, the answer ending with `.`) is driven by a PowerShell client over
  ssh, the same way as the other test tools.
- **The dump is every game state object's `ToString(true)`**, XCOM 2's
  own full printout, rather than a format of ours, so nothing is left out.

## Report (2026-11-01, the Geoscape is the strategy layer; simulating campaigns)

**XCOM 2's strategy clock is gone; Long War's runs everything.**

- **XCOM 2's world map is replaced** (`UIScreenListener_LWX2StrategyMap`,
  switch `ReplaceStrategyMap`, on in both builds).
  - XCOM 2's whole strategy clock runs only while its world map is open:
    dark events, supply drops, the Avatar project, its missions, and also
    healing and building.
  - Whatever opens the map (the Avenger's globe button, the bridge) now
    sees it paused, closed the way its back button closes it, and Long
    War's Geoscape opened instead. Tested with the globe button.
- **XCOM 2's clock follows Long War's** (`XCom2TimePasses`). The hours the
  Geoscape runs move XCOM 2's date too, and its headquarters projects
  complete when due, as its world map would complete them. Nothing else
  of its tick runs. Tested:
  - a soldier wounded in the skipped first mission was healed on XCOM
    2's due date (HP 5 of 5);
  - XCOM 2's "soldier recovered" notice came through.
- **Missions pay no XCOM 2 reward.** It stays XCOM 2's supplies reward,
  with the amount set to 0: `Reward_None` has no mission family, and the
  mission then never started. Tested: the money stayed at §500 through a
  won abduction mission. Long War's rewards by mission kind come with the
  missions.
- **Long War's lose condition** (`XGStrategy.CheckForLoseGame`): when
  `LoseCountries` have left, the campaign is lost and XCOM 2's DEFEAT
  screen shows (tested).
  - The number is generated from Long War's package
    (`LOSE_CONDITION_NUM_DESERTERS`), and it is **16**: Long War loses
    only when the whole council has gone. I believe it was 8 in vanilla,
    but have not checked; the person can confirm from memory.

**Simulating the strategy layer at full speed** (the person's request),
through the control port:

- `resolve <decision> won|lost` takes one decision without playing it:
  - an interception is fought by the air war's own rules (`LWAirWar.Fight`)
    with the healthiest jet, and the result is recorded for the jet and the
    Geoscape;
  - a mission is sent and comes back with the result given.
- `auto <hours> <mission win %> [stance] [sats]` runs time and takes
  every decision as it comes, and with `sats` buys satellites and launches
  them over the most panicked country. Three months: 27 decisions, about
  a second.
- What the first runs show:
  - **jets are never repaired or replaced**: after a few fights they are
    at negative HP and nothing can intercept from then on (Long War
    repairs them over days: the hangar, still to come);
  - an Interceptor is sent at a Terror Ship, as the player could.

**Test tools:**

- `continue` launches the Skyranger itself, by setting what its "press
  any key" sets.
- It passes only screens it knows, and leaves unknown screens alone: a
  blind Enter press confirmed a soldier bond once.

### Decisions

- **The world map is closed when it opens, rather than overriding XCOM
  2's presentation layer** (a class override). That route is smaller,
  and the camera's trip to the map and back is the only cost. If it shows
  in play, the override is the next step.
- **XCOM 2's research still completes on XCOM 2's rules** until Long
  War's research replaces it (the next feature).

### Left open

- XCOM 2's resource bar still shows its income (+§175) and supply-drop
  countdown. Neither is ever paid now; they go when the Avenger's HUD
  does.
- XCOM 2's objectives and narrative still point at its world map.
- Jet repair and replacement, and jets based per continent.

## Report (2026-11-02 night, the screen's layout)

- The HANGAR, BASE and ENGINEERING buttons covered each other
  ("NGINEERING"), and the time buttons touched; they are spaced now.
- The first day's events read "Long War's first mission:" with nothing
  after it: the heading was noted before the loot, and the events show the
  newest first. It now comes after the loot's note and says what it is:
  "Long War's first mission, won before the campaign began, brought back
  what its aliens left:", above "The aliens killed (10) left: …".
- Checked on the screen.
