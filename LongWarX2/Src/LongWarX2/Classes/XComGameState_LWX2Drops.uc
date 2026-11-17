// A variant level's gated alien drops, their state (LWX2LevelDrops): which volumes soldiers have entered, which drops have come.
class XComGameState_LWX2Drops extends XComGameState_BaseObject;

/** (Ints, 0 or 1.) */
var array<int> Entered;
var array<int> Dropped;
/** XCOM's turn when last seen: a new one means the aliens' turn between has ended. */
var int LastTurn;
