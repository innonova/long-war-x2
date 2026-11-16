// The Chryssalid hive's state (LWX2ChryssalidHive): where the objectives stand (XComSpecialMissionHandler_ChrysHive's
// states), the hive's turns since the whale was seen, the run's turns left to the air strike, which volumes soldiers have
// entered, which exits are armed and which of the level's scripted spawns have come.
class XComGameState_LWX2Hive extends XComGameState_BaseObject;

/** 1 investigate the response team's disappearance, 2 find the source of the infestation, 3 reactivate the transponder,
 *  4 reach the EVAC before the strike craft arrive, 5 the air strike come. */
var int Stage;
/** EW's EnemyLevel (2 with more than 4 roaming aliens, 1 with 4, 0 fewer), which picks the level's zombies. */
var int EnemyLevel;
/** The aliens' turns ended since the whale was seen (the hive's TurnCounter). */
var int HiveTurn;
/** XCOM's turn when last counted: a new one means the aliens' turn between has ended. */
var int LastTurn;
/** The run's turns left to the air strike (AirStrikeRemainingTime). */
var int StrikeLeft;
/** XCOM's last turn whose end the countdown has counted, and whether the first (not counted) has been. */
var int CountedTurn;
var bool bFirstCounted;
/** The run's own spawns made and the EVAC shown. */
var bool bRunBegun;
/** (Ints, 0 or 1: a bool array's Length set leaves it empty.) */
var array<int> Entered;
/** An exit's volume entered on the run: it sends its Chryssalid as the aliens' turn ends. */
var array<int> ExitArmed;
var array<int> Spawned;
