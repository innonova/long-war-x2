// Command's charges (features/lw-officers.md): one per officer rank (Long War's "+1 Command charge" each).
class X2AbilityCharges_LWOfficer extends X2AbilityCharges;

function int GetInitialCharges(XComGameState_Ability Ability, XComGameState_Unit Unit)
{
	return class'LWOfficers'.static.Rank(Unit);
}
