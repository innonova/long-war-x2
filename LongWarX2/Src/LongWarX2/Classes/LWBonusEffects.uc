// What Long War's bonuses (LWBonuses, features/lw-startbonus.md) do where they act once: at the campaign's start
// (Long War's XGWorld.StartGame, XGFacility_Engineering.InitNewGame and GrantInitialStores, XGBase.GenerateTiles), and on
// each soldier as Long War makes it (XGFacility_Barracks.CreateSoldier: every recruit; XGStrategySoldier.SetSoldierClass:
// by the soldier's base class). The bonuses that change a rule as it is used (costs, funding, research, psi) are asked for
// where that rule is, with LWBonuses.Has.
class LWBonusEffects extends Object dependson(LWGearRules, LWBaseRules);

/** At the campaign's start, in the state that makes it (S not yet submitted). */
static function AtStart(XComGameState NewGameState, XComGameState_LWStrategy S)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWAirWar AirWar;
	local int v, i, Home;

	XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	if (XComHQ == none)
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	// Wealthy Benefactor (XGWorld.StartGame): money besides the home country's starting cash.
	v = class'LWBonuses'.static.Has(class'LWBonuses'.const.WEALTHY_BENEFACTOR, S);
	if (v > 0)
		XComHQ.AddResource(NewGameState, 'Supplies', v);
	// Foundry projects granted (XGFacility_Engineering.InitNewGame: m_arrFoundryHistory[value] = 1). Resourceful also
	// grants Advanced Salvage (39); Jai Jawan, Sukhoi Company, Their Finest Hour and For the Sake of Glory name theirs.
	GrantFoundry(S, class'LWBonuses'.static.Has(class'LWBonuses'.const.RESOURCEFUL, S));
	if (class'LWBonuses'.static.Has(class'LWBonuses'.const.RESOURCEFUL, S) > 0)
		GrantFoundry(S, 39);
	GrantFoundry(S, class'LWBonuses'.static.Has(class'LWBonuses'.const.JAI_JAWAN, S));
	GrantFoundry(S, class'LWBonuses'.static.Has(class'LWBonuses'.const.SUKHOI, S));
	GrantFoundry(S, class'LWBonuses'.static.Has(class'LWBonuses'.const.JUNGLE_SCOUTS_RIGGING, S));
	GrantFoundry(S, class'LWBonuses'.static.Has(class'LWBonuses'.const.THEIR_FINEST_HOUR, S));
	GrantFoundry(S, class'LWBonuses'.static.Has(class'LWBonuses'.const.FOR_THE_SAKE_OF_GLORY, S));
	// The jets are based on the home continent (made with the campaign, before its home was chosen); Jai Jawan adds two
	// interceptors (GrantInitialStores: eItem_Interceptor x 2).
	AirWar = class'LWHangar'.static.InState(NewGameState);
	Home = class'LWStrategyRules'.default.Countries[S.HomeCountry()].Continent;
	for (i = 0; i < AirWar.Jets.Length; i++)
		AirWar.Jets[i].Continent = Home;
	if (class'LWBonuses'.static.Has(class'LWBonuses'.const.JAI_JAWAN, S) > 0)
	{
		class'LWHangar'.static.NewJet(AirWar, 1, Home);
		class'LWHangar'.static.NewJet(AirWar, 1, Home);
	}
	// The soldiers the bonuses bring (XGFacility_Barracks.InitNewGame): Foreign Legion recruits, a Kiryu-Kai Commander
	// (a Japanese soldier of its rank, of a random base class), Cadre's four of its rank, one of each base class.
	v = class'LWBonuses'.static.Has(class'LWBonuses'.const.FOREIGN_LEGION, S);
	for (i = 0; i < v; i++)
		NewSoldier(NewGameState, XComHQ, 0, 0);
	v = class'LWBonuses'.static.Has(class'LWBonuses'.const.KIRYU_KAI, S);
	if (v > 0)
		NewSoldier(NewGameState, XComHQ, 1 + Rand(4), v, 'Country_Japan');
	v = class'LWBonuses'.static.Has(class'LWBonuses'.const.CADRE, S);
	if (v > 0)
		for (i = 1; i <= 4; i++)
			NewSoldier(NewGameState, XComHQ, i, v);
	// Ghost in the Machine's two SHIVs (XGFacility_Engineering.GrantInitialStores: eItem_SHIV x 2, made SHIVs in the barracks).
	if (class'LWBonuses'.static.Has(class'LWBonuses'.const.GHOST_IN_THE_MACHINE, S) > 0)
	{
		class'LWSHIVs'.static.AddSHIV(NewGameState, class'LWSHIVs'.default.Bodies[0].Template, S);
		class'LWSHIVs'.static.AddSHIV(NewGameState, class'LWSHIVs'.default.Bodies[0].Template, S);
	}
	for (i = 0; i < class'LWBonuses'.default.Bonuses.Length; i++)
		if (class'LWBonuses'.default.Bonuses[i].Kind == 0 && class'LWBonuses'.default.Bonuses[i].Choice == S.StartChoice
			&& class'LWBonuses'.default.Bonuses[i].Country == S.Countries[S.HomeCountry()].Id)
			S.Note("Starting bonus:" @ class'LWBonuses'.static.Text(i));
	`log("LongWarX2: bonuses: home" @ S.CountryName(S.HomeCountry()) $ ", start option" @ S.StartChoice $ "; holding:" @ JoinLines(class'LWBonuses'.static.Holding(S)), , 'LongWarX2');
}

// --- The bonuses on costs, asked for where the cost is read -------------------------------------------------------

/** A share off: Long War's "x *= 1 - bonus / 100" (truncated, as its ints are). */
static function int Off(int Amount, int Percent)
{
	return Percent > 0 ? int(Amount * (1.0 - Percent / 100.0)) : Amount;
}

/** A facility's price and upkeep (XGItemTree.GetFacility): Architects of the Future for labs and workshops, Power to the
 * People for the generators. */
static function AdjustFacility(out LWBaseRules.LWFacilityDef F)
{
	local int v;

	switch (F.Id)
	{
	case 7:
	case 8:
		v = class'LWBonuses'.static.Has(class'LWBonuses'.const.ARCHITECTS);
		break;
	case 10:
	case 15:
	case 16:
		v = class'LWBonuses'.static.Has(class'LWBonuses'.const.POWER_TO_THE_PEOPLE);
		break;
	}
	if (v > 0 && F.Cash > 0)
		F.Cash = Off(F.Cash, v);
	if (v > 0 && F.Upkeep > 0)
		F.Upkeep = Off(F.Upkeep, v);
}

/** A facility's build time in hours (XGItemTree.GetFacilityBuildTime: Baumeister takes its share off). */
static function int FacilityHours(int Days)
{
	return Off(Days * 24, class'LWBonuses'.static.Has(class'LWBonuses'.const.BAUMEISTER));
}

/** An aircraft's price or upkeep (GetItem for interceptors, Firestorms and their weapons; GetShipMaintenanceCost): Air
 * Superiority takes its share off. */
static function int AirCost(int Amount)
{
	return Off(Amount, class'LWBonuses'.static.Has(class'LWBonuses'.const.AIR_SUPERIORITY));
}

/** An item engineering builds (XGItemTree.GetItem, before the workshops' cut): Air Superiority for craft and their weapons
 * (items 103, 104, 116 to 122), NeoPanzers for SHIV and MEC primary weapons, Cyberware for MEC weapons' meld. */
static function AdjustBuild(out LWGearRules.LWBuildDef B)
{
	local int v;

	if (B.Item == 103 || B.Item == 104 || (B.Item > 115 && B.Item < 123))
	{
		v = class'LWBonuses'.static.Has(class'LWBonuses'.const.AIR_SUPERIORITY);
		B.Cash = Off(B.Cash, v);
		B.Alloys = Off(B.Alloys, v);
		B.Elerium = Off(B.Elerium, v);
	}
	switch (B.Item)
	{
	case 29: case 186: case 190: case 30: case 149: case 110: case 111: case 112:
		v = class'LWBonuses'.static.Has(class'LWBonuses'.const.NEOPANZERS);
		B.Cash = Off(B.Cash, v);
		B.Alloys = Off(B.Alloys, v);
		B.Elerium = Off(B.Elerium, v);
		break;
	}
	switch (B.Item)
	{
	case 22: case 23: case 24: case 25: case 26: case 27: case 29: case 186: case 190: case 30:
		B.Meld = Off(B.Meld, class'LWBonuses'.static.Has(class'LWBonuses'.const.CYBERWARE));
		break;
	}
}

/** A Foundry project (XGTechTree.GetFoundryTech): New Warfare takes its share off the cash, alloys and elerium. */
static function AdjustFoundry(out LWGearRules.LWFoundryDef F)
{
	local int v;

	v = class'LWBonuses'.static.Has(class'LWBonuses'.const.NEW_WARFARE);
	F.Cash = Off(F.Cash, v);
	F.Alloys = Off(F.Alloys, v);
	F.Elerium = Off(F.Elerium, v);
}

/**
 * A soldier added to the barracks, as XCOM 2 makes its starting soldiers (from the character pool, kit, barracks). With a
 * base class (EW's ESoldierClass: 1 sniper, 2 heavy weapons, 3 support, 4 assault) and rank: one of its two Long War
 * classes, at that rank, with the experience it needs (so no promotion waits); with a country, a name of that country.
 */
static function XComGameState_Unit NewSoldier(XComGameState NewGameState, XComGameState_HeadquartersXCom XComHQ, int BaseClass, int Rank, optional name Country)
{
	local XComGameState_Unit Unit;
	local XGCharacterGenerator Generator;
	local TSoldier Made;
	local array<name> Classes;
	local int i;

	Unit = `CHARACTERPOOLMGR.CreateCharacter(NewGameState, `XPROFILESETTINGS.Data.m_eCharPoolUsage);
	if (Country != '')
	{
		Generator = `XCOMGRI.Spawn(Unit.GetMyTemplate().CharacterGeneratorClass);
		Made = Generator.CreateTSoldier('Soldier', EGender(Unit.kAppearance.iGender), Country);
		Unit.SetTAppearance(Made.kAppearance);
		Unit.SetCharacterName(Made.strFirstName, Made.strLastName, Made.strNickName);
		Unit.SetCountry(Made.nmCountry);
		Generator.Destroy();
	}
	Unit.RandomizeStats();
	Unit.ApplyInventoryLoadout(NewGameState);
	Unit.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, Unit);
	if (BaseClass > 0 && Rank > 0)
	{
		switch (BaseClass)
		{
		case 1: Classes.AddItem('LWS_Sniper'); Classes.AddItem('LWS_Scout'); break;
		case 2: Classes.AddItem('LWS_Rocketeer'); Classes.AddItem('LWS_Gunner'); break;
		case 3: Classes.AddItem('LWS_Medic'); Classes.AddItem('LWS_Engineer'); break;
		default: Classes.AddItem('LWS_Assault'); Classes.AddItem('LWS_Infantry'); break;
		}
		Unit.RankUpSoldier(NewGameState, Classes[Rand(Classes.Length)]);
		Unit.ApplySquaddieLoadout(NewGameState, XComHQ);
		for (i = 1; i < Rank; i++)
			Unit.RankUpSoldier(NewGameState);
		Unit.SetUnitFloatValue('LWX2XP', class'X2ExperienceConfig'.static.GetRequiredKills(Rank), eCleanup_Never);
		Unit.NonTacticalKills = class'X2ExperienceConfig'.static.GetRequiredKills(Rank);
	}
	`log("LongWarX2: bonuses: a soldier for the barracks:" @ Unit.GetFullName() $ (Rank > 0 ? "," @ Unit.GetSoldierClassTemplateName() @ "rank" @ Unit.GetRank() : ""), , 'LongWarX2');
	return Unit;
}

static function GrantFoundry(XComGameState_LWStrategy S, int Id)
{
	if (Id > 0 && S.FoundryDone.Find(Id) == INDEX_NONE)
		S.FoundryDone.AddItem(Id);
}

/**
 * The bonuses that come with a soldier, given once to each (UnitValue LWX2Bonus: 1 the recruit's, 2 the class's too):
 * every recruit's (Pax Nigerina mobility, the SAS's aim, Patriae Semper Vigilis will, Survival Training HP), then, once
 * the soldier has a Long War class, its base class's (1st Recce defence for scouts and snipers, Southern Cross aim for
 * gunners and rocketeers, Task Force Arrowhead will for medics and engineers, Spetznaz HP for assaults and infantry).
 * The bonuses as they hold when the soldier is first seen (Long War: when it is made). Returns whether anything changed.
 */
/** Whether the soldier has a bonus stage still to get (GiveSoldier would change it). */
static function bool SoldierDue(XComGameState_Unit Unit)
{
	local UnitValue Done;
	local int Stage;

	// (Not SHIVs or MECs: Long War rolls and raises only recruits; a MEC has its own numbers, LWMECs.)
	if (Unit.IsRobotic() || class'LWMECs'.static.IsMEC(Unit))
		return false;
	Stage = Unit.GetUnitValue('LWX2Bonus', Done) ? int(Done.fValue) : 0;
	return class'XComGameState_LWStrategy'.static.Get() != none && (Stage == 0 || (Stage == 1 && BaseClass(Unit) != ""));
}

static function bool GiveSoldier(XComGameState_Unit Unit)
{
	local UnitValue Done;
	local int Stage;
	local string Base;

	Stage = Unit.GetUnitValue('LWX2Bonus', Done) ? int(Done.fValue) : 0;
	if (Stage >= 2 || class'XComGameState_LWStrategy'.static.Get() == none || Unit.IsRobotic() || class'LWMECs'.static.IsMEC(Unit))
		return false;
	if (Stage == 0)
	{
		// Long War's rookie stats first (XGFacility_Barracks.RandomizeStats, which also takes Per Ardua Ad Astra), then the
		// bonuses CreateSoldier adds after it.
		class'LWRookieStats'.static.Roll(Unit);
		Raise(Unit, eStat_Mobility, class'LWBonuses'.static.Has(class'LWBonuses'.const.PAX_NIGERINA));
		Raise(Unit, eStat_Offense, class'LWBonuses'.static.Has(class'LWBonuses'.const.SAS));
		Raise(Unit, eStat_Will, class'LWBonuses'.static.Has(class'LWBonuses'.const.PATRIAE));
		Raise(Unit, eStat_HP, class'LWBonuses'.static.Has(class'LWBonuses'.const.SURVIVAL_TRAINING));
		Stage = 1;
	}
	Base = BaseClass(Unit);
	if (Base != "")
	{
		switch (Base)
		{
		case "Sniper":
			Raise(Unit, eStat_Defense, class'LWBonuses'.static.Has(class'LWBonuses'.const.FIRST_RECCE));
			break;
		case "HeavyWeapons":
			Raise(Unit, eStat_Offense, class'LWBonuses'.static.Has(class'LWBonuses'.const.SOUTHERN_CROSS));
			break;
		case "Support":
			Raise(Unit, eStat_Will, class'LWBonuses'.static.Has(class'LWBonuses'.const.TASK_FORCE_ARROWHEAD));
			break;
		case "Assault":
			Raise(Unit, eStat_HP, class'LWBonuses'.static.Has(class'LWBonuses'.const.SPETZNAZ));
			break;
		}
		Stage = 2;
	}
	Unit.SetUnitFloatValue('LWX2Bonus', Stage, eCleanup_Never);
	return true;
}

static function Raise(XComGameState_Unit Unit, ECharStatType Stat, int By)
{
	if (By == 0)
		return;
	Unit.SetBaseMaxStat(Stat, Unit.GetBaseStat(Stat) + By);
	if (Stat == eStat_HP)
		Unit.SetCurrentStat(eStat_HP, Unit.GetCurrentStat(eStat_HP) + By);
	`log("LongWarX2: bonuses:" @ Unit.GetFullName() @ Stat @ "+" $ By, , 'LongWarX2');
}

/** Long War's base class of the soldier's class (EW's ESoldierClass: the two Long War classes built on each), or "". */
static function string BaseClass(XComGameState_Unit Unit)
{
	local string C;

	C = string(Unit.GetSoldierClassTemplateName());
	if (Left(C, 4) != "LWS_")
		return "";
	C = Repl(Mid(C, 4), "Squaddie", "");
	switch (C)
	{
	case "Sniper":
	case "Scout":
		return "Sniper";
	case "Gunner":
	case "Rocketeer":
		return "HeavyWeapons";
	case "Medic":
	case "Engineer":
		return "Support";
	case "Assault":
	case "Infantry":
		return "Assault";
	}
	return "";
}

static function string JoinLines(array<string> Lines)
{
	local string S, L;

	foreach Lines(L)
		S $= (S != "" ? "; " : "") $ L;
	return S != "" ? S : "none";
}
