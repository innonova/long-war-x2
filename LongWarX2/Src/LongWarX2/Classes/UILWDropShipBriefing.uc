// XCOM 2's briefing while a mission loads (its dropship, a ModClassOverride; features/strategy-flow.md), filled with Long
// War's mission: its country as the location (XCOM 2's was its plot's description, "Wilderness of Eastern U.S." for a
// mission in Argentina) and its objective as the squad select shows it (UILWSquadSelect.UpdateMissionInfo); XCOM 2's
// briefing text for the mission type it is fought as is left out.
class UILWDropShipBriefing extends UIDropShipBriefing_MissionStart;

function UpdateBriefingScreen()
{
	local XComGameState_LWStrategy S;
	local XComGameState_BattleData BattleData;
	local string Title, Reward;

	S = class'XComGameState_LWStrategy'.static.Get();
	// (The campaign's first mission, its base chosen before it: an abduction in a country of the home's continent, as EW's
	// first mission; features/first-mission-order.md.)
	if ((S == none || S.PendingKind == 0) && FirstMission())
		return;
	if (S == none || S.PendingKind == 0)
	{
		super.UpdateBriefingScreen();
		return;
	}
	S.PendingWords(Title, Reward);
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	MC.BeginFunctionOp("updatePreBriefing");
	MC.QueueString(m_strOpLabel);
	MC.QueueString(BattleData.m_strOpName);
	MC.QueueString(m_strLocationLabel);
	MC.QueueString(S.CountryName(S.PendingCountry()));
	MC.QueueString(m_strBriefingLabel);
	MC.QueueString(Reward);
	MC.QueueString(m_strObjectiveLabel);
	MC.QueueString(Title);
	MC.QueueString("");
	MC.QueueString("");
	MC.QueueString(m_strCurrentTip);
	MC.QueueString(m_strLoadingText);
	MC.QueueString(m_strSplashTitle);
	MC.QueueString(m_strSplashLabel);
	MC.EndOp();
}

/** The first mission's briefing, when the base was chosen before it (XComGameState_LWStartChoice): EW's abductions' title
 *  and the country, Long War's words; false otherwise. */
function bool FirstMission()
{
	local XComGameState_LWStartChoice C;
	local XComGameState_BattleData BattleData;
	local string Country;

	C = class'XComGameState_LWStartChoice'.static.Get();
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (C == none || BattleData == none || class'XComGameState_LWStrategy'.static.Get() != none)
		return false;
	Country = class'LWStrategyRules'.default.Countries[C.FirstCountry].Name;
	MC.BeginFunctionOp("updatePreBriefing");
	MC.QueueString(m_strOpLabel);
	MC.QueueString(BattleData.m_strOpName);
	MC.QueueString(m_strLocationLabel);
	MC.QueueString(Country);
	MC.QueueString(m_strBriefingLabel);
	MC.QueueString("");
	MC.QueueString(m_strObjectiveLabel);
	MC.QueueString((class'UILWEWAlert'.default.TitleAbductions != "" ? class'UILWEWAlert'.default.TitleAbductions : "Abductions") @ "-" @ Country);
	MC.QueueString("");
	MC.QueueString("");
	MC.QueueString(m_strCurrentTip);
	MC.QueueString(m_strLoadingText);
	MC.QueueString(m_strSplashTitle);
	MC.QueueString(m_strSplashLabel);
	MC.EndOp();
	return true;
}
