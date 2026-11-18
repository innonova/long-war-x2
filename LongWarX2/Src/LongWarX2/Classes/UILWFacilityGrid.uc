// XCOM 2's base view replaced (features/strategy-flow.md): in place of the Avenger's facility grid (ModClassOverride in
// XComEngine.ini), XCOM 2's strategy layer gets this, which stays the bottom of its screen stack, as the grid does, but
// shows nothing (no room overlays, no border, no buttons), moves no camera and takes no input. Above it, always, Long
// War's root: the start screen in a campaign not yet begun, else EW's base hub (UILWStartSelect.OpenGeoscape).
//
// What XCOM 2 does with its grid, and what that comes to here:
// - XCOM 2 finds its grid by exact class (UIScreenStack.GetScreen, IsCurrentClass), and this is a subclass, so:
//   - its "back to the base view" (XComHQPresentationLayer.ClearToFacilityMainMenu: pop down to the grid) pops nothing.
//     Long War's root stays; the screens that call it (XCOM 2's alerts, the end of the post-mission sequence) close
//     themselves. (Shown by itself over XCOM 2's grid, the Long War screen was popped by those, came back, and looped:
//     features/lw-base.md, experiment 4.)
//   - XCOM 2's queued popups that wait for an idle base view (bDisplayOnAvengerSideViewIdle) never show, and its
//     Avenger HUD's widgets that show only over the grid (shortcuts, objectives, event queue, to-do, status) stay
//     hidden. The popups still queued are logged when the hub gets the focus back (UILWEWHub.LogQueuedPopups).
// - XCOM 2 also calls the grid directly (m_kFacilityGrid: Show, Hide, UpdateData, LookAtSelectedRoom, ActivateGrid,
//   DeactivateGrid, SelectRoomByReference): all of them do nothing here.
// - Long War's root opens once the grid is the top screen (after XCOM 2's after-action screens, when it comes back from a
//   mission), and again should it ever be taken off the stack.
class UILWFacilityGrid extends UIFacilityGrid;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	// (XCOM 2's makes an overlay per Avenger room, the navigation grid and the help bar's buttons: none of them.)
	super(UIScreen).InitScreen(InitController, InitMovie, InitName);
}

simulated function OnInit()
{
	super(UIScreen).OnInit();
	super.Hide();
	OpenRoot();
}

/**
 * Long War's root (start screen or hub) over this, unless it is up; only once this is the top screen. Coming back from a
 * mission, XCOM 2 pushes its after-action screens over the base view (after the campaign's first mission too, which in
 * EW comes before the base is chosen); the root waits until they are done and this gets the focus.
 */
function OpenRoot()
{
	local XComHQPresentationLayer HQPres;

	HQPres = XComHQPresentationLayer(Movie.Pres);
	if (HQPres == none || HQPres.ScreenStack.GetCurrentScreen() != self || HQPres.ScreenStack.IsInStack(class'UILWStartSelect')
		|| HQPres.ScreenStack.IsInStack(class'UILWEWHub') || HQPres.ScreenStack.IsInStack(class'UILWGeoscape'))
		return;
	`log("LongWarX2: XCOM 2's base view replaced: Long War's root opened", , 'LongWarX2');
	class'UILWStartSelect'.static.OpenGeoscape(HQPres);
}

simulated function OnReceiveFocus()
{
	super(UIScreen).OnReceiveFocus();
	super.Hide();
	if (bIsInited)
		OpenRoot();
}

simulated function OnLoseFocus()
{
	// (As XCOM 2's: the help bar cleared for the next screen and the Avenger's free camera movement off.)
	super(UIScreen).OnLoseFocus();
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.ClearButtonHelp();
	XComHeadquartersController(Movie.Pres.Owner).SetInputState('None');
}

simulated function OnRemoved()
{
	super(UIScreen).OnRemoved();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	return false;
}

// Shown never; the rest of XCOM 2's grid does nothing.
simulated function Show();
simulated function LookAtSelectedRoom();
simulated function OnSelectedRoomChanged(int NewIndex);
simulated function UpdateData();
simulated function UpdateOverlayPositions();
simulated function InitializeNavigationGrid();
simulated function InitializeBuildNavigationGrid();
simulated function SelectGeoscape();
simulated function RefreshButtonHelp();
simulated function CameraTravelFinished();
simulated function ActivateGrid();
simulated function DeactivateGrid();
simulated function ClearOverlayHighlights();
function ToggleGrid();
simulated function UnHighlightAvengerShortcuts();
simulated function SetNextShortcutRoomAsSelected();
simulated function SetPrevShortcutRoomAsSelected();
simulated function int GetShadowChamberIndex()
{
	return -1;
}
simulated function SelectRoomByReference(StateObjectReference Reference);
simulated function ClickPauseButton();
