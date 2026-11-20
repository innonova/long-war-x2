// XCOM 2's screen while the squad flies home (its dropship, a ModClassOverride; features/strategy-flow.md), without XCOM 2's
// strategy tip ("Making contact with multiple regions …": EW's loading has no tips, and these are about XCOM 2's
// campaign) and without XCOM 2's post-mission narrative line.
class UILWDropShipBriefingEnd extends UIDropShipBriefing_MissionEnd;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState_BattleData BattleData;
	local string MissionResult;

	super.InitScreen(InitController, InitMovie, InitName);
	if (class'XComGameState_LWStrategy'.static.Get() == none)
		return;
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (BattleData == none)
		return;
	if (BattleData.bLocalPlayerWon && !BattleData.bMissionAborted)
		MissionResult = class'UIUtilities_Text'.static.GetColoredText(class'UIMissionSummary'.default.m_strMissionComplete, eUIState_Good);
	else if (BattleData.bMissionAborted)
		MissionResult = class'UIUtilities_Text'.static.GetColoredText(class'UIMissionSummary'.default.m_strMissionAbandoned, eUIState_Bad);
	else
		MissionResult = class'UIUtilities_Text'.static.GetColoredText(class'UIMissionSummary'.default.m_strMissionFailed, eUIState_Bad);
	MC.BeginFunctionOp("updatePostBriefing");
	MC.QueueString(BattleData.m_strOpName);
	MC.QueueString("");
	MC.QueueString(MissionResult);
	MC.QueueString("");
	MC.QueueString(m_strLoadingText);
	MC.EndOp();
}

function PlayPostMissionNarrative();
