// Long War's engineering (features/lw-gear.md, phase 3): what research has unlocked is built for Long
// War's money, alloys, elerium, meld and items, in Long War's time (XGFacility_Engineering). The
// projects are the Geoscape's (XComGameState_LWStrategy.Builds), and move on with its clock.
//
// Long War's rules: an item can be built once its tech is researched and its Foundry project done
// (XGItemTree.CanBuildItem); the cost is paid when the project starts (AddItemProject), the item it
// needs consumed, one per item. A project of n items has n x the item's engineers on it, however many
// XCOM has (Long War took away the original's "not enough engineers"), and the whole batch is done
// when one item's work is (UpdateItemProject); its work is Days x Engineers x 24 hours (GetItemBuildTime)
// and the engineers make GetWorkPerHour of it an hour: about all of XCOM's engineers when the project
// has that many, less and less the more it is short of them.
class LWEngineering extends Object dependson(LWGearRules, XComGameState_LWStrategy);

/** Has research (and the Foundry) unlocked the item? */
static function bool Unlocked(LWGearRules.LWBuildDef B)
{
	local name Tech;

	if (B.Tech != 0)
	{
		Tech = class'LWResearchRules'.static.TemplateForId(B.Tech);
		if (Tech == '' || !class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(Tech))
			return false;
	}
	return B.Foundry == 0 || (class'XComGameState_LWStrategy'.static.Get() != none && class'XComGameState_LWStrategy'.static.Get().FoundryDone.Find(B.Foundry) != INDEX_NONE);
}

/** The cash an item costs: less with workshops and engineering adjacencies (XGItemTree.ScaleCost). */
static function int CashCost(LWGearRules.LWBuildDef B)
{
	return int(B.Cash * class'LWBase'.static.WorkshopCashScale(class'XComGameState_LWStrategy'.static.Get()));
}

/** How many of an item are in XCOM's stores (its XCOM 2 template). */
static function int Held(name ItemName)
{
	local XComGameState_Item Item;

	Item = class'UIUtilities_Strategy'.static.GetXComHQ().GetItemByName(ItemName);
	return Item != none ? Item.Quantity : 0;
}

static function bool IsInfinite(name ItemName)
{
	local X2ItemTemplate Template;

	Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemName);
	return Template != none && Template.bInfiniteItem;
}

/** What is short for n of an item ("" if nothing). */
static function string Short(LWGearRules.LWBuildDef B, int n)
{
	local array<string> Out;

	if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < CashCost(B) * n)
		Out.AddItem(class'LWStrategyRules'.static.Money(CashCost(B) * n));
	if (Held('AlienAlloy') < B.Alloys * n)
		Out.AddItem(B.Alloys * n @ class'X2Item_LWArtifacts'.static.DisplayName('Alloys'));
	if (Held('EleriumDust') < B.Elerium * n)
		Out.AddItem(B.Elerium * n @ class'X2Item_LWArtifacts'.static.DisplayName('Elerium'));
	if (Held(class'X2Item_LWArtifacts'.static.ItemFor('Meld')) < B.Meld * n)
		Out.AddItem(B.Meld * n @ class'X2Item_LWArtifacts'.static.DisplayName('Meld'));
	if (B.ItemReq != '' && !IsInfinite(B.ItemReq) && Held(B.ItemReq) < n)
		Out.AddItem(n @ ItemName(B.ItemReq));
	return JoinStrings(Out);
}

static function string JoinStrings(array<string> Parts)
{
	local string S;
	local int i;

	for (i = 0; i < Parts.Length; i++)
		S $= (i > 0 ? ", " : "") $ Parts[i];
	return S;
}

static function string ItemName(name ItemName)
{
	local X2ItemTemplate Template;

	Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemName);
	return (Template != none && Template.GetItemFriendlyName() != "") ? Template.GetItemFriendlyName() : string(ItemName);
}

/** An item's cost as the Geoscape shows it. */
static function string CostText(LWGearRules.LWBuildDef B)
{
	local array<string> Out;

	Out.AddItem(class'LWStrategyRules'.static.Money(CashCost(B)));
	if (B.Alloys > 0)
		Out.AddItem(B.Alloys @ class'X2Item_LWArtifacts'.static.DisplayName('Alloys'));
	if (B.Elerium > 0)
		Out.AddItem(B.Elerium @ class'X2Item_LWArtifacts'.static.DisplayName('Elerium'));
	if (B.Meld > 0)
		Out.AddItem(B.Meld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld'));
	if (B.ItemReq != '')
		Out.AddItem("1" @ ItemName(B.ItemReq));
	return JoinStrings(Out);
}

/** One item's work, in engineer hours (GetItemBuildTime). */
static function int UnitWork(LWGearRules.LWBuildDef B)
{
	return int(B.Days * B.Engineers * 24 * class'LWGearRules'.default.TimeBalance);
}

/**
 * The work a project's engineers do in an hour (XGFacility_Engineering.GetWorkPerHour): n / (0.5 x
 * (1 + (n / XCOM's engineers) ^ min(50, 2 x rate x n))), at least 1 and at most XCOM's engineers.
 */
static function int WorkPerHour(int OnProject, int Engineers)
{
	local int w;

	if (Engineers <= 0)
		return 0;
	w = int(OnProject / (0.5 * (1.0 + (float(OnProject) / Engineers) ** FMin(50, 2 * class'LWGearRules'.default.EngineerRate * OnProject))));
	return Min(Max(1, w), Engineers);
}

/** Hours until a project of n items is done, with XCOM's engineers as they are. */
static function int HoursFor(int Work, int OnProject, int Engineers)
{
	local int w;

	w = WorkPerHour(OnProject, Engineers);
	if (Work <= 0)
		return 0;
	return w > 0 ? (Work + w - 1) / w : 999999;
}

static function string HoursText(int Hours)
{
	if (Hours >= 999999)
		return "never (no engineers)";
	if (Hours < 24)
		return Hours @ (Hours == 1 ? "hour" : "hours");
	return (Hours + 23) / 24 @ "days";
}

/** The items research has unlocked, in the config's order. */
static function array<int> Buildable()
{
	local array<int> Out;
	local LWGearRules.LWBuildDef B;

	foreach class'LWGearRules'.default.Builds(B)
		if (Unlocked(B))
			Out.AddItem(B.Item);
	return Out;
}

/** A project begun: n of an item, paid now. Why says what stopped it. */
static function bool Start(int Item, int n, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local LWGearRules.LWBuildDef B;
	local XComGameState_LWStrategy.LWBuild P;

	if (n < 1 || !class'LWGearRules'.static.BuildFor(Item, B))
	{
		Why = "Long War does not build item" @ Item $ ".";
		return false;
	}
	if (!Unlocked(B))
	{
		Why = ItemName(B.Template) @ "is not unlocked yet" $ (B.Foundry != 0 ? " (it waits on the Foundry's" @ FoundryName(B.Foundry) $ ")." : ".");
		return false;
	}
	Why = Short(B, n);
	if (Why != "")
	{
		Why = "Short of" @ Why $ ".";
		return false;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: engineering begins");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -CashCost(B) * n);
	Take(NewGameState, 'AlienAlloy', B.Alloys * n);
	Take(NewGameState, 'EleriumDust', B.Elerium * n);
	Take(NewGameState, class'X2Item_LWArtifacts'.static.ItemFor('Meld'), B.Meld * n);
	if (B.ItemReq != '' && !IsInfinite(B.ItemReq))
		Take(NewGameState, B.ItemReq, n);
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
	P.Item = Item;
	P.Quantity = n;
	P.WorkLeft = UnitWork(B);
	P.Engineers = B.Engineers * n;
	if (P.WorkLeft <= 0)
	{
		Deliver(NewGameState, S, P);
	}
	else
	{
		S.Builds.AddItem(P);
		S.Note("Engineering began:" @ n @ ItemName(B.Template) $ ", done in" @ HoursText(HoursFor(P.WorkLeft, P.Engineers, S.Engineers)) $ ".");
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Why = "";
	return true;
}

/** Some of an item taken from XCOM's stores. */
static function Take(XComGameState NewGameState, name ItemName, int Count)
{
	local XComGameState_Item Item;

	if (Count <= 0)
		return;
	Item = class'UIUtilities_Strategy'.static.GetXComHQ().GetItemByName(ItemName);
	if (Item == none)
		return;
	Item = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Item.ObjectID));
	Item.Quantity -= Count;
}

/** A project's items put in XCOM's stores. */
static function Deliver(XComGameState NewGameState, XComGameState_LWStrategy S, XComGameState_LWStrategy.LWBuild P)
{
	local LWGearRules.LWBuildDef B;
	local int Alloys, Elerium;

	class'LWGearRules'.static.BuildFor(P.Item, B);
	class'X2Item_LWArtifacts'.static.GiveItem(NewGameState, B.Template, P.Quantity);
	// The workshops give back some of the alloys and elerium (OnItemCompleted, CalcWorkshopRebate).
	Alloys = class'LWBase'.static.Rebate(S, B.Alloys) * P.Quantity;
	Elerium = class'LWBase'.static.Rebate(S, B.Elerium) * P.Quantity;
	class'X2Item_LWArtifacts'.static.GiveItem(NewGameState, 'AlienAlloy', Alloys);
	class'X2Item_LWArtifacts'.static.GiveItem(NewGameState, 'EleriumDust', Elerium);
	S.Note("Engineering built" @ P.Quantity @ ItemName(B.Template) $ ((Alloys + Elerium) > 0 ? "; the workshops gave back" @ Alloys @ "alloys and" @ Elerium @ "elerium." : "."));
}

/** A line per project, for the Geoscape. */
static function string ProjectsText(XComGameState_LWStrategy S)
{
	local XComGameState_LWStrategy.LWBuild P;
	local LWGearRules.LWBuildDef B;
	local string Text;

	foreach S.Builds(P)
	{
		class'LWGearRules'.static.BuildFor(P.Item, B);
		Text $= P.Quantity @ ItemName(B.Template) $ ":" @ HoursText(HoursFor(P.WorkLeft, P.Engineers, S.Engineers)) @ "left (" $ P.Engineers @ "engineers on it)\n";
	}
	return Text;
}

/** An unlocked item as the Geoscape lists it. */
static function string BuildLine(int Item, int Engineers)
{
	local LWGearRules.LWBuildDef B;
	local string Missing;

	class'LWGearRules'.static.BuildFor(Item, B);
	Missing = Short(B, 1);
	return ItemName(B.Template) $ ":" @ CostText(B) $ "; " $ HoursText(HoursFor(UnitWork(B), B.Engineers, Engineers)) $ (Missing != "" ? "  (short of" @ Missing $ ")" : "");
}

// --- The Foundry ------------------------------------------------------------------------------
// Long War's Foundry (XGFacility_Engineering's Foundry projects): a project needs its tech researched
// and its item in stores (XGTechTree.HasFoundryPrereqs); it costs money, alloys, elerium, fragments,
// meld and Items of that item, paid at the start; its work is Days x Engineers x 24 hours, less what
// the research credits held take off (GetCreditAdjustedTechHours), done at GetWorkPerHour with its
// engineers on it. One project per Foundry built in the base (CanAddFoundryProject).

static function string FoundryName(int Id)
{
	local X2TechTemplate Template;

	Template = X2TechTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(class'LWGearRules'.static.FoundryTemplateFor(Id)));
	return (Template != none && Template.DisplayName != "") ? Template.DisplayName : "project" @ Id;
}

/** Can the project be started (its tech researched, its item in stores, not done or under way)? */
static function bool FoundryUnlocked(LWGearRules.LWFoundryDef F)
{
	local XComGameState_LWStrategy S;
	local name Tech;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S.FoundryDone.Find(F.Id) != INDEX_NONE)
		return false;
	for (i = 0; i < S.FoundryProjects.Length; i++)
		if (S.FoundryProjects[i].Item == F.Id)
			return false;
	Tech = class'LWResearchRules'.static.TemplateForId(F.Tech);
	if (Tech == '' || !class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(Tech))
		return false;
	if (F.Item != '' && Held(F.Item) <= 0)
		return false;
	return F.EverHad == '' || Held(F.EverHad) > 0;
}

static function array<int> FoundryAvailable()
{
	local array<int> Out;
	local LWGearRules.LWFoundryDef F;

	foreach class'LWGearRules'.default.Foundry(F)
		if (FoundryUnlocked(F))
			Out.AddItem(F.Id);
	return Out;
}

static function string FoundryShort(LWGearRules.LWFoundryDef F)
{
	local array<string> Out;

	if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < F.Cash)
		Out.AddItem(class'LWStrategyRules'.static.Money(F.Cash));
	if (Held('AlienAlloy') < F.Alloys)
		Out.AddItem(F.Alloys @ class'X2Item_LWArtifacts'.static.DisplayName('Alloys'));
	if (Held('EleriumDust') < F.Elerium)
		Out.AddItem(F.Elerium @ class'X2Item_LWArtifacts'.static.DisplayName('Elerium'));
	if (Held(class'X2Item_LWArtifacts'.static.ItemFor('WeaponFragment')) < F.Fragments)
		Out.AddItem(F.Fragments @ class'X2Item_LWArtifacts'.static.DisplayName('WeaponFragment'));
	if (Held(class'X2Item_LWArtifacts'.static.ItemFor('Meld')) < F.Meld)
		Out.AddItem(F.Meld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld'));
	if (F.Item != '' && Held(F.Item) < F.Items)
		Out.AddItem(F.Items @ ItemName(F.Item));
	return JoinStrings(Out);
}

static function string FoundryCostText(LWGearRules.LWFoundryDef F)
{
	local array<string> Out;

	Out.AddItem(class'LWStrategyRules'.static.Money(F.Cash));
	if (F.Alloys > 0)
		Out.AddItem(F.Alloys @ class'X2Item_LWArtifacts'.static.DisplayName('Alloys'));
	if (F.Elerium > 0)
		Out.AddItem(F.Elerium @ class'X2Item_LWArtifacts'.static.DisplayName('Elerium'));
	if (F.Fragments > 0)
		Out.AddItem(F.Fragments @ class'X2Item_LWArtifacts'.static.DisplayName('WeaponFragment'));
	if (F.Meld > 0)
		Out.AddItem(F.Meld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld'));
	if (F.Item != '' && F.Items > 0)
		Out.AddItem(F.Items @ ItemName(F.Item));
	return JoinStrings(Out);
}

/** A project's work: Days x Engineers x 24 hours (FoundryDaysToHours), less each research credit held that covers it (at least a day each). */
static function int FoundryWork(LWGearRules.LWFoundryDef F, array<int> Held)
{
	local int Work, c, k;

	Work = F.Days * F.Engineers * 24;
	foreach Held(c)
	{
		if (F.Credits.Find(c) == INDEX_NONE)
			continue;
		k = class'LWResearchRules'.default.CreditShare.Find('Credit', c);
		if (k != INDEX_NONE)
			Work -= Max(24, Work * class'LWResearchRules'.default.CreditShare[k].Percent / 100);
	}
	return Max(0, Work);
}

static function string FoundryLine(int Id, XComGameState_LWStrategy S)
{
	local LWGearRules.LWFoundryDef F;
	local string Missing;

	class'LWGearRules'.static.FoundryFor(Id, F);
	Missing = FoundryShort(F);
	return FoundryName(Id) $ ":" @ FoundryCostText(F) $ "; " $ HoursText(HoursFor(FoundryWork(F, S.Credits), F.Engineers, S.Engineers)) $ (Missing != "" ? "  (short of" @ Missing $ ")" : "");
}

static function bool StartFoundry(int Id, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local LWGearRules.LWFoundryDef F;
	local XComGameState_LWStrategy.LWBuild P;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (!class'LWGearRules'.static.FoundryFor(Id, F))
	{
		Why = "Long War has no Foundry project" @ Id $ ".";
		return false;
	}
	if (S.FoundryProjects.Length >= class'LWBase'.static.Count(S, 11))
	{
		Why = class'LWBase'.static.Count(S, 11) == 0 ? "XCOM has no Foundry: build one in the base." : "The Foundry is busy.";
		return false;
	}
	if (!FoundryUnlocked(F))
	{
		Why = FoundryName(Id) @ "is not available.";
		return false;
	}
	Why = FoundryShort(F);
	if (Why != "")
	{
		Why = "Short of" @ Why $ ".";
		return false;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a Foundry project begins");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -F.Cash);
	Take(NewGameState, 'AlienAlloy', F.Alloys);
	Take(NewGameState, 'EleriumDust', F.Elerium);
	Take(NewGameState, class'X2Item_LWArtifacts'.static.ItemFor('WeaponFragment'), F.Fragments);
	Take(NewGameState, class'X2Item_LWArtifacts'.static.ItemFor('Meld'), F.Meld);
	if (F.Item != '')
		Take(NewGameState, F.Item, F.Items);
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	P.Item = Id;
	P.Quantity = 1;
	P.WorkLeft = FoundryWork(F, S.Credits);
	P.Engineers = F.Engineers;
	if (P.WorkLeft <= 0)
	{
		S.FoundryDone.AddItem(Id);
		S.Note("The Foundry finished" @ FoundryName(Id) $ ".");
	}
	else
	{
		S.FoundryProjects.AddItem(P);
		S.Note("The Foundry began" @ FoundryName(Id) $ ", done in" @ HoursText(HoursFor(P.WorkLeft, P.Engineers, S.Engineers)) $ ".");
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Why = "";
	return true;
}

static function string FoundryProjectsText(XComGameState_LWStrategy S)
{
	local XComGameState_LWStrategy.LWBuild P;
	local string Text;

	foreach S.FoundryProjects(P)
		Text $= "Foundry:" @ FoundryName(P.Item) $ ":" @ HoursText(HoursFor(P.WorkLeft, P.Engineers, S.Engineers)) @ "left\n";
	return Text;
}
