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

## Step 2, read: EW's bomb disposal (2026-11-16)

EW's mission variants are streamed sub-levels of the map: `URB_CemeteryGrand_Bomb.upk` beside
`URB_CemeteryGrand.upk`, and `URB_PierA_Stream.upk` holding the Pier rescue's sequence
(`EscortVIP`, `RescuePierVIP_01`…, `ExtractionSuccess`, `ExtractionVIPDead`). Their rules are Kismet,
not script. They were read with a Kismet graph reader kept outside the repository (each op's class,
properties, output links and variable links, with the variables' names and values).

**The Grand Cemetery bomb** (`URB_CemeteryGrand_Bomb`, its Main_Sequence):
- `Timer` starts at 3. At each of XCOM's turn ends (`SeqEvent_OnPlayerEndingTurn`) it loses 1. At
  0 the bomb goes off: `Lost`, then `ReportToEvac`.
- There are 10 power nodes (`#Nodes`), each an interactive actor (`ARC_AlienEnergyNode_XLA`).
  Deactivating one gives the timer 1 turn back (`AddInt Timer +1`) and counts it
  (`DeactivatedNodes`). With all ten off, the mission goes to its next state.
- The bomb itself (`ARC_AlienBomb_XLA`) is disarmed by interacting with it (`BombDeactivated`).
  Then the remaining aliens are to be killed (`KillAliens`), and victory.
- The turn counter shows "turns remaining" against a maximum of 11.

**Next:**
- The other bomb levels' numbers.
- The node and bomb placements, read by the map converter.
- The rule as the mod's own: a node ability for a soldier beside one, the timer on XCOM 2's
  mission timer UI, defeat when it runs out.

## Step 2, the bomb disposal: done so far and the plan (2026-11-16)

**Done:** `tools/convert/ew-objectives.ts`, run by the setup, reads the five bomb disposals from the
player's EW into `Config/XComLWX2EWObjectives.ini` (generated, not in the repository or the
download). For each:
- its map;
- the Kismet `Timer` (3 on all five) and `#Nodes` (Grand Cemetery 10, Highway Bridge 9, Train
  Station 8, Trainyard 10, Slaughterhouse 8);
- the bomb's place (the high hot button) and each node's (the low ones), at EW's coordinates.

**Plan for the rule** (`LWX2CouncilBomb`, on a council bomb disposal on its EW map):
- **State:** a game state object with the nodes switched off and whether the bomb is disarmed.
- **Two abilities** for XCOM's soldiers on that mission: "Deactivate node" and "Disarm bomb",
  each one action, usable on a tile beside an active node or the bomb.
- **The timer:** Timer + nodes off − XCOM's turns ended, shown on XCOM 2's mission timer
  (`XComGameState_UITimer`, as `SeqAct_DisplayUISpecialMissionTimer` sets it). At 0 the bomb goes
  off and the mission is lost.
- **Victory:** the bomb disarmed and every alien dead or taken.
- **The objective list:** "Disarm the bomb (n turns); power nodes off: k of N".
- **Seen in the mission:** the bomb and nodes as EW drew them. The variant level is converted
  like a map, its pieces placed with the map's when the mission is a bomb disposal. Until then, a
  plain marker.

## Report (2026-11-16, step 2: the bomb disposal plays)

A council bomb disposal on its EW map now plays by EW's rule (`LWX2CouncilBomb`,
`XComGameState_LWX2Bomb`, `X2Ability_LWX2Bomb`):
- **The timer** is on XCOM 2's mission timer, "BOMB — turns remaining": the level's Timer, plus 1
  for each node switched off, less XCOM's turns ended. At 0 the mission is lost.
- **Two actions** for every soldier on the mission, one action each: "Deactivate node" and "Disarm
  bomb", usable from a tile beside an active node or the bomb (1.5 tiles, within two floors).
- **The objective list:** "Disarm the bomb (power nodes off: k of N, each a turn more)", then "Kill
  or capture every alien (the bomb is disarmed)".
- **Won** when the bomb is disarmed and every alien is dead or taken. Clearing the aliens alone
  does not win.

**Checked on wingpu** (EW maps on; the control port's `council now <id>`, the new `council` listing
of the bomb's and nodes' tiles, and `council disarm`):
- **Train Station** (8 nodes): the timer went 3 → 2 → 1 over XCOM's turn ends. A gunner beside
  node 0 used "Deactivate node": "1 of 8", timer 2. Left to run out: "the timer ran out, the
  mission is lost", and on the Geoscape "The council's bomb disposal in United States failed".
- **Trainyard** (10 nodes): every alien killed with the bomb not disarmed, and the mission went
  on. Disarmed, it was won, and "The council paid for the bomb disposal in United States: §208,
  panic −30".

**Not done yet:**
- **The bomb and nodes are not drawn.** EW's meshes are in the variant level, which is not
  converted, so a player finds them only through the control port or the objective text.
  Converting the variant level and placing its pieces is next.
- **The action's icons are XCOM 2's hack icons.** The actions have no names or texts of their own
  in the HUD yet.

## Report (2026-11-16, step 2: the bomb and nodes drawn, EW's words)

- **Drawn:** each bomb disposal's variant level (`URB_TrainStation_Stream` …) is converted with its map
  (`ew-objectives.ts` `VARIANT_LEVELS`, by the setup and `ew-maps.ts`), and a plot of the two is written,
  `LWX2V_<map>` (`ew-maps.ts` `writePlots`). A council bomb disposal plays on that plot when there is one
  (`UILWHeadquarters.UseEWPlot`, bVariant), so the bomb and the power nodes are part of the map from the
  start, with their collision and XCOM 2's tile data built over them. `LWX2EWMapPieces.MapName` and
  `OnOwnPlot` know the `LWX2V_` plots.
- **EW's words** (`lw-words.mjs` `makeBombWords`, from the player's EW `[XSpecialMissions]`): the objective
  "Approach and defuse the bomb. Deactivate power nodes to delay explosion. (k / N)", then "Kill any
  remaining aliens."; the timer's "Turns until bomb is fully charged"; the actions' help texts. The actions'
  names are the mod's ("Deactivate Power Node", "Defuse Bomb"), their icons XCOM 2's interact and hack.

**Checked on wingpu:** the Train Station bomb disposal on `LWX2V_URB_TrainStation`: the bomb stands on its
marker by the platform and the power nodes where EW put them; the objective and the timer in EW's words;
every soldier has both actions.

**Not done:**
- **A node switched off looks the same.** In EW the node is an interactive actor that powers down; here
  it is a mesh. The objective's count shows it.
- **The variant level's own aliens.** It has pods of its own (4 on the Train Station) and its Kismet
  drops reinforcements (Thin Men, `SeqAct_SpawnAlien`). The mission's aliens are still the
  abduction-style squad (the decision above).
- EW's "find the bomb before it reaches full power" phase (the countdown's first label) is played as the
  bomb being known from the start.

## Report (2026-11-16, step 2: the VIP extractions and rescues)

EW's VIP missions are streamed levels too (`URB_PierA_Stream`, `URB_StreetHurricane_Stream`,
`URB_HighwayFallen_Stream`, `URB_CommercialAlley_Stream`, `URB_ResearchOutpost_Rescue`). Their Kismet, read:
- `SeqAct_SpawnCivilian` puts the VIP at a spawn point and names them (`XComSetUnitName`).
- **An extraction** (Street Hurricane, Highway Fallen): the VIP waits, neutral ("Locate …", "Approach …"),
  until an XCOM soldier walks into the volume around them (`SeqEvent_Touch` → `SeqAct_SwapTeams` to XCOM).
- **A rescue** (Pier, Commercial Alley, Research Outpost): the VIP is XCOM's from the start, and on the Pier
  the squad lands beside them, at the far end of the map (the level's own drop zone).
- Then "Escort … to the Skyranger": an arrow to the Skyranger as the escort begins; the VIP killed loses
  the mission (`LoseBattle`). After the VIP is out: "Kill any remaining aliens", or "All soldiers report
  to the EVAC zone".
- Each also brings Thin Man reinforcements (`SeqAct_SpawnAlien`) as the squad crosses trigger volumes, and
  the extractions have bodyguards (1 HP civilians). Neither is in the port yet.

**Done:**
- `ew-objectives.ts` `readVIP` (with a small Kismet reader, `readKismet`: ops, output links, variable
  links) writes each VIP mission into `XComLWX2EWObjectives.ini` (`[LongWarX2.LWX2CouncilVIP] +VIPs=`): the
  VIP's place and name, where they are reached (none in a rescue), the Skyranger (the escort arrow's
  target) and EW's objective texts, all from the player's install.
- The variant levels are converted with their maps and joined into `LWX2V_<map>` plots as the bombs'
  are; a variant with its own drop zone (the Pier) lands the squad there.
- `LWX2CouncilVIP` (and `XComGameState_LWX2VIP`):
  - The VIP is XCOM 2's friendly VIP civilian (`FriendlyVIPCivilian`: evacuates, takes cover). Neutral in
    an extraction until a soldier comes within 4 tiles of EW's volume (`ApproachTiles`; the volume's own
    size is not read), then swapped to XCOM with XCOM 2's own team change (`XGBattle_SP.SwapTeams`).
    XCOM's from the start in a rescue.
  - **The Skyranger** is XCOM 2's evac zone, on the ground at the map's drop zone nearest EW's arrow (the
    arrow points at the Skyranger's roof).
  - The objective list follows EW's texts: "Locate …" until a soldier sees the VIP, "Approach …",
    "Escort … to the Skyranger.", then "Kill any remaining aliens. All soldiers report to the EVAC zone."
  - **Lost** if the VIP dies. **Won** once the VIP has evacuated and every alien is dead or taken, or every
    soldier still standing has evacuated too.
- A won mission with aliens still standing brings no loot from them (`PendingSurvivors`; until now every
  win had killed them all).
- Control port: `council` lists the VIP, where they are reached, the evac zone; `put <unit|#id> x y z`
  sets a unit on a tile; `spawns` lists the soldier spawns.

**Checked on wingpu:**
- **Highway Fallen** (extraction): "Locate General Van Doorn."; a soldier put beside him: he joined XCOM,
  "Escort General Van Doorn back to the Skyranger."; the evac zone at the squad's landing on the
  highway; he evacuated, "Kill any remaining aliens. All soldiers report to the EVAC zone."; the squad
  evacuated, the mission won with 0 of 12 aliens killed, and the council paid (§163, a soldier, 2
  scientists, panic −10).
- **Pier** (rescue): the squad landed at the pier's north end beside Sgt. Carlock, the evac zone at the
  south end; Carlock evacuated, the aliens killed, won and paid (§185, 4 scientists).
- **Street Hurricane** (extraction): Thomas Hutch waited, joined when reached.

**Not done:**
- **Street Hurricane's drop zone is boxed in.** XCOM 2 finds no open floor around EW's drop zone on this
  map (already seen on 2026-11-05: the squad is moved out of the pocket, 20 tiles away). The evac zone
  stands there too, where no one can reach it. That is the converted map's, to look into; until then this
  extraction cannot be finished.
- EW's Thin Man reinforcements and the bodyguards.
- Commercial Alley and the Research Outpost are read but their maps are not converted here (step 1).
