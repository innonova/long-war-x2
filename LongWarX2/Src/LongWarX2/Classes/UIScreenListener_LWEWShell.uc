// Enemy Within's game creation in place of XCOM 2's (features/strategy-flow.md): where the player's EW shell screens are
// converted (EWShellUI.upk), XCOM 2's new-campaign screen is hidden as it comes up and EW's (UILWEWDifficulty) is shown
// over it; XCOM 2's stays under it to start the campaign. Changing the difficulty during a campaign keeps XCOM 2's.
class UIScreenListener_LWEWShell extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIShellDifficulty X2;

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

	// (Back on top only when EW's was closed without starting: it closes with it.)
	X2 = UIShellDifficulty(Screen);
	if (X2 != none && !X2.m_bIsPlayingGame && class'UILWEWDifficulty'.static.Available())
		X2.Hide();
}

defaultproperties
{
	ScreenClass = none;
}
