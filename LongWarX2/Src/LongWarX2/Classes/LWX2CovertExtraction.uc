// An EXALT covert extraction on its EW map (features/lw-exalt.md, Long War's XGBattle_SPCovertOpsExtraction and the CovExt
// levels' Kismet, read by tools/convert/ew-objectives.ts into XComLWX2EWObjectives.ini): the covert operative starts at the
// level's own spawn point, apart from the squad; two of the level's EXALT comm relays (its radar arrays) are active, and
// only the operative can hack one (from beside it, one action, one a turn: XComRadarArrayActor's CanInteract). Both hacked,
// the operative is to be escorted to the EVAC zone (XCOM 2's, at the Skyranger) and evacuated; then the rest of EXALT
// eliminated, or every soldier still standing evacuated too. The operative killed, the mission is lost.
class LWX2CovertExtraction extends Object config(LWX2EWObjectives);

struct LWX2CovertDef
{
	var string Map;
	var string Level;
	var array<vector> Relays;
	var bool bOperativeSpawn;
	var vector OperativeAt;
	/** EW's texts: hack the relays, the count's label, escort the operative, eliminate or evacuate, retreat. */
	var string Hack, Left, Escort, Cleanup, Retreat;
};

var config array<LWX2CovertDef> Extractions;
/** How far from a relay the operative may hack it, in tiles (EW: an interaction point beside it). */
var config float ReachTiles;

/** The covert extraction being played: EXALT's covert mission on a covert extraction map's variant plot. */
static function bool Active(out LWX2CovertDef C)
{
	local XComGameState_LWStrategy S;
	local XComGameState_BattleData Battle;
	local int k;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.PendingKind != 8 || S.PendingEWMap == "")
		return false;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (Battle == none || Left(Battle.MapData.PlotMapName, 6) != "LWX2V_")
		return false;
	k = default.Extractions.Find('Level', Mid(Battle.MapData.PlotMapName, 6));
	if (k == INDEX_NONE)
		return false;
	C = default.Extractions[k];
	return true;
}

static function XComGameState_LWX2Covert State()
{
	local XComGameState_LWX2Covert C;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWX2Covert', C)
		return C;
	return none;
}

/** The covert operative (Long War's: the soldier sent into the country, XComGameState_LWStrategy.ExaltOperative). */
static function XComGameState_Unit Operative()
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.ExaltOperative <= 0)
		return none;
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.ExaltOperative));
}

static function int TurnNow()
{
	local XComGameState_Player Player;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', Player)
		if (Player.GetTeam() == eTeam_XCom)
			return Player.PlayerTurnCount;
	return 0;
}

/** The active, unhacked relay the unit can hack from its tile (its index among the active ones), or -1. */
static function int InReach(XComGameState_Unit Unit)
{
	local LWX2CovertDef C;
	local XComGameState_LWX2Covert Covert;
	local XComGameState_Unit Op;
	local vector At, Relay;
	local int i;

	if (Unit == none || !Active(C))
		return -1;
	Covert = State();
	Op = Operative();
	if (Covert == none || Op == none || Unit.ObjectID != Op.ObjectID || Covert.HackedOnTurn == TurnNow())
		return -1;
	At = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
	for (i = 0; i < Covert.Active.Length; i++)
	{
		if (i < Covert.Hacked.Length && Covert.Hacked[i])
			continue;
		Relay = C.Relays[Covert.Active[i]];
		if (VSize2D(Relay - At) <= (default.ReachTiles > 0 ? default.ReachTiles : 1.5) * class'XComWorldData'.const.WORLD_StepSize
			&& Abs(Relay.Z - At.Z) <= 2 * class'XComWorldData'.const.WORLD_FloorHeight)
			return i;
	}
	return -1;
}

/** Asked twice a second in the mission (UIScreenListener_LongWarX2Tactical): the relays chosen, the operative put at their
 *  spawn, the evac zone at the Skyranger; the operative's death, their escape. False while they hold the victory back. */
static function bool Update()
{
	local LWX2CovertDef C;
	local XComGameState_LWX2Covert Covert;
	local XComGameState_Unit Op, Unit;
	local XComGameState NewGameState;
	local array<int> Pool;
	local TTile Tile;
	local bool bStanding, bAway;
	local int k;

	if (!Active(C))
		return true;
	Op = Operative();
	Covert = State();
	if (Covert == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the covert extraction");
		Covert = XComGameState_LWX2Covert(NewGameState.CreateNewStateObject(class'XComGameState_LWX2Covert'));
		Covert.HackedOnTurn = -1;
		// Two of the relays, at random (XGBattle_SPCovertOpsExtraction.InitRadarArrays).
		for (k = 0; k < C.Relays.Length; k++)
			Pool.AddItem(k);
		while (Covert.Active.Length < 2 && Pool.Length > 0)
		{
			k = Rand(Pool.Length);
			Covert.Active.AddItem(Pool[k]);
			Covert.Hacked.AddItem(false);
			Pool.Remove(k, 1);
		}
		// The operative at the level's own spawn point (SpawnCovertOperative), apart from the squad.
		if (Op != none && C.bOperativeSpawn && `XWORLD.GetFloorTileForPosition(C.OperativeAt, Tile, true))
		{
			Op = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Op.ObjectID));
			Op.SetVisibilityLocation(Tile);
			Covert.bPlaced = true;
		}
		class'XComGameState_EvacZone'.static.PlaceEvacZone(NewGameState, class'LWX2CouncilVIP'.static.Floor(Skyranger()), eTeam_XCom);
		`TACTICALRULES.SubmitGameState(NewGameState);
		if (Covert.bPlaced && XGUnit(Op.GetVisualizer()) != none)
			XGUnit(Op.GetVisualizer()).GetPawn().SetLocation(`XWORLD.GetPositionFromTileCoordinates(Tile));
		if (class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom) != none)
		{
			class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).FindOrCreateVisualizer();
			class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).SyncVisualizer();
		}
		`log("LongWarX2: covert extraction on" @ C.Map $ ": relays" @ Covert.Active[0] @ "and" @ Covert.Active[1] @ "of" @ C.Relays.Length $ "; the operative" @ (Op != none ? Op.GetFullName() : "missing") @ (Covert.bPlaced ? "at their spawn" : "with the squad"), , 'LongWarX2');
		return false;
	}
	if (Op == none)
		return true;
	if (Op.IsDead())
	{
		if (!`TACTICALRULES.HasTacticalGameEnded())
		{
			`log("LongWarX2: covert extraction: the operative is dead, the mission is lost", , 'LongWarX2');
			`TACTICALRULES.EndBattle(XGBattle_SPCovertOpsExtraction_Loser());
		}
		return false;
	}
	if (!Covert.bExtracted && Op.bRemovedFromPlay)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the operative away");
		XComGameState_LWX2Covert(NewGameState.ModifyStateObject(class'XComGameState_LWX2Covert', Covert.ObjectID)).bExtracted = true;
		`TACTICALRULES.SubmitGameState(NewGameState);
		Covert = State();
		`log("LongWarX2: covert extraction: the operative evacuated with" @ Covert.RelaysLeft() @ "relays left", , 'LongWarX2');
	}
	// (Away before both relays are hacked: the mission is not won, EW's "Get to the EVAC zone" retreat.)
	if (!Covert.bExtracted || Covert.RelaysLeft() > 0)
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
			if (Unit.GetTeam() == eTeam_XCom && Unit.IsSoldier() && Unit.IsAlive() && !Unit.bRemovedFromPlay)
				bStanding = true;
		if (!bStanding && !`TACTICALRULES.HasTacticalGameEnded())
		{
			`log("LongWarX2: covert extraction: the squad left without the relays hacked and the operative out: lost", , 'LongWarX2');
			`TACTICALRULES.EndBattle(XGBattle_SPCovertOpsExtraction_Loser());
		}
		return false;
	}
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() != eTeam_XCom || !Unit.IsSoldier() || !Unit.IsAlive())
			continue;
		if (Unit.bRemovedFromPlay)
			bAway = true;
		else
			bStanding = true;
	}
	if (!bStanding && bAway && !`TACTICALRULES.HasTacticalGameEnded())
	{
		`log("LongWarX2: covert extraction: the operative out and the squad evacuated: the mission is won", , 'LongWarX2');
		class'UIScreenListener_LongWarX2Tactical'.static.TestWin();
	}
	return true;
}

static function XGPlayer XGBattle_SPCovertOpsExtraction_Loser()
{
	return XGBattle_SP(`BATTLE).GetAIPlayer();
}

/** The Skyranger: the map's drop zone nearest the squad's landing (EW's dropship volume, where the operative is escorted). */
static function vector Skyranger()
{
	local XComGameState_BattleData Battle;
	local vector Zone, Best;
	local float Near;

	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	Best = Battle.MapData.SoldierSpawnLocation;
	Near = 10 * class'XComWorldData'.const.WORLD_StepSize;
	foreach class'LWX2EWMapPieces'.static.Map().DropZones(Zone)
	{
		if (VSize2D(Zone - Battle.MapData.SoldierSpawnLocation) < Near)
		{
			Near = VSize2D(Zone - Battle.MapData.SoldierSpawnLocation);
			Best = Zone;
		}
	}
	return Best;
}

/** The objective as EW's Kismet put it: the relays to hack (k left), the escort, then eliminate or evacuate. */
static function string ObjectiveText()
{
	local LWX2CovertDef C;
	local XComGameState_LWX2Covert Covert;

	if (!Active(C))
		return "";
	Covert = State();
	if (Covert == none || Covert.RelaysLeft() > 0)
		return C.Hack @ C.Left $ (Covert != none ? Covert.RelaysLeft() : 2);
	if (!Covert.bExtracted)
		return C.Escort;
	return C.Cleanup;
}

defaultproperties
{
	ReachTiles = 1.5
}
