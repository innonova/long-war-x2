// Enemy Within's soldier list (features/strategy-flow.md; the barracks' View Soldiers): Long War's SoldierList movie (the
// player's converted Long War UI), driven as Long War's UISoldierListBase and UISoldierList_Barracks drive it from its
// soldier table (XGBarracksUI.BuildSoldierOption):
// - a row a soldier (AddSoldierWithNickname): the name line Long War's movie splits into its stat icons
//   (XGStrategySoldier.GetName, type 8: "RANK First 'Nick' Last|HP|Mobility|Will|Aim|Defense|<experience>|<psi>"), the
//   class in its colour, the status in its state's colour, promotable, the rank's and class's icons, the flag;
// - the title's tally (SetCountLabel): soldiers available of all, then per class, with Long War's class icons;
// - the selection (SetSelected) follows the mouse; a click opens the soldier (EW's summary, UILWEWSoldierSummary).
// Long War's class icons in the title's tally come from Long War's own package, converted on the player's machine
// (LongWar.upk: img://LongWar.ClassIcons.*); the rows' class icons and flags are EW's own (XComIcons' frames). EW's
// resource panel is hidden over it
// (UILWEWStrategyHUD.ShowForTop), as XGBarracksUI.UpdateSoldierList hides it.
class UILWEWSoldierList extends UILWEWScreen;

var localized string Title, ClassLabel, StatusLabel;
var localized string Active, OnMission, PsiTesting, CovertOps, GeneMod, Augmenting, Healing, Fatigued, Wounded, GravelyWounded, Dead;

/** The soldiers in the list's order, and the one selected. */
var array<StateObjectReference> Soldiers;
var int Selected;
/** Opened to choose a soldier for a lab (OpenFor; EW's UISoldierList_PsiLabs, _GeneLab, _CyberneticsLab): those the lab
 *  cannot take greyed, the chosen one handed to it. */
var UILWEWSoldierSlots ForLab;

/** Long War's eight classes (EW's soldier class numbers in its list, UISoldierListBase.UpdateDisplay): XCOM 2's class
 *  template, Long War's number, its colour and its icon in Long War's package. */
struct LWX2ListClass
{
	var name Template;
	var int Id;
	var string Color;
	var string Icon;
	/** Its base class's frame in EW's class icon (XComIcons: sniper, heavy, support, assault). */
	var string Frame;
};
var array<LWX2ListClass> Classes;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWSoldierList S;

	DynamicLoadObject(default.UIPackage $ ".ewxSoldierList", class'Object', true);
	// (Long War's icons and flags, its own package converted on the player's machine.)
	DynamicLoadObject("LongWar.ClassIcons.assault", class'Object', true);
	S = HQPres.Spawn(class'UILWEWSoldierList', HQPres);
	S.Package = name("/ package/ewxSoldierList/SoldierList");
	S.MCName = 'theScreen';
	HQPres.ScreenStack.Push(S);
}

/** For a lab: its soldiers (no SHIVs or MECs), those it cannot take greyed; one chosen, the list closes and the lab has them. */
static function UILWEWSoldierList OpenFor(XComHQPresentationLayer HQPres, UILWEWSoldierSlots Lab)
{
	local UILWEWSoldierList S;

	DynamicLoadObject(default.UIPackage $ ".ewxSoldierList", class'Object', true);
	DynamicLoadObject("LongWar.ClassIcons.assault", class'Object', true);
	S = HQPres.Spawn(class'UILWEWSoldierList', HQPres);
	S.Package = name("/ package/ewxSoldierList/SoldierList");
	S.MCName = 'theScreen';
	S.ForLab = Lab;
	S.BaseCamera = '';
	HQPres.ScreenStack.Push(S);
	return S;
}

simulated function OnInit()
{
	super.OnInit();
	Fill();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (bIsInited)
		Fill();
}

/** The rows, the title and its tally, as Long War's UpdateDataFromTable and UpdateDisplay make them. */
function Fill()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local array<int> Avail, Total;
	local string Status, Tally;
	local int UIState, i, k, nAvail;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	S = class'XComGameState_LWStrategy'.static.Get();
	MC.FunctionVoid("ClearSoldierList");
	Soldiers.Length = 0;
	Avail.Length = Classes.Length;
	Total.Length = Classes.Length;
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier() || Unit.IsDead())
			continue;
		// (A lab's list: no SHIVs or MECs, XGPsiLabsUI.UpdateSoldierList.)
		if (ForLab != none && (Unit.IsRobotic() || class'LWMECs'.static.IsMEC(Unit)))
			continue;
		Soldiers.AddItem(Ref);
		Status = StatusOf(Unit, S, UIState);
		k = Classes.Find('Template', Unit.GetSoldierClassTemplateName());
		MC.BeginFunctionOp("AddSoldierWithNickname");
		MC.QueueString(NameLine(Unit));
		MC.QueueString(Repl(Unit.GetNickName(), "'", ""));
		MC.QueueString(ClassText(Unit, k));
		MC.QueueString(Colored(Status, UIState));
		// (Greyed: a lab's list, a soldier it cannot take; UISoldierListBase, the option's state 1.)
		MC.QueueBoolean(ForLab != none && ForLab.WhyNot(Unit) != "");
		MC.QueueBoolean(Unit.ShowPromoteIcon());
		MC.QueueBoolean(false);
		MC.QueueString("rank" $ Clamp(Unit.GetRank(), 0, 7));
		MC.QueueString(k != INDEX_NONE ? Classes[k].Frame : "");
		MC.QueueString(FlagOf(Unit.GetCountry()));
		// (An officer's insignia, one a rank reached: EW's medals, as Long War keeps its officer ranks in them,
		// UIUtilities.GetMedalLabels.)
		MC.QueueString(class'UILWEWOfficers'.static.Insignia(Unit));
		MC.EndOp();
		// (Available: active or ready, Long War's states 2 and 0.)
		if (UIState == 2 || UIState == 0)
		{
			nAvail++;
			if (k != INDEX_NONE)
				Avail[k]++;
		}
		if (k != INDEX_NONE)
			Total[k]++;
	}
	MC.BeginFunctionOp("SetTitleLabels");
	MC.QueueString(Word(Title, "SOLDIERS"));
	MC.QueueString(Word(ClassLabel, "CLASS"));
	MC.QueueString(Word(StatusLabel, "STATUS"));
	MC.EndOp();
	Tally = nAvail $ "<font size='14'>/" $ Soldiers.Length $ "</font>";
	for (i = 0; i < Classes.Length; i++)
		Tally $= " <font color='#" $ Classes[i].Color $ "' size='20'><img src='img://LongWar.ClassIcons." $ Classes[i].Icon
			$ "' height='32' width='32' vspace='-16'>" $ Avail[i] $ "<font size='14'>/" $ Total[i] $ "</font></font>";
	MC.FunctionString("SetCountLabel", Tally);
	Selected = Clamp(Selected, 0, Max(0, Soldiers.Length - 1));
	Select(Selected);
}

/** Long War's name line (XGStrategySoldier.GetName, type 8). */
function string NameLine(XComGameState_Unit Unit)
{
	local string Line, Nick;
	local int Rank, XP;

	// (The nickname alone: XCOM 2's eNameType_Nick comes quoted, and as quotes round nothing when there is none.)
	Nick = Repl(Unit.GetNickName(), "'", "");
	if (Repl(Nick, " ", "") != "")
		Nick = "'" $ Nick $ "'";
	else
		Nick = "";
	Line = RankShort(Unit) @ Unit.GetName(eNameType_First) @ (Nick != "" ? Nick $ " " : "") $ Unit.GetName(eNameType_Last);
	Line $= "|" $ int(Unit.GetBaseStat(eStat_HP)) $ "|" $ int(Unit.GetBaseStat(eStat_Mobility)) $ "|" $ int(Unit.GetBaseStat(eStat_Will))
		$ "|" $ int(Unit.GetBaseStat(eStat_Offense)) $ "|" $ int(Unit.GetBaseStat(eStat_Defense)) $ "|";
	Rank = Unit.GetRank();
	XP = class'LWExperience'.static.XPOf(Unit);
	Line $= "<font size='1'><br></font><font color='#FFD038' size='16'>" $ XP
		$ (Rank < 7 ? "/" $ class'X2ExperienceConfig'.static.GetRequiredKills(Rank + 1) $ "</font>" : "") $ "|";
	return Line;
}

/** The rank's short name, an officer's as Long War names it (XGStrategySoldier.GetName, type 9: the medal's). */
static function string RankShort(XComGameState_Unit Unit)
{
	local int Officer;

	Officer = class'LWOfficers'.static.Rank(Unit);
	if (Officer >= 1 && Officer <= 5 && class'LWOfficers'.default.RankShort[Officer - 1] != "")
		return Caps(class'LWOfficers'.default.RankShort[Officer - 1]);
	return class'X2ExperienceConfig'.static.GetShortRankName(Unit.GetRank(), Unit.GetSoldierClassTemplateName());
}

function string ClassText(XComGameState_Unit Unit, int k)
{
	local string N;

	N = Unit.GetSoldierClassTemplate() != none ? Caps(Unit.GetSoldierClassTemplate().DisplayName) : "";
	return k != INDEX_NONE ? "<font color='#" $ Classes[k].Color $ "'>" $ N $ "</font>" : N;
}

/** Long War's status and its state (XGStrategySoldier.GetStatusString, GetStatusUIState): wounds first, then the labs,
 *  covert operations, fatigue, with the days or hours left. */
static function string StatusOf(XComGameState_Unit Unit, XComGameState_LWStrategy S, out int UIState)
{
	local int i, Hours;

	if (Unit.IsDead())
	{
		UIState = 3;
		return Word(default.Dead, "KIA");
	}
	if (S != none)
	{
		for (i = 0; i < S.PsiTrainees.Length; i++)
			if (S.PsiTrainees[i].Unit == Unit.ObjectID)
			{
				UIState = 1;
				return Word(default.PsiTesting, "Psionic Training") @ Time(S.PsiTrainees[i].HoursLeft);
			}
		for (i = 0; i < S.GenePatients.Length; i++)
			if (S.GenePatients[i].Unit == Unit.ObjectID)
			{
				UIState = 1;
				return Word(default.GeneMod, "Genetics Lab") @ Time(class'XComGameState_LWStrategy'.static.GeneHoursLeft(S.GenePatients[i]));
			}
		for (i = 0; i < S.MECPatients.Length; i++)
			if (S.MECPatients[i].Unit == Unit.ObjectID)
			{
				UIState = 1;
				return Word(default.Augmenting, "Cybernetic Augmentation") @ Time(S.MECPatients[i].HoursLeft);
			}
		if (S.ExaltOperative == Unit.ObjectID)
		{
			UIState = 5;
			return Word(default.CovertOps, "On Covert Operation");
		}
	}
	if (Unit.IsInjured())
	{
		UIState = 3;
		Hours = S != none ? class'LWWounds'.static.HoursFor(Unit, S) : 0;
		return (Unit.IsGravelyInjured() ? Word(default.GravelyWounded, "Gravely Wounded") : Word(default.Wounded, "Wounded")) @ Time(Hours);
	}
	Hours = S != none ? class'LWFatigue'.static.ValueOf(Unit, 'LWX2RestedAt') - S.Hours : 0;
	if (Hours > 0)
	{
		UIState = 0;
		return Word(default.Fatigued, "Fatigued") @ Time(Hours);
	}
	UIState = 2;
	return Word(default.Active, "Active");
}

/** "(n days)" or "(n hours)", as Long War appends the time out (UIUtilities.GetDaysString, GetHoursString). */
static function string Time(int Hours)
{
	if (Hours <= 0)
		return "";
	if (Hours >= 24)
		return "(" $ Repl((Hours / 24 == 1 ? class'UILWEWStrategyHUD'.default.OneDay : class'UILWEWStrategyHUD'.default.ManyDays) != "" ? (Hours / 24 == 1 ? class'UILWEWStrategyHUD'.default.OneDay : class'UILWEWStrategyHUD'.default.ManyDays) : "%d days", "%d", string(Hours / 24)) $ ")";
	return "(" $ Repl(class'UILWEWStrategyHUD'.default.EtaHour != "" ? class'UILWEWStrategyHUD'.default.EtaHour : "%dh", "%d", string(Hours)) $ ")";
}

/** Long War's state colours (UIUtilities.GetHTMLColoredText): 0 normal, 1 warning, 2 good, 3 bad, 5 psionic. */
static function string Colored(string Text, int UIState)
{
	switch (UIState)
	{
	case 1: return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Warning);
	case 2: return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Good);
	case 3: return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Bad);
	case 5: return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Psyonic);
	}
	return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Normal);
}

/** EW's flag for an XCOM 2 nationality: its frame in EW's flag (XComFlag.SetCountry, "_" and the name in lower case);
 *  EW has none for Belgium, Indonesia, Iran, the Netherlands, Norway, Poland, Scotland and Sweden (its "unknown"). */
static function string FlagOf(name Country)
{
	local string N;

	N = Locs(Mid(string(Country), 8));
	switch (N)
	{
	case "usa": return "unitedstates";
	case "uk": return "unitedkingdom";
	case "belgium": case "indonesia": case "iran": case "netherlands": case "norway": case "poland": case "scotland": case "sweden":
		return "unknown";
	}
	return N;
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

/** The row selected (Long War's RealizeSelected: SetSelected with the row's index). */
function Select(int i)
{
	Selected = i;
	MC.FunctionString("SetSelected", string(i));
}

/** The row in an event's path ("…theItems.<i>…"), or -1. */
function int RowIn(array<string> args)
{
	local int k;

	for (k = args.Length - 1; k >= 0; k--)
		if ((string(int(args[k])) == args[k]) && k > 0 && (args[k - 1] == "theItems"))
			return int(args[k]);
	return (args.Length > 0 && (string(int(args[args.Length - 1])) == args[args.Length - 1])) ? int(args[args.Length - 1]) : -1;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int i;

	super.OnMouseEvent(cmd, args);
	i = RowIn(args);
	if (i < 0 || i >= Soldiers.Length)
		return;
	if (cmd == 392)
		Select(i);
	else if (cmd == 391 || cmd == 400 || cmd == 398)
		Choose(i);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0 && Soldiers.Length > 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			Select(Selected > 0 ? Selected - 1 : Soldiers.Length - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			Select(Selected + 1 < Soldiers.Length ? Selected + 1 : 0);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Choose(Selected);
			return true;
		}
	}
	return super.OnUnrealCommand(cmd, arg);
}

/** A soldier chosen: EW's soldier summary, in EW's armory room; for a lab, handed to it (greyed: refused). */
function Choose(int i)
{
	local UILWEWSoldierSlots Lab;
	local StateObjectReference Ref;

	if (i < 0 || i >= Soldiers.Length)
		return;
	Select(i);
	if (ForLab != none)
	{
		if (ForLab.WhyNot(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Soldiers[i].ObjectID))) != "")
		{
			PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
			return;
		}
		Lab = ForLab;
		Ref = Soldiers[i];
		CloseScreen();
		Lab.Chosen(Ref);
		return;
	}
	class'UILWEWSoldierSummary'.static.Open(XComHQPresentationLayer(Movie.Pres), Soldiers[i]);
}

defaultproperties
{
	BaseCamera = "BARRACKS"
	Classes(0)=(Template=LWS_Sniper,Id=11,Color="ffd800",Icon="sniper",Frame="sniper")
	Classes(1)=(Template=LWS_Scout,Id=21,Color="fe642e",Icon="scout",Frame="sniper")
	Classes(2)=(Template=LWS_Rocketeer,Id=12,Color="c01080",Icon="rocketeer",Frame="heavy")
	Classes(3)=(Template=LWS_Gunner,Id=22,Color="609020",Icon="heavy",Frame="heavy")
	Classes(4)=(Template=LWS_Medic,Id=13,Color="fafafa",Icon="support",Frame="support")
	Classes(5)=(Template=LWS_Engineer,Id=23,Color="20b0a0",Icon="engineer",Frame="support")
	Classes(6)=(Template=LWS_Assault,Id=14,Color="fe2e2e",Icon="assault",Frame="assault")
	Classes(7)=(Template=LWS_Infantry,Id=24,Color="5882fa",Icon="infantry",Frame="assault")
}
