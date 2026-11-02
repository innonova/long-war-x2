// The Foundry's projects that change a soldier in missions (features/lw-research.md), once done in the campaign
// (Long War's campaign state comes into the mission with the rest of the strategy game). Long War's texts and EW's
// constants give the numbers:
// - Mag Pistols (13): pistols +25 critical chance (PISTOL_I_CRIT_BONUS);
// - Rail Pistols (14): pistols +15 aim (its constant is named for defence, PISTOL_II_DEF_BONUS; its text: aim);
// - Reflex Pistols (15): pistols +1 damage ("an increase in the maximum damage output").
// Carried by every Long War armour's stat ability (X2Ability_LWArmorStats). Improved Medikit is a heal added to the
// medikit (X2Ability_LWStandins.AddHealBonuses).
class X2Effect_LWFoundry extends X2Effect_Persistent dependson(LWGearRules);

var int PistolCrit, PistolAim, PistolDamage;

static function bool Done(int Foundry)
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	return S != none && S.FoundryDone.Find(Foundry) != INDEX_NONE;
}

/** Long War's pistols (its weapons of the Pistol family). */
static function bool IsPistol(XComGameState_Item Weapon)
{
	local LWGearRules.LWWeaponDef W;
	local string TemplateName;

	if (Weapon == none)
		return false;
	TemplateName = string(Weapon.GetMyTemplateName());
	if (Left(TemplateName, 9) != "LWWeapon_")
		return false;
	foreach class'LWGearRules'.default.Weapons(W)
		if (W.Item == int(Mid(TemplateName, 9)))
			return W.Family == 'Pistol';
	return false;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo Mod;

	if (AbilityState == none || !IsPistol(AbilityState.GetSourceWeapon()))
		return;
	if (Done(13))
	{
		Mod.ModType = eHit_Crit;
		Mod.Value = PistolCrit;
		Mod.Reason = class'LWEngineering'.static.FoundryName(13);
		ShotModifiers.AddItem(Mod);
	}
	if (Done(14))
	{
		Mod.ModType = eHit_Success;
		Mod.Value = PistolAim;
		Mod.Reason = class'LWEngineering'.static.FoundryName(14);
		ShotModifiers.AddItem(Mod);
	}
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	if (CurrentDamage > 0 && AbilityState != none && Done(15) && IsPistol(AbilityState.GetSourceWeapon()))
		return PistolDamage;
	return 0;
}

defaultproperties
{
	EffectName = "LWFoundry"
	DuplicateResponse = eDupe_Ignore
	PistolCrit = 25
	PistolAim = 15
	PistolDamage = 1
}
