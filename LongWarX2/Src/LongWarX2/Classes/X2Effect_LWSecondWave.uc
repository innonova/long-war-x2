// Long War's tactical second-wave options on a unit (features/lw-second-wave.md; X2Ability_LWSecondWave, on every character):
// - #7 Absolutely Critical: a flanking shot's crit bonus Long War's SW_FLANK_CRIT (100) in place of FLANKING_CRIT_BONUS (50)
//   (XGAbility_Targeted: GetFlankingCritBonus): the shooter's flanking crit stat raised by the difference.
// - #11 Cinematic Mode: XCOM's units' aim up by Long War's ABDUCTION_REWARD_SCI (15); Long War adds it to every recruit,
//   SHIV and MEC as they are made (XGFacility_Barracks, XGStrategySoldier, XGFundingCouncil), here for the battle.
// - #19 Aiming Angles (XGTacticalGameCore.CalcAimingAngleMod, native; Long War's ini explains it): a shot at a unit in cover
//   gains aim the nearer the shooter is to flanking it. Along the cover (XCOM 2's angle to cover 0) the cover's bonus plus
//   SW_AIMING_ANGLE_MAXBONUS, at SW_AIMING_ANGLE_THRESHOLD degrees SW_AIMING_ANGLE_MINBONUS, in between in a line, beyond it
//   none. (XCOM 2's own bonus for a good angle is off: Long War has none without the option. scripts/classes-config.mjs.)
// - #28 Perfect Information (XComPresentationLayer.MSGArmorFragments, MSGOverwatchShot): as an enemy's shot is shown, its
//   chance to hit is announced over the shooter, in Long War's words ("<shooter> uses <shot> on <target>: n%", "<shooter>
//   takes a reaction shot: n%"; LongWarX2.int, written on the player's machine).
class X2Effect_LWSecondWave extends X2Effect_ModifyStats config(LWGear);

/** Long War's SW_FLANK_CRIT and FLANKING_CRIT_BONUS; Cinematic Mode's aim (ABDUCTION_REWARD_SCI). */
var config int AbsolutelyCriticalFlankCrit, FlankCrit, CinematicAim;
/** Aiming Angles: Long War's SW_AIMING_ANGLE_THRESHOLD (degrees), _MINBONUS, _MAXBONUS. */
var config float AimingAngleThreshold, AimingAngleMin, AimingAngleMax;
/** Perfect Information's words: Long War's m_strArmorExplodeFragments and eELS_UnitReactionShot (XGParam StrValue0-2). */
var localized string UsesOn, ReactionShot;
/** (Test aid counters: shots seen by Perfect Information's listener, and announced; the control port's 'perfectinfo'.) */
var int Seen, Announced;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local StatChange Change;

	if (class'LWX2SecondWave'.static.On(7))
	{
		Change.StatType = eStat_FlankingCritChance;
		Change.StatAmount = default.AbsolutelyCriticalFlankCrit - default.FlankCrit;
		Change.ModOp = MODOP_Addition;
		NewEffectState.StatChanges.AddItem(Change);
	}
	if (class'LWX2SecondWave'.static.On(11) && XComGameState_Unit(kNewTargetState) != none && XComGameState_Unit(kNewTargetState).GetTeam() == eTeam_XCom)
	{
		Change.StatType = eStat_Offense;
		Change.StatAmount = default.CinematicAim;
		Change.ModOp = MODOP_Addition;
		NewEffectState.StatChanges.AddItem(Change);
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local Object EffectObj;

	super.RegisterForEvents(EffectGameState);
	EffectObj = EffectGameState;
	`XEVENTMGR.RegisterForEvent(EffectObj, 'AbilityActivated', OnShotShown, ELD_OnVisualizationBlockStarted, , , , EffectObj);
}

/** Perfect Information: the unit's shot is being shown; if it is an enemy's, its chance over the shooter. */
static function EventListenerReturn OnShotShown(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Effect EffectState;
	local XComGameState_Ability Ability;
	local XComGameStateContext_Ability Context;
	local XComGameState_Unit Shooter, Target;
	local XGParamTag Tag;
	local string Text;

	EffectState = XComGameState_Effect(CallbackData);
	Ability = XComGameState_Ability(EventData);
	Context = GameState != none ? XComGameStateContext_Ability(GameState.GetContext()) : none;
	if (EffectState != none && X2Effect_LWSecondWave(EffectState.GetX2Effect()) != none)
		X2Effect_LWSecondWave(EffectState.GetX2Effect()).Seen++;
	if (EffectState == none || Ability == none || Context == none || Context.InterruptionStatus == eInterruptionStatus_Interrupt
		|| !class'LWX2SecondWave'.static.On(28))
		return ELR_NoInterrupt;
	if (Context.InputContext.SourceObject.ObjectID != EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		return ELR_NoInterrupt;
	if (X2AbilityToHitCalc_StandardAim(Ability.GetMyTemplate().AbilityToHitCalc) == none)
		return ELR_NoInterrupt;
	Shooter = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
	if (Shooter == none || Target == none || Shooter.GetTeam() == eTeam_XCom)
		return ELR_NoInterrupt;
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.StrValue0 = Shooter.GetName(eNameType_Full);
	Tag.StrValue1 = Ability.GetMyFriendlyName();
	Tag.StrValue2 = Target.GetName(eNameType_Full);
	// (A reaction shot: XCOM 2's overwatch shots are ones the unit did not choose in its own turn.)
	if (Ability.GetMyTemplate().AbilityTriggers.Length > 0 && X2AbilityTrigger_Event(Ability.GetMyTemplate().AbilityTriggers[0]) != none)
		Text = default.ReactionShot != "" ? `XEXPAND.ExpandString(default.ReactionShot) : Tag.StrValue0 @ "takes a reaction shot";
	else
		Text = default.UsesOn != "" ? `XEXPAND.ExpandString(default.UsesOn) : Tag.StrValue0 @ "uses" @ Tag.StrValue1 @ "on" @ Tag.StrValue2;
	X2Effect_LWSecondWave(EffectState.GetX2Effect()).Announced++;
	// (Shown at once, as XCOM 2's flyovers are: queued, it would wait for the visualization to end.)
	`PRES.QueueWorldMessage(Text $ ":" @ Context.ResultContext.CalculatedHitChance $ "%", `XWORLD.GetPositionFromTileCoordinates(Shooter.TileLocation),
		Shooter.GetReference(), eColor_Bad, , , eTeam_All, , , 6.0, , , , , , , , , , true);
	return ELR_NoInterrupt;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo M;
	local int Bonus;

	if (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID != Attacker.ObjectID)
		return;
	Bonus = AimingAngleBonus(Attacker, Target, bMelee, bFlanking, bIndirectFire);
	if (Bonus == 0)
		return;
	M.ModType = eHit_Success;
	M.Value = Bonus;
	M.Reason = class'XLocalizedData'.default.AngleToTargetCover;
	ShotModifiers.AddItem(M);
}

/** Aiming Angles' bonus for this shot; 0 without the option, out of cover or beyond the threshold. */
static function int AimingAngleBonus(XComGameState_Unit Attacker, XComGameState_Unit Target, bool bMelee, bool bFlanking, bool bIndirectFire)
{
	local GameRulesCache_VisibilityInfo VisInfo;
	local float Cover, Angle;

	if (!class'LWX2SecondWave'.static.On(19) || bMelee || bFlanking || bIndirectFire || Target == none || !Target.CanTakeCover()
		|| default.AimingAngleThreshold <= 0)
		return 0;
	if (!`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo))
		return 0;
	switch (VisInfo.TargetCover)
	{
	case CT_MidLevel:
		Cover = class'X2AbilityToHitCalc_StandardAim'.default.LOW_COVER_BONUS;
		break;
	case CT_Standing:
		Cover = class'X2AbilityToHitCalc_StandardAim'.default.HIGH_COVER_BONUS;
		break;
	default:
		return 0;
	}
	Angle = CoverAngle(Attacker, Target);
	if (Angle < 0 || Angle >= default.AimingAngleThreshold)
		return 0;
	return Round(Lerp(Cover + default.AimingAngleMax, default.AimingAngleMin, Angle / default.AimingAngleThreshold));
}

/** The angle from the shooter to the target relative to the target's cover, in degrees (XCOM 2's: 0 along the cover, 90
 *  straight at it; -1 without cover). Asked of the world: the visibility cache's own is not filled in. */
static function float CoverAngle(XComGameState_Unit Attacker, XComGameState_Unit Target)
{
	local vector From, To;
	local float Angle;

	From = `XWORLD.GetPositionFromTileCoordinates(Attacker.TileLocation);
	To = `XWORLD.GetPositionFromTileCoordinates(Target.TileLocation);
	Angle = -1;
	`XWORLD.GetCoverTypeForTarget(From, To, Angle);
	return Angle;
}

defaultproperties
{
	EffectName = "LWX2_SecondWave"
	DuplicateResponse = eDupe_Ignore
}
