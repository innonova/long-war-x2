// The rocket launcher's aim (features/lw-classes.md): XCOM 2's cursor within the weapon's range, a quarter farther with
// Javelin Rockets (Long War's XGAction_Targeting.SetChainedDistance: the rocket's distance x 1.25 with the perk).
class X2AbilityTarget_LWRocketCursor extends X2AbilityTarget_Cursor config(LWClasses);

var config float JavelinRange;

simulated function float GetCursorRangeMeters(XComGameState_Ability AbilityState)
{
	local XComGameState_Unit Unit;
	local float Range;

	Range = super.GetCursorRangeMeters(AbilityState);
	Unit = AbilityState != none ? XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID)) : none;
	if (Unit != none && Unit.HasSoldierAbility('LW_JavelinRockets'))
		Range *= (JavelinRange > 0 ? JavelinRange : 1.25);
	return Range;
}

defaultproperties
{
	JavelinRange = 1.25
}
