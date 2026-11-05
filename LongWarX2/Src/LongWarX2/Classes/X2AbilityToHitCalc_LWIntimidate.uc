// The chance that a Muton's Intimidate panics the soldier who hurt it (features/lw-aliens.md; EW's XGUnit.Intimidate):
// Chance in 100 that it intimidates (EW's INTIMIDATE_CHANCE_MUTON, _BERSERKER), then the soldier's panic test against the
// morale event's will (EW's eMoraleEvent_MutonIntimidate, 40), failed EvenFail in 100 at even will (EW's PassesWillTest
// for panic) and a point more or less for each point of will under or over it. EW's will test itself is native code not
// read; the line through its even point is an approximation, as the psi powers' will checks are (X2Ability_LWStandins).
class X2AbilityToHitCalc_LWIntimidate extends X2AbilityToHitCalc_StatCheck;

var int Chance, Morale, EvenFail;

function int GetAttackValue(XComGameState_Ability kAbility, StateObjectReference TargetRef)
{
	local XComGameState_Unit Target;

	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID));
	if (Target == none)
		return 0;
	return Chance * Clamp(EvenFail + Morale - int(Target.GetCurrentStat(eStat_Will)), 0, 100) / 100;
}

function int GetDefendValue(XComGameState_Ability kAbility, StateObjectReference TargetRef)
{
	return 0;
}

defaultproperties
{
	BaseValue = 0
}
