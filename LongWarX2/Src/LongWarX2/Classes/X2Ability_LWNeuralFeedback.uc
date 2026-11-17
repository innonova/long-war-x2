// Neural Feedback and Extra Conditioning as abilities given with their perks. Neural Feedback (features/lw-psi.md; Long War's XGUnit.ApplyNeuralFeedback, its gene mod slot ePerk_GeneMod_BrainFeedback):
// an enemy's psionic power on a soldier with it puts that enemy's psionic powers on cooldown and hurts it by (the soldier's
// will x1.3 - its will) / 10, at least 1. Given with the power (X2DownloadableContentInfo_LongWarX2).
class X2Ability_LWNeuralFeedback extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2AbilityTemplate Template;
	local X2Effect_LWNeuralFeedback Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_NeuralFeedback');
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_LWNeuralFeedback';
	Effect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Templates.AddItem(Template);
	Templates.AddItem(ExtraConditioning());
	Templates.AddItem(ShapedArmor());
	Templates.AddItem(MECCloseCombat());
	Templates.AddItem(Passive('LWX2_Concealment', new class'X2Effect_LWConcealment'));
	return Templates;
}

/** A perk's hidden passive carrying one persistent effect. */
static function X2AbilityTemplate Passive(name TemplateName, X2Effect_Persistent Effect)
{
	local X2AbilityTemplate Template;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

/** The Foundry's Shaped Armor on a SHIV or a MEC: +3 HP (Long War's XGTacticalGameCore.GetInventoryStatModifiers, its
 *  Foundry perk bit 1; LWSHIVs.AddFoundryAbilities gives it). */
static function X2AbilityTemplate ShapedArmor()
{
	local X2AbilityTemplate Template;
	local X2Effect_PersistentStatChange Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_ShapedArmor');
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_PersistentStatChange';
	Effect.EffectName = 'LWX2_ShapedArmor';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.AddPersistentStatChange(eStat_HP, 3);
	Effect.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

/** The Foundry's MEC Close Combat on a MEC: its effect lets the Kinetic Strike (XCOM 2's sword slice) leave the turn open
 *  (X2Ability_LWStandins.AddMECCloseCombat puts the effect's name in the strike's cost). */
static function X2AbilityTemplate MECCloseCombat()
{
	local X2Effect_Persistent Effect;

	Effect = new class'X2Effect_Persistent';
	Effect.EffectName = 'LWX2_MECCloseCombat';
	Effect.DuplicateResponse = eDupe_Ignore;
	return Passive('LWX2_MECCloseCombat', Effect);
}

/** Extra Conditioning's hit points by armour (X2Effect_LWExtraConditioning), given with the perk. */
static function X2AbilityTemplate ExtraConditioning()
{
	local X2AbilityTemplate Template;
	local X2Effect_LWExtraConditioning Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_ExtraConditioning');
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_LWExtraConditioning';
	Effect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}
