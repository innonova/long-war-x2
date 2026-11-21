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
	/** Its funding before satellites and options (Long War's m_kTCountry.iFunding: its FundingAmounts x FundingBalance, or
	 *  New Economy's draw); 0: not set yet (a campaign from before it was kept: the first). */
	var int Funding;
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
/** A council mission's reward, as rolled when it was offered (LWCouncil): Type, its Amount (a soldier's: their level). */
struct LWCouncilReward
{
	var int Type;
	var int Amount;
	var int SoldierClass;
};

/** A council request (LWCouncilRequests; Long War's TFCRequest): what the country asks for (an item, a satellite over it, a
 *  jet on its continent), how many, its rewards rolled, the hours left; pending (XCOM holds enough: to answer now) or
 *  current (to hand over when XCOM has them, until its hours are out). */
struct LWRequest
{
	var int Id;
	var int Country;
	var name Item;
	var int Amount;
	var int Transfer;
	var array<LWCouncilReward> Rewards;
	var int HoursLeft;
	var bool bPending;
};

struct LWSite
{
	var bool bTerror;
	var bool bHQ;
	var int Country;
	var int Hour;
	var int Status;
	var int Until;
	/** A council mission (LWCouncil): Long War's EFCMission, its kind (1 assault, 2 bomb, 3 extraction, 4 rescue), rewards. */
	var bool bCouncil;
	var int CouncilMission;
	var int CouncilKind;
	var array<LWCouncilReward> Rewards;
	/** An abduction's (and a council mission's) difficulty, 0-3, fixed as it comes (Long War's mission m_eDifficulty, from
	 *  GetAbductionDifficulty as the mission is made): its squad, its reward and what the alert shows. */
	var int Difficulty;
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
/** XCOM's home country (an index of Countries) and the starting bonus chosen with it (LWBonuses' Choice), from Long War's
 * start screen (UILWStartSelect); a campaign begun before it was offered: the United States and none. */
var int HomeIndex;
var int StartChoice;
/** The council's missions (LWCouncil): the hours to the month's mission, whether that clock was started, those played. */
var int CouncilCountdown;
var bool bCouncilSetUp;
/** The council's requests (LWCouncilRequests): those open, the hours to the next, the requests ever made (by EFCRequest), and
 *  what each finished request added to its country's science (Long War's iScience + 10, its hunts' roll). */
var array<LWRequest> Requests;
var int RequestCountdown;
var bool bRequestsSetUp;
var array<int> RequestsMade;
var array<int> CountryScience;
/** Progeny's next mission (XGFundingCouncil.m_eNextProgenyMission: 25 Portent, 26 Deluge, 27 Furies, 28 the chain over);
 *  0 not begun (Portent next). */
var int NextProgeny;
var array<int> CouncilPlayed;

/** Hours since the campaign began; its first hour is the first of a month. */
var int Hours;
var int Month;
var int AlienResources;
var int AlienAggression;
/** Dynamic War's alien AI (second wave #9, XGStrategyAI.TallySquadCost; features/lw-dynamic-war.md): each mission kind's
 *  passes so far (XGStrategy.m_arrMissionTotals[30 + kind]). */
var array<int> WarPasses;
/**
 * The aliens' research, as Long War keeps it (features/lw-aliens.md): each day it is the campaign's days plus this bonus
 * (XGFacility_Barracks.HealAndRest, eRecap_Score), which starts at AlienResearchStart and grows with the aliens' successes:
 * each month's plan (+20, and +2 for each country gone), each UFO that finishes its flight (XGStrategyAI.LogUFORecord).
 */
var int AlienResearchBonus;
var bool bAlienResearchStarted;
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
/** Tiles built on a steam vent (a removed facility leaves the vent: XGBase.m_arrSteamTiles). */
var array<int> SteamTiles;
var array<LWBaseJob> BaseJobs;
/** A soldier training a psi power in the Psi Labs (features/lw-psi.md): the unit, the power (Long War's perk id), the hours left. */
/** An EXALT cell (features/lw-exalt.md; Long War's TExaltCellData): its country, the days it stays exposed, the days
 *  before it acts again. */
struct LWExaltCell
{
	var int Country;
	var int DaysUntilHidden;
	var int DaysUntilNextActivity;
};

struct LWPsiTrainee
{
	var int Unit;
	var int Perk;
	var int HoursLeft;
	var int Chance;
};
var array<LWPsiTrainee> PsiTrainees;
/** Soldiers hired and on their way (LWHiring): how many, the hours until they arrive. */
struct LWHiringOrder
{
	var int Count;
	var int HoursLeft;
};
var array<LWHiringOrder> HiringOrders;
/** The Officer Training School's squad sizes bought (lw-missions.md). */
var int SquadSizesBought;
/** The Officer Training School's officer projects bought, and the officers each rank (lieutenant first) holds, open and
 *  filled (LWOfficers: EW's medals, UnlockMedal's arithmetic). */
var int OfficerProjectsBought;
var array<int> OfficersAvailable, OfficersUsed;
/** A soldier in the Genetics Lab's tank (features/lw-genemods.md), as Long War's TGeneLabsPatient: the unit, the mods it
 *  goes in for (Long War's perk ids) and each one's hours, made one after the other. */
struct LWGenePatient
{
	var int Unit;
	var array<int> Perks;
	var array<int> HoursLeft;
};
var array<LWGenePatient> GenePatients;
/** A soldier in the Cybernetics Lab (features/lw-shivs-mecs.md): the unit, the hours left (LWMECs). */
struct LWMECPatient
{
	var int Unit;
	var int HoursLeft;
};
var array<LWMECPatient> MECPatients;
/** Long War's damaged gear (features/lw-gear-repair.md, LWGearRepair): each damaged item's template, one entry per item, and
 *  the repairs under way. */
var array<name> DamagedItems;
struct LWItemRepair
{
	var name Template;
	var int HoursLeft;
};
var array<LWItemRepair> Repairs;
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
/** The last tech researched (EW's XGFacility_Labs.m_eLastResearched): its report waits in the labs until read; and the one
 *  whose research-complete alert waits on Mission Control (GEOSCAPE().Alert(eGA_ResearchCompleted)). Long War's numbers. */
var int LastResearched, ResearchAlert;
/** A mission sent from here and not yet come back: 1 crash site, 2 landed UFO, 3 abduction, 4 terror, 5 an alien base, 6 the
 *  Temple Ship, 7 the HQ assault, 8 a covert operation, 9 EXALT's base, 10 a council mission (LWCouncil). */
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
/** The aliens still standing when the mission was won (their Long War species: a council VIP's squad evacuated, for one):
 *  no loot from them (UIScreenListener_LongWarX2Tactical.TestWin). */
var array<int> PendingSurvivors;
/** The aliens killed by an explosion in the mission won (their Long War species): their weapons wrecked, no fragments from
 *  them (XGUnit.CheckForDamagedItems). */
var array<int> PendingExploded;
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

// EXALT (features/lw-exalt.md, LWExalt): its state (LWExalt's consts), its base's country, the clues chosen (LWExalt.Clues
// indices, in order), its cells, the days before the next cell, the days since a cell acted, the month's scans and whether a
// scan is allowed today; the countries accused; XCOM's EXALT intelligence (the clues it holds); the covert operative (a
// unit's id), the country and days left.
var int ExaltState, ExaltCountry;
var array<int> ExaltClues;
var array<LWExaltCell> ExaltCells;
var int ExaltCooldown, ExaltDaysSinceOperation, ExaltSweeps;
var bool bExaltSweepAllowed;
var array<int> ExaltAccused;
var int ExaltIntel;
var int ExaltOperative, ExaltOperativeCountry, ExaltOperativeDays;
/** The covert operative's mission (Long War's CreateNextMission): 1 an extraction, 2 a data recovery; and which kinds have
 *  been offered (the first of each comes before chance decides). */
var int ExaltMissionKind;
var bool bExaltOfferedExtraction, bExaltOfferedRecovery;
/** A data recovery's first capture area fell in the mission under way (LWX2DataRecovery): no extra cash. */
var bool bPendingAreaLost;
/** The covert operation's mission: the hour it expires (0: none), and the missions of the kind fought so far (EXALT's
 *  squads grow with them; Long War counts its extraction and capture-and-hold missions). */
var int ExaltMissionUntil, ExaltMissionsFought;
/** EXALT's base found (the right country accused): the raid on it can be launched until it is won. */
var bool bExaltRaidReady;

// The month's tallies (Long War's TMonthlySummary, each continent's m_kMonthly): MonthTally[continent x TALLIES + T_…],
// counted where Long War counts them, cleared at the month's end. The council's last report (XGWorld.CouncilMeeting's
// TCouncilMeeting): the tallies summed, the grade (DetermineMonthlyGrade: 0 A, 1 B, 2 C, 3 D, 4 F), the funding and the
// specialists the council gave, XCOM's money when it was in debt (mismanaged), the countries that left, the hour it met,
// and whether the player is still to see it (UILWEWEndOfMonth).
const T_ABDUCTIONS_THWARTED = 0;
const T_ABDUCTIONS_FAILED = 1;
const T_ABDUCTIONS_IGNORED = 2;
const T_TERROR_THWARTED = 3;
const T_TERROR_FAILED = 4;
const T_TERROR_IGNORED = 5;
const T_UFOS_SHOT_DOWN = 6;
const T_UFOS_DETECTED = 7;
const T_UFO_RAIDS = 8;
const T_SATELLITES_LAUNCHED = 9;
const T_SATELLITES_LOST = 10;
const T_TECHS = 11;
const T_ALIEN_BASES = 12;
const T_COUNCIL_MISSIONS = 13;
const TALLIES = 14;
var array<int> MonthTally;
var array<int> ReportTally;
var int ReportGrade, ReportFunding, ReportScientists, ReportEngineers, ReportHours;
var bool bReportMismanaged;
var int ReportMoney;
var array<int> ReportLeaving;

/** The Situation Room's news ticker (LWTicker, XGFacility_SituationRoom's m_arrTickerItems): five headlines, newest
 *  first, each a line of LWTicker.Lines, its country (-1 none) and colour; the lines used, the narratives told, the hours
 *  until an ambient headline. */
struct LWTickerItem
{
	var int Line;
	var int Country;
	var int State;
};
var array<LWTickerItem> Ticker;
var array<int> TickerUsed;
var array<string> TickerNarratives;
var int TickerQuiet;
/** The campaign's objective (LWObjectives, EW's EGameObjective), and whether a soldier has ever shown the psi gift. */
var int Objective;
var bool bHadPsiSoldier;
var bool bReportDue;
/** The UFOs XCOM has taken, by class (Long War's m_arrCraftEncounters: a crash site or a landed UFO won): a class once
 *  taken is known when seen again (Identified). */
var array<int> CraftEncounters;

// --- Making it ------------------------------------------------------------------------------

static function XComGameState_LWStrategy Get()
{
	return XComGameState_LWStrategy(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LWStrategy', true));
}

/**
 * The campaign's Geoscape, made the first time it is asked for (any campaign, new or loaded): with the home country and
 * starting bonus chosen on the start screen (UILWStartSelect), or else the United States and no starting bonus.
 */
static function XComGameState_LWStrategy GetOrCreate(optional int Home = -1, optional int Choice = -1)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;

	S = Get();
	if (S != none)
		return S;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the Geoscape");
	S = XComGameState_LWStrategy(NewGameState.CreateNewStateObject(class'XComGameState_LWStrategy'));
	S.HomeIndex = Home >= 0 ? Home : 0;
	S.StartChoice = Choice;
	S.Begin();
	// (The world's first news, InitTickerItems, at the campaign's start.)
	class'LWTicker'.static.Fill(S);
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
	// The bonuses that act once, at the start (Wealthy Benefactor's money, Foundry projects granted, a free item ...).
	class'LWBonusEffects'.static.AtStart(NewGameState, S);
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

	StartAlienResearch();

	foreach class'LWStrategyRules'.default.Countries(Def)
	{
		C.Id = Def.Id;
		C.Panic = 0;
		C.bSatellite = false;
		C.bLeft = false;
		C.Funding = Round(Def.Funding * class'LWStrategyRules'.default.FundingBalance[class'LWStrategyRules'.static.Difficulty()]);
		Countries.AddItem(C);
		Open.AddItem(Countries.Length - 1);
	}
	if (class'LWX2SecondWave'.static.On(1))
		RandomizeFunding();
	// We Are Legion (second wave #25, XGFacility_Barracks: both squad size upgrades had from the start).
	if (class'LWX2SecondWave'.static.On(25))
		SquadSizesBought = Max(SquadSizesBought, class'LWStrategyRules'.default.SquadSizes.Length);
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
	// Long War (XGWorld.SetStartingContinent): a satellite over the home country.
	Countries[HomeIndex].bSatellite = true;
	Note("Day 1. The council funds XCOM. A satellite watches" @ (HomeIndex == 0 ? "the United States" : (HomeIndex == 3 ? "the United Kingdom" : CountryName(HomeIndex))) $ ".");
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

/** An XCOM 2 date as Long War's calendar has it: XCOM 2's clock runs with Long War's hours (Run) from its own start
 *  (START_YEAR, 2035), Long War's from 2015 on the same day. */
static function TDateTime LongWarDate(TDateTime T)
{
	T.m_iYear += 2015 - class'X2StrategyGameRulesetDataStructures'.default.START_YEAR;
	return T;
}

/**
 * Time runs hour by hour until the hours are up or something wants a decision (with bThrough, on
 * regardless: the player answering nothing, for development). Returns the hours that passed.
 */
static function int Run(int MaxHours, optional bool bThrough)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local int n, ToResearch;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: time passes");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.bStop = false;
	// A campaign begun before the base was ported gets Long War's starting base.
	if (S.TileType.Length == 0)
		class'LWBase'.static.Generate(S);
	// (Time stops at the hour XCOM 2's research project is done, as EW's research alert stops it: XCOM 2's clock, which
	// completes it, follows the Long War clock's hours after them.)
	ToResearch = HoursToResearch();
	while (n < MaxHours && (bThrough || !S.bStop) && !S.bLost && (bThrough || ToResearch < 0 || n < ToResearch))
	{
		S.Tick(NewGameState);
		n++;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	XCom2TimePasses(n);
	SyncResearch();
	return n;
}

/** The hours until XCOM 2's research project is done (its completion passed: XCom2TimePasses' LessThan), -1 for none. */
static function int HoursToResearch()
{
	local XComGameState_HeadquartersProjectResearch Project;

	Project = class'UIUtilities_Strategy'.static.GetXComHQ().GetCurrentResearchProject();
	if (Project == none || Project.bIncremental)
		return -1;
	return Max(1, class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(Project.CompletionDateTime, `STRATEGYRULES.GameTime) + 1);
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
	// The techs' time cuts, which the bonuses change as satellites come and go.
	TechTimesIn(NewGameState);
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
	S.TechTimesIn(NewGameState);
}

/** A research done (XGFacility_Labs.OnResearchCompleted): its report waits in the labs, its alert on Mission Control. */
static function ResearchDone(XComGameState NewGameState, int Id)
{
	local XComGameState_LWStrategy S;

	if (Get() == none)
		return;
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.LastResearched = Id;
	S.ResearchAlert = Id;
	S.bStop = true;
	// (Long War's objective, as the research report closes: XGResearchUI.)
	class'LWObjectives'.static.Researched(S, Id);
}

/** The research alert answered (0: none waits); and the report read in the labs (EW's OnLeaveReport). */
static function ResearchSeen(bool bAlert, bool bReport)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	if (Get() == none || (!(bAlert && Get().ResearchAlert != 0) && !(bReport && Get().LastResearched != 0)))
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a research's alert or report seen");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	if (bAlert)
		S.ResearchAlert = 0;
	if (bReport)
		S.LastResearched = 0;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** A research done, counted for the council's report (on the home continent, as Long War counts it). */
static function TechResearched(XComGameState NewGameState)
{
	local XComGameState_LWStrategy S;

	if (Get() == none)
		return;
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.Tally(S.CountryContinent(S.HomeCountry()), T_TECHS);
}

/** Every Long War tech's time cut (LWResearchRules.TimeCut: the credits held, Expertise, We Have Ways) set on XCOM 2's
 * tech where it differs. */
function TechTimesIn(XComGameState NewGameState)
{
	local XComGameState_Tech Tech;
	local LWResearchRules.LWTechDef T;
	local float Cut;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', Tech)
	{
		foreach class'LWResearchRules'.default.Techs(T)
		{
			if (class'LWResearchRules'.static.TemplateFor(T) != Tech.GetMyTemplateName())
				continue;
			Cut = class'LWResearchRules'.static.TimeCut(T, Credits, self);
			if (Abs(Tech.TimeReductionScalar - Cut) > 0.0001)
			{
				Tech = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', Tech.ObjectID));
				Tech.TimeReductionScalar = Cut;
			}
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
	local int i, Expired;

	Hours++;
	// Dynamic War's alien AI, Long War's two half-hour updates in the hour.
	if (class'LWX2SecondWave'.static.On(9))
	{
		DynamicWar();
		DynamicWar();
	}
	class'LWBase'.static.Tick(self);
	class'LWFatigue'.static.Tick(NewGameState, self);
	class'LWHangar'.static.Hour(NewGameState, self);
	class'LWTicker'.static.Hour(self);
	class'LWObjectives'.static.Hour(self);
	class'LWGearRepair'.static.Hour(NewGameState, self);
	class'LWHiring'.static.Hour(NewGameState, self);
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
	// Augmentation done: a MEC trooper in the soldier's place (LWMECs.AugmentDone).
	for (i = MECPatients.Length - 1; i >= 0; i--)
	{
		if (--MECPatients[i].HoursLeft > 0)
			continue;
		class'LWMECs'.static.AugmentDone(NewGameState, self, MECPatients[i].Unit);
		MECPatients.Remove(i, 1);
		bStop = true;
	}
	// Gene mods: the first of each soldier's made in turn (XGFacility_GeneLabs.Update); done, the mod is the soldier's, and
	// the soldier out once all are.
	for (i = GenePatients.Length - 1; i >= 0; i--)
	{
		if (GenePatients[i].HoursLeft.Length == 0 || --GenePatients[i].HoursLeft[0] > 0)
			continue;
		GeneModDone(NewGameState, GenePatients[i].Unit, GenePatients[i].Perks[0]);
		GenePatients[i].Perks.Remove(0, 1);
		GenePatients[i].HoursLeft.Remove(0, 1);
		if (GenePatients[i].Perks.Length == 0)
			GenePatients.Remove(i, 1);
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
	// Abductions let go are counted once an hour, however many (XGStrategyAI.AIUpdateMissions' bAbductionBlitzExpired: on
	// the continent of the last mission it looked at).
	Expired = -1;
	for (i = 0; i < Sites.Length; i++)
		if (TickSite(i) && !Sites[i].bTerror && !Sites[i].bCouncil && !Sites[i].bHQ)
			Expired = CountryContinent(Sites[i].Country);
	if (Expired >= 0)
		Tally(Expired, T_ABDUCTIONS_IGNORED);
	class'LWExalt'.static.Hour(NewGameState, self);
	class'LWCouncil'.static.Hour(self);
	class'LWCouncilRequests'.static.Hour(self);
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
	// The aliens' research (XGStrategyAI.FillUFOPool, MakeMonthlyPlan): +20 a month, +2 for each country gone.
	StartAlienResearch();
	AlienResearchBonus += 20 + 2 * NumLeft();
	`log("LongWarX2: the aliens' research" @ AlienResearch() @ "on day" @ Days() @ "(bonus" @ AlienResearchBonus $ ")", , 'LongWarX2');
	Tier = Clamp(AlienResources / 50, 0, 4);
	Start = Month * HoursPerMonth();
	// Dynamic War: no table; its own branch (an infiltration or the HQ assault at the top tiers), the rest of its missions
	// from its passes (DynamicWar), and the aggression not lowered each month.
	if (class'LWX2SecondWave'.static.On(9))
	{
		if ((Tier == 3 && AlienAggression >= 4) || (Tier == 4 && AlienAggression >= 4))
		{
			if (HQAssaultCounter % 3 == 2)
				AddHQAssault(Start);
			HQAssaultCounter++;
		}
		else if (Tier == 4)
			AddUfos(7, Start);
	}
	else if (class'LWStrategyRules'.static.PlanFor(Tier, Clamp(AlienAggression, 0, 4), Cell))
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
	if (!class'LWX2SecondWave'.static.On(9))
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

/** Whether a scout seen brings a hunt (XGStrategyAI.ShouldHunt): not if the country's science turns it away (a roll on half
 *  its scientists, TCountry.iScience), only with a roll on how whole the UFO came back, then a roll on 40 + day / 15. And only
 *  over a country with a satellite to hunt. */
function bool ShouldHunt(LWUfo U, float Intact)
{
	if (!Countries[U.Country].bSatellite || Countries[U.Country].bLeft)
		return false;
	if (Rand(100) < (class'LWStrategyRules'.default.Countries[U.Country].Scientists + (U.Country < CountryScience.Length ? CountryScience[U.Country] : 0)) / 2)
		return false;
	if (Rand(100) >= int(100 * Intact))
		return false;
	return Rand(100) < 40 + Days() / 15;
}

/**
 * An objective of the plan (Long War's AddUFOs): its target and start day by objective, its ship by
 * the aliens' resources and the campaign's day.
 */
function AddUfos(int Objective, int MonthStart, optional bool bNow)
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
	case 10: // the late mission: its own target and start
		AddLateMission(MonthStart);
		return;
	default: // 7, 8: the terror target
		Country = TerrorTarget();
	}
	// (Dynamic War's missions start at once: Long War's start day 0.)
	AddObjective(Objective, bNow ? Hours : MonthStart, bNow ? 0 : class'LWStrategyRules'.static.DayFor(Objective), Country, Objective == 7 ? -1 : class'LWStrategyRules'.static.ShipFor(Objective, AlienResources, Days()));
}

/**
 * Dynamic War's alien AI (second wave #9; XGStrategyAI.TallySquadCost, run each half hour): each mission kind has a cost from
 * the aliens' resources R (9 x month to 300) and aggression A (0 to 8), times SW_MARATHON, and gains a pass with the chance
 * cost / (10000 / SW_ELERIUM_LOSS); on its SW_ELERIUM_LOSS-th pass it comes at once and its count starts again: a UFO of the
 * objective (0 recon, 1 scouting, 2 harvest, 4 hunt, 8 air raid), an abduction (5), a terror mission (6), one aggression
 * fewer (10), the late mission (9: AddLateMission).
 */
function DynamicWar()
{
	local array<float> Cost;
	local float R, A, Marathon;
	local int k, Passes, Sides, Country;
	local array<int> Targets;

	Passes = Max(1, class'LWX2SecondWave'.default.MarathonPasses);
	Marathon = class'LWX2SecondWave'.default.Marathon;
	if (WarPasses.Length < 11)
		StartWar();
	R = Clamp(AlienResources, 9 * Month, 300);
	AlienAggression = Clamp(AlienAggression, 0, 8);
	A = AlienAggression;
	Cost.Length = 11;
	Cost[0] = (0.07 * R) * Marathon;
	Cost[1] = (21 + 0.05 * R + A) * Marathon;
	Cost[2] = (21 - 0.07 * R) * Marathon;
	Cost[4] = (-3 + 0.025 * R + 2 * A) * Marathon;
	Cost[5] = (27 + 0.034 * R - 1.5 * A) * Marathon;
	Cost[6] = (0.03 * R + 1.5 * A) * Marathon;
	Cost[8] = (0.05 * R + A) * Marathon;
	Cost[9] = (0.01 * R + 0.5 * A) * Marathon;
	Cost[10] = A * 5 * Marathon;
	Sides = 10000 / Passes;
	for (k = 0; k < 11; k++)
		if (Rand(Sides) < int(Cost[k]))
			WarPasses[k]++;
	for (k = 0; k < 11; k++)
	{
		if (WarPasses[k] < Passes)
			continue;
		WarPasses[k] = 0;
		switch (k)
		{
		case 0: case 1: case 2: case 4: case 8:
			AddUfos(k, Hours, true);
			break;
		case 5:
			Targets.Length = 0;
			for (Country = 0; Country < Countries.Length; Country++)
				if (!Countries[Country].bLeft && !IsTerrorTarget(Country))
					Targets.AddItem(Country);
			if (Targets.Length > 0)
				AddObjective(5, Hours, 0, Targets[Rand(Targets.Length)], -1);
			break;
		case 6:
			AddObjective(6, Hours, 0, Rand(4) == 0 ? RandomCountry() : TerrorTarget(), -1);
			break;
		case 9:
			AddLateMission(Hours);
			break;
		case 10:
			AlienAggression = Max(0, AlienAggression - 1);
			break;
		}
		`log("LongWarX2: Dynamic War: kind" @ k @ "comes on day" @ Days(), , 'LongWarX2');
	}
}

/**
 * Long War's late mission (XGStrategyAI.AddLateMission, its eObjective_Infiltrate_2): over a continent other than XCOM's
 * where XCOM flies a Firestorm (IsGoodOverseerTarget), an Overseer comes down at the continent's headquarters (its
 * country: the USA, Brazil, Germany, Japan, Nigeria); landed, it is a crash site (OnObjectiveEnded: CheatCrash). It starts
 * with the month, or 1 to 26 days on with Dynamic War. None without such a continent.
 */
function AddLateMission(int MonthStart)
{
	local XComGameState_LWAirWar AirWar;
	local array<int> Continents;
	local array<name> HQs;
	local int c, i, k;

	HQs.AddItem('USA');
	HQs.AddItem('Brazil');
	HQs.AddItem('Germany');
	HQs.AddItem('Japan');
	HQs.AddItem('Nigeria');
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none)
		return;
	for (c = 0; c < HQs.Length; c++)
	{
		if (c == CountryContinent(HomeCountry()))
			continue;
		for (i = 0; i < AirWar.Jets.Length; i++)
			if (AirWar.Jets[i].Continent == c && AirWar.Jets[i].Type == 3)
			{
				Continents.AddItem(c);
				break;
			}
	}
	if (Continents.Length == 0)
		return;
	c = Continents[Rand(Continents.Length)];
	k = class'LWStrategyRules'.default.Countries.Find('Id', HQs[c]);
	if (k == INDEX_NONE)
		return;
	AddObjective(10, MonthStart, class'LWX2SecondWave'.static.On(9) ? 1 + Rand(26) : 0, k, -1);
	`log("LongWarX2: the late mission: an Overseer for" @ CountryName(k), , 'LongWarX2');
}

/** Dynamic War's starting passes (XGStrategy: kinds 0, 1, 2, 5, 6 at 0.2, 0.7, 0.4, 0.7, 0.5 of SW_ELERIUM_LOSS). */
function StartWar()
{
	local int Passes;

	Passes = class'LWX2SecondWave'.default.MarathonPasses;
	WarPasses.Length = 0;
	WarPasses.Length = 11;
	WarPasses[0] = int(Passes * 0.2);
	WarPasses[1] = int(Passes * 0.7);
	WarPasses[2] = int(Passes * 0.4);
	WarPasses[5] = int(Passes * 0.7);
	WarPasses[6] = int(Passes * 0.5);
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

/**
 * A country's funding this month (XGCountry.CalcFunding): its own (New Economy's draw, else FundingAmounts x
 * FundingBalance); War Weariness (#15) 5% less each month, at most 90%; Results Driven (#10) less by its panic; without a
 * satellite, BASE_FUNDING's share. Each step rounded down, as Long War's ints are.
 */
/** The month's funding less the base's upkeep, as EW's HUD shows it (its MONTHLY: eResource_MonthlyNet). */
function int MonthlyNet()
{
	local int i, Funding;

	for (i = 0; i < Countries.Length; i++)
		if (!Countries[i].bLeft)
			Funding += CountryFunding(i, Countries[i].bSatellite);
	return Funding - (TileType.Length > 0 ? class'LWBase'.static.Upkeep(self) : 0);
}

function int CountryFunding(int i, bool bSat)
{
	local int F, d;

	d = class'LWStrategyRules'.static.Difficulty();
	F = Countries[i].Funding > 0 ? Countries[i].Funding : Round(class'LWStrategyRules'.default.Countries[i].Funding * class'LWStrategyRules'.default.FundingBalance[d]);
	if (class'LWX2SecondWave'.static.On(15))
		F = int(F * (1.0 - FClamp(Month * 0.05, 0.0, 0.9)));
	if (class'LWX2SecondWave'.static.On(10))
		F = int(F * float(100 - Countries[i].Panic) / 100.0);
	if (!bSat)
		F = int(F * class'LWStrategyRules'.default.BaseFundingPct[d] / 100.0);
	return F;
}

/**
 * New Economy (#1, XGWorld.RandomizeFunding): the council's funding dealt again at random, in tens: each country, in a
 * random order, half the average left to an average and a half (Rand(1.5 x average) over half), kept between the lowest and
 * the highest of before.
 */
function RandomizeFunding()
{
	local array<int> Left;
	local int i, k, Lo, Hi, Total, Avg, F;

	Lo = 400;
	for (i = 0; i < Countries.Length; i++)
	{
		Lo = Min(Lo, Countries[i].Funding);
		Hi = Max(Hi, Countries[i].Funding);
		Total += Countries[i].Funding;
		Left.AddItem(i);
	}
	Total /= 10;
	Lo /= 10;
	Hi /= 10;
	while (Left.Length > 0)
	{
		k = Rand(Left.Length);
		i = Left[k];
		Avg = Total / Left.Length;
		F = Clamp(Avg / 2 + Rand(Max(1, int(Avg * 1.5))), Lo, Hi);
		Countries[i].Funding = F * 10;
		Left.Remove(k, 1);
		Total -= F;
	}
}

function int CountryIndex(name Id)
{
	return class'LWStrategyRules'.default.Countries.Find('Id', Id);
}

/** XCOM's home country, where it began with a satellite (chosen on the start screen). */
function int HomeCountry()
{
	return HomeIndex;
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
		// Foundry's Enhanced UFO Detection (35) (XGGeoscape: GetNumInterceptorsInRangeAndAvailable): rolled once a UFO.
		Ready = class'LWHangar'.static.ReadyOn(CountryContinent(Ufos[i].Country));
		if (Seen(Ufos[i]) || Rand(100) < class'LWStrategyRules'.default.InterceptorDetectPct * (FoundryDone.Find(35) != INDEX_NONE ? 2 : 1) * Ready.Length
			&& (Ufos[i].Ufo != 9 || Hyperwave()))
			Detected(i);
		return;
	case 1:
		// Still over the country: a satellite there now sees it (XGGeoscape.RadarUpdate, every update).
		if (!Ufos[i].bDetected && Seen(Ufos[i]))
			Detected(i);
		if (Hours < Ufos[i].Until)
			return;
		if (Ufos[i].Flight == 0)
		{
			Ufos[i].Status = 4;
			Ufos[i].Until = Hours + class'LWStrategyRules'.default.LandedUfoHours;
			if (Ufos[i].bDetected)
			{
				Note("The" @ UfoLabel(Ufos[i].Ufo) @ "has landed in" @ CountryName(Ufos[i].Country) $ ". It leaves in" @ class'LWStrategyRules'.default.LandedUfoHours @ "hours.");
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

/** A UFO over its country seen without a roll (XGGeoscape.DetectUFO): by the satellite over the country, or, hunting
 *  (objective 4), at once; an Overseer (9) only with the Hyperwave Relay. */
function bool Seen(LWUfo U)
{
	if (U.Ufo == 9 && !Hyperwave())
		return false;
	return Countries[U.Country].bSatellite || U.Objective == 4;
}

function Detected(int i)
{
	Ufos[i].bDetected = true;
	// (The first Overseer seen: Long War's objective to shoot it down, XGMissionControlUI.PostOverseerMatinee.)
	if (Ufos[i].Ufo == 9)
		class'LWObjectives'.static.Advance(self, class'LWObjectives'.const.OBJ_SHOOT_DOWN_OVERSEER);
	Note("UFO detected over" @ CountryName(Ufos[i].Country) $ ":" @ UfoLabel(Ufos[i].Ufo) $ (Hyperwave() ? "," @ class'LWStrategyRules'.static.ObjectiveName(Ufos[i].Objective) : "") $ ".");
	bStop = true;
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
	// Seen and not brought down: counted as detected, so escaped (XGAlienObjective.NotifyOfSuccess).
	if (U.bDetected)
		Tally(CountryContinent(U.Country), T_UFOS_DETECTED);
	if (U.Objective != 4 && U.Ufo != 9)
		AddPanic(U.Country, int((U.Objective == 8 ? class'LWStrategyRules'.default.PanicAirRaid : class'LWStrategyRules'.default.PanicUfoIgnored) * Intact));
	if (U.Objective == 2 && class'LWStrategyRules'.static.HarvestOf(U.Ufo) > 0)
		AlienResources += class'LWX2SecondWave'.static.War(class'LWStrategyRules'.static.HarvestOf(U.Ufo) + Rand(5));
	if (U.bDetected && U.Objective != 5 && U.Objective != 6 && U.Objective != 7)
		Note("The" @ UfoLabel(U.Ufo) @ "over" @ CountryName(U.Country) @ "finished its mission.");
	// A scout seen (detected, or attacked and away) may bring a hunt for the satellite that saw it (LogUFORecord,
	// ShouldHunt, AddHuntTarget).
	if (U.Objective == 1 && U.Ufo != 9 && U.bDetected && ShouldHunt(U, Intact))
	{
		AddObjective(4, Hours, Rand(5), U.Country, class'LWStrategyRules'.static.ShipFor(4, AlienResources, Days()));
		`log("LongWarX2: Geoscape: the scout seen over" @ CountryName(U.Country) @ "brings a hunt for its satellite", , 'LongWarX2');
	}
	// The aliens' research (XGStrategyAI.LogUFORecord), for a UFO that was not the Ethereals' and not hunting: +1 come
	// back whole, +0 or 1 above half its hull (not for a pact's); a research flight (recon) by its size: a small scout 3,
	// a large scout 5, an abductor 8, larger 10.
	if (U.Ufo != 9 && U.Objective != 4)
	{
		StartAlienResearch();
		if (U.Objective != 7)
			AlienResearchBonus += Intact >= 1.0 ? 1 : (Intact >= 0.5 ? Rand(2) : 0);
		if (U.Objective == 0)
			AlienResearchBonus += U.Ufo == 4 ? 3 : (U.Ufo == 5 ? 5 : (U.Ufo == 6 ? 8 : (U.Ufo >= 7 ? 10 : 0)));
	}
	if (!U.bLast)
		return;
	switch (U.Objective)
	{
	case 4:
		if (FoundSatellite(U))
		{
			Tally(CountryContinent(U.Country), T_SATELLITES_LOST);
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
	case 10:
		// The late mission's Overseer landed: a crash site (CheatCrash).
		Ufos[i].Status = 3;
		Ufos[i].Until = Hours + class'LWStrategyRules'.default.CrashSiteHours;
		Note("An" @ UfoLabel(U.Ufo) @ "has come down in" @ CountryName(U.Country) $ ": a crash site for" @ class'LWStrategyRules'.default.CrashSiteHours @ "hours.");
		bStop = true;
		break;
	}
}

/** The bonus set to Long War's start once (a campaign begun before it was kept starts it at its first month or UFO). */
function StartAlienResearch()
{
	if (bAlienResearchStarted)
		return;
	bAlienResearchStarted = true;
	AlienResearchBonus += class'LWStrategyRules'.default.AlienResearchStart;
}

/** The aliens' research level (Long War's eRecap stat 1): the days, or the days and the bonus when that is more. */
function int AlienResearch()
{
	return Max(Days(), Days() + AlienResearchBonus);
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
	// Its requests go with it (XGFundingCouncil.OnCountryLeft).
	class'LWCouncilRequests'.static.CountryLeft(self, Country);
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
	S.AlienResources -= Round(class'LWX2SecondWave'.static.War(class'LWStrategyRules'.static.WorthOf(U.Ufo)) * (1.0 - float(U.Hp) / float(Max(1, U.MaxHp))));
	if (Outcome == 0 || Outcome == 1) // crashed or destroyed
	{
		// (XGStrategyAI: a UFO shot down makes the news once, PushNarrativeHeadline(UFOShotDown).)
		class'LWTicker'.static.Narrative(S, "UFOShotDown");
		// (XGAlienObjective.NotifyOfCrash: shot down, and detected.)
		S.Tally(S.CountryContinent(U.Country), T_UFOS_SHOT_DOWN);
		S.Tally(S.CountryContinent(U.Country), T_UFOS_DETECTED);
		S.UfoDowned(U);
		S.AddPanic(U.Country, class'LWStrategyRules'.default.PanicUfoShotDown);
		if (Outcome == 0)
		{
			U.Status = 3;
			U.Until = S.Hours + class'LWStrategyRules'.default.CrashSiteHours;
			S.Note("The" @ S.UfoLabel(U.Ufo) @ "is down in" @ S.CountryName(U.Country) $ ": a crash site for" @ class'LWStrategyRules'.default.CrashSiteHours @ "hours.");
		}
		else
		{
			U.Status = 5;
			S.Note("The" @ S.UfoLabel(U.Ufo) @ "broke up over" @ S.CountryName(U.Country) $ ".");
		}
	}
	else
	{
		U.Hp = Max(0, UfoHp);
		S.Note("The" @ S.UfoLabel(U.Ufo) @ "got away, damaged" @ (100 - 100 * U.Hp / Max(1, U.MaxHp)) $ "%.");
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
	if (!bTerror)
		Site.Difficulty = AbductionDifficulty(Country);
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

/** A council mission offered (LWCouncil.NewMission): it waits as an abduction does (Long War's ABDUCTION_TIMER). */
function AddCouncilSite(int Mission, int Country, array<LWCouncilReward> Rewards)
{
	local LWSite Site;

	Site.bCouncil = true;
	Site.CouncilMission = Mission;
	Site.CouncilKind = class'LWCouncil'.static.KindOf(Mission);
	Site.Rewards = Rewards;
	Site.Country = Country;
	Site.Hour = Hours;
	Site.Status = 1;
	Site.Until = Hours + class'LWStrategyRules'.default.AbductionHours;
	Site.Difficulty = AbductionDifficulty(Country);
	Sites.AddItem(Site);
	CouncilPlayed.AddItem(Mission);
	Note("The council asks for XCOM's help in" @ CountryName(Country) $ ":" @ class'LWCouncil'.static.KindName(Site.CouncilKind) $ " (" $ class'LWCouncil'.static.RewardsText(Rewards) $ "). XCOM has" @ (Site.Until - Hours) @ "hours.");
	bStop = true;
}

/** A site's hour: let go once its time is up (true then); terror let go is counted (AIUpdateMissions). */
function bool TickSite(int i)
{
	if (Sites[i].Status == 1 && Hours >= Sites[i].Until)
	{
		Sites[i].Status = 2;
		if (Sites[i].bTerror)
			Tally(CountryContinent(Sites[i].Country), T_TERROR_IGNORED);
		SiteIgnored(i);
		return true;
	}
	return false;
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
	// Stopped, unless the country leaves for it or had gone already (ApplyMissionPanic: a secret pact's is not counted).
	if (PendingCivilians < 0)
	{
		if (!Countries[Country].bLeft)
			Tally(CountryContinent(Country), T_TERROR_THWARTED);
		return;
	}
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
	Tally(CountryContinent(Country), T_TERROR_THWARTED);
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
	if (Sites[i].bCouncil)
	{
		class'LWTicker'.static.CouncilMission(self, i, "Ignore");
		class'LWCouncil'.static.Failed(self, i);
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

	if (PendingKind == 8)
		return class'LWExalt'.static.CovertSquad(ExaltMissionsFought, Days());
	if (PendingKind == 9)
		return class'LWExalt'.static.RaidSquad(Days());
	// A council mission: an abduction's squad in its country (APPROXIMATION: Long War's DetermineSpecialMissionSquad builds its own,
	// 7 to 15 aliens by the month).
	if (PendingKind == 10)
		return class'LWAlienSquads'.static.SquadFor(3, 0, Days(), AlienAggression, AlienResources, Sites[PendingIndex].Difficulty, TerrorsTaken);
	if (PendingKind == 5)
		return class'LWAlienSquads'.static.SquadFor(2, 8, Days(), AlienAggression, AlienResources, 0, TerrorsTaken);
	if (PendingKind >= 6)
		return class'LWAlienSquads'.static.SquadFor(2, 14, Days(), AlienAggression, AlienResources, 0, TerrorsTaken);
	Country = PendingKind <= 2 ? Ufos[PendingIndex].Country : Sites[PendingIndex].Country;
	return class'LWAlienSquads'.static.SquadFor(PendingKind, PendingKind <= 2 ? Ufos[PendingIndex].Ufo : 0, Days(),
		AlienAggression, AlienResources, PendingKind == 3 ? Sites[PendingIndex].Difficulty : 0, TerrorsTaken);
}

/** A mission is sent to a crash site (1), landed UFO (2), abduction (3) or terror site (4): chosen and committed at once. */
static function MissionSent(int Kind, int Index, optional bool bCapture)
{
	MissionChosen(Kind, Index, bCapture);
	MissionCommitted();
}

/**
 * A mission chosen on the Geoscape, its squad still to be picked (XCOM 2's squad select, UILWSquadSelect): the pending
 * mission's kind and target, nothing else changed, so backing out (MissionCancelled) leaves the campaign as it was.
 */
static function MissionChosen(int Kind, int Index, optional bool bCapture)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a mission chosen");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.PendingKind = Kind;
	S.PendingIndex = Index;
	S.bPendingCapture = bCapture;
	S.PendingCaptives.Length = 0;
	S.PendingSurvivors.Length = 0;
	S.PendingExploded.Length = 0;
	S.bPendingAreaLost = false;
	S.PendingSquad.Length = 0;
	S.PendingCivilians = -1;
	S.PendingCiviliansSaved = -1;
	S.PendingMission = 0;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** The chosen mission goes ahead: its UFO or site taken up by XCOM, an alien base's Skeleton Key spent. */
static function MissionCommitted()
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a mission sent");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	if (S.PendingKind <= 2)
		S.Ufos[S.PendingIndex].Status = 5;
	else if (S.PendingKind <= 4 || S.PendingKind == 7 || S.PendingKind == 10)
		S.Sites[S.PendingIndex].Status = 2;
	// (The covert operation answered: it no longer expires.)
	else if (S.PendingKind == 8)
		S.ExaltMissionUntil = 0;
	// An alien base takes a Skeleton Key, whatever comes of it (XGStrategy: STORAGE().RemoveItem(184)).
	if (S.PendingKind == 5)
		class'LWEngineering'.static.Take(NewGameState, 'LWItem_Skeleton_Key', 1);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** Backed out of squad select: no mission pending, the campaign as before it was chosen. */
static function MissionCancelled()
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a mission not sent");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	// A covert operation not sent: the operative back in the field (PrepareMission put them on duty for it).
	if (S.PendingKind == 8)
		class'LWExalt'.static.OperativeBackInField(NewGameState, S);
	S.PendingKind = 0;
	S.PendingIndex = 0;
	S.bPendingCapture = false;
	S.PendingSquad.Length = 0;
	S.PendingEWMap = "";
	S.PendingMission = 0;
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
/** The strategy layer opened (the hub, the Geoscape): the campaign's state there, a mission come back counted, Long War's
 *  wounds, damaged gear and fatigue on those who went, the research rate. */
static function Arrived()
{
	GetOrCreate();
	class'LWWounds'.static.Apply();
	class'LWGearRepair'.static.Apply();
	class'LWFatigue'.static.Apply();
	CheckMissionBack();
	SyncResearch();
}

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
	local int Country, GeneModded, Mecs;
	local array<int> Squad;

	if (Get() == none || Get().PendingKind == 0)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a mission back");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	// The world's news of it (features/ew-sitroom-ticker.md).
	class'LWTicker'.static.SquadCounts(GeneModded, Mecs);
	class'LWTicker'.static.Mission(S, S.PendingKind, S.PendingKind == 10 ? S.PendingIndex : S.PendingKind == 8 ? S.ExaltOperativeCountry
		: (S.PendingKind <= 2 ? S.Ufos[S.PendingIndex].Country : ((S.PendingKind <= 4 || S.PendingKind == 7) ? S.Sites[S.PendingIndex].Country : -1)), bWon, GeneModded, Mecs);
	if (S.PendingKind == 8)
	{
		// EXALT's covert operation (Long War's PostCombat): its cell cleared or moved; the operative back.
		class'LWExalt'.static.CovertMissionBack(NewGameState, S, bWon);
		S.PendingKind = 0;
		S.PendingMission = 0;
		S.bPendingCapture = false;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		return;
	}
	if (S.PendingKind == 9)
	{
		// The raid on EXALT's base.
		class'LWExalt'.static.RaidBack(NewGameState, S, bWon);
		S.PendingKind = 0;
		S.PendingMission = 0;
		S.bPendingCapture = false;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		return;
	}
	if (S.PendingKind == 10)
	{
		// A council mission (LWCouncil): what the aliens killed leave, and the council's rewards; or the failure's panic.
		if (bWon)
		{
			Squad = S.PendingSquad.Length > 0 ? S.PendingSquad : S.MissionSquad();
			S.BringCaptivesHome(NewGameState, Squad);
			S.LeaveSurvivors(Squad);
			S.GiveKillLoot(NewGameState, Squad);
			S.Tally(S.CountryContinent(S.Sites[S.PendingIndex].Country), T_COUNCIL_MISSIONS);
			class'LWCouncil'.static.Grant(NewGameState, S, S.PendingIndex);
		}
		else
			class'LWCouncil'.static.Failed(S, S.PendingIndex);
		S.PendingKind = 0;
		S.PendingMission = 0;
		S.bPendingCapture = false;
		S.PendingCaptives.Length = 0;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		return;
	}
	Country = S.PendingKind <= 2 ? S.Ufos[S.PendingIndex].Country : ((S.PendingKind <= 4 || S.PendingKind == 7) ? S.Sites[S.PendingIndex].Country : (S.PendingKind == 5 ? S.PendingIndex : S.HomeCountry()));
	if (S.PendingKind >= 5)
	{
		if (S.PendingKind == 5 && bWon)
			S.Tally(S.CountryContinent(Country), T_ALIEN_BASES);
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
		S.LeaveSurvivors(Squad);
		S.GiveKillLoot(NewGameState, Squad);
	}
	S.bPendingCapture = false;
	S.PendingCaptives.Length = 0;
	if (S.PendingKind == 4)
	{
		S.TerrorsTaken++;
		if (bWon)
			S.TerrorWon(S.PendingIndex);
		else
			S.Tally(S.CountryContinent(Country), T_TERROR_FAILED);
	}
	if (S.PendingKind == 3 && bWon)
		S.GiveAbductionReward(NewGameState, S.Sites[S.PendingIndex].Difficulty);
	if (S.PendingKind == 1)
	{
		if (bWon)
		{
			S.Tally(S.CountryContinent(Country), T_UFO_RAIDS);
			S.CraftTaken(S.Ufos[S.PendingIndex].Ufo);
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
			S.Tally(S.CountryContinent(Country), T_UFO_RAIDS);
			S.CraftTaken(U.Ufo);
			S.AddPanic(Country, class'LWStrategyRules'.default.PanicUfoAssault);
			S.UfoDowned(U);
			S.AlienResources -= class'LWStrategyRules'.static.WorthOf(U.Ufo);
			S.GiveSalvage(NewGameState, U.Ufo, false);
		}
		else
		{
			S.AddPanic(Country, class'LWStrategyRules'.default.PanicUfoEscaped);
			if (U.Objective == 2 && class'LWStrategyRules'.static.HarvestOf(U.Ufo) > 0)
				S.AlienResources += class'LWX2SecondWave'.static.War(class'LWStrategyRules'.static.HarvestOf(U.Ufo) + Rand(5));
		}
	}
	else if (S.PendingKind == 3)
	{
		S.Tally(S.CountryContinent(Country), bWon ? T_ABDUCTIONS_THWARTED : T_ABDUCTIONS_FAILED);
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
		// (Long War's objective: build the Hyperwave Relay, XGDebriefUI.PostHyperwaveMatinee.)
		class'LWObjectives'.static.Advance(self, class'LWObjectives'.const.OBJ_BUILD_HYPERWAVE);
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
			// (Dynamic War: ÷ SW_MARATHON, XGItemTree.Alloys.)
			Alloys = class'LWX2SecondWave'.static.War(int(Item.Count * class'LWStrategyRules'.default.AlloyBalance[d]));
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
			// (Dynamic War: ÷ SW_MARATHON, XGItemTree.Elerium.)
			Elerium = class'LWX2SecondWave'.static.War(Total * class'LWStrategyRules'.default.EleriumPerPowerSource[d]);
			if (bCrashed)
				Elerium -= int(RandRange(class'LWStrategyRules'.default.MinLostWreckedElerium * class'LWStrategyRules'.default.EleriumPerPowerSource[d],
					class'LWStrategyRules'.default.MaxLostWreckedElerium * class'LWStrategyRules'.default.EleriumPerPowerSource[d]) * (Total - Count));
		}
		class'X2Item_LWArtifacts'.static.Give(NewGameState, Item.Item, Cargo(Item.Item, Count));
		if (Item.Item == 'PsiLink' && Count > 0)
			bHadPsiLink = true;
			// (Long War's objective: use the device, XGDebriefUI.PostPsiLinkMatinee.)
			class'LWObjectives'.static.Advance(self, class'LWObjectives'.const.OBJ_USE_DEVICE);
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
	local array<int> CorpseCounts, Exploded;
	local int a, k, f, d, j, Fragments, Elerium, Alloys, Meld, Wrecked;
	local string Got;

	d = class'LWStrategyRules'.static.Difficulty();
	Exploded = PendingExploded;
	PendingExploded.Length = 0;
	foreach Squad(a)
	{
		k = class'LWStrategyRules'.default.Species.Find('Char', a);
		if (k == INDEX_NONE)
			continue;
		Sp = class'LWStrategyRules'.default.Species[k];
		// Killed by an explosion: its weapons wrecked, no fragments (CheckForDamagedItems); its corpse and the rest stay.
		j = Exploded.Find(a);
		if (j != INDEX_NONE)
		{
			Exploded.Remove(j, 1);
			Wrecked++;
		}
		else
			foreach Sp.Fragments(f)
				Fragments += Max(1, int(f * class'LWStrategyRules'.default.FragmentBalance[d]));
		Elerium += Sp.Elerium;
		Alloys += Sp.Alloys;
		Meld += Sp.Meld;
		AddCount(Corpses, CorpseCounts, Sp.Corpse);
		AddCount(Corpses, CorpseCounts, Sp.ExtraCorpse);
	}
	// (Dynamic War: the elerium, alloys, fragments and meld ÷ SW_MARATHON, 0.5: twice as much from fewer missions;
	// XGSummaryUI.CollectArtifactsFromDeadAliens, its items 161-164.)
	if (class'LWX2SecondWave'.static.On(9) && class'LWX2SecondWave'.default.Marathon > 0)
	{
		Fragments = int(Fragments / class'LWX2SecondWave'.default.Marathon);
		Elerium = int(Elerium / class'LWX2SecondWave'.default.Marathon);
		Alloys = int(Alloys / class'LWX2SecondWave'.default.Marathon);
		Meld = int(Meld / class'LWX2SecondWave'.default.Marathon);
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
	Note("The aliens killed (" $ Squad.Length $ ") left:" @ Fragments @ "weapon fragments," @ Elerium / 10 @ "elerium," @ Alloys / 10 @ "alloys," @ Meld / 10 @ "meld" $ Got $ "."
		$ (Wrecked > 0 ? " The weapons of" @ Wrecked @ "killed by explosions were wrecked." : ""));
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
/** The aliens left standing taken out of the squad whose loot is brought home (XGSummaryUI collects from the dead only). */
function LeaveSurvivors(out array<int> Squad)
{
	local int a, j;

	foreach PendingSurvivors(a)
	{
		j = Squad.Find(a);
		if (j != INDEX_NONE)
			Squad.Remove(j, 1);
	}
	PendingSurvivors.Length = 0;
}

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

/** Long War's act (XGStrategy.GetAct): 3 once a Hyperwave Beacon has ever been held, 2 once a captive has been
 *  interrogated (LABS().HasInterrogatedCaptive: an interrogation researched), else 1. */
static function int Act()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local name Tech;
	local int Id;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ == none)
		return 1;
	if (XComHQ.EverAcquiredInventoryTypes.Find(class'X2Item_LWArtifacts'.static.ItemFor('HyperwaveBeacon')) != INDEX_NONE)
		return 3;
	for (Id = 0; Id < 100; Id++)
	{
		if (!class'LWResearchRules'.static.IsInterrogation(Id))
			continue;
		Tech = class'LWResearchRules'.static.TemplateForId(Id);
		if (Tech != '' && XComHQ.IsTechResearched(Tech))
			return 2;
	}
	return 1;
}

/** An abduction's difficulty (XGStrategyAI.GetAbductionDifficulty): the act and the country's panic, 0-3. */
function int AbductionDifficulty(int Country)
{
	local int Diff;

	Diff = Act() - 1 + (Countries[Country].Panic + 1) / 20 - 1 + Rand(2);
	if (Days() > 210)
		Diff += Rand(2);
	return Clamp(Diff, 0, 3);
}

/** An abduction won: Long War's cash (DetermineAbductionReward: every abduction pays cash), by its difficulty. */
function GiveAbductionReward(XComGameState NewGameState, int Diff)
{
	GiveCash(NewGameState, AbductionReward(Diff));
	Note("The abduction's reward:" @ class'LWStrategyRules'.static.Money(AbductionReward(Diff)) $ ".");
}

/** The cash an abduction of this difficulty pays (DetermineAbductionReward). */
function int AbductionReward(int Diff)
{
	local int Cash;

	Cash = class'LWStrategyRules'.default.AbductionRewardCash;
	// Bounties (DetermineAbductionReward): more, before the difficulty's scale.
	if (class'LWBonuses'.static.Has(class'LWBonuses'.const.BOUNTIES, self) > 0)
		Cash *= 1.0 + class'LWBonuses'.static.Has(class'LWBonuses'.const.BOUNTIES, self) / 100.0;
	// (Dynamic War: ÷ SW_MARATHON.)
	return class'LWX2SecondWave'.static.War(int(Cash * (Diff == 0 ? 0.8 : (Diff == 1 ? 0.9 : (Diff == 2 ? 1.0 : 1.15)))));
}

function GiveCash(XComGameState NewGameState, int Amount)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	if (XComHQ == none)
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', Amount);
}

// --- Satellites ------------------------------------------------------------------------------

static function bool BuildSatellite()
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ.GetSupplies() < class'LWStrategyRules'.static.SatelliteCash())
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a satellite ordered");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -class'LWStrategyRules'.static.SatelliteCash());
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
	S.Tally(S.CountryContinent(Country), T_SATELLITES_LAUNCHED);
	// A council request for a satellite there, met (OnSatelliteSuccessfullyTransferred).
	class'LWCouncilRequests'.static.SatelliteArrived(NewGameState, S, Country);
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
	local int i, d, Blocks, Funding, Chance, Upkeep, MetScientists, MetEngineers;
	local string Report;

	class'LWExalt'.static.MonthEnded(self);
	class'LWCouncil'.static.MonthEnded(self);
	class'LWCouncilRequests'.static.MonthEnded(self);
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(GetParentGameState().ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	// The council's grade, on the month's tallies and XCOM's money before it is paid (DetermineMonthlyGrade).
	Grade(XComHQ.GetSupplies());

	d = class'LWStrategyRules'.static.Difficulty();
	for (i = 0; i < Countries.Length; i++)
	{
		// (A country with abductions under way, or EXALT's covert operative in it, stays: AddToDefectorsList, WhoIsLeaving.)
		if (Countries[i].bLeft || HasAbductions(i) || (ExaltOperative > 0 && ExaltOperativeCountry == i))
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
		if (Rand(100) < Chance)
			Leaving.AddItem(i);
	}
	// The most panicked first; a month graded A to C loses at most DefectionsPerMonth of them, a D or F month all
	// (XGWorld.DetermineDefections, AdjustDefections). The grade then falls a step for any country leaving, two for more
	// than two.
	Leaving.Sort(ByPanic);
	if (ReportGrade < 3 && Leaving.Length > class'LWStrategyRules'.default.DefectionsPerMonth[d])
		Leaving.Length = class'LWStrategyRules'.default.DefectionsPerMonth[d];
	ReportGrade = Min(4, ReportGrade + (Leaving.Length > 0 ? 1 : 0) + (Leaving.Length > 2 ? 1 : 0));
	for (i = 0; i < Leaving.Length; i++)
	{
		Leave(Leaving[i]);
		Report @= CountryName(Leaving[i]) @ "has left the council.";
		class'LWTicker'.static.Push(self, "CountryWithdraw", Leaving[i], class'LWTicker'.const.BAD);
	}
	ReportLeaving = Leaving;
	NotHelped.Length = 0;
	for (i = 0; i < Countries.Length; i++)
	{
		if (Countries[i].bLeft)
			continue;
		Def = class'LWStrategyRules'.default.Countries[i];
		Funding += CountryFunding(i, Countries[i].bSatellite);
		if (!Countries[i].bSatellite)
			continue;
		// The staff a watched country sends (XGWorld's council meeting).
		Scientists += Def.Scientists;
		Engineers += Def.Engineers;
		MetScientists += Def.Scientists;
		MetEngineers += Def.Engineers;
		Blocks = Countries[i].Panic + 1;
		if ((Blocks >= 95 && Rand(100) < class'LWStrategyRules'.default.Panic5ReductionChance[d])
			|| (Blocks >= 80 && Rand(100) < class'LWStrategyRules'.default.Panic4ReductionChance[d])
			|| (Blocks > 1 && Rand(100) < class'LWStrategyRules'.default.PanicLowReductionChance[d]))
			AddPanic(i, -class'LWStrategyRules'.default.SatPanicReduction[d]);
	}
	// Wealth of Nations (XGWorld.GetIncome): the funding raised by its share.
	if (class'LWBonuses'.static.Has(class'LWBonuses'.const.WEALTH_OF_NATIONS, self) > 0)
		Funding = int(Funding + Funding * (class'LWBonuses'.static.Has(class'LWBonuses'.const.WEALTH_OF_NATIONS, self) / 100.0));
	// The base's upkeep, paid from it (XGHeadQuarters.PayMaintenance).
	Upkeep = TileType.Length > 0 ? class'LWBase'.static.Upkeep(self) : 0;
	XComHQ.AddResource(GetParentGameState(), 'Supplies', Funding - Upkeep);
	ReportFunding = Funding;
	ReportScientists = MetScientists;
	ReportEngineers = MetEngineers;
	ReportHours = Hours;
	bReportDue = true;
	Note("Council report: funding" @ class'LWStrategyRules'.static.Money(Funding) $ ", upkeep" @ class'LWStrategyRules'.static.Money(Upkeep) $ "." $ Report);
	`log("LongWarX2: Long War month" @ Month @ "ended: funding" @ Funding @ "countries left" @ NumLeft(), , 'LongWarX2');
	Month++;
	PlanMonth();
	bStop = true;
}

/** The defectors' order (XGWorld.SortDefectorsList): the more panicked first. */
function int ByPanic(int A, int B)
{
	return Countries[B].Panic > Countries[A].Panic ? -1 : 0;
}

/** One more of a tally this month (MonthTally), on a continent. */
function Tally(int Continent, int T)
{
	if (Continent < 0 || Continent > 4)
		return;
	if (MonthTally.Length < 5 * TALLIES)
		MonthTally.Length = 5 * TALLIES;
	MonthTally[Continent * TALLIES + T] += 1;
}

/** A tally this month, on a continent (-1: on all of them). */
function int Tallied(int T, optional int Continent = -1)
{
	local int c, n;

	for (c = 0; c < 5; c++)
		if ((Continent < 0 || Continent == c) && c * TALLIES + T < MonthTally.Length)
			n += MonthTally[c * TALLIES + T];
	return n;
}

/**
 * The council's report of the month (XGFundingCouncil.DetermineMonthlyGrade): the tallies summed, UFOs escaped (detected and
 * not brought down) among them; XCOM in debt (Money below 0) is a mismanaged month. The score is minus every failure:
 * mismanaged, terror and abductions let go or lost, satellites lost; the wins are abductions and terror stopped, UFOs shot
 * down, alien bases and council missions. F at -6 or less, or below 0 with no win; D at -4, or below -1 with one win; C at
 * -2; B at -1; else A. The tallies are then cleared for the next month.
 */
function Grade(int Money)
{
	local int T, Score, Wins;

	ReportTally.Length = TALLIES + 1;
	for (T = 0; T < TALLIES; T++)
		ReportTally[T] = Tallied(T);
	// (TALLIES: UFOs escaped.)
	ReportTally[TALLIES] = ReportTally[T_UFOS_DETECTED] - ReportTally[T_UFOS_SHOT_DOWN];
	bReportMismanaged = Money < 0;
	ReportMoney = Money;
	Wins = ReportTally[T_ABDUCTIONS_THWARTED] + ReportTally[T_TERROR_THWARTED] + ReportTally[T_UFOS_SHOT_DOWN] + ReportTally[T_ALIEN_BASES] + ReportTally[T_COUNCIL_MISSIONS];
	Score = -(bReportMismanaged ? 1 : 0) - ReportTally[T_TERROR_IGNORED] - ReportTally[T_TERROR_FAILED] - ReportTally[T_ABDUCTIONS_IGNORED] - ReportTally[T_ABDUCTIONS_FAILED] - ReportTally[T_SATELLITES_LOST];
	if (Score <= -6 || (Score < 0 && Wins == 0))
		ReportGrade = 4;
	else if (Score <= -4 || (Score < -1 && Wins == 1))
		ReportGrade = 3;
	else if (Score <= -2)
		ReportGrade = 2;
	else if (Score <= -1)
		ReportGrade = 1;
	else
		ReportGrade = 0;
	MonthTally.Length = 0;
	`log("LongWarX2: the council's grade" @ ReportGrade @ "score" @ Score @ "wins" @ Wins, , 'LongWarX2');
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
	local int Before;

	if (Country < 0 || Country >= Countries.Length || Countries[Country].bLeft)
		return;
	// Dynamic War (second wave #9, XGCountry.AddPanic): ÷ SW_MARATHON after the first day.
	if (Days() > 0)
		Amount = class'LWX2SecondWave'.static.War(Amount);
	// (Long War's XGCountry.AddPanic: EXALT's hidden cells on the continent add to a rise.)
	Amount += class'LWExalt'.static.PanicMod(self, Country, Amount);
	Before = Countries[Country].Panic;
	Countries[Country].Panic = Clamp(Countries[Country].Panic + Amount, 0, 99);
	// (Its news, as XGCountry.AddPanic pushes a panic headline whenever the panic changes.)
	if (Countries[Country].Panic != Before)
		class'LWTicker'.static.Panic(self, Country);
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

/** The Hyperwave Relay built (Long War's XGHeadQuarters.IsHyperwaveActive: a UFO's class and objective shown when seen). */
function bool Hyperwave()
{
	return TileFacility.Length > 0 && class'LWBase'.static.Count(self, 18) > 0;
}

/** Whether a UFO's class is known when seen (XGGeoscape.CanIdentifyCraft): with the Hyperwave Relay, or once XCOM has
 *  taken one of the class. */
function bool Identified(int Ufo)
{
	return Hyperwave() || (Ufo >= 0 && Ufo < CraftEncounters.Length && CraftEncounters[Ufo] > 0);
}

/** A UFO as the Geoscape names it (XGMissionControlUI's alerts): its class when known, else unidentified, by its size. */
function string UfoLabel(int Ufo)
{
	return Identified(Ufo) ? ShipName(Ufo) : "unidentified" @ class'LWAirWar'.static.Ufo(Ufo, Category()).Size @ "UFO";
}

/** A UFO of the class taken (a crash site or a landed UFO won: XGStrategy.PostCombat). */
function CraftTaken(int Ufo)
{
	if (Ufo < 0)
		return;
	if (CraftEncounters.Length <= Ufo)
		CraftEncounters.Length = Ufo + 1;
	CraftEncounters[Ufo] += 1;
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
			AddDecision(Kinds, Indexes, Labels, 1, i, "INTERCEPT:" @ UfoLabel(Ufos[i].Ufo) @ "over" @ CountryName(Ufos[i].Country) @ "(" $ (Ufos[i].Until - Hours) $ "h," @ class'LWHangar'.static.CountReadyFor(i) @ "jets ready)");
		else if (Ufos[i].Status == 3)
			AddDecision(Kinds, Indexes, Labels, 2, i, "ASSAULT: crash site in" @ CountryName(Ufos[i].Country) @ "(" $ (Ufos[i].Until - Hours) $ "h)");
		else if (Ufos[i].Status == 4 && Ufos[i].bDetected)
			AddDecision(Kinds, Indexes, Labels, 3, i, "ASSAULT: landed UFO in" @ CountryName(Ufos[i].Country) @ "(" $ (Ufos[i].Until - Hours) $ "h)");
	}
	for (i = 0; i < Sites.Length; i++)
		if (Sites[i].Status == 1 && Sites[i].bHQ)
			AddDecision(Kinds, Indexes, Labels, 8, i, "DEFEND: XCOM's headquarters (" $ (Sites[i].Until - Hours) $ "h)");
		else if (Sites[i].Status == 1 && Sites[i].bCouncil)
			AddDecision(Kinds, Indexes, Labels, 11, i, "COUNCIL:" @ class'LWCouncil'.static.KindName(Sites[i].CouncilKind) @ "in" @ CountryName(Sites[i].Country) @ "(" $ (Sites[i].Until - Hours) $ "h;" @ class'LWCouncil'.static.RewardsText(Sites[i].Rewards) $ ")");
		else if (Sites[i].Status == 1)
			AddDecision(Kinds, Indexes, Labels, Sites[i].bTerror ? 5 : 4, i, (Sites[i].bTerror ? "RESPOND: terror in" : "RESPOND: abductions in") @ CountryName(Sites[i].Country) @ "(" $ (Sites[i].Until - Hours) $ "h)");
	// The council's requests (LWCouncilRequests): one XCOM can meet, to give (or, pending, to refuse).
	for (i = 0; i < Requests.Length; i++)
	{
		if (Requests[i].Transfer != 0)
			continue;
		if (class'LWCouncilRequests'.static.Held(Requests[i]) >= Requests[i].Amount)
			AddDecision(Kinds, Indexes, Labels, 20, i, "COUNCIL REQUEST: give" @ CountryName(Requests[i].Country) @ class'LWCouncilRequests'.static.Words(Requests[i])
				@ "for" @ class'LWCouncil'.static.RewardsText(Requests[i].Rewards) $ (Requests[i].bPending ? "" : " (" $ Requests[i].HoursLeft $ "h)"));
		if (Requests[i].bPending)
			AddDecision(Kinds, Indexes, Labels, 21, i, "COUNCIL REQUEST: refuse" @ CountryName(Requests[i].Country) $ "'s");
	}
	// EXALT: the covert operative ready for extraction (features/lw-exalt.md).
	if (ExaltOperative > 0 && ExaltMissionUntil > Hours)
		AddDecision(Kinds, Indexes, Labels, 9, 0, "COVERT OPERATION:" @ (ExaltMissionKind == 2 ? "data recovery" : "extraction") @ "in" @ CountryName(ExaltOperativeCountry) @ "(" $ (ExaltMissionUntil - Hours) $ "h)");
	if (bExaltRaidReady && ExaltState == class'LWExalt'.const.ACTIVE)
		AddDecision(Kinds, Indexes, Labels, 10, 0, "ASSAULT: EXALT's base in" @ CountryName(ExaltCountry));
	// The story: an alien base, with a Skeleton Key to open it; the Temple Ship, once the Gollop Chamber stands.
	if (class'LWEngineering'.static.Held('LWItem_Skeleton_Key') > 0)
		for (i = 0; i < AlienBases.Length; i++)
			AddDecision(Kinds, Indexes, Labels, 6, AlienBases[i], "ASSAULT: the alien base in" @ CountryName(AlienBases[i]) @ "(a Skeleton Key)");
	// (Liberators, second wave #8: the Temple Ship's volunteer only while no country has left the council, as Long War's
	// XGFacility_Barracks.HasPotentialVolunteer has it: every country freed first.)
	if (!bCampaignWon && TileFacility.Length > 0 && class'LWBase'.static.Count(self, 19) > 0 && (!class'LWX2SecondWave'.static.On(8) || NumLeft() == 0))
		AddDecision(Kinds, Indexes, Labels, 7, 0, "ASSAULT: the Temple Ship");
}

/** The pending mission in words, for squad select's mission panel: its title and what it brings home. */
/** The country of the mission sent (as MissionBack reckons it): a UFO's, a site's (abductions, terror, the HQ's assault, a
 *  council mission), an alien base's; else XCOM's home. */
function int PendingCountry()
{
	switch (PendingKind)
	{
	case 1: case 2: return Ufos[PendingIndex].Country;
	case 3: case 4: case 7: case 10: return Sites[PendingIndex].Country;
	case 5: return PendingIndex;
	}
	return HomeCountry();
}

/** EW's word, or ours where the player's EW words are not written. */
static function string TitleOr(string EW, string Ours)
{
	return EW != "" ? EW : Ours;
}

/** The mission sent, as squad select and the loading briefing name it: EW's mission titles (XGMission_*.m_strTitle, as
 *  Mission Control lists them) and its country; what it brings home. */
function PendingWords(out string Title, out string Reward)
{
	switch (PendingKind)
	{
	case 1:
		Title = TitleOr(class'UILWEWAlert'.default.TitleCrash, "Crash site:") @ UfoLabel(Ufos[PendingIndex].Ufo) @ "-" @ CountryName(Ufos[PendingIndex].Country);
		Reward = "The UFO's salvage";
		break;
	case 2:
		Title = TitleOr(class'UILWEWAlert'.default.TitleLanded, "Landed UFO:") @ UfoLabel(Ufos[PendingIndex].Ufo) @ "-" @ CountryName(Ufos[PendingIndex].Country);
		Reward = "The UFO's salvage";
		break;
	case 3:
		Title = TitleOr(class'UILWEWAlert'.default.TitleAbductions, "Abductions") @ "-" @ CountryName(Sites[PendingIndex].Country);
		Reward = "Cash, and the country's panic down";
		break;
	case 4:
		Title = Repl(TitleOr(class'UILWEWAlert'.default.TitleTerror, "Terror in <XGParam:StrValue0/>"), "<XGParam:StrValue0/>", CountryName(Sites[PendingIndex].Country));
		Reward = "The civilians saved";
		break;
	case 5:
		Title = TitleOr(class'UILWEWAlert'.default.TitleAlienBase, "The alien base in ") $ CountryName(PendingIndex);
		Reward = "The country back, and the Hyperwave Beacon";
		break;
	case 6:
		Title = TitleOr(class'UILWEWAlert'.default.TitleTempleShip, "The Temple Ship");
		Reward = "The end of the war";
		break;
	case 7:
		Title = TitleOr(class'UILWEWAlert'.default.TitleHQ, "XCOM's headquarters under attack");
		Reward = "XCOM's survival";
		break;
	case 10:
		Title = TitleOr(class'UILWEWAlert'.default.FCMission, "Council") @ class'LWCouncil'.static.KindName(Sites[PendingIndex].CouncilKind) @ "-" @ CountryName(Sites[PendingIndex].Country);
		Reward = class'LWCouncil'.static.RewardsText(Sites[PendingIndex].Rewards);
		break;
	default:
		Title = "";
		Reward = "";
	}
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
	return PsiTrainees.Find('Unit', UnitID) != INDEX_NONE || GenePatients.Find('Unit', UnitID) != INDEX_NONE || MECPatients.Find('Unit', UnitID) != INDEX_NONE;
}

/** Whether the Psi Labs have a place free (Long War's places per labs built). */
static function bool PsiPlaceFree(XComGameState_LWStrategy S)
{
	return S != none && S.PsiTrainees.Length < class'LWBaseRules'.default.PsiSlots * class'LWBase'.static.Count(S, 17);
}

/** What keeps a soldier out of the Psi Labs now, whatever the power ("" if nothing): the labs, a free place, ready for duty. */
static function string PsiSoldierWhy(XComGameState_LWStrategy S, XComGameState_Unit Unit)
{
	if (class'LWBase'.static.Count(S, 17) == 0)
		return "the Psi Labs";
	if (!PsiPlaceFree(S))
		return "a free place in the Psi Labs";
	if (Unit == none || !Unit.IsSoldier() || Unit.IsRobotic() || class'LWMECs'.static.IsMEC(Unit) || !Unit.CanGoOnMission() || S.InPsiTraining(Unit.ObjectID))
		return "a soldier ready for duty";
	// Mind Hates Matter (second wave #20, XGFacility_GeneLabs: a gene-modded soldier counts as psi-tested, without the gift).
	if (class'LWX2SecondWave'.static.On(20) && HasAnyGeneMod(Unit))
		return "a soldier without gene mods";
	// (XGStrategySoldier.IsReadyToPsiLevelUp: no Neural Damping gene mod (perk 28), not an officer (perk 171), and the psi
	// experience of their next psi rank; features/lw-psi.md.)
	if (HasGeneMod(Unit, 28))
		return "a soldier without Neural Damping";
	if (class'LWOfficers'.static.Rank(Unit) > 0)
		return "a soldier who is not an officer";
	if (PsiXPOf(Unit) < PsiXPNeeded(PsiRankOf(Unit) + 1))
		return "psi experience (" $ PsiXPOf(Unit) $ " of " $ PsiXPNeeded(PsiRankOf(Unit) + 1) $ ")";
	return "";
}

/** A soldier's psi experience (features/lw-psi.md; Long War's m_kSoldier.iPsiXP), kept on the unit. */
static function int PsiXPOf(XComGameState_Unit Unit)
{
	local UnitValue V;

	return (Unit != none && Unit.GetUnitValue('LWX2PsiXP', V)) ? int(V.fValue) : 0;
}

/** A soldier's psi rank (Long War's iPsiRank: one for each power gained); never set (a campaign from before it was kept):
 *  the powers they hold. */
static function int PsiRankOf(XComGameState_Unit Unit)
{
	local UnitValue V;
	local LWBaseRules.LWPsiPower P;
	local name Ability;
	local int n;

	if (Unit == none)
		return 0;
	if (Unit.GetUnitValue('LWX2PsiRank', V))
		return int(V.fValue);
	foreach class'LWBaseRules'.default.PsiPowers(P)
	{
		Ability = class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk);
		if (Ability != '' && Unit.HasSoldierAbility(Ability))
			n++;
	}
	return n;
}

/** Whether a soldier's psi experience is shown at all (UIStrategyComponent_SoldierStats.UpdateData, XGStrategySoldier.GetName
 *  type 8): once the Psi Labs' research (Long War's tech 4) is done, for a soldier neither a MEC nor robotic nor
 *  Neural-Damped. */
static function bool PsiXPShown(XComGameState_Unit Unit)
{
	local name Tech;

	if (Unit == none || Unit.IsRobotic() || class'LWMECs'.static.IsMEC(Unit) || HasGeneMod(Unit, 28))
		return false;
	Tech = class'LWResearchRules'.static.TemplateForId(4);
	return Tech != '' && class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(Tech);
}

/** A soldier with a psi power to choose (XGStrategySoldier.HasAvailablePerksToAssign(true)): a rank or psi rank, the psi
 *  experience for the next psi rank, and a power not held in the columns up to it. */
static function bool PsiPromotable(XComGameState_Unit Unit)
{
	local LWBaseRules.LWPsiPower P;
	local name Ability;
	local int Rank;

	if (Unit == none || Unit.IsRobotic() || class'LWMECs'.static.IsMEC(Unit))
		return false;
	Rank = PsiRankOf(Unit);
	if ((Unit.GetRank() == 0 && Rank == 0) || Rank >= 6 || PsiXPOf(Unit) < PsiXPNeeded(Rank + 1))
		return false;
	foreach class'LWBaseRules'.default.PsiPowers(P)
	{
		Ability = class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk);
		if (Ability != '' && P.Column >= 1 && P.Column <= Rank + 1 && !Unit.HasSoldierAbility(Ability))
			return true;
	}
	return false;
}

/** The psi experience a psi rank needs (XGTacticalGameCore.GetPsiXPRequired: m_iPsiXPLevels, the last for any above). */
static function int PsiXPNeeded(int Rank)
{
	local int n;

	n = class'LWBaseRules'.default.PsiXPLevels.Length;
	if (n == 0)
		return 0;
	return class'LWBaseRules'.default.PsiXPLevels[Clamp(Rank, 0, n - 1)];
}

/** The psi experience of the powers a soldier holds: each one's tier (XGCharacter_Soldier.AddPsiXP(255)'s per-perk bonuses). */
static function int PsiPowersXP(XComGameState_Unit Unit)
{
	local LWBaseRules.LWPsiPower P;
	local name Ability;
	local int XP;

	foreach class'LWBaseRules'.default.PsiPowers(P)
	{
		Ability = class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk);
		if (Ability != '' && Unit.HasSoldierAbility(Ability))
			XP += P.Tier;
	}
	return XP;
}

/** Psi experience as Long War adds it (XGCharacter_Soldier.AddPsiXP): Dynamic War / SW_MARATHON + 1, x the item's factor
 *  with the Neuroregulator carried. Returns what was added; Unit must be a modified state. */
static function int AddPsiXP(XComGameState_Unit Unit, int XP, XComGameState NewGameState)
{
	local XComGameState_Item Item;
	local array<XComGameState_Item> Items;

	if (Unit == none || !Unit.IsSoldier() || Unit.IsRobotic() || XP <= 0)
		return 0;
	if (class'LWX2SecondWave'.static.On(9))
		XP = class'LWX2SecondWave'.static.War(XP) + 1;
	Items = Unit.GetAllInventoryItems(NewGameState, true);
	foreach Items(Item)
		if (class'LWGearRepair'.static.ItemNumber(Item.GetMyTemplateName()) == class'LWBaseRules'.default.PsiXPItem)
		{
			XP = int(XP * class'LWBaseRules'.default.PsiXPItemFactor);
			break;
		}
	Unit.SetUnitFloatValue('LWX2PsiXP', PsiXPOf(Unit) + XP, eCleanup_Never);
	return XP;
}

/** Any of Long War's gene mods on the soldier. */
static function bool HasAnyGeneMod(XComGameState_Unit Unit)
{
	local LWBaseRules.LWGeneMod G;

	foreach class'LWBaseRules'.default.GeneMods(G)
		if (HasGeneMod(Unit, G.Perk))
			return true;
	return false;
}

/** Any of Long War's psi powers on the soldier. */
static function bool HasAnyPsiPower(XComGameState_Unit Unit)
{
	local LWBaseRules.LWPsiPower P;
	local name Ability;

	foreach class'LWBaseRules'.default.PsiPowers(P)
	{
		Ability = class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk);
		if (Ability != '' && Unit.HasSoldierAbility(Ability))
			return true;
	}
	return false;
}

/** Whether a soldier may begin training a power now; Why says what is missing. */
static function bool CanTrainPsi(XComGameState_LWStrategy S, XComGameState_Unit Unit, LWBaseRules.LWPsiPower P, out string Why)
{
	local name Tech, Ability;

	Ability = class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk);
	Why = PsiSoldierWhy(S, Unit);
	if (Why != "")
		return false;
	if (Ability != '' && Unit.HasSoldierAbility(Ability))
		Why = "a soldier without the power";
	// (Long War's psi tree: a power of a column up to the soldier's next psi rank, UISoldierPromotion's psi mode.)
	else if (P.Column > PsiRankOf(Unit) + 1)
		Why = "psi rank " $ (P.Column - 1);
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

/** A soldier taken out of the Psi Labs (XGPsiLabsUI.OnRemoveTrainee): training stopped, nothing gained, back in the barracks. */
static function StopPsi(int UnitID)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local int i;

	S = Get();
	i = S != none ? S.PsiTrainees.Find('Unit', UnitID) : INDEX_NONE;
	if (i == INDEX_NONE)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("LongWarX2: psi training stopped");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	S.PsiTrainees.Remove(i, 1);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("LongWarX2: psi: training stopped for unit" @ UnitID, , 'LongWarX2');
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
	bHadPsiSoldier = true;
	Power.AbilityType.AbilityName = Ability;
	// Bound to the soldier's weapon, as XCOM 2's psi powers are to the psi amp: its range is the power's reach.
	Power.AbilityType.ApplyToWeaponSlot = eInvSlot_PrimaryWeapon;
	Power.bUnlocked = true;
	// (XGStrategySoldier.PsiLevelUp: a psi rank more, and will: iBaseOTSWillIncrease + Rand(iRandOTSWillIncrease).)
	Unit.SetUnitFloatValue('LWX2PsiRank', PsiRankOf(Unit) + 1, eCleanup_Never);
	Unit.AWCAbilities.AddItem(Power);
	Unit.SetBaseMaxStat(eStat_Will, Unit.GetBaseStat(eStat_Will) + class'LWBaseRules'.default.PsiRankWillBase + Rand(Max(1, class'LWBaseRules'.default.PsiRankWillRand)));
	Note(Unit.GetFullName() @ "gained" @ class'X2Ability_LWStandins'.static.PsiPowerName(Ability) @ "in the Psi Labs.");
	`log("LongWarX2: psi:" @ Unit.GetFullName() @ "gained" @ Ability @ "(rolled" @ Roll @ "against" @ T.Chance $ ")", , 'LongWarX2');
}

// --- Gene mods (features/lw-genemods.md) ----------------------------------------------

/** Whether the Genetics Lab has a tank free (Long War's tanks per lab built). */
static function bool GeneTankFree(XComGameState_LWStrategy S)
{
	return S != none && S.GenePatients.Length < class'LWBaseRules'.default.PsiSlots * class'LWBase'.static.Count(S, 23);
}

/** What keeps a soldier out of the Genetics Lab now, whatever the mod ("" if nothing): the lab, a free tank, ready for duty. */
static function string GeneSoldierWhy(XComGameState_LWStrategy S, XComGameState_Unit Unit)
{
	if (class'LWBase'.static.Count(S, 23) == 0)
		return "the Genetics Lab";
	if (!GeneTankFree(S))
		return "a free tank in the Genetics Lab";
	if (Unit == none || !Unit.IsSoldier() || Unit.IsRobotic() || class'LWMECs'.static.IsMEC(Unit) || !Unit.CanGoOnMission() || S.InPsiTraining(Unit.ObjectID))
		return "a soldier ready for duty";
	// Mind Hates Matter (second wave #20, XGGeneLabUI: a psi-gifted soldier can never be modified).
	if (class'LWX2SecondWave'.static.On(20) && HasAnyPsiPower(Unit))
		return "a soldier without psi powers";
	return "";
}

/** Whether a mod's research is done (XGFacility_GeneLabs.IsGeneModTechAvailable). */
static function bool GeneModOpen(LWBaseRules.LWGeneMod G)
{
	local name Tech;

	if (G.Tech == 0)
		return true;
	Tech = class'LWResearchRules'.static.TemplateForId(G.Tech);
	return Tech != '' && class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(Tech);
}

static function bool HasGeneMod(XComGameState_Unit Unit, int Perk)
{
	local name Ability;

	Ability = class'X2Ability_LWStandins'.static.GeneAbilityFor(Perk);
	return Unit != none && Ability != '' && Unit.HasSoldierAbility(Ability);
}

/** The other mod of a mod's slot (XComPerkManager.GetOppositeGeneModPerk), 0 if none. */
static function int OppositeGeneMod(int Perk)
{
	local LWBaseRules.LWGeneMod G, Other;

	if (!class'LWBaseRules'.static.GeneModFor(Perk, G))
		return 0;
	foreach class'LWBaseRules'.default.GeneMods(Other)
		if (Other.Slot == G.Slot && Other.Perk != Perk)
			return Other.Perk;
	return 0;
}

/** Whether a soldier may go into the tank for these mods now; Why says what is missing. As Long War's gene lab: each mod
 *  researched, not had already, one a slot (one in a slot the soldier has the other of replaces it), all paid for. */
static function bool CanGeneMods(XComGameState_LWStrategy S, XComGameState_Unit Unit, array<int> Perks, out string Why)
{
	local LWBaseRules.LWGeneMod G;
	local array<string> Slots;
	local int Perk, Cash, Meld;

	Why = GeneSoldierWhy(S, Unit);
	if (Why == "" && Perks.Length == 0)
		Why = "a gene mod";
	foreach Perks(Perk)
	{
		if (Why != "")
			break;
		if (!class'LWBaseRules'.static.GeneModFor(Perk, G))
			Why = "a gene mod";
		else if (!GeneModOpen(G))
			Why = "its research";
		else if (HasGeneMod(Unit, Perk))
			Why = "a soldier without the mod";
		else if (Slots.Find(G.Slot) != INDEX_NONE)
			Why = "one mod a slot (" $ G.Slot $ ")";
		Slots.AddItem(G.Slot);
		Cash += G.Cash;
		Meld += G.Meld;
	}
	if (Why == "" && class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < Cash)
		Why = class'LWStrategyRules'.static.Money(Cash);
	if (Why == "" && class'LWEngineering'.static.Held(class'X2Item_LWArtifacts'.static.ItemFor('Meld')) < Meld)
		Why = Meld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld');
	return Why == "";
}

static function bool CanGeneMod(XComGameState_LWStrategy S, XComGameState_Unit Unit, LWBaseRules.LWGeneMod G, out string Why)
{
	local array<int> Perks;

	Perks.AddItem(G.Perk);
	return CanGeneMods(S, Unit, Perks, Why);
}

static function bool StartGeneMod(int UnitID, int Perk, out string Why)
{
	local array<int> Perks;

	Perks.AddItem(Perk);
	return StartGeneMods(UnitID, Perks, Why);
}

/** A soldier into the tank for these mods (XGFacility_GeneLabs.AddSoldierToGeneLabs): all paid at once, out of the barracks
 *  until the last is made. */
static function bool StartGeneMods(int UnitID, array<int> Perks, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local LWBaseRules.LWGeneMod G;
	local LWGenePatient P;
	local int Perk, Cash, Meld;

	S = Get();
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (!CanGeneMods(S, Unit, Perks, Why))
		return false;
	P.Unit = UnitID;
	foreach Perks(Perk)
	{
		class'LWBaseRules'.static.GeneModFor(Perk, G);
		P.Perks.AddItem(Perk);
		P.HoursLeft.AddItem(class'LWBaseRules'.static.GeneHours(G));
		Cash += G.Cash;
		Meld += G.Meld;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: gene mod begun");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -Cash);
	class'LWEngineering'.static.Take(NewGameState, class'X2Item_LWArtifacts'.static.ItemFor('Meld'), Meld);
	S.GenePatients.AddItem(P);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("LongWarX2: gene mods:" @ Unit.GetFullName() @ "in the tank for" @ Perks.Length @ "mods," @ GeneHoursLeft(P) @ "hours", , 'LongWarX2');
	return true;
}

/** The hours until a soldier is out of the tank. */
static function int GeneHoursLeft(LWGenePatient P)
{
	local int H, Total;

	foreach P.HoursLeft(H)
		Total += H;
	return Total;
}

/** A mod made: the soldier's from then on (as a soldier ability); the other mod of its slot, if the soldier had it, gone. */
function GeneModDone(XComGameState NewGameState, int UnitID, int Perk)
{
	local XComGameState_Unit Unit;
	local ClassAgnosticAbility Mod;
	local name Ability, Other;
	local bool bReplaced;
	local int i;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	Ability = class'X2Ability_LWStandins'.static.GeneAbilityFor(Perk);
	if (Unit == none || Ability == '')
		return;
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Other = class'X2Ability_LWStandins'.static.GeneAbilityFor(OppositeGeneMod(Perk));
	bReplaced = false;
	for (i = Unit.AWCAbilities.Length - 1; Other != '' && i >= 0; i--)
		if (Unit.AWCAbilities[i].AbilityType.AbilityName == Other)
		{
			Unit.AWCAbilities.Remove(i, 1);
			bReplaced = true;
		}
	Mod.AbilityType.AbilityName = Ability;
	Mod.bUnlocked = true;
	Unit.AWCAbilities.AddItem(Mod);
	Note(Unit.GetFullName() @ "came out of the Genetics Lab with" @ class'X2Ability_LWStandins'.static.PsiPowerName(Ability) $ ".");
	`log("LongWarX2: gene mods:" @ Unit.GetFullName() @ "gained" @ Ability $ (bReplaced ? ", lost" @ Other : ""), , 'LongWarX2');
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
/** The next squad size, as the Officer Training School offers it (XGTechTree.GetOTSTech, HasOTSPrereqs): Special Warfare
 * School takes its share off the cash, Sandhurst off the ranks it needs. */
static function LWStrategyRules.LWSquadSize SquadSizeNext(XComGameState_LWStrategy S)
{
	local LWStrategyRules.LWSquadSize Next;
	local int v;

	Next = class'LWStrategyRules'.default.SquadSizes[Min(S.SquadSizesBought, class'LWStrategyRules'.default.SquadSizes.Length - 1)];
	v = class'LWBonuses'.static.Has(class'LWBonuses'.const.SPECIAL_WARFARE_SCHOOL, S);
	if (v > 0)
		Next.Cash *= 1.0 - v / 100.0;
	v = class'LWBonuses'.static.Has(class'LWBonuses'.const.SANDHURST, S);
	if (v > 0)
		Next.Ranks = int(Next.Ranks * (1.0 - v / 100.0));
	return Next;
}

static function bool CanBuySquadSize(XComGameState_LWStrategy S, out string Why)
{
	local LWStrategyRules.LWSquadSize Next;

	Why = "";
	if (S.SquadSizesBought >= class'LWStrategyRules'.default.SquadSizes.Length)
		Why = "nothing: both bought";
	else
	{
		Next = SquadSizeNext(S);
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
	Cash = SquadSizeNext(S).Cash;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: squad size bought");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -Cash);
	S.SquadSizesBought++;
	S.Note("The Officer Training School: squad size" @ (class'LWStrategyRules'.default.SkyrangerCapacity + S.SquadSizesBought) $ ".");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

