// What Long War's bonuses (LWBonuses, features/lw-startbonus.md) do where they act once: at the campaign's start
// (Long War's XGWorld.StartGame, XGFacility_Engineering.InitNewGame and GrantInitialStores, XGBase.GenerateTiles), and on
// each soldier as Long War makes it (XGFacility_Barracks.CreateSoldier: every recruit; XGStrategySoldier.SetSoldierClass:
// by the soldier's base class). The bonuses that change a rule as it is used (costs, funding, research, psi) are asked for
// where that rule is, with LWBonuses.Has.
class LWBonusEffects extends Object;

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
	for (i = 0; i < class'LWBonuses'.default.Bonuses.Length; i++)
		if (class'LWBonuses'.default.Bonuses[i].Kind == 0 && class'LWBonuses'.default.Bonuses[i].Choice == S.StartChoice
			&& class'LWBonuses'.default.Bonuses[i].Country == S.Countries[S.HomeCountry()].Id)
			S.Note("Starting bonus:" @ class'LWBonuses'.static.Text(i));
	`log("LongWarX2: bonuses: home" @ S.CountryName(S.HomeCountry()) $ ", start option" @ S.StartChoice $ "; holding:" @ JoinLines(class'LWBonuses'.static.Holding(S)), , 'LongWarX2');
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

	Stage = Unit.GetUnitValue('LWX2Bonus', Done) ? int(Done.fValue) : 0;
	return class'XComGameState_LWStrategy'.static.Get() != none && (Stage == 0 || (Stage == 1 && BaseClass(Unit) != ""));
}

static function bool GiveSoldier(XComGameState_Unit Unit)
{
	local UnitValue Done;
	local int Stage;
	local string Base;

	Stage = Unit.GetUnitValue('LWX2Bonus', Done) ? int(Done.fValue) : 0;
	if (Stage >= 2 || class'XComGameState_LWStrategy'.static.Get() == none)
		return false;
	if (Stage == 0)
	{
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
