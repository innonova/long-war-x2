// Long War's aliens' damage bonus (features/lw-aliens.md): the automatic upgrades' iDamage reached by the aliens' research
// (LWAlienStats sets it on the alien as its pod spawns, a unit value), added to every damaging attack of the alien's.
class X2Effect_LWAlienDamage extends X2Effect_Persistent;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local UnitValue Bonus;

	if (CurrentDamage <= 0 || !Attacker.GetUnitValue('LWX2DamageBonus', Bonus))
		return 0;
	return int(Bonus.fValue);
}
