// The air war from the main menu, with a demo jet (no campaign): for trying the
// rules and the screen quickly (features/hard-parts.md, experiment 3). And,
// for testing only, a new campaign that skips the first mission (the game's own
// "Debug NonCheat Start"): it starts at the Avenger, nothing else changed.
class UIScreenListener_LongWarX2Shell extends UIScreenListener config(LWAirWar);

/** The test campaign's button; for development, never in a release. */
var config bool ShowTestCampaign;
/** An Enemy Within map to open as it is (experiment 2), with its URL options. */
var config string TestMapURL;

event OnInit(UIScreen Screen)
{
	local UIButton Button;

	if (UIShell(Screen) == none || UIShell(Screen).GetChildByName('LWX2AirWarDemo', false) != none)
		return;
	Button = Screen.Spawn(class'UIButton', Screen);
	Button.InitButton('LWX2AirWarDemo', "LONG WAR: AIR WAR (DEMO)", OnAirWar);
	Button.SetPosition(40, 40);
	if (default.ShowTestCampaign)
	{
		Button = Screen.Spawn(class'UIButton', Screen);
		Button.InitButton('LWX2TestCampaign', "TEST CAMPAIGN (NO FIRST MISSION)", OnTestCampaign);
		Button.SetPosition(40, 90);
		Button = Screen.Spawn(class'UIButton', Screen);
		Button.InitButton('LWX2TestTactical', "TEST TACTICAL (QUICK LAUNCH)", OnTestTactical);
		Button.SetPosition(40, 140);
		if (default.TestMapURL != "")
		{
			Button = Screen.Spawn(class'UIButton', Screen);
			Button.InitButton('LWX2TestMap', "TEST EW MAP", OnTestMap);
			Button.SetPosition(40, 190);
		}
	}
	`log("LongWarX2: air war button on" @ Screen.Class.Name, , 'LongWarX2');
}

/** The game's own tactical quick launch (what the development menu's "Tactical" opens). */
simulated function OnTestTactical(UIButton Button)
{
	`XCOMHISTORY.ResetHistory(, false);
	Button.ConsoleCommand("open TacticalQuickLaunch");
	`log("LongWarX2: test tactical: TacticalQuickLaunch", , 'LongWarX2');
}

/** Experiment 2: an Enemy Within map, converted on this machine (tools/convert/ew-package.ts), opened as it is. */
simulated function OnTestMap(UIButton Button)
{
	`log("LongWarX2: test map: open" @ default.TestMapURL, , 'LongWarX2');
	Button.ConsoleCommand("open" @ default.TestMapURL);
}

simulated function OnTestCampaign(UIButton Button)
{
	local XComShellPresentationLayer Pres;
	local UIShellStrategy Strategy;

	Pres = XComShellPresentationLayer(Button.Movie.Pres);
	`XCOMHISTORY.ResetHistory();
	Pres.UIStrategyShell();
	Strategy = UIShellStrategy(Pres.ScreenStack.GetScreen(class'UIShellStrategy'));
	Strategy.m_bSkipFirstTactical = true;
	Pres.UIDifficulty();
	`log("LongWarX2: test campaign: difficulty next, the first mission skipped", , 'LongWarX2');
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
