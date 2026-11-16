// A council bomb disposal's state (LWX2CouncilBomb): the power nodes switched off, and whether the bomb is disarmed.
class XComGameState_LWX2Bomb extends XComGameState_BaseObject;

var array<bool> NodeOff;
var bool bDisarmed;

function int NodesOff()
{
	local int i, n;

	for (i = 0; i < NodeOff.Length; i++)
		if (NodeOff[i])
			n++;
	return n;
}
