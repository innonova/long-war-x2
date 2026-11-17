// Alien Containment in the base (Long War's XGFacility_Lockers.EquipSmallItem: no arc thrower without it): the arc thrower's
// stun is not offered in a mission without one. A campaign without its base yet, or a mission outside a campaign, has it.
class X2Condition_LWContainment extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.TileFacility.Length == 0 || class'LWBase'.static.Count(S, 13) > 0)
		return 'AA_Success';
	return 'AA_AbilityUnavailable';
}
