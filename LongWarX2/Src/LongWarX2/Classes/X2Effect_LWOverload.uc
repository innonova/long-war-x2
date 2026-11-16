// The Drone's Overload blast (EW's death explosion for the Drone, XComAlienPawn.GetDeathExplosionDamage: half its maximum
// health, at least OverloadMin, at most OverloadMax).
class X2Effect_LWOverload extends X2Effect_ApplyWeaponDamage;

function WeaponDamageValue GetBonusEffectDamageValue(XComGameState_Ability AbilityState, XComGameState_Unit SourceUnit, XComGameState_Item SourceWeapon, StateObjectReference TargetRef)
{
	local WeaponDamageValue Value;

	Value.Damage = Clamp(int(SourceUnit.GetMaxStat(eStat_HP)) / 2, class'X2Ability_LWAliens'.default.OverloadMin, class'X2Ability_LWAliens'.default.OverloadMax);
	return Value;
}

defaultproperties
{
	bIgnoreBaseDamage = true
	EnvironmentalDamageAmount = 10
}
