// An EXALT comm relay hacked by the covert operative beside it (LWX2CovertExtraction; XComRadarArrayActor's interaction).
class X2Effect_LWX2Relay extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_LWX2Covert Covert;
	local int i;

	Covert = class'LWX2CovertExtraction'.static.State();
	i = class'LWX2CovertExtraction'.static.InReach(XComGameState_Unit(kNewTargetState));
	if (Covert == none || i == -1)
		return;
	Covert = XComGameState_LWX2Covert(NewGameState.ModifyStateObject(class'XComGameState_LWX2Covert', Covert.ObjectID));
	Covert.Hacked[i] = true;
	Covert.HackedOnTurn = class'LWX2CovertExtraction'.static.TurnNow();
	`log("LongWarX2: covert extraction: relay" @ Covert.Active[i] @ "hacked;" @ Covert.RelaysLeft() @ "left", , 'LongWarX2');
}
