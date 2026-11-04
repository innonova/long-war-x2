// What Long War's passive small items do beyond stats (features/lw-gear.md, phase 5): Hi-Cap and Drum Mags (a shot
// with the primary weapon costs a half, a third of the ammo: every second, two in three shots refunded;
// XGAbility_Targeted), the extra Rocket (another charge for the rocket launcher; XGUnit.UpdateItemCharges), the
// Chameleon Suit (reaction shots never crit its wearer).
class X2Effect_LWSmallItem extends X2Effect_Persistent;

var int AmmoMultiplier;
var int ExtraRockets;
var int CritAgainstReaction;
/** Crit for its carrier's shots once the Foundry's S.C.O.P.E. (project 18) is done, not a pistol's (LWGearRules.LWSmallDef). */
var int ScopeCrit;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Unit;
	local XComGameState_Item Launcher;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
	Unit = XComGameState_Unit(kNewTargetState);
	if (Unit == none || ExtraRockets <= 0)
		return;
	Launcher = Unit.GetItemInSlot(eInvSlot_SecondaryWeapon, NewGameState);
	if (Launcher == none || Launcher.GetMyTemplateName() != 'LWSmall_218')
		return;
	Launcher = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Launcher.ObjectID));
	Launcher.Ammo += ExtraRockets;
}

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local UnitValue Shots;
	local XComGameState_Unit Unit;

	if (AmmoMultiplier <= 1 || AffectWeapon == none || AffectWeapon.InventorySlot != eInvSlot_PrimaryWeapon)
		return false;
	if (AbilityContext.InputContext.SourceObject.ObjectID != EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		return false;
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', SourceUnit.ObjectID));
	Unit.GetUnitValue('LWAmmoShots', Shots);
	Unit.SetUnitFloatValue('LWAmmoShots', Shots.fValue + 1, eCleanup_BeginTactical);
	// One shot in AmmoMultiplier pays; the others are given their round back.
	if (int(Shots.fValue) % AmmoMultiplier != 0)
	{
		AffectWeapon = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', AffectWeapon.ObjectID));
		AffectWeapon.Ammo = Min(AffectWeapon.Ammo + 1, AffectWeapon.GetClipSize());
	}
	return false;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo Info;

	if (ScopeCrit == 0 || AbilityState == none || bMelee || !class'X2Effect_LWFoundry'.static.Done(18))
		return;
	if (AbilityState.GetSourceWeapon() == none || class'X2Effect_LWFoundry'.static.IsPistol(AbilityState.GetSourceWeapon()))
		return;
	Info.ModType = eHit_Crit;
	Info.Value = ScopeCrit;
	Info.Reason = "S.C.O.P.E.";
	ShotModifiers.AddItem(Info);
}

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo Info;
	local X2AbilityToHitCalc_StandardAim Aim;

	if (CritAgainstReaction == 0 || AbilityState == none)
		return;
	Aim = X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);
	if (Aim == none || !Aim.bReactionFire)
		return;
	Info.ModType = eHit_Crit;
	Info.Value = -CritAgainstReaction;
	Info.Reason = FriendlyName;
	ShotModifiers.AddItem(Info);
}

defaultproperties
{
	DuplicateResponse = eDupe_Allow
	EffectName = "LWSmallItem"
}
