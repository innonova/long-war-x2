// Long War's Geoscape in XCOM 2's game state (features/lw-geoscape.md): the council's countries
// with their panic, satellites and funding; the clock; the aliens' resources, aggression and this
// month's plan (UFOs, abductions, terror); what happened. Saved with the campaign. The rules are
// Long War's (LWStrategyRules, its numbers); where a rule is not read from Long War yet, the
// function says APPROXIMATION.
class XComGameState_LWStrategy extends XComGameState_BaseObject dependson(LWAirWar, LWResearchRules, LWStrategyRules, LWBaseRules);

struct LWCountry
{
	var name Id;
	var int Panic;
	var bool bSatellite;
	var bool bLeft;
	/** A hunt has been over the country (Long War's BeenHunted: the second pass finds satellites more easily). */
	var bool bHunted;
};

/**
 * A UFO of the aliens' objectives (one per phase, LWStrategyRules.Phases). Status: 0 to come,
 * 1 flying to and over its target, 2 leaving after landing, 3 crashed, 4 landed, 5 over.
 */
struct LWUfo
{
	var int Objective;
	/** The objective it belongs to: its phases share it. */
	var int Group;
	/** The objective's last UFO: its success is the objective's. */
	var bool bLast;
	var int Ufo;
	var int Country;
	var int Hour;
	var int Status;
	var bool bDetected;
	var int Flight;
	var int SpendHours;
	var int Hp;
	var int MaxHp;
	var int Until;
	var bool bAttacked;
};

/** An abduction or a terror site, or the aliens at XCOM's headquarters (bHQ). Status: 1 on the map, 2 over. */
struct LWSite
{
	var bool bTerror;
	var bool bHQ;
	var int Country;
	var int Hour;
	var int Status;
	var int Until;
};

/** An engineering project (LWEngineering): Quantity of Long War's item Item, the work left in engineer hours, the engineers on it. */
struct LWBuild
{
	var int Item;
	var int Quantity;
	var int WorkLeft;
	var int Engineers;
};

/** Work in the base (LWBase): 0 digging, 1 a facility; the tile; the hours left. */
struct LWBaseJob
{
	var int Kind;
	var int X;
	var int Y;
	var int Facility;
	var int HoursLeft;
};

var array<LWCountry> Countries;
/** Hours since the campaign began; its first hour is the first of a month. */
var int Hours;
var int Month;
var int AlienResources;
var int AlienAggression;
var array<LWUfo> Ufos;
var int NextGroup;
var array<LWSite> Sites;
/** The countries XCOM left alone this month (Long War's arrCountriesNotHelped): abductions or terror unanswered or lost. */
var array<int> NotHelped;
/** Long War's staff (features/lw-research.md): the research rate is the scientists' (SyncResearch). */
var int Scientists;
var int Engineers;
/** The research credits held (LWResearchRules.CreditShare): interrogations done. */
var array<int> Credits;
/** Terror missions XCOM has taken (Long War's GetNumMissionsTaken(9): its terror squads grow with them). */
var int TerrorsTaken;
/** Enough countries have left: the campaign is lost (the Geoscape shows XCOM 2's defeat). */
var bool bLost;
/** Satellites built and waiting for a country, and the hours the ones in the works are ready. */
var int SatellitesReady;
var array<int> SatellitesDue;
/** The base (LWBase): each tile's ground (rock, open, dug, a facility) and facility, and the work under way. */
var array<int> TileType;
var array<int> TileFacility;
var array<LWBaseJob> BaseJobs;
/** A soldier training a psi power in the Psi Labs (features/lw-psi.md): the unit, the power (Long War's perk id), the hours left. */
struct LWPsiTrainee
{
	var int Unit;
	var int Perk;
	var int HoursLeft;
	var int Chance;
};
var array<LWPsiTrainee> PsiTrainees;
/** The Officer Training School's squad sizes bought (lw-missions.md). */
var int SquadSizesBought;
/** A soldier in the Genetics Lab's tank (features/lw-genemods.md): the unit, the mod (Long War's perk id), the hours left. */
var array<LWPsiTrainee> GeneTrainees;
/** Engineering's projects (LWEngineering). */
var array<LWBuild> Builds;
/** The Foundry's projects under way (Item: the project's id) and those done. */
var array<LWBuild> FoundryProjects;
var array<int> FoundryDone;
var array<string> Events;
/** Events noted since the campaign began (Events keeps the last 40). */
var int EventCount;
/** Set when something wants the player's decision: the clock stops. */
var bool bStop;
/** A mission sent from here and not yet come back: 1 crash site, 2 landed UFO, 3 abduction, 4 terror. */
var int PendingKind;
var int PendingIndex;
/** XCOM 2's mission site launched for it: its battle's result is the mission's. */
var int PendingMission;
/** The mission sent is to come back with an alien taken alive (won without playing it, with a captive). */
var bool bPendingCapture;
/** The squad the mission sent was given (LWMissionSquads): its kill loot is theirs. */
var array<int> PendingSquad;
/** The aliens stunned with the arc thrower in the mission under way (their XCOM 2 character groups; X2Effect_LWCapture). */
var array<name> PendingCaptives;
/** The converted Enemy Within map the mission sent is played on (LWX2EWMapPieces.ChooseMap; "": XCOM 2's plot). */
var string PendingEWMap;
/** Foundry projects whose one-time change to the soldiers' gear has been made (LWX2Gear.ApplyFoundryGear). */
var array<int> FoundryApplied;
/** The civilians of the terror mission sent, counted as it ended: all of them, and those alive (-1: not counted). */
var int PendingCivilians, PendingCiviliansSaved;
/** The story (features/lw-story.md): the countries with an alien base, the Hyperwave Beacon and the Ethereal
 * Device ever held, the campaign won. */
var array<int> AlienBases;
/** The HQ assault: the times a month that could bring it came (Long War's eRecap_ContinentsCovered), and whether one came. */
var int HQAssaultCounter;
var bool bHQAssaultCame;
var bool bHadHyperwaveBeacon;
var bool bHadPsiLink;
var bool bCampaignWon;

// --- Making it ------------------------------------------------------------------------------

static function XComGameState_LWStrategy Get()
{
	return XComGameState_LWStrategy(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LWStrategy', true));
}

/** The campaign's Geoscape, made the first time it is asked for (any campaign, new or loaded). */
static function XComGameState_LWStrategy GetOrCreate()
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;

	S = Get();
	if (S != none)
		return S;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the Geoscape");
	S = XComGameState_LWStrategy(NewGameState.CreateNewStateObject(class'XComGameState_LWStrategy'));
	S.Begin();
	S.SyncResearchIn(NewGameState);
	// Long War's campaign begins with its first mission won: what its aliens left (XCOM 2's first
	// mission, played or skipped, leaves nothing of Long War's).
	S.GiveKillLoot(NewGameState, class'LWAlienSquads'.static.FirstMissionSquad());
	// After the loot's note: the events show the newest first, so this reads above it.
	S.Note("Long War's first mission, won before the campaign began, brought back what its aliens left:");
	// Long War's starting money: the home country's starting cash x StartingCashBalance, in place of XCOM 2's.
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', Round(class'LWStrategyRules'.default.Countries[S.HomeCountry()].StartingCash * class'LWStrategyRules'.default.StartingCashBalance[class'LWStrategyRules'.static.Difficulty()]) - XComHQ.GetSupplies());
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return Get();
}

/** Long War's start: the countries, their starting panic, one satellite at home, the first month's plan. */
function Begin()
{
	local LWStrategyRules.LWCountryDef Def;
	local LWCountry C;
	local array<int> Open;
	local int Points, Step, k;

	foreach class'LWStrategyRules'.default.Countries(Def)
	{
		C.Id = Def.Id;
		C.Panic = 0;
		C.bSatellite = false;
		C.bLeft = false;
		Countries.AddItem(C);
		Open.AddItem(Countries.Length - 1);
	}
	// Long War (XGWorld.AddInitialPanic): the starting panic goes out in steps of
	// UFO_ENTERTAINMENT_SURVIVE to random council countries; a country at 84 (85 "blocks") gets no more.
	Points = class'LWStrategyRules'.default.StartingPanic[class'LWStrategyRules'.static.Difficulty()];
	Step = Max(1, class'LWStrategyRules'.default.StartingPanicStep);
	while (Points > 0 && Open.Length > 0)
	{
		k = Open[Rand(Open.Length)];
		Countries[k].Panic = Min(99, Countries[k].Panic + Step);
		if (Countries[k].Panic + 1 >= 85)
			Open.RemoveItem(k);
		Points -= Step;
	}
	Scientists = class'LWResearchRules'.default.StartingScientists;
	Engineers = class'LWResearchRules'.default.StartingEngineers;
	class'LWBase'.static.Generate(self);
	// Long War (XGWorld.SetStartingContinent): a satellite over the home country. The choice of
	// home is not offered yet: the United States.
	Countries[0].bSatellite = true;
	Note("Day 1. The council funds XCOM. A satellite watches the United States.");
	PlanMonth();
}

// --- The clock ------------------------------------------------------------------------------

static function int HoursPerMonth() { return 30 * 24; }
function int DayOfMonth() { return (Hours % HoursPerMonth()) / 24 + 1; }
function int HourOfDay() { return Hours % 24; }

/** The date as the screen shows it: Long War's campaigns begin on March 1st. */
function string DateText()
{
	local TDateTime T;

	class'X2StrategyGameRulesetDataStructures'.static.SetTime(T, 0, 0, 0, 3, 1, 2015);
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(T, Hours);
	return class'X2StrategyGameRulesetDataStructures'.static.GetDateString(T) @ (HourOfDay() < 10 ? "0" : "") $ HourOfDay() $ ":00";
}

/**
 * Time runs hour by hour until the hours are up or something wants a decision (with bThrough, on
 * regardless: the player answering nothing, for development). Returns the hours that passed.
 */
static function int Run(int MaxHours, optional bool bThrough)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local int n;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: time passes");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.bStop = false;
	// A campaign begun before the base was ported gets Long War's starting base.
	if (S.TileType.Length == 0)
		class'LWBase'.static.Generate(S);
	while (n < MaxHours && (bThrough || !S.bStop) && !S.bLost)
	{
		S.Tick(NewGameState);
		n++;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	XCom2TimePasses(n);
	SyncResearch();
	return n;
}

/**
 * XCOM 2's research runs at Long War's rate (XGFacility_Labs.GetResearchPerHour: scientists x (1 +
 * the labs' bonus); no labs yet): XCOM 2's science score is its research points an hour, so its
 * bonus is set to make up the difference from what XCOM 2's own staff gives (and its difficulty's
 * research time scalar is made up for).
 */
static function SyncResearch()
{
	local XComGameState NewGameState;

	if (Get() == none)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Long War's research rate");
	Get().SyncResearchIn(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom')).HandlePowerOrStaffingChange();
}

function SyncResearchIn(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int Target, Base;

	XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	if (XComHQ == none)
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	Target = Round(ResearchPerHour() * class'X2StrategyGameRulesetDataStructures'.default.ResearchProject_TimeScalar[class'LWStrategyRules'.static.Difficulty()]);
	Base = XComHQ.GetScienceScore(true) - XComHQ.BonusScienceScore;
	XComHQ.BonusScienceScore = Target - Base;
	// No XCOM 2 inspirations or breakthroughs (Long War has neither): their timers never run out, and
	// one already given is taken back.
	class'X2StrategyGameRulesetDataStructures'.static.SetTime(XComHQ.InspiredTechTimer, 0, 0, 0, 1, 1, 9999);
	class'X2StrategyGameRulesetDataStructures'.static.SetTime(XComHQ.BreakthroughTechTimer, 0, 0, 0, 1, 1, 9999);
	if (XComHQ.CurrentInspiredTech.ObjectID != 0)
	{
		XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', XComHQ.CurrentInspiredTech.ObjectID)).bInspired = false;
		XComHQ.CurrentInspiredTech.ObjectID = 0;
	}
	if (XComHQ.CurrentBreakthroughTech.ObjectID != 0)
	{
		XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', XComHQ.CurrentBreakthroughTech.ObjectID)).bBreakthrough = false;
		XComHQ.CurrentBreakthroughTech.ObjectID = 0;
	}
}

/** Long War's research points an hour. */
function float ResearchPerHour()
{
	return Scientists * (1.0 + class'LWBase'.static.LabBonus(self));
}

/** A research credit held (an interrogation done): every Long War tech it covers costs less from now on (LWResearchRules.CreditCut). */
static function CreditHeld(XComGameState NewGameState, int Credit)
{
	local XComGameState_LWStrategy S;
	local XComGameState_Tech Tech;
	local LWResearchRules.LWTechDef T;

	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	if (S.Credits.Find(Credit) == INDEX_NONE)
		S.Credits.AddItem(Credit);
	S.Note("A research credit is held: research it covers will cost less.");
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', Tech)
	{
		foreach class'LWResearchRules'.default.Techs(T)
		{
			if (class'LWResearchRules'.static.TemplateFor(T) != Tech.GetMyTemplateName())
				continue;
			Tech = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', Tech.ObjectID));
			Tech.TimeReductionScalar = class'LWResearchRules'.static.CreditCut(T, S.Credits);
			break;
		}
	}
}

/**
 * XCOM 2's clock moved on with Long War's, and its headquarters' projects done when due (healing,
 * training, building, XCOM 2's research until Long War's replaces it): what XCOM 2's world map does
 * as time passes (XComGameState_HeadquartersXCom.UpdateGameBoard), without the rest of its tick:
 * no dark events, supply drops, Avatar project or XCOM 2 missions.
 */
static function XCom2TimePasses(int PassedHours)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_GameTime TimeState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProject Project;
	local int i, Guard;
	local bool bDone;

	if (PassedHours <= 0)
		return;
	History = `XCOMHISTORY;
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: XCOM 2's clock follows");
	TimeState = XComGameState_GameTime(NewGameState.ModifyStateObject(class'XComGameState_GameTime', TimeState.ObjectID));
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(TimeState.CurrentTime, PassedHours);
	`STRATEGYRULES.GameTime = TimeState.CurrentTime;
	if (`GAME.GetGeoscape() != none)
		`GAME.GetGeoscape().m_kDateTime = TimeState.CurrentTime;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// Projects done, one at a time as XCOM 2 does them (each completion may change the list).
	for (Guard = 0; Guard < 500; Guard++)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		bDone = false;
		for (i = 0; i < XComHQ.Projects.Length && !bDone; i++)
		{
			Project = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(XComHQ.Projects[i].ObjectID));
			if (Project == none)
				continue;
			if (!Project.bIncremental && class'X2StrategyGameRulesetDataStructures'.static.LessThan(Project.CompletionDateTime, TimeState.CurrentTime))
			{
				Project.OnProjectCompleted();
				bDone = true;
			}
			else if (Project.bIncremental && Project.BlocksRemaining <= 0)
			{
				Project.OnProjectCompleted();
				bDone = true;
			}
			else if (Project.bIncremental && class'X2StrategyGameRulesetDataStructures'.static.LessThan(Project.BlockCompletionDateTime, TimeState.CurrentTime))
			{
				Project.OnBlockCompleted();
				bDone = true;
			}
		}
		if (!bDone)
			break;
		XComHQ.HandlePowerOrStaffingChange();
	}
}

function Tick(XComGameState NewGameState)
{
	local int i;

	Hours++;
	class'LWBase'.static.Tick(self);
	class'LWHangar'.static.Hour(NewGameState, self);
	// Engineering: a project whose work is done delivers its items.
	for (i = Builds.Length - 1; i >= 0; i--)
	{
		Builds[i].WorkLeft -= class'LWEngineering'.static.WorkPerHour(Builds[i].Engineers, Engineers);
		if (Builds[i].WorkLeft <= 0)
		{
			class'LWEngineering'.static.Deliver(NewGameState, self, Builds[i]);
			Builds.Remove(i, 1);
			bStop = true;
		}
	}
	for (i = FoundryProjects.Length - 1; i >= 0; i--)
	{
		FoundryProjects[i].WorkLeft -= class'LWEngineering'.static.WorkPerHour(FoundryProjects[i].Engineers, Engineers);
		if (FoundryProjects[i].WorkLeft <= 0)
		{
			FoundryDone.AddItem(FoundryProjects[i].Item);
			Note("The Foundry finished" @ class'LWEngineering'.static.FoundryName(FoundryProjects[i].Item) $ ".");
			FoundryProjects.Remove(i, 1);
			bStop = true;
		}
	}
	// Psi training finished: the roll; on success the power is the soldier's.
	for (i = PsiTrainees.Length - 1; i >= 0; i--)
	{
		if (--PsiTrainees[i].HoursLeft > 0)
			continue;
		PsiTrainingDone(NewGameState, PsiTrainees[i]);
		PsiTrainees.Remove(i, 1);
		bStop = true;
	}
	// Gene mods finished: the mod is the soldier's.
	for (i = GeneTrainees.Length - 1; i >= 0; i--)
	{
		if (--GeneTrainees[i].HoursLeft > 0)
			continue;
		GeneModDone(NewGameState, GeneTrainees[i]);
		GeneTrainees.Remove(i, 1);
		bStop = true;
	}
	// Satellites finished.
	for (i = SatellitesDue.Length - 1; i >= 0; i--)
	{
		if (SatellitesDue[i] <= Hours)
		{
			SatellitesDue.Remove(i, 1);
			SatellitesReady++;
			Note("A satellite is ready to launch.");
			bStop = true;
		}
	}
	for (i = 0; i < Ufos.Length; i++)
		TickUfo(i);
	for (i = 0; i < Sites.Length; i++)
		TickSite(i);
	if (Hours % HoursPerMonth() == 0)
		EndMonth();
}

// --- The aliens' month --------------------------------------------------------------------

/**
 * Long War's monthly plan (XGStrategyAI.AIAddNewObjectives): the aliens' resources grow by 20 per
 * country that has left and are kept between 9 x month and 300; their tier (resources / 50) and
 * aggression pick the month's UFO objectives, abductions and terror; aggression then falls by 2.
 * In the first month the aliens also infiltrate a country off XCOM's continent.
 */
function PlanMonth()
{
	local LWStrategyRules.LWPlanCell Cell;
	local array<int> Targets;
	local int i, n, k, Tier, Start;

	ForgetFinished();
	AlienResources = Clamp(AlienResources + 20 * NumLeft(), 9 * Month, 300);
	Tier = Clamp(AlienResources / 50, 0, 4);
	Start = Month * HoursPerMonth();
	if (class'LWStrategyRules'.static.PlanFor(Tier, Clamp(AlienAggression, 0, 4), Cell))
	{
		for (i = 0; i < Cell.Ufos.Length; i++)
			AddUfos(Cell.Ufos[i], Start);
		for (i = 0; i < Cell.MaybeUfos.Length; i++)
			if (Rand(2) == 0)
				AddUfos(Cell.MaybeUfos[i], Start);
		// Abductions (AddNewAbductions): one country each, spread over the month, no country twice.
		n = Rand(2) == 0 ? Cell.Abductions : Cell.AbductionsAlt;
		for (k = 0; k < Countries.Length; k++)
			if (!Countries[k].bLeft && !IsTerrorTarget(k))
				Targets.AddItem(k);
		for (i = 0; i < n && Targets.Length > 0; i++)
		{
			k = Rand(Targets.Length);
			AddObjective(5, Start, 1 + i * (30 / n) + Rand(Max(1, 30 / n - 1)), Targets[k], -1);
			Targets.Remove(k, 1);
		}
		// Terror (AddNewTerrorMission): the best terror target below the top tier, else anywhere.
		if (Cell.Terror >= 1)
			AddObjective(6, Start, 1 + Rand(23), Tier < 4 ? TerrorTarget() : RandomCountry(), -1);
		if (Cell.Terror >= 2)
			AddObjective(6, Start, 1 + Rand(23), RandomCountry(), -1);
		// The HQ assault (AddHQAssaultMission): every third time such a month comes.
		if (Cell.HQAssault)
		{
			if (HQAssaultCounter % 3 == 2)
				AddHQAssault(Start);
			HQAssaultCounter++;
		}
	}
	// And at month 12 if none has come.
	if (Month == 12 && !bHQAssaultCame && HQAssaultCounter != 3)
	{
		AddHQAssault(Start);
		HQAssaultCounter = 3;
	}
	AlienAggression = Clamp(AlienAggression - 2, 0, 4);
	AddOverseers(Start);
	if (Month == 0)
	{
		do
			k = RandomCountry();
		until (CountryContinent(k) != CountryContinent(HomeCountry()));
		AddObjective(7, Start, 5 + Rand(5), k, -1);
	}
	`log("LongWarX2: Long War month" @ Month @ "planned: resources" @ AlienResources @ "tier" @ Tier @ "aggression" @ Cell.Aggression $ ";" @ Ufos.Length @ "UFOs," @ n @ "abductions," @ Cell.Terror @ "terror", , 'LongWarX2');
}

/** The aliens go for XCOM's headquarters (AddHQAssaultMission): a Battleship hunts over its country on day 2 to 7, an Assault Carrier comes down on it on day 8 to 25. */
function AddHQAssault(int Start)
{
	AddObjective(4, Start, 2 + Rand(6), HomeCountry(), 8);
	AddObjective(9, Start, 8 + Rand(18), HomeCountry(), -1);
	`log("LongWarX2: Long War month" @ Month @ "brings the HQ assault", , 'LongWarX2');
}

/**
 * Long War's Overseers (XGStrategyAI.AddNewOverseers): until XCOM has an Ethereal Device, up to three
 * Overseers fly over watched countries each month, on days 5, 15 and 25; and one over each country that
 * has left, any day from the 5th to the 24th.
 */
function AddOverseers(int Start)
{
	local array<int> Visible;
	local int i, k, n;

	if (!bHadPsiLink)
	{
		Visible = VisibleTargets();
		n = Min(3, Visible.Length);
		for (i = 0; i < n; i++)
		{
			k = Rand(Visible.Length);
			AddObjective(3, Start, 5 + 10 * i, Visible[k], -1);
			if (Visible.Length > 1)
				Visible.Remove(k, 1);
		}
	}
	for (k = 0; k < Countries.Length; k++)
		if (Countries[k].bLeft)
			AddObjective(3, Start, 5 + Rand(20), k, -1);
}

/** Finished UFOs and sites dropped at the month's turn (none while a mission is out: it holds an index). */
function ForgetFinished()
{
	local int i;

	if (PendingKind != 0)
		return;
	for (i = Ufos.Length - 1; i >= 0; i--)
		if (Ufos[i].Status == 5)
			Ufos.Remove(i, 1);
	for (i = Sites.Length - 1; i >= 0; i--)
		if (Sites[i].Status == 2)
			Sites.Remove(i, 1);
}

/**
 * An objective of the plan (Long War's AddUFOs): its target and start day by objective, its ship by
 * the aliens' resources and the campaign's day.
 */
function AddUfos(int Objective, int MonthStart)
{
	local array<int> Targets;
	local int Country, Tries;

	switch (Objective)
	{
	case 0: // recon, scouting: a country XCOM watches
	case 1:
		Country = Pick(VisibleTargets());
		break;
	case 2: // harvest: anywhere; if watched, with aggression, somewhere unwatched (and 5 resources spent finding it)
		Country = RandomCountry();
		if (Countries[Country].bSatellite && Rand(10) < AlienAggression)
		{
			for (Tries = 0; Tries < 16; Tries++)
			{
				Country = RandomCountry();
				if (!Countries[Country].bSatellite)
				{
					AlienResources -= 5;
					break;
				}
			}
		}
		break;
	case 4: // hunt: a watched country among the defectors, else the terror target if watched, else any watched one
		Targets = OverseerTargets();
		Country = Pick(Targets);
		break;
	default: // 7, 8: the terror target
		Country = TerrorTarget();
	}
	AddObjective(Objective, MonthStart, class'LWStrategyRules'.static.DayFor(Objective), Country, Objective == 7 ? -1 : class'LWStrategyRules'.static.ShipFor(Objective, AlienResources, Days()));
}

/** An objective's UFOs, one per phase, each launching no earlier than the one before. */
function AddObjective(int Objective, int MonthStart, int StartDay, int Country, int Ship)
{
	local array<LWStrategyRules.LWPhase> Phases;
	local LWAirWar.LWShip Def;
	local LWUfo U;
	local int i, Hour;

	class'LWStrategyRules'.static.Phases(Objective, Phases);
	Hour = MonthStart;
	for (i = 0; i < Phases.Length; i++)
	{
		U.Objective = Objective;
		U.Group = NextGroup;
		U.bLast = i == Phases.Length - 1;
		U.Ufo = Phases[i].Ship >= 0 ? Phases[i].Ship : Ship;
		U.Country = Country;
		Hour = Max(Hour, MonthStart + class'LWStrategyRules'.static.PhaseHour(StartDay + Phases[i].Day, Phases[i].RandDays));
		U.Hour = Hour;
		U.Flight = Phases[i].Flight;
		U.SpendHours = Phases[i].SpendHours;
		Def = class'LWAirWar'.static.Ufo(U.Ufo, Category());
		U.MaxHp = Def.Hp;
		U.Hp = Def.Hp;
		Ufos.AddItem(U);
	}
	NextGroup++;
}

// --- Targets (Long War's XGStrategyAI.DetermineBest…Targets) ---------------------------------

/** One of the countries, or any council country if there are none (ChooseUFOTarget). */
function int Pick(array<int> Targets)
{
	return Targets.Length > 0 ? Targets[Rand(Targets.Length)] : RandomCountry();
}

/** A council country still in the council (World.GetRandomCouncilCountry). */
function int RandomCountry()
{
	local array<int> Choices;
	local int k;

	for (k = 0; k < Countries.Length; k++)
		if (!Countries[k].bLeft)
			Choices.AddItem(k);
	return Choices.Length > 0 ? Choices[Rand(Choices.Length)] : 0;
}

/** The countries under XCOM's satellites (DetermineBestVisibleTargets). */
function array<int> VisibleTargets()
{
	local array<int> Targets;
	local int k;

	for (k = 0; k < Countries.Length; k++)
		if (Countries[k].bSatellite && !Countries[k].bLeft)
			Targets.AddItem(k);
	return Targets;
}

/** A hunt's targets (DetermineBestOverseerTargets): defectors under a satellite (never, here: a country that leaves loses it); else the terror target if watched; else the watched countries. */
function array<int> OverseerTargets()
{
	local array<int> Targets;
	local int k;

	k = TerrorTarget();
	if (Countries[k].bSatellite)
	{
		Targets.AddItem(k);
		return Targets;
	}
	return VisibleTargets();
}

/**
 * Where the aliens strike (DetermineBestTerrorTarget): any council country while none has left;
 * after that the neighbours of the ones that left. A country already facing terror first, then the
 * most panicked: that one at Long War's AI_TERRORIZE_MOST_PANICKED chance, else one of the top three.
 */
function int TerrorTarget()
{
	local array<int> All;
	local int k, j, n, Best, Swap;
	local name Id;

	for (k = 0; k < Countries.Length; k++)
	{
		if (NumLeft() == 0)
		{
			if (!Countries[k].bLeft)
				All.InsertItem(Rand(All.Length + 1), k);
		}
		else if (Countries[k].bLeft)
		{
			foreach class'LWStrategyRules'.default.Countries[k].Neighbours(Id)
			{
				n = CountryIndex(Id);
				if (n >= 0 && !Countries[n].bLeft)
					All.InsertItem(Rand(All.Length + 1), n);
			}
		}
	}
	if (All.Length == 0)
		return RandomCountry();
	// The top three, in order.
	for (j = 0; j < Min(3, All.Length); j++)
	{
		Best = j;
		for (k = j + 1; k < All.Length; k++)
			if (TerrorRank(All[k]) > TerrorRank(All[Best]))
				Best = k;
		Swap = All[j];
		All[j] = All[Best];
		All[Best] = Swap;
	}
	if (Rand(100) < class'LWStrategyRules'.default.TerrorizeMostPanickedPct)
		return All[0];
	return All[Rand(Min(3, All.Length))];
}

function int TerrorRank(int k)
{
	return (IsTerrorTarget(k) ? 1000 : 0) + Countries[k].Panic;
}

/** A terror objective of the aliens' aims at the country (IsTerrorTarget). */
function bool IsTerrorTarget(int k)
{
	local int i;

	for (i = 0; i < Ufos.Length; i++)
		if (Ufos[i].Objective == 6 && Ufos[i].Country == k && Ufos[i].Status != 5)
			return true;
	return false;
}

function int CountryIndex(name Id)
{
	return class'LWStrategyRules'.default.Countries.Find('Id', Id);
}

/** XCOM's home country, where it began with a satellite. The choice is not offered yet: the United States. */
function int HomeCountry()
{
	return 0;
}

/** The campaign's day, from 1 (Long War's eRecap_Days). */
function int Days()
{
	return Hours / 24 + 1;
}

/** The aliens' research for the air war: Long War's category, about one a month. */
function int Category()
{
	return Month;
}

// --- UFOs -----------------------------------------------------------------------------------

/**
 * A UFO's flight (Long War's XGShip_UFO flight plans): it arrives, then lands for Long War's landed
 * timer and leaves (specimen flights), circles the country and leaves (scouts), flies over and
 * leaves (drop-offs), or touches down and completes its objective (direct). Seen if a satellite
 * watches the country, or by chance by XCOM's jets on the continent.
 */
function TickUfo(int i)
{
	local int Legs;
	local array<int> Ready;

	switch (Ufos[i].Status)
	{
	case 0:
		if (Hours < Ufos[i].Hour)
			return;
		Legs = (Ufos[i].Flight == 0 || Ufos[i].Flight == 3) ? 1 : 3;
		Ufos[i].Status = 1;
		Ufos[i].Until = Hours + Legs * class'LWStrategyRules'.static.LegHours() + (Ufos[i].Flight == 1 ? Ufos[i].SpendHours : 0);
		// Without a satellite, each ready interceptor on the continent may spot it, twice as likely with the
		// Foundry's Enhanced UFO Detection (35) (XGGeoscape: GetNumInterceptorsInRangeAndAvailable).
		Ready = class'LWHangar'.static.ReadyOn(CountryContinent(Ufos[i].Country));
		if (Countries[Ufos[i].Country].bSatellite || Rand(100) < class'LWStrategyRules'.default.InterceptorDetectPct * (FoundryDone.Find(35) != INDEX_NONE ? 2 : 1) * Ready.Length)
		{
			Ufos[i].bDetected = true;
			Note("UFO detected over" @ CountryName(Ufos[i].Country) $ ":" @ ShipName(Ufos[i].Ufo) $ "," @ class'LWStrategyRules'.static.ObjectiveName(Ufos[i].Objective) $ ".");
			bStop = true;
		}
		return;
	case 1:
		if (Hours < Ufos[i].Until)
			return;
		if (Ufos[i].Flight == 0)
		{
			Ufos[i].Status = 4;
			Ufos[i].Until = Hours + class'LWStrategyRules'.default.LandedUfoHours;
			if (Ufos[i].bDetected)
			{
				Note("The" @ ShipName(Ufos[i].Ufo) @ "has landed in" @ CountryName(Ufos[i].Country) $ ". It leaves in" @ class'LWStrategyRules'.default.LandedUfoHours @ "hours.");
				bStop = true;
			}
			return;
		}
		UfoDone(i);
		return;
	case 2:
		if (Hours >= Ufos[i].Until)
			UfoDone(i);
		return;
	case 3:
		if (Hours < Ufos[i].Until)
			return;
		Ufos[i].Status = 5;
		Note("The crash site in" @ CountryName(Ufos[i].Country) @ "is gone.");
		return;
	case 4:
		if (Hours < Ufos[i].Until)
			return;
		Ufos[i].Status = 2;
		Ufos[i].Until = Hours + class'LWStrategyRules'.static.LegHours();
		return;
	}
}

/**
 * A UFO's mission done (Long War's LogUFORecord, OnObjectiveEnded): panic in the country for every
 * UFO but a hunt's or an Overseer's (an air raid's own), less in proportion to its damage; a
 * harvest brings the aliens resources. The objective's last UFO completes it: a hunt may find the
 * satellite, an abduction or terror site appears, an infiltrated country leaves the council.
 */
function UfoDone(int i)
{
	local LWUfo U;
	local float Intact;

	Ufos[i].Status = 5;
	U = Ufos[i];
	Intact = U.MaxHp > 0 ? float(U.Hp) / float(U.MaxHp) : 1.0;
	if (U.Objective != 4 && U.Ufo != 9)
		AddPanic(U.Country, int((U.Objective == 8 ? class'LWStrategyRules'.default.PanicAirRaid : class'LWStrategyRules'.default.PanicUfoIgnored) * Intact));
	if (U.Objective == 2 && class'LWStrategyRules'.static.HarvestOf(U.Ufo) > 0)
		AlienResources += class'LWStrategyRules'.static.HarvestOf(U.Ufo) + Rand(5);
	if (U.bDetected && U.Objective != 5 && U.Objective != 6 && U.Objective != 7)
		Note("The" @ ShipName(U.Ufo) @ "over" @ CountryName(U.Country) @ "finished its mission.");
	if (!U.bLast)
		return;
	switch (U.Objective)
	{
	case 4:
		if (FoundSatellite(U))
		{
			Countries[U.Country].bSatellite = false;
			AddPanic(U.Country, class'LWStrategyRules'.default.PanicSatDestroyedCountry);
			AddContinentPanic(CountryContinent(U.Country), class'LWStrategyRules'.default.PanicSatDestroyedContinent);
			Note("A satellite over" @ CountryName(U.Country) @ "was destroyed.");
			bStop = true;
		}
		Countries[U.Country].bHunted = true;
		break;
	case 5:
		AddSite(false, U.Country);
		break;
	case 6:
		AddSite(true, U.Country);
		break;
	case 7:
		if (!Countries[U.Country].bLeft)
		{
			Leave(U.Country);
			Note(CountryName(U.Country) @ "has signed a pact with the aliens and left the council.");
			bStop = true;
		}
		break;
	case 9:
		AddHQSite();
		break;
	}
}

/** A hunt's chance to find the satellite (XGAlienObjective.FoundSatellite): by its UFO's damage, more on a second pass. */
function bool FoundSatellite(LWUfo U)
{
	local int Chance;

	if (!Countries[U.Country].bSatellite)
		return false;
	Chance = Max(0, 200 * U.Hp / Max(1, U.MaxHp) - 100);
	// Stealth Satellites (the Foundry's project 17) are harder to find (XGAlienObjective).
	if (FoundryDone.Find(17) != INDEX_NONE)
		Chance = Chance * (Countries[U.Country].bHunted ? class'LWStrategyRules'.default.UfoSecondPassFindStealthSatPct : class'LWStrategyRules'.default.UfoFindStealthSatPct) / 100;
	else
		Chance = Chance * (Countries[U.Country].bHunted ? class'LWStrategyRules'.default.UfoSecondPassFindSatPct : class'LWStrategyRules'.default.UfoFindSatPct) / 100;
	return Rand(100) < Chance;
}

/** A country leaves the council (XGCountry.LeaveXComProject): its satellite lost, the aliens 50 resources poorer after the first month; the aliens build a base there (XGStrategyAI.AddToAssets, CreateAlienBase). */
function Leave(int Country)
{
	if (AlienBases.Find(Country) == INDEX_NONE)
	{
		AlienBases.AddItem(Country);
		Note("The aliens are building a base in" @ CountryName(Country) $ ". A Skeleton Key would open it.");
	}
	Countries[Country].bLeft = true;
	Countries[Country].bSatellite = false;
	if (Month != 0)
		AlienResources -= 50;
	// XGStrategy.CheckForLoseGame.
	if (!bLost && NumLeft() >= class'LWStrategyRules'.default.LoseCountries)
	{
		bLost = true;
		bStop = true;
		Note("The council has fallen: the campaign is lost.");
	}
}

/** The aliens' aggression for a UFO brought down (Long War's LogUFORecord): 1, and 1 more for the large ships. */
function UfoDowned(LWUfo U)
{
	AlienAggression += 1;
	if ((U.Ufo >= 7 && U.Ufo <= 9) || (U.Ufo >= 12 && U.Ufo <= 14))
		AlienAggression += 1;
}

/**
 * An interception's result (Long War's OnUFOShotDown, OnUFODestroyed, LogUFORecord): the aliens lose
 * resources in proportion to the damage (all of the UFO's worth when it comes down); shot down, their
 * aggression rises and the country's panic falls; a crash site lasts Long War's crash timer.
 */
static function Intercepted(int i, int Outcome, int UfoHp)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local LWUfo U;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: an interception");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	U = S.Ufos[i];
	U.bAttacked = true;
	U.Hp = (Outcome == 0 || Outcome == 1) ? 0 : Max(0, UfoHp);
	S.AlienResources -= Round(class'LWStrategyRules'.static.WorthOf(U.Ufo) * (1.0 - float(U.Hp) / float(Max(1, U.MaxHp))));
	if (Outcome == 0 || Outcome == 1) // crashed or destroyed
	{
		S.UfoDowned(U);
		S.AddPanic(U.Country, class'LWStrategyRules'.default.PanicUfoShotDown);
		if (Outcome == 0)
		{
			U.Status = 3;
			U.Until = S.Hours + class'LWStrategyRules'.default.CrashSiteHours;
			S.Note("The" @ S.ShipName(U.Ufo) @ "is down in" @ S.CountryName(U.Country) $ ": a crash site for" @ class'LWStrategyRules'.default.CrashSiteHours @ "hours.");
		}
		else
		{
			U.Status = 5;
			S.Note("The" @ S.ShipName(U.Ufo) @ "broke up over" @ S.CountryName(U.Country) $ ".");
		}
	}
	else
	{
		U.Hp = Max(0, UfoHp);
		S.Note("The" @ S.ShipName(U.Ufo) @ "got away, damaged" @ (100 - 100 * U.Hp / Max(1, U.MaxHp)) $ "%.");
	}
	S.Ufos[i] = U;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// --- Abductions and terror -----------------------------------------------------------------

/** An abduction or terror site, now on the map (its UFO came down): XCOM has Long War's timer to answer it. */
function AddSite(bool bTerror, int Country)
{
	local LWSite Site;

	Site.bTerror = bTerror;
	Site.Country = Country;
	Site.Hour = Hours;
	Site.Status = 1;
	Site.Until = Hours + (bTerror ? class'LWStrategyRules'.default.TerrorHours : class'LWStrategyRules'.default.AbductionHours);
	Sites.AddItem(Site);
	Note((bTerror ? "Terror in" : "Abductions in") @ CountryName(Country) $ ". XCOM has" @ (Site.Until - Hours) @ "hours.");
	bStop = true;
}

/** The Assault Carrier is down at XCOM's headquarters: the base must be defended (Long War forces the mission; unanswered, it is lost). */
function AddHQSite()
{
	local LWSite Site;

	Site.bHQ = true;
	Site.Country = HomeCountry();
	Site.Hour = Hours;
	Site.Status = 1;
	Site.Until = Hours + class'LWStrategyRules'.default.TerrorHours;
	Sites.AddItem(Site);
	bHQAssaultCame = true;
	Note("The aliens are assaulting XCOM's headquarters! Defend it within" @ (Site.Until - Hours) @ "hours.");
	bStop = true;
}

function TickSite(int i)
{
	if (Sites[i].Status == 1 && Hours >= Sites[i].Until)
	{
		Sites[i].Status = 2;
		SiteIgnored(i);
	}
}

/**
 * Long War's result for an abduction or terror site XCOM did not answer or lost (XGStrategyAI.
 * ApplyMissionPanic): abductions, panic in the country and on its continent; terror, the country
 * leaves the council and its continent panics.
 */
/**
 * A terror mission won (Long War's XGStrategyAI.ApplyMissionPanic, terror, and CalcTerrorMissionPanicResult): the country
 * panics by the civilians lost, its continent too; with no civilian saved the country leaves all the same. A country
 * gone already (Long War's secret pact) only moves its continent. Not counted (won without playing it): no panic.
 */
function TerrorWon(int i)
{
	local int Country, Lost;

	Country = Sites[i].Country;
	if (PendingCivilians < 0)
		return;
	Lost = PendingCivilians - PendingCiviliansSaved;
	Note(PendingCiviliansSaved @ "of" @ PendingCivilians @ "civilians saved in" @ CountryName(Country) $ ".");
	AddContinentPanic(CountryContinent(Country), Lost * class'LWStrategyRules'.default.PanicTerrorCivilianContinent);
	if (Countries[Country].bLeft)
		return;
	if (PendingCiviliansSaved == 0)
	{
		Leave(Country);
		Note("No civilian was saved in" @ CountryName(Country) $ ": it has left the council.");
		return;
	}
	AddPanic(Country, Lost * class'LWStrategyRules'.default.PanicTerrorCivilianCountry);
}

function SiteIgnored(int i)
{
	local int d;

	d = class'LWStrategyRules'.static.Difficulty();
	if (Sites[i].bHQ)
	{
		bLost = true;
		bStop = true;
		Note("XCOM's headquarters has fallen. The war is lost.");
		return;
	}
	if (NotHelped.Find(Sites[i].Country) == INDEX_NONE)
		NotHelped.AddItem(Sites[i].Country);
	if (Sites[i].bTerror)
	{
		if (!Countries[Sites[i].Country].bLeft)
		{
			Leave(Sites[i].Country);
			Note("Terror in" @ CountryName(Sites[i].Country) @ "went unanswered: it has left the council.");
		}
		AddContinentPanic(CountryContinent(Sites[i].Country), class'LWStrategyRules'.default.PanicTerrorContinent);
	}
	else
	{
		AddPanic(Sites[i].Country, class'LWStrategyRules'.default.PanicAbductionCountry[d]);
		AddContinentPanic(CountryContinent(Sites[i].Country), class'LWStrategyRules'.default.PanicAbductionContinent[d]);
		Note("The abductions in" @ CountryName(Sites[i].Country) @ "went unanswered.");
	}
}

// --- Missions sent from here -------------------------------------------------------------

/** A mission won without playing it (the Geoscape's WIN, the control port's resolve): sent and come back won. */
static function WonWithoutPlaying(int Kind, int Index, optional bool bCapture)
{
	MissionSent(Kind, Index, bCapture);
	MissionBack(true);
}

/** The aliens of the mission sent (Long War's squad for it): a UFO's crew, an abduction's, a terror site's; for the story's
 * missions, a Battleship's crew (the alien base) or an Assault Carrier's (the HQ assault, the Temple Ship; APPROXIMATION). */
function array<int> MissionSquad()
{
	local int Country;

	if (PendingKind == 5)
		return class'LWAlienSquads'.static.SquadFor(2, 8, Days(), AlienAggression, AlienResources, 0, TerrorsTaken);
	if (PendingKind >= 6)
		return class'LWAlienSquads'.static.SquadFor(2, 14, Days(), AlienAggression, AlienResources, 0, TerrorsTaken);
	Country = PendingKind <= 2 ? Ufos[PendingIndex].Country : Sites[PendingIndex].Country;
	return class'LWAlienSquads'.static.SquadFor(PendingKind, PendingKind <= 2 ? Ufos[PendingIndex].Ufo : 0, Days(),
		AlienAggression, AlienResources, PendingKind == 3 ? AbductionDifficulty(Country) : 0, TerrorsTaken);
}

/** A mission is sent to a crash site (1), landed UFO (2), abduction (3) or terror site (4). */
static function MissionSent(int Kind, int Index, optional bool bCapture)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a mission sent");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.PendingKind = Kind;
	S.PendingIndex = Index;
	S.bPendingCapture = bCapture;
	S.PendingCaptives.Length = 0;
	S.PendingSquad.Length = 0;
	S.PendingCivilians = -1;
	S.PendingCiviliansSaved = -1;
	if (Kind <= 2)
		S.Ufos[Index].Status = 5;
	else if (Kind <= 4 || Kind == 7)
		S.Sites[Index].Status = 2;
	// An alien base takes a Skeleton Key, whatever comes of it (XGStrategy: STORAGE().RemoveItem(184)).
	if (Kind == 5)
		class'LWEngineering'.static.Take(NewGameState, 'LWItem_Skeleton_Key', 1);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function MissionLaunched(int MissionID)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a mission launched");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.PendingMission = MissionID;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** Back on the Geoscape: if the mission sent from it has been played, its result applied. */
static function CheckMissionBack()
{
	local XComGameState_BattleData Battle;

	if (Get() == none || Get().PendingKind == 0 || Get().PendingMission == 0)
		return;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	if (Battle != none && Battle.m_iMissionID == Get().PendingMission)
		MissionBack(Battle.bLocalPlayerWon);
}

/** The mission came back: Long War's panic for it, won or lost. */
static function MissionBack(bool bWon)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local LWUfo U;
	local int Country;
	local array<int> Squad;

	if (Get() == none || Get().PendingKind == 0)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a mission back");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	Country = S.PendingKind <= 2 ? S.Ufos[S.PendingIndex].Country : ((S.PendingKind <= 4 || S.PendingKind == 7) ? S.Sites[S.PendingIndex].Country : (S.PendingKind == 5 ? S.PendingIndex : S.HomeCountry()));
	if (S.PendingKind >= 5)
	{
		S.StoryMissionBack(NewGameState, bWon, Country);
		S.PendingKind = 0;
		S.PendingMission = 0;
		S.bPendingCapture = false;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		return;
	}
	// What the aliens killed leave (all of them, a mission won: our missions do not count them yet).
	if (bWon)
	{
		// The squad the mission was given when it was played; else Long War's for it.
		Squad = S.PendingSquad.Length > 0 ? S.PendingSquad : S.MissionSquad();
		if (S.bPendingCapture)
			S.TakeCaptive(NewGameState, Squad);
		S.BringCaptivesHome(NewGameState, Squad);
		S.GiveKillLoot(NewGameState, Squad);
	}
	S.bPendingCapture = false;
	S.PendingCaptives.Length = 0;
	if (S.PendingKind == 4)
	{
		S.TerrorsTaken++;
		if (bWon)
			S.TerrorWon(S.PendingIndex);
	}
	if (S.PendingKind == 3 && bWon)
		S.GiveAbductionReward(NewGameState, Country);
	if (S.PendingKind == 1)
	{
		if (bWon)
		{
			S.AddPanic(Country, class'LWStrategyRules'.default.PanicUfoAssault);
			S.GiveSalvage(NewGameState, S.Ufos[S.PendingIndex].Ufo, true);
		}
	}
	else if (S.PendingKind == 2)
	{
		// Long War's XGStrategy mission results and LogUFORecord: taken, the UFO counts as brought
		// down; lost, it escapes with its harvest and the country panics.
		U = S.Ufos[S.PendingIndex];
		if (bWon)
		{
			S.AddPanic(Country, class'LWStrategyRules'.default.PanicUfoAssault);
			S.UfoDowned(U);
			S.AlienResources -= class'LWStrategyRules'.static.WorthOf(U.Ufo);
			S.GiveSalvage(NewGameState, U.Ufo, false);
		}
		else
		{
			S.AddPanic(Country, class'LWStrategyRules'.default.PanicUfoEscaped);
			if (U.Objective == 2 && class'LWStrategyRules'.static.HarvestOf(U.Ufo) > 0)
				S.AlienResources += class'LWStrategyRules'.static.HarvestOf(U.Ufo) + Rand(5);
		}
	}
	else if (S.PendingKind == 3)
	{
		if (bWon)
			S.AddPanic(Country, class'LWStrategyRules'.default.PanicAbductionThwartedCountry);
		else
			S.SiteIgnored(S.PendingIndex);
	}
	else if (!bWon)
		S.SiteIgnored(S.PendingIndex);
	S.Note("The mission in" @ S.CountryName(Country) @ (bWon ? "succeeded." : "failed."));
	S.PendingKind = 0;
	S.PendingMission = 0;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/**
 * A story mission back (features/lw-story.md). The HQ assault (kind 7): held, or the war is lost. An alien base (kind 5) taken: the country rejoins the council
 * at 98 panic less PanicAlienBaseCountry, its continent PanicAlienBaseContinent (XGStrategyAI: CostTest, the
 * mission's results); its artifacts (CreateAlienBase), and the first time the Hyperwave Beacon. The Temple
 * Ship (kind 6): won, the campaign is won; lost, it is lost (XGStrategy: YouWin, YouLose).
 */
function StoryMissionBack(XComGameState NewGameState, bool bSuccess, int Country)
{
	local int d;

	if (PendingKind == 7)
	{
		if (bSuccess)
		{
			// What the aliens killed leave: the Assault Carrier's crew (APPROXIMATION: Long War's HQ assault squad is its own).
			GiveKillLoot(NewGameState, class'LWAlienSquads'.static.SquadFor(2, 14, Days(), AlienAggression, AlienResources, 0, TerrorsTaken));
			Note("XCOM's headquarters held.");
		}
		else
		{
			bLost = true;
			bStop = true;
			Note("XCOM's headquarters has fallen. The war is lost.");
		}
		return;
	}
	if (PendingKind == 6)
	{
		if (bSuccess)
		{
			bCampaignWon = true;
			bStop = true;
			Note("The Temple Ship is destroyed. XCOM has won the war.");
		}
		else
		{
			bLost = true;
			bStop = true;
			Note("The assault on the Temple Ship failed. The war is lost.");
		}
		return;
	}
	if (!bSuccess)
	{
		Note("The assault on the alien base in" @ CountryName(Country) @ "failed; the Skeleton Key is lost.");
		return;
	}
	d = class'LWStrategyRules'.static.Difficulty();
	// What the aliens killed leave: APPROXIMATION, a Battleship's crew for Long War's base squad (DetermineAlienBaseSquad).
	GiveKillLoot(NewGameState, class'LWAlienSquads'.static.SquadFor(2, 8, Days(), AlienAggression, AlienResources, 0, TerrorsTaken));
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'Alloys', Cargo('Alloys', 100));
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'UFOPowerSource', 3);
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'Elerium', Cargo('Elerium', 3 * class'LWStrategyRules'.default.EleriumPerPowerSource[d]));
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'AlienSurgery', 4);
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'AlienStasisTank', 15);
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'AlienFood', 10);
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'AlienEntertainment', 1);
	if (!bHadHyperwaveBeacon)
	{
		class'X2Item_LWArtifacts'.static.Give(NewGameState, 'HyperwaveBeacon', 1);
		bHadHyperwaveBeacon = true;
		Note("In the alien base: a Hyperwave Beacon.");
	}
	AlienBases.RemoveItem(Country);
	Countries[Country].bLeft = false;
	Countries[Country].Panic = 98;
	AddPanic(Country, class'LWStrategyRules'.default.PanicAlienBaseCountry);
	AddContinentPanic(CountryContinent(Country), class'LWStrategyRules'.default.PanicAlienBaseContinent);
	Note("The alien base in" @ CountryName(Country) @ "is destroyed, and" @ CountryName(Country) @ "rejoins the council.");
}

// --- Salvage ------------------------------------------------------------------------------

/**
 * A UFO's salvage to XCOM's stores (XGItemTree.DetermineShipSalvage, XGStrategyAI.DetermineCrashLoot):
 * its artifacts, alloys (x AlloyBalance) and elerium (power sources x EleriumPerPowerSource), 20 % more
 * of both once its UFO analysis is researched. Crashed: 30-45 % of the alloys, each artifact at its
 * chance, and 70-100 % of a power source's elerium lost with each power source destroyed.
 */
function GiveSalvage(XComGameState NewGameState, int Ufo, bool bCrashed)
{
	local LWStrategyRules.LWSalvage Item;
	local int d, j, k, Count, Total, Alloys, Elerium;
	local float Bonus;
	local string Got;

	d = class'LWStrategyRules'.static.Difficulty();
	Bonus = class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(class'LWResearchRules'.static.TemplateForId(57 + Ufo)) ? 1.2 : 1.0;
	foreach class'LWStrategyRules'.default.Salvage(Item)
	{
		if (Item.Ufo != Ufo)
			continue;
		if (Item.Item == 'Alloys')
		{
			Alloys = int(Item.Count * class'LWStrategyRules'.default.AlloyBalance[d]);
			if (bCrashed)
				Alloys = int(Alloys * RandRange(class'LWStrategyRules'.default.MinWreckedAlloys, class'LWStrategyRules'.default.MaxWreckedAlloys));
			continue;
		}
		Total = Item.Count;
		Count = Total;
		if (bCrashed)
		{
			// Each one survives at its chance (GetSurvivingCollectibles).
			k = class'LWStrategyRules'.default.Survive.Find('Item', Item.Item);
			Count = 0;
			for (j = 0; j < Total; j++)
				if (Rand(100) < (k == INDEX_NONE ? 100 : class'LWStrategyRules'.default.Survive[k].Percent))
					Count++;
		}
		if (Item.Item == 'UFOPowerSource')
		{
			Elerium = Total * class'LWStrategyRules'.default.EleriumPerPowerSource[d];
			if (bCrashed)
				Elerium -= int(RandRange(class'LWStrategyRules'.default.MinLostWreckedElerium * class'LWStrategyRules'.default.EleriumPerPowerSource[d],
					class'LWStrategyRules'.default.MaxLostWreckedElerium * class'LWStrategyRules'.default.EleriumPerPowerSource[d]) * (Total - Count));
		}
		class'X2Item_LWArtifacts'.static.Give(NewGameState, Item.Item, Cargo(Item.Item, Count));
		if (Item.Item == 'PsiLink' && Count > 0)
			bHadPsiLink = true;
		if (Count > 0)
			Got $= "," @ Count @ class'X2Item_LWArtifacts'.static.DisplayName(Item.Item);
	}
	Alloys = int(Alloys * Bonus);
	Elerium = Max(0, int(Elerium * Bonus));
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'Alloys', Cargo('Alloys', Alloys));
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'Elerium', Cargo('Elerium', Elerium));
	// The UFO type counts as captured (the UFO analyses ask for it).
	if (class'UIUtilities_Strategy'.static.GetXComHQ().GetItemByName(class'X2Item_LWArtifacts'.static.CapturedMarker(Ufo)) == none)
		class'X2Item_LWArtifacts'.static.GiveItem(NewGameState, class'X2Item_LWArtifacts'.static.CapturedMarker(Ufo), 1);
	Note("Salvage:" @ Alloys @ "alloys," @ Elerium @ "elerium" $ Got $ ".");
}

/**
 * What the aliens of a mission won leave (XGSummaryUI.CollectArtifactsFromDeadAliens, XGUnit's death):
 * each its corpse, its weapons' fragments (x FragmentBalance, at least one each), the elerium, alloys
 * and meld points of the mechanical ones and meld for the rest (ten points make one). As if none
 * was killed by an explosion and none taken alive: our missions do not tell yet.
 */
function GiveKillLoot(XComGameState NewGameState, array<int> Squad)
{
	local LWStrategyRules.LWSpecies Sp;
	local array<name> Corpses;
	local array<int> CorpseCounts;
	local int a, k, f, d, Fragments, Elerium, Alloys, Meld;
	local string Got;

	d = class'LWStrategyRules'.static.Difficulty();
	foreach Squad(a)
	{
		k = class'LWStrategyRules'.default.Species.Find('Char', a);
		if (k == INDEX_NONE)
			continue;
		Sp = class'LWStrategyRules'.default.Species[k];
		foreach Sp.Fragments(f)
			Fragments += Max(1, int(f * class'LWStrategyRules'.default.FragmentBalance[d]));
		Elerium += Sp.Elerium;
		Alloys += Sp.Alloys;
		Meld += Sp.Meld;
		AddCount(Corpses, CorpseCounts, Sp.Corpse);
		AddCount(Corpses, CorpseCounts, Sp.ExtraCorpse);
	}
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'WeaponFragment', Cargo('WeaponFragment', Fragments));
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'Elerium', Cargo('Elerium', Elerium / 10));
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'Alloys', Cargo('Alloys', Alloys / 10));
	class'X2Item_LWArtifacts'.static.Give(NewGameState, 'Meld', Meld / 10);
	for (k = 0; k < Corpses.Length; k++)
	{
		class'X2Item_LWArtifacts'.static.Give(NewGameState, Corpses[k], CorpseCounts[k]);
		Got $= "," @ CorpseCounts[k] @ class'X2Item_LWArtifacts'.static.DisplayName(Corpses[k]);
	}
	Note("The aliens killed (" $ Squad.Length $ ") left:" @ Fragments @ "weapon fragments," @ Elerium / 10 @ "elerium," @ Alloys / 10 @ "alloys," @ Meld / 10 @ "meld" $ Got $ ".");
}

/**
 * An alien of the squad taken alive (the arc thrower; in XCOM 2 a mission won without playing it, with a
 * captive): the most valuable kind there, out of the squad's dead. Its weapons come home intact; the
 * captive to Alien Containment, or, without one, dead (its corpse; XGFacility_Hangar.UnloadArtifacts).
 * Needs the Arc Thrower researched.
 */
function TakeCaptive(XComGameState NewGameState, out array<int> Squad)
{
	local array<int> Order;
	local int i, j;

	if (!class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(class'LWResearchRules'.static.TemplateForId(2)))
	{
		Note("No alien could be taken alive: the Arc Thrower is not researched.");
		return;
	}
	// The leaders first (the captives research most wants), then by toughness.
	Order.AddItem(9); Order.AddItem(12); Order.AddItem(11); Order.AddItem(10); Order.AddItem(15);
	Order.AddItem(7); Order.AddItem(6); Order.AddItem(5); Order.AddItem(4);
	for (i = 0; i < Order.Length; i++)
	{
		j = Squad.Find(Order[i]);
		if (j == INDEX_NONE || !GiveCaptive(NewGameState, Order[i]))
			continue;
		Squad.Remove(j, 1);
		return;
	}
	Note("No alien there could be taken alive.");
}

/** A captive of a Long War species home: its weapons intact; it to Alien Containment, or dead without one. False if the species is never taken alive. */
function bool GiveCaptive(XComGameState NewGameState, int Char)
{
	local LWStrategyRules.LWSpecies Sp;
	local name W;
	local string Got;
	local int k;

	k = class'LWStrategyRules'.default.Species.Find('Char', Char);
	if (k == INDEX_NONE || class'LWStrategyRules'.default.Species[k].Captive == '')
		return false;
	Sp = class'LWStrategyRules'.default.Species[k];
	foreach Sp.Weapons(W)
	{
		class'X2Item_LWArtifacts'.static.Give(NewGameState, W, 1);
		Got $= "," @ class'X2Item_LWArtifacts'.static.DisplayName(W);
	}
	if (TileFacility.Length == 0 || class'LWBase'.static.Count(self, 13) > 0)
	{
		class'X2Item_LWArtifacts'.static.Give(NewGameState, Sp.Captive, 1);
		Note("Taken alive:" @ class'X2Item_LWArtifacts'.static.DisplayName(Sp.Captive) @ "to Alien Containment" $ Got $ ".");
	}
	else
	{
		class'X2Item_LWArtifacts'.static.Give(NewGameState, Sp.Corpse, 1);
		Note("Taken alive, but without Alien Containment it died:" @ class'X2Item_LWArtifacts'.static.DisplayName(Sp.Corpse) $ Got $ ".");
	}
	return true;
}

/**
 * The aliens stunned with the arc thrower in the mission (PendingCaptives) home as Long War's captives
 * (LWStrategyRules.CaptureAs: XCOM 2's kind of alien as Long War's species, until Enemy Within's aliens
 * are the missions'); one of that species is then not among the dead.
 */
function BringCaptivesHome(XComGameState NewGameState, out array<int> Squad)
{
	local name Group;
	local int k, j;

	foreach PendingCaptives(Group)
	{
		k = class'LWStrategyRules'.default.CaptureAs.Find('Group', Group);
		if (k == INDEX_NONE || !GiveCaptive(NewGameState, class'LWStrategyRules'.default.CaptureAs[k].Char))
		{
			Note("A stunned" @ Group @ "came home, but Long War has no captive of its kind.");
			continue;
		}
		j = Squad.Find(class'LWStrategyRules'.default.CaptureAs[k].Char);
		if (j != INDEX_NONE)
			Squad.Remove(j, 1);
	}
}

/** What the Skyranger brings home, with the Foundry's Alien Metallurgy (alloys), Alien Nucleonics
 * (elerium) and Improved Salvage (fragments): a fifth more each (XGFacility_Hangar.UnloadArtifacts). */
function int Cargo(name Artifact, int Count)
{
	if ((Artifact == 'Alloys' && FoundryDone.Find(25) != INDEX_NONE)
		|| (Artifact == 'Elerium' && FoundryDone.Find(38) != INDEX_NONE)
		|| (Artifact == 'WeaponFragment' && FoundryDone.Find(39) != INDEX_NONE))
		return int(Count * 1.2);
	return Count;
}

static function AddCount(out array<name> Names, out array<int> Counts, name N)
{
	local int k;

	if (N == '')
		return;
	k = Names.Find(N);
	if (k == INDEX_NONE)
	{
		Names.AddItem(N);
		Counts.AddItem(1);
	}
	else
		Counts[k]++;
}

/** An abduction's difficulty (XGStrategyAI.GetAbductionDifficulty): the act (1 for now) and the country's panic, 0-3. */
function int AbductionDifficulty(int Country)
{
	local int Diff;

	Diff = 1 - 1 + (Countries[Country].Panic + 1) / 20 - 1 + Rand(2);
	if (Days() > 210)
		Diff += Rand(2);
	return Clamp(Diff, 0, 3);
}

/** An abduction won: Long War's cash (DetermineAbductionReward: every abduction pays cash), by its difficulty. */
function GiveAbductionReward(XComGameState NewGameState, int Country)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int Cash, Diff;

	Diff = AbductionDifficulty(Country);
	Cash = int(class'LWStrategyRules'.default.AbductionRewardCash * (Diff == 0 ? 0.8 : (Diff == 1 ? 0.9 : (Diff == 2 ? 1.0 : 1.15))));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	if (XComHQ == none)
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', Cash);
	Note("The abduction's reward:" @ class'LWStrategyRules'.static.Money(Cash) $ ".");
}

// --- Satellites ------------------------------------------------------------------------------

static function bool BuildSatellite()
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ.GetSupplies() < class'LWStrategyRules'.default.SatelliteCost)
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a satellite ordered");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -class'LWStrategyRules'.default.SatelliteCost);
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.SatellitesDue.AddItem(S.Hours + 24 * class'LWStrategyRules'.default.SatelliteDays);
	S.Note("A satellite ordered: ready in" @ class'LWStrategyRules'.default.SatelliteDays @ "days.");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

/** A ready satellite put over a country: Long War's panic relief for it. */
static function bool LaunchSatellite(int Country)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	if (Get().SatellitesReady <= 0 || Get().Countries[Country].bSatellite || Get().Countries[Country].bLeft)
		return false;
	// The uplinks hold so many (Long War's satellite limit); a campaign without its base yet is not held back.
	if (Get().TileType.Length > 0 && class'LWBase'.static.SatellitesUp(Get()) >= class'LWBase'.static.SatelliteLimit(Get()))
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a satellite launched");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.SatellitesReady--;
	S.Countries[Country].bSatellite = true;
	S.AddPanic(Country, class'LWStrategyRules'.default.PanicSatAddedCountry);
	S.AddContinentPanic(S.CountryContinent(Country), class'LWStrategyRules'.default.PanicSatAddedContinent);
	S.Note("A satellite now watches" @ S.CountryName(Country) $ ".");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

// --- The month's end ----------------------------------------------------------------------

/**
 * The council's meeting (Long War's XGWorld council meeting): first who leaves (XGContinent.
 * WhoIsLeaving): a country XCOM left alone this month (abductions or terror unanswered or lost) at
 * the not-helped threshold rolls (panic blocks)^2 / 100 %, any other at the threshold blocks x
 * chance per block %; a satellite over it, or else on its continent, cuts the chance; a country
 * with abductions under way stays. Then the funding (each country's amount x FundingBalance; without
 * a satellite BASE_FUNDING% of it) from those still in; then the satellites' panic relief (a chance
 * by panic level). Then the next month's plan.
 */
function EndMonth()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local LWStrategyRules.LWCountryDef Def;
	local array<int> Leaving;
	local int i, d, Blocks, Funding, Chance, Upkeep;
	local string Report;

	d = class'LWStrategyRules'.static.Difficulty();
	for (i = 0; i < Countries.Length; i++)
	{
		if (Countries[i].bLeft || HasAbductions(i))
			continue;
		Blocks = Countries[i].Panic + 1;
		if (NotHelped.Find(i) != INDEX_NONE && Blocks >= class'LWStrategyRules'.default.DefectNotHelpedThreshold[d])
			Chance = int(Blocks * Blocks / 10000.0 * 100);
		else if (Blocks >= class'LWStrategyRules'.default.DefectThreshold[d])
			Chance = Blocks * class'LWStrategyRules'.default.DefectChancePerPoint[d];
		else
			continue;
		if (Countries[i].bSatellite)
			Chance *= class'LWStrategyRules'.default.SatHelpDefect[d];
		else if (ContinentHasSatellite(CountryContinent(i)))
			Chance *= class'LWStrategyRules'.default.SatNearbyHelpDefect[d];
		if (Rand(100) < Chance && Leaving.Length < class'LWStrategyRules'.default.DefectionsPerMonth[d])
			Leaving.AddItem(i);
	}
	for (i = 0; i < Leaving.Length; i++)
	{
		Leave(Leaving[i]);
		Report @= CountryName(Leaving[i]) @ "has left the council.";
	}
	NotHelped.Length = 0;
	for (i = 0; i < Countries.Length; i++)
	{
		if (Countries[i].bLeft)
			continue;
		Def = class'LWStrategyRules'.default.Countries[i];
		Funding += Round(Def.Funding * class'LWStrategyRules'.default.FundingBalance[d] * (Countries[i].bSatellite ? 1.0 : class'LWStrategyRules'.default.BaseFundingPct[d] / 100.0));
		if (!Countries[i].bSatellite)
			continue;
		// The staff a watched country sends (XGWorld's council meeting).
		Scientists += Def.Scientists;
		Engineers += Def.Engineers;
		Blocks = Countries[i].Panic + 1;
		if ((Blocks >= 95 && Rand(100) < class'LWStrategyRules'.default.Panic5ReductionChance[d])
			|| (Blocks >= 80 && Rand(100) < class'LWStrategyRules'.default.Panic4ReductionChance[d])
			|| (Blocks > 1 && Rand(100) < class'LWStrategyRules'.default.PanicLowReductionChance[d]))
			AddPanic(i, -class'LWStrategyRules'.default.SatPanicReduction[d]);
	}
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(GetParentGameState().ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	// The base's upkeep, paid from it (XGHeadQuarters.PayMaintenance).
	Upkeep = TileType.Length > 0 ? class'LWBase'.static.Upkeep(self) : 0;
	XComHQ.AddResource(GetParentGameState(), 'Supplies', Funding - Upkeep);
	Note("Council report: funding" @ class'LWStrategyRules'.static.Money(Funding) $ ", upkeep" @ class'LWStrategyRules'.static.Money(Upkeep) $ "." $ Report);
	`log("LongWarX2: Long War month" @ Month @ "ended: funding" @ Funding @ "countries left" @ NumLeft(), , 'LongWarX2');
	Month++;
	PlanMonth();
	bStop = true;
}

/** Abductions under way in the country (Long War's CountryHasAbductionMission). */
function bool HasAbductions(int k)
{
	local int i;

	for (i = 0; i < Sites.Length; i++)
		if (!Sites[i].bTerror && Sites[i].Country == k && Sites[i].Status == 1)
			return true;
	return false;
}

// --- Helpers ------------------------------------------------------------------------------

function AddPanic(int Country, int Amount)
{
	if (Country < 0 || Country >= Countries.Length || Countries[Country].bLeft)
		return;
	Countries[Country].Panic = Clamp(Countries[Country].Panic + Amount, 0, 99);
}

function AddContinentPanic(int Continent, int Amount)
{
	local int i;

	if (Amount == 0)
		return;
	for (i = 0; i < Countries.Length; i++)
		if (CountryContinent(i) == Continent)
			AddPanic(i, Amount);
}

function int CountryContinent(int i) { return class'LWStrategyRules'.default.Countries[i].Continent; }
function string CountryName(int i) { return class'LWStrategyRules'.default.Countries[i].Name; }

function bool ContinentHasSatellite(int Continent)
{
	local int i;

	for (i = 0; i < Countries.Length; i++)
		if (CountryContinent(i) == Continent && Countries[i].bSatellite)
			return true;
	return false;
}

function int NumLeft()
{
	local int i, n;

	for (i = 0; i < Countries.Length; i++)
		if (Countries[i].bLeft)
			n++;
	return n;
}

/** The campaign's jets on a continent. APPROXIMATION: jets have no base yet; all count for the home continent. */
function int JetsOn(int Continent)
{
	local XComGameState_LWAirWar AirWar;
	local int i, n;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none)
		return 0;
	for (i = 0; i < AirWar.Jets.Length; i++)
		if (AirWar.Jets[i].Continent == Continent)
			n++;
	return n;
}

function string ShipName(int Ufo)
{
	return class'LWAirWar'.static.Ufo(Ufo, Category()).Name;
}

/**
 * What wants the player's decision, in the Geoscape's order: 1 intercept a detected UFO, 2 a crash
 * site, 3 a landed UFO, 4 abductions, 5 terror; with the UFO's or site's index and the words.
 */
function Decisions(out array<int> Kinds, out array<int> Indexes, out array<string> Labels)
{
	local int i;

	Kinds.Length = 0;
	Indexes.Length = 0;
	Labels.Length = 0;
	for (i = 0; i < Ufos.Length; i++)
	{
		// An interception needs a ready jet over the UFO's continent (LWHangar).
		if ((Ufos[i].Status == 1 || Ufos[i].Status == 2) && Ufos[i].bDetected && !Ufos[i].bAttacked && class'LWHangar'.static.CountReadyFor(i) > 0)
			AddDecision(Kinds, Indexes, Labels, 1, i, "INTERCEPT:" @ ShipName(Ufos[i].Ufo) @ "over" @ CountryName(Ufos[i].Country) @ "(" $ (Ufos[i].Until - Hours) $ "h," @ class'LWHangar'.static.CountReadyFor(i) @ "jets ready)");
		else if (Ufos[i].Status == 3)
			AddDecision(Kinds, Indexes, Labels, 2, i, "ASSAULT: crash site in" @ CountryName(Ufos[i].Country) @ "(" $ (Ufos[i].Until - Hours) $ "h)");
		else if (Ufos[i].Status == 4 && Ufos[i].bDetected)
			AddDecision(Kinds, Indexes, Labels, 3, i, "ASSAULT: landed UFO in" @ CountryName(Ufos[i].Country) @ "(" $ (Ufos[i].Until - Hours) $ "h)");
	}
	for (i = 0; i < Sites.Length; i++)
		if (Sites[i].Status == 1 && Sites[i].bHQ)
			AddDecision(Kinds, Indexes, Labels, 8, i, "DEFEND: XCOM's headquarters (" $ (Sites[i].Until - Hours) $ "h)");
		else if (Sites[i].Status == 1)
			AddDecision(Kinds, Indexes, Labels, Sites[i].bTerror ? 5 : 4, i, (Sites[i].bTerror ? "RESPOND: terror in" : "RESPOND: abductions in") @ CountryName(Sites[i].Country) @ "(" $ (Sites[i].Until - Hours) $ "h)");
	// The story: an alien base, with a Skeleton Key to open it; the Temple Ship, once the Gollop Chamber stands.
	if (class'LWEngineering'.static.Held('LWItem_Skeleton_Key') > 0)
		for (i = 0; i < AlienBases.Length; i++)
			AddDecision(Kinds, Indexes, Labels, 6, AlienBases[i], "ASSAULT: the alien base in" @ CountryName(AlienBases[i]) @ "(a Skeleton Key)");
	if (!bCampaignWon && TileFacility.Length > 0 && class'LWBase'.static.Count(self, 19) > 0)
		AddDecision(Kinds, Indexes, Labels, 7, 0, "ASSAULT: the Temple Ship");
}

static function AddDecision(out array<int> Kinds, out array<int> Indexes, out array<string> Labels, int Kind, int Index, string Label)
{
	Kinds.AddItem(Kind);
	Indexes.AddItem(Index);
	Labels.AddItem(Label);
}

function Note(string Text)
{
	EventCount++;
	Events.AddItem("Day" @ DayOfMonth() $ "," @ (HourOfDay() < 10 ? "0" : "") $ HourOfDay() $ ":00 -" @ Text);
	if (Events.Length > 40)
		Events.Remove(0, Events.Length - 40);
	`log("LongWarX2: Geoscape:" @ Text, , 'LongWarX2');
}

// --- Psi training (features/lw-psi.md) -----------------------------------------------

function bool InPsiTraining(int UnitID)
{
	return PsiTrainees.Find('Unit', UnitID) != INDEX_NONE || GeneTrainees.Find('Unit', UnitID) != INDEX_NONE;
}

/** Whether a soldier may begin training a power now; Why says what is missing. */
static function bool CanTrainPsi(XComGameState_LWStrategy S, XComGameState_Unit Unit, LWBaseRules.LWPsiPower P, out string Why)
{
	local name Tech, Ability;

	Why = "";
	Ability = class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk);
	if (class'LWBase'.static.Count(S, 17) == 0)
		Why = "the Psi Labs";
	else if (S.PsiTrainees.Length >= class'LWBaseRules'.default.PsiSlots * class'LWBase'.static.Count(S, 17))
		Why = "a free place in the Psi Labs";
	else if (Unit == none || !Unit.IsSoldier() || !Unit.CanGoOnMission() || S.InPsiTraining(Unit.ObjectID))
		Why = "a soldier ready for duty";
	else if (Ability != '' && Unit.HasSoldierAbility(Ability))
		Why = "a soldier without the power";
	else if (P.Tech != 0)
	{
		Tech = class'LWResearchRules'.static.TemplateForId(P.Tech);
		if (Tech == '' || !class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(Tech))
			Why = "its research";
	}
	// Rift (specially coded in Long War): after Mind Control.
	else if (P.Perk == 73 && !Unit.HasSoldierAbility(class'X2Ability_LWStandins'.static.PsiAbilityFor(71)))
		Why = "Mind Control first";
	return Why == "";
}

/** A soldier begins training a power: out of the barracks until it is done. */
static function bool StartPsi(int UnitID, int Perk, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local LWBaseRules.LWPsiPower P;
	local LWPsiTrainee T;

	S = Get();
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (S == none || !class'LWBaseRules'.static.PsiPowerFor(Perk, P))
	{
		Why = "a psi power";
		return false;
	}
	if (!CanTrainPsi(S, Unit, P, Why))
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: psi training begun");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	T.Unit = UnitID;
	T.Perk = Perk;
	T.HoursLeft = class'LWBaseRules'.static.PsiHours(int(Unit.GetMaxStat(eStat_Will)), P);
	T.Chance = class'LWBaseRules'.static.PsiChance(int(Unit.GetMaxStat(eStat_Will)), P);
	S.PsiTrainees.AddItem(T);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("LongWarX2: psi:" @ Unit.GetFullName() @ "trains" @ class'X2Ability_LWStandins'.static.PsiAbilityFor(Perk) @ "for" @ T.HoursLeft @ "hours," @ T.Chance $ "% chance", , 'LongWarX2');
	return true;
}

/** The roll at the end of training; on success the soldier has the power (as a soldier ability) from then on. */
function PsiTrainingDone(XComGameState NewGameState, LWPsiTrainee T)
{
	local XComGameState_Unit Unit;
	local ClassAgnosticAbility Power;
	local name Ability;
	local int Roll;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(T.Unit));
	Ability = class'X2Ability_LWStandins'.static.PsiAbilityFor(T.Perk);
	if (Unit == none || Ability == '')
		return;
	Roll = Rand(100);
	if (Roll >= T.Chance)
	{
		Note(Unit.GetFullName() @ "finished psi training without gaining" @ class'X2Ability_LWStandins'.static.PsiPowerName(Ability) $ ".");
		`log("LongWarX2: psi:" @ Unit.GetFullName() @ "failed" @ Ability @ "(rolled" @ Roll @ "against" @ T.Chance $ ")", , 'LongWarX2');
		return;
	}
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Power.AbilityType.AbilityName = Ability;
	// Bound to the soldier's weapon, as XCOM 2's psi powers are to the psi amp: its range is the power's reach.
	Power.AbilityType.ApplyToWeaponSlot = eInvSlot_PrimaryWeapon;
	Power.bUnlocked = true;
	Unit.AWCAbilities.AddItem(Power);
	Note(Unit.GetFullName() @ "gained" @ class'X2Ability_LWStandins'.static.PsiPowerName(Ability) @ "in the Psi Labs.");
	`log("LongWarX2: psi:" @ Unit.GetFullName() @ "gained" @ Ability @ "(rolled" @ Roll @ "against" @ T.Chance $ ")", , 'LongWarX2');
}

// --- Gene mods (features/lw-genemods.md) ----------------------------------------------

/** Whether a soldier may go into the tank for a mod now; Why says what is missing. */
static function bool CanGeneMod(XComGameState_LWStrategy S, XComGameState_Unit Unit, LWBaseRules.LWGeneMod G, out string Why)
{
	local LWBaseRules.LWGeneMod Other;
	local name Tech, Meld;

	Why = "";
	Meld = class'X2Item_LWArtifacts'.static.ItemFor('Meld');
	if (class'LWBase'.static.Count(S, 23) == 0)
		Why = "the Genetics Lab";
	else if (S.GeneTrainees.Length >= class'LWBaseRules'.default.PsiSlots * class'LWBase'.static.Count(S, 23))
		Why = "a free tank in the Genetics Lab";
	else if (Unit == none || !Unit.IsSoldier() || !Unit.CanGoOnMission() || S.InPsiTraining(Unit.ObjectID))
		Why = "a soldier ready for duty";
	else
	{
		foreach class'LWBaseRules'.default.GeneMods(Other)
			if (Other.Slot == G.Slot && Unit.HasSoldierAbility(class'X2Ability_LWStandins'.static.GeneAbilityFor(Other.Perk)))
				Why = "a soldier without a mod there (" $ G.Slot $ ")";
	}
	if (Why == "" && G.Tech != 0)
	{
		Tech = class'LWResearchRules'.static.TemplateForId(G.Tech);
		if (Tech == '' || !class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(Tech))
			Why = "its research";
	}
	if (Why == "" && class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < G.Cash)
		Why = class'LWStrategyRules'.static.Money(G.Cash);
	if (Why == "" && class'LWEngineering'.static.Held(Meld) < G.Meld)
		Why = G.Meld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld');
	return Why == "";
}

/** A soldier goes into the tank for a mod (its cost paid): out of the barracks for its days. */
static function bool StartGeneMod(int UnitID, int Perk, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local LWBaseRules.LWGeneMod G;
	local LWPsiTrainee T;

	S = Get();
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (S == none || !class'LWBaseRules'.static.GeneModFor(Perk, G))
	{
		Why = "a gene mod";
		return false;
	}
	if (!CanGeneMod(S, Unit, G, Why))
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: gene mod begun");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -G.Cash);
	class'LWEngineering'.static.Take(NewGameState, class'X2Item_LWArtifacts'.static.ItemFor('Meld'), G.Meld);
	T.Unit = UnitID;
	T.Perk = Perk;
	T.HoursLeft = G.Days * 24;
	S.GeneTrainees.AddItem(T);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("LongWarX2: gene mods:" @ Unit.GetFullName() @ "in the tank for" @ class'X2Ability_LWStandins'.static.GeneAbilityFor(Perk) @ "," @ G.Days @ "days", , 'LongWarX2');
	return true;
}

/** Out of the tank: the mod is the soldier's (a soldier ability) from then on. */
function GeneModDone(XComGameState NewGameState, LWPsiTrainee T)
{
	local XComGameState_Unit Unit;
	local ClassAgnosticAbility Mod;
	local name Ability;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(T.Unit));
	Ability = class'X2Ability_LWStandins'.static.GeneAbilityFor(T.Perk);
	if (Unit == none || Ability == '')
		return;
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Mod.AbilityType.AbilityName = Ability;
	Mod.bUnlocked = true;
	Unit.AWCAbilities.AddItem(Mod);
	Note(Unit.GetFullName() @ "came out of the Genetics Lab with" @ class'X2Ability_LWStandins'.static.PsiPowerName(Ability) $ ".");
	`log("LongWarX2: gene mods:" @ Unit.GetFullName() @ "gained" @ Ability, , 'LongWarX2');
}

// --- The Officer Training School's squad sizes (lw-missions.md) ------------------------

/** The barracks' ranks added up (rookie 0, squaddie 1 …), as Long War counts them for the school's projects. */
static function int RanksInBarracks()
{
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local int n;

	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit != none && Unit.IsSoldier() && Unit.IsAlive())
			n += Unit.GetRank();
	}
	return n;
}

/** Whether the next squad size can be bought now; Why says what is missing. */
static function bool CanBuySquadSize(XComGameState_LWStrategy S, out string Why)
{
	local LWStrategyRules.LWSquadSize Next;

	Why = "";
	if (S.SquadSizesBought >= class'LWStrategyRules'.default.SquadSizes.Length)
		Why = "nothing: both bought";
	else
	{
		Next = class'LWStrategyRules'.default.SquadSizes[S.SquadSizesBought];
		if (class'LWBase'.static.Count(S, 12) == 0)
			Why = "the Officer Training School";
		else if (RanksInBarracks() < Next.Ranks)
			Why = "ranks adding up to" @ Next.Ranks @ "(now" @ RanksInBarracks() $ ")";
		else if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < Next.Cash)
			Why = class'LWStrategyRules'.static.Money(Next.Cash);
	}
	return Why == "";
}

static function bool BuySquadSize(out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local int Cash;

	S = Get();
	if (S == none || !CanBuySquadSize(S, Why))
		return false;
	Cash = class'LWStrategyRules'.default.SquadSizes[S.SquadSizesBought].Cash;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: squad size bought");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -Cash);
	S.SquadSizesBought++;
	S.Note("The Officer Training School: squad size" @ (class'LWStrategyRules'.default.SkyrangerCapacity + S.SquadSizesBought) $ ".");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

