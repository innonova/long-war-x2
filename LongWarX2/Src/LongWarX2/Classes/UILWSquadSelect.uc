// XCOM 2's squad select for a mission chosen on the Long War Geoscape (features/lw-squad-select.md): the player picks the
// squad and its loadout on XCOM 2's own screen, then the mission goes ahead on the Long War launch path (UILWGeoscape.
// LaunchChosen), not XCOM 2's Skyranger flight over its world map; backing out leaves the mission where it was.
//
// XCOM 2's screen ends in GoToGeoscape, when the launch bay's departure (or cancel) cinematic sends PreM_Exit; that is where
// this takes over. A fallback timer does the same if the cinematic never sends it.
//
// In EW's hangar (LWX2EWBase.SquadHere, features/lw-base-view.md, plan step 4): the squad stands where EW lined it up in
// front of the Skyranger, seen through EW's camera for it, in place of the Avenger's launch bay. No cinematic there: the
// soldiers stand idle at their spots (LWX2EWBase.SquadSpot, in the order of the slots on screen), the screen shows at once
// (as the launch bay's PreM_LineupUI shows it), and launching or backing out goes straight on (no PreM_Exit to wait for).
// The Avenger comes back while the armory is over this (its loadout stands the soldier in the Avenger's armory).
class UILWSquadSelect extends UISquadSelect;

/** Seconds after launch or cancel before GoToGeoscape runs anyway (the cinematic's PreM_Exit not come). (Not config: the
 * class keeps UISquadSelect's config file, whose MaxDisplayedSlots it needs.) */
const EXIT_FALLBACK = 20.0;

var bool bExited;
/** In EW's hangar (decided as the screen opens). */
var bool bHangar;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	bHangar = class'LWX2EWBase'.static.SquadHere();
	if (bHangar)
		UIDisplayCam = "LWX2EWBase_" $ class'LWX2EWBase'.default.SquadCamera;
	super.InitScreen(InitController, InitMovie, InitName);
}

/** EW's hangar in view, through EW's camera for the squad. */
function ShowHangar()
{
	local LWX2EWBase B;

	B = class'LWX2EWBase'.static.Get(self);
	B.Show();
	B.LookAt(class'LWX2EWBase'.default.SquadCamera, 0);
}

/** In EW's hangar, in place of the launch bay's cinematic: the soldiers idle at their spots and the screen shown. */
function StartPreMissionCinematic()
{
	if (!bHangar)
	{
		super.StartPreMissionCinematic();
		return;
	}
	if (!bIsFocused)
	{
		SetTimer(0.1f, false, nameof(StartPreMissionCinematic));
		return;
	}
	ShowHangar();
	GotoState('Cinematic_PawnsIdling');
	OnRemoteEvent('PreM_LineupUI');
}

/** In EW's hangar: each soldier at their spot, left to right in the order of the slots on screen. */
simulated function XComUnitPawn CreatePawn(StateObjectReference UnitRef, int index)
{
	local XComGameState_Unit UnitState;
	local XComUnitPawn UnitPawn, GremlinPawn;
	local array<AnimSet> GremlinHQAnims;
	local vector Loc;
	local rotator Rot;
	local int Column;

	if (!bHangar)
		return super.CreatePawn(UnitRef, index);
	Column = SlotListOrder.Find(index);
	if (Column == INDEX_NONE)
		Column = index;
	class'LWX2EWBase'.static.SquadSpot(Column, Max(SoldierSlotCount, SlotListOrder.Length), Loc, Rot);
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	UnitPawn = m_kPawnMgr.RequestCinematicPawn(self, UnitRef.ObjectID, Loc, Rot, name("Soldier" $ (index + 1)), '', true);
	UnitPawn.GotoState('CharacterCustomization');
	UnitPawn.CreateVisualInventoryAttachments(m_kPawnMgr, UnitState, , , true);
	// (Cinematic pawns are made hidden: the launch bay's cinematic shows them.)
	UnitPawn.SetVisible(true);
	GremlinPawn = m_kPawnMgr.GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID);
	if (GremlinPawn != none)
	{
		GremlinPawn.SetLocation(Loc);
		GremlinPawn.SetRotation(Rot);
		GremlinHQAnims.AddItem(AnimSet'HQ_ANIM.Anims.AS_Gremlin');
		GremlinPawn.XComAddAnimSetsExternal(GremlinHQAnims);
	}
	return UnitPawn;
}

simulated function OnReceiveFocus()
{
	if (bHangar && !bLaunched)
		ShowHangar();
	super.OnReceiveFocus();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	// (The armory, its loadout and the soldier's screens stand the soldier in the Avenger's armory.)
	if (bHangar && !bLaunched)
		class'LWX2EWBase'.static.Get(self).Hide();
}

/** The mission panel: Long War's mission (what was chosen on the Geoscape, its objective, what it brings home), not the
 * XCOM 2 mission source it is fought as. */
simulated function UpdateMissionInfo()
{
	local XComGameState_LWStrategy S;
	local GeneratedMissionData MissionData;
	local string Title, Reward;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.PendingKind == 0)
	{
		super.UpdateMissionInfo();
		return;
	}
	S.PendingWords(Title, Reward);
	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	m_kMissionInfo.UpdateData(MissionData.BattleOpName, Title, "", Reward);
}

simulated function CloseScreen()
{
	local bool bReserveBackedOut;

	// XCOM 2's CloseScreen does not leave the stack (the cinematic's PreM_Exit does); with a reserve squad backed out, it
	// stays open and nothing is to wait for.
	bReserveBackedOut = !bLaunched && XComHQ.AllSquads.Length > 0;
	super.CloseScreen();
	if (bReserveBackedOut)
		return;
	// (In EW's hangar no cinematic sends PreM_Exit.)
	if (bHangar)
		GoToGeoscape();
	else
		SetTimer(EXIT_FALLBACK, false, nameof(ExitFallbackFired));
}

function ExitFallbackFired()
{
	if (!bExited)
	{
		`log("LongWarX2: squad select: no PreM_Exit from the launch bay in" @ EXIT_FALLBACK @ "s; going on without it", , 'LongWarX2');
		GoToGeoscape();
	}
}

/** In place of XCOM 2's: the Long War Geoscape launches the mission, or takes it back. */
function GoToGeoscape()
{
	local UILWGeoscape Geo;
	local int MissionID;
	local bool bGo;

	if (bExited)
		return;
	bExited = true;
	ClearTimer(nameof(ExitFallbackFired));
	MissionID = class'UIUtilities_Strategy'.static.GetXComHQ().MissionRef.ObjectID;
	bGo = bLaunched;
	`XCOMGRI.DoRemoteEvent('CIN_UnhideArmoryStaff');
	// (Out of EW's hangar: the base's own view again for the screen under this.)
	if (bHangar)
		class'LWX2EWBase'.static.Get(self).LookAt('Base', 0);
	Geo = UILWGeoscape(Movie.Pres.ScreenStack.GetFirstInstanceOf(class'UILWGeoscape'));
	Movie.Stack.Pop(self);
	`log("LongWarX2: squad select:" @ (bGo ? "launch" : "backed out of") @ "mission" @ MissionID, , 'LongWarX2');
	if (bGo)
	{
		if (Geo != none)
			Geo.LaunchChosen(MissionID);
		else
			`log("LongWarX2: squad select: no Long War Geoscape to launch from", , 'LongWarX2');
	}
	else
	{
		class'UILWGeoscape'.static.ForgetChosen(MissionID);
		`XSTRATEGYSOUNDMGR.PlayGeoscapeMusic();
		if (Geo != none)
			Geo.Refresh();
	}
}

defaultproperties
{
}
