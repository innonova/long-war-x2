// An Enemy Within screen's own Flash movie shown in XCOM 2 (the experiment of features/lw-ew-screens.md): the movie of
// the converted EW UI package (tools/convert/ew-ui.ts: EWStrategyUI.upk in the mod's Content), at
// "/ package/ewx<Screen>/<Screen>". Nothing drives it yet: it shows what EW's movie draws by itself. Escape closes it.
class UILWEWScreen extends UIScreen;

// EW's strategy pictures, in EW's base as the setup converts it (tools/convert/ew-images.ts): asked for by the image
// path "img:" + "///" + this + ".Group.Name", as EW asked for its UILibrary_StrategyImages.
const EW_IMAGES = "Command1.QILibrary_StrategyImages";

var string UIPackage;
/** EW's movies are laid out for a 1280 x 720 stage, XCOM 2's is 1920 x 1080: every EW screen is scaled up by this, as EW
 *  scaled its whole stage to the window, and EW's framework is told a stage this much smaller (SetEWView), so a screen
 *  that places itself by the stage's edges (EW's HUD, the hub, the hangar's list) lands where EW put it, at EW's size.
 *  (Before 2026-11-17 those screens were left unscaled and drew at two-thirds of EW's size: ew-compare.) */
const STAGE_SCALE = 1.5;
var bool bScaleToStage;
/** Where EW placed the screen's clip on its stage (ScaleToStage): a point of EW's stage is this far from the clip. */
var float StageX, StageY;
/** Whether the screen shows EW's base itself (the build screens): the screen under it does not hide the base for it. */
var bool bShowsBase;
/** The base's camera the screen stands over, as EW shows it over its room (research, engineering, the hangar …): the base
 *  shown and looked at through it as the screen comes up and comes back (the screen under it may have handed the view back);
 *  none: the screen makes its own background. */
var name BaseCamera;
/** EW's 3D panel the screen stands on in its room, and EW's camera onto it (features/ew-3d-screens.md): with
 *  LWX2EWBase.ScreensIn3D, the screen goes into XCOM 2's 3D movie (Push3D) and shows on that panel. */
var name EWDisplay, EWDisplayCamera;
var LWX2UIDisplay ShownOn;
/** The screen's movie (EW's SwfMovie in the converted package), held while the screen is up. Nothing else holds the
 *  package: a garbage collection between loading it and Flash looking the movie up (the base's levels streaming in at a
 *  campaign's start ran one) purged it, and Mission Control came up empty and stayed so ("Failed to find object 'SwfMovie
 *  ewxMissionControl.missioncontrol'"; ew-compare, 2026-11-17). */
var Object MovieObject;
/** The help bar buttons attached (HelpButton), as <container>.<L|R>.<button>, for their layout. */
var array<string> HelpButtons;

/** The presentation layer up now (the strategy layer's, or the shell's for EW's game creation screens): the test aids'. */
static function XComPresentationLayerBase AnyPres()
{
	return XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).Pres;
}

/** Whether the converted EW UI package is in the mod's Content (loading one of its objects loads it whole). */
static function bool HasEWScreens()
{
	return DynamicLoadObject(default.UIPackage $ ".ewxChooseTech", class'Object', true) != none;
}

/** The converted package loaded (any of its objects loads it whole), then the screen pushed with EW's movie. */
static function string ShowMovie(string MovieName, optional string Instance)
{
	local XComHQPresentationLayer HQPres;
	local UILWEWScreen EWScreen;
	local Object Loaded;

	HQPres = `HQPRES;
	if (HQPres == none)
		return "ERR not on the Avenger";
	Loaded = DynamicLoadObject(default.UIPackage $ ".ewx" $ MovieName, class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWScreen', HQPres);
	EWScreen.Package = name("/ package/ewx" $ MovieName $ "/" $ MovieName);
	// The movie's own instance on its stage (EW names it per screen: theChooseResearch, theStrategyHUD …).
	if (Instance != "")
		EWScreen.MCName = name(Instance);
	HQPres.ScreenStack.Push(EWScreen);
	`log("LongWarX2: EW screen" @ MovieName @ "pushed, package" @ default.UIPackage @ (Loaded != none ? "loaded" : "not found by that path"), , 'LongWarX2');
	return "ok" @ EWScreen.Package @ (Loaded != none ? "(package loaded)" : "(package object not found by that path)");
}

/** A function of EW's movie called on the top EW screen, as EW's own script calls it (its AS_ functions): each argument a
 *  number when it reads as one, else a string. */
static function string CallMovie(array<string> Args)
{
	local UILWEWScreen EWScreen;
	local int i;

	EWScreen = UILWEWScreen(AnyPres().ScreenStack.GetFirstInstanceOf(class'UILWEWScreen'));
	if (EWScreen == none || Args.Length < 2)
		return "ERR no EW screen open (ewscreen <movie>), or no function given";
	EWScreen.MC.BeginFunctionOp(Args[1]);
	for (i = 2; i < Args.Length; i++)
	{
		// (s:<text>: a string even when it reads as a number.)
		if (Left(Args[i], 2) == "s:")
			EWScreen.MC.QueueString(Mid(Args[i], 2));
		else if (string(int(Args[i])) == Args[i])
			EWScreen.MC.QueueNumber(int(Args[i]));
		else
			EWScreen.MC.QueueString(Repl(Args[i], "_", " "));
	}
	EWScreen.MC.EndOp();
	return "ok" @ EWScreen.MCPath $ "." $ Args[1] @ "with" @ (Args.Length - 2) @ "arguments";
}

/** A function of the movie called at once (below the screen's clip), with these arguments. */
function CallNow(string Func, optional array<ASValue> Params)
{
	Movie.Invoke(MCPath $ "." $ Func, Params);
}

static function ASValue Str(string Text)
{
	local ASValue V;

	V.Type = AS_String;
	V.s = Text;
	return V;
}

/** Text in one of EW's colours, by EW's state numbers (EW's UIUtilities.GetHTMLColoredText): 0 normal, 1 disabled, 2 good,
 *  3 bad, 4 warning, 5 highlight, 6 cash, 10 and 12 hyperwave, 11 psionic. */
static function string EWColoured(string Txt, int EWState, optional int FontSize = -1)
{
	local string Colour;

	if (Txt == "")
		return Txt;
	switch (EWState)
	{
	case 1: Colour = "808080"; break;
	case 2: case 6: Colour = "5CD16C"; break;
	case 3: Colour = "EE1C25"; break;
	case 4: Colour = "FFD038"; break;
	case 5: Colour = "B9FFFF"; break;
	case 10: case 12: Colour = "F78000"; break;
	case 11: Colour = "A09CD6"; break;
	default: Colour = "67E8ED";
	}
	return "<font " $ (FontSize > 0 ? "size='" $ FontSize $ "' " : "") $ "color='#" $ Colour $ "'>" $ Txt $ "</font>";
}

static function ASValue Num(float N)
{
	local ASValue V;

	V.Type = AS_Number;
	V.n = N;
	return V;
}

/** A function of the top EW screen's movie called at once (Movie.Invoke), its result (a test aid: ewinvoke). */
static function string InvokeMovie(array<string> Args)
{
	local UILWEWScreen EWScreen;
	local array<ASValue> Params;
	local ASValue V, Result;
	local int i;

	EWScreen = UILWEWScreen(AnyPres().ScreenStack.GetFirstInstanceOf(class'UILWEWScreen'));
	if (EWScreen == none || Args.Length < 2)
		return "ERR no EW screen open, or no function given";
	for (i = 2; i < Args.Length; i++)
	{
		if (Left(Args[i], 2) == "s:")
		{
			// (A command's words are split at spaces: "_" stands for one.)
			V.Type = AS_String;
			V.s = Repl(Mid(Args[i], 2), "_", " ");
		}
		else if (Args[i] ~= "true" || Args[i] ~= "false")
		{
			V.Type = AS_Boolean;
			V.b = Args[i] ~= "true";
		}
		else
		{
			V.Type = AS_Number;
			V.n = float(Args[i]);
		}
		Params.AddItem(V);
	}
	Result = EWScreen.Movie.Invoke(EWScreen.MCPath $ "." $ Args[1], Params);
	return "ok" @ Args[1] @ "returned" @ Result.Type @ Result.s @ Result.n @ Result.b;
}

/** A variable of the top EW screen's movie set, below its clip (a test aid: ewset): true, false or a number. */
static function string SetVar(string SubPath, string Value)
{
	local UILWEWScreen EWScreen;

	EWScreen = UILWEWScreen(AnyPres().ScreenStack.GetFirstInstanceOf(class'UILWEWScreen'));
	// (2nd:<path>: inside the screen under the top one, as ReadVar's.)
	if (Left(SubPath, 4) == "2nd:")
	{
		EWScreen = AnyPres().ScreenStack.Screens.Length > 1 ? UILWEWScreen(AnyPres().ScreenStack.Screens[1]) : none;
		SubPath = Mid(SubPath, 4);
	}
	if (EWScreen == none || SubPath == "")
		return "ERR no EW screen open, or no path";
	// (abs:<path>: from the movie's root, as ReadVar's.)
	if (Left(SubPath, 4) == "abs:")
	{
		if (Value ~= "true" || Value ~= "false")
			EWScreen.Movie.SetVariableBool(Mid(SubPath, 4), Value ~= "true");
		else
			EWScreen.Movie.SetVariableNumber(Mid(SubPath, 4), float(Value));
		return "ok" @ Mid(SubPath, 4) @ "=" @ Value;
	}
	if (Value ~= "true" || Value ~= "false")
		EWScreen.Movie.SetVariableBool(EWScreen.MCPath $ "." $ SubPath, Value ~= "true");
	else
		EWScreen.Movie.SetVariableNumber(EWScreen.MCPath $ "." $ SubPath, float(Value));
	return "ok" @ EWScreen.MCPath $ "." $ SubPath @ "=" @ Value;
}

/** A variable of the top EW screen's movie, below its clip (a test aid: ewvar). */
static function string ReadVar(string SubPath)
{
	local UILWEWScreen EWScreen;
	local UILWEWStrategyHUD HUD;
	local UILWEWRadar Radar;
	local UIScreen Top;

	// (abs:<path>: a path from the movie's root, _global.<Class> too, in the movie of the EW screen up.)
	if (Left(SubPath, 4) == "abs:")
	{
		EWScreen = UILWEWScreen(AnyPres().ScreenStack.GetFirstInstanceOf(class'UILWEWScreen'));
		return EWScreen == none ? "ERR no EW screen" : Mid(SubPath, 4) @ "=" @ EWScreen.Movie.GetVariableString(Mid(SubPath, 4));
	}
	// (radar:<path>: inside EW's tactical radar's movie (UILWEWRadar), not on the stack either; "radar:" alone its path.)
	if (Left(SubPath, 6) == "radar:")
	{
		foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'UILWEWRadar', Radar)
			return Mid(SubPath, 6) == "" ? string(Radar.MCPath) : (Radar.MCPath $ "." $ Mid(SubPath, 6) @ "=" @ Radar.Movie.GetVariableString(Radar.MCPath $ "." $ Mid(SubPath, 6)));
		return "ERR no EW radar";
	}
	// (any:<path>: a path from the 2D movie's root, the tactical one too.)
	if (Left(SubPath, 4) == "any:")
	{
		foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'UILWEWRadar', Radar)
			return Mid(SubPath, 4) @ "=" @ Radar.Movie.GetVariableString(Mid(SubPath, 4));
		return "ERR no EW radar";
	}
	// (hud:<path>: inside EW's strategy HUD, which is not on the screen stack.)
	if (Left(SubPath, 4) == "hud:")
	{
		foreach `HQPRES.AllActors(class'UILWEWStrategyHUD', HUD)
			return HUD.MCPath $ "." $ Mid(SubPath, 4) @ "=" @ HUD.Movie.GetVariableString(HUD.MCPath $ "." $ Mid(SubPath, 4));
		return "ERR no EW strategy HUD up";
	}
	// (2nd:<path>: inside the screen under the top one, as the Situation Room under its HUD.)
	if (Left(SubPath, 4) == "2nd:")
	{
		EWScreen = AnyPres().ScreenStack.Screens.Length > 1 ? UILWEWScreen(AnyPres().ScreenStack.Screens[1]) : none;
		SubPath = Mid(SubPath, 4);
		return EWScreen == none ? "ERR no EW screen second" : EWScreen.MCPath $ "." $ SubPath @ "=" @ EWScreen.Movie.GetVariableString(EWScreen.MCPath $ "." $ SubPath);
	}
	Top = AnyPres().ScreenStack.GetCurrentScreen();
	EWScreen = UILWEWScreen(Top) != none ? UILWEWScreen(Top) : UILWEWScreen(AnyPres().ScreenStack.GetFirstInstanceOf(class'UILWEWScreen'));
	if (EWScreen == none)
		return "ERR no EW screen";
	return EWScreen.MCPath $ "." $ SubPath @ "=" @ EWScreen.Movie.GetVariableString(EWScreen.MCPath $ "." $ SubPath);
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	HoldMovie();
	super.InitScreen(InitController, InitMovie, InitName);
	LendXCom2Spawning(Movie);
}

simulated function OnInit()
{
	super.OnInit();
	if (bScaleToStage)
		ScaleToStage();
	SetEWView(Movie);
	ShowRoom();
	ShowOnPanel();
	class'UILWEWStrategyHUD'.static.RelayHelpBar(self);
	`log("LongWarX2: EW screen" @ Package @ "inited", , 'LongWarX2');
}

/** The screen pushed: onto its EW panel in 3D where it has one (EWDisplay, LWX2EWBase.ScreensIn3D), else flat. */
static function Push3D(XComHQPresentationLayer HQPres, UILWEWScreen S)
{
	if (S.EWDisplay != '' && class'LWX2EWBase'.default.ScreensIn3D && class'LWX2EWBase'.static.DisplayFor(HQPres, S.EWDisplay) != none)
	{
		S.BaseCamera = S.EWDisplayCamera != '' ? S.EWDisplayCamera : S.BaseCamera;
		// (Its clicks taken under a 2D screen of its own too, as the Situation Room's HUD over its satellites' view:
		// XCOM 2 hands mouse events only to a focused screen, UIMovie.FlashRaiseMouseEvent.)
		S.bProcessMouseEventsIfNotFocused = true;
		HQPres.ScreenStack.Push(S, HQPres.Get3DMovie());
		return;
	}
	HQPres.ScreenStack.Push(S);
}

/** In 3D: the movie shown on the screen's EW panels (the Situation Room's wall is several of one tag). */
function ShowOnPanel()
{
	local LWX2EWBase B;
	local LWX2UIDisplay D;

	if (!bIsIn3D || EWDisplay == '')
		return;
	ShownOn = class'LWX2EWBase'.static.DisplayFor(self, EWDisplay);
	if (ShownOn == none)
		return;
	B = class'LWX2EWBase'.static.Get(self);
	foreach B.Displays(D)
		if (D != none && D.Tag == EWDisplay && D.bEWMesh)
		{
			ShownOn = D;
			break;
		}
	UIMovie_3D(Movie).ShowDisplay(EWDisplay, ShownOn);
	B = class'LWX2EWBase'.static.Get(self);
	// (Of a tag with several panels, those with EW's own mesh only: its UVs take each panel's part of the movie.)
	foreach B.Displays(D)
		if (D != none && D.Tag == EWDisplay && D != ShownOn && (D.bEWMesh || !ShownOn.bEWMesh))
			UIMovie_3D(Movie).ShowDisplayByInst(D);
}

simulated function OnRemoved()
{
	local LWX2EWBase B;
	local LWX2UIDisplay D;

	if (bIsIn3D && ShownOn != none)
	{
		B = class'LWX2EWBase'.static.Get(self);
		foreach B.Displays(D)
			if (D != none && D.Tag == EWDisplay)
				UIMovie_3D(Movie).HideDisplayByInst(D);
	}
	super.OnRemoved();
}

/** The movie Package names ("/ package/ewx<Group>/<Movie>") loaded and held (MovieObject). The group is the movie's
 *  outermost package (its path is ewx<Group>.<Movie>), loaded with the converted file through its name in it. */
function HoldMovie()
{
	local string P;
	local int i;

	P = string(Package);
	i = InStr(P, "ewx");
	if (i == INDEX_NONE || MovieObject != none)
		return;
	P = Mid(P, i);
	i = InStr(P, "/");
	if (i == INDEX_NONE)
		return;
	DynamicLoadObject(UIPackage $ "." $ Left(P, i), class'Object', true);
	MovieObject = FindObject(Left(P, i) $ "." $ Mid(P, i + 1), class'Object');
	if (MovieObject == none)
		`log("LongWarX2: EW screen: no movie" @ Left(P, i) $ "." $ Mid(P, i + 1), , 'LongWarX2');
}

/** EW's camera into the first facility of a kind (EW's Base.LookAtFacility: the add-on camera of its tile), '' if none. */
static function name FacilityCamera(int Facility)
{
	local XComGameState_LWStrategy S;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = 0; S != none && i < S.TileFacility.Length; i++)
		if (S.TileFacility[i] == Facility)
			return name("AddonCam_R" $ (i / class'LWBase'.const.W) $ "_C" $ (i % class'LWBase'.const.W + 1));
	return '';
}

/** EW's base behind the screen, through its room's camera (BaseCamera). */
function ShowRoom()
{
	local LWX2EWBase B;

	if (BaseCamera == '')
		return;
	B = class'LWX2EWBase'.static.Get(self);
	if (B == none)
		return;
	B.Show();
	B.LookAt(BaseCamera, 0);
}

/** Under a dialog (EW's confirmations: CONFIRM UPGRADE, NEW TRAINING, ...) the screen stays in view, as EW's: XCOM 2 hides a
 *  screen losing the focus, which left the base's black cutaway around the dialog (the click tests' shot, 2026-11-23). */
simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	SetTimer(0.01, false, nameof(ShowUnderDialog));
}

function ShowUnderDialog()
{
	// (And under EW's item cards, as EW shows the craft summary behind a WEAPON INFO card: the navigation map's pair.)
	if (!bIsFocused && (UIDialogueBox(Movie.Pres.ScreenStack.GetCurrentScreen()) != none || UILWEWItemCard(Movie.Pres.ScreenStack.GetCurrentScreen()) != none)
		&& Movie.Pres.ScreenStack.GetScreen(class) == self)
		Show();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (bIsInited)
	{
		ShowRoom();
		ShowOnPanel();
	}
}

/**
 * EW's 1280x720 stage onto XCOM 2's 1920x1080: the screen's clip scaled, and moved as the stage is (XCOM 2's SetPanelScale
 * scales a clip about its own origin; a screen EW placed away from the stage's corner, the Gene Mods' at (582, 397), would
 * otherwise reach past the top and left edges).
 */
function ScaleToStage()
{
	local float Scale;

	Scale = STAGE_SCALE;
	StageX = Movie.GetVariableNumber(MCPath $ "._x");
	StageY = Movie.GetVariableNumber(MCPath $ "._y");
	SetPanelScale(Scale);
	if (StageX != 0 || StageY != 0)
	{
		Movie.SetVariableNumber(MCPath $ "._x", StageX * Scale);
		Movie.SetVariableNumber(MCPath $ "._y", StageY * Scale);
	}
}

/**
 * XCOM 2's widgets spawned inside EW's clips (the hub's room list, the Situation Room's earth): XCOM 2 makes a widget's clip
 * by calling spawnChildPanel on its parent clip, which EW's clips had only while they ran on XCOM 2's framework (the class
 * names clashed). Now that they run on EW's own (tools/convert/ew-ui.ts), XCOM 2's spawnChildPanel is lent to every movie
 * clip without one (MovieClip's prototype; XCOM 2's own panels keep theirs). Once a session; the class that has it is found
 * among XCOM 2's (LendFrom).
 */
static function LendXCom2Spawning(UIMovie TheMovie)
{
	local GFxObject From, Fn, ClipProto;
	local string C;
	local array<string> Classes;

	ClipProto = TheMovie.GetVariableObject("_global.MovieClip.prototype");
	if (ClipProto == none || TheMovie.GetVariableString("_global.MovieClip.prototype.spawnChildPanel") != "")
		return;
	Classes.AddItem("Panel");
	Classes.AddItem("UIPanel");
	Classes.AddItem("XComPanel");
	Classes.AddItem("Control");
	Classes.AddItem("Screen");
	foreach Classes(C)
	{
		if (TheMovie.GetVariableString("_global." $ C $ ".prototype.spawnChildPanel") == "")
			continue;
		From = TheMovie.GetVariableObject("_global." $ C $ ".prototype");
		Fn = From != none ? From.GetObject("spawnChildPanel") : none;
		if (Fn == none)
			continue;
		ClipProto.SetObject("spawnChildPanel", Fn);
		`log("LongWarX2: EW screens: XCOM 2's spawnChildPanel (" $ C $ ") lent to movie clips", , 'LongWarX2');
		return;
	}
	`log("LongWarX2: EW screens: XCOM 2's spawnChildPanel not found", , 'LongWarX2');
}

/**
 * EW's Flash framework told the stage, as XCOM 2 tells its own (UIMovie.SetResolutionAndSafeArea: SetUIView), in EW's
 * stage units (XCOM 2's divided by STAGE_SCALE, the scale every EW screen is drawn at). EW's movies
 * run on their own framework (tools/convert/ew-ui.ts renames its classes: Environment is Qnvironment), whose singleton
 * anchors EW's screens to the stage edges by what SetView last said (EW's game said it); and the mouse made active, as on
 * the PC.
 */
static function SetEWView(UIMovie TheMovie)
{
	local GFxObject Env;
	local array<ASValue> Args;
	local ASValue V;

	Env = TheMovie.GetVariableObject("_global.Qnvironment._instance");
	if (Env == none)
		return;
	V.Type = AS_Number;
	V.n = TheMovie.m_v2ScaledDimension.X / STAGE_SCALE;
	Args.AddItem(V);
	V.n = TheMovie.m_v2ScaledDimension.Y / STAGE_SCALE;
	Args.AddItem(V);
	V.n = 0;
	Args.AddItem(V);
	V.n = TheMovie.m_v2ScaledOrigin.X / STAGE_SCALE;
	Args.AddItem(V);
	V.n = TheMovie.m_v2ScaledOrigin.Y / STAGE_SCALE;
	Args.AddItem(V);
	V.n = 0;
	Args.AddItem(V);
	V.Type = AS_Boolean;
	V.b = false;
	Args.AddItem(V);
	Env.Invoke("SetView", Args);
	Args.Length = 0;
	V.b = true;
	Args.AddItem(V);
	Env.Invoke("setMouseActive", Args);
}

/**
 * A button of one of EW's help bars (XComHelpBar: SECOND WAVE, START GAME, BACK …), attached into the bar's left or right
 * container as the bar's AddLeftButtonHelp/AddRightButtonHelp would (the button EW's: Type, as SetButtonType sets it;
 * buttonHelp_<Index>, whose clicks name it; its label, icon and style in the init fields EW passes). In the converted
 * shell movies the bar's own adding makes nothing (its container's add, for every kind of item; plain attaching works:
 * strategy-flow.md), so the button is attached here and laid out as the bar would: left to right in the left container,
 * right to left from the right container's place (LayOutHelpButtons, once they have their width).
 */
function HelpButton(string Bar, bool bRight, int Index, string Label, string Icon, optional string Type = "QComButton")
{
	local GFxObject Box, B;
	local array<ASValue> Args;
	local string Path;

	Path = MCPath $ "." $ Bar;
	Box = Movie.GetVariableObject(Path $ (bRight ? ".rightBtnHelpContainer" : ".leftBtnHelpContainer"));
	if (Box == none)
	{
		`log("LongWarX2: EW screen: no help bar" @ Bar, , 'LongWarX2');
		return;
	}
	B = Box.AttachMovie(Type, "buttonHelp_" $ Index);
	if (B == none)
		return;
	B.SetString("initLabel", Label);
	B.SetString("initIcon", Icon);
	B.SetBool("initDisabled", false);
	B.SetFloat("style", Movie.GetVariableNumber(Path $ (bRight ? ".rightContainerButtonStyle" : ".leftContainerButtonStyle")));
	B.SetBool("isResizingToText", true);
	// (Its own setters too: it read its init fields as it was made, before they were set here.)
	Args.AddItem(Str(Label));
	B.Invoke("setText", Args);
	HelpButtons.AddItem(Path $ (bRight ? ".rightBtnHelpContainer.R." : ".leftBtnHelpContainer.L.") $ "buttonHelp_" $ Index);
	SetTimer(0.1, false, nameof(LayOutHelpButtons));
}

/** The help bars' buttons laid out as EW's bar lays them out once they have loaded (XComHelpBar.onLeftButtonHelpLoaded,
 *  onRightButtonHelpLoaded): side by side in their container, the container raised by the first button's height from
 *  its start, and the right one moved left by its buttons' width from its start (its start is its right edge). */
function LayOutHelpButtons()
{
	local array<string> Boxes;
	local string P, Box, Bar, Side;
	local float X, W, H;
	local int k, b;

	foreach HelpButtons(P)
	{
		k = InStr(P, ".R.") != INDEX_NONE ? InStr(P, ".R.") : InStr(P, ".L.");
		if (Boxes.Find(Left(P, k)) == INDEX_NONE)
			Boxes.AddItem(Left(P, k));
		if (Movie.GetVariableNumber(Left(P, k) $ "." $ Mid(P, k + 3) $ "._width") <= 0)
		{
			SetTimer(0.1, false, nameof(LayOutHelpButtons));
			return;
		}
	}
	for (b = 0; b < Boxes.Length; b++)
	{
		Box = Boxes[b];
		Side = InStr(Box, ".rightBtnHelpContainer") != INDEX_NONE ? "right" : "left";
		Bar = Left(Box, InStr(Box, "." $ Side $ "BtnHelpContainer"));
		X = 0;
		H = 0;
		foreach HelpButtons(P)
		{
			k = InStr(P, ".R.") != INDEX_NONE ? InStr(P, ".R.") : InStr(P, ".L.");
			if (Left(P, k) != Box)
				continue;
			W = Movie.GetVariableNumber(Box $ "." $ Mid(P, k + 3) $ "._width");
			if (H == 0)
				H = Movie.GetVariableNumber(Box $ "." $ Mid(P, k + 3) $ "._height");
			Movie.SetVariableNumber(Box $ "." $ Mid(P, k + 3) $ "._x", X);
			X += W;
		}
		Movie.SetVariableNumber(Box $ "._y", Movie.GetVariableNumber(Bar $ "." $ Side $ "ContainerStartPos.y") - H);
		if (Side == "right")
			Movie.SetVariableNumber(Box $ "._x", Movie.GetVariableNumber(Bar $ ".rightContainerStartPos.x") - X);
	}
}

/** The help bar button under the mouse (HelpButton's), as "<bar>.buttonHelp_<n>", or "". Their clicks are found so:
 *  attached outside EW's container, they report none (the container relays them in EW). */
function string HelpButtonUnderMouse()
{
	local string P, Clip, Bar;
	local float MouseX, MouseY, W, H;
	local int k;

	foreach HelpButtons(P)
	{
		k = InStr(P, ".R.") != INDEX_NONE ? InStr(P, ".R.") : InStr(P, ".L.");
		Clip = Left(P, k) $ "." $ Mid(P, k + 3);
		W = Movie.GetVariableNumber(Clip $ "._width");
		H = Movie.GetVariableNumber(Clip $ "._height");
		MouseX = Movie.GetVariableNumber(Clip $ "._xmouse");
		MouseY = Movie.GetVariableNumber(Clip $ "._ymouse");
		if (W > 0 && MouseX >= 0 && MouseY >= 0 && MouseX <= W && MouseY <= H)
		{
			Bar = Left(P, InStr(P, InStr(P, ".rightBtnHelpContainer") != INDEX_NONE ? ".rightBtnHelpContainer" : ".leftBtnHelpContainer"));
			return Mid(Bar, InStr(Bar, ".", true) + 1) $ "." $ Mid(P, k + 3);
		}
	}
	return "";
}

/** What EW's movie reports when it is clicked (EW's movies call back as XCOM 2's do: FlashRaiseMouseEvent). */
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Joined;
	local int i;

	for (i = 0; i < args.Length; i++)
		Joined @= args[i];
	`log("LongWarX2: EW screen mouse" @ cmd $ ":" $ Joined, , 'LongWarX2');
	super.OnMouseEvent(cmd, args);
}

/**
 * A diagnostic line for a left press or release (aek 2026-11-28: the first click on a button sometimes does nothing, on a
 * 2560x1440 window, not seen on the test machine): where XCOM 2's cursor is (its presentation layer's mouse) and where
 * Flash has the mouse on the stage (_level0._xmouse), which the screens' own hit tests read. One log line per click.
 */
static function LogClick(UIScreen S, int cmd, int arg)
{
	local Vector2D Cursor;
	local bool bCursor;

	if (cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN && cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_UP
		&& cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED && cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP)
		return;
	bCursor = S.Movie.Pres.GetMouseCoords(Cursor);
	`log("LongWarX2: click" @ cmd @ "arg" @ arg @ "on" @ S.Class.Name @ "cursor" @ (bCursor ? (int(Cursor.X) $ "," $ int(Cursor.Y)) : "default")
		@ "flash" @ int(S.Movie.GetVariableNumber("_level0._xmouse")) $ "," $ int(S.Movie.GetVariableNumber("_level0._ymouse")), , 'LongWarX2');
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local UILWEWHub Hub;

	LogClick(self, cmd, arg);

	// (Out by Esc, a pad's B or a right click, as EW's screens all take them; the right click only on some screens had made
	// leaving a screen feel random, aek 2026-11-22, features/e2e-tests.md.)
	if ((cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE || cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B) && (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		CloseScreen();
		return true;
	}
	if (cmd == class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN)
	{
		// (On the press only: its release comes to the screen below, which had closed on it too, two levels for one click.)
		if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) == 0)
			return true;
		// (The hub below told, so it does not take the same click as its own: one click had left two levels.)
		foreach AllActors(class'UILWEWHub', Hub)
			Hub.LastRightClose = WorldInfo.TimeSeconds;
		CloseScreen();
		return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	UIPackage = "EWStrategyUI"
	bScaleToStage = true
	InputState = eInputState_Consume
}
