// XCOM 2's soldier header (the armory, squad select's edit, the promotion screens) with Long War's officer rank in place of
// the soldier rank (features/lw-officers.md), as Long War names an officer by the rank of its medal ("LIEUTENANT"), as the
// soldier lists do (UIPersonnel_LWSoldierListItem). Put in XCOM 2's place by XComEngine.ini's ModClassOverrides.
class UISoldierHeader_LW extends UISoldierHeader;

var XComGameState_Unit ShownUnit;

public function PopulateData(optional XComGameState_Unit Unit, optional StateObjectReference NewItem, optional StateObjectReference ReplacedItem, optional XComGameState NewCheckGameState)
{
	ShownUnit = Unit;
	if (ShownUnit == none && UnitRef.ObjectID > 0)
		ShownUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	super.PopulateData(Unit, NewItem, ReplacedItem, NewCheckGameState);
}

simulated function SetSoldierInfo(string unitName, string statusLabel, string status, string missionsLabel, string missions, string killsLabel, string kills,
	string classIcon, string classLabel, string rankIcon, string rankLabel, string flagIcon, bool showPromoteIcon, string statusTime)
{
	local int Officer;
	local string Short;

	Officer = ShownUnit != none ? class'LWOfficers'.static.Rank(ShownUnit) : 0;
	if (Officer >= 1 && Officer <= 5 && class'LWOfficers'.default.RankNames[Officer - 1] != "")
	{
		rankLabel = Caps(class'LWOfficers'.default.RankNames[Officer - 1]);
		// (The name leads with the soldier rank's short form, "LCPL MIN JI LIU": the officer's in its place, as in the lists.)
		Short = Caps(class'X2ExperienceConfig'.static.GetShortRankName(ShownUnit.GetRank(), ShownUnit.GetSoldierClassTemplateName())) $ " ";
		if (class'LWOfficers'.default.RankShort[Officer - 1] != "" && Left(unitName, Len(Short)) == Short)
			unitName = Caps(class'LWOfficers'.default.RankShort[Officer - 1]) @ Mid(unitName, Len(Short));
	}
	super.SetSoldierInfo(unitName, statusLabel, status, missionsLabel, missions, killsLabel, kills, classIcon, classLabel, rankIcon, rankLabel, flagIcon, showPromoteIcon, statusTime);
}
