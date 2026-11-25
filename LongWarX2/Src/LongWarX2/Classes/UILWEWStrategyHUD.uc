// Enemy Within's strategy HUD (its StrategyHUD movie, features/lw-ew-screens.md) over the Avenger: the resource bar with
// Long War's money and materials, filled as EW's UIStrategyHUD fills it (ClearResources, one AddResource each), and
// EW's clock with Long War's date, refreshed every second. It takes no input.
class UILWEWStrategyHUD extends UILWEWScreen;

/** EW's words (XGScreenMgr's resource names; the research panel's, XGResearchUI, XGFacility_Labs; the event list's). */
var localized string ResourceNames[8], CurrentResearch, NoResearch, Speeds[3], OneDay, ManyDays, NextEvent, DaysTitle, UpcomingEvents;
var localized string QueueTitle, QueueEmpty, EtaLabel, ProjectLabel, QtyLabel, FoundryPrefix, EtaHour, EtaDay;
/** The engineering queue as last given (given again only when it changes). */
var string QueueShown;
/** Where the player is, as EW's HUD changes with it (UIStrategyHUD and its rooms' UIStrategyHUD_FSM_*): 0 the base's view,
 *  1 Mission Control, 2 a room of the base, 3 a screen over the base. */
var int Context;
/** What the room or screen is about, for its panels and resource line: 'Research', 'Engineering', 'Facilities', 'RepairBay',
 *  'Soldier' or none. */
var name Kind;
/** The context the back arrow and panels were last set for ("": not yet). */
var string ShownFor;
/** Where the back arrow's clicks are addressed (UILWEWAlertTarget: XCOM 2 hands a Flash event only to a panel at its path). */
var UILWEWAlertTarget BackTarget, BarTarget;
/** What the event list shows: its events as last given (given again only when they change). */
var string EventsShown;
/** How many of them. */
var int MaxEvents;
/** In Mission Control, EW's list of what is coming (UIStrategyComponent_EventList's default: ten a column, UPCOMING
 *  EVENTS), where the base's view shows the next one. */
var int MissionControlEvents;
/** The list last filled (the HUD's, or Mission Control's own). */
var UIMCController EventsTarget;
/** Whether EW's resource panel is hidden (ShowForTop). */
var bool bResourcesHidden;
/** Whether XCOM 2's navigation help is hidden (an EW screen on top, which has EW's own back arrow and help: ShowForTop). */
var bool bNavHelpHidden;
/** EW's build screen's item card button shown in the bar. */
var bool bCardHelp, bBuildHelp;

/**
 * The HUD shown over the Avenger, on top, when the converted package is there. It is loaded into the movie without
 * joining the screen stack: pushed, it took the focus, and XCOM 2's screens hide when they lose it. A movie is drawn
 * over those loaded before it, so a HUD already up is taken down and loaded again above the screen just opened.
 */
/**
 * The help bar laid out again (its back arrow re-added). An EW screen's movie brings its own copy of EW's layout classes,
 * and the view they place the bar by is set again as it opens (UILWEWScreen.SetEWView); the bar lays itself out only as
 * its buttons are added, which the HUD does when the kind of screen changes, so a second screen of the same kind over the
 * first (the craft summary over the aircraft list) left the arrow where the view had briefly put it, below the screen.
 */
static function RelayHelpBar(UIScreen Screen)
{
	local UILWEWStrategyHUD HUD;

	foreach Screen.AllActors(class'UILWEWStrategyHUD', HUD)
	{
		HUD.ShownFor = "";
		HUD.Refresh();
	}
}

static function ShowIfAvailable()
{
	local XComHQPresentationLayer HQPres;
	local UILWEWStrategyHUD HUD;

	HQPres = `HQPRES;
	if (HQPres == none || !HasEWScreens())
		return;
	foreach HQPres.AllActors(class'UILWEWStrategyHUD', HUD)
	{
		HQPres.Get2DMovie().RemoveScreen(HUD);
		HUD.Destroy();
	}
	DynamicLoadObject(default.UIPackage $ ".ewxStrategyHUD", class'Object', true);
	HUD = HQPres.Spawn(class'UILWEWStrategyHUD', HQPres);
	HUD.Package = name("/ package/ewxStrategyHUD/StrategyHUD");
	HUD.MCName = 'theStrategyHUD';
	HUD.InitScreen(XComPlayerController(HQPres.Owner), HQPres.Get2DMovie());
	HQPres.Get2DMovie().LoadScreen(HUD);
}

simulated function OnInit()
{
	super.OnInit();
	MC.FunctionVoid("ShowResourcesPanel");
	// The ticker and the hotlink (EW's news line and its shortcut) are not used.
	MC.FunctionVoid("HideTicker");
	MC.FunctionVoid("HideHotlink");
	// The room tabs are the hub's own (its instance of this movie): here their bracket would draw alone, a line across the
	// top over every screen (the reviewer's "full-width rule"); EW's resource bracket stays.
	Movie.SetVariableBool(MCPath $ ".theMenu.facilityHeaderBracket._visible", false);
	Movie.SetVariableBool(MCPath $ ".theMenu.facilityMenu._visible", false);
	Refresh();
	SetTimer(1.0, true, nameof(Refresh));
	SetTimer(0.1, true, nameof(ShowForTop));
}

/** EW's engineering queue (XGEngineeringUI.BuildQueueItem): each build "Item (n)" with done/n and its ETA, each Foundry
 *  project "Foundry: name", the ETA in EW's hours or days (XGFacility_Engineering.GetETAString). */
function SetQueue(XComGameState_LWStrategy S)
{
	local LWGearRules.LWBuildDef B;
	local array<string> Names, Qtys, Etas;
	local string Shown;
	local int i;

	for (i = 0; i < S.Builds.Length; i++)
	{
		class'LWGearRules'.static.BuildFor(S.Builds[i].Item, B);
		Names.AddItem(class'LWEngineering'.static.ItemName(B.Template) $ " (" $ S.Builds[i].Quantity $ ")");
		Qtys.AddItem("0/" $ S.Builds[i].Quantity);
		Etas.AddItem(Eta(class'LWEngineering'.static.HoursFor(S.Builds[i].WorkLeft, S.Builds[i].Engineers, S.Engineers), S.Builds[i].Engineers));
	}
	for (i = 0; i < S.FoundryProjects.Length; i++)
	{
		Names.AddItem((FoundryPrefix != "" ? FoundryPrefix : "Foundry:") @ class'LWEngineering'.static.FoundryName(S.FoundryProjects[i].Item));
		Qtys.AddItem("---");
		Etas.AddItem(Eta(class'LWEngineering'.static.HoursFor(S.FoundryProjects[i].WorkLeft, S.FoundryProjects[i].Engineers, S.Engineers), S.FoundryProjects[i].Engineers));
	}
	// (Never empty: an empty queue is given too, or the movie's placeholders show.)
	Shown = "q|";
	for (i = 0; i < Names.Length; i++)
		Shown $= Names[i] $ "|" $ Etas[i] $ "|";
	if (Shown == QueueShown)
		return;
	QueueShown = Shown;
	MC.ChildFunctionVoid("engineeringQueue", "clear");
	MC.BeginChildFunctionOp("engineeringQueue", "SetQueueTitle");
	MC.QueueString(Names.Length > 0 ? (QueueTitle != "" ? QueueTitle : "CURRENT PROJECTS") : (QueueEmpty != "" ? QueueEmpty : "NO CURRENT PROJECTS"));
	MC.QueueString(Names.Length > 0 ? (EtaLabel != "" ? EtaLabel : "ETA") : "");
	MC.QueueString(Names.Length > 0 ? (ProjectLabel != "" ? ProjectLabel : "PROJECT") : "");
	MC.QueueString("");
	MC.QueueString(Names.Length > 0 ? (QtyLabel != "" ? QtyLabel : "QTY") : "");
	MC.EndOp();
	for (i = 0; i < Names.Length; i++)
	{
		MC.BeginChildFunctionOp("engineeringQueue", "AddProjectToQueue");
		MC.QueueString(Names[i]);
		MC.QueueString("");
		MC.QueueString(Qtys[i]);
		MC.QueueString(Etas[i]);
		MC.QueueNumber(0);
		MC.EndOp();
	}
}

function string Eta(int Hours, int Engineers)
{
	if (Engineers <= 0)
		return "--";
	if (Hours < 24)
		return Repl(EtaHour != "" ? EtaHour : "%dh", "%d", string(Max(Hours, 0)));
	return Repl(EtaDay != "" ? EtaDay : "%dd", "%d", string((Hours + 23) / 24));
}

/** One entry of the bar, in EW's colours (UIUtilities.GetHTMLColoredText: good 5CD16C, bad EE1C25). */
function AddResource(string Label, string Value, bool bGood)
{
	MC.FunctionString("AddResource", EWColored(Label $ ":" @ Value, bGood ? "5CD16C" : "EE1C25"));
}

/** EW's meld line (UIStrategyHUD.UpdateMeld, UIUtilities.HTMLFormatMeld): orange with EW's orange meld symbol when there
 *  is some, red with its red one when none. */
function AddMeld(string Label, int Meld)
{
	MC.FunctionString("AddResource", EWColored(Label $ ":", Meld > 0 ? "F78000" : "EE1C25") @ EWColored(string(Meld), Meld > 0 ? "F78000" : "EE1C25")
		@ "<img src='" $ (Meld > 0 ? "meld_orange" : "meld_red") $ "' width='25' height='20' vspace='-2'>");
}

/** A line in one of EW's HTML colours. */
static function string EWColored(string Text, string Hex)
{
	return "<font color='#" $ Hex $ "'>" $ Text $ "</font>";
}

/** EW's resource panel hidden while a soldier screen is on top (the barracks' soldier list, the armory and its screens,
 *  customization; the labs' soldier lists keep it), over the memorial, the research room's screens and gene mods, as EW
 *  hides it there (AS_HideResourcesPanel);
 *  the back arrow stays, as EW's does (ShowBackButton). */
function ShowForTop()
{
	local UIScreen Top;
	local bool bHide;

	Top = Movie.Pres.ScreenStack.GetCurrentScreen();
	ShowNavHelpFor(Top);
	class'UILWEWSituationRoom'.static.WallFor(XComHQPresentationLayer(Movie.Pres));
	// (And over Officer Billets, EW's medals screen as Long War made it: UIMedals.OnInit hides it.)
	bHide = UIPersonnel_Armory(Top) != none || UILWEWSoldierList(Top) != none || UILWEWSoldierSummary(Top) != none || UILWEWMemorial(Top) != none || UIArmory(Top) != none || UICustomize(Top) != none || UIMouseGuard_RotatePawn(Top) != none
		|| UILWEWOfficers(Top) != none
		// (And over the research room's own screens, as EW's science HUD hides it for each of its views but the room's menu,
		// UIStrategyHUD_FSM_Science.GoToView: the research list, the archives and reports, the credits, the Gene Lab; and
		// over gene mods, UISoldierGeneMods.)
		|| UILWEWResearch(Top) != none || UILWEWScienceLabs(Top) != none || UILWEWGeneLab(Top) != none || UILWEWGeneMods(Top) != none
		// (And over Mission Control, whose own screen hides EW's whole strategy HUD, UIMissionControl.GoToView.)
		|| UILWEWMissionControl(Top) != none;
	if (bHide == bResourcesHidden)
		return;
	bResourcesHidden = bHide;
	MC.FunctionVoid(bHide ? "HideResourcesPanel" : "ShowResourcesPanel");
}

/** XCOM 2's navigation help (its back and geoscape icons) hidden under EW's screens, which draw EW's back arrow: it sat
 *  over EW's (the reviewer's facilities, engineering and soldier screens); shown again for XCOM 2's own (the armory's). */
function ShowNavHelpFor(UIScreen Top)
{
	local XComHQPresentationLayer HQPres;
	local bool bHide;

	HQPres = XComHQPresentationLayer(Movie.Pres);
	if (HQPres == none || HQPres.m_kAvengerHUD == none || HQPres.m_kAvengerHUD.NavHelp == none)
		return;
	bHide = UILWEWScreen(Top) != none || UILWEWHub(Top) != none;
	if (bHide == bNavHelpHidden)
		return;
	bNavHelpHidden = bHide;
	if (bHide)
		HQPres.m_kAvengerHUD.NavHelp.Hide();
	else
		HQPres.m_kAvengerHUD.NavHelp.Show();
}

/** Whether XCOM 2's own navigation help is the one shown (an XCOM 2 screen on top: ShowNavHelpFor). */
function bool bNavHelpShown()
{
	local UIScreen Top;

	Top = Movie.Pres.ScreenStack.GetCurrentScreen();
	// (XCOM 2's squad select too: its own back button sat on EW's arrow, beside its BUILD ITEMS; the click tests' shot.)
	return Top != none && UILWEWScreen(Top) == none && UILWEWHub(Top) == none && (UIArmory(Top) != none || UISquadSelect(Top) != none);
}

static function string FragmentsName()
{
	local X2ItemTemplate T;

	T = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'X2Item_LWArtifacts'.static.ItemFor('WeaponFragment'));
	return T != none ? T.GetItemFriendlyNamePlural() : "Weapon Fragments";
}

function Refresh()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy S;
	local int Cash, Meld, Net;
	local bool bWide;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	S = class'XComGameState_LWStrategy'.static.Get();
	if (XComHQ == none || S == none)
		return;
	FindContext();
	Cash = XComHQ.GetSupplies();
	Meld = XComHQ.GetResourceAmount(class'X2Item_LWArtifacts'.static.ItemFor('Meld'));
	MC.FunctionVoid("ClearResources");
	// EW's lines: the default (UIStrategyHUD.UpdateDefaultResources) credits, the month's net, meld once there is some;
	// engineering's and its screens' (UIStrategyHUD_FSM_Engineering) credits, elerium, alloys, meld, power; building
	// facilities' (UIBuildFacilities.UpdateResources) credits, the month's net, elerium, alloys, meld, power.
	bWide = Kind == 'Engineering' || Kind == 'Facilities';
	AddResource(Label(0, "CREDITS"), class'LWStrategyRules'.static.Money(Cash), Cash > 0);
	// (The Repair Bay's: credits, meld, elerium, alloys.)
	if (Kind == 'RepairBay')
	{
		AddMeld(Label(7, "MELD"), Meld);
		MC.FunctionString("AddResource", EWColored(Label(1, "ELERIUM") $ ":" @ XComHQ.GetResourceAmount('EleriumDust'), "67E8ED"));
		MC.FunctionString("AddResource", EWColored(Label(2, "ALLOYS") $ ":" @ XComHQ.GetResourceAmount('AlienAlloy'), "67E8ED"));
	}
	else if (Kind != 'Engineering' && Kind != 'GreyMarket')
	{
		Net = S.MonthlyNet();
		AddResource(Label(6, "MONTHLY"), (Net > 0 ? "+" : "") $ class'LWStrategyRules'.static.Money(Net), Net > 0);
	}
	if (bWide)
	{
		MC.FunctionString("AddResource", EWColored(Label(1, "ELERIUM") $ ":" @ XComHQ.GetResourceAmount('EleriumDust'), "67E8ED"));
		MC.FunctionString("AddResource", EWColored(Label(2, "ALLOYS") $ ":" @ XComHQ.GetResourceAmount('AlienAlloy'), "67E8ED"));
		// (Long War's line in engineering, UIStrategyHUD_FSM_Engineering.UpdateResources: its fragments, named by the item's
		// plural without "WEAPON ".)
		if (Kind == 'Engineering')
			MC.FunctionString("AddResource", EWColored(Repl(Caps(FragmentsName()), "WEAPON ", "") $ ":" @ XComHQ.GetResourceAmount(class'X2Item_LWArtifacts'.static.ItemFor('WeaponFragment')), "67E8ED"));
	}
	if ((Meld > 0 || bWide) && Kind != 'RepairBay' && Kind != 'SitRoom' && Kind != 'GreyMarket')
		AddMeld(Label(7, "MELD"), Meld);
	// (Added again each second: kept hidden where it is, ShowForTop.)
	if (bResourcesHidden)
		MC.FunctionVoid("HideResourcesPanel");
	if (bWide && S.TileType.Length > 0)
		// (EW's: yellow, red when more is used than made.)
		MC.FunctionString("AddResource", EWColored(Label(5, "POWER") $ ":" @ class'LWBase'.static.PowerUsed(S) $ "/" $ class'LWBase'.static.PowerCapacity(S),
			class'LWBase'.static.PowerUsed(S) <= class'LWBase'.static.PowerCapacity(S) ? "FFD038" : "EE1C25"));
	SetClock(S);
	// The clock and the event list on the base's view and in Mission Control only: EW's rooms and screens have their back
	// arrow and their own panels there instead.
	Movie.SetVariableBool(MCPath $ ".theClock._visible", Context <= 1);
	Movie.SetVariableBool(MCPath $ ".theEventList._visible", Context == 0);
	if (Context <= 1)
		SetEvents(XComHQ, S);
	SetPanels(XComHQ, S);
	// The engineering queue in engineering's room and screens, as EW's (UIStrategyHUD_BuildQueue); hidden elsewhere (each
	// refresh: the movie shows it again as it lays itself out).
	Movie.SetVariableBool(MCPath $ ".engineeringQueue._visible", Kind == 'Engineering');
	if (Kind == 'Engineering')
		SetQueue(S);
}

function string Label(int i, string Fallback)
{
	return ResourceNames[i] != "" ? ResourceNames[i] : Fallback;
}

/** Context and Kind from the screen on top (and the hub's room). */
function FindContext()
{
	local UIScreen Top;
	local UILWEWHub Hub;

	Top = Movie.Pres.ScreenStack.GetCurrentScreen();
	Hub = UILWEWHub(Top);
	Kind = '';
	if (Hub != none)
	{
		Context = Hub.Room < 0 ? 0 : 2;
		if (Hub.Room == 0)
			Kind = 'Research';
		else if (Hub.Room == 1)
			Kind = 'Engineering';
		else if (Hub.Room == 4)
			Kind = 'SitRoom';
	}
	else if (UILWEWMissionControl(Top) != none || UILWGeoscape(Top) != none || UILWEWAlert(Top) != none)
		Context = 1;
	else
	{
		Context = 3;
		if (UILWEWResearch(Top) != none)
			Kind = 'Research';
		// (And the Repair Bay, EW's MEC inventory: engineering's lines and its engineers, as EW's capture shows.)
		else if (UILWEWEngineering(Top) != none || UILWEWManufacturing(Top) != none)
			Kind = 'Engineering';
		// (The Repair Bay, EW's MEC inventory: its own lines, UIMECInventory.UpdateResources, and the engineers.)
		else if (UILWEWRepairBay(Top) != none)
			Kind = 'RepairBay';
		else if (UILWEWBuildFacilities(Top) != none || UILWEWChooseFacility(Top) != none)
			Kind = 'Facilities';
		else if (UILWEWSoldierSummary(Top) != none)
			Kind = 'Soldier';
		// (The Situation Room's own screens: its FSM's header, credits and the month's net, UIStrategyHUD_FSM_SituationRoom.
		// UpdateHeader; the Grey Market's: credits alone, UIGreyMarket.)
		else if (UILWEWSituationRoomHUD(Top) != none || UILWEWPendingRequests(Top) != none || UILWEWFinances(Top) != none)
			Kind = 'SitRoom';
		else if (UILWEWGreyMarket(Top) != none)
			Kind = 'GreyMarket';
	}
}

/**
 * EW's panels for the room or screen: the back arrow (UIStrategyHUD.ShowBackButton: the help bar's PC icon 4) everywhere
 * but the base's view; the scientists in the labs and the engineers in engineering (AS_SetHumanResources); the current
 * research in the labs and on its screen (UIStrategyHUD_FSM_Science.UpdateResearchData, XGResearchUI.UpdateHeader).
 */
function SetPanels(XComGameState_HeadquartersXCom XComHQ, XComGameState_LWStrategy S)
{
	local XComGameState_HeadquartersProjectResearch Project;
	local XComGameState_Tech Tech;
	local string Ctx, Eta;
	local int HoursLeft, D;

	// (Shown before its button is added: XCOM 2's Flash does not advance a hidden clip, and the button waits for a
	// frame to load. The bar is hidden until a back arrow is in it, as EW's ShowBackButton shows it.)
	// (Not under Mission Control itself, which has its own: UILWEWMissionControl.)
	// (Nor under XCOM 2's own screens, the loadout and customization, whose own back button takes the screen back: two
	// back buttons sat over each other there, round 6.)
	// (Nor over EW's screens with their own Cancel, as EW shows them: hiring and the pending requests; round 9 #13.)
	Movie.SetVariableBool(MCPath $ ".helpBar._visible", Context > 0 && UILWEWMissionControl(Movie.Pres.ScreenStack.GetCurrentScreen()) == none && !bNavHelpShown()
		&& UILWEWHiring(Movie.Pres.ScreenStack.GetCurrentScreen()) == none && UILWEWPendingRequests(Movie.Pres.ScreenStack.GetCurrentScreen()) == none);
	// (EW's build screen's "?" beside the back arrow, UIBuildItem: its item card.)
	bCardHelp = UILWEWEngineering(Movie.Pres.ScreenStack.GetCurrentScreen()) != none && !UILWEWEngineering(Movie.Pres.ScreenStack.GetCurrentScreen()).bFoundry;
	// (The facility chooser's BEGIN BUILD on the right, UIChooseFacility.UpdateButtonHelp; aek 2026-11-25: no way to build.)
	bBuildHelp = UILWEWChooseFacility(Movie.Pres.ScreenStack.GetCurrentScreen()) != none;
	Ctx = Context $ Kind $ bCardHelp $ bBuildHelp;
	if (Ctx != ShownFor)
	{
		ShownFor = Ctx;
		MC.ChildFunctionVoid("helpBar", "ClearButtonHelp");
		// (EW's UINavigationHelp.Init: its containers' padding, the centre's wide enough to keep the soldier summary's
		// previous and next soldier apart around the plinth.)
		MC.ChildFunctionNum("helpBar", "SetLeftHelpPadding", 20);
		MC.ChildFunctionNum("helpBar", "SetRightHelpPadding", 20);
		MC.ChildFunctionNum("helpBar", "SetCenterHelpPadding", 60);
		if (Context > 0)
		{
			// (EW's XComButtonIconPC, renamed with the other classes EW's movies compile in: tools/convert/ew-ui.ts.)
			MC.ChildFunctionString("helpBar", "SetButtonType", "QComButtonIconPC");
			MC.BeginChildFunctionOp("helpBar", "AddLeftButtonHelp");
			MC.QueueNumber(0);
			MC.QueueString("4");
			MC.QueueString("");
			MC.QueueBoolean(false);
			MC.EndOp();
			if (bCardHelp)
			{
				MC.BeginChildFunctionOp("helpBar", "AddLeftButtonHelp");
				MC.QueueNumber(3);
				MC.QueueString("3");
				MC.QueueString("");
				MC.QueueBoolean(false);
				MC.EndOp();
			}
			// (The soldier summary's previous and next soldier, EW's icon buttons 0 and 1 in the bar's middle:
			// UISoldierSummary.UpdateButtonHelp.)
			if (Kind == 'Soldier')
			{
				MC.BeginChildFunctionOp("helpBar", "AddCenterButtonHelp");
				MC.QueueNumber(1);
				MC.QueueString("0");
				MC.QueueString("");
				MC.QueueBoolean(false);
				MC.EndOp();
				MC.BeginChildFunctionOp("helpBar", "AddCenterButtonHelp");
				MC.QueueNumber(2);
				MC.QueueString("1");
				MC.QueueString("");
				MC.QueueBoolean(false);
				MC.EndOp();
				MC.ChildFunctionVoid("helpBar", "onCenterButtonHelpLoaded");
			}
			MC.ChildFunctionString("helpBar", "SetButtonType", "");
			if (bBuildHelp)
			{
				MC.BeginChildFunctionOp("helpBar", "AddRightButtonHelp");
				MC.QueueNumber(5);
				MC.QueueString(class'UILWEWHub'.static.Word(class'UILWEWBuildFacilities'.default.BeginBuild, "BEGIN BUILD"));
				MC.QueueString("Icon_START");
				MC.QueueBoolean(false);
				MC.EndOp();
				MC.ChildFunctionVoid("helpBar", "onRightButtonHelpLoaded");
			}
			// (The bar hides itself until its button reports loaded, which takes a frame of the hidden clip that XCOM 2's
			// Flash never gives: told at once, as the hub's submenu is shown.)
			MC.ChildFunctionVoid("helpBar", "onLeftButtonHelpLoaded");
			// (Placed at the stage's bottom left, as the bar lays itself out on a resolution change.)
			MC.ChildFunctionVoid("helpBar", "AnchorToBottom");
			MC.ChildFunctionVoid("helpBar", "UpdateLocations");
			if (BackTarget == none)
			{
				// (The bar reports its buttons' clicks under its own path, as EW's alerts do; the button's own too.)
				BackTarget = class'UILWEWAlertTarget'.static.At(self, MCPath $ ".helpBarMC.leftBtnHelpContainer.buttonHelp_0");
				BarTarget = class'UILWEWAlertTarget'.static.At(self, MCPath $ ".helpBarMC");
			}
		}
	}
	// (Room and screen alike: EW's labs show the scientists in the room, not on the research list.)
	MC.BeginFunctionOp("SetHumanResources");
	if (Context == 2 && Kind == 'Research')
	{
		MC.QueueString(Label(4, "SCIENTISTS"));
		MC.QueueString(string(S.Scientists));
	}
	else if (Kind == 'Engineering' || Kind == 'RepairBay')
	{
		MC.QueueString(Label(3, "ENGINEERS"));
		MC.QueueString(string(S.Engineers));
	}
	else
	{
		MC.QueueString("");
		MC.QueueString("");
	}
	MC.EndOp();
	if (Kind != 'Research')
	{
		MC.BeginFunctionOp("SetCurrentResearch");
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueNumber(-1);
		MC.QueueString("");
		MC.EndOp();
		return;
	}
	Project = XComHQ.GetCurrentResearchProject();
	Tech = Project != none ? XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Project.ProjectFocus.ObjectID)) : none;
	if (Tech == none)
	{
		// (EW's AS_SetCurrentResearch has its defaults for the rest: "" and -1.)
		MC.BeginFunctionOp("SetCurrentResearch");
		MC.QueueString(NoResearch != "" ? NoResearch : "NO ACTIVE RESEARCH");
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueNumber(-1);
		MC.QueueString("");
		MC.EndOp();
		return;
	}
	// EW's: the pace by the days it takes (up to 5 fast, up to 10 normal: XGFacility_Labs.GetProgress), and the days.
	HoursLeft = Project.GetCurrentNumHoursRemaining();
	D = Max(1, Days(HoursLeft));
	Eta = D <= 5 ? Speeds[0] : (D <= 10 ? Speeds[1] : Speeds[2]);
	Eta @= "(" $ Repl(D == 1 ? OneDay : ManyDays, "%d", string(D)) $ ")";
	MC.BeginFunctionOp("SetCurrentResearch");
	MC.QueueString(CurrentResearch != "" ? CurrentResearch : "CURRENT RESEARCH");
	MC.QueueString(Tech.GetDisplayName());
	MC.QueueString(Eta);
	MC.QueueNumber(Progress(Project));
	MC.QueueString("");
	MC.EndOp();
}

/** How far the project is, 0 to 1. */
function float Progress(XComGameState_HeadquartersProjectResearch Project)
{
	local XComGameState_Tech Tech;
	local int Needed;

	Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Project.ProjectFocus.ObjectID));
	Needed = Tech != none ? Tech.GetMyTemplate().PointsToComplete : 0;
	if (Needed <= 0)
		return 0;
	return FClamp(1.0 - float(Project.ProjectPointsRemaining) / float(Needed), 0, 1);
}

/**
 * EW's event list (theEventList, one event a row as EW's HUD has it: UIStrategyComponent_EventList), whose title showed
 * its placeholders ("LALALAL") unfed: what Long War has coming, soonest first, the days to each. Its icons by EW's event
 * kinds (GetEventImageLabel), in EW's mixed case ("Advanced Repair", "Psi Training").
 */
function SetEvents(XComGameState_HeadquartersXCom XComHQ, XComGameState_LWStrategy S)
{
	local XComGameState_HeadquartersProjectResearch Project;
	local XComGameState_Tech Tech;
	local XComGameState_LWAirWar AirWar;
	local XComGameState_Unit Unit;
	local LWGearRules.LWBuildDef B;
	local array<string> Texts, Icons;
	local array<int> Hours;
	local string Shown;
	local int i, n;
	local UIMCController Target;

	Project = XComHQ.GetCurrentResearchProject();
	Tech = Project != none ? XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Project.ProjectFocus.ObjectID)) : none;
	if (Tech != none)
		PutEvent(Texts, Hours, Icons, Tech.GetDisplayName(), Project.GetCurrentNumHoursRemaining(), "_research");
	for (i = 0; i < S.BaseJobs.Length; i++)
		PutEvent(Texts, Hours, Icons, S.BaseJobs[i].Kind == 0 ? "Excavation" : class'LWBase'.static.FacilityName(S.BaseJobs[i].Facility), S.BaseJobs[i].HoursLeft, "_facility");
	for (i = 0; i < S.Builds.Length; i++)
	{
		class'LWGearRules'.static.BuildFor(S.Builds[i].Item, B);
		PutEvent(Texts, Hours, Icons, (S.Builds[i].Quantity > 1 ? S.Builds[i].Quantity $ "x " : "") $ class'LWEngineering'.static.ItemName(B.Template), class'LWEngineering'.static.HoursFor(S.Builds[i].WorkLeft, S.Builds[i].Engineers, S.Engineers), "_itemProject");
	}
	for (i = 0; i < S.FoundryProjects.Length; i++)
		PutEvent(Texts, Hours, Icons, class'LWEngineering'.static.FoundryName(S.FoundryProjects[i].Item), class'LWEngineering'.static.HoursFor(S.FoundryProjects[i].WorkLeft, S.FoundryProjects[i].Engineers, S.Engineers), "_foundry");
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar != none)
		for (i = 0; i < AirWar.Orders.Length; i++)
			PutEvent(Texts, Hours, Icons, (AirWar.Orders[i].Count == 1 ? "Interceptor to " : AirWar.Orders[i].Count @ "Interceptors to ") $ class'LWStrategyRules'.static.ContinentName(AirWar.Orders[i].Continent), AirWar.Orders[i].HoursLeft, "_interceptorOrdering");
	// (Soldiers hired, as EW's event list shows them: XGMissionControlUI.m_strNewSoldierEvent, its hiring icon.)
	for (i = 0; i < S.HiringOrders.Length; i++)
		PutEvent(Texts, Hours, Icons, (class'UILWEWHiring'.default.Event != "" ? class'UILWEWHiring'.default.Event : "New Soldiers arrive at XCOM HQ"), S.HiringOrders[i].HoursLeft, "_hiring");
	for (i = 0; i < S.PsiTrainees.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.PsiTrainees[i].Unit));
		PutEvent(Texts, Hours, Icons, "Psi Testing:" @ (Unit != none ? Unit.GetFullName() : ""), S.PsiTrainees[i].HoursLeft, "_psiTraining");
	}
	for (i = 0; i < S.GenePatients.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.GenePatients[i].Unit));
		PutEvent(Texts, Hours, Icons, "Gene Mod:" @ (Unit != none ? Unit.GetFullName() : ""), class'XComGameState_LWStrategy'.static.GeneHoursLeft(S.GenePatients[i]), "_genemod");
	}
	PutEvent(Texts, Hours, Icons, "Council Report", S.HoursPerMonth() - S.Hours % S.HoursPerMonth(), "_endOfMonth");
	// The soonest only on the base's view (a second row reaches the screen's bottom edge); EW's ten in Mission Control.
	n = Context == 1 ? MissionControlEvents : MaxEvents;
	if (Texts.Length > n)
	{
		Texts.Length = n;
		Hours.Length = n;
		Icons.Length = n;
	}
	for (i = 0; i < Texts.Length; i++)
		Shown $= Texts[i] $ "|" $ Days(Hours[i]) $ "|";
	// (In Mission Control, its own movie's list: UIMissionControl's.)
	Target = MC;
	if (Context == 1 && UILWEWMissionControl(Movie.Pres.ScreenStack.GetCurrentScreen()) != none)
		Target = UILWEWMissionControl(Movie.Pres.ScreenStack.GetCurrentScreen()).MC;
	if (Shown == EventsShown && Target == EventsTarget)
		return;
	EventsShown = Shown;
	EventsTarget = Target;
	Target.ChildFunctionVoid("theEventList", "clear");
	Target.ChildFunctionNum("theEventList", "OverrideMaxItemsPerColumn", n);
	// (EW's default for its event list, Mission Control's, is not to (UIStrategyComponent_EventList.m_bExpandListVertically);
	// the base's single row is.)
	Target.ChildFunctionBool("theEventList", "ExpandListVertically", n == 1);
	Target.BeginChildFunctionOp("theEventList", "SetTitle");
	// (EW's single-row list: NEXT EVENT, DAYS; its list in Mission Control: UPCOMING EVENTS.)
	Target.QueueString(n > 1 ? (UpcomingEvents != "" ? UpcomingEvents : "UPCOMING EVENTS") : (NextEvent != "" ? NextEvent : "NEXT EVENT"));
	Target.QueueString(DaysTitle != "" ? DaysTitle : "DAYS");
	Target.EndOp();
	for (i = 0; i < Texts.Length; i++)
	{
		Target.BeginChildFunctionOp("theEventList", "AddEvent");
		Target.QueueString(Texts[i]);
		Target.QueueString("DAYS");
		Target.QueueString(string(Days(Hours[i])));
		Target.QueueString(Icons[i]);
		Target.EndOp();
	}
}

/** An event put in its place by the hours to it. */
static function PutEvent(out array<string> Texts, out array<int> Hours, out array<string> Icons, string Text, int H, string Icon)
{
	local int i;

	while (i < Hours.Length && Hours[i] <= H)
		i++;
	Texts.InsertItem(i, Text);
	Hours.InsertItem(i, H);
	Icons.InsertItem(i, Icon);
}

static function int Days(int H) { return Max(0, (H + 23) / 24); }

/** EW's clock (its theClock, as EW's UIStrategyComponent_Clock sets it for English): Long War's date and hour. */
function SetClock(XComGameState_LWStrategy S)
{
	local TDateTime T;
	local array<ASValue> Args;
	local ASValue V;
	local int Hour;

	class'X2StrategyGameRulesetDataStructures'.static.SetTime(T, 0, 0, 0, 3, 1, 2015);
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(T, S.Hours);
	Hour = class'X2StrategyGameRulesetDataStructures'.static.GetHour(T);
	V.Type = AS_String;
	V.s = class'X2StrategyGameRulesetDataStructures'.static.GetDay(T) @ class'X2StrategyGameRulesetDataStructures'.static.GetMonthString(class'X2StrategyGameRulesetDataStructures'.static.GetMonth(T));
	Args.AddItem(V);
	V.s = string(class'X2StrategyGameRulesetDataStructures'.static.GetYear(T));
	Args.AddItem(V);
	V.Type = AS_Number;
	V.n = (Hour % 12 == 0) ? 12 : Hour % 12;
	Args.AddItem(V);
	V.n = 0;
	Args.AddItem(V);
	V.Type = AS_Boolean;
	V.b = Hour < 12;
	Args.AddItem(V);
	V.Type = AS_Number;
	V.n = 0;
	Args.AddItem(V);
	V.Type = AS_Boolean;
	V.b = false;
	Args.AddItem(V);
	Movie.Invoke(MCPath $ ".theClock.SetDateTime", Args);
}

/** The back arrow clicked: what Escape does on the screen on top (a room left, a screen closed), as EW's back button. */
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local UIScreen Top;
	local int i;

	`log("LongWarX2: EW HUD mouse" @ cmd @ (args.Length > 0 ? args[args.Length - 1] : ""), , 'LongWarX2');
	if (cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		return;
	Top = Movie.Pres.ScreenStack.GetCurrentScreen();
	// (The soldier summary's previous and next soldier, buttons 1 and 2.)
	if (UILWEWSoldierSummary(Top) != none && args.Length > 0 && (args[args.Length - 1] == "buttonHelp_1" || args[args.Length - 1] == "buttonHelp_2"))
	{
		UILWEWSoldierSummary(Top).Cycle(args[args.Length - 1] == "buttonHelp_1" ? -1 : 1);
		return;
	}
	// (The facility chooser's BEGIN BUILD, button 5.)
	if (UILWEWChooseFacility(Top) != none && args.Length > 0 && args[args.Length - 1] == "buttonHelp_5")
	{
		UILWEWChooseFacility(Top).Accept();
		return;
	}
	// (The build screen's "?": the selected item's card, UIBuildItem.OnMouseAccept.)
	if (UILWEWEngineering(Top) != none && args.Length > 0 && args[args.Length - 1] == "buttonHelp_3")
	{
		UILWEWEngineering(Top).ShowCard();
		return;
	}
	// (To the screen on top that takes it, downwards (Screens[0] is the top): a screen over another that passes its keys on (the Situation Room's
	// own HUD over its room, on Launch Satellite) had swallowed the back arrow, which then did nothing.)
	for (i = 0; i < Movie.Pres.ScreenStack.Screens.Length && Top != none; i++)
	{
		Top = Movie.Pres.ScreenStack.Screens[i];
		if (Top == none || Top == self)
			continue;
		if (Top.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_KEY_ESCAPE, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE))
			break;
	}
}

defaultproperties
{
	InputState = eInputState_None
	bConsumeMouseEvents = false
	// (Never focused, being off the stack: its back arrow's clicks taken all the same, UIMovie.FlashRaiseMouseEvent.)
	bProcessMouseEventsIfNotFocused = true
	MaxEvents = 1
	MissionControlEvents = 10
}
