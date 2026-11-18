// XCOM 2's After Action screen replaced (a ModClassOverride; features/strategy-flow.md): not its squad lined up on the
// Avenger's walkway, but EW's debrief over EW's base (UILWEWDebrief). XCOM 2's own bookkeeping after it is kept (its
// OnContinue: the squad's invalid soldiers removed, PostAfterAction), and then the items recovered (UILWLootRecovered),
// which returns to EW's base.
class UILWAfterAction extends UIAfterAction;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super(UIScreen).InitScreen(InitController, InitMovie, InitName);
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	Hide();
	`HQPRES.m_kAvengerHUD.FacilityHeader.Hide();
	SetTimer(0.1, false, nameof(OpenDebrief));
}

function OpenDebrief()
{
	class'UILWEWDebrief'.static.Open(`HQPRES, self);
}

/** The debrief's CONTINUE: XCOM 2's OnContinue (its Avenger cinematic's remote event is harmless with the Avenger hidden). */
function GoOn()
{
	OnContinue();
}

// (None of XCOM 2's lineup: no pawns, no walk-up cinematic, no list, no camera of the Avenger's.)
function StartPostMissionCinematic();
function ForceNavHelpOn();
simulated function UpdateData();
simulated function UpdateMissionInfo();
simulated function UpdateNavHelp();
function BuildFlyoverList();
function LoadPhotoboothAutoGenDeadSoldiers();
event Tick(float DeltaTime);

simulated function OnReceiveFocus()
{
	super(UIScreen).OnReceiveFocus();
	Hide();
}

simulated function OnLoseFocus()
{
	super(UIScreen).OnLoseFocus();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	return false;
}
