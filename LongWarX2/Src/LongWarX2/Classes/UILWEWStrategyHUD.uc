// Enemy Within's strategy HUD (its StrategyHUD movie, features/lw-ew-screens.md) over the Avenger: the resource bar with
// Long War's money and materials, filled as EW's UIStrategyHUD fills it (ClearResources, one AddResource each), and
// EW's clock with Long War's date, refreshed every second. It takes no input.
class UILWEWStrategyHUD extends UILWEWScreen;

/** EW's words (XGScreenMgr's resource names; the research panel's, XGResearchUI, XGFacility_Labs; the event list's). */
var localized string ResourceNames[8], CurrentResearch, NoResearch, Speeds[3], OneDay, ManyDays, NextEvent, DaysTitle;
/** Where the player is, as EW's HUD changes with it (UIStrategyHUD and its rooms' UIStrategyHUD_FSM_*): 0 the base's view,
 *  1 Mission Control, 2 a room of the base, 3 a screen over the base. */
var int Context;
/** What the room or screen is about, for its panels and resource line: 'Research', 'Engineering', 'Facilities' or none. */
var name Kind;
/** The context the back arrow and panels were last set for ("": not yet). */
var string ShownFor;
/** Where the back arrow's clicks are addressed (UILWEWAlertTarget: XCOM 2 hands a Flash event only to a panel at its path). */
var UILWEWAlertTarget BackTarget, BarTarget;
/** What the event list shows: its events as last given (given again only when they change). */
var string EventsShown;
/** How many of them. */
var int MaxEvents;

/**
 * The HUD shown over the Avenger, on top, when the converted package is there. It is loaded into the movie without
 * joining the screen stack: pushed, it took the focus, and XCOM 2's screens hide when they lose it. A movie is drawn
 * over those loaded before it, so a HUD already up is taken down and loaded again above the screen just opened.
 */
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
	Refresh();
	SetTimer(1.0, true, nameof(Refresh));
}

/** One entry of the bar, as EW colours it (good when there is some, bad when none). */
function AddResource(string Label, string Value, bool bGood)
{
	MC.FunctionString("AddResource", class'UIUtilities_Text'.static.GetColoredText(Label $ ":" @ Value, bGood ? eUIState_Good : eUIState_Bad));
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
	if (Kind != 'Engineering')
	{
		Net = S.MonthlyNet();
		AddResource(Label(6, "MONTHLY"), (Net > 0 ? "+" : "") $ class'LWStrategyRules'.static.Money(Net), Net > 0);
	}
	if (bWide)
	{
		AddResource(Label(1, "ELERIUM"), string(XComHQ.GetResourceAmount('EleriumDust')), true);
		AddResource(Label(2, "ALLOYS"), string(XComHQ.GetResourceAmount('AlienAlloy')), true);
	}
	if (Meld > 0 || bWide)
		AddResource(Label(7, "MELD"), string(Meld), Meld > 0);
	if (bWide && S.TileType.Length > 0)
		AddResource(Label(5, "POWER"), class'LWBase'.static.PowerUsed(S) $ "/" $ class'LWBase'.static.PowerCapacity(S),
			class'LWBase'.static.PowerUsed(S) <= class'LWBase'.static.PowerCapacity(S));
	SetClock(S);
	// The clock and the event list on the base's view and in Mission Control only: EW's rooms and screens have their back
	// arrow and their own panels there instead.
	Movie.SetVariableBool(MCPath $ ".theClock._visible", Context <= 1);
	Movie.SetVariableBool(MCPath $ ".theEventList._visible", Context <= 1);
	if (Context <= 1)
		SetEvents(XComHQ, S);
	SetPanels(XComHQ, S);
	// Nor the engineering queue: not fed yet (its AddProjectToQueue not read), it showed its placeholders ("LALALAL", "P",
	// "E"). Each refresh: the movie shows it again as it lays itself out.
	Movie.SetVariableBool(MCPath $ ".engineeringQueue._visible", false);
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
	}
	else if (UILWEWMissionControl(Top) != none || UILWGeoscape(Top) != none || UILWEWAlert(Top) != none)
		Context = 1;
	else
	{
		Context = 3;
		if (UILWEWResearch(Top) != none)
			Kind = 'Research';
		else if (UILWEWEngineering(Top) != none || UILWEWManufacturing(Top) != none)
			Kind = 'Engineering';
		else if (UILWEWBuildFacilities(Top) != none || UILWEWChooseFacility(Top) != none)
			Kind = 'Facilities';
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
	Movie.SetVariableBool(MCPath $ ".helpBar._visible", Context > 0);
	Ctx = Context $ Kind;
	if (Ctx != ShownFor)
	{
		ShownFor = Ctx;
		MC.ChildFunctionVoid("helpBar", "ClearButtonHelp");
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
			MC.ChildFunctionString("helpBar", "SetButtonType", "");
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
	else if (Kind == 'Engineering')
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
 * kinds (GetEventImageLabel).
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
	local int i;

	Project = XComHQ.GetCurrentResearchProject();
	Tech = Project != none ? XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Project.ProjectFocus.ObjectID)) : none;
	if (Tech != none)
		PutEvent(Texts, Hours, Icons, Caps(Tech.GetDisplayName()), Project.GetCurrentNumHoursRemaining(), "_research");
	for (i = 0; i < S.BaseJobs.Length; i++)
		PutEvent(Texts, Hours, Icons, S.BaseJobs[i].Kind == 0 ? "EXCAVATION" : Caps(class'LWBase'.static.FacilityName(S.BaseJobs[i].Facility)), S.BaseJobs[i].HoursLeft, "_facility");
	for (i = 0; i < S.Builds.Length; i++)
	{
		class'LWGearRules'.static.BuildFor(S.Builds[i].Item, B);
		PutEvent(Texts, Hours, Icons, (S.Builds[i].Quantity > 1 ? S.Builds[i].Quantity $ "x " : "") $ Caps(class'LWEngineering'.static.ItemName(B.Template)), class'LWEngineering'.static.HoursFor(S.Builds[i].WorkLeft, S.Builds[i].Engineers, S.Engineers), "_itemProject");
	}
	for (i = 0; i < S.FoundryProjects.Length; i++)
		PutEvent(Texts, Hours, Icons, Caps(class'LWEngineering'.static.FoundryName(S.FoundryProjects[i].Item)), class'LWEngineering'.static.HoursFor(S.FoundryProjects[i].WorkLeft, S.FoundryProjects[i].Engineers, S.Engineers), "_foundry");
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar != none)
		for (i = 0; i < AirWar.Orders.Length; i++)
			PutEvent(Texts, Hours, Icons, (AirWar.Orders[i].Count == 1 ? "INTERCEPTOR TO " : AirWar.Orders[i].Count @ "INTERCEPTORS TO ") $ Caps(class'LWStrategyRules'.static.ContinentName(AirWar.Orders[i].Continent)), AirWar.Orders[i].HoursLeft, "_interceptorOrdering");
	for (i = 0; i < S.PsiTrainees.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.PsiTrainees[i].Unit));
		PutEvent(Texts, Hours, Icons, "PSI TESTING:" @ (Unit != none ? Caps(Unit.GetFullName()) : ""), S.PsiTrainees[i].HoursLeft, "_psiTraining");
	}
	for (i = 0; i < S.GenePatients.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.GenePatients[i].Unit));
		PutEvent(Texts, Hours, Icons, "GENE MOD:" @ (Unit != none ? Caps(Unit.GetFullName()) : ""), class'XComGameState_LWStrategy'.static.GeneHoursLeft(S.GenePatients[i]), "_genemod");
	}
	PutEvent(Texts, Hours, Icons, "COUNCIL REPORT", S.HoursPerMonth() - S.Hours % S.HoursPerMonth(), "_endOfMonth");
	// The soonest only: a second row reaches the screen's bottom edge.
	if (Texts.Length > MaxEvents)
	{
		Texts.Length = MaxEvents;
		Hours.Length = MaxEvents;
		Icons.Length = MaxEvents;
	}
	for (i = 0; i < Texts.Length; i++)
		Shown $= Texts[i] $ "|" $ Days(Hours[i]) $ "|";
	if (Shown == EventsShown)
		return;
	EventsShown = Shown;
	MC.ChildFunctionVoid("theEventList", "clear");
	MC.ChildFunctionNum("theEventList", "OverrideMaxItemsPerColumn", 1);
	MC.ChildFunctionBool("theEventList", "ExpandListVertically", true);
	MC.BeginChildFunctionOp("theEventList", "SetTitle");
	// (EW's single-row list: NEXT EVENT, DAYS.)
	MC.QueueString(NextEvent != "" ? NextEvent : "NEXT EVENT");
	MC.QueueString(DaysTitle != "" ? DaysTitle : "DAYS");
	MC.EndOp();
	for (i = 0; i < Texts.Length; i++)
	{
		MC.BeginChildFunctionOp("theEventList", "AddEvent");
		MC.QueueString(Texts[i]);
		MC.QueueString("DAYS");
		MC.QueueString(string(Days(Hours[i])));
		MC.QueueString(Icons[i]);
		MC.EndOp();
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

	`log("LongWarX2: EW HUD mouse" @ cmd @ (args.Length > 0 ? args[args.Length - 1] : ""), , 'LongWarX2');
	if (cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		return;
	Top = Movie.Pres.ScreenStack.GetCurrentScreen();
	if (Top != none)
		Top.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_KEY_ESCAPE, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
}

defaultproperties
{
	InputState = eInputState_None
	bConsumeMouseEvents = false
	// (Never focused, being off the stack: its back arrow's clicks taken all the same, UIMovie.FlashRaiseMouseEvent.)
	bProcessMouseEventsIfNotFocused = true
	MaxEvents = 1
}
