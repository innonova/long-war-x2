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

/** The home country's continent, where XCOM's base and first jets are. */
static function int HomeContinent()
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	return class'LWStrategyRules'.default.Countries[S != none ? S.HomeCountry() : 0].Continent;
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

/** After a fight (XComGameState_LWAirWar.Record): destroyed, it is gone; damaged, it goes for repair; whole, it refuels for an
 *  hour (Long War's XGFacility_Hangar.DetermineInterceptorStatus: a jet back with less than a full tank). */
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
	{
		AirWar.Jets[Index].Status = 2;
		AirWar.Jets[Index].HoursDown = 1;
		return;
	}
	Hours = class'LWBaseRules'.default.RepairHours * (1.0 - float(J.Hp) / MaxHp(J));
	// Dynamic War (second wave #9, XGFacility_Hangar): ÷ SW_MARATHON.
	if (class'LWX2SecondWave'.static.On(9) && class'LWX2SecondWave'.default.Marathon > 0)
		Hours /= class'LWX2SecondWave'.default.Marathon;
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
			class'LWCouncilRequests'.static.JetArrived(NewGameState, S, AirWar.Jets[i].Continent);
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
		class'LWCouncilRequests'.static.JetArrived(NewGameState, S, AirWar.Orders[i].Continent);
		AirWar.Orders.Remove(i, 1);
		S.bStop = true;
	}
	AssignBays(AirWar);
}

static function NewJet(XComGameState_LWAirWar AirWar, int Type, int Continent)
{
	AirWar.Counter++;
	AirWar.AddJet((Type == 3 ? "Firestorm-" : "Raven-") $ AirWar.Counter, Type, Type == 3 ? 3 : 3);
	AirWar.Jets[AirWar.Jets.Length - 1].Continent = Continent;
	AssignBays(AirWar);
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
/**
 * Long War's ferry restriction (its XGStrategyAI.CostAlienSquad, asked before a transfer or a change of loadout): none while
 * a UFO on a retaliation (Long War's objectives 9 and 10) is in flight, or an airbase defence waits (the port has none).
 */
static function bool FerryRestricted()
{
	local XComGameState_LWStrategy S;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = 0; S != none && i < S.Ufos.Length; i++)
		if (S.Ufos[i].Status == 1 && (S.Ufos[i].Objective == 9 || S.Ufos[i].Objective == 10))
			return true;
	return false;
}

/** A craft dismissed (XGFacility_Hangar.RemoveInterceptor): gone, its weapon back to the stores unless it was shot to
 *  pieces. Not while it is in the air or transferring (UIShipSummary.OnDismissShip). */
static function bool Dismiss(int Index, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWAirWar AirWar;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none || Index < 0 || Index >= AirWar.Jets.Length)
	{
		Why = "No such craft.";
		return false;
	}
	if (AirWar.Jets[Index].Status == 1 || AirWar.Jets[Index].Status == 6)
	{
		Why = AirWar.Jets[Index].Callsign @ "is away.";
		return false;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a craft dismissed");
	if (AirWar.Jets[Index].Hp > 0 && WeaponItem(AirWar.Jets[Index].Weapon) != '')
		class'X2Item_LWArtifacts'.static.GiveItem(NewGameState, WeaponItem(AirWar.Jets[Index].Weapon), 1);
	AirWar = InState(NewGameState);
	NoteIn(NewGameState, AirWar.Jets[Index].Callsign @ "was dismissed.");
	AirWar.Jets.Remove(Index, 1);
	AssignBays(AirWar);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

/** A craft given one of Long War's pilots (UIShipSummary's RENAME: XGLocalizedData.ShipWeaponFlavorTxt[11 + Rand(245)]). */
static function Rename(int Index, string Callsign)
{
	local XComGameState NewGameState;
	local XComGameState_LWAirWar AirWar;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none || Index < 0 || Index >= AirWar.Jets.Length || Callsign == "")
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a craft renamed");
	AirWar = InState(NewGameState);
	AirWar.Jets[Index].Callsign = Callsign;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** One interceptor of a continent's order cancelled (XGHeadQuarters.ReduceInterceptorOrder): its price back, the order one
 *  smaller, gone at none. False if the continent has no order. */
/**
 * The base's hangar bays (Long War's XGFacility_Hangar.GetAvailableBay, as a jet arrives at the base, is built there or comes
 * back from a transfer; m_iHomeBay -1 as it leaves): a jet based on the home continent keeps its bay, one without takes the
 * lowest free one; a jet based elsewhere or on its way has none. What the base's hangar shows (LWX2EWBase.RefreshBays).
 */
static function AssignBays(XComGameState_LWAirWar AirWar, optional int Home = -1)
{
	local int i, b;
	local array<int> Taken;

	if (Home < 0)
		Home = HomeContinent();
	for (i = 0; i < AirWar.Jets.Length; i++)
		if (AirWar.Jets[i].Continent != Home || AirWar.Jets[i].Status == 6)
			AirWar.Jets[i].Bay = 0;
		else if (AirWar.Jets[i].Bay > 0)
			Taken.AddItem(AirWar.Jets[i].Bay);
	for (i = 0; i < AirWar.Jets.Length; i++)
	{
		if (AirWar.Jets[i].Bay > 0 || AirWar.Jets[i].Continent != Home || AirWar.Jets[i].Status == 6)
			continue;
		for (b = 1; b <= 4 && Taken.Find(b) != INDEX_NONE; b++);
		if (b > 4)
			break;
		AirWar.Jets[i].Bay = b;
		Taken.AddItem(b);
	}
}

/** A test aid (the control port's jet): a jet's status and hours down set, or its kind (1 Interceptor, 3 Firestorm). */
static function bool TestSetJet(int Index, int Status, int Hours, optional int Type)
{
	local XComGameState NewGameState;
	local XComGameState_LWAirWar AirWar;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none || Index < 0 || Index >= AirWar.Jets.Length)
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a jet set (test aid)");
	AirWar = InState(NewGameState);
	AirWar.Jets[Index].Status = Status;
	AirWar.Jets[Index].HoursDown = Hours;
	if (Type > 0)
		AirWar.Jets[Index].Type = Type;
	AssignBays(AirWar);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

static function bool CancelOrder(int Continent)
{
	local XComGameState NewGameState;
	local XComGameState_LWAirWar AirWar;
	local XComGameState_HeadquartersXCom XComHQ;
	local int i;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none)
		return false;
	for (i = 0; i < AirWar.Orders.Length && AirWar.Orders[i].Continent != Continent; i++);
	if (i >= AirWar.Orders.Length)
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: an interceptor order cancelled");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', class'LWBonusEffects'.static.AirCost(class'LWBaseRules'.default.InterceptorCost));
	AirWar = InState(NewGameState);
	AirWar.Orders[i].Count--;
	if (AirWar.Orders[i].Count <= 0)
		AirWar.Orders.Remove(i, 1);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

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
	if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < class'LWBonusEffects'.static.AirCost(class'LWBaseRules'.default.InterceptorCost) * Count)
	{
		Why = "They cost" @ class'LWStrategyRules'.static.Money(class'LWBonusEffects'.static.AirCost(class'LWBaseRules'.default.InterceptorCost) * Count) $ ".";
		return false;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: interceptors ordered");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -class'LWBonusEffects'.static.AirCost(class'LWBaseRules'.default.InterceptorCost) * Count);
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
	if (FerryRestricted())
	{
		Why = "Ferry flights are restricted while a retaliation is under way.";
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
	AssignBays(AirWar);
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
		U += class'LWBonusEffects'.static.AirCost(AirWar.Jets[i].Type == 3 ? class'LWBaseRules'.default.FirestormUpkeep : class'LWBaseRules'.default.InterceptorUpkeep);
	return U;
}

/** A jet as the hangar screen and the control port show it. */
static function string JetText(XComGameState_LWAirWar.LWJet J)
{
	local string Status;

	switch (J.Status)
	{
	case 2: Status = "refuelling," @ J.HoursDown $ "h"; break;
	case 4: Status = "repairing," @ J.HoursDown $ "h"; break;
	case 6: Status = "to" @ class'LWStrategyRules'.static.ContinentName(J.TransferTo) $ "," @ J.HoursDown $ "h"; break;
	case 7: Status = "refitting," @ J.HoursDown $ "h"; break;
	default: Status = "ready";
	}
	return J.Callsign @ "(" $ (J.Type == 3 ? "Firestorm" : "Interceptor") $ "," @ WeaponName(J.Weapon) $ ")" @ class'LWStrategyRules'.static.ContinentName(J.Continent) @ "HP" @ J.Hp $ "/" $ MaxHp(J) @ "kills" @ J.Kills @ "-" @ Status;
}
