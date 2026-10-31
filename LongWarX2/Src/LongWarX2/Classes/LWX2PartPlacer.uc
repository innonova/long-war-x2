// On the Tactical Quick Launch screen: once the screen has generated its map, part of the
// EW map placed in front of the soldiers' spawn as XCOM 2 level geometry, and the screen
// told to rebuild the tile data when the battle starts (the game's own path, before any
// unit is on the map) (features/hard-parts.md, experiment 2).
class LWX2PartPlacer extends Actor config(LWAirWar);

var UITacticalQuickLaunch Screen;
var vector Center;
var float Radius;
var vector Offset;
var bool bPlaced;
/** Where the last part went: for the count in the battle, at the same place (config only so its default can be set; never saved). */
var config vector PlacedAt;

event Tick(float DeltaTime)
{
	local XComParcelManager Parcels;
	local XComWorldData World;
	local vector At;
	local array<Actor> Placed;

	if (bPlaced || Screen == none)
		return;
	Parcels = Screen.ParcelManager;
	if (Parcels == none || Parcels.IsGeneratingMap() || Parcels.SoldierSpawn == none)
		return;
	bPlaced = true;
	World = `XWORLD;
	At = Parcels.SoldierSpawn.Location + Offset;
	At.Z = World.GetFloorZForPosition(Parcels.SoldierSpawn.Location);
	`log("LongWarX2: EW map part: before, cover points" @ class'LWX2EWMapPieces'.static.CountCover(World, At, Radius) $ ", tiles units cannot enter near its centre" @ class'LWX2EWMapPieces'.static.CountBlocked(World, At) @ "of 49", , 'LongWarX2');
	class'LWX2EWMapPieces'.static.Place(self, Center, Radius, At, class'LWX2LevelActor', Placed);
	Screen.bPathingNeedsRebuilt = true;
	default.PlacedAt = At;
	`log("LongWarX2: EW map part placed at" @ At $ "; the tile data is rebuilt when the battle starts", , 'LongWarX2');
}

defaultproperties
{
	bHidden = true;
	bAlwaysTick = true; // the screen's world is paused
}
