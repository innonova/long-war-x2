// Long War's rules that follow XCOM 2's strategy events (registered from the start of a strategy session:
// UIScreenListener_LWX2StrategyEvents).
// - UnitRankUp: Long War's gains on promotion (LWX2StatGains), in a game state of their own after the promotion's.
class X2EventListener_LWStrategy extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2EventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'LWX2_StrategyRules');
	Template.RegisterInStrategy = true;
	Template.AddEvent('UnitRankUp', OnRankUp);
	Templates.AddItem(Template);
	// (In missions: a soldier who resists an alien psi attack gains psi experience, features/lw-psi.md.)
	`CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'LWX2_TacticalPsiXP');
	Template.RegisterInTactical = true;
	Template.AddEvent('AbilityActivated', OnPsiAttack);
	Templates.AddItem(Template);
	return Templates;
}

static function EventListenerReturn OnRankUp(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit Unit, Before;
	local XComGameState NewGameState;

	Unit = XComGameState_Unit(EventData);
	if (Unit == none || GameState == none)
		return ELR_NoInterrupt;
	// The rank before the promotion's game state (one state can hold several rank-ups: each rank's gain rolled once).
	Before = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID, , GameState.HistoryIndex - 1));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: gains on promotion");
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	if (class'LWX2StatGains'.static.RankedUp(Unit, Before != none ? Before.GetRank() : 0))
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	else
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	return ELR_NoInterrupt;
}

/** An alien's psionic ability that missed an XCOM soldier (XGAbilityTree: the ability failed against a soldier, CalcXP event
 *  7): the soldier gains Long War's psi experience for resisting it (PsiResistXP). */
static function EventListenerReturn OnPsiAttack(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Ability Ability;
	local XComGameStateContext_Ability Context;
	local XComGameState_Unit Attacker, Target;
	local XComGameState NewGameState;
	local int XP;

	Ability = XComGameState_Ability(EventData);
	Context = XComGameStateContext_Ability(GameState.GetContext());
	if (Ability == none || Context == none || Context.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;
	if (Ability.GetMyTemplate().AbilitySourceName != 'eAbilitySource_Psionic' || !Context.IsResultContextMiss())
		return ELR_NoInterrupt;
	Attacker = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
	if (Attacker == none || Target == none || Attacker.GetTeam() != eTeam_Alien || Target.GetTeam() != eTeam_XCom || !Target.IsSoldier() || Target.IsRobotic())
		return ELR_NoInterrupt;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: psi experience, a psi attack resisted");
	Target = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Target.ObjectID));
	XP = class'XComGameState_LWStrategy'.static.AddPsiXP(Target, class'LWBaseRules'.default.PsiResistXP, NewGameState);
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("LongWarX2: psi:" @ Target.GetFullName() @ "resisted" @ Ability.GetMyTemplateName() @ "+" $ XP @ "psi XP", , 'LongWarX2');
	return ELR_NoInterrupt;
}
