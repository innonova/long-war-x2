// A Long War perk that makes a standard shot free under a condition, once a turn
// (features/lw-classes.md): Hit and Run (an exposed or flanked target), Close Encounters (a
// target within Param tiles), Light 'Em Up (the turn's first action: the shot no longer ends
// the turn, it costs one action); Paramedic (a medikit used, Medikit); Double Tap (the turn's first shot
// leaves the second action, Param turns' cooldown). After XCOM 2 has taken the ability's cost, the action
// points are given back: all of them, or all but one (bKeepOne). And the reaction perks, which give back or
// give a reserve point: Rapid Reaction (a reaction shot that hits keeps the overwatch, Param times a turn),
// Ready for Anything (a shot taken as the turn's first action ends it in overwatch).
class X2Effect_LWFreeShot extends X2Effect_Persistent;

/** TargetExposed, Within, FirstAction (a standard shot); Medikit (a medikit's heal or stabilize); DoubleTap;
 * OverwatchHit (Rapid Reaction); ReadyForAnything. */
var name Condition;
var float Param;
var bool bKeepOne;

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local XComGameState_Unit Target;
	local GameRulesCache_VisibilityInfo VisInfo;
	local UnitValue Used;
	local bool bHolds;

	switch (Condition)
	{
	case 'OverwatchHit':
		return KeepOverwatch(EffectState, AbilityContext, kAbility, SourceUnit, PreCostReservePoints);
	case 'ReadyForAnything':
		return OverwatchAfterShot(kAbility, SourceUnit, PreCostActionPoints);
	case 'DoubleTap':
		return SecondShot(kAbility, SourceUnit, PreCostActionPoints);
	}
	if (SourceUnit.ActionPoints.Length >= PreCostActionPoints.Length)
		return false;
	if (Condition == 'Medikit' ? !IsMedikit(kAbility.GetMyTemplateName()) : kAbility.GetMyTemplateName() != 'StandardShot')
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
	case 'Medikit':
		bHolds = true;
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

/** Rapid Reaction: a reaction shot that hits gives its reserve point back, Param times a turn. */
function bool KeepOverwatch(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, const array<name> PreCostReservePoints)
{
	local UnitValue Used;

	if (!IsReactionShot(kAbility.GetMyTemplateName()) || !AbilityContext.IsResultContextHit() || SourceUnit.ReserveActionPoints.Length >= PreCostReservePoints.Length)
		return false;
	SourceUnit.GetUnitValue(EffectName, Used);
	if (Param > 0 && Used.fValue >= Param)
		return false;
	SourceUnit.ReserveActionPoints = PreCostReservePoints;
	SourceUnit.SetUnitFloatValue(EffectName, Used.fValue + 1, eCleanup_BeginTurn);
	return true;
}

/** Ready for Anything: a shot taken as the turn's first action, the turn over, ends in overwatch. */
function bool OverwatchAfterShot(XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, const array<name> PreCostActionPoints)
{
	if (!IsShot(kAbility.GetMyTemplateName()) || PreCostActionPoints.Length < class'X2CharacterTemplateManager'.default.StandardActionsPerTurn || SourceUnit.ActionPoints.Length > 0)
		return false;
	if (SourceUnit.ReserveActionPoints.Find(class'X2CharacterTemplateManager'.default.OverwatchReserveActionPoint) != INDEX_NONE)
		return false;
	SourceUnit.ReserveActionPoints.AddItem(class'X2CharacterTemplateManager'.default.OverwatchReserveActionPoint);
	return true;
}

/** Double Tap: the turn's first shot leaves the second action; then Param turns before it works again. */
function bool SecondShot(XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, const array<name> PreCostActionPoints)
{
	local XComGameState_Player Player;
	local UnitValue Last;

	if (!IsShot(kAbility.GetMyTemplateName()) || PreCostActionPoints.Length < class'X2CharacterTemplateManager'.default.StandardActionsPerTurn || SourceUnit.ActionPoints.Length >= PreCostActionPoints.Length)
		return false;
	Player = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.ControllingPlayer.ObjectID));
	if (Player == none)
		return false;
	// The turn it was last used, plus one (0: never).
	if (SourceUnit.GetUnitValue(EffectName, Last) && Last.fValue > 0 && Player.PlayerTurnCount - (Last.fValue - 1) < Param)
		return false;
	SourceUnit.ActionPoints = PreCostActionPoints;
	SourceUnit.ActionPoints.Remove(0, 1);
	SourceUnit.SetUnitFloatValue(EffectName, Player.PlayerTurnCount + 1, eCleanup_BeginTactical);
	return true;
}

static function bool IsShot(name Ability)
{
	return Ability == 'StandardShot' || Ability == 'SniperStandardFire' || Ability == 'LW_PrecisionShot' || Ability == 'LW_DisablingShot' || Ability == 'LW_SnapShot';
}

static function bool IsReactionShot(name Ability)
{
	return Ability == 'OverwatchShot' || Ability == 'PistolOverwatchShot' || Ability == 'LongWatchShot';
}

static function bool IsMedikit(name Ability)
{
	return Ability == 'MedikitHeal' || Ability == 'NanoMedikitHeal' || Ability == 'MedikitStabilize';
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
}
