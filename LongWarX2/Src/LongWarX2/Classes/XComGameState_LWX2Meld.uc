// Meld canisters not seen yet (LWMeld; features/lw-loot.md): without Recon (second wave #29) Long War keeps a canister hidden
// in the fog until XCOM sees it, and XCOM 2 shows a loot drop's marker anywhere, so a canister waits here, unmade, until
// XCOM has seen its tile.
class XComGameState_LWX2Meld extends XComGameState_BaseObject;

struct LWX2HiddenCanister
{
	var TTile Tile;
	/** EW's turns for it, from the mission's start (gone on that turn). */
	var int Turns;
	var int Amount;
};
var array<LWX2HiddenCanister> Hidden;
