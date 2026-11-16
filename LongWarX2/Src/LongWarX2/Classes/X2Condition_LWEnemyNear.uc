// An ability's user has an enemy within Tiles (features/lw-aliens.md: the Cyberdisc's Death Blossom, used only with someone
// to hit; XCOM 2's AI asks an ability whether it is available, and this makes it not, with no one near).
class X2Condition_LWEnemyNear extends X2Condition;

var int Tiles;
/** At least this many enemies within Tiles (0: one); and at least SeenEnemies enemies in sight (0: no matter). */
var int MinCount, SeenEnemies;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Me, Other;
	local int n;

	Me = XComGameState_Unit(kTarget);
	if (Me == none)
		return 'AA_NotAUnit';
	if (SeenEnemies > 0 && class'X2TacticalVisibilityHelpers'.static.GetNumVisibleEnemyTargetsToSource(Me.ObjectID) < SeenEnemies)
		return 'AA_NoTargets';
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Other)
		if (Other.IsAlive() && !Other.bRemovedFromPlay && Other.IsEnemyUnit(Me) && Me.TileDistanceBetween(Other) <= Tiles)
			if (++n >= Max(1, MinCount))
				return 'AA_Success';
	return 'AA_NoTargets';
}
