// Progeny's Furies on its EW map (features/lw-council-missions.md, step 4; the DLC2_3_Furies_Stream level's Kismet with EW's
// rescue handler, read by tools/convert/ew-objectives.ts readFuries into XComLWX2EWObjectives.ini): rescue the abductees by
// destroying or disarming the command console. Once a soldier sounds the alarm (its volume), the execution comes in twelve
// XCOM turns ("Turns Until Execution"; the first turn's end not counted); at 0 the captives are executed and the mission
// is lost. The console disarmed (a soldier beside it, one action), the rest of the aliens are to be killed; then it is won.
class LWX2Furies extends Object config(LWX2EWObjectives) dependson(LWCouncil);

struct LWX2FuriesDef
{
	var string Map;
	var string Level;
	var vector Console;
	var vector AlarmCenter, AlarmExtent;
	var int Timer;
	/** EW's texts: rescue the abductees, destroy or disarm the console, kill the rest; the count's label. */
	var string Rescue, ConsoleText, Kill, Execution;
};

var config array<LWX2FuriesDef> Furies;
/** How far from the console a soldier may disarm it, in tiles. */
var config float ReachTiles;

/** Furies being played: the council's mission 27 on its variant plot. */
static function bool Active(out LWX2FuriesDef F)
{
	local LWCouncil.LWCouncilMission M;
	local XComGameState_BattleData Battle;
	local int k;

	if (!class'LWCouncil'.static.Current(M) || M.Id != 27 || M.Level == "")
		return false;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (Battle == none || !(Battle.MapData.PlotMapName ~= ("LWX2V_" $ M.Level)))
		return false;
	k = default.Furies.Find('Level', M.Level);
	if (k == INDEX_NONE)
		return false;
	F = default.Furies[k];
	return true;
}

static function XComGameState_LWX2Furies State()
{
	local XComGameState_LWX2Furies F;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWX2Furies', F)
		return F;
	return none;
}

/** The unit beside the console while it is still on. */
static function bool InReach(XComGameState_Unit Unit)
{
	local LWX2FuriesDef F;
	local XComGameState_LWX2Furies S;
	local vector At;

	if (Unit == none || !Active(F))
		return false;
	S = State();
	if (S == none || S.Stage != 1)
		return false;
	At = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
	return VSize2D(F.Console - At) <= (default.ReachTiles > 0 ? default.ReachTiles : 1.5) * class'XComWorldData'.const.WORLD_StepSize
		&& Abs(F.Console.Z - At.Z) <= 2 * class'XComWorldData'.const.WORLD_FloorHeight;
}

/** The console disarmed (X2Effect_LWX2Console; EW's interactive actor raising ConsoleActivated): the rest to be killed. */
static function Disarmed(XComGameState NewGameState)
{
	local XComGameState_LWX2Furies S;

	S = State();
	if (S == none)
		return;
	S = XComGameState_LWX2Furies(NewGameState.ModifyStateObject(class'XComGameState_LWX2Furies', S.ObjectID));
	S.Stage = 2;
	`log("LongWarX2: Furies: the console is disarmed; the rest of the aliens to be killed", , 'LongWarX2');
}

/** Asked twice a second in the mission (UIScreenListener_LongWarX2Tactical): the alarm, the execution's countdown. False
 *  while the console holds the victory back. */
static function bool Update()
{
	local LWX2FuriesDef F;
	local XComGameState_LWX2Furies S;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local array<XComGameState_Unit> Squad;
	local int Now;
	local bool bAlarm, bTurnEnded;

	if (!Active(F))
		return true;
	S = State();
	if (S == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Furies");
		S = XComGameState_LWX2Furies(NewGameState.CreateNewStateObject(class'XComGameState_LWX2Furies'));
		S.Stage = 1;
		S.TimerLeft = F.Timer;
		S.CountedTurn = -1;
		`TACTICALRULES.SubmitGameState(NewGameState);
		`log("LongWarX2: Furies on" @ F.Map $ ": the execution" @ F.Timer @ "turns after the alarm", , 'LongWarX2');
		return false;
	}
	if (S.Stage >= 2)
		return true;
	Squad = class'LWX2ChryssalidHive'.static.Seeing();
	if (!S.bAlarm)
		foreach Squad(Unit)
			if (class'LWX2ChryssalidHive'.static.Inside(F.AlarmCenter, F.AlarmExtent, `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation)))
				bAlarm = true;
	Now = class'LWX2CovertExtraction'.static.TurnNow();
	bTurnEnded = S.bAlarm && !class'LWX2ChryssalidHive'.static.XComTurn() && S.CountedTurn != Now;
	if (bAlarm || bTurnEnded)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Furies' countdown");
		S = XComGameState_LWX2Furies(NewGameState.ModifyStateObject(class'XComGameState_LWX2Furies', S.ObjectID));
		if (bAlarm)
		{
			S.bAlarm = true;
			`log("LongWarX2: Furies: the alarm; the execution in" @ S.TimerLeft @ "turns", , 'LongWarX2');
		}
		if (bTurnEnded)
		{
			S.CountedTurn = Now;
			if (S.bFirstCounted)
				S.TimerLeft--;
			S.bFirstCounted = true;
		}
		`TACTICALRULES.SubmitGameState(NewGameState);
		S = State();
	}
	if (S.bAlarm && S.TimerLeft <= 0 && !`TACTICALRULES.HasTacticalGameEnded())
	{
		`log("LongWarX2: Furies: the captives are executed; the mission is lost", , 'LongWarX2');
		`TACTICALRULES.EndBattle(XGBattle_SP(`BATTLE).GetAIPlayer());
	}
	return false;
}

static function string ObjectiveText()
{
	local LWX2FuriesDef F;
	local XComGameState_LWX2Furies S;

	if (!Active(F))
		return "";
	S = State();
	if (S != none && S.Stage >= 2)
		return F.Kill;
	if (S != none && S.bAlarm)
		return F.Rescue @ F.ConsoleText @ F.Execution @ S.TimerLeft;
	return F.Rescue @ F.ConsoleText;
}
