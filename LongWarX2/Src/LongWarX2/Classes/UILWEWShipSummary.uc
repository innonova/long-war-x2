// Enemy Within's craft summary (features/strategy-flow.md; a craft chosen in the aircraft list): its ShipSummary movie,
// driven as EW's UIShipSummary drives it: the callsign, its status in EW's words and colours, its kills, SHIP WEAPON: the
// weapon and its picture, and three buttons: EDIT LOADOUT (the loadout screen, UILWEWShipLoadout; Long War refuses it while
// its ferry restriction holds), DISMISS SHIP (EW's confirmation; not while the craft is away) and Long War's RENAME (a
// pilot from its list, XGLocalizedData.ShipWeaponFlavorTxt[11 + Rand(245)]: "F.O. 'Mad Dog' Wilson", ranked by kills
// after its next kill). Seen through EW's camera on the hangar's summary display (Hangar_UIDisplayCam_Summary).
class UILWEWShipSummary extends UILWEWScreen;

var localized string m_strKillsLabel, m_strWeaponLabel, m_strEditLoadoutBtnHelp, m_strDismissShipBtnHelp, m_strWeaponInfoBtnHelp,
	m_strShipInfoBtnHelp,
	m_strDismissShipConfirmDialogTitle, m_strDismissShipConfirmDialogText, m_strDismissShipConfirmDialogAcceptText;
/** Long War's pilots (XGLocalizedData.ShipWeaponFlavorTxt[11..255]). */
var localized array<string> Pilots;

var int Jet;
var int Focused;

static function Open(XComHQPresentationLayer HQPres, int JetIndex)
{
	local UILWEWShipSummary S;

	DynamicLoadObject(default.UIPackage $ ".ewxShipSummary", class'Object', true);
	S = HQPres.Spawn(class'UILWEWShipSummary', HQPres);
	S.Package = name("/ package/ewxShipSummary/ShipSummary");
	S.MCName = 'theScreen';
	S.Jet = JetIndex;
	HQPres.ScreenStack.Push(S);
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

/** Long War's item number for a craft weapon (XGFacility_Hangar.ShipWeaponToItemType). */
static function int WeaponItemNumber(int Weapon)
{
	return Weapon == 2 ? 116 : (Weapon == 1 ? 117 : 115 + Weapon);
}

simulated function OnInit()
{
	super.OnInit();
	Focused = -1;
	// (UpdateButtonHelp, with the mouse: WEAPON INFO on the left of the movie's help bar, SHIP INFO on the right.)
	HelpButton("helpBarMC", false, 0, Word(m_strWeaponInfoBtnHelp, "WEAPON INFO"), "");
	HelpButton("helpBarMC", true, 1, Word(m_strShipInfoBtnHelp, "SHIP INFO"), "");
	SetTimer(0.1, false, nameof(Fill));
}

/** WEAPON INFO and SHIP INFO: EW's item cards for the craft's weapon and for the craft (OnWeaponItemCard, OnShipItemCard). */
function WeaponCard()
{
	class'UILWEWItemCard'.static.OpenShipWeapon(XComHQPresentationLayer(Movie.Pres), class'XComGameState_LWAirWar'.static.Get().Jets[Jet].Weapon);
}

function CraftCard()
{
	class'UILWEWItemCard'.static.OpenCraft(XComHQPresentationLayer(Movie.Pres), class'XComGameState_LWAirWar'.static.Get().Jets[Jet].Type == 3 ? 3 : 1);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (bIsInited)
		Fill();
}

/** UpdateData and UpdateButtonHelp, every call at once (Movie.Invoke). */
function Fill()
{
	local XComGameState_LWAirWar AirWar;
	local XComGameState_LWAirWar.LWJet J;
	local array<ASValue> Params;
	local int StatusId;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none || Jet < 0 || Jet >= AirWar.Jets.Length)
	{
		CloseScreen();
		return;
	}
	J = AirWar.Jets[Jet];
	switch (J.Status)
	{
	case 0: StatusId = 2; break;
	case 3: case 4: case 5: StatusId = 3; break;
	case 2: case 6: case 7: StatusId = 4; break;
	default: StatusId = 0;
	}
	Params.AddItem(Str(J.Callsign));
	CallNow("SetShipName", Params);
	Params.Length = 0;
	Params.AddItem(Str(Word(m_strWeaponLabel, "SHIP WEAPON:")));
	CallNow("SetWeaponLabel", Params);
	Params.Length = 0;
	Params.AddItem(Str(class'LWHangar'.static.WeaponName(J.Weapon)));
	CallNow("SetWeaponName", Params);
	Params.Length = 0;
	Params.AddItem(Str(EWColoured(class'UILWEWAlert'.static.StatusText(J), StatusId)));
	Params.AddItem(Num(StatusId));
	CallNow("SetShipStatus", Params);
	Params.Length = 0;
	Params.AddItem(Str(Word(m_strKillsLabel, "Confirmed Kills:") @ J.Kills));
	CallNow("SetKills", Params);
	Params.Length = 0;
	Params.AddItem(Str(class'LWX2Pictures'.static.Item(WeaponItemNumber(J.Weapon), "")));
	CallNow("SetWeaponImage", Params);
	ButtonHelp(0, Word(m_strEditLoadoutBtnHelp, "EDIT LOADOUT"), class'LWHangar'.static.FerryRestricted());
	ButtonHelp(1, Word(m_strDismissShipBtnHelp, "DISMISS SHIP"), J.Status == 1 || J.Status == 6);
	// (Long War's third button: its RENAME, under the dismiss dialog's title's key.)
	ButtonHelp(2, Word(m_strDismissShipConfirmDialogTitle, "RENAME"), false);
	Focus(Focused < 0 ? 0 : Focused);
}

function ButtonHelp(int i, string Label, bool bDisabled)
{
	local array<ASValue> Params;
	local ASValue V;

	Params.AddItem(Num(i));
	Params.AddItem(Str(Label));
	Params.AddItem(Str(""));
	V.Type = AS_Boolean;
	V.b = bDisabled;
	Params.AddItem(V);
	CallNow("SetWeaponButtonHelp", Params);
}

/** RealizeSelected: the button with the focus. */
function Focus(int i)
{
	local array<ASValue> Params;
	local ASValue V;

	V.Type = AS_Boolean;
	if (Focused >= 0 && Focused != i)
	{
		Params.AddItem(Num(Focused));
		V.b = false;
		Params.AddItem(V);
		CallNow("SetWeaponButtonFocus", Params);
	}
	Focused = i;
	Params.Length = 0;
	Params.AddItem(Num(Focused));
	V.b = true;
	Params.AddItem(V);
	CallNow("SetWeaponButtonFocus", Params);
}

function Press(int i)
{
	switch (i)
	{
	case 0: EditLoadout(); break;
	case 1: DismissShip(); break;
	case 2: Rename(); break;
	}
}

/** OnEditLoadout: the loadout screen, unless Long War's ferry restriction holds. */
function EditLoadout()
{
	if (class'LWHangar'.static.FerryRestricted())
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	class'UILWEWShipLoadout'.static.Open(XComHQPresentationLayer(Movie.Pres), Jet);
}

/** OnDismissShip: EW's confirmation ("Are you sure you want to dismiss Raven-1?"); refused while the craft is away. */
function DismissShip()
{
	local XComGameState_LWAirWar AirWar;
	local TDialogueBoxData Data;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar.Jets[Jet].Status == 1 || AirWar.Jets[Jet].Status == 6)
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	Data.eType = eDialog_Warning;
	Data.strTitle = Word(m_strDismissShipBtnHelp, "DISMISS SHIP");
	Data.strText = Repl(Word(m_strDismissShipConfirmDialogText, "Are you sure you want to dismiss <XGParam:StrValue0/>?"), "<XGParam:StrValue0/>", AirWar.Jets[Jet].Callsign);
	Data.strAccept = Word(m_strDismissShipConfirmDialogAcceptText, "CONFIRM");
	Data.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Data.fnCallback = OnDismissDialog;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnDismissDialog(Name Action)
{
	local string Why;

	if (Action != 'eUIAction_Accept')
		return;
	if (class'LWHangar'.static.Dismiss(Jet, Why))
	{
		PlaySound(SoundCue'SoundUI.PositiveUISelctionCue', true);
		CloseScreen();
	}
	else
		`log("LongWarX2: EW craft summary:" @ Why, , 'LongWarX2');
}

/** Long War's RENAME: a pilot drawn from its list. */
function Rename()
{
	if (Pilots.Length == 0)
		return;
	class'LWHangar'.static.Rename(Jet, Pilots[Rand(Pilots.Length)]);
	PlaySound(SoundCue'SoundUI.PositiveUISelctionCue', true);
	Fill();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (InStr(Target, "weaponButton_") == 0)
	{
		if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		{
			Press(int(Mid(Target, 13)));
			return;
		}
		if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN)
			Focus(int(Mid(Target, 13)));
	}
	super.OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local string Help;

	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
			Help = HelpButtonUnderMouse();
			if (Help == "")
				break;
			// (The lookup gives the bar and the button: buttonHelp_0 the left one, buttonHelp_1 the right.)
			if (Right(Help, 1) == "0")
				WeaponCard();
			else
				CraftCard();
			return true;
		// (UIShipSummary: the right stick or Tab for the weapon's card.)
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
			WeaponCard();
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			Focus(Focused <= 0 ? 2 : Focused - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			Focus(Focused >= 2 ? 0 : Focused + 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Press(Focused);
			return true;
		}
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	BaseCamera = HANGAR
}
