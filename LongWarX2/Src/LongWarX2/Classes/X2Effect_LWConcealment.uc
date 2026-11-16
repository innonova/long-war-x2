// Concealment (Long War's Mimetic Skin, ePerk_GeneMod_MimeticSkin; features/lw-classes.md): "When the soldier moves to high
// cover, enemies without special capabilities will not target the soldier. Does not work if any enemies have line of sight
// to the soldier's starting position. Leaving cover, being flanked, firing … will break this concealment." Played with
// XCOM 2's concealment of one unit: a move ending in high cover, no enemy seeing the soldier where it began, hides it; a
// move ending out of high cover breaks it; firing and being seen close break it as XCOM 2's concealment breaks.
class X2Effect_LWConcealment extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local Object EffectObj;

	EffectObj = EffectGameState;
	`XEVENTMGR.RegisterForEvent(EffectObj, 'AbilityActivated', OnMoved, ELD_OnStateSubmitted, , , , EffectObj);
}

static function EventListenerReturn OnMoved(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Effect EffectState;
	local XComGameState_Ability Ability;
	local XComGameStateContext_Ability Context;
	local XComGameState_Unit Me, Before;
	local XComGameState NewGameState;
	local bool bHigh;

	EffectState = XComGameState_Effect(CallbackData);
	Ability = XComGameState_Ability(EventData);
	Context = XComGameStateContext_Ability(GameState.GetContext());
	if (EffectState == none || Ability == none || Context == none || Context.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;
	if (Context.InputContext.SourceObject.ObjectID != EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		return ELR_NoInterrupt;
	if (Context.InputContext.MovementPaths.Length == 0)
		return ELR_NoInterrupt;
	Me = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	if (Me == none || !Me.IsAlive())
		return ELR_NoInterrupt;
	bHigh = Me.GetCoverTypeFromLocation() == CT_Standing;
	if (Me.IsConcealed() && !bHigh)
	{
		// Out of high cover: found.
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Concealment broken");
		XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Me.ObjectID)).SetIndividualConcealment(false, NewGameState);
		`TACTICALRULES.SubmitGameState(NewGameState);
		return ELR_NoInterrupt;
	}
	if (Me.IsConcealed() || !bHigh)
		return ELR_NoInterrupt;
	// Seen where it began (the state before the move), no concealment.
	Before = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Me.ObjectID, , GameState.HistoryIndex - 1));
	if (Before != none && class'X2TacticalVisibilityHelpers'.static.GetNumEnemyViewersOfTarget(Before.ObjectID, GameState.HistoryIndex - 1) > 0)
		return ELR_NoInterrupt;
	if (class'X2TacticalVisibilityHelpers'.static.GetNumEnemyViewersOfTarget(Me.ObjectID) > 0)
		return ELR_NoInterrupt;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Concealment");
	XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Me.ObjectID)).SetIndividualConcealment(true, NewGameState);
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("LongWarX2: Concealment:" @ Me.GetFullName() @ "hidden in high cover", , 'LongWarX2');
	return ELR_NoInterrupt;
}

defaultproperties
{
	EffectName = "LWX2_Concealment"
	DuplicateResponse = eDupe_Ignore
}
