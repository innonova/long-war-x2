// Enemy Within's Hire Soldiers dialog over the barracks (features/strategy-flow.md): its Hiring movie, driven as EW's
// UIHiring_Barracks drives it for XGBarracksUI's hiring view: the title, the soldier icon, the count on its spinner
// (widgetHelper; red when it cannot be paid for), the cost and the barracks' room (UpdateInfo; red when over), the HIRE
// button (SetMouseConfirmText, theConfirmButton) and CANCEL (its help bar). The count starts at 1 and stays within 1 and
// the barracks' room (XGBarracksUI.OnIncreaseHiringOrder, OnDecreaseHiringOrder); HIRE orders them (LWHiring.Order).
// The same dialog orders interceptors into a continent's hangar (EW's UIHiring_Hangar over XGHangarUI.UpdateHireDisplay):
// ORDER INTERCEPTORS, the jet icon, the initial cost and the monthly cost, the hangar's capacity (its craft and those on
// order), ORDER (LWHangar.Order).
class UILWEWHiring extends UILWEWScreen;

var localized string Title, CostLabel, CapacityLabel, HireLabel, NoMoney, Full, Event;
var localized string OrderTitle, OrderCostLabel, MonthlyCostLabel, HangarCapacityLabel, OrderLabel;

var int Count;
/** The continent whose hangar interceptors are ordered into; -1: soldiers hired. */
var int Continent;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWHiring S;

	DynamicLoadObject(default.UIPackage $ ".ewxHiring", class'Object', true);
	S = HQPres.Spawn(class'UILWEWHiring', HQPres);
	S.Package = name("/ package/ewxHiring/Hiring");
	S.MCName = 'theHiringScreen';
	S.Continent = -1;
	HQPres.ScreenStack.Push(S);
}

/** Interceptors ordered into a continent's hangar (UIShipList's ORDER INTERCEPTORS). */
static function OpenOrder(XComHQPresentationLayer HQPres, int ContinentIndex)
{
	local UILWEWHiring S;

	DynamicLoadObject(default.UIPackage $ ".ewxHiring", class'Object', true);
	S = HQPres.Spawn(class'UILWEWHiring', HQPres);
	S.Package = name("/ package/ewxHiring/Hiring");
	S.MCName = 'theHiringScreen';
	S.Continent = ContinentIndex;
	HQPres.ScreenStack.Push(S);
}

simulated function OnInit()
{
	super.OnInit();
	Count = 1;
	if (Continent >= 0)
	{
		MC.FunctionString("SetTitle", EWColoured(Caps(Word(OrderTitle, "Order Interceptors")), 0));
		MC.FunctionString("SetIcon", "jet");
		MC.FunctionString("SetMouseConfirmText", Word(OrderLabel, "ORDER"));
	}
	else
	{
		MC.FunctionString("SetTitle", class'UIUtilities_Text'.static.GetColoredText(Caps(Word(Title, "Hire Soldiers")), eUIState_Normal));
		MC.FunctionString("SetIcon", "soldier");
		MC.FunctionString("SetMouseConfirmText", Word(HireLabel, "HIRE"));
	}
	HelpButton("helpBarMC", false, 0, class'UIUtilities_Text'.default.m_strGenericCancel, "Icon_B_CIRCLE");
	Refresh();
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

/** EW's lines and the count (XGBarracksUI.UpdateHiring). */
function Refresh()
{
	local XComGameState_LWStrategy S;
	local int Wanted, Cost;
	local bool bAfford;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return;
	if (Continent >= 0)
	{
		RefreshOrder();
		return;
	}
	Wanted = class'LWHiring'.static.Counted(S) + Count;
	Cost = class'LWHiring'.static.Cost(S) * Count;
	bAfford = Cost <= class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies();
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(Word(CostLabel, "Hiring Cost:") $ "<br>" $ class'LWStrategyRules'.static.Money(Cost), bAfford ? eUIState_Good : eUIState_Bad));
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(Word(CapacityLabel, "Barracks Capacity:") $ "<br>" $ Wanted $ "/" $ class'LWHiring'.static.Capacity(), Wanted >= class'LWHiring'.static.Capacity() ? eUIState_Bad : eUIState_Normal));
	MC.EndOp();
	MC.BeginChildFunctionOp("widgetHelper", "SetSpinnerValue");
	MC.QueueNumber(0);
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(string(Count), bAfford ? eUIState_Normal : eUIState_Bad));
	MC.EndOp();
	MC.BeginChildFunctionOp("widgetHelper", "SetSpinnerArrows");
	MC.QueueNumber(0);
	MC.QueueBoolean(true);
	MC.EndOp();
	MC.ChildFunctionNum("widgetHelper", "SetSelected", 0);
}

/** XGHangarUI.UpdateHireDisplay: the cost (green, red when it cannot be paid), the monthly cost (yellow), the hangar's
 *  capacity (red when over), the count. */
function RefreshOrder()
{
	local XComGameState_LWAirWar AirWar;
	local int Wanted, Cost;
	local bool bAfford;

	class'XComGameState_LWAirWar'.static.EnsureExists();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	Wanted = class'LWHangar'.static.BaysTaken(AirWar, Continent) + Count;
	Cost = class'LWBonusEffects'.static.AirCost(class'LWBaseRules'.default.InterceptorCost) * Count;
	bAfford = Cost <= class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies();
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(EWColoured(Word(OrderCostLabel, "Initial Cost:") $ "<br>" $ class'LWStrategyRules'.static.Money(Cost), bAfford ? 6 : 3) $ "<br>"
		$ EWColoured(Word(MonthlyCostLabel, "Monthly Cost:") $ "<br>" $ class'LWStrategyRules'.static.Money(class'LWBonusEffects'.static.AirCost(class'LWBaseRules'.default.InterceptorUpkeep) * Count), 4) $ "<br>");
	MC.QueueString(EWColoured(Word(HangarCapacityLabel, "Hangar Capacity:") $ "<br>" $ Wanted $ "/" $ class'LWBaseRules'.default.HangarBays, Wanted > class'LWBaseRules'.default.HangarBays ? 3 : 0));
	MC.EndOp();
	MC.BeginChildFunctionOp("widgetHelper", "SetSpinnerValue");
	MC.QueueNumber(0);
	MC.QueueString(EWColoured(string(Count), bAfford ? 0 : 3));
	MC.EndOp();
	MC.BeginChildFunctionOp("widgetHelper", "SetSpinnerArrows");
	MC.QueueNumber(0);
	MC.QueueBoolean(true);
	MC.EndOp();
	MC.ChildFunctionNum("widgetHelper", "SetSelected", 0);
}

function Change(int By)
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	// (OnIncreaseHiringOrder: not past the hangar's bays.)
	if (Continent >= 0 && By > 0 && class'LWHangar'.static.BaysTaken(class'XComGameState_LWAirWar'.static.Get(), Continent) + Count + By > class'LWBaseRules'.default.HangarBays)
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	if (Continent < 0 && By > 0 && class'LWHiring'.static.Counted(S) + Count + By > class'LWHiring'.static.Capacity())
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	Count = Max(1, Count + By);
	PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
	Refresh();
}

function Hire()
{
	local string Why;

	if (Continent >= 0)
	{
		if (class'LWHangar'.static.Order(Continent, Count, Why))
		{
			PlaySound(SoundCue'SoundUI.PositiveUISelctionCue', true);
			CloseScreen();
		}
		else
		{
			`log("LongWarX2: EW interceptor order:" @ Why, , 'LongWarX2');
			PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		}
		return;
	}
	if (class'LWHiring'.static.Order(Count))
	{
		PlaySound(SoundCue'SoundUI.PositiveUISelctionCue', true);
		CloseScreen();
	}
	else
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string All;
	local int i;

	super.OnMouseEvent(cmd, args);
	if (cmd != 391 && cmd != 398)
		return;
	for (i = 0; i < args.Length; i++)
		All $= "." $ args[i];
	if (InStr(All, "theConfirmButton") != INDEX_NONE)
		Hire();
	// (The spinner's arrows: …option0, then the arrow as its last part, -1 up, -2 down: EW's ProcessMouseEvent_Spinner.)
	else if (InStr(All, "option") != INDEX_NONE && args[args.Length - 1] == "-1")
		Change(1);
	else if (InStr(All, "option") != INDEX_NONE && args[args.Length - 1] == "-2")
		Change(-1);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
			if (HelpButtonUnderMouse() == "")
				break;
			CloseScreen();
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			Change(1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			Change(-1);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Hire();
			return true;
		}
	}
	return super.OnUnrealCommand(cmd, arg);
}
