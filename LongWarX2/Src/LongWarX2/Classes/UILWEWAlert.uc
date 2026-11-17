// Enemy Within's Mission Control alerts (features/lw-mission-control.md) for the Long War Geoscape's decisions, on EW's own
// MissionControl movie as EW's UIMissionControl drives it: the movie loads the alert (Load<Name>), its fields are filled
// (SetTitle, SetContact, SetLocation, SetClass, SetButtonText), then its frame shown (UFOAlertFinishedLoading,
// AlertFullyLoaded). Its first button (or Enter) takes the decision (UILWGeoscape.ActOn); its second, Esc or a right click
// leaves it for later (it stays on the Geoscape's list). The movie's functions are called by Invoke (XCOM 2's queued calls
// do not reach an alert), and an alert whose name is also one of EW's ActionScript classes is attached under the converter's
// name for it (tools/convert/ew-ui.ts: RadarContactAlert's instance is QadarContactAlertMC).
// The alert's clicks come back under its own clip's path, where UILWEWAlertTarget stands to take them.
// For now: a UFO detected (kind 1), a crash site (2) and a landed UFO (3); the other decisions keep the panel's buttons.
class UILWEWAlert extends UILWEWScreen;

var localized string RadarContact, Contact, Location, UFOClass, Unidentified, Scramble, IgnoreContact, SendSkyranger, Ignore,
	CrashSite, HasLanded;

/** The decision (the Geoscape's kind and index) and its screen. */
var int Kind, Index;
var UILWGeoscape Geo;
var string AlertPath;
var UILWEWAlertTarget ClickTarget;

/** Kinds this screen can show. */
static function bool Handles(int K)
{
	return K >= 1 && K <= 3;
}

/** The next decision not yet shown, opened over the Geoscape; false if none (or EW's screens are not converted). */
static function bool OpenNext(UILWGeoscape Geoscape, array<int> Kinds, array<int> Indexes)
{
	local XComHQPresentationLayer HQPres;
	local UILWEWAlert EWScreen;
	local int i;

	HQPres = XComHQPresentationLayer(Geoscape.Movie.Pres);
	if (HQPres == none || !HasEWScreens() || HQPres.ScreenStack.GetFirstInstanceOf(class'UILWEWAlert') != none)
		return false;
	for (i = 0; i < Kinds.Length; i++)
	{
		// (Each decision once while the Geoscape is open.)
		if (!Handles(Kinds[i]) || Geoscape.AlertsShown.Find(Kinds[i] * 100000 + Indexes[i]) != INDEX_NONE)
			continue;
		Geoscape.AlertsShown.AddItem(Kinds[i] * 100000 + Indexes[i]);
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
	super.OnInit();
	// Only the alert: the movie's mission list and clock are the Geoscape's business.
	Movie.SetVariableBool(MCPath $ ".theMissionList._visible", false);
	Movie.SetVariableBool(MCPath $ ".clockMC._visible", false);
	switch (Kind)
	{
		case 1:
			Load("LoadRadarContactAlert", "QadarContactAlertMC");
			break;
		case 2:
			Load("LoadUFOCrashAlert", "UFOCrashAlertMC");
			break;
		default:
			Load("LoadUFOLandedAlert", "UFOLandingAlertMC");
	}
	// (The alert's own onLoad hides its fields a frame after it is attached: filled after that.)
	SetTimer(0.2, false, nameof(Fill));
}

function Load(string Loader, string Instance)
{
	local array<ASValue> NoArgs;

	AlertPath = MCPath $ ".theAlertContainer." $ Instance;
	Movie.Invoke(MCPath $ "." $ Loader, NoArgs);
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
	local array<ASValue> NoArgs;
	local int Ufo, Country;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || Index < 0 || Index >= S.Ufos.Length)
	{
		Leave();
		return;
	}
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
	Movie.Invoke(AlertPath $ ".AlertFullyLoaded", NoArgs);
	ClickTarget = class'UILWEWAlertTarget'.static.At(self, AlertPath);
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

/** The decision taken: the alert closed, the Geoscape acts (the air war, squad select). */
function Accept()
{
	local UILWGeoscape G;
	local int K, I;

	G = Geo;
	K = Kind;
	I = Index;
	Leave();
	if (G != none)
		G.ActOn(K, I);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	`log("LongWarX2: EW alert: mouse" @ cmd @ (args.Length > 1 ? args[args.Length - 2] : "") @ Target, , 'LongWarX2');
	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		if (InStr(Target, "button_0") != INDEX_NONE || (args.Length > 1 && InStr(args[args.Length - 2], "button_0") != INDEX_NONE))
		{
			Accept();
			return;
		}
		if (InStr(Target, "button_1") != INDEX_NONE || (args.Length > 1 && InStr(args[args.Length - 2], "button_1") != INDEX_NONE))
		{
			Leave();
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
