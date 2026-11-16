// A MEC suit's numbers while worn (features/lw-shivs-mecs.md): HP, defence, mobility, will, and the immunities to poison and
// fire every MEC suit has in Long War (eAP_MEC armours' properties).
class X2Ability_LWMECSuit extends X2Ability dependson(LWMECs);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWMECs.LWMECSuit S;

	foreach class'LWMECs'.default.Suits(S)
		Templates.AddItem(Stats(S));
	return Templates;
}

static function name StatsFor(int Item)
{
	return name("LWMECSuitStats_" $ Item);
}

static function X2AbilityTemplate Stats(LWMECs.LWMECSuit S)
{
	local X2AbilityTemplate Template;
	local X2Effect_PersistentStatChange Effect;
	local X2Effect_DamageImmunity Immunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, StatsFor(S.Item));
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	Template.bDisplayInUITooltip = false;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_PersistentStatChange';
	Effect.BuildPersistentEffect(1, true, false, false);
	if (S.HP != 0)
		Effect.AddPersistentStatChange(eStat_HP, S.HP);
	if (S.Defense != 0)
		Effect.AddPersistentStatChange(eStat_Defense, S.Defense);
	if (S.Will != 0)
		Effect.AddPersistentStatChange(eStat_Will, S.Will);
	if (S.Mobility != 0)
		Effect.AddPersistentStatChange(eStat_Mobility, S.Mobility);
	Template.AddTargetEffect(Effect);
	Immunity = new class'X2Effect_DamageImmunity';
	Immunity.BuildPersistentEffect(1, true, false, false);
	Immunity.ImmuneTypes.AddItem('Fire');
	Immunity.ImmuneTypes.AddItem('Poison');
	Template.AddTargetEffect(Immunity);
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}
