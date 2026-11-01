// XCOM 2's world map closed as soon as it lets itself be (its camera transition done), then Long
// War's Geoscape opened (UIScreenListener_LWX2StrategyMap).
class LWX2StrategyMapRedirect extends Actor;

var UIStrategyMap Map;
var float Waited;

event Tick(float DeltaTime)
{
	local XComHQPresentationLayer HQ;

	Waited += DeltaTime;
	HQ = `HQPRES;
	if (Map != none && HQ.ScreenStack.IsInStack(class'UIStrategyMap'))
	{
		// Paused at once, so no XCOM 2 time passes; closed when the geoscape allows it.
		`GAME.GetGeoscape().Pause();
		if (Waited > 0.5 && `GAME.GetGeoscape().CanExit() && HQ.ScreenStack.GetCurrentScreen() == Map)
			Map.CloseScreen();
		if (Waited < 30)
			return;
	}
	if (!HQ.ScreenStack.IsInStack(class'UILWGeoscape'))
		HQ.ScreenStack.Push(HQ.Spawn(class'UILWGeoscape', HQ));
	Destroy();
}

defaultproperties
{
	bAlwaysTick = true;
}
