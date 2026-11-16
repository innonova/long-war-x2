// A council bomb disposal's two actions (LWX2CouncilBomb): a power node switched off, the bomb disarmed, each from a tile
// beside it, for one action. Given to XCOM's soldiers on such a mission (X2DownloadableContentInfo_LongWarX2's
// FinalizeUnitAbilitiesForInit).
class X2Ability_LWX2Bomb extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Part('LWX2_DeactivateNode', false, "img:///UILibrary_PerkIcons.UIPerk_hack_reward"));
	Templates.AddItem(Part('LWX2_DisarmBomb', true, "img:///UILibrary_PerkIcons.UIPerk_hack_reward_debuff"));
	return Templates;
}

static function X2AbilityTemplate Part(name TemplateName, bool bBomb, string Icon)
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2Condition_LWX2BombPart Near;
	local X2Effect_LWX2BombPart Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.IconImage = Icon;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.INTERACT_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(Cost);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Near = new class'X2Condition_LWX2BombPart';
	Near.bBomb = bBomb;
	Template.AbilityShooterConditions.AddItem(Near);
	Effect = new class'X2Effect_LWX2BombPart';
	Effect.bBomb = bBomb;
	Template.AddShooterEffect(Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}
