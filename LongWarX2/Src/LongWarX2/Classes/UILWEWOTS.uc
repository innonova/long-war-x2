// Enemy Within's own Officer Training School screen (features/lw-officers.md): its OfficerTrainingSchool movie, driven as
// EW's UIOTS drives it (SetTitles: title, ranks, cost; Clear; AddOption per project: index, name, cost, disabled;
// SetListSelection; SetHelp; UpdateInfo: image, description; SetPurchaseButtonText: text, disabled). Long War's seven
// projects in its order: Squad Size I and II, bought as before (XComGameState_LWStrategy.BuySquadSize, after a
// confirmation as EW asks it), then the five officer projects, greyed until the officers are in (features/lw-officers.md).
// Over the hub's Barracks, EW's base staying in view behind it.
class UILWEWOTS extends UILWEWScreen;

/** EW's and Long War's words, written from the player's install (scripts/lw-words.mjs, makeOTSWords). */
var localized string Title, TotalRanks, Cost, Purchase, ConfirmTitle, ConfirmBody;
var localized string Names[7], Summaries[7];

var int Selected;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWOTS EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxOfficerTrainingSchool", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWOTS', HQPres);
	EWScreen.Package = name("/ package/ewxOfficerTrainingSchool/OfficerTrainingSchool");
	EWScreen.MCName = 'theOTS';
	HQPres.ScreenStack.Push(EWScreen);
}

simulated function OnInit()
{
	super.OnInit();
	ShowBase();
	Fill();
}

/** EW's base behind it, through the barracks' camera (the screen under it may have handed the view back). */
function ShowBase()
{
	local LWX2EWBase B;

	B = class'LWX2EWBase'.static.Get(self);
	B.Show();
	B.LookAt('BARRACKS', 0);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (bIsInited)
		ShowBase();
}

static function string ProjectName(int i)
{
	return class'UILWEWHub'.static.Word(default.Names[i], i < 2 ? "Squad Size" @ (i == 0 ? "I" : "II") : "Officers");
}

/** Whether project i can be bought now, and if not, why (Why). */
function bool Able(XComGameState_LWStrategy S, int i, out string Why)
{
	Why = "";
	if (i >= 2)
	{
		Why = "Officers are not in the port yet.";
		return false;
	}
	if (i < S.SquadSizesBought)
	{
		Why = "Bought.";
		return false;
	}
	if (i > S.SquadSizesBought)
	{
		Why = "Needs" @ ProjectName(i - 1) $ ".";
		return false;
	}
	if (!class'XComGameState_LWStrategy'.static.CanBuySquadSize(S, Why))
	{
		Why = "Needs" @ Why $ ".";
		return false;
	}
	return true;
}

function int ProjectCash(XComGameState_LWStrategy S, int i)
{
	if (i < 2)
		return i == S.SquadSizesBought ? class'XComGameState_LWStrategy'.static.SquadSizeNext(S).Cash : class'LWStrategyRules'.default.SquadSizes[i].Cash;
	return class'LWStrategyRules'.default.OfficerProjects[i - 2].Cash;
}

function int ProjectRanks(XComGameState_LWStrategy S, int i)
{
	if (i < 2)
		return i == S.SquadSizesBought ? class'XComGameState_LWStrategy'.static.SquadSizeNext(S).Ranks : class'LWStrategyRules'.default.SquadSizes[i].Ranks;
	return class'LWStrategyRules'.default.OfficerProjects[i - 2].Ranks;
}

function int Count()
{
	return 2 + class'LWStrategyRules'.default.OfficerProjects.Length;
}

function Fill()
{
	local XComGameState_LWStrategy S;
	local string Why;
	local int i;
	local bool bAble;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return;
	MC.BeginFunctionOp("SetTitles");
	MC.QueueString(class'UILWEWHub'.static.Word(Title, "Officer Training School"));
	MC.QueueString(class'UILWEWHub'.static.Word(TotalRanks, "TOTAL RANKS") $ ":" @ class'XComGameState_LWStrategy'.static.RanksInBarracks());
	MC.QueueString(class'UILWEWHub'.static.Word(Cost, "COST"));
	MC.EndOp();
	MC.FunctionVoid("Clear");
	for (i = 0; i < Count(); i++)
	{
		// (As the movie's own sample shows them: what cannot be bought with its cost in red.)
		bAble = Able(S, i, Why);
		MC.BeginFunctionOp("AddOption");
		MC.QueueNumber(i);
		// (The name field is plain text: the cost column carries the colour.)
		MC.QueueString(ProjectName(i));
		MC.QueueString((i < 2 && i < S.SquadSizesBought) ? "" : class'UIUtilities_Text'.static.GetColoredText(class'LWStrategyRules'.static.Money(ProjectCash(S, i)), bAble ? eUIState_Normal : eUIState_Bad));
		MC.QueueBoolean(!bAble);
		MC.EndOp();
	}
	Select(Selected);
}

function Select(int i)
{
	local XComGameState_LWStrategy S;
	local string Why, Desc;
	local bool bAble;

	S = class'XComGameState_LWStrategy'.static.Get();
	Selected = Clamp(i, 0, Count() - 1);
	bAble = Able(S, Selected, Why);
	// (Why it cannot be bought and the ranks it needs first: the panel cuts off what does not fit below the summary.)
	Desc = "";
	if (!bAble)
		Desc $= class'UIUtilities_Text'.static.GetColoredText(Why, eUIState_Bad) $ "\n";
	if (Selected >= S.SquadSizesBought || Selected >= 2)
		Desc $= class'UILWEWHub'.static.Word(TotalRanks, "TOTAL RANKS") $ ":" @ ProjectRanks(S, Selected) $ "\n";
	Desc $= Summaries[Selected];
	MC.FunctionString("SetListSelection", string(Selected));
	MC.FunctionString("SetHelp", "");
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString("");
	MC.QueueString(Desc);
	MC.EndOp();
	MC.BeginFunctionOp("SetPurchaseButtonText");
	MC.QueueString(class'UILWEWHub'.static.Word(Purchase, "PURCHASE"));
	MC.QueueBoolean(!bAble);
	MC.EndOp();
}

/** The selected project bought, after EW's confirmation. */
function Accept()
{
	local XComGameState_LWStrategy S;
	local TDialogueBoxData Data;
	local XGParamTag Tag;
	local string Why;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (!Able(S, Selected, Why))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.StrValue0 = ProjectName(Selected);
	Tag.StrValue1 = class'LWStrategyRules'.static.Money(ProjectCash(S, Selected));
	Data.eType = eDialog_Normal;
	Data.strTitle = class'UILWEWHub'.static.Word(ConfirmTitle, "CONFIRM UPGRADE");
	Data.strText = ConfirmBody != "" ? `XEXPAND.ExpandString(ConfirmBody) : ProjectName(Selected) @ "for" @ Tag.StrValue1 $ "?";
	Data.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	Data.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	Data.fnCallback = OnConfirm;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnConfirm(Name Action)
{
	local string Why;

	if (Action != 'eUIAction_Accept')
		return;
	if (class'XComGameState_LWStrategy'.static.BuySquadSize(Why))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
			XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
		class'UILWEWStrategyHUD'.static.ShowIfAvailable();
	}
	else
		`log("LongWarX2: EW Officer Training School:" @ Why, , 'LongWarX2');
	Fill();
}

/** The project or the purchase button under the mouse (EW's clips do not report their clicks to XCOM 2): -2 the button. */
function int UnderMouse()
{
	local int i;

	if (MouseOver(MCPath $ ".purchaseButtonMC"))
		return -2;
	for (i = 0; i < Count(); i++)
		if (MouseOver(MCPath $ ".itemList.theItems." $ i) || MouseOver(MCPath $ ".theList.theItems." $ i))
			return i;
	return -1;
}

function bool MouseOver(string Path)
{
	local float MouseX, MouseY, W, H;

	W = Movie.GetVariableNumber(Path $ "._width");
	H = Movie.GetVariableNumber(Path $ "._height");
	MouseX = Movie.GetVariableNumber(Path $ "._xmouse");
	MouseY = Movie.GetVariableNumber(Path $ "._ymouse");
	return W > 0 && MouseX >= 0 && MouseY >= 0 && MouseX <= W && MouseY <= H;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (cmd == 391 && Target == "purchaseButtonMC")
		Accept();
	super(UIScreen).OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int i;

	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
		i = UnderMouse();
		if (i == -2)
		{
			Accept();
			return true;
		}
		if (i >= 0)
		{
			Select(i);
			return true;
		}
		break;
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

defaultproperties
{
	// (Over the hub's Barracks room: the base stays in view behind it.)
	bShowsBase = true
}
