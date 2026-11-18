// Long War's Psi Labs on EW's lab screen (UILWEWSoldierSlots; XGPsiLabsUI.BuildTrainees): a row a place, each soldier in
// training as "RANK First 'Nick' Last (power) (chance%)" with the days and hours left and REMOVE SOLDIER (with EW's
// confirmation: training stopped, XComGameState_LWStrategy.StopPsi), each free place (EMPTY) with ADD SOLDIER. The soldier
// chosen on EW's list goes to the powers they may train (UILWPsiLabs, until EW's psi tree takes it).
class UILWEWPsiLabs extends UILWEWSoldierSlots;

var int RemovingUnit;

function BuildRows()
{
	local XComGameState_LWStrategy S;
	local XComGameState_Unit U;
	local LabRow R;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = 0; i < Places(); i++)
	{
		if (S == none || i >= S.PsiTrainees.Length)
		{
			AddEmptyRow(true);
			continue;
		}
		U = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.PsiTrainees[i].Unit));
		R.Unit = S.PsiTrainees[i].Unit;
		R.Soldier = (U != none ? SoldierName(U) : "") @ "(" $ class'UILWPsiLabs'.static.PowerName(S.PsiTrainees[i].Perk) $ ") (" $ S.PsiTrainees[i].Chance $ "%)";
		R.Status = class'UIUtilities_Text'.static.GetColoredText((S.PsiTrainees[i].HoursLeft / 24) @ Word(Days, "Days") @ (S.PsiTrainees[i].HoursLeft % 24) @ Word(Hours, "Hours"), eUIState_Warning);
		R.Button = Word(RemoveSoldier, "REMOVE SOLDIER");
		R.bDisabled = false;
		Rows.AddItem(R);
	}
}

function string WhyNot(XComGameState_Unit U)
{
	return class'XComGameState_LWStrategy'.static.PsiSoldierWhy(class'XComGameState_LWStrategy'.static.Get(), U);
}

function Chosen(StateObjectReference UnitRef)
{
	class'UILWPsiLabs'.static.OpenPowers(XComHQPresentationLayer(Movie.Pres), UnitRef);
}

/** EW's OnConfirmRemoveTrainee. */
function RemoveAt(int i)
{
	local TDialogueBoxData D;
	local XGParamTag Tag;
	local XComGameState_Unit U;

	RemovingUnit = Rows[i].Unit;
	U = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(RemovingUnit));
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.StrValue0 = U != none ? U.GetName(eNameType_Full) : "";
	D.eType = eDialog_Normal;
	D.strTitle = Word(RemoveTitle, "CONFIRM REMOVAL");
	D.strText = class'XComLocalizer'.static.ExpandString(Word(RemoveText, "Are you sure you want to stop psi training for <XGParam:StrValue0/>?"));
	D.strAccept = Word(RemoveAccept, "CONFIRM");
	D.strCancel = class'UIUtilities_Text'.default.m_strGenericCancel;
	D.fnCallback = RemoveAnswered;
	Movie.Pres.UIRaiseDialog(D);
}

simulated function RemoveAnswered(Name Action)
{
	if (Action != 'eUIAction_Accept')
		return;
	class'XComGameState_LWStrategy'.static.StopPsi(RemovingUnit);
	Fill();
}

defaultproperties
{
	Facility = 17
}
