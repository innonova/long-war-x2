// Progeny's Deluge, its state (LWX2Deluge): where the objectives stand, the turns to the dam's collapse (or, once it has
// broken, to the end), which bypass valves are open and which have brought their aliens.
class XComGameState_LWX2Deluge extends XComGameState_BaseObject;

/** 1 locate the transport, 2 secure it (spotted), 3 the dam broken: report to the EVAC, 5 over. */
var int Stage;
var int TurnsLeft;
/** (Ints, 0 or 1.) */
var array<int> ValveOpen;
var array<int> Dropped;
/** XCOM's turn when last seen (a new one: the aliens' turn has ended), and the last whose end was counted. */
var int LastTurn;
var int CountedTurn;

function int ValvesOpen()
{
	local int i, n;

	for (i = 0; i < ValveOpen.Length; i++)
		if (ValveOpen[i] != 0)
			n++;
	return n;
}
