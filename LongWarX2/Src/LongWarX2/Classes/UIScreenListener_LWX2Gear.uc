// Long War's soldiers armed as Long War allows (LWX2Gear) whenever soldiers are looked at or sent out:
// the armory, squad selection, the after-action report (promotions), the Geoscape.
class UIScreenListener_LWX2Gear extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	if (UIArmory(Screen) != none || UISquadSelect(Screen) != none || UIAfterAction(Screen) != none || UILWGeoscape(Screen) != none || UIPersonnel(Screen) != none)
		class'LWX2Gear'.static.ArmAll();
}

defaultproperties
{
	ScreenClass = none;
}
