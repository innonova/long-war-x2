// An EXALT data recovery's state (LWX2DataRecovery): each capture area's progress (EXALT's turns alone in it) and whether it
// fell, the turn each set of waves began (-1 not yet), which groups have come, and the last XCOM turn counted.
class XComGameState_LWX2Recovery extends XComGameState_BaseObject;

var array<int> Progress;
var array<bool> Captured;
var array<int> SetStart;
var array<bool> GroupDone;
var int LastTurn;
