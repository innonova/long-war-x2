// Long War's Shredder Ammo (features/lw-classes.md): a unit hit by a Gunner's LMG or SAW or by a Rocketeer's rocket
// from a soldier with the perk takes Pct % more damage from every source for Duration turns. EW applies its shred in
// native code; its factor here is EW's documented one (APPROXIMATION).
class X2Effect_LWShredded extends X2Effect_Persistent;

var int Pct;

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState)
{
	return CurrentDamage > 0 ? Max(1, CurrentDamage * Pct / 100) : 0;
}

defaultproperties
{
	EffectName = "LWShredded"
	DuplicateResponse = eDupe_Refresh
}
