// Long War's mission restarts on XCOM 2's pause menu (features/lw-second-wave.md): XCOM 2 offers Restart Mission only in its
// first and final missions and never in Ironman; Long War offers it in every mission of a game not in Ironman, and with
// Bronzeman Mode (second wave #16) in Ironman too ("Allows restart of tactical missions via pause menu in Ironman mode.
// Restarts are automatically enabled for non-Ironman games"). XCOM 2's own item, question and restart (UIPauseMenu's
// m_sRestartLevel, RestartMissionDialogue), added where XCOM 2 left it out.
// (A screen listener is a default object, outside the world: it keeps no reference to the menu, which would keep the
// mission's world alive through the restart's map change and crash the game. The menu is looked up when needed.)
class UIScreenListener_LWX2PauseMenu extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	if (UIPauseMenu(Screen) == none)
		return;
	// (After the menu has built its list, in its own OnInit.)
	Screen.SetTimer(0.1, false, nameof(AddRestart), self);
}

function AddRestart()
{
	local UIPauseMenu Menu;

	Menu = `PRES != none ? UIPauseMenu(`PRES.ScreenStack.GetScreen(class'UIPauseMenu')) : none;
	if (Menu == none || Menu.m_optRestart != -1 || `TACTICALRULES == none || XGBattle_SP(`BATTLE) == none
		|| Menu.WorldInfo.NetMode != NM_Standalone || `ONLINEEVENTMGR.bIsChallengeModeGame)
		return;
	if (Menu.m_bIsIronman && !class'LWX2SecondWave'.static.On(16))
		return;
	Menu.m_optRestart = Menu.List.ItemCount;
	UIListItemString(Menu.List.CreateItem()).InitListItem(Menu.m_sRestartLevel);
	Menu.List.OnItemClicked = OnClicked;
}

/** Restart Mission: XCOM 2's question and restart (its own handler refuses it in Ironman); anything else, the menu's. */
function OnClicked(UIList ContainerList, int ItemIndex)
{
	local UIPauseMenu Menu;

	Menu = UIPauseMenu(ContainerList.Screen);
	if (Menu == none)
		return;
	if (ItemIndex == Menu.m_optRestart)
		Menu.RestartMissionDialogue();
	else
		Menu.OnChildClicked(ContainerList, ItemIndex);
}

defaultproperties
{
	ScreenClass = none;
}
