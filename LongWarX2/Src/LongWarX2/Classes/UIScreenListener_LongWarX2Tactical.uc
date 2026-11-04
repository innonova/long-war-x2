// In a tactical mission, for the experiments (features/hard-parts.md), each behind its switch:
// an Enemy Within unit shown beside the first soldier (experiment 1), and the effect on the
// tile data of the EW map part placed on the Tactical Quick Launch screen (LWX2PartPlacer,
// experiment 2). Both need the player's converted packages in the mod's Content.
class UIScreenListener_LongWarX2Tactical extends UIScreenListener config(LWAirWar);

var config bool ShowEWUnit;
var config bool PlaceEWMapPart;
/** The whole EW map in place of the generated one (instead of a part). */
var config bool PlaceEWMapWhole;
/** Long War's squad written into XCOM 2's alien encounters before the map loads (LWMissionSquads.ApplyTo). */
var config bool SquadsInEncounters;
/** The part of the EW map (its coordinates): the pieces within the radius of the centre. */
var config vector PartCenter;
var config float PartRadius;
/** Where the part's centre goes, from the soldiers' spawn (its floor). */
var config vector PartOffset;
var int BoxedTries;
/** An empty objective line (its struct defaults), for LongWarObjectives. */
var ObjectiveDisplayInfo ObjectiveTemplate;
var bool bSwept;

event OnInit(UIScreen Screen)
{
	local XComUnitPawn Pawn;
	local LWX2EWUnitDisplay Display;

	if (UIMissionSummary(Screen) != none)
	{
		CountCivilians();
		class'LWExperience'.static.MissionOver();
		FieldSurgeon();
	}
	if (UITacticalHUD(Screen) == none)
		return;
	class'LWX2PerkProbe'.static.Start(Screen);
	if (class'UIScreenListener_LongWarX2HQ'.default.ShowTestEndMission && XGBattle_SP(`BATTLE) != none && !`BATTLE.m_kDesc.bIsTacticalQuickLaunch)
		AddEndButton(Screen);
	// A mission of the Long War Geoscape is won when its aliens are all dead or taken (lw-missions.md); so is any mission
	// on an EW map's own plot (the campaign's first did not count as one: its squad is not known yet when the HUD
	// comes up).
	`log("LongWarX2: missions: the HUD is up; Long War's squad" @ class'LWMissionSquads'.static.SquadNow().Length @ "aliens, on an EW map's own plot" @ class'LWX2EWMapPieces'.static.OnOwnPlot(), , 'LongWarX2');
	if (class'LWMissionSquads'.static.SquadNow().Length > 0 || class'LWX2EWMapPieces'.static.OnOwnPlot())
	{
		bSwept = false;
		Screen.SetTimer(2.0, true, nameof(CheckSwept), self);
		NoTimer();
		// On XCOM 2's maps: the squad's aliens whose pods found no room.
		class'LWMissionSquads'.static.TopUp();
		class'LWMeld'.static.Place();
		class'LWFatigue'.static.MarkAllIn();
	}
	foreach Screen.WorldInfo.AllActors(class'LWX2EWUnitDisplay', Display)
		return;
	foreach Screen.WorldInfo.AllActors(class'XComUnitPawn', Pawn)
	{
		if (XComHumanPawn(Pawn) != none)
			break;
	}
	`log("LongWarX2: tactical HUD; first soldier pawn" @ Pawn, , 'LongWarX2');
	if (Pawn == none)
		return;
	// On an Enemy Within map, Long War's pods at its places (lw-missions.md, step 2).
	if (class'LWX2EWMapPieces'.static.HasMap())
	{
		// XCOM 2's geometry that arrived after the map was placed (or was shown again since), hidden; on the EW map's own
		// plot there is none (and its pieces are XCOM 2 level actors themselves).
		if (!class'LWX2EWMapPieces'.static.OnOwnPlot())
			`log("LongWarX2: EW map: at the battle's start," @ class'LWX2PartPlacer'.static.HideForeign(Screen, `XWORLD) @ "of XCOM 2's actors hidden (again)", , 'LongWarX2');
		if (class'LWX2EWMapPieces'.static.OnOwnPlot() && class'LWX2PartPlacer'.default.CacheBuildingFloors)
			`log("LongWarX2: EW map: at the battle's start," @ class'LWX2PartPlacer'.static.CacheBuildings(Screen) @ "buildings' floors cached," @ class'LWX2PartPlacer'.static.ShowBuildings(Screen) @ "of their actors shown", , 'LongWarX2');
		// EW's doors (XComInteractiveLevelActors in the plot) known to the tile data, so paths go through them.
		if (class'LWX2EWMapPieces'.static.OnOwnPlot())
			`log("LongWarX2: EW map: at the battle's start," @ class'LWX2PartPlacer'.static.RegisterDoors(Screen) @ "doors added to the tile data;" @ class'LWX2PartPlacer'.static.WallToughness(Screen), , 'LongWarX2');
		// (The fog of war is set before the battle, at the dropship: changed while it is being drawn, the game died now and
		// then right here, on the person's machine.)
		class'LWMissionSquads'.static.SpawnAtEWPods();
		class'LWMissionSquads'.static.SpawnCivilians();
		// Enemy Within's bodies on the aliens already on the field (a loaded battle; the pods spawned get theirs as they come).
		`log("LongWarX2: EW bodies:" @ class'LWX2EWBodies'.static.ApplyAll() @ "units given Enemy Within's body", , 'LongWarX2');
		// Soldiers boxed in by EW's walls moved out, once their paths are known.
		BoxedTries = 0;
		Screen.SetTimer(3.0, true, nameof(FreeBoxedIn), self);
	}
	if (default.PlaceEWMapPart || class'LWX2EWMapPieces'.static.HasMap())
	{
		ReportMapPart(Screen, Pawn);
		Screen.SetTimer(40.0, false, nameof(ReportReach), self);
	}
	if (!default.ShowEWUnit)
		return;
	Display = Screen.WorldInfo.Spawn(class'LWX2EWUnitDisplay');
	if (!Display.ShowBeside(Pawn))
		Display.Destroy();
}

/** For development (experiment 4): a button that ends a campaign's mission as won, through the ruleset, as XCOM 2's cheat does. */
function AddEndButton(UIScreen Screen)
{
	local UIButton Button;

	Button = Screen.Spawn(class'UIButton', Screen);
	Button.InitButton('LWX2EndMission', "LONG WAR: WIN THIS MISSION", OnEndMission);
	Button.SetPosition(40, 200);
}

function OnEndMission(UIButton Button)
{
	TestWin();
}

/** For development: the mission ended as won (its button; LWX2Control's "win"). */
/**
 * Long War's missions have no turn limit: XCOM 2's mission timer suspended for the whole mission, as War of the Chosen
 * suspends it while the squad is concealed. Missions whose timer is their point refuse it (XCOM 2's
 * DisallowUITimerSuspension). Once a mission (the HUD can come up again after a load).
 */
static function NoTimer()
{
	local XComGameState NewGameState;
	local XComGameState_UITimer Timer;

	Timer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_UITimer', true));
	if (Timer != none && Timer.IsSuspended())
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: no mission timer");
	class'XComGameState_UITimer'.static.SuspendTimer(false, NewGameState);
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("LongWarX2: missions: XCOM 2's mission timer suspended (Long War's missions have none)", , 'LongWarX2');
}

/**
 * Long War's Field Surgeon (XGBattle_SP.PutSoldiersOnDropship): with a soldier who has it coming home (alive, not
 * critically wounded, not left behind), every soldier coming home so heals as if their lowest health in the mission had
 * been one higher; more than one such medic gives no more. XCOM 2 heals from LowestHP when the summary is closed
 * (XComGameState_Unit.EndTacticalHealthMod), so it is raised here, as the summary opens.
 */
static function FieldSurgeon()
{
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	local array<XComGameState_Unit> Home;
	local bool bSurgeon;
	local int n;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!Unit.IsSoldier() || Unit.GetTeam() != eTeam_XCom || !Unit.IsAlive() || Unit.IsBleedingOut() || Unit.IsUnconscious() || Unit.bCaptured)
			continue;
		Home.AddItem(Unit);
		if (Unit.HasSoldierAbility('LW_FieldSurgeon'))
			bSurgeon = true;
	}
	if (!bSurgeon)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Field Surgeon");
	foreach Home(Unit)
	{
		if (Unit.LowestHP >= Unit.HighestHP)
			continue;
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.LowestHP += 1;
		`log("LongWarX2: perks: Field Surgeon:" @ Unit.GetFullName() @ "heals as from" @ Unit.LowestHP @ "of" @ Unit.HighestHP, , 'LongWarX2');
		n++;
	}
	if (n > 0)
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	else
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
}

/**
 * A Long War terror mission ended: its civilians counted for Long War's result (XComGameState_LWStrategy.TerrorWon). The
 * civilians of this mission are those with a pawn here (the dead keep theirs); Faceless posing as civilians are not counted.
 */
static function CountCivilians()
{
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	local int All, Saved;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.PendingKind != 4 || S.PendingCivilians >= 0)
		return;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetMyTemplate() == none || !Unit.GetMyTemplate().bIsCivilian || Unit.GetMyTemplateName() == 'FacelessCivilian' || Unit.GetVisualizer() == none)
			continue;
		All++;
		if (Unit.IsAlive())
			Saved++;
	}
	`log("LongWarX2: missions: terror mission over," @ Saved @ "of" @ All @ "civilians alive", , 'LongWarX2');
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: civilians counted");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	S.PendingCivilians = All;
	S.PendingCiviliansSaved = Saved;
	// The tactical game has ended: its rules take no more changes, the history does.
	`XCOMHISTORY.AddGameStateToHistory(NewGameState);
}

/**
 * Long War's missions get no reinforcements: XCOM 2's reinforcement spawners (ADVENT, called by its missions' kismet)
 * waiting to land have their countdown put out of reach. One that lands at once (countdown 0) is not caught.
 */
static function NoReinforcements()
{
	local XComGameState_AIReinforcementSpawner Spawner;
	local XComGameState NewGameState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AIReinforcementSpawner', Spawner)
	{
		if (Spawner.Countdown <= 0 || Spawner.Countdown >= 90 || Spawner.SpawnedUnitIDs.Length > 0)
			continue;
		if (NewGameState == none)
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: no reinforcements");
		Spawner = XComGameState_AIReinforcementSpawner(NewGameState.ModifyStateObject(class'XComGameState_AIReinforcementSpawner', Spawner.ObjectID));
		`log("LongWarX2: missions: XCOM 2's reinforcements (" $ Spawner.SpawnInfo.EncounterID $ ", in" @ Spawner.Countdown @ "turns) held back", , 'LongWarX2');
		Spawner.Countdown = 99;
	}
	if (NewGameState != none)
		`TACTICALRULES.SubmitGameState(NewGameState);
}

/**
 * Long War's rule for its missions: when the aliens that came are all dead or taken (none alive on the field, after
 * at least one was there), the mission is won, as by the test button (XCOM 2's objectives counted as done). XCOM 2
 * leaves victory to each mission's kismet, which on an Enemy Within map has nothing to act on.
 */
function CheckSwept()
{
	local XComGameState_Unit Unit;
	local int Came, Alive;

	if (bSwept || `TACTICALRULES == none || `TACTICALRULES.HasTacticalGameEnded())
		return;
	NoReinforcements();
	LongWarObjectives();
	// Units that came after the pods (a Chryssalid's zombie, a spawn of XCOM 2's) given their EW body too.
	class'LWX2EWBodies'.static.ApplyAll();
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() != eTeam_Alien || Unit.GetMyTemplate().bIsCosmetic)
			continue;
		Came++;
		if (Unit.IsAlive() && !Unit.bRemovedFromPlay)
			Alive++;
	}
	if (Came == 0 || Alive > 0)
		return;
	bSwept = true;
	if (HUD() != none)
		HUD().ClearTimer(nameof(CheckSwept), self);
	`log("LongWarX2: missions: all" @ Came @ "aliens dead or taken: the mission is won", , 'LongWarX2');
	TestWin();
}

/**
 * On an Enemy Within map, the objective list shows Long War's objective in place of the XCOM 2 mission's (a device to
 * protect, charges to plant: things that are not on the map), each time XCOM 2's kismet writes its own. Not on a terror
 * mission: XCOM 2's terror objective counts the civilians, as Long War's does.
 */
static function LongWarObjectives()
{
	local XComGameState_ObjectivesList List;
	local XComGameState_BattleData Battle;
	local ObjectiveDisplayInfo Info;
	local XComGameState NewGameState;
	local bool bOurs, bOthers;

	if (!class'LWX2EWMapPieces'.static.HasMap())
		return;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (Battle == none || Battle.MapData.ActiveMission.sType == "Terror")
		return;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_ObjectivesList', List)
		break;
	if (List != none)
	{
		foreach List.ObjectiveDisplayInfos(Info)
		{
			if (Info.MissionType == "LongWarX2")
				bOurs = true;
			else if (!Info.GPObjective)
				bOthers = true;
		}
		if (bOurs && !bOthers)
			return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Long War's objective");
	// The mission's own objective map has no kismet, so nothing made the list (XCOM 2's mission scripts do): made here.
	if (List == none)
		List = XComGameState_ObjectivesList(NewGameState.CreateNewStateObject(class'XComGameState_ObjectivesList'));
	else
		List = XComGameState_ObjectivesList(NewGameState.ModifyStateObject(class'XComGameState_ObjectivesList', List.ObjectID));
	List.ClearTacticalObjectives();
	Info = default.ObjectiveTemplate;
	Info.MissionType = "LongWarX2";
	Info.DisplayLabel = "Kill or capture every alien";
	Info.ShowCheckBox = true;
	List.SetObjectiveDisplay(Info);
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("LongWarX2: missions: the objective list shows Long War's objective", , 'LongWarX2');
}

static function TestWin()
{
	local XComGameState NewGameState;
	local XComGameState_BattleData Battle;
	local int i;

	// XCOM 2 counts a mission won by its objectives (the mission source's WasMissionSuccessful): all done first.
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: test mission won");
	Battle = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', Battle.ObjectID));
	for (i = 0; i < Battle.MapData.ActiveMission.MissionObjectives.Length; i++)
		Battle.MapData.ActiveMission.MissionObjectives[i].bCompleted = true;
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("LongWarX2: test: mission ended as won", , 'LongWarX2');
	`TACTICALRULES.EndBattle(XGBattle_SP(`BATTLE).GetHumanPlayer());
}

/** After the battle started: the EW map's effect on the tile data around the placement, and whether its pieces collide. */
function ReportMapPart(UIScreen Screen, XComUnitPawn Pawn)
{
	local XComWorldData World;
	local LWX2LevelActor Piece;
	local vector At, HitLocation, HitNormal, FloorPos, Probe;
	local Actor Hit;
	local TTile Centre, T;
	local int n, dx, dy, Floors, Enterable;
	local XGUnit Unit;
	local array<TTile> Reachable;

	World = `XWORLD;
	foreach Screen.WorldInfo.AllActors(class'LWX2LevelActor', Piece)
		n++;
	if (n == 0)
		return;
	At = class'LWX2PartPlacer'.default.PlacedAt;
	Hit = Screen.Trace(HitLocation, HitNormal, At - vect(0, 0, 400), At + vect(0, 0, 2000), false);
	Centre = World.GetTileCoordinatesFromPosition(At);
	for (dx = -7; dx <= 7; dx++)
		for (dy = -7; dy <= 7; dy++)
		{
			T = Centre;
			T.X += dx;
			T.Y += dy;
			Probe = World.GetPositionFromTileCoordinates(T);
			if (World.GetFloorTileForPosition(Probe, T, true))
			{
				Floors++;
				if (World.GetFloorPositionForTile(T, FloorPos) && World.CanUnitsEnterTile(T))
					Enterable++;
			}
		}
	Unit = XGUnit(Pawn.GetGameUnit());
	if (Unit != none && Unit.m_kReachableTilesCache != none)
	{
		Unit.m_kReachableTilesCache.UpdateTileCacheIfNeeded();
		Unit.m_kReachableTilesCache.GetAllPathableTiles(Reachable);
	}
	`log("LongWarX2: EW map in the battle: the first soldier" @ Unit @ "can reach" @ Reachable.Length @ "tiles; the line hits" @ (StaticMeshActor(Hit) != none ? string(StaticMeshActor(Hit).StaticMeshComponent.StaticMesh) : "-") @ "collide" @ Hit.bCollideActors @ "block" @ Hit.bBlockActors @ "hidden" @ Hit.bHidden, , 'LongWarX2');
	`log("LongWarX2: EW map in the battle:" @ n @ "pieces; around" @ At @ "(tile" @ Centre.X $ "," $ Centre.Y $ "," $ Centre.Z $ "): floor tiles" @ Floors @ "of 225, enterable" @ Enterable $ "; cover points" @ class'LWX2EWMapPieces'.static.CountCover(World, At, default.PartRadius) $ "; a line down hits" @ Hit @ "at" @ HitLocation $ "; the first soldier at" @ Pawn.Location, , 'LongWarX2');
}

/** Of the tiles 1 to 5 tiles away from the unit (a ring of 120), how many its path cache says it can reach. */
function int CountReachableAround(XGUnit Unit)
{
	local XComWorldData World;
	local TTile Centre, T;
	local vector Probe;
	local int dx, dy, n;

	World = `XWORLD;
	Probe = Unit.GetPawn().Location;
	Centre = World.GetTileCoordinatesFromPosition(Probe);
	for (dx = -5; dx <= 5; dx++)
		for (dy = -5; dy <= 5; dy++)
		{
			if (dx == 0 && dy == 0)
				continue;
			T = Centre;
			T.X += dx;
			T.Y += dy;
			Probe = World.GetPositionFromTileCoordinates(T);
			if (World.GetFloorTileForPosition(Probe, T, true) && Unit.m_kReachableTilesCache.IsTileReachable(T))
				n++;
		}
	return n;
}

/**
 * The tactical HUD, looked up when a timer on it is to be cleared. The listener outlives the mission, so it holds no
 * screen: one held would keep the mission's world from being freed (XCOM 2 then stops: "not cleaned up by garbage
 * collection").
 */
static function UIScreen HUD()
{
	local XComTacticalController Controller;

	Controller = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	return (Controller != none && Controller.Pres != none) ? Controller.Pres.ScreenStack.GetFirstInstanceOf(class'UITacticalHUD') : none;
}

/** Tried every 3 seconds, for a minute at most, until the soldiers' paths are known. */
function FreeBoxedIn()
{
	local int Moved;

	Moved = class'LWX2PartPlacer'.static.FreeBoxedIn();
	`log("LongWarX2: EW map: boxed-in try" @ BoxedTries @ "->" @ Moved, , 'LongWarX2');
	if ((Moved >= 0 || ++BoxedTries >= 20) && HUD() != none)
		HUD().ClearTimer(nameof(FreeBoxedIn), self);
}

/** Later, once the mission has settled: how far each soldier can move. */
function ReportReach()
{
	local XGUnit Unit;
	local array<TTile> Reachable;
	local string Out;

	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XGUnit', Unit)
	{
		if (Unit.m_kReachableTilesCache == none)
			continue;
		Unit.m_kReachableTilesCache.ForceCacheUpdate();
		Unit.m_kReachableTilesCache.UpdateTileCacheIfNeeded();
		Reachable.Length = 0;
		Unit.m_kReachableTilesCache.GetAllPathableTiles(Reachable, 100000, false);
		Out @= Unit.GetVisualizedGameState().GetMyTemplateName() $ ":" $ Reachable.Length $ "/" $ CountReachableAround(Unit);
	}
	`log("LongWarX2: EW map in the battle, later: tiles each unit can reach:" $ Out, , 'LongWarX2');
	ReportPerks();
}

/** Each soldier of a Long War class: its Long War effects in play (features/lw-classes.md). */
function ReportPerks()
{
	local XComGameState_Unit Unit;
	local name Effect;
	local string Out;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Left(string(Unit.GetSoldierClassTemplateName()), 4) != "LWS_")
			continue;
		Out = "";
		foreach Unit.AffectedByEffectNames(Effect)
			if (Left(string(Effect), 3) == "LW_")
				Out @= string(Effect);
		`log("LongWarX2: Long War perks in play:" @ Unit.GetFullName() @ "(" $ Unit.GetSoldierClassTemplateName() @ "rank" @ Unit.GetRank() $ "): aim" @ Unit.GetCurrentStat(eStat_Offense) @ "mobility" @ Unit.GetCurrentStat(eStat_Mobility) $ ";" $ Out, , 'LongWarX2');
	}
}

defaultproperties
{
	ScreenClass = none;
}
