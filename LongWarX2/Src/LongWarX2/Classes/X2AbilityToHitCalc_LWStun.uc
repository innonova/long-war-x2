// Long War's arc thrower's chance: Enemy Within's stun chance (native in its code, not readable) times Long War's
// UFO_PSI_LINK_SURVIVE, 0.85 (XGTacticalGameCore.TryStunned). APPROXIMATION of Enemy Within's part: the more of its
// health the alien has left, the less the chance: 100 - 50 x its health's share (a full-health alien 50 %, near
// death almost 100 %), times 0.85.
class X2AbilityToHitCalc_LWStun extends X2AbilityToHitCalc config(LWGear);

var config float StunBalance;

protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown m_ShotBreakdown, optional bool bDebugLog = false)
{
	local XComGameState_Unit Target;
	local ShotBreakdown Empty;
	local int Chance;

	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
	m_ShotBreakdown = Empty;
	if (Target == none || Target.GetMaxStat(eStat_HP) <= 0)
		return 0;
	Chance = int((100.0 - 50.0 * Target.GetCurrentStat(eStat_HP) / Target.GetMaxStat(eStat_HP)) * StunBalance);
	AddModifier(Chance, class'XLocalizedData'.default.BaseChance, m_ShotBreakdown, eHit_Success, bDebugLog);
	FinalizeHitChance(m_ShotBreakdown, bDebugLog);
	return m_ShotBreakdown.FinalHitChance;
}

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local ShotBreakdown Breakdown;
	local int Chance;

	Chance = GetHitChance(kAbility, kTarget, Breakdown);
	ResultContext.HitResult = `SYNC_RAND(100) < Chance ? eHit_Success : eHit_Miss;
	`log("LongWarX2: arc thrower:" @ Chance $ "% ->" @ ResultContext.HitResult, , 'LongWarX2');
}
