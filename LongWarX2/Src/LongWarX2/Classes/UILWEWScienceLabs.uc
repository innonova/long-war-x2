// Enemy Within's research report and archives (features/strategy-flow.md; the research room's Access Research Archives):
// its ScienceLabs movie, driven as EW's UIScienceLabs drives it from XGResearchUI (UpdateArchives, UpdateReport). The
// archives list every tech researched; the one under the mouse or the keys is shown as EW's report: RESEARCH REPORT, its
// codename and the month it was done, the subject, its picture, Long War's report text, and what it opened: facilities to
// build, items to make, gene mods, Foundry projects, the research credit it earned, as EW words them. Choosing one shows the
// report alone (EW's view 3); back returns to the list, and from the list to the room.
class UILWEWScienceLabs extends UILWEWScreen dependson(LWGearRules, LWBaseRules);

/** EW's words: UIScienceLabs' titles, XGResearchUI's report labels and results. */
var localized string m_strScienceLabsArchiveTitle, m_strScienceLabsReportTitle, m_strTopSecret;
var localized string ReportTitle, CodeName, FacilityAvailable, ItemAvailable, GeneModAvailable, FoundryAvailable, CreditEarned, BonusMeld;

/** The techs researched (their state objects), in Long War's numbering's order (UpdateArchives). */
var array<XComGameState_Tech> Researched;
var int Selected;
/** Showing one report alone (EW's view 3), not the list beside it (view 2). */
var bool bReportOnly;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWScienceLabs S;

	DynamicLoadObject(default.UIPackage $ ".ewxScienceLabs", class'Object', true);
	S = HQPres.Spawn(class'UILWEWScienceLabs', HQPres);
	S.Package = name("/ package/ewxScienceLabs/ScienceLabs");
	S.MCName = 'theScienceLabs';
	Push3D(HQPres, S);
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

static function string Expand(string W, optional int IntValue, optional string StrValue)
{
	return Repl(Repl(W, "<XGParam:IntValue0/>", string(IntValue)), "<XGParam:StrValue0/>", StrValue);
}

simulated function OnInit()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech Tech;
	local array<int> Ids;
	local int Id, j;

	super.OnInit();
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	// (UpdateArchives: Long War's techs researched, by number.)
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', Tech)
	{
		Id = class'LWResearchRules'.static.IdOfTemplate(Tech.GetMyTemplateName());
		if (Id <= 0 || !XComHQ.TechIsResearched(Tech.GetReference()))
			continue;
		for (j = 0; j < Ids.Length && Ids[j] < Id; j++);
		Ids.InsertItem(j, Id);
		Researched.InsertItem(j, Tech);
	}
	SetTimer(0.1, false, nameof(Fill));
}

/** RealizeArchiveList, then the first report (OnInit: OnOption). Every call at once (Movie.Invoke). */
function Fill()
{
	local array<ASValue> Params;
	local int i;

	CallNow("ClearArchives", Params);
	Params.AddItem(Str(Word(m_strScienceLabsArchiveTitle, "ARCHIVES")));
	CallNow("SetArchiveTitle", Params);
	Params.Length = 0;
	Params.AddItem(Str(Word(m_strTopSecret, "TOP SECRET")));
	CallNow("SetTopSecretText", Params);
	for (i = 0; i < Researched.Length; i++)
	{
		Params.Length = 0;
		Params.AddItem(Num(i));
		Params.AddItem(Str(Researched[i].GetDisplayName()));
		Params.AddItem(AsBool(false));
		CallNow("AddOption", Params);
	}
	Params.Length = 0;
	Params.AddItem(AsBool(true));
	CallNow("EnableArchives", Params);
	Choose(0);
}

static function ASValue AsBool(bool V)
{
	local ASValue A;

	A.Type = AS_Boolean;
	A.b = V;
	return A;
}

/** An archive chosen (OnChooseArchive): its report shown, the list's selection on it. */
function Choose(int i)
{
	local array<ASValue> Params;

	if (Researched.Length == 0)
		return;
	Selected = Clamp(i, 0, Researched.Length - 1);
	ShowReport(Researched[Selected]);
	Params.AddItem(Num(Selected));
	CallNow("SetListSelection", Params);
}

/** XGResearchUI.UpdateReport and UIScienceLabs.RealizeReport. */
function ShowReport(XComGameState_Tech Tech)
{
	local XComGameState_LWStrategy S;
	local LWResearchRules.LWTechDef T;
	local LWBaseRules.LWFacilityDef F;
	local LWGearRules.LWBuildDef B;
	local LWGearRules.LWFoundryDef P;
	local LWBaseRules.LWGeneMod G;
	local X2ItemTemplate Item;
	local X2TechTemplate Project;
	local array<string> Results;
	local array<ASValue> Params;
	local TDateTime When;
	local string Line;
	local int Id;

	Id = class'LWResearchRules'.static.IdOfTemplate(Tech.GetMyTemplateName());
	class'LWResearchRules'.static.TechById(Id, T);
	S = class'XComGameState_LWStrategy'.static.Get();
	// What it opened, each in EW's warning colour: facilities, items (those engineering builds), gene mods, Xenogenetics'
	// meld, Foundry projects; the research credit it earned in EW's good colour.
	foreach class'LWBaseRules'.default.Facilities(F)
		if (F.Tech == Id)
			Results.AddItem(EWColoured(Expand(Word(FacilityAvailable, "<XGParam:StrValue0/> available for construction."), , class'LWBase'.static.FacilityName(F.Id)), 4));
	foreach class'LWGearRules'.default.Builds(B)
	{
		if (B.Tech != Id)
			continue;
		Item = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(B.Template);
		if (Item != none)
			Results.AddItem(EWColoured(Expand(Word(ItemAvailable, "<XGParam:StrValue0/> available for manufacture."), , Item.GetItemFriendlyName()), 4));
	}
	foreach class'LWBaseRules'.default.GeneMods(G)
		if (G.Tech == Id)
			Results.AddItem(EWColoured(Expand(Word(GeneModAvailable, "<XGParam:StrValue0/> available in Gene Lab."), , class'UILWEWGeneMods'.static.ModName(G.Perk)), 4));
	if (Id == 13)
		Results.AddItem(EWColoured(Expand(Word(BonusMeld, "Acquiring more meld should be a top priority."), , "40"), 4));
	foreach class'LWGearRules'.default.Foundry(P)
	{
		if (P.Tech != Id)
			continue;
		Project = X2TechTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(class'LWGearRules'.static.FoundryTemplateFor(P.Id)));
		if (Project != none)
			Results.AddItem(EWColoured(Expand(Word(FoundryAvailable, "<XGParam:StrValue0/> project available in the Foundry."), , Project.DisplayName), 4));
	}
	if (T.GrantsCredit > 0)
		Results.AddItem(EWColoured(Expand(Word(CreditEarned, "<XGParam:StrValue0/>: research credit earned."), , class'UILWEWResearch'.default.CreditNames[T.GrantsCredit]), 2));
	// The titles: RESEARCH REPORT; "Codename: …" and the month it was done, in Long War's calendar.
	When = class'XComGameState_LWStrategy'.static.LongWarDate(Tech.CompletionTime);
	Params.AddItem(Str(Word(ReportTitle, "Research Report")));
	Params.AddItem(Str(Word(CodeName, "Codename:") @ Tech.GetMyTemplate().CodeName $ "\n"
		$ class'X2StrategyGameRulesetDataStructures'.static.GetMonthString(class'X2StrategyGameRulesetDataStructures'.static.GetMonth(When)) $ ","
		@ class'X2StrategyGameRulesetDataStructures'.static.GetYear(When)));
	CallNow("SetReportTitles", Params);
	Params.Length = 0;
	Params.AddItem(Str(Tech.GetDisplayName()));
	Params.AddItem(Str(Tech.GetMyTemplate().LongDescription));
	Params.AddItem(Str(class'LWX2Pictures'.static.Tech(Id, Tech.GetImage())));
	CallNow("SetReportItem", Params);
	Params.Length = 0;
	CallNow("ClearResults", Params);
	foreach Results(Line)
	{
		Params.Length = 0;
		Params.AddItem(Str(Line));
		CallNow("AddResults", Params);
	}
}

/** The list (EW's view 2) or one report alone (view 3). */
function ReportOnly(bool bOnly)
{
	local array<ASValue> Params;

	bReportOnly = bOnly;
	Params.AddItem(AsBool(!bOnly));
	CallNow("EnableArchives", Params);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	if (!bReportOnly && args.Length > 1 && args[args.Length - 2] == "theItems")
	{
		if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN)
		{
			Choose(int(args[args.Length - 1]));
			return;
		}
		if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		{
			Choose(int(args[args.Length - 1]));
			ReportOnly(true);
			PlaySound(SoundCue'SoundUI.MenuSelectCue', true);
			return;
		}
	}
	super.OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local array<ASValue> Params;

	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		if (bReportOnly)
			ReportOnly(false);
		else
			ReportOnly(true);
		return true;
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		// (OnCancel: from one report back to the list; from the list out.)
		if (bReportOnly)
		{
			ReportOnly(false);
			return true;
		}
		break;
	case class'UIUtilities_Input'.const.FXS_ARROW_UP:
	case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		if (!bReportOnly)
			Choose(Selected - 1);
		return true;
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		if (!bReportOnly)
			Choose(Selected + 1);
		return true;
	case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:
		CallNow("ScrollResearchUp", Params);
		return true;
	case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN:
		CallNow("ScrollResearchDown", Params);
		return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	BaseCamera = ScienceLab
	// (EW's: UIScienceLabs on UIDisplay_Report through ScienceLab_UIDisplayCam_Report.)
	EWDisplay = UIDisplay_Report
	EWDisplayCamera = ScienceLab_UIDisplayCam_Report
}
