// XCOM 2's soldier list for the Psi Labs (features/lw-psi.md): the soldiers who could go into the labs now (ready for duty,
// not training already, a place free). Which powers each may train, and why not the others, the labs' own screen shows.
class UIPersonnel_LWPsi extends UIPersonnel;

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
		if (S == none || class'XComGameState_LWStrategy'.static.PsiSoldierWhy(S, Unit) != "")
			m_arrSoldiers.Remove(i, 1);
	}
}

defaultproperties
{
	m_eListType = eUIPersonnel_Soldiers;
	m_bRemoveWhenUnitSelected = true;
}
