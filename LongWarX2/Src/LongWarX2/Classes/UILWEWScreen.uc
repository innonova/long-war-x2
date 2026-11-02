// An Enemy Within screen's own Flash movie shown in XCOM 2 (the experiment of features/lw-ew-screens.md): the movie of
// the converted EW UI package (tools/convert/ew-ui.ts: EWStrategyUI.upk in the mod's Content), at
// "/ package/ewx<Screen>/<Screen>". Nothing drives it yet: it shows what EW's movie draws by itself. Escape closes it.
class UILWEWScreen extends UIScreen;

var string UIPackage;

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
		if (string(int(Args[i])) == Args[i])
			EWScreen.MC.QueueNumber(int(Args[i]));
		else
			EWScreen.MC.QueueString(Repl(Args[i], "_", " "));
	}
	EWScreen.MC.EndOp();
	return "ok" @ EWScreen.MCPath $ "." $ Args[1] @ "with" @ (Args.Length - 2) @ "arguments";
}

simulated function OnInit()
{
	super.OnInit();
	`log("LongWarX2: EW screen" @ Package @ "inited", , 'LongWarX2');
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
	InputState = eInputState_Consume
}
