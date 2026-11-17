// Long War's tactical second-wave options on a unit (features/lw-second-wave.md; X2Ability_LWSecondWave, on every character):
// - #7 Absolutely Critical: a flanking shot's crit bonus Long War's SW_FLANK_CRIT (100) in place of FLANKING_CRIT_BONUS (50)
//   (XGAbility_Targeted: GetFlankingCritBonus): the shooter's flanking crit stat raised by the difference.
class X2Effect_LWSecondWave extends X2Effect_ModifyStats config(LWGear);

/** Long War's SW_FLANK_CRIT and FLANKING_CRIT_BONUS. */
var config int AbsolutelyCriticalFlankCrit, FlankCrit;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local StatChange Change;

	if (class'LWX2SecondWave'.static.On(7))
	{
		Change.StatType = eStat_FlankingCritChance;
		Change.StatAmount = default.AbsolutelyCriticalFlankCrit - default.FlankCrit;
		Change.ModOp = MODOP_Addition;
		NewEffectState.StatChanges.AddItem(Change);
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

defaultproperties
{
	EffectName = "LWX2_SecondWave"
	DuplicateResponse = eDupe_Ignore
}
