// An EXALT data recovery on its EW map (features/lw-exalt.md, Long War's XGBattle_SPCaptureAndHold, XComCapturePointVolume and
// the CNH levels' XComWaveSystem, read by tools/convert/ew-objectives.ts into XComLWX2EWObjectives.ini): EXALT comes in waves
// at the level's spawn points (the turns the wave system gives, after its set starts) and makes for the active capture area
// (XGOvermind.DetermineCaptureAndHoldTactics: a hunt target there). Each XCOM turn an area holds EXALT and no soldier, its
// capture goes a turn on; at its turns, it falls (the transmitter first, then the backup; a second set of waves comes as the
// first falls). Both fallen, the mission is lost. Every wave come and every EXALT soldier dead or taken, it is won; with the
// first area never fallen, Long War pays its extra (DataRecoveryCash).
class LWX2DataRecovery extends Object config(LWX2EWObjectives);

struct LWX2RecoveryDef
{
	var string Map;
	var string Level;
	var string Protect, Backup, Kill, Hint;
};

struct LWX2CapturePoint
{
	var string Level;
	var vector Center;
	var vector Extent;
	var int Turns;
	var int Seq;
};

struct LWX2WaveGroup
{
	var string Level;
	/** 0: from the start; 1: once the first area falls. */
	var int Set;
	var int Turn;
	var int Count;
	var array<vector> At;
};

var config array<LWX2RecoveryDef> Recoveries;
var config array<LWX2CapturePoint> Points;
var config array<LWX2WaveGroup> Groups;

static function bool Active(out LWX2RecoveryDef R)
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
	k = default.Recoveries.Find('Level', Mid(Battle.MapData.PlotMapName, 6));
	if (k == INDEX_NONE)
		return false;
	R = default.Recoveries[k];
	return true;
}

static function XComGameState_LWX2Recovery State()
{
	local XComGameState_LWX2Recovery R;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWX2Recovery', R)
		return R;
	return none;
}

static function array<LWX2CapturePoint> PointsOf(string Level)
{
	local array<LWX2CapturePoint> Out;
	local LWX2CapturePoint P;

	foreach default.Points(P)
		if (P.Level ~= Level)
			Out.AddItem(P);
	return Out;
}

static function array<LWX2WaveGroup> GroupsOf(string Level)
{
	local array<LWX2WaveGroup> Out;
	local LWX2WaveGroup G;

	foreach default.Groups(G)
		if (G.Level ~= Level)
			Out.AddItem(G);
	return Out;
}

/** The area EXALT is after now (IsActive: the first not fallen, in order), -1 when all have fallen. */
static function int ActivePoint(XComGameState_LWX2Recovery R)
{
	local int i;

	for (i = 0; i < R.Captured.Length; i++)
		if (!R.Captured[i])
			return i;
	return -1;
}

static function bool Inside(LWX2CapturePoint P, vector At)
{
	return Abs(At.X - P.Center.X) <= P.Extent.X && Abs(At.Y - P.Center.Y) <= P.Extent.Y && Abs(At.Z - P.Center.Z) <= P.Extent.Z + 64;
}

/** Asked twice a second in the mission (UIScreenListener_LongWarX2Tactical): at each new XCOM turn, the areas' capture and
 *  the waves due. False while waves are still to come (the mission is not won before). */
static function bool Update()
{
	local LWX2RecoveryDef Def;
	local XComGameState_LWX2Recovery R;
	local array<LWX2CapturePoint> Pts;
	local array<LWX2WaveGroup> Grps;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local vector At;
	local int Now, i, a, Aliens, Soldiers;
	local bool bDue;

	if (!Active(Def))
		return true;
	Pts = PointsOf(Def.Level);
	Grps = GroupsOf(Def.Level);
	R = State();
	Now = class'LWX2CovertExtraction'.static.TurnNow();
	if (R == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the data recovery");
		R = XComGameState_LWX2Recovery(NewGameState.CreateNewStateObject(class'XComGameState_LWX2Recovery'));
		R.Progress.Length = Pts.Length;
		R.Captured.Length = Pts.Length;
		R.SetStart.AddItem(Now);
		R.SetStart.AddItem(-1);
		R.GroupDone.Length = Grps.Length;
		R.LastTurn = Now;
		class'XComGameState_EvacZone'.static.PlaceEvacZone(NewGameState, class'LWX2CouncilVIP'.static.Floor(class'LWX2CovertExtraction'.static.Skyranger()), eTeam_XCom);
		`TACTICALRULES.SubmitGameState(NewGameState);
		if (class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom) != none)
		{
			class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).FindOrCreateVisualizer();
			class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).SyncVisualizer();
		}
		`log("LongWarX2: data recovery on" @ Def.Map $ ":" @ Pts.Length @ "capture areas," @ Grps.Length @ "wave groups", , 'LongWarX2');
		Hunt(Pts[0].Center);
		return false;
	}
	if (Now != R.LastTurn)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the data recovery's turn");
		R = XComGameState_LWX2Recovery(NewGameState.ModifyStateObject(class'XComGameState_LWX2Recovery', R.ObjectID));
		R.LastTurn = Now;
		// The capture (XComCapturePointVolume.UpdateCaptureState, AdvanceCapture): EXALT alone in the active area.
		a = ActivePoint(R);
		if (a >= 0)
		{
			foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
			{
				if (!Unit.IsAlive() || Unit.bRemovedFromPlay || Unit.GetMyTemplate().bIsCosmetic)
					continue;
				At = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
				if (!Inside(Pts[a], At))
					continue;
				if (Unit.GetTeam() == eTeam_Alien)
					Aliens++;
				else if (Unit.GetTeam() == eTeam_XCom)
					Soldiers++;
			}
			if (Aliens > 0 && Soldiers == 0)
			{
				R.Progress[a]++;
				`log("LongWarX2: data recovery: EXALT holds area" @ a @ "(" $ R.Progress[a] @ "of" @ Pts[a].Turns $ ")", , 'LongWarX2');
				if (R.Progress[a] >= Pts[a].Turns)
				{
					R.Captured[a] = true;
					`log("LongWarX2: data recovery: area" @ a @ "fell", , 'LongWarX2');
					if (a == 0)
					{
						R.SetStart[1] = Now;
						// (For Long War's extra cash: the first area did not hold.)
						XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID)).bPendingAreaLost = true;
					}
				}
			}
		}
		// The waves due (XComWaveSystem.UpdateWaveSpawning: the set's start plus the wave's turn).
		for (i = 0; i < Grps.Length; i++)
		{
			if (R.GroupDone[i] || R.SetStart[Grps[i].Set] < 0 || R.SetStart[Grps[i].Set] + Grps[i].Turn > Now)
				continue;
			R.GroupDone[i] = true;
			bDue = true;
		}
		`TACTICALRULES.SubmitGameState(NewGameState);
		R = State();
		if (bDue)
			SpawnDue(Grps, R, Now);
		if (ActivePoint(R) < 0)
		{
			if (!`TACTICALRULES.HasTacticalGameEnded())
			{
				`log("LongWarX2: data recovery: every area fell, the mission is lost", , 'LongWarX2');
				`TACTICALRULES.EndBattle(XGBattle_SP(`BATTLE).GetAIPlayer());
			}
			return false;
		}
		Hunt(Pts[ActivePoint(R)].Center);
	}
	for (i = 0; i < Grps.Length; i++)
		if (Grps[i].Set == 0 && !R.GroupDone[i])
			return false;
	return true;
}

/** The groups that came this turn: each its count of EXALT's soldiers (the mission's squad's kinds, as the wave system
 *  scales its groups from the mission's), at different spawn points of the group's. */
static function SpawnDue(array<LWX2WaveGroup> Grps, XComGameState_LWX2Recovery R, int Now)
{
	local XComGameState_LWStrategy S;
	local array<vector> Free;
	local array<name> Names;
	local array<int> Species;
	local int i, n, k, Kind;

	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = 0; i < Grps.Length; i++)
	{
		if (!R.GroupDone[i] || R.SetStart[Grps[i].Set] < 0 || R.SetStart[Grps[i].Set] + Grps[i].Turn != Now)
			continue;
		Free = Grps[i].At;
		for (n = 0; n < Grps[i].Count && Free.Length > 0; n++)
		{
			k = Rand(Free.Length);
			Kind = S.PendingSquad.Length > 0 ? S.PendingSquad[Rand(S.PendingSquad.Length)] : 24;
			Names.Length = 0;
			Species.Length = 0;
			Names.AddItem(class'LWMissionSquads'.static.TemplateFor(Kind));
			Species.AddItem(Kind);
			class'LWMissionSquads'.static.SpawnPod(name("LWX2_Wave" $ i $ "_" $ n), Free[k], Names, Species);
			Free.Remove(k, 1);
		}
		`log("LongWarX2: data recovery: wave group" @ i @ "came (" $ n @ "EXALT)", , 'LongWarX2');
	}
}

/** EXALT makes for the area (XGOvermind.DetermineCaptureAndHoldTactics's hunt target; XCOM 2's map-wide alert there). */
static function Hunt(vector Where)
{
	local XComGameState NewGameState;
	local XComGameState_AIUnitData Data, NewData;
	local XComGameState_Unit Unit;
	local AlertAbilityInfo Info;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: EXALT makes for the capture area");
	Info.AlertTileLocation = `XWORLD.GetTileCoordinatesFromPosition(Where);
	Info.AlertRadius = 1000;
	Info.AnalyzingHistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AIUnitData', Data)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Data.m_iUnitObjectID));
		if (Unit == none || !Unit.IsAlive() || Unit.GetTeam() != eTeam_Alien)
			continue;
		NewData = XComGameState_AIUnitData(NewGameState.ModifyStateObject(Data.Class, Data.ObjectID));
		NewData.AddAlertData(Data.m_iUnitObjectID, eAC_MapwideAlert_Hostile, Info, NewGameState, "LWX2CaptureArea", true);
	}
	if (NewGameState.GetNumGameStateObjects() > 0)
		`TACTICALRULES.SubmitGameState(NewGameState);
	else
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
}

/** Whether the first area held (Long War's "all points safe": the extra cash). */
static function bool FirstHeld()
{
	local XComGameState_LWX2Recovery R;

	R = State();
	return R != none && R.Captured.Length > 0 && !R.Captured[0];
}

static function string ObjectiveText()
{
	local LWX2RecoveryDef Def;
	local XComGameState_LWX2Recovery R;
	local array<LWX2CapturePoint> Pts;
	local array<LWX2WaveGroup> Grps;
	local int a, i;

	if (!Active(Def))
		return "";
	R = State();
	if (R == none)
		return Def.Protect @ Def.Hint;
	Pts = PointsOf(Def.Level);
	Grps = GroupsOf(Def.Level);
	a = ActivePoint(R);
	for (i = 0; i < Grps.Length; i++)
		if (Grps[i].Set == 0 && !R.GroupDone[i])
			return (a <= 0 ? Def.Protect : Def.Backup) @ "(" $ R.Progress[Max(a, 0)] @ "/" @ Pts[Max(a, 0)].Turns $ ")";
	return Def.Kill;
}
