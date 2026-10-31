// A panel, a title, a line of text and a button: the UI pieces the air war's
// screen will be made of (features/hard-parts.md, experiment 3).
class UILongWarX2Hello extends UIScreen;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIText Line;

	super.InitScreen(InitController, InitMovie, InitName);
	Spawn(class'UIBGBox', self).InitBG('LWX2Bg', 560, 300, 800, 320);
	Spawn(class'UIX2PanelHeader', self).InitPanelHeader('LWX2Header', "LONG WAR X2", "The toolchain works").SetPosition(580, 316);
	Line = Spawn(class'UIText', self).InitText('LWX2Line', "Built over ssh with X2ModBuildCommon, loaded by War of the Chosen. Next: the air war.");
	Line.SetPosition(580, 420);
	Line.SetWidth(760);
	Spawn(class'UIButton', self).InitButton('LWX2Close', "CLOSE", OnClose).SetPosition(580, 540);
}

simulated function OnClose(UIButton Button)
{
	CloseScreen();
}

defaultproperties
{
	InputState = eInputState_Consume;
}
