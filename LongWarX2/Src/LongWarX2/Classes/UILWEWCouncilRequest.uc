// Enemy Within's council request screen (features/lw-council-requests.md; EW's UIFundingCouncilRequest on its
// FundingCouncilRequests movie, filled as XGPendingRequestsUI.UpdateRequest fills it) for a Long War council request the
// player can answer (LWCouncilRequests): REQUEST FROM <country>, the items asked for, how many are in storage (red while
// too few), the days left, the country's own words (XGFundingCouncil's request intro, its <XGCountry:…/> tags in EW's forms
// of the country's name), the rewards; DISPATCH ITEMS (only with enough in storage) gives them, NOT NOW leaves the request:
// one that is pending (met as it came) is then ignored, as the Geoscape's refusal does. Opened from Mission Control's list
// (EW: from its Situation Room). The item's picture is Long War's (LWX2Pictures).
class UILWEWCouncilRequest extends UILWEWScreen;

var localized string TitleLabel, Requested, ValueRequested, InStorage, TimeLimit, TimeLimitDays, RewardsLabel, SellItems,
	NotNow, NumPanic, NumEngineers, NumScientists, NewRecruit;
/** XGFundingCouncil.m_strRequestIntro, by Long War's EFCRequest. */
var localized string Intro[42];
/** The council countries' names in EW's forms (CountryNamesWithArticle, …Lower, CountryAdjective, CountryPossessive), by the
 *  mod's country order (LWStrategyRules.Countries). */
var localized array<string> ArticleUpper, ArticleLower, Adjective, Possessive;

/** The request (XComGameState_LWStrategy.Requests) and the screen it was opened over. */
var int Index;
var UILWGeoscape Geo;

static function bool Open(UILWGeoscape Geoscape, int RequestIndex)
{
	local XComHQPresentationLayer HQPres;
	local UILWEWCouncilRequest EWScreen;

	HQPres = XComHQPresentationLayer(Geoscape.Movie.Pres);
	if (HQPres == none || !HasEWScreens() || HQPres.ScreenStack.GetFirstInstanceOf(class'UILWEWCouncilRequest') != none)
		return false;
	DynamicLoadObject(default.UIPackage $ ".ewxFundingCouncilRequests", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWCouncilRequest', HQPres);
	EWScreen.Package = name("/ package/ewxFundingCouncilRequests/FundingCouncilRequests");
	EWScreen.MCName = 'theScreen';
	EWScreen.Index = RequestIndex;
	EWScreen.Geo = Geoscape;
	HQPres.ScreenStack.Push(EWScreen);
	return true;
}

simulated function OnInit()
{
	super.OnInit();
	SetTimer(0.1, false, nameof(Fill));
}

/** UIFundingCouncilRequest.ShowRequest. */
function Fill()
{
	local XComGameState_LWStrategy S;
	local XComGameState_LWStrategy.LWRequest R;
	local X2ItemTemplate T;
	local LWCouncilRequests.LWRequestDef D;
	local array<ASValue> Params;
	local string Items, Stored;
	local int Held;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || Index < 0 || Index >= S.Requests.Length)
	{
		CloseScreen();
		return;
	}
	R = S.Requests[Index];
	T = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(R.Item);
	Items = T == none ? string(R.Item) : (R.Amount == 1 ? T.GetItemFriendlyName() : T.GetItemFriendlyNamePlural());
	Held = class'LWCouncilRequests'.static.Held(R);
	Stored = T == none ? string(R.Item) : (Held == 1 ? T.GetItemFriendlyName() : T.GetItemFriendlyNamePlural());
	Params.AddItem(Str(Caps(Repl(TitleLabel, "<XGParam:StrValue0/>", S.CountryName(R.Country)))));
	Params.AddItem(Str(Caps(Items)));
	Params.AddItem(Str(Caps(Requested)));
	Params.AddItem(Str(Coloured(Repl(Repl(ValueRequested, "<XGParam:IntValue0/>", string(R.Amount)), "<XGParam:StrValue0/>", Items), "FFD038")));
	Params.AddItem(Str(Caps(InStorage)));
	Params.AddItem(Str(Coloured(Repl(Repl(ValueRequested, "<XGParam:IntValue0/>", string(Held)), "<XGParam:StrValue0/>", Stored), Held >= R.Amount ? "FFD038" : "EE1C25")));
	Params.AddItem(Str(Caps(TimeLimit)));
	Params.AddItem(Str(Coloured(Repl(TimeLimitDays, "<XGParam:IntValue0/>", string(R.bPending ? 0 : R.HoursLeft / 24)), "FFD038")));
	Params.AddItem(Str(Coloured(CountryText(S, (R.Id >= 0 && R.Id < 42) ? Intro[R.Id] : "", R.Country), "67E8ED")));
	Params.AddItem(Str(Coloured(Caps(RewardsLabel), "5CD16C") @ Coloured(RewardsText(R), "5CD16C")));
	Params.AddItem(Str(class'LWCouncilRequests'.static.DefOf(R.Id, D) ? class'LWX2Pictures'.static.Item(D.Item, "") : ""));
	Params.AddItem(Num(1.0));
	Params.AddItem(Str(""));
	Movie.Invoke(MCPath $ ".OpenSalesRequest", Params);
	ButtonData(0, Caps(SellItems), R.Transfer != 0 || Held < R.Amount);
	ButtonData(1, Caps(NotNow), false);
}

function ButtonData(int i, string Text, bool bDisabled)
{
	local array<ASValue> Params;
	local ASValue V;

	Params.AddItem(Num(i));
	Params.AddItem(Str(Text));
	V.Type = AS_Boolean;
	V.b = bDisabled;
	Params.AddItem(V);
	Movie.Invoke(MCPath $ ".SetButtonData", Params);
}

static function string Coloured(string Text, string Colour)
{
	return "<font color='#" $ Colour $ "'>" $ Text $ "</font>";
}

/** EW's <XGCountry:…/> tags (XGCountryTag) in a council text, in the country's forms. */
function string CountryText(XComGameState_LWStrategy S, string Text, int Country)
{
	local string Name;

	Name = S.CountryName(Country);
	Text = Repl(Text, "<XGCountry:Name/>", Name);
	Text = Repl(Text, "<XGCountry:CityName/>", Name);
	Text = Repl(Text, "<XGCountry:NameAdjective/>", Form(Adjective, Country, Name));
	Text = Repl(Text, "<XGCountry:NamePossessive/>", Form(Possessive, Country, Name $ "'s"));
	Text = Repl(Text, "<XGCountry:NameWithArticleLowerCase/>", Form(ArticleLower, Country, Name));
	Text = Repl(Text, "<XGCountry:NameWithArticleUpperCase/>", Form(ArticleUpper, Country, Name));
	return Text;
}

static function string Form(array<string> Forms, int Country, string Fallback)
{
	return (Country >= 0 && Country < Forms.Length && Forms[Country] != "") ? Forms[Country] : Fallback;
}

/** The rewards (XGPendingRequestsUI.RewardToString): cash, scientists, engineers, a recruit, panic reduction; any other
 *  in the port's words. */
function string RewardsText(XComGameState_LWStrategy.LWRequest R)
{
	local XComGameState_LWStrategy.LWCouncilReward W;
	local string Text, One;

	foreach R.Rewards(W)
	{
		switch (W.Type)
		{
		case 1: One = class'LWStrategyRules'.static.Money(W.Amount); break;
		case 4: One = Repl(NumScientists, "<XGParam:IntValue0/>", string(W.Amount)); break;
		case 5: One = Repl(NumEngineers, "<XGParam:IntValue0/>", string(W.Amount)); break;
		case 6: One = NumPanic; break;
		// (A recruit: EW names its class and rank; Long War's reward picks the class when the soldier comes.)
		case 2:
		case 3:
		case 9: One = Repl(Repl(NewRecruit, "<XGParam:StrValue0/>", ""), ":", ""); break;
		default: One = class'LWCouncil'.static.RewardsText(OneReward(W));
		}
		Text $= (Text != "" ? ", " : "") $ One;
	}
	return Text;
}

static function array<XComGameState_LWStrategy.LWCouncilReward> OneReward(XComGameState_LWStrategy.LWCouncilReward W)
{
	local array<XComGameState_LWStrategy.LWCouncilReward> One;

	One.AddItem(W);
	return One;
}

/** DISPATCH ITEMS (OnAccept: refused while too few are in storage) or NOT NOW. */
function Answer(bool bGive)
{
	local XComGameState_LWStrategy S;
	local UILWGeoscape G;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (bGive && !class'LWCouncilRequests'.static.Answer(Index, true))
		return;
	if (!bGive && S != none && Index < S.Requests.Length && S.Requests[Index].bPending)
		class'LWCouncilRequests'.static.Answer(Index, false);
	G = Geo;
	CloseScreen();
	if (G != none)
		G.Refresh();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		// (EW's script names the PC buttons mouseBtn1 and 2; this movie raises its buttons' own names.)
		if (Target == "mouseBtn1" || Target == "button_0")
		{
			Answer(true);
			return;
		}
		if (Target == "mouseBtn2" || Target == "button_1")
		{
			Answer(false);
			return;
		}
	}
	super.OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true;
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
			Answer(true);
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			Answer(false);
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}
