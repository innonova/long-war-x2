// XCOM 2's 3D screens (the armory and its loadout, promotion, the soldier's screens) draw onto display meshes in the Avenger's
// rooms (UIDisplay_LevelActor, shown by UIMovie_3D.ShowDisplay, which only unhides them). While EW's base is in view, every
// other streamed level is hidden (LWX2EWBase.HideWorld), and the engine detaches the meshes of the actors those levels hold;
// shown again, the display meshes XCOM 2's blueprints placed stayed detached, so the armory came up with the soldier and no
// menu (found 2026-11-16, features/lw-squad-select.md). Whenever a 3D screen opens or comes back, the display meshes not
// attached are attached again for a few seconds (LWX2DisplayWatch: the screen's own is placed a moment later; a hidden display
// stays hidden).
class UIScreenListener_LWX2Displays extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	Reattach(Screen);
}

event OnReceiveFocus(UIScreen Screen)
{
	Reattach(Screen);
}

static function Reattach(UIScreen Screen)
{
	// (Any of the strategy layer's screens: the armory's own may not say it is a 3D screen yet when it opens.)
	if (Screen != none && `HQPRES != none)
		class'LWX2DisplayWatch'.static.Watch(Screen);
}

defaultproperties
{
	ScreenClass = none;
}
