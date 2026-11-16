// A target not carrying an item of a template (Chitin Plating against the Seeker's Strangle: Long War's "sturdy enough to
// provide a strangulation countermeasure").
class X2Condition_LWNoItem extends X2Condition;

var name Item;
/** Another item that also protects (the Respirator Implant: "immunity to strangle"). */
var name OrItem;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(kTarget);
	if (Unit != none && (class'X2Ability_LWDamageReduction'.static.HasItem(Unit, Item) || (OrItem != '' && class'X2Ability_LWDamageReduction'.static.HasItem(Unit, OrItem))))
		return 'AA_UnitIsImmune';
	return 'AA_Success';
}
