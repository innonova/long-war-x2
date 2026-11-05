// Long War's aliens' stats (features/lw-aliens.md): each alien of a Long War mission given its species' base stats
// (XGTacticalGameCore's Characters), the campaign difficulty's adjustments and the automatic upgrades the aliens' research
// has brought (BalanceMods_Easy and _Normal), in place of the XCOM 2 template's it fights as. Config generated from stock
// Long War by scripts/aliens-config.mjs. The damage bonus rides on a passive every alien template gets (X2Ability_LWAliens).
// Pod leaders and navigators (BalanceMods_Hard) add their stats and the pawn's scale; their perks are noted, not given
// yet (features/lw-aliens.md). Not yet: the regeneration.
class LWAlienStats extends Object config(LWAliens) dependson(LWStrategyRules);

struct LWAlienBase { var int Species, HP, Aim, Defense, Mobility, Sight, Will, Crit; };
struct LWAlienDifficulty { var int Species, Level, Damage, Aim, Defense, HP, Mobility, Will; };
struct LWAlienUpgrade { var int Species, Research, Damage, Aim, Crit, Defense, HP, Shield, Mobility, Will, Regen; var float DR; };
struct LWAlienWeapon { var int Species, Damage; };
struct LWAlienAbility { var int Species; var name Ability; };
struct LWAlienLeader { var int Species, Research, Level, Chance, HP, Aim, Damage, Will, Perk, Scale; };

var config array<LWAlienBase> Base;
var config array<LWAlienDifficulty> Difficulty;
var config array<LWAlienUpgrade> Upgrade;
/** Each species' weapon's damage in Long War (its shots with the XCOM 2 weapon are shifted to it). */
var config array<LWAlienWeapon> Weapon;
/** Each species' own abilities (Long War's ABILITIES[]) where the mod has them: the Sectoid's Mind Merge, Psi Panic, Mindfray … */
var config array<LWAlienAbility> SpeciesAbilities;
/** Pod leaders (Level: a leader of at least that level) and navigators (Chance in 100, any member), from a research level. */
var config array<LWAlienLeader> Leader;
/**
 * XCOM 2's abilities of the templates Long War's species fight as that no Long War alien has (Blazing Pinions on a Floater,
 * a Cyberdisc raising the dead, a Sectoid reanimating corpses …), taken off those templates; each species' own Enemy
 * Within abilities are to come (features/lw-aliens.md). Basic attacks and immunities stay.
 */
var array<name> NotLongWar;
/** The same for their weapons' abilities: "<weapon template>:<ability>" (the Viper's tongue on a Thin Man …). */
var array<string> NotLongWarWeapons;

/**
 * The aliens' research level: Long War's grows about a day a day ("roughly days passed", its config says); the campaign's
 * day here (APPROXIMATION until the aliens' research clock is Long War's own: features/lw-geoscape.md). 0 without a Long
 * War campaign (the first mission).
 */
static function int ResearchLevel()
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	return S != none ? S.AlienResearch() : 0;
}

/** The campaign's difficulty, 0-3 (XCOM 2's Rookie … Legend as Long War's Normal … Impossible). */
static function int DifficultyLevel()
{
	local XComGameState_CampaignSettings Settings;

	Settings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	return Settings != none ? Clamp(Settings.DifficultySetting, 0, 3) : 1;
}

/** A unit (new or modified in the change being built) given its species' Long War stats; false when the species has none. */
/**
 * A pod leader's level, as Long War rolls it when it builds a pod (XGStrategyAI.BuildPod): out of the research level / 40
 * + 1 (1 to 15), above 7 folded back (7 less a roll out of 16 less it), 0 to 7.
 */
static function int LeaderLevel()
{
	local int n, L;

	n = Clamp(ResearchLevel() / 40 + 1, 1, 15);
	L = Rand(n);
	if (L > 7)
		L = 7 - Rand(16 - n);
	return Clamp(L, 0, 7);
}

static function bool ApplyTo(XComGameState_Unit Unit, int Species, optional int LeaderLevel, optional XComGameState NewGameState)
{
	local int k, HP, Aim, Defense, Mobility, Will, Crit, Shield, Research, Level, Damage;
	local float DR;
	local LWAlienDifficulty D;
	local LWAlienUpgrade U;
	local LWAlienLeader L;
	local int Scale, Perks;
	local string PerkList;
	local name Ability;
	local LWAlienAbility A;

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
	// The pod's leader (its level) and navigators (each member, by chance), as Long War applies them (XGUnit's hand-patched
	// DebugAnims): the leader's lines up to its level, each navigator line at its chance.
	foreach default.Leader(L)
	{
		if (L.Species != Species || L.Research > Research)
			continue;
		if (L.Chance > 0 ? Rand(100) > L.Chance : LeaderLevel < L.Level)
			continue;
		HP += L.HP;
		Aim += L.Aim;
		Damage += L.Damage;
		Will += L.Will;
		Scale += L.Scale;
		if (L.Perk > 0)
		{
			Unit.SetUnitFloatValue(name("LWX2Perk" $ Perks), L.Perk, eCleanup_Never);
			Perks++;
			// The ability a soldier's perk of that number is, given to the alien (in the game state that spawns it:
			// InitAbilityForUnit activates a passive's effects then).
			Ability = class'X2Ability_LWStandins'.static.AlienAbilityFor(L.Perk);
			PerkList @= string(L.Perk) $ "=" $ (Ability != '' ? Ability : 'none') $ (Give(Unit, Ability, NewGameState) ? "" : "(not given)");
		}
	}
	if (Scale != 0)
		Unit.SetUnitFloatValue('LWX2Scale', Scale, eCleanup_Never);
	// The kill's experience is more for a leader (LWExperience).
	if (LeaderLevel > 0)
		Unit.SetUnitFloatValue('LWX2Leader', LeaderLevel, eCleanup_Never);
	foreach default.SpeciesAbilities(A)
		if (A.Species == Species)
			Give(Unit, A.Ability, NewGameState);
	if (LeaderLevel > 0 || Perks > 0)
		`log("LongWarX2: aliens: species" @ Species @ (LeaderLevel > 0 ? "leader of level" @ LeaderLevel : "navigator") $ ", scale" @ Scale $ "%, Long War perks" @ (PerkList != "" ? PerkList : "none"), , 'LongWarX2');
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
	k = default.Weapon.Find('Species', Species);
	if (k != INDEX_NONE)
		Unit.SetUnitFloatValue('LWX2WeaponDamage', default.Weapon[k].Damage, eCleanup_Never);
	return true;
}

/** An ability given to the unit in the game state that spawns it (InitAbilityForUnit activates a passive's effects then),
 *  with the abilities it brings (its AdditionalAbilities: the Seeker's Strangle's hold each turn, as XCOM 2 gives a
 *  character's); false where there is no such ability, no game state, or the unit has it. */
static function bool Give(XComGameState_Unit Unit, name Ability, XComGameState NewGameState)
{
	local X2AbilityTemplate Template;
	local name Other;

	Template = Ability != '' ? class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Ability) : none;
	if (Template == none || NewGameState == none || Unit.FindAbility(Ability).ObjectID != 0)
		return false;
	class'X2TacticalGameRuleset'.static.InitAbilityForUnit(Template, Unit, NewGameState, Unit.GetPrimaryWeapon().GetReference());
	foreach Template.AdditionalAbilities(Other)
		Give(Unit, Other, NewGameState);
	return true;
}

/** The aliens' passives on every template Long War's species fight as (as the templates are made). */
static function AddAbilities()
{
	local X2CharacterTemplateManager Manager;
	local array<X2DataTemplate> Templates;
	local X2DataTemplate T;
	local LWFightAs F;
	local X2ItemTemplateManager Items;
	local string Pair;
	local int k, n;

	Manager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	foreach class'LWStrategyRules'.default.FightAs(F)
	{
		Templates.Length = 0;
		Manager.FindDataTemplateAllDifficulties(F.Template, Templates);
		foreach Templates(T)
			if (X2CharacterTemplate(T) != none && X2CharacterTemplate(T).Abilities.Find('LWX2_AlienDamage') == INDEX_NONE)
				X2CharacterTemplate(T).Abilities.AddItem('LWX2_AlienDamage');
		foreach Templates(T)
			if (X2CharacterTemplate(T) != none)
				for (k = X2CharacterTemplate(T).Abilities.Length - 1; k >= 0; k--)
					if (default.NotLongWar.Find(X2CharacterTemplate(T).Abilities[k]) != INDEX_NONE)
					{
						X2CharacterTemplate(T).Abilities.Remove(k, 1);
						n++;
					}
	}
	Items = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach default.NotLongWarWeapons(Pair)
	{
		Templates.Length = 0;
		Items.FindDataTemplateAllDifficulties(name(Left(Pair, InStr(Pair, ":"))), Templates);
		foreach Templates(T)
			if (X2WeaponTemplate(T) != none)
			{
				k = X2WeaponTemplate(T).Abilities.Find(name(Mid(Pair, InStr(Pair, ":") + 1)));
				if (k != INDEX_NONE)
				{
					X2WeaponTemplate(T).Abilities.Remove(k, 1);
					n++;
				}
			}
	}
	`log("LongWarX2: aliens:" @ n @ "of XCOM 2's abilities no Long War alien has taken off their templates and weapons", , 'LongWarX2');
}

defaultproperties
{
	// Sectoid (and Sectoid Commander): XCOM 2's psionics and its weakness to blades.
	NotLongWar(0)=PsiReanimation
	NotLongWar(1)=KillSiredZombies
	NotLongWar(2)=DelayedPsiExplosion
	NotLongWar(3)=Mindspin
	NotLongWar(4)=VulnerabilityMelee
	// Floater (Archon): Blazing Pinions, frenzy.
	NotLongWar(5)=BlazingPinionsStage1
	NotLongWar(6)=FrenzyDamageListener
	// Thin Man (Viper): bind.
	NotLongWar(7)=Bind
	// Cyberdisc (Gatekeeper): the Anima abilities.
	NotLongWar(8)=AnimaInversion
	NotLongWar(9)=AnimaConsume
	NotLongWar(10)=AnimaGate
	// Outsider (Codex): teleporting, cloning, the psi bomb, its weakness to hacking.
	NotLongWar(11)=Teleport
	NotLongWar(12)=Malfunction
	NotLongWar(13)=PsiBombStage1
	NotLongWar(14)=Superposition
	NotLongWar(15)=TriggerSuperpositionDamageListener
	NotLongWar(16)=TechVulnerability
	// Muton Elite (Andromedon): the robot suit, its punch, smashing walls, the acid launcher.
	NotLongWar(17)=SwitchToRobot
	NotLongWar(18)=RobotBattlesuit
	NotLongWar(19)=BigDamnPunch
	NotLongWar(20)=WallBreaking
	NotLongWar(21)=WallSmash
	NotLongWar(22)=ShellLauncher
	// Muton: XCOM 2's counterattack; Berserker: its rage; Chryssalid: burrowing.
	NotLongWar(23)=CounterattackPreparation
	NotLongWar(24)=CounterattackDescription
	NotLongWar(25)=TriggerRageDamageListener
	NotLongWar(26)=ChryssalidBurrow
	// Seeker (Faceless): its regeneration (EW's Seeker has none; seen in an alien turn, 2026-11-04 night). FacelessInit is
	// that regeneration (and brings the Regeneration passive with it).
	NotLongWar(27)=FacelessInit
	// Their weapons: the Viper's tongue (Thin Man), the Archon's melee (Floater), the Muton's bayonet and execute, the
	// MECs' micro missiles (Drone, Mechtoid).
	NotLongWarWeapons(0)="Viper_Tongue_WPN:GetOverHere"
	NotLongWarWeapons(1)="Archon_MeleeAttack:StandardMelee"
	NotLongWarWeapons(2)="Muton_MeleeAttack:Bayonet"
	NotLongWarWeapons(3)="Muton_MeleeAttack:CounterattackBayonet"
	NotLongWarWeapons(4)="Muton_WPN:Execute"
	NotLongWarWeapons(5)="AdvMEC_M1_Shoulder_WPN:MicroMissiles"
	NotLongWarWeapons(6)="AdvMEC_M1_Shoulder_WPN:MicroMissileFuse"
	NotLongWarWeapons(7)="AdvMEC_M2_Shoulder_WPN:MicroMissiles"
	NotLongWarWeapons(8)="AdvMEC_M2_Shoulder_WPN:MicroMissileFuse"
}

static function SetStat(XComGameState_Unit Unit, ECharStatType Stat, float Value)
{
	Unit.SetBaseMaxStat(Stat, Value);
	Unit.SetCurrentStat(Stat, Value);
}
