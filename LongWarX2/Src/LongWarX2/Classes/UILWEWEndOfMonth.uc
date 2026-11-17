// The council's monthly report on Enemy Within's own End of Month Report screen (features/lw-geoscape.md): its
// EndOfMonthReport movie, driven as EW's UIEndOfMonthReport drives it from XGWorldReportUI (UpdateHeader: the title and the
// month, XCOM's activity, the rewards, the grade; UpdateBar per continent: its name, the specialists it sent, its bonus;
// UpdateCountry per council country: its name, panic and funding, or withdrawn). What it shows is the report the month's end
// kept (XComGameState_LWStrategy.Grade, EndMonth); the countries and continents as they stand after the meeting, as EW reads
// them. It comes after EW's transmission and defections (UILWEWWorldReport). Enter, Escape or a click carries on.
class UILWEWEndOfMonth extends UILWEWScreen;

/** EW's words, written from the player's install (scripts/lw-words.mjs, makeReportWords). */
var localized string MonthlyReport, FundingAwarded, MilitaryGrade, XComActivity, SpecialistsAwarded, NumScientists, NumEngineers;
var localized string GradeNames[5];
var localized string UFOShotDown, TerrorStopped, AbductionsStopped, SatellitesLaunched, ResearchCompleted, UFORaided;
var localized string SatellitesLost, UFOsEscaped, MismanagedResources, NoSatelliteCoverage, Withdrawn, BaseAssaulted;
var localized string FCMissions, TerrorFailed, TerrorIgnored, AbductionsFailed, AbductionsIgnored;
var localized string MonthlyReward, CarryOn;
var localized string LinkStatus, Next, Decoded, AndAppend, OneWithdrawn, ManyWithdrawn;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWEndOfMonth EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxEndOfMonthReport", class'Object', true);
	class'UILWEWMapBackdrop'.static.ShowIfAvailable();
	EWScreen = HQPres.Spawn(class'UILWEWEndOfMonth', HQPres);
	EWScreen.Package = name("/ package/ewxEndOfMonthReport/EndOfMonthReport");
	EWScreen.MCName = 'theScreen';
	HQPres.ScreenStack.Push(EWScreen);
}

simulated function OnInit()
{
	super.OnInit();
	Fill();
}

simulated function OnRemoved()
{
	class'UILWEWMapBackdrop'.static.HideAll();
	super.OnRemoved();
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

static function string Colored(string Text, int UIState)
{
	return class'UIUtilities_Text'.static.GetColoredText(Text, UIState);
}

/** "Scientists: +2, Engineers: +1" (XGWorldReportUI.GetSpecialistsText); "" for none. */
static function string Specialists(int Sci, int Eng)
{
	local string S;

	if (Sci > 0)
		S = Repl(Word(default.NumScientists, "Scientists: +<XGParam:IntValue0/>"), "<XGParam:IntValue0/>", string(Sci));
	if (Eng > 0)
		S $= (S != "" ? ", " : "") $ Repl(Word(default.NumEngineers, "Engineers: +<XGParam:IntValue0/>"), "<XGParam:IntValue0/>", string(Eng));
	return S;
}

/** XCOM's activity, in EW's order and colours (XGWorldReportUI.BuildActivityText): the wins green, the failures red. */
static function array<string> Activity(XComGameState_LWStrategy S)
{
	local array<string> A;
	local array<int> T;

	T = S.ReportTally;
	if (T.Length <= class'XComGameState_LWStrategy'.const.TALLIES)
		return A;
	if (T[class'XComGameState_LWStrategy'.const.T_ALIEN_BASES] > 0)
		A.AddItem(Colored(Word(default.BaseAssaulted, "Alien Base Eliminated"), eUIState_Good));
	Add(A, default.FCMissions, "Council Missions Completed:", T[class'XComGameState_LWStrategy'.const.T_COUNCIL_MISSIONS], eUIState_Good);
	Add(A, default.UFOShotDown, "UFOs Shot Down:", T[class'XComGameState_LWStrategy'.const.T_UFOS_SHOT_DOWN], eUIState_Good);
	Add(A, default.TerrorStopped, "Terror Missions Stopped:", T[class'XComGameState_LWStrategy'.const.T_TERROR_THWARTED], eUIState_Good);
	Add(A, default.AbductionsStopped, "Abductions Stopped:", T[class'XComGameState_LWStrategy'.const.T_ABDUCTIONS_THWARTED], eUIState_Good);
	Add(A, default.TerrorIgnored, "Terror Missions Ignored:", T[class'XComGameState_LWStrategy'.const.T_TERROR_IGNORED], eUIState_Bad);
	Add(A, default.TerrorFailed, "Terror Missions Failed:", T[class'XComGameState_LWStrategy'.const.T_TERROR_FAILED], eUIState_Bad);
	Add(A, default.AbductionsIgnored, "Abductions Ignored:", T[class'XComGameState_LWStrategy'.const.T_ABDUCTIONS_IGNORED], eUIState_Bad);
	Add(A, default.AbductionsFailed, "Abductions Failed:", T[class'XComGameState_LWStrategy'.const.T_ABDUCTIONS_FAILED], eUIState_Bad);
	Add(A, default.SatellitesLaunched, "Satellites Launched:", T[class'XComGameState_LWStrategy'.const.T_SATELLITES_LAUNCHED], eUIState_Good);
	Add(A, default.ResearchCompleted, "Research Projects Completed:", T[class'XComGameState_LWStrategy'.const.T_TECHS], eUIState_Good);
	Add(A, default.UFORaided, "UFOs Raided:", T[class'XComGameState_LWStrategy'.const.T_UFO_RAIDS], eUIState_Good);
	Add(A, default.SatellitesLost, "Satellites Lost:", T[class'XComGameState_LWStrategy'.const.T_SATELLITES_LOST], eUIState_Bad);
	Add(A, default.UFOsEscaped, "UFOs Escaped:", T[class'XComGameState_LWStrategy'.const.TALLIES], eUIState_Bad);
	if (S.bReportMismanaged)
		A.AddItem(Colored(Word(default.MismanagedResources, "Mismanaged Resources:") @ class'LWStrategyRules'.static.Money(S.ReportMoney), eUIState_Bad));
	return A;
}

static function Add(out array<string> A, string Label, string Fallback, int N, int UIState)
{
	if (N > 0)
		A.AddItem(Colored(Word(Label, Fallback) @ N, UIState));
}

/** The month reported (the one just ended: Long War's campaigns begin on March 1st, its months are of 30 days here). */
static function string MonthText(XComGameState_LWStrategy S)
{
	local TDateTime T;

	class'X2StrategyGameRulesetDataStructures'.static.SetTime(T, 0, 0, 0, 3, 1, 2015);
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(T, Max(0, S.ReportHours - 15 * 24));
	return class'X2StrategyGameRulesetDataStructures'.static.GetMonthString(class'X2StrategyGameRulesetDataStructures'.static.GetMonth(T)) $ ","
		@ class'X2StrategyGameRulesetDataStructures'.static.GetYear(T);
}

/** A country's funding now (EndMonth's: without a satellite, Long War's base share). */
static function int CountryFunding(XComGameState_LWStrategy S, int k)
{
	local int d;

	d = class'LWStrategyRules'.static.Difficulty();
	return d >= 0 ? S.CountryFunding(k, S.Countries[k].bSatellite) : 0;
}

/** The continent's bonus held (all its countries under satellites): its name, without Long War's ": ". */
static function string BonusTitle(XComGameState_LWStrategy S, int Continent)
{
	local int i;
	local string N;

	if (!class'LWBonuses'.static.ContinentCovered(S, Continent))
		return "";
	for (i = 0; i < class'LWBonuses'.default.Bonuses.Length; i++)
	{
		if (class'LWBonuses'.default.Bonuses[i].Kind != 2 || class'LWBonuses'.default.Bonuses[i].Continent != Continent)
			continue;
		N = class'LWBonuses'.static.Text(i, true);
		if (Right(N, 2) == ": ")
			N = Left(N, Len(N) - 2);
		else if (Right(N, 1) == ":")
			N = Left(N, Len(N) - 1);
		return N;
	}
	return "";
}

function Fill()
{
	local XComGameState_LWStrategy S;
	local array<string> Acts;
	local string Act, Rewards, Grade;
	local int i, c, k, Slot, Sci, Eng, Funding, UIState;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return;
	Acts = Activity(S);
	for (i = 0; i < Acts.Length; i++)
		Act $= (i == 0 ? Word(XComActivity, "XCOM Activity") $ ": " : ", ") $ Acts[i];
	Rewards = Word(MonthlyReward, "Monthly Reward:") @ Colored("+" $ class'LWStrategyRules'.static.Money(S.ReportFunding), eUIState_Cash) $ "\n" $ Word(MonthlyReward, "Monthly Reward:")
		@ Colored(Specialists(S.ReportScientists, S.ReportEngineers), eUIState_Cash);
	if (S.ReportGrade <= 1)
		UIState = eUIState_Good;
	else if (S.ReportGrade == 2)
		UIState = eUIState_Warning;
	else
		UIState = eUIState_Bad;
	Grade = Colored(Word(GradeNames[Clamp(S.ReportGrade, 0, 4)], Mid("ABCDF", Clamp(S.ReportGrade, 0, 4), 1)), UIState);
	MC.BeginFunctionOp("UpdateHeader");
	MC.QueueString(Caps(Word(MonthlyReport, "\"XCOM Project\" Monthly Report") @ "-" @ MonthText(S)));
	MC.QueueString(Act);
	MC.QueueString(Rewards);
	MC.QueueString(Word(MilitaryGrade, "GRADE"));
	MC.QueueString(Grade);
	MC.EndOp();
	for (c = 0; c < 5; c++)
	{
		Sci = 0;
		Eng = 0;
		for (k = 0; k < S.Countries.Length; k++)
		{
			if (S.CountryContinent(k) != c || S.Countries[k].bLeft || !S.Countries[k].bSatellite)
				continue;
			Sci += class'LWStrategyRules'.default.Countries[k].Scientists;
			Eng += class'LWStrategyRules'.default.Countries[k].Engineers;
		}
		MC.BeginFunctionOp("UpdateBar");
		MC.QueueNumber(c);
		MC.QueueString(Caps(class'LWStrategyRules'.static.ContinentName(c)));
		MC.QueueString(Specialists(Sci, Eng));
		MC.QueueString(BonusTitle(S, c));
		MC.QueueNumber(c);
		MC.QueueBoolean(false);
		MC.EndOp();
		Slot = 0;
		for (k = 0; k < S.Countries.Length && Slot < 4; k++)
		{
			if (S.CountryContinent(k) != c)
				continue;
			Funding = CountryFunding(S, k);
			MC.BeginFunctionOp("UpdateCountry");
			MC.QueueNumber(c);
			MC.QueueNumber(Slot);
			MC.QueueString(Caps(S.CountryName(k)));
			if (S.Countries[k].bLeft)
			{
				MC.QueueNumber(-1);
				MC.QueueString(Colored(Word(Withdrawn, "WITHDRAWN"), eUIState_Disabled));
			}
			else
			{
				// EW's panic levels, 1 to 5 (its colours know only these); Long War's panic bars below.
				MC.QueueNumber(Clamp(S.Countries[k].Panic / 20 + 1, 1, 5));
				MC.QueueString(Funding > 0 ? Colored("+" $ class'LWStrategyRules'.static.Money(Funding), eUIState_Cash) : Colored(Word(NoSatelliteCoverage, "NO SATELLITE COVERAGE"), eUIState_Disabled));
			}
			MC.EndOp();
			if (!S.Countries[k].bLeft)
				PanicBar(c, Slot, S.Countries[k].Panic);
			Slot++;
		}
	}
	MC.BeginFunctionOp("SetHelp");
	MC.QueueNumber(3);
	MC.QueueString(Caps(Word(CarryOn, "Carry On")));
	MC.QueueString("");
	MC.EndOp();
	`log("LongWarX2: the council's report shown: grade" @ S.ReportGrade @ "funding" @ S.ReportFunding @ Acts.Length @ "lines of activity", , 'LongWarX2');
}

/** A country's panic clip at Long War's panic (its 0 to 100, plus one) when it has the frames for it (Long War's movies draw
 *  their panic bars from that number, as the Situation Room's do); else EW's level stands. */
function PanicBar(int Bar, int Slot, int Panic)
{
	local string Clip;

	Clip = MCPath $ ".bar" $ Bar $ ".country" $ Slot $ ".panic";
	if (Movie.GetVariableNumber(Clip $ "._totalframes") > 6)
		MC.ChildFunctionNum("bar" $ Bar $ ".country" $ Slot $ ".panic", "gotoAndStop", Panic + 1);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Joined;
	local int i;

	for (i = 0; i < args.Length; i++)
		Joined @= args[i];
	if (cmd == 391 && (InStr(Joined, "theStartButton") != INDEX_NONE || InStr(Caps(Joined), "HELP") != INDEX_NONE || InStr(Joined, "Button") != INDEX_NONE))
	{
		CarryOnNow();
		return;
	}
	super.OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			CarryOnNow();
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

function CarryOnNow()
{
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	CloseScreen();
}

defaultproperties
{
}
