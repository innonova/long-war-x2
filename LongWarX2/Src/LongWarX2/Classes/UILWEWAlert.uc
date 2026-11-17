// Enemy Within's Mission Control alerts (features/lw-mission-control.md) for the Long War Geoscape's decisions, on EW's own
// MissionControl movie as EW's UIMissionControl drives it: the movie loads the alert (Load<Name>), its fields are filled as
// EW's alert classes fill them from XGMissionControlUI.UpdateAlert's data, then its frame shown (UFOAlertFinishedLoading for
// the UFO alerts, AlertFullyLoaded). Its first button (or Enter) takes the decision (UILWGeoscape.ActOn); its second, Esc or
// a right click leaves it for later (it stays on the Geoscape's list). The movie's functions are called by Invoke (XCOM 2's
// queued calls do not reach an alert); an alert whose name is also one of EW's ActionScript classes is attached under the
// converter's name for it (tools/convert/ew-ui.ts: RadarContactAlert's instance is QadarContactAlertMC). The alert's clicks
// come back under its own clip's path, where UILWEWAlertTarget stands to take them.
// The decisions with an alert of EW's: a UFO detected (kind 1), a crash site (2), a landed UFO (3), abductions (4: one alert
// for those come together; "view" opens EW's site selection, AbductionSelection, where one is chosen), terror (5), an alien base
// (6), the Temple Ship (7), the covert operative ready (9) and a council mission (11). The others (the HQ's defence, EXALT's
// base, the council's requests) EW shows on screens of their own; they keep the panel's buttons.
class UILWEWAlert extends UILWEWScreen dependson(LWAirWar);

var localized string RadarContact, Contact, Location, UFOClass, Unidentified, Scramble, IgnoreContact, SendSkyranger, Ignore,
	CrashSite, HasLanded;
var localized string AbductionsReported, ViewAbductionSites, TerrorCity, PanicLevel, Difficulty, FCMission,
	AssaultAlienBase, AssaultTempleShip, TempleShipText, Assault, Wait, ExaltTitle, ExaltBody, ExaltSend, ExaltNotNow,
	AbductionSites, Reward, Confirm, UFOPrefix, SizeLabel, ObjectiveLabel, HyperwaveTitle;
/** A UFO's size (XGItemTree: m_strSizeSmall … VeryLarge), its altitude by
 *  its mission (XGShip_UFO.GetAltitudeString: low, high, very high), and the missions' names (XGStrategyAI.m_arrObjectiveNames,
 *  by Long War's EAlienObjective). */
var localized string SizeNames[4];
var localized string AltitudeNames[3];
var localized string ObjectiveNames[11];
/** The contact alert's jet list (XGInterceptionUI.UpdateSquadron): Long War's stance buttons ("DEF|BAL|AGG"), the kills' words
 *  after the weapon, the jets' statuses (XGLocalizedData.ShipStatusNames, by Long War's interceptor status) and their time
 *  (XGShip_Interceptor: hours, days). */
var localized string LaunchStances, Kills, ValueHours, ValueDays;
/** Mission Control's list (UILWEWMissionControl): its title, the scan, the hours left, the missions' titles (XGMission_*). */
var localized string MissionsTitle, ScanForActivity, HoursLeft, TitleAbductions, TitleTerror, TitleCrash, TitleLanded,
	TitleAlienBase, TitleTempleShip, TitleHQ, TitleCovertExtraction, TitleDataRecovery, TitleExaltRaid;
var localized string StatusNames[8];
/** EW's mission difficulties' names (XGLocalizedData.MissionDifficultyNames: light to swarming). */
var localized string DifficultyNames[4];

/** The decision (the Geoscape's kind and index) and its screen. */
var int Kind, Index;
var UILWGeoscape Geo;
var string AlertPath;
var UILWEWAlertTarget ClickTarget;
/** The abduction site selection (EW's AbductionSelection) open: the sites shown (Long War's site indexes) and the one chosen. */
var bool bSelection;
var array<int> SiteIndexes;
var int Selected;
/** The contact alert's jet list open (UIMissionControl_UFORadarContactAlert's ShipSelection): the jets listed (the air war's
 *  indexes), the one chosen, the stance chosen (Long War's: 1 balanced, 2 aggressive, 3 defensive). */
var bool bShips;
var array<int> ShipJets;
var int ShipSel, StanceSel;

/** Kinds this screen can show. */
static function bool Handles(int K)
{
	return (K >= 1 && K <= 7) || K == 9 || K == 11;
}

/** The next decision not yet shown, opened over the Geoscape; false if none (or EW's screens are not converted). */
static function bool OpenNext(UILWGeoscape Geoscape, array<int> Kinds, array<int> Indexes)
{
	local XComHQPresentationLayer HQPres;
	local int i, j;

	HQPres = XComHQPresentationLayer(Geoscape.Movie.Pres);
	if (HQPres == none || !HasEWScreens() || HQPres.ScreenStack.GetFirstInstanceOf(class'UILWEWAlert') != none)
		return false;
	for (i = 0; i < Kinds.Length; i++)
	{
		// (Each decision once while the Geoscape is open.)
		if (!Handles(Kinds[i]) || Geoscape.AlertsShown.Find(Kinds[i] * 100000 + Indexes[i]) != INDEX_NONE)
			continue;
		Geoscape.AlertsShown.AddItem(Kinds[i] * 100000 + Indexes[i]);
		// (Abductions come together: one alert for all of them, as EW's.)
		if (Kinds[i] == 4)
			for (j = 0; j < Kinds.Length; j++)
				if (Kinds[j] == 4 && Geoscape.AlertsShown.Find(400000 + Indexes[j]) == INDEX_NONE)
					Geoscape.AlertsShown.AddItem(400000 + Indexes[j]);
		return Open(Geoscape, Kinds[i], Indexes[i]);
	}
	return false;
}

/** A decision's alert opened (Mission Control's list: the mission chosen there); abductions straight to their site
 *  selection, as EW's list opens it (XGMissionControlUI.OnMissionInput). False if there is none for it. */
static function bool Open(UILWGeoscape Geoscape, int K, int I, optional bool bSites)
{
	local XComHQPresentationLayer HQPres;
	local UILWEWAlert EWScreen;

	HQPres = XComHQPresentationLayer(Geoscape.Movie.Pres);
	if (HQPres == none || !Handles(K) || !HasEWScreens() || HQPres.ScreenStack.GetFirstInstanceOf(class'UILWEWAlert') != none)
		return false;
	DynamicLoadObject(default.UIPackage $ ".ewxMissionControl", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWAlert', HQPres);
	EWScreen.Package = name("/ package/ewxMissionControl/MissionControl");
	EWScreen.MCName = 'theScreen';
	EWScreen.Kind = K;
	EWScreen.Index = I;
	EWScreen.Geo = Geoscape;
	EWScreen.bSelection = bSites && K == 4;
	HQPres.ScreenStack.Push(EWScreen);
	return true;
}

simulated function OnInit()
{
	local array<ASValue> NoArgs;

	super.OnInit();
	// Only the alert: the movie's mission list, clock and event list are the Geoscape's business (EW's own call for it).
	Movie.Invoke(MCPath $ ".HideNonAlertComponents", NoArgs);
	Movie.SetVariableBool(MCPath $ ".theMissionList._visible", false);
	Movie.SetVariableBool(MCPath $ ".clockMC._visible", false);
	if (bSelection)
	{
		Load("AbductionSelection");
		SetTimer(0.2, false, nameof(FillSelection));
		return;
	}
	switch (Kind)
	{
		case 1: Load("RadarContactAlert"); break;
		case 2: Load("UFOCrashAlert"); break;
		case 3: Load("UFOLandedAlert", "UFOLandingAlert"); break;
		case 4: Load("AbductionAlert"); break;
		case 5: Load("TerrorAlert"); break;
		case 6: Load("AlienBaseAlert"); break;
		case 7: Load("TempleShipAlert"); break;
		case 9: Load("ExaltAlert"); break;
		default: Load("FundingCouncilAlert");
	}
	// (The alert's own onLoad hides its fields a frame after it is attached: filled after that.)
	SetTimer(0.2, false, nameof(Fill));
}

/** The movie's Load<Alert>; the alert attached as <Instance>MC (by default the alert's name), under the converter's name for
 *  it when that is one of EW's classes (Fill finds which). */
function Load(string Alert, optional string Instance)
{
	local array<ASValue> NoArgs;

	if (Instance == "")
		Instance = Alert;
	AlertPath = MCPath $ ".theAlertContainer." $ Instance $ "MC";
	Movie.Invoke(MCPath $ ".Load" $ Alert, NoArgs);
}

/** The alert's clip as attached: its own name, or the converter's (first letter Q, or Z for a Q). */
function FindAlert()
{
	local string Container, Name, Renamed;

	Container = Left(AlertPath, InStr(AlertPath, ".", true) + 1);
	Name = Mid(AlertPath, Len(Container));
	Renamed = (Left(Name, 1) == "Q" ? "Z" : "Q") $ Mid(Name, 1);
	if (Movie.GetVariableObject(AlertPath) == none && Movie.GetVariableObject(Container $ Renamed) != none)
		AlertPath = Container $ Renamed;
}

function Call(string Func, optional string A, optional string B, optional bool bTwo)
{
	local array<ASValue> Params;

	if (A != "" || bTwo)
		Params.AddItem(Str(A));
	if (bTwo)
		Params.AddItem(Str(B));
	Movie.Invoke(AlertPath $ "." $ Func, Params);
}

/** A button's words (EW's AlertWithMultipleButtons: SetButtonText(index, text, disabled)). */
function Button(int i, string Text)
{
	local array<ASValue> Params;
	local ASValue V;

	Params.AddItem(Num(i));
	Params.AddItem(Str(Text));
	V.Type = AS_Boolean;
	V.b = false;
	Params.AddItem(V);
	Movie.Invoke(AlertPath $ ".SetButtonText", Params);
}

/** EW's alerts colour their title and labels (UIUtilities.GetHTMLColoredText: state 3 red EE1C25, 10 orange F78000). */
static function string Coloured(string Text, string Colour)
{
	return "<font color='#" $ Colour $ "'>" $ Text $ "</font>";
}

/** A UFO's size in EW's words: the air war's (LWAirWar: XGItemTree.BuildShips' size, with Long War's changes by the aliens'
 *  research category). */
function string UfoSize(XComGameState_LWStrategy S, int Ufo)
{
	local LWAirWar.LWShip Ship;

	Ship = class'LWAirWar'.static.Ufo(Ufo, S.Category());
	if (Ship.Size == "small")
		return SizeNames[0];
	if (Ship.Size == "medium")
		return SizeNames[1];
	if (Ship.Size == "very_large")
		return SizeNames[3];
	return SizeNames[2];
}

/** Its altitude by its mission (XGShip_UFO.GetAltitudeString): low for research, harvest, abductions, terror and
 *  infiltration; very high for a hunt; high otherwise. */
function string Altitude(int Objective)
{
	switch (Objective)
	{
	case 0: case 2: case 5: case 6: case 7: return AltitudeNames[0];
	case 4: return AltitudeNames[2];
	default: return AltitudeNames[1];
	}
}

function Fill()
{
	local XComGameState_LWStrategy S;
	local array<ASValue> Params, NoArgs;
	local int Ufo, Country;
	local string Colour;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || (Kind <= 3 && (Index < 0 || Index >= S.Ufos.Length)) || ((Kind == 4 || Kind == 5 || Kind == 11) && (Index < 0 || Index >= S.Sites.Length)))
	{
		Leave();
		return;
	}
	FindAlert();
	switch (Kind)
	{
	case 1:
	case 2:
	case 3:
		// XGMissionControlUI.UpdateAlert: eGA_UFODetected, eGA_UFOCrash, eGA_UFOLanded, as UIMissionControl_UFORadarContactAlert
		// and UIMissionControl_UFOAlert show them: the labels red, orange once the Hyperwave Relay reads the UFOs (it adds the
		// UFO's mission). The contact is EW's UFO-<n>: here the UFO's number in the campaign's list.
		Ufo = S.Ufos[Index].Ufo;
		Country = S.Ufos[Index].Country;
		Colour = S.Hyperwave() ? "F78000" : "EE1C25";
		if (Kind == 1)
			Call("SetTitle", Coloured(Caps(RadarContact), Colour));
		else if (Kind == 2)
			Call("SetTitle", Coloured(Caps(CrashSite), Colour));
		else
			Call("SetTitle", Coloured(Caps(Repl(HasLanded, "<XGParam:StrValue0/>", UFOPrefix $ (Index + 1))), Colour));
		Call("SetContact", Coloured(Caps(Contact), Colour), UFOPrefix $ (Index + 1), true);
		Call("SetLocation", Coloured(Caps(Location), Colour), S.CountryName(Country) $ (Kind == 1 ? Altitude(S.Ufos[Index].Objective) : ""), true);
		if (Kind == 1)
			Call("SetSize", Coloured(Caps(SizeLabel), Colour), UfoSize(S, Ufo), true);
		Call("SetClass", Coloured(Caps(UFOClass), Colour), S.Identified(Ufo) ? S.ShipName(Ufo) : Caps(Unidentified), true);
		if (S.Hyperwave())
		{
			Params.AddItem(Str(HyperwaveTitle));
			Params.AddItem(Str(Caps(ObjectiveLabel)));
			Params.AddItem(Str((S.Ufos[Index].Objective >= 0 && S.Ufos[Index].Objective < 11) ? ObjectiveNames[S.Ufos[Index].Objective] : ""));
			Movie.Invoke(AlertPath $ ".SetHyperwaveData", Params);
		}
		Button(0, Caps(Kind == 1 ? Scramble : SendSkyranger));
		Button(1, Caps(Kind == 1 ? IgnoreContact : Ignore));
		Movie.Invoke(AlertPath $ ".UFOAlertFinishedLoading", NoArgs);
		break;
	case 4:
		// eGA_Abduction (AlertWithMultipleButtons): the title, View Abduction Site / Ignore.
		Call("SetTitle", Caps(AbductionsReported));
		Button(0, Caps(ViewAbductionSites));
		Button(1, Caps(Ignore));
		break;
	case 5:
		// eGA_Terror (UIMissionControl_TerrorAlert): Aliens Terrorizing, the place (EW: the city; the port has none: the
		// country), the country's panic (GetPanicBlocks), Alien Activity: the hardest (eMissionDiff_VeryHard).
		Call("SetTitle", Caps(TerrorCity));
		Call("SetCountryName", Caps(S.CountryName(S.Sites[Index].Country)));
		Params.AddItem(Str(Caps(PanicLevel)));
		Params.AddItem(Num(class'LWCouncil'.static.PanicBlocks(S, S.Sites[Index].Country)));
		Movie.Invoke(AlertPath $ ".SetPanicLevel", Params);
		Call("SetDifficulty", Caps(Difficulty), DifficultyNames[3], true);
		Button(0, Caps(SendSkyranger));
		Button(1, Caps(Ignore));
		break;
	case 6:
		// eGA_AlienBase (UIMissionControl_AlienBaseAlert): Assault the Alien Base, its country, Assault / Wait (the decision
		// is offered only with a Skeleton Key held: no notice of one wanted).
		Call("SetTitle", Caps(AssaultAlienBase));
		Call("SetCountry", Caps(Location), S.CountryName(Index), true);
		Button(0, Caps(Assault));
		Button(1, Caps(Wait));
		break;
	case 7:
		// eGA_Temple: Assault the Temple Ship, its words, Assault / Wait.
		Call("SetTitle", Caps(AssaultTempleShip));
		FitTitle(Caps(AssaultTempleShip));
		Call("SetText", TempleShipText);
		Button(0, Caps(Assault));
		Button(1, Caps(Wait));
		break;
	case 9:
		// eGA_ExaltAlert: Operative Ready, its warning, Send Extraction Squad / Not Now.
		Call("SetTitle", Caps(ExaltTitle));
		Call("SetText", ExaltBody);
		Button(0, Caps(ExaltSend));
		Button(1, Caps(ExaltNotNow));
		break;
	default:
		// eGA_FCMission (a SimpleAlert, one button; Esc ignores): Council Mission: its name, Location: its place.
		Call("SetTitle", Caps(FCMission @ class'LWCouncil'.static.KindName(S.Sites[Index].CouncilKind)));
		Call("SetText", Location @ S.CountryName(S.Sites[Index].Country));
		Call("SetButtonText", Caps(SendSkyranger));
	}
	Movie.Invoke(AlertPath $ ".AlertFullyLoaded", NoArgs);
	ClickTarget = class'UILWEWAlertTarget'.static.At(self, AlertPath);
}

/** XCOM 2's fonts stand in for EW's and run wider: the Temple Ship's one-line title (its titleField, wider than the alert's
 *  frame, which cuts it about two thirds of the way across) does not fit as EW's font did. Its size is set so that it does:
 *  measured at a known size (textWidth), scaled to the frame's share of the field. */
function FitTitle(string Title)
{
	local string F;
	local float W, T;
	local int Size;

	F = AlertPath $ ".titleField";
	W = 0.65 * Movie.GetVariableNumber(F $ "._width");
	if (W <= 0 || Movie.GetVariableNumber(F $ ".textWidth") <= W)
		return;
	Call("SetTitle", "<font size='20'>" $ Title $ "</font>");
	T = Movie.GetVariableNumber(F $ ".textWidth");
	if (T <= 0)
		return;
	Size = Clamp(int(20 * W / T), 10, 40);
	Call("SetTitle", "<font size='" $ Size $ "'>" $ Title $ "</font>");
}

/** The alert closed: its click target no longer one of the screen's panels (it made no clip of its own to remove). */
function Leave()
{
	DropClickTarget();
	CloseScreen();
}

function DropClickTarget()
{
	if (ClickTarget != none)
	{
		ChildPanels.RemoveItem(ClickTarget);
		ClickTarget.Destroy();
		ClickTarget = none;
	}
}

/** The decision taken: the alert closed, the Geoscape acts (the air war, squad select). Abductions: EW's site selection
 *  first, where one is chosen and confirmed. */
function Accept()
{
	local UILWGeoscape G;
	local int K, I;

	if (Kind == 4)
	{
		if (bSelection)
			ConfirmSite();
		else
			OpenSelection();
		return;
	}
	if (Kind == 1)
	{
		if (bShips)
			Launch();
		else
			ShowShips();
		return;
	}
	G = Geo;
	K = Kind;
	I = Index;
	Leave();
	if (G != none)
		G.ActOn(K, I);
}

/** The jets based on the UFO's continent (XGInterceptionUI.BuildInterceptorList), each with its weapon and kills and its
 *  status (green when ready, red otherwise: GetStatusUIState), those not ready greyed; Long War's stance buttons under them. */
function ShowShips()
{
	local XComGameState_LWStrategy S;
	local XComGameState_LWAirWar AirWar;
	local XComGameState_LWAirWar.LWJet J;
	local array<ASValue> Params;
	local ASValue V;
	local int i, Continent;

	S = class'XComGameState_LWStrategy'.static.Get();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (S == none || AirWar == none)
		return;
	Continent = S.CountryContinent(S.Ufos[Index].Country);
	ShipJets.Length = 0;
	for (i = 0; i < AirWar.Jets.Length; i++)
		if (AirWar.Jets[i].Continent == Continent)
			ShipJets.AddItem(i);
	if (ShipJets.Length == 0)
		return;
	bShips = true;
	ShipSel = Max(0, ShipJets.Find(class'LWHangar'.static.BestFor(Index)));
	StanceSel = 1;
	foreach ShipJets(i)
	{
		J = AirWar.Jets[i];
		Params.Length = 0;
		Params.AddItem(Str(J.Callsign));
		Params.AddItem(Str(class'LWHangar'.static.WeaponName(J.Weapon) @ "(" $ J.Kills @ Kills));
		Params.AddItem(Str(Coloured(StatusText(J), class'LWHangar'.static.IsReady(J) ? "5CD16C" : "EE1C25")));
		Params.AddItem(Str(J.Type == 3 ? "firestorm" : "interceptor"));
		V.Type = AS_Boolean;
		V.b = !class'LWHangar'.static.IsReady(J);
		Params.AddItem(V);
		Movie.Invoke(AlertPath $ ".AddShip", Params);
	}
	Params.Length = 0;
	Params.AddItem(Str(LaunchStances));
	Movie.Invoke(AlertPath $ ".ActivateShipList", Params);
	FocusShip(-1);
}

/** A jet's status in EW's words (XGShip_Interceptor.GetStatusString): ready, or what it is doing and for how long. */
function string StatusText(XComGameState_LWAirWar.LWJet J)
{
	local string Time;

	if (J.Status <= 0 || J.Status >= 8)
		return StatusNames[0];
	Time = J.HoursDown >= 24 ? Repl(ValueDays, "<XGParam:IntValue0/>", string((J.HoursDown + 23) / 24)) : Repl(ValueHours, "<XGParam:IntValue0/>", string(J.HoursDown));
	return Repl(StatusNames[J.Status], "<XGParam:StrValue0/>", Time);
}

/** The jet and stance shown chosen (SetShipFocus: the jet in the low byte, the stance above it), the one before not. */
function FocusShip(int Before)
{
	local array<ASValue> Params;
	local ASValue V;

	V.Type = AS_Boolean;
	if (Before >= 0)
	{
		Params.AddItem(Num(Before));
		V.b = false;
		Params.AddItem(V);
		Movie.Invoke(AlertPath $ ".SetShipFocus", Params);
		Params.Length = 0;
	}
	Params.AddItem(Num(ShipSel + StanceSel * 256));
	V.b = true;
	Params.AddItem(V);
	Movie.Invoke(AlertPath $ ".SetShipFocus", Params);
}

/** The chosen jet launched at the chosen stance (OnAccept: refused while it is not ready). Long War's stances in the air war's
 *  numbering: balanced 1, aggressive 2, defensive 0. */
function Launch()
{
	local XComGameState_LWAirWar AirWar;
	local UILWGeoscape G;
	local int Jet, Ufo, Stance;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	Jet = ShipJets[ShipSel];
	if (AirWar == none || !class'LWHangar'.static.IsReady(AirWar.Jets[Jet]))
		return;
	G = Geo;
	Ufo = Index;
	Stance = StanceSel == 2 ? 2 : (StanceSel == 3 ? 0 : 1);
	Leave();
	if (G != none)
		G.Intercept(Ufo, Jet, Stance);
}

/** Up and down the jets, left and right the stances (DEF, BAL, AGG on screen: 3, 1, 2), each wrapping round. */
function MoveShip(int Down, int Right)
{
	local int Before, Pos;

	Before = ShipSel + StanceSel * 256;
	ShipSel = (ShipSel + Down + ShipJets.Length) % ShipJets.Length;
	if (Right != 0)
	{
		Pos = StanceSel == 3 ? 0 : (StanceSel == 1 ? 1 : 2);
		Pos = (Pos + Right + 3) % 3;
		StanceSel = Pos == 0 ? 3 : (Pos == 1 ? 1 : 2);
	}
	FocusShip(Before);
}

/** EW's abduction site selection in the alert's place (XGMissionControlUI.OnAlertInput: eGA_Abduction's first reply). */
function OpenSelection()
{
	local array<ASValue> NoArgs;

	DropClickTarget();
	Movie.Invoke(AlertPath $ ".removeMovieClip", NoArgs);
	bSelection = true;
	Load("AbductionSelection");
	SetTimer(0.2, false, nameof(FillSelection));
}

/** The sites (up to EW's three, XGMissionControlUI.UpdateAbduction: the abductions on the map) as its buttons, the one the
 *  alert came for chosen. */
function FillSelection()
{
	local XComGameState_LWStrategy S;
	local array<ASValue> NoArgs;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	SiteIndexes.Length = 0;
	for (i = 0; S != none && i < S.Sites.Length && SiteIndexes.Length < 3; i++)
		if (S.Sites[i].Status == 1 && !S.Sites[i].bTerror && !S.Sites[i].bHQ && !S.Sites[i].bCouncil)
			SiteIndexes.AddItem(i);
	if (SiteIndexes.Length == 0)
	{
		Leave();
		return;
	}
	Selected = Max(0, SiteIndexes.Find(Index));
	FindAlert();
	for (i = 0; i < 3; i++)
	{
		WidgetCall("SetButtonLabel", i, i < SiteIndexes.Length ? Caps(S.CountryName(S.Sites[SiteIndexes[i]].Country)) : "");
		WidgetActive(i, i < SiteIndexes.Length);
	}
	ShowSite();
	Movie.Invoke(AlertPath $ ".AlertFullyLoaded", NoArgs);
	ClickTarget = class'UILWEWAlertTarget'.static.At(self, AlertPath);
}

/** The chosen site's details (UIMissionControl_AbductionSelection.UpdateData): the country, its panic, the alien activity in
 *  EW's colours (light green, moderate yellow, else red), the cash it pays (Long War: every abduction pays cash). */
function ShowSite()
{
	local XComGameState_LWStrategy S;
	local array<ASValue> Params;
	local int Site, Diff;

	S = class'XComGameState_LWStrategy'.static.Get();
	Site = SiteIndexes[Selected];
	Diff = Clamp(S.Sites[Site].Difficulty, 0, 3);
	WidgetCall("SetSelected", Selected);
	Params.AddItem(Str(Caps(AbductionSites)));
	Params.AddItem(Str(Caps(PanicLevel)));
	Params.AddItem(Str(Caps(Difficulty)));
	Params.AddItem(Str(Caps(Reward)));
	Params.AddItem(Str(Confirm));
	Movie.Invoke(AlertPath $ ".SetHeaderLabels", Params);
	Params.Length = 0;
	Params.AddItem(Str(Caps(S.CountryName(S.Sites[Site].Country))));
	Params.AddItem(Num(class'LWCouncil'.static.PanicBlocks(S, S.Sites[Site].Country)));
	Params.AddItem(Str("<font color='#" $ (Diff == 0 ? "5CD16C" : (Diff == 1 ? "FFD038" : "EE1C25")) $ "'>" $ DifficultyNames[Diff] $ "</font>"));
	Params.AddItem(Str(class'LWStrategyRules'.static.Money(S.AbductionReward(Diff))));
	Movie.Invoke(AlertPath $ ".SetData", Params);
}

function ConfirmSite()
{
	local UILWGeoscape G;
	local int I;

	G = Geo;
	I = SiteIndexes[Selected];
	Leave();
	if (G != none)
		G.ActOn(4, I);
}

/** The selection's widget helper (EW's UIWidgetHelper: widgetHelper.<Func>(index[, text])). */
function WidgetCall(string Func, int i, optional string Text)
{
	local array<ASValue> Params;

	Params.AddItem(Num(i));
	if (Func != "SetSelected")
		Params.AddItem(Str(Text));
	Movie.Invoke(AlertPath $ ".widgetHelper." $ Func, Params);
}

function WidgetActive(int i, bool bActive)
{
	local array<ASValue> Params;
	local ASValue V;

	Params.AddItem(Num(i));
	V.Type = AS_Boolean;
	V.b = bActive;
	Params.AddItem(V);
	Movie.Invoke(AlertPath $ ".widgetHelper.SetActive", Params);
}

/** A button clicked (EW's AlertWithMultipleButtons.OnMouseEvent): the clip named button<N> (button_<N>; a simple alert's one
 *  button has no number): the first takes the decision, the second leaves it. */
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Clicked;
	local int i, Before, Stance;

	`log("LongWarX2: EW alert: mouse" @ cmd @ (args.Length > 1 ? args[args.Length - 2] : "") @ (args.Length > 0 ? args[args.Length - 1] : ""), , 'LongWarX2');
	// The jet list (the ShipSelection state's OnMouseEvent): a jet's row chosen as the mouse is on it; a stance button (bal,
	// agg, def) chosen too, and clicked: the chosen jet launched at it.
	if (bShips)
	{
		for (i = args.Length - 1; i >= 0; i--)
		{
			if (InStr(args[i], "ship") == 0 && int(Mid(args[i], 4)) < ShipJets.Length && int(Mid(args[i], 4)) != ShipSel)
			{
				Before = ShipSel + StanceSel * 256;
				ShipSel = int(Mid(args[i], 4));
				FocusShip(Before);
			}
			Stance = InStr(args[i], "bal") == 0 ? 1 : (InStr(args[i], "agg") == 0 ? 2 : (InStr(args[i], "def") == 0 ? 3 : 0));
			if (Stance > 0)
			{
				Before = ShipSel + StanceSel * 256;
				StanceSel = Stance;
				FocusShip(Before);
				if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
					Launch();
				return;
			}
		}
		return;
	}
	// The site selection: a site's button (option<N>) chosen, Confirm sends the squad.
	if (bSelection && cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		for (i = args.Length - 1; i >= 0; i--)
		{
			if (args[i] == "confirmButton")
			{
				ConfirmSite();
				return;
			}
			if (InStr(args[i], "option") == 0 && int(Mid(args[i], 6)) < SiteIndexes.Length)
			{
				Selected = int(Mid(args[i], 6));
				ShowSite();
				return;
			}
		}
	}
	else if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		// (The click's clip is the button's own, or one inside it named "button": the numbered one wins.)
		for (i = args.Length - 1; i >= 0 && Len(Clicked) <= 6; i--)
			if (InStr(args[i], "button") == 0 && Len(args[i]) >= Len(Clicked))
				Clicked = args[i];
		if (Clicked != "")
		{
			if (Right(Clicked, 1) == "1")
				Leave();
			else
				Accept();
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
			if (bSelection)
			{
				Selected = (Selected + SiteIndexes.Length - 1) % SiteIndexes.Length;
				ShowSite();
			}
			else if (bShips)
				MoveShip(-1, 0);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
			if (bSelection)
			{
				Selected = (Selected + 1) % SiteIndexes.Length;
				ShowSite();
			}
			else if (bShips)
				MoveShip(1, 0);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
			if (bShips)
				MoveShip(0, -1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
			if (bShips)
				MoveShip(0, 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			Accept();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			Leave();
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}
