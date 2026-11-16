// A thrown or launched explosive's aim (features/lw-classes.md), as Long War reaches it (its repurposed
// XGUnit.GetMoveModifierCost): XCOM 2's cursor within the weapon's range, times
// - a grenade (thrown or launched): Bombard x1.4, else Grenadier x1.2;
// - a rocket: Javelin Rockets x1.25; after moving x0.4, or x0.6 with Snap Shot.
class X2AbilityTarget_LWRangeCursor extends X2AbilityTarget_Cursor config(LWClasses);

/** 'Grenade' or 'Rocket'. */
var name Kind;
var config float BombardRange, GrenadierRange, JavelinRange, MovedRocketRange, SnapShotRocketRange;

static function float Factor(XComGameState_Unit Unit, name WhatKind)
{
	local float F;

	F = 1.0;
	if (Unit == none)
		return F;
	if (WhatKind == 'Grenade')
	{
		if (Unit.HasSoldierAbility('LW_Bombard'))
			F *= default.BombardRange;
		else if (Unit.HasSoldierAbility('LW_Grenadier'))
			F *= default.GrenadierRange;
	}
	if (WhatKind == 'Rocket')
	{
		if (Unit.HasSoldierAbility('LW_JavelinRockets'))
			F *= default.JavelinRange;
		// (Moved: fewer than XCOM 2's two actions left, as the scatter reads it.)
		if (Unit.ActionPoints.Length < 2)
			F *= Unit.HasSoldierAbility('LW_SnapShotRocket') ? default.SnapShotRocketRange : default.MovedRocketRange;
	}
	return F;
}

simulated function float GetCursorRangeMeters(XComGameState_Ability AbilityState)
{
	local XComGameState_Unit Unit;

	Unit = AbilityState != none ? XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID)) : none;
	return super.GetCursorRangeMeters(AbilityState) * Factor(Unit, Kind);
}

defaultproperties
{
	BombardRange = 1.4
	GrenadierRange = 1.2
	JavelinRange = 1.25
	MovedRocketRange = 0.4
	SnapShotRocketRange = 0.6
}
