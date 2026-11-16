// Long War's officer promotions (features/lw-officers.md; EW's Officer Billets, its medals screen): the five officer ranks
// with their open billets; a rank chosen, XCOM 2's soldier list of those Long War lets be promoted to it
// (UIPersonnel_LWOfficer); a soldier chosen, the rank's two abilities to choose from, and EW's confirmation. Built from
// XCOM 2's widgets over EW's base (EW's own movie needs its shared components, which do not resolve in XCOM 2).
class UILWOfficers extends UIScreen;

/** EW's words (XGMedalsUI), written from the player's install (scripts/lw-words.mjs, makeOfficerWords). */
var localized string BilletsTitle, OpenBillets, Locked, AssignAbility, ConfirmTitle, ConfirmBody, Promotions, PromotionsHelp;

var UIBGBox Back;
var UIText Title, Help;
var UIList Ranks;
var UIButton PowerButtons[2];
var UIText PowerTexts[2];
var int ChosenRank;
var StateObjectReference ChosenUnit;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int i;

	super.InitScreen(InitController, InitMovie, InitName);
	Back = Spawn(class'UIBGBox', self);
	Back.InitBG('LWOfficersBG', 60, 120, 900, 620);
	Title = Spawn(class'UIText', self);
	Title.InitText('LWOfficersTitle', "", false);
	Title.SetPosition(80, 135);
	Title.SetWidth(860);
	Ranks = Spawn(class'UIList', self);
	Ranks.InitList('LWOfficersRanks', 80, 200, 860, 400);
	Ranks.OnItemClicked = OnRankClicked;
	Help = Spawn(class'UIText', self);
	Help.InitText('LWOfficersHelp', "", false);
	Help.SetPosition(80, 620);
	Help.SetWidth(860);
	for (i = 0; i < 2; i++)
	{
		PowerTexts[i] = Spawn(class'UIText', self);
		PowerTexts[i].InitText(name("LWOfficersPowerText" $ i), "", false);
		PowerTexts[i].SetPosition(80 + 440 * i, 280);
		PowerTexts[i].SetWidth(410);
		PowerTexts[i].Hide();
		PowerButtons[i] = Spawn(class'UIButton', self);
		PowerButtons[i].InitButton(name("LWOfficersPower" $ i), "", OnPowerClicked);
		PowerButtons[i].SetPosition(80 + 440 * i, 220);
		PowerButtons[i].Hide();
	}
	ShowRanks();
	ShowBase();
}

/** EW's base behind it, through the barracks' camera. */
function ShowBase()
{
	local LWX2EWBase B;

	if (!class'LWX2EWBase'.static.Converted())
		return;
	B = class'LWX2EWBase'.static.Get(self);
	B.Show();
	B.LookAt('BARRACKS', 0);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	ShowBase();
}

static function string Word(string Localized, string Fallback)
{
	return Localized != "" ? Localized : Fallback;
}

/** The five ranks: name, open billets or locked (EW's main menu). */
function ShowRanks()
{
	local XComGameState_LWStrategy S;
	local string Line;
	local int r, i;

	ChosenRank = 0;
	for (i = 0; i < 2; i++)
	{
		PowerButtons[i].Hide();
		PowerTexts[i].Hide();
	}
	Title.SetHtmlText(class'UIUtilities_Text'.static.GetSizedText(Word(BilletsTitle, "Officer Billets"), 32));
	S = class'XComGameState_LWStrategy'.static.Get();
	Ranks.ClearItems();
	for (r = 1; r <= 5; r++)
	{
		if (S.OfficerProjectsBought < r)
			Line = class'LWOfficers'.static.RankName(r) @ "-" @ Word(Locked, "LOCKED");
		else
			Line = class'LWOfficers'.static.RankName(r) @ "-" @ Word(OpenBillets, "Open Billets:") @ (S.OfficersAvailable.Length >= r ? S.OfficersAvailable[r - 1] : 0);
		Spawn(class'UIListItemString', Ranks.itemContainer).InitListItem(Line);
	}
	Ranks.Show();
	Help.SetText("");
}

function OnRankClicked(UIList ContainerList, int ItemIndex)
{
	local XComGameState_LWStrategy S;
	local UIPersonnel_LWOfficer List;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S.OfficerProjectsBought <= ItemIndex || S.OfficersAvailable.Length <= ItemIndex || S.OfficersAvailable[ItemIndex] <= 0)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	ChosenRank = ItemIndex + 1;
	List = Spawn(class'UIPersonnel_LWOfficer', Movie.Pres);
	List.OfficerRank = ChosenRank;
	List.onSelectedDelegate = OnSoldierChosen;
	Movie.Pres.ScreenStack.Push(List);
}

/** A soldier chosen: the rank's two abilities to choose from. */
function OnSoldierChosen(StateObjectReference UnitRef)
{
	local int i, Power;

	ChosenUnit = UnitRef;
	Ranks.Hide();
	Title.SetHtmlText(class'UIUtilities_Text'.static.GetSizedText(Word(AssignAbility, "ASSIGN ABILITY") @ "-" @ class'LWOfficers'.static.RankName(ChosenRank), 32));
	for (i = 0; i < 2; i++)
	{
		Power = 2 * (ChosenRank - 1) + i;
		PowerButtons[i].SetText(Caps(class'LWOfficers'.static.PowerName(Power)));
		PowerButtons[i].Show();
		PowerTexts[i].SetText(class'LWOfficers'.static.PowerDesc(Power));
		PowerTexts[i].Show();
	}
	Help.SetText(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID)).GetName(eNameType_FullNick));
}

function OnPowerClicked(UIButton Button)
{
	local TDialogueBoxData Data;
	local XGParamTag Tag;
	local int i;

	i = Button == PowerButtons[1] ? 1 : 0;
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.StrValue0 = class'LWOfficers'.static.RankName(ChosenRank);
	Tag.StrValue1 = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ChosenUnit.ObjectID)).GetName(eNameType_Full);
	Data.eType = eDialog_Normal;
	Data.strTitle = Word(ConfirmTitle, "CONFIRM");
	Data.strText = (ConfirmBody != "" ? `XEXPAND.ExpandString(ConfirmBody) : "Promote" @ Tag.StrValue1 @ "to" @ Tag.StrValue0 $ "?")
		$ "\n\n" $ class'LWOfficers'.static.PowerName(2 * (ChosenRank - 1) + i);
	Data.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	Data.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	Data.fnCallback = i == 1 ? OnConfirmSecond : OnConfirmFirst;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnConfirmFirst(Name Action) { Confirmed(Action, false); }
simulated function OnConfirmSecond(Name Action) { Confirmed(Action, true); }

function Confirmed(Name Action, bool bSecond)
{
	local string Why;

	if (Action != 'eUIAction_Accept')
		return;
	if (class'LWOfficers'.static.Promote(ChosenUnit.ObjectID, bSecond, Why))
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	else
		`log("LongWarX2: officers:" @ Why, , 'LongWarX2');
	ShowRanks();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0
		&& (cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE || cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B))
	{
		// Out of the abilities, back to the ranks; from the ranks, closed.
		if (ChosenRank > 0)
			ShowRanks();
		else
			CloseScreen();
		return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	InputState = eInputState_Consume;
}
