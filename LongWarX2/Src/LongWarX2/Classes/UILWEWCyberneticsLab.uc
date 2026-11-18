// Long War's Cybernetics Lab on EW's lab screen (UILWEWSoldierSlots; XGCyberneticsUI.BuildTrainees): a row a place, each
// soldier being augmented with the time left (hours under a day, else days), each free place (EMPTY), the first with ADD
// SOLDIER. The soldier chosen on EW's list: Long War's price and days in a confirmation, then into the lab
// (LWMECs.StartAugment; EW's augmentation screen, AugmentSoldier, not yet).
class UILWEWCyberneticsLab extends UILWEWSoldierSlots;

var StateObjectReference Augmenting;

function BuildRows()
{
	local XComGameState_LWStrategy S;
	local XComGameState_Unit U;
	local LabRow R;
	local int i;
	local bool bFirstEmpty;

	S = class'XComGameState_LWStrategy'.static.Get();
	bFirstEmpty = true;
	for (i = 0; i < Places(); i++)
	{
		if (S == none || i >= S.MECPatients.Length)
		{
			AddEmptyRow(bFirstEmpty);
			bFirstEmpty = false;
			continue;
		}
		U = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.MECPatients[i].Unit));
		R.Unit = S.MECPatients[i].Unit;
		R.Soldier = U != none ? SoldierName(U) : "";
		R.Status = class'UIUtilities_Text'.static.GetColoredText(TimeLeft(S.MECPatients[i].HoursLeft), eUIState_Warning);
		R.Button = "";
		R.bDisabled = false;
		Rows.AddItem(R);
	}
}

/** Who may be augmented (LWMECs.CanAugment); the price aside, which the confirmation shows. */
function string WhyNot(XComGameState_Unit U)
{
	local string Why;

	class'LWMECs'.static.CanAugment(class'XComGameState_LWStrategy'.static.Get(), U, Why);
	if (InStr(Why, "§") != INDEX_NONE || InStr(Why, class'X2Item_LWArtifacts'.static.DisplayName('Meld')) != INDEX_NONE)
		return "";
	return Why;
}

/** Long War's price and days, and what is short (as UIPersonnel_LWAugment asked it). */
function Chosen(StateObjectReference UnitRef)
{
	local TDialogueBoxData Data;
	local XComGameState_Unit Unit;
	local string Why;

	Augmenting = UnitRef;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	class'LWMECs'.static.CanAugment(class'XComGameState_LWStrategy'.static.Get(), Unit, Why);
	Data.eType = eDialog_Normal;
	Data.strTitle = Word(class'UIPersonnel_LWAugment'.default.ConfirmTitle, "AUGMENT SOLDIER");
	Data.strText = Unit.GetName(eNameType_FullNick) @ "->" @ class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(class'LWMECs'.static.MECClassFor(Unit.GetSoldierClassTemplateName())).DisplayName
		$ "\n\n" $ class'LWStrategyRules'.static.Money(class'LWMECs'.default.AugmentCash) $ "," @ class'LWMECs'.default.AugmentMeld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld')
		$ "," @ class'LWMECs'.default.AugmentDays @ Word(Days, "Days")
		$ (Why != "" ? "\n\n" $ class'UIUtilities_Text'.static.GetColoredText("Needs" @ Why, eUIState_Bad) : "");
	Data.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	Data.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	Data.fnCallback = AugmentAnswered;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function AugmentAnswered(Name Action)
{
	local string Why;

	if (Action != 'eUIAction_Accept')
		return;
	if (!class'LWMECs'.static.StartAugment(Augmenting.ObjectID, Why))
	{
		`log("LongWarX2: MECs: augmentation needs" @ Why, , 'LongWarX2');
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	PlaySound(SoundCue'SoundUI.MenuSelectCue', true);
	Fill();
}

defaultproperties
{
	// (EW's UICyberneticsLab.m_strCameraTag.)
	LabCamera = CyberneticsLab_FacilityCamera
	Facility = 22
}
