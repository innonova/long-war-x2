// The campaign's jets, kept in XCOM 2's game state so the save carries them
// (features/hard-parts.md, experiment 3): damage taken and kills, fight by fight.
class XComGameState_LWAirWar extends XComGameState_BaseObject;

struct LWJet
{
	var string Callsign;
	/** 1 Interceptor, 3 Firestorm. */
	var int Type;
	var int Weapon;
	var int Hp;
	var int Kills;
	/** The continent it is based on (LWStrategyRules' numbering); where it is going while it transfers. */
	var int Continent;
	var int TransferTo;
	/** 0 ready, 2 refuelling, 4 repairing, 6 transferring, 7 refitting (Long War's interceptor statuses); the hours until done. */
	var int Status;
	var int HoursDown;
	/** Its bay in the base's hangar (1-4: EW's m_iHomeBay + 1; LWHangar.AssignBays), 0 none: based elsewhere, on its way. */
	var int Bay;
};

/** Interceptors ordered (the hangar, LWHangar): how many, where to, the hours until they arrive. */
struct LWJetOrder
{
	var int Continent;
	var int Count;
	var int HoursLeft;
};

var array<LWJet> Jets;
var array<LWJetOrder> Orders;
/** Craft made so far, for their callsigns. */
var int Counter;

static function XComGameState_LWAirWar Get()
{
	return XComGameState_LWAirWar(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LWAirWar', true));
}

/** Long War's start: two Interceptors with Avalanche Missiles. */
static function XComGameState_LWAirWar CreateIn(XComGameState NewGameState)
{
	local XComGameState_LWAirWar AirWar;

	AirWar = XComGameState_LWAirWar(NewGameState.CreateNewStateObject(class'XComGameState_LWAirWar'));
	AirWar.AddJet("Raven-1", 1, 3);
	AirWar.AddJet("Raven-2", 1, 3);
	AirWar.Counter = 2;
	return AirWar;
}

function AddJet(string Callsign, int Type, int Weapon)
{
	local LWJet Jet;

	Jet.Callsign = Callsign;
	Jet.Type = Type;
	Jet.Weapon = Weapon;
	Jet.Hp = class'LWAirWar'.static.Craft(Type, Weapon, 0).MaxHp;
	Jets.AddItem(Jet);
}

/** In a campaign loaded from before the mod was there: made once. */
static function EnsureExists()
{
	local XComGameState NewGameState;

	if (Get() != none)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the air war's jets");
	CreateIn(NewGameState);
	`XCOMHISTORY.AddGameStateToHistory(NewGameState);
}

/** Long War's pilot rank by confirmed kills (XGInterception): Cmdr. from 10, Col. from 7, Maj. from 5, Capt. from 3, Lt. */
static function string PilotRank(int Kills)
{
	return Kills >= 10 ? "Cmdr." : (Kills >= 7 ? "Col." : (Kills >= 5 ? "Maj." : (Kills >= 3 ? "Capt." : "Lt.")));
}

/** A fight's result, committed: the jet's HP and kills; a damaged jet goes for repair, a destroyed one is lost (LWHangar). */
static function Record(int Index, int Hp, bool Kill)
{
	local XComGameState NewGameState;
	local XComGameState_LWAirWar AirWar;

	AirWar = Get();
	if (AirWar == none || Index < 0 || Index >= AirWar.Jets.Length)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: an interception");
	AirWar = XComGameState_LWAirWar(NewGameState.ModifyStateObject(class'XComGameState_LWAirWar', AirWar.ObjectID));
	AirWar.Jets[Index].Hp = Max(0, Hp);
	if (Kill)
	{
		AirWar.Jets[Index].Kills++;
		// (A named pilot's rank by kills, XGInterception's end: the callsign's first word replaced, Lt. to Cmdr.)
		if (AirWar.Jets[Index].Hp > 0 && InStr(AirWar.Jets[Index].Callsign, " ") >= 0)
			AirWar.Jets[Index].Callsign = PilotRank(AirWar.Jets[Index].Kills) @ Split(AirWar.Jets[Index].Callsign, " ", true);
	}
	class'LWHangar'.static.AfterFight(AirWar, Index);
	`GAMERULES.SubmitGameState(NewGameState);
}
