// Long War 1.0's strategic numbers (features/lw-geoscape.md), generated from Long War's
// DefaultGameCore.ini and XComStrategyGame.upk by scripts/strategy-config.mjs: the council
// countries, panic, funding, defections, mission timers, the aliens' monthly plan. Arrays are by
// XCOM 2 difficulty (Long War's Normal, Classic, Brutal, Impossible).
class LWStrategyRules extends Object config(LWStrategy);

struct LWCountryDef
{
	var name Id;
	var string Name;
	var int Continent;
	var int Funding;
	var int StartingCash;
	/** The staff it sends each month while a satellite watches it (ContBalance_Easy). */
	var int Scientists;
	var int Engineers;
	/** The countries the aliens turn to when this one has left (Long War's DetermineBestTerrorTarget). */
	var array<name> Neighbours;
};

/**
 * One UFO of an objective (Long War's XGStrategyAI.BuildObjectives, AddUFOMission): the day after
 * the objective's start it launches, give or take RandDays; its ship (-1: the one the plan chose);
 * its flight (Long War's EUFOMission, XGAlienObjective.GetFlightPlan): 0 lands for a while (the
 * specimen flights), 1 circles the country for SpendHours and leaves (scout, seek), 2 flies over
 * and leaves (drop-off), 3 touches down and so completes its objective (direct).
 */
struct LWPhase
{
	var int Day;
	var int RandDays;
	var int Ship;
	var int Flight;
	var int SpendHours;
};

struct LWPlanCell
{
	var int Tier;
	var int Aggression;
	var int Abductions;
	var int AbductionsAlt;
	var int Terror;
	var array<int> Ufos;
	var array<int> MaybeUfos;
	/** From month 4 the aliens may go for XCOM's headquarters (every third such month). */
	var bool HQAssault;
};

struct LWUfoValue
{
	var int Ufo;
	var int Resources;
};

var config array<LWCountryDef> Countries;
var config float FundingBalance[4];
var config float StartingCashBalance[4];
var config int BaseFundingPct[4];
var config int StartingPanic[4];
var config int StartingPanicStep;
var config int PanicUfoIgnored, PanicAirRaid, PanicUfoShotDown, PanicUfoAssault, PanicUfoEscaped;
var config int PanicSatAddedCountry, PanicSatAddedContinent, PanicSatDestroyedCountry, PanicSatDestroyedContinent;
var config int PanicAbductionCountry[4];
var config int PanicAbductionContinent[4];
var config int PanicAbductionThwartedCountry, PanicAbductionThwartedContinent, PanicTerrorContinent;
/** Panic "blocks" (panic + 1) from which a country rolls to leave at the month's end; the same for a country XCOM left alone this month. */
var config int DefectThreshold[4];
var config int DefectNotHelpedThreshold[4];
var config int DefectChancePerPoint[4];
var config int DefectionsPerMonth[4];
var config float SatHelpDefect[4];
var config float SatNearbyHelpDefect[4];
var config int SatPanicReduction[4];
var config int Panic5ReductionChance[4];
var config int Panic4ReductionChance[4];
var config int PanicLowReductionChance[4];
var config int AbductionLurkPct;
var config int CrashSiteHours, LandedUfoHours, AbductionHours, TerrorHours;
var config int InterceptorDetectPct;
/** A hunting UFO's chance (%) to find a satellite over its target (Long War's UFO_FIND_SAT). */
var config int UfoFindSatPct;
/** The same for a country hunted before (UFO_SECOND_PASS_FIND_SAT). */
var config int UfoSecondPassFindSatPct;
/** An alien base taken: the country back at 98 panic plus this, its continent this (features/lw-story.md). */
var config int PanicAlienBaseCountry;
var config int PanicAlienBaseContinent;
/** The same once the Foundry's Stealth Satellites are done. */
var config int UfoFindStealthSatPct;
var config int UfoSecondPassFindStealthSatPct;
/** The chance (%) a terror target is the most panicked candidate rather than one of the top three. */
var config int TerrorizeMostPanickedPct;
var config int SatelliteCost, SatelliteDays;
var config array<LWUfoValue> Harvest;
var config array<LWUfoValue> UfoWorth;
var config array<LWPlanCell> Plan;

/** A UFO's salvage (XGItemTree.DetermineShipSalvage): an artifact (or Alloys, before AlloyBalance) and how many. */
struct LWSalvage
{
	var int Ufo;
	var name Item;
	var int Count;
};
struct LWSurvive
{
	var name Item;
	var int Percent;
};
var config array<LWSalvage> Salvage;
var config float AlloyBalance[4];
var config int EleriumPerPowerSource[4];
var config float MinWreckedAlloys, MaxWreckedAlloys, MinLostWreckedElerium, MaxLostWreckedElerium;
/** Each artifact's chance (%) to come through a crash (XGStrategyAI.DetermineCrashLoot). */
var config array<LWSurvive> Survive;

/** What an alien species leaves when killed (not by an explosion): XGSummaryUI.CollectArtifactsFromDeadAliens. */
struct LWSpecies
{
	var int Char;
	var name Name;
	var name Corpse;
	var name ExtraCorpse;
	var array<int> Fragments;
	var int Elerium;
	var int Alloys;
	var int Meld;
	/** Taken alive: the captive, and its weapons intact (none: never stunned). */
	var name Captive;
	var array<name> Weapons;
};
var config array<LWSpecies> Species;
var config float FragmentBalance[4];
var config int AbductionRewardCash;
/** An alien stunned in a mission comes home as Long War's captive of this species (XCOM 2's character group). */
struct LWCaptureAs
{
	var name Group;
	var int Char;
};
var config array<LWCaptureAs> CaptureAs;
/** The campaign is lost when this many countries have left (Long War's LOSE_CONDITION_NUM_DESERTERS). */
var config int LoseCountries;

static function string ContinentName(int Continent)
{
	switch (Continent)
	{
	case 0: return "North America";
	case 1: return "South America";
	case 2: return "Europe";
	case 3: return "Asia";
	case 4: return "Africa";
	}
	return "?";
}

/** XCOM 2's difficulty (0 Rookie … 3 Legend), Long War's index for the per-difficulty arrays. */
static function int Difficulty()
{
	return Clamp(`CAMPAIGNDIFFICULTYSETTING, 0, 3);
}

static function int HarvestOf(int Ufo)
{
	local int k;

	k = default.Harvest.Find('Ufo', Ufo);
	return k == INDEX_NONE ? 0 : default.Harvest[k].Resources;
}

static function int WorthOf(int Ufo)
{
	local int k;

	k = default.UfoWorth.Find('Ufo', Ufo);
	return k == INDEX_NONE ? 0 : default.UfoWorth[k].Resources;
}

static function bool PlanFor(int Tier, int Aggression, out LWPlanCell Cell)
{
	local LWPlanCell C;

	foreach default.Plan(C)
	{
		if (C.Tier == Tier && C.Aggression == Aggression)
		{
			Cell = C;
			return true;
		}
	}
	return false;
}

/** An amount of money as the game writes it: Long War's credits sign (§, written by its code so the source stays ASCII). */
static function string Money(int Amount)
{
	return Chr(167) $ Amount;
}

/** An objective's name, as the Geoscape shows it (Long War's EAlienObjective). */
static function string ObjectiveName(int Objective)
{
	switch (Objective)
	{
	case 0: return "Recon";
	case 1: return "Scouting";
	case 2: return "Harvest";
	case 4: return "Hunt";
	case 5: return "Abduction";
	case 6: return "Terror";
	case 7: return "Infiltration";
	case 8: return "Air raid";
	case 3: return "Flyby";
	case 9: return "Assault on XCOM";
	}
	return "Unknown";
}

/**
 * The ship an objective of the monthly plan sends (Long War's XGStrategyAI.GetNumOutsiders, which
 * Long War rewrote for this): a roll below the aliens' resources / 25 (/ 18 after a year, / 10
 * after two, except harvests), at most 11, picks from the objective's list. Days: the campaign's.
 * Ship ids: 4 Scout, 5 Destroyer, 6 Abductor, 7 Transport, 8 Battleship, 9 Overseer, 10 Fighter,
 * 11 Raider, 12 Harvester, 13 Terror Ship, 14 Assault Carrier.
 */
static function int ShipFor(int Objective, int Resources, int Days)
{
	local int d, r;

	d = 25;
	if (Objective != 2)
	{
		if (Days >= 360)
			d = 18;
		if (Days >= 720)
			d = 10;
	}
	r = Clamp(Rand(Max(1, Resources / d)), 0, 11);
	switch (Objective)
	{
	case 0:
		switch (r)
		{
		case 0: case 1: case 3: return 4;
		case 2: case 5: case 6: return 11;
		case 9: case 10: return 13;
		case 11: return 14;
		}
		return 6;
	case 1:
		switch (r)
		{
		case 1: case 3: case 5: case 7: case 9: return 11;
		case 8: case 10: return 5;
		case 11: return 8;
		}
		return 4;
	case 2:
		switch (r)
		{
		case 0: case 1: return 7;
		case 4: case 9: case 10: return 11;
		case 8: case 11: return 4;
		}
		return 12;
	case 4:
		switch (r)
		{
		case 0: case 1: case 2: case 4: return 10;
		case 3: case 5: case 6: case 7: case 9: return Days < 75 ? 11 : 5;
		case 8: case 10: case 11: return Days < 75 ? 10 : 8;
		}
		return 5;
	case 8:
		switch (r)
		{
		case 0: case 1: case 3: case 8: return 10;
		case 6: case 9: case 10: case 11: return 8;
		}
		return 5;
	}
	return 4;
}

/** An objective's UFOs, in order (Long War's XGStrategyAI.BuildObjectives). */
static function Phases(int Objective, out array<LWPhase> Out)
{
	Out.Length = 0;
	switch (Objective)
	{
	case 0: // recon: a specimen flight
	case 2: // harvest
		AddPhase(Out, 0, 3, -1, 0, 0);
		break;
	case 1: AddPhase(Out, 0, 3, -1, 1, 4); break; // scouting
	case 4: AddPhase(Out, 0, 3, -1, 1, 6); break; // hunt: seek
	case 5: AddPhase(Out, 1, 0, 6, 3, 0); break; // abduction: an Abductor, direct
	case 6: // terror: a Terror Ship drops off, an Assault Carrier comes down
		AddPhase(Out, 0, 3, 13, 2, 0);
		AddPhase(Out, 5, 7, 14, 3, 0);
		break;
	case 7: // infiltration: a Battleship scouts, a Transport drops off, an Overseer comes down
		AddPhase(Out, 0, 1, 8, 1, 6);
		AddPhase(Out, 2, 1, 7, 2, 0);
		AddPhase(Out, 4, 3, 9, 3, 0);
		break;
	case 8: AddPhase(Out, 0, 5, -1, 1, 6); break; // air raid: a long scout
	case 3: AddPhase(Out, 0, 3, 9, 2, 0); break; // flyby: an Overseer passes over and leaves (eUM_Flyby), no landing
	case 9: AddPhase(Out, 2, 1, 14, 3, 0); break; // the HQ assault: an Assault Carrier comes down on XCOM (Infiltrate_1)
	}
}

static function AddPhase(out array<LWPhase> Out, int Day, int RandDays, int Ship, int Flight, int SpendHours)
{
	local LWPhase P;

	P.Day = Day;
	P.RandDays = RandDays;
	P.Ship = Ship;
	P.Flight = Flight;
	P.SpendHours = SpendHours;
	Out.AddItem(P);
}

/**
 * The hour (from the objective's start) a phase launches: Long War's ConvertDaysToTimeslices, the
 * day give or take up to RandDays, never before the start.
 */
static function int PhaseHour(int Day, int RandDays)
{
	local int HalfHours;

	HalfHours = Day * 48;
	if (RandDays > 0)
		HalfHours += Rand(RandDays * 2 * 48) - RandDays * 48;
	return Max(0, HalfHours / 2);
}

/** The day of the month an objective of the plan starts (Long War's AddUFOs: 2+Rand(26), 1+Rand(27) …). */
static function int DayFor(int Objective)
{
	switch (Objective)
	{
	case 0: return 2 + Rand(26);
	case 1: return 1 + Rand(27);
	case 2: return 1 + Rand(26);
	case 4: return 1 + Rand(27);
	case 7: return 5 + Rand(8);
	case 8: return 2 + Rand(26);
	}
	return 1 + Rand(27);
}

/**
 * The hours a UFO spends getting to its target, and leaving it, in each leg (arrival, fly-over,
 * departure). APPROXIMATION: in Long War these are flights across the globe at the ship's speed;
 * there is no globe here.
 */
static function int LegHours()
{
	return 1;
}
