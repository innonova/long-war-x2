// Enemy Within's strategy HUD (its StrategyHUD movie, features/lw-ew-screens.md) over the Avenger: the resource bar with
// Long War's money and materials, filled as EW's UIStrategyHUD fills it (ClearResources, one AddResource each), and
// EW's clock with Long War's date, refreshed every second. It takes no input.
class UILWEWStrategyHUD extends UILWEWScreen;

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
	local int Cash, Meld;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	S = class'XComGameState_LWStrategy'.static.Get();
	if (XComHQ == none || S == none)
		return;
	Cash = XComHQ.GetSupplies();
	Meld = XComHQ.GetResourceAmount(class'X2Item_LWArtifacts'.static.ItemFor('Meld'));
	MC.FunctionVoid("ClearResources");
	AddResource("CASH", class'LWStrategyRules'.static.Money(Cash), Cash > 0);
	AddResource("ALLOYS", string(XComHQ.GetResourceAmount('AlienAlloy')), true);
	AddResource("ELERIUM", string(XComHQ.GetResourceAmount('EleriumDust')), true);
	AddResource("MELD", string(Meld), Meld > 0);
	SetClock(S);
	// The research is in the event list (EW's HUD shows its research panel only in the labs: ClearFacilityPanels).
	MC.FunctionString("SetCurrentResearch", "");
	SetEvents(XComHQ, S);
	// Nor the engineering queue: not fed yet (its AddProjectToQueue not read), it showed its placeholders ("LALALAL", "P",
	// "E"). Each refresh: the movie shows it again as it lays itself out.
	Movie.SetVariableBool(MCPath $ ".engineeringQueue._visible", false);
}

/**
 * EW's event list (theEventList, one event a row as EW's HUD has it: UIStrategyComponent_EventList), whose title showed
 * its placeholders ("LALALAL") unfed: what Long War has coming, soonest first, the days to each. Its icons by EW's event
 * kinds (GetEventImageLabel). Not yet: Engineering's and the Foundry's projects (their work, not hours).
 */
function SetEvents(XComGameState_HeadquartersXCom XComHQ, XComGameState_LWStrategy S)
{
	local XComGameState_HeadquartersProjectResearch Project;
	local XComGameState_Tech Tech;
	local XComGameState_LWAirWar AirWar;
	local XComGameState_Unit Unit;
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
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar != none)
		for (i = 0; i < AirWar.Orders.Length; i++)
			PutEvent(Texts, Hours, Icons, (AirWar.Orders[i].Count == 1 ? "INTERCEPTOR TO " : AirWar.Orders[i].Count @ "INTERCEPTORS TO ") $ Caps(class'LWStrategyRules'.static.ContinentName(AirWar.Orders[i].Continent)), AirWar.Orders[i].HoursLeft, "_interceptorOrdering");
	for (i = 0; i < S.PsiTrainees.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.PsiTrainees[i].Unit));
		PutEvent(Texts, Hours, Icons, "PSI TESTING:" @ (Unit != none ? Caps(Unit.GetFullName()) : ""), S.PsiTrainees[i].HoursLeft, "_psiTraining");
	}
	for (i = 0; i < S.GeneTrainees.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.GeneTrainees[i].Unit));
		PutEvent(Texts, Hours, Icons, "GENE MOD:" @ (Unit != none ? Caps(Unit.GetFullName()) : ""), S.GeneTrainees[i].HoursLeft, "_genemod");
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
	// Its title row lies level with the Geoscape window's buttons (its DAYS over CLOSE): hidden (moving the list did
	// nothing, it lays itself out again). Each refresh, as SetTitle shows it.
	Movie.SetVariableBool(MCPath $ ".theEventList.titleMC._visible", false);
	if (Shown == EventsShown)
		return;
	EventsShown = Shown;
	MC.ChildFunctionVoid("theEventList", "clear");
	MC.ChildFunctionNum("theEventList", "OverrideMaxItemsPerColumn", 1);
	MC.ChildFunctionBool("theEventList", "ExpandListVertically", true);
	MC.BeginChildFunctionOp("theEventList", "SetTitle");
	MC.QueueString("COMING UP");
	MC.QueueString("DAYS");
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

defaultproperties
{
	InputState = eInputState_None
	bScaleToStage = false
	bConsumeMouseEvents = false
	MaxEvents = 1
}
