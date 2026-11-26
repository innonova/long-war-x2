// Enemy Within's own research screen (its ChooseTech movie, features/lw-ew-screens.md) choosing what XCOM researches:
// Long War's techs as XCOM 2 runs them (lw-research.md), filled as EW's UIChooseTech fills it from XGResearchUI's tech
// table (UpdateTechTable, BuildTechOption, BuildTechSummary; XGFacility_Labs' IsPriorityTech, GetProgress, GetCostSummary):
// Long War's order (priority techs first, then by time, autopsies and interrogations last), "-**Priority**" on the priority
// ones, red the ones XCOM cannot afford; for the selected one its time (FAST / NORMAL / SLOW and the days), its
// requirements (red where short, and why), the research credits that cut it, its summary and picture. Driven as UIChooseTech
// drives the movie (SetTitle, AddOption, setFocus, UpdateInfo, SetConfirmButtonHelp; clicks 400 select, 398 select and
// accept, 391 on the confirm button accept); the project started as XCOM 2's research screen starts one (its cost paid).
// The same screen lists the research credits XCOM holds (EW's Review Research Credits: XGResearchUI.UpdateCreditArchives).
class UILWEWResearch extends UILWEWScreen;

/** EW's words (UIChooseTech, XGResearchUI, XGFacility_Labs, XGLocalizedData's research credits), from the player's install. */
var localized string Title, CreditTitle, Confirm, Priority, CostLabel, CreditApplies, ETAInstant, ETADay, ETADays, CostAmount,
	CostElerium, CostAlloys, ErrFunds, ErrElerium, ErrAlloys, ErrResources;
/** FAST, NORMAL, SLOW (EW's eResearchProgress_Fast, _Normal, _Slow). */
var localized string Progress[3];
var localized string CreditNames[10], CreditSummary[10];

var array<StateObjectReference> Techs;
/** The research credits listed (Review Research Credits). */
var array<int> CreditList;
var bool bCredits;
var int Selected;

/** The screen pushed over the base: the techs to choose from, or (bCreditArchive) the research credits held. */
static function string Open(optional bool bCreditArchive)
{
	local XComHQPresentationLayer HQPres;
	local UILWEWResearch EWScreen;

	HQPres = `HQPRES;
	if (HQPres == none)
		return "ERR not on the Avenger";
	DynamicLoadObject(default.UIPackage $ ".ewxChooseTech", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWResearch', HQPres);
	EWScreen.Package = name("/ package/ewxChooseTech/ChooseTech");
	EWScreen.MCName = 'theChooseResearch';
	EWScreen.bCredits = bCreditArchive;
	Push3D(HQPres, EWScreen);
	return "ok EW research screen";
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

static function string Expand(string W, optional int IntValue, optional string StrValue)
{
	return Repl(Repl(W, "<XGParam:IntValue0/>", string(IntValue)), "<XGParam:StrValue0/>", StrValue);
}

/** Long War's tech for a template (LWResearchRules), Id 0 when it is none of Long War's. */
static function int DefOf(XComGameState_Tech Tech, out LWResearchRules.LWTechDef T)
{
	local int Id;

	Id = class'LWResearchRules'.static.IdOfTemplate(Tech.GetMyTemplateName());
	if (Id <= 0 || !class'LWResearchRules'.static.TechById(Id, T))
		return 0;
	return Id;
}

/** Long War's tech (by its number) as XCOM 2's tech state; none if it has none. */
static function XComGameState_Tech TechOf(int Id)
{
	local XComGameState_Tech Tech;
	local name Template;

	Template = class'LWResearchRules'.static.TemplateForId(Id);
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', Tech)
		if (Tech.GetMyTemplateName() == Template)
			return Tech;
	return none;
}

/** How many of Long War's techs XCOM has researched (XGFacility_Labs.GetNumTechsResearched). */
static function int NumResearched()
{
	local XComGameState_Tech Tech;
	local int n;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', Tech)
		if (Left(string(Tech.GetMyTemplateName()), 7) == "LWTech_" && class'UIUtilities_Strategy'.static.GetXComHQ().TechIsResearched(Tech.GetReference()))
			n++;
	return n;
}

/** An interrogation researched (XGFacility_Labs.HasInterrogatedCaptive). */
static function bool HasInterrogated()
{
	local int Id;

	for (Id = 35; Id <= 43; Id++)
		if (class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(class'LWResearchRules'.static.TemplateForId(Id)))
			return true;
	return false;
}

/**
 * XGFacility_Labs.IsPriorityTech: Xenobiology once two techs are done, the interrogations until one is done, Xenoneurology,
 * Alien Operations, the Psionics tech, Alien Communications and Alien Command and Control. (Long War also marks Alien
 * Propulsion while the story's objective is to shoot down the Overseer and Xenogenetics while it is to capture an Outsider;
 * the port has no story objectives to ask.)
 */
static function bool IsPriority(int Id)
{
	if (Id == 1 && NumResearched() > 2)
		return true;
	if (class'LWResearchRules'.static.IsInterrogation(Id) && !HasInterrogated())
		return true;
	return Id == 2 || Id == 3 || Id == 4 || Id == 7 || Id == 8;
}

/** XGResearchUI.SortTechs' order: priority techs (by number), then by time, autopsies and interrogations last (by number). */
static function int SortKey(XComGameState_Tech Tech)
{
	local LWResearchRules.LWTechDef T;
	local XComGameState_LWStrategy S;
	local int Id;

	Id = DefOf(Tech, T);
	if (Id <= 0)
		return 3000000;
	if (IsPriority(Id))
		return Id;
	if (class'LWResearchRules'.static.IsAutopsy(Id) || class'LWResearchRules'.static.IsInterrogation(Id))
		return 2000000 + Id;
	S = class'XComGameState_LWStrategy'.static.Get();
	return 1000 + int(T.Days * 24 * (1.0 - class'LWResearchRules'.static.TimeCut(T, S != none ? S.Credits : T.Credits, S))) * 100 + Id;
}

/** The tech's requirements as EW lists them (GetCostSummary), and why it cannot be afforded ("" when it can). */
static function string Requirements(XComGameState_Tech Tech, out string Why)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2TechTemplate Template;
	local X2ItemTemplate Item;
	local ArtifactCost C;
	local string Out, Line;
	local int Have, LineState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	Template = Tech.GetMyTemplate();
	Why = "";
	foreach Template.Cost.ResourceCosts(C)
	{
		Have = XComHQ.GetResourceAmount(C.ItemTemplateName);
		Item = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(C.ItemTemplateName);
		// (Elerium and alloys as EW writes them, "100 Elerium"; any other item "40x Weapon Fragments".)
		if (C.ItemTemplateName == 'EleriumDust' || C.ItemTemplateName == 'AlienAlloy')
		{
			Line = Expand(Word(default.CostAmount, "<XGParam:IntValue0/> <XGParam:StrValue0/>"), C.Quantity,
				C.ItemTemplateName == 'EleriumDust' ? Word(default.CostElerium, "Elerium") : Word(default.CostAlloys, "Alloys"));
			LineState = 0;
			if (C.Quantity > Have)
			{
				LineState = 3;
				Why = C.ItemTemplateName == 'EleriumDust' ? Word(default.ErrElerium, "Insufficient Elerium.") : Word(default.ErrAlloys, "Insufficient Alloys.");
			}
		}
		else
		{
			Line = C.Quantity $ "x" @ (Item == none ? string(C.ItemTemplateName) : (C.Quantity > 1 ? Item.GetItemFriendlyNamePlural() : Item.GetItemFriendlyName()));
			LineState = 0;
			if (C.Quantity > Have)
			{
				LineState = 3;
				Why = Expand(Word(default.ErrResources, "Insufficient resources."), C.Quantity - Have, Item != none ? Item.GetItemFriendlyName() : "");
			}
		}
		Out $= (Out != "" ? "," : "") @ EWColoured(Line, LineState);
	}
	foreach Template.Cost.ArtifactCosts(C)
	{
		Have = XComHQ.GetNumItemInInventory(C.ItemTemplateName);
		Item = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(C.ItemTemplateName);
		Line = C.Quantity $ "x" @ (Item == none ? string(C.ItemTemplateName) : (C.Quantity > 1 ? Item.GetItemFriendlyNamePlural() : Item.GetItemFriendlyName()));
		LineState = 0;
		if (C.Quantity > Have)
		{
			LineState = 3;
			Why = Expand(Word(default.ErrResources, "Insufficient resources."), C.Quantity - Have, Item != none ? Item.GetItemFriendlyName() : "");
		}
		Out $= (Out != "" ? "," : "") @ EWColoured(Line, LineState);
	}
	return Out;
}

simulated function OnInit()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy S;
	local XComGameState_Tech Tech;
	local array<int> Keys;
	local array<StateObjectReference> Available;
	local StateObjectReference Ref;
	local string Label, Why;
	local bool bPriority;
	local int i, j, Key, Id, c;
	local LWResearchRules.LWTechDef T;

	super.OnInit();
	MC.FunctionString("SetTitle", bCredits ? Word(CreditTitle, "RESEARCH CREDITS") : Word(Title, "CHOOSE RESEARCH"));
	MC.FunctionString("SetConfirmButtonHelp", bCredits ? "" : Word(Confirm, "BEGIN PROJECT"));
	MC.FunctionVoid("clear");
	if (bCredits)
	{
		// (XGResearchUI.UpdateCreditArchives: each credit held, by its number.)
		S = class'XComGameState_LWStrategy'.static.Get();
		for (c = 1; S != none && c < 10; c++)
			if (S.Credits.Find(c) != INDEX_NONE)
				CreditList.AddItem(c);
		for (i = 0; i < CreditList.Length; i++)
		{
			MC.BeginFunctionOp("AddOption");
			MC.QueueNumber(i);
			MC.QueueString(EWColoured(Caps(CreditNames[CreditList[i]]), 0));
			MC.QueueNumber(0);
			MC.EndOp();
		}
		Select(0);
		return;
	}
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	Available = XComHQ.GetAvailableTechsForResearch();
	foreach Available(Ref)
	{
		Key = SortKey(XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID)));
		for (j = 0; j < Keys.Length && Keys[j] <= Key; j++);
		Keys.InsertItem(j, Key);
		Techs.InsertItem(j, Ref);
	}
	for (i = 0; i < Techs.Length; i++)
	{
		Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Techs[i].ObjectID));
		Id = DefOf(Tech, T);
		// (BuildTechOption: the name, "-**Priority**" on a priority tech; UpdateLayout: red when it cannot be afforded, the
		// priority ones in EW's state 2.)
		Label = Caps(Tech.GetDisplayName());
		if (Id > 0 && IsPriority(Id))
			Label @= "-" @ Word(Priority, "**Priority**");
		Requirements(Tech, Why);
		MC.BeginFunctionOp("AddOption");
		MC.QueueNumber(i);
		bPriority = Id > 0 && IsPriority(Id);
		MC.QueueString(EWColoured(Label, Why != "" ? 3 : (bPriority ? 2 : 0)));
		MC.QueueNumber(0);
		MC.EndOp();
	}
	`log("LongWarX2: EW research screen:" @ Techs.Length @ "techs listed", , 'LongWarX2');
	Select(0);
}

/** A tech (or credit) selected: the movie's focus and its info panel (UIChooseTech.UpdateInfoPanelData). */
function Select(int Index)
{
	local XComGameState_LWStrategy S;
	local XComGameState_Tech Tech;
	local LWResearchRules.LWTechDef T;
	local string Info, Desc, Req, Why;
	local int Hours, Days, Id, c, k, Cut;

	if (bCredits)
	{
		if (CreditList.Length == 0)
			return;
		Selected = (Index + CreditList.Length) % CreditList.Length;
		MC.FunctionString("setFocus", string(Selected));
		MC.BeginFunctionOp("UpdateInfo");
		MC.QueueString(Caps(CreditNames[CreditList[Selected]]));
		MC.QueueString("");
		MC.QueueString(CreditSummary[CreditList[Selected]]);
		MC.QueueString("");
		MC.EndOp();
		return;
	}
	if (Techs.Length == 0)
		return;
	Selected = (Index + Techs.Length) % Techs.Length;
	Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Techs[Selected].ObjectID));
	Id = DefOf(Tech, T);
	MC.FunctionString("setFocus", string(Selected));
	// The time: EW's FAST (5 days or less), NORMAL (10 or less), SLOW, coloured, and the days (GetProgress, GetEstimateString).
	Hours = class'UIUtilities_Strategy'.static.GetXComHQ().GetResearchHours(Techs[Selected]);
	Days = Max(1, (Hours + 23) / 24);
	if (Hours <= 0)
		Info = Word(ETAInstant, "INSTANT");
	else
		// (The days in the time's colour too: EW's BuildTechSummary adds them to GetProgressText's coloured text.)
		Info = EWColoured((Days <= 5 ? Word(Progress[0], "FAST") : (Days <= 10 ? Word(Progress[1], "NORMAL") : Word(Progress[2], "SLOW")))
			@ "(" $ Expand(Days == 1 ? Word(ETADay, "<XGParam:IntValue0/> day") : Word(ETADays, "<XGParam:IntValue0/> days"), Days) $ ")", Days <= 5 ? 2 : (Days <= 10 ? 0 : 3));
	Req = Requirements(Tech, Why);
	if (Req != "")
		Info $= "\n" $ Word(CostLabel, "REQUIREMENTS:") $ Req;
	Desc = Why != "" ? EWColoured(Why, 3) $ "\n" : "";
	Desc $= Tech.GetSummary();
	// (BuildTechSummary: each credit held that applies, "Laser Weaponry research credit applies, reducing research time by 25%.")
	S = class'XComGameState_LWStrategy'.static.Get();
	for (c = 1; Id > 0 && S != none && c < 10; c++)
	{
		if (S.Credits.Find(c) == INDEX_NONE || (T.Credits.Find(c) == INDEX_NONE && c != 9))
			continue;
		k = class'LWResearchRules'.default.CreditShare.Find('Credit', c);
		Cut = k != INDEX_NONE ? class'LWResearchRules'.default.CreditShare[k].Percent + class'LWBonuses'.static.Has(class'LWBonuses'.const.EXPERTISE, S) : 0;
		Desc $= "\n" $ Expand(Word(CreditApplies, "<XGParam:StrValue0/> research credit applies, reducing research time by <XGParam:IntValue0/>%."), Cut, CreditNames[c]);
	}
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(Caps(Tech.GetDisplayName()));
	MC.QueueString(Info);
	MC.QueueString(Desc);
	MC.QueueString(class'LWX2Pictures'.static.Tech(Id, Tech.GetImage()));
	MC.EndOp();
}

/** The selected tech researched (XCOM 2's UIChooseResearch.OnTechTableOption, without its confirmation popups); one XCOM
 *  cannot afford refused, as EW's (OnTechTableOption: SFX_UI_No). */
function Accept()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local string Why;

	if (bCredits || Techs.Length == 0)
		return;
	Requirements(XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Techs[Selected].ObjectID)), Why);
	if (Why != "")
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ.SetNewResearchProject(Techs[Selected]);
	`log("LongWarX2: EW research screen: research begun:" @ XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Techs[Selected].ObjectID)).GetMyTemplateName(), , 'LongWarX2');
	CloseScreen();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (cmd == 391 && Target == "theConfirmButton")
		Accept();
	else if ((cmd == 400 || cmd == 398) && InStr(Target, "option") == 0)
	{
		Select(int(Mid(Target, 6)));
		if (cmd == 398)
			Accept();
	}
	super(UIScreen).OnMouseEvent(cmd, args);
}

/**
 * The option under the mouse, or -1. EW's list items do not report clicks to XCOM 2 (their own input code is EW's), so
 * each option's clip (itemList.theItems.<i>, as EW's list names them) is asked where the mouse is, in its own coordinates.
 */
function int OptionUnderMouse()
{
	local string Path;
	local float MouseX, MouseY, W, H;
	local int i;

	// (From the last up, as the build screen's: a row's box can cover the next row's, and the first row then took every
	// click; UILWEWEngineering.OptionUnderMouse.)
	for (i = (bCredits ? CreditList.Length : Techs.Length) - 1; i >= 0; i--)
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

	// A click on the list: the option under the mouse selected (a double click starts it).
	if ((cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP)
		&& (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		i = OptionUnderMouse();
		`log("LongWarX2: EW research screen: click on option" @ i, , 'LongWarX2');
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
		case class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_8:
		case class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_2:
			Select(Selected + (cmd == class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_2 ? 1 : -1));
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			Select(Selected - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			Select(Selected + 1);
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
	// (Over EW's research lab, as EW shows its research choice.)
	BaseCamera = ScienceLab
	// (EW's: UIChooseTech on UIDisplay_ScienceLabs through ScienceLab_UIDisplayCam.)
	EWDisplay = UIDisplay_ScienceLabs
	EWDisplayCamera = ScienceLab_UIDisplayCam
}
