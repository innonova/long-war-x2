// Enemy Within's Situation Room (its SituationRoom movie, features/lw-ew-screens.md) as the port's view of the world: the
// council's countries with Long War's panic, funding and satellites, and the map with XCOM's headquarters, the
// satellites and the UFOs seen, filled as EW's UISituationRoom fills it (SetCountryInfo for each council country in
// EW's order, ClearMap, AddMapItem, SetDoomLevel). Escape closes it.
// With bCovert, EXALT's view (features/lw-exalt.md), EW's covert operations mode as Long War's InfiltratorState fills it:
// each country's cell (exposed or not known), the countries the clues held rule out, the cells on the map, the Intel Scan
// (SetIntel; its button scans after EW's confirmation); a country chosen, the accusation where Long War allows it.
class UILWEWSituationRoom extends UILWEWScreen dependson(LWStrategyRules);

/** EW's words (UISituationRoom, XGInfiltratorSitRoomUI), written from the player's install (lw-words.mjs, makeExaltWords). */
var localized string SweepButton, SweepDesc, SweepDisabled, SweepCantAfford, SweepFailed, RuledOut, AccuseLabel, RaidLabel;
var localized string SweepTitle, SweepBody, SweepConfirm, SweepDecline, CluesTitle, CluesNone, CluesFew, CluesEnough;
var localized string LaunchLabel, StatusNoCell, StatusUnknown, StatusExposed, NotScanned, FailTitle, FailBody, FailLeftTitle, FailLeftBody, SuccessTitle, SuccessBody;
/** The satellites' view's words (XGSatelliteSitRoomUI, UISituationRoom's uplinks). */
var localized string SatAvailable, SatInOrbit, SatLaunch, SatHas, SatNone, SatNoCapacity, SatLeft, SatPerMonth, SatStaff, SatScientist, SatScientists;
var localized string SatEngineer, SatEngineers, SatConfirmTitle, SatCountry, SatFunding, SatMonitoring, SatReward, SatLaunchLower, SatCancelLower;

/** The satellites' view (EW's SatelliteState): a country chosen, the HUD's panels, a satellite launched there. */
var bool bSatellite;
var int SatSlot;
var UILWEWSituationRoomHUD SatHUD;

/** EXALT's view (EW's covert operations mode) rather than the satellites'. */
var bool bCovert;
/** The country an accusation is asked about (the dialog's answer); the one a covert operative is chosen for. */
var int AccuseCountry, OperativeCountry;
var StateObjectReference OperativeChosen;
/** The Intel Scan, an XCOM 2 button under the map in EW's words: EW's own scan panel stands where this port's
 *  right-hand country list is, and its intro never runs here. */
var UIButton SweepButtonWidget;

/** The council's countries in the order EW's Situation Room lists them (XGSituationRoomUI.SortSitCountries: North
 *  America, South America, Africa, Europe, Asia, each continent's countries as XGWorld.CreateCountries adds them). */
var array<name> Order;
/** The earth's texture, held: Flash fetches it a frame later, by its path, and found nothing once it had been collected. */
var Texture2D EarthTexture;

static function string Open(optional bool bCovertOps, optional bool bSatellites)
{
	local XComHQPresentationLayer HQPres;
	local UILWEWSituationRoom EWScreen;

	HQPres = `HQPRES;
	if (HQPres == none)
		return "ERR not on the Avenger";
	DynamicLoadObject(default.UIPackage $ ".ewxSituationRoom", class'Object', true);
	// A black background under it (EW's earth goes into its map area: OnInit).
	class'UILWEWMapBackdrop'.static.ShowIfAvailable();
	EWScreen = HQPres.Spawn(class'UILWEWSituationRoom', HQPres);
	EWScreen.Package = name("/ package/ewxSituationRoom/SituationRoom");
	EWScreen.MCName = 'theScreen';
	EWScreen.bCovert = bCovertOps;
	EWScreen.bSatellite = bSatellites && !bCovertOps;
	HQPres.ScreenStack.Push(EWScreen);
	return "ok EW Situation Room" $ (bCovertOps ? ", EXALT" : "");
}

simulated function OnRemoved()
{
	if (SatHUD != none)
		SatHUD.CloseScreen();
	SatHUD = none;
	class'UILWEWMapBackdrop'.static.HideAll();
	super.OnRemoved();
}

simulated function OnInit()
{
	super.OnInit();
	AddEarth();
	MC.FunctionVoid("HideTicker");
	MC.FunctionVoid("HideUplinks");
	if (bCovert)
	{
		MC.FunctionNum("SetDisplayMode", 1);
		// EW's scan panel hidden (see SweepButtonWidget).
		Movie.SetVariableBool(MCPath $ ".intel._visible", false);
		Movie.SetVariableBool(MCPath $ ".desc_txt._visible", false);
		SweepButtonWidget = Spawn(class'UIButton', self);
		SweepButtonWidget.InitButton('LWExaltSweep', "", OnSweepClicked);
		SweepButtonWidget.SetPosition(560, 380);
	}
	if (bSatellite)
	{
		// (DISPLAY_MODE_SATELLITE: EW's satellites' view, its uplinks shown; the HUD over it.)
		MC.FunctionNum("SetDisplayMode", 0);
		MC.FunctionVoid("ShowUplinks");
		SatSlot = FirstSlotWithout();
		// (The HUD over it takes the focus: the room stays drawn under it.)
		bHideOnLoseFocus = false;
		SatHUD = class'UILWEWSituationRoomHUD'.static.Open(XComHQPresentationLayer(Movie.Pres), self);
	}
	Refresh();
	SetTimer(1.0, true, nameof(Refresh));
}

/**
 * EW's earth (FX_Globe.T_Earth_Holo, made teal on the player's machine: tools/convert/ew-earth.ts) inside the movie's map
 * area, where EW's 3D globe showed through: over the area's panel, under the markers (a negative depth: the markers are
 * attached at depths from 0), the size the movie maps 0..1 onto (its MAP_WIDTH and MAP_HEIGHT). The area's height scaled
 * to the frame's (MAP_FINAL_HEIGHT): unscaled, the map ran past its frame, over the UFO slots and the ticker, and was
 * squeezed sideways; its width already is the frame's (measured on the screen).
 */
function AddEarth()
{
	local UIPanel Area;
	local UIImage Earth;
	local float W, H, X, Y, FH;

	EarthTexture = Texture2D(DynamicLoadObject("FX_Globe.T_Earth_Holo", class'Texture2D', true));
	if (EarthTexture == none)
		return;
	W = MC.GetNum("MAP_WIDTH");
	H = MC.GetNum("MAP_HEIGHT");
	// The area's place in the movie, put back once it is bound (a bound panel takes its own position).
	X = MC.GetNum("theMapArea._x");
	Y = MC.GetNum("theMapArea._y");
	FH = MC.GetNum("MAP_FINAL_HEIGHT");
	Area = Spawn(class'UIPanel', self).InitPanel('theMapArea');
	Area.SetPosition(X, Y);
	// The UFO slots (the doom trackers, along the map's top edge) over it, as over EW's globe.
	MC.ChildFunctionNum("theDoomTracker", "swapDepths", 16000);
	MC.ChildFunctionNum("doomTracker2", "swapDepths", 16001);
	if (H > 0 && FH > 0)
		Area.MC.SetNum("_yscale", 100.0 * FH / H);
	Earth = Spawn(class'UIImage', Area).InitImage('LWEWEarth', "img:///FX_Globe.T_Earth_Holo");
	Earth.SetPosition(0, 0);
	Earth.SetSize(W > 0 ? W : 750.0, H > 0 ? H : 498.0);
	Earth.MC.FunctionNum("swapDepths", -16000);
	`log("LongWarX2: EW screen: the earth in the Situation Room's map area," @ W @ "x" @ H, , 'LongWarX2');
}

function Refresh()
{
	local XComGameState_LWStrategy S;
	local int i, k, d, Funding, Left;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return;
	if (bCovert)
	{
		RefreshCovert(S);
		return;
	}
	d = class'LWStrategyRules'.static.Difficulty();
	for (i = 0; i < Order.Length; i++)
	{
		k = S.CountryIndex(Order[i]);
		if (k < 0)
			continue;
		Funding = S.CountryFunding(k, S.Countries[k].bSatellite);
		if (S.Countries[k].bLeft)
			Left++;
		MC.BeginFunctionOp("SetCountryInfo");
		MC.QueueNumber(i);
		MC.QueueString(Caps(S.CountryName(k)));
		MC.QueueString((S.Countries[k].bSatellite ? "+" : "") $ class'LWStrategyRules'.static.Money(Funding));
		// The movie's panic level, 0 to 5: its bars have six frames and its colours (Colors.wrapInPanicLevelHtml) know
		// only these; any other value leaves the name and the funding without a colour, and so unseen. Long War's panic is
		// 0 to 100: a level each 20.
		MC.QueueNumber(Clamp(S.Countries[k].Panic / 20, 0, 5));
		MC.QueueBoolean(!S.Countries[k].bLeft);
		MC.EndOp();
		// Long War's movie draws the panic bars from the same number, over about a hundred frames (its panic, 0 to 100,
		// plus one); the level above gives only their first frames. The bar set to Long War's panic itself.
		if (!S.Countries[k].bLeft)
			SetPanicBar(i, S.Countries[k].Panic + 1);
	}
	RealizeMap(S);
	MC.FunctionNum("SetDoomLevel", Left);
	if (bSatellite)
	{
		MC.BeginFunctionOp("SetSatellites");
		MC.QueueNumber(S.SatellitesReady);
		MC.QueueString(Word(SatAvailable, "Available"));
		MC.QueueNumber(class'LWBase'.static.SatellitesUp(S));
		MC.QueueNumber(class'LWBase'.static.SatelliteLimit(S));
		MC.QueueString(Word(SatInOrbit, "In Orbit"));
		MC.EndOp();
		MC.FunctionNum("SetSelected", SatSlot);
		UpdateSatelliteHUD();
	}
}

/** The first council country without a satellite (EW's SatelliteState starts on its manager's country). */
function int FirstSlotWithout()
{
	local XComGameState_LWStrategy S;
	local int i, k;

	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = 0; i < Order.Length; i++)
	{
		k = S.CountryIndex(Order[i]);
		if (k >= 0 && !S.Countries[k].bSatellite && !S.Countries[k].bLeft)
			return i;
	}
	return 0;
}

/** What launching over the chosen country would say (XGSatelliteSitRoomUI.UpdateCountryHelp): "" if it can be done. */
function string WhyNoLaunch(XComGameState_LWStrategy S, int k)
{
	if (S.Countries[k].bLeft)
		return Word(SatLeft, "Withdrawn from XCOM Project");
	if (S.Countries[k].bSatellite)
		return Word(SatHas, "HAS SATELLITE");
	if (S.TileType.Length > 0 && class'LWBase'.static.SatellitesUp(S) >= class'LWBase'.static.SatelliteLimit(S))
		return Word(SatNoCapacity, "Build More Uplinks.");
	if (S.SatellitesReady <= 0)
		return Word(SatNone, "NO SATELLITES AVAILABLE");
	return "";
}

/** A country's funding, with a satellite or without (EndMonth's). */
static function int FundingOf(int k, bool bSat)
{
	local int d;

	d = class'LWStrategyRules'.static.Difficulty();
	return (d >= 0 && class'XComGameState_LWStrategy'.static.Get() != none) ? class'XComGameState_LWStrategy'.static.Get().CountryFunding(k, bSat) : 0;
}

/** The staff a country under a satellite gives, as EW words it ("+1 Scientist"; BuildBonusString). */
function string StaffText(int k)
{
	local string T;
	local int Sci, Eng;

	Sci = class'LWStrategyRules'.default.Countries[k].Scientists;
	Eng = class'LWStrategyRules'.default.Countries[k].Engineers;
	if (Sci > 0)
		T = "+" $ Sci @ (Sci == 1 ? Word(SatScientist, "Scientist") : Word(SatScientists, "Scientists"));
	if (Eng > 0)
		T $= (T != "" ? ", " : "") $ "+" $ Eng @ (Eng == 1 ? Word(SatEngineer, "Engineer") : Word(SatEngineers, "Engineers"));
	return T;
}

/**
 * The HUD's panels for the chosen country (XGSatelliteSitRoomUI.UpdateContinent, UpdateCountry, UpdateCountryHelp): the
 * continent's name; the country's staff ("Staff:"), its own bonus (not the home country's; the home country's starting
 * bonus instead) and the continent's, each lit when it holds or would with this satellite; the country's name, its funding
 * a month (with a satellite), panic and satellite; the launch button, or why not.
 */
function UpdateSatelliteHUD()
{
	local XComGameState_LWStrategy S;
	local LWBonuses.LWBonusDef B;
	local string Body, Why;
	local int k, i, c;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (SatHUD == none || S == none || SatSlot < 0 || SatSlot >= Order.Length)
		return;
	k = S.CountryIndex(Order[SatSlot]);
	if (k < 0)
		return;
	c = S.CountryContinent(k);
	Body = class'UIUtilities_Text'.static.GetColoredText(Word(SatStaff, "Staff: ") $ StaffText(k), S.Countries[k].bSatellite ? eUIState_Warning : eUIState_Disabled) $ "\n";
	for (i = 0; i < class'LWBonuses'.default.Bonuses.Length; i++)
	{
		B = class'LWBonuses'.default.Bonuses[i];
		if ((B.Kind == 1 && B.Country == S.Countries[k].Id && k != S.HomeCountry())
			|| (B.Kind == 0 && k == S.HomeCountry() && B.Country == S.Countries[k].Id && B.Choice == S.StartChoice)
			|| (B.Kind == 2 && B.Continent == c))
			Body $= class'UIUtilities_Text'.static.GetColoredText(class'LWBonuses'.static.Text(i),
				(B.Kind == 2 ? class'LWBonuses'.static.ContinentCovered(S, c) : (S.Countries[k].bSatellite || B.Kind == 0)) ? eUIState_Warning : eUIState_Disabled) $ "\n";
	}
	SatHUD.SetContinentInfo(Caps(class'LWStrategyRules'.static.ContinentName(c)), Body);
	Why = WhyNoLaunch(S, k);
	SatHUD.SetCountryInfo(Caps(S.CountryName(k)), class'LWStrategyRules'.static.Money(FundingOf(k, true)) @ Word(SatPerMonth, "per month") $ (Why != "" ? "\n" $ Why : ""),
		Clamp(S.Countries[k].Panic / 20 + 1, 1, 5));
	SatHUD.SetSatStatus(S.Countries[k].bSatellite);
	SatHUD.SetLaunchButton(Why == "" ? Word(SatLaunch, "LAUNCH SATELLITE") : "", Why == "");
}

/** The launch asked (the HUD's button, Enter): EW's confirmation (ConfirmSatelliteDialogue): the country, the funding it
 *  adds, the coverage of its continent it brings, the staff it sends. */
function AskLaunch()
{
	local XComGameState_LWStrategy S;
	local TDialogueBoxData Data;
	local XGParamTag Tag;
	local int k, i, Covered, Council;

	S = class'XComGameState_LWStrategy'.static.Get();
	k = (SatSlot >= 0 && SatSlot < Order.Length) ? S.CountryIndex(Order[SatSlot]) : INDEX_NONE;
	if (k < 0 || WhyNoLaunch(S, k) != "")
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	for (i = 0; i < S.Countries.Length; i++)
	{
		if (S.CountryContinent(i) != S.CountryContinent(k) || S.Countries[i].bLeft)
			continue;
		Council++;
		if (S.Countries[i].bSatellite || i == k)
			Covered++;
	}
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.IntValue0 = Covered;
	Tag.IntValue1 = Council;
	Tag.StrValue0 = class'LWStrategyRules'.static.ContinentName(S.CountryContinent(k));
	Data.eType = eDialog_Normal;
	Data.strTitle = Word(SatConfirmTitle, "Confirm Satellite Launch");
	Data.strText = Word(SatCountry, "COUNTRY") $ ":" @ S.CountryName(k)
		$ "\n" $ Word(SatFunding, "MONTHLY FUNDING INCREASE") $ ":" @ class'UIUtilities_Text'.static.GetColoredText("+" $ class'LWStrategyRules'.static.Money(FundingOf(k, true) - FundingOf(k, false)), eUIState_Cash)
		$ "\n" $ class'XComLocalizer'.static.ExpandString(Word(SatMonitoring, "If launched, we will have satellite coverage over <XGParam:IntValue0/>/<XGParam:IntValue1/> countries in <XGParam:StrValue0/>"))
		$ (StaffText(k) != "" ? "\n" $ Word(SatReward, "Reward:") @ StaffText(k) : "");
	Data.strAccept = Word(SatLaunchLower, "Launch Satellite");
	Data.strCancel = Word(SatCancelLower, "Cancel");
	Data.fnCallback = OnLaunchConfirm;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnLaunchConfirm(Name Action)
{
	local XComGameState_LWStrategy S;

	if (Action != 'eUIAction_Accept')
		return;
	S = class'XComGameState_LWStrategy'.static.Get();
	if (class'XComGameState_LWStrategy'.static.LaunchSatellite(S.CountryIndex(Order[SatSlot])))
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	Refresh();
}

/** EXALT's view: each country's cell state, the clues' verdicts, the cells on the map, the Intel Scan. */
function RefreshCovert(XComGameState_LWStrategy S)
{
	local LWStrategyRules.LWMapPlace P;
	local XGParamTag Tag;
	local string Why;
	local int i, k, Left;
	local bool bExposed;

	for (i = 0; i < Order.Length; i++)
	{
		k = S.CountryIndex(Order[i]);
		if (k < 0)
			continue;
		bExposed = class'LWExalt'.static.IsExposed(S, k) || (S.ExaltOperative > 0 && S.ExaltOperativeCountry == k);
		if (S.Countries[k].bLeft)
			Left++;
		MC.BeginFunctionOp("SetCountryInfoInfiltrator");
		MC.QueueNumber(i);
		MC.QueueString(Caps(S.CountryName(k)));
		MC.QueueNumber(Clamp(S.Countries[k].Panic / 20, 0, 5));
		MC.QueueBoolean(!S.Countries[k].bLeft);
		MC.QueueBoolean(bExposed);
		// (EW's cell states: 0 a cell, 1 our operative in it, 2 ready for extraction, 4 none known.)
		MC.QueueNumber((S.ExaltOperative > 0 && S.ExaltOperativeCountry == k) ? (S.ExaltMissionUntil > 0 ? 2 : 1) : (bExposed ? 0 : 4));
		MC.QueueBoolean(class'LWExalt'.static.RuledOutByHeldClues(S, k) || S.ExaltAccused.Find(k) != INDEX_NONE);
		MC.QueueBoolean(k == S.ExaltCountry && S.ExaltAccused.Find(k) != INDEX_NONE);
		MC.EndOp();
	}
	MC.FunctionVoid("ClearMap");
	foreach class'LWStrategyRules'.default.MapPlaces(P)
	{
		k = S.CountryIndex(P.Country);
		if (k < 0)
			continue;
		if (k == S.HomeCountry())
			AddMapItem("_hq", P.X, P.Y);
		if (class'LWExalt'.static.IsExposed(S, k))
			AddMapItem("_cell", P.X, P.Y);
	}
	MC.FunctionNum("SetDoomLevel", Left);
	if (SweepButtonWidget == none)
		return;
	if (class'LWExalt'.static.CanSweep(S, Why))
	{
		Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		Tag.StrValue0 = class'LWStrategyRules'.static.Money(class'LWExalt'.static.SweepCost(S));
		SweepButtonWidget.SetText(Caps(Word(SweepButton, "Intel Scan")) @ "-" @ (SweepDesc != "" ? `XEXPAND.ExpandString(SweepDesc) : Tag.StrValue0));
		SweepButtonWidget.SetDisabled(false);
	}
	else
	{
		SweepButtonWidget.SetText(S.ExaltState != class'LWExalt'.const.ACTIVE ? Word(NotScanned, "")
			: (InStr(Why, "§") != INDEX_NONE ? Word(SweepCantAfford, "Insufficient cash to sweep") : Word(SweepDisabled, "Global intel up to date")));
		SweepButtonWidget.SetDisabled(true);
	}
}

function OnSweepClicked(UIButton Button)
{
	AskSweep();
}

static function string Word(string Localized, string Fallback)
{
	return Localized != "" ? Localized : Fallback;
}

/** EW's confirmation of an Intel Scan (its cost), then the scan. */
function AskSweep()
{
	local TDialogueBoxData Data;
	local XGParamTag Tag;
	local string Why;

	if (!class'LWExalt'.static.CanSweep(class'XComGameState_LWStrategy'.static.Get(), Why))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.StrValue0 = class'LWStrategyRules'.static.Money(class'LWExalt'.static.SweepCost(class'XComGameState_LWStrategy'.static.Get()));
	Data.eType = eDialog_Normal;
	Data.strTitle = Word(SweepTitle, "CONFIRM INTEL SCAN");
	Data.strText = SweepBody != "" ? `XEXPAND.ExpandString(SweepBody) : "An intel scan costs" @ Tag.StrValue0 $ ".";
	Data.strAccept = Word(SweepConfirm, class'UIUtilities_Text'.default.m_strGenericYes);
	Data.strCancel = Word(SweepDecline, class'UIUtilities_Text'.default.m_strGenericNo);
	Data.fnCallback = OnSweepConfirm;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnSweepConfirm(Name Action)
{
	local string Why;

	if (Action != 'eUIAction_Accept')
		return;
	if (!class'LWExalt'.static.Sweep(Why))
		`log("LongWarX2: EXALT: no scan:" @ Why, , 'LongWarX2');
	if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
	Refresh();
}

/** A country chosen in EXALT's view: the accusation where Long War allows it (three clues held, not ruled out, not
 *  accused before), after a confirmation. */
function ChooseCountry(int Slot)
{
	local XComGameState_LWStrategy S;
	local TDialogueBoxData Data;
	local UIPersonnel_LWCovert Personnel;
	local int k;

	S = class'XComGameState_LWStrategy'.static.Get();
	k = (Slot >= 0 && Slot < Order.Length) ? S.CountryIndex(Order[Slot]) : INDEX_NONE;
	// An exposed cell and nobody in the field: a covert operative chosen for it (Long War's COVERT OPERATION).
	if (k >= 0 && class'LWExalt'.static.IsExposed(S, k) && S.ExaltOperative <= 0)
	{
		OperativeCountry = k;
		Personnel = Spawn(class'UIPersonnel_LWCovert', Movie.Pres);
		Personnel.onSelectedDelegate = OnOperativeChosen;
		Movie.Pres.ScreenStack.Push(Personnel);
		return;
	}
	if (k < 0 || !class'LWExalt'.static.CanAccuse(S, k))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	AccuseCountry = k;
	Data.eType = eDialog_Warning;
	Data.strTitle = Word(AccuseLabel, "ATTEMPT RAID ON EXALT HQ");
	Data.strText = Caps(S.CountryName(k));
	Data.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	Data.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	Data.fnCallback = OnAccuseConfirm;
	Movie.Pres.UIRaiseDialog(Data);
}

/** A country chosen in the satellites' view: selected, the HUD's panels for it. */
function ChooseSatCountry(int Slot)
{
	if (Slot < 0 || Slot >= Order.Length)
		return;
	SatSlot = Slot;
	MC.FunctionNum("SetSelected", SatSlot);
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	UpdateSatelliteHUD();
}

/** A soldier chosen for the covert operation: EW's words for it, then sent (LWExalt.SendOperative). */
function OnOperativeChosen(StateObjectReference UnitRef)
{
	local TDialogueBoxData Data;

	OperativeChosen = UnitRef;
	Data.eType = eDialog_Normal;
	Data.strTitle = Word(LaunchLabel, "COVERT OPERATION");
	Data.strText = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID)).GetName(eNameType_FullNick) @ "-"
		@ Caps(class'XComGameState_LWStrategy'.static.Get().CountryName(OperativeCountry));
	Data.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	Data.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	Data.fnCallback = OnOperativeConfirm;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnOperativeConfirm(Name Action)
{
	local string Why;

	if (Action == 'eUIAction_Accept' && !class'LWExalt'.static.SendOperative(OperativeChosen.ObjectID, OperativeCountry, Why))
		`log("LongWarX2: EXALT: no operative sent:" @ Why, , 'LongWarX2');
	Refresh();
}

simulated function OnAccuseConfirm(Name Action)
{
	if (Action == 'eUIAction_Accept')
		class'LWExalt'.static.Accuse(AccuseCountry);
	Refresh();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target, Joined;
	local int i;

	if ((bCovert || bSatellite) && cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP && args.Length > 0)
	{
		Target = args[args.Length - 1];
		for (i = 0; i < args.Length; i++)
			Joined @= args[i];
		for (i = 0; i < args.Length; i++)
				if (Left(args[i], 7) == "country" && string(int(Mid(args[i], 7))) == Mid(args[i], 7))
				{
					if (bSatellite)
						ChooseSatCountry(int(Mid(args[i], 7)));
					else
						ChooseCountry(int(Mid(args[i], 7)));
					break;
				}
	}
	super.OnMouseEvent(cmd, args);
}

/** The country row under the mouse (its clip country<i>: EW's rows report no clicks here), or -1: of the rows whose box
 *  holds the pointer (a row's box reaches over the next: its highlight), the one whose top is nearest above it. */
function int SlotUnderMouse()
{
	local float MouseX, MouseY, W, H, BestY;
	local string Path;
	local int i, Best;

	Best = -1;
	for (i = 0; i < Order.Length; i++)
	{
		Path = MCPath $ ".country" $ i;
		W = Movie.GetVariableNumber(Path $ "._width");
		H = Movie.GetVariableNumber(Path $ "._height");
		MouseX = Movie.GetVariableNumber(Path $ "._xmouse");
		MouseY = Movie.GetVariableNumber(Path $ "._ymouse");
		if (W > 0 && MouseX >= 0 && MouseY >= 0 && MouseX <= W && MouseY <= H && (Best < 0 || MouseY < BestY))
		{
			Best = i;
			BestY = MouseY;
		}
	}
	return Best;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int i;

	if ((bCovert || bSatellite) && (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0
		&& (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED))
	{
		i = SlotUnderMouse();
		if (i >= 0)
		{
			if (bSatellite)
				ChooseSatCountry(i);
			else
				ChooseCountry(i);
			return true;
		}
	}
	// The satellites' view: the arrows choose a country, Enter launches (EW's SatelliteState).
	if (bSatellite && (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			ChooseSatCountry((SatSlot + Order.Length - 1) % Order.Length);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			ChooseSatCountry((SatSlot + 1) % Order.Length);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			AskLaunch();
			return true;
		}
	}
	return super.OnUnrealCommand(cmd, arg);
}

/** EW's map: the headquarters, the satellites (at their countries' places) and the UFOs seen (over their countries). */
function RealizeMap(XComGameState_LWStrategy S)
{
	local LWStrategyRules.LWMapPlace P;
	local int i, k;

	MC.FunctionVoid("ClearMap");
	foreach class'LWStrategyRules'.default.MapPlaces(P)
	{
		k = S.CountryIndex(P.Country);
		if (k < 0)
			continue;
		if (k == S.HomeCountry())
			AddMapItem("_hq", P.X, P.Y);
		if (S.Countries[k].bSatellite)
			AddMapItem("_satellite", P.X + 0.01, P.Y - 0.01);
	}
	for (i = 0; i < S.Ufos.Length; i++)
	{
		if (!S.Ufos[i].bDetected)
			continue;
		foreach class'LWStrategyRules'.default.MapPlaces(P)
			if (S.CountryIndex(P.Country) == S.Ufos[i].Country)
				AddMapItem("_ufo", P.X - 0.015, P.Y + 0.015);
	}
}

/** A country slot's panic bar (the movie's country<i>.panicLevels clip) at a frame, queued after SetCountryInfo (which
 *  sets the bar too): MC's calls are run in order at the end of the frame, Movie.Invoke at once. */
function SetPanicBar(int Slot, int Frame)
{
	MC.ChildFunctionNum("country" $ Slot $ ".panicLevels", "gotoAndStop", Frame);
}

function AddMapItem(string Label, float MapX, float MapY)
{
	MC.BeginFunctionOp("AddMapItem");
	MC.QueueString(Label);
	MC.QueueNumber(MapX);
	MC.QueueNumber(MapY);
	MC.EndOp();
}

defaultproperties
{
	Order(0) = USA
	Order(1) = Canada
	Order(2) = Mexico
	Order(3) = Argentina
	Order(4) = Brazil
	Order(5) = Egypt
	Order(6) = SouthAfrica
	Order(7) = Nigeria
	Order(8) = UK
	Order(9) = Russia
	Order(10) = France
	Order(11) = Germany
	Order(12) = China
	Order(13) = Japan
	Order(14) = India
	Order(15) = Australia
}
