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
/** Beside each mission: won without playing it (to try the strategy layer), and won with an alien taken alive. */
var UIButton WinButtons[MAX_ACTIONS];
var UIButton CaptureButtons[MAX_ACTIONS];
var UIButton StoresButton, EngineeringButton, BaseButton, HangarButton, SitRoomButton;
/** The right-hand text shows the stores instead of the events. */
var bool bShowStores;
/** For each action button: 1 intercept, 2 crash site, 3 landed UFO, 4 abduction, 5 terror; and the index. */
var int ActionKind[MAX_ACTIONS];
var int ActionIndex[MAX_ACTIONS];
var UIButton HourButton, SixHoursButton, RunButton, BuildSatButton, LaunchSatButton, SquadButton, AirButton, CloseGeoButton;
var int SelectedCountry;
var bool bLossShown;
var bool bWinShown;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int i;
	local UIButton B;
	local UIText T;

	super(UIScreen).InitScreen(InitController, InitMovie, InitName);
	class'XComGameState_LWStrategy'.static.GetOrCreate();
	class'XComGameState_LWStrategy'.static.CheckMissionBack();
	class'XComGameState_LWStrategy'.static.SyncResearch();
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
		WinButtons[i] = Spawn(class'UIButton', self).InitButton(name("LWGeoWin" $ i), "WIN", OnWin);
		WinButtons[i].SetPosition(1560, 220 + i * 46);
		WinButtons[i].Hide();
		CaptureButtons[i] = Spawn(class'UIButton', self).InitButton(name("LWGeoCapture" $ i), "WIN + CAPTIVE", OnWin);
		CaptureButtons[i].SetPosition(1640, 220 + i * 46);
		CaptureButtons[i].Hide();
	}
	EventsText = Spawn(class'UIText', self).InitText('LWGeoEvents', "");
	EventsText.SetPosition(940, 520);
	EventsText.SetSize(880, 420);

	HourButton = Spawn(class'UIButton', self).InitButton('LWGeoHour', "+1 HOUR", OnHour);
	HourButton.SetPosition(780, 960);
	SixHoursButton = Spawn(class'UIButton', self).InitButton('LWGeoSix', "+6 HOURS", OnSix);
	SixHoursButton.SetPosition(940, 960);
	RunButton = Spawn(class'UIButton', self).InitButton('LWGeoRun', "RUN TIME", OnRun);
	RunButton.SetPosition(1100, 960);
	AirButton = Spawn(class'UIButton', self).InitButton('LWGeoAir', "AIR WAR", OnAirWar);
	AirButton.SetPosition(1260, 960);
	StoresButton = Spawn(class'UIButton', self).InitButton('LWGeoStores', "STORES", OnStores);
	StoresButton.SetPosition(1420, 960);
	EngineeringButton = Spawn(class'UIButton', self).InitButton('LWGeoEngineering', "ENGINEERING", OnEngineering);
	EngineeringButton.SetPosition(1580, 75);
	BaseButton = Spawn(class'UIButton', self).InitButton('LWGeoBase', "BASE", OnBase);
	BaseButton.SetPosition(1410, 75);
	HangarButton = Spawn(class'UIButton', self).InitButton('LWGeoHangar', "HANGAR", OnHangar);
	HangarButton.SetPosition(1240, 75);
	// Enemy Within's own Situation Room, where its converted screens are in the mod (lw-ew-screens.md).
	if (class'UILWEWScreen'.static.HasEWScreens())
	{
		SitRoomButton = Spawn(class'UIButton', self).InitButton('LWGeoSitRoom', "SITUATION ROOM", OnSitRoom);
		SitRoomButton.SetPosition(1020, 75);
	}
	CloseGeoButton = Spawn(class'UIButton', self).InitButton('LWGeoClose', "CLOSE", OnAvenger);
	CloseGeoButton.SetPosition(1700, 960);
	Refresh();
	// The Avenger's resource bar shows the money the Geoscape may just have set (Long War's starting cash).
	if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
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
	local array<int> Kinds, Indexes;
	local array<string> Labels;
	local string Events;
	local int i, n;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || Header == none)
		return;
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Header.SetText("LONG WAR: GEOSCAPE -" @ S.DateText() $ "    " $ class'LWStrategyRules'.static.Money(XComHQ.GetSupplies()) $ "    Month" @ (S.Month + 1));
	for (i = 0; i < CountryButtons.Length; i++)
	{
		CountryButtons[i].SetText((i == SelectedCountry ? "> " : "") $ class'LWStrategyRules'.default.Countries[i].Name);
		CountryTexts[i].SetText(CountryLine(S, i));
	}
	BuildSatButton.SetText("BUILD SATELLITE (" $ class'LWStrategyRules'.static.Money(class'LWStrategyRules'.default.SatelliteCost) $ ")");
	LaunchSatButton.SetText("LAUNCH SATELLITE (" $ S.SatellitesReady @ "ready" $ (S.SatellitesDue.Length > 0 ? "," @ S.SatellitesDue.Length @ "building" : "") $ ")");
	LaunchSatButton.SetDisabled(S.SatellitesReady <= 0 || SelectedCountry < 0);

	// What wants a decision.
	S.Decisions(Kinds, Indexes, Labels);
	for (n = 0; n < Kinds.Length && n < MAX_ACTIONS; n++)
		SetAction(n, Kinds[n], Indexes[n], Labels[n]);
	for (n = n; n < MAX_ACTIONS; n++)
	{
		ActionButtons[n].Hide();
		ActionKind[n] = 0;
	}
	for (n = 0; n < MAX_ACTIONS; n++)
	{
		WinButtons[n].SetVisible(ActionKind[n] >= 2);
		CaptureButtons[n].SetVisible(ActionKind[n] >= 2);
	}
	StatusText.SetText(S.PendingKind != 0 ? "A squad is out on a mission." : (ActiveCount(S) > 0 ? "XCOM's decision:" : "Nothing waits on XCOM. Run time to see the aliens move."));
	for (i = S.Events.Length - 1; i >= 0 && i >= S.Events.Length - 14; i--)
		Events $= S.Events[i] $ "\n";
	EventsText.SetText(bShowStores ? StoresText(S) : Events);
	StoresButton.SetText(bShowStores ? "EVENTS" : "STORES");
	if (S.bLost && !bLossShown && XComHQPresentationLayer(Movie.Pres) != none)
	{
		bLossShown = true;
		XComHQPresentationLayer(Movie.Pres).UIYouLose();
	}
	if (S.bCampaignWon && !bWinShown && XComHQPresentationLayer(Movie.Pres) != none)
	{
		bWinShown = true;
		XComHQPresentationLayer(Movie.Pres).UIYouWin();
	}
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
	return "Panic" @ Bar @ S.Countries[i].Panic @ (S.Countries[i].bSatellite ? " SATELLITE" : " no satellite") @ "  " $ class'LWStrategyRules'.static.Money(Round(class'LWStrategyRules'.default.Countries[i].Funding * class'LWStrategyRules'.default.FundingBalance[d] * (S.Countries[i].bSatellite ? 1.0 : class'LWStrategyRules'.default.BaseFundingPct[d] / 100.0))) $ "/month";
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

/** XCOM's stores, Long War's part of them: staff, alloys, elerium, fragments, artifacts, corpses, weapons; and engineering's projects. */
simulated function string StoresText(XComGameState_LWStrategy S)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item Item;
	local StateObjectReference Ref;
	local string Text, ItemName;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	Text = "STORES:" @ S.Scientists @ "scientists," @ S.Engineers @ "engineers.\n";
	foreach XComHQ.Inventory(Ref)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Item == none || Item.Quantity <= 0)
			continue;
		ItemName = string(Item.GetMyTemplateName());
		if (!(Left(ItemName, 7) == "LWItem_" || Left(ItemName, 9) == "LWWeapon_" || ItemName == "AlienAlloy" || ItemName == "EleriumDust"))
			continue;
		Text $= Item.Quantity @ (Item.GetMyTemplate().GetItemFriendlyName() != "" ? Item.GetMyTemplate().GetItemFriendlyName() : ItemName) $ "\n";
	}
	if (S.Builds.Length + S.FoundryProjects.Length > 0)
		Text $= "ENGINEERING:\n" $ class'LWEngineering'.static.ProjectsText(S) $ class'LWEngineering'.static.FoundryProjectsText(S);
	return Text;
}

simulated function OnHangar(UIButton Button)
{
	Movie.Pres.ScreenStack.Push(Spawn(class'UILWHangar', Movie.Pres));
}

simulated function OnBase(UIButton Button)
{
	Movie.Pres.ScreenStack.Push(Spawn(class'UILWBase', Movie.Pres));
}

simulated function OnEngineering(UIButton Button)
{
	Movie.Pres.ScreenStack.Push(Spawn(class'UILWEngineering', Movie.Pres));
}

simulated function OnSitRoom(UIButton Button)
{
	class'UILWEWSituationRoom'.static.Open();
}

simulated function OnStores(UIButton Button)
{
	bShowStores = !bShowStores;
	Refresh();
}

/** A mission won without playing it (with a captive: its own button). */
simulated function OnWin(UIButton Button)
{
	local int n;

	for (n = 0; n < MAX_ACTIONS; n++)
		if ((WinButtons[n] == Button || CaptureButtons[n] == Button) && ActionKind[n] >= 2)
		{
			class'XComGameState_LWStrategy'.static.WonWithoutPlaying(ActionKind[n] - 1, ActionIndex[n], CaptureButtons[n] == Button);
			if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
				XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
			Refresh();
			return;
		}
}

simulated function OnAction(UIButton Button)
{
	local int n;

	for (n = 0; n < MAX_ACTIONS; n++)
		if (ActionButtons[n] == Button)
			break;
	if (n < MAX_ACTIONS)
		Act(n);
}

/** The n-th decision taken (its button pressed; also LWX2Control's "act"): false if there is none. */
simulated function bool Act(int n)
{
	local UILWInterception Air;

	if (n < 0 || n >= MAX_ACTIONS || ActionKind[n] == 0)
		return false;
	if (ActionKind[n] == 1)
	{
		Air = Spawn(class'UILWInterception', Movie.Pres);
		Air.bCampaign = true;
		Air.StrategyUfo = ActionIndex[n];
		Movie.Pres.ScreenStack.Push(Air);
		return true;
	}
	// A mission: crash site 1, landed UFO 2, abduction 3, terror 4 for the Geoscape's state.
	class'XComGameState_LWStrategy'.static.MissionSent(ActionKind[n] - 1, ActionIndex[n]);
	OnLaunch(none);
	return true;
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
