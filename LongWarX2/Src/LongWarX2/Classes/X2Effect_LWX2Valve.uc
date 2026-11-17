// One of Deluge's bypass valves opened by the soldier beside it (LWX2Deluge; EW's interactive actor raising
// TransponderActivated): two more turns to the dam's collapse.
class X2Effect_LWX2Valve extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	class'LWX2Deluge'.static.Opened(NewGameState, XComGameState_Unit(kNewTargetState));
}
