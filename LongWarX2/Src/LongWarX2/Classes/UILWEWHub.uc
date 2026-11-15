// The Long War hub (features/lw-base-view.md), on Enemy Within's layout: EW's base in view (LWX2EWBase), EW's rooms across
// the top and MISSION CONTROL above the clock, from EW's own strategy HUD movie, driven as EW's UIStrategyHUD drives it
// (its facilityMenu: AddMenuOption, SetFocus, DimAllUnselectedMenuOptions; SetHotlink, a click on missionControlButton).
// Choosing a room does what EW does: the camera moves to the room (its camera in EW's base) and the room's menu shows; an
// option opens its screen. Back (Escape, the room chosen again) returns to the base's view; Escape there closes the hub.
// The rooms: research (EW's research screen), engineering (items, facilities, the Foundry once it is built), the barracks
// (XCOM 2's soldier list and armory), the hangar, the Situation Room (its overview, the grey market). Mission Control is
// the Long War Geoscape (time, decisions, the council). The resources, clock and events stay on UILWEWStrategyHUD.
//
// The room's menu is XCOM 2's list at EW's submenu place: EW's own submenu clip (subMenuMC) takes its options but creates
// none, its option symbol coming from EW's shared components movie, which does not resolve here.
class UILWEWHub extends UILWEWScreen config(LWEWMaps);

/** The hub in place of the Geoscape as the strategy layer's root (off while it is being made: features/lw-base-view.md). */
var config bool Enabled;

/** EW's words, written from the player's install (scripts/lw-words.mjs, makeHubWords). */
var localized string RoomNames[5];
var localized string MissionControlName;
var localized string NewResearch, BuildItems, BuildItemsHelp, BuildFacilities, BuildFacilitiesHelp, Foundry, FoundryHelp;
var localized string ViewSoldiers, ViewSoldiersHelp, AircraftList, AircraftListHelp, SituationRoom, GreyMarket, GreyMarketHelp;

/** Each room's camera in EW's base (Command1's, by tag), in the order of the top menu. */
var array<name> RoomCameras;
/** Words when the setup has not written EW's (each in the order of RoomNames, then the options' keys). */
var array<string> FallbackRooms;

/** The room entered (-1: the base's view), its options (OPT_ consts) and the list showing them. */
var int Room;
var array<int> RoomOptions;
var UIList RoomList;
var UIText RoomHelp;

const OPT_RESEARCH = 0;
const OPT_ITEMS = 1;
const OPT_FACILITIES = 2;
const OPT_FOUNDRY = 3;
const OPT_SOLDIERS = 4;
const OPT_AIRCRAFT = 5;
const OPT_SITROOM = 6;
const OPT_GREYMARKET = 7;

/** Long War's Foundry facility (LWBase's facility numbers: EW's eFacility_Foundry). */
const FACILITY_FOUNDRY = 11;

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

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	// The room's menu where EW's submenu stands (below the top menu, at the left).
	RoomList = Spawn(class'UIList', self);
	RoomList.InitList('LWHubRoomMenu', 60, 120, 420, 300);
	RoomList.OnItemClicked = OnRoomOptionClicked;
	RoomList.Hide();
	RoomHelp = Spawn(class'UIText', self);
	RoomHelp.InitText('LWHubRoomHelp', "", false);
	RoomHelp.SetPosition(60, 430);
	RoomHelp.SetWidth(420);
	RoomHelp.Hide();
}

simulated function OnInit()
{
	local int i;

	super.OnInit();
	Room = -1;
	// Only the menu and Mission Control: the HUD shown beside this one has the resources, the clock and the events.
	MC.FunctionVoid("HideTicker");
	HideHUDParts();
	for (i = 0; i < RoomCameras.Length; i++)
	{
		MC.BeginChildFunctionOp("theMenu.facilityMenu", "AddMenuOption");
		MC.QueueNumber(i);
		MC.QueueString(RoomName(i));
		MC.QueueBoolean(false);
		MC.EndOp();
	}
	MC.ChildFunctionVoid("theMenu.facilityMenu", "onReceiveFocus");
	// EW's Mission Control button above the clock (its second, the Gollop Chamber's, left empty).
	MC.BeginFunctionOp("SetHotlink");
	MC.QueueString(Word(MissionControlName, "MISSION CONTROL"));
	MC.QueueString("");
	MC.QueueBoolean(false);
	MC.QueueString("");
	MC.QueueString("");
	MC.QueueBoolean(false);
	MC.EndOp();
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

static function string Word(string Localized, string Fallback)
{
	return Localized != "" ? Localized : Fallback;
}

function string RoomName(int i)
{
	return Word(RoomNames[i], FallbackRooms[i]);
}

/** The base in view, through the room's camera when a room is entered. */
function ShowBase()
{
	local LWX2EWBase B;

	B = class'LWX2EWBase'.static.Get(self);
	B.Show();
	if (Room >= 0)
		B.LookAt(RoomCameras[Room], 0);
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
	for (i = 0; i < RoomCameras.Length; i++)
	{
		Widths.AddItem(Movie.GetVariableNumber(MCPath $ ".theMenu.facilityMenu." $ i $ "._width"));
		Width += Widths[i] + (i > 0 ? Gap : 0.0);
	}
	X = -Width / 2 - Movie.GetVariableNumber(MCPath $ ".theMenu.facilityMenu._x");
	for (i = 0; i < RoomCameras.Length; i++)
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

/** A room chosen from the top menu: the camera into it and its menu shown (chosen again: back to the base's view). */
function EnterRoom(int i)
{
	local XComGameState_LWStrategy S;
	local int k;

	if (i == Room)
	{
		LeaveRoom();
		return;
	}
	`log("LongWarX2: Long War hub: room" @ RoomName(i), , 'LongWarX2');
	Room = i;
	MC.ChildFunctionString("theMenu.facilityMenu", "setFocus", string(i));
	MC.ChildFunctionVoid("theMenu.facilityMenu", "DimAllUnselectedMenuOptions");
	class'LWX2EWBase'.static.Get(self).LookAt(RoomCameras[i], 1.0);
	RoomOptions.Length = 0;
	switch (i)
	{
	case 0:
		RoomOptions.AddItem(OPT_RESEARCH);
		break;
	case 1:
		RoomOptions.AddItem(OPT_ITEMS);
		RoomOptions.AddItem(OPT_FACILITIES);
		// (As EW: the Foundry once its facility is built.)
		S = class'XComGameState_LWStrategy'.static.Get();
		if (S != none && class'LWBase'.static.Count(S, FACILITY_FOUNDRY) > 0)
			RoomOptions.AddItem(OPT_FOUNDRY);
		break;
	case 2:
		RoomOptions.AddItem(OPT_SOLDIERS);
		break;
	case 3:
		RoomOptions.AddItem(OPT_AIRCRAFT);
		break;
	case 4:
		RoomOptions.AddItem(OPT_SITROOM);
		RoomOptions.AddItem(OPT_GREYMARKET);
		break;
	}
	RoomList.ClearItems();
	for (k = 0; k < RoomOptions.Length; k++)
		Spawn(class'UIListItemString', RoomList.itemContainer).InitListItem(Caps(OptionName(RoomOptions[k])));
	RoomList.Show();
	RoomList.SetSelectedIndex(0);
	RoomHelp.SetText(OptionHelp(RoomOptions[0]));
	RoomHelp.Show();
}

/** Back to the base's view. */
function LeaveRoom()
{
	Room = -1;
	RoomList.Hide();
	RoomHelp.Hide();
	MC.ChildFunctionVoid("theMenu.facilityMenu", "RestoreOpacityToAllMenuOptions");
	class'LWX2EWBase'.static.Get(self).LookAt('Base', 1.0);
}

function string OptionName(int Option)
{
	switch (Option)
	{
	case OPT_RESEARCH: return Word(NewResearch, "Start a research project");
	case OPT_ITEMS: return Word(BuildItems, "Build items");
	case OPT_FACILITIES: return Word(BuildFacilities, "Build facilities");
	case OPT_FOUNDRY: return Word(Foundry, "Foundry");
	case OPT_SOLDIERS: return Word(ViewSoldiers, "Soldiers");
	case OPT_AIRCRAFT: return Word(AircraftList, "Aircraft");
	case OPT_SITROOM: return Word(SituationRoom, "Situation Room");
	case OPT_GREYMARKET: return Word(GreyMarket, "Grey market");
	}
	return "";
}

function string OptionHelp(int Option)
{
	switch (Option)
	{
	case OPT_ITEMS: return BuildItemsHelp;
	case OPT_FACILITIES: return BuildFacilitiesHelp;
	case OPT_FOUNDRY: return FoundryHelp;
	case OPT_SOLDIERS: return ViewSoldiersHelp;
	case OPT_AIRCRAFT: return AircraftListHelp;
	case OPT_GREYMARKET: return GreyMarketHelp;
	}
	return "";
}

function OnRoomOptionClicked(UIList ContainerList, int ItemIndex)
{
	if (ItemIndex >= 0 && ItemIndex < RoomOptions.Length)
		ChooseOption(RoomOptions[ItemIndex]);
}

/** A room's option: its screen opened over the hub. */
function ChooseOption(int Option)
{
	local XComHQPresentationLayer HQPres;

	HQPres = XComHQPresentationLayer(Movie.Pres);
	`log("LongWarX2: Long War hub: option" @ OptionName(Option), , 'LongWarX2');
	switch (Option)
	{
	case OPT_RESEARCH: class'UILWEWResearch'.static.Open(); break;
	case OPT_ITEMS: class'UILWEWEngineering'.static.Open(HQPres); break;
	case OPT_FACILITIES: HQPres.ScreenStack.Push(HQPres.Spawn(class'UILWBase', HQPres)); break;
	case OPT_FOUNDRY: class'UILWEWEngineering'.static.Open(HQPres, true); break;
	case OPT_SOLDIERS:
		// (The Avenger back first: the armory stands the soldier in its room as it opens.)
		class'LWX2EWBase'.static.Get(self).Hide();
		HQPres.UIPersonnel_Armory(OnSoldierChosen);
		break;
	case OPT_AIRCRAFT: class'UILWEWHangar'.static.Open(HQPres); break;
	case OPT_SITROOM: class'UILWEWSituationRoom'.static.Open(); break;
	case OPT_GREYMARKET: class'UILWEWGreyMarket'.static.Open(HQPres); break;
	}
}

/** Mission Control: the Long War Geoscape. */
function EnterMissionControl()
{
	local XComHQPresentationLayer HQPres;

	`log("LongWarX2: Long War hub: Mission Control", , 'LongWarX2');
	HQPres = XComHQPresentationLayer(Movie.Pres);
	HQPres.ScreenStack.Push(HQPres.Spawn(class'UILWGeoscape', HQPres));
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
	if (cmd == 391 && args.Length > 0 && args[args.Length - 1] == "missionControlButton")
		EnterMissionControl();
	else if (cmd == 391 && args.Length > 1 && InStr(S, "facilityMenu") != INDEX_NONE)
		EnterRoom(int(args[args.Length - 2]));
	super(UIScreen).OnMouseEvent(cmd, args);
}

/** Whether the mouse is over a clip of the movie (its own coordinates against its size; nudge: that much above its box
 *  counts too, a share of its height). EW's clips do not report their clicks to XCOM 2 (their input code is EW's). */
function bool MouseOver(string Path, optional float Nudge)
{
	local float MouseX, MouseY, W, H;

	W = Movie.GetVariableNumber(Path $ "._width");
	H = Movie.GetVariableNumber(Path $ "._height");
	MouseX = Movie.GetVariableNumber(Path $ "._xmouse");
	MouseY = Movie.GetVariableNumber(Path $ "._ymouse");
	return W > 0 && MouseX >= 0 && MouseY >= -H * Nudge && MouseX <= W && MouseY <= H;
}

/** The top menu's room under the mouse, or -1. */
function int RoomUnderMouse()
{
	local int i;

	for (i = 0; i < RoomCameras.Length; i++)
		// (The tab is drawn a little above its clip's box: half its height above counts too.)
		if (MouseOver(MCPath $ ".theMenu.facilityMenu." $ i, 0.5))
			return i;
	return -1;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int i;

	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		i = RoomUnderMouse();
		if (i >= 0)
		{
			EnterRoom(i);
			return true;
		}
		// (The movie's Mission Control button is centred on its clip's origin: x from minus half its width.)
		if (MouseOver(MCPath $ ".hotlinkMC.missionControlButton"))
		{
			EnterMissionControl();
			return true;
		}
	}
	// Escape: out of the room, back to the base's view; at the base's view, the hub closed, back to XCOM 2's Avenger.
	if (cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE || cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B)
	{
		if (Room >= 0)
			LeaveRoom();
		else
			CloseScreen();
		return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	// The HUD places itself by the stage's edges.
	bScaleToStage = false
	RoomCameras(0) = ScienceLab
	RoomCameras(1) = ENGINEERING
	RoomCameras(2) = BARRACKS
	RoomCameras(3) = HANGAR
	RoomCameras(4) = Cam_SituationRoom
	FallbackRooms(0) = "RESEARCH"
	FallbackRooms(1) = "ENGINEERING"
	FallbackRooms(2) = "BARRACKS"
	FallbackRooms(3) = "HANGAR"
	FallbackRooms(4) = "SITUATION ROOM"
}
