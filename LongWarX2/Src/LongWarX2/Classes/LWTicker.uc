// The Situation Room's news ticker (features/ew-sitroom-ticker.md), as Long War's XGFacility_SituationRoom keeps it: five
// headlines, newest first. A headline is pushed by a country's panic changing (XGCountry.AddPanic), a mission's result
// (XGFundingCouncil, as the mission's report is made), a country leaving the council, EXALT's operations, a UFO shot
// down, and, after 120 hours without news, an ambient one of the act (XGFacility_SituationRoom.Update). A country's new
// headline replaces its old one. Each family's lines are dealt without repeats until all are used, those still shown kept
// out of the next deal (Get…TickerString). EW's words, written from the player's install (lw-words.mjs, makeTickerWords):
// each line "family|text".
class LWTicker extends Object;

var localized string Title;
var localized array<string> Lines;

/** Hours without news before an ambient headline (XGFacility_SituationRoom: m_iLastPushedTicker = 120). */
const QUIET_HOURS = 120;
const MAX_SHOWN = 5;

/** EW's text colours (TText.iState): 0 plain, 2 good, 3 bad. */
const PLAIN = 0;
const GOOD = 2;
const BAD = 3;

static function string FamilyOf(int Line)
{
	local int i;

	i = InStr(default.Lines[Line], "|");
	return i < 0 ? "" : Left(default.Lines[Line], i);
}

static function string TextOf(int Line)
{
	local int i;

	if (Line < 0 || Line >= default.Lines.Length)
		return "";
	i = InStr(default.Lines[Line], "|");
	return i < 0 ? default.Lines[Line] : Mid(default.Lines[Line], i + 1);
}

/**
 * A headline of a family pushed: a line not yet used (the family dealt again, but for those shown, once all are), at the
 * front; a country's other headline taken away first (RemoveCountrySpecificHeadline). Returns false if the family has no
 * lines (the player's words not written).
 */
static function bool Push(XComGameState_LWStrategy S, string Family, int Country, int State)
{
	local array<int> Pool, Shown;
	local XComGameState_LWStrategy.LWTickerItem Item;
	local int i;

	for (i = 0; i < default.Lines.Length; i++)
		if (FamilyOf(i) == Family)
			Pool.AddItem(i);
	if (Pool.Length == 0)
		return false;
	for (i = 0; i < S.Ticker.Length; i++)
		Shown.AddItem(S.Ticker[i].Line);
	for (i = Pool.Length - 1; i >= 0; i--)
		if (S.TickerUsed.Find(Pool[i]) != INDEX_NONE)
			Pool.Remove(i, 1);
	if (Pool.Length == 0)
	{
		for (i = 0; i < default.Lines.Length; i++)
			if (FamilyOf(i) == Family && Shown.Find(i) == INDEX_NONE)
			{
				S.TickerUsed.RemoveItem(i);
				Pool.AddItem(i);
			}
		if (Pool.Length == 0)
			return false;
	}
	if (Country >= 0)
		for (i = 0; i < S.Ticker.Length; i++)
			if (S.Ticker[i].Country == Country)
			{
				S.Ticker.Remove(i, 1);
				break;
			}
	Item.Line = Pool[Rand(Pool.Length)];
	Item.Country = Country;
	Item.State = State;
	S.TickerUsed.AddItem(Item.Line);
	S.Ticker.InsertItem(0, Item);
	if (S.Ticker.Length > MAX_SHOWN)
		S.Ticker.Length = MAX_SHOWN;
	S.TickerQuiet = QUIET_HOURS;
	return true;
}

/** A narrative headline, once a campaign (PushNarrativeHeadline): UFOShotDown, AlienCaptured, CodeBroken, BaseAssaulted,
 *  PsiSoldier, EXALTRaid. */
static function Narrative(XComGameState_LWStrategy S, string Name)
{
	if (S.TickerNarratives.Find(Name) != INDEX_NONE)
		return;
	if (Push(S, "Narrative:" $ Name, -1, GOOD))
		S.TickerNarratives.AddItem(Name);
}

/** A country's panic changed (XGCountry.AddPanic → PushPanicHeadline(panic / 20)): EW's lines for levels 1, 2 (also 3),
 *  4 and 5; none for the lowest. */
static function Panic(XComGameState_LWStrategy S, int Country)
{
	local int Level;

	Level = S.Countries[Country].Panic / 20;
	if (Level == 3)
		Level = 2;
	if (Level >= 1)
		Push(S, "Panic:" $ class'LWStrategyRules'.default.Countries[Country].Id $ ":" $ Level, Country, BAD);
}

/** A mission's result (PushMissionSpecificHeadline), by the port's kinds: 1 crash site, 2 landed UFO, 3 abduction,
 *  4 terror, 8 EXALT's covert extraction; the HQ assault (7) and the raid on EXALT's base (9) are narratives. */
static function Mission(XComGameState_LWStrategy S, int Kind, int Country, bool bWon, int GeneModded, int Mecs)
{
	local string Family;

	switch (Kind)
	{
	case 1: Family = "CrashedUFO"; break;
	case 2: Family = "LandedUFO"; break;
	case 3:
		Family = "Abduction";
		// (A won abduction with gene-modded soldiers or MECs on it: their own lines, either at random when both.)
		if (bWon && GeneModded > 0 && (Mecs == 0 || Rand(2) == 0))
			Family = "AbductionWonWithGeneMods";
		else if (bWon && Mecs > 0)
			Family = "AbductionWonWithMecs";
		break;
	case 4: Family = "Terror"; break;
	case 7:
		if (bWon)
			Narrative(S, "BaseAssaulted");
		return;
	case 8: Family = "CovertOps"; break;
	case 9:
		if (bWon)
			Narrative(S, "EXALTRaid");
		return;
	default:
		return;
	}
	if (Right(Family, 8) != "GeneMods" && Right(Family, 4) != "Mecs")
		Family $= bWon ? "Won" : "Lost";
	Push(S, Family, Country, bWon ? GOOD : BAD);
}

/** The squad's gene-modded soldiers and MECs (XGFundingCouncil counts them for the abduction lines). */
static function SquadCounts(out int GeneModded, out int Mecs)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local LWBaseRules.LWGeneMod G;
	local StateObjectReference Ref;

	GeneModded = 0;
	Mecs = 0;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ == none)
		return;
	foreach XComHQ.Squad(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none)
			continue;
		if (class'LWMECs'.static.IsMEC(Unit))
		{
			Mecs++;
			continue;
		}
		foreach class'LWBaseRules'.default.GeneMods(G)
			if (class'XComGameState_LWStrategy'.static.HasGeneMod(Unit, G.Perk))
			{
				GeneModded++;
				break;
			}
	}
}

/** An hour (XGFacility_SituationRoom.Update): after 120 without news, an ambient headline of the act, or of the first
 *  act, two times in five. */
static function Hour(XComGameState_LWStrategy S)
{
	if (default.Lines.Length == 0)
		return;
	if (S.Ticker.Length == 0)
		Fill(S);
	if (--S.TickerQuiet > 0)
		return;
	Push(S, "Ambient:" $ (Rand(5) > 2 ? 0 : class'XComGameState_LWStrategy'.static.Act()), -1, PLAIN);
	S.TickerQuiet = QUIET_HOURS;
}

/** A campaign's first headlines (InitTickerItems): five ambient ones of the first acts. */
static function Fill(XComGameState_LWStrategy S)
{
	local int i;

	for (i = 0; i < MAX_SHOWN; i++)
		Push(S, "Ambient:" $ (Rand(5) > 2 ? 0 : 1), -1, PLAIN);
}

/** The ticker's text as EW's UISituationRoom.UpdateTicker joins it: each headline in its colour, "//" between. */
static function string Text(XComGameState_LWStrategy S)
{
	local string Out, Line;
	local int i;

	for (i = 0; i < S.Ticker.Length; i++)
	{
		Line = CountryText(S, TextOf(S.Ticker[i].Line), S.Ticker[i].Country);
		if (Line == "")
			continue;
		if (Out != "")
			Out $= "//";
		Out $= S.Ticker[i].State == GOOD ? class'UIUtilities_Text'.static.GetColoredText(Line, eUIState_Good)
			: (S.Ticker[i].State == BAD ? class'UIUtilities_Text'.static.GetColoredText(Line, eUIState_Bad) : Line);
	}
	return Out;
}

/** EW's <XGCountry:…/> tags in the country's forms (as the council's texts, UILWEWCouncilRequest). */
static function string CountryText(XComGameState_LWStrategy S, string Line, int Country)
{
	local string Name;

	if (Country < 0)
		return Line;
	Name = S.CountryName(Country);
	Line = Repl(Line, "<XGCountry:Name/>", Name);
	Line = Repl(Line, "<XGCountry:CityName/>", Name);
	Line = Repl(Line, "<XGCountry:NameAdjective/>", class'UILWEWCouncilRequest'.static.Form(class'UILWEWCouncilRequest'.default.Adjective, Country, Name));
	Line = Repl(Line, "<XGCountry:NamePossessive/>", class'UILWEWCouncilRequest'.static.Form(class'UILWEWCouncilRequest'.default.Possessive, Country, Name $ "'s"));
	Line = Repl(Line, "<XGCountry:NameWithArticleLowerCase/>", class'UILWEWCouncilRequest'.static.Form(class'UILWEWCouncilRequest'.default.ArticleLower, Country, Name));
	Line = Repl(Line, "<XGCountry:NameWithArticleUpperCase/>", class'UILWEWCouncilRequest'.static.Form(class'UILWEWCouncilRequest'.default.ArticleUpper, Country, Name));
	return Line;
}
