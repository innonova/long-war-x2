// XCOM 2's armory screens over EW's armory (features/lw-base-view.md, the armory in EW's rooms; LWX2EWBase.ArmoryHere): the
// base kept in view, the view through EW's own camera for the screen (its main menu, loadout, promotion), and the soldier
// standing in front of it in EW's armory (LWX2EWBase.ArmorySpot), kept there twice a second as the screens make the pawn
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
	Place(UIArmory(Screen));
	Screen.SetTimer(0.5, true, nameof(Keep), self);
}

/** EW's camera for an armory screen. */
static function name CameraFor(UIArmory Armory)
{
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
	local vector Loc, Offset;
	local rotator Rot, Turn;
	local Actor Placement;
	local UIDisplay_LevelActor Display;

	Placement = Armory.GetPlacementActor();
	if (Placement == none)
		return;
	class'LWX2EWBase'.static.Get(Armory).ArmorySpot(CameraFor(Armory), Loc, Rot);
	if (VSize(Placement.Location - Loc) < 4 && Placement.Rotation.Yaw == Rot.Yaw)
		return;
	// XCOM 2 stands and turns its pawn by its placement (a point in the Avenger's armory): the placement moved to EW's
	// armory, and the screen's 3D display (its menu) where XCOM 2 has it beside the placement, the same beside ours.
	Turn.Yaw = Rot.Yaw - Placement.Rotation.Yaw;
	Display = DisplayOf(Armory);
	if (Display != none)
	{
		Offset = Display.Location - Placement.Location;
		Display.SetLocation(Loc + (Offset >> Turn));
		Display.SetRotation(Display.Rotation + Turn);
	}
	Placement.SetLocation(Loc);
	Placement.SetRotation(Rot);
	if (Armory.ActorPawn != none)
	{
		Armory.ActorPawn.SetLocation(Loc);
		Armory.ActorPawn.SetRotation(Rot);
	}
	`log("LongWarX2: armory in EW's: placement at" @ Placement.Location @ "yaw" @ Placement.Rotation.Yaw @ "; display" @ (Display != none ? string(Display.Location) : "not found"), , 'LongWarX2');
}

/** The screen's 3D display (in its blueprint's level, which the world's actor lists do not reach: LWX2DisplayWatch). */
static function UIDisplay_LevelActor DisplayOf(UIArmory Armory)
{
	local XComBlueprint Blueprint;
	local array<Actor> Actors;
	local Actor A;

	foreach Armory.WorldInfo.AllActors(class'XComBlueprint', Blueprint)
	{
		if (Blueprint.Tag != Armory.DisplayTag)
			continue;
		Blueprint.GetLoadedLevelActors(Actors);
		foreach Actors(A)
			if (UIDisplay_LevelActor(A) != none)
				return UIDisplay_LevelActor(A);
	}
	return none;
}

defaultproperties
{
	ScreenClass = none;
}
