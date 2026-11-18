// Enemy Within's Second Wave screen (features/strategy-flow.md: game creation as in EW): its GameplayToggles movie (the
// converted EW common UI package, EWCommonUI.upk), driven as EW's UIGameplayToggles drives it: the title, a checkbox per
// option (widgetHelper: label, value, active), the description of the one under the mouse, the back arrow (helpBarMC).
// Long War's options and words, from the player's install (makeShellWords: EW's [UIGameplayToggles] under this class);
// each option's number is the one in its title ("Damage Roulette (#0)"), as LWX2SecondWave counts them. What is ticked
// is kept by EW's new-game screen under this one (UILWEWDifficulty.SecondWave), which hands it to XCOM 2's.
class UILWEWSecondWave extends UILWEWScreen;

var localized string m_strTitle;
var localized string m_arrGameplayToggleTitle[36], m_arrGameplayToggleDesc[36];

var UILWEWDifficulty NewGame;
/** Each checkbox's index into EW's lists, and Long War's option number. */
var array<int> Shown, Numbers;

static function Open(XComPresentationLayerBase Pres, UILWEWDifficulty From)
{
	local UILWEWSecondWave S;

	DynamicLoadObject("EWCommonUI.ewxGameplayToggles", class'Object', true);
	S = Pres.Spawn(class'UILWEWSecondWave', Pres);
	S.Package = name("/ package/ewxGameplayToggles/GameplayToggles");
	S.MCName = 'theGameplayToggles';
	S.NewGame = From;
	Pres.ScreenStack.Push(S);
}

simulated function OnInit()
{
	local int i, k, n;
	local string T;

	super.OnInit();
	MC.FunctionString("SetTitle", m_strTitle);
	for (i = 0; i < 36; i++)
	{
		T = m_arrGameplayToggleTitle[i];
		if (T == "" || T ~= "unused")
			continue;
		k = InStr(T, "(#");
		n = k != INDEX_NONE ? int(Mid(T, k + 2)) : -1;
		Shown.AddItem(i);
		Numbers.AddItem(n);
		Checkbox(Shown.Length - 1, T, n >= 0 && n < NewGame.SecondWave.Length && NewGame.SecondWave[n]);
	}
	MC.ChildFunctionNum("widgetHelper", "SetSelected", 0);
	Describe(0);
	// EW's back arrow (UINavigationHelp.AddBackButton with the mouse: EW's icon button, glyph 4).
	HelpButton("helpBarMC", false, 0, "4", "", "QComButtonIconPC");
}

function Checkbox(int i, string Label, bool bChecked)
{
	MC.BeginChildFunctionOp("widgetHelper", "SetCheckboxLabel");
	MC.QueueNumber(i);
	MC.QueueString(Label);
	MC.EndOp();
	MC.BeginChildFunctionOp("widgetHelper", "SetCheckboxValue");
	MC.QueueNumber(i);
	MC.QueueBoolean(bChecked);
	MC.EndOp();
	MC.BeginChildFunctionOp("widgetHelper", "SetCheckboxStyle");
	MC.QueueNumber(i);
	MC.QueueNumber(0);
	MC.EndOp();
	MC.BeginChildFunctionOp("widgetHelper", "SetReadOnly");
	MC.QueueNumber(i);
	MC.QueueBoolean(false);
	MC.EndOp();
	MC.BeginChildFunctionOp("widgetHelper", "SetActive");
	MC.QueueNumber(i);
	MC.QueueBoolean(true);
	MC.EndOp();
}

function Describe(int i)
{
	if (i >= 0 && i < Shown.Length)
		MC.FunctionString("SetDesc", m_arrGameplayToggleDesc[Shown[i]]);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string All;
	local int i, n;

	super.OnMouseEvent(cmd, args);
	for (i = 0; i < args.Length; i++)
		All $= "." $ args[i];
	if (cmd == 391 && InStr(All, "buttonHelp") != INDEX_NONE)
	{
		CloseScreen();
		return;
	}
	// (EW's list reports the checkbox as the path's part before last: …optionsList.<i>.<clip>, or as option<i>.)
	i = class'UILWEWDifficulty'.static.OptionIn(args.Length > 0 ? args[args.Length - 1] : "");
	if (i < 0 && args.Length > 1 && string(int(args[args.Length - 2])) == args[args.Length - 2])
		i = int(args[args.Length - 2]);
	if (i < 0 || i >= Shown.Length)
		return;
	if (cmd == 392)
	{
		MC.ChildFunctionNum("widgetHelper", "SetSelected", i);
		Describe(i);
	}
	else if (cmd == 391)
	{
		n = Numbers[i];
		if (n < 0 || n >= NewGame.SecondWave.Length)
			return;
		NewGame.SecondWave[n] = !NewGame.SecondWave[n];
		MC.BeginChildFunctionOp("widgetHelper", "SetCheckboxValue");
		MC.QueueNumber(i);
		MC.QueueBoolean(NewGame.SecondWave[n]);
		MC.EndOp();
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0
		&& (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED)
		&& HelpButtonUnderMouse() != "")
	{
		CloseScreen();
		return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	UIPackage = "EWCommonUI"
}
