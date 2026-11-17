// Progeny's Furies, its state (LWX2Furies): the console disarmed or not, the alarm sounded, the turns to the execution.
class XComGameState_LWX2Furies extends XComGameState_BaseObject;

/** 1 rescue the abductees (the console still on), 2 kill the rest, 5 over. */
var int Stage;
var bool bAlarm;
var int TimerLeft;
/** XCOM's last turn whose end the countdown has seen, and whether the first (not counted: DecrementFirstTime?) has been. */
var int CountedTurn;
var bool bFirstCounted;
