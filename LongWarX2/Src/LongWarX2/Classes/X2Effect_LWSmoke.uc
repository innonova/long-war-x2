// More in the cloud of a Long War smoke grenade thrown by a soldier with Dense Smoke (defence) or Combat Drugs
// (critical chance, will) (features/lw-classes.md): as XCOM 2's smoke effect, it counts while the unit stands in
// smoke and lasts as long as the smoke. The will is given for the effect's time (a stat change has no tile check).
class X2Effect_LWSmoke extends X2Effect_PersistentStatChange;

var int Defense;
var int Crit;

static function X2Effect_LWSmoke Make(name Perk, int InDefense, int InCrit, int InWill)
{
	local X2Effect_LWSmoke Effect;

	Effect = new class'X2Effect_LWSmoke';
	Effect.EffectName = name(Perk $ "_Smoke");
	Effect.BuildPersistentEffect(class'X2Effect_ApplySmokeGrenadeToWorld'.default.Duration + 1, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.DuplicateResponse = eDupe_Refresh;
	Effect.Defense = InDefense;
	Effect.Crit = InCrit;
	if (InWill != 0)
		Effect.AddPersistentStatChange(eStat_Will, InWill);
	return Effect;
}

static function bool InSmoke(XComGameState_Unit Unit)
{
	return Unit != none && Unit.IsInWorldEffectTile(class'X2Effect_ApplySmokeGrenadeToWorld'.default.Class.Name);
}

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;

	if (Defense == 0 || !InSmoke(Target))
		return;
	ShotMod.ModType = eHit_Success;
	ShotMod.Value = -Defense;
	ShotMod.Reason = FriendlyName;
	ShotModifiers.AddItem(ShotMod);
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;

	if (Crit == 0 || !InSmoke(Attacker))
		return;
	ShotMod.ModType = eHit_Crit;
	ShotMod.Value = Crit;
	ShotMod.Reason = FriendlyName;
	ShotModifiers.AddItem(ShotMod);
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	return InSmoke(TargetUnit);
}
