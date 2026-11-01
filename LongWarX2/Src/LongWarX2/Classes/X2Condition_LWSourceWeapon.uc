// The ability's weapon is of one of these categories (Shredder Ammo: the Gunner's LMGs and SAWs, the rocket launcher).
class X2Condition_LWSourceWeapon extends X2Condition;

var array<name> Categories;

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{
	local XComGameState_Item Weapon;
	local X2WeaponTemplate Template;

	Weapon = kAbility.GetSourceWeapon();
	Template = Weapon != none ? X2WeaponTemplate(Weapon.GetMyTemplate()) : none;
	return (Template != none && Categories.Find(Template.WeaponCat) != INDEX_NONE) ? 'AA_Success' : 'AA_WeaponIncompatible';
}
