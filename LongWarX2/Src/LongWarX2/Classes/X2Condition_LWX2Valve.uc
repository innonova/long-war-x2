// A soldier beside one of Deluge's closed bypass valves, before the transport is secured or the dam breaks (LWX2Deluge).
class X2Condition_LWX2Valve extends X2Condition;

event name MeetsCondition(XComGameState_BaseObject kTarget)
{
	if (class'LWX2Deluge'.static.InReach(XComGameState_Unit(kTarget)) < 0)
		return 'AA_NotInRange';
	return 'AA_Success';
}
