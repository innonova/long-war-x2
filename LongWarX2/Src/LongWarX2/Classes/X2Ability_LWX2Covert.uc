// The covert operative's hack of an EXALT comm relay (LWX2CovertExtraction): from beside an active relay, one action, one
// relay a turn. Given to the operative on a covert extraction (X2DownloadableContentInfo_LongWarX2's
// FinalizeUnitAbilitiesForInit). And the Chryssalid hive's transponder, for every soldier on the hive.
class X2Ability_LWX2Covert extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_HackRelay');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_comm_hack";
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
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_LWX2Relay');
	Template.AddShooterEffect(new class'X2Effect_LWX2Relay');
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Templates.AddItem(Template);

	// The Chryssalid hive's transponder (LWX2ChryssalidHive): any soldier beside it, one action, once the whale is seen.
	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_ActivateTransponder');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_comm_hack";
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
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_LWX2Transponder');
	Template.AddShooterEffect(new class'X2Effect_LWX2Transponder');
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Templates.AddItem(Template);

	// Progeny's Deluge: a bypass valve opened (LWX2Deluge), any soldier beside it, one action.
	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_OpenValve');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_comm_hack";
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
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_LWX2Valve');
	Template.AddShooterEffect(new class'X2Effect_LWX2Valve');
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Templates.AddItem(Template);
	return Templates;
}
