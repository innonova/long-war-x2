// The Chryssalid hive's transponder reactivated by the soldier beside it (LWX2ChryssalidHive; EW's XComInteractiveLevelActor
// raising EngineActivated): the run to the EVAC begins.
class X2Effect_LWX2Transponder extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	class'LWX2ChryssalidHive'.static.Reactivated(NewGameState);
}
