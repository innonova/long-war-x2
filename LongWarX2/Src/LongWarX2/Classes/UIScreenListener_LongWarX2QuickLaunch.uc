// On the game's Tactical Quick Launch screen (an empty world until a map is generated):
// an Enemy Within map's geometry placed at the origin, to look at with its debug
// camera (features/hard-parts.md, experiment 2), when the switch is on.
class UIScreenListener_LongWarX2QuickLaunch extends UIScreenListener config(LWAirWar);

var config bool PlaceEWMap;

event OnInit(UIScreen Screen)
{
	if (!default.PlaceEWMap || Screen.Class.Name != 'UITacticalQuickLaunch')
		return;
	class'LWX2EWMapPieces'.static.PlaceAll(Screen, vect(0, 0, 0));
}

defaultproperties
{
	ScreenClass = none;
}
