// EXALT (features/lw-exalt.md), Long War's XGExaltSimulation on the Long War Geoscape: from the third month EXALT has a
// base in a council country and places cells in others, which steal money, raise panic and set research back, exposing
// themselves for a few days when they act; XCOM scans to expose them all, and gathers clues to accuse the right country.
// Its state is on XComGameState_LWStrategy (Exalt*); Long War's numbers by difficulty and its clues are generated from the
// package's defaults (scripts/strategy-config.mjs, [LongWarX2.LWExalt]).
class LWExalt extends Object config(LWStrategy);

struct LWExaltTuning
{
	var int StartDelay, StartDelayVariation, SweepCost;
	var float SweepIncrease;
	var int CovertDays;
	var int MinDaysBetweenCellOperations, MinDaysBetweenOperations, MaxDaysBetweenOperations;
	var int MinDaysToHide, MaxDaysToHide, MinDaysBetweenCells, MaxDaysBetweenCells, MaxCells;
	var int MinResearchHackDays;
	var float ResearchHackShare;
	var float PlaceChance, PlaceSatellite, PlaceStealthSatellite;
	var array<float> PanicScore;
	var float CountryLeftScore, SatelliteScore, HomeScore, NoCellsScore, OnlyOneLeftScore, ContinentLeftScore, OnlyWithoutSatelliteScore;
};

/** A clue: the countries it rules out (Invalid), or the only ones it leaves (Valid); its words (Text) from Long War's. */
struct LWExaltClue
{
	var int Text;
	var array<name> Invalid, Valid;
};

/** A pod of EXALT's squads for covert operations (XGStrategyAI.DetermineCovertOpsSquad): from this many such missions
 *  fought, the main soldier (Main + 0..Spread-1) and Long War's pod size (above 8, its last digit). */
struct LWCovertPod
{
	var int Missions, Main, Spread, Size;
};

var config array<LWExaltTuning> Tuning;
var config array<LWExaltClue> Clues;
var config array<LWCovertPod> CovertPods;
/** EXALT's squad at its base (DetermineExaltRaidSquad; Missions unused). */
var config array<LWCovertPod> RaidPods;
/** What a covert mission pays (Long War's CollectLoot): the extraction won; the data recovery with its first point safe. */
var config int CovertCash, DataRecoveryCash;
/** Long War's clue texts (XGExaltSimulation.m_arrClueText), written from the player's install (lw-words.mjs). */
var localized string ClueTexts[40];

/** Clues XCOM needs before it may accuse a country (Long War's XGInfiltratorSitRoomUI: three). */
const CLUES_TO_ACCUSE = 3;

/** Simulation states (Long War's EExaltSimulationState). */
const NOT_BEGUN = 0;
const STARTING = 1;
const ACTIVE = 2;
const ENDED = 3;

/** Long War's Foundry project Stealth Satellites (placement is harder under them). */
const FOUNDRY_STEALTH_SATELLITES = 17;
/** Long War's laboratory (each takes a fifth off a research hack). */
const FACILITY_LAB = 7;

static function LWExaltTuning Tune()
{
	return default.Tuning[Clamp(class'LWStrategyRules'.static.Difficulty(), 0, default.Tuning.Length - 1)];
}

static function bool IsActive(XComGameState_LWStrategy S)
{
	return S.ExaltState == ACTIVE;
}

/** Each hour (XComGameState_LWStrategy.Tick): begun in the third month (Long War's GetMonth() > 1: months passed); a day
 *  passed every 24 hours. */
static function Hour(XComGameState NewGameState, XComGameState_LWStrategy S)
{
	if (default.Tuning.Length == 0)
		return;
	if (S.ExaltState == NOT_BEGUN)
	{
		// (United Humanity, second wave #23, XGExaltSimulation.BeginSimulation: EXALT never begins.)
		if (S.Month > 1 && !class'LWX2SecondWave'.static.On(23))
			Begin(S);
		return;
	}
	if (S.ExaltState == ENDED)
		return;
	// The extraction not answered in time: the operative is lost (Long War's OnMissionExpire).
	if (S.ExaltMissionUntil > 0 && S.Hours >= S.ExaltMissionUntil && S.PendingKind != 8)
		OperativeLost(NewGameState, S);
	if (S.Hours % 24 != 12)
		return;
	S.bExaltSweepAllowed = true;
	DayForOperative(S);
	if (S.ExaltOperative <= 0)
		DayForExalt(NewGameState, S);
}

/** Long War's BeginSimulation: EXALT's country (a council country), its clues, the delay before its first cells. */
static function Begin(XComGameState_LWStrategy S)
{

	S.ExaltCountry = Rand(S.Countries.Length);
	SelectClues(S);
	S.ExaltCooldown = Tune().StartDelay + Rand(Tune().StartDelayVariation);
	S.ExaltState = STARTING;
	`log("LongWarX2: EXALT: begun, its base in" @ S.CountryName(S.ExaltCountry) $ "," @ S.ExaltClues.Length @ "clues; cells in" @ S.ExaltCooldown @ "days", , 'LongWarX2');
}

/** Long War's NextDayForOperative: on the last day, the mission to extract the operative (96 hours to answer). */
static function DayForOperative(XComGameState_LWStrategy S)
{
	if (S.ExaltOperative <= 0 || S.ExaltOperativeDays <= 0)
		return;
	if (S.ExaltOperativeDays == 1)
	{
		// Which mission (CreateNextMission): the kind not offered yet, else either at even odds.
		if (S.bExaltOfferedRecovery && !S.bExaltOfferedExtraction)
			S.ExaltMissionKind = 1;
		else if (!S.bExaltOfferedRecovery && S.bExaltOfferedExtraction)
			S.ExaltMissionKind = 2;
		else
			S.ExaltMissionKind = 1 + Rand(2);
		if (S.ExaltMissionKind == 2)
			S.bExaltOfferedRecovery = true;
		else
			S.bExaltOfferedExtraction = true;
		S.ExaltMissionUntil = S.Hours + 96;
		S.Note("Our covert operative in" @ S.CountryName(S.ExaltOperativeCountry) @ "is ready for extraction.");
		S.bStop = true;
	}
	S.ExaltOperativeDays--;
}

/** Long War's NextDayForExalt. */
static function DayForExalt(XComGameState NewGameState, XComGameState_LWStrategy S)
{
	local int i;

	if (S.ExaltState == STARTING)
	{
		if (--S.ExaltCooldown > 0)
			return;
		S.ExaltState = ACTIVE;
		PlaceNextCell(S, true);
		PlaceNextCell(S, true);
		if (S.ExaltCells.Length > 0)
			PerformRandomOperation(NewGameState, S, S.ExaltCells[0].Country);
		return;
	}
	if (--S.ExaltCooldown <= 0)
		PlaceNextCell(S);
	S.ExaltDaysSinceOperation++;
	for (i = 0; i < S.ExaltCells.Length; i++)
	{
		if (S.ExaltCells[i].DaysUntilHidden <= 0)
		{
			S.ExaltCells[i].DaysUntilNextActivity = Max(0, S.ExaltCells[i].DaysUntilNextActivity - 1);
			if (S.ExaltCells[i].DaysUntilNextActivity == 0 && S.ExaltDaysSinceOperation > Tune().MinDaysBetweenCellOperations)
			{
				PerformRandomOperation(NewGameState, S, S.ExaltCells[i].Country);
				// (The cell may have moved: the list changed under the loop.)
				if (i < S.ExaltCells.Length)
					S.ExaltCells[i].DaysUntilNextActivity = Between(Tune().MinDaysBetweenOperations, Tune().MaxDaysBetweenOperations);
			}
		}
		else if (--S.ExaltCells[i].DaysUntilHidden == 0)
			S.Note("The EXALT cell in" @ S.CountryName(S.ExaltCells[i].Country) @ "has gone back into hiding.");
	}
}

static function int Between(int Lo, int Hi)
{
	return Lo + Rand(Max(1, Hi - Lo + 1));
}

static function int CellIndex(XComGameState_LWStrategy S, int Country)
{
	local int i;

	for (i = 0; i < S.ExaltCells.Length; i++)
		if (S.ExaltCells[i].Country == Country)
			return i;
	return INDEX_NONE;
}

static function bool HasCell(XComGameState_LWStrategy S, int Country)
{
	return IsActive(S) && CellIndex(S, Country) != INDEX_NONE;
}

static function bool IsExposed(XComGameState_LWStrategy S, int Country)
{
	local int i;

	i = IsActive(S) ? CellIndex(S, Country) : INDEX_NONE;
	return i != INDEX_NONE && S.ExaltCells[i].DaysUntilHidden > 0;
}

/** Council countries of a continent still in XCOM. */
static function int RemainingOn(XComGameState_LWStrategy S, int Continent)
{
	local int i, n;

	for (i = 0; i < S.Countries.Length; i++)
		if (S.CountryContinent(i) == Continent && !S.Countries[i].bLeft)
			n++;
	return n;
}

static function int SatellitesOn(XComGameState_LWStrategy S, int Continent)
{
	local int i, n;

	for (i = 0; i < S.Countries.Length; i++)
		if (S.CountryContinent(i) == Continent && S.Countries[i].bSatellite)
			n++;
	return n;
}

static function int CellsOn(XComGameState_LWStrategy S, int Continent)
{
	local int i, n;

	for (i = 0; i < S.ExaltCells.Length; i++)
		if (S.CountryContinent(S.ExaltCells[i].Country) == Continent)
			n++;
	return n;
}

/** Long War's ScoreCountryForCellPlacementAttempt. */
static function float Score(XComGameState_LWStrategy S, int Country)
{
	local LWExaltTuning T;
	local float F;
	local int Continent, Remaining;

	T = Tune();
	Continent = S.CountryContinent(Country);
	Remaining = RemainingOn(S, Continent);
	F = T.PanicScore[Clamp(S.Countries[Country].Panic / 20, 0, 4)];
	if (CellsOn(S, Continent) == 0)
		F += T.NoCellsScore;
	if (Remaining == 0)
		F += T.ContinentLeftScore;
	else if (S.Countries[Country].bLeft)
		F += T.CountryLeftScore;
	else if (Remaining == 1)
		F += T.OnlyOneLeftScore;
	if (S.Countries[Country].bSatellite)
		F += T.SatelliteScore;
	else if (SatellitesOn(S, Continent) == 1)
		F += T.OnlyWithoutSatelliteScore;
	if (Continent == S.CountryContinent(S.HomeCountry()))
		F += T.HomeScore;
	return F;
}

/** Long War's SelectCountryForCellPlacementAttempt: each country without a cell kept with chance by its score. */
static function int SelectCountry(XComGameState_LWStrategy S)
{
	local int i, Selected;
	local float Total, F;

	Selected = INDEX_NONE;
	for (i = 0; i < S.Countries.Length; i++)
	{
		if (CellIndex(S, i) != INDEX_NONE)
			continue;
		F = Score(S, i);
		if (F <= 0)
			continue;
		Total += F;
		if (FRand() < F / Total)
			Selected = i;
	}
	return Selected != INDEX_NONE ? Selected : Rand(S.Countries.Length);
}

/** Long War's PlaceNextCell (with the dice unless forced). */
static function PlaceNextCell(XComGameState_LWStrategy S, optional bool bForce)
{
	local XComGameState_LWStrategy.LWExaltCell Cell;
	local LWExaltTuning T;
	local int Country;
	local float Chance;

	T = Tune();
	if (!IsActive(S) || S.ExaltCells.Length >= T.MaxCells)
		return;
	Country = SelectCountry(S);
	if (CellIndex(S, Country) == INDEX_NONE)
	{
		Chance = T.PlaceChance;
		if (S.Countries[Country].bSatellite)
			Chance += class'LWAirWar'.static.FoundryDone(FOUNDRY_STEALTH_SATELLITES) ? T.PlaceStealthSatellite : T.PlaceSatellite;
		if (bForce || FRand() < Chance)
		{
			Cell.Country = Country;
			Cell.DaysUntilNextActivity = Between(T.MinDaysBetweenOperations, T.MaxDaysBetweenOperations);
			S.ExaltCells.AddItem(Cell);
			`log("LongWarX2: EXALT: a cell placed in" @ S.CountryName(Country), , 'LongWarX2');
		}
	}
	S.ExaltCooldown = Between(T.MinDaysBetweenCells, T.MaxDaysBetweenCells);
}

/** Long War's ExposeCell: shown for some days (a day count already running is not renewed). */
static function Expose(XComGameState_LWStrategy S, int Country)
{
	local int i;

	i = CellIndex(S, Country);
	if (i == INDEX_NONE || S.ExaltCells[i].DaysUntilHidden > 0)
		return;
	S.ExaltCells[i].DaysUntilHidden = Between(Tune().MinDaysToHide, Tune().MaxDaysToHide);
}

/** Long War's RelocateCell: removed, and another placed at once. */
static function Relocate(XComGameState_LWStrategy S, int Country)
{
	local int i;

	i = CellIndex(S, Country);
	if (i == INDEX_NONE)
		return;
	S.ExaltCells.Remove(i, 1);
	S.Note("The EXALT cell in" @ S.CountryName(Country) @ "has moved.");
	PlaceNextCell(S, true);
}

/** Long War's PerformRandomOperation: what the cell can do (GetPossibleOperationTypes), one at random; nothing: it moves. */
static function PerformRandomOperation(XComGameState NewGameState, XComGameState_LWStrategy S, int Country)
{
	local array<int> Kinds;

	if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() >= 0)
		Kinds.AddItem(1);
	if (!S.Countries[Country].bLeft)
		Kinds.AddItem(2);
	if (ResearchDone(NewGameState) > Tune().ResearchHackShare)
		Kinds.AddItem(3);
	if (Kinds.Length == 0)
	{
		Relocate(S, Country);
		return;
	}
	switch (Kinds[Rand(Kinds.Length)])
	{
	case 1: Sabotage(NewGameState, S, Country); break;
	case 2: Propaganda(S, Country); break;
	case 3: ResearchHack(NewGameState, S, Country); break;
	}
}

/** Long War's sabotage: 40 x the month + 0..99 stolen. */
static function Sabotage(XComGameState NewGameState, XComGameState_LWStrategy S, int Country)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int Amount;

	Expose(S, Country);
	Amount = 40 * S.Month + Rand(100);
	if (Amount <= 0)
		return;
	XComHQ = HQIn(NewGameState);
	XComHQ.AddResource(NewGameState, 'Supplies', -Amount);
	S.ExaltDaysSinceOperation = 0;
	S.Note("EXALT sabotage in" @ S.CountryName(Country) $ ": XCOM lost" @ class'LWStrategyRules'.static.Money(Amount) $ ".");
}

/** Long War's propaganda: +40 panic in the country, +20 in another of its continent still in XCOM. */
static function Propaganda(XComGameState_LWStrategy S, int Country)
{
	local int i, Valid, Other;

	if (S.Countries[Country].bLeft)
		return;
	S.AddPanic(Country, 40);
	Other = INDEX_NONE;
	for (i = 0; i < S.Countries.Length; i++)
		if (i != Country && S.CountryContinent(i) == S.CountryContinent(Country) && !S.Countries[i].bLeft)
			if (Rand(++Valid) == 0)
				Other = i;
	if (Other != INDEX_NONE)
		S.AddPanic(Other, 20);
	Expose(S, Country);
	S.ExaltDaysSinceOperation = 0;
	S.Note("EXALT propaganda in" @ S.CountryName(Country) $ ": panic rises" $ (Other != INDEX_NONE ? ", and in" @ S.CountryName(Other) : "") $ ".");
}

static function XComGameState_HeadquartersXCom HQIn(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	if (XComHQ == none)
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	return XComHQ;
}

static function XComGameState_HeadquartersProjectResearch Research()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetCurrentResearchProject();
}

/** How much of the current research is done (0..1; none under way: 0). */
static function float ResearchDone(XComGameState NewGameState)
{
	local XComGameState_HeadquartersProjectResearch P;

	P = Research();
	if (P == none || P.InitialProjectPoints <= 0)
		return 0;
	return 1.0 - float(P.ProjectPointsRemaining) / float(P.InitialProjectPoints);
}

/** Long War's research hack: the larger of a share of the estimate and some days set back, at most what was done, less a
 *  fifth for each laboratory. */
static function ResearchHack(XComGameState NewGameState, XComGameState_LWStrategy S, int Country)
{
	local XComGameState_HeadquartersProjectResearch P;
	local float PerHour, Estimate, Remaining, Hacked;

	P = Research();
	if (P == none || P.InitialProjectPoints <= 0)
		return;
	PerHour = FMax(1, S.ResearchPerHour());
	Estimate = P.InitialProjectPoints / PerHour;
	Remaining = P.ProjectPointsRemaining / PerHour;
	Hacked = FMax(Estimate * Tune().ResearchHackShare, Tune().MinResearchHackDays * 24);
	Hacked = FMin(Hacked, Estimate - Remaining);
	Hacked -= Hacked * class'LWBase'.static.Count(S, FACILITY_LAB) * 0.2;
	Hacked = FMax(0, Hacked);
	P = XComGameState_HeadquartersProjectResearch(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectResearch', P.ObjectID));
	P.ProjectPointsRemaining = Min(P.InitialProjectPoints, P.ProjectPointsRemaining + Round(Hacked * PerHour));
	Expose(S, Country);
	S.ExaltDaysSinceOperation = 0;
	S.Note("EXALT hacked XCOM's research from" @ S.CountryName(Country) $ ": set back" @ Round(Hacked / 24) @ "days.");
}

/** Long War's GetPanicMod: panic rising in a country rises up to 10 more while a hidden cell is on its continent (a coin
 *  flip for each; no operative in the field). */
static function int PanicMod(XComGameState_LWStrategy S, int Country, int Base)
{
	local int i;

	if (!IsActive(S) || Base <= 0 || S.ExaltOperative > 0)
		return 0;
	for (i = 0; i < S.ExaltCells.Length; i++)
		if (S.CountryContinent(S.ExaltCells[i].Country) == S.CountryContinent(Country) && S.ExaltCells[i].DaysUntilHidden <= 0 && Rand(2) == 0)
			return Min(10, Base);
	return 0;
}

/** Long War's GetSweepCost: more each time in the month, less by the country bonus that says so (16). */
static function int SweepCost(XComGameState_LWStrategy S)
{
	local float Cost;
	local int i;

	Cost = Tune().SweepCost;
	for (i = 0; i < S.ExaltSweeps; i++)
		Cost += Cost * Tune().SweepIncrease;
	if (class'LWBonuses'.static.Has(16, S) > 0)
		Cost *= 1 - class'LWBonuses'.static.Has(16, S) / 100.0;
	return int(Cost);
}

static function bool CanSweep(XComGameState_LWStrategy S, out string Why)
{
	Why = "";
	if (!IsActive(S))
		Why = "EXALT is not active";
	else if (!S.bExaltSweepAllowed)
		Why = "a scan already today";
	if (Why == "" && class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < SweepCost(S))
		Why = class'LWStrategyRules'.static.Money(SweepCost(S));
	return Why == "";
}

/** Long War's PerformSweep: every cell exposed, paid for. */
static function bool Sweep(out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local int i, Cost;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || !CanSweep(S, Why))
		return false;
	Cost = SweepCost(S);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a scan for EXALT");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	for (i = 0; i < S.ExaltCells.Length; i++)
		Expose(S, S.ExaltCells[i].Country);
	HQIn(NewGameState).AddResource(NewGameState, 'Supplies', -Cost);
	S.ExaltSweeps++;
	S.bExaltSweepAllowed = false;
	S.Note("XCOM scanned for EXALT (" $ class'LWStrategyRules'.static.Money(Cost) $ "):" @ S.ExaltCells.Length @ (S.ExaltCells.Length == 1 ? "cell" : "cells") @ "exposed.");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

/** Pay day (Long War's PayDay): the month's scans counted again from nothing. */
static function MonthEnded(XComGameState_LWStrategy S)
{
	S.ExaltSweeps = 0;
}

/** Long War's IsCountryRuledOutByClue. */
static function bool RuledOut(XComGameState_LWStrategy S, int Country, LWExaltClue C)
{
	if (C.Valid.Length > 0)
		return C.Valid.Find(S.Countries[Country].Id) == INDEX_NONE;
	return C.Invalid.Find(S.Countries[Country].Id) != INDEX_NONE;
}

static function int RuledOutCount(XComGameState_LWStrategy S, LWExaltClue C)
{
	return C.Valid.Length > 0 ? S.Countries.Length - C.Valid.Length : C.Invalid.Length;
}

/** Long War's SelectClues: clues that leave EXALT's country, chosen weighted toward those ruling out many, each kept if it
 *  rules out another of those remaining, until one is left. */
static function SelectClues(XComGameState_LWStrategy S)
{
	local array<int> Candidates, Remaining, Kept;
	local float Weight, Total;
	local int i, Chosen, Before;

	S.ExaltClues.Length = 0;
	for (i = 0; i < default.Clues.Length; i++)
		if (!RuledOut(S, S.ExaltCountry, default.Clues[i]))
			Candidates.AddItem(i);
	for (i = 0; i < S.Countries.Length; i++)
		Remaining.AddItem(i);
	while (Candidates.Length > 0 && Remaining.Length > 1)
	{
		Chosen = 0;
		Total = 0;
		for (i = 0; i < Candidates.Length; i++)
		{
			Weight = RuledOutCount(S, default.Clues[Candidates[i]]);
			Weight += Weight * Weight * 0.2;
			Total += Weight;
			if (Total > 0 && FRand() < Weight / Total)
				Chosen = i;
		}
		Before = Remaining.Length;
		Kept.Length = 0;
		for (i = 0; i < Remaining.Length; i++)
			if (!RuledOut(S, Remaining[i], default.Clues[Candidates[Chosen]]))
				Kept.AddItem(Remaining[i]);
		Remaining = Kept;
		if (Remaining.Length < Before)
			S.ExaltClues.AddItem(Candidates[Chosen]);
		Candidates.Remove(Chosen, 1);
	}
}

/** The clues XCOM holds (as many as its EXALT intelligence). */
static function int CluesHeld(XComGameState_LWStrategy S)
{
	return Min(S.ExaltIntel, S.ExaltClues.Length);
}

static function bool RuledOutByHeldClues(XComGameState_LWStrategy S, int Country)
{
	local int i;

	for (i = 0; i < CluesHeld(S); i++)
		if (RuledOut(S, Country, default.Clues[S.ExaltClues[i]]))
			return true;
	return false;
}

/** Long War's accusation rules (XGInfiltratorSitRoomUI.UpdateCursor): EXALT active, three clues held, the country neither
 *  accused before nor ruled out by them. */
static function bool CanAccuse(XComGameState_LWStrategy S, int Country)
{
	return IsActive(S) && CluesHeld(S) >= CLUES_TO_ACCUSE && S.ExaltAccused.Find(Country) == INDEX_NONE && !RuledOutByHeldClues(S, Country);
}

/** Long War's AccuseCountry: right, the raid on EXALT's base is next (phase 4, features/lw-exalt.md); wrong, the country
 *  leaves XCOM (already gone: its continent's council countries +40 panic). */
static function bool Accuse(int Country)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || !CanAccuse(S, Country))
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: EXALT accusation");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	S.ExaltAccused.AddItem(Country);
	if (Country == S.ExaltCountry)
	{
		S.bExaltRaidReady = true;
		S.bStop = true;
		S.Note("EXALT's base is in" @ S.CountryName(Country) $ ". The raid can be launched.");
	}
	else if (S.Countries[Country].bLeft)
	{
		for (i = 0; i < S.Countries.Length; i++)
			if (S.CountryContinent(i) == S.CountryContinent(Country))
				S.AddPanic(i, 40);
		S.Note("EXALT's base is not in" @ S.CountryName(Country) $ ". Panic rises on its continent.");
	}
	else
	{
		S.Note("EXALT's base is not in" @ S.CountryName(Country) $ "; accused, it has withdrawn from XCOM.");
		S.Leave(Country);
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

/** EXALT's squad for a covert operation, by the missions of the kind fought (Long War's second table: the extraction's). */
static function array<int> CovertSquad(int Fought, int Days)
{
	local array<int> Out;
	local LWCovertPod P;
	local int Group;

	Group = -1;
	foreach default.CovertPods(P)
		if (P.Missions <= Fought && P.Missions > Group)
			Group = P.Missions;
	foreach default.CovertPods(P)
		if (P.Missions == Group)
			class'LWAlienSquads'.static.AddPod(Out, 0, P.Main + Rand(Max(1, P.Spread)), P.Size, Days);
	return Out;
}

/** Long War's IsAvailableForCovertOps: no heavy weapons class (Gunner, Rocketeer), no rookie, ready (not hurt, not
 *  resting, not training), and nobody else in the field. */
static function bool CanBeOperative(XComGameState_LWStrategy S, XComGameState_Unit Unit, out string Why)
{
	local UnitValue RestedAt;

	Why = "";
	if (Unit == none || !Unit.IsSoldier() || Unit.IsRobotic())
		Why = "not a soldier";
	else if (S.ExaltOperative > 0)
		Why = "an operative is in the field";
	else if (Unit.GetSoldierClassTemplateName() == 'LWS_Gunner' || Unit.GetSoldierClassTemplateName() == 'LWS_Rocketeer')
		Why = "Gunners and Rocketeers are not eligible";
	else if (Unit.GetRank() == 0)
		Why = "rookies are not eligible";
	else if (Unit.GetStatus() != eStatus_Active || Unit.IsInjured() || !Unit.CanGoOnMission())
		Why = "not ready";
	else if (Unit.GetUnitValue('LWX2RestedAt', RestedAt) && int(RestedAt.fValue) > S.Hours)
		Why = "resting";
	else if (S.InPsiTraining(Unit.ObjectID))
		Why = "in psi training";
	return Why == "";
}

/** Long War's SetCovertOperative: the soldier sent into a country with a cell, away for its days, their gear released. */
static function bool SendOperative(int UnitID, int Country, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;

	S = class'XComGameState_LWStrategy'.static.Get();
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (S == none || !HasCell(S, Country))
	{
		Why = "no EXALT cell there";
		return false;
	}
	if (!CanBeOperative(S, Unit, Why))
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a covert operative sent");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitID));
	Unit.SetStatus(eStatus_CovertAction);
	Unit.MakeItemsAvailable(NewGameState, true);
	S.ExaltOperative = UnitID;
	S.ExaltOperativeCountry = Country;
	S.ExaltOperativeDays = Tune().CovertDays;
	S.Note(Unit.GetName(eNameType_FullNick) @ "infiltrates the EXALT cell in" @ S.CountryName(Country) $ ": ready in" @ S.ExaltOperativeDays @ "days.");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

/** The operative into the mission's squad: on duty again, their gear back (Long War sends them with what they had). */
static function XComGameState_Unit OperativeForMission(XComGameState NewGameState)
{
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.ExaltOperative <= 0)
		return none;
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', S.ExaltOperative));
	if (Unit.GetStatus() == eStatus_CovertAction)
	{
		Unit.SetStatus(eStatus_Active);
		Unit.EquipOldItems(NewGameState);
	}
	return Unit;
}

/** Long War's ClearOperative: the operative back on duty (their gear back), the operation over. */
static function ClearOperative(XComGameState NewGameState, XComGameState_LWStrategy S)
{
	local XComGameState_Unit Unit;

	if (S.ExaltOperative > 0)
	{
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', S.ExaltOperative));
		if (Unit != none && Unit.IsAlive() && Unit.GetStatus() == eStatus_CovertAction)
		{
			Unit.SetStatus(eStatus_Active);
			Unit.EquipOldItems(NewGameState);
		}
	}
	S.ExaltOperative = 0;
	S.ExaltOperativeDays = 0;
	S.ExaltMissionUntil = 0;
}

/** Long War's OnMissionExpire: the operative abandoned, to the memorial. */
static function OperativeLost(XComGameState NewGameState, XComGameState_LWStrategy S)
{
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersXCom XComHQ;

	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', S.ExaltOperative));
	if (Unit != none)
	{
		Unit.SetCurrentStat(eStat_HP, 0);
		Unit.m_strCauseOfDeath = "Covert Infiltration - Abandoned";
		Unit.m_strKIAOp = "Covert Infiltration";
		XComHQ = HQIn(NewGameState);
		XComHQ.RemoveFromCrew(Unit.GetReference());
		XComHQ.DeadCrew.AddItem(Unit.GetReference());
		S.Note("The extraction in" @ S.CountryName(S.ExaltOperativeCountry) @ "went unanswered:" @ Unit.GetName(eNameType_FullNick) @ "is lost.");
	}
	S.ExaltOperative = 0;
	S.ExaltOperativeDays = 0;
	S.ExaltMissionUntil = 0;
}

/** Long War's ClearCell: the cell gone; every other exposed one moves (each placed anew at once). */
static function ClearCell(XComGameState_LWStrategy S, int Country)
{
	local int i, Moved;

	i = CellIndex(S, Country);
	if (i != INDEX_NONE)
		S.ExaltCells.Remove(i, 1);
	for (i = S.ExaltCells.Length - 1; i >= 0; i--)
		if (S.ExaltCells[i].DaysUntilHidden > 0)
		{
			S.ExaltCells.Remove(i, 1);
			Moved++;
		}
	for (i = 0; i < Moved; i++)
		PlaceNextCell(S, true);
}

/** Long War's PostCombat for a covert operation: won, the cell cleared, the country 20 panic less, the intel brought home
 *  (a clue); lost, the cell moves. The operative comes back either way. */
static function CovertMissionBack(XComGameState NewGameState, XComGameState_LWStrategy S, bool bWon)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int Country, Cash;

	Country = S.ExaltOperativeCountry;
	S.ExaltMissionsFought++;
	if (bWon)
	{
		ClearCell(S, Country);
		S.AddPanic(Country, -20);
		S.ExaltIntel++;
		S.Note("The covert operation in" @ S.CountryName(Country) @ "succeeded: the EXALT cell is gone, and the operative brought intel home.");
		// (CollectLoot: the extraction's cash, or the data recovery's with its first area held, on EW's map where they are played.)
		Cash = S.ExaltMissionKind == 2 ? (S.bPendingAreaLost ? 0 : default.DataRecoveryCash) : default.CovertCash;
		if (S.PendingEWMap != "" && Cash > 0)
		{
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
			if (XComHQ == none)
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
			XComHQ.AddResource(NewGameState, 'Supplies', Cash);
			S.Note("The" @ (S.ExaltMissionKind == 2 ? "data recovery" : "extraction") @ "brought" @ class'LWStrategyRules'.static.Money(Cash) @ "home.");
		}
	}
	else
	{
		Relocate(S, Country);
		S.Note("The covert operation in" @ S.CountryName(Country) @ "failed.");
	}
	ClearOperative(NewGameState, S);
}

/** EXALT's squad at its base (Long War's DetermineExaltRaidSquad). */
static function array<int> RaidSquad(int Days)
{
	local array<int> Out;
	local LWCovertPod P;

	foreach default.RaidPods(P)
		class'LWAlienSquads'.static.AddPod(Out, 0, P.Main + Rand(Max(1, P.Spread)), P.Size, Days);
	return Out;
}

/** Long War's PostCombat for the raid: won, EXALT is finished (EndSimulation); lost, EXALT's country leaves XCOM (gone
 *  already: its continent +40 panic), and the raid can be tried again (the base stays exposed). */
static function RaidBack(XComGameState NewGameState, XComGameState_LWStrategy S, bool bWon)
{
	local int i;

	if (bWon)
	{
		S.ExaltState = ENDED;
		S.bExaltRaidReady = false;
		S.ExaltCells.Length = 0;
		ClearOperative(NewGameState, S);
		S.Note("The raid on EXALT's base in" @ S.CountryName(S.ExaltCountry) @ "succeeded: EXALT is finished.");
		return;
	}
	if (S.Countries[S.ExaltCountry].bLeft)
	{
		for (i = 0; i < S.Countries.Length; i++)
			if (S.CountryContinent(i) == S.CountryContinent(S.ExaltCountry))
				S.AddPanic(i, 40);
		S.Note("The raid on EXALT's base failed: panic rises on its continent.");
	}
	else
	{
		S.Note("The raid on EXALT's base failed:" @ S.CountryName(S.ExaltCountry) @ "has withdrawn from XCOM.");
		S.Leave(S.ExaltCountry);
	}
}

/** The extraction not sent after all (squad select backed out of): the operative away again, their gear released. */
static function OperativeBackInField(XComGameState NewGameState, XComGameState_LWStrategy S)
{
	local XComGameState_Unit Unit;

	if (S.ExaltOperative <= 0)
		return;
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', S.ExaltOperative));
	if (Unit != none && Unit.IsAlive() && Unit.GetStatus() == eStatus_Active)
	{
		Unit.SetStatus(eStatus_CovertAction);
		Unit.MakeItemsAvailable(NewGameState, true);
	}
}
