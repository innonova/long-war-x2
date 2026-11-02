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
	/** Damage taken more (%) for ShredTurns turns by a unit this soldier hits with an LMG, a SAW or a rocket (Shredder Ammo: AddShredders). */
	var int ShredPct, ShredTurns;
	/** A psi power in missions (X2Ability_LWPsi): which; the will check's base; a second number (turns); its radius (tiles); will given. */
	var name PsiKind;
	var int Base, Param2, Will;
	var float Radius;
	/** Hit points more from a medikit used on this soldier (Smart Macrophages: AddHealBonuses); regenerated a turn (Adaptive Bone Marrow). */
	var int HealTaken, Regen;
	/** Secondary Heart: bleeding out instead of dying once a mission, these turns more (X2Effect_LWSecondaryHeart). */
	var int BleedTurns;
	/** Revive: a medikit's stabilize brings the soldier back at this % of their health (AddHealBonuses). */
	var int Revive;
	/** Will more against psi attacks, the aliens' too (Neural Damping: X2AbilityToHitCalc_LWPsiCheck, AddPsiChecks). */
	var int PsiWill;
};

var config array<LWStandin> Standins;

/** Long War's psi powers: the ability each gives (features/lw-psi.md). */
struct LWPsiAbility
{
	var int Perk;
	var name Ability;
};
var config array<LWPsiAbility> PsiAbilities;
/** Long War's gene mods: the ability each gives (features/lw-genemods.md). */
var config array<LWPsiAbility> GeneAbilities;

static function name GeneAbilityFor(int Perk)
{
	local int k;

	k = default.GeneAbilities.Find('Perk', Perk);
	return k == INDEX_NONE ? '' : default.GeneAbilities[k].Ability;
}

/** A power's name as the player reads it (the ability's). */
static function string PsiPowerName(name Ability)
{
	local X2AbilityTemplate Template;

	Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Ability);
	return (Template != none && Template.LocFriendlyName != "") ? Template.LocFriendlyName : string(Ability);
}

static function name PsiAbilityFor(int Perk)
{
	local int k;

	k = default.PsiAbilities.Find('Perk', Perk);
	return k == INDEX_NONE ? '' : default.PsiAbilities[k].Ability;
}

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWStandin S;

	foreach default.Standins(S)
	{
		if (S.Kind == 'SnapShot')
			Templates.AddItem(SnapShot(S));
		else if (S.Kind == 'PrecisionShot' || S.Kind == 'DisablingShot' || S.Kind == 'Flush')
		{
			Templates.AddItem(ActiveShot(S));
			// Flush's reduced damage: a passive of its own (the shooter's damage modifier on that shot).
			if (S.Kind == 'Flush')
				Templates.AddItem(Passive(FlushDamage(S)));
		}
		else if (S.Kind == 'CloseCombat')
			Templates.AddItem(CloseCombatShot(S));
		else if (S.PsiKind != '')
			Templates.AddItem(PsiPower(S));
		else if (S.Kind == 'Adrenal')
			Templates.AddItem(Adrenal(S));
		else if (S.Kind == 'Biofield')
			Templates.AddItem(Biofield(S));
		else if (S.Aim != 0 || S.Crit != 0 || S.Defense != 0 || S.Damage != 0 || S.Damage2 != 0 || S.DamageTaken != 0 || S.CritDamagePct != 0 || S.BonusRadius != 0 || S.DamagePct != 0 || S.CritAgainst != 0 || S.Mobility != 0 || S.FreeShotIf != '' || S.ImmuneTo.Length > 0 || S.HealTaken != 0 || S.Regen != 0 || S.BleedTurns != 0)
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
	local X2AbilityCost Cost;

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
	// Flush: two shots' ammo, and the damage passive with it.
	if (S.Kind == 'Flush')
	{
		foreach Template.AbilityCosts(Cost)
			if (X2AbilityCost_Ammo(Cost) != none)
				X2AbilityCost_Ammo(Cost).iAmmo = 2;
		Template.AdditionalAbilities.AddItem(name(S.Name $ "_Damage"));
	}
	if (S.Param > 0)
	{
		Cooldown = new class'X2AbilityCooldown';
		Cooldown.iNumTurns = S.Param;
		Template.AbilityCooldown = Cooldown;
	}
	return Template;
}

/**
 * Long War's Close Combat Specialist: a reaction shot with the weapon at an enemy who moves or acts within Param
 * tiles, without overwatch, once a turn for each enemy (as XCOM 2's Bladestorm, with a shot).
 */
static function X2AbilityTemplate CloseCombatShot(LWStandin S)
{
	local X2AbilityTemplate Template;
	local X2AbilityToHitCalc_StandardAim Aim;
	local X2AbilityTrigger_EventListener Trigger;
	local X2Condition_Visibility Visible;
	local X2Condition_UnitProperty Near, NotSquadmates;
	local X2AbilityCost_Ammo Ammo;
	local X2Effect_Persistent Marked;
	local X2Condition_UnitEffectsWithAbilitySource NotMarked;

	`CREATE_X2ABILITY_TEMPLATE(Template, S.Name);
	Template.IconImage = S.Icon;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Offensive;
	Aim = new class'X2AbilityToHitCalc_StandardAim';
	Aim.bReactionFire = true;
	Template.AbilityToHitCalc = Aim;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'ObjectMoved';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.TypicalOverwatchListener;
	Template.AbilityTriggers.AddItem(Trigger);
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.TypicalAttackListener;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	Visible = new class'X2Condition_Visibility';
	Visible.bRequireGameplayVisible = true;
	Visible.bRequireBasicVisibility = true;
	Visible.bDisablePeeksOnMovement = true;
	Template.AbilityTargetConditions.AddItem(Visible);
	Near = new class'X2Condition_UnitProperty';
	Near.RequireWithinRange = true;
	Near.WithinRange = S.Param * class'XComWorldData'.const.WORLD_StepSize;
	Template.AbilityTargetConditions.AddItem(Near);
	Template.AbilityTargetConditions.AddItem(class'X2Ability_DefaultAbilitySet'.static.OverwatchTargetEffectsCondition());
	NotSquadmates = new class'X2Condition_UnitProperty';
	NotSquadmates.ExcludeSquadmates = true;
	Template.AbilityTargetConditions.AddItem(NotSquadmates);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Ammo = new class'X2AbilityCost_Ammo';
	Ammo.iAmmo = 1;
	Template.AbilityCosts.AddItem(Ammo);
	Template.bAllowBonusWeaponEffects = true;
	Template.AddTargetEffect(new class'X2Effect_ApplyWeaponDamage');

	// Once a turn for each enemy, hit or miss (as Bladestorm marks its targets).
	Marked = new class'X2Effect_Persistent';
	Marked.BuildPersistentEffect(1, false, true, true, eGameRule_PlayerTurnEnd);
	Marked.EffectName = 'LWCloseCombatTarget';
	Marked.bApplyOnMiss = true;
	Template.AddTargetEffect(Marked);
	NotMarked = new class'X2Condition_UnitEffectsWithAbilitySource';
	NotMarked.AddExcludeEffect('LWCloseCombatTarget', 'AA_DuplicateEffectIgnored');
	Template.AbilityTargetConditions.AddItem(NotMarked);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = OverwatchShot_BuildVisualization;
	Template.bShowActivation = true;
	return Template;
}

/**
 * Long War's psi powers in missions (features/lw-psi.md, step 2), built for the stand-ins whose Kind is Psi
 * (CreateTemplates): a will check, the soldier's will against the target's (XCOM 2's StatCheck_UnitVsUnit:
 * Base + will - will), and XCOM 2's status effects.
 * - Mindfray: disoriented (XCOM 2's), and Damage base damage; robots immune.
 * - Panic: panicked (XCOM 2's); robots immune.
 * - Mind Control: controlled for Param2 turns (XCOM 2's); robots immune.
 * - Inspiration: allies within Radius tiles of the place chosen lose disorientation and panic and gain Will for
 *   Param2 turns.
 * The soldier has no psi animations: the powers show their effects without a firing animation.
 */
static function X2AbilityTemplate PsiPower(LWStandin S)
{
	local X2AbilityTemplate Template;
	local X2AbilityToHitCalc_StatCheck_UnitVsUnit Check;
	local X2AbilityCost_ActionPoints Cost;
	local X2AbilityCooldown Cooldown;
	local X2Condition_UnitProperty Living;
	local X2Effect_ApplyWeaponDamage Damage;
	local X2AbilityTarget_Cursor Cursor;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Effect_RemoveEffects Calm;
	local X2Effect_PersistentStatChange Will;
	local X2Effect_LWModifiers Merge;

	`CREATE_X2ABILITY_TEMPLATE(Template, S.Name);
	Template.IconImage = S.Icon;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Cost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(Cost);
	if (S.Param > 0)
	{
		Cooldown = new class'X2AbilityCooldown';
		Cooldown.iNumTurns = S.Param;
		Template.AbilityCooldown = Cooldown;
	}
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	// Mind Merge: an ally gains Crit critical chance and takes DamageTaken less damage until the psion's next turn.
	if (S.PsiKind == 'MindMerge')
	{
		Template.Hostility = eHostility_Defensive;
		Template.AbilityToHitCalc = default.DeadEye;
		Template.AbilityTargetStyle = default.SimpleSingleTarget;
		Living = new class'X2Condition_UnitProperty';
		Living.ExcludeHostileToSource = true;
		Living.ExcludeFriendlyToSource = false;
		Living.ExcludeDead = true;
		Living.ExcludeRobotic = true;
		Living.RequireSquadmates = true;
		Living.FailOnNonUnits = true;
		Template.AbilityTargetConditions.AddItem(Living);
		Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
		Merge = new class'X2Effect_LWModifiers';
		Merge.EffectName = name(S.Name $ "_Merged");
		Merge.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
		Merge.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
		Merge.Crit = S.Crit;
		Merge.DamageTaken = S.DamageTaken;
		Merge.Reason = Template.LocFriendlyName;
		Merge.DuplicateResponse = eDupe_Refresh;
		Template.AddTargetEffect(Merge);
		return Template;
	}
	// Psychokinetic Strike: cover destroyed within Radius tiles of the place chosen, no unit harmed.
	if (S.PsiKind == 'PsychokineticStrike')
	{
		Template.Hostility = eHostility_Neutral;
		Template.AbilityToHitCalc = default.DeadEye;
		Cursor = new class'X2AbilityTarget_Cursor';
		Template.AbilityTargetStyle = Cursor;
		Radius = new class'X2AbilityMultiTarget_Radius';
		Radius.fTargetRadius = S.Radius * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
		Template.AbilityMultiTargetStyle = Radius;
		Template.TargetingMethod = class'X2TargetingMethod_VoidRift';
		Damage = new class'X2Effect_ApplyWeaponDamage';
		Damage.bIgnoreBaseDamage = true;
		Damage.EnvironmentalDamageAmount = S.Param2;
		Damage.bApplyOnHit = true;
		Damage.bApplyOnMiss = true;
		Template.AddMultiTargetEffect(Damage);
		return Template;
	}
	// Telekinetic Field: allies within Radius tiles of the psion gain Defense until its next turn.
	if (S.PsiKind == 'TKField')
	{
		Template.Hostility = eHostility_Neutral;
		Template.AbilityToHitCalc = default.DeadEye;
		Template.AbilityTargetStyle = default.SelfTarget;
		Radius = new class'X2AbilityMultiTarget_Radius';
		Radius.fTargetRadius = S.Radius * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
		Radius.bIgnoreBlockingCover = true;
		Radius.bExcludeSelfAsTargetIfWithinRadius = false;
		Template.AbilityMultiTargetStyle = Radius;
		Living = new class'X2Condition_UnitProperty';
		Living.ExcludeHostileToSource = true;
		Living.ExcludeFriendlyToSource = false;
		Living.ExcludeDead = true;
		Template.AbilityMultiTargetConditions.AddItem(Living);
		Will = new class'X2Effect_PersistentStatChange';
		Will.EffectName = name(S.Name $ "_Defense");
		Will.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
		Will.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
		Will.AddPersistentStatChange(eStat_Defense, S.Defense);
		Will.DuplicateResponse = eDupe_Refresh;
		Template.AddShooterEffect(Will);
		Template.AddMultiTargetEffect(Will);
		return Template;
	}
	// Rift: Damage psi damage to every unit within Radius tiles of the place chosen.
	if (S.PsiKind == 'Rift')
	{
		Template.Hostility = eHostility_Offensive;
		Template.AbilityToHitCalc = default.DeadEye;
		Cursor = new class'X2AbilityTarget_Cursor';
		Template.AbilityTargetStyle = Cursor;
		Radius = new class'X2AbilityMultiTarget_Radius';
		Radius.fTargetRadius = S.Radius * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
		Template.AbilityMultiTargetStyle = Radius;
		Template.TargetingMethod = class'X2TargetingMethod_VoidRift';
		Damage = new class'X2Effect_ApplyWeaponDamage';
		Damage.bIgnoreBaseDamage = true;
		Damage.EffectDamageValue.Damage = S.Damage;
		Damage.EffectDamageValue.DamageType = 'Psi';
		Damage.bExplosiveDamage = true;
		Template.AddMultiTargetEffect(Damage);
		return Template;
	}

	if (S.PsiKind == 'Inspiration')
	{
		Template.Hostility = eHostility_Neutral;
		Template.AbilityToHitCalc = default.DeadEye;
		Cursor = new class'X2AbilityTarget_Cursor';
		Cursor.bRestrictToSquadsightRange = true;
		Template.AbilityTargetStyle = Cursor;
		Radius = new class'X2AbilityMultiTarget_Radius';
		Radius.fTargetRadius = S.Radius * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
		Radius.bIgnoreBlockingCover = true;
		Template.AbilityMultiTargetStyle = Radius;
		Template.TargetingMethod = class'X2TargetingMethod_GremlinAOE';
		Living = new class'X2Condition_UnitProperty';
		Living.ExcludeHostileToSource = true;
		Living.ExcludeFriendlyToSource = false;
		Living.ExcludeDead = true;
		Template.AbilityMultiTargetConditions.AddItem(Living);
		Calm = new class'X2Effect_RemoveEffects';
		Calm.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
		Calm.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.PanickedName);
		Template.AddMultiTargetEffect(Calm);
		Will = new class'X2Effect_PersistentStatChange';
		Will.EffectName = name(S.Name $ "_Will");
		Will.BuildPersistentEffect(S.Param2, false, true, false, eGameRule_PlayerTurnBegin);
		Will.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
		Will.AddPersistentStatChange(eStat_Will, S.Will);
		Will.DuplicateResponse = eDupe_Refresh;
		Template.AddMultiTargetEffect(Will);
		return Template;
	}

	Template.Hostility = eHostility_Offensive;
	Check = new class'X2AbilityToHitCalc_StatCheck_UnitVsUnit';
	Check.AttackerStat = eStat_Will;
	Check.DefenderStat = eStat_Will;
	Check.BaseValue = S.Base;
	Template.AbilityToHitCalc = Check;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Living = new class'X2Condition_UnitProperty';
	Living.ExcludeRobotic = true;
	Living.FailOnNonUnits = true;
	Template.AbilityTargetConditions.AddItem(Living);
	switch (S.PsiKind)
	{
	case 'Mindfray':
		Template.AddTargetEffect(class'X2StatusEffects'.static.CreateDisorientedStatusEffect());
		if (S.Damage > 0)
		{
			Damage = new class'X2Effect_ApplyWeaponDamage';
			Damage.bIgnoreBaseDamage = true;
			Damage.EffectDamageValue.Damage = S.Damage;
			Damage.EffectDamageValue.DamageType = 'Psi';
			Template.AddTargetEffect(Damage);
		}
		break;
	case 'Panic':
		Template.AddTargetEffect(class'X2StatusEffects'.static.CreatePanickedStatusEffect());
		break;
	case 'MindControl':
		Template.AddTargetEffect(class'X2StatusEffects'.static.CreateMindControlStatusEffect(S.Param2));
		Template.AddTargetEffect(class'X2StatusEffects'.static.CreateMindControlRemoveEffects());
		break;
	}
	return Template;
}

/** Flush's reduced damage, as a stand-in of its own: Damage2 % (negative) on Flush's shot. */
static function LWStandin FlushDamage(LWStandin S)
{
	local LWStandin D;

	D.Name = name(S.Name $ "_Damage");
	D.Icon = S.Icon;
	D.DamagePct = S.Damage2;
	D.DamageIf = 'FlushShot';
	return D;
}

/**
 * Long War's Adrenal Neurosympathy: when the soldier kills, squadmates within Radius tiles gain Aim, Crit and Mobility
 * until the soldier's next turn; Param turns before it can happen again. Triggered by XCOM 2's KillMail event (the
 * killer its source).
 */
static function X2AbilityTemplate Adrenal(LWStandin S)
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener Trigger;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Condition_UnitProperty Allies;
	local X2Effect_PersistentStatChange Rush;
	local X2AbilityCooldown Cooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, S.Name);
	Template.IconImage = S.Icon;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'KillMail';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);
	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = S.Radius * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	Radius.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = Radius;
	Allies = new class'X2Condition_UnitProperty';
	Allies.ExcludeHostileToSource = true;
	Allies.ExcludeFriendlyToSource = false;
	Allies.ExcludeDead = true;
	Allies.RequireSquadmates = true;
	Allies.FailOnNonUnits = true;
	Template.AbilityMultiTargetConditions.AddItem(Allies);
	if (S.Param > 0)
	{
		Cooldown = new class'X2AbilityCooldown';
		Cooldown.iNumTurns = S.Param;
		Template.AbilityCooldown = Cooldown;
	}
	Rush = new class'X2Effect_PersistentStatChange';
	Rush.EffectName = name(S.Name $ "_Rush");
	Rush.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	Rush.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Rush.AddPersistentStatChange(eStat_Offense, S.Aim);
	Rush.AddPersistentStatChange(eStat_CritChance, S.Crit);
	Rush.AddPersistentStatChange(eStat_Mobility, S.Mobility);
	Rush.DuplicateResponse = eDupe_Refresh;
	Template.AddMultiTargetEffect(Rush);
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

/** Long War's Regen Biofield: at the start of each of XCOM's turns, allies within Radius tiles (the psion too) heal Heal. */
static function X2AbilityTemplate Biofield(LWStandin S)
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener Trigger;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Condition_UnitProperty Allies;
	local X2Effect_ApplyMedikitHeal Heal;

	`CREATE_X2ABILITY_TEMPLATE(Template, S.Name);
	Template.IconImage = S.Icon;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'PlayerTurnBegun';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Player;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);
	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = S.Radius * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	Radius.bIgnoreBlockingCover = true;
	Radius.bExcludeSelfAsTargetIfWithinRadius = false;
	Template.AbilityMultiTargetStyle = Radius;
	Allies = new class'X2Condition_UnitProperty';
	Allies.ExcludeHostileToSource = true;
	Allies.ExcludeFriendlyToSource = false;
	Allies.ExcludeDead = true;
	Allies.ExcludeFullHealth = true;
	Allies.FailOnNonUnits = true;
	Template.AbilityMultiTargetConditions.AddItem(Allies);
	Heal = new class'X2Effect_ApplyMedikitHeal';
	Heal.PerUseHP = S.Heal;
	Template.AddMultiTargetEffect(Heal);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
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
	local X2Effect_Regeneration Regen;
	local X2Effect_LWSecondaryHeart Heart;
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

	if (S.BleedTurns > 0)
	{
		Heart = new class'X2Effect_LWSecondaryHeart';
		Heart.BuildPersistentEffect(1, true, false, false);
		Heart.ExtraTurns = S.BleedTurns;
		Template.AddTargetEffect(Heart);
	}

	if (S.Regen > 0)
	{
		Regen = new class'X2Effect_Regeneration';
		Regen.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnBegin);
		Regen.HealAmount = S.Regen;
		Regen.MaxHealAmount = 1000;
		Regen.HealthRegeneratedName = name(S.Name $ "_Healed");
		Template.AddTargetEffect(Regen);
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

/** Savior and its like: XCOM 2's medikit abilities heal more for a soldier with the perk, Smart Macrophages on one, and with Improved Medikit done; Revive's stabilize (OnPostTemplatesCreated). */
static function AddHealBonuses()
{
	local X2AbilityTemplateManager Manager;
	local X2AbilityTemplate Medikit;
	local X2Effect_ApplyMedikitHeal Heal;
	local X2Condition_AbilityProperty Owner;
	local X2Condition_UnitEffects Target;
	local X2Condition_LWFoundry Done;
	local X2Condition_LWOwnerLacks Lacks;
	local X2Effect Effect;
	local X2Effect_LWReviveHeal Revive;
	local LWStandin S;
	local name Ability;
	local array<name> Medikits;

	Medikits.AddItem('MedikitHeal');
	Medikits.AddItem('NanoMedikitHeal');
	Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	// Revive: the stabilized soldier stays awake, healed to a share of their health.
	Medikit = Manager.FindAbilityTemplate('MedikitStabilize');
	foreach default.Standins(S)
		if (S.Revive != 0 && Medikit != none)
		{
			Owner = new class'X2Condition_AbilityProperty';
			Owner.OwnerHasSoldierAbilities.AddItem(S.Name);
			// XCOM 2's unconsciousness after stabilizing: only for a medic without the perk.
			Lacks = new class'X2Condition_LWOwnerLacks';
			Lacks.Ability = S.Name;
			foreach Medikit.AbilityTargetEffects(Effect)
				if (X2Effect_Persistent(Effect) != none && X2Effect_Persistent(Effect).EffectName == class'X2StatusEffects'.default.UnconsciousName)
					Effect.TargetConditions.AddItem(Lacks);
			Revive = new class'X2Effect_LWReviveHeal';
			Revive.Pct = S.Revive;
			Revive.TargetConditions.AddItem(Owner);
			Medikit.AddTargetEffect(Revive);
		}
	foreach Medikits(Ability)
	{
		Medikit = Manager.FindAbilityTemplate(Ability);
		if (Medikit == none)
			continue;
		// Improved Medikit (the Foundry's project 3): +3 a charge, Long War's text ("by three for medikits").
		Heal = new class'X2Effect_ApplyMedikitHeal';
		Heal.PerUseHP = 3;
		Done = new class'X2Condition_LWFoundry';
		Done.Foundry = 3;
		Heal.TargetConditions.AddItem(Done);
		Medikit.AddTargetEffect(Heal);
		foreach default.Standins(S)
		{
			// Smart Macrophages: more when used on a soldier with the perk (its passive effect, named as the perk).
			if (S.HealTaken != 0)
			{
				Heal = new class'X2Effect_ApplyMedikitHeal';
				Heal.PerUseHP = S.HealTaken;
				Target = new class'X2Condition_UnitEffects';
				Target.AddRequireEffect(S.Name, 'AA_MissingRequiredEffect');
				Heal.TargetConditions.AddItem(Target);
				Medikit.AddTargetEffect(Heal);
			}
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

/** Shredder Ammo: the shots of a Gunner's LMG or SAW and the rockets shred what they hit, for a soldier with the perk (OnPostTemplatesCreated). */
/**
 * Every psi ability checked against the target's will (XCOM 2's X2AbilityToHitCalc_StatCheck_UnitVsUnit, the aliens' and
 * Long War's powers alike) gets X2AbilityToHitCalc_LWPsiCheck, which counts PsiWill (Neural Damping): XCOM 2's check reads
 * the stat itself and asks no effect.
 */
static function AddPsiChecks()
{
	local X2AbilityTemplateManager Manager;
	local X2DataTemplate Data;
	local X2AbilityTemplate Template;
	local X2AbilityToHitCalc_StatCheck_UnitVsUnit Old;
	local X2AbilityToHitCalc_LWPsiCheck Check;
	local int n;

	Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach Manager.IterateTemplates(Data, none)
	{
		Template = X2AbilityTemplate(Data);
		Old = Template == none ? none : X2AbilityToHitCalc_StatCheck_UnitVsUnit(Template.AbilityToHitCalc);
		if (Old == none || X2AbilityToHitCalc_LWPsiCheck(Old) != none || Old.DefenderStat != eStat_Will)
			continue;
		Check = new class'X2AbilityToHitCalc_LWPsiCheck';
		Check.BaseValue = Old.BaseValue;
		Check.AttackerStat = Old.AttackerStat;
		Check.DefenderStat = Old.DefenderStat;
		Template.AbilityToHitCalc = Check;
		n++;
	}
	`log("LongWarX2: perks:" @ n @ "psi abilities checked with Long War's will against psi", , 'LongWarX2');
}

/** Will more against psi attacks this unit has (PsiWill of its abilities). */
static function int PsiWillOf(XComGameState_Unit Unit)
{
	local LWStandin S;
	local int Will;

	foreach default.Standins(S)
		if (S.PsiWill != 0 && Unit.HasSoldierAbility(S.Name))
			Will += S.PsiWill;
	return Will;
}

static function AddShredders()
{
	local X2AbilityTemplateManager Manager;
	local X2AbilityTemplate Template;
	local X2Effect_LWShredded Shred;
	local X2Condition_AbilityProperty Owner;
	local X2Condition_LWSourceWeapon Weapon;
	local LWStandin S;
	local name Ability;
	local array<name> Shots;

	Shots.AddItem('StandardShot');
	Shots.AddItem('OverwatchShot');
	Shots.AddItem('RocketLauncher');
	Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach default.Standins(S)
	{
		if (S.ShredPct == 0)
			continue;
		foreach Shots(Ability)
		{
			Template = Manager.FindAbilityTemplate(Ability);
			if (Template == none)
				continue;
			Shred = new class'X2Effect_LWShredded';
			Shred.BuildPersistentEffect(S.ShredTurns, false, true, false, eGameRule_PlayerTurnBegin);
			Shred.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, "", S.Icon, true);
			Shred.Pct = S.ShredPct;
			Owner = new class'X2Condition_AbilityProperty';
			Owner.OwnerHasSoldierAbilities.AddItem(S.Name);
			Shred.TargetConditions.AddItem(Owner);
			Weapon = new class'X2Condition_LWSourceWeapon';
			Weapon.Categories.AddItem('lw_gunner');
			Weapon.Categories.AddItem('lw_rocketeer_engineer');
			Shred.TargetConditions.AddItem(Weapon);
			if (Template.AbilityMultiTargetStyle != none && Ability == 'RocketLauncher')
				Template.AddMultiTargetEffect(Shred);
			else
				Template.AddTargetEffect(Shred);
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
