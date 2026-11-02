// Long War's alien squads in XCOM 2's missions (features/lw-missions.md): a mission sent from the Long War Geoscape is
// fought against the squad Long War gives it (LWAlienSquads: by UFO, kind of mission, day, the aliens' resources and
// aggression), its species as XCOM 2's nearest aliens (LWStrategyRules.FightAs, APPROXIMATION until Enemy Within's
// aliens are units). XCOM 2's mission keeps its pods' number and places (its map's); Long War's aliens are shared out
// among them, the first alien (the commander) in the first pod. Pods that are not aliens' (a VIP, a strategy unit)
// are left as they are.
class LWMissionSquads extends Object dependson(LWStrategyRules, LWX2EWMapPieces);

/** The patrol zone of a pod spawned at Enemy Within's pod (tiles a side). */
const ZoneTiles = 16;

static function name TemplateFor(int Char)
{
	local int k;

	k = class'LWStrategyRules'.default.FightAs.Find('Char', Char);
	return k == INDEX_NONE ? 'Sectoid' : class'LWStrategyRules'.default.FightAs[k].Template;
}

/** The mission's pods given Long War's squad (the mission site in the change being built, its pods cached first). */
static function ApplyTo(XComGameState_MissionSite Mission, array<int> Squad)
{
	local array<int> Pods;
	local int i, k, p, n, Size;

	if (!class'UIScreenListener_LongWarX2Tactical'.default.SquadsInEncounters)
	{
		`log("LongWarX2: missions: Long War's squad not written into XCOM 2's encounters (SquadsInEncounters off)", , 'LongWarX2');
		return;
	}
	Mission.UpdateSelectedMissionData();
	for (i = 0; i < Mission.SelectedMissionData.SelectedEncounters.Length; i++)
		if (Mission.SelectedMissionData.SelectedEncounters[i].EncounterSpawnInfo.Team == eTeam_Alien
			&& Mission.SelectedMissionData.SelectedEncounters[i].EncounterSpawnInfo.StrategyUnitTag == '')
			Pods.AddItem(i);
	if (Pods.Length == 0 || Squad.Length == 0)
		return;
	for (p = 0; p < Pods.Length; p++)
	{
		i = Pods[p];
		Mission.SelectedMissionData.SelectedEncounters[i].EncounterSpawnInfo.SelectedCharacterTemplateNames.Length = 0;
		// An even share, the first pods taking the remainder.
		Size = Squad.Length / Pods.Length + (p < Squad.Length % Pods.Length ? 1 : 0);
		for (n = 0; n < Size && k < Squad.Length; n++)
			Mission.SelectedMissionData.SelectedEncounters[i].EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem(TemplateFor(Squad[k++]));
		Mission.SelectedMissionData.SelectedEncounters[i].EncounterSpawnInfo.MaxGroupSize = Max(1, Size);
	}
	`log("LongWarX2: missions: Long War's squad of" @ Squad.Length @ "in" @ Pods.Length @ "pods", , 'LongWarX2');
}

/**
 * On an Enemy Within map (the whole map placed in the mission: XCOM 2's pods spawn nowhere there), Long War's squad
 * spawned at Enemy Within's pods (step 2): the commander's pod first, the aliens shared out among the pods that
 * hold any (their Max), each pod unaware of XCOM, its turn begun as a pod's at the start. Once a mission, when no
 * alien is on the field.
 */
static function SpawnAtEWPods()
{
	local XComGameState_LWStrategy S;
	local array<LWX2EWMapPieces.LWX2Pod> Pods;
	local LWX2EWMapPieces.LWX2Pod Pod;
	local XComGameState_Unit Unit;
	local array<name> Names, Levels;
	local name Level;
	local int i, k, n, Size;
	local array<LWX2EWMapPieces.LWX2Pod> MapPods;
	local array<int> Squad;

	MapPods = class'LWX2EWMapPieces'.static.Map().Pods;
	Levels.AddItem('Stream');
	Levels.AddItem('EWI');
	Levels.AddItem('Any');
	S = class'XComGameState_LWStrategy'.static.Get();
	Squad = SquadNow();
	if (!class'LWX2PartPlacer'.default.bEWPlaced || Squad.Length == 0)
		return;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && Unit.IsAlive() && !Unit.bRemovedFromPlay)
			return;
	// The map's own pods and its always streamed sub-level's; else the abduction ones (the map's, its EWI variant's); else any.
	foreach Levels(Level)
	{
		foreach MapPods(Pod)
			if (Pod.Max > 0 && (Level == 'Any' || Pod.Level == Level || Level == 'Stream' && Pod.Level == '' || Level == 'EWI' && Pod.Level == 'Abduction'))
			{
				if (Pod.Commander)
					Pods.InsertItem(0, Pod);
				else
					Pods.AddItem(Pod);
			}
		if (Pods.Length > 0)
			break;
	}
	if (Pods.Length == 0)
		Pods = MapPods;
	if (Pods.Length == 0)
		return;
	for (i = 0; i < Pods.Length; i++)
	{
		Names.Length = 0;
		Size = Squad.Length / Pods.Length + (i < Squad.Length % Pods.Length ? 1 : 0);
		for (n = 0; n < Size && k < Squad.Length; n++)
			Names.AddItem(TemplateFor(Squad[k++]));
		if (Names.Length > 0)
			SpawnPod(name("LWX2_EWPod" $ i), Pods[i].Loc + class'LWX2PartPlacer'.default.EWShift, Names);
	}
	`log("LongWarX2: missions: Long War's squad of" @ Squad.Length @ "spawned at" @ Pods.Length @ "of Enemy Within's pods", , 'LongWarX2');
}

/**
 * The squad of the mission under way: the one Long War chose for it (XComGameState_LWStrategy.PendingSquad); on the
 * campaign's first mission (XCOM 2's, on an EW map's own plot, before Long War's Geoscape exists) Long War's first
 * mission squad (LWAlienSquads.FirstMissionSquad); else none.
 */
static function array<int> SquadNow()
{
	local XComGameState_LWStrategy S;
	local array<int> Empty;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S != none && S.PendingSquad.Length > 0)
		return S.PendingSquad;
	if (S == none && class'LWX2EWMapPieces'.static.OnOwnPlot())
		return class'LWAlienSquads'.static.FirstMissionSquad();
	return Empty;
}

/**
 * On XCOM 2's maps: those of Long War's squad that did not come (XCOM 2 places a pod whole or not at all, and its pods
 * are made for fewer aliens than Long War's squads share into them) spawned as pods of up to 4 beside aliens already
 * on the field. Once a mission: every alien that came stays in the history, dead or taken.
 */
static function TopUp()
{
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local array<XComGameState_Unit> Field;
	local array<name> Names;
	local vector At;
	local int Came, Missing, k, n, Pod;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.PendingSquad.Length == 0 || class'LWX2PartPlacer'.default.bEWPlaced)
		return;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && !Unit.GetMyTemplate().bIsCosmetic)
		{
			Came++;
			if (Unit.IsAlive() && !Unit.bRemovedFromPlay)
				Field.AddItem(Unit);
		}
	Missing = S.PendingSquad.Length - Came;
	if (Missing <= 0 || Field.Length == 0)
		return;
	`log("LongWarX2: missions:" @ Missing @ "of Long War's squad of" @ S.PendingSquad.Length @ "did not come (XCOM 2's pods too small): spawned beside the others", , 'LongWarX2');
	// The squad's last ones (which pods failed is not known: the squad is shared out in order).
	for (k = S.PendingSquad.Length - Missing; k < S.PendingSquad.Length; k += n)
	{
		Names.Length = 0;
		for (n = 0; n < 4 && k + n < S.PendingSquad.Length; n++)
			Names.AddItem(TemplateFor(S.PendingSquad[k + n]));
		At = `XWORLD.GetPositionFromTileCoordinates(Field[Pod % Field.Length].TileLocation);
		At.X += (Pod % 2 == 0 ? 3 : -3) * class'XComWorldData'.const.WORLD_StepSize;
		At.Y += (Pod % 3 == 0 ? 3 : -3) * class'XComWorldData'.const.WORLD_StepSize;
		SpawnPod(name("LWX2_TopUp" $ Pod), At, Names);
		Pod++;
	}
}

/** A pod of these templates at a location (XComAISpawnManager.SpawnPodAtLocation), shown, its turn begun. */
static function SpawnPod(name EncounterID, vector Location, array<name> Templates)
{
	local XComGameState NewGameState;
	local PodSpawnInfo Info;
	local XGAIGroup Group;
	local XComWorldData World;
	local XComGameState_Unit Unit;
	local XComGameState_AIUnitData AIData;

	World = `XWORLD;
	// Inside the tile grid, two tiles in from its edge: XCOM 2's spawner is given no place it cannot hold (an EW pod in
	// a sub-level can stand beyond the play area the plot's grid covers).
	if (Location.X < World.WorldBounds.Min.X + 192 || Location.X > World.WorldBounds.Max.X - 192
		|| Location.Y < World.WorldBounds.Min.Y + 192 || Location.Y > World.WorldBounds.Max.Y - 192)
	{
		`log("LongWarX2: missions: pod" @ EncounterID @ "at" @ Location @ "is outside the tile grid; moved inside", , 'LongWarX2');
		Location.X = FClamp(Location.X, World.WorldBounds.Min.X + 192, World.WorldBounds.Max.X - 192);
		Location.Y = FClamp(Location.Y, World.WorldBounds.Min.Y + 192, World.WorldBounds.Max.Y - 192);
	}
	Location.Z = FClamp(Location.Z, World.WorldBounds.Min.Z + 32, World.WorldBounds.Max.Z - 32);
	Location.Z = World.GetFloorZForPosition(Location);
	Info.Team = eTeam_Alien;
	Info.EncounterID = EncounterID;
	Info.SpawnLocation = Location;
	Info.SelectedCharacterTemplateNames = Templates;
	Info.MaxGroupSize = Templates.Length;
	// Its patrol zone around where it stands: XCOM 2's pods patrol between the corners of their encounter zone.
	ZoneAround(Location, Info);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a Long War pod at Enemy Within's place");
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildPodVisualization;
	Group = `SPAWNMGR.SpawnPodAtLocation(NewGameState, Info, false, false, true);
	// Each alien's AI data (the spawn manager makes none mid-mission; XCOM 2's reinforcements get theirs after
	// spawning): without it the AI never moves the pod.
	foreach NewGameState.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && Unit.GetAIUnitDataID() < 0)
		{
			AIData = XComGameState_AIUnitData(NewGameState.CreateNewStateObject(class'XComGameState_AIUnitData'));
			AIData.Init(Unit.ObjectID);
		}
	`TACTICALRULES.SubmitGameState(NewGameState);
	if (XGAIPlayer(`BATTLE.GetAIPlayer()) != none)
		XGAIPlayer(`BATTLE.GetAIPlayer()).RebuildUnitAIIDList();
	if (Group != none)
		Group.InitTurn();
	// The AI's patrol groups (made at the mission's start) told of the new one.
	if (XGAIPlayer(`BATTLE.GetAIPlayer()) != none && XGAIPlayer(`BATTLE.GetAIPlayer()).m_kNav != none)
		XGAIPlayer(`BATTLE.GetAIPlayer()).m_kNav.RefreshGroups();
	`log("LongWarX2: missions: pod" @ EncounterID @ "of" @ Templates.Length @ "at" @ Location @ (Group != none ? "spawned" : "FAILED"), , 'LongWarX2');
}

/**
 * An encounter zone of ZoneTiles x ZoneTiles holding Location: XCOM 2 builds a pod's zone from the line of play (from
 * XCOM to the objective) and offsets from it and along it, in tiles; the offsets are found by trying.
 */
static function ZoneAround(vector Location, out PodSpawnInfo Info)
{
	local XComGameState_BattleData BattleData;
	local XComAISpawnManager SpawnManager;
	local EncounterZone Zone;
	local vector Objective, XCom;
	local float Along, From;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	SpawnManager = `SPAWNMGR;
	Objective = BattleData.MapData.ObjectiveLocation;
	XCom = SpawnManager.GetCurrentXComLocation();
	Info.EncounterZoneWidth = ZoneTiles;
	Info.EncounterZoneDepth = ZoneTiles;
	for (Along = -80; Along <= 80; Along += 4)
		for (From = -60; From <= 60; From += 4)
		{
			Zone = class'XComAISpawnManager'.static.BuildEncounterZone(Objective, XCom, ZoneTiles, ZoneTiles, From, Along, '');
			if (class'XComAISpawnManager'.static.PointInEncounterZone(Location, Zone))
			{
				Info.EncounterZoneOffsetAlongLOP = Along;
				Info.EncounterZoneOffsetFromLOP = From;
				return;
			}
		}
	`log("LongWarX2: missions: no encounter zone found around" @ Location, , 'LongWarX2');
}

/** The spawned aliens' visualizers made and put where they are. */
static function BuildPodVisualization(XComGameState VisualizeGameState)
{
	local XComGameState_Unit Unit;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetVisualizer() == none)
			Unit.FindOrCreateVisualizer();
		Unit.SyncVisualizer();
	}
}
