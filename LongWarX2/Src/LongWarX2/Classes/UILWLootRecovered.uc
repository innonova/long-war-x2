// XCOM 2's loot screen after a mission (UIInventory_LootRecovered, which opens the mission's caches into XCOM's stores),
// ending straight in the return to the base (features/strategy-flow.md): not into XCOM 2's research-unlocked screen nor
// its rewards recap, which follow it on the Avenger. The return (ExitPostMissionSequence) lands on EW's base, the strategy
// layer's root (UILWFacilityGrid).
// Its own list is not shown: EW's debrief has shown the artifacts recovered (UILWEWDebrief); XCOM 2's opening of the
// mission's caches into the stores is kept, then the screen closes at once.
class UILWLootRecovered extends UIInventory_LootRecovered;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	Hide();
	SetTimer(0.05, false, nameof(CloseScreen));
}

simulated function CloseScreen()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Post Mission Loot UI Sequence Hook");
	`XEVENTMGR.TriggerEvent('PostMissionLoot', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	super(UIScreen).CloseScreen();
	if (VIPPanel != none)
		VIPPanel.Cleanup();
	`HQPRES.ExitPostMissionSequence();
}
