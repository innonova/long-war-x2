// A Long War perk's bonuses, each under its own condition (features/lw-classes.md): aim, critical
// chance and damage when shooting, defence and immunity to critical hits when shot at. The
// numbers and conditions come from the perk's definition (X2Ability_LWStandins, generated from
// Long War's and EW's values). Conditions:
//   Always; NoAllyWithin (Param tiles); TargetHealthBelow (Param, a fraction of its maximum);
//   PerVisibleEnemy (times the enemies the soldier sees, up to MaxStacks); HeightAdvantage;
//   NoActionTaken (the soldier has not acted this turn); TargetInFullCover; InLowCover (as the
//   target); PrimaryOrPistol, Primary (the shot's weapon); TargetRobotic; Explosive (a Long War grenade or the
//   rocket launcher); GunnerShot (a standard or Rapid Fire shot with an autorifle or LMG); InCover (as the target:
//   in cover and not flanked); AfterRunAndGun (Run and Gun used this turn).
class X2Effect_LWModifiers extends X2Effect_Persistent;

var int Aim, Crit, Defense, Damage, CritAgainst;
/** A second damage bonus under its own condition. */
var int Damage2;
var name Damage2If;
/** Damage taken less under its condition (as the target); crit damage more, a share of the weapon's crit damage. */
var int DamageTaken;
var name DamageTakenIf;
var int CritDamagePct;
var name CritDamageIf;
/** Extra damage as a percentage of the shot's, under DamageIf (HEAT Ammo). */
var int DamagePct;
var name AimIf, CritIf, DefenseIf, DamageIf;
var float Param;
var int MaxStacks;
var string Reason;
/** Set while working out damage: the shot is a critical hit. */
var bool bCrit;

/** How many times the condition holds for this shot: 0 (no), 1, or the count for PerVisibleEnemy. */
function int Holds(name Condition, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, bool bAsTarget)
{
	local XComGameState_Unit Me, Other;
	local GameRulesCache_VisibilityInfo VisInfo;
	local XComGameState_Item Weapon;
	local int n;

	Me = bAsTarget ? Target : Attacker;
	Other = bAsTarget ? Attacker : Target;
	switch (Condition)
	{
	case '':
	case 'Always':
		return 1;
	case 'NoAllyWithin':
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Other)
		{
			if (Other.ObjectID != Me.ObjectID && Other.GetTeam() == Me.GetTeam() && Other.IsAlive() && !Other.bRemovedFromPlay
				&& Me.TileDistanceBetween(Other) < Param)
				return 0;
		}
		return 1;
	case 'TargetHealthBelow':
		return (Target != none && Target.GetCurrentStat(eStat_HP) <= Param * Target.GetMaxStat(eStat_HP)) ? 1 : 0;
	case 'PerVisibleEnemy':
		n = class'X2TacticalVisibilityHelpers'.static.GetNumVisibleEnemyTargetsToSource(Me.ObjectID);
		return MaxStacks > 0 ? Min(n, MaxStacks) : n;
	case 'HeightAdvantage':
		return (Other != none && Me.HasHeightAdvantageOver(Other, !bAsTarget)) ? 1 : 0;
	case 'NoActionTaken':
		return Me.NumAllActionPoints() >= class'X2CharacterTemplateManager'.default.StandardActionsPerTurn ? 1 : 0;
	case 'TargetInFullCover':
	case 'InLowCover':
		if (Attacker == none || Target == none || !`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo))
			return 0;
		if (Condition == 'InLowCover')
			return VisInfo.TargetCover == CT_MidLevel ? 1 : 0;
		return VisInfo.TargetCover == CT_Standing ? 1 : 0;
	case 'CritPerSquadVisibleEnemy':
		// On a critical hit: one per enemy the squad sees (the most any of them sees), up to MaxStacks.
		if (!bCrit)
			return 0;
		n = 0;
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Other)
			if (Other.GetTeam() == Me.GetTeam() && Other.IsAlive() && !Other.bRemovedFromPlay)
				n = Max(n, class'X2TacticalVisibilityHelpers'.static.GetNumVisibleEnemyTargetsToSource(Other.ObjectID));
		return MaxStacks > 0 ? Min(n, MaxStacks) : n;
	case 'TargetRobotic':
		return (Target != none && Target.IsRobotic()) ? 1 : 0;
	case 'Primary':
		Weapon = AbilityState != none ? AbilityState.GetSourceWeapon() : none;
		return (Weapon != none && Weapon.InventorySlot == eInvSlot_PrimaryWeapon) ? 1 : 0;
	case 'InCover':
		if (Attacker == none || Target == none || !`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo))
			return 0;
		// Flanked, the attacker sees no cover.
		return VisInfo.TargetCover != CT_None ? 1 : 0;
	case 'AfterRunAndGun':
		return RunAndGunThisTurn(Me) ? 1 : 0;
	case 'Explosive':
		Weapon = AbilityState != none ? AbilityState.GetSourceWeapon() : none;
		return (Weapon != none && (X2GrenadeTemplate(Weapon.GetMyTemplate()) != none || Weapon.GetMyTemplateName() == 'LWSmall_218')) ? 1 : 0;
	case 'GunnerShot':
		Weapon = AbilityState != none ? AbilityState.GetSourceWeapon() : none;
		if (Weapon == none || (AbilityState.GetMyTemplateName() != 'StandardShot' && AbilityState.GetMyTemplateName() != 'RapidFire' && AbilityState.GetMyTemplateName() != 'RapidFire2'))
			return 0;
		n = class'LWGearRules'.default.Weapons.Find('Item', int(Mid(string(Weapon.GetMyTemplateName()), 9)));
		return (Left(string(Weapon.GetMyTemplateName()), 9) == "LWWeapon_" && n != INDEX_NONE
			&& (class'LWGearRules'.default.Weapons[n].Family == 'Autorifle' || class'LWGearRules'.default.Weapons[n].Family == 'LMG')) ? 1 : 0;
	case 'PrimaryOrPistol':
		Weapon = AbilityState != none ? AbilityState.GetSourceWeapon() : none;
		return (Weapon != none && (Weapon.InventorySlot == eInvSlot_PrimaryWeapon || Weapon.InventorySlot == eInvSlot_SecondaryWeapon)) ? 1 : 0;
	}
	return 0;
}

/** Run and Gun used this turn: its cooldown is at its full length. */
static function bool RunAndGunThisTurn(XComGameState_Unit Unit)
{
	local StateObjectReference Ref;
	local XComGameState_Ability Ability;

	if (Unit == none)
		return false;
	Ref = Unit.FindAbility('RunAndGun');
	Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
	return Ability != none && Ability.GetMyTemplate().AbilityCooldown != none && Ability.iCooldown >= Ability.GetMyTemplate().AbilityCooldown.iNumTurns;
}

function AddModifier(out array<ShotModifierInfo> ShotModifiers, EAbilityHitResult Kind, int Value)
{
	local ShotModifierInfo Info;

	if (Value == 0)
		return;
	Info.ModType = Kind;
	Info.Value = Value;
	Info.Reason = Reason;
	ShotModifiers.AddItem(Info);
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	if (Aim != 0)
		AddModifier(ShotModifiers, eHit_Success, Aim * Holds(AimIf, Attacker, Target, AbilityState, false));
	if (Crit != 0)
		AddModifier(ShotModifiers, eHit_Crit, Crit * Holds(CritIf, Attacker, Target, AbilityState, false));
}

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	if (Defense != 0)
		AddModifier(ShotModifiers, eHit_Success, -Defense * Holds(DefenseIf, Attacker, Target, AbilityState, true));
	if (CritAgainst != 0)
		AddModifier(ShotModifiers, eHit_Crit, -CritAgainst);
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local int Bonus;
	local X2WeaponTemplate Weapon;

	if ((Damage == 0 && DamagePct == 0 && Damage2 == 0 && CritDamagePct == 0) || CurrentDamage <= 0)
		return 0;
	bCrit = AppliedData.AbilityResultContext.HitResult == eHit_Crit;
	if (CritDamagePct != 0 && bCrit && AbilityState != none && AbilityState.GetSourceWeapon() != none)
	{
		Weapon = X2WeaponTemplate(AbilityState.GetSourceWeapon().GetMyTemplate());
		if (Weapon != none)
			Bonus += Weapon.BaseDamage.Crit * CritDamagePct / 100 * Holds(CritDamageIf, Attacker, XComGameState_Unit(TargetDamageable), AbilityState, false);
	}
	if (DamagePct != 0)
		Bonus += (CurrentDamage * DamagePct / 100) * Holds(DamageIf, Attacker, XComGameState_Unit(TargetDamageable), AbilityState, false);
	else if (Damage != 0)
		Bonus += Damage * Holds(DamageIf, Attacker, XComGameState_Unit(TargetDamageable), AbilityState, false);
	if (Damage2 != 0)
		Bonus += Damage2 * Holds(Damage2If, Attacker, XComGameState_Unit(TargetDamageable), AbilityState, false);
	return Bonus;
}

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState)
{
	if (DamageTaken == 0 || CurrentDamage <= 0)
		return 0;
	return -Min(CurrentDamage, DamageTaken * Holds(DamageTakenIf, Attacker, XComGameState_Unit(TargetDamageable), AbilityState, true));
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "LWModifiers"
}
