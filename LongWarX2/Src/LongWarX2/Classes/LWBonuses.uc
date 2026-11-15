// Long War's bonuses (features/lw-startbonus.md): the starting bonus chosen with the home country, the bonuses of the other
// council countries under satellites, and the continents' when all their countries are. Generated from Long War's
// ItemBalance_Classic by scripts/strategy-config.mjs; the words (Names, Descs) by the setup program from the player's Long
// War install, into the mod's LongWarX2.int (Long War's ContinentBonusNames and ContinentBonusDesc, by type).
//
// Has(Type) is Long War's XGHeadQuarters.HasBonus: the sum of the values of every bonus of that type that holds now.
class LWBonuses extends Object config(LWStrategy);

struct LWBonusDef
{
	/** 0 a starting bonus, 1 a country's, 2 a continent's. */
	var int Kind;
	/** A starting bonus: its option on the start screen (one option can hold more than one bonus). */
	var int Choice;
	var name Country;
	var int Continent;
	/** What Long War's code asks for (EContinentBonus). */
	var int Type;
	var int Value;
};

var config array<LWBonusDef> Bonuses;
/** The values' scale by difficulty (Long War's FundingBalance[8 + difficulty]). */
var config float Scale[4];

/** By type: the bonus's name ("Wealthy Benefactor: ") and its description, <XGParam:IntValue0/> for its number. */
var localized string Names[64];
var localized string Descs[64];
/** The start screen's words (Long War's XGContinentUI). */
var localized string LabelBaseLocation, LabelBegin, LabelStarting, LabelContinentBonus;

// The types Long War's code asks for (EContinentBonus), named after the stock bonus that has each.
const AIR_SUPERIORITY = 2;
const POWER_TO_THE_PEOPLE = 3;
const NEW_WARFARE = 4;
const ARCHITECTS = 5;
const WEALTH_OF_NATIONS = 6;
const GIFT_OF_OSIRIS = 7;
const PAX_NIGERINA = 8;
const RESOURCEFUL = 9;
const PER_ARDUA = 10;
const JAI_JAWAN = 11;
const BAUMEISTER = 12;
const RING_OF_FIRE = 13;
const SUKHOI = 14;
const SAS = 15;
const QUAI_DORSAY = 16;
const SKUNKWORKS = 17;
const WEALTHY_BENEFACTOR = 18;
const SPECIAL_WARFARE_SCHOOL = 19;
const ADVANCED_PREPARATIONS = 20;
const PATRIAE = 21;
const JUNGLE_SCOUTS_RIGGING = 22; // Long War's coded alternative, commented out in its ini
const ANCIENT_ARTIFACT = 23;
const CHEYENNE_MOUNTAIN = 24;
const GHOST_IN_THE_MACHINE = 25;
const THEIR_FINEST_HOUR = 26;
const SURVIVAL_TRAINING = 27;
const FOR_THE_SAKE_OF_GLORY = 28;
const ROSCOSMOS = 29;
const WEI_RENMIN = 30;
const DEUS_EX = 31;
const KIRYU_KAI = 32;
const JUNGLE_SCOUTS = 35;
const FOREIGN_LEGION = 36;
const CADRE = 37;
const ON_OUR_OWN = 41;
const CALL_TO_ARMS = 42;
const THE_OLD_PATH = 43;
const FIRST_RECCE = 44;
const SOUTHERN_CROSS = 45;
const JAI_VIDWAN = 46;
const XENOLOGICAL_REMEDIES = 47;
const ROBOTICS = 48;
const SPETZNAZ = 49;
const SANDHURST = 50;
const CYBERWARE = 51;
const NEOPANZERS = 52;
const BOUNTIES = 53;
const EXPERTISE = 54;
const LEGACY_OF_UXMAL = 55;
const TASK_FORCE_ARROWHEAD = 56;
const WE_HAVE_WAYS = 57;

/** A bonus's number now (Long War's GetContinentByBonus: Value x Scale, at least 1). */
static function int ValueOf(int i)
{
	return Max(1, int(default.Bonuses[i].Value * default.Scale[class'LWStrategyRules'.static.Difficulty()]));
}

/** The sum of every bonus of the type that holds (Long War's HasBonus); 0 for none, or before the campaign has begun. */
static function int Has(int Type, optional XComGameState_LWStrategy S)
{
	local int i, Sum, k;

	if (S == none)
		S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return 0;
	for (i = 0; i < default.Bonuses.Length; i++)
	{
		if (default.Bonuses[i].Type != Type)
			continue;
		switch (default.Bonuses[i].Kind)
		{
		case 0:
			if (S.StartChoice == default.Bonuses[i].Choice && S.Countries[S.HomeCountry()].Id == default.Bonuses[i].Country)
				Sum += ValueOf(i);
			break;
		case 1:
			k = S.CountryIndex(default.Bonuses[i].Country);
			if (k != INDEX_NONE && k != S.HomeCountry() && S.Countries[k].bSatellite && !S.Countries[k].bLeft)
				Sum += ValueOf(i);
			break;
		case 2:
			if (ContinentCovered(S, default.Bonuses[i].Continent))
				Sum += ValueOf(i);
			break;
		}
	}
	return Sum;
}

/** Every council country of the continent under a satellite (Long War's XGContinent.HasBonus). */
static function bool ContinentCovered(XComGameState_LWStrategy S, int Continent)
{
	local int k;
	local bool bAny;

	for (k = 0; k < S.Countries.Length; k++)
	{
		if (S.CountryContinent(k) != Continent)
			continue;
		if (!S.Countries[k].bSatellite)
			return false;
		bAny = true;
	}
	return bAny;
}

/** The start screen's options, as Long War's XGContinentUI.Init makes them: each (choice, country) of a starting bonus once. */
static function GetChoices(out array<int> Choices, out array<int> Countries)
{
	local LWBonusDef B;
	local int i, k;
	local bool bSeen;

	Choices.Length = 0;
	Countries.Length = 0;
	foreach default.Bonuses(B)
	{
		if (B.Kind != 0)
			continue;
		k = class'LWStrategyRules'.default.Countries.Find('Id', B.Country);
		if (k == INDEX_NONE)
			continue;
		bSeen = false;
		for (i = 0; i < Choices.Length; i++)
			if (Choices[i] == B.Choice && Countries[i] == k)
				bSeen = true;
		if (!bSeen)
		{
			Choices.AddItem(B.Choice);
			Countries.AddItem(k);
		}
	}
}

/** A bonus's words with its number in them: "Wealthy Benefactor: You start with §500 more." (its type's name and text). */
static function string Text(int i, optional bool bNameOnly)
{
	local string BonusName, Desc;

	BonusName = default.Names[default.Bonuses[i].Type];
	if (BonusName == "")
		BonusName = "Bonus " $ default.Bonuses[i].Type $ ": ";
	if (bNameOnly)
		return BonusName;
	Desc = Repl(Repl(default.Descs[default.Bonuses[i].Type], "<XGParam:IntValue0/>", string(ValueOf(i))), "<XGParam:IntValue0>", string(ValueOf(i)));
	return BonusName $ Desc;
}

/** Every bonus of a start option (choice and home country), and the home continent's, as EW's start screen lists them. */
static function string ChoiceText(int Choice, int Country, optional string ContinentLabel = "CONTINENT BONUS:")
{
	local int i;
	local string S;

	for (i = 0; i < default.Bonuses.Length; i++)
		if (default.Bonuses[i].Kind == 0 && default.Bonuses[i].Choice == Choice && default.Bonuses[i].Country == class'LWStrategyRules'.default.Countries[Country].Id)
			S $= Text(i) $ "\n";
	S $= "\n" $ ContinentLabel $ "\n";
	for (i = 0; i < default.Bonuses.Length; i++)
		if (default.Bonuses[i].Kind == 2 && default.Bonuses[i].Continent == class'LWStrategyRules'.default.Countries[Country].Continent)
			S $= Text(i) $ "\n";
	return S;
}

/** The bonuses that hold now, a line each (the stores and the control port). */
static function array<string> Holding(XComGameState_LWStrategy S)
{
	local array<string> Out;
	local int i, k;
	local bool bHolds;

	for (i = 0; i < default.Bonuses.Length; i++)
	{
		switch (default.Bonuses[i].Kind)
		{
		case 0:
			bHolds = S.StartChoice == default.Bonuses[i].Choice && S.Countries[S.HomeCountry()].Id == default.Bonuses[i].Country;
			break;
		case 1:
			k = S.CountryIndex(default.Bonuses[i].Country);
			bHolds = k != INDEX_NONE && k != S.HomeCountry() && S.Countries[k].bSatellite && !S.Countries[k].bLeft;
			break;
		case 2:
			bHolds = ContinentCovered(S, default.Bonuses[i].Continent);
			break;
		}
		if (bHolds && default.Bonuses[i].Type != ON_OUR_OWN)
			Out.AddItem(Text(i));
	}
	return Out;
}
