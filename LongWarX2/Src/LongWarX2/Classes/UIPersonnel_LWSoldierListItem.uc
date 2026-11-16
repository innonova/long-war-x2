// A row of XCOM 2's soldier lists (the barracks, squad select's picker, the labs' lists: an override of XCOM 2's row,
// XComEngine.ini) with an officer's rank shown as Long War's (features/lw-officers.md): its short name (LT, CAPT, MAJ,
// COL, CMDR; XGFacility_Barracks.m_arrMedalNames) in place of the soldier's rank, as Long War's XGStrategySoldier.GetName
// gives an officer's rank. The rest of the row is XCOM 2's.
class UIPersonnel_LWSoldierListItem extends UIPersonnel_SoldierListItem;

simulated function AS_UpdateDataSoldier(string UnitName, string UnitNickname, string UnitRank, string UnitRankPath, string UnitClass, string UnitClassPath, string UnitStatus, string UnitStatusValue, string UnitLocation, string UnitCountryFlagPath, bool bIsDisabled, bool bPromote, bool bPsiPromote, string UnitMentalState, int BondLevel)
{
	local XComGameState_Unit Unit;
	local int Officer;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	Officer = class'LWOfficers'.static.Rank(Unit);
	if (Officer >= 1 && Officer <= 5 && class'LWOfficers'.default.RankShort[Officer - 1] != "")
		UnitRank = Caps(class'LWOfficers'.default.RankShort[Officer - 1]);
	super.AS_UpdateDataSoldier(UnitName, UnitNickname, UnitRank, UnitRankPath, UnitClass, UnitClassPath, UnitStatus, UnitStatusValue, UnitLocation, UnitCountryFlagPath, bIsDisabled, bPromote, bPsiPromote, UnitMentalState, BondLevel);
}
