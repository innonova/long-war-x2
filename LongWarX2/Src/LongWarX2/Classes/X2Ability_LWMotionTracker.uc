// The Motion Tracker's radar (Long War's item 222 and its eAbility_TooCloseForComfort; features/lw-gear.md): Long War
// builds it as (XGAbilityTree.BuildAbilities) a self-targeted ability lasting one turn, a free action (eProp_CostNone) with
// a cooldown of one turn, its charges the item's (X2Effect_LWCharges: three, one more with Deep Pockets). Activated, the
// radar is on for the rest of the turn (LW_MotionTrackerActive): EW's radar on the tactical HUD shows the aliens,
// civilians and meld within its reach as blips, without showing the units themselves (UILWEWRadar).
class X2Ability_LWMotionTracker extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(MotionTracker());
	return Templates;
}

static function X2AbilityTemplate MotionTracker()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCost_Ammo AmmoCost;
	local X2AbilityCooldown Cooldown;
	local X2Effect_Persistent Active;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LW_MotionTracker');
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_battlescanner";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITooltip = true;
	Template.bDisplayInUITacticalText = true;

	// (A free action: eProp_CostNone.)
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 1;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// (The radar on for the rest of the turn: iDuration 1.)
	Active = new class'X2Effect_Persistent';
	Active.EffectName = 'LW_MotionTrackerActive';
	Active.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Active.DuplicateResponse = eDupe_Refresh;
	Template.AddTargetEffect(Active);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}
