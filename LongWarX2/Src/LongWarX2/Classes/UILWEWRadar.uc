// Enemy Within's radar on XCOM 2's tactical HUD (features/lw-gear.md: the Motion Tracker): EW's TacticalHUD movie (the
// player's converted EWTacticalUI.upk), only its radar (theRadarMC) shown, driven as EW's UITacticalHUD_Radar drives it:
// shown while the selected soldier has Bioelectric Skin or a Motion Tracker turned on this turn (LW_MotionTrackerActive),
// its blips every fifth of a second (UpdateBlips: "type,x,y//…", x and y within -1..1 of the radar's reach, the reach
// BASE_REMOVAL_DAYS of EW's metres, 35 x 64 units), turned with the camera (SetRotation). EW's blip types: 1 a squadmate,
// 2 hurt, 3 dead, 4 an alien (a Seeker cloaked and EW's battle scanners left out), 5 a civilian, 6 meld. Not on the screen
// stack: it takes no input.
class UILWEWRadar extends UILWEWScreen config(LWGear) dependson(XComGameState_LWX2Meld);

/** The radar's reach in XCOM 2's units (Long War's BASE_REMOVAL_DAYS, 35, in EW's metres of 64 units). */
var config float Reach;
/** Where the radar's centre stands on EW's stage, down from the top (EW's own: 95, where XCOM 2's objectives are). */
var config float RadarY;
var bool bShown, bSetUp;
/** What it showed last (the control port's radar aid): its blips and its turn. */
var string LastBlips;
var float LastTurn;

/** The radar of this mission's HUD, made the first time (a soldier able to use it in the squad). */
static function UILWEWRadar Ensure(XComPresentationLayer Pres)
{
	local UILWEWRadar R;

	if (Pres == none || Pres.Get2DMovie() == none)
		return none;
	foreach Pres.AllActors(class'UILWEWRadar', R)
		return R;
	if (DynamicLoadObject(default.UIPackage $ ".ewxTacticalHUD", class'Object', true) == none)
		return none;
	R = Pres.Spawn(class'UILWEWRadar', Pres);
	R.Package = name("/ package/ewxTacticalHUD/TacticalHUD");
	R.MCName = 'theTacticalHUD';
	R.InitScreen(XComPlayerController(Pres.Owner), Pres.Get2DMovie());
	Pres.Get2DMovie().LoadScreen(R);
	// (EW's tactical HUD never reports itself inited to XCOM 2 (its screen class waits on EW's tactical framework): set up
	// once its radar's clip is there, SetUp.)
	R.SetTimer(0.2, true, nameof(Refresh));
	return R;
}

simulated function OnInit()
{
	super(UIScreen).OnInit();
	SetUp();
}

/** Scaled to XCOM 2's stage, everything of EW's HUD but its radar hidden. */
function SetUp()
{
	local string C;
	local array<string> Others;

	if (bSetUp)
		return;
	bSetUp = true;
	ScaleToStage();
	SetEWView(Movie);
	// (Everything of EW's HUD but its radar hidden: XCOM 2's own HUD stays.)
	Others.AddItem("theInfoBox");
	Others.AddItem("theRightHUD");
	Others.AddItem("theWeaponContainer");
	Others.AddItem("theStatsContainer");
	Others.AddItem("perkContainer");
	Others.AddItem("theObjectivesList");
	Others.AddItem("theTargetHealthBar");
	Others.AddItem("theReticle");
	Others.AddItem("theAimArea");
	foreach Others(C)
		Movie.SetVariableBool(MCPath $ "." $ C $ "._visible", false);
	Movie.SetVariableBool(MCPath $ ".theRadarMC._visible", false);
}

/** The selected soldier, and whether the radar is on for them. */
function XComGameState_Unit Selected()
{
	local XComTacticalController TC;
	local XGUnit U;

	TC = XComTacticalController(GetALocalPlayerController());
	U = TC != none ? TC.GetActiveUnit() : none;
	return U != none ? XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(U.ObjectID)) : none;
}

static function bool RadarOn(XComGameState_Unit Unit)
{
	return Unit != none && (Unit.IsUnitAffectedByEffectName('LW_MotionTrackerActive') || Unit.FindAbility('LW_BioelectricSkin').ObjectID > 0);
}

function Refresh()
{
	local XComGameState_Unit Unit, Other;
	local UITacticalHUD HUD;
	local XComGameStateHistory History;
	local XComGameState_LootDrop Drop;
	local XComGameState_LWX2Meld Waiting;
	local XComGameState_LWX2Meld.LWX2HiddenCanister H;
	local vector At, Here;
	local array<string> Blips;
	local float R;
	local int Type;

	if (!bSetUp)
	{
		if (Movie == none || Movie.GetVariableObject(MCPath $ ".theRadarMC") == none)
			return;
		SetUp();
	}
	Unit = Selected();
	// (Shown with XCOM 2's HUD only: not over a reveal's or an ability's camera, which hide it.)
	HUD = XComPresentationLayer(Movie.Pres) != none ? XComPresentationLayer(Movie.Pres).GetTacticalHUD() : none;
	if (!RadarOn(Unit) || HUD == none || !HUD.bIsVisible || HUD.m_kAbilityHUD == none || !HUD.m_kAbilityHUD.bIsVisible)
	{
		if (bShown)
			Movie.SetVariableBool(MCPath $ ".theRadarMC._visible", false);
		bShown = false;
		return;
	}
	R = Reach > 0 ? Reach : 35.0 * 64.0;
	Here = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', Other)
	{
		if (Other.ObjectID == Unit.ObjectID || Other.bRemovedFromPlay || Other.GetMyTemplate().bIsCosmetic)
			continue;
		At = `XWORLD.GetPositionFromTileCoordinates(Other.TileLocation);
		if (VSize2D(At - Here) > R)
			continue;
		Type = 0;
		if (Other.GetTeam() == eTeam_XCom && Other.IsSoldier())
			Type = Other.IsDead() ? 3 : (Other.GetCurrentStat(eStat_HP) < Other.GetMaxStat(eStat_HP) ? 2 : 1);
		else if (Other.GetTeam() == eTeam_Alien && Other.IsAlive())
			Type = 4;
		else if (Other.IsCivilian() && Other.IsAlive())
			Type = 5;
		if (Type > 0)
			Blips.AddItem(Blip(Type, At - Here, R));
	}
	// (Meld: the canisters on the field, and those still hidden in the fog (LWMeld): EW's radar shows both.)
	foreach History.IterateByClassType(class'XComGameState_LootDrop', Drop)
	{
		if (!IsMeld(Drop))
			continue;
		At = `XWORLD.GetPositionFromTileCoordinates(Drop.TileLocation);
		if (VSize2D(At - Here) <= R)
			Blips.AddItem(Blip(6, At - Here, R));
	}
	Waiting = XComGameState_LWX2Meld(History.GetSingleGameStateObjectForClass(class'XComGameState_LWX2Meld', true));
	if (Waiting != none)
		foreach Waiting.Hidden(H)
		{
			At = `XWORLD.GetPositionFromTileCoordinates(H.Tile);
			if (VSize2D(At - Here) <= R)
				Blips.AddItem(Blip(6, At - Here, R));
		}
	LastBlips = Blips.Length > 0 ? JoinBlips(Blips) : "0,0,0";
	SetBlips(LastBlips);
	TurnRadar();
	// (Below XCOM 2's objectives, which hold EW's corner: RadarY of EW's stage, again each time as the radar moves itself
	// back on a change of resolution.)
	Movie.SetVariableNumber(MCPath $ ".theRadarMC._y", RadarY > 0 ? RadarY : 250.0);
	if (!bShown)
		Movie.SetVariableBool(MCPath $ ".theRadarMC._visible", true);
	bShown = true;
}

/** A drop of meld (LWMeld.Canister: a loot drop of Long War's meld). */
static function bool IsMeld(XComGameState_LootDrop Drop)
{
	local StateObjectReference Ref;
	local XComGameState_Item Item;

	foreach Drop.LootableItemRefs(Ref)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Item != none && Item.GetMyTemplateName() == 'LWItem_Meld')
			return true;
	}
	return false;
}

/** A blip: its type, and where it lies within the reach (EW's radar axes: -x forward of the world's X, -y its Y; the
 *  radar turned with the camera, SetRotation). */
static function string Blip(int Type, vector Off, float R)
{
	return Type $ "," $ (-Off.X / R) $ "," $ (-Off.Y / R);
}

static function string JoinBlips(array<string> A)
{
	local string S;
	local int i;

	for (i = 0; i < A.Length; i++)
		S $= (i > 0 ? "//" : "") $ A[i];
	return S;
}

function SetBlips(string Data)
{
	local array<ASValue> Args;
	local ASValue V;

	V.Type = AS_String;
	V.s = Data;
	Args.AddItem(V);
	Movie.Invoke(MCPath $ ".theRadarMC.UpdateBlips", Args);
}

/** The radar turned as the camera looks (UITacticalHUD_Radar.UpdateCameraOrientation). */
function TurnRadar()
{
	local array<ASValue> Args;
	local ASValue V;
	local vector Look;

	Look = vector(GetALocalPlayerController().PlayerCamera.GetCameraRotation());
	Look.Z = 0;
	Look = Normal(Look);
	V.Type = AS_Number;
	V.n = (Atan2(1.0, 0.0) - Atan2(Look.Y, Look.X)) * 57.2958;
	LastTurn = V.n;
	Args.AddItem(V);
	Movie.Invoke(MCPath $ ".theRadarMC.SetRotation", Args);
}

simulated function OnReceiveFocus();
simulated function OnLoseFocus();
simulated function bool OnUnrealCommand(int cmd, int arg) { return false; }
simulated function OnMouseEvent(int cmd, array<string> args);

defaultproperties
{
	UIPackage = "EWTacticalUI"
	InputState = eInputState_None
	bConsumeMouseEvents = false
	bShowsBase = false
}
