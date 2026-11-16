// Neural Feedback's answer to a psionic attack (X2Ability_LWNeuralFeedback; XGUnit.ApplyNeuralFeedback): the attacker's
// psionic powers cool down (their own cooldown, at least a turn) and it takes (defender's will x1.3 - its will) / 10, at
// least 1.
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
	local XComGameState_Unit Me, Attacker;
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
	if (Context.InputContext.PrimaryTarget.ObjectID != EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		return ELR_NoInterrupt;
	Me = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	Attacker = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	if (Me == none || Attacker == none || !Me.IsAlive() || !Attacker.IsAlive() || !Attacker.IsEnemyUnit(Me))
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
	`log("LongWarX2: Neural Feedback:" @ Me.GetFullName() @ "hurt" @ Attacker.GetMyTemplateName() @ "by" @ Damage $ ", its psionic powers cooling down", , 'LongWarX2');
	return ELR_NoInterrupt;
}

defaultproperties
{
	EffectName = "LWX2_NeuralFeedback"
	DuplicateResponse = eDupe_Ignore
}
