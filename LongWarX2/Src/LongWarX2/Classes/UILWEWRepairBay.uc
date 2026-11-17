// Long War's Repair Bay on Enemy Within's own MEC inventory screen (its MECInventory movie; features/lw-gear-repair.md), as
// Long War made it over EW's (XGCyberneticsUI.UpdateInventory, UIMECInventory): REPAIR ALL above, then each damaged item
// ("DAMAGED: …", greyed when XCOM cannot pay for it) and each repair under way ("REPAIRING: … Days: n"). The info panel shows
// the selected item's repair cost; choosing a damaged item asks EW's question (REPAIR ITEM: … / REPAIR, NOT NOW), REPAIR ALL
// repairs every one XCOM can pay for (GenerateUpgradeMEC, which Long War rewrote for it). Driven as EW drives the movie:
// SetTitle, SetSubTitle, SetBuildButtonHelp, widgetHelper.SetListOptions / SetListSelection / SetSelected,
// NewMecButtonSelected / Deselected, UpdateInfo, SetBuildInfo, SetSoldier, SetConfirmButtonHelp; clicks 392 (over) and
// 391 / 398 (chosen) on option0 (the button) or option1 (the list, args[6] the row). Long War's words in LongWarX2.int
// (scripts/lw-words.mjs makeRepairWords, the player's machine). The rules are LWGearRepair's.
class UILWEWRepairBay extends UILWEWScreen dependson(XComGameState_LWStrategy);

var localized string Title, SubTitle, RepairItem, Description, RepairsNeeded, Damaged, Repairing, RepairAll, RepairTitle,
	RepairCost, RepairWarning, Confirm, NotNow, CostLabel, StartedTitle, StartedText;

/** The list's rows: a damaged item's template (Repair -1) or a repair under way (Repair: its index in the campaign's). */
struct LWRepairRow
{
	var name Template;
	var int Repair;
};
var array<LWRepairRow> Rows;
/** -1: REPAIR ALL; else the list's row. */
var int Selected;
var name Chosen;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWRepairBay EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxMECInventory", class'Object', true);
	class'UILWEWMapBackdrop'.static.ShowIfAvailable();
	EWScreen = HQPres.Spawn(class'UILWEWRepairBay', HQPres);
	EWScreen.Package = name("/ package/ewxMECInventory/MECInventory");
	EWScreen.MCName = 'theScreen';
	HQPres.ScreenStack.Push(EWScreen);
}

simulated function OnInit()
{
	super.OnInit();
	MC.FunctionString("SetTitle", W(Title, "DAMAGED ITEM INVENTORY"));
	MC.FunctionString("SetSubTitle", W(SubTitle, "MANIFEST"));
	Selected = -1;
	Fill();
}

simulated function OnRemoved()
{
	class'UILWEWMapBackdrop'.static.HideAll();
	super.OnRemoved();
}

static function string W(string Localized, string Fallback)
{
	return Localized != "" ? Localized : Fallback;
}

/** The button and the list as XGCyberneticsUI.UpdateInventory and UIMECInventory.UpdateData write them. */
function Fill()
{
	local XComGameState_LWStrategy S;
	local LWRepairRow Row;
	local array<ASValue> Params;
	local string Labels, Label;
	local int i, Cash, Elerium, Alloys, Meld, AllCash, AllElerium, AllAlloys, AllMeld;
	local bool bAny;

	S = class'XComGameState_LWStrategy'.static.Get();
	Rows.Length = 0;
	for (i = 0; i < S.DamagedItems.Length; i++)
	{
		Row.Template = S.DamagedItems[i];
		Row.Repair = -1;
		Rows.AddItem(Row);
		class'LWGearRepair'.static.CostOf(Row.Template, Cash, Elerium, Alloys, Meld);
		AllCash += Cash;
		AllElerium += Elerium;
		AllAlloys += Alloys;
		AllMeld += Meld;
		bAny = bAny || class'LWGearRepair'.static.Short(Row.Template) == "";
	}
	for (i = 0; i < S.Repairs.Length; i++)
	{
		Row.Template = S.Repairs[i].Template;
		Row.Repair = i;
		Rows.AddItem(Row);
	}
	// REPAIR ALL: what all of them cost together (GetMecCosts over every damaged item).
	MC.BeginFunctionOp("SetBuildButtonHelp");
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(W(RepairAll, "REPAIR ALL"), bAny ? eUIState_Normal : eUIState_Disabled));
	MC.QueueString(CostWords(AllCash, AllElerium, AllAlloys, AllMeld));
	MC.EndOp();
	Params.AddItem(Num(0));
	CallNow(bAny ? "widgetHelper.SetEnabledButton" : "widgetHelper.SetDisabledButton", Params);
	for (i = 0; i < Rows.Length; i++)
	{
		Label = RowLabel(S, Rows[i]);
		Labels @= Label $ "," $ i;
		if (i < Rows.Length - 1)
			Labels @= ";";
	}
	Params.Length = 0;
	Params.AddItem(Num(1));
	Params.AddItem(Str(Labels));
	CallNow("widgetHelper.SetListOptions", Params);
	Selected = Clamp(Selected, -1, Rows.Length - 1);
	ShowSelected();
}

/** A row's words: "DAMAGED: <item>" (greyed when XCOM cannot pay for its repair), or "REPAIRING: <item> Days: n". */
function string RowLabel(XComGameState_LWStrategy S, LWRepairRow Row)
{
	local XGParamTag PTag;
	local string ItemLabel;

	ItemLabel = Caps(class'LWEngineering'.static.ItemName(Row.Template));
	if (Row.Repair < 0)
		return Fit(W(Damaged, "DAMAGED:") @ ItemLabel, class'UIUtilities_Text'.static.GetColoredText(class'UIUtilities_Text'.static.GetColoredText(W(Damaged, "DAMAGED:"), eUIState_Bad) @ ItemLabel,
			class'LWGearRepair'.static.Short(Row.Template) == "" ? eUIState_Normal : eUIState_Disabled));
	PTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	PTag.StrValue0 = ItemLabel;
	PTag.IntValue0 = S.Repairs[Row.Repair].HoursLeft / 24;
	ItemLabel = Repairing != "" ? `XEXPAND.ExpandString(Repairing) : "REPAIRING:" @ ItemLabel @ "Days:" $ PTag.IntValue0;
	return Fit(ItemLabel, class'UIUtilities_Text'.static.GetColoredText(ItemLabel, eUIState_Warning));
}

/** A row's words made to fit: XCOM 2's font stands in for EW's and runs wider, and a row (427 wide, the movie's size 24) holds
 *  about 27 of its capitals with digits and spaces; a longer label is set smaller in proportion. */
static function string Fit(string Plain, string Html)
{
	if (Len(Plain) <= 27)
		return Html;
	return "<font size='" $ Max(14, 24 * 27 / Len(Plain)) $ "'>" $ Html $ "</font>";
}

/** A cost as EW writes it ("§40, 9 Alien Alloys"); "" when nothing. */
static function string CostWords(int Cash, int Elerium, int Alloys, int Meld)
{
	local array<string> Out;

	if (Cash > 0)
		Out.AddItem(class'LWStrategyRules'.static.Money(Cash));
	if (Alloys > 0)
		Out.AddItem(Alloys @ class'X2Item_LWArtifacts'.static.DisplayName('Alloys'));
	if (Elerium > 0)
		Out.AddItem(Elerium @ class'X2Item_LWArtifacts'.static.DisplayName('Elerium'));
	if (Meld > 0)
		Out.AddItem(Meld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld'));
	return class'LWEngineering'.static.JoinStrings(Out);
}

/** The selection shown: the button or the row highlighted, the info panel filled (UpdateWidgetSelection, UpdateInfoPanelData). */
function ShowSelected()
{
	local array<ASValue> Params;
	local X2ItemTemplate Template;
	local LWRepairRow Row;
	local string Cost, Short, Info;
	local int Cash, Elerium, Alloys, Meld;

	if (Selected < 0)
	{
		CallNow("NewMecButtonSelected");
		Params.AddItem(Num(0));
		CallNow("widgetHelper.SetSelected", Params);
		Info5(W(RepairAll, "REPAIR ALL"), W(Description, "Select items to repair."), "");
		MC.FunctionString("SetBuildInfo", "");
		SetSoldier("", "");
		MC.FunctionString("SetConfirmButtonHelp", "");
		return;
	}
	CallNow("NewMecButtonDeselected");
	Params.AddItem(Num(1));
	CallNow("widgetHelper.SetSelected", Params);
	Params.AddItem(Num(Selected));
	CallNow("widgetHelper.SetListSelection", Params);
	Row = Rows[Selected];
	Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(Row.Template);
	// The perk info's form (GenerateMecWeaponDescription): name || summary || icon.
	Info = Caps(class'LWEngineering'.static.ItemName(Row.Template)) $ "||" $ (Template != none ? Template.GetItemBriefSummary() : "") $ "||";
	MC.FunctionString("SetBuildInfo", "");
	if (Row.Repair >= 0)
	{
		Info5(RowLabel(class'XComGameState_LWStrategy'.static.Get(), Row), "", Info);
		SetSoldier("", "");
		MC.FunctionString("SetConfirmButtonHelp", "");
		return;
	}
	class'LWGearRepair'.static.CostOf(Row.Template, Cash, Elerium, Alloys, Meld);
	Cost = CostWords(Cash, Elerium, Alloys, Meld);
	Short = class'LWGearRepair'.static.Short(Row.Template);
	Cost = W(CostLabel, "REPAIR COST:") @ class'UIUtilities_Text'.static.GetColoredText(Cost != "" ? Cost : "-", Short == "" ? eUIState_Normal : eUIState_Bad);
	Info5(Caps(class'LWEngineering'.static.ItemName(Row.Template)), Cost, Info);
	SetSoldier("", W(RepairsNeeded, "REPAIRS NEEDED"));
	MC.FunctionString("SetConfirmButtonHelp", Short == "" ? W(RepairItem, "REPAIR ITEM") : "");
}

function Info5(string Title5, string Cost, string Info0)
{
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(Title5);
	MC.QueueString(Cost);
	MC.QueueString(Info0);
	MC.QueueString("");
	MC.QueueString("");
	MC.EndOp();
}

function SetSoldier(string SoldierName, string Status)
{
	MC.BeginFunctionOp("SetSoldier");
	MC.QueueString(SoldierName);
	MC.QueueString(Status);
	MC.EndOp();
}

function Select(int i)
{
	Selected = Clamp(i, -1, Rows.Length - 1);
	ShowSelected();
}

/** The selection chosen: REPAIR ALL, or EW's question for a damaged item. */
function Choose()
{
	local TDialogueBoxData Data;
	local string Why;

	if (Selected < 0)
	{
		RepairEverything();
		return;
	}
	if (Rows[Selected].Repair >= 0 || class'LWGearRepair'.static.Short(Rows[Selected].Template) != "")
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Chosen = Rows[Selected].Template;
	Data.eType = eDialog_Normal;
	Data.strTitle = W(RepairTitle, "REPAIR ITEM:") @ Caps(class'LWEngineering'.static.ItemName(Chosen));
	Why = class'LWGearRepair'.static.CostText(Chosen);
	Data.strText = W(RepairCost, "REPAIR COST:") @ (Why != "" ? Why : "-") $ "\n\n" $ W(RepairWarning, "");
	Data.strAccept = W(Confirm, "REPAIR");
	Data.strCancel = W(NotNow, "NOT NOW");
	Data.fnCallback = OnConfirm;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnConfirm(Name Action)
{
	local TDialogueBoxData Data;
	local XGParamTag PTag;
	local string Why;
	local int Hours;

	if (Action != 'eUIAction_Accept')
		return;
	Hours = class'LWGearRepair'.static.HoursFor(class'XComGameState_LWStrategy'.static.Get(), Chosen);
	if (!class'LWGearRepair'.static.StartRepair(Chosen, Why))
	{
		`log("LongWarX2: Repair Bay:" @ Why, , 'LongWarX2');
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Repaired();
	// EW's word that the repair has begun (XGCyberneticsUI.ShowMecRepairingPopup).
	PTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	PTag.StrValue0 = class'LWEngineering'.static.ItemName(Chosen);
	PTag.StrValue1 = string((Hours + 23) / 24);
	Data.eType = eDialog_Normal;
	Data.strTitle = W(StartedTitle, "REPAIR IN PROGRESS");
	Data.strText = StartedText != "" ? `XEXPAND.ExpandString(StartedText) : PTag.StrValue0 @ "in repair for" @ PTag.StrValue1 @ "days.";
	Data.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;
	Movie.Pres.UIRaiseDialog(Data);
}

/** REPAIR ALL: each damaged item XCOM can pay for, in the order they were damaged. */
function RepairEverything()
{
	local XComGameState_LWStrategy S;
	local array<name> All;
	local name T;
	local string Why;
	local int n;

	S = class'XComGameState_LWStrategy'.static.Get();
	All = S.DamagedItems;
	foreach All(T)
		if (class'LWGearRepair'.static.StartRepair(T, Why))
			n++;
	if (n == 0)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Repaired();
}

function Repaired()
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
	Fill();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;
	local int i, Row;

	Target = "";
	Row = -1;
	for (i = 0; i < args.Length; i++)
		if (Left(args[i], 6) == "option")
		{
			Target = args[i];
			Row = (Target == "option1" && i + 2 < args.Length) ? int(args[i + 2]) : -1;
			break;
		}
	if (Target == "option0" && (cmd == 392 || cmd == 391 || cmd == 398))
	{
		Select(-1);
		if (cmd != 392)
			Choose();
	}
	else if (Target == "option1" && Row >= 0 && (cmd == 392 || cmd == 391 || cmd == 398))
	{
		if (Row != Selected)
			Select(Row);
		if (cmd != 392)
			Choose();
	}
	super(UIScreen).OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
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
			Choose();
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}
