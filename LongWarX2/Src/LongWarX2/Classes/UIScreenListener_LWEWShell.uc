// Enemy Within's main menu and game creation in place of XCOM 2's (features/strategy-flow.md): where the player's EW shell
// screens are converted (EWShellUI.upk), XCOM 2's main menu and new-campaign screen are hidden as they come up and EW's
// (UILWEWMainMenu, UILWEWDifficulty) shown over them; XCOM 2's stays under it to start the campaign. Changing the difficulty during a campaign keeps XCOM 2's.
class UIScreenListener_LWEWShell extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIShellDifficulty X2;

	// XCOM 2's main menu: EW's over it (UILWEWMainMenu), XCOM 2's hidden.
	if (UIFinalShell(Screen) != none && class'UILWEWMainMenu'.static.Available())
	{
		Screen.Hide();
		class'UILWEWMainMenu'.static.Open(Screen.Movie.Pres);
		`log("LongWarX2: XCOM 2's main menu under EW's", , 'LongWarX2');
		return;
	}

	X2 = UIShellDifficulty(Screen);
	if (X2 == none || X2.m_bIsPlayingGame || !class'UILWEWDifficulty'.static.Available())
		return;
	X2.Hide();
	class'UILWEWDifficulty'.static.Open(X2.Movie.Pres, X2);
	`log("LongWarX2: XCOM 2's new-campaign screen under EW's", , 'LongWarX2');
}

event OnReceiveFocus(UIScreen Screen)
{
	local UIShellDifficulty X2;

	if (UIFinalShell(Screen) != none && class'UILWEWMainMenu'.static.Available())
		Screen.Hide();
	// (Back on top only when EW's was closed without starting: it closes with it.)
	X2 = UIShellDifficulty(Screen);
	if (X2 != none && !X2.m_bIsPlayingGame && class'UILWEWDifficulty'.static.Available())
		X2.Hide();
}

defaultproperties
{
	ScreenClass = none;
}
