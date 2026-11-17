// Taking off or landing (X2Ability_LWFlight): the unit flying or not, and for taking off fuel enough (Long War's
// CanSatisfyHoverRequirements: two or more).
class X2Condition_LWFlight extends X2Condition;

var bool bWantFlying;
var int MinFuel;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(kTarget);
	if (Unit == none)
		return 'AA_NotAUnit';
	if (Unit.IsUnitAffectedByEffectName(class'X2Effect_LWFlying'.default.EffectName) != bWantFlying)
		return bWantFlying ? 'AA_UnitIsNotFlying' : 'AA_UnitIsFlying';
	return 'AA_Success';
}

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{
	if (MinFuel > 0 && kAbility != none && kAbility.GetCharges() < MinFuel)
		return 'AA_CannotAfford_Charges';
	return 'AA_Success';
}
