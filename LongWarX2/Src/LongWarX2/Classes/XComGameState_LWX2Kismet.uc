// An Enemy Within level's Kismet being run (LWX2Kismet), its state: the variables' values as the script has set them, how
// often each event has fired, the remote events fired so far, the objectives it shows, whether it still holds victory back,
// and its wave system's sets and waves (LWX2WaveSystem).
class XComGameState_LWX2Kismet extends XComGameState_BaseObject;

/** The level being run (LWX2Kismet.Levels' L). */
var int Level;
/** Int and bool variables the script has written (by K), and their values; floats likewise. */
var array<int> VarK, VarV;
var array<int> FloatK;
var array<float> FloatV;
/** Object variables the script has written: a unit's ObjectID (0: none). */
var array<int> ObjK, ObjV;
/** Each event that has fired (by K), and how often. */
var array<int> EvK, EvN;
/** Every remote event fired, in order (the wave system's sets start and stop on them, EW's ActivateCount). */
var array<string> Fired;
/** The objectives shown: their id, text and state (0 open, 1 done, 2 failed, -1 removed). */
var array<string> ObjIds, ObjTexts;
var array<int> ObjStates;
/** A Delay Victory activated with Stop Delaying set: the script lets the battle be won. */
var bool bVictoryReleased;
/** The wave system: each set's state (0 waiting, 1 active, 2 done) and the turn it began, by set number; the waves spawned
 *  (set × 100 + wave). */
var array<int> SetState, SetTurn;
var array<int> WavesSpawned;
/** Long War's species the mission's squad holds (EW's scalable list: XComWaveSystem.InitScalableList). */
var array<int> Species;
/** Whose turn it was when last seen (1 XCOM, 2 the aliens), and the units known dead. */
var int LastSide;
var array<int> DeadSeen;

/** Told of every side's turn beginning and ending (XCOM 2's PlayerTurnBegun and PlayerTurnEnded), for the script's turn events
 *  and the wave system (LWX2HQAssault.Turn): the mod's own check, twice a second, misses an aliens' turn with nothing in it. */
function RegisterTurns()
{
	local Object Me;

	Me = self;
	`XEVENTMGR.RegisterForEvent(Me, 'PlayerTurnBegun', OnTurnBegun, ELD_OnStateSubmitted);
	`XEVENTMGR.RegisterForEvent(Me, 'PlayerTurnEnded', OnTurnEnded, ELD_OnStateSubmitted);
}

function EventListenerReturn OnTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	if (XComGameState_Player(EventData) != none)
		class'LWX2HQAssault'.static.Turn(XComGameState_Player(EventData).GetTeam(), true);
	return ELR_NoInterrupt;
}

function EventListenerReturn OnTurnEnded(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	if (XComGameState_Player(EventData) != none)
		class'LWX2HQAssault'.static.Turn(XComGameState_Player(EventData).GetTeam(), false);
	return ELR_NoInterrupt;
}

function int GetInt(int K, int Fallback)
{
	local int i;

	i = VarK.Find(K);
	return i == INDEX_NONE ? Fallback : VarV[i];
}

function SetInt(int K, int V)
{
	local int i;

	i = VarK.Find(K);
	if (i == INDEX_NONE)
	{
		VarK.AddItem(K);
		VarV.AddItem(V);
	}
	else
		VarV[i] = V;
}

function float GetFloat(int K, float Fallback)
{
	local int i;

	i = FloatK.Find(K);
	return i == INDEX_NONE ? Fallback : FloatV[i];
}

function SetFloat(int K, float V)
{
	local int i;

	i = FloatK.Find(K);
	if (i == INDEX_NONE)
	{
		FloatK.AddItem(K);
		FloatV.AddItem(V);
	}
	else
		FloatV[i] = V;
}

function int GetObj(int K)
{
	local int i;

	i = ObjK.Find(K);
	return i == INDEX_NONE ? 0 : ObjV[i];
}

function SetObj(int K, int ObjectID)
{
	local int i;

	i = ObjK.Find(K);
	if (i == INDEX_NONE)
	{
		ObjK.AddItem(K);
		ObjV.AddItem(ObjectID);
	}
	else
		ObjV[i] = ObjectID;
}

/** An event may fire (it has fired fewer than Max times; Max 0: any); counted. */
function bool CountEvent(int K, int Max)
{
	local int i;

	i = EvK.Find(K);
	if (i == INDEX_NONE)
	{
		EvK.AddItem(K);
		EvN.AddItem(1);
		return true;
	}
	if (Max > 0 && EvN[i] >= Max)
		return false;
	EvN[i]++;
	return true;
}

function SetObjective(string Id, string Text, int Kind)
{
	local int i;

	i = ObjIds.Find(Id);
	if (i == INDEX_NONE)
	{
		ObjIds.AddItem(Id);
		ObjTexts.AddItem(Text);
		ObjStates.AddItem(Kind);
	}
	else
	{
		if (Text != "")
			ObjTexts[i] = Text;
		ObjStates[i] = Kind;
	}
}
