// A new campaign's first mission: the helper that lets it launch without XCOM 2's intro (LWX2FirstMissionStart),
// put on the strategy map by its first screen.
class UIScreenListener_LWX2FirstMission extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local LWX2FirstMissionStart Helper;

	if (!class'LWX2FirstMissionStart'.default.bPending || XComHeadquartersGame(Screen.WorldInfo.Game) == none)
		return;
	foreach Screen.AllActors(class'LWX2FirstMissionStart', Helper)
		return;
	Screen.Spawn(class'LWX2FirstMissionStart');
}

defaultproperties
{
	ScreenClass = none;
}
