// Furies' command console disarmed by the soldier beside it (LWX2Furies; EW's interactive actor raising ConsoleActivated).
class X2Effect_LWX2Console extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	class'LWX2Furies'.static.Disarmed(NewGameState);
}
