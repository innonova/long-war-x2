// Long War's council requests (features/lw-council-requests.md), as its XGFundingCouncil makes them: every NextHours +
// rand(NextRand) hours (Quai d'Orsay: sooner by its share; Update, SetupMonthlyRequests) a council country asks for items
// (corpses, artifacts, weapons), a satellite over it or a jet on its continent, for rewards rolled as Long War rolls them
// (BuildRequest, CreateReward). One the player can already meet is pending: given now, or ignored. Else it waits its hours
// (RequestDays x its factor, less 2 per panic block of its country) to be handed over once XCOM has the items, or met by the
// satellite or jet arriving. Met (AttemptTurnInRequest, OnRequestCompleted): the items taken, the rewards paid
// (GrantFCRewards), the country's science up 10 (Quai d'Orsay: more by its share). A country leaving takes its requests.
// The config is Long War's (scripts/requests-config.mjs from the Tree's data/requests.json).
class LWCouncilRequests extends Object config(LWRequests) dependson(XComGameState_LWStrategy);

struct LWRequestRewardDef
{
	/** Long War's EFCRewardType: 1 cash, 2 a soldier or scientists (even odds), 3 a soldier, 4 scientists, 5 engineers,
	 *  6 panic. */
	var int Type;
	/** CreateReward's quantities (its defaults 2 and 2), or an amount given as it is (a transfer's). */
	var int Min, Max, Fixed;
};

struct LWRequestAlt
{
	var array<LWRequestRewardDef> Rewards;
};

struct LWRequestDef
{
	/** Long War's EFCRequest. */
	var int Id;
	/** The item asked for (EItemType) and its template here. */
	var int Item;
	var name Template;
	/** Long War's techs (ETechType) all researched before it is asked. */
	var array<int> Requires;
	/** How many: Amount, or AmountKind 1 the corpses' number, 2 the fragments', 3 rand(RandN) + RandAdd. */
	var int Amount, AmountKind, RandN, RandAdd;
	/** Its hours: RequestDays x HoursFactor, or Hours. */
	var int HoursFactor, Hours;
	/** 1 a satellite over the country, 2 a jet on its continent. */
	var int Transfer;
	/** The item's quest price (XGItemTree.GetItemQuestPrice), for a cash reward. */
	var int Price;
	/** One per branch of Long War's roll. */
	var array<LWRequestAlt> Alts;
};

var config int NextHours, NextRand, RequestDays;
var config float ProfitMargin;
var config array<LWRequestDef> Requests;

static function bool DefOf(int Id, out LWRequestDef D)
{
	local int k;

	k = default.Requests.Find('Id', Id);
	if (k == INDEX_NONE)
		return false;
	D = default.Requests[k];
	return true;
}

/** The hours to the next request (SetupMonthlyRequests, Update): NextHours + rand(NextRand), Quai d'Orsay's share less. */
static function int NextIn()
{
	local int H, Quai;

	H = default.NextHours + Rand(Max(1, default.NextRand));
	Quai = class'LWBonuses'.static.Has(class'LWBonuses'.const.QUAI_DORSAY);
	if (Quai > 0)
		H = int(H * (1.0 - Quai / 100.0));
	return Max(1, H);
}

/** An hour (XGFundingCouncil.Update): each open request's hours run down (out: it expires, unless a satellite or jet is on
 *  its way to meet it: none is here, they arrive at once); at the countdown's end, a new request. */
static function Hour(XComGameState_LWStrategy S)
{
	local int i;

	if (default.Requests.Length == 0)
		return;
	if (!S.bRequestsSetUp)
	{
		S.bRequestsSetUp = true;
		S.RequestCountdown = NextIn();
	}
	for (i = S.Requests.Length - 1; i >= 0; i--)
	{
		if (S.Requests[i].bPending || --S.Requests[i].HoursLeft > 0)
			continue;
		S.Note(S.CountryName(S.Requests[i].Country) $ "'s request (" $ Words(S.Requests[i]) $ ") went unanswered.");
		S.Requests.Remove(i, 1);
	}
	if (--S.RequestCountdown > 0)
		return;
	S.RequestCountdown = NextIn();
	NewRequest(S);
}

/** The month over (OnEndOfMonth, SetupMonthlyRequests): the countdown set again. */
static function MonthEnded(XComGameState_LWStrategy S)
{
	if (default.Requests.Length > 0)
		S.RequestCountdown = NextIn();
}

/** A country gone: its requests with it (OnCountryLeft). */
static function CountryLeft(XComGameState_LWStrategy S, int Country)
{
	local int i;

	for (i = S.Requests.Length - 1; i >= 0; i--)
		if (S.Requests[i].Country == Country)
			S.Requests.Remove(i, 1);
}

/** Whether a request may be asked now (passesRequestRequirements): its techs researched, the same not open for the country,
 *  a jet transfer only with jets; and, built for its country (BuildRequest), a transfer only where it can be met. */
static function bool Passes(XComGameState_LWStrategy S, LWRequestDef D, int Country)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local name Tech;
	local int i;

	for (i = 0; i < S.Requests.Length; i++)
		if (S.Requests[i].Id == D.Id && S.Requests[i].Country == Country)
			return false;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	for (i = 0; i < D.Requires.Length; i++)
	{
		if (D.Requires[i] <= 0)
			continue;
		Tech = class'LWResearchRules'.static.TemplateForId(D.Requires[i]);
		if (Tech == '' || !XComHQ.IsTechResearched(Tech))
			return false;
	}
	if (D.Transfer == 1 && S.Countries[Country].bSatellite)
		return false;
	if (D.Transfer == 2 && !CanTransferJet(S, Country))
		return false;
	return true;
}

/** A jet may be asked for on the country's continent (CanTransferJet): XCOM has two jets or more, fewer than four there, and
 *  a satellite off its home continent. */
static function bool CanTransferJet(XComGameState_LWStrategy S, int Country)
{
	local XComGameState_LWAirWar AirWar;
	local int i, Total, There;
	local bool bAway;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none)
		return false;
	for (i = 0; i < AirWar.Jets.Length; i++)
	{
		Total++;
		if (AirWar.Jets[i].Continent == S.CountryContinent(Country))
			There++;
	}
	for (i = 0; i < S.Countries.Length; i++)
		if (S.Countries[i].bSatellite && S.CountryContinent(i) != S.CountryContinent(S.HomeCountry()))
			bAway = true;
	return Total >= 2 && There < 4 && bAway;
}

/** A new request (DetermineNewFCRequest): its country any council country still in (DetermineFCRequestCountry), the request
 *  any that passes (ChooseNextRequest: Long War's cooldowns leave every passing request possible), built for the country. */
static function bool NewRequest(XComGameState_LWStrategy S, optional int ForceId)
{
	local array<int> Countries, Possible;
	local LWRequestDef D;
	local XComGameState_LWStrategy.LWRequest R;
	local int i, Country;

	for (i = 0; i < S.Countries.Length; i++)
		if (!S.Countries[i].bLeft)
			Countries.AddItem(i);
	if (Countries.Length == 0)
		return false;
	Country = Countries[Rand(Countries.Length)];
	foreach default.Requests(D)
		if ((ForceId == 0 || D.Id == ForceId) && Passes(S, D, Country))
			Possible.AddItem(D.Id);
	if (Possible.Length == 0)
		return false;
	DefOf(Possible[Rand(Possible.Length)], D);
	R.Id = D.Id;
	R.Country = Country;
	R.Item = D.Template;
	R.Transfer = D.Transfer;
	R.Amount = AmountFor(S, D);
	R.Rewards = RollRewards(S, D, R);
	R.HoursLeft = Max(1, (D.Hours > 0 ? D.Hours : default.RequestDays * D.HoursFactor) - 2 * class'LWCouncil'.static.PanicBlocks(S, Country));
	if (S.RequestsMade.Find(D.Id) == INDEX_NONE)
		S.RequestsMade.AddItem(D.Id);
	// (OnValidRequestAdded: XCOM holds enough already, it is answered now; else it waits.)
	R.bPending = D.Transfer == 0 && Held(R) >= R.Amount;
	S.Requests.AddItem(R);
	S.Note("The council asks, for" @ S.CountryName(Country) $ ":" @ Words(R) $ "; it offers" @ class'LWCouncil'.static.RewardsText(R.Rewards)
		$ (R.bPending ? ". XCOM has them." : ". XCOM has" @ R.HoursLeft @ "hours."));
	// (A pending one asks at once, as EW's alert; a delayed one is a notice: the clock goes on.)
	if (R.bPending)
		S.bStop = true;
	`log("LongWarX2: council request" @ D.Id @ "for" @ S.CountryName(Country) $ ":" @ R.Amount @ R.Item @ (R.bPending ? "(pending)" : "(" $ R.HoursLeft $ "h)"), , 'LongWarX2');
	return true;
}

/** How many (BuildRequest): the corpses' number (1 + rand 4) x the month, 6 to 20; the fragments' (2 + rand 4) x month, 12
 *  to 50; rand(n) + add; else its own. (Long War's month counts from 1.) */
static function int AmountFor(XComGameState_LWStrategy S, LWRequestDef D)
{
	switch (D.AmountKind)
	{
	case 1: return Clamp((1 + Rand(4)) * (S.Month + 1), 6, 20);
	case 2: return Clamp((2 + Rand(4)) * (S.Month + 1), 12, 50);
	case 3: return Rand(Max(1, D.RandN)) + D.RandAdd;
	}
	return D.Amount;
}

/**
 * The rewards (CreateReward), one branch of the request's chosen at random: a "soldier or scientists" either at even odds;
 * scientists or engineers with more than 120 of them already a soldier or cash (a third each, else as asked); cash the
 * item's quest price (+ the minimum unless 1) x the amount x ProfitMargin; a soldier level 3 of a base class (4 from the
 * year's end in a country of science above 50; "class + 100 x level" as Long War writes it); scientists and engineers
 * min + rand(rolled - min + 1), rolled min + rand(max - min + 1); panic -20; a fixed amount as it is.
 */
static function array<XComGameState_LWStrategy.LWCouncilReward> RollRewards(XComGameState_LWStrategy S, LWRequestDef D, XComGameState_LWStrategy.LWRequest Req)
{
	local array<XComGameState_LWStrategy.LWCouncilReward> Out;
	local XComGameState_LWStrategy.LWCouncilReward R;
	local LWRequestRewardDef W;
	local int Type, Rolled, k;

	if (D.Alts.Length == 0)
		return Out;
	foreach D.Alts[Rand(D.Alts.Length)].Rewards(W)
	{
		R.Type = W.Type;
		R.SoldierClass = 0;
		if (W.Fixed != 0)
		{
			R.Amount = W.Fixed;
			Out.AddItem(R);
			continue;
		}
		Type = W.Type;
		if (Type == 2)
			Type = Rand(2) == 1 ? 3 : 4;
		if ((Type == 4 && S.Scientists > 120) || (Type == 5 && S.Engineers > 120))
		{
			k = Rand(3);
			Type = k == 0 ? 3 : (k == 1 ? 1 : Type);
		}
		R.Type = Type;
		switch (Type)
		{
		case 1:
			R.Amount = int((D.Price + (W.Min != 1 ? W.Min : 0)) * Req.Amount * default.ProfitMargin);
			break;
		case 3:
			// (The soldier's level as XComGameState_LWStrategy's council soldiers take it: 3, or 4.)
			R.Amount = (class'LWStrategyRules'.default.Countries[Req.Country].Scientists + (Req.Country < S.CountryScience.Length ? S.CountryScience[Req.Country] : 0) > 50
				&& S.Month + 1 > 11) ? 4 : 3;
			R.SoldierClass = 1 + Rand(4);
			break;
		case 4:
		case 5:
			Rolled = W.Min + Rand(Max(0, W.Max - W.Min) + 1);
			R.Amount = W.Min + Rand(Max(0, Rolled - W.Min) + 1);
			break;
		case 6:
			R.Amount = -20;
			break;
		default:
			R.Type = 0;
		}
		if (R.Type != 0)
			Out.AddItem(R);
	}
	return Out;
}

/** How many of the item XCOM holds. */
static function int Held(XComGameState_LWStrategy.LWRequest R)
{
	return R.Item != '' ? class'LWEngineering'.static.Held(R.Item) : 0;
}

/** The request in words: "8 Floater Corpses", "a satellite over Brazil", "an interceptor in Europe". */
static function string Words(XComGameState_LWStrategy.LWRequest R)
{
	local XComGameState_LWStrategy S;
	local X2ItemTemplate T;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (R.Transfer == 1)
		return "a satellite over" @ S.CountryName(R.Country);
	if (R.Transfer == 2)
		return "an interceptor in" @ class'LWStrategyRules'.static.ContinentName(S.CountryContinent(R.Country));
	T = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(R.Item);
	return R.Amount @ (T != none ? (R.Amount == 1 ? T.GetItemFriendlyName() : T.GetItemFriendlyNamePlural()) : string(R.Item));
}

/**
 * A request answered (the Geoscape's decision): given (AcceptPendingRequest and AttemptTurnInRequest: the items taken, the
 * rewards paid, the country's science up) if XCOM has the items; else, ignored (IgnorePendingRequest: gone, as expired).
 */
static function bool Answer(int Index, bool bGive)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_LWStrategy.LWRequest R;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || Index < 0 || Index >= S.Requests.Length)
		return false;
	R = S.Requests[Index];
	if (bGive && (R.Transfer != 0 || Held(R) < R.Amount))
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a council request answered");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	if (bGive)
	{
		class'LWEngineering'.static.Take(NewGameState, R.Item, R.Amount);
		Complete(NewGameState, S, Index);
	}
	else
	{
		S.Note(S.CountryName(R.Country) $ "'s request (" $ Words(R) $ ") was refused.");
		S.Requests.Remove(Index, 1);
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

/** Met (OnRequestCompleted): the rewards paid (GrantFCRewards), the country's science up 10, Quai d'Orsay's share more. */
static function Complete(XComGameState NewGameState, XComGameState_LWStrategy S, int Index)
{
	local XComGameState_LWStrategy.LWRequest R;
	local int Quai, Up;

	R = S.Requests[Index];
	class'LWCouncil'.static.GrantRewards(NewGameState, S, R.Rewards, R.Country);
	Up = 10;
	Quai = class'LWBonuses'.static.Has(class'LWBonuses'.const.QUAI_DORSAY);
	if (Quai > 0)
		Up += int(10 * Quai / 100.0);
	if (S.CountryScience.Length < S.Countries.Length)
		S.CountryScience.Length = S.Countries.Length;
	S.CountryScience[R.Country] = Clamp(S.CountryScience[R.Country] + Up, 0, 100);
	S.Note(S.CountryName(R.Country) $ "'s request met (" $ Words(R) $ "):" @ class'LWCouncil'.static.RewardsText(R.Rewards) $ ".");
	S.Requests.Remove(Index, 1);
	S.bStop = true;
}

/** A satellite now over a country: its request for one met (OnSatelliteSuccessfullyTransferred). */
static function SatelliteArrived(XComGameState NewGameState, XComGameState_LWStrategy S, int Country)
{
	local int i;

	for (i = S.Requests.Length - 1; i >= 0; i--)
		if (S.Requests[i].Transfer == 1 && S.Requests[i].Country == Country)
			Complete(NewGameState, S, i);
}

/** A jet come to a continent (bought or transferred: OnShipAdded): the first request for one there met. */
static function JetArrived(XComGameState NewGameState, XComGameState_LWStrategy S, int Continent)
{
	local int i;

	for (i = 0; i < S.Requests.Length; i++)
	{
		if (S.Requests[i].Transfer == 2 && S.CountryContinent(S.Requests[i].Country) == Continent)
		{
			Complete(NewGameState, S, i);
			return;
		}
	}
}

defaultproperties
{
}
