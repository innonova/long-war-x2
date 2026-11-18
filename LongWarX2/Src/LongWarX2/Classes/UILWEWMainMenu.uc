// Enemy Within's main menu (features/strategy-flow.md: game creation as in EW): its Shell movie (EWShellUI.upk; clip
// theShell), driven as EW's UIShell and UIFinalShell drive it: its buttons (SetDisplay, one label each), the selection
// (setSelectedMenuItem) following the mouse, a click doing what EW's AcceptMenu does. Long War's words from the player's
// install (XComUIShell.int, [UIFinalShell]). Over XCOM 2's main menu, hidden (UIScreenListener_LWEWShell).
//
// Long War's own entries: LONG WAR (a new game: XCOM 2's difficulty screen, which EW's new-game screen covers), LOAD GAME,
// OPTIONS, EXIT TO DESKTOP. EW's MULTIPLAYER (second) is left out (the port has none); XCOM 2's CHARACTER POOL takes its
// place, as the soldiers' looks are XCOM 2's.
class UILWEWMainMenu extends UILWEWScreen;

var localized string m_sSinglePlayer, m_sLoad, m_sOptions, m_sExitToDesktop;

var array<name> Entries;
var int Selected;

static function UILWEWMainMenu Open(XComPresentationLayerBase Pres)
{
	local UILWEWMainMenu S;

	DynamicLoadObject("EWShellUI.ewxShell", class'Object', true);
	S = Pres.Spawn(class'UILWEWMainMenu', Pres);
	S.Package = name("/ package/ewxShell/Shell");
	S.MCName = 'theShell';
	Pres.ScreenStack.Push(S);
	return S;
}

static function bool Available()
{
	return DynamicLoadObject("EWShellUI.ewxShell", class'Object', true) != none;
}

simulated function OnInit()
{
	super.OnInit();
	Fill();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (bIsInited)
		Fill();
}

function Fill()
{
	local name E;

	Entries.Length = 0;
	Entries.AddItem('SP');
	Entries.AddItem('CharacterPool');
	Entries.AddItem('Load');
	Entries.AddItem('Options');
	Entries.AddItem('Exit');
	MC.BeginFunctionOp("SetDisplay");
	foreach Entries(E)
		MC.QueueString(Label(E));
	MC.EndOp();
	Select(Clamp(Selected, 0, Entries.Length - 1));
}

function string Label(name E)
{
	switch (E)
	{
	case 'SP': return Word(m_sSinglePlayer, class'UIFinalShell'.default.m_sNewGame);
	case 'Load': return Word(m_sLoad, class'UIShell'.default.m_sLoad);
	case 'CharacterPool': return Caps(class'UIFinalShell'.default.m_sCharacterPool);
	case 'Options': return Word(m_sOptions, class'UIShell'.default.m_sOptions);
	case 'Exit': return Word(m_sExitToDesktop, "EXIT TO DESKTOP");
	}
	return "";
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

function Select(int i)
{
	Selected = i;
	MC.FunctionNum("setSelectedMenuItem", i);
}

/** What EW's AcceptMenu does, with XCOM 2's screens: its difficulty screen (EW's new-game screen covers it), its load
 *  screen, its character pool, its options, the exit. */
function Accept(int i)
{
	local XComShellPresentationLayer Pres;

	if (i < 0 || i >= Entries.Length)
		return;
	Select(i);
	Pres = XComShellPresentationLayer(Movie.Pres);
	switch (Entries[i])
	{
	case 'SP': Pres.UIDifficulty(); break;
	case 'Load': Pres.UILoadScreen(); break;
	case 'CharacterPool': Pres.UICharacterPool(); break;
	case 'Options': Pres.UIPCOptions(); break;
	case 'Exit': ConsoleCommand("exit"); break;
	}
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int i, k;

	super.OnMouseEvent(cmd, args);
	// (Its buttons report themselves as option<i>, UIShell.OnMouseEvent.)
	i = -1;
	for (k = args.Length - 1; k >= 0 && i < 0; k--)
		if (InStr(args[k], "option") == 0)
			i = int(Mid(args[k], 6));
	if (i < 0)
		return;
	if (cmd == 392)
		Select(i);
	else if (cmd == 391)
		Accept(i);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
			Select(Selected > 0 ? Selected - 1 : Entries.Length - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
			Select(Selected + 1 < Entries.Length ? Selected + 1 : 0);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Accept(Selected);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			// (The root of the shell: Escape closes nothing.)
			return true;
		}
	}
	return super(UIScreen).OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	UIPackage = "EWShellUI"
}
