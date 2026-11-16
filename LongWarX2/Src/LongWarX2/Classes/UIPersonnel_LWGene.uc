// XCOM 2's soldier list for the Genetics Lab (features/lw-genemods.md): the soldiers who could go into a tank now (ready for
// duty, not in a lab already, a tank free). Which mods each may have, EW's Gene Mods screen shows (UILWEWGeneMods).
class UIPersonnel_LWGene extends UIPersonnel;

/** Out of the list without a soldier (the Genetics Lab's screen closes with it). */
var delegate<OnListCancelled> OnCancelled;
delegate OnListCancelled();

simulated function UpdateData()
{
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local int i;

	super.UpdateData();
	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = m_arrSoldiers.Length - 1; i >= 0; i--)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrSoldiers[i].ObjectID));
		if (S == none || class'XComGameState_LWStrategy'.static.GeneSoldierWhy(S, Unit) != "")
			m_arrSoldiers.Remove(i, 1);
	}
}

simulated function OnCancel()
{
	local delegate<OnListCancelled> Cancelled;

	Cancelled = OnCancelled;
	CloseScreen();
	if (Cancelled != none)
		Cancelled();
}

defaultproperties
{
	m_eListType = eUIPersonnel_Soldiers;
	m_bRemoveWhenUnitSelected = true;
}
