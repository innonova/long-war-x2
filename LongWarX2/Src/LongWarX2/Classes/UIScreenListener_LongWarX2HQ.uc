// On the Avenger of a campaign: the Long War headquarters screen (experiment 4) on top, when its
// switch is on; once each time the strategy game starts (a campaign's start, a load, the return
// from a mission), when the base view (the facility grid) comes up or gets the focus back.
class UIScreenListener_LongWarX2HQ extends UIScreenListener config(LWAirWar);

var config bool ShowLWHeadquarters;

event OnInit(UIScreen Screen)
{
	TryShow(Screen);
}

event OnReceiveFocus(UIScreen Screen)
{
	TryShow(Screen);
}

function TryShow(UIScreen Screen)
{
	local XComHQPresentationLayer Pres;

	if (!default.ShowLWHeadquarters || UIFacilityGrid(Screen) == none)
		return;
	Pres = `HQPRES;
	if (Pres == none || Pres.ScreenStack.IsInStack(class'UILWHeadquarters') || class'LWX2SessionMarker'.static.Seen(Pres, 'LWHeadquartersShown'))
		return;
	Pres.ScreenStack.Push(Pres.Spawn(class'UILWHeadquarters', Pres));
	`log("LongWarX2: Long War HQ shown", , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = none;
}
