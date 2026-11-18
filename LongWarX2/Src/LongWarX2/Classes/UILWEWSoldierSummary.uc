// Enemy Within's soldier summary (features/strategy-flow.md; a soldier chosen in the barracks' list): its SoldierSummary
// movie on EW's soldier summary panel in EW's armory, through EW's camera (UIDisplay_SoldierSummary,
// Armory_UIDisplayCam_Summary), the soldier standing on EW's pad. Driven as EW's UISoldierSummary and its components drive
// it: the menu (ClearMenuItems, AddMenuOption, SetSelected, SetDescription), the soldier's information
// (soldierInfoMC.SetSoldierInformation), Long War's stats line (soldierStatsMC.SetUnitStats: HP|mod|Mobility|mod|Will|mod|
// Aim|mod|Defense|mod|…|XP|needed|Psi XP|needed) and the abilities (soldierAbilityListMC.SetTitle, AddAbility). The menu
// is Long War's (XGSoldierUI.UpdateMainMenu): Abilities (Long War's promotion screen), Psi-Abilities, Loadout and
// Customize (XCOM 2's, in EW's armory), Dismiss. (Gene Mods, the mods a soldier has, not yet.)
class UILWEWSoldierSummary extends UILWEWScreen;

var localized string StatusLabel, MissionsLabel, KillsLabel, AbilitiesTitle;
var localized string Abilities, AbilitiesHelp, PsiAbilities, PsiAbilitiesHelp, GeneMods, GeneModsHelp, Loadout, LoadoutHelp;
var localized string Customize, CustomizeHelp, Dismiss, DismissHelp, DismissTitle, DismissText;

var StateObjectReference UnitRef;
var Actor Pawn;
var array<name> Options;
var int Selected;

static function Open(XComHQPresentationLayer HQPres, StateObjectReference Unit)
{
	local UILWEWSoldierSummary S;

	DynamicLoadObject(default.UIPackage $ ".ewxSoldierSummary", class'Object', true);
	S = HQPres.Spawn(class'UILWEWSoldierSummary', HQPres);
	S.Package = name("/ package/ewxSoldierSummary/SoldierSummary");
	S.MCName = 'theScreen';
	S.UnitRef = Unit;
	S.EWDisplay = 'UIDisplay_SoldierSummary';
	S.EWDisplayCamera = 'Armory_UIDisplayCam_Summary';
	Push3D(HQPres, S);
}

simulated function OnInit()
{
	super.OnInit();
	Fill();
	PlacePawn();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (!bIsInited)
		return;
	Fill();
	PlacePawn();
}

simulated function OnRemoved()
{
	if (Pawn != none)
		Movie.Pres.GetUIPawnMgr().ReleasePawn(self, UnitRef.ObjectID);
	super.OnRemoved();
}

function XComGameState_Unit Unit()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
}

/** The soldier on EW's pad, facing EW's camera (LWX2EWBase.ArmorySpot), from XCOM 2's pawn manager. */
function PlacePawn()
{
	local vector Loc;
	local rotator Rot;

	class'LWX2EWBase'.static.Get(self).ArmorySpot(EWDisplayCamera, Loc, Rot);
	Pawn = Movie.Pres.GetUIPawnMgr().RequestPawnByID(self, UnitRef.ObjectID, Loc, Rot);
	if (Pawn == none)
		return;
	// (As XCOM 2's armory has it: its idle, and the gear worn: UIArmory.RequestPawn, LoadSoldierEquipment.)
	Pawn.GotoState('CharacterCustomization');
	if (XComUnitPawn(Pawn) != none)
		XComUnitPawn(Pawn).CreateVisualInventoryAttachments(Movie.Pres.GetUIPawnMgr(), Unit());
	Pawn.SetLocation(Loc);
	Pawn.SetRotation(Rot);
}

/** Long War's menu (XGSoldierUI.UpdateMainMenu, in its order), the soldier's panels. */
function Fill()
{
	local XComGameState_Unit U;
	local XComGameState_LWStrategy S;
	local name O;
	local int i;

	U = Unit();
	S = class'XComGameState_LWStrategy'.static.Get();
	if (U == none)
		return;
	Options.Length = 0;
	Options.AddItem('Abilities');
	if (class'LWGearRules'.static.IsPsionic(U))
		Options.AddItem('PsiAbilities');
	Options.AddItem('Loadout');
	Options.AddItem('Customize');
	Options.AddItem('Dismiss');
	MC.FunctionVoid("ClearMenuItems");
	foreach Options(O)
	{
		MC.BeginFunctionOp("AddMenuOption");
		MC.QueueNumber(i);
		MC.QueueString(Caps(OptionText(O)));
		MC.QueueBoolean(O == 'Abilities' && U.ShowPromoteIcon());
		MC.QueueBoolean(false);
		MC.QueueBoolean(!OptionOpen(O, U));
		MC.EndOp();
		i++;
	}
	Select(Clamp(Selected, 0, Options.Length - 1));
	FillInfo(U, S);
	FillStats(U);
	FillAbilities(U);
}

function string OptionText(name O)
{
	switch (O)
	{
	case 'Abilities': return Word(Abilities, "Abilities");
	case 'PsiAbilities': return Word(PsiAbilities, "Psi-Abilities");
	case 'GeneMods': return Word(GeneMods, "Gene Mods");
	case 'Loadout': return Word(Loadout, "Loadout");
	case 'Customize': return Word(Customize, "Customize");
	case 'Dismiss': return Word(Dismiss, "Dismiss");
	}
	return string(O);
}

function string OptionHelp(name O)
{
	switch (O)
	{
	case 'Abilities': return AbilitiesHelp;
	case 'PsiAbilities': return PsiAbilitiesHelp;
	case 'GeneMods': return GeneModsHelp;
	case 'Loadout': return LoadoutHelp;
	case 'Customize': return CustomizeHelp;
	case 'Dismiss': return DismissHelp;
	}
	return "";
}

/** Whether the option can be taken now (Long War greys dismissal of a wounded soldier, a soldier in the labs). */
function bool OptionOpen(name O, XComGameState_Unit U)
{
	if (O == 'Dismiss')
		return !U.IsInjured();
	return true;
}

/** The soldier's information panel (UIStrategyComponent_SoldierInfo.UpdateData). */
function FillInfo(XComGameState_Unit U, XComGameState_LWStrategy S)
{
	local int UIState, k;
	local string Status;

	Status = class'UILWEWSoldierList'.static.StatusOf(U, S, UIState);
	k = class'UILWEWSoldierList'.default.Classes.Find('Template', U.GetSoldierClassTemplateName());
	MC.BeginChildFunctionOp("soldierInfoMC", "SetSoldierInformation");
	MC.QueueString(Caps(U.GetName(eNameType_First) @ U.GetName(eNameType_Last)));
	MC.QueueString(Repl(U.GetNickName(), "'", "") != "" ? "'" $ Repl(U.GetNickName(), "'", "") $ "'" : "");
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(Word(StatusLabel, "STATUS:"), eUIState_Normal) @ class'UILWEWSoldierList'.static.Colored(Status, UIState) $ "   ");
	MC.QueueString(class'UILWEWSoldierList'.static.FlagOf(U.GetCountry()));
	MC.QueueString(k != INDEX_NONE ? class'UILWEWSoldierList'.default.Classes[k].Frame : "");
	MC.QueueString(U.GetSoldierClassTemplate() != none ? Caps(U.GetSoldierClassTemplate().DisplayName) : "");
	MC.QueueString("rank" $ Clamp(U.GetRank(), 0, 7));
	MC.QueueString(Caps(class'X2ExperienceConfig'.static.GetRankName(U.GetRank(), U.GetSoldierClassTemplateName())));
	MC.QueueBoolean(U.ShowPromoteIcon());
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(Word(MissionsLabel, "MISSIONS:") @ U.GetNumMissions(), eUIState_Normal));
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(Word(KillsLabel, "KILLS:") @ U.GetNumKills(), eUIState_Normal));
	MC.EndOp();
}

/** Long War's stats line (UIStrategyComponent_SoldierStats.UpdateData): each stat and its gear's bonus, then the
 *  experience and what the next rank needs (psi: none, -1). */
function FillStats(XComGameState_Unit U)
{
	local string Line;
	local int Rank;

	Line = Stat(U, eStat_HP) $ "|" $ Stat(U, eStat_Mobility) $ "|" $ Stat(U, eStat_Will) $ "|" $ Stat(U, eStat_Offense) $ "|" $ Stat(U, eStat_Defense);
	Rank = U.GetRank();
	Line $= "|" $ "|" $ "|" $ class'LWExperience'.static.XPOf(U) $ "|" $ (Rank < 7 ? string(class'X2ExperienceConfig'.static.GetRequiredKills(Rank + 1)) : "0") $ "|0|-1";
	MC.BeginChildFunctionOp("soldierStatsMC", "SetUnitStats");
	MC.QueueString(Line);
	MC.QueueString("");
	MC.QueueString("");
	MC.QueueString("");
	MC.EndOp();
}

/** A stat and its gear's bonus, as Long War's header shows them ("8|+2"; no bonus, an empty one): the gear's as XCOM 2's
 *  armory adds it up (each item's UI stat markup). */
static function string Stat(XComGameState_Unit U, ECharStatType T)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;
	local int Bonus;

	Items = U.GetAllInventoryItems(, true);
	foreach Items(Item)
		if (X2EquipmentTemplate(Item.GetMyTemplate()) != none)
			Bonus += X2EquipmentTemplate(Item.GetMyTemplate()).GetUIStatMarkup(T, Item);
	return int(U.GetCurrentStat(T)) $ "|" $ (Bonus > 0 ? "+" $ Bonus : (Bonus < 0 ? string(Bonus) : ""));
}

/** The abilities the soldier has, each with EW's icon for its Long War perk (LWPerkIcons). */
function FillAbilities(XComGameState_Unit U)
{
	local array<SoldierClassAbilityType> Earned;
	local SoldierClassAbilityType A;
	local X2AbilityTemplate T;
	local X2AbilityTemplateManager Manager;
	local string Frame;

	MC.ChildFunctionVoid("soldierAbilityListMC", "clear");
	MC.ChildFunctionString("soldierAbilityListMC", "SetTitle", Word(AbilitiesTitle, "ABILITIES"));
	Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Earned = U.GetEarnedSoldierAbilities();
	foreach Earned(A)
	{
		T = Manager.FindAbilityTemplate(A.AbilityName);
		Frame = class'LWPerkIcons'.static.FrameOf(A.AbilityName);
		// (EW lists the soldier's perks: XCOM 2's mechanics without a Long War perk, such as its pistol shot, are left out.)
		if (T == none || T.LocFriendlyName == "" || Frame == "")
			continue;
		MC.BeginChildFunctionOp("soldierAbilityListMC", "AddAbility");
		MC.QueueString(T.LocFriendlyName);
		MC.QueueString(Frame);
		MC.QueueBoolean(false);
		MC.EndOp();
	}
}

/** The previous (-1) or next (1) soldier of the list it was opened from (EW's PrevSoldier, NextSoldier). */
function Cycle(int By)
{
	local UILWEWSoldierList L;
	local int i;

	L = UILWEWSoldierList(Movie.Pres.ScreenStack.GetFirstInstanceOf(class'UILWEWSoldierList'));
	if (L == none || L.Soldiers.Length < 2)
		return;
	i = L.Soldiers.Find('ObjectID', UnitRef.ObjectID);
	i = (i + By + L.Soldiers.Length) % L.Soldiers.Length;
	if (Pawn != none)
		Movie.Pres.GetUIPawnMgr().ReleasePawn(self, UnitRef.ObjectID);
	Pawn = none;
	UnitRef = L.Soldiers[i];
	L.Select(i);
	PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
	Fill();
	PlacePawn();
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

function Select(int i)
{
	Selected = i;
	MC.FunctionString("SetSelected", string(i));
	if (i >= 0 && i < Options.Length)
		MC.FunctionString("SetDescription", OptionHelp(Options[i]));
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int i;

	super.OnMouseEvent(cmd, args);
	// (…theItems.<i>: EW's menu, UISoldierSummary.OnMouseEvent.)
	if (args.Length < 2 || args[args.Length - 2] != "theItems")
		return;
	i = int(args[args.Length - 1]);
	if (cmd == 392)
		Select(i);
	else if (cmd == 391 || cmd == 398)
	{
		Select(i);
		Choose(i);
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			Select(Selected > 0 ? Selected - 1 : Options.Length - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			Select(Selected + 1 < Options.Length ? Selected + 1 : 0);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Choose(Selected);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			Cycle(-1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
			Cycle(1);
			return true;
		}
	}
	return super.OnUnrealCommand(cmd, arg);
}

function Choose(int i)
{
	local XComHQPresentationLayer HQPres;
	local TDialogueBoxData D;
	local XGParamTag Tag;

	if (i < 0 || i >= Options.Length || !OptionOpen(Options[i], Unit()))
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	HQPres = XComHQPresentationLayer(Movie.Pres);
	switch (Options[i])
	{
	case 'Abilities':
		HQPres.UIArmory_Promotion(UnitRef);
		break;
	case 'PsiAbilities':
		HQPres.UIArmory_Promotion(UnitRef);
		break;
	case 'Loadout':
		HQPres.UIArmory_Loadout(UnitRef);
		break;
	case 'Customize':
		Movie.Pres.UICustomize_Menu(Unit(), Pawn);
		break;
	case 'Dismiss':
		Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		Tag.StrValue0 = Unit().GetName(eNameType_Full);
		D.eType = eDialog_Warning;
		D.strTitle = Word(DismissTitle, "DISMISS SOLDIER");
		D.strText = DismissText != "" ? Repl(DismissText, "<XGStrategySoldier:FullName/>", Unit().GetName(eNameType_Full)) : "Dismiss" @ Unit().GetName(eNameType_Full) $ "?";
		D.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
		D.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
		D.fnCallback = DismissAnswered;
		Movie.Pres.UIRaiseDialog(D);
		break;
	}
}

simulated function DismissAnswered(Name Action)
{
	if (Action != 'eUIAction_Accept')
		return;
	class'UIUtilities_Strategy'.static.GetXComHQ().FireStaff(UnitRef);
	CloseScreen();
}
