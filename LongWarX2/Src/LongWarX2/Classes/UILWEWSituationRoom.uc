// Enemy Within's Situation Room (its SituationRoom movie, features/lw-ew-screens.md) as the port's view of the world: the
// council's countries with Long War's panic, funding and satellites, and the map with XCOM's headquarters, the
// satellites and the UFOs seen, filled as EW's UISituationRoom fills it (SetCountryInfo for each council country in
// EW's order, ClearMap, AddMapItem, SetDoomLevel). Escape closes it.
class UILWEWSituationRoom extends UILWEWScreen dependson(LWStrategyRules);

/** The council's countries in the order EW's Situation Room lists them (XGSituationRoomUI.SortSitCountries: North
 *  America, South America, Africa, Europe, Asia, each continent's countries as XGWorld.CreateCountries adds them). */
var array<name> Order;

static function string Open()
{
	local XComHQPresentationLayer HQPres;
	local UILWEWSituationRoom EWScreen;

	HQPres = `HQPRES;
	if (HQPres == none)
		return "ERR not on the Avenger";
	DynamicLoadObject(default.UIPackage $ ".ewxSituationRoom", class'Object', true);
	// A black background under it (EW's earth goes into its map area: OnInit).
	class'UILWEWMapBackdrop'.static.ShowIfAvailable(false);
	EWScreen = HQPres.Spawn(class'UILWEWSituationRoom', HQPres);
	EWScreen.Package = name("/ package/ewxSituationRoom/SituationRoom");
	EWScreen.MCName = 'theScreen';
	HQPres.ScreenStack.Push(EWScreen);
	return "ok EW Situation Room";
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

	if (DynamicLoadObject("FX_Globe.T_Earth_Holo", class'Texture2D', true) == none)
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
