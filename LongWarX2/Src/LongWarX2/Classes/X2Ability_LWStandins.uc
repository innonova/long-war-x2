// Long War's perks that XCOM 2 has no ability of its own for (features/lw-classes.md): each
// with Long War's name, words and an icon; those whose bonuses are given (aim, critical chance,
// defence, damage, immunity to critical hits, mobility, each under a condition) work, through
// X2Effect_LWModifiers; the others are stand-ins without effect for now. The list is
// generated (scripts/classes-config.mjs).
class X2Ability_LWStandins extends X2Ability config(LWClasses);

struct LWStandin
{
	var name Name;
	var string Icon;
	var int Aim, Crit, Defense, Damage, DamagePct, CritAgainst, Mobility;
	var name AimIf, CritIf, DefenseIf, DamageIf;
	var float Param;
	var int MaxStacks;
	/** A free standard shot under this condition, once a turn (X2Effect_LWFreeShot); KeepOne: it costs one action. */
	var name FreeShotIf;
	var bool KeepOne;
};

var config array<LWStandin> Standins;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWStandin S;

	foreach default.Standins(S)
	{
		if (S.Aim != 0 || S.Crit != 0 || S.Defense != 0 || S.Damage != 0 || S.DamagePct != 0 || S.CritAgainst != 0 || S.Mobility != 0 || S.FreeShotIf != '')
			Templates.AddItem(Passive(S));
		else
			Templates.AddItem(PurePassive(S.Name, S.Icon, false, 'eAbilitySource_Perk', true));
	}
	return Templates;
}

/** A passive perk with its bonuses, shown in the soldier's perks. */
static function X2AbilityTemplate Passive(LWStandin S)
{
	local X2AbilityTemplate Template;
	local X2Effect_LWModifiers Effect;
	local X2Effect_PersistentStatChange Stats;
	local X2Effect_LWFreeShot Free;

	`CREATE_X2ABILITY_TEMPLATE(Template, S.Name);
	Template.IconImage = S.Icon;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_LWModifiers';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	Effect.EffectName = S.Name;
	Effect.Aim = S.Aim;
	Effect.AimIf = S.AimIf;
	Effect.Crit = S.Crit;
	Effect.CritIf = S.CritIf;
	Effect.Defense = S.Defense;
	Effect.DefenseIf = S.DefenseIf;
	Effect.Damage = S.Damage;
	Effect.DamageIf = S.DamageIf;
	Effect.CritAgainst = S.CritAgainst;
	Effect.DamagePct = S.DamagePct;
	Effect.Param = S.Param;
	Effect.MaxStacks = S.MaxStacks;
	Effect.Reason = Template.LocFriendlyName;
	Template.AddTargetEffect(Effect);

	if (S.FreeShotIf != '')
	{
		Free = new class'X2Effect_LWFreeShot';
		Free.BuildPersistentEffect(1, true, false, false);
		Free.EffectName = name(S.Name $ "_Free");
		Free.Condition = S.FreeShotIf;
		Free.Param = S.Param;
		Free.bKeepOne = S.KeepOne;
		Template.AddTargetEffect(Free);
	}

	if (S.Mobility != 0)
	{
		Stats = new class'X2Effect_PersistentStatChange';
		Stats.BuildPersistentEffect(1, true, false, false);
		Stats.AddPersistentStatChange(eStat_Mobility, S.Mobility);
		Template.AddTargetEffect(Stats);
		Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, S.Mobility);
	}

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}
