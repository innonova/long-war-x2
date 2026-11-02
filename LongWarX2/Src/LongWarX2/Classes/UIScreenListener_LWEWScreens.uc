// Enemy Within's own screens in place of XCOM 2's (features/lw-ew-screens.md), where the converted EW UI package is in
// the mod's Content (tools/convert/ew-ui.ts); without it XCOM 2's screens stay. So far: research, the strategy HUD.
class UIScreenListener_LWEWScreens extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	// EW's resource bar over the Avenger, from the first of the port's strategy screens.
	if (UILWGeoscape(Screen) != none || UILWBase(Screen) != none || UILWEngineering(Screen) != none || UILWHangar(Screen) != none || UIAvengerHUD(Screen) != none)
		class'UILWEWStrategyHUD'.static.ShowIfAvailable();
	if (UIChooseResearch(Screen) != none && !UIChooseResearch(Screen).bShadowChamber && class'UILWEWScreen'.static.HasEWScreens())
	{
		Screen.CloseScreen();
		class'UILWEWResearch'.static.Open();
	}
}

defaultproperties
{
	ScreenClass = none;
}
