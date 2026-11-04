// Long War's aliens' damage (features/lw-aliens.md): an alien's shots with its own weapon (the XCOM 2 template's, shared by
// every species that fights as it) shifted from that weapon's base damage to its species' Long War weapon's
// (LWX2WeaponDamage), plus the difficulty's and the research upgrades' bonus (LWX2DamageBonus) on every damaging attack;
// both set on the alien as its pod spawns (LWAlienStats). XCOM 2's damage spread and crit damage stay.
class X2Effect_LWAlienDamage extends X2Effect_Persistent;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local UnitValue Bonus, LWDamage;
	local XComGameState_Item Source;
	local X2WeaponTemplate Weapon;
	local int Shift;

	if (CurrentDamage <= 0)
		return 0;
	if (Attacker.GetUnitValue('LWX2DamageBonus', Bonus))
		Shift = int(Bonus.fValue);
	Source = AbilityState != none ? AbilityState.GetSourceWeapon() : none;
	Weapon = Source != none ? X2WeaponTemplate(Source.GetMyTemplate()) : none;
	// Its weapon, not a grenade or other item: the primary or the melee weapon.
	if (Weapon != none && Attacker.GetUnitValue('LWX2WeaponDamage', LWDamage) && Weapon.WeaponCat != 'grenade'
		&& (Source.InventorySlot == eInvSlot_PrimaryWeapon || Source.InventorySlot == eInvSlot_SecondaryWeapon))
		Shift += int(LWDamage.fValue) - Weapon.BaseDamage.Damage;
	// Never below 1 damage for a hit.
	return Max(Shift, 1 - CurrentDamage);
}
