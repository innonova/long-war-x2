// Long War's Geoscape in XCOM 2's game state (features/lw-geoscape.md): the council's countries
// with their panic, satellites and funding; the clock; the aliens' resources, aggression and this
// month's plan (UFOs, abductions, terror); what happened. Saved with the campaign. The rules are
// Long War's (LWStrategyRules, its numbers); where a rule is not read from Long War yet, the
// function says APPROXIMATION.
class XComGameState_LWStrategy extends XComGameState_BaseObject;

struct LWCountry
{
	var name Id;
	var int Panic;
	var bool bSatellite;
	var bool bLeft;
};

/** A UFO of this month. Status: 0 to come, 1 flying unseen, 2 flying detected, 3 crashed, 4 landed, 5 over. */
struct LWUfo
{
	var int Objective;
	var int Ufo;
	var int Country;
	var int Hour;
	var int Status;
	var int Hp;
	var int MaxHp;
	var int Until;
	var bool bAttacked;
};

/** An abduction or a terror site. Status: 0 to come, 1 on the map, 2 over. */
struct LWSite
{
	var bool bTerror;
	var int Country;
	var int Hour;
	var int Status;
	var int Until;
};

var array<LWCountry> Countries;
/** Hours since the campaign began; its first hour is the first of a month. */
var int Hours;
var int Month;
var int AlienResources;
var int AlienAggression;
var array<LWUfo> Ufos;
var array<LWSite> Sites;
/** Satellites built and waiting for a country, and the hours the ones in the works are ready. */
var int SatellitesReady;
var array<int> SatellitesDue;
var array<string> Events;
/** Set when something wants the player's decision: the clock stops. */
var bool bStop;
/** A mission sent from here and not yet come back: 1 crash site, 2 landed UFO, 3 abduction, 4 terror. */
var int PendingKind;
var int PendingIndex;
/** XCOM 2's mission site launched for it: its battle's result is the mission's. */
var int PendingMission;

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

	S = Get();
	if (S != none)
		return S;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the Geoscape");
	S = XComGameState_LWStrategy(NewGameState.CreateNewStateObject(class'XComGameState_LWStrategy'));
	S.Begin();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return Get();
}

/** Long War's start: the countries, their starting panic spread in chunks, one satellite at home, the first month's plan. */
function Begin()
{
	local LWStrategyRules.LWCountryDef Def;
	local LWCountry C;
	local int Points, Chunk, k, Tries;

	foreach class'LWStrategyRules'.default.Countries(Def)
	{
		C.Id = Def.Id;
		C.Panic = 0;
		C.bSatellite = false;
		C.bLeft = false;
		Countries.AddItem(C);
	}
	// Long War: the starting panic points spread at random in chunks; no country above 90.
	Points = class'LWStrategyRules'.default.StartingPanic[class'LWStrategyRules'.static.Difficulty()];
	Chunk = Max(1, Points / Max(1, class'LWStrategyRules'.default.StartingPanicChunks) / Countries.Length * 2);
	while (Points > 0 && Tries++ < 1000)
	{
		k = Rand(Countries.Length);
		if (Countries[k].Panic + Chunk > 90)
			continue;
		Countries[k].Panic += Min(Chunk, Points);
		Points -= Chunk;
	}
	// APPROXIMATION: Long War's start gives a satellite over the home country; the home country is the United States here.
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

/** Time runs hour by hour until the hours are up or something wants a decision. Returns the hours that passed. */
static function int Run(int MaxHours)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local int n;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: time passes");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.bStop = false;
	while (n < MaxHours && !S.bStop)
	{
		S.Tick();
		n++;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return n;
}

function Tick()
{
	local int i;

	Hours++;
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
 * country that has left and are kept between 9 × month and 300; their tier (resources / 50) and
 * aggression pick the month's abductions, terror missions and UFOs; aggression then falls by 2.
 */
function PlanMonth()
{
	local LWStrategyRules.LWPlanCell Cell;
	local int i, n, Tier, Start;

	AlienResources = Clamp(AlienResources + 20 * NumLeft(), 9 * Month, 300);
	Tier = Clamp(AlienResources / 50, 0, 4);
	Start = Month * HoursPerMonth();
	Ufos.Length = 0;
	Sites.Length = 0;
	if (!class'LWStrategyRules'.static.PlanFor(Tier, Clamp(AlienAggression, 0, 4), Cell))
		return;
	for (i = 0; i < Cell.Ufos.Length; i++)
		AddUfo(Cell.Ufos[i], Start);
	for (i = 0; i < Cell.MaybeUfos.Length; i++)
		if (Rand(2) == 0)
			AddUfo(Cell.MaybeUfos[i], Start);
	// Abductions: one site each, spread over the month (Long War's AddNewAbductions).
	n = Rand(2) == 0 ? Cell.Abductions : Cell.AbductionsAlt;
	for (i = 0; i < n; i++)
		AddSite(false, Start + 24 * (1 + i * (30 / n) + Rand(Max(1, 30 / n - 1))));
	for (i = 0; i < Cell.Terror; i++)
		AddSite(true, Start + 24 * (1 + Rand(23)));
	AlienAggression = Clamp(AlienAggression - 2, 0, 4);
	`log("LongWarX2: Long War month" @ Month @ "planned: resources" @ AlienResources @ "tier" @ Tier @ "aggression" @ Cell.Aggression $ ";" @ Ufos.Length @ "UFOs," @ n @ "abductions," @ Cell.Terror @ "terror", , 'LongWarX2');
}

function AddUfo(int Objective, int MonthStart)
{
	local LWUfo U;
	local LWAirWar.LWShip Ship;

	U.Objective = Objective;
	U.Ufo = class'LWStrategyRules'.static.UfoFor(Objective, Category());
	U.Country = TargetCountry();
	U.Hour = MonthStart + 24 * (class'LWStrategyRules'.static.DayFor(Objective) - 1) + Rand(24);
	Ship = class'LWAirWar'.static.Ufo(U.Ufo, Category());
	U.MaxHp = Ship.Hp;
	U.Hp = Ship.Hp;
	Ufos.AddItem(U);
}

function AddSite(bool bTerror, int Hour)
{
	local LWSite Site;

	Site.bTerror = bTerror;
	Site.Country = TargetCountry();
	Site.Hour = Hour;
	Sites.AddItem(Site);
}

/**
 * A council country still in the council. APPROXIMATION: Long War weighs targets by panic, coverage
 * and the AI's objectives (DetermineBestVisibleTargets, AI_TERRORIZE_MOST_PANICKED); not read yet.
 */
function int TargetCountry()
{
	local int k, Tries;

	do
		k = Rand(Countries.Length);
	until (!Countries[k].bLeft || Tries++ > 50);
	return k;
}

/** The aliens' research for the air war: Long War's category, about one a month. */
function int Category()
{
	return Month;
}

// --- UFOs -----------------------------------------------------------------------------------

function TickUfo(int i)
{
	local int Continent;

	switch (Ufos[i].Status)
	{
	case 0:
		if (Hours < Ufos[i].Hour)
			return;
		Ufos[i].Until = Hours + class'LWStrategyRules'.static.FlightHoursFor(Ufos[i].Objective);
		Ufos[i].Status = 1;
		// Detected by a satellite over the country, or by chance by a jet on the continent.
		if (Countries[Ufos[i].Country].bSatellite || Rand(100) < class'LWStrategyRules'.default.InterceptorDetectPct * JetsOn(CountryContinent(Ufos[i].Country)))
		{
			Ufos[i].Status = 2;
			Note("UFO detected over" @ CountryName(Ufos[i].Country) $ ":" @ ShipName(Ufos[i].Ufo) $ "," @ class'LWStrategyRules'.static.ObjectiveName(Ufos[i].Objective) $ ".");
			bStop = true;
		}
		return;
	case 1:
	case 2:
		if (Hours < Ufos[i].Until)
			return;
		if (Ufos[i].Status == 2 && class'LWStrategyRules'.static.LandsFor(Ufos[i].Objective))
		{
			Ufos[i].Status = 4;
			Ufos[i].Until = Hours + class'LWStrategyRules'.default.LandedUfoHours;
			Note("The" @ ShipName(Ufos[i].Ufo) @ "has landed in" @ CountryName(Ufos[i].Country) $ ". It leaves in" @ class'LWStrategyRules'.default.LandedUfoHours @ "hours.");
			bStop = true;
			return;
		}
		UfoDone(i);
		return;
	case 3:
	case 4:
		if (Hours < Ufos[i].Until)
			return;
		Continent = Ufos[i].Status;
		Ufos[i].Status = 5;
		AddPanic(Ufos[i].Country, class'LWStrategyRules'.default.PanicUfoEscaped);
		Note((Continent == 3 ? "The crash site" : "The landed UFO") @ "in" @ CountryName(Ufos[i].Country) @ "is gone.");
		return;
	}
}

/**
 * A UFO's mission done: Long War's panic for a mission not attacked (an air raid's own, larger),
 * reduced in proportion to the damage it took; a harvest brings the aliens resources; a hunt may
 * find the country's satellite.
 */
function UfoDone(int i)
{
	local int Panic;
	local float Intact;

	Ufos[i].Status = 5;
	Intact = Ufos[i].MaxHp > 0 ? float(Ufos[i].Hp) / float(Ufos[i].MaxHp) : 1.0;
	Panic = Ufos[i].Objective == 8 ? class'LWStrategyRules'.default.PanicAirRaid + class'LWStrategyRules'.default.PanicUfoIgnored : class'LWStrategyRules'.default.PanicUfoIgnored;
	AddPanic(Ufos[i].Country, Round(Panic * Intact));
	if (Ufos[i].Objective == 2)
		AlienResources += class'LWStrategyRules'.static.HarvestOf(Ufos[i].Ufo);
	if (Ufos[i].Objective == 4 && Countries[Ufos[i].Country].bSatellite && Rand(100) < class'LWStrategyRules'.default.UfoFindSatPct)
	{
		Countries[Ufos[i].Country].bSatellite = false;
		AddPanic(Ufos[i].Country, class'LWStrategyRules'.default.PanicSatDestroyedCountry);
		AddContinentPanic(CountryContinent(Ufos[i].Country), class'LWStrategyRules'.default.PanicSatDestroyedContinent);
		Note("A satellite over" @ CountryName(Ufos[i].Country) @ "was destroyed.");
		bStop = true;
	}
	if (Ufos[i].bAttacked || Ufos[i].Status == 2)
		Note("The" @ ShipName(Ufos[i].Ufo) @ "over" @ CountryName(Ufos[i].Country) @ "finished its mission.");
}

/**
 * An interception's result for a detected UFO (Long War's XGStrategyAI.OnUFOAttacked and friends):
 * the aliens lose resources in proportion to the damage; shot down, their aggression rises (more for
 * the large ships) and the country's panic falls; a crash site lasts Long War's crash timer.
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
	S.AlienResources -= Round(class'LWStrategyRules'.static.WorthOf(U.Ufo) * (1.0 - float(Max(0, UfoHp)) / float(Max(1, U.MaxHp))));
	U.Hp = Max(0, UfoHp);
	if (Outcome == 0 || Outcome == 1) // crashed or destroyed
	{
		S.AlienAggression += 1;
		if (U.Ufo == 7 || U.Ufo == 8 || U.Ufo == 9 || U.Ufo == 13 || U.Ufo == 14)
			S.AlienAggression += 1;
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
		S.Note("The" @ S.ShipName(U.Ufo) @ "got away, damaged" @ (100 - 100 * U.Hp / Max(1, U.MaxHp)) $ "%.");
	S.Ufos[i] = U;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// --- Abductions and terror -----------------------------------------------------------------

function TickSite(int i)
{
	if (Sites[i].Status == 0 && Hours >= Sites[i].Hour)
	{
		Sites[i].Status = 1;
		Sites[i].Until = Hours + (Sites[i].bTerror ? class'LWStrategyRules'.default.TerrorHours : class'LWStrategyRules'.default.AbductionHours);
		Note((Sites[i].bTerror ? "Terror in" : "Abductions in") @ CountryName(Sites[i].Country) $ ". XCOM has" @ (Sites[i].Until - Hours) @ "hours.");
		bStop = true;
	}
	else if (Sites[i].Status == 1 && Hours >= Sites[i].Until)
	{
		Sites[i].Status = 2;
		SiteIgnored(i);
	}
}

/** Long War's panic for an abduction or terror site XCOM did not answer. */
function SiteIgnored(int i)
{
	local int d;

	d = class'LWStrategyRules'.static.Difficulty();
	if (Sites[i].bTerror)
	{
		AddContinentPanic(CountryContinent(Sites[i].Country), class'LWStrategyRules'.default.PanicTerrorContinent);
		Note("Terror in" @ CountryName(Sites[i].Country) @ "went unanswered.");
	}
	else
	{
		AddPanic(Sites[i].Country, class'LWStrategyRules'.default.PanicAbductionCountry[d]);
		AddContinentPanic(CountryContinent(Sites[i].Country), class'LWStrategyRules'.default.PanicAbductionContinent[d]);
		Note("The abductions in" @ CountryName(Sites[i].Country) @ "went unanswered.");
	}
}

// --- Missions sent from here -------------------------------------------------------------

/** A mission is sent to a crash site (1), landed UFO (2), abduction (3) or terror site (4). */
static function MissionSent(int Kind, int Index)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a mission sent");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	S.PendingKind = Kind;
	S.PendingIndex = Index;
	if (Kind <= 2)
		S.Ufos[Index].Status = 5;
	else
		S.Sites[Index].Status = 2;
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
	local int Country;

	if (Get() == none || Get().PendingKind == 0)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a mission back");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', Get().ObjectID));
	Country = S.PendingKind <= 2 ? S.Ufos[S.PendingIndex].Country : S.Sites[S.PendingIndex].Country;
	if (S.PendingKind <= 2)
		S.AddPanic(Country, bWon ? class'LWStrategyRules'.default.PanicUfoAssault : class'LWStrategyRules'.default.PanicUfoEscaped);
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
 * The council's report: Long War's funding (each country's amount × FundingBalance; a country without
 * a satellite gives BASE_FUNDING% of it), the satellites' panic relief (a chance by panic level), the
 * defection rolls above the threshold (a chance per panic point, lessened by a satellite over the
 * country or the continent); then the next month's plan.
 */
function EndMonth()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local LWStrategyRules.LWCountryDef Def;
	local int i, d, Funding, Chance, Left, Threshold;
	local float Help;
	local string Report;

	d = class'LWStrategyRules'.static.Difficulty();
	for (i = 0; i < Countries.Length; i++)
	{
		if (Countries[i].bLeft)
			continue;
		Def = class'LWStrategyRules'.default.Countries[i];
		Funding += Round(Def.Funding * class'LWStrategyRules'.default.FundingBalance[d] * (Countries[i].bSatellite ? 1.0 : class'LWStrategyRules'.default.BaseFundingPct[d] / 100.0));
		if (Countries[i].bSatellite)
		{
			Chance = Countries[i].Panic >= 95 ? class'LWStrategyRules'.default.Panic5ReductionChance[d] : (Countries[i].Panic >= 80 ? class'LWStrategyRules'.default.Panic4ReductionChance[d] : 0);
			if (Rand(100) < Chance)
				AddPanic(i, -class'LWStrategyRules'.default.SatPanicReduction[d]);
		}
	}
	Threshold = class'LWStrategyRules'.default.DefectThreshold[d];
	for (i = 0; i < Countries.Length && Left < class'LWStrategyRules'.default.DefectionsPerMonth[d]; i++)
	{
		if (Countries[i].bLeft || Countries[i].Panic < Threshold)
			continue;
		Help = Countries[i].bSatellite ? class'LWStrategyRules'.default.SatHelpDefect[d] : (ContinentHasSatellite(CountryContinent(i)) ? class'LWStrategyRules'.default.SatNearbyHelpDefect[d] : 1.0);
		// APPROXIMATION: Long War's exact roll (XGFundingCouncil) not read yet: per panic point at the threshold and above.
		if (Rand(100) < Round((Countries[i].Panic - Threshold + 1) * class'LWStrategyRules'.default.DefectChancePerPoint[d] * Help * 10))
		{
			Countries[i].bLeft = true;
			Countries[i].bSatellite = false;
			Left++;
			Report @= CountryName(i) @ "has left the council.";
		}
	}
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(GetParentGameState().ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.AddResource(GetParentGameState(), 'Supplies', Funding);
	Note("Council report: funding $" $ Funding $ "." $ Report);
	`log("LongWarX2: Long War month" @ Month @ "ended: funding" @ Funding @ "countries left" @ NumLeft(), , 'LongWarX2');
	Month++;
	PlanMonth();
	bStop = true;
}

// --- Helpers ------------------------------------------------------------------------------

function AddPanic(int Country, int Amount)
{
	if (Country < 0 || Country >= Countries.Length || Countries[Country].bLeft)
		return;
	Countries[Country].Panic = Clamp(Countries[Country].Panic + Amount, 0, 100);
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

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	return (AirWar != none && Continent == 0) ? AirWar.Jets.Length : 0;
}

function string ShipName(int Ufo)
{
	return class'LWAirWar'.static.Ufo(Ufo, Category()).Name;
}

function Note(string Text)
{
	Events.AddItem("Day" @ DayOfMonth() $ "," @ (HourOfDay() < 10 ? "0" : "") $ HourOfDay() $ ":00 -" @ Text);
	if (Events.Length > 40)
		Events.Remove(0, Events.Length - 40);
	`log("LongWarX2: Geoscape:" @ Text, , 'LongWarX2');
}
