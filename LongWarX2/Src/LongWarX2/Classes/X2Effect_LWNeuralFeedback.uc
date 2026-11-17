// Neural Feedback's answer to a psionic attack (X2Ability_LWNeuralFeedback; XGUnit.ApplyNeuralFeedback): the attacker's
// psionic powers cool down (their own cooldown, at least a turn) and it takes (defender's will x1.3 - its will) / 10, at
// least 1. The defender: the target, when it has the power; else a teammate with it within 8 tiles of the target and in
// its sight who passes a will test against the attacker, the one with the most will of those who pass. Not a defender
// panicking, stunned, bound or hunkered down.
class X2Effect_LWNeuralFeedback extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local Object EffectObj;

	EffectObj = EffectGameState;
	`XEVENTMGR.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted, , , , EffectObj);
}

static function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Effect EffectState;
	local XComGameState_Ability Ability, Power;
	local XComGameStateContext_Ability Context;
	local XComGameState_Unit Me, Attacker, Target, Owner, Helper;
	local array<XComGameState_Unit> Near;
	local XComGameState NewGameState;
	local StateObjectReference Ref;
	local int Damage, Cooldown;

	EffectState = XComGameState_Effect(CallbackData);
	Ability = XComGameState_Ability(EventData);
	Context = XComGameStateContext_Ability(GameState.GetContext());
	if (EffectState == none || Ability == none || Context == none || Context.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;
	if (Ability.GetMyTemplate().AbilitySourceName != 'eAbilitySource_Psionic')
		return ELR_NoInterrupt;
	// (The target as it was before the power: Mind Control has made it the attacker's by the time this is heard.)
	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference, GameState.HistoryIndex - 1));
	Owner = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	Attacker = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	if (Target == none || Owner == none || Attacker == none || !Attacker.IsAlive() || !Attacker.IsEnemyUnit(Target))
		return ELR_NoInterrupt;
	if (Target.ObjectID == Owner.ObjectID)
		Me = Owner;
	else
	{
		// A teammate's: one listener answers for them all (the power's owner with the lowest id near the target), the
		// defender the most willed of those who pass their will test.
		Near = Teammates(Target);
		if (Target.IsUnitAffectedByEffectName(default.EffectName) || Near.Length == 0 || Near[0].ObjectID != Owner.ObjectID)
			return ELR_NoInterrupt;
		foreach Near(Helper)
			if (Able(Helper) && Rand(100) < Clamp(50 + int(Helper.GetCurrentStat(eStat_Will)) - int(Attacker.GetCurrentStat(eStat_Will)), 0, 100)
				&& (Me == none || Helper.GetCurrentStat(eStat_Will) > Me.GetCurrentStat(eStat_Will)))
				Me = Helper;
		if (Me == none)
			return ELR_NoInterrupt;
	}
	if (!Able(Me))
		return ELR_NoInterrupt;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Neural Feedback");
	// Its psionic powers cool down.
	foreach Attacker.Abilities(Ref)
	{
		Power = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Power == none || Power.GetMyTemplate().AbilitySourceName != 'eAbilitySource_Psionic' || Power.GetMyTemplate().AbilityTriggers.Length == 0)
			continue;
		Cooldown = Power.GetMyTemplate().AbilityCooldown != none ? Power.GetMyTemplate().AbilityCooldown.iNumTurns : 0;
		Power = XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', Power.ObjectID));
		Power.iCooldown = Max(Power.iCooldown, Max(1, Cooldown));
	}
	// And it is hurt.
	Damage = Max(1, int((Me.GetCurrentStat(eStat_Will) * 1.3 - Attacker.GetCurrentStat(eStat_Will)) / 10));
	Attacker = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Attacker.ObjectID));
	Attacker.TakeDamage(NewGameState, Damage, 0, 0);
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("LongWarX2: Neural Feedback:" @ Me.GetFullName() @ (Me.ObjectID != Target.ObjectID ? "(for" @ Target.GetFullName() $ ")" : "") @ "hurt" @ Attacker.GetMyTemplateName() @ "by" @ Damage $ ", its psionic powers cooling down", , 'LongWarX2');
	return ELR_NoInterrupt;
}

/** The target's teammates with the power within 8 tiles of it and in its sight (XGUnit.m_arrVisibleFriends), by id. */
static function array<XComGameState_Unit> Teammates(XComGameState_Unit Target)
{
	local array<XComGameState_Unit> Out;
	local XComGameState_Unit Unit;
	local GameRulesCache_VisibilityInfo Info;
	local int i;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.ObjectID == Target.ObjectID || Unit.GetTeam() != Target.GetTeam() || !Unit.IsAlive() || Unit.bRemovedFromPlay
			|| !Unit.IsUnitAffectedByEffectName(default.EffectName))
			continue;
		if (VSize(`XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation) - `XWORLD.GetPositionFromTileCoordinates(Target.TileLocation)) >= 8 * class'XComWorldData'.const.WORLD_StepSize)
			continue;
		if (!`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Target.ObjectID, Unit.ObjectID, Info) || !Info.bVisibleGameplay)
			continue;
		for (i = 0; i < Out.Length && Out[i].ObjectID < Unit.ObjectID; i++);
		Out.InsertItem(i, Unit);
	}
	return Out;
}

/** A defender who can answer: alive, not panicking, stunned, bound or hunkered down (IsAliveAndWell and its checks). */
static function bool Able(XComGameState_Unit Unit)
{
	return Unit != none && Unit.IsAlive() && !Unit.IsPanicked() && !Unit.IsStunned() && !Unit.IsUnitAffectedByEffectName('Bind')
		&& !Unit.IsUnitAffectedByEffectName('HunkerDown');
}

defaultproperties
{
	EffectName = "LWX2_NeuralFeedback"
	DuplicateResponse = eDupe_Ignore
}
