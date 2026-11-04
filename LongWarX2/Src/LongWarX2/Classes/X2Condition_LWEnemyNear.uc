// An ability's user has an enemy within Tiles (features/lw-aliens.md: the Cyberdisc's Death Blossom, used only with someone
// to hit; XCOM 2's AI asks an ability whether it is available, and this makes it not, with no one near).
class X2Condition_LWEnemyNear extends X2Condition;

var int Tiles;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Me, Other;

	Me = XComGameState_Unit(kTarget);
	if (Me == none)
		return 'AA_NotAUnit';
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Other)
		if (Other.IsAlive() && !Other.bRemovedFromPlay && Other.IsEnemyUnit(Me) && Me.TileDistanceBetween(Other) <= Tiles)
			return 'AA_Success';
	return 'AA_NoTargets';
}
