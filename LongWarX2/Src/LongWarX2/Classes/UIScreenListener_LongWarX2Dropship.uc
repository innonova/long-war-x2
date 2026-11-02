// In a campaign's mission: the EW map put in place of the generated one (LWX2PartPlacer) while the
// dropship's briefing waits for the player, when the switch is on (features/hard-parts.md,
// experiment 2, with experiment 4's missions).
class UIScreenListener_LongWarX2Dropship extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local LWX2PartPlacer Placer;

	if (UIDropShipBriefing_MissionStart(Screen) == none || !class'LWX2EWMapPieces'.static.HasMap())
		return;
	Placer = Screen.Spawn(class'LWX2PartPlacer');
	Placer.bCampaign = true;
	Placer.bWhole = true;
	`log("LongWarX2: EW map: waiting for the mission's map to place it", , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = none;
}
