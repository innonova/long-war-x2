// Enemy Within's own Build Facilities screen over its base (features/lw-base-view.md): its BuildFacilities movie, driven as
// EW's UIBuildFacilities drives it (SetTitle; UpdateFacilityCard per tile: column, row, label, icon, disabled, adjacency left
// and top; SetCursor: column, row, text, state), seen through EW's camera for it (Expansion: the whole base). The rules are
// Long War's base (LWBase.Work): a rock tile chosen is excavated, an empty one in the shaft gets an access lift, an empty
// one elsewhere opens EW's ChooseFacility (UILWEWChooseFacility); a tile out of reach says why, as EW's cursor does.
// Arrows move the cursor, Enter or a click chooses, Escape closes.
class UILWEWBuildFacilities extends UILWEWScreen;

/** EW's words, written from the player's install (scripts/lw-words.mjs, makeBuildWords). */
var localized string Title, Excavate, Excavating, BuildLift, BuildFacility, Steam, Days, Cost, RequiredBuild;
var localized string ErrNeedLift, ErrNeedExcavating, ErrNeedFunds, ErrNeedPower, ErrNeedSteam, NoRequirements;

var int CursorX, CursorY;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWBuildFacilities EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxBuildFacilities", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWBuildFacilities', HQPres);
	EWScreen.Package = name("/ package/ewxBuildFacilities/BuildFacilities");
	EWScreen.MCName = 'theBuildFacilitiesScreen';
	HQPres.ScreenStack.Push(EWScreen);
}

/** Whether EW's screens and base are here (else the plain base screen, UILWBase, serves). */
static function bool Available()
{
	return class'UILWEWScreen'.static.HasEWScreens() && class'LWX2EWBase'.static.Converted();
}

simulated function OnInit()
{
	super.OnInit();
	MC.FunctionString("SetTitle", class'UILWEWHub'.static.Word(Title, "BUILD FACILITIES"));
	CursorX = class'LWBase'.const.SHAFT;
	CursorY = 1;
	ShowBase();
	Refresh();
}

/** EW's base through its camera for building. */
function ShowBase()
{
	local LWX2EWBase B;

	B = class'LWX2EWBase'.static.Get(self);
	B.Show();
	B.LookAt('Expansion', 1.0);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (!bIsInited)
		return;
	ShowBase();
	Refresh();
}

/** Every card and the cursor, from the Long War base. */
function Refresh()
{
	local XComGameState_LWStrategy S;
	local int TX, TY;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.TileType.Length < class'LWBase'.const.W * class'LWBase'.const.H)
		return;
	for (TY = 1; TY < class'LWBase'.const.H; TY++)
		for (TX = 0; TX < class'LWBase'.const.W; TX++)
			Card(S, TX, TY);
	Cursor(S);
}

/** A tile's card, as EW's BuildBaseTile and BuildFacilityTile make them. */
function Card(XComGameState_LWStrategy S, int TX, int TY)
{
	local string Label, Icon;
	local int Job, Type, i;

	i = TY * class'LWBase'.const.W + TX;
	Type = S.TileType[i];
	Job = class'LWBase'.static.JobAt(S, TX, TY);
	if (Job >= 0)
	{
		Icon = S.BaseJobs[Job].Kind == 0 ? "BeingExcavated" : "Construction";
		Label = (S.BaseJobs[Job].Kind == 0 ? class'UILWEWHub'.static.Word(Excavating, "EXCAVATING") : Caps(class'LWBase'.static.FacilityName(S.BaseJobs[Job].Facility)))
			$ "<br>" $ DaysText((S.BaseJobs[Job].HoursLeft + 23) / 24);
	}
	else if (Type == class'LWBase'.const.BUILT)
	{
		if (S.TileFacility[i] == 0)
			return;
		Icon = FacilityIcon(S.TileFacility[i]);
		Label = Caps(class'LWBase'.static.FacilityName(S.TileFacility[i]));
	}
	else if (Type == class'LWBase'.const.ROCK)
		Icon = "Rock";
	else if (Type == class'LWBase'.const.ROCK_STEAM)
	{
		Icon = "RockSteam";
		Label = class'UILWEWHub'.static.Word(Steam, "STEAM");
	}
	else
	{
		Icon = "Excavated";
		if (Type == class'LWBase'.const.DUG_STEAM)
			Label = class'UILWEWHub'.static.Word(Steam, "STEAM");
	}
	MC.BeginFunctionOp("UpdateFacilityCard");
	MC.QueueNumber(TX);
	MC.QueueNumber(TY);
	MC.QueueString(Label);
	MC.QueueString(Icon);
	MC.QueueBoolean(false);
	MC.QueueBoolean(false);
	MC.QueueBoolean(false);
	MC.EndOp();
}

function string DaysText(int N)
{
	local XGParamTag Tag;

	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	if (Days == "" || Tag == none)
		return N @ "days";
	Tag.IntValue0 = N;
	return `XEXPAND.ExpandString(Days);
}

/** EW's facility image label (UIUtilities.GetFacilityLabel) for a Long War facility (EW's facility numbers). */
static function string FacilityIcon(int Facility)
{
	switch (Facility)
	{
	case 6: return "AccessLift";
	case 7: return "Laboratories";
	case 8: return "Workshops";
	case 9: return "SatelliteUplink";
	case 10: return "PowerGenerator";
	case 11: return "Foundry";
	case 12: return "OfficerTrainingSchool";
	case 13: return "AlienContainment";
	case 14: return "SatelliteNexusUplink";
	case 15: return "ThermalPowerGenerator";
	case 16: return "EleriumGenerator";
	case 17: return "PsionicLabs";
	case 18: return "HyperwaveUplink";
	case 19: return "GollopChamber";
	case 22: return "CyberneticsLab";
	case 23: return "GeneLab";
	}
	return "Unknown";
}

/** What choosing the cursor's tile does, as EW's cursor says it (and its cost), or why it cannot (Why). State: 0 able, else
 *  out of reach or nothing to do. */
function int CursorAction(XComGameState_LWStrategy S, out string Text)
{
	local int Type;

	Text = "";
	if (class'LWBase'.static.JobAt(S, CursorX, CursorY) >= 0)
		return 2;
	Type = S.TileType[CursorY * class'LWBase'.const.W + CursorX];
	if (Type == class'LWBase'.const.BUILT)
		return 2;
	if (!class'LWBase'.static.Reachable(S, CursorX, CursorY))
	{
		Text = class'UIUtilities_Text'.static.GetColoredText(class'LWBase'.static.HasAccess(S, CursorX, CursorY)
			? class'UILWEWHub'.static.Word(ErrNeedExcavating, "Dig the way here first.") : class'UILWEWHub'.static.Word(ErrNeedLift, "It needs an access lift on this level."), eUIState_Bad);
		return 1;
	}
	if (Type == class'LWBase'.const.ROCK || Type == class'LWBase'.const.ROCK_STEAM)
	{
		Text = class'UILWEWHub'.static.Word(Excavate, "EXCAVATE") $ "<br>" $ class'UILWEWHub'.static.Word(Cost, "Cost:") @ class'LWStrategyRules'.static.Money(class'LWBase'.static.DigCost(CursorY));
		return 0;
	}
	Text = CursorX == class'LWBase'.const.SHAFT ? class'UILWEWHub'.static.Word(BuildLift, "BUILD ACCESS LIFT") : class'UILWEWHub'.static.Word(BuildFacility, "BUILD FACILITY");
	return 0;
}

function Cursor(XComGameState_LWStrategy S)
{
	local string Text;
	local int Action;

	Action = CursorAction(S, Text);
	MC.BeginFunctionOp("SetCursor");
	MC.QueueNumber(CursorX);
	MC.QueueNumber(CursorY);
	MC.QueueString(Text);
	MC.QueueNumber(Action == 1 ? 3 : 0);
	MC.EndOp();
}

function MoveCursor(int DX, int DY)
{
	CursorX = Clamp(CursorX + DX, 0, class'LWBase'.const.W - 1);
	CursorY = Clamp(CursorY + DY, 1, class'LWBase'.const.H - 1);
	Cursor(class'XComGameState_LWStrategy'.static.Get());
}

/** The cursor's tile chosen: excavated, an access lift begun, or EW's facility choice opened. */
function Choose()
{
	local XComGameState_LWStrategy S;
	local string Text, Why;
	local int Type;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (CursorAction(S, Text) != 0)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Type = S.TileType[CursorY * class'LWBase'.const.W + CursorX];
	if (Type != class'LWBase'.const.ROCK && Type != class'LWBase'.const.ROCK_STEAM && CursorX != class'LWBase'.const.SHAFT)
	{
		class'UILWEWChooseFacility'.static.Open(XComHQPresentationLayer(Movie.Pres), CursorX, CursorY);
		return;
	}
	if (class'LWBase'.static.Work(CursorX, CursorY, CursorX == class'LWBase'.const.SHAFT ? 6 : 0, Why))
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		`log("LongWarX2: EW base building:" @ Why, , 'LongWarX2');
	}
	UpdateResources();
	Refresh();
}

function UpdateResources()
{
	if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
	class'UILWEWStrategyHUD'.static.ShowIfAvailable();
}

/** The card under the mouse (its column and row), or false: EW's clips do not report their clicks to XCOM 2. */
function bool CardUnderMouse(out int TX, out int TY)
{
	local int i, j;

	for (j = 1; j < class'LWBase'.const.H; j++)
	{
		for (i = 0; i < class'LWBase'.const.W; i++)
		{
			// (The movie names each card card_<column>_<row>.)
			if (MouseOver(MCPath $ ".card_" $ i $ "_" $ j))
			{
				TX = i;
				TY = j;
				return true;
			}
		}
	}
	return false;
}

function bool MouseOver(string Path)
{
	local float MouseX, MouseY, W, H;

	W = Movie.GetVariableNumber(Path $ "._width");
	H = Movie.GetVariableNumber(Path $ "._height");
	MouseX = Movie.GetVariableNumber(Path $ "._xmouse");
	MouseY = Movie.GetVariableNumber(Path $ "._ymouse");
	return W > 0 && MouseX >= 0 && MouseY >= 0 && MouseX <= W && MouseY <= H;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;
	local int TX, TY;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	// (card_<column>_<row>: EW's SetCursorAt reads the first and the last character.)
	if (Left(Target, 5) == "card_" && Len(Target) == 8)
	{
		TX = int(Mid(Target, 5, 1));
		TY = int(Mid(Target, 7, 1));
		if (cmd == 392)
		{
			CursorX = TX;
			CursorY = TY;
			Cursor(class'XComGameState_LWStrategy'.static.Get());
		}
		else if (cmd == 391 || cmd == 398)
		{
			CursorX = TX;
			CursorY = TY;
			Choose();
		}
	}
	super(UIScreen).OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int TX, TY;

	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
		if (CardUnderMouse(TX, TY))
		{
			CursorX = TX;
			CursorY = TY;
			Choose();
			return true;
		}
		break;
	case class'UIUtilities_Input'.const.FXS_ARROW_UP:
	case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		MoveCursor(0, -1);
		return true;
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		MoveCursor(0, 1);
		return true;
	case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		MoveCursor(-1, 0);
		return true;
	case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		MoveCursor(1, 0);
		return true;
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		Choose();
		return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	bShowsBase = true
}
