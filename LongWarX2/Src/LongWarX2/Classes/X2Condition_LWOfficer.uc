// The officers' conditions (features/lw-officers.md). Kind:
//   Leader: the unit is its squad's leader (LWX2SquadLeader, marked at launch);
//   Near: the target is within Tiles of the source (the leader), not the source itself;
//   CommandTarget: the target's turn is done (no action points, none held for overwatch), not hunkered down, not a robot.
class X2Condition_LWOfficer extends X2Condition;

var name Kind;
var int Tiles;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(kTarget);
	if (Unit == none)
		return 'AA_NotAUnit';
	if (Kind == 'Leader')
		return (class'LWOfficers'.static.ValueOf(Unit, 'LWX2SquadLeader') == Unit.ObjectID) ? 'AA_Success' : 'AA_AbilityUnavailable';
	if (Kind == 'CommandTarget')
	{
		if (Unit.NumAllActionPoints() > 0 || Unit.ReserveActionPoints.Length > 0)
			return 'AA_UnitIsNotImpaired';
		if (Unit.IsUnitAffectedByEffectName('HunkerDown') || Unit.IsRobotic())
			return 'AA_UnitIsNotImpaired';
	}
	return 'AA_Success';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit Unit, Source;

	if (Kind != 'Near')
		return 'AA_Success';
	Unit = XComGameState_Unit(kTarget);
	Source = XComGameState_Unit(kSource);
	if (Unit == none || Source == none || Unit.ObjectID == Source.ObjectID || Unit.TileDistanceBetween(Source) > Tiles)
		return 'AA_NotInRange';
	return 'AA_Success';
}
