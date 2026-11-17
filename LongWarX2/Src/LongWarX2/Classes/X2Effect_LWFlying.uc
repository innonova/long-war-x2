// A unit in flight (X2Ability_LWFlight; EW's flying): XCOM 2's flying traversal while it lasts; on each shot at it, air
// evasion in place of cover (Long War's AIR_EVADE_DEF, for eAP_AirEvade: the attacker's aim down by it, less the cover the
// unit has here) and no bonus for its being exposed (Long War's flying perk: the attacker's flanking aim and crit taken off
// again). Each of the unit's turns that begins in the air costs a fuel (the fly ability's charges); with none left it comes
// down, onto the floor below if it was over none.
class X2Effect_LWFlying extends X2Effect_PersistentTraversalChange config(LWGear);

var config int AirEvade;

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo Mod;
	local GameRulesCache_VisibilityInfo VisInfo;
	local int Cover;

	if (bMelee || Attacker == none || Target == none || ClassIsChildOf(ToHitType, class'X2AbilityToHitCalc_StandardAim') == false)
		return;
	Mod.Reason = "Flying";
	if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo) && !bFlanking)
		Cover = VisInfo.TargetCover == CT_Standing ? class'X2AbilityToHitCalc_StandardAim'.default.HIGH_COVER_BONUS
			: (VisInfo.TargetCover == CT_MidLevel ? class'X2AbilityToHitCalc_StandardAim'.default.LOW_COVER_BONUS : 0);
	Mod.ModType = eHit_Success;
	Mod.Value = -(default.AirEvade - Cover);
	if (Mod.Value != 0)
		ShotModifiers.AddItem(Mod);
	if (bFlanking)
	{
		Mod.Value = -int(Attacker.GetCurrentStat(eStat_FlankingAimBonus));
		if (Mod.Value != 0)
			ShotModifiers.AddItem(Mod);
		Mod.ModType = eHit_Crit;
		Mod.Value = -int(Attacker.GetCurrentStat(eStat_FlankingCritChance));
		if (Mod.Value != 0)
			ShotModifiers.AddItem(Mod);
	}
}

/** A turn of the unit's begun in the air: a fuel spent; none left, it comes down (the effect over). */
static function bool BurnFuel(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit Unit;
	local XComGameState_Ability Fly;
	local StateObjectReference Ref;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (Unit == none)
		return true;
	Ref = Unit.FindAbility('LWX2_Fly');
	Fly = Ref.ObjectID > 0 ? XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', Ref.ObjectID)) : none;
	if (Fly == none)
		return true;
	if (Fly.iCharges > 0)
		Fly.iCharges--;
	`log("LongWarX2: flight:" @ Unit.GetFullName() @ "fuel" @ Fly.iCharges, , 'LongWarX2');
	if (Fly.iCharges > 0)
		return false;
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Down(Unit);
	return true;
}

/** Back on a floor: the floor below its tile, if it stands over none. */
static function Down(XComGameState_Unit Unit)
{
	local XComWorldData World;
	local TTile Floor;
	local vector At;

	World = `XWORLD;
	if (World.IsFloorTile(Unit.TileLocation))
		return;
	At = World.GetPositionFromTileCoordinates(Unit.TileLocation);
	if (World.GetFloorTileForPosition(At, Floor, true))
	{
		Unit.SetVisibilityLocation(Floor);
		if (XGUnit(Unit.GetVisualizer()) != none && XGUnit(Unit.GetVisualizer()).GetPawn() != none)
			XGUnit(Unit.GetVisualizer()).GetPawn().SetLocation(World.GetPositionFromTileCoordinates(Floor));
		`log("LongWarX2: flight:" @ Unit.GetFullName() @ "comes down to the floor below", , 'LongWarX2');
	}
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit Unit;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
	Unit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (Unit != none)
		Down(Unit);
}

defaultproperties
{
	EffectName = "LWX2_Flying"
	DuplicateResponse = eDupe_Ignore
	EffectTickedFn = BurnFuel
}
