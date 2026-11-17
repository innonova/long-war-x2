// Long War's weapons' mobility and defence while carried (features/lw-gear.md; their BalanceMods_Classic lines, "iDefense --
// defense, works only for weapons and items; iMobility -- mobility, works only for weapons/items", as
// XGTacticalGameCore.GetInventoryStatModifiers adds them): a stat ability on each weapon that has either, for as long as it is
// equipped. Shotguns +1 to +3, SMGs +3 and +4, LMGs and sniper rifles -1 and -2, the plasma pistol's defence +6.
class X2Ability_LWWeaponStats extends X2Ability dependson(LWGearRules);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWGearRules.LWWeaponDef W;

	foreach class'LWGearRules'.default.Weapons(W)
		if (W.Mobility != 0 || W.Defense != 0)
			Templates.AddItem(Stats(W));
	return Templates;
}

static function name StatsFor(int Item)
{
	return name("LWWeaponStats_" $ Item);
}

static function X2AbilityTemplate Stats(LWGearRules.LWWeaponDef W)
{
	local X2AbilityTemplate Template;
	local X2Effect_PersistentStatChange Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, StatsFor(W.Item));
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_PersistentStatChange';
	Effect.BuildPersistentEffect(1, true, false, false);
	if (W.Mobility != 0)
		Effect.AddPersistentStatChange(eStat_Mobility, W.Mobility);
	if (W.Defense != 0)
		Effect.AddPersistentStatChange(eStat_Defense, W.Defense);
	Template.AddTargetEffect(Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}
