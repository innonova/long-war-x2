// The Long War hub (features/lw-base-view.md): Enemy Within's base in view (LWX2EWBase) and EW's room menu on the left,
// from its own strategy HUD movie (its facilityMenu, driven as EW's UIStrategyHUD_FacilityMenu drives it: AddMenuOption,
// SetFocus, DimAllUnselectedMenuOptions; a click 391 names its option second to last). Each room opens its screen:
// Mission Control the Long War Geoscape (time, decisions, the council), the Situation Room, research, engineering, the
// Foundry, the barracks (XCOM 2's armory, as its armory facility opens it), the hangar, the base's building, the grey
// market. The resources, clock and events stay on the HUD over it (UILWEWStrategyHUD).
class UILWEWHub extends UILWEWScreen config(LWEWMaps);

var array<string> Options;
/** The hub in place of the Geoscape as the strategy layer's root (off while it is being made: features/lw-base-view.md). */
var config bool Enabled;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWHub Hub;

	if (HQPres.ScreenStack.IsInStack(class'UILWEWHub'))
		return;
	DynamicLoadObject(default.UIPackage $ ".ewxStrategyHUD", class'Object', true);
	Hub = HQPres.Spawn(class'UILWEWHub', HQPres);
	Hub.Package = name("/ package/ewxStrategyHUD/StrategyHUD");
	Hub.MCName = 'theStrategyHUD';
	HQPres.ScreenStack.Push(Hub);
	`log("LongWarX2: Long War hub shown", , 'LongWarX2');
}

simulated function OnInit()
{
	local int i;

	super.OnInit();
	// Only the menu: the HUD shown beside this one has the resources, the clock and the events.
	MC.FunctionVoid("HideTicker");
	MC.FunctionVoid("HideHotlink");
	HideHUDParts();
	for (i = 0; i < Options.Length; i++)
	{
		MC.BeginChildFunctionOp("theMenu.facilityMenu", "AddMenuOption");
		MC.QueueNumber(i);
		MC.QueueString(Options[i]);
		MC.QueueBoolean(false);
		MC.EndOp();
	}
	MC.ChildFunctionVoid("theMenu.facilityMenu", "onReceiveFocus");
	class'LWX2EWBase'.static.Get(self).Show();
	// The movie lays its menu out once its items have loaded, which it does not do here (each stays at 0): laid out in a
	// row, centred, once they have their sizes; and the parts the HUD beside this one shows hidden (the movie shows them
	// again as it lays itself out).
	SetTimer(0.5, false, nameof(LayOutMenu));
	SetTimer(0.5, true, nameof(HideHUDParts));
	// The view asked for again a moment later: a screen closed just before (the start screen) sends XCOM 2's camera back
	// to the Avenger after this. And the HUD with the resources and clock over this.
	SetTimer(0.6, false, nameof(ShowBase));
	ShowAvengerButton(false);
}

function ShowBase()
{
	class'LWX2EWBase'.static.Get(self).Show();
	class'UILWEWStrategyHUD'.static.ShowIfAvailable();
}

/** The Avenger's LONG WAR GEOSCAPE button (UIScreenListener_LongWarX2HQ) is drawn above this screen: hidden while it is up. */
simulated function ShowAvengerButton(bool bShow)
{
	local UIScreen Hud;
	local UIPanel Button;

	Hud = Movie.Pres.ScreenStack.GetScreen(class'UIAvengerHUD');
	Button = Hud != none ? Hud.GetChildByName('LWX2HQButton', false) : none;
	if (Button != none)
		Button.SetVisible(bShow);
}

function LayOutMenu()
{
	local float X, Width, Gap;
	local array<float> Widths;
	local int i;

	Gap = 8;
	for (i = 0; i < Options.Length; i++)
	{
		Widths.AddItem(Movie.GetVariableNumber(MCPath $ ".theMenu.facilityMenu." $ i $ "._width"));
		Width += Widths[i] + (i > 0 ? Gap : 0.0);
	}
	X = -Width / 2 - Movie.GetVariableNumber(MCPath $ ".theMenu.facilityMenu._x");
	for (i = 0; i < Options.Length; i++)
	{
		Movie.SetVariableNumber(MCPath $ ".theMenu.facilityMenu." $ i $ "._x", X);
		X += Widths[i] + Gap;
	}
}

function HideHUDParts()
{
	Movie.SetVariableBool(MCPath $ ".theClock._visible", false);
	Movie.SetVariableBool(MCPath $ ".theEventList._visible", false);
	Movie.SetVariableBool(MCPath $ ".engineeringQueue._visible", false);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (!bIsInited)
		return;
	MC.ChildFunctionVoid("theMenu.facilityMenu", "onReceiveFocus");
	ShowBase();
	SetTimer(0.6, false, nameof(ShowBase));
	ShowAvengerButton(false);
}

/** Another screen over the hub: the Avenger back (the armory and squad select stand their soldiers in its rooms; EW's
 *  screens put their own backdrop over it); the base again when the hub has focus back. */
simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	ClearTimer(nameof(ShowBase));
	class'LWX2EWBase'.static.Get(self).Hide();
}

simulated function OnRemoved()
{
	class'LWX2EWBase'.static.Get(self).Hide();
	ShowAvengerButton(true);
	super.OnRemoved();
}

/** A room chosen: its screen opened over the hub. */
function Choose(int i)
{
	local XComHQPresentationLayer HQPres;

	HQPres = XComHQPresentationLayer(Movie.Pres);
	`log("LongWarX2: Long War hub: room" @ i, , 'LongWarX2');
	switch (i)
	{
	case 0: HQPres.ScreenStack.Push(HQPres.Spawn(class'UILWGeoscape', HQPres)); break;
	case 1: class'UILWEWSituationRoom'.static.Open(); break;
	case 2: class'UILWEWResearch'.static.Open(); break;
	case 3: class'UILWEWEngineering'.static.Open(HQPres); break;
	case 4: class'UILWEWEngineering'.static.Open(HQPres, true); break;
	case 5:
		// (The Avenger back first: the armory stands the soldier in its room as it opens.)
		class'LWX2EWBase'.static.Get(self).Hide();
		HQPres.UIPersonnel_Armory(OnSoldierChosen);
		break;
	case 6: class'UILWEWHangar'.static.Open(HQPres); break;
	case 7: HQPres.ScreenStack.Push(HQPres.Spawn(class'UILWBase', HQPres)); break;
	case 8: class'UILWEWGreyMarket'.static.Open(HQPres); break;
	}
}

/** The barracks: a soldier chosen opens XCOM 2's armory on them (as its armory facility does). */
function OnSoldierChosen(StateObjectReference UnitRef)
{
	`HQPRES.UIArmory_MainMenu(UnitRef);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string S;
	local int i;

	S = "";
	for (i = 0; i < args.Length; i++)
		S @= args[i];
	if (cmd == 391 && args.Length > 1 && InStr(S, "facilityMenu") != INDEX_NONE)
		Choose(int(args[args.Length - 2]));
	super(UIScreen).OnMouseEvent(cmd, args);
}

/** The menu option under the mouse, or -1: EW's menu items do not report their clicks to XCOM 2 (their input code is
 *  EW's), so each item's clip is asked where the mouse is, in its own coordinates (as UILWEWResearch does). */
function int OptionUnderMouse()
{
	local string Path;
	local float MouseX, MouseY, W, H;
	local int i;

	for (i = 0; i < Options.Length; i++)
	{
		Path = MCPath $ ".theMenu.facilityMenu." $ i;
		W = Movie.GetVariableNumber(Path $ "._width");
		H = Movie.GetVariableNumber(Path $ "._height");
		MouseX = Movie.GetVariableNumber(Path $ "._xmouse");
		MouseY = Movie.GetVariableNumber(Path $ "._ymouse");
		// (The tab is drawn a little above its clip's box: half its height above counts too.)
		if (W > 0 && MouseX >= 0 && MouseY >= -H / 2 && MouseX <= W && MouseY <= H)
			return i;
	}
	return -1;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int i;

	if ((cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP) && (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		i = OptionUnderMouse();
		if (i >= 0)
		{
			Choose(i);
			return true;
		}
	}
	// Escape closes the hub, back to XCOM 2's Avenger (as the Geoscape's CLOSE did).
	if ((cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE || cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B) && (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		CloseScreen();
		return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	// The HUD places itself by the stage's edges.
	bScaleToStage = false
	Options(0) = "MISSION CONTROL"
	Options(1) = "SITUATION ROOM"
	Options(2) = "RESEARCH"
	Options(3) = "ENGINEERING"
	Options(4) = "FOUNDRY"
	Options(5) = "BARRACKS"
	Options(6) = "HANGAR"
	Options(7) = "BASE"
	Options(8) = "GREY MARKET"
}
