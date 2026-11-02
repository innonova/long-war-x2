// Long War's Distortion Field: allies in cover near the psion get defence (DISTORTIONFIELD_DEFENSE within
// DISTORTIONFIELD_RADIUS; X2Ability_LWStandins.AuraDefenseAt). XCOM 2 has no auras: every Long War soldier carries this
// effect (X2Ability_LWArmorStats), and it asks, as the soldier is shot at, whether such a psion is near. In cover means
// as XCOM 2's aim counts it: cover against this attacker.
class X2Effect_LWDistortionField extends X2Effect_Persistent;

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local GameRulesCache_VisibilityInfo VisInfo;
	local ShotModifierInfo Mod;
	local int Defense;

	if (bMelee || bFlanking || Attacker == none || !Target.CanTakeCover())
		return;
	if (!`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo) || VisInfo.TargetCover == CT_None)
		return;
	Defense = class'X2Ability_LWStandins'.static.AuraDefenseAt(Target);
	if (Defense <= 0)
		return;
	Mod.ModType = eHit_Success;
	Mod.Value = -Defense;
	Mod.Reason = class'X2Ability_LWStandins'.static.PsiPowerName('LW_DistortionField');
	ShotModifiers.AddItem(Mod);
}

defaultproperties
{
	EffectName = "LWDistortionField"
	DuplicateResponse = eDupe_Ignore
}
