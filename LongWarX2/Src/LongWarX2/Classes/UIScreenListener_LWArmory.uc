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
	local vector Loc;
	local rotator Rot;

	if (Armory.ActorPawn == none)
		return;
	class'LWX2EWBase'.static.Get(Armory).ArmorySpot(CameraFor(Armory), Loc, Rot);
	if (VSize(Armory.ActorPawn.Location - Loc) < 4)
		return;
	Armory.ActorPawn.SetLocation(Loc);
	Armory.ActorPawn.SetRotation(Rot);
}

defaultproperties
{
	ScreenClass = none;
}
