// Long War's damage reduction (features/lw-damage-reduction.md): a passive on every character (AddAbilities) whose
// effect (X2Effect_LWDamageReduction) takes Long War's reduction off each hit. Absorb is Long War's XGUnit.AbsorbDamage
// for what the port has: the unit's own (Long War's aliens, LWAlienStats; armour, LWGearRules; a SHIV's deck, a MEC's
// suit), Combat Stims, Chitin Plating, the target's shield, Shock-Absorbent Armor, Absorption Fields, acid, cover as the
// attacker sees it, hunkering, Will to Survive, Fortiores Una; the attacker's Combined Arms, Armor Piercing Ammo and Gauss
// weapons; shotguns' extra penalty. The numbers are Long War's (scripts/classes-config.mjs).
class X2Ability_LWDamageReduction extends X2Ability config(LWClasses) dependson(LWSHIVs, LWMECs);

/** Cover's reduction, low and high (AbsorbDamage: 0.667, 1); hunkered down, as much again; Fortiores Una, as much again. */
var config float LowCover, HighCover;
/** Will to Survive's, in cover and not flanked (AbsorbDamage: 1.5; its words: "1 to 2 points"). */
var config float WillToSurvive;
/** Combined Arms: the attacker ignores this much (1). */
var config float CombinedArms;
/** Gauss weapons ignore this much (Long War's COUNCIL_FUNDING_MULTIPLIER_EASY, 0.34), twice that with the Foundry's
 *  project GaussFoundry (Long War's 44, its m_arrFoundryHistory[44] read as aUpgrades[123] & 32). */
var config float Gauss;
var config int GaussFoundry;
/** A shield up: the damage times this (0.5). */
var config float ShieldFactor;
/** Acid: back at least AcidMin, or AcidShare of what was taken off (3, 0.5). */
var config float AcidMin, AcidShare;
/** Shotguns: the reduction taken off once more times this (0.5; Breaching Ammo would cancel it). */
var config float ShotgunExtra;
/** Armor Piercing Ammo (its item's template): its carrier's shots ignore this much (2). */
var config name APAmmoItem;
var config float APAmmo;
/** Combat Stims: a hit times StimsFactor while they last (0.6). */
var config float StimsFactor;
/** Chitin Plating (its item's template): a melee hit times ChitinFactor (0.6). */
var config name ChitinPlating;
var config float ChitinFactor;
/** Shock-Absorbent Armor: the damage times ShockFactor from an attacker within ShockTiles (0.67, 4). */
var config float ShockFactor;
var config int ShockTiles;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(DamageReduction());
	return Templates;
}

static function X2AbilityTemplate DamageReduction()
{
	local X2AbilityTemplate Template;
	local X2Effect_LWDamageReduction Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_DamageReduction');
	// (A rule's carrier, not a perk: not listed among the soldier's abilities in the armory.)
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_LWDamageReduction';
	Effect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(Effect);
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

/** On every character template (soldiers, aliens, civilians: Long War reduces everyone's damage). */
static function AddAbilities()
{
	local X2CharacterTemplateManager Manager;
	local X2DataTemplate T;
	local array<X2DataTemplate> Templates;
	local X2CharacterTemplate C;

	Manager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	foreach Manager.IterateTemplates(T, none)
	{
		Templates.Length = 0;
		Manager.FindDataTemplateAllDifficulties(T.DataName, Templates);
		foreach Templates(T)
		{
			C = X2CharacterTemplate(T);
			if (C != none && C.Abilities.Find('LWX2_DamageReduction') == INDEX_NONE)
				C.Abilities.AddItem('LWX2_DamageReduction');
		}
	}
}

/** The unit's own reduction: Long War's aliens' (LWX2DR, LWAlienStats) and its armour's (LWGearRules.Armors' DR). */
static function float OwnReduction(XComGameState_Unit Unit)
{
	local UnitValue V;
	local XComGameState_Item Armor;
	local LWGearRules.LWArmorDef A;
	local LWSHIVs.LWSHIVBody Body;
	local LWMECs.LWMECSuit Suit;
	local float DR;

	if (Unit.GetUnitValue('LWX2DR', V))
		DR += V.fValue;
	Armor = Unit.GetItemInSlot(eInvSlot_Armor);
	if (Armor != none)
		foreach class'LWGearRules'.default.Armors(A)
			if (class'LWGearRules'.static.ArmorTemplateFor(A.Item) == Armor.GetMyTemplateName())
				DR += A.DR;
	// A SHIV's deck, a MEC's suit (their items' reductions in Long War).
	if (class'LWSHIVs'.static.BodyForTemplate(Unit.GetMyTemplateName(), Body))
		DR += Body.DR;
	if (Armor != none)
		foreach class'LWMECs'.default.Suits(Suit)
			if (class'LWMECs'.static.SuitTemplate(Suit.Item) == Armor.GetMyTemplateName())
				DR += Suit.DR;
	return DR;
}

/** Cover's reduction as the attacker sees the target: none flanked (or without cover), else low or high. */
static function float CoverReduction(XComGameState_Unit Target, XComGameState_Unit Attacker)
{
	local GameRulesCache_VisibilityInfo VisInfo;
	local ECoverType Cover;

	// Beside the Alloy SHIV on the attacker's side: high cover (X2Ability_LWMobileCover).
	if (Attacker != none && class'X2Ability_LWMobileCover'.static.CoverFor(Target, `XWORLD.GetPositionFromTileCoordinates(Attacker.TileLocation)) != none)
		return default.HighCover;
	// In cover at all (Long War's IsInCover; XCOM 2's own test, as for hunkering down).
	if (!Target.CanTakeCover() || Target.GetCoverTypeFromLocation() == CT_None)
		return 0;
	// In the attacker's line of sight, the cover it sees (none when flanked); else, as for a grenade out of sight, the best
	// at the tile. (Without a line of sight XCOM 2's record of the pair keeps no cover worth reading.)
	if (Attacker != none && `TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo) && VisInfo.bClearLOS)
		Cover = VisInfo.TargetCover;
	else
		Cover = Target.GetCoverTypeFromLocation();
	return Cover == CT_Standing ? default.HighCover : (Cover == CT_MidLevel ? default.LowCover : 0.0);
}

/** Near enough its squad's leader for Fortiores Una (the officers' radius, X2Ability_LWOfficers.LeadRadiusTiles). */
static function bool NearLeader(XComGameState_Unit Unit)
{
	local XComGameState_Unit Leader;
	local int LeaderID;

	LeaderID = class'LWOfficers'.static.ValueOf(Unit, 'LWX2SquadLeader');
	if (LeaderID <= 0)
		return false;
	if (LeaderID == Unit.ObjectID)
		return true;
	Leader = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LeaderID));
	return Leader != none && Leader.IsAlive() && Unit.TileDistanceBetween(Leader) <= class'X2Ability_LWOfficers'.default.LeadRadiusTiles;
}

/** The Long War weapon (LWGearRules.Weapons) a weapon is, if it is one. */
static function bool LongWarWeapon(XComGameState_Item Weapon, out LWGearRules.LWWeaponDef W)
{
	local LWGearRules.LWWeaponDef D;

	if (Weapon == none)
		return false;
	foreach class'LWGearRules'.default.Weapons(D)
		if (class'LWGearRules'.static.TemplateFor(D.Item) == Weapon.GetMyTemplateName())
		{
			W = D;
			return true;
		}
	return false;
}

/** Long War's AbsorbDamage: the damage left of Damage (a fraction), and what took it off (Parts, for the control port). */
static function float Absorb(XComGameState_Unit Target, XComGameState_Unit Attacker, XComGameState_Item Weapon, int Damage, out string Parts, optional bool bMelee)
{
	local float F, Cover, X;
	local LWGearRules.LWWeaponDef W;
	local bool bLongWarWeapon;

	F = Damage;
	Parts = "";
	X = OwnReduction(Target);
	if (X > 0)
	{
		F -= X;
		Parts @= "own" @ X;
	}
	// Combat Stims active (Long War's GetAppliedAbility(31)): x StimsFactor (0.6). XCOM 2's stims, whose stats effect this is.
	if (Target.IsUnitAffectedByEffectName('StimStats'))
	{
		F *= default.StimsFactor;
		Parts @= "stims x" $ default.StimsFactor;
	}
	// Chitin Plating against a melee attack (and the Kinetic Strike): x ChitinFactor (0.6).
	if (bMelee && HasItem(Target, default.ChitinPlating))
	{
		F *= default.ChitinFactor;
		Parts @= "chitin x" $ default.ChitinFactor;
	}
	if (Target.GetCurrentStat(eStat_ShieldHP) > 0)
	{
		F *= default.ShieldFactor;
		Parts @= "shield x" $ default.ShieldFactor;
	}
	// Shock-Absorbent Armor (a MEC perk, Long War's upgrade 143): x ShockFactor from an attacker within ShockTiles.
	if (Attacker != none && Target.HasSoldierAbility('LW_ShockAbsorbentArmor') && Target.TileDistanceBetween(Attacker) <= default.ShockTiles)
	{
		F *= default.ShockFactor;
		Parts @= "shock-absorbent x" $ default.ShockFactor;
	}
	// Absorption Fields (upgrade 142): over 1 damage, x (0.6 + 0.4 x min(2 / damage, 1)), at most 40% off.
	if (Target.HasSoldierAbility('LW_AbsorptionFields') && F > 1)
	{
		X = 0.6 + 0.4 * FMin(2.0 / F, 1.0);
		F *= X;
		Parts @= "absorption-fields x" $ X;
	}
	if (Target.IsPoisoned() || Target.IsAcidBurning())
	{
		F += FMax(default.AcidMin, default.AcidShare * (Damage - F));
		Parts @= "acid";
	}
	// In cover and not flanked (flanked: CoverReduction finds none).
	Cover = CoverReduction(Target, Attacker);
	if (Cover > 0)
	{
		F -= Cover;
		Parts @= "cover" @ Cover;
		if (Target.IsUnitAffectedByEffectName('HunkerDown'))
		{
			F -= Cover;
			Parts @= "hunkered" @ Cover;
		}
		if (Target.HasSoldierAbility('LW_WilltoSurvive'))
		{
			F -= default.WillToSurvive;
			Parts @= "will-to-survive" @ default.WillToSurvive;
		}
		if (class'LWOfficers'.static.SquadHad(Target, class'LWOfficers'.const.FORTIORES_UNA) && NearLeader(Target))
		{
			F -= Cover;
			Parts @= "fortiores-una" @ Cover;
		}
	}
	bLongWarWeapon = LongWarWeapon(Weapon, W);
	if (Attacker != none)
	{
		if (class'LWOfficers'.static.SquadHad(Attacker, class'LWOfficers'.const.COMBINED_ARMS))
		{
			F += default.CombinedArms;
			Parts @= "combined-arms -" $ default.CombinedArms;
		}
		// Armor Piercing Ammo carried (item 198): +APAmmo, not with an Assault or Pistol weapon (shotguns, pistols).
		if (bLongWarWeapon && HasItem(Attacker, default.APAmmoItem) && W.Family != 'Shotgun' && W.Family != 'SawedOff' && W.Family != 'Pistol' && W.Family != 'MachinePistol')
		{
			F += default.APAmmo;
			Parts @= "ap-ammo -" $ default.APAmmo;
		}
		if (bLongWarWeapon && W.Tier == 'Gauss')
		{
			X = class'LWAirWar'.static.FoundryDone(default.GaussFoundry) ? 2 * default.Gauss : default.Gauss;
			F += X;
			Parts @= "gauss -" $ X;
		}
	}
	F = FMin(F, Damage);
	if (F < Damage && bLongWarWeapon && W.Family == 'Shotgun')
	{
		F -= default.ShotgunExtra * (Damage - F);
		Parts @= "shotgun x" $ (1 + default.ShotgunExtra);
	}
	return FMax(F, 0);
}

/** Whether the unit carries an item of the template. */
static function bool HasItem(XComGameState_Unit Unit, name Template)
{
	local XComGameState_Item Item;
	local array<XComGameState_Item> Items;

	if (Template == '')
		return false;
	Items = Unit.GetAllInventoryItems();
	foreach Items(Item)
		if (Item.GetMyTemplateName() == Template)
			return true;
	return false;
}

/** A fraction rounded up by chance (Long War: up when a roll is under the fraction). */
static function int RoundByChance(float F)
{
	local int Whole;

	Whole = FFloor(F);
	return (`SYNC_FRAND_STATIC() < F - Whole) ? Whole + 1 : Whole;
}

defaultproperties
{
}
