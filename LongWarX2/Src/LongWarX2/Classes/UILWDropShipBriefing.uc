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
