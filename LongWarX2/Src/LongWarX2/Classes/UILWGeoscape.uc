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
var UIButton StoresButton, EngineeringButton, FoundryButton, GreyMarketButton, BaseButton, HangarButton, SitRoomButton;
/** The right-hand text shows the stores instead of the events. */
var bool bShowStores;
/** For each action button: 1 intercept, 2 crash site, 3 landed UFO, 4 abduction, 5 terror; and the index. */
var int ActionKind[MAX_ACTIONS];
var int ActionIndex[MAX_ACTIONS];
var UIButton HourButton, SixHoursButton, RunButton, BuildSatButton, LaunchSatButton, SquadButton, AirButton, CloseGeoButton;
var int SelectedCountry;
/** Missions go through XCOM 2's squad select (UILWSquadSelect); off, the first soldiers able to go are sent at once. */
var config bool UseSquadSelect;
var bool bLossShown;
var bool bWinShown;
/** Decisions EW's alerts have shown (kind x 100000 + index; UILWEWAlert). */
var array<int> AlertsShown;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int i;
	local UIButton B;
	local UIText T;

	super(UIScreen).InitScreen(InitController, InitMovie, InitName);
	class'XComGameState_LWStrategy'.static.Arrived();
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
	// The Foundry's projects (EW's screen, as engineering's).
	FoundryButton = Spawn(class'UIButton', self).InitButton('LWGeoFoundry', "FOUNDRY", OnFoundry);
	FoundryButton.SetPosition(870, 75);
	// The grey market (LWGreyMarket) on EW's screen, when EW's screens are converted.
	if (class'UILWEWScreen'.static.HasEWScreens())
	{
		GreyMarketButton = Spawn(class'UIButton', self).InitButton('LWGeoGreyMarket', "GREY MARKET", OnGreyMarket);
		GreyMarketButton.SetPosition(690, 75);
	}
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
	// EW's base behind it, when converted on this machine (features/lw-base-view.md).
	class'LWX2EWBase'.static.Get(self).Show();
	`log("LongWarX2: Long War Geoscape shown", , 'LongWarX2');
	// EW's Mission Control over this panel, where EW's screens are converted (UILWEWMissionControl).
	SetTimer(0.1, false, nameof(OpenEWMissionControl));
}

/** EW's Mission Control screen opened over this one, which then stays out of sight beneath it, holding the state and acting
 *  for it. Without EW's screens this panel is the Geoscape. */
simulated function OpenEWMissionControl()
{
	// (Only while this is the top screen: a screen opened from here at once, as the control port's test aids do, stays up.)
	if (Movie.Pres.ScreenStack.GetCurrentScreen() != self)
		return;
	if (class'UILWEWMissionControl'.static.OpenOver(self))
		Hide();
}

simulated function OnRemoved()
{
	// The camera back to the Avenger, unless the hub is under this (it shows the base again as it gets the focus).
	if (!Movie.Pres.ScreenStack.IsInStack(class'UILWEWHub'))
		class'LWX2EWBase'.static.Get(self).Hide();
	super.OnRemoved();
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
	local UILWEWMissionControl MissionControl;
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
	BuildSatButton.SetText("BUILD SATELLITE (" $ class'LWStrategyRules'.static.Money(class'LWStrategyRules'.static.SatelliteCash()) $ ")");
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
		WinButtons[n].SetVisible(ActionKind[n] >= 2 && ActionKind[n] < 20);
		CaptureButtons[n].SetVisible(ActionKind[n] >= 2 && ActionKind[n] < 20);
	}
	StatusText.SetText(S.PendingKind != 0 ? "A squad is out on a mission." : (ActiveCount(S) > 0 ? "XCOM's decision:" : "Nothing waits on XCOM. Run time to see the aliens move."));
	// The council's open requests first (EW lists them in its Situation Room).
	for (i = 0; i < S.Requests.Length; i++)
		Events $= "Council request:" @ S.CountryName(S.Requests[i].Country) @ "wants" @ class'LWCouncilRequests'.static.Words(S.Requests[i])
			@ "(" $ (S.Requests[i].bPending ? "XCOM has them" : S.Requests[i].HoursLeft $ "h left") $ "; offers" @ class'LWCouncil'.static.RewardsText(S.Requests[i].Rewards) $ ")\n";
	for (i = S.Events.Length - 1; i >= 0 && i >= S.Events.Length - 14 + S.Requests.Length; i--)
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
	// The council's monthly report, once the month has ended (EW's transmission, then its End of Month Report).
	if (!S.bLost && XComHQPresentationLayer(Movie.Pres) != none)
		class'UILWEWWorldReport'.static.OpenIfDue(XComHQPresentationLayer(Movie.Pres));
	// EW's Mission Control's list brought up to date (UILWEWMissionControl), and a new decision: EW's alert for it, where
	// there is one (UILWEWAlert), over this screen or Mission Control.
	MissionControl = UILWEWMissionControl(Movie.Pres.ScreenStack.GetFirstInstanceOf(class'UILWEWMissionControl'));
	if (MissionControl != none)
		MissionControl.Refresh();
	if (!S.bLost && S.PendingKind == 0 && (Movie.Pres.ScreenStack.GetCurrentScreen() == self || Movie.Pres.ScreenStack.GetCurrentScreen() == MissionControl))
		class'UILWEWAlert'.static.OpenNext(self, Kinds, Indexes);
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
	return "Panic" @ Bar @ S.Countries[i].Panic @ (S.Countries[i].bSatellite ? " SATELLITE" : " no satellite") @ "  " $ class'LWStrategyRules'.static.Money(S.CountryFunding(i, S.Countries[i].bSatellite)) $ "/month";
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

/** The hangar on EW's own screen (the plain one without EW's screens). */
simulated function OnHangar(UIButton Button)
{
	class'UILWEWHangar'.static.Open(XComHQPresentationLayer(Movie.Pres));
}

simulated function OnBase(UIButton Button)
{
	Movie.Pres.ScreenStack.Push(Spawn(class'UILWBase', Movie.Pres));
}

/** Engineering's items on EW's own screen (the plain one without EW's screens). */
simulated function OnEngineering(UIButton Button)
{
	class'UILWEWEngineering'.static.Open(XComHQPresentationLayer(Movie.Pres));
}

simulated function OnGreyMarket(UIButton Button)
{
	class'UILWEWGreyMarket'.static.Open(XComHQPresentationLayer(Movie.Pres));
}

/** The Foundry's projects on EW's own screen (the plain one without EW's screens). */
simulated function OnFoundry(UIButton Button)
{
	class'UILWEWEngineering'.static.Open(XComHQPresentationLayer(Movie.Pres), true);
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

/** A decision taken by its kind and index (EW's alerts: UILWEWAlert); false if it is no longer open. */
simulated function bool ActOn(int Kind, int Index)
{
	local int n;

	Refresh();
	for (n = 0; n < MAX_ACTIONS; n++)
		if (ActionKind[n] == Kind && ActionIndex[n] == Index)
			return Act(n);
	return false;
}

/** A detected UFO met by a chosen jet at a chosen stance (EW's contact alert's jet list): the air war on it, with that jet
 *  (its place among the jets ready for the UFO) and stance. False if the jet is not ready for it. */
simulated function bool Intercept(int Ufo, int Jet, int Stance)
{
	local UILWInterception Air;
	local array<int> Ready;

	Ready = class'LWHangar'.static.ReadyFor(Ufo);
	if (Ready.Find(Jet) == INDEX_NONE)
		return false;
	Air = Spawn(class'UILWInterception', Movie.Pres);
	Air.bCampaign = true;
	Air.StrategyUfo = Ufo;
	Air.JetPick = Ready.Find(Jet);
	Air.PresetStance = Stance;
	Movie.Pres.ScreenStack.Push(Air);
	return true;
}

/** The n-th decision taken (its button pressed; also LWX2Control's "act"): false if there is none. */
simulated function bool Act(int n)
{
	local UILWInterception Air;

	if (n < 0 || n >= MAX_ACTIONS || ActionKind[n] == 0)
		return false;
	// A council request given or refused (LWCouncilRequests).
	if (ActionKind[n] == 20 || ActionKind[n] == 21)
	{
		class'LWCouncilRequests'.static.Answer(ActionIndex[n], ActionKind[n] == 20);
		Refresh();
		return true;
	}
	if (ActionKind[n] == 1)
	{
		Air = Spawn(class'UILWInterception', Movie.Pres);
		Air.bCampaign = true;
		Air.StrategyUfo = ActionIndex[n];
		Movie.Pres.ScreenStack.Push(Air);
		return true;
	}
	// A mission: crash site 1, landed UFO 2, abduction 3, terror 4 for the Geoscape's state.
	if (!UseSquadSelect)
	{
		class'XComGameState_LWStrategy'.static.MissionSent(ActionKind[n] - 1, ActionIndex[n]);
		OnLaunch(none);
		return true;
	}
	return ChooseSquad(ActionKind[n] - 1, ActionIndex[n]);
}

/** The mission chosen, its site made with the first soldiers able to go, and XCOM 2's squad select opened on it. */
simulated function bool ChooseSquad(int Kind, int Index)
{
	local int MissionID;
	local UILWSquadSelect Select;

	class'XComGameState_LWStrategy'.static.MissionChosen(Kind, Index);
	MissionID = PrepareMission();
	if (MissionID == 0)
	{
		class'XComGameState_LWStrategy'.static.MissionCancelled();
		StatusText.SetText("No soldier is able to go.");
		return false;
	}
	// The Avenger back first when squad select stands the soldiers in its launch bay, as it opens, before this screen loses
	// focus (in EW's hangar, the base stays).
	if (!class'LWX2EWBase'.static.SquadHere())
		class'LWX2EWBase'.static.Get(self).Hide();
	Select = Spawn(class'UILWSquadSelect', Movie.Pres);
	Movie.Pres.ScreenStack.Push(Select);
	return true;
}

/** Squad select launched the chosen mission: the mission goes ahead with the squad picked there. */
function LaunchChosen(int MissionID)
{
	DropPsiTrainees();
	if (class'UIUtilities_Strategy'.static.GetXComHQ().Squad.Length == 0)
	{
		`log("LongWarX2: Long War Geoscape: no soldier left in the squad; the mission is not sent", , 'LongWarX2');
		ForgetChosen(MissionID);
		Refresh();
		return;
	}
	class'XComGameState_LWStrategy'.static.MissionCommitted();
	LaunchMission(MissionID);
}

/**
 * Soldiers in Long War's psi training (features/lw-psi.md) taken out of the squad: XCOM 2's squad select offers them,
 * since their training is Long War's, not XCOM 2's.
 */
function DropPsiTrainees()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy S;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	for (i = XComHQ.Squad.Length - 1; i >= 0; i--)
	{
		if (XComHQ.Squad[i].ObjectID == 0 || !S.InPsiTraining(XComHQ.Squad[i].ObjectID))
			continue;
		if (NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: psi trainees stay home");
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		}
		`log("LongWarX2: Long War Geoscape: soldier" @ XComHQ.Squad[i].ObjectID @ "is in psi training and stays home", , 'LongWarX2');
		XComHQ.Squad.Remove(i, 1);
	}
	if (NewGameState != none)
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** Squad select backed out of: the chosen mission's site removed, and nothing pending. */
static function ForgetChosen(int MissionID)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference EmptyRef;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a mission not sent");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.MissionRef = EmptyRef;
	if (MissionID > 0 && `XCOMHISTORY.GetGameStateForObjectID(MissionID) != none)
		NewGameState.RemoveStateObject(MissionID);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	class'XComGameState_LWStrategy'.static.MissionCancelled();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Refresh();
	// The base's tiles brought up to date, and its view back (a screen over this one may have moved the camera).
	class'LWX2EWBase'.static.Get(self).Show();
}

defaultproperties
{
	InputState = eInputState_Consume;
}
