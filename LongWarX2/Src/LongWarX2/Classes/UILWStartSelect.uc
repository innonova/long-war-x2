// Long War's start screen (features/lw-startbonus.md): the home country and its starting bonus chosen together, on Enemy
// Within's own ContinentSelect movie, driven as Long War's XGContinentUI and UIContinentSelect drive it. One option per
// starting bonus (a country can be offered more than once, with another bonus); the info panel shows the country, its
// starting money, its bonus and its continent's. Chosen, the Long War campaign begins (XComGameState_LWStrategy.
// GetOrCreate) and the Geoscape opens.
class UILWStartSelect extends UILWEWScreen;

var array<int> Choices;
var array<int> Countries;
var int Selected;

/** The start screen if the campaign has not begun and EW's screens are there; else the Geoscape (the campaign begun with
 * the United States and no starting bonus, as before the start screen). */
static function OpenGeoscape(XComHQPresentationLayer HQPres)
{
	local UILWStartSelect Start;

	if (class'XComGameState_LWStrategy'.static.Get() == none && class'UILWEWScreen'.static.HasEWScreens())
	{
		if (HQPres.ScreenStack.IsInStack(class'UILWStartSelect'))
			return;
		DynamicLoadObject(default.UIPackage $ ".ewxContinentSelect", class'Object', true);
		// The black background the Situation Room uses: the Avenger does not show through.
		class'UILWEWMapBackdrop'.static.ShowIfAvailable();
		Start = HQPres.Spawn(class'UILWStartSelect', HQPres);
		Start.Package = name("/ package/ewxContinentSelect/ContinentSelect");
		Start.MCName = 'theScreen';
		HQPres.ScreenStack.Push(Start);
		`log("LongWarX2: start screen shown", , 'LongWarX2');
		return;
	}
	if (!HQPres.ScreenStack.IsInStack(class'UILWGeoscape'))
		HQPres.ScreenStack.Push(HQPres.Spawn(class'UILWGeoscape', HQPres));
}

simulated function OnInit()
{
	local int i;

	super.OnInit();
	class'LWBonuses'.static.GetChoices(Choices, Countries);
	MC.FunctionString("SetTitle", Caps(Label(class'LWBonuses'.default.LabelBaseLocation, "Select Base Location:")));
	MC.BeginFunctionOp("SetAcceptButton");
	MC.QueueString(Label(class'LWBonuses'.default.LabelBegin, "Begin Game"));
	MC.QueueString("");
	MC.EndOp();
	MC.BeginFunctionOp("SetBackButton");
	MC.QueueString("");
	MC.QueueString("");
	MC.EndOp();
	// No way back (the campaign has to begin somewhere): EW's back button, left empty, is hidden once the movie has made it.
	SetTimer(0.3, false, nameof(HideBackButton));
	MC.FunctionVoid("clear");
	for (i = 0; i < Choices.Length; i++)
	{
		MC.BeginFunctionOp("AddOption");
		MC.QueueNumber(i);
		// Smaller than EW's own (its list was made for a country's name alone): the bonus's name fits beside it.
		MC.QueueString("<font size='15'>" $ Caps(OptionLabel(i)) $ "</font>");
		MC.QueueNumber(0);
		MC.EndOp();
	}
	`log("LongWarX2: start screen:" @ Choices.Length @ "options", , 'LongWarX2');
	Select(0);
}

function HideBackButton()
{
	MC.ChildSetBool("theBackButton", "_visible", false);
}

simulated function OnRemoved()
{
	class'UILWEWMapBackdrop'.static.HideAll();
	super.OnRemoved();
}

static function string Label(string Words, string Otherwise)
{
	return Words != "" ? Words : Otherwise;
}

/** An option's line: the country and its starting bonus's name ("Mexico: Wealthy Benefactor"). EW lists the country only;
 * with the bonus beside it the list reads without the info panel. */
function string OptionLabel(int i)
{
	local int b;
	local string BonusName;

	for (b = 0; b < class'LWBonuses'.default.Bonuses.Length; b++)
		if (class'LWBonuses'.default.Bonuses[b].Kind == 0 && class'LWBonuses'.default.Bonuses[b].Choice == Choices[i]
			&& class'LWBonuses'.default.Bonuses[b].Country == class'LWStrategyRules'.default.Countries[Countries[i]].Id)
		{
			BonusName = class'LWBonuses'.static.Text(b, true);
			break;
		}
	BonusName = Repl(BonusName, ":", "");
	BonusName = Repl(BonusName, "  ", " ");
	while (Right(BonusName, 1) == " ")
		BonusName = Left(BonusName, Len(BonusName) - 1);
	return class'LWStrategyRules'.default.Countries[Countries[i]].Name $ (BonusName != "" ? ":" @ BonusName : "");
}

/** An option selected: the list's selection and the info panel (Long War's BuildContinentOption). */
function Select(int Index)
{
	local int k;

	if (Choices.Length == 0)
		return;
	Selected = (Index + Choices.Length) % Choices.Length;
	k = Countries[Selected];
	MC.FunctionNum("SetListSelection", Selected);
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(Caps(class'LWStrategyRules'.default.Countries[k].Name));
	MC.QueueString(Label(class'LWBonuses'.default.LabelStarting, "Starting: ") $ class'LWStrategyRules'.static.Money(Round(class'LWStrategyRules'.default.Countries[k].StartingCash * class'LWStrategyRules'.default.StartingCashBalance[class'LWStrategyRules'.static.Difficulty()])));
	MC.QueueString(class'LWBonuses'.static.ChoiceText(Choices[Selected], k, Label(class'LWBonuses'.default.LabelContinentBonus, "CONTINENT BONUS:")));
	MC.EndOp();
}

/** The option chosen: the campaign begins there, and the Geoscape opens in place of this screen. */
function Accept()
{
	local XComHQPresentationLayer HQPres;

	if (Choices.Length == 0 || class'XComGameState_LWStrategy'.static.Get() != none)
		return;
	`log("LongWarX2: start screen: home" @ class'LWStrategyRules'.default.Countries[Countries[Selected]].Name $ ", option" @ Choices[Selected], , 'LongWarX2');
	class'XComGameState_LWStrategy'.static.GetOrCreate(Countries[Selected], Choices[Selected]);
	HQPres = XComHQPresentationLayer(Movie.Pres);
	CloseScreen();
	if (HQPres != none)
		OpenGeoscape(HQPres);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (cmd == 391 && Target == "theStartButton")
		Accept();
	else if (cmd == 391 && InStr(Target, "option") == 0)
		Select(int(Mid(Target, 6)));
	super(UIScreen).OnMouseEvent(cmd, args);
}

/** The option under the mouse, or -1 (as UILWEWResearch: EW's list items do not report their clicks to XCOM 2). */
function int OptionUnderMouse()
{
	local string Path;
	local float MouseX, MouseY, W, H;
	local int i;

	for (i = 0; i < Choices.Length; i++)
	{
		Path = MCPath $ ".itemList.theItems." $ i;
		W = Movie.GetVariableNumber(Path $ "._width");
		H = Movie.GetVariableNumber(Path $ "._height");
		MouseX = Movie.GetVariableNumber(Path $ "._xmouse");
		MouseY = Movie.GetVariableNumber(Path $ "._ymouse");
		if (W > 0 && MouseX >= 0 && MouseY >= 0 && MouseX <= W && MouseY <= H)
			return i;
	}
	return -1;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int i;

	if ((cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP)
		&& (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		i = OptionUnderMouse();
		if (i >= 0)
		{
			Select(i);
			if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP)
				Accept();
			return true;
		}
	}
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super(UIScreen).OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
			Select(Selected - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
			Select(Selected + 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Accept();
			return true;
		// No way back: the campaign has to begin somewhere (Long War's offers only Exit, to the main menu).
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			return true;
	}
	return super(UIScreen).OnUnrealCommand(cmd, arg);
}
