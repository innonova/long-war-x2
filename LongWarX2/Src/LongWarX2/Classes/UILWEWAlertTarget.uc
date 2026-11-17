// What an Enemy Within alert's clicks are addressed to (UILWEWAlert). EW's AlertBase reports its buttons' clicks under its
// own Flash path (FlashRaiseMouseEvent with the alert's movie clip), and XCOM 2's UIMovie hands an event only to a panel
// whose MCPath is exactly that path: this panel stands at it, bound to the alert's clip without creating one, and passes the
// events to its screen.
class UILWEWAlertTarget extends UIPanel;

/** Stands at Path (the alert's clip, already in the movie) as one of Screen's panels. */
static function UILWEWAlertTarget At(UIScreen OnScreen, string Path)
{
	local UILWEWAlertTarget Target;

	Target = OnScreen.Spawn(class'UILWEWAlertTarget', OnScreen);
	Target.Movie = OnScreen.Movie;
	Target.Screen = OnScreen;
	Target.ParentPanel = OnScreen;
	Target.PC = OnScreen.PC;
	Target.MCName = name(Mid(Path, InStr(Path, ".", true) + 1));
	Target.MCPath = name(Path);
	Target.bIsInited = true;
	Target.bIsVisible = true;
	OnScreen.ChildPanels.AddItem(Target);
	return Target;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	Screen.OnMouseEvent(cmd, args);
}
