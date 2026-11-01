// A Long War perk's bonuses, each under its own condition (features/lw-classes.md): aim, critical
// chance and damage when shooting, defence and immunity to critical hits when shot at. The
// numbers and conditions come from the perk's definition (X2Ability_LWStandins, generated from
// Long War's and EW's values). Conditions:
//   Always; NoAllyWithin (Param tiles); TargetHealthBelow (Param, a fraction of its maximum);
//   PerVisibleEnemy (times the enemies the soldier sees, up to MaxStacks); HeightAdvantage;
//   NoActionTaken (the soldier has not acted this turn); TargetInFullCover; InLowCover (as the
//   target); PrimaryOrPistol, Primary (the shot's weapon); TargetRobotic.
class X2Effect_LWModifiers extends X2Effect_Persistent;

var int Aim, Crit, Defense, Damage, CritAgainst;
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
	case 'PrimaryOrPistol':
		Weapon = AbilityState != none ? AbilityState.GetSourceWeapon() : none;
		return (Weapon != none && (Weapon.InventorySlot == eInvSlot_PrimaryWeapon || Weapon.InventorySlot == eInvSlot_SecondaryWeapon)) ? 1 : 0;
	}
	return 0;
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
	if ((Damage == 0 && DamagePct == 0) || CurrentDamage <= 0)
		return 0;
	bCrit = AppliedData.AbilityResultContext.HitResult == eHit_Crit;
	if (DamagePct != 0)
		return (CurrentDamage * DamagePct / 100) * Holds(DamageIf, Attacker, XComGameState_Unit(TargetDamageable), AbilityState, false);
	return Damage * Holds(DamageIf, Attacker, XComGameState_Unit(TargetDamageable), AbilityState, false);
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "LWModifiers"
}
