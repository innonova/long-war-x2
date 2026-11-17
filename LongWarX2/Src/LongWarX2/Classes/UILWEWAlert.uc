// Enemy Within's Mission Control alerts (features/lw-mission-control.md) for the Long War Geoscape's decisions, on EW's own
// MissionControl movie as EW's UIMissionControl drives it: the movie loads the alert (Load<Name>), its fields are filled as
// EW's alert classes fill them from XGMissionControlUI.UpdateAlert's data, then its frame shown (UFOAlertFinishedLoading for
// the UFO alerts, AlertFullyLoaded). Its first button (or Enter) takes the decision (UILWGeoscape.ActOn); its second, Esc or
// a right click leaves it for later (it stays on the Geoscape's list). The movie's functions are called by Invoke (XCOM 2's
// queued calls do not reach an alert); an alert whose name is also one of EW's ActionScript classes is attached under the
// converter's name for it (tools/convert/ew-ui.ts: RadarContactAlert's instance is QadarContactAlertMC). The alert's clicks
// come back under its own clip's path, where UILWEWAlertTarget stands to take them.
// The decisions with an alert of EW's: a UFO detected (kind 1), a crash site (2), a landed UFO (3), abductions (4: one alert
// for those come together; "view" leaves the Geoscape's list of their sites, EW's site selection), terror (5), an alien base
// (6), the Temple Ship (7), the covert operative ready (9) and a council mission (11). The others (the HQ's defence, EXALT's
// base, the council's requests) EW shows on screens of their own; they keep the panel's buttons.
class UILWEWAlert extends UILWEWScreen;

var localized string RadarContact, Contact, Location, UFOClass, Unidentified, Scramble, IgnoreContact, SendSkyranger, Ignore,
	CrashSite, HasLanded;
var localized string AbductionsReported, ViewAbductionSites, TerrorCity, PanicLevel, Difficulty, Swarming, FCMission,
	AssaultAlienBase, AssaultTempleShip, TempleShipText, Assault, Wait, ExaltTitle, ExaltBody, ExaltSend, ExaltNotNow;

/** The decision (the Geoscape's kind and index) and its screen. */
var int Kind, Index;
var UILWGeoscape Geo;
var string AlertPath;
var UILWEWAlertTarget ClickTarget;

/** Kinds this screen can show. */
static function bool Handles(int K)
{
	return (K >= 1 && K <= 7) || K == 9 || K == 11;
}

/** The next decision not yet shown, opened over the Geoscape; false if none (or EW's screens are not converted). */
static function bool OpenNext(UILWGeoscape Geoscape, array<int> Kinds, array<int> Indexes)
{
	local XComHQPresentationLayer HQPres;
	local UILWEWAlert EWScreen;
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
		DynamicLoadObject(default.UIPackage $ ".ewxMissionControl", class'Object', true);
		EWScreen = HQPres.Spawn(class'UILWEWAlert', HQPres);
		EWScreen.Package = name("/ package/ewxMissionControl/MissionControl");
		EWScreen.MCName = 'theScreen';
		EWScreen.Kind = Kinds[i];
		EWScreen.Index = Indexes[i];
		EWScreen.Geo = Geoscape;
		HQPres.ScreenStack.Push(EWScreen);
		return true;
	}
	return false;
}

simulated function OnInit()
{
	local array<ASValue> NoArgs;

	super.OnInit();
	// Only the alert: the movie's mission list, clock and event list are the Geoscape's business (EW's own call for it).
	Movie.Invoke(MCPath $ ".HideNonAlertComponents", NoArgs);
	Movie.SetVariableBool(MCPath $ ".theMissionList._visible", false);
	Movie.SetVariableBool(MCPath $ ".clockMC._visible", false);
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

/** EW's alerts colour their title and labels (UIUtilities.GetHTMLColoredText, state 3: red). */
static function string Red(string Text)
{
	return "<font color='#ee1c25'>" $ Text $ "</font>";
}

function Fill()
{
	local XComGameState_LWStrategy S;
	local array<ASValue> Params, NoArgs;
	local int Ufo, Country;

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
		// XGMissionControlUI.UpdateAlert: eGA_UFODetected, eGA_UFOCrash, eGA_UFOLanded.
		Ufo = S.Ufos[Index].Ufo;
		Country = S.Ufos[Index].Country;
		if (Kind == 1)
			Call("SetTitle", Red(Caps(RadarContact)));
		else if (Kind == 2)
			Call("SetTitle", Red(Caps(CrashSite)));
		else
			Call("SetTitle", Red(Caps(Repl(HasLanded, "<XGParam:StrValue0/>", S.UfoLabel(Ufo)))));
		Call("SetContact", Red(Caps(Contact)), S.UfoLabel(Ufo), true);
		Call("SetLocation", Red(Caps(Location)), S.CountryName(Country), true);
		Call("SetClass", Red(Caps(UFOClass)), S.Identified(Ufo) ? S.UfoLabel(Ufo) : Caps(Unidentified), true);
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
		Call("SetDifficulty", Caps(Difficulty), Swarming, true);
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
	if (ClickTarget != none)
	{
		ChildPanels.RemoveItem(ClickTarget);
		ClickTarget.Destroy();
		ClickTarget = none;
	}
	CloseScreen();
}

/** The decision taken: the alert closed, the Geoscape acts (the air war, squad select). Abductions: their sites are the
 *  Geoscape's list (EW's site selection), where one is chosen. */
function Accept()
{
	local UILWGeoscape G;
	local int K, I;

	G = Geo;
	K = Kind;
	I = Index;
	Leave();
	if (G != none && K != 4)
		G.ActOn(K, I);
}

/** A button clicked (EW's AlertWithMultipleButtons.OnMouseEvent): the clip named button<N> (button_<N>; a simple alert's one
 *  button has no number): the first takes the decision, the second leaves it. */
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Clicked;
	local int i;

	`log("LongWarX2: EW alert: mouse" @ cmd @ (args.Length > 1 ? args[args.Length - 2] : "") @ (args.Length > 0 ? args[args.Length - 1] : ""), , 'LongWarX2');
	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
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
