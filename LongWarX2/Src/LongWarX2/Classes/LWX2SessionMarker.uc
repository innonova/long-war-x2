// A mark left in the current world (it goes with it): how a screen listener remembers something
// for one strategy or tactical session without holding an actor (a listener holding one keeps
// the old world from being unloaded, and the game stops at the next map change).
class LWX2SessionMarker extends Actor;

/** Whether the world has a mark with this tag; if not, leaves one. */
static function bool Seen(Actor InWorld, name Mark)
{
	local LWX2SessionMarker M;

	foreach InWorld.AllActors(class'LWX2SessionMarker', M)
		if (M.Tag == Mark)
			return true;
	M = InWorld.Spawn(class'LWX2SessionMarker');
	M.Tag = Mark;
	return false;
}

defaultproperties
{
	bHidden = true;
}
