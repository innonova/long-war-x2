// A soldier beside an active power node, or beside the bomb (bBomb), of a council bomb disposal (LWX2CouncilBomb).
class X2Condition_LWX2BombPart extends X2Condition;

var bool bBomb;

event name MeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(kTarget);
	if (Unit == none || class'LWX2CouncilBomb'.static.InReach(Unit.TileLocation, bBomb) == -1)
		return 'AA_NotInRange';
	return 'AA_Success';
}
