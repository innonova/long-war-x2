// A Long War headquarters screen in place of XCOM 2's base and Geoscape (features/hard-parts.md,
// experiment 4): can a strategy layer of our own send a squad on a mission and take the result
// back? It shows the campaign's date, its soldiers, the last mission's outcome, and launches a
// mission with the first four soldiers able to go, through XCOM 2's own mission path (a mission
// site, PrepareTacticalBattle, LaunchTacticalBattle), skipping its Geoscape, squad select and
// Skyranger; and opens the air war (experiment 3) with the campaign's jets.
class UILWHeadquarters extends UIScreen config(LWAirWar);

/** The mission being launched, and the pause before its map loads (OnLaunch). */
var int PendingLaunch;
var config float LaunchDelay;
/** For the load-crash test: a narrative voice started as the mission launches, and left playing. */
var config bool TestVoiceAtLaunch;
/** The plot and biome of a mission on an Enemy Within map (UseEWPlot). */
var config string EWPlot;
var config string EWBiome;
var config string EWMission;
/** For development: every Long War mission played as this kind (1 crash site, 2 landed UFO, 3 abduction, 4 terror; 0: its own). */
var config int ForceKind;

var UIText Title, Info, Squad, Last;
var UIButton LaunchButton, AirWarButton, AvengerButton;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	Spawn(class'UIBGBox', self).InitBG('LWHQBg', 360, 120, 1200, 840);
	Title = Spawn(class'UIText', self).InitText('LWHQTitle', "LONG WAR: HEADQUARTERS (EXPERIMENT 4)", true);
	Title.SetPosition(390, 140);
	Title.SetWidth(1100);
	Info = Spawn(class'UIText', self).InitText('LWHQInfo', "");
	Info.SetPosition(390, 210);
	Info.SetSize(1140, 60);
	Last = Spawn(class'UIText', self).InitText('LWHQLast', "");
	Last.SetPosition(390, 280);
	Last.SetSize(1140, 120);
	Squad = Spawn(class'UIText', self).InitText('LWHQSquad', "");
	Squad.SetPosition(390, 420);
	Squad.SetSize(1140, 380);
	LaunchButton = Spawn(class'UIButton', self).InitButton('LWHQLaunch', "LAUNCH MISSION", OnLaunch);
	LaunchButton.SetPosition(390, 880);
	AirWarButton = Spawn(class'UIButton', self).InitButton('LWHQAirWar', "AIR WAR", OnAirWar);
	AirWarButton.SetPosition(640, 880);
	AvengerButton = Spawn(class'UIButton', self).InitButton('LWHQAvenger', "CLOSE", OnAvenger);
	AvengerButton.SetPosition(840, 880);
	Refresh();
}

function Refresh()
{
	local XComGameStateHistory History;
	local XComGameState_GameTime Time;
	local XComGameState_BattleData Battle;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Unit Unit;
	local string S;

	History = `XCOMHISTORY;
	Time = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	Soldiers = ReadySoldiers(99);
	Info.SetText("Date:" @ class'X2StrategyGameRulesetDataStructures'.static.GetDateString(Time.CurrentTime) $ "    Soldiers able to go:" @ Soldiers.Length);
	Battle = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	if (Battle != none && Battle.m_strOpName != "")
		Last.SetText("Last mission:" @ Battle.m_strOpName @ "(" $ Battle.m_strDesc $ "," @ Battle.MapData.PlotMapName $ "):" @ (Battle.bLocalPlayerWon ? "WON" : "LOST"));
	else
		Last.SetText("Last mission: none yet");
	S = "Squad for the next mission:\n";
	Soldiers = ReadySoldiers(SquadSize());
	foreach Soldiers(Unit)
		S $= Unit.GetName(eNameType_RankFull) @ "-" @ Unit.GetSoldierClassTemplate().DisplayName @ "-" @ Unit.GetNumMissions() @ "missions," @ Unit.GetNumKills() @ "kills\n";
	Squad.SetText(S);
}

/** Long War's squad: its Skyranger's capacity (4 if the config is from before it was generated) and the squad sizes bought. */
static function int SquadSize()
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	return (class'LWStrategyRules'.default.SkyrangerCapacity > 0 ? class'LWStrategyRules'.default.SkyrangerCapacity : 4) + (S != none ? S.SquadSizesBought : 0);
}

/** XCOM 2's mission source for a Long War mission kind (XComGameState_LWStrategy.PendingKind). */
static function name SourceForKind(int Kind)
{
	switch (Kind)
	{
	case 1: // crash site
	case 2: // landed UFO
		return 'MissionSource_LandedUFO';
	case 4: // terror site
		return 'MissionSource_Retaliation';
	}
	return 'MissionSource_GuerillaOp';
}

/** The first soldiers able to go on a mission. */
function array<XComGameState_Unit> ReadySoldiers(int Max)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference Ref;
	local XComGameState_Unit Unit;
	local array<XComGameState_Unit> Out;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		// Not those in psi training (features/lw-psi.md).
		if (Unit != none && Unit.IsSoldier() && Unit.CanGoOnMission() && Out.Length < Max
			&& (class'XComGameState_LWStrategy'.static.Get() == none || !class'XComGameState_LWStrategy'.static.Get().InPsiTraining(Unit.ObjectID)))
			Out.AddItem(Unit);
	}
	return Out;
}

function OnLaunch(UIButton Button)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_MissionSite Mission;
	local XComGameState_WorldRegion Region;
	local XComGameState_Reward Reward;
	local array<XComGameState_Reward> Rewards;
	local X2StrategyElementTemplateManager Strategy;
	local X2RewardTemplate RewardTemplate;
	local name Source;
	local int Kind;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Unit Unit;
	local XGStrategy Game;
	local int Attempt;
	local Vector2D Where;
	local XComGameState_LWStrategy LW;
	local string EWMap;

	Soldiers = ReadySoldiers(SquadSize());
	if (Soldiers.Length == 0)
		return;
	History = `XCOMHISTORY;
	Strategy = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	Region = XComGameState_WorldRegion(History.GetGameStateForObjectID(XComHQ.StartingRegion.ObjectID));
	Where = Region.GetRandom2DLocationInRegion();
	Kind = class'XComGameState_LWStrategy'.static.Get() != none ? class'XComGameState_LWStrategy'.static.Get().PendingKind : 0;
	if (ForceKind > 0 && Kind != 0)
		Kind = ForceKind;
	// Enemy Within's map for it, when the switch is on and this machine has one converted for the kind (and ship).
	if (class'UIScreenListener_LongWarX2Tactical'.default.PlaceEWMapWhole && Kind != 0)
	{
		LW = class'XComGameState_LWStrategy'.static.Get();
		EWMap = class'LWX2EWMapPieces'.static.ChooseMap(class'LWX2EWMapPieces'.static.KindFor(Kind), (Kind <= 2 && LW.PendingIndex < LW.Ufos.Length) ? LW.Ufos[LW.PendingIndex].Ufo : 0);
		`log("LongWarX2: Long War HQ: EW map for kind" @ Kind $ ":" @ (EWMap != "" ? EWMap : "none converted, XCOM 2's plot"), , 'LongWarX2');
	}
	if (EWMap != "")
		DaylightRegion(Region, Where);

	// A mission site, as XCOM 2's calendar makes a guerrilla op; and the squad. With the EW map,
	// made again (up to eight times) until its mission can be played on an outdoor plot.
	for (Attempt = 0; Attempt < 8; Attempt++)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("LongWarX2: a mission from the Long War headquarters");
		// XCOM 2's mission for Long War's kind (lw-missions.md): a crash site or landed UFO is XCOM 2's
		// landed UFO, a terror site its retaliation (its civilians), the rest a guerrilla op. The reward is
		// what XCOM 2 pairs with the source, with nothing in it: Long War's missions pay their own. (A
		// guerrilla op with Reward_None has no mission family, and the mission then never starts.)
		Source = SourceForKind(Kind);
		RewardTemplate = X2RewardTemplate(Strategy.FindStrategyElementTemplate(Source == 'MissionSource_GuerillaOp' ? 'Reward_Supplies' : 'Reward_None'));
		Reward = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		Reward.GenerateReward(NewGameState, ResHQ.GetMissionResourceRewardScalar(Reward), Region.GetReference());
		Reward.Quantity = 0;
		Rewards.Length = 0;
		Rewards.AddItem(Reward);
		Mission = XComGameState_MissionSite(NewGameState.CreateNewStateObject(class'XComGameState_MissionSite'));
		// Long War has no sitreps and no Chosen: none from the mission source, and (below) none forced by the plot
		// and none of the tags that bring the Chosen or a sitrep's units.
		Mission.bForceNoSitRep = true;
		// Not War of the Chosen's own retaliation, which brings the Chosen.
		Mission.ExcludeMissionFamilies.AddItem("ChosenRetaliation");
		Mission.BuildMission(X2MissionSourceTemplate(Strategy.FindStrategyElementTemplate(Source)), Where, Region.GetReference(), Rewards, true, false);
		Mission.GeneratedMission.SitReps.Length = 0;
		Mission.TacticalGameplayTags.Length = 0;
		if (EWMap == "" || UseEWPlot(Mission, true, EWMap) || PreferOutdoorPlot(Mission) || Attempt == 7)
			break;
		History.CleanupPendingGameState(NewGameState);
	}
	// A mission of the Long War Geoscape: fought against Long War's squad for it (LWMissionSquads).
	if (class'XComGameState_LWStrategy'.static.Get() != none && class'XComGameState_LWStrategy'.static.Get().PendingKind != 0)
	{
		LW = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
		LW.PendingSquad = LW.MissionSquad();
		LW.PendingEWMap = EWMap;
		class'LWMissionSquads'.static.ApplyTo(Mission, LW.PendingSquad);
	}
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.Squad.Length = 0;
	foreach Soldiers(Unit)
		XComHQ.Squad.AddItem(Unit.GetReference());
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("LongWarX2: Long War HQ: launching" @ Mission.GeneratedMission.Mission.sType @ "on" @ Mission.GeneratedMission.Plot.MapName @ "with" @ Soldiers.Length @ "soldiers", , 'LongWarX2');

	if (class'XComGameState_LWStrategy'.static.Get() != none && class'XComGameState_LWStrategy'.static.Get().PendingKind != 0)
		class'XComGameState_LWStrategy'.static.MissionLaunched(Mission.ObjectID);
	Game = `GAME;
	Game.PrepareTacticalBattle(Mission.ObjectID);
	// The map is loaded a moment later, not in this frame (lw-missions.md, the load crash): XCOM 2 died now and then in
	// LoadMap, on Wwise's thread, in a sound's duration callback that reached for the world while it was being torn down.
	// A sound posted as the launch begins (its narrative voices load here) has its callback by then; voices are stopped.
	if (TestVoiceAtLaunch)
		`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.Avenger_Skyranger_Deployed');
	PendingLaunch = Mission.ObjectID;
	if (LaunchDelay <= 0)
		LoadMapNow();
	else
		SetTimer(0.5, false, nameof(LaunchNow));
}

/** The mission launched (OnLaunch, after LaunchDelay seconds): voices and the Avenger's cinematics stopped first. */
function LaunchNow()
{
	local Sequence Seq;
	local array<SequenceObject> Interps;
	local SequenceObject Obj;
	local int n;

	if (`HQPRES.m_kNarrativeUIMgr != none)
		`HQPRES.m_kNarrativeUIMgr.StopConversations();
	// Running cinematics (their sound tracks post the events whose callbacks crashed): stopped (SeqAct_Interp's input 2).
	Seq = WorldInfo.GetGameSequence();
	if (Seq != none)
	{
		Seq.FindSeqObjectsByClass(class'SeqAct_Interp', true, Interps);
		foreach Interps(Obj)
		{
			if (SeqAct_Interp(Obj).bIsPlaying)
			{
				SeqAct_Interp(Obj).ForceActivateInput(2);
				n++;
			}
		}
	}
	SetTimer(LaunchDelay, false, nameof(LoadMapNow));
	`log("LongWarX2: Long War HQ: voices and" @ n @ "running cinematics stopped; the map loads in" @ LaunchDelay @ "s", , 'LongWarX2');
}

function LoadMapNow()
{
	`log("LongWarX2: Long War HQ: the map loads now", , 'LongWarX2');
	`GAME.LaunchTacticalBattle(PendingLaunch);
}

/**
 * The EW map's mission on XCOM 2's empty test plot (EWPlot): a level volume, a spawn and one parcel, so nothing of an XCOM 2
 * map is around the EW map; its light is a clear day (Config/XComMaps.ini gives the plot its own). With bTestMission, also
 * XCOM 2's mission made for that plot (EWMission, "TestMission": no aliens of its own, no timer, no objective items;
 * Long War's aliens stand at EW's pods and its rule ends the mission); not for a terror site, whose XCOM 2 mission brings
 * and counts the civilians. False when the plot is not in this install's list.
 */
function bool UseEWPlot(XComGameState_MissionSite Mission, bool bTestMission, string EWMap)
{
	local XComParcelManager Parcels;
	local PlotDefinition Plot;
	local MissionDefinition Def;

	Parcels = `PARCELMGR;
	// The EW map's own plot (LWX2_<map>: ew-plot.ts, listed by the setup program) when there is one; else the template,
	// with the map placed at run time.
	foreach Parcels.arrPlots(Plot)
	{
		if (Plot.MapName ~= ("LWX2_" $ EWMap))
		{
			Mission.GeneratedMission.Plot = Plot;
			Mission.GeneratedMission.Biome = Parcels.GetBiomeDefinition(EWBiome);
			if (bTestMission && EWMission != "" && `TACTICALMISSIONMGR.GetMissionDefinitionForType(EWMission, Def))
				Mission.GeneratedMission.Mission = Def;
			return true;
		}
	}
	foreach Parcels.arrPlots(Plot)
	{
		if (Plot.MapName ~= EWPlot)
		{
			Mission.GeneratedMission.Plot = Plot;
			Mission.GeneratedMission.Biome = Parcels.GetBiomeDefinition(EWBiome);
			if (bTestMission && EWMission != "" && `TACTICALMISSIONMGR.GetMissionDefinitionForType(EWMission, Def))
				Mission.GeneratedMission.Mission = Def;
			return true;
		}
	}
	`log("LongWarX2: Long War HQ: no plot" @ EWPlot $ "; an outdoor plot instead", , 'LongWarX2');
	return false;
}

/**
 * The EW map goes in place of the generated map, under its light: an outdoor plot (wilderness,
 * a small town or an abandoned city, arid where it can be, like EW's badlands) rather than a
 * city centre or a sewer. False when the mission has none. (XCOM 2's guerrilla ops are never
 * in the wilderness.)
 */
function bool PreferOutdoorPlot(XComGameState_MissionSite Mission)
{
	local XComParcelManager Parcels;
	local array<PlotDefinition> Plots;
	local PlotDefinition Plot, Best;
	local bool bFound;
	local string Types;

	Parcels = `PARCELMGR;
	Parcels.GetValidPlotsForMission(Plots, Mission.GeneratedMission.Mission);
	foreach Plots(Plot)
		Types $= " " $ Plot.strType;
	`log("LongWarX2: Long War HQ:" @ Mission.GeneratedMission.Mission.sType @ "can be played on" @ Plots.Length @ "plots:" $ Types, , 'LongWarX2');
	foreach Plots(Plot)
	{
		if (OutdoorRank(Plot) == 0 || Plot.ExcludeFromStrategy)
			continue;
		if (!bFound || OutdoorRank(Plot) > OutdoorRank(Best)
			|| (OutdoorRank(Plot) == OutdoorRank(Best) && Best.ValidBiomes.Find("Arid") == INDEX_NONE && Plot.ValidBiomes.Find("Arid") != INDEX_NONE))
			Best = Plot;
		bFound = true;
	}
	if (!bFound)
		return false;
	Mission.GeneratedMission.Plot = Best;
	if (Best.ValidBiomes.Length > 0)
		Mission.GeneratedMission.Biome = Parcels.GetBiomeDefinition(Best.ValidBiomes.Find("Arid") != INDEX_NONE ? "Arid" : Best.ValidBiomes[0]);
	return true;
}

/**
 * A region where it is day now, and a place in it: the mission's light follows its local time
 * (XCOM 2 picks the plot's lighting by it), and the EW map has none of its own yet.
 */
function DaylightRegion(out XComGameState_WorldRegion Region, out Vector2D Where)
{
	local XComGameState_GameTime Time;
	local XComGameState_WorldRegion Candidate;
	local Vector2D Place;
	local TDateTime LocalTime;
	local ETimeOfDay TimeOfDay;

	Time = XComGameState_GameTime(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_WorldRegion', Candidate)
	{
		Place = Candidate.GetRandom2DLocationInRegion();
		LocalTime = Time.CurrentTime;
		class'X2StrategyGameRulesetDataStructures'.static.GetLocalizedTime(Place, LocalTime);
		TimeOfDay = class'X2StrategyGameRulesetDataStructures'.static.GetTimeOfDay(LocalTime);
		if (TimeOfDay == eTimeOfDay_Morning || TimeOfDay == eTimeOfDay_Noon || TimeOfDay == eTimeOfDay_Afternoon)
		{
			Region = Candidate;
			Where = Place;
			`log("LongWarX2: Long War HQ: daylight in" @ Candidate.GetMyTemplateName() @ "(" $ TimeOfDay $ ")", , 'LongWarX2');
			return;
		}
	}
}

/** How well a plot type suits EW's outdoor maps: wilderness, then small towns, then abandoned cities; 0 for the rest. */
function int OutdoorRank(PlotDefinition Plot)
{
	switch (Plot.strType)
	{
	case "Wilderness": return 3;
	case "SmallTown": return 2;
	case "Abandoned": return 1;
	}
	return 0;
}

/** Experiment 3's interception screen, with the campaign's jets and month. */
function OnAirWar(UIButton Button)
{
	local UILWInterception Air;

	Air = Spawn(class'UILWInterception', Movie.Pres);
	Air.bCampaign = true;
	Movie.Pres.ScreenStack.Push(Air);
}

function OnAvenger(UIButton Button)
{
	CloseScreen();
}

defaultproperties
{
	InputState = eInputState_Consume;
}
