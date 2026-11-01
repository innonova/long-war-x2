// A Long War perk that makes a standard shot free under a condition, once a turn
// (features/lw-classes.md): Hit and Run (an exposed or flanked target), Close Encounters (a
// target within Param tiles), Light 'Em Up (the turn's first action: the shot no longer ends
// the turn, it costs one action). After XCOM 2 has taken the shot's cost, the action points are
// given back: all of them, or all but one (bKeepOne).
class X2Effect_LWFreeShot extends X2Effect_Persistent;

/** TargetExposed, Within, FirstAction. */
var name Condition;
var float Param;
var bool bKeepOne;

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local XComGameState_Unit Target;
	local GameRulesCache_VisibilityInfo VisInfo;
	local UnitValue Used;
	local bool bHolds;

	if (kAbility.GetMyTemplateName() != 'StandardShot' || SourceUnit.ActionPoints.Length >= PreCostActionPoints.Length)
		return false;
	if (SourceUnit.GetUnitValue(EffectName, Used) && Used.fValue > 0)
		return false;
	Target = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (Target == none)
		Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	switch (Condition)
	{
	case 'TargetExposed':
		bHolds = Target != none && `TACTICALRULES.VisibilityMgr.GetVisibilityInfo(SourceUnit.ObjectID, Target.ObjectID, VisInfo)
			&& (VisInfo.TargetCover == CT_None || Target.IsFlanked(SourceUnit.GetReference()));
		break;
	case 'Within':
		bHolds = Target != none && SourceUnit.TileDistanceBetween(Target) <= Param;
		break;
	case 'FirstAction':
		bHolds = PreCostActionPoints.Length >= class'X2CharacterTemplateManager'.default.StandardActionsPerTurn;
		break;
	}
	if (!bHolds)
		return false;
	SourceUnit.ActionPoints = PreCostActionPoints;
	if (bKeepOne && SourceUnit.ActionPoints.Length > 0)
		SourceUnit.ActionPoints.Remove(0, 1);
	SourceUnit.SetUnitFloatValue(EffectName, 1, eCleanup_BeginTurn);
	return true;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
}
