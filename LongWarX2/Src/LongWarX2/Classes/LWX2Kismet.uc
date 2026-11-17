// An interpreter for Enemy Within levels' Kismet (features/lw-story.md): the level's sequence ops, links and variables as
// tools/convert/ew-kismet.ts reads them from the player's own install into XComLWX2Kismet.ini, run in the mission as EW runs
// them. Events (the level loaded, turns beginning and ending, a unit killed, remote events) start ops; each op does what its
// class does in EW and passes on along its output links. What acts on the game: remote events (the level's own, the wave
// system's, the mission handler's states), objectives shown, units counted in volumes, XCOM's reinforcements spawned, victory
// held back (Delay Victory). Cinematics, cameras, sounds, narrative, effects and toggled actors do nothing but pass on.
// The script's values live in XComGameState_LWX2Kismet; one run is one change to it, with what it asks of the game done
// after (spawning needs game states of its own).
class LWX2Kismet extends Object config(LWX2Kismet);

struct LWX2KLevel
{
	var int L;
	var string Name;
};

/** An op: K (the level × 100000 + its export index), its class, its sequence, a name (an event's, a state's, a label), an
 *  int and a float (a random switch's link count, a delay's duration, a reinforcement's blueshirt), how often an event fires
 *  (0: any). */
struct LWX2KOp
{
	var int K;
	var name T;
	var int Sq;
	var string N;
	var int I;
	var float F;
	var int M;
};

struct LWX2KLink
{
	var int K;
	var int O;
	var int To;
	var int In;
};

struct LWX2KVarLink
{
	var int K;
	var string D;
	var int V;
};

/** A variable: its class and value; for an actor, its class (A), where it stands (P) and a volume's half-size (E). */
struct LWX2KVar
{
	var int K;
	var name T;
	var int I;
	var float F;
	var string S;
	var name A;
	var vector P;
	var vector E;
};

struct LWX2KSeqIn
{
	var int K;
	var int In;
	var int E;
};

struct LWX2KSeqOut
{
	var int K;
	var int O;
	var int F;
};

struct LWX2KAct
{
	var int K;
	var int In;
};

/** Something the run asks of the game, done once its change is submitted: 1 an XCOM reinforcement (B: a blueshirt). */
struct LWX2KDeferred
{
	var int Kind;
	var vector From, To;
	var bool B;
};

var config array<LWX2KLevel> Levels;
var config array<LWX2KOp> Ops;
var config array<LWX2KLink> Links;
var config array<LWX2KVarLink> VL;
var config array<LWX2KVar> Vars;
var config array<LWX2KSeqIn> SeqIn;
var config array<LWX2KSeqOut> SeqOut;

/** The state being changed in this run, its level, what is to run, what is to be done after. */
var XComGameState_LWX2Kismet S;
var array<LWX2KAct> Queue;
var array<LWX2KDeferred> Deferred;
var int Steps;

/** The level's number (L), by its package name; 0 when its Kismet was not exported. */
static function int LevelOf(string LevelName)
{
	local int k;

	k = default.Levels.Find('Name', LevelName);
	return k == INDEX_NONE ? 0 : default.Levels[k].L;
}

static function XComGameState_LWX2Kismet Current()
{
	local XComGameState_LWX2Kismet K;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWX2Kismet', K)
		return K;
	return none;
}

/** Begins running a level's Kismet: its state made (with the squad's species for the wave system), the level loaded. */
static function Begin(int Level, array<int> Species)
{
	local XComGameState NewGameState;
	local XComGameState_LWX2Kismet K;

	if (Level <= 0 || Current() != none)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: an EW level's Kismet begins");
	K = XComGameState_LWX2Kismet(NewGameState.CreateNewStateObject(class'XComGameState_LWX2Kismet'));
	K.Level = Level;
	K.Species = Species;
	K.LastSide = 1;
	`TACTICALRULES.SubmitGameState(NewGameState);
	Current().RegisterTurns();
	`log("LongWarX2: Kismet: level" @ Level @ "begins (" $ default.Ops.Length @ "ops exported in all)", , 'LongWarX2');
	Fire('SeqEvent_LevelLoaded');
}

/** Fires an event of this class (a remote event: by name; a unit killed or an alien count: with it) and runs what follows. */
static function Fire(name Kind, optional string EventName, optional int UnitID, optional int Number)
{
	local XComGameState NewGameState;
	local XComGameState_LWX2Kismet K;
	local LWX2Kismet VM;

	K = Current();
	if (K == none)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Kismet" @ Kind @ EventName);
	VM = new class'LWX2Kismet';
	VM.S = XComGameState_LWX2Kismet(NewGameState.ModifyStateObject(class'XComGameState_LWX2Kismet', K.ObjectID));
	if (Kind == 'SeqEvent_RemoteEvent')
		VM.Remote(EventName);
	else
		VM.TriggerAll(Kind, UnitID, Number);
	VM.Run();
	`TACTICALRULES.SubmitGameState(NewGameState);
	VM.DoDeferred();
}

/** Every event of this class in the level started (a unit killed: as its instigator; an alien count: into its variable). */
function TriggerAll(name Kind, int UnitID, int Number)
{
	local int i;
	local LWX2KOp Op;

	for (i = 0; i < default.Ops.Length; i++)
	{
		Op = default.Ops[i];
		if (Op.T != Kind || Op.K / 100000 != S.Level)
			continue;
		if (!S.CountEvent(Op.K, Op.M))
			continue;
		if (UnitID > 0)
			WriteObj(Op.K, "Instigator", UnitID);
		if (Kind == 'SeqEvent_RoamingAlienNumberSet')
			WriteInt(Op.K, "Alien Number", Number);
		Pass(Op.K, 0);
		// (A level loaded: visible, and its beginning.)
		if (Kind == 'SeqEvent_LevelLoaded')
			Pass(Op.K, 1);
	}
}

/** A remote event: noted (the wave system's sets go by it) and every remote event of that name in the level started. */
function Remote(string EventName)
{
	local int i;
	local LWX2KOp Op;

	S.Fired.AddItem(EventName);
	for (i = 0; i < default.Ops.Length; i++)
	{
		Op = default.Ops[i];
		if (Op.T == 'SeqEvent_RemoteEvent' && Op.K / 100000 == S.Level && Op.N == EventName && S.CountEvent(Op.K, Op.M))
			Pass(Op.K, 0);
	}
}

/** An op's output: every op linked to it queued, at the input it is linked to. */
function Pass(int K, int O)
{
	local int i;
	local LWX2KAct A;

	i = default.Links.Find('K', K);
	if (i == INDEX_NONE)
		return;
	while (i < default.Links.Length && default.Links[i].K == K)
	{
		if (default.Links[i].O == O)
		{
			A.K = default.Links[i].To;
			A.In = default.Links[i].In;
			Queue.AddItem(A);
		}
		i++;
	}
}

function Run()
{
	local LWX2KAct A;

	while (Queue.Length > 0 && Steps < 20000)
	{
		A = Queue[0];
		Queue.Remove(0, 1);
		Steps++;
		Perform(A.K, A.In);
	}
	if (Steps >= 20000)
		`log("LongWarX2: Kismet: stopped after 20000 steps (a loop?)", , 'LongWarX2');
}

/** The variables an op links under this label (each the one it stands for). */
function array<int> VarsOf(int K, string D)
{
	local array<int> Found;
	local int i;

	i = default.VL.Find('K', K);
	if (i == INDEX_NONE)
		return Found;
	while (i < default.VL.Length && default.VL[i].K == K)
	{
		if (default.VL[i].D == D)
			Found.AddItem(default.VL[i].V);
		i++;
	}
	return Found;
}

function int VarIndex(int V)
{
	return default.Vars.Find('K', V);
}

/** An int (or bool) variable's value: as the script set it, else as the level has it. */
function int IntOf(int V)
{
	local int i;

	i = VarIndex(V);
	return S.GetInt(V, i == INDEX_NONE ? 0 : default.Vars[i].I);
}

/** The first variable under a label read as an int; Default when none is linked. */
function int ReadInt(int K, string D, int Fallback)
{
	local array<int> L;

	L = VarsOf(K, D);
	return L.Length > 0 ? IntOf(L[0]) : Fallback;
}

function WriteInt(int K, string D, int Value)
{
	local array<int> L;
	local int V;

	L = VarsOf(K, D);
	foreach L(V)
		S.SetInt(V, Value);
}

function WriteObj(int K, string D, int ObjectID)
{
	local array<int> L;
	local int V;

	L = VarsOf(K, D);
	foreach L(V)
		S.SetObj(V, ObjectID);
}

function string ReadString(int K, string D)
{
	local array<int> L;
	local int i;

	L = VarsOf(K, D);
	if (L.Length == 0)
		return "";
	i = VarIndex(L[0]);
	return i == INDEX_NONE ? "" : default.Vars[i].S;
}

/** An actor variable's place (and a volume's half-size, zero for a point). */
function bool ReadPlace(int K, string D, out vector P, out vector E)
{
	local array<int> L;
	local int i;

	L = VarsOf(K, D);
	if (L.Length == 0)
		return false;
	i = VarIndex(L[0]);
	if (i == INDEX_NONE)
		return false;
	P = default.Vars[i].P;
	E = default.Vars[i].E;
	return true;
}

/** What an op does, by its class, as EW's does. */
function Perform(int K, int In)
{
	local int i, A, B, n;
	local LWX2KOp Op;
	local LWX2KDeferred D;
	local array<int> L;
	local bool bAll;
	local vector P, E;
	local string Text, Id;

	i = default.Ops.Find('K', K);
	if (i == INDEX_NONE)
		return;
	Op = default.Ops[i];
	switch (Op.T)
	{
		case 'Sequence':
			// A subsequence entered at an input: the event inside that the input starts.
			for (i = 0; i < default.SeqIn.Length; i++)
				if (default.SeqIn[i].K == K && default.SeqIn[i].In == In)
					Pass(default.SeqIn[i].E, 0);
			break;
		case 'SeqAct_FinishSequence':
			// Out of a subsequence: its sequence's output that this ends at.
			for (i = 0; i < default.SeqOut.Length; i++)
				if (default.SeqOut[i].F == K)
					Pass(default.SeqOut[i].K, default.SeqOut[i].O);
			break;
		case 'SeqAct_SetBool':
			L = VarsOf(K, "Value");
			A = L.Length > 0 ? IntOf(L[0]) : 1;
			WriteInt(K, "Target", A);
			Pass(K, 0);
			break;
		case 'SeqAct_SetInt':
			WriteInt(K, "Target", ReadInt(K, "Value", 0));
			Pass(K, 0);
			break;
		case 'SeqAct_AddInt':
			WriteInt(K, "IntResult", ReadInt(K, "A", 0) + ReadInt(K, "B", 0));
			Pass(K, 0);
			break;
		case 'SeqAct_SubtractInt':
			WriteInt(K, "IntResult", ReadInt(K, "A", 0) - ReadInt(K, "B", 0));
			Pass(K, 0);
			break;
		case 'SeqCond_CompareBool':
			// True when every linked bool is.
			bAll = true;
			L = VarsOf(K, "Bool");
			foreach L(A)
				if (IntOf(A) == 0)
					bAll = false;
			Pass(K, bAll ? 0 : 1);
			break;
		case 'SeqCond_CompareInt':
			// Every output that holds: A <= B, A > B, A == B, A < B, A >= B.
			A = ReadInt(K, "A", 0);
			B = ReadInt(K, "B", 0);
			if (A <= B)
				Pass(K, 0);
			if (A > B)
				Pass(K, 1);
			if (A == B)
				Pass(K, 2);
			if (A < B)
				Pass(K, 3);
			if (A >= B)
				Pass(K, 4);
			break;
		case 'SeqCond_IsHuman':
			Pass(K, IsHuman(K) ? 0 : 1);
			break;
		case 'SeqAct_RandomSwitch':
			if (In == 0)
			{
				n = Rand(Max(1, Op.I));
				WriteInt(K, "Active Link", n + 1);
				Pass(K, n);
			}
			break;
		case 'SeqAct_Delay':
			// Turn-based: a delay only orders things; it finishes now, after what is already queued.
			if (In == 0)
				Pass(K, 0);
			break;
		case 'SeqAct_ActivateRemoteEvent':
			Remote(Op.N);
			Pass(K, 0);
			break;
		case 'SeqAct_SpecialMissionHandler_GotoState':
			// The mission handler's state: it raises <State>_Begin, as EW's handlers do.
			Remote(Op.N $ "_Begin");
			Pass(K, 0);
			break;
		case 'SeqAct_DisplayMissionObjective':
			Text = ReadString(K, "Message");
			Id = ReadString(K, "Unique ID");
			if (Id == "")
				Id = Text;
			// Inputs: show incomplete, show complete, remove, show failed, hide its checkbox.
			S.SetObjective(Id, Text, In == 1 ? 1 : In == 2 ? -1 : In == 3 ? 2 : 0);
			Pass(K, 0);
			break;
		case 'SeqAct_GetNumUnitsInVolume':
			if (ReadPlace(K, "Volume", P, E))
				CountIn(K, P, E, In == 1);
			Pass(K, 0);
			break;
		case 'SeqAct_SpawnReinforcement':
			// Spawned at its origin point and walking to its destination (EW's SpawnNextReinforcement): here placed there.
			D.Kind = 1;
			D.B = Op.I != 0;
			if (ReadPlace(K, "Origin Point", P, E))
			{
				D.From = P;
				D.To = P;
				if (ReadPlace(K, "Destination Point", P, E))
					D.To = P;
				Deferred.AddItem(D);
			}
			Pass(K, 0);
			break;
		case 'SeqAct_DelayVictory':
			if (ReadInt(K, "Stop Delaying", 0) != 0)
				S.bVictoryReleased = true;
			Pass(K, 0);
			break;
		case 'SeqAct_GetActiveUnit':
			WriteObj(K, "Unit Pawn", FirstSoldier());
			Pass(K, 0);
			break;
		case 'SeqAct_PlaySound':
			// (Out, and Finished.)
			Pass(K, 0);
			Pass(K, 1);
			break;
		default:
			// Cinematics, cameras, narrative, effects, toggles, debug output: passed on.
			Pass(K, 0);
	}
}

/** The unit an op's "Unit" variable holds is XCOM's (EW's SeqCond_IsHuman: on the human team). */
function bool IsHuman(int K)
{
	local array<int> L;
	local XComGameState_Unit Unit;

	L = VarsOf(K, "Unit");
	if (L.Length == 0)
		return false;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.GetObj(L[0])));
	return Unit != none && Unit.GetTeam() == eTeam_XCom;
}

/** Units in a volume, by side, into the op's XCom, Alien, Civilian and Total variables (alive and well only, or every
 *  living one). */
function CountIn(int K, vector P, vector E, bool bWellOnly)
{
	local XComGameState_Unit Unit;
	local vector At;
	local int nX, nA, nC;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!Unit.IsAlive() || Unit.bRemovedFromPlay || Unit.GetMyTemplate().bIsCosmetic)
			continue;
		if (bWellOnly && (Unit.IsBleedingOut() || Unit.IsUnconscious()))
			continue;
		At = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
		if (!class'LWX2ChryssalidHive'.static.Inside(P, E, At))
			continue;
		if (Unit.GetTeam() == eTeam_XCom)
			nX++;
		else if (Unit.GetTeam() == eTeam_Alien)
			nA++;
		else
			nC++;
	}
	WriteInt(K, "XCom", nX);
	WriteInt(K, "Alien", nA);
	WriteInt(K, "Civilian", nC);
	WriteInt(K, "Total", nX + nA + nC);
}

function int FirstSoldier()
{
	local XComGameState_Unit Unit;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_XCom && Unit.IsSoldier() && Unit.IsAlive() && !Unit.bRemovedFromPlay)
			return Unit.ObjectID;
	return 0;
}

/** What the run asked of the game. */
function DoDeferred()
{
	local LWX2KDeferred D;

	foreach Deferred(D)
		if (D.Kind == 1)
			class'LWX2HQAssault'.static.Reinforce(D.From, D.To, D.B);
}

/** The objective the script shows last that is still open; "" for none. */
static function string ObjectiveText()
{
	local XComGameState_LWX2Kismet K;
	local int i;

	K = Current();
	if (K == none)
		return "";
	for (i = K.ObjIds.Length - 1; i >= 0; i--)
		if (K.ObjStates[i] == 0 && K.ObjTexts[i] != "")
			return K.ObjTexts[i];
	return "";
}
