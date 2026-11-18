// Long War's Genetics Lab on EW's lab screen (UILWEWSoldierSlots; XGGeneLabUI.BuildTrainees): a row a tank, each soldier in
// one with the time left on all their mods (hours under a day, else days), each free tank (EMPTY), the first with ADD
// SOLDIER. The soldier chosen on EW's list goes to EW's Gene Mods screen (UILWEWGeneMods.OpenFor).
class UILWEWGeneLab extends UILWEWSoldierSlots;

function BuildRows()
{
	local XComGameState_LWStrategy S;
	local XComGameState_Unit U;
	local LabRow R;
	local int i, h, Total;
	local bool bFirstEmpty;

	S = class'XComGameState_LWStrategy'.static.Get();
	bFirstEmpty = true;
	for (i = 0; i < Places(); i++)
	{
		if (S == none || i >= S.GenePatients.Length)
		{
			AddEmptyRow(bFirstEmpty);
			bFirstEmpty = false;
			continue;
		}
		U = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.GenePatients[i].Unit));
		Total = 0;
		foreach S.GenePatients[i].HoursLeft(h)
			Total += h;
		R.Unit = S.GenePatients[i].Unit;
		R.Soldier = U != none ? SoldierName(U) : "";
		R.Status = class'UIUtilities_Text'.static.GetColoredText(TimeLeft(Total), eUIState_Warning);
		R.Button = "";
		R.bDisabled = false;
		Rows.AddItem(R);
	}
}

function string WhyNot(XComGameState_Unit U)
{
	return class'XComGameState_LWStrategy'.static.GeneSoldierWhy(class'XComGameState_LWStrategy'.static.Get(), U);
}

function Chosen(StateObjectReference UnitRef)
{
	class'UILWEWGeneMods'.static.OpenFor(XComHQPresentationLayer(Movie.Pres), UnitRef);
}

defaultproperties
{
	// (EW's UIGeneLab.m_strCameraTag.)
	LabCamera = GeneLab_FacilityCamera
	Facility = 23
}
