// Long War's Secondary Heart gene mod (features/lw-genemods.md): "Causes soldiers to bleed out instead of dying the
// first time they go to zero health in a mission. The bleed-out timer is extended by 2 turns." XCOM 2 asks the
// effects named in X2AbilityTemplateManager.PreDeathCheckEffects (XComGameData.ini) before a unit dies; this one puts
// the unit into bleeding out instead (as XComGameState_Unit.ApplyBleedingOut does, which is protected), once a
// mission, and lengthens the timer.
class X2Effect_LWSecondaryHeart extends X2Effect_Persistent;

var int ExtraTurns;

function bool PreDeathCheck(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState)
{
	local EffectAppliedData ApplyData;
	local X2Effect BleedOut;
	local XComGameState_Effect Bleeding;
	local UnitValue Used;

	if (UnitState.GetUnitValue(EffectName, Used) && Used.fValue > 0)
		return false;
	BleedOut = class'X2StatusEffects'.static.CreateBleedingOutStatusEffect();
	ApplyData.PlayerStateObjectRef = UnitState.ControllingPlayer;
	ApplyData.SourceStateObjectRef = UnitState.GetReference();
	ApplyData.TargetStateObjectRef = UnitState.GetReference();
	ApplyData.EffectRef.LookupType = TELT_BleedOutEffect;
	if (BleedOut.ApplyEffect(ApplyData, UnitState, NewGameState) != 'AA_Success')
		return false;
	UnitState.SetUnitFloatValue(EffectName, 1, eCleanup_BeginTactical);
	Bleeding = UnitState.GetUnitAffectedByEffectState(class'X2StatusEffects'.default.BleedingOutName);
	if (Bleeding != none)
	{
		Bleeding = XComGameState_Effect(NewGameState.ModifyStateObject(class'XComGameState_Effect', Bleeding.ObjectID));
		Bleeding.iTurnsRemaining += ExtraTurns;
	}
	`log("LongWarX2: gene mods: Secondary Heart:" @ UnitState.GetFullName() @ "bleeds out instead of dying", , 'LongWarX2');
	return true;
}

defaultproperties
{
	EffectName = "LWSecondaryHeart"
	DuplicateResponse = eDupe_Ignore
}
