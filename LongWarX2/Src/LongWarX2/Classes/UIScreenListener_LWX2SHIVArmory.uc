// A SHIV's armory (features/lw-shivs-mecs.md): of XCOM 2's armory menu only the loadout and dismissing are a robot's; the
// rest (customizing, combat sims, weapon upgrades, promotion, the photo booth, bonds) are greyed for it.
class UIScreenListener_LWX2SHIVArmory extends UIScreenListener;

var localized string NotForSHIV;

event OnInit(UIScreen Screen)
{
	Limit(UIArmory_MainMenu(Screen));
}

event OnReceiveFocus(UIScreen Screen)
{
	Limit(UIArmory_MainMenu(Screen));
}

static function Limit(UIArmory_MainMenu Menu)
{
	local UIListItemString Item;
	local int i;

	if (Menu == none || !class'LWSHIVs'.static.IsSHIV(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Menu.UnitReference.ObjectID))))
		return;
	for (i = 0; i < Menu.List.GetItemCount(); i++)
	{
		Item = UIListItemString(Menu.List.GetItem(i));
		if (Item == none || Item.Text == Menu.m_strLoadout || Item.Text == Menu.m_strDismiss)
			continue;
		Item.SetDisabled(true, default.NotForSHIV != "" ? default.NotForSHIV : "Not for a SHIV");
	}
}

defaultproperties
{
	ScreenClass = class'UIArmory_MainMenu';
}
