// XCOM 2's squad select for a mission chosen on the Long War Geoscape (features/lw-squad-select.md): the player picks the
// squad and its loadout on XCOM 2's own screen, then the mission goes ahead on the Long War launch path (UILWGeoscape.
// LaunchChosen), not XCOM 2's Skyranger flight over its world map; backing out leaves the mission where it was.
//
// XCOM 2's screen ends in GoToGeoscape, when the launch bay's departure (or cancel) cinematic sends PreM_Exit; that is where
// this takes over. A fallback timer does the same if the cinematic never sends it.
class UILWSquadSelect extends UISquadSelect;

/** Seconds after launch or cancel before GoToGeoscape runs anyway (the cinematic's PreM_Exit not come). (Not config: the
 * class keeps UISquadSelect's config file, whose MaxDisplayedSlots it needs.) */
const EXIT_FALLBACK = 20.0;

var bool bExited;

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
	if (!bReserveBackedOut)
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
