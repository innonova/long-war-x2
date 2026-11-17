---
title: "EXALT: the cells, their operations, scans, covert operatives, clues and the raid on EXALT's base"
status: review
priority: 35
dependsOn:
  - lw-geoscape
  - lw-missions
---

## Purpose

Enemy Within's human enemy, kept by Long War: EXALT cells hide in council countries and steal
money, raise panic and set research back, until XCOM scans for them, sends a covert operative in,
fights the extraction, and gathers enough intelligence to accuse the right country and raid
EXALT's base. The port has none of it (STATUS: EXALT, none).

## Long War's rules, as read (2026-11-16)

From stock Long War's `XGExaltSimulation` (its functions and defaults), `XGStrategyAI`'s EXALT
missions and squads (read with the Tree's `upk_script.py` and upkit's `class`; the decompiled
code stays out of the repository). Numbers by difficulty (Long War's Normal, Classic, Brutal,
Impossible).

**When.** The simulation begins in the third month (`AI().GetMonth() > 1`; Long War counts the months passed, 0 in the first): EXALT's country is
a random council country, its clues are chosen, and after 18 + 0..6 days (Brutal and
Impossible 15 + 0..9) two cells are placed and the first acts at once. Then a day passes every
48 half-hours of Geoscape time (not while the Geoscape is busy or on pay day).

**Cells.** One per country, at most 10. A new one is tried every 7–10 days (Classic 7–11,
Brutal 6–10, Impossible 6–9): a council country without a cell is picked with chance by its
score, then placed with chance 0.9 (Classic 1.0), less 0.2 with a satellite over it (0.35 with
the Foundry's Stealth Satellites). The score:
- by its panic, in fifths of 0–100 (the fifth step from 80 up): Normal 0.0, 0.1, 0.2, 0.2, 0.1, rising toward
  the higher steps on the harder difficulties (each difficulty's list is in the generated config);
- +0.1 (Brutal +0.2) if no cell is on its continent;
- −0.3 if its whole continent has left XCOM; else nothing more if it left itself; else −0.1 if it
  is its continent's only one left in XCOM;
- −0.3 (Classic and up −0.1) with a satellite over it; +0.2 if it is the only one on its
  continent without one where the continent has a single satellite;
- −0.1 on XCOM's home continent (not on Impossible).

**Operations.** Each hidden cell acts every 7–21 days (Brutal and Impossible 7–15), and only
when no cell has acted for more than 5 days (Classic 5, Brutal 4, Impossible 3). It picks at
random among what it can do:
- **sabotage** (XCOM has money): steals 40 × the month + 0..99 (Long War's own line, in place
  of EW's share of XCOM's money);
- **propaganda** (the country is still in XCOM): +40 panic there, +20 in another council country
  of its continent still in XCOM;
- **research hack** (the current research is more than 30% done; Classic 50%): sets it back the
  larger of 30% (50%) of its estimate and 5 days, at most what has been done, less a fifth per
  laboratory.
A cell with nothing it can do moves (to a new country, placed at once). Acting **exposes** the
cell for 4–7 days (Classic and up 2–5).

**Panic.** While EXALT is active and no operative is in the field, panic rising in a country rises
up to 10 more when a hidden cell is on its continent (each such cell, a coin flip).

**Scans.** XCOM scans for EXALT (once a day at most, and only after a day has passed): every
cell is exposed. §50, then 50% more each time in the month (Classic and up 100% more), the count
back to zero on pay day; less by the country bonus that says so (`HasBonus(16)`).

**Covert operatives.** A soldier sent into a country with a cell (exposed: the Situation Room
shows those) is away 6 days, without their gear. Then a mission comes in that country (96 hours
to answer): extraction or data recovery (the first of each, then at random). Not answered, the
operative is lost (to the memorial). Won: the cell is cleared and the country loses 20 panic, and
the other exposed cells move; lost: the cell moves. The operative comes back. The missions'
squads are EXALT's (`DetermineCovertOpsSquad`: by how many such missions were fought, EXALT
operatives, snipers, heavies, medics and their elites, a commander).

**Clues.** Long War's clue definitions (28: "not in <country>", "not in Asia", "not in an
English speaking country" …), chosen at the start so each rules out more of the remaining
council countries, weighted toward those ruling out many, until one country is left. XCOM holds
as many as it has EXALT intelligence (item 181) from covert missions.

**Accusation.** XCOM accuses a council country once: right, the raid on EXALT's base is the next
mission there; wrong, the country leaves XCOM (if it had already left, its continent's council
countries +40 panic). The raid won ends EXALT; lost, EXALT's country leaves XCOM (or its
neighbours +40 panic).

## Plan

1. **The simulation** (`LWExalt`, its state on `XComGameState_LWStrategy`): begin, cells,
   operations, exposure, scans, the panic addition, clues and accusations, run by the Long War
   Geoscape's clock; each event in the Geoscape's log; Long War's numbers in the generated config
   (read from the class defaults by the config generator). Control-port aids to see and drive it.
2. **The Situation Room's EXALT** on EW's own screen: the scan (its cost), cells on the map,
   the clues, accusing a country.
3. **Covert operatives and their missions**: a soldier sent and away, the mission after six days
   with the operative in the squad, EXALT's squads as Long War gives them, the outcome.
4. **The raid on EXALT's base.**

## Report (2026-11-16, phase 1: the simulation)

`LWExalt` runs Long War's `XGExaltSimulation` on the Long War Geoscape, its state on
`XComGameState_LWStrategy` (`Exalt*`), each hour from the strategy clock (a day every 24 hours):
- begun in the third month: EXALT's base in a council country, its clues chosen
  (`SelectClues`, weighted as Long War weighs them), its first two cells after the start delay,
  the first acting at once;
- cells placed by Long War's score and dice (panic, cells and departures on the continent,
  satellites, the home continent, Stealth Satellites), at most 10;
- operations every 7–21 days (by difficulty), no sooner than the gap between any two:
  sabotage (40 × the month + 0..99), propaganda (+40 panic, +20 in a neighbour), research hack
  (XCOM 2's project set back by Long War's share or days, less a fifth per laboratory); a cell with
  nothing to do moves; acting exposes it for some days, then it hides again;
- the panic addition inside every panic rise (`AddPanic`, as Long War's `XGCountry.AddPanic`);
- scans (`LWExalt.Sweep`): every cell exposed, Long War's cost rising through the month (reset on
  pay day), the country bonus' cut; one a day;
- clue bookkeeping (the clues held: as many as XCOM's EXALT intelligence).
Each event is a line in the Geoscape's log.

Long War's numbers by difficulty and its 28 clues are generated from the package's defaults
(`scripts/strategy-config.mjs`, `exaltRules`: upkit's `class XGExaltSimulation`, its
`defaultproperties` parsed) into `[LongWarX2.LWExalt]`.

**Checked on wingpu** (control port, a new campaign, EXALT begun by the aid): base in Argentina,
cells in Japan and the United Kingdom, Japan's sabotage (§68) exposing it for 4 days; in another,
base in the United States, nine clues each ruling out more of the council, propaganda in China
raising panic there and in Australia, a cell placed in Canada 9 days later, sabotage §88, China's
cell hiding again after its days.

Control port: `exalt` (state, cells, clues, last events), `exalt begin|place|act <country>|intel
<n>` (test aids), `exalt sweep`.

### Found on the way

- Long War's `XGCountry.AddPanic` also halves a rise with a chance by the country (its `iScience`);
  the port's `AddPanic` does not. No script writes `iScience` (it is only read: here, by the funding
  council's rewards and the hunts), so its values are set natively and are not known; left out
  until they can be read.

### Left open

- Phase 2 (the Situation Room's EXALT on EW's screen), phase 3 (covert operatives and their
  missions; until then no intelligence and no clues held), phase 4 (the raid).

## Report (2026-11-16, phase 2: EXALT in the Situation Room)

The hub's Situation Room has an **EXALT** option once EXALT is active: EW's Situation Room in its
covert operations mode (`UILWEWSituationRoom`, `bCovert`), filled as Long War's
`InfiltratorState` fills it (`SetDisplayMode` 1, `SetCountryInfoInfiltrator`):
- each council country: its exposed cell (EW's EXALT emblem), "cleared by intel" where the clues
  held rule it out (or it was accused), EXALT's base marker once accused rightly; the countries
  gone in EW's red;
- the exposed cells on the map (EW's `_cell` markers) beside XCOM's headquarters;
- **Intel Scan**: EW's words and Long War's cost on a button under the map ("INTEL SCAN - Cost:
  §50"; "Global intel up to date" once today's is spent, "Insufficient cash to sweep"), then EW's
  confirmation ("CONFIRM INTEL SCAN … INITIATE SCAN");
- a country clicked: **the accusation** where Long War allows it (three clues held, not ruled out,
  not accused before), after EW's warning ("ATTEMPT RAID ON EXALT HQ"). Wrong: the country
  withdraws (gone already: its continent +40 panic); right: the base is marked, the raid next.

The words are Long War's from the player's install (`lw-words.mjs`, `makeExaltWords`: 26 for the
screen, the 28 clue texts for `LWExalt`).

**Checked on wingpu** by mouse (EXALT begun and three clues given by the aids): a scan for §50
exposing a hidden cell in Nigeria (`logs/wingpu_exalt_scan.png`); Canada accused wrongly and
withdrawn; Nigeria, the base, accused and marked (`logs/wingpu_exalt_accused.png`).

### Decisions

- **The Intel Scan is an XCOM 2 button in EW's words**, under the map: EW's own scan panel stands
  where this port's right-hand country list is, and its intro tween never runs in XCOM 2's Flash
  (it stays at a third of its width). The cost text EW draws is hidden with it.
- **The accusation asks through XCOM 2's dialog** (EW's accuse button is on its Situation Room
  HUD movie, not used here); the rows are hit-tested, as EW's rows raise no clicks here.

### Found on the way

- On EW screens the map area (with the earth) sits above the timeline's own panels: anything EW
  draws under it must be raised (the scan panel was).

## Report (2026-11-16, phase 3: covert operatives and their missions)

- **Sending one** (EXALT's view in the Situation Room): a country with an exposed cell clicked,
  nobody in the field → XCOM 2's soldier list of those Long War allows (`UIPersonnel_LWCovert`,
  `LWExalt.CanBeOperative`: no Gunners or Rocketeers, no rookies, ready, rested, not training) →
  EW's words ("COVERT OPERATION — <soldier> - <country>") → sent (`SendOperative`): XCOM 2's
  covert-action status (away, out of squads), their gear released for others; EW's "operative in
  the field" emblem on the country.
- **Six days later** (Long War's `NextDayForOperative`): "ready for extraction", the clock stops,
  and a decision on the Geoscape: "COVERT OPERATION: extraction in <country> (96h)"
  (decision 9, mission kind 8). Not answered in time: the operative is lost to the memorial
  (Long War's `OnMissionExpire`).
- **The mission**: the operative first in the squad, on duty with their gear back; EXALT's squad
  from Long War's covert table by the missions of the kind fought (`CovertSquad`, generated from
  `DetermineCovertOpsSquad`: 54 pods), EXALT's soldiers standing in as ADVENT's (the elites as
  their third tier); XCOM 2's guerrilla op as the mission.
- **Back** (Long War's `PostCombat`): won, the cell cleared (the other exposed cells move), the
  country 20 panic less, one EXALT intelligence (a clue held); lost, the cell moves; the operative
  back on duty either way.

**Checked on wingpu** (control port aids): an operative sent into France; the extraction after
six days; the mission with the operative first and EXALT's first-table squad (8 soldiers in
three pods, Long War's stats); won; back through the hub: France's cell gone, intel 1, one covert
mission counted, the soldier back. An earlier run let the 96 hours pass: "the extraction … went
unanswered: … is lost".

**Fixed on the way:** a mission's result (and Long War's wounds and fatigue after it) was only
applied when the Geoscape panel opened, not the hub, which is the strategy layer's root now: both
call `XComGameState_LWStrategy.Arrived`.

### Decisions

- **The operative goes with their own gear**: Long War sends them with what was backed up; the
  gear is released while they are away and put back for the mission.
- **The mission is XCOM 2's guerrilla op** with EXALT's squad, until Long War's extraction and
  data-recovery objectives exist (STATUS: Missions, "Long War's objectives per kind").

### Left open

- Phase 4 (the raid on EXALT's base, after the right accusation).
- The extraction's own objectives (rendezvous, hack two comm relays) and the data recovery's.

## Report (2026-11-16, phase 4: the raid on EXALT's base)

- The right accusation marks the base and stops the clock; the Geoscape then offers "ASSAULT:
  EXALT's base in <country>" (decision 10, mission kind 9) until the raid is won.
- **The squad** is Long War's `DetermineExaltRaidSquad`, generated like the covert one: four pods of
  EXALT's elites (each kind six strong), two pods of its soldiers, a Muton Elite and a Sectoid
  Commander's pod (about 33; Long War's pod builder rolls).
- **Back**: won, EXALT is finished (no more cells, scans or decisions); lost, EXALT's country
  withdraws from XCOM (gone already: its continent +40 panic), and the raid stays open.

**Checked on wingpu** (the accusation by the aid): the raid in Mexico, 30 of EXALT's soldiers on
the field (15 through XCOM 2's encounters, 15 beside them), won; back through the hub, EXALT
finished.

**Also:** backing out of the extraction's squad select puts the operative back in the field (away,
gear released) with the extraction still offered (checked).

**Fixed on the way:** XCOM 2's spawner crashed when an encounter was given 9 or more aliens (the
raid's 33 shared over four): each encounter now gets at most 5 (`LWMissionSquads.MaxEncounterPod`),
the rest come beside them at the battle's start, as those whose pods found no room already did.

### Left open

- The covert missions' and the raid's own objectives and maps (EW's EXALT HQ is a skyscraper):
  XCOM 2's guerrilla ops stand in.
- EXALT's soldiers stand in as ADVENT's (their bodies are not EW's EXALT yet).

## Report (2026-11-16, step 3 of the council missions' plan: EXALT's covert extraction)

Long War's covert extraction, read from its `XComGame.upk` (`XGBattle_SPCovertOpsExtraction`,
`XComRadarArrayActor`) and the `_CovExt` levels' Kismet:
- **Its maps**: Long War's `DefaultMaps.ini` lists 8 in rotation (`eMission_CovertOpsExtraction`), each with
  its streamed `_CovExt` level. `maps-config.mjs` now writes them (`Kind=CovertExtraction`, `Level=`), and the
  10 data recovery maps (`Kind=DataRecovery`, the `_CNH` levels) for the next step. The converter and the setup
  convert each level with its map into a `LWX2V_<level>` plot, as the council's.
- **The operative** starts at the level's own covert-operative spawn point, apart from the squad
  (`SpawnCovertOperative`).
- **The comm relays**: each level has four (its `XComRadarArrayActor`s); the battle activates two at random
  (`InitRadarArrays`). Only the operative can hack one, from beside it, one a turn (`CanInteract`:
  `m_bCovertHackerThisTurn`): `LWX2_HackRelay`, one action.
- **Then** "Escort the operative to the EVAC zone." (XCOM 2's evac zone at the Skyranger, from the start, as EW's
  dropship volume is), and "Eliminate remaining EXALT forces, or get to the EVAC zone.". The operative killed
  loses the mission; the squad leaving without both relays hacked and the operative out loses it too.
- **Paid**: Long War's §200 (`m_iCovertOpsCashRewardAmount`, read by `strategy-config.mjs` from Long War's
  XComGame.upk as `CovertCash`), on top of the cell cleared, the panic and the intel.
- EW's texts from the level's Kismet ("The covert operative must hack the EXALT comm relays.", "EXALT Comm Relays
  left to hack: 2", …).

**Checked on wingpu** (`exalt begin`, `exalt sweep`, `exalt send`, `run 24` to the extraction, then `put`, `use`,
and the new `evac` and `crew list` aids): on the Convenience Store, relays 3 and 0 active; the operative at
their spawn, the squad at the Skyranger in the evac zone; relay 3 hacked, relay 0 then out of reach the same
turn; hacked the next turn: "Escort the operative to the EVAC zone."; the operative and the squad evacuated:
won, "The covert operation in China succeeded …", "The extraction brought §200 home.". An earlier run on the
Trainyard placed the operative and took both relays the same way.

**Not done:**
- **The relays are not drawn.** Their mesh is XCOM's hot button column (`HotButton.Meshes.HotButtonColumnLow`, a
  class default of `XComRadarArrayActor`), which is not in the level's package; where the player's EW keeps it is
  not found yet. The objective text and the action are the way to them for now.
- A hack's effect on EXALT: EW blinds and disables the EXALT soldiers already fighting for a turn and holds the
  pods still (`OnExaltHackingArrayInteraction`). Not yet.
- The Kismet's reinforcements as the operative nears each relay, and the wave spawner.

## Report (2026-11-16, EXALT's data recovery)

Long War's capture and hold (`XGBattle_SPCaptureAndHold`, `XComCapturePointVolume`, `XComWaveSystem`,
`XGOvermind.DetermineCaptureAndHoldTactics`) and the `_CNH` levels:
- **Which mission**: Long War's `CreateNextMission`: the kind not offered yet, else either at even odds. The
  decision now reads "COVERT OPERATION: extraction / data recovery in <country>".
- **Its maps**: the 10 in rotation, each with its `_CNH` level, converted into `LWX2V_<level>` plots.
- **The capture areas** (`ew-objectives.ts readRecovery`): each volume's box, its turns (`m_iTurnsToCapture`, 3 or
  EW's default 2) and its order (the transmitter, then the backup relay). At each new XCOM turn, an area with EXALT
  and no soldier in it goes a turn on; at its turns it falls. The transmitter fallen, the backup is next; both
  fallen, the mission is lost.
- **EXALT's waves** (the level's wave system): each group's turn after its set begins, its count and its spawn
  points (14 groups on most maps; the second set begins as the transmitter falls). The soldiers are of the
  mission's own EXALT kinds. EXALT then makes for the active area (XCOM 2's map-wide alert at the area's floor,
  as EW's hunt target there).
- **Won** once every wave of the first set has come and every EXALT soldier is dead or taken: "Eliminate all
  EXALT forces.". Long War's §120 (`m_iAllPointsSafeCashRewardAmount`) when the transmitter held.
- EW's texts from the Kismet: "Protect the capture area. (k / 3)", "Protect the backup capture area.", "Eliminate
  all EXALT forces.".

**Checked on wingpu** (Industrial Office, `ForceMap` on the test machine): **lost**: the waves came on turns 3, 5
and 7, EXALT went for the transmitter, held it 3 turns ("area 0 fell"), then the backup, "every area fell, the
mission is lost", and on the Geoscape the cell moved and the operation failed. **Won**: two soldiers held the
transmitter (no capture while they stood in it), all first-set waves came, the rest killed: "The covert
operation in Russia succeeded …", "The data recovery brought §120 home.".

**Not done:**
- **Commercial Restaurant's first area is a roof deck with no floor** in the converted map: units cannot stand
  there, so EXALT cannot take it and XCOM cannot hold it. Converter 19 lets wide breakable pieces be stood on, but
  XCOM 2 still makes no floor tile on this deck; to look into (`lw-missions.md`).
- The capture areas are not marked on the map (EW drew their border); the objective's count is the only sign.
- The covert extraction's and the data recovery's reinforcement drops tied to Kismet events (the relays'
  proximity) are not in.

## Report (2026-11-17, the raid on EW's own map)

The raid now plays on EW's `EWI_ExaltHQAssault` (at night) instead of an XCOM 2 guerrilla plot; how is in
`lw-story.md`'s report of the same date. Checked on wingpu: the raid chose that map and EXALT's squad spawned at its
pods. Its objective is still "kill all"; EW's level has its own scripted waves, not read yet.
