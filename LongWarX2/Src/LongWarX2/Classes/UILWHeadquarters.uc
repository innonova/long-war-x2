// A Long War headquarters screen in place of XCOM 2's base and Geoscape (features/hard-parts.md,
// experiment 4): can a strategy layer of our own send a squad on a mission and take the result
// back? It shows the campaign's date, its soldiers, the last mission's outcome, and launches a
// mission with the first four soldiers able to go, through XCOM 2's own mission path (a mission
// site, PrepareTacticalBattle, LaunchTacticalBattle), skipping its Geoscape, squad select and
// Skyranger.
class UILWHeadquarters extends UIScreen;

var UIText Title, Info, Squad, Last;
var UIButton LaunchButton, AvengerButton;

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
	AvengerButton = Spawn(class'UIButton', self).InitButton('LWHQAvenger', "TO XCOM 2'S AVENGER", OnAvenger);
	AvengerButton.SetPosition(700, 880);
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
	Soldiers = ReadySoldiers(4);
	foreach Soldiers(Unit)
		S $= Unit.GetName(eNameType_RankFull) @ "-" @ Unit.GetSoldierClassTemplate().DisplayName @ "-" @ Unit.GetNumMissions() @ "missions," @ Unit.GetNumKills() @ "kills\n";
	Squad.SetText(S);
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
		if (Unit != none && Unit.IsSoldier() && Unit.CanGoOnMission() && Out.Length < Max)
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
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Unit Unit;
	local XGStrategy Game;

	Soldiers = ReadySoldiers(4);
	if (Soldiers.Length == 0)
		return;
	History = `XCOMHISTORY;
	Strategy = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	Region = XComGameState_WorldRegion(History.GetGameStateForObjectID(XComHQ.StartingRegion.ObjectID));

	// A mission site, as XCOM 2's calendar makes a guerrilla op; and the squad.
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("LongWarX2: a mission from the Long War headquarters");
	RewardTemplate = X2RewardTemplate(Strategy.FindStrategyElementTemplate('Reward_Supplies'));
	Reward = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	Reward.GenerateReward(NewGameState, ResHQ.GetMissionResourceRewardScalar(Reward), Region.GetReference());
	Rewards.AddItem(Reward);
	Mission = XComGameState_MissionSite(NewGameState.CreateNewStateObject(class'XComGameState_MissionSite'));
	Mission.BuildMission(X2MissionSourceTemplate(Strategy.FindStrategyElementTemplate('MissionSource_GuerillaOp')), Region.GetRandom2DLocationInRegion(), Region.GetReference(), Rewards, true, false);
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.Squad.Length = 0;
	foreach Soldiers(Unit)
		XComHQ.Squad.AddItem(Unit.GetReference());
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("LongWarX2: Long War HQ: launching" @ Mission.GeneratedMission.Mission.sType @ "on" @ Mission.GeneratedMission.Plot.MapName @ "with" @ Soldiers.Length @ "soldiers", , 'LongWarX2');

	Game = `GAME;
	Game.PrepareTacticalBattle(Mission.ObjectID);
	Game.LaunchTacticalBattle(Mission.ObjectID);
}

function OnAvenger(UIButton Button)
{
	CloseScreen();
}

defaultproperties
{
	InputState = eInputState_Consume;
}
