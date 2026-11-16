// XCOM 2's soldier list for an officer promotion (features/lw-officers.md): only the soldiers Long War lets be promoted to
// the rank (LWOfficers.CanPromote: holding the rank below, rank, missions in grade, not psionic, not in the labs).
class UIPersonnel_LWOfficer extends UIPersonnel;

/** The officer rank the list is for (1: lieutenant). */
var int OfficerRank;

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
		if (Unit == none || class'LWOfficers'.static.Rank(Unit) != OfficerRank - 1 || !class'LWOfficers'.static.CanPromote(S, Unit, Why))
			m_arrSoldiers.Remove(i, 1);
	}
}

defaultproperties
{
	m_eListType = eUIPersonnel_Soldiers;
	m_bRemoveWhenUnitSelected = true;
}
