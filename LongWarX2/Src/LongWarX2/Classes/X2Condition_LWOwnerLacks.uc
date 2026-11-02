// The ability's owner lacks this ability (Revive: the medikit's stabilize leaves the soldier unconscious only for a
// medic without it). X2Condition_AbilityProperty asks for abilities the owner has; this is its opposite. With bTarget, the
// target lacks it (Bioelectric Skin: XCOM 2's Bind not against its soldier).
class X2Condition_LWOwnerLacks extends X2Condition;

var name Ability;
var bool bTarget;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Unit;

	if (!bTarget)
		return 'AA_Success';
	Unit = XComGameState_Unit(kTarget);
	return (Unit != none && Unit.HasSoldierAbility(Ability)) ? 'AA_UnitIsImmune' : 'AA_Success';
}

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Owner;

	if (bTarget)
		return 'AA_Success';
	Owner = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
	return (Owner != none && Owner.HasSoldierAbility(Ability)) ? 'AA_AbilityUnavailable' : 'AA_Success';
}
