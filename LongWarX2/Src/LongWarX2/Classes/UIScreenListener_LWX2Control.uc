// For development: the control port (LWX2Control) open in every world the game shows a screen in.
class UIScreenListener_LWX2Control extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	class'LWX2Control'.static.Ensure(Screen);
}

defaultproperties
{
	ScreenClass = none;
}
