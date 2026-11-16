// A council extraction or rescue on its EW map (features/lw-council-missions.md, step 2), as EW's variant level plays it
// (URB_PierA_Stream …, read by tools/convert/ew-objectives.ts into XComLWX2EWObjectives.ini): a VIP stands where EW's
// Kismet spawned them. In an extraction they wait, out of XCOM's control, until a soldier reaches them (EW's volume that
// swaps them to XCOM: "Locate …", "Approach …"); in a rescue they are XCOM's from the start. Then they are to be escorted to
// the Skyranger (XCOM 2's evac zone, placed where EW's arrow pointed) and evacuated. The VIP killed, the mission is lost. Got
// away, the mission is won once every alien is dead or taken, or every soldier still standing has evacuated too.
class LWX2CouncilVIP extends Object config(LWX2EWObjectives);

struct LWX2VIPDef
{
	var string Map;
	var vector At;
	var string First, Last;
	/** An extraction: the VIP waits at Approach until a soldier comes within ApproachTiles. */
	var bool bApproach;
	var vector Approach;
	var vector Extract;
	/** EW's objective texts: locate, approach, escort (an extraction); escort alone (a rescue). */
	var array<string> Texts;
	var string KillRest, Report;
};

var config array<LWX2VIPDef> VIPs;
/** How near a soldier comes to EW's volume around the VIP to reach them, in tiles (the volume's size is not read). */
var config float ApproachTiles;
/** XCOM 2's character for the VIP: its friendly VIP civilian (evacuates, takes cover). */
var config name VIPTemplate;

/** The VIP mission being played, if this mission is one: a council extraction or rescue on its EW map's variant plot. */
static function bool Active(out LWX2VIPDef P)
{
	local XComGameState_LWStrategy S;
	local XComGameState_BattleData Battle;
	local int k;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.PendingKind != 10 || S.PendingIndex >= S.Sites.Length || (S.Sites[S.PendingIndex].CouncilKind != 3 && S.Sites[S.PendingIndex].CouncilKind != 4))
		return false;
	// (Only on the map with its variant level: the VIP's way is that level's.)
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (Battle == none || !(Battle.MapData.PlotMapName ~= ("LWX2V_" $ S.PendingEWMap)))
		return false;
	k = default.VIPs.Find('Map', S.PendingEWMap);
	if (k == INDEX_NONE)
		return false;
	P = default.VIPs[k];
	return true;
}

static function XComGameState_LWX2VIP State()
{
	local XComGameState_LWX2VIP V;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWX2VIP', V)
		return V;
	return none;
}

static function XComGameState_Unit VIPUnit()
{
	local XComGameState_LWX2VIP V;

	V = State();
	return V != none ? XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(V.VIP.ObjectID)) : none;
}

/** A place on the floor nearest a point of EW's (the maps are at EW's coordinates on their own plots). */
static function vector Floor(vector At)
{
	local TTile Tile;

	if (`XWORLD.GetFloorTileForPosition(At, Tile, true))
		return `XWORLD.GetPositionFromTileCoordinates(Tile);
	return At;
}

/** The Skyranger's ground: EW's arrow pointed above it (at its roof, where the map has EW's Skyranger); the map's drop zone
 *  nearest the arrow, within ten tiles, else under the arrow. */
static function vector Skyranger(LWX2VIPDef P)
{
	local vector Zone, Best;
	local float Near;

	Best = P.Extract;
	Near = 10 * class'XComWorldData'.const.WORLD_StepSize;
	foreach class'LWX2EWMapPieces'.static.Map().DropZones(Zone)
	{
		if (VSize2D(Zone - P.Extract) < Near)
		{
			Near = VSize2D(Zone - P.Extract);
			Best = Zone;
		}
	}
	return Best;
}

/** Asked twice a second in the mission (UIScreenListener_LongWarX2Tactical): the VIP made, reached, got away or killed.
 *  False while the VIP holds the mission back from being won (not yet away). */
static function bool Update()
{
	local LWX2VIPDef P;
	local XComGameState_LWX2VIP V;
	local XComGameState_Unit VIP, Unit;
	local XComGameState_EvacZone Zone;
	local XComGameState NewGameState;
	local StateObjectReference Ref;
	local bool bNear, bStanding, bAway;
	local float Reach;
	local ETeam Team;
	local name Template;

	if (!Active(P))
		return true;
	V = State();
	if (V == none)
	{
		// The VIP where EW's Kismet spawned them: XCOM's in a rescue, waiting (neutral) in an extraction.
		Team = eTeam_XCom;
		if (P.bApproach)
			Team = eTeam_Neutral;
		Template = default.VIPTemplate;
		if (Template == '')
			Template = 'FriendlyVIPCivilian';
		Ref = `SPAWNMGR.CreateUnit(Floor(P.At), Template, Team, false);
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the council's VIP");
		V = XComGameState_LWX2VIP(NewGameState.CreateNewStateObject(class'XComGameState_LWX2VIP'));
		V.VIP = Ref;
		V.bJoined = !P.bApproach;
		VIP = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Ref.ObjectID));
		if (VIP != none && (P.First != "" || P.Last != ""))
			VIP.SetCharacterName(P.First, P.Last, "");
		// The Skyranger: XCOM 2's evac zone where EW's arrow pointed.
		class'XComGameState_EvacZone'.static.PlaceEvacZone(NewGameState, Floor(Skyranger(P)), eTeam_XCom);
		`TACTICALRULES.SubmitGameState(NewGameState);
		Zone = class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom);
		if (Zone != none)
		{
			Zone.FindOrCreateVisualizer();
			Zone.SyncVisualizer();
		}
		`log("LongWarX2: council VIP on" @ P.Map $ ":" @ P.First @ P.Last @ (P.bApproach ? "waiting to be reached" : "with XCOM") $ "; the Skyranger at" @ Skyranger(P), , 'LongWarX2');
		return false;
	}
	VIP = VIPUnit();
	if (VIP == none)
		return false;
	if (VIP.IsDead())
	{
		if (!`TACTICALRULES.HasTacticalGameEnded())
		{
			`log("LongWarX2: council VIP killed: the mission is lost", , 'LongWarX2');
			`TACTICALRULES.EndBattle(XGBattle_SP(`BATTLE).GetAIPlayer());
		}
		return false;
	}
	Reach = (default.ApproachTiles > 0 ? default.ApproachTiles : 4.0) * class'XComWorldData'.const.WORLD_StepSize;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.ObjectID == VIP.ObjectID || Unit.GetTeam() != eTeam_XCom || !Unit.IsSoldier() || !Unit.IsAlive())
			continue;
		if (!Unit.bRemovedFromPlay)
		{
			bStanding = true;
			if (VSize2D(`XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation) - P.Approach) <= Reach
				&& Abs(`XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation).Z - P.Approach.Z) <= 2 * class'XComWorldData'.const.WORLD_FloorHeight)
				bNear = true;
		}
		else
			bAway = true;
	}
	// Reached: the VIP is XCOM's (EW's SeqAct_SwapTeams, as XCOM 2's own does it).
	if (!V.bJoined && bNear)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the VIP reached");
		XComGameState_LWX2VIP(NewGameState.ModifyStateObject(class'XComGameState_LWX2VIP', V.ObjectID)).bJoined = true;
		`TACTICALRULES.SubmitGameState(NewGameState);
		`BATTLE.SwapTeams(VIP, eTeam_XCom);
		`log("LongWarX2: council VIP reached: with XCOM now", , 'LongWarX2');
	}
	if (!V.bExtracted && VIP.bRemovedFromPlay)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the VIP away");
		XComGameState_LWX2VIP(NewGameState.ModifyStateObject(class'XComGameState_LWX2VIP', V.ObjectID)).bExtracted = true;
		`TACTICALRULES.SubmitGameState(NewGameState);
		`log("LongWarX2: council VIP evacuated", , 'LongWarX2');
		return true;
	}
	if (!V.bExtracted)
		return false;
	// Away, and every soldier still standing evacuated too: won (EW: "All soldiers report to the EVAC zone").
	if (!bStanding && bAway && !`TACTICALRULES.HasTacticalGameEnded())
	{
		`log("LongWarX2: council VIP away and the squad evacuated: the mission is won", , 'LongWarX2');
		class'UIScreenListener_LongWarX2Tactical'.static.TestWin();
	}
	return true;
}

/** The objective as EW put it: locate, approach, escort; then kill the rest or report to evac. "" when no VIP mission. */
static function string ObjectiveText()
{
	local LWX2VIPDef P;
	local XComGameState_LWX2VIP V;
	local XComGameState_Unit VIP;

	if (!Active(P) || P.Texts.Length == 0)
		return "";
	V = State();
	if (V != none && V.bExtracted)
		return P.KillRest @ P.Report;
	if (V != none && V.bJoined)
		return P.Texts[P.Texts.Length - 1];
	// Waiting: "Locate" until a soldier sees them, then "Approach".
	VIP = VIPUnit();
	if (P.Texts.Length >= 3 && VIP != none && !Seen(VIP))
		return P.Texts[0];
	return P.Texts[Min(1, P.Texts.Length - 1)];
}

/** Whether any XCOM soldier sees the unit. */
static function bool Seen(XComGameState_Unit Target)
{
	local XComGameState_Unit Unit;
	local GameRulesCache_VisibilityInfo Info;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() != eTeam_XCom || !Unit.IsSoldier() || !Unit.IsAlive() || Unit.bRemovedFromPlay)
			continue;
		if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Unit.ObjectID, Target.ObjectID, Info) && Info.bVisibleGameplay)
			return true;
	}
	return false;
}

defaultproperties
{
	ApproachTiles = 4
	VIPTemplate = "FriendlyVIPCivilian"
}
