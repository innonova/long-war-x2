// The Temple Ship, its state (LWX2TempleShip): which stage the battle is in, which scripted spawns have come, the Uber Ethereal.
class XComGameState_LWX2Temple extends XComGameState_BaseObject;

/** 1 the first arena, 2 its first swarm due, 3 its second swarm due, 4 the second arena, 5 the boss arena, 6 the Uber Ethereal
 *  seen (its guard come), 7 over. */
var int Stage;
/** (Ints, 0 or 1.) The first swarm and the second have come. */
var int Swarm1, Swarm2;
/** XCOM's turn when last seen (a new one: the aliens' turn has ended). */
var int LastTurn;
var int UberID;
