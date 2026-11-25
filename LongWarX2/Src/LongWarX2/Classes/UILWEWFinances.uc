// Enemy Within's XCOM finances (features/strategy-flow.md; the Situation Room's View XCOM Finances): its BaseFinances movie,
// driven as EW's UIBaseFinances drives it from Long War's XGFinanceUI.UpdateMain: the title, the net monthly income, the
// gross (the council's funding), then craft maintenance (each kind of jet and the Skyranger), staff salaries (none in Long
// War) and facility maintenance (each facility kind built), each with its total.
class UILWEWFinances extends UILWEWScreen;

/** Long War's words (XGFinanceUI; the craft's names, ShipTypeNames), from the player's install (lw-words.mjs). */
var localized string Title, Net, Gross, Salary, Craft, Facilities, Interceptor, Firestorm, Skyranger;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWFinances S;

	DynamicLoadObject(default.UIPackage $ ".ewxBaseFinances", class'Object', true);
	S = HQPres.Spawn(class'UILWEWFinances', HQPres);
	S.Package = name("/ package/ewxBaseFinances/BaseFinances");
	S.MCName = 'theScreen';
	HQPres.ScreenStack.Push(S);
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

simulated function OnInit()
{
	super.OnInit();
	Fill();
}

/** A sum as EW writes it here: + and green when not negative, red otherwise (XGFinanceUI's ltxt states 6 and 3). */
static function string Signed(int Cash)
{
	return Cash >= 0 ? class'UIUtilities_Text'.static.GetColoredText("+" $ class'LWStrategyRules'.static.Money(Cash), eUIState_Good)
		: class'UIUtilities_Text'.static.GetColoredText(class'LWStrategyRules'.static.Money(Cash), eUIState_Bad);
}

function Section(int Index, string Subtitle, int Total, string Labels, string Values)
{
	MC.BeginFunctionOp("SetSection");
	MC.QueueNumber(Index);
	MC.QueueString(Caps(Subtitle));
	// (A cost as EW writes it, negative: XGFinanceUI's titles are the maintenance costs, which EW keeps negative; an empty
	// section, the salaries', has no sum at all.)
	MC.QueueString(Subtitle == "" ? "" : class'UIUtilities_Text'.static.GetColoredText(class'LWStrategyRules'.static.Money(-Total), eUIState_Bad));
	MC.QueueString(Labels);
	MC.QueueString(Values);
	MC.EndOp();
}

function Fill()
{
	local XComGameState_LWStrategy S;
	local XComGameState_LWAirWar AirWar;
	local LWBaseRules.LWFacilityDef F;
	local string Labels, Values;
	local int i, n, Jets, Storms, Income, Each, Total, Id;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return;
	for (i = 0; i < S.Countries.Length; i++)
		if (!S.Countries[i].bLeft)
			Income += S.CountryFunding(i, S.Countries[i].bSatellite);
	MC.FunctionString("SetTitle", Word(Title, "CASH FLOW STATEMENT"));
	MC.FunctionString("SetNet", Word(Net, "NET MONTHLY INCOME:") @ Signed(S.MonthlyNet()));
	MC.BeginFunctionOp("SetSection");
	MC.QueueNumber(0);
	MC.QueueString(Caps(Word(Gross, "GROSS MONTHLY INCOME")));
	MC.QueueString(Signed(Income));
	MC.QueueString("");
	MC.QueueString("");
	MC.EndOp();
	// Craft maintenance (XGFinanceUI.BuildCraftUI): the interceptors, the Firestorms, the Skyranger.
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	for (i = 0; AirWar != none && i < AirWar.Jets.Length; i++)
	{
		if (AirWar.Jets[i].Type == 3)
			Storms++;
		else
			Jets++;
	}
	Labels = "";
	Values = "";
	if (Jets > 0)
	{
		Each = class'LWBonusEffects'.static.AirCost(class'LWBaseRules'.default.InterceptorUpkeep);
		Labels $= Jets $ "x" @ Word(Interceptor, "Interceptor") $ "\n";
		Values $= class'LWStrategyRules'.static.Money(-Each * Jets) $ "\n";
	}
	if (Storms > 0)
	{
		Each = class'LWBonusEffects'.static.AirCost(class'LWBaseRules'.default.FirestormUpkeep);
		Labels $= Storms $ "x" @ Word(Firestorm, "Firestorm") $ "\n";
		Values $= class'LWStrategyRules'.static.Money(-Each * Storms) $ "\n";
	}
	Labels $= "1x" @ Word(Skyranger, "Skyranger") $ "\n";
	Values $= class'LWStrategyRules'.static.Money(-class'LWBaseRules'.default.SkyrangerUpkeep) $ "\n";
	Section(1, Word(Craft, "Craft Maintenance"), class'LWHangar'.static.Upkeep() + class'LWBaseRules'.default.SkyrangerUpkeep, Labels, Values);
	// Staff salaries: none in Long War (BuildSalaryUI makes an empty section: no title, no sum).
	Section(2, "", 0, "", "");
	// Facility maintenance (BuildFacilityUI): each kind built, in EW's order of facilities (0 to 23), its count and its
	// cost, the starting rooms too at §0 (EW lists every kind with a maintenance of 0 or more).
	Labels = "";
	Values = "";
	Total = 0;
	for (Id = 0; Id < 24; Id++)
	{
		if (!class'LWBaseRules'.static.FacilityFor(Id, F))
			continue;
		class'LWBonusEffects'.static.AdjustFacility(F);
		n = S.TileType.Length > 0 ? class'LWBase'.static.Count(S, F.Id) : 0;
		if (n <= 0 || F.Upkeep < 0)
			continue;
		Labels $= n $ "x" @ class'LWBase'.static.FacilityName(F.Id) $ "\n";
		Values $= class'LWStrategyRules'.static.Money(-F.Upkeep * n) $ "\n";
		Total += F.Upkeep * n;
	}
	Section(3, Word(Facilities, "Facility Maintenance"), Total, Labels, Values);
}

defaultproperties
{
	BaseCamera = Cam_SituationRoom
}
