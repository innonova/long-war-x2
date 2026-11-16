// The covert operative beside an active EXALT comm relay of a covert extraction, not having hacked one this turn
// (LWX2CovertExtraction).
class X2Condition_LWX2Relay extends X2Condition;

event name MeetsCondition(XComGameState_BaseObject kTarget)
{
	if (class'LWX2CovertExtraction'.static.InReach(XComGameState_Unit(kTarget)) == -1)
		return 'AA_NotInRange';
	return 'AA_Success';
}
