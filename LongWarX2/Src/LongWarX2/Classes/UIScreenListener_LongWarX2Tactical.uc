// In a tactical mission: an Enemy Within unit shown beside the first soldier
// (features/hard-parts.md, experiment 1), when the player has converted one
// (its package in the mod's Content folder) and the switch is on.
class UIScreenListener_LongWarX2Tactical extends UIScreenListener config(LWAirWar);

var config bool ShowEWUnit;

event OnInit(UIScreen Screen)
{
	local XComUnitPawn Pawn;
	local LWX2EWUnitDisplay Display;

	if (!default.ShowEWUnit || UITacticalHUD(Screen) == none)
		return;
	foreach Screen.WorldInfo.AllActors(class'LWX2EWUnitDisplay', Display)
		return;
	foreach Screen.WorldInfo.AllActors(class'XComUnitPawn', Pawn)
	{
		if (XComHumanPawn(Pawn) != none)
			break;
	}
	`log("LongWarX2: tactical HUD; first soldier pawn" @ Pawn, , 'LongWarX2');
	if (Pawn == none)
		return;
	Display = Screen.WorldInfo.Spawn(class'LWX2EWUnitDisplay');
	if (!Display.ShowBeside(Pawn))
		Display.Destroy();
}

defaultproperties
{
	ScreenClass = none;
}
