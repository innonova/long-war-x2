// Long War's flight (features/lw-gear.md; EW's eAbility_Fly, XGUnit.ProcessFlightMode, CanSatisfyHoverRequirements) for
// Archangel and Seraph armour and the Hover SHIV, on XCOM 2's flying movement (the Archon's: over obstacles and up to
// roofs). The person's choice (2026-11-17): Long War's rules, though XCOM 2's soldiers have no flying animations and fly in
// their ground poses.
// - LWX2_Fly takes off: no action, one fuel, and only with two or more (CanSatisfyHoverRequirements); the fuel is the
//   ability's charges (the armour's or the deck's: 6), shown on its icon.
// - Flying (X2Effect_LWFlying): XCOM 2's flying traversal; each of the unit's turns that begins in the air costs one fuel,
//   and at none it comes down; immune to the bonus for being exposed (Long War's flying perk text), and air evasion in place
//   of cover (AIR_EVADE_DEF).
// - LWX2_Land comes down again, no action.
class X2Ability_LWFlight extends X2Ability dependson(LWGearRules, LWSHIVs);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Fly());
	Templates.AddItem(Land());
	return Templates;
}

static function X2AbilityTemplate Fly()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2AbilityCost_Charges ChargeCost;
	local X2AbilityCharges_LWFuel Charges;
	local X2Condition_LWFlight Condition;
	local X2Effect_LWFlying Flying;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_Fly');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_flying";
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Cost.bFreeCost = true;
	Template.AbilityCosts.AddItem(Cost);
	Charges = new class'X2AbilityCharges_LWFuel';
	Template.AbilityCharges = Charges;
	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Condition = new class'X2Condition_LWFlight';
	Condition.bWantFlying = false;
	Condition.MinFuel = 2;
	Template.AbilityShooterConditions.AddItem(Condition);
	Template.AddShooterEffectExclusions();
	Flying = new class'X2Effect_LWFlying';
	Flying.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	Flying.AddTraversalChange(eTraversal_Flying, true);
	Flying.AddTraversalChange(eTraversal_JumpUp, true);
	Flying.SetDisplayInfo(ePerkBuff_Bonus, "Flying", "Flying: over obstacles while the fuel lasts.", Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(Flying);
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

static function X2AbilityTemplate Land()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2Condition_LWFlight Condition;
	local X2Effect_RemoveEffects Remove;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_Land');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_flying";
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_UnitIsNotFlying');
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY + 1;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Cost.bFreeCost = true;
	Template.AbilityCosts.AddItem(Cost);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Condition = new class'X2Condition_LWFlight';
	Condition.bWantFlying = true;
	Template.AbilityShooterConditions.AddItem(Condition);
	Remove = new class'X2Effect_RemoveEffects';
	Remove.EffectNamesToRemove.AddItem(class'X2Effect_LWFlying'.default.EffectName);
	Template.AddTargetEffect(Remove);
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

/** The unit's fuel for a mission: its armour's (LWGearRules.Armors' Fuel), or its SHIV body's deck's. */
static function int MaxFuel(XComGameState_Unit Unit)
{
	local XComGameState_Item Armor;
	local LWSHIVs.LWSHIVBody B;
	local string T;
	local int k;

	if (Unit == none)
		return 0;
	if (class'LWSHIVs'.static.BodyForTemplate(Unit.GetMyTemplateName(), B))
		return B.Fly ? B.Fuel : 0;
	Armor = Unit.GetItemInSlot(eInvSlot_Armor);
	T = Armor != none ? string(Armor.GetMyTemplateName()) : "";
	// (Long War's armours are LWArmor_<item>.)
	if (Left(T, 8) != "LWArmor_")
		return 0;
	k = class'LWGearRules'.default.Armors.Find('Item', int(Mid(T, 8)));
	return (k != INDEX_NONE && class'LWGearRules'.default.Armors[k].Fly) ? class'LWGearRules'.default.Armors[k].Fuel : 0;
}
