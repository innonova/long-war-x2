// XCOM 2's Customize opened from EW's soldier summary (features/strategy-flow.md): XCOM 2 takes it for its armory only with
// its own armory screen on the stack (UICustomize.InitScreen: bInArmory), which EW's summary replaces, and showed its
// character pool's options instead (Change Soldier Type, Can Appear as VIP …; the click tests' customize.png). In a
// campaign at headquarters it is the armory's: told so, and its menu made again (UpdateData hides and rebuilds it).
class UIScreenListener_LWX2CustomizeInArmory extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UICustomize C;

	C = UICustomize(Screen);
	if (C == none || C.bInArmory || XComHQPresentationLayer(Screen.Movie.Pres) == none)
		return;
	C.bInArmory = true;
	// And the armory's navigation (back, the soldiers before and after): InitScreen took the presentation layer's own help
	// for a screen outside the armory, which the strategy layer does not draw, and kept it. (aek 2026-11-28: "back button
	// on customize screen does not work"; the HUD's help, as UICustomize.InitScreen takes it in the armory.)
	if (C.NavHelp != XComHQPresentationLayer(Screen.Movie.Pres).m_kAvengerHUD.NavHelp)
	{
		C.NavHelp.ClearButtonHelp();
		C.NavHelp = XComHQPresentationLayer(Screen.Movie.Pres).m_kAvengerHUD.NavHelp;
	}
	C.UpdateData();
	C.UpdateNavHelp();
	`log("LongWarX2: XCOM 2's Customize told it is in the armory:" @ Screen.Class.Name, , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = none;
}
