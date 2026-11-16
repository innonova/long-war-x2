// The Ethereals' Psi Drain (X2Ability_LWAliens.PsiDrain), as Long War's XGUnit.PsiDrain: the ally loses the least of its
// health, 10 and half what the Ethereal is missing (at least 1); the Ethereal heals twice that.
class X2Effect_LWPsiDrain extends X2Effect;

var localized string DrainedText, HealedText;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Target, Source;
	local int Amount;

	Target = XComGameState_Unit(kNewTargetState);
	Source = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (Target == none || Source == none)
		return;
	Amount = Max(1, Min(Min(int(Target.GetCurrentStat(eStat_HP)), 10), int(Source.GetMaxStat(eStat_HP) - Source.GetCurrentStat(eStat_HP)) / 2));
	Target.TakeEffectDamage(self, Amount, 0, 0, ApplyEffectParameters, NewGameState);
	Source.SetCurrentStat(eStat_HP, FMin(Source.GetMaxStat(eStat_HP), Source.GetCurrentStat(eStat_HP) + 2 * Amount));
	`log("LongWarX2: aliens: Psi Drain:" @ Target.GetMyTemplateName() @ "-" $ Amount $ "," @ Source.GetMyTemplateName() @ "+" $ (2 * Amount), , 'LongWarX2');
}

defaultproperties
{
}
