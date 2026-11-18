// XCOM 2's armory screens in EW's armory (features/strategy-flow.md; LWX2EWBase.ArmoryHere): the base kept in view, the
// view through EW's own camera for the screen (its main menu, loadout, promotion: LWX2EWBase.ScreenDisplays), the screen's
// menu on EW's panel for it there (the base places a display with the screen's tag on it), and the soldier standing in
// front of the camera in EW's armory (LWX2EWBase.ArmorySpot), kept there twice a second as the screens make the pawn
// again (another soldier chosen, the loadout changed).
class UIScreenListener_LWArmory extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	Take(Screen);
}

event OnReceiveFocus(UIScreen Screen)
{
	Take(Screen);
}

function Take(UIScreen Screen)
{
	local LWX2EWBase B;

	if (UIArmory(Screen) == none || !class'LWX2EWBase'.static.ArmoryHere())
		return;
	B = class'LWX2EWBase'.static.Get(Screen);
	B.Show();
	B.LookAt(CameraFor(UIArmory(Screen)), 0);
	Screen.Movie.Pres.Get3DMovie().ShowDisplay(UIArmory(Screen).DisplayTag);
	Place(UIArmory(Screen));
	Screen.SetTimer(0.5, true, nameof(Keep), self);
}

/** EW's camera for an armory screen. */
static function name CameraFor(UIArmory Armory)
{
	local name Camera;

	Camera = class'LWX2EWBase'.static.ScreenCamera(Armory.DisplayTag);
	if (Camera != '')
		return Camera;
	if (UIArmory_Loadout(Armory) != none)
		return 'Armory_UIDisplayCam_Loadout';
	if (UIArmory_Promotion(Armory) != none)
		return 'Armory_UIDisplayCam_Promote';
	return 'Armory_UIDisplayCam_Summary';
}

function Keep()
{
	local UIArmory Armory;

	Armory = UIArmory(`SCREENSTACK.GetCurrentScreen());
	if (Armory != none)
		Place(Armory);
}

static function Place(UIArmory Armory)
{
	local vector Loc;
	local rotator Rot;
	local Actor Placement;
	local UIMouseGuard_RotatePawn Guard;

	// (The Avenger's placement point, in its armory's level, may not be loaded at all: the pawn is placed without it.)
	Placement = Armory.GetPlacementActor();
	class'LWX2EWBase'.static.Get(Armory).ArmorySpot(CameraFor(Armory), Loc, Rot);
	Guard = UIMouseGuard_RotatePawn(`SCREENSTACK.GetFirstInstanceOf(class'UIMouseGuard_RotatePawn'));
	if (Armory.ActorPawn != none && VSize(Armory.ActorPawn.Location - Loc) < 4 && (Guard == none || Guard.ActorRotation.Yaw == Rot.Yaw))
		return;
	// XCOM 2 stands and turns its pawn by its placement (a point in the Avenger's armory, static): the pawn put on EW's
	// floor directly, and the placement told too where there is one.
	if (Placement != none)
	{
		Placement.SetLocation(Loc);
		Placement.SetRotation(Rot);
	}
	if (Armory.ActorPawn != none)
	{
		Armory.ActorPawn.SetLocation(Loc);
		Armory.ActorPawn.SetRotation(Rot);
	}
	// (The armory's mouse guard turns the pawn to its own rotation every tick: it is given ours.)
	if (Guard != none)
		Guard.ActorRotation = Rot;
}

defaultproperties
{
	ScreenClass = none;
}
