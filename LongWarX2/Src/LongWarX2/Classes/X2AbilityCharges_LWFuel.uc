// Flight's fuel as the fly ability's charges (X2Ability_LWFlight): the armour's or the SHIV deck's, for each mission.
class X2AbilityCharges_LWFuel extends X2AbilityCharges;

function int GetInitialCharges(XComGameState_Ability Ability, XComGameState_Unit Unit)
{
	return class'X2Ability_LWFlight'.static.MaxFuel(Unit);
}
