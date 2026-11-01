// Who Long War's arc thrower may stun (XGTacticalGameCore.CanBeStunned): an alien, not a chryssalid, a zombie or the
// Uber Ethereal (robots are kept out by the ability's other condition). XCOM 2's: no chryssalids, their cocoons, the
// psi zombies, the Chosen or the Avatar.
class X2Condition_LWStunnable extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Unit;
	local name Group;

	Unit = XComGameState_Unit(kTarget);
	if (Unit == none || Unit.IsChosen() || Unit.GetMyTemplate().bIsCivilian || Unit.IsSoldier())
		return 'AA_UnitIsWrongType';
	Group = Unit.GetMyTemplate().CharacterGroupName;
	if (Group == 'Chryssalid' || Group == 'ChryssalidCocoon' || Group == 'PsiZombie' || Group == 'TheLost' || Group == 'AdventPsiWitch')
		return 'AA_UnitIsWrongType';
	return 'AA_Success';
}
