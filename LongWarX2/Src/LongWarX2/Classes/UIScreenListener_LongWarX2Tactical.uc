// In a tactical mission, for the experiments (features/hard-parts.md), each behind its switch:
// an Enemy Within unit shown beside the first soldier (experiment 1), and the effect on the
// tile data of the EW map part placed on the Tactical Quick Launch screen (LWX2PartPlacer,
// experiment 2). Both need the player's converted packages in the mod's Content.
class UIScreenListener_LongWarX2Tactical extends UIScreenListener config(LWAirWar);

var config bool ShowEWUnit;
var config bool PlaceEWMapPart;
/** The part of the EW map (its coordinates): the pieces within the radius of the centre. */
var config vector PartCenter;
var config float PartRadius;
/** Where the part's centre goes, from the soldiers' spawn (its floor). */
var config vector PartOffset;

event OnInit(UIScreen Screen)
{
	local XComUnitPawn Pawn;
	local LWX2EWUnitDisplay Display;

	if (UITacticalHUD(Screen) == none)
		return;
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
	if (default.PlaceEWMapPart)
		ReportMapPart(Screen, Pawn);
	if (!default.ShowEWUnit)
		return;
	Display = Screen.WorldInfo.Spawn(class'LWX2EWUnitDisplay');
	if (!Display.ShowBeside(Pawn))
		Display.Destroy();
}

/** After the battle started: the EW map part's effect on the tile data, and whether its pieces collide. */
function ReportMapPart(UIScreen Screen, XComUnitPawn Pawn)
{
	local XComWorldData World;
	local LWX2LevelActor Piece;
	local vector At, HitLocation, HitNormal;
	local Actor Hit;
	local int n;

	World = `XWORLD;
	foreach Screen.WorldInfo.AllActors(class'LWX2LevelActor', Piece)
		n++;
	if (n == 0)
		return;
	At = class'LWX2PartPlacer'.default.PlacedAt;
	Hit = Screen.Trace(HitLocation, HitNormal, At - vect(0, 0, 200), At + vect(0, 0, 2000), false);
	`log("LongWarX2: EW map part in the battle:" @ n @ "pieces; at" @ At $ ", cover points" @ class'LWX2EWMapPieces'.static.CountCover(World, At, default.PartRadius) $ ", tiles units cannot enter near its centre" @ class'LWX2EWMapPieces'.static.CountBlocked(World, At) @ "of 49; a line down onto it hits" @ Hit @ "at" @ HitLocation, , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = none;
}
