// The Respirator Implant (Long War's item 76; XGAction_CriticallyWounded, UIUnitFlag.RealizeCriticallyWounded): the first
// time its wearer's health would run out in a mission, they bleed out instead (XCOM 2's bleed-out forced, whatever its roll),
// and the bleed-out lasts ExtraTurns more. Spent once used (a unit value).
class X2Effect_LWRespirator extends X2Effect_Persistent config(LWGear);

var config int ExtraTurns;

function bool ForcesBleedout(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState)
{
	local UnitValue Spent;

	return !UnitState.GetUnitValue('LWRespiratorSpent', Spent);
}

/** Asked in the mission (UIScreenListener_LongWarX2Tactical): a wearer bleeding out for the first time given ExtraTurns
 *  more, and the implant spent. */
static function Update()
{
	local XComGameState_Unit Unit;
	local XComGameState_Effect BleedOut;
	local XComGameState NewGameState;
	local UnitValue Spent;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!Unit.IsBleedingOut() || !Unit.IsUnitAffectedByEffectName('LWX2_Respirator') || Unit.GetUnitValue('LWRespiratorSpent', Spent))
			continue;
		BleedOut = Unit.GetUnitAffectedByEffectState(class'X2StatusEffects'.default.BleedingOutName);
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the Respirator Implant");
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetUnitFloatValue('LWRespiratorSpent', 1, eCleanup_BeginTactical);
		if (BleedOut != none)
			XComGameState_Effect(NewGameState.ModifyStateObject(class'XComGameState_Effect', BleedOut.ObjectID)).iTurnsRemaining += default.ExtraTurns;
		`TACTICALRULES.SubmitGameState(NewGameState);
		`log("LongWarX2: Respirator Implant:" @ Unit.GetFullName() @ "bleeds out instead of dying," @ default.ExtraTurns @ "turns more", , 'LongWarX2');
	}
}

defaultproperties
{
	EffectName = "LWX2_Respirator"
	DuplicateResponse = eDupe_Ignore
	ExtraTurns = 2
}
