// Enemy Within's own Manufacturing screen (its movie, features/lw-ew-screens.md): how many of an item engineering builds,
// with the cost and time for that many; driven as EW's UIManufacturing drives it (SetTitle, SetEngineerLine,
// SetQuantityLine, UpdateInfo; clicks on theStartButton_PC submit, theBackButton cancel). The quantity moves with the
// arrow keys, the mouse wheel or the spinner's own +/- (its clicks, "-1" and "-2", when the movie makes it). The project
// is begun with LWEngineering.Start.
class UILWEWManufacturing extends UILWEWScreen;

/** EW's words (XGManufacturingUI, XGFacility_Engineering's ETA; lw-words.mjs, makeManufactureWords). */
var localized string Duration, Immediate, Requirements, EngineersNeeded, QuantityLabel, Notes, CostHelp, SubmitOrder, BeginProject, BackLabel, ErrEngineers, ETADay, ETAHour;
var localized string TimeToBuild, ETADays, NoteMaintenance, BeginBuild;

var int Item;
var int Quantity;
var UILWEWEngineering From;
/** A Foundry project (Item its id): no quantity, begun with LWEngineering.StartFoundry (EW's UIManufacturing.InitFoundry). */
var bool bFoundry;
/** A facility on a tile (Item its Long War facility id), from EW's facility chooser (EW's UIManufacturing.InitFacility,
 *  XGManufacturingUI.UpdateManufactureFacility): its time to build, requirements and upkeep; BEGIN CONSTRUCTION builds it
 *  (LWBase.Work) and closes the chooser too. */
var bool bFacility;
var int TileX, TileY;
var UILWEWChooseFacility Chooser;

static function Open(XComHQPresentationLayer HQPres, int ItemNumber, UILWEWEngineering Caller, optional bool bFoundryProject)
{
	local UILWEWManufacturing EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxManufacturing", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWManufacturing', HQPres);
	EWScreen.Package = name("/ package/ewxManufacturing/Manufacturing");
	EWScreen.MCName = 'theManufacturingScreen';
	EWScreen.Item = ItemNumber;
	EWScreen.Quantity = 1;
	EWScreen.From = Caller;
	EWScreen.bFoundry = bFoundryProject;
	HQPres.ScreenStack.Push(EWScreen);
}

/** EW's dialog for a facility chosen on a tile. */
static function OpenFacility(XComHQPresentationLayer HQPres, int FacilityId, int AtX, int AtY, UILWEWChooseFacility From)
{
	local UILWEWManufacturing EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxManufacturing", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWManufacturing', HQPres);
	EWScreen.Package = name("/ package/ewxManufacturing/Manufacturing");
	EWScreen.MCName = 'theManufacturingScreen';
	EWScreen.Item = FacilityId;
	EWScreen.Quantity = 1;
	EWScreen.bFacility = true;
	EWScreen.TileX = AtX;
	EWScreen.TileY = AtY;
	EWScreen.Chooser = From;
	HQPres.ScreenStack.Push(EWScreen);
}

simulated function OnInit()
{
	super.OnInit();
	// EW's buttons by their help (UI_FxsShellScreen.SetHelp, XGManufacturingUI.UpdateManButtons): 0 back, 3 SUBMIT ORDER
	// (BEGIN PROJECT for the Foundry); 1 (delete an order) and 2 (Long War's Build Quickly) are not Long War X2's, hidden.
	Help(0, Caps(W(BackLabel, "BACK")));
	Help(3, Caps(bFacility ? W(BeginBuild, "Begin Construction") : (bFoundry ? W(BeginProject, "Begin Project") : W(SubmitOrder, "Submit Order"))));
	Help(1, "");
	Help(2, "");
	// Once the movie has laid them out: the two unused buttons and the second spinner (EW's engineers, not adjustable).
	SetTimer(0.3, false, nameof(HideUnused));
	Refresh();
}

function HideUnused()
{
	MC.ChildSetBool("centerButton1", "_visible", false);
	MC.ChildSetBool("centerButton2", "_visible", false);
	// (EW's spinners, option0 and option1, unused: the quantity on its line, Refresh.)
	MC.ChildSetBool("option0", "_visible", false);
	MC.ChildSetBool("option1", "_visible", false);
}

/** A facility's dialog (XGManufacturingUI.UpdateManufactureFacility): its name, picture, "Time to Build: ETA (days): n",
 *  "Requirements:" and the chooser's costs, and its upkeep as EW's note; no engineers or quantity. */
function RefreshFacility()
{
	local LWBaseRules.LWFacilityDef F;
	local XGParamTag Tag;
	local string Req;

	if (!class'LWBaseRules'.static.FacilityFor(Item, F))
		return;
	class'LWBonusEffects'.static.AdjustFacility(F);
	MC.FunctionString("SetTitle", class'UIUtilities_Text'.static.GetColoredText(Caps(class'LWBase'.static.FacilityName(Item)), eUIState_Warning));
	MC.BeginFunctionOp("SetEngineerLine");
	MC.QueueString("");
	MC.QueueString("");
	MC.EndOp();
	MC.BeginFunctionOp("SetQuantityLine");
	MC.QueueString("");
	MC.QueueString("");
	MC.QueueBoolean(true);
	MC.EndOp();
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.IntValue0 = F.Days;
	Req = Chooser != none ? Chooser.Requirements(F) : "";
	Req = Repl(Req, W(class'UILWEWBuildFacilities'.default.RequiredBuild, "Required to Build:"), class'UIUtilities_Text'.static.GetColoredText(W(Requirements, "Requirements:"), eUIState_Warning));
	Tag.StrValue0 = class'LWStrategyRules'.static.Money(F.Upkeep);
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(W(TimeToBuild, "Time to Build:") @ `XEXPAND.ExpandString(W(ETADays, "ETA (days): <XGParam:IntValue0/>")), eUIState_Warning) $ "\n" $ Req);
	MC.QueueString(F.Upkeep > 0 ? W(Notes, "Note(s):") @ `XEXPAND.ExpandString(W(NoteMaintenance, "Maintenance on this facility will cost <XGParam:StrValue0/> every month.")) : "");
	// (EW's picture of it, GetStrategyImagePath: its FacilityIcons, named as its blueprints are.)
	MC.QueueString(class'UILWEWChooseFacility'.static.BlueprintName(Item) != "" ? "img:///" $ class'UILWEWScreen'.const.EW_IMAGES $ ".FacilityIcons.ChooseFacility_" $ class'UILWEWChooseFacility'.static.BlueprintName(Item) : "");
	MC.EndOp();
}

static function string W(string Localized, string Fallback)
{
	return Localized != "" ? Localized : Fallback;
}

/** EW's ETA (XGFacility_Engineering.GetETAString): hours under a day ("5h"), else days rounded up ("2d"); none, EW's
 *  Immediate. */
function string ETA(int Hours)
{
	local XGParamTag Tag;

	if (Hours <= 0)
		return W(Immediate, "Immediate");
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.IntValue0 = Hours < 24 ? Hours : (Hours + 23) / 24;
	return `XEXPAND.ExpandString(Hours < 24 ? W(ETAHour, "<XGParam:IntValue0/>h") : W(ETADay, "<XGParam:IntValue0/>d"));
}

/** What n of the item take, as EW's GetItemCostSummary lists them: each part in its colour, red when XCOM is short, by
 *  commas; bShort when any is. */
static function string RequirementsFor(LWGearRules.LWBuildDef B, int n, out int bShort)
{
	local array<string> Parts;
	local string Out;
	local int i, Cash;

	Cash = class'LWEngineering'.static.CashCost(B) * n;
	if (Cash > 0)
		Parts.AddItem(Part(class'LWStrategyRules'.static.Money(Cash), class'LWEngineering'.static.Held('Supplies') < Cash, eUIState_Cash, bShort));
	if (B.Elerium > 0)
		Parts.AddItem(Part(B.Elerium * n $ "x" @ class'X2Item_LWArtifacts'.static.DisplayName('Elerium'), class'LWEngineering'.static.Held('EleriumDust') < B.Elerium * n, eUIState_Psyonic, bShort));
	if (B.Alloys > 0)
		Parts.AddItem(Part(B.Alloys * n $ "x" @ class'X2Item_LWArtifacts'.static.DisplayName('Alloys'), class'LWEngineering'.static.Held('AlienAlloy') < B.Alloys * n, eUIState_Highlight, bShort));
	if (B.Meld > 0)
		Parts.AddItem(Part(B.Meld * n $ "x" @ class'X2Item_LWArtifacts'.static.DisplayName('Meld'), class'LWEngineering'.static.Held('LWItem_Meld') < B.Meld * n, eUIState_Warning, bShort));
	if (B.ItemReq != '')
		Parts.AddItem(Part(class'LWEngineering'.static.ReqCount(B) * n $ "x" @ class'LWEngineering'.static.ItemName(B.ItemReq), class'LWEngineering'.static.Held(B.ItemReq) < class'LWEngineering'.static.ReqCount(B) * n, eUIState_Normal, bShort));
	if (B.ItemReq2 != '')
		Parts.AddItem(Part(B.ItemReq2Count * n $ "x" @ class'LWEngineering'.static.ItemName(B.ItemReq2), class'LWEngineering'.static.Held(B.ItemReq2) < B.ItemReq2Count * n, eUIState_Normal, bShort));
	for (i = 0; i < Parts.Length; i++)
		Out $= (i > 0 ? ", " : "") $ Parts[i];
	return Out;
}

static function string Part(string Text, bool bLacking, EUIState Colour, out int bShort)
{
	if (bLacking)
		bShort = 1;
	if (bLacking)
		Colour = eUIState_Bad;
	return class'UIUtilities_Text'.static.GetColoredText(Text, Colour);
}

function Help(int Index, string Text)
{
	MC.BeginFunctionOp("SetHelp");
	MC.QueueNumber(Index);
	MC.QueueString(Text);
	MC.QueueString("");
	MC.EndOp();
}

function Refresh()
{
	local LWGearRules.LWBuildDef B;
	local X2ItemTemplate Template;
	local XComGameState_LWStrategy S;
	local string Req, Why;
	local int Needed, Hours, bShort;
	local bool bFewEngineers;

	if (bFacility)
	{
		RefreshFacility();
		return;
	}
	if (bFoundry)
	{
		RefreshFoundry();
		return;
	}
	if (!class'LWGearRules'.static.BuildFor(Item, B))
		return;
	Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(B.Template);
	S = class'XComGameState_LWStrategy'.static.Get();
	// As EW's XGManufacturingUI.UpdateManufactureItem and UIManufacturing.DrawItemProject: the title; the engineers the
	// order needs (red when XCOM has fewer); the quantity on EW's spinner; the duration and requirements; the problem (red)
	// and EW's note.
	MC.FunctionString("SetTitle", class'UIUtilities_Text'.static.GetColoredText(Caps(class'LWEngineering'.static.ItemName(B.Template)), eUIState_Warning));
	Needed = B.Engineers * Quantity;
	bFewEngineers = S != none && S.Engineers < Needed;
	// (Plain text: the movie's engineer and quantity lines take no HTML, UIManufacturing.RefreshDisplay.)
	MC.BeginFunctionOp("SetEngineerLine");
	MC.QueueString(Caps(W(EngineersNeeded, "Engineers Needed")));
	MC.QueueString(string(Needed));
	MC.EndOp();
	// (OPEN: EW shows the quantity on its spinner, option0 (SetSpinnerLabel, SetSpinnerValue, SetSpinnerArrows, SetActive);
	// called so, it did not show here. The quantity line instead; the arrow keys and the wheel change it.)
	MC.BeginFunctionOp("SetQuantityLine");
	MC.QueueString(Caps(W(QuantityLabel, "Quantity:")));
	MC.QueueString(string(Quantity));
	MC.QueueBoolean(true);
	MC.EndOp();
	Req = RequirementsFor(B, Quantity, bShort);
	Hours = class'LWEngineering'.static.HoursFor(class'LWEngineering'.static.UnitWork(B), Needed, S != none ? S.Engineers : 0);
	Why = bShort > 0 ? class'UIUtilities_Text'.static.GetColoredText("Short of" @ class'LWEngineering'.static.Short(B, Quantity), eUIState_Bad) $ "\n"
		: (bFewEngineers ? class'UIUtilities_Text'.static.GetColoredText(W(ErrEngineers, ""), eUIState_Bad) $ "\n" : "");
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(W(Duration, "Project Duration:") @ ETA(Hours), eUIState_Warning) $ "\n"
		$ (Req != "" ? class'UIUtilities_Text'.static.GetColoredText(W(Requirements, "Requirements:"), bShort > 0 ? eUIState_Bad : eUIState_Warning) @ Req : ""));
	MC.QueueString(Why $ class'UIUtilities_Text'.static.GetColoredText(W(Notes, "Note(s):"), eUIState_Normal) @ class'UIUtilities_Text'.static.GetColoredText(W(CostHelp, ""), eUIState_Normal));
	MC.QueueString(class'LWX2Pictures'.static.Item(Item, Template != none ? Template.strImage : ""));
	MC.EndOp();
}

/** A Foundry project: its name, engineers, time and cost, words and picture; no quantity. */
function RefreshFoundry()
{
	local LWGearRules.LWFoundryDef F;
	local X2TechTemplate Template;
	local XComGameState_LWStrategy S;
	local string Short;

	if (!class'LWGearRules'.static.FoundryFor(Item, F))
		return;
	Template = X2TechTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(class'LWGearRules'.static.FoundryTemplateFor(Item)));
	S = class'XComGameState_LWStrategy'.static.Get();
	Short = class'LWEngineering'.static.FoundryShort(F);
	MC.FunctionString("SetTitle", "<font size='26'>" $ Caps(class'LWEngineering'.static.FoundryName(Item)) $ "</font>");
	MC.BeginFunctionOp("SetEngineerLine");
	MC.QueueString("ENGINEERS");
	MC.QueueString(string(F.Engineers));
	MC.EndOp();
	MC.BeginFunctionOp("SetQuantityLine");
	MC.QueueString("");
	MC.QueueString("");
	MC.QueueBoolean(true);
	MC.EndOp();
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString("TIME:" @ class'LWEngineering'.static.HoursText(class'LWEngineering'.static.HoursFor(class'LWEngineering'.static.FoundryWork(F, S.Credits), F.Engineers, S.Engineers))
		$ "\n" $ "COST:" @ class'LWEngineering'.static.FoundryCostText(F) $ (Short != "" ? "\n" $ class'UIUtilities_Text'.static.GetColoredText("Short of" @ Short, eUIState_Bad) : ""));
	MC.QueueString(Template != none ? Template.Summary : "");
	MC.QueueString(class'LWX2Pictures'.static.Project(Item, Template != none ? Template.strImage : ""));
	MC.EndOp();
}

/** The cost of one, for n: "§30, 4 Alloys" for 2 is "2 x (§30, 4 Alloys)". */
static function string Times(string One, int n)
{
	return n == 1 ? One : n @ "x (" $ One $ ")";
}

function Change(int By)
{
	if (bFoundry || bFacility)
		return;
	Quantity = Clamp(Quantity + By, 1, 99);
	Refresh();
}

/** The project begun (LWEngineering.Start pays now); the list shows it, and its count once delivered. */
function Submit()
{
	local string Why;

	// (A facility: built on its tile, the chooser closed with this dialog, as EW's BEGIN CONSTRUCTION leaves both.)
	if (bFacility)
	{
		if (!class'LWBase'.static.Work(TileX, TileY, Item, Why))
		{
			`log("LongWarX2: EW base building:" @ Why, , 'LongWarX2');
			Movie.Pres.PlayUISound(eSUISound_MenuClose);
			return;
		}
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		CloseScreen();
		if (Chooser != none)
			Chooser.CloseScreen();
		return;
	}
	if (bFoundry ? !class'LWEngineering'.static.StartFoundry(Item, Why) : !class'LWEngineering'.static.Start(Item, Quantity, Why))
	{
		`log("LongWarX2: EW manufacturing:" @ Why, , 'LongWarX2');
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		MC.BeginFunctionOp("UpdateInfo");
		MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(Why, eUIState_Bad));
		MC.QueueString("");
		MC.QueueString("");
		MC.EndOp();
		return;
	}
	`log("LongWarX2: EW manufacturing: begun," @ Quantity @ "of item" @ Item, , 'LongWarX2');
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	CloseScreen();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (cmd == 391 || cmd == 398)
	{
		if (Target == "theStartButton_PC")
			Submit();
		else if (Target == "theBackButton")
			CloseScreen();
		// The spinner's arrows: "-1" more, "-2" fewer.
		else if (Target == "-1")
			Change(1);
		else if (Target == "-2")
			Change(-1);
	}
	super(UIScreen).OnMouseEvent(cmd, args);
}

static function string JoinArgs(array<string> Args)
{
	local string S, A;

	foreach Args(A)
		S $= A $ " ";
	return S;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:
			Change(1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN:
			Change(-1);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Submit();
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}
