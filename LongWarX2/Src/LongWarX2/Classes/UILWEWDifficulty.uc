// Enemy Within's new-game screen (features/strategy-flow.md: game creation as in EW): its DifficultyMenu movie (the
// converted EW shell package, EWShellUI.upk), driven as EW's UIShellDifficulty drives it: the title, four difficulty
// checkboxes (difficultyWidgetHelper), the advanced options (advancedWidgetHelper: tutorial, meld tutorial, Operation
// Progeny, Operation Slingshot, Ironman, beginner VO), the description of the one under the mouse, the ADVANCED OPTIONS
// button, and its button bars (helpBarTop: SECOND WAVE, START GAME; helpBarBot: BACK). Long War's words for it, from the
// player's install (scripts/lw-words.mjs, makeShellWords: EW's [UIShellDifficulty] section under this class).
//
// XCOM 2's own new-campaign screen stays under it, hidden (UIScreenListener_LWEWShell), and starts the campaign: START
// GAME sets its difficulty, Ironman and second-wave checkboxes to what was chosen here and calls its confirm, so that
// XCOM 2's campaign start (its Ironman save, its DLC, its intro) is untouched. Long War's tutorials stay off, as Long War
// has them ("Disabled"). Progeny and Slingshot are kept in the campaign's options (LWX2_EWNoProgeny, LWX2_EWNoSlingshot:
// set when unticked; LWCouncil reads the first; Slingshot is not in the port yet).
class UILWEWDifficulty extends UILWEWScreen;

var localized string m_strSelectDifficulty;
var localized string m_arrDifficultyTypeStrings[4], m_arrDifficultyDescStrings[4];
var localized string m_strDifficultyEnableTutorial, m_strDifficultyEnableMeldTutorial, m_strDifficultyEnableProgeny;
var localized string m_strDifficultyEnableSlingshot, m_strDifficultyEnableIronman, m_strDifficultySuppressFirstTimeNarrativeVO;
var localized string m_strDifficultyTutorialDesc, m_strDifficultyMeldTutorialDesc, m_strDifficultyProgenyDesc;
var localized string m_strDifficultySlingshotDesc, m_strDifficultyIronmanDesc, m_strDifficultySuppressFirstTimeNarrativeVODesc;
var localized string m_strDifficulty_Back, m_strDifficulty_ToggleAdvanced, m_strDifficulty_Accept, m_strDifficulty_SecondWaveButtonLabel;
var localized string m_strIronmanTitle, m_strIronmanBody, m_strIronmanOK, m_strIronmanCancel, m_strTutorialOnImpossible;

const OPT_TUTORIAL = 0;
const OPT_MELD = 1;
const OPT_PROGENY = 2;
const OPT_SLINGSHOT = 3;
const OPT_IRONMAN = 4;
const OPT_VO = 5;

/** XCOM 2's new-campaign screen under this one, which starts the campaign. */
var UIShellDifficulty Under;
var int Difficulty;
var array<bool> Advanced;
var bool bViewingAdvanced;
/** Long War's second-wave options chosen (by Long War's number, #0 …), from EW's Second Wave screen (UILWEWSecondWave). */
var array<bool> SecondWave;

static function UILWEWDifficulty Open(XComPresentationLayerBase Pres, UIShellDifficulty Beneath)
{
	local UILWEWDifficulty S;

	DynamicLoadObject("EWShellUI.ewxDifficultyMenu", class'Object', true);
	S = Pres.Spawn(class'UILWEWDifficulty', Pres);
	S.Package = name("/ package/ewxDifficultyMenu/DifficultyMenu");
	S.MCName = 'theDifficultyMenu';
	S.Under = Beneath;
	Pres.ScreenStack.Push(S);
	return S;
}

/** Whether EW's shell screens are converted on this machine. */
static function bool Available()
{
	return DynamicLoadObject("EWShellUI.ewxDifficultyMenu", class'Object', true) != none;
}

simulated function OnInit()
{
	super.OnInit();
	Difficulty = 1;
	Advanced.Length = 6;
	Advanced[OPT_PROGENY] = true;
	Advanced[OPT_SLINGSHOT] = true;
	SecondWave.Length = 31;
	MC.FunctionBool("InitBG", true);
	MC.BeginFunctionOp("SetAdvancedOptionsButton");
	MC.QueueString(Word(m_strDifficulty_ToggleAdvanced, "ADVANCED OPTIONS"));
	MC.QueueString("Icon_X_SQUARE");
	MC.EndOp();
	MC.FunctionString("SetTitle", Word(m_strSelectDifficulty, "SELECT DIFFICULTY"));
	Build();
	Buttons();
	Describe(Difficulty);
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

/** The checkboxes, as EW's BuildMenu makes them (each: label, value, style, read-only). */
function Build()
{
	local int i;

	for (i = 0; i < 4; i++)
		Checkbox("difficultyWidgetHelper", i, Word(m_arrDifficultyTypeStrings[i], string(i)), i == Difficulty, false);
	MC.ChildFunctionNum("difficultyWidgetHelper", "SetSelected", Difficulty);
	Checkbox("advancedWidgetHelper", OPT_TUTORIAL, m_strDifficultyEnableTutorial, false, true);
	Checkbox("advancedWidgetHelper", OPT_MELD, m_strDifficultyEnableMeldTutorial, false, true);
	Checkbox("advancedWidgetHelper", OPT_PROGENY, m_strDifficultyEnableProgeny, Advanced[OPT_PROGENY], false);
	Checkbox("advancedWidgetHelper", OPT_SLINGSHOT, m_strDifficultyEnableSlingshot, Advanced[OPT_SLINGSHOT], false);
	Checkbox("advancedWidgetHelper", OPT_IRONMAN, m_strDifficultyEnableIronman, Advanced[OPT_IRONMAN], false);
	Checkbox("advancedWidgetHelper", OPT_VO, m_strDifficultySuppressFirstTimeNarrativeVO, Advanced[OPT_VO], false);
	MC.ChildFunctionNum("advancedWidgetHelper", "SetSelected", 0);
}

/** One of EW's checkboxes (UIWidgetHelper.RefreshCheckbox: SetCheckboxLabel, SetCheckboxValue, SetCheckboxStyle,
 *  SetReadOnly). */
function Checkbox(string Helper, int i, string Label, bool bChecked, bool bReadOnly)
{
	MC.BeginChildFunctionOp(Helper, "SetCheckboxLabel");
	MC.QueueNumber(i);
	MC.QueueString(Label);
	MC.EndOp();
	MC.BeginChildFunctionOp(Helper, "SetCheckboxValue");
	MC.QueueNumber(i);
	MC.QueueBoolean(bChecked);
	MC.EndOp();
	MC.BeginChildFunctionOp(Helper, "SetCheckboxStyle");
	MC.QueueNumber(i);
	MC.QueueNumber(1);
	MC.EndOp();
	MC.BeginChildFunctionOp(Helper, "SetReadOnly");
	MC.QueueNumber(i);
	MC.QueueBoolean(bReadOnly);
	MC.EndOp();
}

/** EW's button bars (UpdateButtonHelp, UpdateButtonHelp2): SECOND WAVE and START GAME above, BACK below. */
function Buttons()
{
	HelpButton("helpBarTop", false, 0, Word(m_strDifficulty_SecondWaveButtonLabel, "SECOND WAVE"), "Icon_Y_TRIANGLE");
	HelpButton("helpBarTop", true, 1, Word(m_strDifficulty_Accept, "START GAME"), "Icon_START");
	HelpButton("helpBarBot", false, 0, Word(m_strDifficulty_Back, "BACK"), "Icon_B_CIRCLE");
}

/** The description of option i of the list in view (EW's RefreshDescInfo). */
function Describe(int i)
{
	local string D;

	if (!bViewingAdvanced)
	{
		MC.FunctionString("SetDifficultyDesc", m_arrDifficultyDescStrings[Clamp(i, 0, 3)]);
		return;
	}
	switch (i)
	{
	// (EW adds its note on the tutorial in its warning colour: RefreshDescInfo, GetHTMLColoredText(…, 4).)
	case OPT_TUTORIAL: D = m_strDifficultyTutorialDesc @ class'UIUtilities_Text'.static.GetColoredText(m_strTutorialOnImpossible, eUIState_Warning); break;
	case OPT_MELD: D = m_strDifficultyMeldTutorialDesc @ class'UIUtilities_Text'.static.GetColoredText(m_strTutorialOnImpossible, eUIState_Warning); break;
	case OPT_PROGENY: D = m_strDifficultyProgenyDesc; break;
	case OPT_SLINGSHOT: D = m_strDifficultySlingshotDesc; break;
	case OPT_IRONMAN: D = m_strDifficultyIronmanDesc; break;
	case OPT_VO: D = m_strDifficultySuppressFirstTimeNarrativeVODesc; break;
	}
	MC.FunctionString("SetAdvancedDesc", D);
}

/** The option's number in an EW path's last part ("option3" → 3), or -1. */
static function int OptionIn(string Target)
{
	local int k;

	k = InStr(Target, "option");
	if (k == INDEX_NONE)
		return -1;
	return int(Mid(Target, k + 6));
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target, All;
	local int i;

	super.OnMouseEvent(cmd, args);
	Target = args.Length > 0 ? args[args.Length - 1] : "";
	for (i = 0; i < args.Length; i++)
		All $= "." $ args[i];
	if (cmd != 391 && cmd != 392)
		return;
	if (InStr(All, "advancedOptionsButton") != INDEX_NONE)
	{
		if (cmd == 391)
			ToggleAdvanced();
		return;
	}
	if (InStr(All, "buttonHelp") != INDEX_NONE)
	{
		if (cmd == 391)
			Pressed(InStr(All, "helpBarBot") != INDEX_NONE ? "BACK" : (InStr(Target, "1") != INDEX_NONE ? "START" : "SECOND"));
		return;
	}
	i = OptionIn(Target);
	if (i < 0)
		return;
	if (cmd == 392)
	{
		MC.ChildFunctionNum(bViewingAdvanced ? "advancedWidgetHelper" : "difficultyWidgetHelper", "SetSelected", i);
		Describe(i);
		return;
	}
	if (bViewingAdvanced)
		ToggleOption(i);
	else
		SelectDifficulty(i);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local string B;

	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
			B = HelpButtonUnderMouse();
			if (B == "")
				break;
			Pressed(InStr(B, "helpBarBot") != INDEX_NONE ? "BACK" : (Right(B, 1) == "1" ? "START" : "SECOND"));
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			if (bViewingAdvanced)
				ToggleAdvanced();
			else
				Pressed("BACK");
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			Pressed("START");
			return true;
		}
	}
	return super(UIScreen).OnUnrealCommand(cmd, arg);
}

function SelectDifficulty(int i)
{
	local int k;

	if (i < 0 || i > 3)
		return;
	Difficulty = i;
	for (k = 0; k < 4; k++)
	{
		MC.BeginChildFunctionOp("difficultyWidgetHelper", "SetCheckboxValue");
		MC.QueueNumber(k);
		MC.QueueBoolean(k == i);
		MC.EndOp();
	}
	Describe(i);
}

function ToggleOption(int i)
{
	local TDialogueBoxData D;

	if (i == OPT_TUTORIAL || i == OPT_MELD || i < 0 || i >= Advanced.Length)
		return;
	// (Ironman asked first, as EW asks it: ConfirmIronmanDialogue.)
	if (i == OPT_IRONMAN && !Advanced[i] && m_strIronmanTitle != "")
	{
		D.eType = eDialog_Warning;
		D.strTitle = m_strIronmanTitle;
		D.strText = m_strIronmanBody;
		D.strAccept = m_strIronmanOK;
		D.strCancel = m_strIronmanCancel;
		D.fnCallback = IronmanAnswered;
		Movie.Pres.UIRaiseDialog(D);
		return;
	}
	SetOption(i, !Advanced[i]);
}

simulated function IronmanAnswered(Name Action)
{
	if (Action == 'eUIAction_Accept')
		SetOption(OPT_IRONMAN, true);
}

function SetOption(int i, bool bOn)
{
	Advanced[i] = bOn;
	MC.BeginChildFunctionOp("advancedWidgetHelper", "SetCheckboxValue");
	MC.QueueNumber(i);
	MC.QueueBoolean(bOn);
	MC.EndOp();
}

function ToggleAdvanced()
{
	bViewingAdvanced = !bViewingAdvanced;
	MC.FunctionVoid("ToggleAdvancedOptions");
	Describe(bViewingAdvanced ? 0 : Difficulty);
}

function Pressed(string Which)
{
	`log("LongWarX2: EW new-game screen:" @ Which, , 'LongWarX2');
	switch (Which)
	{
	case "SECOND":
		class'UILWEWSecondWave'.static.Open(Movie.Pres, self);
		break;
	case "START":
		Start();
		break;
	case "BACK":
		CloseScreen();
		if (Under != none)
			Under.OnButtonCancel(none);
		break;
	}
}

/** XCOM 2's screen under this told what was chosen here, then its confirm: the campaign starts as XCOM 2 starts one. */
function Start()
{
	local UIMechaListItem Item;
	local string ID;
	local int i, n;

	if (Under == none)
		return;
	Under.m_iSelectedDifficulty = Difficulty;
	Under.m_bIronmanFromShell = Advanced[OPT_IRONMAN];
	Under.m_bControlledStart = false;
	Under.m_bShowedFirstTimeTutorialNotice = true;
	if (Under.m_TutorialMechaItem != none)
		Under.m_TutorialMechaItem.Checkbox.SetChecked(false, false);
	for (i = 0; i < Under.SecondWaveOptions.Length; i++)
	{
		Item = Under.m_SecondWaveList != none ? UIMechaListItem(Under.m_SecondWaveList.GetItem(i)) : none;
		if (Item == none)
			continue;
		ID = string(Under.SecondWaveOptions[i].ID);
		if (Left(ID, 5) == "LWSW_")
		{
			n = int(Mid(ID, 5, 2));
			Item.Checkbox.SetChecked(n >= 0 && n < SecondWave.Length && SecondWave[n], false);
		}
		else if (ID == "LWX2_EWNoProgeny")
			Item.Checkbox.SetChecked(!Advanced[OPT_PROGENY], false);
		else if (ID == "LWX2_EWNoSlingshot")
			Item.Checkbox.SetChecked(!Advanced[OPT_SLINGSHOT], false);
		else
			Item.Checkbox.SetChecked(false, false);
	}
	`log("LongWarX2: EW new-game screen: campaign started through XCOM 2's (difficulty" @ Difficulty $ ", Ironman" @ Advanced[OPT_IRONMAN] $ ")", , 'LongWarX2');
	Under.OnDifficultyConfirm(none);
}

defaultproperties
{
	UIPackage = "EWShellUI"
}
