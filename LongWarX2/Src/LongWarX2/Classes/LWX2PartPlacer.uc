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
	local Actor A;
	local PrimitiveComponent Prim;
	local int Hidden;

	Mid = (World.WorldBounds.Min + World.WorldBounds.Max) * 0.5;
	Size = World.WorldBounds.Max - World.WorldBounds.Min;
	`log("LongWarX2: EW map whole: the generated map's level volume is" @ int(Size.X / 96) @ "x" @ int(Size.Y / 96) @ "x" @ int(Size.Z / 96) @ "tiles; EW's play area" @ int(2 * class'LWX2EWMapPieces'.default.PlayExtent.X / 96) @ "x" @ int(2 * class'LWX2EWMapPieces'.default.PlayExtent.Y / 96), , 'LongWarX2');
	// The generated map's geometry: hidden and without collision (its spawn points, volumes and lights stay).
	foreach AllActors(class'Actor', A)
	{
		if (LWX2LevelActor(A) != none || DynamicSMActor_Spawnable(A) != none)
			continue;
		if (StaticMeshActorBase(A) == none && DynamicSMActor(A) == none && !A.bWorldGeometry)
			continue;
		if (A.Location.X < World.WorldBounds.Min.X - 960 || A.Location.X > World.WorldBounds.Max.X + 960
			|| A.Location.Y < World.WorldBounds.Min.Y - 960 || A.Location.Y > World.WorldBounds.Max.Y + 960)
			continue;
		A.SetHidden(true);
		A.SetCollision(false, false);
		// Its components too: they block traces (the tile data is built by tracing) on their own.
		foreach A.ComponentList(class'PrimitiveComponent', Prim)
		{
			Prim.SetTraceBlocking(false, false);
			Prim.SetActorCollision(false, false);
			Prim.SetBlockRigidBody(false);
		}
		Hidden++;
	}
	// EW's floor (the bottom of its play area) on the generated map's floor at its spawn.
	EWFloor = class'LWX2EWMapPieces'.default.PlayCenter;
	EWFloor.Z -= class'LWX2EWMapPieces'.default.PlayExtent.Z;
	At = Mid;
	At.Z = World.GetFloorZForPosition(Parcels.SoldierSpawn.Location);
	class'LWX2EWMapPieces'.static.Place(self, EWFloor, 0, At, class'LWX2LevelActor', Placed, true);
	// The first EW drop zone inside the generated map's level volume (two tiles in from its edge).
	foreach class'LWX2EWMapPieces'.default.DropZones(DropZone)
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
	Spawn = OpenGround(World, Parcels.SoldierSpawn.Location, At.Z);
	Parcels.SoldierSpawn.SetLocation(Spawn);
	if (Screen != none)
		Screen.BattleDataState.MapData.SoldierSpawnLocation = Spawn;
	Rebuild(Parcels);
	default.PlacedAt = Spawn;
	`log("LongWarX2: EW map whole:" @ Hidden @ "actors of the generated map hidden; EW's map centred at" @ At $ "; the soldiers' spawn moved to" @ Parcels.SoldierSpawn.Location, , 'LongWarX2');
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

defaultproperties
{
	bHidden = true;
	bAlwaysTick = true; // the screen's world is paused
}
