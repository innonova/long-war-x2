// A soldier beside the Chryssalid hive's transponder while it waits to be reactivated (LWX2ChryssalidHive).
class X2Condition_LWX2Transponder extends X2Condition;

event name MeetsCondition(XComGameState_BaseObject kTarget)
{
	if (!class'LWX2ChryssalidHive'.static.InReach(XComGameState_Unit(kTarget)))
		return 'AA_NotInRange';
	return 'AA_Success';
}
