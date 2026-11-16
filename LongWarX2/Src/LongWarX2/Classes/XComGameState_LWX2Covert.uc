// An EXALT covert extraction's state (LWX2CovertExtraction): the two comm relays the battle activated (indices into the
// level's relays), which are hacked, the turn the operative last hacked one, and whether the operative got away.
class XComGameState_LWX2Covert extends XComGameState_BaseObject;

var array<int> Active;
var array<bool> Hacked;
var int HackedOnTurn;
var bool bPlaced;
var bool bExtracted;

function int Left()
{
	local int i, n;

	for (i = 0; i < Active.Length; i++)
		if (i >= Hacked.Length || !Hacked[i])
			n++;
	return n;
}
