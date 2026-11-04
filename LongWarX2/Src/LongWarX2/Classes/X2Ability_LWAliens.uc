// Long War's aliens' passives (features/lw-aliens.md): their damage bonus from the aliens' research, given to every alien
// template Long War's species fight as (LWAlienStats.AddAbilities); and species' own abilities XCOM 2 has nothing like
// (the Muton's Blood Call, the Drone's repair), given by species (LWAlienStats, +SpeciesAbilities). EW's numbers are its
// constants (XGTacticalGameCoreNativeBase), set here from the config.
class X2Ability_LWAliens extends X2Ability config(LWAliens);

/** Blood Call (EW's BLOODCALL_*): aim, will and mobility for the Muton's allies within BloodCallTiles, for its turn and the next. */
var config int BloodCallAim, BloodCallWill, BloodCallMobility, BloodCallTiles;
/** The Drone's repair (EW's DRONE_REPAIR_HP): a damaged robotic ally within RepairTiles. */
var config int RepairHP, RepairTiles;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AlienDamage());
	Templates.AddItem(BloodCall());
	Templates.AddItem(Repair());
	return Templates;
}

static function X2AbilityTemplate AlienDamage()
{
	local X2AbilityTemplate Template;
	local X2Effect_LWAlienDamage Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_AlienDamage');
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_LWAlienDamage';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.EffectName = 'LWX2_AlienDamage';
	Template.AddTargetEffect(Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

/** The Muton's Blood Call: its allies near it (and itself) gain aim, will and mobility; once a battle. */
static function X2AbilityTemplate BloodCall()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2AbilityCharges Charges;
	local X2AbilityCost_Charges ChargeCost;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Condition_UnitProperty Allies;
	local X2Effect_PersistentStatChange Called;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LW_BloodCall');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_bloodcall";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(Cost);
	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = 1;
	Template.AbilityCharges = Charges;
	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);
	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.BloodCallTiles * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	Radius.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = Radius;
	Allies = new class'X2Condition_UnitProperty';
	Allies.ExcludeHostileToSource = true;
	Allies.ExcludeFriendlyToSource = false;
	Allies.ExcludeDead = true;
	Allies.ExcludeCivilian = true;
	Template.AbilityMultiTargetConditions.AddItem(Allies);
	Called = new class'X2Effect_PersistentStatChange';
	Called.EffectName = 'LW_BloodCalled';
	Called.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnBegin);
	Called.AddPersistentStatChange(eStat_Offense, default.BloodCallAim);
	Called.AddPersistentStatChange(eStat_Will, default.BloodCallWill);
	Called.AddPersistentStatChange(eStat_Mobility, default.BloodCallMobility);
	Called.DuplicateResponse = eDupe_Refresh;
	Template.AddTargetEffect(Called);
	Template.AddMultiTargetEffect(Called);
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

/** The Drone's repair: a damaged robotic ally within RepairTiles regains RepairHP. */
static function X2AbilityTemplate Repair()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2Condition_UnitProperty Damaged;
	local X2Effect_ApplyMedikitHeal Heal;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LW_Repair');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_repair";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Defensive;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Cost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(Cost);
	Damaged = new class'X2Condition_UnitProperty';
	Damaged.ExcludeHostileToSource = true;
	Damaged.ExcludeFriendlyToSource = false;
	Damaged.ExcludeDead = true;
	Damaged.ExcludeOrganic = true;
	Damaged.ExcludeFullHealth = true;
	Damaged.RequireWithinRange = true;
	Damaged.WithinRange = default.RepairTiles * class'XComWorldData'.const.WORLD_StepSize;
	Damaged.FailOnNonUnits = true;
	Template.AbilityTargetConditions.AddItem(Damaged);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Heal = new class'X2Effect_ApplyMedikitHeal';
	Heal.PerUseHP = default.RepairHP;
	Template.AddTargetEffect(Heal);
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

