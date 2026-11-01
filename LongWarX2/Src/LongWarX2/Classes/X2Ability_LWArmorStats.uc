// Long War's armours' numbers as XCOM 2 stat abilities (features/lw-gear.md, phase 2): HP, defence,
// will and mobility, and the immunities to fire and poison, for as long as the armour is worn; and Long War's item
// charges (X2Effect_LWCharges), every Long War soldier wearing a Long War armour.
class X2Ability_LWArmorStats extends X2Ability dependson(LWGearRules);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWGearRules.LWArmorDef A;

	foreach class'LWGearRules'.default.Armors(A)
		Templates.AddItem(Stats(A));
	return Templates;
}

static function name StatsFor(int Item)
{
	return name("LWArmorStats_" $ Item);
}

static function X2AbilityTemplate Stats(LWGearRules.LWArmorDef A)
{
	local X2AbilityTemplate Template;
	local X2Effect_PersistentStatChange Effect;
	local X2Effect_DamageImmunity Immunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, StatsFor(A.Item));
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_PersistentStatChange';
	Effect.BuildPersistentEffect(1, true, false, false);
	if (A.HP != 0)
		Effect.AddPersistentStatChange(eStat_HP, A.HP);
	if (A.Defense != 0)
		Effect.AddPersistentStatChange(eStat_Defense, A.Defense);
	if (A.Will != 0)
		Effect.AddPersistentStatChange(eStat_Will, A.Will);
	if (A.Mobility != 0)
		Effect.AddPersistentStatChange(eStat_Mobility, A.Mobility);
	Template.AddTargetEffect(Effect);

	if (A.FireImmune || A.PoisonImmune)
	{
		Immunity = new class'X2Effect_DamageImmunity';
		Immunity.BuildPersistentEffect(1, true, false, false);
		if (A.FireImmune)
			Immunity.ImmuneTypes.AddItem('Fire');
		if (A.PoisonImmune)
			Immunity.ImmuneTypes.AddItem('Poison');
		Template.AddTargetEffect(Immunity);
	}

	// Long War's item charges for the soldier's small items and perks.
	Template.AddTargetEffect(new class'X2Effect_LWCharges');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}
