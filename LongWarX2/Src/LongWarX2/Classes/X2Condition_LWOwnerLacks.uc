// The ability's owner lacks this ability (Revive: the medikit's stabilize leaves the soldier unconscious only for a
// medic without it). X2Condition_AbilityProperty asks for abilities the owner has; this is its opposite.
class X2Condition_LWOwnerLacks extends X2Condition;

var name Ability;

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Owner;

	Owner = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
	return (Owner != none && Owner.HasSoldierAbility(Ability)) ? 'AA_AbilityUnavailable' : 'AA_Success';
}
