// Enemy Within's own Manufacturing screen (its movie, features/lw-ew-screens.md): how many of an item engineering builds,
// with the cost and time for that many; driven as EW's UIManufacturing drives it (SetTitle, SetEngineerLine,
// SetQuantityLine, UpdateInfo; clicks on theStartButton_PC submit, theBackButton cancel). The quantity moves with the
// arrow keys, the mouse wheel or the spinner's own +/- (its clicks, "-1" and "-2", when the movie makes it). The project
// is begun with LWEngineering.Start.
class UILWEWManufacturing extends UILWEWScreen;

var int Item;
var int Quantity;
var UILWEWEngineering From;

static function Open(XComHQPresentationLayer HQPres, int ItemNumber, UILWEWEngineering Caller)
{
	local UILWEWManufacturing EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxManufacturing", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWManufacturing', HQPres);
	EWScreen.Package = name("/ package/ewxManufacturing/Manufacturing");
	EWScreen.MCName = 'theManufacturingScreen';
	EWScreen.Item = ItemNumber;
	EWScreen.Quantity = 1;
	EWScreen.From = Caller;
	HQPres.ScreenStack.Push(EWScreen);
}

simulated function OnInit()
{
	super.OnInit();
	// EW's buttons by their help (UI_FxsShellScreen.SetHelp): 0 back, 3 start; 1 (cancel an order) and 2 (rush) are not
	// Long War X2's, so hidden.
	Help(0, "BACK");
	Help(3, "START PROJECT");
	Help(1, "");
	Help(2, "");
	// Once the movie has laid them out: the two unused buttons and the second spinner (EW's engineers, not adjustable).
	SetTimer(0.3, false, nameof(HideUnused));
	Refresh();
}

function HideUnused()
{
	MC.ChildSetBool("centerButton1", "_visible", false);
	MC.ChildSetBool("centerButton2", "_visible", false);
	MC.ChildSetBool("option0", "_visible", false);
	// The arrows that stay (the movie's second spinner) moved up into the hidden one's place, beside the quantity.
	MC.ChildSetNum("option1", "_y", Movie.GetVariableNumber(MCPath $ ".option0._y"));
}

function Help(int Index, string Text)
{
	MC.BeginFunctionOp("SetHelp");
	MC.QueueNumber(Index);
	MC.QueueString(Text);
	MC.QueueString("");
	MC.EndOp();
}

function Refresh()
{
	local LWGearRules.LWBuildDef B;
	local X2ItemTemplate Template;
	local XComGameState_LWStrategy S;
	local string Short, Cost;

	if (!class'LWGearRules'.static.BuildFor(Item, B))
		return;
	Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(B.Template);
	S = class'XComGameState_LWStrategy'.static.Get();
	Short = class'LWEngineering'.static.Short(B, Quantity);
	MC.FunctionString("SetTitle", "<font size='26'>" $ Caps(class'LWEngineering'.static.ItemName(B.Template)) $ "</font>");
	MC.BeginFunctionOp("SetEngineerLine");
	MC.QueueString("ENGINEERS");
	MC.QueueString(string(S != none ? S.Engineers : 0));
	MC.EndOp();
	// The quantity on the movie's quantity line (read-only: it shows the number), beside the spinner arrows the movie draws there.
	MC.BeginFunctionOp("SetQuantityLine");
	MC.QueueString("QUANTITY");
	MC.QueueString(string(Quantity));
	MC.QueueBoolean(true);
	MC.EndOp();
	Cost = "COST:" @ Times(class'LWEngineering'.static.CostText(B), Quantity);
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString("TIME:" @ class'LWEngineering'.static.HoursText(class'LWEngineering'.static.HoursFor(class'LWEngineering'.static.UnitWork(B), B.Engineers * Quantity, S != none ? S.Engineers : 0))
		$ "\n" $ Cost $ (Short != "" ? "\n" $ class'UIUtilities_Text'.static.GetColoredText("Short of" @ Short, eUIState_Bad) : ""));
	MC.QueueString(Template != none ? Template.GetItemBriefSummary() : "");
	MC.QueueString(Template != none ? Template.strImage : "");
	MC.EndOp();
}

/** The cost of one, for n: "§30, 4 Alloys" for 2 is "2 x (§30, 4 Alloys)". */
static function string Times(string One, int n)
{
	return n == 1 ? One : n @ "x (" $ One $ ")";
}

function Change(int By)
{
	Quantity = Clamp(Quantity + By, 1, 99);
	Refresh();
}

/** The project begun (LWEngineering.Start pays now); the list shows it, and its count once delivered. */
function Submit()
{
	local string Why;

	if (!class'LWEngineering'.static.Start(Item, Quantity, Why))
	{
		`log("LongWarX2: EW manufacturing:" @ Why, , 'LongWarX2');
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		MC.BeginFunctionOp("UpdateInfo");
		MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(Why, eUIState_Bad));
		MC.QueueString("");
		MC.QueueString("");
		MC.EndOp();
		return;
	}
	`log("LongWarX2: EW manufacturing: begun," @ Quantity @ "of item" @ Item, , 'LongWarX2');
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	CloseScreen();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (cmd == 391 || cmd == 398)
	{
		if (Target == "theStartButton_PC")
			Submit();
		else if (Target == "theBackButton")
			CloseScreen();
		// The spinner's arrows: "-1" more, "-2" fewer.
		else if (Target == "-1")
			Change(1);
		else if (Target == "-2")
			Change(-1);
	}
	super(UIScreen).OnMouseEvent(cmd, args);
}

static function string JoinArgs(array<string> Args)
{
	local string S, A;

	foreach Args(A)
		S $= A $ " ";
	return S;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:
			Change(1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN:
			Change(-1);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Submit();
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}
