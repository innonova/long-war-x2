// XCOM 2's psi check (attacker's psi offence against the target's will) with Long War's will against psi on the target's
// side: Neural Damping (X2Ability_LWStandins.PsiWill). Put on every will-defended psi ability: AddPsiChecks.
class X2AbilityToHitCalc_LWPsiCheck extends X2AbilityToHitCalc_StatCheck_UnitVsUnit;

function int GetDefendValue(XComGameState_Ability kAbility, StateObjectReference TargetRef)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID));
	if (Unit == none)
		return super.GetDefendValue(kAbility, TargetRef);
	return super.GetDefendValue(kAbility, TargetRef) + class'X2Ability_LWStandins'.static.PsiWillOf(Unit);
}
