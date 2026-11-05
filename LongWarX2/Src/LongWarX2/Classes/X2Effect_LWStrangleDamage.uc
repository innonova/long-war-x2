// The Seeker's strangle damage (features/lw-aliens.md; EW's XGUnit.TakeStrangleDamage): 1 as it seizes, then on each of its
// turns 2, 4, 8, and 4 more each turn after (12, 16 …). The squeezes so far are counted on the held unit (LWX2Strangled).
// The aliens' damage bonus is added as on all their attacks (X2Effect_LWAlienDamage). EW's lessening for the units it calls
// immune (a fifth) is not here.
class X2Effect_LWStrangleDamage extends X2Effect_ApplyWeaponDamage;

/** The squeezes before this one: none as the Seeker seizes (LW_Strangle), else as counted. */
static function int Squeezes(XComGameState_Ability AbilityState, XComGameState_Unit Target)
{
	local UnitValue Count;

	if (AbilityState == none || AbilityState.GetMyTemplateName() == 'LW_Strangle' || Target == none)
		return 0;
	Target.GetUnitValue('LWX2Strangled', Count);
	return int(Count.fValue);
}

function WeaponDamageValue GetBonusEffectDamageValue(XComGameState_Ability AbilityState, XComGameState_Unit SourceUnit, XComGameState_Item SourceWeapon, StateObjectReference TargetRef)
{
	local WeaponDamageValue Damage;
	local int Turns;

	Turns = Squeezes(AbilityState, XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID)));
	Damage = EffectDamageValue;
	Damage.Damage = Turns < 4 ? 1 << Turns : 4 * (Turns - 1);
	Damage.Spread = 0;
	return Damage;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit Target;
	local int Turns;

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	Turns = Squeezes(AbilityState, Target);
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
	if (XComGameState_Unit(kNewTargetState) != none)
		XComGameState_Unit(kNewTargetState).SetUnitFloatValue('LWX2Strangled', Turns + 1, eCleanup_BeginTactical);
}

defaultproperties
{
	bIgnoreBaseDamage = true
	DamageTypes(0) = "Melee"
}
