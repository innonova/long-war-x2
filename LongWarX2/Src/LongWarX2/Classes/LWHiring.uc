// Hiring soldiers, as Long War hires them (features/strategy-flow.md; EW's barracks, Hire Soldiers): an order of n rookies
// costs n x the soldier's cost (XGItemTree.SetSoldierStaffCost: SOLDIER_COST, less what bonus 38 takes off), is paid at
// once and arrives after the delivery time (XGItemTree.BuildStaffTypes; orders for the same arrival are one, as
// XGHeadQuarters.OrderStaff merges them). The barracks hold so many (BARRACKS_CAPACITY; XGBarracksUI.OnIncreaseHiringOrder
// counts the soldiers there and on order). Each hour every order counts down; at its end the rookies arrive as Long War
// makes them (XGHeadQuarters.UpdateHiringOrders, XGFacility_Barracks.AddNewSoldiers: LWBonusEffects.NewSoldier), and time
// is stopped for the news.
class LWHiring extends Object;

/** A soldier's cost now. */
static function int Cost(optional XComGameState_LWStrategy S)
{
	return Max(0, class'LWStrategyRules'.default.SoldierCost - class'LWBonuses'.static.Has(38, S));
}

/** Soldiers in the barracks and on order. */
static function int Counted(XComGameState_LWStrategy S)
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetNumberOfSoldiers() + OnOrder(S);
}

static function int OnOrder(XComGameState_LWStrategy S)
{
	local int i, n;

	for (i = 0; i < S.HiringOrders.Length; i++)
		n += S.HiringOrders[i].Count;
	return n;
}

static function int Capacity()
{
	return class'LWStrategyRules'.default.BarracksCapacity;
}

/** Whether n more can be ordered now, and if not, why (Why: "money" or "room"). */
static function bool CanOrder(XComGameState_LWStrategy S, int n, out string Why)
{
	Why = "";
	if (n <= 0)
		Why = "none";
	else if (Counted(S) + n > Capacity())
		Why = "room";
	else if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < n * Cost(S))
		Why = "money";
	return Why == "";
}

/** n rookies ordered and paid for (XGHeadQuarters.OrderStaff); false when they cannot be. */
static function bool Order(int n)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy.LWHiringOrder O;
	local string Why;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || !CanOrder(S, n, Why))
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: soldiers hired");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -n * Cost(S));
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	for (i = 0; i < S.HiringOrders.Length; i++)
		if (S.HiringOrders[i].HoursLeft == class'LWStrategyRules'.default.SoldierDeliveryHours)
			break;
	if (i < S.HiringOrders.Length)
		S.HiringOrders[i].Count += n;
	else
	{
		O.Count = n;
		O.HoursLeft = class'LWStrategyRules'.default.SoldierDeliveryHours;
		S.HiringOrders.AddItem(O);
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("LongWarX2: hiring:" @ n @ "soldiers ordered, arriving in" @ class'LWStrategyRules'.default.SoldierDeliveryHours @ "hours", , 'LongWarX2');
	return true;
}

/** An hour of the orders (XComGameState_LWStrategy.Tick, S already in NewGameState). */
static function Hour(XComGameState NewGameState, XComGameState_LWStrategy S)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int i, k;

	for (i = S.HiringOrders.Length - 1; i >= 0; i--)
	{
		if (--S.HiringOrders[i].HoursLeft > 0)
			continue;
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
		if (XComHQ == none)
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
		for (k = 0; k < S.HiringOrders[i].Count; k++)
			class'LWBonusEffects'.static.NewSoldier(NewGameState, XComHQ, 0, 0);
		S.Notice(class'UILWEWAlert'.default.NoticeNewSoldiers, "New soldiers on site: <XGParam:IntValue0/>", , , S.HiringOrders[i].Count);
		S.Note(S.HiringOrders[i].Count == 1 ? "A new soldier has arrived at XCOM HQ." : S.HiringOrders[i].Count @ "new soldiers have arrived at XCOM HQ.");
		S.HiringOrders.Remove(i, 1);
		S.bStop = true;
	}
}
