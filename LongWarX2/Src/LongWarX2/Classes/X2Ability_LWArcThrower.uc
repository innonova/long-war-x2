// Long War's arc thrower (features/lw-gear.md, phase 5): a shot at an alien close by that, if it stuns, takes it
// alive: off the field and home as Long War's captive (X2Effect_LWCapture, XComGameState_LWStrategy.PendingCaptives).
// One charge an arc thrower; the shot ends the soldier's turn as Long War's shots do. Never at robots, chryssalids,
// zombies (XGTacticalGameCore.CanBeStunned). Its chance: X2AbilityToHitCalc_LWStun.
class X2Ability_LWArcThrower extends X2Ability config(LWGear);

/** In tiles: Enemy Within's arc thrower is a short-range shot (APPROXIMATION, its range is not in its config). */
var config int ArcThrowerRange;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Stun());
	return Templates;
}

static function X2AbilityTemplate Stun()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionCost;
	local X2AbilityCost_Ammo AmmoCost;
	local X2Condition_UnitProperty Target;
	local X2Condition_LWStunnable Stunnable;
	local X2Condition_Visibility Visible;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWArcThrowerStun');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_stunstrike";
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;
	Template.Hostility = eHostility_Offensive;
	Template.bDisplayInUITooltip = true;
	Template.bDisplayInUITacticalText = true;
	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_LWStun';
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionCost = new class'X2AbilityCost_ActionPoints';
	ActionCost.iNumPoints = 1;
	ActionCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionCost);
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Target = new class'X2Condition_UnitProperty';
	Target.ExcludeDead = true;
	Target.ExcludeFriendlyToSource = true;
	Target.ExcludeRobotic = true;
	Target.ExcludeCivilian = true;
	Target.RequireWithinRange = true;
	Target.WithinRange = default.ArcThrowerRange * class'XComWorldData'.const.WORLD_StepSize;
	Template.AbilityTargetConditions.AddItem(Target);
	Stunnable = new class'X2Condition_LWStunnable';
	Template.AbilityTargetConditions.AddItem(Stunnable);
	Visible = new class'X2Condition_Visibility';
	Visible.bRequireGameplayVisible = true;
	Template.AbilityTargetConditions.AddItem(Visible);

	Template.AddTargetEffect(new class'X2Effect_LWCapture');
	Template.CustomFireAnim = 'FF_Melee';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

defaultproperties
{
}
