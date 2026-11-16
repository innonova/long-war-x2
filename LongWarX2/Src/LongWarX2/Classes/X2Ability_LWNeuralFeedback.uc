// Neural Feedback (features/lw-psi.md; Long War's XGUnit.ApplyNeuralFeedback, its gene mod slot ePerk_GeneMod_BrainFeedback):
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
	return Templates;
}
