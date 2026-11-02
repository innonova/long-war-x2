// Enemy Within's strategy HUD (its StrategyHUD movie, features/lw-ew-screens.md) over the Avenger: the resource bar with
// Long War's money and materials, filled as EW's UIStrategyHUD fills it (ClearResources, one AddResource each), and
// EW's clock with Long War's date, refreshed every second. It takes no input.
class UILWEWStrategyHUD extends UILWEWScreen;

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
	SetResearch(XComHQ);
}

/** EW's current project panel: XCOM's research under way (its name, the days left, how far along). */
function SetResearch(XComGameState_HeadquartersXCom XComHQ)
{
	local XComGameState_Tech Tech;
	local XComGameState_HeadquartersProjectResearch Project;

	Project = XComHQ.GetCurrentResearchProject();
	Tech = Project != none ? XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Project.ProjectFocus.ObjectID)) : none;
	MC.BeginFunctionOp("SetCurrentResearch");
	MC.QueueString("RESEARCH");
	MC.QueueString(Tech != none ? Caps(Tech.GetDisplayName()) : "NONE");
	MC.QueueString(Project != none ? class'UIUtilities_Text'.static.GetTimeRemainingString(Project.GetCurrentNumHoursRemaining()) : "");
	MC.QueueNumber(Project != none ? Project.GetPercentComplete() : 0.0);
	MC.QueueString("");
	MC.EndOp();
}

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
	bConsumeMouseEvents = false
}
