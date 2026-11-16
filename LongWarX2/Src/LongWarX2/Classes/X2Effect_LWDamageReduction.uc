// Long War's damage reduction (features/lw-damage-reduction.md), on every unit (X2Ability_LWDamageReduction): each hit
// less a fraction of damage, in the order of Long War's XGUnit.AbsorbDamage, the remainder's fraction rounded up by
// chance (1.333 is 1 two times in three, 2 once). XCOM 2's armour stays as it is; Long War's aliens carry none.
class X2Effect_LWDamageReduction extends X2Effect_Persistent;

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState)
{
	local XComGameState_Unit Target;
	local float Left;
	local string Parts;
	local int Rolled;

	Target = XComGameState_Unit(TargetDamageable);
	// (Burning, acid and poison each turn pass by XCOM 2's armour, and by Long War's reduction.)
	if (Target == none || CurrentDamage <= 0 || (WeaponDamageEffect != none && WeaponDamageEffect.bIgnoreArmor))
		return 0;
	Left = class'X2Ability_LWDamageReduction'.static.Absorb(Target, Attacker, AbilityState != none ? AbilityState.GetSourceWeapon() : none, CurrentDamage, Parts);
	if (Left >= CurrentDamage)
		return 0;
	// The preview shows the nearer whole number; the hit itself rolls the fraction.
	if (NewGameState == none)
		return Round(Left) - CurrentDamage;
	Rolled = class'X2Ability_LWDamageReduction'.static.RoundByChance(Left);
	`log("LongWarX2: damage reduction:" @ Target.GetFullName() @ "hit for" @ CurrentDamage $ ", left" @ Left @ "rolled" @ Rolled $ ";" $ Parts, , 'LongWarX2');
	return Rolled - CurrentDamage;
}

defaultproperties
{
	EffectName = "LWX2_DamageReduction"
	DuplicateResponse = eDupe_Ignore
}
