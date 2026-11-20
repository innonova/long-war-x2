// EW's emitters on a mission map placed a few each tick (features/ew-emitters.md): the terror bar's 76 started in one frame
// killed XCOM 2 a second later; one by one, all of them in view, they did not. Tagged LWX2EWMission (placed once).
class LWX2EmitterPlacer extends Actor;

var LWX2EWMapData Data;
var int Next;
/** How many each tick. */
var int PerTick;
/** Seconds after the battle's start before the first (placed at once at the start, the game died; placed minutes in,
 *  all of them, it did not). */
var float Delay;

function Begin(LWX2EWMapData D)
{
	Data = D;
	Next = 0;
}

event Tick(float DeltaTime)
{
	local array<Actor> Placed;
	local Actor A;

	super.Tick(DeltaTime);
	if (Delay > 0)
	{
		Delay -= DeltaTime;
		return;
	}
	if (Data == none || Next >= Data.Emitters.Length)
	{
		if (Data != none)
			`log("LongWarX2: EW map:" @ Data.Emitters.Length @ "of EW's emitters placed, a few each tick", , 'LongWarX2');
		Destroy();
		return;
	}
	class'LWX2EWMapPieces'.static.PlaceEmittersOf(Data, self, vect(0, 0, 0), Placed, "", Next, PerTick);
	foreach Placed(A)
		A.Tag = 'LWX2EWMission';
	Next += PerTick;
}

defaultproperties
{
	PerTick = 2
	Delay = 0
}
