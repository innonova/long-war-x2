---
title: The base chosen before the first mission, as EW's
status: review
priority: 1
dependsOn: [strategy-flow, e2e-tests]
---

## The problem

EW (Long War, without the tutorial) has the player choose the base's place first and then sends the squad on the first
mission, an abduction in a city of the base's continent (`XGStrategyAI.CreateFirstMission`: `XGMission_Abduction`, the
city `Continent(HQ().GetContinent()).GetRandomCity()`, the squad `DetermineFirstMissionSquad`). The port starts XCOM 2's
campaign, whose first mission launches at once from the strategy map's start (`XGStrategy`, `Initing`), and shows Long
War's start screen (SELECT BASE LOCATION) only after it: the first mission's briefing names no country, its location
is XCOM 2's region text ("Wilderness of East Africa").

## The way

- **SELECT BASE LOCATION right after START GAME**, in the main menu's world, over EW's new-game screen
  (`UILWStartSelect` in the shell): EW's own screen, as now, the choice (home country and its starting bonus) kept; then
  the campaign starts as now (`UILWEWDifficulty.Start`).
- **The choice kept with the campaign** (a small state object made with the campaign's start state,
  `InstallNewCampaign`), so that a save during the first mission keeps it: Long War's campaign is made with it when the
  strategy layer first opens after the mission (`UILWStartSelect.OpenGeoscape`), and the start screen no longer comes then.
- **The first mission in the home continent:** a council country of that continent (EW's city, as near as Long War's
  countries go) named in the briefing as the location, Long War's abduction title for it.
- **Checked** by the first-mission journey: LONG WAR → START GAME → SELECT BASE LOCATION → Begin Game → the briefing with
  the country → the mission → the debrief → EW's base (no start screen after the mission).

## Report (2026-11-23)

- **Built:** START GAME on EW's new-game screen opens Long War's start screen (`UILWStartSelect.OpenInShell`) over EW's main
  menu room; Begin Game keeps the choice (`LWX2FirstMissionStart.StartHome/StartChoice`, config defaults across the map
  change) and starts the campaign (`UILWEWDifficulty.StartCampaign`, as before); Esc there goes back to the new-game
  screen. The campaign's start state takes it (`XComGameState_LWStartChoice`, with the first mission's country: a random
  council country of the home's continent). After the mission, the strategy layer's root makes Long War's campaign with
  that choice (`UILWStartSelect.OpenGeoscape`) and opens EW's base: no start screen then. Campaigns started without it
  (the control port's) keep the start screen after the mission.
- **The first mission's briefing:** the location is that country, the objective Long War's "Alien Abductions - <country>"
  (EW's words), the operation EW's name (`UILWDropShipBriefing.FirstMission`).
- **Checked on wingpu** (`first-mission` journey, by clicks): LONG WAR → START GAME → SELECT BASE LOCATION → Begin Game
  (Argentina) → briefing "Alien Abductions - Brazil", location Brazil → mission → debrief → EW's base, home Argentina
  (`lw bonuses`). Screenshots: `logs/e2e/first-mission/start-screen.png`, `briefing.png`.
- **Left:** the briefing's own text (EW's abduction briefing) is empty; the first mission is still XCOM 2's mission run
  on an EW abduction map (its squad Long War's first-mission squad), not a Long War abduction site with its rewards.
