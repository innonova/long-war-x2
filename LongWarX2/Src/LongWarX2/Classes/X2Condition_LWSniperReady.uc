// Long War's sniper rifles fire only with the whole turn left (as XCOM 2's sniper rifle shot), unless the soldier has
// Snap Shot: for the shots the mod adds beside the standard one (X2Ability_LWStandins.ActiveShot: Precision Shot,
// Disabling Shot), which XCOM 2 builds as one-action shots.
class X2Condition_LWSniperReady extends X2Condition;

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Unit;
	local XComGameState_Item Weapon;
	local X2WeaponTemplate Template;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
	Weapon = kAbility.GetSourceWeapon();
	Template = Weapon != none ? X2WeaponTemplate(Weapon.GetMyTemplate()) : none;
	if (Unit == none || Template == none || Template.WeaponCat != 'lw_sniper' || Unit.HasSoldierAbility('LW_SnapShot'))
		return 'AA_Success';
	return Unit.NumActionPoints(class'X2CharacterTemplateManager'.default.StandardActionPoint) >= 2 ? 'AA_Success' : 'AA_CannotAfford_ActionPoints';
}
