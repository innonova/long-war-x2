// Holds the Tactical Quick Launch screen's camera at a given view while the screen's
// debug camera is on (features/hard-parts.md, experiment 2). The screen's own toggle does
// nothing in the retail game (the controller's ToggleDebugCamera needs the console), so
// the camera is put into its free-look state here, and its view set every frame (the
// screen takes the input it would fly with).
class LWX2CameraHold extends Actor;

var UITacticalQuickLaunch Screen;
var TPOV View;
var bool bHolding;

event Tick(float DeltaTime)
{
	local XComCameraBase Camera;

	if (Screen == none || Screen.PC == none)
		return;
	Camera = XComCameraBase(Screen.PC.PlayerCamera);
	if (Camera == none)
		return;
	if (Screen.bDebugCameraActive != bHolding)
	{
		bHolding = Screen.bDebugCameraActive;
		`log("LongWarX2: camera hold:" @ (bHolding ? "on" : "off"), , 'LongWarX2');
		if (bHolding)
			Camera.PushState('DebugView');
		else
			Camera.PopState();
	}
	if (bHolding)
		Camera.CameraCache.POV = View;
}

defaultproperties
{
	bHidden = true;
	bAlwaysTick = true; // the screen's world is paused
	TickGroup = TG_PostAsyncWork;
}
