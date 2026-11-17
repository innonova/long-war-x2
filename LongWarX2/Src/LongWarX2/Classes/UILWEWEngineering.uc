// Enemy Within's own engineering screen (its BuildItem movie, features/lw-ew-screens.md): what research has unlocked,
// by EW's tabs (weapons, armour, vehicles), with how many XCOM holds, the cost and the item's words and picture; driven as
// EW's UIBuildItem drives the movie (SetLabels, SetTabState, SetSelectedCategory, BatchAddOptions, SetFocus,
// UpdateInfo, SetConfirmButton; clicks 391 select an option or a tab or confirm, 398 select and confirm). Confirmed, the
// quantity is chosen on EW's Manufacturing screen (UILWEWManufacturing). The rules are LWEngineering's.
// With bFoundry, the Foundry's projects on the same movie, as EW's UIFoundry shows them (its tabs off, BEGIN PROJECT).
class UILWEWEngineering extends UILWEWScreen;

/** EW's tabs and Long War's item categories (EItemCategory) on them. */
var array<int> Tabs;
var int Tab;
var array<int> Items;
var int Selected;
/** The Foundry's available projects instead of engineering's items (Items holds their ids). */
var bool bFoundry;

/** The screen pushed over the Avenger (EW's screens converted); else the plain engineering screen. */
static function Open(XComHQPresentationLayer HQPres, optional bool bFoundryProjects)
{
	local UILWEWEngineering EWScreen;
	local UILWEngineering Plain;

	if (!class'UILWEWScreen'.static.HasEWScreens())
	{
		Plain = HQPres.Spawn(class'UILWEngineering', HQPres);
		Plain.bFoundry = bFoundryProjects;
		HQPres.ScreenStack.Push(Plain);
		return;
	}
	DynamicLoadObject(default.UIPackage $ ".ewxBuildItem", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWEngineering', HQPres);
	EWScreen.Package = name("/ package/ewxBuildItem/BuildItem");
	EWScreen.MCName = 'theBuildScreen';
	EWScreen.bFoundry = bFoundryProjects;
	Push3D(HQPres, EWScreen);
}

simulated function OnInit()
{
	super.OnInit();
	MC.FunctionString("SetConfirmButton", bFoundry ? "BEGIN PROJECT" : "MANUFACTURE");
	Fill();
}

/** The current tab's items, as EW's UpdateItemTable lists them (the tab with nothing in it disabled). */
function Fill()
{
	local LWGearRules.LWBuildDef B;
	local array<int> All;
	local int i, Item;

	if (bFoundry)
	{
		FillFoundry();
		return;
	}
	All = class'LWEngineering'.static.Buildable();
	MC.BeginFunctionOp("SetLabels");
	MC.QueueString("BUILD" @ TabName(Tabs[Tab]));
	MC.QueueString("ITEM");
	MC.QueueString("HELD");
	MC.EndOp();
	for (i = 0; i < Tabs.Length; i++)
	{
		MC.BeginFunctionOp("SetTabState");
		MC.QueueNumber(i);
		MC.QueueNumber(i == Tab ? 5 : (CountIn(All, Tabs[i]) == 0 ? 1 : 0));
		MC.EndOp();
	}
	MC.FunctionNum("SetSelectedCategory", Tab);
	Items.Length = 0;
	foreach All(Item)
		if (class'LWGearRules'.static.BuildFor(Item, B) && CategoryOf(B) == Tabs[Tab])
			Items.AddItem(Item);
	MC.FunctionVoid("clear");
	for (i = 0; i < Items.Length; i++)
	{
		class'LWGearRules'.static.BuildFor(Items[i], B);
		// EW's AddOption (index, label, disabled, quantity); its BatchAddOptions took nothing here.
		MC.BeginFunctionOp("AddOption");
		MC.QueueNumber(i);
		// Smaller than EW's own: Long War's names are longer than EW's list was made for.
		MC.QueueString("<font size='20'>" $ class'UIUtilities_Text'.static.GetColoredText(Caps(class'LWEngineering'.static.ItemName(B.Template)), class'LWEngineering'.static.Short(B, 1) != "" ? eUIState_Disabled : eUIState_Normal) $ "</font>");
		MC.QueueBoolean(class'LWEngineering'.static.Short(B, 1) != "");
		MC.QueueNumber(class'LWEngineering'.static.Held(B.Template));
		MC.EndOp();
	}
	`log("LongWarX2: EW engineering: tab" @ TabName(Tabs[Tab]) @ "with" @ Items.Length @ "items", , 'LongWarX2');
	Select(0);
}

/** The Foundry's available projects (EW's UIFoundry.RealizeAvailableProjects: no tabs, no counts). */
function FillFoundry()
{
	local LWGearRules.LWFoundryDef F;
	local int i;

	Items = class'LWEngineering'.static.FoundryAvailable();
	MC.BeginFunctionOp("SetLabels");
	MC.QueueString("FOUNDRY PROJECTS");
	MC.QueueString("");
	MC.QueueString("");
	MC.EndOp();
	MC.FunctionVoid("clear");
	for (i = 0; i < Tabs.Length; i++)
	{
		MC.BeginFunctionOp("SetTabState");
		MC.QueueNumber(i);
		MC.QueueNumber(1);
		MC.EndOp();
	}
	MC.FunctionString("ShowNoProjectMessage", Items.Length == 0 ? "NO PROJECTS AVAILABLE" : "");
	for (i = 0; i < Items.Length; i++)
	{
		class'LWGearRules'.static.FoundryFor(Items[i], F);
		MC.BeginFunctionOp("AddOption");
		MC.QueueNumber(i);
		MC.QueueString("<font size='20'>" $ class'UIUtilities_Text'.static.GetColoredText(Caps(class'LWEngineering'.static.FoundryName(Items[i])), class'LWEngineering'.static.FoundryShort(F) != "" ? eUIState_Disabled : eUIState_Normal) $ "</font>");
		MC.QueueBoolean(false);
		MC.QueueNumber(0);
		MC.EndOp();
	}
	`log("LongWarX2: EW Foundry:" @ Items.Length @ "projects", , 'LongWarX2');
	SelectFoundry(0);
}

/** A Foundry project selected: its name, cost and time, words and picture. */
function SelectFoundry(int Index)
{
	local LWGearRules.LWFoundryDef F;
	local X2TechTemplate Template;
	local XComGameState_LWStrategy S;
	local string Short;

	if (Items.Length == 0)
	{
		MC.BeginFunctionOp("UpdateInfo");
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueString("");
		MC.EndOp();
		return;
	}
	Selected = (Index + Items.Length) % Items.Length;
	class'LWGearRules'.static.FoundryFor(Items[Selected], F);
	Template = X2TechTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(class'LWGearRules'.static.FoundryTemplateFor(Items[Selected])));
	S = class'XComGameState_LWStrategy'.static.Get();
	Short = class'LWEngineering'.static.FoundryShort(F);
	MC.FunctionString("SetFocus", string(Selected));
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(Caps(class'LWEngineering'.static.FoundryName(Items[Selected])));
	MC.QueueString("PROJECT COST:" @ class'LWEngineering'.static.FoundryCostText(F) $ "<br>"
		$ "TIME:" @ class'LWEngineering'.static.HoursText(class'LWEngineering'.static.HoursFor(class'LWEngineering'.static.FoundryWork(F, S.Credits), F.Engineers, S.Engineers))
		@ "(" $ F.Engineers @ "engineers)"
		$ (Short != "" ? "<br>" $ class'UIUtilities_Text'.static.GetColoredText("Short of" @ Short, eUIState_Bad) : ""));
	MC.QueueString(Template != none ? Template.Summary : "");
	MC.QueueString(class'LWX2Pictures'.static.Project(Items[Selected], Template != none ? Template.strImage : ""));
	MC.EndOp();
}

static function string TabName(int Category)
{
	switch (Category)
	{
	case 1: return "WEAPONS";
	case 2: return "ARMOR";
	case 3: return "VEHICLES";
	}
	return "ITEMS";
}

/** An item's tab: its Long War category (an item with none counts as a weapon, as EW's GetBuildItems lists it). */
static function int CategoryOf(LWGearRules.LWBuildDef B)
{
	return B.Category > 0 ? B.Category : 1;
}

static function int CountIn(array<int> All, int Category)
{
	local LWGearRules.LWBuildDef B;
	local int Item, n;

	foreach All(Item)
		if (class'LWGearRules'.static.BuildFor(Item, B) && CategoryOf(B) == Category)
			n++;
	return n;
}

/** An item selected: its focus and the info panel (name, cost and time, words, picture). */
function Select(int Index)
{
	local LWGearRules.LWBuildDef B;
	local X2ItemTemplate Template;
	local XComGameState_LWStrategy S;
	local string Info, Short;

	if (bFoundry)
	{
		SelectFoundry(Index);
		return;
	}

	if (Items.Length == 0)
	{
		MC.BeginFunctionOp("UpdateInfo");
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueString("Research unlocks what engineering can build here.");
		MC.QueueString("");
		MC.EndOp();
		return;
	}
	Selected = (Index + Items.Length) % Items.Length;
	class'LWGearRules'.static.BuildFor(Items[Selected], B);
	Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(B.Template);
	S = class'XComGameState_LWStrategy'.static.Get();
	Short = class'LWEngineering'.static.Short(B, 1);
	Info = "BUILD COST:" @ class'LWEngineering'.static.CostText(B) $ "<br>"
		$ "TIME:" @ class'LWEngineering'.static.HoursText(class'LWEngineering'.static.HoursFor(class'LWEngineering'.static.UnitWork(B), B.Engineers, S != none ? S.Engineers : 0))
		@ "(" $ B.Engineers @ "engineers)"
		$ (Short != "" ? "<br>" $ class'UIUtilities_Text'.static.GetColoredText("Short of" @ Short, eUIState_Bad) : "");
	MC.FunctionString("SetFocus", string(Selected));
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(Caps(class'LWEngineering'.static.ItemName(B.Template)));
	MC.QueueString(Info);
	MC.QueueString(Template != none ? Template.GetItemBriefSummary() : "");
	MC.QueueString(class'LWX2Pictures'.static.Item(Items[Selected], Template != none ? Template.strImage : ""));
	MC.EndOp();
}

/** The selected item to the Manufacturing screen, where its quantity is chosen. */
function Accept()
{
	if (Items.Length == 0)
		return;
	class'UILWEWManufacturing'.static.Open(XComHQPresentationLayer(Movie.Pres), Items[Selected], self, bFoundry);
}

simulated function OnRemoved()
{
	class'UILWEWMapBackdrop'.static.HideAll();
	super.OnRemoved();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (bIsInited)
		Fill();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (cmd == 391 && Target == "theConfirmButton")
		Accept();
	else if ((cmd == 391 || cmd == 398) && InStr(Target, "option") == 0)
	{
		Select(int(Mid(Target, 6)));
		if (cmd == 398)
			Accept();
	}
	else if (cmd == 391 && InStr(Target, "cat") == 0)
		ToTab(int(Mid(Target, 3)));
	super(UIScreen).OnMouseEvent(cmd, args);
}

function ToTab(int i)
{
	if (bFoundry)
		return;
	if (i < 0 || i >= Tabs.Length || i == Tab)
		return;
	Tab = i;
	Fill();
}

/** The option under the mouse, or -1 (as UILWEWResearch: EW's list items do not report their clicks to XCOM 2). */
function int OptionUnderMouse()
{
	local string Path;
	local float MouseX, MouseY, W, H;
	local int i;

	for (i = 0; i < Items.Length; i++)
	{
		Path = MCPath $ ".itemList.theItems." $ i;
		W = Movie.GetVariableNumber(Path $ "._width");
		H = Movie.GetVariableNumber(Path $ "._height");
		MouseX = Movie.GetVariableNumber(Path $ "._xmouse");
		MouseY = Movie.GetVariableNumber(Path $ "._ymouse");
		if (W > 0 && MouseX >= 0 && MouseY >= 0 && MouseX <= W && MouseY <= H)
			return i;
	}
	return -1;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int i;

	if ((cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP)
		&& (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		i = OptionUnderMouse();
		if (i >= 0)
		{
			Select(i);
			if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP)
				Accept();
			return true;
		}
	}
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			Select(Selected - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			Select(Selected + 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			ToTab((Tab + Tabs.Length - 1) % Tabs.Length);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
			ToTab((Tab + 1) % Tabs.Length);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Accept();
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	// (Over EW's engineering, as EW shows it.)
	BaseCamera = ENGINEERING
	// (EW's: UIBuildItem and UIFoundry on UIDisplay_Engineering through Engineering_UIDisplayCam.)
	EWDisplay = UIDisplay_Engineering
	EWDisplayCamera = Engineering_UIDisplayCam
	Tabs(0) = 1
	Tabs(1) = 2
	Tabs(2) = 3
}
