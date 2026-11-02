// In a campaign's mission: the EW map put in place of the generated one (LWX2PartPlacer) while the
// dropship's briefing waits for the player, when the switch is on (features/hard-parts.md,
// experiment 2, with experiment 4's missions).
class UIScreenListener_LongWarX2Dropship extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local LWX2PartPlacer Placer;

	if (UIDropShipBriefing_MissionStart(Screen) == none || !class'LWX2EWMapPieces'.static.HasMap())
		return;
	// On the EW map's own plot: it is all there already, at EW's coordinates (its pods need no shift).
	if (class'LWX2EWMapPieces'.static.OnOwnPlot())
	{
		class'LWX2PartPlacer'.default.EWShift = vect(0, 0, 0);
		class'LWX2PartPlacer'.default.bEWPlaced = true;
		class'LWX2PartPlacer'.static.Fog(`XWORLD);
		`log("LongWarX2: EW map: on its own plot" @ `XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData').ObjectID, , 'LongWarX2');
		return;
	}
	Placer = Screen.Spawn(class'LWX2PartPlacer');
	Placer.bCampaign = true;
	Placer.bWhole = true;
	`log("LongWarX2: EW map: waiting for the mission's map to place it", , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = none;
}
