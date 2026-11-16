// Lead By Example (features/lw-officers.md): a soldier near the squad's leader with lower will uses the leader's (Long War's
// text: "substitutes his or her Will for that of all nearby lower-Will squadmates"). Applied by the leader's ability as each
// XCOM turn begins and ends, after the last one is taken off: the will raised by the difference.
class X2Effect_LWLeadByExample extends X2Effect_ModifyStats;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Unit, Leader;
	local StatChange Change;

	Unit = XComGameState_Unit(kNewTargetState);
	Leader = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (Leader == none)
		Leader = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (Unit != none && Leader != none && Leader.GetCurrentStat(eStat_Will) > Unit.GetCurrentStat(eStat_Will))
	{
		Change.StatType = eStat_Will;
		Change.StatAmount = Leader.GetCurrentStat(eStat_Will) - Unit.GetCurrentStat(eStat_Will);
		NewEffectState.StatChanges.AddItem(Change);
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

defaultproperties
{
	EffectName = "LWX2_LeadByExampleWill"
	DuplicateResponse = eDupe_Ignore
}
