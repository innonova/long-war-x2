// On the game's Tactical Quick Launch screen: an Enemy Within map's geometry placed
// beside where the screen generates its map, to look at with the screen's debug camera
// (features/hard-parts.md, experiment 2), when the switch is on. The screen draws the
// world only once a map is generated (which also brings the light): Generate Map, then
// Turn On Debug Camera.
class UIScreenListener_LongWarX2QuickLaunch extends UIScreenListener config(LWAirWar);

var config bool PlaceEWMap;
/** Where the map's origin goes: away from the map the screen generates (its lights still reach). */
var config vector Origin;
/** Where the screen's debug camera is held when it is turned on, from Origin: looking at the pieces. */
var config vector CameraPosition;
var config vector CameraDirection;

event OnInit(UIScreen Screen)
{
	local LWX2CameraHold Hold;
	local LWX2PartPlacer Placer;

	if (!default.PlaceEWMap || Screen.Class.Name != 'UITacticalQuickLaunch')
		return;
	class'LWX2EWMapPieces'.static.PlaceAll(Screen, default.Origin);
	// The debug camera, once turned on, held where the config says.
	Hold = Screen.Spawn(class'LWX2CameraHold', Screen.PC);
	`log("LongWarX2: camera hold" @ (Hold != none ? "spawned" : "NOT spawned") @ "for" @ Screen.PC, , 'LongWarX2');
	if (Hold == none)
		return;
	Hold.Screen = UITacticalQuickLaunch(Screen);
	Hold.View.Location = default.Origin + default.CameraPosition;
	Hold.View.Rotation = rotator(default.CameraDirection);
	Hold.View.FOV = 70;
	if (class'UIScreenListener_LongWarX2Tactical'.default.PlaceEWMapPart)
	{
		Placer = Screen.Spawn(class'LWX2PartPlacer', Screen.PC);
		Placer.Screen = UITacticalQuickLaunch(Screen);
		Placer.Center = class'UIScreenListener_LongWarX2Tactical'.default.PartCenter;
		Placer.Radius = class'UIScreenListener_LongWarX2Tactical'.default.PartRadius;
		Placer.Offset = class'UIScreenListener_LongWarX2Tactical'.default.PartOffset;
	}
}

defaultproperties
{
	ScreenClass = none;
}
