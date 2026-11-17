// XCOM 2's armory menu, with Long War's Commander's Choice (second wave #18; XGSoldierUI with eGO_MorePower: the class chosen
// for each soldier on promotion from rookie): PROMOTE for a rookie who can rank up opens XCOM 2's class chooser with Long
// War's classes (UILWChooseClass) instead of XCOM 2's draw from its class deck. Everything else is XCOM 2's.
class UIArmory_LWMainMenu extends UIArmory_MainMenu;

simulated function OnAccept()
{
	local XComGameState_Unit Unit;
	local UILWChooseClass Chooser;
	local XComHQPresentationLayer HQPres;

	Unit = GetUnit();
	HQPres = XComHQPresentationLayer(Movie.Pres);
	// (Index 4: PROMOTE, as XCOM 2's OnAccept numbers its items.)
	if (List.SelectedIndex == 4 && HQPres != none && !UIListItemString(List.GetSelectedItem()).bDisabled
		&& class'LWX2SecondWave'.static.On(18) && Unit != none && Unit.GetRank() == 0 && Unit.CanRankUpSoldier())
	{
		Chooser = HQPres.Spawn(class'UILWChooseClass', HQPres);
		Chooser.m_UnitRef = UnitReference;
		HQPres.ScreenStack.Push(Chooser);
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
		return;
	}
	super.OnAccept();
}
