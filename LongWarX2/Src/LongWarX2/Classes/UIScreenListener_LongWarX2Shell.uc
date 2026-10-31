// The air war from the main menu, with a demo jet (no campaign): for trying the
// rules and the screen quickly (features/hard-parts.md, experiment 3).
class UIScreenListener_LongWarX2Shell extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIButton Button;

	if (UIShell(Screen) == none || UIShell(Screen).GetChildByName('LWX2AirWarDemo', false) != none)
		return;
	Button = Screen.Spawn(class'UIButton', Screen);
	Button.InitButton('LWX2AirWarDemo', "LONG WAR: AIR WAR (DEMO)", OnAirWar);
	Button.SetPosition(40, 40);
	`log("LongWarX2: air war button on" @ Screen.Class.Name, , 'LongWarX2');
}

simulated function OnAirWar(UIButton Button)
{
	local UILWInterception Screen;

	Screen = Button.Spawn(class'UILWInterception', Button.Movie.Pres);
	Button.Movie.Pres.ScreenStack.Push(Screen);
}

defaultproperties
{
	ScreenClass = none;
}
