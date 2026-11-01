// Long War's hangar (features/lw-hangar.md): the interceptors, each based on a continent, repaired after a
// fight, refitted with the weapons engineering builds, sent to other continents, ordered in; and the
// Firestorms engineering builds. The jets are XComGameState_LWAirWar's; their hours pass with the
// Geoscape's clock (XComGameState_LWStrategy.Tick).
//
// Long War's rules, read from its code (XGFacility_Hangar, XGHeadQuarters.OrderInterceptors):
// - A jet fights only UFOs over its own continent, and only when ready (GetNumInterceptorsInRangeAndAvailable).
// - Damaged, it is repaired for RepairHours x the share of its HP lost (two thirds of that once the Foundry's
//   Advanced Repair is done), its HP coming back a little each hour (Update, DetermineInterceptorStatus).
// - Destroyed, it is gone (OnInterceptorDestroyed).
// - An interceptor costs InterceptorCost and arrives OrderHours later; a continent has HangarBays bays,
//   orders counted (GetContinentInfo, GetFreeHangerSpots).
// - A transfer takes TransferHours; a new weapon RearmHours to fit (missiles 12), the old one back to
//   the stores.
class LWHangar extends Object dependson(XComGameState_LWAirWar);

/** The air war's jets in this change, made part of it if they are not yet. */
static function XComGameState_LWAirWar InState(XComGameState NewGameState)
{
	local XComGameState_LWAirWar AirWar;

	class'XComGameState_LWAirWar'.static.EnsureExists();
	AirWar = XComGameState_LWAirWar(NewGameState.GetGameStateForObjectID(class'XComGameState_LWAirWar'.static.Get().ObjectID));
	if (AirWar == none)
		AirWar = XComGameState_LWAirWar(NewGameState.ModifyStateObject(class'XComGameState_LWAirWar', class'XComGameState_LWAirWar'.static.Get().ObjectID));
	return AirWar;
}

static function int HomeContinent()
{
	return class'LWStrategyRules'.default.Countries[0].Continent;
}

static function int MaxHp(XComGameState_LWAirWar.LWJet J)
{
	return class'LWAirWar'.static.Craft(J.Type, J.Weapon, 0).MaxHp;
}

static function bool IsReady(XComGameState_LWAirWar.LWJet J)
{
	return J.Status == 0 && J.HoursDown <= 0 && J.Hp > 0;
}

/** The ready jets over a continent (their indexes). */
static function array<int> ReadyOn(int Continent)
{
	local XComGameState_LWAirWar AirWar;
	local array<int> Out;
	local int i;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none)
		return Out;
	for (i = 0; i < AirWar.Jets.Length; i++)
		if (AirWar.Jets[i].Continent == Continent && IsReady(AirWar.Jets[i]))
			Out.AddItem(i);
	return Out;
}

/** The ready jets that can meet a Geoscape UFO (those over its country's continent). */
static function array<int> ReadyFor(int StrategyUfo)
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	return ReadyOn(S.CountryContinent(S.Ufos[StrategyUfo].Country));
}

/** How many (UnrealScript does not take .Length of a function's array result reliably). */
static function int CountReadyFor(int StrategyUfo)
{
	local array<int> Ready;

	Ready = ReadyFor(StrategyUfo);
	return Ready.Length;
}

/** The healthiest of them (-1: none). */
static function int BestFor(int StrategyUfo)
{
	local XComGameState_LWAirWar AirWar;
	local array<int> Ready;
	local int i, Best;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	Ready = ReadyFor(StrategyUfo);
	Best = -1;
	for (i = 0; i < Ready.Length; i++)
		if (Best < 0 || AirWar.Jets[Ready[i]].Hp > AirWar.Jets[Best].Hp)
			Best = Ready[i];
	return Best;
}

/** Jets based on a continent, or on their way there (with the orders, the bays taken). */
static function int BaysTaken(XComGameState_LWAirWar AirWar, int Continent)
{
	local int i, n;

	for (i = 0; i < AirWar.Jets.Length; i++)
		if (AirWar.Jets[i].Continent == Continent || (AirWar.Jets[i].Status == 6 && AirWar.Jets[i].TransferTo == Continent))
			n++;
	for (i = 0; i < AirWar.Orders.Length; i++)
		if (AirWar.Orders[i].Continent == Continent)
			n += AirWar.Orders[i].Count;
	return n;
}

/** After a fight (XComGameState_LWAirWar.Record): destroyed, it is gone; damaged, it goes for repair. */
static function AfterFight(XComGameState_LWAirWar AirWar, int Index)
{
	local XComGameState_LWAirWar.LWJet J;
	local float Hours;

	J = AirWar.Jets[Index];
	if (J.Hp <= 0)
	{
		AirWar.Jets.Remove(Index, 1);
		return;
	}
	if (J.Hp >= MaxHp(J))
		return;
	Hours = class'LWBaseRules'.default.RepairHours * (1.0 - float(J.Hp) / MaxHp(J));
	if (class'XComGameState_LWStrategy'.static.Get() != none && class'XComGameState_LWStrategy'.static.Get().FoundryDone.Find(5) != INDEX_NONE)
		Hours *= 0.67;
	AirWar.Jets[Index].Status = 4;
	AirWar.Jets[Index].HoursDown = Max(1, int(Hours));
}

/** An hour in the hangar: repairs, transfers, refits and orders move on (Long War's XGFacility_Hangar.Update). */
static function Hour(XComGameState NewGameState, XComGameState_LWStrategy S)
{
	local XComGameState_LWAirWar AirWar;
	local int i, k;

	if (class'XComGameState_LWAirWar'.static.Get() == none)
		return;
	AirWar = InState(NewGameState);
	for (i = 0; i < AirWar.Jets.Length; i++)
	{
		// A ready jet below its HP (a Foundry project raised it) goes in for repair (DetermineInterceptorStatus).
		if (AirWar.Jets[i].Status == 0 && AirWar.Jets[i].HoursDown <= 0 && AirWar.Jets[i].Hp < MaxHp(AirWar.Jets[i]))
			AfterFight(AirWar, i);
		if (AirWar.Jets[i].HoursDown <= 0)
			continue;
		AirWar.Jets[i].HoursDown--;
		if (AirWar.Jets[i].HoursDown > 0)
		{
			if (AirWar.Jets[i].Status == 4)
				AirWar.Jets[i].Hp += (MaxHp(AirWar.Jets[i]) - AirWar.Jets[i].Hp) / AirWar.Jets[i].HoursDown;
			continue;
		}
		switch (AirWar.Jets[i].Status)
		{
		case 4:
			AirWar.Jets[i].Hp = MaxHp(AirWar.Jets[i]);
			S.Note(AirWar.Jets[i].Callsign @ "is repaired.");
			break;
		case 6:
			AirWar.Jets[i].Continent = AirWar.Jets[i].TransferTo;
			S.Note(AirWar.Jets[i].Callsign @ "has arrived in" @ class'LWStrategyRules'.static.ContinentName(AirWar.Jets[i].Continent) $ ".");
			break;
		case 7:
			S.Note(AirWar.Jets[i].Callsign @ "is refitted with" @ WeaponName(AirWar.Jets[i].Weapon) $ ".");
			break;
		}
		AirWar.Jets[i].Status = 0;
	}
	for (i = AirWar.Orders.Length - 1; i >= 0; i--)
	{
		if (--AirWar.Orders[i].HoursLeft > 0)
			continue;
		for (k = 0; k < AirWar.Orders[i].Count; k++)
			NewJet(AirWar, 1, AirWar.Orders[i].Continent);
		S.Note(AirWar.Orders[i].Count @ (AirWar.Orders[i].Count == 1 ? "interceptor has" : "interceptors have") @ "arrived in" @ class'LWStrategyRules'.static.ContinentName(AirWar.Orders[i].Continent) $ ".");
		AirWar.Orders.Remove(i, 1);
		S.bStop = true;
	}
}

static function NewJet(XComGameState_LWAirWar AirWar, int Type, int Continent)
{
	AirWar.Counter++;
	AirWar.AddJet((Type == 3 ? "Firestorm-" : "Raven-") $ AirWar.Counter, Type, Type == 3 ? 3 : 3);
	AirWar.Jets[AirWar.Jets.Length - 1].Continent = Continent;
}

/** Craft built in engineering (a Firestorm), at home. */
static function AddCraft(XComGameState NewGameState, int Type, int Count)
{
	local XComGameState_LWAirWar AirWar;
	local int i;

	AirWar = InState(NewGameState);
	for (i = 0; i < Count; i++)
		NewJet(AirWar, Type, HomeContinent());
}

/** Interceptors ordered to a continent. Why says what stopped it. */
static function bool Order(int Continent, int Count, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWAirWar AirWar;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWAirWar.LWJetOrder O;

	class'XComGameState_LWAirWar'.static.EnsureExists();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (Continent < 0 || Continent > 4 || Count < 1)
	{
		Why = "No such continent.";
		return false;
	}
	if (BaysTaken(AirWar, Continent) + Count > class'LWBaseRules'.default.HangarBays)
	{
		Why = class'LWStrategyRules'.static.ContinentName(Continent) $ "'s hangar has" @ (class'LWBaseRules'.default.HangarBays - BaysTaken(AirWar, Continent)) @ "free bays.";
		return false;
	}
	if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < class'LWBaseRules'.default.InterceptorCost * Count)
	{
		Why = "They cost" @ class'LWStrategyRules'.static.Money(class'LWBaseRules'.default.InterceptorCost * Count) $ ".";
		return false;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: interceptors ordered");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -class'LWBaseRules'.default.InterceptorCost * Count);
	AirWar = InState(NewGameState);
	O.Continent = Continent;
	O.Count = Count;
	O.HoursLeft = class'LWBaseRules'.default.OrderHours;
	AirWar.Orders.AddItem(O);
	NoteIn(NewGameState, Count @ (Count == 1 ? "interceptor" : "interceptors") @ "ordered for" @ class'LWStrategyRules'.static.ContinentName(Continent) $ ", arriving in" @ (O.HoursLeft / 24) @ "days.");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Why = "";
	return true;
}

/** A ready jet sent to another continent. */
static function bool Transfer(int Index, int Continent, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWAirWar AirWar;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none || Index < 0 || Index >= AirWar.Jets.Length || Continent < 0 || Continent > 4)
	{
		Why = "No such jet or continent.";
		return false;
	}
	if (!IsReady(AirWar.Jets[Index]) || AirWar.Jets[Index].Continent == Continent)
	{
		Why = AirWar.Jets[Index].Callsign @ (AirWar.Jets[Index].Continent == Continent ? "is already there." : "is not ready.");
		return false;
	}
	if (BaysTaken(AirWar, Continent) >= class'LWBaseRules'.default.HangarBays)
	{
		Why = class'LWStrategyRules'.static.ContinentName(Continent) $ "'s hangar is full.";
		return false;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a jet transferred");
	AirWar = InState(NewGameState);
	AirWar.Jets[Index].Status = 6;
	AirWar.Jets[Index].TransferTo = Continent;
	AirWar.Jets[Index].HoursDown = class'LWBaseRules'.default.TransferHours;
	NoteIn(NewGameState, AirWar.Jets[Index].Callsign @ "is on its way to" @ class'LWStrategyRules'.static.ContinentName(Continent) $ ".");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Why = "";
	return true;
}

/** The interceptors' weapons: Long War's ship weapon (LWAirWar) and the item it is built as ('' : always there). */
static function name WeaponItem(int Weapon)
{
	switch (Weapon)
	{
	case 1: return 'LWItem_IntWeap_I';
	case 4: return 'LWItem_IntWeap_III';
	case 5: return 'LWItem_IntWeap_IV';
	case 6: return 'LWItem_IntWeap_V';
	case 7: return 'LWItem_IntWeap_VI';
	}
	return '';
}

static function string WeaponName(int Weapon)
{
	local LWAirWar.LWWeaponDef W;

	foreach class'LWAirWar'.default.Weapons(W)
		if (W.Id == Weapon)
			return W.Name;
	return "weapon" @ Weapon;
}

/** A ready jet refitted with a weapon from the stores (Avalanche and Stingray missiles always there). */
static function bool Equip(int Index, int Weapon, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWAirWar AirWar;
	local name Item;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none || Index < 0 || Index >= AirWar.Jets.Length || Weapon < 1 || Weapon > 7)
	{
		Why = "No such jet or weapon.";
		return false;
	}
	if (!IsReady(AirWar.Jets[Index]) || AirWar.Jets[Index].Weapon == Weapon)
	{
		Why = AirWar.Jets[Index].Callsign @ (AirWar.Jets[Index].Weapon == Weapon ? "carries it already." : "is not ready.");
		return false;
	}
	Item = WeaponItem(Weapon);
	if (Item != '' && class'LWEngineering'.static.Held(Item) < 1)
	{
		Why = "None in the stores: engineering builds" @ WeaponName(Weapon) $ ".";
		return false;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a jet refitted");
	if (Item != '')
		class'LWEngineering'.static.Take(NewGameState, Item, 1);
	if (WeaponItem(AirWar.Jets[Index].Weapon) != '')
		class'X2Item_LWArtifacts'.static.GiveItem(NewGameState, WeaponItem(AirWar.Jets[Index].Weapon), 1);
	AirWar = InState(NewGameState);
	AirWar.Jets[Index].Weapon = Weapon;
	AirWar.Jets[Index].Status = 7;
	AirWar.Jets[Index].HoursDown = (Weapon == 2 || Weapon == 3) ? 12 : class'LWBaseRules'.default.RearmHours;
	NoteIn(NewGameState, AirWar.Jets[Index].Callsign @ "is being refitted with" @ WeaponName(Weapon) $ ", ready in" @ AirWar.Jets[Index].HoursDown @ "hours.");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Why = "";
	return true;
}

static function NoteIn(XComGameState NewGameState, string Text)
{
	local XComGameState_LWStrategy S;

	if (class'XComGameState_LWStrategy'.static.Get() == none)
		return;
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
	S.Note(Text);
}

/** The craft's upkeep a month (GetShipMaintenanceCost, the Skyranger apart). */
static function int Upkeep()
{
	local XComGameState_LWAirWar AirWar;
	local int i, U;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none)
		return 0;
	for (i = 0; i < AirWar.Jets.Length; i++)
		U += AirWar.Jets[i].Type == 3 ? class'LWBaseRules'.default.FirestormUpkeep : class'LWBaseRules'.default.InterceptorUpkeep;
	return U;
}

/** A jet as the hangar screen and the control port show it. */
static function string JetText(XComGameState_LWAirWar.LWJet J)
{
	local string Status;

	switch (J.Status)
	{
	case 4: Status = "repairing," @ J.HoursDown $ "h"; break;
	case 6: Status = "to" @ class'LWStrategyRules'.static.ContinentName(J.TransferTo) $ "," @ J.HoursDown $ "h"; break;
	case 7: Status = "refitting," @ J.HoursDown $ "h"; break;
	default: Status = "ready";
	}
	return J.Callsign @ "(" $ (J.Type == 3 ? "Firestorm" : "Interceptor") $ "," @ WeaponName(J.Weapon) $ ")" @ class'LWStrategyRules'.static.ContinentName(J.Continent) @ "HP" @ J.Hp $ "/" $ MaxHp(J) @ "kills" @ J.Kills @ "-" @ Status;
}
