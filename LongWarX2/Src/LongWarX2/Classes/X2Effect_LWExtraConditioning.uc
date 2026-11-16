// Extra Conditioning (features/lw-classes.md; Long War's XGTacticalGameCore.GetExtraArmorStatBonus): extra hit points by the
// armour worn, heavier armour more (Armors: Long War's armour item and its HP).
class X2Effect_LWExtraConditioning extends X2Effect_ModifyStats config(LWClasses);

struct LWArmorHP
{
	var int Armor;
	var int HP;
};
var config array<LWArmorHP> ExtraConditioning;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Unit;
	local XComGameState_Item Armor;
	local StatChange Change;
	local string Name;
	local int k;

	Unit = XComGameState_Unit(kNewTargetState);
	Armor = Unit != none ? Unit.GetItemInSlot(eInvSlot_Armor, NewGameState) : none;
	Name = Armor != none ? string(Armor.GetMyTemplateName()) : "";
	// (Long War's armours are LWArmor_<its item number>.)
	k = Left(Name, 8) == "LWArmor_" ? default.ExtraConditioning.Find('Armor', int(Mid(Name, 8))) : INDEX_NONE;
	if (k != INDEX_NONE)
	{
		Change.StatType = eStat_HP;
		Change.StatAmount = default.ExtraConditioning[k].HP;
		Change.ModOp = MODOP_Addition;
		NewEffectState.StatChanges.AddItem(Change);
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
	`log("LongWarX2: Extra Conditioning:" @ (Unit != none ? Unit.GetFullName() : "?") @ "in" @ Name @ "+" $ (k != INDEX_NONE ? default.ExtraConditioning[k].HP : 0) @ "HP", , 'LongWarX2');
}

defaultproperties
{
	EffectName = "LWX2_ExtraConditioning"
	DuplicateResponse = eDupe_Ignore
}
