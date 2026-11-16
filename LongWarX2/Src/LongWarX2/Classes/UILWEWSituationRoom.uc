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
var localized string StatusNoCell, StatusUnknown, StatusExposed, NotScanned, FailTitle, FailBody, FailLeftTitle, FailLeftBody, SuccessTitle, SuccessBody;

/** EXALT's view (EW's covert operations mode) rather than the satellites'. */
var bool bCovert;
/** The country an accusation is asked about (the dialog's answer). */
var int AccuseCountry;
/** The Intel Scan, an XCOM 2 button under the map in EW's words: EW's own scan panel stands where this port's
 *  right-hand country list is, and its intro never runs here. */
var UIButton SweepButtonWidget;

/** The council's countries in the order EW's Situation Room lists them (XGSituationRoomUI.SortSitCountries: North
 *  America, South America, Africa, Europe, Asia, each continent's countries as XGWorld.CreateCountries adds them). */
var array<name> Order;
/** The earth's texture, held: Flash fetches it a frame later, by its path, and found nothing once it had been collected. */
var Texture2D EarthTexture;

static function string Open(optional bool bCovertOps)
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
	HQPres.ScreenStack.Push(EWScreen);
	return "ok EW Situation Room" $ (bCovertOps ? ", EXALT" : "");
}

simulated function OnRemoved()
{
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
		Funding = Round(class'LWStrategyRules'.default.Countries[k].Funding * class'LWStrategyRules'.default.FundingBalance[d] * (S.Countries[k].bSatellite ? 1.0 : class'LWStrategyRules'.default.BaseFundingPct[d] / 100.0));
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
		bExposed = class'LWExalt'.static.IsExposed(S, k);
		if (S.Countries[k].bLeft)
			Left++;
		MC.BeginFunctionOp("SetCountryInfoInfiltrator");
		MC.QueueNumber(i);
		MC.QueueString(Caps(S.CountryName(k)));
		MC.QueueNumber(Clamp(S.Countries[k].Panic / 20, 0, 5));
		MC.QueueBoolean(!S.Countries[k].bLeft);
		MC.QueueBoolean(bExposed);
		// (EW's cell states: 0 a cell, 4 none known.)
		MC.QueueNumber(bExposed ? 0 : 4);
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
	local int k;

	S = class'XComGameState_LWStrategy'.static.Get();
	k = (Slot >= 0 && Slot < Order.Length) ? S.CountryIndex(Order[Slot]) : INDEX_NONE;
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

	if (bCovert && cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP && args.Length > 0)
	{
		Target = args[args.Length - 1];
		for (i = 0; i < args.Length; i++)
			Joined @= args[i];
		for (i = 0; i < args.Length; i++)
				if (Left(args[i], 7) == "country" && string(int(Mid(args[i], 7))) == Mid(args[i], 7))
				{
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

	if (bCovert && (arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0
		&& (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED))
	{
		i = SlotUnderMouse();
		if (i >= 0)
		{
			ChooseCountry(i);
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
