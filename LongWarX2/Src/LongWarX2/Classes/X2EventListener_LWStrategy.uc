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
