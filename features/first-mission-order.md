---
title: The base chosen before the first mission, as EW's
status: in-progress
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
