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
	Rebuild(Parcels);
	default.PlacedAt = Spawn;
	`log("LongWarX2: EW map whole:" @ Hidden @ "actors of the generated map hidden; EW's map centred at" @ At $ "; the soldiers' spawn moved to" @ Parcels.SoldierSpawn.Location, , 'LongWarX2');
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

defaultproperties
{
	bHidden = true;
	bAlwaysTick = true; // the screen's world is paused
}
