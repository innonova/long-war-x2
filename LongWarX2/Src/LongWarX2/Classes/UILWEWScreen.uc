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

	EWScreen = UILWEWScreen(`HQPRES.ScreenStack.GetFirstInstanceOf(class'UILWEWScreen'));
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

	EWScreen = UILWEWScreen(`HQPRES.ScreenStack.GetFirstInstanceOf(class'UILWEWScreen'));
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

	EWScreen = UILWEWScreen(`HQPRES.ScreenStack.GetFirstInstanceOf(class'UILWEWScreen'));
	if (EWScreen == none || SubPath == "")
		return "ERR no EW screen open, or no path";
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
	local UIScreen Top;

	// (hud:<path>: inside EW's strategy HUD, which is not on the screen stack.)
	if (Left(SubPath, 4) == "hud:")
	{
		foreach `HQPRES.AllActors(class'UILWEWStrategyHUD', HUD)
			return HUD.MCPath $ "." $ Mid(SubPath, 4) @ "=" @ HUD.Movie.GetVariableString(HUD.MCPath $ "." $ Mid(SubPath, 4));
		return "ERR no EW strategy HUD up";
	}
	Top = `HQPRES.ScreenStack.GetCurrentScreen();
	EWScreen = UILWEWScreen(Top) != none ? UILWEWScreen(Top) : UILWEWScreen(`HQPRES.ScreenStack.GetFirstInstanceOf(class'UILWEWScreen'));
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
	`log("LongWarX2: EW screen" @ Package @ "inited", , 'LongWarX2');
}

/** The screen pushed: onto its EW panel in 3D where it has one (EWDisplay, LWX2EWBase.ScreensIn3D), else flat. */
static function Push3D(XComHQPresentationLayer HQPres, UILWEWScreen S)
{
	if (S.EWDisplay != '' && class'LWX2EWBase'.default.ScreensIn3D && class'LWX2EWBase'.static.DisplayFor(HQPres, S.EWDisplay) != none)
	{
		S.BaseCamera = S.EWDisplayCamera != '' ? S.EWDisplayCamera : S.BaseCamera;
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
	UIMovie_3D(Movie).ShowDisplay(EWDisplay, ShownOn);
	B = class'LWX2EWBase'.static.Get(self);
	foreach B.Displays(D)
		if (D.Tag == EWDisplay && D != ShownOn)
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
			if (D.Tag == EWDisplay)
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

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE || cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B) && (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
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
