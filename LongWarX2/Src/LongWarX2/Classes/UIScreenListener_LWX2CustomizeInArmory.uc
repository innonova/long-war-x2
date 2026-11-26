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
	C.UpdateData();
	`log("LongWarX2: XCOM 2's Customize told it is in the armory:" @ Screen.Class.Name, , 'LongWarX2');
	// OPEN: straight from EW's soldier summary its navigation (back, the soldiers before and after, on XCOM 2's HUD's
	// helpBarMC) is not drawn, though every clip up to the root is visible; after XCOM 2's loadout it is. Showing the HUD
	// and the help and making the help again changed nothing (features/strategy-flow.md).
}

defaultproperties
{
	ScreenClass = none;
}
