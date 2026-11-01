// Long War's passive small items as XCOM 2 stat abilities (features/lw-gear.md, phase 5): aim, crit and HP while
// carried, and what X2Effect_LWSmallItem does (ammo, rockets, the Chameleon Suit).
class X2Ability_LWSmallItems extends X2Ability dependson(LWGearRules);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWGearRules.LWSmallDef D;

	foreach class'LWGearRules'.default.SmallItems(D)
		if (D.Kind == 'Passive' || D.Kind == 'Rocket')
			Templates.AddItem(Stats(D));
	return Templates;
}

static function name StatsFor(int Item)
{
	return name("LWSmallStats_" $ Item);
}

static function X2AbilityTemplate Stats(LWGearRules.LWSmallDef D)
{
	local X2AbilityTemplate Template;
	local X2Effect_PersistentStatChange Effect;
	local X2Effect_LWSmallItem Extra;

	`CREATE_X2ABILITY_TEMPLATE(Template, StatsFor(D.Item));
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	if (D.Aim != 0 || D.Crit != 0 || D.HP != 0)
	{
		Effect = new class'X2Effect_PersistentStatChange';
		Effect.BuildPersistentEffect(1, true, false, false);
		if (D.Aim != 0)
			Effect.AddPersistentStatChange(eStat_Offense, D.Aim);
		if (D.Crit != 0)
			Effect.AddPersistentStatChange(eStat_CritChance, D.Crit);
		if (D.HP != 0)
			Effect.AddPersistentStatChange(eStat_HP, D.HP);
		Template.AddTargetEffect(Effect);
	}
	if (D.Ammo > 1 || D.Kind == 'Rocket' || D.CritAgainstReaction != 0)
	{
		Extra = new class'X2Effect_LWSmallItem';
		Extra.BuildPersistentEffect(1, true, false, false);
		Extra.EffectName = name("LWSmallItem_" $ D.Item);
		Extra.AmmoMultiplier = D.Ammo;
		Extra.ExtraRockets = D.Kind == 'Rocket' ? 1 : 0;
		Extra.CritAgainstReaction = D.CritAgainstReaction;
		Template.AddTargetEffect(Extra);
	}
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}
