// A power node switched off, or the bomb disarmed (bBomb), by the soldier beside it (LWX2CouncilBomb).
class X2Effect_LWX2BombPart extends X2Effect;

var bool bBomb;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Unit;
	local XComGameState_LWX2Bomb Bomb;
	local int i;

	Unit = XComGameState_Unit(kNewTargetState);
	Bomb = class'LWX2CouncilBomb'.static.State();
	if (Unit == none || Bomb == none)
		return;
	i = class'LWX2CouncilBomb'.static.InReach(Unit.TileLocation, bBomb);
	if (i == -1)
		return;
	Bomb = XComGameState_LWX2Bomb(NewGameState.ModifyStateObject(class'XComGameState_LWX2Bomb', Bomb.ObjectID));
	if (bBomb)
		Bomb.bDisarmed = true;
	else if (i >= 0 && i < Bomb.NodeOff.Length)
		Bomb.NodeOff[i] = true;
	`log("LongWarX2: council bomb:" @ Unit.GetFullName() @ (bBomb ? "disarmed the bomb" : "switched node" @ i @ "off"), , 'LongWarX2');
}
