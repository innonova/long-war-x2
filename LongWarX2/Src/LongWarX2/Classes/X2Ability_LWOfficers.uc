// Long War's officers in a mission (features/lw-officers.md), on every soldier (LWOfficers.AddAbilities), acting by what
// was marked at launch (LWOfficers.MarkSquad): the squad's officer powers on each soldier; the leader's Command (EW's War
// Cry, Long War's: a move for a soldier in sight whose turn is done) and Lead By Example (nearby soldiers take the leader's
// will when theirs is lower).
class X2Ability_LWOfficers extends X2Ability config(LWStrategy);

/** Lead By Example's reach, in tiles (Long War's "nearby", the officer's native radius: Fortiores Una's text, 8 tiles). */
var config int LeadRadiusTiles;
/** Command's reach (sight range, EW's 27) and cooldown, in XCOM 2's turns (EW's 10 half-turns). */
var config int CommandRangeTiles;
var config int CommandCooldown;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(OfficerPowers());
	Templates.AddItem(Command());
	Templates.AddItem(LeadByExample());
	return Templates;
}

static function X2AbilityTemplate OfficerPowers()
{
	local X2AbilityTemplate Template;
	local X2Effect_LWOfficerPowers Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_OfficerPowers');
	// (A rule's carrier, not a perk: not listed among the soldier's abilities in the armory.)
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_command";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_LWOfficerPowers';
	Effect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(Effect);
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

static function X2AbilityTemplate Command()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionCost;
	local X2AbilityCost_Charges ChargeCost;
	local X2AbilityCooldown Cooldown;
	local X2Condition_LWOfficer Leader, Target;
	local X2Condition_UnitProperty Ally;
	local X2Condition_Visibility Visible;
	local X2Effect_GrantActionPoints Move;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_Command');
	Template.LocFriendlyName = class'LWOfficers'.default.Command;
	Template.LocLongDescription = class'LWOfficers'.default.CommandDesc;
	Template.LocHelpText = class'LWOfficers'.default.CommandDesc;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_command";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	// Only the leader sees it.
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_AbilityUnavailable');
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITooltip = true;
	Template.bDisplayInUITacticalText = true;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionCost = new class'X2AbilityCost_ActionPoints';
	ActionCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionCost);
	Template.AbilityCharges = new class'X2AbilityCharges_LWOfficer';
	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.CommandCooldown;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Leader = new class'X2Condition_LWOfficer';
	Leader.Kind = 'Leader';
	Template.AbilityShooterConditions.AddItem(Leader);
	Template.AddShooterEffectExclusions();
	Ally = new class'X2Condition_UnitProperty';
	Ally.ExcludeDead = true;
	Ally.ExcludeHostileToSource = true;
	Ally.ExcludeFriendlyToSource = false;
	Ally.ExcludeRobotic = true;
	Ally.ExcludeCivilian = true;
	Ally.RequireSquadmates = true;
	Ally.RequireWithinRange = true;
	Ally.WithinRange = default.CommandRangeTiles * class'XComWorldData'.const.WORLD_StepSize;
	Template.AbilityTargetConditions.AddItem(Ally);
	Target = new class'X2Condition_LWOfficer';
	Target.Kind = 'CommandTarget';
	Template.AbilityTargetConditions.AddItem(Target);
	Visible = new class'X2Condition_Visibility';
	Visible.bRequireGameplayVisible = true;
	Template.AbilityTargetConditions.AddItem(Visible);

	Move = new class'X2Effect_GrantActionPoints';
	Move.NumActionPoints = 1;
	Move.PointType = class'X2CharacterTemplateManager'.default.MoveActionPoint;
	Template.AddTargetEffect(Move);
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

static function X2AbilityTemplate LeadByExample()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener Begun, Ended;
	local X2Condition_LWOfficer Leader, Near;
	local X2Effect_RemoveEffects Remove;
	local X2Effect_LWLeadByExample Will;
	local X2AbilityMultiTarget_AllAllies Allies;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_LeadByExample');
	Template.LocFriendlyName = class'LWOfficers'.default.LeadByExample;
	Template.LocLongDescription = class'LWOfficers'.default.LeadByExampleDesc;
	Template.LocHelpText = class'LWOfficers'.default.LeadByExampleDesc;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_command";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Allies = new class'X2AbilityMultiTarget_AllAllies';
	Template.AbilityMultiTargetStyle = Allies;
	// At the mission's start, and as each XCOM turn begins and ends (before the aliens' turn, when will is tested).
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Begun = new class'X2AbilityTrigger_EventListener';
	Begun.ListenerData.Deferral = ELD_OnStateSubmitted;
	Begun.ListenerData.EventID = 'PlayerTurnBegun';
	Begun.ListenerData.Filter = eFilter_Player;
	Begun.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Begun);
	Ended = new class'X2AbilityTrigger_EventListener';
	Ended.ListenerData.Deferral = ELD_OnStateSubmitted;
	Ended.ListenerData.EventID = 'PlayerTurnEnded';
	Ended.ListenerData.Filter = eFilter_Player;
	Ended.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Ended);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Leader = new class'X2Condition_LWOfficer';
	Leader.Kind = 'Leader';
	Template.AbilityShooterConditions.AddItem(Leader);

	// The last one taken off every ally, then given again to those near.
	Remove = new class'X2Effect_RemoveEffects';
	Remove.EffectNamesToRemove.AddItem('LWX2_LeadByExampleWill');
	Template.AddMultiTargetEffect(Remove);
	Will = new class'X2Effect_LWLeadByExample';
	Will.BuildPersistentEffect(1, true, false, false);
	Near = new class'X2Condition_LWOfficer';
	Near.Kind = 'Near';
	Near.Tiles = default.LeadRadiusTiles;
	Will.TargetConditions.AddItem(Near);
	Template.AddMultiTargetEffect(Will);
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

defaultproperties
{
}
