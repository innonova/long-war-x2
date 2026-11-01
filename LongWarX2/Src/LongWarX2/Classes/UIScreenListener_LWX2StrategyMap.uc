// Long War's Geoscape in place of XCOM 2's world map (features/lw-geoscape.md): XCOM 2's strategy
// clock (dark events, supply drops, the Avatar project, its missions, healing and building) runs
// only while its world map is open, so the map is never left open. Whatever opens it (the Avenger's
// Geoscape button, the bridge), it is closed again the way its back button closes it, and Long
// War's Geoscape opens instead (LWX2StrategyMapRedirect). Its switch: ReplaceStrategyMap.
class UIScreenListener_LWX2StrategyMap extends UIScreenListener config(LWAirWar);

var config bool ReplaceStrategyMap;

event OnInit(UIScreen Screen)
{
	local LWX2StrategyMapRedirect Redirect;

	if (!default.ReplaceStrategyMap || UIStrategyMap(Screen) == none)
		return;
	Redirect = Screen.Spawn(class'LWX2StrategyMapRedirect');
	Redirect.Map = UIStrategyMap(Screen);
	`log("LongWarX2: XCOM 2's world map opened: Long War's Geoscape instead", , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = class'UIStrategyMap';
}
