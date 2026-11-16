// Mobile cover on a shot (X2Ability_LWMobileCover): a soldier beside the Alloy SHIV, on the side the shot comes from, is
// as in high cover against it: the attacker's aim less XCOM 2's high cover bonus, less what cover the soldier has
// already; flanked, not flanked (the attacker's flanking aim and crit taken off again). Not for melee or a shot that
// falls from above (as cover).
class X2Effect_LWMobileCover extends X2Effect_Persistent;

var localized string MobileCoverReason;

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo Mod;
	local ECoverType Seen;
	local int Had;

	if (bMelee || bIndirectFire || Attacker == none || Target == none || ClassIsChildOf(ToHitType, class'X2AbilityToHitCalc_StandardAim') == false)
		return;
	if (class'X2Ability_LWMobileCover'.static.CoverAgainst(Target, Attacker, Seen) != CT_Standing || Seen == CT_Standing)
		return;
	Mod.Reason = MobileCoverReason != "" ? MobileCoverReason : "Mobile cover";
	Mod.ModType = eHit_Success;
	Had = 0;
	if (Seen == CT_MidLevel && !bFlanking)
		Had = class'X2AbilityToHitCalc_StandardAim'.default.LOW_COVER_BONUS;
	Mod.Value = -(class'X2AbilityToHitCalc_StandardAim'.default.HIGH_COVER_BONUS - Had);
	ShotModifiers.AddItem(Mod);
	if (bFlanking)
	{
		Mod.Value = -int(Attacker.GetCurrentStat(eStat_FlankingAimBonus));
		if (Mod.Value != 0)
			ShotModifiers.AddItem(Mod);
		Mod.ModType = eHit_Crit;
		Mod.Value = -int(Attacker.GetCurrentStat(eStat_FlankingCritChance));
		if (Mod.Value != 0)
			ShotModifiers.AddItem(Mod);
	}
}

defaultproperties
{
	EffectName = "LWX2_MobileCover"
	DuplicateResponse = eDupe_Ignore
}
