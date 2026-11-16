// Long War's council missions (features/lw-council-missions.md), as its XGFundingCouncil makes them: once a month, after
// FirstHours + rand(FirstRand) hours, a mission of the kind played least (assault, bomb, extraction, rescue) in a council
// country under a satellite, on its own EW map, with its rewards rolled and scaled by the campaign's age. It waits on the
// Geoscape as an abduction does (AbductionHours); won, its rewards are paid; lost or let go, its continent panics.
// The config is Long War's (scripts/council-config.mjs from the Tree's data/council.json).
class LWCouncil extends Object config(LWCouncil) dependson(XComGameState_LWStrategy);

struct LWCouncilRewardDef
{
	/** 1 cash, 3 a soldier, 4 scientists, 5 engineers, 6 the country's panic, 8 elerium (Long War's EFCRewardType: GrantFCRewards
	 *  adds eResource_Scientists for 4, eResource_Engineers for 5). */
	var int Type;
	var int Amount;
	/** Cash: this times RandMoneyRewardAmount. */
	var float Money;
	/** A soldier: its class (-1 rolled) and level (-1: by the campaign's age). */
	var int SoldierClass;
	var int SoldierLevel;
};

struct LWCouncilMission
{
	/** Long War's EFCMission. */
	var int Id;
	/** 1 assault, 2 bomb, 3 extraction, 4 rescue. */
	var int Kind;
	/** Its EW map (XComLWEWMaps.ini's name), and the streamed level with its variant (Long War's DefaultMaps.ini): the mission
	 *  plays on the plot of the two, LWX2V_<Level>, when the setup has made it. */
	var string Map;
	var string Level;
	/** The panic on its continent when it fails (Long War's iPanicOnFailure). */
	var int PanicOnFailure;
	/** Offered by its own rule (DetermineNewFCMission), never by the kinds' rotation: 29 the Chryssalid hive. */
	var bool Special;
	/** Its own country (BuildMission's), for a special mission. */
	var name Country;
	var array<LWCouncilRewardDef> Rewards;
};

var config int FirstHours, FirstRand;
var config int MinMoney, MaxMoney;
var config int RewardLowDays, RewardMedDays;
var config float RewardLowMult, RewardMedMult;
var config int SoldierLevels[3];
var config array<LWCouncilMission> Missions;

/** The kinds' names, for the decision and the events (the mod's own words). */
var localized string KindNames[5];

static function bool MissionById(int Id, out LWCouncilMission M)
{
	local int k;

	k = default.Missions.Find('Id', Id);
	if (k == INDEX_NONE)
		return false;
	M = default.Missions[k];
	return true;
}

/** The council mission under way, if the mission is one. */
static function bool Current(out LWCouncilMission M)
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.PendingKind != 10 || S.PendingIndex >= S.Sites.Length)
		return false;
	return MissionById(S.Sites[S.PendingIndex].CouncilMission, M);
}

/** The EW map of a variant level's plot (LWX2V_<level>), "" when no council mission has that level. */
static function string MapOfLevel(string Level)
{
	local LWCouncilMission M;

	foreach default.Missions(M)
		if (M.Level ~= Level)
			return M.Map;
	return "";
}

static function int KindOf(int Id)
{
	local LWCouncilMission M;

	return MissionById(Id, M) ? M.Kind : 0;
}

static function string KindName(int Kind)
{
	local string Fallback;

	switch (Kind)
	{
	case 1: Fallback = "assault"; break;
	case 2: Fallback = "bomb disposal"; break;
	case 3: Fallback = "extraction"; break;
	case 4: Fallback = "rescue"; break;
	default: Fallback = "operation";
	}
	return (Kind >= 0 && Kind < 5 && default.KindNames[Kind] != "") ? default.KindNames[Kind] : Fallback;
}

/** The hours to the month's council mission (SetupMonthlyRequests). */
static function SetupMonth(XComGameState_LWStrategy S)
{
	S.CouncilCountdown = default.FirstHours + Rand(Max(1, default.FirstRand));
}

/** An hour (XGFundingCouncil.Update): the countdown run down; at 0, with no council mission waiting, the month's mission. */
static function Hour(XComGameState_LWStrategy S)
{
	local int i;

	if (default.Missions.Length == 0)
		return;
	if (S.CouncilCountdown == 0 && !S.bCouncilSetUp)
	{
		S.bCouncilSetUp = true;
		SetupMonth(S);
	}
	if (--S.CouncilCountdown > 0)
		return;
	for (i = 0; i < S.Sites.Length; i++)
		if (S.Sites[i].bCouncil && S.Sites[i].Status == 1)
			return;
	S.CouncilCountdown = 9999;
	NewMission(S);
}

/** The month over (OnEndOfMonth): the next month's countdown. */
static function MonthEnded(XComGameState_LWStrategy S)
{
	SetupMonth(S);
}

/** The kind played least (ChooseNextMissionByType), among those with a mission whose map can be played; one of its missions. */
static function bool ChooseMission(XComGameState_LWStrategy S, out LWCouncilMission Chosen)
{
	local array<int> Played, Kinds;
	local array<LWCouncilMission> Of;
	local LWCouncilMission M;
	local int k, Least;

	Played.Length = 5;
	foreach S.CouncilPlayed(k)
		if (MissionById(k, M))
			Played[M.Kind]++;
	Least = 9999;
	for (k = 1; k <= 4; k++)
		if (HasPlayable(k) && Played[k] < Least)
			Least = Played[k];
	for (k = 1; k <= 4; k++)
		if (HasPlayable(k) && Played[k] == Least)
			Kinds.AddItem(k);
	if (Kinds.Length == 0)
		return false;
	k = Kinds[Rand(Kinds.Length)];
	foreach default.Missions(M)
		if (M.Kind == k && !M.Special && Playable(M))
			Of.AddItem(M);
	Chosen = Of[Rand(Of.Length)];
	return true;
}

/** Whether a mission can be played here: its EW map converted when missions play on EW's maps; any, on XCOM 2's plots. */
static function bool Playable(LWCouncilMission M)
{
	local array<string> Converted;

	if (!class'UIScreenListener_LongWarX2Tactical'.default.PlaceEWMapWhole)
		return true;
	Converted = class'LWX2EWMapPieces'.static.ConvertedMaps();
	return Converted.Find(M.Map) != INDEX_NONE;
}

static function bool HasPlayable(int Kind)
{
	local LWCouncilMission M;

	foreach default.Missions(M)
		if (M.Kind == Kind && !M.Special && Playable(M))
			return true;
	return false;
}

/** The Chryssalid hive, when Long War would offer it instead of the month's mission (DetermineNewFCMission): after day 35
 *  (IsChryssalidHiveValid: STAT_GetStat(eRecap_Days) > 35), once XCOM has ever held a Chryssalid corpse
 *  (STORAGE().EverHadItem(eItem_CryssalidCorpse)), and never before played (HasPlayedChryssalidHive). */
static function bool HiveDue(XComGameState_LWStrategy S, out LWCouncilMission Hive)
{
	local XComGameState_HeadquartersXCom XComHQ;

	if (!MissionById(29, Hive) || !Playable(Hive) || S.CouncilPlayed.Find(29) != INDEX_NONE || S.Days() <= 35)
		return false;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	return XComHQ != none && XComHQ.EverAcquiredInventoryTypes.Find(class'X2Item_LWArtifacts'.static.ItemFor('CryssalidCorpse')) != INDEX_NONE;
}

/** A council country under a satellite (GetAvailableMissionCountries), else any still in the council; -1 for none. */
static function int ChooseCountry(XComGameState_LWStrategy S)
{
	local array<int> With, Any;
	local int i;

	for (i = 0; i < S.Countries.Length; i++)
	{
		if (S.Countries[i].bLeft)
			continue;
		Any.AddItem(i);
		if (S.Countries[i].bSatellite)
			With.AddItem(i);
	}
	if (With.Length > 0)
		return With[Rand(With.Length)];
	return Any.Length > 0 ? Any[Rand(Any.Length)] : -1;
}

/** The month's council mission made (DetermineNewFCMission, BuildMission, CreateMission). */
static function NewMission(XComGameState_LWStrategy S, optional int Id)
{
	local LWCouncilMission M;
	local int Country;

	// (Id: that mission, a test aid.) The hive before the kinds' rotation, when it is due.
	if (Id > 0 ? !MissionById(Id, M) : (!HiveDue(S, M) && !ChooseMission(S, M)))
		return;
	Country = M.Country != '' ? S.CountryIndex(M.Country) : ChooseCountry(S);
	if (Country < 0)
		return;
	S.AddCouncilSite(M.Id, Country, RollRewards(S, M));
}

/** The mission's rewards as Long War rolls and scales them (BuildMission, CreateMission). */
static function array<XComGameState_LWStrategy.LWCouncilReward> RollRewards(XComGameState_LWStrategy S, LWCouncilMission M)
{
	local array<XComGameState_LWStrategy.LWCouncilReward> Out;
	local LWCouncilRewardDef D;
	local XComGameState_LWStrategy.LWCouncilReward R;
	local float Scale;
	local int Days, Level;

	Days = S.Days();
	Scale = Days < default.RewardLowDays ? default.RewardLowMult : (Days < default.RewardMedDays ? default.RewardMedMult : 1.0);
	Level = default.SoldierLevels[Days < default.RewardLowDays ? 0 : (Days < default.RewardMedDays ? 1 : 2)];
	foreach M.Rewards(D)
	{
		R.Type = D.Type;
		R.Amount = D.Amount;
		R.SoldierClass = D.SoldierClass;
		// (A mission's own sum, as the hive's §450, else the rolled amount times its multiple.)
		if (D.Type == 1 && D.Money > 0)
			R.Amount = int(D.Money * (default.MinMoney + 5 * Rand((default.MaxMoney - default.MinMoney) / 5 + 1)));
		// Cash, engineers and scientists by the campaign's age, at least 1 (CreateMission).
		if (Scale != 1.0 && (D.Type == 1 || D.Type == 4 || D.Type == 5))
			R.Amount = Max(1, int(R.Amount * Scale));
		if (D.Type == 3)
			R.Amount = D.SoldierLevel >= 0 ? D.SoldierLevel : Level;
		Out.AddItem(R);
	}
	return Out;
}

/** The rewards in words: "§150, 8 scientists, panic -30". */
static function string RewardsText(array<XComGameState_LWStrategy.LWCouncilReward> Rewards)
{
	local XComGameState_LWStrategy.LWCouncilReward R;
	local string T;

	foreach Rewards(R)
	{
		if (T != "")
			T $= ", ";
		switch (R.Type)
		{
		case 1: T $= class'LWStrategyRules'.static.Money(R.Amount); break;
		case 3: T $= "a soldier"; break;
		case 4: T $= R.Amount @ "scientists"; break;
		case 5: T $= R.Amount @ "engineers"; break;
		case 6: T $= "panic" @ R.Amount; break;
		case 8: T $= R.Amount @ "elerium"; break;
		default: T $= "?";
		}
	}
	return T;
}

/** Won (GrantFCRewards): the rewards paid. */
static function Grant(XComGameState NewGameState, XComGameState_LWStrategy S, int SiteIndex)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy.LWCouncilReward R;
	local XComGameState_Unit Soldier;
	local int Country;

	Country = S.Sites[SiteIndex].Country;
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	if (XComHQ == none)
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	foreach S.Sites[SiteIndex].Rewards(R)
	{
		switch (R.Type)
		{
		case 1:
			XComHQ.AddResource(NewGameState, 'Supplies', R.Amount);
			break;
		case 3:
			// (GrantFCRewards: CreateSoldier(class, level, country); a class of its own rolled: a base class.)
			Soldier = class'LWBonusEffects'.static.NewSoldier(NewGameState, XComHQ, R.SoldierClass > 0 ? R.SoldierClass : 1 + Rand(4), R.Amount,
				class'LWStrategyRules'.default.Countries[Country].Id);
			if (Soldier != none)
				S.Note(Soldier.GetFullName() @ "joins XCOM from" @ S.CountryName(Country) $ ".");
			break;
		case 4:
			S.Scientists += R.Amount;
			break;
		case 5:
			S.Engineers += R.Amount;
			break;
		case 6:
			S.AddPanic(Country, R.Amount);
			break;
		case 8:
			class'X2Item_LWArtifacts'.static.Give(NewGameState, 'Elerium', R.Amount);
			break;
		}
	}
	if (S.Sites[SiteIndex].CouncilMission == 29)
		HivePanicBonus(S);
	S.Note("The council paid for the" @ KindName(S.Sites[SiteIndex].CouncilKind) @ "in" @ S.CountryName(Country) $ ":" @ RewardsText(S.Sites[SiteIndex].Rewards) $ ".");
}

/** The hive won with Canada gone from the council (ApplyChryssalidHivePanicBonus): the United States or Mexico loses 20 panic,
 *  as Long War picks: Mexico if the States are gone or less panicked, else the States if Mexico is gone or less panicked,
 *  else either; neither when both are gone. */
static function HivePanicBonus(XComGameState_LWStrategy S)
{
	local int Canada, USA, Mexico;

	Canada = S.CountryIndex('Canada');
	USA = S.CountryIndex('USA');
	Mexico = S.CountryIndex('Mexico');
	if (Canada < 0 || USA < 0 || Mexico < 0 || !S.Countries[Canada].bLeft || (S.Countries[USA].bLeft && S.Countries[Mexico].bLeft))
		return;
	if (S.Countries[USA].bLeft || PanicBlocks(S, USA) < PanicBlocks(S, Mexico))
		S.AddPanic(Mexico, -20);
	else if (S.Countries[Mexico].bLeft || PanicBlocks(S, USA) > PanicBlocks(S, Mexico))
		S.AddPanic(USA, -20);
	else
		S.AddPanic(Rand(2) == 0 ? Mexico : USA, -20);
}

/** XGCountry.GetPanicBlocks: panic + 1, 1 to 100. */
static function int PanicBlocks(XComGameState_LWStrategy S, int Country)
{
	return Clamp(S.Countries[Country].Panic + 1, 1, 100);
}

/** Lost or let go (CausePanicOnFailure): its continent panics. */
static function Failed(XComGameState_LWStrategy S, int SiteIndex)
{
	local LWCouncilMission M;

	if (MissionById(S.Sites[SiteIndex].CouncilMission, M) && M.PanicOnFailure > 0)
		S.AddContinentPanic(S.CountryContinent(S.Sites[SiteIndex].Country), M.PanicOnFailure);
	S.Note("The council's" @ KindName(S.Sites[SiteIndex].CouncilKind) @ "in" @ S.CountryName(S.Sites[SiteIndex].Country) @ "failed.");
}
