// Once XCOM 2 has generated a mission's map, the EW map placed as XCOM 2 level geometry and the
// tile data rebuilt before any unit is on the map (features/hard-parts.md, experiment 2). On the
// Tactical Quick Launch screen the screen rebuilds it when the battle starts; in a campaign's
// mission (bCampaign, spawned from the dropship's briefing) it is rebuilt at once, while the game
// waits for the player to launch. Either a part of it in front of the soldiers' spawn, or the whole map in
// place of the generated one: that one's geometry hidden and without collision, the EW play
// area centred in its level volume, the soldiers' spawn moved to an EW drop zone.
class LWX2PartPlacer extends Actor config(LWAirWar);

var UITacticalQuickLaunch Screen;
var vector Center;
var float Radius;
var vector Offset;
var bool bPlaced;
var bool bWhole;
var bool bCampaign;
/** Where the last part went: for the count in the battle, at the same place (config only so its default can be set; never saved). */
var config vector PlacedAt;
/** The whole EW map's shift from EW's coordinates to the mission's, once placed (for its pods: LWMissionSquads; never saved). */
var config vector EWShift;
var config bool bEWPlaced;
/** The fog of war on an EW map: ground not yet seen drawn as seen before (Enemy Within never blacked it out), and the two
 *  fog levels (0: XCOM 2's own) set on the world data once the map is placed. */
var config bool FogNeverSeenAsHaveSeen;
var config float FogNeverSeen;
var config float FogHaveSeen;
/** Each building's floors given their actors on an EW map's own plot (UIScreenListener_LongWarX2Dropship), for XCOM 2's building visibility. */
var config bool CacheBuildingFloors;

event Tick(float DeltaTime)
{
	local XComParcelManager Parcels;
	local XComWorldData World;
	local vector At;
	local array<Actor> Placed;

	if (bPlaced || (Screen == none && !bCampaign))
		return;
	Parcels = bCampaign ? `PARCELMGR : Screen.ParcelManager;
	if (Parcels == none || Parcels.IsGeneratingMap() || Parcels.SoldierSpawn == none || (bCampaign && !`MAPS.IsStreamingComplete()))
		return;
	bPlaced = true;
	World = `XWORLD;
	if (bWhole)
	{
		PlaceWhole(Parcels, World);
		return;
	}
	At = Parcels.SoldierSpawn.Location + Offset;
	At.Z = World.GetFloorZForPosition(Parcels.SoldierSpawn.Location);
	`log("LongWarX2: EW map part: before, cover points" @ class'LWX2EWMapPieces'.static.CountCover(World, At, Radius) $ ", tiles units cannot enter near its centre" @ class'LWX2EWMapPieces'.static.CountBlocked(World, At) @ "of 49", , 'LongWarX2');
	class'LWX2EWMapPieces'.static.Place(self, Center, Radius, At, class'LWX2LevelActor', Placed);
	Rebuild(Parcels);
	default.PlacedAt = At;
	`log("LongWarX2: EW map part placed at" @ At $ "; the tile data is rebuilt when the battle starts", , 'LongWarX2');
}

function PlaceWhole(XComParcelManager Parcels, XComWorldData World)
{
	local vector EWFloor, At, Mid, Size, Spawn, DropZone;
	local array<Actor> Placed;
	local int Hidden;
	local array<vector> DropZones;

	FitVolume(World);
	Mid = (World.WorldBounds.Min + World.WorldBounds.Max) * 0.5;
	Size = World.WorldBounds.Max - World.WorldBounds.Min;
	`log("LongWarX2: EW map whole: the generated map's level volume is" @ int(Size.X / 96) @ "x" @ int(Size.Y / 96) @ "x" @ int(Size.Z / 96) @ "tiles; EW's play area" @ int(2 * class'LWX2EWMapPieces'.static.Map().PlayExtent.X / 96) @ "x" @ int(2 * class'LWX2EWMapPieces'.static.Map().PlayExtent.Y / 96), , 'LongWarX2');
	// The generated map's geometry: hidden and without collision (its spawn points, volumes and lights stay).
	Hidden = HideForeign(self, World);
	// EW's floor (the bottom of its play area) on the generated map's floor at its spawn.
	EWFloor = class'LWX2EWMapPieces'.static.Map().PlayCenter;
	EWFloor.Z -= class'LWX2EWMapPieces'.static.Map().PlayExtent.Z;
	At = Mid;
	At.Z = World.GetFloorZForPosition(Parcels.SoldierSpawn.Location);
	class'LWX2EWMapPieces'.static.Place(self, EWFloor, 0, At, class'LWX2LevelActor', Placed, true);
	default.EWShift = At - EWFloor;
	default.bEWPlaced = true;
	class'LWX2EWMapPieces'.static.PlaceLights(self, default.EWShift);
	// The first EW drop zone inside the generated map's level volume (two tiles in from its edge).
	DropZones = class'LWX2EWMapPieces'.static.Map().DropZones;
	foreach DropZones(DropZone)
	{
		Spawn = At + DropZone - EWFloor;
		if (Spawn.X > World.WorldBounds.Min.X + 192 && Spawn.X < World.WorldBounds.Max.X - 192
			&& Spawn.Y > World.WorldBounds.Min.Y + 192 && Spawn.Y < World.WorldBounds.Max.Y - 192)
		{
			Parcels.SoldierSpawn.SetLocation(Spawn);
			if (Screen != none)
				Screen.BattleDataState.MapData.SoldierSpawnLocation = Spawn;
			break;
		}
	}
	// The tile data now (the quick launch screen rebuilds it again when the battle starts), so the
	// spawn can be moved off anything EW placed on its drop zone (a trailer's roof is floor too).
	Parcels.RebuildWorldData();
	// The ground looked for at the drop zone's own floor, not EW's lowest (a drop zone on a highway's deck stands far above it).
	Spawn = OpenGround(World, Parcels.SoldierSpawn.Location, World.GetFloorZForPosition(Parcels.SoldierSpawn.Location));
	Parcels.SoldierSpawn.SetLocation(Spawn);
	if (Screen != none)
		Screen.BattleDataState.MapData.SoldierSpawnLocation = Spawn;
	Rebuild(Parcels);
	Fog(World);
	default.PlacedAt = Spawn;
	`log("LongWarX2: EW map whole:" @ Hidden @ "actors of the generated map hidden; EW's map centred at" @ At $ "; the soldiers' spawn moved to" @ Parcels.SoldierSpawn.Location, , 'LongWarX2');
}

/**
 * XCOM 2's own geometry around the EW map (the plot's, its parcels', their cars, doors and other destructibles): hidden,
 * each component too (destructibles and the building visibility system show actors again), and without collision.
 * Ours, units, lights and volumes are left. Called when the map is placed and again when the battle starts, for what
 * arrived since. Returns how many it hid.
 */
static function int HideForeign(Actor Finder, XComWorldData World)
{
	local Actor A;
	local PrimitiveComponent Prim;
	local int Hidden;

	foreach Finder.AllActors(class'Actor', A)
	{
		if (LWX2LevelActor(A) != none || DynamicSMActor_Spawnable(A) != none)
			continue;
		if (StaticMeshActorBase(A) == none && DynamicSMActor(A) == none && FracturedStaticMeshActor(A) == none && !A.bWorldGeometry)
			continue;
		if (A.Location.X < World.WorldBounds.Min.X - 960 || A.Location.X > World.WorldBounds.Max.X + 960
			|| A.Location.Y < World.WorldBounds.Min.Y - 960 || A.Location.Y > World.WorldBounds.Max.Y + 960)
			continue;
		A.SetHidden(true);
		A.SetCollision(false, false);
		// Its components too: they block traces (the tile data is built by tracing) and draw on their own.
		foreach A.ComponentList(class'PrimitiveComponent', Prim)
		{
			Prim.SetHidden(true);
			Prim.SetTraceBlocking(false, false);
			Prim.SetActorCollision(false, false);
			Prim.SetBlockRigidBody(false);
		}
		Hidden++;
	}
	return Hidden;
}

/**
 * Every actor of the plot's buildings' floors reset to XCOM 2's uncut, shown state (cutdown 999999, cutout -999999, not
 * hideable): with its floors just cached, XCOM 2 left EW's buildings in its fully hidden state, and showed them again
 * only when told to (lw-missions.md, night log). Its building visibility cuts them from there as units and the cursor
 * move. Returns how many it reset.
 */
/**
 * Each building told which of the plot's actors are on which of its floors (RebuildCachedActors: the editor does it for
 * a plot it saves, the plot writer cannot), after the map is generated (cached during its generation, the game crashed).
 * Returns how many buildings.
 */
static function int CacheBuildings(Actor Finder)
{
	local XComBuildingVolume B;
	local int n, f, g, k, i;
	local bool bBelow;

	foreach Finder.AllActors(class'XComBuildingVolume', B)
	{
		B.CacheBuildingVolumeInChildrenFloorVolumes();
		B.CacheFloorCenterAndExtent();
		B.RebuildCachedActors();
		// Each floor caches every actor that reaches into it. XCOM 2's buildings are made of a piece per floor; EW's walls
		// are often one piece for the whole building (the ice cream shop's), so on every floor at once: viewed from the
		// ground floor, the floors above are cut out, and the whole wall with them (the person: "missing walls").
		// Such an actor is left on the lowest floor it is on, as XCOM 2's ground-floor walls are.
		for (f = B.Floors.Length - 1; f > 0; f--)
			for (k = B.Floors[f].m_aCachedActors.Length - 1; k >= 0; k--)
			{
				bBelow = false;
				for (g = 0; g < f && !bBelow; g++)
					for (i = 0; i < B.Floors[g].m_aCachedActors.Length && !bBelow; i++)
						bBelow = B.Floors[g].m_aCachedActors[i].ResidentActor == B.Floors[f].m_aCachedActors[k].ResidentActor;
				if (bBelow)
					B.Floors[f].m_aCachedActors.Remove(k, 1);
			}
		n++;
	}
	return n;
}

/**
 * The plot's doors added to the world's tile data again, as each door does in its PostBeginPlay: on a map's own plot
 * that ran before the tile data was built, so no door had its interaction points and no path went through a door
 * (lw-missions.md). Returns how many.
 */
/**
 * EW's walls placed as XCOM 2's breakable walls (ew-plot.ts: their Tag LWX2T_<EW toughness>) given XCOM 2's toughness
 * for EW's: masonry and wood as XCOM 2's standard walls, glass as its windows, metal and cars as its strong ones, the
 * rest as fragile. Returns a line for the log.
 */
static function string WallToughness(Actor Finder)
{
	local XComFracLevelActor Wall;
	local XComDestructibleActor_Toughness T;
	local string Kind, Path;
	local int n, Missing;

	foreach Finder.WorldInfo.AllActors(class'XComFracLevelActor', Wall)
	{
		if (Left(string(Wall.Tag), 6) != "LWX2T_")
			continue;
		Kind = Mid(string(Wall.Tag), 6);
		switch (Kind)
		{
			case "MASONRY": case "WOOD": Path = "Toughness.Toughness_STANDARD"; break;
			case "GLASS": Path = "Toughness.Toughness_WINDOW"; break;
			case "METAL": case "SMALLCAR": Path = "Toughness.Toughness_STRONG"; break;
			case "DECO": Path = "Toughness.Toughness_DECO"; break;
			default: Path = "Toughness_FRAGILE";
		}
		T = XComDestructibleActor_Toughness(DynamicLoadObject("GameData_Toughness_X2." $ Path, class'XComDestructibleActor_Toughness', true));
		if (T == none)
		{
			Missing++;
			continue;
		}
		Wall.Toughness = T;
		n++;
	}
	return n @ "walls given XCOM 2's toughness" $ (Missing > 0 ? "," @ Missing @ "not (no toughness object found)" : "");
}

static function int RegisterDoors(Actor Finder)
{
	local XComInteractiveLevelActor Door;
	local int n;

	foreach Finder.WorldInfo.AllActors(class'XComInteractiveLevelActor', Door)
	{
		`XWORLD.AddActorTileData(Door);
		n++;
	}
	return n;
}

static function int ShowBuildings(Actor Finder)
{
	local XComBuildingVolume B;
	local XComLevelActor A;
	local XComFracLevelActor W;
	local int f, k, n;

	foreach Finder.AllActors(class'XComBuildingVolume', B)
		for (f = 0; f < B.Floors.Length; f++)
			for (k = 0; k < B.Floors[f].m_aCachedActors.Length; k++)
			{
				// EW's breakable walls (ew-plot.ts) the same way: left cut out, they stood as ankle-high stubs.
				W = XComFracLevelActor(B.Floors[f].m_aCachedActors[k].ResidentActor);
				if (W != none)
				{
					W.SetHideableFlag(false);
					W.SetPrimitiveCutdownFlag(false);
					W.SetPrimitiveCutoutFlag(false);
					W.SetPrimitiveVisHeight(999999, -999999, 999999, 999999);
					n++;
					continue;
				}
				A = XComLevelActor(B.Floors[f].m_aCachedActors[k].ResidentActor);
				if (A == none)
					continue;
				A.SetHideableFlag(false);
				A.SetPrimitiveCutdownFlag(false);
				A.SetPrimitiveCutoutFlag(false);
				A.SetPrimitiveVisHeight(999999, -999999, 999999, 999999);
				if (A.StaticMeshComponent != none)
					A.StaticMeshComponent.SetHidden(false);
				n++;
			}
	return n;
}

/** The fog of war as configured (FogNeverSeenAsHaveSeen, FogNeverSeen, FogHaveSeen), and its levels logged. */
static function Fog(XComWorldData World)
{
	`log("LongWarX2: EW map: fog of war was: never seen" @ World.FOWNeverSeen $ ", have seen" @ World.FOWHaveSeen $ ", never seen shown as seen" @ World.bShowNeverSeenAsHaveSeen, , 'LongWarX2');
	// Only what differs is written: the fog is drawn on its own thread.
	if (World.bShowNeverSeenAsHaveSeen != default.FogNeverSeenAsHaveSeen)
		World.bShowNeverSeenAsHaveSeen = default.FogNeverSeenAsHaveSeen;
	if (default.FogNeverSeen > 0 && World.FOWNeverSeen != default.FogNeverSeen)
		World.FOWNeverSeen = default.FogNeverSeen;
	if (default.FogHaveSeen > 0 && World.FOWHaveSeen != default.FogHaveSeen)
		World.FOWHaveSeen = default.FogHaveSeen;
}

/**
 * The level volume (the playable space, which XCOM 2's tiles fill) stretched to hold EW's play area with two tiles to
 * spare on each side, where it is smaller (XCOM 2's empty test plot is 36 x 36 tiles; EW's maps run to over 70), and the
 * tile grid made again for it. The volume's centre stays.
 */
function FitVolume(XComWorldData World)
{
	local XComLevelVolume Volume;
	local vector Have, Need, Scale, Before;

	Volume = World.Volume;
	if (Volume == none)
		foreach AllActors(class'XComLevelVolume', Volume)
			break;
	if (Volume == none)
		return;
	Have = World.WorldBounds.Max - World.WorldBounds.Min;
	Need = 2 * class'LWX2EWMapPieces'.static.Map().PlayExtent + vect(384, 384, 0);
	Scale.X = FMax(1, Need.X / FMax(Have.X, 96));
	Scale.Y = FMax(1, Need.Y / FMax(Have.Y, 96));
	Scale.Z = FMax(1, Need.Z / FMax(Have.Z, 96));
	if (Scale.X == 1 && Scale.Y == 1 && Scale.Z == 1)
		return;
	Before = Have;
	Volume.SetDrawScale3D(Volume.DrawScale3D * Scale);
	World.BuildWorldData(Volume);
	Have = World.WorldBounds.Max - World.WorldBounds.Min;
	`log("LongWarX2: EW map whole: the level volume stretched by" @ Scale @ "from" @ int(Before.X / 96) @ "x" @ int(Before.Y / 96) @ "x" @ int(Before.Z / 96) @ "to" @ int(Have.X / 96) @ "x" @ int(Have.Y / 96) @ "x" @ int(Have.Z / 96) @ "tiles", , 'LongWarX2');
}

/**
 * The nearest point to Start (in rings of a tile, up to six tiles out) whose spawn area (the
 * floor tiles within two tiles, as XCOM 2's group spawn takes them) is all on the ground, at
 * GroundZ, holds six, and from each of whose tiles a unit can walk at least 40 tiles (not walled
 * in); else the one with the most ground and the least roof.
 */
function vector OpenGround(XComWorldData World, vector Start, float GroundZ)
{
	local vector Candidate, P;
	local array<vector> Points;
	local int Ring, Step, Steps, Ground, Best, Room;
	local vector BestPoint;
	local float Angle;

	BestPoint = Start;
	Best = -1;
	for (Ring = 0; Ring <= 6; Ring++)
	{
		Steps = Ring == 0 ? 1 : 8 * Ring;
		for (Step = 0; Step < Steps; Step++)
		{
			Angle = 2 * Pi * Step / Steps;
			Candidate = Start + vect(96, 0, 0) * Ring * Cos(Angle) + vect(0, 96, 0) * Ring * Sin(Angle);
			Candidate.Z = GroundZ + 64;
			Points.Length = 0;
			World.GetFloorTilePositions(Candidate, 192, 128, Points, true);
			Ground = 0;
			foreach Points(P)
				if (Abs(P.Z - GroundZ) < 48)
					Ground++;
			if (Ground == Points.Length && Ground >= 6)
			{
				// Room from every tile the squad may be put on, not only the centre.
				Room = 999;
				foreach Points(P)
					Room = Min(Room, RoomAround(World, P, GroundZ, 40));
				if (Room >= 40)
				{
					`log("LongWarX2: EW map: spawn on open ground" @ Ring @ "tiles from the drop zone (" $ Ground @ "floor tiles, each with room for" @ Room $ "+)", , 'LongWarX2');
					return Candidate;
				}
			}
			if (Ground - 2 * (Points.Length - Ground) > Best)
			{
				Best = Ground - 2 * (Points.Length - Ground);
				BestPoint = Candidate;
			}
		}
	}
	`log("LongWarX2: EW map: no open ground near the drop zone; the spawn with the most ground and the least roof (score " $ Best $ ")", , 'LongWarX2');
	return BestPoint;
}

/** The tile data rebuilt over the new geometry: by the quick launch screen when its battle starts, else now. */
function Rebuild(XComParcelManager Parcels)
{
	if (Screen != none)
	{
		Screen.bPathingNeedsRebuilt = true;
		return;
	}
	Parcels.RebuildWorldData();
	`log("LongWarX2: EW map: tile data rebuilt for the mission", , 'LongWarX2');
}

/**
 * How many ground tiles a unit at Where could walk to (a flood fill over enterable floor tiles at
 * GroundZ, four neighbours), counted up to Cap: whether the spot is walled in.
 */
function int RoomAround(XComWorldData World, vector Where, float GroundZ, int Cap)
{
	local array<TTile> Seen, Queue;
	local TTile T, N;
	local vector P;
	local int Head, d;
	local float FloorZ;

	Where.Z = GroundZ + 32;
	if (!World.GetFloorTileForPosition(Where, T, false))
		return 0;
	Seen.AddItem(T);
	Queue.AddItem(T);
	while (Head < Queue.Length && Seen.Length < Cap)
	{
		T = Queue[Head++];
		for (d = 0; d < 4; d++)
		{
			N = T;
			if (d == 0) N.X += 1;
			else if (d == 1) N.X -= 1;
			else if (d == 2) N.Y += 1;
			else N.Y -= 1;
			if (Seen.Find('X', N.X) != INDEX_NONE && Contains(Seen, N))
				continue;
			P = World.GetPositionFromTileCoordinates(N);
			FloorZ = World.GetFloorZForPosition(P);
			if (Abs(FloorZ - GroundZ) > 48 || !World.CanUnitsEnterTile(N))
				continue;
			Seen.AddItem(N);
			Queue.AddItem(N);
		}
	}
	return Seen.Length;
}

function bool Contains(const out array<TTile> Tiles, TTile T)
{
	local TTile X;

	foreach Tiles(X)
		if (X.X == T.X && X.Y == T.Y && X.Z == T.Z)
			return true;
	return false;
}

/**
 * Once the squad stands on the EW map (lw-missions.md, step 2): each soldier who can reach fewer than MinReach tiles
 * (boxed in by EW's walls and wrecks, which XCOM 2's group spawn does not see) is moved to the free floor tile
 * nearest to the soldier who can reach the most, among the tiles that soldier can reach. Returns how many moved;
 * -1 while the soldiers' paths are not known yet (none reaches MinReach: they have not taken their places).
 */
static function int FreeBoxedIn(optional int MinReach = 40)
{
	local XGUnit Unit, Best;
	local XComGameState_Unit UnitState;
	local array<XGUnit> Boxed;
	local array<TTile> Tiles, BestTiles, Taken;
	local TTile From, T, Pick;
	local XComGameState NewGameState;
	local int Most, Dist, Nearest, Moved;

	Taken.Length = 0;
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XGUnit', Unit)
	{
		UnitState = Unit.GetVisualizedGameState();
		if (UnitState == none || UnitState.GetTeam() != eTeam_XCom || !UnitState.IsAlive() || UnitState.bRemovedFromPlay || Unit.m_kReachableTilesCache == none)
			continue;
		Unit.m_kReachableTilesCache.ForceCacheUpdate();
		Unit.m_kReachableTilesCache.UpdateTileCacheIfNeeded();
		Tiles.Length = 0;
		Unit.m_kReachableTilesCache.GetAllPathableTiles(Tiles, 100000, true);
		if (Tiles.Length > Most)
		{
			Most = Tiles.Length;
			Best = Unit;
			BestTiles = Tiles;
		}
		if (Tiles.Length < MinReach)
			Boxed.AddItem(Unit);
	}
	if (Best == none || Most < MinReach)
		return -1;
	// The tiles units stand on (XComWorldData.IsTileOccupied counts more than units).
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
		if (!UnitState.bRemovedFromPlay && UnitState.IsAlive())
			Taken.AddItem(UnitState.TileLocation);
	`log("LongWarX2: EW map: boxed-in check:" @ Boxed.Length @ "soldiers reach fewer than" @ MinReach @ "tiles; the best reaches" @ Most, , 'LongWarX2');
	if (Boxed.Length == 0)
		return 0;
	From = Best.GetVisualizedGameState().TileLocation;
	foreach Boxed(Unit)
	{
		Nearest = MaxInt;
		foreach BestTiles(T)
		{
			if (TakenAt(Taken, T))
				continue;
			Dist = (T.X - From.X) * (T.X - From.X) + (T.Y - From.Y) * (T.Y - From.Y) + (T.Z - From.Z) * (T.Z - From.Z);
			if (Dist > 0 && Dist < Nearest)
			{
				Nearest = Dist;
				Pick = T;
			}
		}
		if (Nearest == MaxInt)
			break;
		Taken.AddItem(Pick);
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a soldier boxed in on the EW map moved");
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = class'LWMissionSquads'.static.BuildPodVisualization;
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		UnitState.bRequiresVisibilityUpdate = true;
		UnitState.SetVisibilityLocation(Pick);
		`TACTICALRULES.SubmitGameState(NewGameState);
		Moved++;
		`log("LongWarX2: EW map: soldier" @ UnitState.GetFullName() @ "boxed in, moved to tile" @ Pick.X $ "," $ Pick.Y $ "," $ Pick.Z @ "beside" @ Best.GetVisualizedGameState().GetFullName() @ "(who reaches" @ Most @ "tiles)", , 'LongWarX2');
	}
	return Moved;
}

/**
 * A squad none of whom can reach anywhere (XCOM 2's group spawn put every soldier on one doorway tile of
 * URB_StreetHurricane, 2026-11-05: FreeBoxedIn has no one to bring them beside): the first soldier moved to the nearest
 * free floor tile with at least MinOpen floor tiles units can enter around it (eleven by eleven); FreeBoxedIn, tried
 * again, then brings the others beside them. True if one moved.
 */
static function bool MoveOutOfPocket(optional int MinOpen = 40)
{
	local XComWorldData World;
	local XComGameState_Unit UnitState, Mover;
	local array<TTile> Taken;
	local TTile From, T, U;
	local XComGameState NewGameState;
	local int r, dx, dy, dz, ox, oy, ax, ay, Open;

	World = `XWORLD;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if (UnitState.bRemovedFromPlay || !UnitState.IsAlive())
			continue;
		Taken.AddItem(UnitState.TileLocation);
		if (Mover == none && UnitState.GetTeam() == eTeam_XCom && UnitState.IsSoldier())
			Mover = UnitState;
	}
	if (Mover == none)
		return false;
	From = Mover.TileLocation;
	for (r = 1; r <= 15; r++)
		for (dx = -r; dx <= r; dx++)
			for (dy = -r; dy <= r; dy++)
			{
				ax = dx < 0 ? -dx : dx;
				ay = dy < 0 ? -dy : dy;
				if (ax != r && ay != r)
					continue;
				for (dz = -1; dz <= 1; dz++)
				{
					T = From;
					T.X += dx;
					T.Y += dy;
					T.Z += dz;
					if (T.Z < 0 || TakenAt(Taken, T) || !World.IsFloorTileAndValidDestination(T, Mover))
						continue;
					Open = 0;
					for (ox = -5; ox <= 5; ox++)
						for (oy = -5; oy <= 5; oy++)
						{
							U = T;
							U.X += ox;
							U.Y += oy;
							if (World.IsFloorTileAndValidDestination(U, Mover))
								Open++;
						}
					if (Open < MinOpen)
						continue;
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a squad boxed in on the EW map, one soldier moved out");
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = class'LWMissionSquads'.static.BuildPodVisualization;
					UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Mover.ObjectID));
					UnitState.bRequiresVisibilityUpdate = true;
					UnitState.SetVisibilityLocation(T);
					`TACTICALRULES.SubmitGameState(NewGameState);
					`log("LongWarX2: EW map: the whole squad boxed in at" @ From.X $ "," $ From.Y $ "," $ From.Z $ ";" @ UnitState.GetFullName() @ "moved out to" @ T.X $ "," $ T.Y $ "," $ T.Z @ "(" $ Open @ "floor tiles around)", , 'LongWarX2');
					return true;
				}
			}
	`log("LongWarX2: EW map: the whole squad boxed in at" @ From.X $ "," $ From.Y $ "," $ From.Z $ "; no open floor within 15 tiles", , 'LongWarX2');
	return false;
}

static function bool TakenAt(array<TTile> Taken, TTile T)
{
	local TTile X;

	foreach Taken(X)
		if (X.X == T.X && X.Y == T.Y && X.Z == T.Z)
			return true;
	return false;
}

defaultproperties
{
	bHidden = true;
	bAlwaysTick = true; // the screen's world is paused
}
