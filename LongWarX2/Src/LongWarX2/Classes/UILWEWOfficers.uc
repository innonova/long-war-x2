// Long War's officer promotions on Enemy Within's own Officer Billets screen (features/lw-officers.md): EW's Medals movie,
// driven as Long War's UIMedals drives it. The five ranks (SetDisplayMode 0; currentMedalsMC.SetInfo: name, open billets or
// locked, its insignia); a rank chosen, XCOM 2's soldier list of those Long War lets be promoted to it
// (UIPersonnel_LWOfficer); a soldier chosen, the rank's two powers (SetDisplayMode 2; assignPowerMC.SetPowerInfo,
// SetButtonHelp), and EW's confirmation; promoted (LWOfficers.Promote). Over the hub's Barracks, the base behind it.
// Where EW's screens are not converted, UILWOfficers (XCOM 2's widgets) stands in.
class UILWEWOfficers extends UILWEWScreen;

/** What the screen shows: 0 the ranks, 2 a rank's powers (EW's display modes). */
var int EWView;
var int Selected, Power, ChosenRank;
var StateObjectReference ChosenUnit;

/** Each officer rank's insignia: the medal frames of EW's icon movie (Long War's UIUtilities.GetMedalLabel). */
var array<string> RankLabels;

/** An officer's insignia as EW lists them (UIUtilities.GetMedalLabels: a medal frame for each rank reached, comma
 *  separated); none for a soldier who is no officer. */
static function string Insignia(XComGameState_Unit Unit)
{
	local string S;
	local int r, n;

	n = Min(class'LWOfficers'.static.Rank(Unit), default.RankLabels.Length);
	for (r = 0; r < n; r++)
		S $= (S != "" ? "," : "") $ default.RankLabels[r];
	return S;
}

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWOfficers EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxMedals", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWOfficers', HQPres);
	EWScreen.Package = name("/ package/ewxMedals/Medals");
	EWScreen.MCName = 'theScreen';
	HQPres.ScreenStack.Push(EWScreen);
}

simulated function OnInit()
{
	super.OnInit();
	ShowBase();
	ShowRanks();
}

/** EW's base behind it, through the barracks' camera. */
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

/** The five ranks: name, open billets or locked, insignia. */
function ShowRanks()
{
	local XComGameState_LWStrategy S;
	local array<ASValue> Params;
	local int r;
	local bool bLocked;

	EWView = 0;
	ChosenRank = 0;
	S = class'XComGameState_LWStrategy'.static.Get();
	Params.AddItem(Num(0));
	CallNow("SetDisplayMode", Params);
	Params.Length = 0;
	Params.AddItem(Str(class'UILWOfficers'.static.Word(class'UILWOfficers'.default.BilletsTitle, "Officer Billets")));
	CallNow("SetTitle", Params);
	for (r = 1; r <= 5; r++)
	{
		bLocked = S == none || S.OfficerProjectsBought < r;
		Params.Length = 0;
		Params.AddItem(Num(r - 1));
		Params.AddItem(Str(class'LWOfficers'.static.RankName(r)));
		Params.AddItem(Str(bLocked ? class'UILWOfficers'.static.Word(class'UILWOfficers'.default.Locked, "LOCKED")
			: class'UILWOfficers'.static.Word(class'UILWOfficers'.default.OpenBillets, "Open Billets:") @ (S.OfficersAvailable.Length >= r ? S.OfficersAvailable[r - 1] : 0)));
		Params.AddItem(BoolValue(bLocked));
		Params.AddItem(Str(RankLabels[r - 1]));
		CallNow("currentMedalsMC.SetInfo", Params);
	}
	Focus(Selected);
}

static function ASValue BoolValue(bool B)
{
	local ASValue V;

	V.Type = AS_Boolean;
	V.b = B;
	return V;
}

/** EW's highlight on a row (the ranks) or a power. */
function Focus(int i)
{
	local array<ASValue> Params;

	if (EWView == 0)
		Selected = Clamp(i, 0, 4);
	else
		Power = Clamp(i, 0, 1);
	Params.AddItem(Num(EWView == 0 ? Selected : Power));
	CallNow("SetFocus", Params);
}

/** A rank chosen: XCOM 2's soldier list of those Long War lets be promoted to it (if it has an open billet). */
function ChooseRank()
{
	local XComGameState_LWStrategy S;
	local UIPersonnel_LWOfficer List;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.OfficerProjectsBought <= Selected || S.OfficersAvailable.Length <= Selected || S.OfficersAvailable[Selected] <= 0)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	ChosenRank = Selected + 1;
	List = Spawn(class'UIPersonnel_LWOfficer', Movie.Pres);
	List.OfficerRank = ChosenRank;
	List.onSelectedDelegate = OnSoldierChosen;
	Movie.Pres.ScreenStack.Push(List);
}

/** A soldier chosen: the rank's two powers, their words and names. */
function OnSoldierChosen(StateObjectReference UnitRef)
{
	local array<ASValue> Params;
	local int i, P;

	ChosenUnit = UnitRef;
	EWView = 2;
	Params.AddItem(Num(2));
	CallNow("SetDisplayMode", Params);
	Params.Length = 0;
	Params.AddItem(Str(class'UILWOfficers'.static.Word(class'UILWOfficers'.default.AssignAbility, "ASSIGN ABILITY") @ "-" @ class'LWOfficers'.static.RankName(ChosenRank)));
	CallNow("SetTitle", Params);
	for (i = 0; i < 2; i++)
	{
		P = 2 * (ChosenRank - 1) + i;
		Params.Length = 0;
		Params.AddItem(Num(i));
		Params.AddItem(Str(class'LWOfficers'.static.PowerDesc(P)));
		// (Stock Long War's power pictures table is empty: no picture.)
		Params.AddItem(Str(""));
		CallNow("assignPowerMC.SetPowerInfo", Params);
		Params.Length = 0;
		Params.AddItem(Num(i));
		Params.AddItem(Str(Caps(class'LWOfficers'.static.PowerName(P))));
		CallNow("assignPowerMC.SetButtonHelp", Params);
	}
	Focus(0);
}

/** The power chosen: EW's confirmation, then the promotion. */
function ChoosePower()
{
	local TDialogueBoxData Data;
	local XGParamTag Tag;
	local string Body;

	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.StrValue0 = class'LWOfficers'.static.RankName(ChosenRank);
	Tag.StrValue1 = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ChosenUnit.ObjectID)).GetName(eNameType_Full);
	Body = class'UILWOfficers'.default.ConfirmBody;
	Data.eType = eDialog_Normal;
	Data.strTitle = class'UILWOfficers'.static.Word(class'UILWOfficers'.default.ConfirmTitle, "CONFIRM");
	Data.strText = (Body != "" ? `XEXPAND.ExpandString(Body) : "Promote" @ Tag.StrValue1 @ "to" @ Tag.StrValue0 $ "?")
		$ "\n\n" $ class'LWOfficers'.static.PowerName(2 * (ChosenRank - 1) + Power);
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
	if (class'LWOfficers'.static.Promote(ChosenUnit.ObjectID, Power == 1, Why))
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	else
		`log("LongWarX2: officers:" @ Why, , 'LongWarX2');
	ShowRanks();
}

function Choose()
{
	if (EWView == 0)
		ChooseRank();
	else
		ChoosePower();
}

/** EW's clicks (as Long War's UIMedals reads them): the row or power under the mouse, option<n> or highlightMC<n>. */
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;
	local int i;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	i = -1;
	if (Left(Target, 6) == "option")
		i = int(Mid(Target, 6));
	else if (Left(Target, 11) == "highlightMC")
		i = int(Mid(Target, 11));
	if (i >= 0)
	{
		if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN)
			Focus(i);
		else if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		{
			Focus(i);
			Choose();
		}
	}
	super(UIScreen).OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super(UIScreen).OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_ARROW_UP:
	case class'UIUtilities_Input'.const.FXS_DPAD_UP:
	case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		Focus((EWView == 0 ? Selected : Power) - 1);
		return true;
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
	case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		Focus((EWView == 0 ? Selected : Power) + 1);
		return true;
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		Choose();
		return true;
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		// Out of the powers, back to the ranks; from the ranks, closed.
		if (EWView == 2)
			ShowRanks();
		else
			CloseScreen();
		return true;
	}
	return super(UIScreen).OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	// (Over the hub's Barracks room: the base stays in view behind it.)
	bShowsBase = true
	RankLabels(0) = "urbancombat"
	RankLabels(1) = "defender"
	RankLabels(2) = "international"
	RankLabels(3) = "honor"
	RankLabels(4) = "starofterra"
}
