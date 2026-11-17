// A soldier beside Furies' command console while it is still on (LWX2Furies).
class X2Condition_LWX2Console extends X2Condition;

event name MeetsCondition(XComGameState_BaseObject kTarget)
{
	if (!class'LWX2Furies'.static.InReach(XComGameState_Unit(kTarget)))
		return 'AA_NotInRange';
	return 'AA_Success';
}
