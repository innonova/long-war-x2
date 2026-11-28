// XCOM 2's armory menu, with Long War's Commander's Choice (second wave #18; XGSoldierUI with eGO_MorePower: the class chosen
// for each soldier on promotion from rookie): PROMOTE for a rookie who can rank up opens XCOM 2's class chooser with Long
// War's classes (UILWChooseClass) instead of XCOM 2's draw from its class deck. Leaving it from squad select in EW's base
// (OnCancel). Everything else is XCOM 2's.
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

/**
 * Back to squad select from EW's base: XCOM 2's armory opened from squad select leaves by its remote event
 * (NavigationBackEvent) for the Avenger's launch bay scene to play and close it, losing the focus meanwhile; in EW's hangar
 * there is no such scene, so it stayed, unfocused, with no way out (aek's trapped.png, 2026-11-28). There it is left
 * directly, as XCOM 2 leaves an armory with no scene to wait on (UIArmory.OnCancel's own first branch).
 */
simulated function OnCancel()
{
	if (NavigationBackEvent != '' && class'LWX2EWBase'.static.ArmoryHere())
	{
		RemoveMenuEvent = '';
		NavigationBackEvent = '';
		`log("LongWarX2: the armory left straight back to squad select (EW's base has no scene for its back event)", , 'LongWarX2');
	}
	super.OnCancel();
}
