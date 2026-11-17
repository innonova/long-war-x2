// The Chryssalid hive on its EW map (features/lw-council-missions.md, step 4; EW's XComSpecialMissionHandler_ChrysHive and
// the EWI_ChryssalidHive_Stream level's Kismet, read by tools/convert/ew-objectives.ts into XComLWX2EWObjectives.ini). Its
// objectives move on as EW's do: investigate the response team's disappearance; on seeing a zombie, a Chryssalid or the
// ship (EW's squad-visible points), find the source of the infestation; on seeing the whale, reactivate the ship's
// transponder, from beside it (one action). The mission is then won (EW marks it so): the strike craft come once every
// soldier still standing is in the EVAC volume (XCOM 2's evac zone is placed there too) or, at the latest, at the end of
// the eighth XCOM turn after; the air strike kills every alien and ends the battle.
// The level's scripted spawns come as its Kismet has them: zombies at the start and as soldiers first enter its volumes
// (by EW's EnemyLevel), the hive's Chryssalids on the aliens' turns after the whale is seen, and on the run a Chryssalid from
// each of the ship's exits whose volume a soldier enters, as the aliens' turn ends.
class LWX2ChryssalidHive extends Object config(LWX2EWObjectives) dependson(LWCouncil);

struct LWX2HiveDef
{
	var string Map;
	var string Level;
	var int Countdown;
	var vector Transponder;
	var vector EvacCenter, EvacExtent;
	var array<vector> Ship, Whale;
	/** EW's objectives: investigate, find the source, the transponder, reach the EVAC; the count's label. */
	var array<string> Texts;
	var string Strike;
};

struct LWX2HiveVolume
{
	var string Level;
	var vector Center, Extent;
};

struct LWX2HiveSpawn
{
	var string Level;
	/** Long War's character: 13 a Chryssalid, 14 a zombie. */
	var int Char;
	var vector At;
	/** 0 at the start, 1 a volume first entered (before the whale is seen), 2 the hive's turn, 3 a ship's exit on the run,
	 *  4 as the run starts. */
	var int When;
	var int Volume;
	var int Turn;
	/** Only at this EnemyLevel; -1 at any. */
	var int EnemyLevel;
};

var config array<LWX2HiveDef> Hives;
var config array<LWX2HiveVolume> Volumes;
var config array<LWX2HiveSpawn> Spawns;
/** How far from the transponder a soldier may reactivate it, in tiles (EW: its interaction point beside it). */
var config float ReachTiles;
/** EW's squad-visible points are seen within this share of the soldier's sight, squared (XComSquadVisiblePoint's
 *  fMinSightPercent). */
var config float SightShare;

/** The hive being played: the council's mission 29 on its variant plot. */
static function bool Active(out LWX2HiveDef H)
{
	local LWCouncil.LWCouncilMission M;
	local XComGameState_BattleData Battle;
	local int k;

	if (!class'LWCouncil'.static.Current(M) || M.Id != 29 || M.Level == "")
		return false;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (Battle == none || !(Battle.MapData.PlotMapName ~= ("LWX2V_" $ M.Level)))
		return false;
	k = default.Hives.Find('Level', M.Level);
	if (k == INDEX_NONE)
		return false;
	H = default.Hives[k];
	return true;
}

static function XComGameState_LWX2Hive State()
{
	local XComGameState_LWX2Hive H;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWX2Hive', H)
		return H;
	return none;
}

static function array<LWX2HiveVolume> VolumesOf(string Level)
{
	local array<LWX2HiveVolume> Out;
	local LWX2HiveVolume V;

	foreach default.Volumes(V)
		if (V.Level ~= Level)
			Out.AddItem(V);
	return Out;
}

static function array<LWX2HiveSpawn> SpawnsOf(string Level)
{
	local array<LWX2HiveSpawn> Out;
	local LWX2HiveSpawn P;

	foreach default.Spawns(P)
		if (P.Level ~= Level)
			Out.AddItem(P);
	return Out;
}

static function bool Inside(vector Center, vector Extent, vector At)
{
	return Abs(At.X - Center.X) <= Extent.X && Abs(At.Y - Center.Y) <= Extent.Y && Abs(At.Z - Center.Z) <= Extent.Z + 64;
}

/** XCOM's soldiers on the field who can see (XComSquadVisiblePoint.Tick: not dead, not off the field, not critically wounded). */
static function array<XComGameState_Unit> Seeing()
{
	local array<XComGameState_Unit> Out;
	local XComGameState_Unit Unit;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_XCom && Unit.IsSoldier() && Unit.IsAlive() && !Unit.bRemovedFromPlay && !Unit.IsBleedingOut() && !Unit.IsUnconscious())
			Out.AddItem(Unit);
	return Out;
}

/** A point one of them sees: in line of sight, nearer than its sight radius times the root of SightShare. */
static function bool PointSeen(array<XComGameState_Unit> Squad, array<vector> Points)
{
	local XComGameState_Unit Unit;
	local GameRulesCache_VisibilityInfo Info;
	local vector At, P;
	local TTile From, To;
	local float Reach;

	foreach Points(P)
	{
		To = `XWORLD.GetTileCoordinatesFromPosition(P);
		foreach Squad(Unit)
		{
			At = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
			Reach = Unit.GetCurrentStat(eStat_SightRadius) * class'XComWorldData'.const.WORLD_StepSize;
			if (VSizeSq(At - P) >= Reach * Reach * (default.SightShare > 0 ? default.SightShare : 0.75))
				continue;
			From = Unit.TileLocation;
			if (`XWORLD.CanSeeTileToTile(From, To, Info))
				return true;
		}
	}
	return false;
}

/** One of them sees a zombie or a Chryssalid (the handler's OnAlienTypeSeen: OnZombieSpotted, the first Chryssalid). */
static function bool InfestationSeen(array<XComGameState_Unit> Squad)
{
	local XComGameState_Unit Unit, Alien;
	local GameRulesCache_VisibilityInfo Info;
	local UnitValue V;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Alien)
	{
		if (Alien.GetTeam() != eTeam_Alien || !Alien.IsAlive() || !Alien.GetUnitValue('LWX2Species', V) || (int(V.fValue) != 13 && int(V.fValue) != 14))
			continue;
		foreach Squad(Unit)
			if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Unit.ObjectID, Alien.ObjectID, Info) && Info.bVisibleGameplay)
				return true;
	}
	return false;
}

/** The unit beside the transponder while it waits to be reactivated. */
static function bool InReach(XComGameState_Unit Unit)
{
	local LWX2HiveDef H;
	local XComGameState_LWX2Hive Hive;
	local vector At;

	if (Unit == none || !Active(H))
		return false;
	Hive = State();
	if (Hive == none || Hive.Stage != 3)
		return false;
	At = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
	return VSize2D(H.Transponder - At) <= (default.ReachTiles > 0 ? default.ReachTiles : 1.5) * class'XComWorldData'.const.WORLD_StepSize
		&& Abs(H.Transponder.Z - At.Z) <= 2 * class'XComWorldData'.const.WORLD_FloorHeight;
}

/** EW's EnemyLevel, from the roaming aliens the mission's squad brings (XGDeployAI.KismetRoamingNumber: iNumDynamicAliens). */
static function int EnemyLevel()
{
	local XComGameState_LWStrategy S;
	local int n;

	S = class'XComGameState_LWStrategy'.static.Get();
	n = S != none ? S.PendingSquad.Length : 0;
	return n > 4 ? 2 : (n == 4 ? 1 : 0);
}

/** Asked twice a second in the mission (UIScreenListener_LongWarX2Tactical): the objectives moved on, the level's spawns made,
 *  the run's end. False while the hive holds the victory back (until the air strike). */
static function bool Update()
{
	local LWX2HiveDef H;
	local XComGameState_LWX2Hive Hive;
	local XComGameState NewGameState;
	local array<LWX2HiveVolume> Vols;
	local array<LWX2HiveSpawn> All;
	local array<XComGameState_Unit> Squad;
	local XComGameState_Unit Unit;
	local vector At;
	local int i, Now, Stage;
	local bool bAlienTurnEnded, bXComTurnEnded, bAllIn, bAny;

	if (!Active(H))
		return true;
	Vols = VolumesOf(H.Level);
	Hive = State();
	if (Hive == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the Chryssalid hive");
		Hive = XComGameState_LWX2Hive(NewGameState.CreateNewStateObject(class'XComGameState_LWX2Hive'));
		Hive.Stage = 1;
		Hive.EnemyLevel = EnemyLevel();
		Hive.LastTurn = class'LWX2CovertExtraction'.static.TurnNow();
		Hive.StrikeLeft = H.Countdown;
		// (Filled item by item: a Length set from a function's array came out empty.)
		All = SpawnsOf(H.Level);
		for (i = 0; i < Vols.Length; i++)
		{
			Hive.Entered.AddItem(0);
			Hive.ExitArmed.AddItem(0);
		}
		for (i = 0; i < All.Length; i++)
			Hive.Spawned.AddItem(0);
		`TACTICALRULES.SubmitGameState(NewGameState);
		`log("LongWarX2: Chryssalid hive on" @ H.Map $ ": enemy level" @ Hive.EnemyLevel $ "," @ Vols.Length @ "volumes," @ Hive.Spawned.Length @ "scripted spawns", , 'LongWarX2');
		SpawnWhen(H, 0, -1, 0);
		return false;
	}
	if (Hive.Stage >= 5)
		return true;
	Squad = Seeing();
	Stage = Hive.Stage;
	// The objectives (InvestigateDistress → FindInfestation → ActivateBeacon): the whale seen starts the hive's turns.
	if (Stage <= 2 && PointSeen(Squad, H.Whale))
		Stage = 3;
	else if (Stage == 1 && (InfestationSeen(Squad) || PointSeen(Squad, H.Ship)))
		Stage = 2;
	// The turns: XCOM's turn begun again (the aliens' has ended); XCOM's turn over (the aliens' has begun).
	Now = class'LWX2CovertExtraction'.static.TurnNow();
	bAlienTurnEnded = Now != Hive.LastTurn;
	bXComTurnEnded = !bAlienTurnEnded && Hive.Stage == 4 && !XComTurn() && Hive.CountedTurn != Now;
	if (Stage != Hive.Stage || bAlienTurnEnded || bXComTurnEnded || Entering(Hive, Vols, Squad))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the hive's turn");
		Hive = XComGameState_LWX2Hive(NewGameState.ModifyStateObject(class'XComGameState_LWX2Hive', Hive.ObjectID));
		if (Stage != Hive.Stage)
			`log("LongWarX2: Chryssalid hive: objective" @ Hive.Stage @ "->" @ Stage, , 'LongWarX2');
		Hive.Stage = Stage;
		if (bAlienTurnEnded)
		{
			Hive.LastTurn = Now;
			if (Hive.Stage == 3)
				Hive.HiveTurn++;
		}
		if (bXComTurnEnded)
		{
			// (The turn the transponder came on is not counted: EW's FirstCountdownCheck.)
			Hive.CountedTurn = Now;
			if (Hive.bFirstCounted)
				Hive.StrikeLeft--;
			Hive.bFirstCounted = true;
		}
		for (i = 0; i < Vols.Length; i++)
			if (AnyInside(Squad, Vols[i]))
			{
				if (Hive.Entered[i] == 0 && Hive.Stage <= 2)
				{
					Hive.Entered[i] = 1;
					`log("LongWarX2: Chryssalid hive: volume" @ i @ "entered", , 'LongWarX2');
				}
				if (Hive.Stage == 4)
					Hive.ExitArmed[i] = 1;
			}
		`TACTICALRULES.SubmitGameState(NewGameState);
		Hive = State();
		for (i = 0; i < Vols.Length; i++)
			if (Hive.Entered[i] != 0)
				SpawnWhen(H, 1, i, 0);
		if (bAlienTurnEnded && Hive.Stage == 3)
			SpawnWhen(H, 2, -1, Hive.HiveTurn);
		if (bAlienTurnEnded && Hive.Stage == 4)
			for (i = 0; i < Vols.Length; i++)
				if (Hive.ExitArmed[i] != 0)
					SpawnWhen(H, 3, i, 0);
	}
	if (Hive.Stage != 4)
		return false;
	if (!Hive.bRunBegun)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the run to the EVAC");
		XComGameState_LWX2Hive(NewGameState.ModifyStateObject(class'XComGameState_LWX2Hive', Hive.ObjectID)).bRunBegun = true;
		`TACTICALRULES.SubmitGameState(NewGameState);
		RunBegun();
		Hive = State();
	}
	// The run: every soldier still standing in the EVAC volume (or evacuated), or the countdown out: the air strike.
	bAllIn = true;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() != eTeam_XCom || !Unit.IsSoldier() || !Unit.IsAlive())
			continue;
		bAny = true;
		if (Unit.bRemovedFromPlay)
			continue;
		At = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
		if (!Inside(H.EvacCenter, H.EvacExtent, At))
			bAllIn = false;
	}
	if ((bAny && bAllIn) || Hive.StrikeLeft <= 0)
		AirStrike(Hive, Hive.StrikeLeft <= 0 ? "the countdown ran out" : "the squad is at the EVAC");
	return false;
}

/** It is XCOM's turn (the unit actions' player is XCOM's). */
static function bool XComTurn()
{
	local XComGameState_Player Player;

	Player = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID));
	return Player == none || Player.GetTeam() == eTeam_XCom;
}

static function bool AnyInside(array<XComGameState_Unit> Squad, LWX2HiveVolume V)
{
	local XComGameState_Unit Unit;

	foreach Squad(Unit)
		if (Inside(V.Center, V.Extent, `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation)))
			return true;
	return false;
}

/** A soldier newly in a volume: one not yet entered (before the whale), or an exit not yet armed (on the run). */
static function bool Entering(XComGameState_LWX2Hive Hive, array<LWX2HiveVolume> Vols, array<XComGameState_Unit> Squad)
{
	local int i;

	for (i = 0; i < Vols.Length; i++)
		if (((Hive.Stage <= 2 && Hive.Entered[i] == 0) || (Hive.Stage == 4 && Hive.ExitArmed[i] == 0)) && AnyInside(Squad, Vols[i]))
			return true;
	return false;
}

/** The level's spawns of this kind (and volume, or hive turn) not yet made, at this EnemyLevel: each its alien, at its point.
 *  The Chryssalids come for the squad (EW's bRevealSpawn, bTriggerOverwatch); the zombies stand where they are put. */
static function SpawnWhen(LWX2HiveDef H, int When, int Volume, int Turn)
{
	local XComGameState_LWX2Hive Hive;
	local XComGameState NewGameState;
	local array<LWX2HiveSpawn> All;
	local array<int> Due, Before, Hunters;
	local array<name> Names;
	local array<int> Species;
	local XComGameState_Unit Unit;
	local int i;

	Hive = State();
	All = SpawnsOf(H.Level);
	for (i = 0; i < All.Length && i < Hive.Spawned.Length; i++)
	{
		if (Hive.Spawned[i] != 0 || All[i].When != When || (All[i].EnemyLevel >= 0 && All[i].EnemyLevel != Hive.EnemyLevel))
			continue;
		if ((When == 1 || When == 3) && All[i].Volume != Volume)
			continue;
		if (When == 2 && All[i].Turn != Turn)
			continue;
		Due.AddItem(i);
	}
	if (Due.Length == 0)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the hive's spawns");
	Hive = XComGameState_LWX2Hive(NewGameState.ModifyStateObject(class'XComGameState_LWX2Hive', Hive.ObjectID));
	foreach Due(i)
		Hive.Spawned[i] = 1;
	`TACTICALRULES.SubmitGameState(NewGameState);
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien)
			Before.AddItem(Unit.ObjectID);
	foreach Due(i)
	{
		Names.Length = 0;
		Species.Length = 0;
		Names.AddItem(class'LWMissionSquads'.static.TemplateFor(All[i].Char));
		Species.AddItem(All[i].Char);
		class'LWMissionSquads'.static.SpawnPod(name("LWX2_Hive" $ i), All[i].At, Names, Species);
	}
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && Before.Find(Unit.ObjectID) == INDEX_NONE && Unit.GetMyTemplate().CharacterGroupName == 'Chryssalid')
			Hunters.AddItem(Unit.ObjectID);
	if (Hunters.Length > 0)
		Hunt(Hunters);
	`log("LongWarX2: Chryssalid hive:" @ Due.Length @ "spawned (" $ When @ Volume @ Turn $ ")," @ Hunters.Length @ "hunting", , 'LongWarX2');
}

/** These aliens told where the squad is (a hostile alert at the nearest soldier: XCOM 2's way to set them on it). */
static function Hunt(array<int> Units)
{
	local XComGameState NewGameState;
	local XComGameState_AIUnitData Data, NewData;
	local XComGameState_Unit Unit, Soldier, Nearest;
	local AlertAbilityInfo Info;
	local float Best;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the hive's Chryssalids come");
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AIUnitData', Data)
	{
		if (Units.Find(Data.m_iUnitObjectID) == INDEX_NONE)
			continue;
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Data.m_iUnitObjectID));
		Nearest = none;
		Best = 1000000000.0;
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Soldier)
			if (Soldier.GetTeam() == eTeam_XCom && Soldier.IsAlive() && !Soldier.bRemovedFromPlay
				&& VSizeSq(`XWORLD.GetPositionFromTileCoordinates(Soldier.TileLocation) - `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation)) < Best)
			{
				Best = VSizeSq(`XWORLD.GetPositionFromTileCoordinates(Soldier.TileLocation) - `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation));
				Nearest = Soldier;
			}
		if (Nearest == none)
			continue;
		Info.AlertTileLocation = Nearest.TileLocation;
		Info.AlertRadius = 1000;
		Info.AlertUnitSourceID = Nearest.ObjectID;
		Info.AnalyzingHistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
		NewData = XComGameState_AIUnitData(NewGameState.ModifyStateObject(Data.Class, Data.ObjectID));
		NewData.AddAlertData(Data.m_iUnitObjectID, eAC_MapwideAlert_Hostile, Info, NewGameState, "LWX2Hive", true);
	}
	if (NewGameState.GetNumGameStateObjects() > 0)
		`TACTICALRULES.SubmitGameState(NewGameState);
	else
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
}

/** The transponder reactivated (X2Effect_LWX2Transponder): the run begins (RunLikeDickens), its spawns come, the EVAC shown. */
static function Reactivated(XComGameState NewGameState)
{
	local LWX2HiveDef H;
	local XComGameState_LWX2Hive Hive;

	Hive = State();
	if (Hive == none || !Active(H))
		return;
	Hive = XComGameState_LWX2Hive(NewGameState.ModifyStateObject(class'XComGameState_LWX2Hive', Hive.ObjectID));
	Hive.Stage = 4;
	Hive.StrikeLeft = H.Countdown;
	class'XComGameState_EvacZone'.static.PlaceEvacZone(NewGameState, class'LWX2CouncilVIP'.static.Floor(H.EvacCenter), eTeam_XCom);
	`log("LongWarX2: Chryssalid hive: the transponder is on; the strike craft in" @ H.Countdown @ "turns", , 'LongWarX2');
}

/** After the transponder's state is in: the run's own spawns, and the evac zone's flare. */
static function RunBegun()
{
	local LWX2HiveDef H;

	if (!Active(H))
		return;
	SpawnWhen(H, 4, -1, 0);
	if (class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom) != none)
	{
		class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).FindOrCreateVisualizer();
		class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).SyncVisualizer();
	}
}

/** The strike craft (Airstrike: KillSquad on the aliens, then WinBattleIfHuman). */
static function AirStrike(XComGameState_LWX2Hive Hive, string Why)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local int n;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the air strike on the hive");
	XComGameState_LWX2Hive(NewGameState.ModifyStateObject(class'XComGameState_LWX2Hive', Hive.ObjectID)).Stage = 5;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!Unit.IsAlive() || Unit.bRemovedFromPlay || Unit.GetTeam() != eTeam_Alien)
			continue;
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetCurrentStat(eStat_HP, 0);
		n++;
	}
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("LongWarX2: Chryssalid hive: air strike (" $ Why $ "):" @ n @ "aliens killed; the mission is won", , 'LongWarX2');
	if (!`TACTICALRULES.HasTacticalGameEnded())
		class'UIScreenListener_LongWarX2Tactical'.static.TestWin();
}

/** The objective as EW's handler shows it; on the run, with the count to the air strike. */
static function string ObjectiveText()
{
	local LWX2HiveDef H;
	local XComGameState_LWX2Hive Hive;
	local int k;

	if (!Active(H))
		return "";
	Hive = State();
	k = Hive != none ? Clamp(Hive.Stage - 1, 0, 3) : 0;
	if (k >= H.Texts.Length)
		return "";
	if (Hive != none && Hive.Stage == 4)
		return H.Texts[k] @ H.Strike @ Hive.StrikeLeft;
	return H.Texts[k];
}
