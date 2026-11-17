// XCOM 2 registers the strategy event listener templates (X2EventListenerTemplateManager.RegisterStrategyListeners) only
// on the way back from a mission (XGStrategy's return from tactical): a new campaign or a loaded save has none until then.
// Long War's own (X2EventListener_LWStrategy) are needed from the start, so all are registered again as the Avenger's HUD
// comes up, once a strategy session (the manager unregisters every template's listeners first, so this does not double them).
class UIScreenListener_LWX2StrategyEvents extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	if (UIAvengerHUD(Screen) != none)
		class'X2EventListenerTemplateManager'.static.RegisterStrategyListeners();
}

defaultproperties
{
	ScreenClass = none;
}
