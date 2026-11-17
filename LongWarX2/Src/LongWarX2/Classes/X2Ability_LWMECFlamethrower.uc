// The MEC's flamethrower (features/lw-shivs-mecs.md; Long War's eItem_MecFlameThrower, its Weapons= line: 5 damage; EW's
// XGAction_FireCustom_Flamethrower, Long War's config: a sweep of 60 degrees over 8 tiles, setting fire with EW's chances by
// fire level, 1.0, 0.3 and 0.2): a cone from the MEC, every unit in it hurt and set burning, two charges an item. The flame
// never misses (EW sets fire along its sweep and burns what it reaches). The MEC plays its own firing animation (EW's
// flamethrower sweep is not among its converted ones).
class X2Ability_LWMECFlamethrower extends X2Ability config(LWGear);

var config float RangeTiles, SweepAngle;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Flamethrower());
	return Templates;
}

static function X2AbilityTemplate Flamethrower()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCost_Ammo AmmoCost;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2AbilityMultiTarget_Cone Cone;
	local X2Effect_ApplyFireToWorld FireToWorld;
	local X2Effect_ApplyWeaponDamage Damage;
	local float Range, Angle;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_MECFlamethrower');
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_flamethrower";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;
	Template.Hostility = eHostility_Offensive;
	Template.bDisplayInUITooltip = true;
	Template.bDisplayInUITacticalText = true;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Range = default.RangeTiles > 0 ? default.RangeTiles : 8.0;
	Angle = default.SweepAngle > 0 ? default.SweepAngle : 60.0;
	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.FixedAbilityRange = Range * 1.5;
	Template.AbilityTargetStyle = CursorTarget;
	Cone = new class'X2AbilityMultiTarget_Cone';
	Cone.ConeLength = Range * class'XComWorldData'.const.WORLD_StepSize;
	Cone.ConeEndDiameter = 2 * Range * Tan(Angle / 2 * DegToRad) * class'XComWorldData'.const.WORLD_StepSize;
	Cone.bExcludeSelfAsTargetIfWithinRadius = true;
	Template.AbilityMultiTargetStyle = Cone;
	Template.TargetingMethod = class'X2TargetingMethod_Cone';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityMultiTargetConditions.AddItem(default.LivingTargetOnlyProperty);

	FireToWorld = new class'X2Effect_ApplyFireToWorld';
	FireToWorld.bUseFireChanceLevel = true;
	FireToWorld.bDamageFragileOnly = true;
	FireToWorld.FireChance_Level1 = 1.0;
	FireToWorld.FireChance_Level2 = 0.3;
	FireToWorld.FireChance_Level3 = 0.2;
	FireToWorld.bCheckForLOSFromTargetLocation = false;
	Template.AddMultiTargetEffect(FireToWorld);
	Damage = new class'X2Effect_ApplyWeaponDamage';
	Damage.bExplosiveDamage = true;
	Damage.bApplyOnMiss = true;
	Template.AddMultiTargetEffect(Damage);
	Template.AddMultiTargetEffect(class'X2StatusEffects'.static.CreateBurningStatusEffect(1, 0));

	Template.bCheckCollision = true;
	Template.bAffectNeighboringTiles = true;
	Template.bFragileDamageOnly = true;
	Template.ActivationSpeech = 'Flamethrower';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}
