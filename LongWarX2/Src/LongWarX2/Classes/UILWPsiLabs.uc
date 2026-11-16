// Long War's Psi Labs (features/lw-psi.md), on XCOM 2's widgets (agreed 2026-11-16: soldier screens are XCOM 2's): who is
// in training and how long is left; a soldier chosen from XCOM 2's list (UIPersonnel_LWPsi), the powers Long War lets them
// train, each with its target will, the chance at the soldier's will (LWBaseRules.PsiChance) and the days
// (LWBaseRules.PsiHours); one chosen, confirmed, training begun (XComGameState_LWStrategy.StartPsi). EW's base behind it,
// the camera in the Psi Labs.
class UILWPsiLabs extends UIScreen;

/** EW's words (XGPsiLabsUI), written from the player's install (lw-words.mjs, makePsiWords). */
var localized string Title, Current, Days, Empty;

var UIBGBox Back;
var UIText TitleText, InfoText, HelpText;
var UIList Powers;
var StateObjectReference Soldier;
/** The powers listed, in the list's order (their perks), and whether each can be trained now. */
var array<int> ListedPerks;
var array<int> ListedAble;
var int ChosenPerk;

static function Open(XComHQPresentationLayer HQPres)
{
	local UIPersonnel_LWPsi List;
	local UILWPsiLabs Labs;

	Labs = HQPres.Spawn(class'UILWPsiLabs', HQPres);
	HQPres.ScreenStack.Push(Labs);
	// The labs full: what they are training, no list to choose from.
	if (!class'XComGameState_LWStrategy'.static.PsiPlaceFree(class'XComGameState_LWStrategy'.static.Get()))
		return;
	List = HQPres.Spawn(class'UIPersonnel_LWPsi', HQPres);
	List.onSelectedDelegate = Labs.OnSoldierChosen;
	HQPres.ScreenStack.Push(List);
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	Back = Spawn(class'UIBGBox', self);
	Back.InitBG('LWPsiBG', 60, 120, 1000, 760);
	TitleText = Spawn(class'UIText', self);
	TitleText.InitText('LWPsiTitle', "", false);
	TitleText.SetPosition(80, 135);
	TitleText.SetWidth(960);
	InfoText = Spawn(class'UIText', self);
	InfoText.InitText('LWPsiInfo', "", false);
	InfoText.SetPosition(80, 190);
	InfoText.SetWidth(960);
	Powers = Spawn(class'UIList', self);
	Powers.InitList('LWPsiPowers', 80, 330, 960, 420);
	Powers.OnItemClicked = OnPowerClicked;
	HelpText = Spawn(class'UIText', self);
	HelpText.InitText('LWPsiHelp', "", false);
	HelpText.SetPosition(80, 770);
	HelpText.SetWidth(960);
	ShowBase();
	Fill();
}

static function string Word(string Localized, string Fallback)
{
	return Localized != "" ? Localized : Fallback;
}

/** EW's base behind it, the camera in the (first) Psi Labs. */
function ShowBase()
{
	local XComGameState_LWStrategy S;
	local LWX2EWBase B;
	local int i;

	if (!class'LWX2EWBase'.static.Converted())
		return;
	B = class'LWX2EWBase'.static.Get(self);
	B.Show();
	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = 0; S != none && i < S.TileFacility.Length; i++)
		if (S.TileFacility[i] == 17)
		{
			B.LookAt(name("AddonCam_R" $ (i / class'LWBase'.const.W) $ "_C" $ (i % class'LWBase'.const.W + 1)), 1.0);
			return;
		}
	B.LookAt('BARRACKS', 1.0);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	ShowBase();
	Fill();
}

static function string PowerName(int Perk)
{
	local X2AbilityTemplate T;

	T = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(class'X2Ability_LWStandins'.static.PsiAbilityFor(Perk));
	return (T != none && T.LocFriendlyName != "") ? T.LocFriendlyName : string(class'X2Ability_LWStandins'.static.PsiAbilityFor(Perk));
}

/** Who is training (Long War's current psionic training), then the chosen soldier's powers. */
function Fill()
{
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local LWBaseRules.LWPsiPower P;
	local string Line, Why;
	local int i, Will;
	local bool bAble;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return;
	TitleText.SetHtmlText(class'UIUtilities_Text'.static.GetSizedText(Caps(Word(Title, "Psionic Training")), 32));
	Line = Word(Current, "Current Psionic Training:");
	for (i = 0; i < S.PsiTrainees.Length; i++)
		Line $= "\n" $ XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.PsiTrainees[i].Unit)).GetName(eNameType_FullNick)
			@ "-" @ PowerName(S.PsiTrainees[i].Perk) @ "-" @ ((S.PsiTrainees[i].HoursLeft + 23) / 24) @ Word(Days, "Days") @ "-" @ S.PsiTrainees[i].Chance $ "%";
	if (S.PsiTrainees.Length == 0)
		Line $= "\n" $ Word(Empty, "(EMPTY)");
	InfoText.SetText(Line);
	Powers.ClearItems();
	ListedPerks.Length = 0;
	ListedAble.Length = 0;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Soldier.ObjectID));
	if (Unit == none)
	{
		Powers.Hide();
		HelpText.SetText("");
		return;
	}
	Will = int(Unit.GetMaxStat(eStat_Will));
	foreach class'LWBaseRules'.default.PsiPowers(P)
	{
		bAble = class'XComGameState_LWStrategy'.static.CanTrainPsi(S, Unit, P, Why);
		// (Powers the soldier has are left out; those not yet open are shown greyed with what they need.)
		if (!bAble && Why == "a soldier without the power")
			continue;
		Line = Caps(PowerName(P.Perk)) @ "-" @ class'XLocalizedData'.default.WillLabel @ P.TargetWill @ "-"
			@ class'LWBaseRules'.static.PsiChance(Will, P) $ "% -" @ ((class'LWBaseRules'.static.PsiHours(Will, P) + 23) / 24) @ Word(Days, "Days");
		if (!bAble)
			Line = class'UIUtilities_Text'.static.GetColoredText(Line @ "(" $ Why $ ")", eUIState_Disabled);
		Spawn(class'UIListItemString', Powers.itemContainer).InitListItem(Line);
		ListedPerks.AddItem(P.Perk);
		ListedAble.AddItem(bAble ? 1 : 0);
	}
	Powers.Show();
	HelpText.SetText(Unit.GetName(eNameType_FullNick) @ "-" @ class'XLocalizedData'.default.WillLabel @ Will);
}

function OnSoldierChosen(StateObjectReference UnitRef)
{
	Soldier = UnitRef;
	Fill();
}

function OnPowerClicked(UIList ContainerList, int ItemIndex)
{
	local TDialogueBoxData Data;

	if (ItemIndex < 0 || ItemIndex >= ListedPerks.Length || ListedAble[ItemIndex] == 0)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	ChosenPerk = ListedPerks[ItemIndex];
	Data.eType = eDialog_Normal;
	Data.strTitle = Caps(Word(Title, "Psionic Training"));
	Data.strText = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Soldier.ObjectID)).GetName(eNameType_FullNick) @ "-" @ Caps(PowerName(ChosenPerk));
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
	if (class'XComGameState_LWStrategy'.static.StartPsi(Soldier.ObjectID, ChosenPerk, Why))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		Soldier.ObjectID = 0;
		Fill();
		// A place still free: the soldier list again, as EW's labs go back to theirs.
		if (class'XComGameState_LWStrategy'.static.PsiPlaceFree(class'XComGameState_LWStrategy'.static.Get()))
			ChooseSoldier();
		return;
	}
	`log("LongWarX2: psi:" @ Why, , 'LongWarX2');
	Fill();
}

function ChooseSoldier()
{
	local UIPersonnel_LWPsi List;

	List = Spawn(class'UIPersonnel_LWPsi', Movie.Pres);
	List.onSelectedDelegate = OnSoldierChosen;
	Movie.Pres.ScreenStack.Push(List);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0
		&& (cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE || cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B))
	{
		// From a soldier's powers back to the list; from the list's place, closed.
		if (Soldier.ObjectID != 0)
		{
			Soldier.ObjectID = 0;
			Fill();
			ChooseSoldier();
		}
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
