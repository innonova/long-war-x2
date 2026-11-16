// The Long War hub (features/lw-base-view.md), on Enemy Within's layout: EW's base in view (LWX2EWBase), EW's rooms across
// the top and MISSION CONTROL above the clock, from EW's own strategy HUD movie, driven as EW's UIStrategyHUD drives it
// (its facilityMenu: AddMenuOption, SetFocus, DimAllUnselectedMenuOptions; SetHotlink, a click on missionControlButton).
// Choosing a room does what EW does: the camera moves to the room (its camera in EW's base) and the room's menu shows; an
// option opens its screen. Back (Escape, the room chosen again) returns to the base's view; Escape there closes the hub.
// The rooms: research (EW's research screen), engineering (items, facilities, the Foundry once it is built), the barracks
// (XCOM 2's soldier list and armory), the hangar, the Situation Room (its overview, the grey market). Mission Control is
// the Long War Geoscape (time, decisions, the council). The resources, clock and events stay on UILWEWStrategyHUD.
//
// The room's menu is EW's own submenu (subMenuMC), as EW's UIStrategyHUD_FacilitySubMenu drives it: attached to the room's
// tab (facilityMenu.setFocus), its options (clear, AddOption, Show), the selected one's help (setFocus, SetHelpText). Its
// calls go at once (Movie.Invoke): queued through MC, setFocus found no tab.
class UILWEWHub extends UILWEWScreen config(LWEWMaps);

/** The hub in place of the Geoscape as the strategy layer's root (off while it is being made: features/lw-base-view.md). */
var config bool Enabled;

/** EW's words, written from the player's install (scripts/lw-words.mjs, makeHubWords). */
var localized string RoomNames[5];
var localized string MissionControlName;
var localized string NewResearch, BuildItems, BuildItemsHelp, BuildFacilities, BuildFacilitiesHelp, Foundry, FoundryHelp;
var localized string ViewSoldiers, ViewSoldiersHelp, AircraftList, AircraftListHelp, SituationRoom, GreyMarket, GreyMarketHelp;
var localized string PsiLabs, PsiLabsHelp, OTS, OTSHelp;

/** Each room's camera in EW's base (Command1's, by tag), in the order of the top menu. */
var array<name> RoomCameras;
/** Words when the setup has not written EW's (each in the order of RoomNames, then the options' keys). */
var array<string> FallbackRooms;

/** The room entered (-1: the base's view), its options (OPT_ consts) and the one selected in EW's submenu. */
var int Room;
var array<int> RoomOptions;
var int RoomSelected;

const OPT_RESEARCH = 0;
const OPT_ITEMS = 1;
const OPT_FACILITIES = 2;
const OPT_FOUNDRY = 3;
const OPT_SOLDIERS = 4;
const OPT_AIRCRAFT = 5;
const OPT_SITROOM = 6;
const OPT_GREYMARKET = 7;
const OPT_OTS = 8;
const OPT_PSI = 9;
const OPT_GENE = 10;
const OPT_OFFICERS = 11;
const OPT_EXALT = 12;

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
	// (As the Geoscape does: a mission come back counted, its wounds and fatigue; the hub is the strategy layer's root.)
	class'XComGameState_LWStrategy'.static.Arrived();
}

/** The room's options in EW's submenu under its tab, the first selected. */
function ShowRoomMenu()
{
	local array<ASValue> Params;
	local int k;

	CallNow("subMenuMC.clear");
	for (k = 0; k < RoomOptions.Length; k++)
	{
		Params.Length = 0;
		Params.AddItem(Num(k));
		Params.AddItem(Str(Caps(OptionName(RoomOptions[k]))));
		Params.AddItem(Num(0));
		CallNow("subMenuMC.AddOption", Params);
	}
	CallNow("subMenuMC.Show");
	// (Show waits for a frame on the hidden clip, which XCOM 2's Flash does not advance: shown at once.)
	CallNow("subMenuMC.onInvalidate");
	CallNow("subMenuMC.UpdateLocation");
	SelectOption(0);
	SetTimer(0.15, true, nameof(HoverOption));
}

/** The option under the mouse selected, its help shown, as in EW (the submenu's own mouse events do not reach XCOM 2:
 *  they name no panel of its). */
function HoverOption()
{
	local int k;

	k = OptionUnderMouse();
	if (k >= 0 && k != RoomSelected)
		SelectOption(k);
}

/** An option of the room's menu selected: EW's highlight and its help. */
function SelectOption(int k)
{
	local array<ASValue> Params;

	if (RoomOptions.Length == 0)
		return;
	RoomSelected = Clamp(k, 0, RoomOptions.Length - 1);
	Params.AddItem(Str(string(RoomSelected)));
	CallNow("subMenuMC.setFocus", Params);
	Params.Length = 0;
	Params.AddItem(Str(OptionHelp(RoomOptions[RoomSelected])));
	CallNow("subMenuMC.SetHelpText", Params);
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
	// The parts the HUD beside this one shows, hidden (the movie shows them again as it lays itself out).
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
	if (Room >= 0)
		SetTimer(0.15, true, nameof(HoverOption));
	ShowBase();
	SetTimer(0.6, false, nameof(ShowBase));
	ShowAvengerButton(false);
}

/** Another screen over the hub: the Avenger back (the armory and squad select stand their soldiers in its rooms; EW's
 *  screens put their own backdrop over it); the base again when the hub has focus back. */
simulated function OnLoseFocus()
{
	local UILWEWScreen Next;

	super.OnLoseFocus();
	ClearTimer(nameof(ShowBase));
	ClearTimer(nameof(HoverOption));
	// (A screen that shows the base itself, building in it, keeps it.)
	Next = UILWEWScreen(Movie.Pres.ScreenStack.GetCurrentScreen());
	if ((Next == none || !Next.bShowsBase) && UILWOfficers(Movie.Pres.ScreenStack.GetCurrentScreen()) == none)
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
	local array<ASValue> Params;

	if (i == Room)
	{
		LeaveRoom();
		return;
	}
	`log("LongWarX2: Long War hub: room" @ RoomName(i), , 'LongWarX2');
	Room = i;
	Params.AddItem(Str(string(i)));
	CallNow("theMenu.facilityMenu.setFocus", Params);
	CallNow("theMenu.facilityMenu.DimAllUnselectedMenuOptions");
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
		// (As EW: each once its facility is built: the Officer Training School, the Psi Labs, the Genetics Lab.)
		S = class'XComGameState_LWStrategy'.static.Get();
		if (S != none && class'LWBase'.static.Count(S, 12) > 0)
			RoomOptions.AddItem(OPT_OTS);
		// (Officer promotions once a rank is open, as EW's once medals are.)
		if (S != none && S.OfficerProjectsBought > 0)
			RoomOptions.AddItem(OPT_OFFICERS);
		if (S != none && class'LWBase'.static.Count(S, 17) > 0)
			RoomOptions.AddItem(OPT_PSI);
		if (S != none && class'LWBase'.static.Count(S, 23) > 0)
			RoomOptions.AddItem(OPT_GENE);
		break;
	case 3:
		RoomOptions.AddItem(OPT_AIRCRAFT);
		break;
	case 4:
		RoomOptions.AddItem(OPT_SITROOM);
		// (EXALT's view once EXALT is active, features/lw-exalt.md.)
		S = class'XComGameState_LWStrategy'.static.Get();
		if (S != none && S.ExaltState >= class'LWExalt'.const.ACTIVE)
			RoomOptions.AddItem(OPT_EXALT);
		RoomOptions.AddItem(OPT_GREYMARKET);
		break;
	}
	ShowRoomMenu();
}

/** Back to the base's view. */
function LeaveRoom()
{
	Room = -1;
	ClearTimer(nameof(HoverOption));
	CallNow("subMenuMC.Hide");
	CallNow("theMenu.facilityMenu.RestoreOpacityToAllMenuOptions");
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
	case OPT_OTS: return Word(OTS, "Officer Training School");
	case OPT_PSI: return Word(PsiLabs, "Psi Labs");
	case OPT_GENE: return class'LWBase'.static.FacilityName(23);
	case OPT_OFFICERS: return Word(class'UILWOfficers'.default.Promotions, "Officer Promotions");
	case OPT_EXALT: return "EXALT";
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
	case OPT_OTS: return OTSHelp;
	case OPT_PSI: return PsiLabsHelp;
	case OPT_OFFICERS: return class'UILWOfficers'.default.PromotionsHelp;
	case OPT_EXALT: return class'UILWEWSituationRoom'.default.NotScanned;
	}
	return "";
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
	case OPT_FACILITIES:
		// EW's own building over its base; the plain base screen where EW's screens are not converted.
		if (class'UILWEWBuildFacilities'.static.Available())
			class'UILWEWBuildFacilities'.static.Open(HQPres);
		else
			HQPres.ScreenStack.Push(HQPres.Spawn(class'UILWBase', HQPres));
		break;
	case OPT_FOUNDRY: class'UILWEWEngineering'.static.Open(HQPres, true); break;
	case OPT_SOLDIERS:
		// (The Avenger back first: the armory stands the soldier in its room as it opens.)
		class'LWX2EWBase'.static.Get(self).Hide();
		HQPres.UIPersonnel_Armory(OnSoldierChosen);
		break;
	case OPT_AIRCRAFT: class'UILWEWHangar'.static.Open(HQPres); break;
	case OPT_SITROOM: class'UILWEWSituationRoom'.static.Open(); break;
	case OPT_EXALT: class'UILWEWSituationRoom'.static.Open(true); break;
	case OPT_GREYMARKET: class'UILWEWGreyMarket'.static.Open(HQPres); break;
	// (The plain base screen holds the Officer Training School's, the Psi Labs' and the Genetics Lab's panels, until each
	// has EW's own screen.)
	case OPT_OFFICERS:
		// EW's own Officer Billets screen; XCOM 2's widgets where EW's screens are not converted.
		if (class'UILWEWScreen'.static.HasEWScreens())
			class'UILWEWOfficers'.static.Open(HQPres);
		else
			HQPres.ScreenStack.Push(HQPres.Spawn(class'UILWOfficers', HQPres));
		break;
	case OPT_OTS:
		if (class'UILWEWScreen'.static.HasEWScreens())
		{
			class'UILWEWOTS'.static.Open(HQPres);
			break;
		}
	case OPT_PSI:
	case OPT_GENE:
		HQPres.ScreenStack.Push(HQPres.Spawn(class'UILWBase', HQPres));
		break;
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

/** The room menu's option under the mouse (EW's submenu: its options are theItems.<k>), or -1. */
function int OptionUnderMouse()
{
	local int k;

	if (Room < 0)
		return -1;
	for (k = 0; k < RoomOptions.Length; k++)
		if (MouseOver(MCPath $ ".subMenuMC.theItems." $ k))
			return k;
	return -1;
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
		i = OptionUnderMouse();
		if (i >= 0)
		{
			SelectOption(i);
			ChooseOption(RoomOptions[i]);
			return true;
		}
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
	// In a room: its menu by the arrows, an option chosen by Enter.
	if (Room >= 0)
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			SelectOption(RoomSelected - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			SelectOption(RoomSelected + 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			if (RoomSelected < RoomOptions.Length)
				ChooseOption(RoomOptions[RoomSelected]);
			return true;
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
