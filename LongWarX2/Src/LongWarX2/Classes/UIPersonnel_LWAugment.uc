// XCOM 2's soldier list for the Cybernetics Lab (features/lw-shivs-mecs.md): the soldiers Long War lets be augmented now
// (LWMECs.CanAugment, the price aside); one chosen, Long War's price and days in a confirmation, then into the lab.
class UIPersonnel_LWAugment extends UIPersonnel;

var localized string ConfirmTitle, ConfirmBody;
var StateObjectReference Chosen;

simulated function UpdateData()
{
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local string Why;
	local int i;

	super.UpdateData();
	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = m_arrSoldiers.Length - 1; i >= 0; i--)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrSoldiers[i].ObjectID));
		class'LWMECs'.static.CanAugment(S, Unit, Why);
		// (Kept when only the price is short: the confirmation says so.)
		if (Why != "" && InStr(Why, "§") == INDEX_NONE && InStr(Why, class'X2Item_LWArtifacts'.static.DisplayName('Meld')) == INDEX_NONE)
			m_arrSoldiers.Remove(i, 1);
	}
}

static function Open(XComHQPresentationLayer HQPres)
{
	local UIPersonnel_LWAugment List;

	List = HQPres.Spawn(class'UIPersonnel_LWAugment', HQPres);
	List.onSelectedDelegate = List.OnChosen;
	HQPres.ScreenStack.Push(List);
}

function OnChosen(StateObjectReference UnitRef)
{
	local TDialogueBoxData Data;
	local XComGameState_Unit Unit;
	local string Why;

	Chosen = UnitRef;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	class'LWMECs'.static.CanAugment(class'XComGameState_LWStrategy'.static.Get(), Unit, Why);
	Data.eType = eDialog_Normal;
	Data.strTitle = ConfirmTitle != "" ? ConfirmTitle : "AUGMENT SOLDIER";
	Data.strText = Unit.GetName(eNameType_FullNick) @ "->" @ class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(class'LWMECs'.static.MECClassFor(Unit.GetSoldierClassTemplateName())).DisplayName
		$ "\n\n" $ class'LWStrategyRules'.static.Money(class'LWMECs'.default.AugmentCash) $ "," @ class'LWMECs'.default.AugmentMeld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld')
		$ "," @ class'LWMECs'.default.AugmentDays @ class'UILWPsiLabs'.static.Word(class'UILWPsiLabs'.default.Days, "Days")
		$ (Why != "" ? "\n\n" $ class'UIUtilities_Text'.static.GetColoredText("Needs" @ Why, eUIState_Bad) : "");
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
	if (!class'LWMECs'.static.StartAugment(Chosen.ObjectID, Why))
	{
		`log("LongWarX2: MECs: augmentation needs" @ Why, , 'LongWarX2');
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
	UpdateData();
	UpdateList();
}

defaultproperties
{
	m_eListType = eUIPersonnel_Soldiers;
	// (Kept while the confirmation is up: its answer comes back here; refreshed after, for another soldier.)
	m_bRemoveWhenUnitSelected = false;
}
