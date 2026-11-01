// Long War's Geoscape (features/lw-geoscape.md): the council's countries by continent with their
// panic and satellites, the date and the money, what wants a decision (a UFO to intercept, a crash
// site or landed UFO to assault, abductions or terror to answer), what happened, and the clock.
// The state and its rules are XComGameState_LWStrategy's; missions go out through the
// headquarters screen's launch (UILWHeadquarters, which this extends).
class UILWGeoscape extends UILWHeadquarters;

const MAX_ACTIONS = 6;

var UIText Header, EventsText, StatusText;
var array<UIButton> CountryButtons;
var array<UIText> CountryTexts;
var UIButton ActionButtons[MAX_ACTIONS];
/** For each action button: 1 intercept, 2 crash site, 3 landed UFO, 4 abduction, 5 terror; and the index. */
var int ActionKind[MAX_ACTIONS];
var int ActionIndex[MAX_ACTIONS];
var UIButton HourButton, SixHoursButton, RunButton, BuildSatButton, LaunchSatButton, SquadButton, AirButton, CloseGeoButton;
var int SelectedCountry;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int i;
	local UIButton B;
	local UIText T;

	super(UIScreen).InitScreen(InitController, InitMovie, InitName);
	class'XComGameState_LWStrategy'.static.GetOrCreate();
	class'XComGameState_LWStrategy'.static.CheckMissionBack();
	SelectedCountry = -1;

	Spawn(class'UIBGBox', self).InitBG('LWGeoBg', 60, 60, 1800, 960);
	Header = Spawn(class'UIText', self).InitText('LWGeoHeader', "", true);
	Header.SetPosition(90, 75);
	Header.SetWidth(1700);

	// The countries, by continent: a button to select one (for a satellite), its panic and coverage beside it.
	for (i = 0; i < class'LWStrategyRules'.default.Countries.Length; i++)
	{
		B = Spawn(class'UIButton', self).InitButton(name("LWGeoCountry" $ i), class'LWStrategyRules'.default.Countries[i].Name, OnCountry);
		B.SetPosition(90, 140 + RowOf(i) * 44);
		CountryButtons.AddItem(B);
		T = Spawn(class'UIText', self).InitText(name("LWGeoCountryText" $ i), "");
		T.SetPosition(330, 140 + RowOf(i) * 44);
		T.SetWidth(560);
		CountryTexts.AddItem(T);
	}
	BuildSatButton = Spawn(class'UIButton', self).InitButton('LWGeoBuildSat', "", OnBuildSat);
	BuildSatButton.SetPosition(90, 960);
	LaunchSatButton = Spawn(class'UIButton', self).InitButton('LWGeoLaunchSat', "", OnLaunchSat);
	LaunchSatButton.SetPosition(420, 960);

	StatusText = Spawn(class'UIText', self).InitText('LWGeoStatus', "");
	StatusText.SetPosition(940, 140);
	StatusText.SetWidth(880);
	for (i = 0; i < MAX_ACTIONS; i++)
	{
		ActionButtons[i] = Spawn(class'UIButton', self).InitButton(name("LWGeoAction" $ i), "", OnAction);
		ActionButtons[i].SetPosition(940, 220 + i * 46);
	}
	EventsText = Spawn(class'UIText', self).InitText('LWGeoEvents', "");
	EventsText.SetPosition(940, 520);
	EventsText.SetSize(880, 420);

	HourButton = Spawn(class'UIButton', self).InitButton('LWGeoHour', "+1 HOUR", OnHour);
	HourButton.SetPosition(940, 960);
	SixHoursButton = Spawn(class'UIButton', self).InitButton('LWGeoSix', "+6 HOURS", OnSix);
	SixHoursButton.SetPosition(1080, 960);
	RunButton = Spawn(class'UIButton', self).InitButton('LWGeoRun', "RUN TIME", OnRun);
	RunButton.SetPosition(1230, 960);
	AirButton = Spawn(class'UIButton', self).InitButton('LWGeoAir', "AIR WAR", OnAirWar);
	AirButton.SetPosition(1390, 960);
	CloseGeoButton = Spawn(class'UIButton', self).InitButton('LWGeoClose', "CLOSE", OnAvenger);
	CloseGeoButton.SetPosition(1700, 960);
	Refresh();
	ShowAvengerButton(false);
	`log("LongWarX2: Long War Geoscape shown", , 'LongWarX2');
}

simulated function OnRemoved()
{
	ShowAvengerButton(true);
	super.OnRemoved();
}

/** The Avenger's LONG WAR GEOSCAPE button (UIScreenListener_LongWarX2HQ) is drawn above this screen: hidden while it is up. */
simulated function ShowAvengerButton(bool bShow)
{
	local UIScreen Hud;
	local UIPanel Button;

	Hud = Movie.Pres.ScreenStack.GetScreen(class'UIAvengerHUD');
	Button = Hud != none ? Hud.GetChildByName('LWX2HQButton', false) : none;
	if (Button != none)
		Button.SetVisible(bShow);
}

/** A country's row: by continent, with a gap between continents. */
simulated function int RowOf(int i)
{
	local int c, k, Row;

	c = class'LWStrategyRules'.default.Countries[i].Continent;
	for (k = 0; k < class'LWStrategyRules'.default.Countries.Length; k++)
	{
		if (class'LWStrategyRules'.default.Countries[k].Continent < c || (class'LWStrategyRules'.default.Countries[k].Continent == c && k < i))
			Row++;
	}
	return Row + c / 2;
}

function Refresh()
{
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local string Events;
	local int i, n;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || Header == none)
		return;
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Header.SetText("LONG WAR: GEOSCAPE -" @ S.DateText() $ "    $" $ XComHQ.GetSupplies() $ "    Month" @ (S.Month + 1));
	for (i = 0; i < CountryButtons.Length; i++)
	{
		CountryButtons[i].SetText((i == SelectedCountry ? "> " : "") $ class'LWStrategyRules'.default.Countries[i].Name);
		CountryTexts[i].SetText(CountryLine(S, i));
	}
	BuildSatButton.SetText("BUILD SATELLITE ($" $ class'LWStrategyRules'.default.SatelliteCost $ ")");
	LaunchSatButton.SetText("LAUNCH SATELLITE (" $ S.SatellitesReady @ "ready" $ (S.SatellitesDue.Length > 0 ? "," @ S.SatellitesDue.Length @ "building" : "") $ ")");
	LaunchSatButton.SetDisabled(S.SatellitesReady <= 0 || SelectedCountry < 0);

	// What wants a decision.
	for (i = 0; i < S.Ufos.Length && n < MAX_ACTIONS; i++)
	{
		if ((S.Ufos[i].Status == 1 || S.Ufos[i].Status == 2) && S.Ufos[i].bDetected && !S.Ufos[i].bAttacked)
			SetAction(n++, 1, i, "INTERCEPT:" @ S.ShipName(S.Ufos[i].Ufo) @ "over" @ S.CountryName(S.Ufos[i].Country) @ "(" $ (S.Ufos[i].Until - S.Hours) $ "h)");
		else if (S.Ufos[i].Status == 3)
			SetAction(n++, 2, i, "ASSAULT: crash site in" @ S.CountryName(S.Ufos[i].Country) @ "(" $ (S.Ufos[i].Until - S.Hours) $ "h)");
		else if (S.Ufos[i].Status == 4 && S.Ufos[i].bDetected)
			SetAction(n++, 3, i, "ASSAULT: landed UFO in" @ S.CountryName(S.Ufos[i].Country) @ "(" $ (S.Ufos[i].Until - S.Hours) $ "h)");
	}
	for (i = 0; i < S.Sites.Length && n < MAX_ACTIONS; i++)
	{
		if (S.Sites[i].Status == 1)
			SetAction(n++, S.Sites[i].bTerror ? 5 : 4, i, (S.Sites[i].bTerror ? "RESPOND: terror in" : "RESPOND: abductions in") @ S.CountryName(S.Sites[i].Country) @ "(" $ (S.Sites[i].Until - S.Hours) $ "h)");
	}
	for (n = n; n < MAX_ACTIONS; n++)
	{
		ActionButtons[n].Hide();
		ActionKind[n] = 0;
	}
	StatusText.SetText(S.PendingKind != 0 ? "A squad is out on a mission." : (ActiveCount(S) > 0 ? "XCOM's decision:" : "Nothing waits on XCOM. Run time to see the aliens move."));
	for (i = S.Events.Length - 1; i >= 0 && i >= S.Events.Length - 14; i--)
		Events $= S.Events[i] $ "\n";
	EventsText.SetText(Events);
}

simulated function int ActiveCount(XComGameState_LWStrategy S)
{
	local int i, n;

	for (i = 0; i < MAX_ACTIONS; i++)
		if (ActionKind[i] != 0)
			n++;
	return n;
}

simulated function SetAction(int n, int Kind, int Index, string Label)
{
	ActionKind[n] = Kind;
	ActionIndex[n] = Index;
	ActionButtons[n].SetText(Label);
	ActionButtons[n].Show();
}

/** Panic as Long War shows it (five levels of 20), with the points, the satellite and what the country gives. */
simulated function string CountryLine(XComGameState_LWStrategy S, int i)
{
	local string Bar;
	local int k, d;

	if (S.Countries[i].bLeft)
		return "LEFT THE COUNCIL";
	for (k = 0; k < 5; k++)
		Bar $= S.Countries[i].Panic > k * 20 ? "#" : "-";
	d = class'LWStrategyRules'.static.Difficulty();
	return "Panic" @ Bar @ S.Countries[i].Panic @ (S.Countries[i].bSatellite ? " SATELLITE" : " no satellite") @ "  $" $ Round(class'LWStrategyRules'.default.Countries[i].Funding * class'LWStrategyRules'.default.FundingBalance[d] * (S.Countries[i].bSatellite ? 1.0 : class'LWStrategyRules'.default.BaseFundingPct[d] / 100.0)) $ "/month";
}

// --- The clock ----------------------------------------------------------------------------

simulated function OnHour(UIButton Button) { class'XComGameState_LWStrategy'.static.Run(1); Refresh(); }
simulated function OnSix(UIButton Button) { class'XComGameState_LWStrategy'.static.Run(6); Refresh(); }
/** Runs until something wants a decision (at most a month). */
simulated function OnRun(UIButton Button) { class'XComGameState_LWStrategy'.static.Run(30 * 24); Refresh(); }

// --- Satellites ---------------------------------------------------------------------------

simulated function OnCountry(UIButton Button)
{
	SelectedCountry = CountryButtons.Find(Button);
	Refresh();
}

simulated function OnBuildSat(UIButton Button)
{
	class'XComGameState_LWStrategy'.static.BuildSatellite();
	Refresh();
}

simulated function OnLaunchSat(UIButton Button)
{
	if (SelectedCountry >= 0)
		class'XComGameState_LWStrategy'.static.LaunchSatellite(SelectedCountry);
	Refresh();
}

// --- Decisions ------------------------------------------------------------------------------

simulated function OnAction(UIButton Button)
{
	local int n;
	local UILWInterception Air;

	for (n = 0; n < MAX_ACTIONS; n++)
		if (ActionButtons[n] == Button)
			break;
	if (n >= MAX_ACTIONS || ActionKind[n] == 0)
		return;
	if (ActionKind[n] == 1)
	{
		Air = Spawn(class'UILWInterception', Movie.Pres);
		Air.bCampaign = true;
		Air.StrategyUfo = ActionIndex[n];
		Movie.Pres.ScreenStack.Push(Air);
		return;
	}
	// A mission: crash site 1, landed UFO 2, abduction 3, terror 4 for the Geoscape's state.
	class'XComGameState_LWStrategy'.static.MissionSent(ActionKind[n] - 1, ActionIndex[n]);
	OnLaunch(none);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Refresh();
}

defaultproperties
{
	InputState = eInputState_Consume;
}
