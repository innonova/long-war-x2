// Enemy Within's Mission Control screen over the Long War Geoscape (features/lw-mission-control.md, plan 2): EW's
// MissionControl movie with its mission list (theMissionList, as UIMissionControl_MissionList fills it from
// XGMissionControlUI.UpdateMissions), in place of the Geoscape's plain panel, which stays beneath it as the screen that
// holds Long War's state and acts. The list: the UFOs detected in flight (UFO-<n>), the missions waiting with their hours
// left (one entry for abductions, as EW's), and SCAN FOR ACTIVITY (UpdateScan: time run until something happens). Choosing
// an entry (a click, or the arrows and Enter) opens its EW alert (UILWEWAlert; abductions their site selection, as EW's
// OnMissionInput does), a council request EW's request screen (UILWEWCouncilRequest; EW opens it from its Situation
// Room); what EW decides elsewhere (the HQ's defence, EXALT's base) the Geoscape takes as before. Esc leaves Mission Control. EW's clock and event list are
// the strategy HUD's, under this screen; the movie's own are hidden, as for the alerts.
class UILWEWMissionControl extends UILWEWScreen dependson(LWStrategyRules);

/** A scan's time being shown passing (Scan). */
var bool bScanning;
/** The screen beneath, and the list's entries: the Geoscape's decision kind and index (kind 0: the scan). */
var UILWGeoscape Geo;
var array<int> EntryKinds, EntryIndexes;
var int Highlight;
var UILWEWAlertTarget ListTarget;
/** EW's notices shown now, and when each came (XGMissionControlUI.AddNotice: six seconds each; features/ew-notices.md). */
var array<string> NoticeTexts;
var array<float> NoticeTimes;
var string NoticesShown;

/** Opened over the Geoscape (UILWGeoscape.InitScreen) when EW's screens are converted; false otherwise. */
static function bool OpenOver(UILWGeoscape Geoscape)
{
	local XComHQPresentationLayer HQPres;
	local UILWEWMissionControl EWScreen;

	HQPres = XComHQPresentationLayer(Geoscape.Movie.Pres);
	if (HQPres == none || !HasEWScreens() || HQPres.ScreenStack.GetFirstInstanceOf(class'UILWEWMissionControl') != none)
		return false;
	DynamicLoadObject(default.UIPackage $ ".ewxMissionControl", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWMissionControl', HQPres);
	EWScreen.Package = name("/ package/ewxMissionControl/MissionControl");
	EWScreen.MCName = 'theScreen';
	EWScreen.Geo = Geoscape;
	HQPres.ScreenStack.Push(EWScreen);
	return true;
}

simulated function OnInit()
{
	local array<ASValue> NoArgs;

	super.OnInit();
	// The clock is the strategy HUD's (beneath), the movie's own hidden; the event list is the movie's own, EW's UPCOMING
	// EVENTS on the right (UIMissionControl's m_kEventList), filled by the HUD (UILWEWStrategyHUD.SetEvents).
	Movie.SetVariableBool(MCPath $ ".clockMC._visible", false);
	// EW's back arrow in the movie's own help bar (UIMissionControl.UpdateButtonHelp: AddBackButton; its hologlobe button
	// leads to EW's space view of the earth, which the port does not have). The HUD's beneath it was covered by this movie.
	HelpButton("helpBarMC", false, 0, "4", "", "QComButtonIconPC");
	`log("LongWarX2: Mission Control: list title visible" @ Movie.GetVariableBool(MCPath $ ".theMissionList.titleMC._visible") @ "y" @ Movie.GetVariableNumber(MCPath $ ".theMissionList._y"), , 'LongWarX2');
	Movie.Invoke(MCPath $ ".theMissionList.onLoad", NoArgs);
	`log("LongWarX2: Mission Control: list after onLoad y" @ Movie.GetVariableNumber(MCPath $ ".theMissionList._y"), , 'LongWarX2');
	ListTarget = class'UILWEWAlertTarget'.static.At(self, MCPath $ ".theMissionList");
	LookAtRoom();
	SetTimer(0.2, false, nameof(Refresh));
	// (The Geoscape beneath brought up to date once this is up: an alert that waited opens over Mission Control.)
	SetTimer(0.3, false, nameof(RefreshGeoscape));
	SetTimer(0.5, true, nameof(UpdateNotices));
}

/**
 * EW's notices (XGMissionControlUI.AddNotice, UpdateNotices; UIMissionControl.UpdateNotices): each new one of Long War's
 * (XComGameState_LWStrategy.Notices) shown for six seconds, the newest first, one a line, through the movie's
 * DisplayNotifications. Those that came while Mission Control was closed show when it opens, as EW's wait for it.
 */
function UpdateNotices()
{
	local XComGameState_LWStrategy S;
	local array<ASValue> Params;
	local string Shown;
	local UILWEWHub Hub;
	local int i, n;

	S = class'XComGameState_LWStrategy'.static.Get();
	Hub = UILWEWHub(Movie.Pres.ScreenStack.GetFirstInstanceOf(class'UILWEWHub'));
	if (S == none || Hub == none)
		return;
	// (The first time in a session (a game loaded, the strategy layer come back to), those of the last game day only, not the
	// campaign's older ones.)
	if (!Hub.bNoticesStarted)
	{
		Hub.bNoticesStarted = true;
		Hub.NoticesSeen = S.NoticeCount;
		for (i = S.NoticeHours.Length - 1; i >= 0 && S.Hours - S.NoticeHours[i] <= 24; i--)
			Hub.NoticesSeen--;
	}
	n = Min(S.NoticeCount - Hub.NoticesSeen, S.Notices.Length);
	for (i = S.Notices.Length - n; i < S.Notices.Length; i++)
	{
		NoticeTexts.AddItem(S.Notices[i]);
		NoticeTimes.AddItem(WorldInfo.RealTimeSeconds);
	}
	Hub.NoticesSeen = S.NoticeCount;
	for (i = NoticeTexts.Length - 1; i >= 0; i--)
		if (WorldInfo.RealTimeSeconds - NoticeTimes[i] > 6.0)
		{
			NoticeTexts.Remove(i, 1);
			NoticeTimes.Remove(i, 1);
		}
	for (i = NoticeTexts.Length - 1; i >= 0; i--)
		Shown $= NoticeTexts[i] $ Chr(10);
	if (Shown == NoticesShown)
		return;
	NoticesShown = Shown;
	Params.AddItem(Str(Shown));
	Movie.Invoke(MCPath $ ".DisplayNotifications", Params);
	`log("LongWarX2: Mission Control: notices" @ Repl(Shown, Chr(10), " | ") @ "at" @ Movie.GetVariableNumber(MCPath $ ".notificationTextfield._x") @ Movie.GetVariableNumber(MCPath $ ".notificationTextfield._y") @ "visible" @ Movie.GetVariableBool(MCPath $ ".notificationTextfield._visible") @ "alpha" @ Movie.GetVariableNumber(MCPath $ ".notificationTextfield._alpha"), , 'LongWarX2');
}

function RefreshGeoscape()
{
	if (Geo != none)
		Geo.Refresh();
}

/** EW's Mission Control room behind the screen (its MissionControl camera in EW's base, as EW enters the room). */
function LookAtRoom()
{
	local LWX2EWBase B;

	B = class'LWX2EWBase'.static.Get(self);
	if (B == none)
		return;
	B.Show();
	B.LookAt('MissionControl', 1.0);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	LookAtRoom();
	if (Geo != none)
		Geo.Refresh();
	Refresh();
}

/** The list from the Geoscape's decisions (XComGameState_LWStrategy.Decisions), in EW's words and icons. */
function Refresh()
{
	local XComGameState_LWStrategy S;
	local array<int> Kinds, Indexes;
	local array<string> Labels;
	local array<ASValue> Params, NoArgs;
	local bool bAbductions;
	local array<int> RequestsListed;
	local int i, n;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return;
	S.Decisions(Kinds, Indexes, Labels);
	EntryKinds.Length = 0;
	EntryIndexes.Length = 0;
	Params.AddItem(Str(class'UILWEWAlert'.default.MissionsTitle));
	Movie.Invoke(MCPath $ ".theMissionList.SetTitle", Params);
	Movie.Invoke(MCPath $ ".theMissionList.clear", NoArgs);
	for (i = 0; i < Kinds.Length; i++)
	{
		// (Abductions: one entry, as EW's; a council request one, given or refused on its screen.)
		if (Kinds[i] == 4 && bAbductions)
			continue;
		if (Kinds[i] >= 20)
		{
			if (RequestsListed.Find(Indexes[i]) != INDEX_NONE)
				continue;
			RequestsListed.AddItem(Indexes[i]);
		}
		bAbductions = bAbductions || Kinds[i] == 4;
		AddEntry(n++, Entry(S, Kinds[i], Indexes[i], Labels[i]), 4, Icon(Kinds[i]));
		EntryKinds.AddItem(Kinds[i]);
		EntryIndexes.AddItem(Indexes[i]);
	}
	// The scan last (UpdateScan): none while a squad is out.
	if (S.PendingKind == 0 && !S.bLost)
	{
		AddEntry(n++, class'UILWEWAlert'.default.ScanForActivity, 2, "_ScanForUFO");
		EntryKinds.AddItem(0);
		EntryIndexes.AddItem(0);
	}
	Highlight = Clamp(Highlight, 0, Max(0, EntryKinds.Length - 1));
	Focus();
	MarkGlobe(S);
}

/** The hologlobe's markers (EW's globe shows the base, the UFOs and the missions): the headquarters cyan, each UFO seen in
 *  flight red, each mission waiting yellow, at their countries. */
function MarkGlobe(XComGameState_LWStrategy S)
{
	local LWX2EWBase B;
	local array<float> Xs, Ys;
	local array<LinearColor> Colours;
	local float X, Y;
	local int i;

	B = class'LWX2EWBase'.static.Get(self);
	if (B == none)
		return;
	if (PlaceOf(S, S.HomeCountry(), X, Y))
		AddMark(Xs, Ys, Colours, X, Y, MakeLinearColor(0.1, 0.9, 1.0, 1));
	for (i = 0; i < S.Ufos.Length; i++)
		if (S.Ufos[i].bDetected && (S.Ufos[i].Status == 1 || S.Ufos[i].Status == 2) && PlaceOf(S, S.Ufos[i].Country, X, Y))
			AddMark(Xs, Ys, Colours, X + 0.01, Y - 0.01, MakeLinearColor(1.0, 0.1, 0.1, 1));
	for (i = 0; i < S.Sites.Length; i++)
		if (S.Sites[i].Status == 1 && PlaceOf(S, S.Sites[i].Country, X, Y))
			AddMark(Xs, Ys, Colours, X - 0.01, Y + 0.01, MakeLinearColor(1.0, 0.8, 0.1, 1));
	for (i = 0; i < S.Ufos.Length; i++)
		if ((S.Ufos[i].Status == 3 || (S.Ufos[i].Status == 4 && S.Ufos[i].bDetected)) && PlaceOf(S, S.Ufos[i].Country, X, Y))
			AddMark(Xs, Ys, Colours, X - 0.01, Y + 0.01, MakeLinearColor(1.0, 0.8, 0.1, 1));
	B.SetGlobeMarkers(Xs, Ys, Colours);
}

static function AddMark(out array<float> Xs, out array<float> Ys, out array<LinearColor> Colours, float X, float Y, LinearColor C)
{
	Xs.AddItem(X);
	Ys.AddItem(Y);
	Colours.AddItem(C);
}

/** A country's place on EW's flat earth (LWStrategyRules.MapPlaces). */
static function bool PlaceOf(XComGameState_LWStrategy S, int Country, out float X, out float Y)
{
	local LWStrategyRules.LWMapPlace P;

	foreach class'LWStrategyRules'.default.MapPlaces(P)
		if (S.CountryIndex(P.Country) == Country)
		{
			X = P.X;
			Y = P.Y;
			return true;
		}
	return false;
}

/** An entry (UIMissionControl_MissionList.UpdateData): its words coloured by its state, in capitals. */
function AddEntry(int i, string Text, int State, string IconLabel)
{
	local array<ASValue> Params;

	Params.AddItem(Num(i));
	Params.AddItem(Str(Caps(State == 0 ? Text : Coloured(Text, State))));
	Params.AddItem(Num(State));
	Params.AddItem(Str(IconLabel));
	Movie.Invoke(MCPath $ ".theMissionList.AddOption", Params);
}

static function string Coloured(string Text, int State)
{
	return "<font color='#" $ (State == 2 ? "5CD16C" : (State == 3 ? "EE1C25" : (State == 4 ? "FFD038" : "67E8ED"))) $ "'>" $ Text $ "</font>";
}

/** A decision as EW's list names it (XGMissionControlUI.UpdateMissions: UFO-<n>, or the mission's title), with the hours
 *  it waits. The council's requests, which EW answers in its Situation Room, keep the Geoscape's words here. */
function string Entry(XComGameState_LWStrategy S, int K, int I, string Label)
{
	local string T;
	local int Left;

	Left = -1;
	switch (K)
	{
	case 1: return class'UILWEWAlert'.default.UFOPrefix $ (I + 1);
	case 2: T = class'UILWEWAlert'.default.TitleCrash; Left = S.Ufos[I].Until - S.Hours; break;
	case 3: T = class'UILWEWAlert'.default.TitleLanded; Left = S.Ufos[I].Until - S.Hours; break;
	case 4: T = class'UILWEWAlert'.default.TitleAbductions; Left = S.Sites[I].Until - S.Hours; break;
	case 5: T = Repl(class'UILWEWAlert'.default.TitleTerror, "<XGParam:StrValue0/>", S.CountryName(S.Sites[I].Country)); Left = S.Sites[I].Until - S.Hours; break;
	case 6: T = class'UILWEWAlert'.default.TitleAlienBase $ S.CountryName(I); break;
	case 7: T = class'UILWEWAlert'.default.TitleTempleShip; break;
	case 8: T = class'UILWEWAlert'.default.TitleHQ; Left = S.Sites[I].Until - S.Hours; break;
	case 9: T = S.ExaltMissionKind == 2 ? class'UILWEWAlert'.default.TitleDataRecovery : class'UILWEWAlert'.default.TitleCovertExtraction; Left = S.ExaltMissionUntil - S.Hours; break;
	case 10: T = class'UILWEWAlert'.default.TitleExaltRaid; break;
	case 11: T = class'UILWEWAlert'.default.FCMission @ class'LWCouncil'.static.KindName(S.Sites[I].CouncilKind); Left = S.Sites[I].Until - S.Hours; break;
	// A council request (EW lists them in its Situation Room): EW's request title.
	case 20:
	case 21:
		T = Repl(class'UILWEWCouncilRequest'.default.TitleLabel, "<XGParam:StrValue0/>", S.CountryName(S.Requests[I].Country));
		Left = S.Requests[I].bPending ? -1 : S.Requests[I].HoursLeft;
		break;
	default: return Label;
	}
	return Left >= 0 ? T @ Left $ class'UILWEWAlert'.default.HoursLeft : T;
}

/** EW's list icon (UIUtilities.GetMissionListItemIcon, by the image UpdateMissions gives each kind). */
static function string Icon(int K)
{
	switch (K)
	{
	case 1: case 3: return "_LandedUFO";
	case 2: return "_Crash";
	case 4: return "_Abduction";
	case 5: return "_TerrorSite";
	case 6: return "_AlienBase";
	case 7: return "_Final";
	default: return "_Special";
	}
}

/** The highlighted entry (RealizeSelected: the list's setFocus, by index as a string). */
function Focus()
{
	local array<ASValue> Params;

	Params.AddItem(Str(string(Highlight)));
	Movie.Invoke(MCPath $ ".theMissionList.setFocus", Params);
}

/** SCAN FOR ACTIVITY: time run until something happens (a month at most), and shown passing as EW's clock races while it
 *  scans, about half a second a day (at most 3 seconds); what happened shown once the clock is there (aek 2026-11-28: the
 *  scan jumped to the next event at once). The campaign's time is run at once: hour by hour it would write a state of the
 *  campaign for every hour into the save. */
function Scan()
{
	local UILWEWStrategyHUD HUD;
	local int Before, Hours;
	local float Seconds;

	Before = class'XComGameState_LWStrategy'.static.Get().Hours;
	Hours = class'XComGameState_LWStrategy'.static.Run(30 * 24);
	Seconds = FClamp(Hours / 24.0 * 0.5, 0.3, 3.0);
	foreach AllActors(class'UILWEWStrategyHUD', HUD)
		HUD.RunClock(Before, Before + Hours, Seconds);
	bScanning = true;
	SetTimer(Seconds + 0.1, false, nameof(ScanDone));
}

function ScanDone()
{
	bScanning = false;
	Geo.Refresh();
	Refresh();
}

/** An entry taken (XGMissionControlUI.OnMissionInput): the scan runs time until something happens (a month at most);
 *  a decision opens its EW alert, or, where EW has none here, the Geoscape takes it. */
function Choose(int i)
{
	if (i < 0 || i >= EntryKinds.Length || Geo == none)
		return;
	if (bScanning)
		return;
	if (EntryKinds[i] == 0)
	{
		Scan();
		return;
	}
	if (EntryKinds[i] >= 20 && class'UILWEWCouncilRequest'.static.Open(Geo, EntryIndexes[i]))
		return;
	if (!class'UILWEWAlert'.static.Open(Geo, EntryKinds[i], EntryIndexes[i], true))
		Geo.ActOn(EntryKinds[i], EntryIndexes[i]);
}

/** A list item's click (the list raises its items' events under its own path; the item's name is its index), or its
 *  pointer (it becomes the highlighted one). */
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int i;

	i = args.Length > 0 ? int(args[args.Length - 1]) : -1;
	if (args.Length > 0 && string(i) == args[args.Length - 1])
	{
		if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN)
		{
			Highlight = i;
			Focus();
			return;
		}
		if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		{
			Highlight = i;
			Choose(i);
			return;
		}
	}
	super.OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true;
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
			if (EntryKinds.Length > 0)
			{
				Highlight = (Highlight + EntryKinds.Length - 1) % EntryKinds.Length;
				Focus();
			}
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
			if (EntryKinds.Length > 0)
			{
				Highlight = (Highlight + 1) % EntryKinds.Length;
				Focus();
			}
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			Choose(Highlight);
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			Leave();
			return true;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
			if (HelpButtonUnderMouse() == "")
				break;
			Leave();
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

/** Mission Control left (ExitMC): this screen and the Geoscape beneath it. */
function Leave()
{
	local UILWGeoscape G;

	G = Geo;
	if (ListTarget != none)
	{
		ChildPanels.RemoveItem(ListTarget);
		ListTarget.Destroy();
		ListTarget = none;
	}
	CloseScreen();
	if (G != none)
		G.CloseScreen();
}
