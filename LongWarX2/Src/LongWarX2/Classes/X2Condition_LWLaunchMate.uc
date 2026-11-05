// The Floater's Launch only with another Launch-capable alien of its side on the field (features/lw-aliens.md: EW's AI
// launches only with more than one Floater active, XGAIPlayer.UpdateLaunchCandidate).
class X2Condition_LWLaunchMate extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Me, Other;

	Me = XComGameState_Unit(kTarget);
	if (Me == none)
		return 'AA_NotAUnit';
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Other)
		if (Other.ObjectID != Me.ObjectID && Other.IsAlive() && !Other.bRemovedFromPlay && Other.GetTeam() == Me.GetTeam()
			&& Other.FindAbility('LW_Launch').ObjectID > 0)
			return 'AA_Success';
	return 'AA_AbilityUnavailable';
}
