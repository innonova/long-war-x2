// For development: the game driven from outside without the mouse. A TCP port on the test
// machine (its switch: ControlPort, 0 = off, off in the player's build) takes one command a line and
// answers with lines ending in a line holding a single ".": the Geoscape's state, running time,
// taking a decision, satellites, ending a mission as won, any console command.
// tools/test/lw.sh sends them from here. Spawned in each world by UIScreenListener_LWX2Control.
class LWX2Control extends TcpLink config(LWAirWar);

var config int ControlPort;

event PostBeginPlay()
{
	super.PostBeginPlay();
	if (BindPort(ControlPort) != ControlPort || !Listen())
	{
		`log("LongWarX2: control: port" @ ControlPort @ "not open", , 'LongWarX2');
		return;
	}
	`log("LongWarX2: control: listening on" @ ControlPort, , 'LongWarX2');
}

/** The listener in this world, made if the switch is on and there is none. */
static function Ensure(Actor Anywhere)
{
	local LWX2Control C;

	if (default.ControlPort <= 0)
		return;
	foreach Anywhere.WorldInfo.AllActors(class'LWX2Control', C)
		return;
	Anywhere.Spawn(class'LWX2Control');
}

defaultproperties
{
	AcceptClass = class'LWX2ControlClient';
	bAlwaysTick = true;
}
