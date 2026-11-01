// Long War's alien squads in XCOM 2's missions (features/lw-missions.md): a mission sent from the Long War Geoscape is
// fought against the squad Long War gives it (LWAlienSquads: by UFO, kind of mission, day, the aliens' resources and
// aggression), its species as XCOM 2's nearest aliens (LWStrategyRules.FightAs, APPROXIMATION until Enemy Within's
// aliens are units). XCOM 2's mission keeps its pods' number and places (its map's); Long War's aliens are shared out
// among them, the first alien (the commander) in the first pod. Pods that are not aliens' (a VIP, a strategy unit)
// are left as they are.
class LWMissionSquads extends Object dependson(LWStrategyRules, LWX2EWMapPieces);

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
	local array<name> Names;
	local int i, k, n, Size;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (!class'LWX2PartPlacer'.default.bEWPlaced || S == none || S.PendingSquad.Length == 0)
		return;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && Unit.IsAlive() && !Unit.bRemovedFromPlay)
			return;
	foreach class'LWX2EWMapPieces'.default.Pods(Pod)
		if (Pod.Max > 0)
		{
			if (Pod.Commander)
				Pods.InsertItem(0, Pod);
			else
				Pods.AddItem(Pod);
		}
	if (Pods.Length == 0)
		Pods = class'LWX2EWMapPieces'.default.Pods;
	if (Pods.Length == 0)
		return;
	for (i = 0; i < Pods.Length; i++)
	{
		Names.Length = 0;
		Size = S.PendingSquad.Length / Pods.Length + (i < S.PendingSquad.Length % Pods.Length ? 1 : 0);
		for (n = 0; n < Size && k < S.PendingSquad.Length; n++)
			Names.AddItem(TemplateFor(S.PendingSquad[k++]));
		if (Names.Length > 0)
			SpawnPod(name("LWX2_EWPod" $ i), Pods[i].Loc + class'LWX2PartPlacer'.default.EWShift, Names);
	}
	`log("LongWarX2: missions: Long War's squad of" @ S.PendingSquad.Length @ "spawned at" @ Pods.Length @ "of Enemy Within's pods", , 'LongWarX2');
}

/** A pod of these templates at a location (XComAISpawnManager.SpawnPodAtLocation), shown, its turn begun. */
static function SpawnPod(name EncounterID, vector Location, array<name> Templates)
{
	local XComGameState NewGameState;
	local PodSpawnInfo Info;
	local XGAIGroup Group;
	local XComWorldData World;

	World = `XWORLD;
	Location.Z = World.GetFloorZForPosition(Location);
	Info.Team = eTeam_Alien;
	Info.EncounterID = EncounterID;
	Info.SpawnLocation = Location;
	Info.SelectedCharacterTemplateNames = Templates;
	Info.MaxGroupSize = Templates.Length;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a Long War pod at Enemy Within's place");
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildPodVisualization;
	Group = `SPAWNMGR.SpawnPodAtLocation(NewGameState, Info, false, false, true);
	`TACTICALRULES.SubmitGameState(NewGameState);
	if (Group != none)
		Group.InitTurn();
	`log("LongWarX2: missions: pod" @ EncounterID @ "of" @ Templates.Length @ "at" @ Location @ (Group != none ? "spawned" : "FAILED"), , 'LongWarX2');
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
