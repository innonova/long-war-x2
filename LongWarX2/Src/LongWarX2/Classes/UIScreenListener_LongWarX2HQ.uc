// On the Avenger of a campaign: a LONG WAR HQ button that opens the Long War headquarters screen
// (experiment 4), when its switch is on. (Shown by itself over the base view, the screen fought
// XCOM 2's popups: they take screens above the base view off the stack, and it came straight back,
// in a loop.)
class UIScreenListener_LongWarX2HQ extends UIScreenListener config(LWAirWar);

var config bool ShowLWHeadquarters;
/** For development: in a campaign's mission, a button that ends it as won. */
var config bool ShowTestEndMission;

event OnInit(UIScreen Screen)
{
	local UIButton Button;

	if (!default.ShowLWHeadquarters || UIAvengerHUD(Screen) == none)
		return;
	Button = Screen.Spawn(class'UIButton', Screen);
	Button.InitButton('LWX2HQButton', "LONG WAR HQ", OnOpen);
	Button.SetPosition(40, 120);
}

function OnOpen(UIButton Button)
{
	local XComHQPresentationLayer Pres;

	Pres = `HQPRES;
	if (Pres.ScreenStack.IsInStack(class'UILWHeadquarters'))
		return;
	Pres.ScreenStack.Push(Pres.Spawn(class'UILWHeadquarters', Pres));
	`log("LongWarX2: Long War HQ shown", , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = none;
}
