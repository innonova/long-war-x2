// The air war in a campaign: a button on the geoscape opens it with the
// campaign's jets (XComGameState_LWAirWar) and the aliens' progress by month.
class UIScreenListener_LongWarX2Geoscape extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIButton Button;

	if (UIStrategyMap(Screen) == none || Screen.GetChildByName('LWX2AirWar', false) != none)
		return;
	class'XComGameState_LWAirWar'.static.EnsureExists();
	Button = Screen.Spawn(class'UIButton', Screen);
	Button.InitButton('LWX2AirWar', "LONG WAR: AIR WAR", OnAirWar);
	Button.SetPosition(40, 140);
	`log("LongWarX2: air war button on the geoscape", , 'LongWarX2');
}

simulated function OnAirWar(UIButton Button)
{
	local UILWInterception Screen;

	Screen = Button.Spawn(class'UILWInterception', Button.Movie.Pres);
	Screen.bCampaign = true;
	Button.Movie.Pres.ScreenStack.Push(Screen);
}

defaultproperties
{
	ScreenClass = none;
}
