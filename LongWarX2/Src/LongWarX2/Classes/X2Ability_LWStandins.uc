// Long War's perks that XCOM 2 has no ability of its own for (features/lw-classes.md): each
// with Long War's name, words and an icon; those whose bonuses are given (aim, critical chance,
// defence, damage, immunity to critical hits, mobility, each under a condition) work, through
// X2Effect_LWModifiers; the others are stand-ins without effect for now. The list is
// generated (scripts/classes-config.mjs).
class X2Ability_LWStandins extends X2Ability config(LWClasses) dependson(LWGearRules);

struct LWStandin
{
	var name Name;
	var string Icon;
	var int Aim, Crit, Defense, Damage, DamagePct, CritAgainst, Mobility;
	var name AimIf, CritIf, DefenseIf, DamageIf;
	/** A second damage bonus under its own condition (Mayhem: explosives, and the Gunner's shots). */
	var int Damage2;
	var name Damage2If;
	/** Damage taken less (Will to Survive); crit damage more, a share of the weapon's (Killer Instinct). */
	var int DamageTaken;
	var name DamageTakenIf;
	var int CritDamagePct;
	var name CritDamageIf;
	/** Tiles more for the rocket launcher's blast (Danger Zone; X2DownloadableContentInfo adds it to the ability). */
	var float BonusRadius;
	var float Param;
	var int MaxStacks;
	/** A free standard shot under this condition, once a turn (X2Effect_LWFreeShot); KeepOne: it costs one action. */
	var name FreeShotIf;
	var bool KeepOne;
	/** Not a passive: SnapShot (a one-action shot with the weapon, Aim as its built-in modifier). */
	var name Kind;
	/** Immunities (Panic …), as XCOM 2's damage immunity effect has them. */
	var array<name> ImmuneTo;
	/** Hit points more per medikit use (Savior; added to XCOM 2's medikit abilities: AddHealBonuses). */
	var int Heal;
	/** In the cloud of the soldier's smoke grenades: defence, critical chance, will more (Dense Smoke, Combat Drugs: AddSmokeBonuses). */
	var int SmokeDefense, SmokeCrit, SmokeWill;
};

var config array<LWStandin> Standins;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWStandin S;

	foreach default.Standins(S)
	{
		if (S.Kind == 'SnapShot')
			Templates.AddItem(SnapShot(S));
		else if (S.Kind == 'PrecisionShot' || S.Kind == 'DisablingShot')
			Templates.AddItem(ActiveShot(S));
		else if (S.Aim != 0 || S.Crit != 0 || S.Defense != 0 || S.Damage != 0 || S.Damage2 != 0 || S.DamageTaken != 0 || S.CritDamagePct != 0 || S.BonusRadius != 0 || S.DamagePct != 0 || S.CritAgainst != 0 || S.Mobility != 0 || S.FreeShotIf != '' || S.ImmuneTo.Length > 0)
			Templates.AddItem(Passive(S));
		else
			Templates.AddItem(PurePassive(S.Name, S.Icon, false, 'eAbilitySource_Perk', true));
	}
	return Templates;
}

/**
 * Long War's Snap Shot for the sniper classes: a shot with one action (XCOM 2's sniper rifle needs
 * both), at Long War's aim penalty; the full shot stays as it is.
 */
static function X2AbilityTemplate SnapShot(LWStandin S)
{
	local X2AbilityTemplate Template;
	local X2AbilityToHitCalc_StandardAim Aim;

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot(S.Name);
	Template.IconImage = S.Icon;
	Template.bDontDisplayInAbilitySummary = false;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_SHOT_PRIORITY + 1;
	Aim = new class'X2AbilityToHitCalc_StandardAim';
	Aim.BuiltInHitMod = S.Aim;
	Template.AbilityToHitCalc = Aim;
	return Template;
}

/**
 * Long War's Precision Shot (more critical chance, more damage on a critical hit) and Disabling Shot (the target's
 * weapon emptied: XCOM 2's X2Effect_DisableWeapon; no critical hits): shots with the weapon beside the standard one,
 * Param their cooldown.
 */
static function X2AbilityTemplate ActiveShot(LWStandin S)
{
	local X2AbilityTemplate Template;
	local X2AbilityToHitCalc_StandardAim Aim;
	local X2Effect_ApplyWeaponDamage Bonus;
	local X2AbilityCooldown Cooldown;

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot(S.Name);
	Template.IconImage = S.Icon;
	Template.bDontDisplayInAbilitySummary = false;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_SHOT_PRIORITY + 2;
	Aim = new class'X2AbilityToHitCalc_StandardAim';
	Aim.BuiltInHitMod = S.Aim;
	Aim.BuiltInCritMod = S.Crit;
	if (S.Kind == 'DisablingShot')
	{
		Aim.bAllowCrit = false;
		Template.AddTargetEffect(new class'X2Effect_DisableWeapon');
	}
	if (S.Kind == 'PrecisionShot' && S.Damage > 0)
	{
		// Damage on a critical hit only: no base damage of its own.
		Bonus = new class'X2Effect_ApplyWeaponDamage';
		Bonus.bIgnoreBaseDamage = true;
		Bonus.EffectDamageValue.Crit = S.Damage;
		Template.AddTargetEffect(Bonus);
	}
	Template.AbilityToHitCalc = Aim;
	Template.AbilityTargetConditions.AddItem(new class'X2Condition_LWSniperReady');
	if (S.Param > 0)
	{
		Cooldown = new class'X2AbilityCooldown';
		Cooldown.iNumTurns = S.Param;
		Template.AbilityCooldown = Cooldown;
	}
	return Template;
}

/** A passive perk with its bonuses, shown in the soldier's perks. */
static function X2AbilityTemplate Passive(LWStandin S)
{
	local X2AbilityTemplate Template;
	local X2Effect_LWModifiers Effect;
	local X2Effect_PersistentStatChange Stats;
	local X2Effect_LWFreeShot Free;
	local X2Effect_DamageImmunity Immunity;
	local name Immune;

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
	Effect.Damage2 = S.Damage2;
	Effect.Damage2If = S.Damage2If;
	Effect.DamageTaken = S.DamageTaken;
	Effect.DamageTakenIf = S.DamageTakenIf;
	Effect.CritDamagePct = S.CritDamagePct;
	Effect.CritDamageIf = S.CritDamageIf;
	Effect.CritAgainst = S.CritAgainst;
	Effect.DamagePct = S.DamagePct;
	Effect.Param = S.Param;
	Effect.MaxStacks = S.MaxStacks;
	Effect.Reason = Template.LocFriendlyName;
	Template.AddTargetEffect(Effect);

	if (S.ImmuneTo.Length > 0)
	{
		Immunity = new class'X2Effect_DamageImmunity';
		Immunity.BuildPersistentEffect(1, true, false, false);
		foreach S.ImmuneTo(Immune)
			Immunity.ImmuneTypes.AddItem(Immune);
		Template.AddTargetEffect(Immunity);
	}

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

/** Savior and its like: XCOM 2's medikit abilities heal more for a soldier with the perk (OnPostTemplatesCreated). */
static function AddHealBonuses()
{
	local X2AbilityTemplateManager Manager;
	local X2AbilityTemplate Medikit;
	local X2Effect_ApplyMedikitHeal Heal;
	local X2Condition_AbilityProperty Owner;
	local LWStandin S;
	local name Ability;
	local array<name> Medikits;

	Medikits.AddItem('MedikitHeal');
	Medikits.AddItem('NanoMedikitHeal');
	Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach Medikits(Ability)
	{
		Medikit = Manager.FindAbilityTemplate(Ability);
		if (Medikit == none)
			continue;
		foreach default.Standins(S)
			if (S.Heal != 0)
			{
				Heal = new class'X2Effect_ApplyMedikitHeal';
				Heal.PerUseHP = S.Heal;
				Owner = new class'X2Condition_AbilityProperty';
				Owner.OwnerHasSoldierAbilities.AddItem(S.Name);
				Heal.TargetConditions.AddItem(Owner);
				Medikit.AddTargetEffect(Heal);
			}
	}
}

/** Dense Smoke and Combat Drugs: Long War's smoke grenades give more in their cloud when the thrower has the perk (OnPostTemplatesCreated). */
static function AddSmokeBonuses()
{
	local X2ItemTemplateManager Manager;
	local array<X2DataTemplate> Variants;
	local X2DataTemplate Data;
	local X2GrenadeTemplate Grenade;
	local LWGearRules.LWSmallDef D;
	local LWStandin S;
	local X2Effect_LWSmoke Smoke;
	local X2Condition_AbilityProperty Owner;

	Manager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach class'LWGearRules'.default.SmallItems(D)
	{
		if (D.Look != 'SmokeGrenade')
			continue;
		Manager.FindDataTemplateAllDifficulties(D.Template, Variants);
		foreach Variants(Data)
		{
			Grenade = X2GrenadeTemplate(Data);
			if (Grenade == none)
				continue;
			foreach default.Standins(S)
				if (S.SmokeDefense != 0 || S.SmokeCrit != 0 || S.SmokeWill != 0)
				{
					Smoke = class'X2Effect_LWSmoke'.static.Make(S.Name, S.SmokeDefense, S.SmokeCrit, S.SmokeWill);
					Owner = new class'X2Condition_AbilityProperty';
					Owner.OwnerHasSoldierAbilities.AddItem(S.Name);
					Smoke.TargetConditions.AddItem(Owner);
					Grenade.ThrownGrenadeEffects.AddItem(Smoke);
					Grenade.LaunchedGrenadeEffects.AddItem(Smoke);
				}
		}
	}
}

/** Danger Zone and its like: the rocket launcher's blast wider for a soldier with the perk (OnPostTemplatesCreated). */
static function AddBonusRadii()
{
	local X2AbilityTemplateManager Manager;
	local X2AbilityTemplate Rocket;
	local X2AbilityMultiTarget_Radius Radius;
	local LWStandin S;

	Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Rocket = Manager.FindAbilityTemplate('RocketLauncher');
	Radius = Rocket != none ? X2AbilityMultiTarget_Radius(Rocket.AbilityMultiTargetStyle) : none;
	if (Radius == none)
		return;
	foreach default.Standins(S)
		if (S.BonusRadius != 0)
			Radius.AddAbilityBonusRadius(S.Name, S.BonusRadius);
}
