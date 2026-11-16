// A SHIV's armory (features/lw-shivs-mecs.md): of XCOM 2's armory menu only the loadout and dismissing are a robot's; the
// rest (customizing, combat sims, weapon upgrades, promotion, the photo booth, bonds) are greyed for it; on the platform, EW's
// body.
class UIScreenListener_LWX2SHIVArmory extends UIScreenListener;

var localized string NotForSHIV;

event OnInit(UIScreen Screen)
{
	Limit(UIArmory_MainMenu(Screen));
	Body(UIArmory(Screen));
}

event OnReceiveFocus(UIScreen Screen)
{
	Limit(UIArmory_MainMenu(Screen));
	Body(UIArmory(Screen));
}

/** The SHIV on the armory's platform in EW's body (its pawn is made a moment after the screen: looked at again then). */
static function Body(UIArmory Armory)
{
	local XComGameState_Unit Unit;

	if (Armory == none)
		return;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Armory.UnitReference.ObjectID));
	if (!class'LWSHIVs'.static.IsSHIV(Unit))
		return;
	if (XComUnitPawn(Armory.ActorPawn) != none)
		class'LWX2EWBodies'.static.ApplyToPawn(XComUnitPawn(Armory.ActorPawn), Unit.GetMyTemplateName());
	// (And for the next few seconds, by the 3D screens' watch: LWX2DisplayWatch.)
}

static function Limit(UIArmory_MainMenu Menu)
{
	local UIListItemString Item;
	local int i, n;

	if (Menu == none || !class'LWSHIVs'.static.IsSHIV(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Menu.UnitReference.ObjectID))))
		return;
	for (i = 0; i < Menu.List.GetItemCount(); i++)
	{
		Item = UIListItemString(Menu.List.GetItem(i));
		if (Item == none || Item.Text == Menu.m_strLoadout || Item.Text == Menu.m_strDismiss || Item.bDisabled)
			continue;
		Item.SetDisabled(true, default.NotForSHIV != "" ? default.NotForSHIV : "Not for a SHIV");
		n++;
	}
	if (n > 0)
		`log("LongWarX2: SHIVs: armory menu," @ n @ "of" @ Menu.List.GetItemCount() @ "options greyed", , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = none;
}
