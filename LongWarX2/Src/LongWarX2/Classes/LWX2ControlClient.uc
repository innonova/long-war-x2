// For development: one connection to the control port (LWX2Control): a command a line, the
// answer's lines, then ".". "help" lists the commands. Text mode, lines split here.
class LWX2ControlClient extends TcpLink dependson(XComGameState_LWStrategy, LWBaseRules, XComGameState_LWAirWar);

/** What came in and is not yet a whole line. */
var string Pending;

event ReceivedText(string Text)
{
	local int i;

	Pending $= Text;
	for (i = InStr(Pending, Chr(10)); i != INDEX_NONE; i = InStr(Pending, Chr(10)))
	{
		Answer(Repl(Left(Pending, i), Chr(13), ""));
		Pending = Mid(Pending, i + 1);
	}
}

function Answer(string Line)
{
	local array<string> Out;
	local string L;

	if (!(Line ~= "ping" || Line ~= "screens" || Line ~= "geo" || Line ~= "decisions" || Line ~= "continue"))
		`log("LongWarX2: control:" @ Line, , 'LongWarX2');
	Handle(Line, Out);
	// A line at a time: a dump is thousands of them.
	foreach Out(L)
		SendText(L $ Chr(10));
	SendText("." $ Chr(10));
}

function Handle(string Line, out array<string> Out)
{
	local array<string> Args;
	local XComGameState_LWStrategy S;
	local UILWGeoscape Geo;
	local string Cmd, Why;
	local int Before;

	ParseStringIntoArray(Line, Args, " ", true);
	if (Args.Length == 0)
		return;
	Cmd = Locs(Args[0]);
	S = class'XComGameState_LWStrategy'.static.Get();
	switch (Cmd)
	{
	case "help":
		Out.AddItem("ping | screens | geo | decisions | geoscape | run <hours> [all] | act <n> | intercepted <ufo> <outcome 0 crashed 1 destroyed 2 escaped> <ufo hp>");
		Out.AddItem("resolve <decision> won|captive|lost [stance]: a decision taken without playing it (an interception fought by the air war's rules, a mission's result given; captive: won with an alien taken alive)");
		Out.AddItem("auto <hours> [mission win %, default 100] [stance 0-2, default 1] [sats]: time at full speed, every decision taken (interceptions fought, missions won at the %, an alien taken alive when it can be); with sats also satellites bought and launched (the base grown for uplinks), two interceptors kept at home, research kept going");
		Out.AddItem("squad <kind 1 crash 2 landed 3 abduction 4 terror> [ufo or abduction difficulty] [day]: a squad Long War would send (its species, counted)");
		Out.AddItem("research [n]: XCOM 2's research list (Long War's techs: hours, affordable), the project under way; with n, that tech started");
		Out.AddItem("campaign [difficulty 0-3, default 1] [first]: a new campaign from the main menu, without its first mission unless 'first'");
		Out.AddItem("continue: the top screen's own way on (reports, loot, alerts, tips; else Enter) | key <UIUtilities_Input code>: any input (300 A, 301 B, 510 Esc, 513 Space)");
		Out.AddItem("sat build | sat launch <country> | win | exec <console command>");
		Out.AddItem("builds: what engineering can build (Long War's item numbers, cost, time) and its projects | build <item> [n]: n of it begun | give <template> <n>: items put in the stores (a test aid)");
		Out.AddItem("foundry: the Foundry's available projects (ids), the one under way, those done | foundry <id>: that project begun | foundry done <id>: marked done (a test aid)");
		Out.AddItem("base: the base's tiles, numbers and facilities | base set <column> <row> <facility>: placed at once (a test aid) | work <column> <row> [facility id]: dig rock, a lift in the shaft, or the facility");
		Out.AddItem("hangar: the jets (index first), orders, bays | order [continent 0-4] [n] | transfer <jet> <continent> | equip <jet> <weapon 1-7>");
		Out.AddItem("dump [class name part]: every game state object with all its fields (tools/test/lw-dump.sh saves it)");
		return;
	case "ping":
		Out.AddItem("pong" @ (Pres().ScreenStack.GetCurrentScreen() != none ? string(Pres().ScreenStack.GetCurrentScreen().Class.Name) : "none"));
		return;
	case "screens":
		Screens(Out);
		return;
	case "exec":
		Out.AddItem(GetALocalPlayerController().ConsoleCommand(Mid(Line, Len(Args[0]) + 1), true));
		return;
	case "win":
		if (XComTacticalController(GetALocalPlayerController()) == none)
		{
			Out.AddItem("ERR not in a mission");
			return;
		}
		class'UIScreenListener_LongWarX2Tactical'.static.TestWin();
		Out.AddItem("ok");
		return;
	case "dump":
		DumpAll(Args.Length > 1 ? Args[1] : "", Out);
		return;
	case "continue":
	case "key":
		Out.AddItem(Cmd == "continue" ? Continue() : Press(int(Args.Length > 1 ? Args[1] : "0")));
		return;
	case "campaign":
		Out.AddItem(NewCampaign(Args.Length > 1 ? int(Args[1]) : 1, Args.Length > 2 && Args[2] ~= "first"));
		return;
	case "research":
		Research(Args.Length > 1 ? Args[1] : "", Out);
		return;
	case "give":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR give <template> <n>");
			return;
		}
		Give(name(Args[1]), int(Args[2]), Out);
		return;
	case "arm":
		if (Args.Length > 1 && Args[1] ~= "now")
			Out.AddItem("armed" @ class'LWX2Gear'.static.ArmAll());
		class'LWX2Gear'.static.Report(Out);
		return;
	case "geoscape":
		Out.AddItem(OpenGeoscape() != none ? "ok" : "ERR not on the Avenger");
		return;
	}
	// The rest needs the campaign's Geoscape.
	if (S == none)
	{
		Out.AddItem("ERR no Geoscape in this campaign yet (geoscape opens it)");
		return;
	}
	switch (Cmd)
	{
	case "geo":
		Dump(S, Out);
		return;
	case "decisions":
		Decisions(S, Out);
		return;
	case "run":
		Before = S.EventCount;
		Out.AddItem("hours" @ class'XComGameState_LWStrategy'.static.Run(Args.Length > 1 ? int(Args[1]) : 1, Args.Length > 2 && Args[2] ~= "all"));
		S = class'XComGameState_LWStrategy'.static.Get();
		NewEvents(S, Before, Out);
		Refreshed();
		return;
	case "act":
		Geo = OpenGeoscape();
		if (Geo == none)
			Out.AddItem("ERR not on the Avenger");
		else
			Out.AddItem(Geo.Act(Args.Length > 1 ? int(Args[1]) : 0) ? "ok" : "ERR no such decision");
		return;
	case "squad":
		Squad(S, Args.Length > 1 ? int(Args[1]) : 1, Args.Length > 2 ? int(Args[2]) : 4, Args.Length > 3 ? int(Args[3]) : S.Days(), Out);
		return;
	case "resolve":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR resolve <decision> won|captive|lost [stance 0-2]");
			return;
		}
		Before = S.EventCount;
		Out.AddItem(ResolveDecision(int(Args[1]), Args[2] ~= "won" || Args[2] ~= "captive", Args.Length > 3 ? int(Args[3]) : 1, Args[2] ~= "captive"));
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		Refreshed();
		return;
	case "auto":
		AutoPlay(Args.Length > 1 ? int(Args[1]) : 720, Args.Length > 2 ? int(Args[2]) : 100, Args.Length > 3 ? int(Args[3]) : 1, InStr(Locs(Line), " sats") != INDEX_NONE, Out);
		Refreshed();
		return;
	case "intercepted":
		if (Args.Length < 4 || int(Args[1]) < 0 || int(Args[1]) >= S.Ufos.Length)
		{
			Out.AddItem("ERR intercepted <ufo> <outcome> <hp>");
			return;
		}
		Before = S.EventCount;
		class'XComGameState_LWStrategy'.static.Intercepted(int(Args[1]), int(Args[2]), int(Args[3]));
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		Refreshed();
		return;
	case "builds":
		Builds(S, Out);
		return;
	case "build":
		if (Args.Length < 2)
		{
			Out.AddItem("ERR build <item> [n]");
			return;
		}
		Before = S.EventCount;
		Out.AddItem(class'LWEngineering'.static.Start(int(Args[1]), Args.Length > 2 ? int(Args[2]) : 1, Why) ? "ok" : "ERR" @ Why);
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		Refreshed();
		return;
	case "base":
		if (Args.Length > 4 && Args[1] ~= "set")
		{
			BaseSet(int(Args[2]) - 1, int(Args[3]) - 1, int(Args[4]));
			S = class'XComGameState_LWStrategy'.static.Get();
			Refreshed();
		}
		Base(S, Out);
		return;
	case "hangar":
		Hangar(Out);
		return;
	case "order":
		Before = S.EventCount;
		Out.AddItem(class'LWHangar'.static.Order(Args.Length > 1 ? int(Args[1]) : class'LWHangar'.static.HomeContinent(), Args.Length > 2 ? int(Args[2]) : 1, Why) ? "ok" : "ERR" @ Why);
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		return;
	case "transfer":
	case "equip":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR" @ Cmd @ "<jet> <" $ (Cmd == "equip" ? "weapon 1-7" : "continent 0-4") $ ">");
			return;
		}
		Before = S.EventCount;
		if (Cmd == "equip")
			Out.AddItem(class'LWHangar'.static.Equip(int(Args[1]), int(Args[2]), Why) ? "ok" : "ERR" @ Why);
		else
			Out.AddItem(class'LWHangar'.static.Transfer(int(Args[1]), int(Args[2]), Why) ? "ok" : "ERR" @ Why);
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		return;
	case "work":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR work <column 1-7> <row 1-5> [facility id]");
			return;
		}
		Before = S.EventCount;
		Out.AddItem(class'LWBase'.static.Work(int(Args[1]) - 1, int(Args[2]) - 1, Args.Length > 3 ? int(Args[3]) : 0, Why) ? "ok" : "ERR" @ Why);
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		Refreshed();
		return;
	case "foundry":
		if (Args.Length < 2)
		{
			Foundry(S, Out);
			return;
		}
		if (Args[1] ~= "done" && Args.Length > 2)
		{
			FoundryDone(int(Args[2]));
			Out.AddItem("done" @ class'LWEngineering'.static.FoundryName(int(Args[2])));
			Refreshed();
			return;
		}
		Before = S.EventCount;
		Out.AddItem(class'LWEngineering'.static.StartFoundry(int(Args[1]), Why) ? "ok" : "ERR" @ Why);
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		Refreshed();
		return;
	case "sat":
		if (Args.Length > 1 && Args[1] ~= "build")
			Out.AddItem(class'XComGameState_LWStrategy'.static.BuildSatellite() ? "ok" : "ERR not enough money");
		else if (Args.Length > 2 && Args[1] ~= "launch")
			Out.AddItem(class'XComGameState_LWStrategy'.static.LaunchSatellite(int(Args[2])) ? "ok" : "ERR none ready, the uplinks are full, or the country has one or has left");
		else
			Out.AddItem("ERR sat build | sat launch <country>");
		Refreshed();
		return;
	}
	Out.AddItem("ERR unknown command (help)");
}

/**
 * A new campaign from the main menu, as the difficulty screen's Start makes one
 * (UIShellDifficulty.OnDifficultyConfirm): no tutorial, no narrative, no intro movie; without its
 * first mission unless asked (the development shell's "skip first tactical").
 */
function string NewCampaign(int Difficulty, bool bFirstMission)
{
	local XComGameState Start;
	local XComGameState_CampaignSettings Settings;
	local UIShellDifficulty.DifficultyConfiguration D;
	local array<name> NoOptions;

	if (XComShellPresentationLayer(Pres()) == none)
		return "ERR not at the main menu";
	Difficulty = Clamp(Difficulty, 0, 3);
	D = class'UIShellDifficulty'.default.DifficultyConfigurations[Difficulty];
	NoOptions.Length = 0;
	`XCOMHISTORY.ResetHistory();
	Start = class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(, , false, false, true, Difficulty,
		D.TacticalDifficulty, D.StrategyDifficulty, D.GameLength, true, NoOptions, , false, , , NoOptions);
	Settings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	Settings.SetStartTime(Start.TimeStamp);
	Settings.bSkipFirstTactical = !bFirstMission;
	Settings.SetDifficulty(Difficulty, D.TacticalDifficulty, D.StrategyDifficulty, D.GameLength);
	GetALocalPlayerController().ConsoleCommand("open Avenger_Root?game=XComGame.XComHeadQuartersGame");
	return "ok difficulty" @ Difficulty @ (bFirstMission ? "with" : "without") @ "the first mission";
}

/**
 * The top screen passed the way its continue button would, for the screens that only report:
 * the Skyranger's briefing launched or left, the after-action report's Continue, an alert's
 * confirm, the loot, mission summary, tips and rewards recap closed. Nothing on the screens where
 * the player decides (the base, a facility, the maps, a mission's HUD, the main menu), and nothing on
 * a screen it does not know: a blind Enter there takes decisions (it bonded two soldiers once).
 */
function string Continue()
{
	local UIScreen Top;

	Top = Pres().ScreenStack.GetCurrentScreen();
	if (Top == none || UIFacilityGrid(Top) != none || UIFacility(Top) != none || UIStrategyMap(Top) != none || UILWGeoscape(Top) != none
		|| UITacticalHUD(Top) != none || UISpecialMissionHUD(Top) != none || UIShell(Top) != none)
		return "nothing to continue:" @ (Top != none ? string(Top.Class.Name) : "no screen");
	if (UIDropShipBriefing_MissionStart(Top) != none || UIDropShipBriefing_MissionEnd(Top) != none)
		WorldInfo.bContinueToSeamlessTravelDestination = true; // what the Skyranger's "press any key" sets (X2TacticalGameRuleset waits on it)
	else if (UIAfterAction(Top) != none)
		UIAfterAction(Top).OnContinue();
	else if (UIAlert(Top) != none)
		UIAlert(Top).OnConfirmClicked(none);
	else if (UIInventory_LootRecovered(Top) != none || UIMissionSummary(Top) != none || UITutorialBox(Top) != none || UIRewardsRecap(Top) != none
		|| UISoldierBondAlert(Top) != none || UIArmory_Photobooth(Top) != none || UIMissionIntro(Top) != none)
		Top.CloseScreen();
	else
		return "unknown screen, not touched:" @ Top.Class.Name;
	return "continued" @ Top.Class.Name;
}

/** An input pressed and released on the screen stack, as the keyboard or a gamepad would: what was on top before and after. */
function string Press(int Code)
{
	local string Before;

	Before = Pres().ScreenStack.GetCurrentScreen() != none ? string(Pres().ScreenStack.GetCurrentScreen().Class.Name) : "none";
	Pres().ScreenStack.OnInput(Code, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
	Pres().ScreenStack.OnInput(Code, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
	return "pressed" @ Code @ "on" @ Before;
}

/** A squad as Long War would make it now (or on the given day): its species, counted. */
function Squad(XComGameState_LWStrategy S, int Kind, int Which, int Day, out array<string> Out)
{
	local array<int> Aliens, Kinds, Counts;
	local int a, k;
	local string Line;

	Aliens = class'LWAlienSquads'.static.SquadFor(Kind, Which, Day, S.AlienAggression, S.AlienResources, Which, S.TerrorsTaken);
	foreach Aliens(a)
	{
		k = Kinds.Find(a);
		if (k == INDEX_NONE)
		{
			Kinds.AddItem(a);
			Counts.AddItem(1);
		}
		else
			Counts[k]++;
	}
	for (k = 0; k < Kinds.Length; k++)
		Line @= Counts[k] @ (class'LWStrategyRules'.default.Species.Find('Char', Kinds[k]) != INDEX_NONE
			? string(class'LWStrategyRules'.default.Species[class'LWStrategyRules'.default.Species.Find('Char', Kinds[k])].Name) : string(Kinds[k])) $ ",";
	Out.AddItem("squad of" @ Aliens.Length $ ":" $ Line);
}

/** XCOM 2's research: the techs available, with their hours and whether they can be paid for; or one started (as the research screen starts it). */
/** Engineering: each unlocked item (its number first, for build), then the projects. */
function Builds(XComGameState_LWStrategy S, out array<string> Out)
{
	local array<int> Items;
	local int Item;
	local XComGameState_LWStrategy.LWBuild P;

	Items = class'LWEngineering'.static.Buildable();
	foreach Items(Item)
		Out.AddItem("item" @ Item @ class'LWEngineering'.static.BuildLine(Item, S.Engineers));
	foreach S.Builds(P)
		Out.AddItem("project item" @ P.Item @ "quantity" @ P.Quantity @ "work" @ P.WorkLeft @ "engineers" @ P.Engineers @ "hours" @ class'LWEngineering'.static.HoursFor(P.WorkLeft, P.Engineers, S.Engineers));
	Out.AddItem("engineers" @ S.Engineers);
}

/** The hangar: a line per jet (its index first), the orders, the bays per continent. */
function Hangar(out array<string> Out)
{
	local XComGameState_LWAirWar AirWar;
	local int i;
	local string Line;

	class'XComGameState_LWAirWar'.static.EnsureExists();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	for (i = 0; i < AirWar.Jets.Length; i++)
		Out.AddItem("jet" @ i @ class'LWHangar'.static.JetText(AirWar.Jets[i]));
	for (i = 0; i < AirWar.Orders.Length; i++)
		Out.AddItem("order" @ AirWar.Orders[i].Count @ "to" @ class'LWStrategyRules'.static.ContinentName(AirWar.Orders[i].Continent) @ "in" @ AirWar.Orders[i].HoursLeft $ "h");
	Line = "bays taken:";
	for (i = 0; i < 5; i++)
		Line @= i $ "=" $ class'LWStrategyRules'.static.ContinentName(i) @ class'LWHangar'.static.BaysTaken(AirWar, i) $ "/" $ class'LWBaseRules'.default.HangarBays $ ";";
	Out.AddItem(Line);
	Out.AddItem("interceptor" @ class'LWStrategyRules'.static.Money(class'LWBaseRules'.default.InterceptorCost) @ "upkeep" @ class'LWStrategyRules'.static.Money(class'LWHangar'.static.Upkeep()) $ "/month");
}

/** The base: a line per row of tiles, its numbers, and each facility that could be built with what it needs. */
function Base(XComGameState_LWStrategy S, out array<string> Out)
{
	local LWBaseRules.LWFacilityDef F;
	local string Line, Why;
	local int X, Y;

	if (S.TileType.Length == 0)
	{
		class'XComGameState_LWStrategy'.static.Run(0);
		S = class'XComGameState_LWStrategy'.static.Get();
	}
	for (Y = 0; Y < class'LWBase'.const.H; Y++)
	{
		Line = "row" @ (Y + 1) $ ":";
		for (X = 0; X < class'LWBase'.const.W; X++)
			Line @= "[" $ class'LWBase'.static.TileText(S, X, Y) $ "]";
		Out.AddItem(Line);
	}
	Out.AddItem(class'LWBase'.static.Summary(S));
	foreach class'LWBaseRules'.default.Facilities(F)
	{
		if (F.Cash < 0)
			continue;
		class'LWBase'.static.CanBuild(S, F, Why);
		Out.AddItem("facility" @ F.Id @ class'LWBase'.static.FacilityName(F.Id) @ class'LWStrategyRules'.static.Money(F.Cash) @ "power" @ F.Power @ "days" @ F.Days @ (Why != "" ? "needs" @ Why : "ok"));
	}
}

/** The Foundry: each available project (its id first, for foundry <id>), the one under way, those done. */
function Foundry(XComGameState_LWStrategy S, out array<string> Out)
{
	local array<int> Ids;
	local int Id;
	local XComGameState_LWStrategy.LWBuild P;
	local string Done;

	Ids = class'LWEngineering'.static.FoundryAvailable();
	foreach Ids(Id)
		Out.AddItem("project" @ Id @ class'LWEngineering'.static.FoundryLine(Id, S));
	foreach S.FoundryProjects(P)
		Out.AddItem("under_way" @ P.Item @ "work" @ P.WorkLeft @ "engineers" @ P.Engineers @ "hours" @ class'LWEngineering'.static.HoursFor(P.WorkLeft, P.Engineers, S.Engineers));
	foreach S.FoundryDone(Id)
		Done @= string(Id);
	Out.AddItem("done" $ Done);
}

/** For auto play: the quickest tech XCOM can pay for started, if none is under way. What in What. */
function bool AutoResearch(out string What)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech Tech;
	local array<StateObjectReference> Refs;
	local int i, Best, Hours, BestHours;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ == none || XComHQ.GetCurrentResearchTech() != none)
		return false;
	Refs = XComHQ.GetAvailableTechsForResearch();
	Best = -1;
	for (i = 0; i < Refs.Length; i++)
	{
		Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Refs[i].ObjectID));
		if (!XComHQ.MeetsRequirmentsAndCanAffordCost(Tech.GetMyTemplate().Requirements, Tech.GetMyTemplate().Cost, XComHQ.ResearchCostScalars, 0.0, Tech.GetMyTemplate().AlternateRequirements))
			continue;
		Hours = XComHQ.GetResearchHours(Refs[i]);
		if (Best < 0 || Hours < BestHours)
		{
			Best = i;
			BestHours = Hours;
		}
	}
	if (Best < 0)
		return false;
	XComHQ.SetNewResearchProject(Refs[Best]);
	What = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Refs[Best].ObjectID)).GetMyTemplate().DisplayName @ "(" $ BestHours $ "h)";
	return true;
}

/** A facility put on a tile at once, whatever the tile (a test aid). */
function BaseSet(int X, int Y, int Facility)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	if (!class'LWBase'.static.IsValid(X, Y))
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a facility placed (control port)");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
	class'LWBase'.static.SetFacility(S, Facility, X, Y);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** A Foundry project marked done (a test aid). */
function FoundryDone(int Id)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a Foundry project done (control port)");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
	if (S.FoundryDone.Find(Id) == INDEX_NONE)
		S.FoundryDone.AddItem(Id);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function Give(name ItemName, int n, out array<string> Out)
{
	local XComGameState NewGameState;

	if (class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemName) == none)
	{
		Out.AddItem("ERR no item template" @ ItemName);
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: items given (control port)");
	class'X2Item_LWArtifacts'.static.GiveItem(NewGameState, ItemName, n);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Out.AddItem("held" @ class'LWEngineering'.static.Held(ItemName));
}

function Research(string Which, out array<string> Out)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech Tech;
	local array<StateObjectReference> Refs;
	local int i;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ == none)
	{
		Out.AddItem("ERR not in a campaign");
		return;
	}
	Refs = XComHQ.GetAvailableTechsForResearch();
	if (Which != "")
	{
		i = int(Which);
		if (i < 0 || i >= Refs.Length)
		{
			Out.AddItem("ERR no such tech");
			return;
		}
		Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Refs[i].ObjectID));
		if (!XComHQ.MeetsRequirmentsAndCanAffordCost(Tech.GetMyTemplate().Requirements, Tech.GetMyTemplate().Cost, XComHQ.ResearchCostScalars, 0.0, Tech.GetMyTemplate().AlternateRequirements))
		{
			Out.AddItem("ERR cannot pay for" @ Tech.GetMyTemplate().DisplayName);
			return;
		}
		XComHQ.SetNewResearchProject(Refs[i]);
		Out.AddItem("started" @ Tech.GetMyTemplateName() @ Tech.GetMyTemplate().DisplayName);
		return;
	}
	Tech = XComHQ.GetCurrentResearchTech();
	if (Tech != none)
		Out.AddItem("under way" @ Tech.GetMyTemplateName() @ "hours" @ XComHQ.GetHoursLeftOnResearchProject() @ "|" @ Tech.GetMyTemplate().DisplayName);
	for (i = 0; i < Refs.Length; i++)
	{
		Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Refs[i].ObjectID));
		Out.AddItem("tech" @ i @ Tech.GetMyTemplateName() @ "hours" @ XComHQ.GetResearchHours(Refs[i])
			@ "affordable" @ int(XComHQ.MeetsRequirmentsAndCanAffordCost(Tech.GetMyTemplate().Requirements, Tech.GetMyTemplate().Cost, XComHQ.ResearchCostScalars, 0.0, Tech.GetMyTemplate().AlternateRequirements))
			@ "inspired" @ int(Tech.bInspired) @ "|" @ Tech.GetMyTemplate().DisplayName);
	}
}

function XComPresentationLayerBase Pres()
{
	return XComPlayerController(GetALocalPlayerController()).Pres;
}

function Screens(out array<string> Out)
{
	local UIScreen Screen;

	foreach Pres().ScreenStack.Screens(Screen)
		Out.AddItem(string(Screen.Class.Name));
}

/**
 * A decision taken without playing it: an interception fought by the air war's rules with the
 * healthiest jet at the stance (its result recorded for the jet and the Geoscape), a mission given
 * its result (sent and come back, as XCOM 2's mission path would report it).
 */
function string ResolveDecision(int n, bool bWon, int Stance, optional bool bCapture)
{
	local XComGameState_LWStrategy S;
	local XComGameState_LWAirWar AirWar;
	local array<int> Kinds, Indexes;
	local array<string> Labels;
	local LWAirWar.LWResult R;
	local LWAirWar.LWShip Jet, TheUfo;
	local int Best;

	S = class'XComGameState_LWStrategy'.static.Get();
	S.Decisions(Kinds, Indexes, Labels);
	if (n < 0 || n >= Kinds.Length)
		return "ERR no such decision";
	if (Kinds[n] != 1)
	{
		if (bWon)
			class'XComGameState_LWStrategy'.static.WonWithoutPlaying(Kinds[n] - 1, Indexes[n], bCapture);
		else
		{
			class'XComGameState_LWStrategy'.static.MissionSent(Kinds[n] - 1, Indexes[n]);
			class'XComGameState_LWStrategy'.static.MissionBack(false);
		}
		return "resolved" @ Labels[n] @ (bWon ? "won" : "lost");
	}
	class'XComGameState_LWAirWar'.static.EnsureExists();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	Best = class'LWHangar'.static.BestFor(Indexes[n]);
	if (Best < 0)
		return "no jet fit to fly:" @ Labels[n];
	Jet = class'LWAirWar'.static.Craft(AirWar.Jets[Best].Type, AirWar.Jets[Best].Weapon, S.Category());
	Jet.Hp = AirWar.Jets[Best].Hp;
	TheUfo = class'LWAirWar'.static.Ufo(S.Ufos[Indexes[n]].Ufo, S.Category());
	TheUfo.Hp = S.Ufos[Indexes[n]].Hp;
	R = class'LWAirWar'.static.Fight(TheUfo, Jet, Clamp(Stance, 0, 2), class'LWAirWar'.static.NoActions());
	class'XComGameState_LWAirWar'.static.Record(Best, R.CraftHp, R.Outcome == eLWOutcome_Crashed || R.Outcome == eLWOutcome_Destroyed);
	class'XComGameState_LWStrategy'.static.Intercepted(Indexes[n], int(R.Outcome), R.UfoHp);
	return "fought" @ Labels[n] @ "with" @ AirWar.Jets[Best].Callsign $ ":" @ R.Outcome @ "ufo hp" @ R.UfoHp @ "jet hp" @ R.CraftHp;
}

/**
 * The campaign at full speed: time runs, and every decision is taken as it comes: interceptions
 * fought (resolve), missions won at WinPct %; with bSatellites, a satellite bought whenever there is
 * the money and room in the uplinks (else the base grown for an uplink) and launched over the most
 * panicked country without one, and two interceptors kept at home. A line a decision, then the
 * Geoscape's summary line.
 */
function AutoPlay(int Hours, int WinPct, int Stance, bool bSatellites, out array<string> Out)
{
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<int> Kinds, Indexes;
	local array<string> Labels;
	local int Done, Passed, k, Best, Guard;
	local string Why;

	Done = 0;
	while (Done < Hours && Guard++ < 5000)
	{
		Passed = class'XComGameState_LWStrategy'.static.Run(Hours - Done);
		Done += Passed;
		S = class'XComGameState_LWStrategy'.static.Get();
		if (S.bLost)
			break;
		if (bSatellites)
		{
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			// Satellites up to what the uplinks hold; the base grown for more (an uplink, else a dig or a lift).
			if (S.TileType.Length > 0 && class'LWBase'.static.SatellitesUp(S) + S.SatellitesReady + S.SatellitesDue.Length >= class'LWBase'.static.SatelliteLimit(S))
			{
				if (class'LWBase'.static.GrowForUplink(Why))
					Out.AddItem("day" @ S.Days() @ "base:" @ Why);
			}
			else if (XComHQ.GetSupplies() >= class'LWStrategyRules'.default.SatelliteCost && class'XComGameState_LWStrategy'.static.BuildSatellite())
				Out.AddItem("satellite ordered");
			// Two interceptors kept at home: a lost one replaced.
			if (class'LWHangar'.static.BaysTaken(class'XComGameState_LWAirWar'.static.Get(), class'LWHangar'.static.HomeContinent()) < 2
				&& class'LWHangar'.static.Order(class'LWHangar'.static.HomeContinent(), 1, Why))
				Out.AddItem("day" @ S.Days() @ "interceptor ordered");
			S = class'XComGameState_LWStrategy'.static.Get();
			while (S.SatellitesReady > 0)
			{
				Best = -1;
				for (k = 0; k < S.Countries.Length; k++)
					if (!S.Countries[k].bLeft && !S.Countries[k].bSatellite && (Best < 0 || S.Countries[k].Panic > S.Countries[Best].Panic))
						Best = k;
				if (Best < 0 || !class'XComGameState_LWStrategy'.static.LaunchSatellite(Best))
					break;
				Out.AddItem("satellite launched over" @ S.CountryName(Best));
				S = class'XComGameState_LWStrategy'.static.Get();
			}
		}
		// The decisions, the first each time (taking one can change the others); an interception
		// only with a jet fit to fly.
		S.Decisions(Kinds, Indexes, Labels);
		for (k = 0; k < Kinds.Length; k++)
			if (Kinds[k] != 1 || class'LWHangar'.static.BestFor(Indexes[k]) >= 0)
				break;
		if (k < Kinds.Length)
			Out.AddItem("day" @ S.Days() @ ResolveDecision(k, Rand(100) < WinPct, Stance, true));
		// Research kept going: the quickest affordable tech when none is under way.
		if (bSatellites && AutoResearch(Why))
			Out.AddItem("day" @ S.Days() @ "research:" @ Why);
		else if (Passed == 0)
			break;
	}
	Dump(class'XComGameState_LWStrategy'.static.Get(), Labels);
	Out.AddItem(Labels[0]);
}

/** A jet with HP left. */
/** The Geoscape screen, opened if it is not up (only on the Avenger). */
function UILWGeoscape OpenGeoscape()
{
	local XComHQPresentationLayer HQ;
	local UILWGeoscape Geo;

	HQ = XComHQPresentationLayer(Pres());
	if (HQ == none)
		return none;
	Geo = UILWGeoscape(HQ.ScreenStack.GetScreen(class'UILWGeoscape'));
	if (Geo == none)
	{
		Geo = HQ.Spawn(class'UILWGeoscape', HQ);
		HQ.ScreenStack.Push(Geo);
	}
	return Geo;
}

function Refreshed()
{
	local UILWGeoscape Geo;

	if (XComHQPresentationLayer(Pres()) == none)
		return;
	Geo = UILWGeoscape(Pres().ScreenStack.GetScreen(class'UILWGeoscape'));
	if (Geo != none)
		Geo.Refresh();
}

function NewEvents(XComGameState_LWStrategy S, int Before, out array<string> Out)
{
	local int i;

	for (i = Max(0, S.Events.Length - (S.EventCount - Before)); i < S.Events.Length; i++)
		Out.AddItem("event" @ S.Events[i]);
}

function Decisions(XComGameState_LWStrategy S, out array<string> Out)
{
	local array<int> Kinds, Indexes;
	local array<string> Labels;
	local int i;

	S.Decisions(Kinds, Indexes, Labels);
	for (i = 0; i < Kinds.Length; i++)
		Out.AddItem("decision" @ i @ "kind" @ Kinds[i] @ "index" @ Indexes[i] @ "|" @ Labels[i]);
}

/**
 * The whole game as XCOM 2 holds it: the screens up, then every object of its history, newest
 * version, with all its fields (BaseObject.ToString). With a filter, only the classes whose name
 * holds it. (The game's FileWriter does not open files in the shipped game: it comes back here.)
 */
function DumpAll(string Filter, out array<string> Out)
{
	local XComGameState_BaseObject Obj;
	local UIScreen Screen;

	foreach Pres().ScreenStack.Screens(Screen)
		Out.AddItem("== screen" @ Screen.Class.Name);
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_BaseObject', Obj)
	{
		if (Filter != "" && InStr(Locs(string(Obj.Class.Name)), Locs(Filter)) == INDEX_NONE)
			continue;
		Out.AddItem("== " $ Obj.Class.Name @ Obj.ObjectID);
		Out.AddItem(Obj.ToString(true));
	}
}

/** The Geoscape's state, a line a thing: "key value" pairs after the thing's name and number. */
function Dump(XComGameState_LWStrategy S, out array<string> Out)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int i;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Out.AddItem("date" @ S.DateText() @ "| xcom2" @ class'X2StrategyGameRulesetDataStructures'.static.GetDateString(`STRATEGYRULES.GameTime) @ class'X2StrategyGameRulesetDataStructures'.static.GetTimeString(`STRATEGYRULES.GameTime) @ "lost" @ int(S.bLost) @ "| month" @ S.Month @ "hours" @ S.Hours @ "money" @ XComHQ.GetSupplies() @ "resources" @ S.AlienResources @ "aggression" @ S.AlienAggression
		@ "satellites_ready" @ S.SatellitesReady @ "satellites_building" @ S.SatellitesDue.Length @ "pending" @ S.PendingKind @ "events" @ S.EventCount
		@ "scientists" @ S.Scientists @ "engineers" @ S.Engineers @ "research_per_hour" @ class'UIUtilities_Strategy'.static.GetXComHQ().GetScienceScore(true) @ "credits" @ S.Credits.Length);
	for (i = 0; i < S.Countries.Length; i++)
		Out.AddItem("country" @ i @ S.Countries[i].Id @ "panic" @ S.Countries[i].Panic @ "satellite" @ int(S.Countries[i].bSatellite) @ "left" @ int(S.Countries[i].bLeft) @ "hunted" @ int(S.Countries[i].bHunted));
	for (i = 0; i < S.Ufos.Length; i++)
		Out.AddItem("ufo" @ i @ "objective" @ S.Ufos[i].Objective @ "group" @ S.Ufos[i].Group @ "last" @ int(S.Ufos[i].bLast) @ "ship" @ S.Ufos[i].Ufo @ "country" @ S.Ufos[i].Country
			@ "hour" @ S.Ufos[i].Hour @ "status" @ S.Ufos[i].Status @ "detected" @ int(S.Ufos[i].bDetected) @ "flight" @ S.Ufos[i].Flight @ "hp" @ S.Ufos[i].Hp @ "maxhp" @ S.Ufos[i].MaxHp
			@ "until" @ S.Ufos[i].Until @ "attacked" @ int(S.Ufos[i].bAttacked));
	for (i = 0; i < S.Sites.Length; i++)
		Out.AddItem("site" @ i @ "terror" @ int(S.Sites[i].bTerror) @ "country" @ S.Sites[i].Country @ "status" @ S.Sites[i].Status @ "until" @ S.Sites[i].Until);
	Decisions(S, Out);
	for (i = Max(0, S.Events.Length - 10); i < S.Events.Length; i++)
		Out.AddItem("event" @ S.Events[i]);
}

defaultproperties
{
	LinkMode = MODE_Text;
	ReceiveMode = RMODE_Event;
	bAlwaysTick = true;
}
