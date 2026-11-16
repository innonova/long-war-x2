// Long War's ammo (XGAbility_Targeted.GraduatedOdds; features/lw-gear.md, lw-classes.md): a shot with the primary weapon
// pays its round once in 1 + the soldier's adjustments: Lock N' Load +1, the Hi-Cap Mags +1, the Drum Mags +2 (their
// LWSmallDef's Ammo less one). The others are given their round back. One effect per soldier, so the adjustments add up.
class X2Effect_LWAmmoOdds extends X2Effect_Persistent dependson(LWGearRules);

/** 1 + the soldier's adjustments. */
static function int Odds(XComGameState_Unit Unit)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;
	local LWGearRules.LWSmallDef D;
	local int n;

	n = 1;
	if (Unit.HasSoldierAbility('LW_LockNLoad'))
		n++;
	Items = Unit.GetAllInventoryItems(, true);
	foreach Items(Item)
		if (class'LWGearRules'.static.SmallFor(Item.GetMyTemplateName(), D) && D.Ammo > 1)
			n += D.Ammo - 1;
	return n;
}

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local UnitValue Shots;
	local XComGameState_Unit Unit;
	local int n;

	if (AffectWeapon == none || AffectWeapon.InventorySlot != eInvSlot_PrimaryWeapon)
		return false;
	if (AbilityContext.InputContext.SourceObject.ObjectID != EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		return false;
	n = Odds(SourceUnit);
	if (n <= 1)
		return false;
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', SourceUnit.ObjectID));
	Unit.GetUnitValue('LWAmmoShots', Shots);
	Unit.SetUnitFloatValue('LWAmmoShots', Shots.fValue + 1, eCleanup_BeginTactical);
	// One shot in n pays; the others are given their round back.
	if (int(Shots.fValue) % n != 0)
	{
		AffectWeapon = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', AffectWeapon.ObjectID));
		AffectWeapon.Ammo = Min(AffectWeapon.Ammo + 1, AffectWeapon.GetClipSize());
	}
	return false;
}

defaultproperties
{
	EffectName = "LWX2_AmmoOdds"
	DuplicateResponse = eDupe_Ignore
}
