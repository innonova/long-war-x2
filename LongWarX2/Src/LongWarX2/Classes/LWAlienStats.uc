// Long War's aliens' stats (features/lw-aliens.md): each alien of a Long War mission given its species' base stats
// (XGTacticalGameCore's Characters), the campaign difficulty's adjustments and the automatic upgrades the aliens' research
// has brought (BalanceMods_Easy and _Normal), in place of the XCOM 2 template's it fights as. Config generated from stock
// Long War by scripts/aliens-config.mjs. The damage bonus rides on a passive every alien template gets (X2Ability_LWAliens).
// Not yet: pod leaders and navigators (BalanceMods_Hard), the regeneration.
class LWAlienStats extends Object config(LWAliens) dependson(LWStrategyRules);

struct LWAlienBase { var int Species, HP, Aim, Defense, Mobility, Sight, Will, Crit; };
struct LWAlienDifficulty { var int Species, Level, Damage, Aim, Defense, HP, Mobility, Will; };
struct LWAlienUpgrade { var int Species, Research, Damage, Aim, Crit, Defense, HP, Shield, Mobility, Will, Regen; var float DR; };

var config array<LWAlienBase> Base;
var config array<LWAlienDifficulty> Difficulty;
var config array<LWAlienUpgrade> Upgrade;

/**
 * The aliens' research level: Long War's grows about a day a day ("roughly days passed", its config says); the campaign's
 * day here (APPROXIMATION until the aliens' research clock is Long War's own: features/lw-geoscape.md). 0 without a Long
 * War campaign (the first mission).
 */
static function int ResearchLevel()
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	return S != none ? S.Days() : 0;
}

/** The campaign's difficulty, 0-3 (XCOM 2's Rookie … Legend as Long War's Normal … Impossible). */
static function int DifficultyLevel()
{
	local XComGameState_CampaignSettings Settings;

	Settings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	return Settings != none ? Clamp(Settings.DifficultySetting, 0, 3) : 1;
}

/** A unit (new or modified in the change being built) given its species' Long War stats; false when the species has none. */
static function bool ApplyTo(XComGameState_Unit Unit, int Species)
{
	local int k, HP, Aim, Defense, Mobility, Will, Crit, Shield, Research, Level, Damage;
	local float DR;
	local LWAlienDifficulty D;
	local LWAlienUpgrade U;

	k = default.Base.Find('Species', Species);
	if (Unit == none || k == INDEX_NONE)
		return false;
	HP = default.Base[k].HP;
	Aim = default.Base[k].Aim;
	Defense = default.Base[k].Defense;
	Mobility = default.Base[k].Mobility;
	Will = default.Base[k].Will;
	Crit = default.Base[k].Crit;
	Level = DifficultyLevel();
	foreach default.Difficulty(D)
		if (D.Species == Species && D.Level == Level)
		{
			HP += D.HP;
			Aim += D.Aim;
			Defense += D.Defense;
			Mobility += D.Mobility;
			Will += D.Will;
			Damage += D.Damage;
		}
	Research = ResearchLevel();
	foreach default.Upgrade(U)
		if (U.Species == Species && U.Research <= Research)
		{
			HP += U.HP;
			Aim += U.Aim;
			Crit += U.Crit;
			Defense += U.Defense;
			DR += U.DR;
			Shield += U.Shield;
			Mobility += U.Mobility;
			Will += U.Will;
			Damage += U.Damage;
		}
	SetStat(Unit, eStat_HP, Max(1, HP));
	SetStat(Unit, eStat_Offense, Aim);
	SetStat(Unit, eStat_Defense, Defense);
	SetStat(Unit, eStat_Mobility, Max(1, Mobility));
	SetStat(Unit, eStat_Will, Will);
	SetStat(Unit, eStat_CritChance, Crit);
	if (Shield > 0)
		SetStat(Unit, eStat_ShieldHP, Shield);
	if (DR > 0)
		SetStat(Unit, eStat_ArmorMitigation, Round(DR));
	Unit.SetUnitFloatValue('LWX2DamageBonus', Damage, eCleanup_Never);
	return true;
}

/** The aliens' passives on every template Long War's species fight as (as the templates are made). */
static function AddAbilities()
{
	local X2CharacterTemplateManager Manager;
	local array<X2DataTemplate> Templates;
	local X2DataTemplate T;
	local LWFightAs F;

	Manager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	foreach class'LWStrategyRules'.default.FightAs(F)
	{
		Templates.Length = 0;
		Manager.FindDataTemplateAllDifficulties(F.Template, Templates);
		foreach Templates(T)
			if (X2CharacterTemplate(T) != none && X2CharacterTemplate(T).Abilities.Find('LWX2_AlienDamage') == INDEX_NONE)
				X2CharacterTemplate(T).Abilities.AddItem('LWX2_AlienDamage');
	}
}

static function SetStat(XComGameState_Unit Unit, ECharStatType Stat, float Value)
{
	Unit.SetBaseMaxStat(Stat, Value);
	Unit.SetCurrentStat(Stat, Value);
}
