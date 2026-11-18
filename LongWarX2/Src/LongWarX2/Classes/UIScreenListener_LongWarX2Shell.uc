// For development only (ShowTestCampaign; never in a release, as EW's main menu has none of these): the air war with a
// demo jet (no campaign; features/hard-parts.md, experiment 3), a new campaign that skips the first mission (the game's
// own "Debug NonCheat Start"), XCOM 2's tactical quick launch and an EW map as it is. Below EW's logo (UILWEWMainMenu).
class UIScreenListener_LongWarX2Shell extends UIScreenListener config(LWAirWar);

/** The test buttons; for development, never in a release. */
var config bool ShowTestCampaign;
/** An Enemy Within map to open as it is (experiment 2), with its URL options. */
var config string TestMapURL;

event OnInit(UIScreen Screen)
{
	local UIButton Button;

	// (On EW's main menu where it stands over XCOM 2's, which is hidden: UILWEWMainMenu.)
	if (UIShell(Screen) != none && class'UILWEWMainMenu'.static.Available())
		return;
	if ((UIShell(Screen) == none && UILWEWMainMenu(Screen) == none) || Screen.GetChildByName('LWX2AirWarDemo', false) != none)
		return;
	// (A test aid: EW's base's fixed rooms placed at the main menu first, LWX2EWBase.PlaceInShell, which made the crash at a
	// campaign's start happen every time: features/strategy-flow.md.)
	if (class'LWX2EWBase'.default.PlaceInShell && class'LWX2EWBase'.static.Converted())
		class'LWX2EWBase'.static.Get(Screen).PlaceFixed();
	// (EW's own scene behind EW's main menu: LWX2EWBase.ShowShell.)
	if (class'LWX2EWBase'.default.ShellScene && UILWEWMainMenu(Screen) != none && class'LWX2EWBase'.static.Converted())
		class'LWX2EWBase'.static.Get(Screen).ShowShell();
	// (The test scripts wait for this line: tools/test/start-game.ps1.)
	`log("LongWarX2: main menu up on" @ Screen.Class.Name, , 'LongWarX2');
	if (!default.ShowTestCampaign)
		return;
	Button = Screen.Spawn(class'UIButton', Screen);
	Button.InitButton('LWX2AirWarDemo', "LONG WAR: AIR WAR (DEMO)", OnAirWar);
	Button.SetPosition(40, 340);
	Button = Screen.Spawn(class'UIButton', Screen);
	Button.InitButton('LWX2TestCampaign', "TEST CAMPAIGN (NO FIRST MISSION)", OnTestCampaign);
	Button.SetPosition(40, 390);
	Button = Screen.Spawn(class'UIButton', Screen);
	Button.InitButton('LWX2TestTactical', "TEST TACTICAL (QUICK LAUNCH)", OnTestTactical);
	Button.SetPosition(40, 440);
	if (default.TestMapURL != "")
	{
		Button = Screen.Spawn(class'UIButton', Screen);
		Button.InitButton('LWX2TestMap', "TEST EW MAP", OnTestMap);
		Button.SetPosition(40, 490);
	}
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
