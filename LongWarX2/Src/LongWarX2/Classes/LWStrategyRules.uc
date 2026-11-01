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
var config int StartingPanicChunks;
var config int PanicUfoIgnored, PanicAirRaid, PanicUfoShotDown, PanicUfoAssault, PanicUfoEscaped;
var config int PanicSatAddedCountry, PanicSatAddedContinent, PanicSatDestroyedCountry, PanicSatDestroyedContinent;
var config int PanicAbductionCountry[4];
var config int PanicAbductionContinent[4];
var config int PanicAbductionThwartedCountry, PanicAbductionThwartedContinent, PanicTerrorContinent;
var config int DefectThreshold[4];
var config int DefectChancePerPoint[4];
var config int DefectionsPerMonth[4];
var config float SatHelpDefect[4];
var config float SatNearbyHelpDefect[4];
var config int SatPanicReduction[4];
var config int Panic5ReductionChance[4];
var config int Panic4ReductionChance[4];
var config int AbductionLurkPct;
var config int CrashSiteHours, LandedUfoHours, AbductionHours, TerrorHours;
var config int InterceptorDetectPct;
/** A hunting UFO's chance (%) to find a satellite over its target (Long War's UFO_FIND_SAT). */
var config int UfoFindSatPct;
var config int SatelliteCost, SatelliteDays;
var config array<LWUfoValue> Harvest;
var config array<LWUfoValue> UfoWorth;
var config array<LWPlanCell> Plan;

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

/** An objective's name, as the Geoscape shows it. */
static function string ObjectiveName(int Objective)
{
	switch (Objective)
	{
	case 0: return "Recon";
	case 1: return "Research";
	case 2: return "Harvest";
	case 4: return "Hunt";
	case 7: return "Infiltration";
	case 8: return "Air raid";
	}
	return "Unknown";
}

/**
 * The UFO an objective sends, by the aliens' research (Long War's category, about one a month).
 * APPROXIMATION: Long War chooses the ship in code not yet read (XGStrategyAI.AIAddNewObjective);
 * this picks the kind of ship Long War's UFO analyses give each mission, growing with the months.
 * Ship ids: 4 Scout, 5 Destroyer, 6 Abductor, 7 Transport, 8 Battleship, 10 Fighter, 11 Raider,
 * 12 Harvester, 13 Terror Ship, 14 Assault Carrier.
 */
static function int UfoFor(int Objective, int Category)
{
	switch (Objective)
	{
	case 0: return Category < 4 ? 4 : 10;
	case 1: return Category < 3 ? 4 : (Category < 8 ? 10 : 6);
	case 2: return Category < 3 ? 4 : (Category < 6 ? 11 : (Category < 10 ? 12 : 7));
	case 4: return Category < 5 ? 11 : 5;
	case 7: return Category < 12 ? 7 : 8;
	case 8: return Category < 6 ? 11 : (Category < 12 ? 5 : 14);
	}
	return 4;
}

/** The day of the month an objective's UFO flies (Long War's AddUFOs: 2+Rand(26), 1+Rand(27) …). */
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
 * How long a UFO is over its target, in hours. APPROXIMATION: Long War's flight plans
 * (eUM_QuickScout, eUM_LongScout, eUM_Dropoff …) are not read yet.
 */
static function int FlightHoursFor(int Objective)
{
	switch (Objective)
	{
	case 0: return 4;
	case 1: return 6;
	case 2: return 10;
	case 4: return 6;
	case 7: return 12;
	case 8: return 4;
	}
	return 6;
}

/** Whether an objective's UFO lands (a landed UFO the squad can assault). APPROXIMATION, as above. */
static function bool LandsFor(int Objective)
{
	return Objective == 2 || Objective == 7;
}
