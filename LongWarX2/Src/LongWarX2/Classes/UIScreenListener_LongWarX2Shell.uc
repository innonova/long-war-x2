// The toolchain's first proof (features/hard-parts.md): on the main menu, a
// screen of ours, built from XCOM 2's own UI pieces.
class UIScreenListener_LongWarX2Shell extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	if (UIShell(Screen) == none || Screen.Movie.Pres.ScreenStack.HasInstanceOf(class'UILongWarX2Hello'))
		return;
	Screen.Movie.Pres.ScreenStack.Push(Screen.Spawn(class'UILongWarX2Hello', Screen.Movie.Pres));
}

defaultproperties
{
	ScreenClass = none;
}
