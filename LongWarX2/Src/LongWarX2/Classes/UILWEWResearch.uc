// Enemy Within's own research screen (its ChooseTech movie, features/lw-ew-screens.md) choosing what XCOM researches:
// Long War's techs as XCOM 2 runs them (lw-research.md), driven as EW's UIChooseTech drives the movie
// (SetTitle, AddOption, setFocus, UpdateInfo, SetConfirmButtonHelp; clicks 400 select, 398 select and accept, 391 on
// the confirm button accept), the project started as XCOM 2's research screen starts one.
class UILWEWResearch extends UILWEWScreen;

var array<StateObjectReference> Techs;
var int Selected;

/** The screen pushed over the Avenger. */
static function string Open()
{
	local XComHQPresentationLayer HQPres;
	local UILWEWResearch EWScreen;

	HQPres = `HQPRES;
	if (HQPres == none)
		return "ERR not on the Avenger";
	DynamicLoadObject(default.UIPackage $ ".ewxChooseTech", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWResearch', HQPres);
	EWScreen.Package = name("/ package/ewxChooseTech/ChooseTech");
	EWScreen.MCName = 'theChooseResearch';
	HQPres.ScreenStack.Push(EWScreen);
	return "ok EW research screen";
}

simulated function OnInit()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech Tech;
	local int i;

	super.OnInit();
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	Techs = XComHQ.GetAvailableTechsForResearch();
	MC.FunctionString("SetTitle", "RESEARCH");
	MC.FunctionString("SetConfirmButtonHelp", "START RESEARCH");
	MC.FunctionVoid("clear");
	for (i = 0; i < Techs.Length; i++)
	{
		Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Techs[i].ObjectID));
		MC.BeginFunctionOp("AddOption");
		MC.QueueNumber(i);
		MC.QueueString(Caps(Tech.GetDisplayName()));
		MC.QueueNumber(0);
		MC.EndOp();
	}
	`log("LongWarX2: EW research screen:" @ Techs.Length @ "techs listed", , 'LongWarX2');
	Select(0);
}

/** A tech selected: the movie's focus and its info panel (name, days, summary, picture). */
function Select(int Index)
{
	local XComGameState_Tech Tech;
	local int Hours;

	if (Techs.Length == 0)
		return;
	Selected = (Index + Techs.Length) % Techs.Length;
	Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Techs[Selected].ObjectID));
	MC.FunctionString("setFocus", string(Selected));
	Hours = class'UIUtilities_Strategy'.static.GetXComHQ().GetResearchHours(Techs[Selected]);
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(Caps(Tech.GetDisplayName()));
	MC.QueueString(class'UIUtilities_Text'.static.GetTimeRemainingString(Hours));
	MC.QueueString(Tech.GetSummary());
	MC.QueueString(Tech.GetImage());
	MC.EndOp();
}

/** The selected tech researched (XCOM 2's UIChooseResearch.OnTechTableOption, without its confirmation popups). */
function Accept()
{
	local XComGameState_HeadquartersXCom XComHQ;

	if (Techs.Length == 0)
		return;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ.SetNewResearchProject(Techs[Selected]);
	`log("LongWarX2: EW research screen: research begun:" @ XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Techs[Selected].ObjectID)).GetMyTemplateName(), , 'LongWarX2');
	CloseScreen();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (cmd == 391 && Target == "theConfirmButton")
		Accept();
	else if ((cmd == 400 || cmd == 398) && InStr(Target, "option") == 0)
	{
		Select(int(Mid(Target, 6)));
		if (cmd == 398)
			Accept();
	}
	super(UIScreen).OnMouseEvent(cmd, args);
}

/**
 * The option under the mouse, or -1. EW's list items do not report clicks to XCOM 2 (their own input code is EW's), so
 * each option's clip (itemList.theItems.<i>, as EW's list names them) is asked where the mouse is, in its own coordinates.
 */
function int OptionUnderMouse()
{
	local string Path;
	local float MouseX, MouseY, W, H;
	local int i;

	for (i = 0; i < Techs.Length; i++)
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

	// A click on the list: the option under the mouse selected (a double click starts it).
	if ((cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP)
		&& (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		i = OptionUnderMouse();
		`log("LongWarX2: EW research screen: click on option" @ i, , 'LongWarX2');
		if (i >= 0)
		{
			Select(i);
			if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP)
				Accept();
			return true;
		}
	}
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_8:
		case class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_2:
			Select(Selected + (cmd == class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_2 ? 1 : -1));
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			Select(Selected - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			Select(Selected + 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Accept();
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}
