// Long War's Repair Servos (a MEC perk, and a SHIV's with the Foundry's Sentinel Drone): "repairs up to 50% of damage
// taken (max 2 per turn)". XCOM 2's regeneration at each of the unit's turns (HealAmount, 2), its total held to half of
// the damage the unit has taken this mission (its highest HP less its lowest), less what it has repaired already.
class X2Effect_LWRepairServos extends X2Effect_Regeneration;

function bool RegenerationTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (Unit == none || Unit.IsDead() || Unit.GetCurrentStat(eStat_HP) >= Unit.GetMaxStat(eStat_HP))
		return false;
	// (Set on the effect for this tick only: the same effect serves every unit with the perk.)
	MaxHealAmount = Max(0, (Unit.HighestHP - Unit.LowestHP) / 2);
	if (MaxHealAmount <= 0)
		return false;
	return super.RegenerationTicked(PersistentEffect, ApplyEffectParameters, kNewEffectState, NewGameState, FirstApplication);
}
