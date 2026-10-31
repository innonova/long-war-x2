// On the game's Tactical Quick Launch screen (an empty world until a map is generated):
// an Enemy Within map's geometry placed at the origin, to look at with its debug
// camera (features/hard-parts.md, experiment 2), when the switch is on.
class UIScreenListener_LongWarX2QuickLaunch extends UIScreenListener config(LWAirWar);

var config bool PlaceEWMap;
/** Where the screen's debug camera starts when it is turned on: looking at the pieces. */
var config vector CameraPosition;
var config vector CameraDirection;

event OnInit(UIScreen Screen)
{
	local UITacticalQuickLaunch Launch;

	if (!default.PlaceEWMap || Screen.Class.Name != 'UITacticalQuickLaunch')
		return;
	class'LWX2EWMapPieces'.static.PlaceAll(Screen, vect(0, 0, 0));
	Launch = UITacticalQuickLaunch(Screen);
	Launch.DefaultCameraPosition = default.CameraPosition;
	Launch.DefaultCameraDirection = Normal(default.CameraDirection);
	Launch.bShouldInitCamera = true;
}

defaultproperties
{
	ScreenClass = none;
}
