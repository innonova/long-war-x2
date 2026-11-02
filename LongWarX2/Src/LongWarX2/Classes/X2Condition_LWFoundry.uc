// A Foundry project done in the campaign (features/lw-research.md): Improved Medikit's heal applies only then.
class X2Condition_LWFoundry extends X2Condition;

var int Foundry;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	return class'X2Effect_LWFoundry'.static.Done(Foundry) ? 'AA_Success' : 'AA_AbilityUnavailable';
}
