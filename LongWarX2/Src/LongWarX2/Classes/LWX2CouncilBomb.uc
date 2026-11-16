// A council bomb disposal on its EW map (features/lw-council-missions.md, step 2), as EW's variant level's Kismet plays it
// (URB_CemeteryGrand_Bomb …, read by tools/convert/ew-objectives.ts into XComLWX2EWObjectives.ini): the bomb's timer starts at
// Timer and loses one at each of XCOM's turn ends; each power node switched off gives a turn back; at 0 the bomb goes off and
// the mission is lost. Disarmed, the mission is won once every alien is dead or taken. XCOM's soldiers switch a node off or
// disarm the bomb from a tile beside it (X2Ability_LWX2Bomb); the state is XComGameState_LWX2Bomb.
class LWX2CouncilBomb extends Object config(LWX2EWObjectives);

struct LWX2BombDef
{
	var string Map;
	var int Timer;
	var int Nodes;
	var vector Bomb;
	var array<vector> NodeAt;
};

var config array<LWX2BombDef> Bombs;
/** How far from a node or the bomb a soldier may act on it, in tiles (EW: an adjacent tile). */
var config float ReachTiles;

/** The bomb disposal being played, if this mission is one: a council bomb disposal on its EW map with its objects read. */
static function bool Active(out LWX2BombDef B)
{
	local XComGameState_LWStrategy S;
	local string Map;
	local int k;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.PendingKind != 10 || S.PendingIndex >= S.Sites.Length || S.Sites[S.PendingIndex].CouncilKind != 2)
		return false;
	Map = S.PendingEWMap;
	if (Map == "")
		return false;
	k = default.Bombs.Find('Map', Map);
	if (k == INDEX_NONE)
		return false;
	B = default.Bombs[k];
	return true;
}

static function XComGameState_LWX2Bomb State()
{
	local XComGameState_LWX2Bomb Bomb;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWX2Bomb', Bomb)
		return Bomb;
	return none;
}

/** XCOM's turns ended so far (EW's Kismet takes a turn off the timer at each). */
static function int TurnsEnded()
{
	local XComGameState_Player Player;
	local StateObjectReference Active;

	Active = `TACTICALRULES.GetCachedUnitActionPlayerRef();
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', Player)
		if (Player.GetTeam() == eTeam_XCom)
			return Max(0, Player.PlayerTurnCount - (Active.ObjectID == Player.ObjectID ? 1 : 0));
	return 0;
}

static function int TurnsLeft(LWX2BombDef B, XComGameState_LWX2Bomb Bomb)
{
	return B.Timer + (Bomb != none ? Bomb.NodesOff() : 0) - TurnsEnded();
}

/** Asked twice a second in the mission (UIScreenListener_LongWarX2Tactical): the state made, the timer shown, the bomb gone
 *  off. False when the bomb holds the mission back from being won (not yet disarmed). */
static function bool Update()
{
	local LWX2BombDef B;
	local XComGameState_LWX2Bomb Bomb;
	local XComGameState NewGameState;
	local XComGameState_UITimer Timer;
	local int Left;

	if (!Active(B))
		return true;
	Bomb = State();
	if (Bomb == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the bomb");
		Bomb = XComGameState_LWX2Bomb(NewGameState.CreateNewStateObject(class'XComGameState_LWX2Bomb'));
		Bomb.NodeOff.Length = B.NodeAt.Length;
		`TACTICALRULES.SubmitGameState(NewGameState);
		`log("LongWarX2: council bomb on" @ B.Map $ ":" @ B.NodeAt.Length @ "nodes, timer" @ B.Timer, , 'LongWarX2');
	}
	if (Bomb.bDisarmed)
		return true;
	Left = TurnsLeft(B, Bomb);
	// The timer on XCOM 2's mission timer, as EW's Kismet showed it (SeqAct_DisplayUISpecialMissionTimer's way).
	Timer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_UITimer', true));
	if (Timer == none || Timer.TimerValue != Left || !Timer.ShouldShow)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the bomb's timer");
		if (Timer == none)
			Timer = XComGameState_UITimer(NewGameState.CreateNewStateObject(class'XComGameState_UITimer'));
		else
			Timer = XComGameState_UITimer(NewGameState.ModifyStateObject(class'XComGameState_UITimer', Timer.ObjectID));
		Timer.UiState = Left <= 1 ? eUIState_Bad : eUIState_Normal;
		Timer.ShouldShow = true;
		Timer.DisplayMsgTitle = "BOMB";
		Timer.DisplayMsgSubtitle = "Turns remaining";
		Timer.TimerValue = Left;
		Timer.IsTimer = true;
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	if (Left <= 0 && !`TACTICALRULES.HasTacticalGameEnded())
	{
		`log("LongWarX2: council bomb: the timer ran out, the mission is lost", , 'LongWarX2');
		`TACTICALRULES.EndBattle(XGBattle_SP(`BATTLE).GetAIPlayer());
	}
	return false;
}

/** The objective line: the bomb and its nodes. */
static function string ObjectiveText()
{
	local LWX2BombDef B;
	local XComGameState_LWX2Bomb Bomb;

	if (!Active(B))
		return "";
	Bomb = State();
	if (Bomb != none && Bomb.bDisarmed)
		return "Kill or capture every alien (the bomb is disarmed)";
	return "Disarm the bomb (power nodes off:" @ (Bomb != none ? Bomb.NodesOff() : 0) @ "of" @ B.NodeAt.Length $ ", each a turn more)";
}

/** The nearest active node within reach of a tile (its index), or -1; the bomb in reach (-2) when bBomb. */
static function int InReach(TTile Tile, bool bBomb)
{
	local LWX2BombDef B;
	local XComGameState_LWX2Bomb Bomb;
	local vector At;
	local float Reach, Best, D;
	local int i, Pick;

	if (!Active(B))
		return -1;
	Bomb = State();
	if (Bomb == none || Bomb.bDisarmed)
		return -1;
	At = `XWORLD.GetPositionFromTileCoordinates(Tile);
	Reach = (default.ReachTiles > 0 ? default.ReachTiles : 1.5) * class'XComWorldData'.const.WORLD_StepSize;
	if (bBomb)
	{
		if (VSize2D(B.Bomb - At) <= Reach && Abs(B.Bomb.Z - At.Z) <= 2 * class'XComWorldData'.const.WORLD_FloorHeight)
			return -2;
		return -1;
	}
	Pick = -1;
	Best = Reach;
	for (i = 0; i < B.NodeAt.Length; i++)
	{
		if (i < Bomb.NodeOff.Length && Bomb.NodeOff[i])
			continue;
		D = VSize2D(B.NodeAt[i] - At);
		if (D <= Best && Abs(B.NodeAt[i].Z - At.Z) <= 2 * class'XComWorldData'.const.WORLD_FloorHeight)
		{
			Best = D;
			Pick = i;
		}
	}
	return Pick;
}

defaultproperties
{
	ReachTiles = 1.5
}
