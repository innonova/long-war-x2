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
	local vector Loc, CamLoc, Forward, Right;
	local rotator Rot, Turn, CamRot;
	local Actor Placement;
	local UIDisplay_LevelActor Display, Ours;
	local UIMouseGuard_RotatePawn Guard;

	Placement = Armory.GetPlacementActor();
	if (Placement == none)
		return;
	class'LWX2EWBase'.static.Get(Armory).ArmorySpot(CameraFor(Armory), Loc, Rot);
	Guard = UIMouseGuard_RotatePawn(`SCREENSTACK.GetFirstInstanceOf(class'UIMouseGuard_RotatePawn'));
	if (Armory.ActorPawn != none && VSize(Armory.ActorPawn.Location - Loc) < 4 && (Guard == none || Guard.ActorRotation.Yaw == Rot.Yaw))
		return;
	// XCOM 2 stands and turns its pawn by its placement (a point in the Avenger's armory): the placement moved to EW's
	// armory, and the screen's 3D display (its menu) where XCOM 2 has it beside the placement, the same beside ours.
	// The blueprint's display does not move (it sits in the blueprint's own level, its location unreadable): a display of
	// our own instead, with its mesh and material, tagged as the screen's so the 3D movie draws on it too
	// (UIMovie_3D.ShowDisplayByTag), standing to the soldier's side as the camera sees it, facing the camera.
	Display = DisplayOf(Armory);
	if (Display != none && class'LWX2EWBase'.static.Get(Armory).CameraOf(CameraFor(Armory), CamLoc, CamRot))
	{
		Ours = OwnDisplay(Armory, Display);
		if (Ours != none)
		{
			Forward = vector(CamRot);
			Forward.Z = 0;
			Forward = Normal(Forward);
			Right.X = -Forward.Y;
			Right.Y = Forward.X;
			Ours.SetLocation(Loc - Forward * class'LWX2EWBase'.default.ArmoryDisplayForward + Right * class'LWX2EWBase'.default.ArmoryDisplaySide
				+ vect(0, 0, 1) * class'LWX2EWBase'.default.ArmoryDisplayUp);
			Turn = rotator(-Forward);
			Turn.Yaw += class'LWX2EWBase'.default.ArmoryDisplayYaw;
			Ours.SetRotation(Turn);
			Ours.SetDrawScale3D(Display.DrawScale3D);
			Ours.SetDrawScale(Display.DrawScale * class'LWX2EWBase'.default.ArmoryDisplayScale);
			Armory.Movie.Pres.Get3DMovie().ShowDisplay(Armory.DisplayTag);
		}
	}
	Placement.SetLocation(Loc);
	Placement.SetRotation(Rot);
	if (Armory.ActorPawn != none)
	{
		Armory.ActorPawn.SetLocation(Loc);
		Armory.ActorPawn.SetRotation(Rot);
	}
	// (The armory's mouse guard turns the pawn to its own rotation every tick: it is given ours.)
	if (Guard != none)
		Guard.ActorRotation = Rot;
	`log("LongWarX2: armory in EW's: placement at" @ Placement.Location @ "yaw" @ Placement.Rotation.Yaw @ "; our display" @ (Ours != none ? string(Ours.Location) @ "scale" @ Ours.DrawScale @ Ours.DrawScale3D : "none")
		@ "pawn yaw" @ (Armory.ActorPawn != none ? string(Armory.ActorPawn.Rotation.Yaw) : "-"), , 'LongWarX2');
}

/** Our display for the screen's tag: spawned once, the blueprint's mesh and material on it. */
static function UIDisplay_LevelActor OwnDisplay(UIArmory Armory, UIDisplay_LevelActor Model)
{
	local UIDisplay_LevelActor D;

	foreach Armory.WorldInfo.AllActors(class'UIDisplay_LevelActor', D)
		if (D.Tag == Armory.DisplayTag && D.Name != Model.Name && D.Owner == Armory.WorldInfo)
			return D;
	D = Armory.WorldInfo.Spawn(class'UIDisplay_LevelActor', Armory.WorldInfo, Armory.DisplayTag, Model.Location, Model.Rotation, , true);
	if (D == none)
	{
		`log("LongWarX2: armory in EW's: our display could not be made", , 'LongWarX2');
		return none;
	}
	D.StaticMeshComponent.SetStaticMesh(Model.StaticMeshComponent.StaticMesh);
	D.StaticMeshComponent.SetMaterial(0, Model.StaticMeshComponent.GetMaterial(0));
	D.SetCollisionType(COLLIDE_BlockAll);
	`log("LongWarX2: armory in EW's: our display made for" @ Armory.DisplayTag @ "with" @ Model.StaticMeshComponent.StaticMesh, , 'LongWarX2');
	return D;
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
