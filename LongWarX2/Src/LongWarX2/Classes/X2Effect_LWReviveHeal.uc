// Long War's Revive (features/lw-classes.md): a medikit used on a soldier bleeding out brings them back at Pct % of
// their maximum health, not only stabilized. XCOM 2's medikit heal, its amount set from the target before it heals.
class X2Effect_LWReviveHeal extends X2Effect_ApplyMedikitHeal;

var int Pct;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(kNewTargetState);
	if (Unit != none)
		PerUseHP = Max(1, Round(Unit.GetMaxStat(eStat_HP) * Pct / 100.0) - int(Unit.GetCurrentStat(eStat_HP)));
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}
