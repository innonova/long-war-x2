// XCOM 2's soldier list for a covert operative (features/lw-exalt.md): only those Long War lets go
// (LWExalt.CanBeOperative: no Gunners or Rocketeers, no rookies, ready, rested).
class UIPersonnel_LWCovert extends UIPersonnel;

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
		if (S == none || !class'LWExalt'.static.CanBeOperative(S, Unit, Why))
			m_arrSoldiers.Remove(i, 1);
	}
}

defaultproperties
{
	m_eListType = eUIPersonnel_Soldiers;
	m_bRemoveWhenUnitSelected = true;
}
