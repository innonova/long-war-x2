// Bioelectric Skin's reveal (features/lw-genemods.md): EW shows every enemy within BioelectricSkinRange (12 of its metres,
// 64 units each: 768 units, eight tiles) of a soldier with the gene mod, through walls and fog, with an aura
// (XGUnitNativeBase.SetEnableBioElectricParticles; XComUnitPawn: "visible only with Bioelectric Skin"). It shows them and
// no more: they cannot be shot unless seen. Here: the unit drawn even out of sight (its visualizer forced visible, as
// X2Action_Fire shows a target it cannot see; the game's own visibility, which targeting uses, untouched) and outlined as
// XCOM 2 outlines a unit the Reaper's Target Definition marked (XComUnitPawn.bAffectedByTargetDefinition, as
// X2Action_TargetDefinition sets it); both switched on and off as enemies come within reach and leave it. A unit Target
// Definition itself marked keeps its outline; the dead are left as their death left them.
class LWX2Bioelectric extends Object;

const REACH = 768.0;

/** Asked twice a second in a mission (UIScreenListener_LongWarX2Tactical). */
static function Update()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local array<vector> Skins;
	local vector At;
	local XGUnit Visualizer;
	local XComUnitPawn Pawn;
	local bool bShow, bMarked;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_XCom && Unit.IsAlive() && !Unit.bRemovedFromPlay && Unit.FindAbility('LW_BioelectricSkin').ObjectID > 0)
			Skins.AddItem(`XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation));
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() != eTeam_Alien || Unit.GetMyTemplate().bIsCosmetic)
			continue;
		Visualizer = XGUnit(Unit.GetVisualizer());
		Pawn = Visualizer != none ? Visualizer.GetPawn() : none;
		if (Pawn == none)
			continue;
		bShow = false;
		if (Unit.IsAlive() && !Unit.bRemovedFromPlay)
		{
			At = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
			bShow = Near(Skins, At);
		}
		bMarked = Unit.IsUnitAffectedByEffectName('TargetDefinition');
		if (Pawn.bAffectedByTargetDefinition == (bShow || bMarked))
			continue;
		// (Shown by this, or no longer: drawn as the game's visibility has it once more, unless dead.)
		if (Unit.IsAlive() && !bMarked)
		{
			Visualizer.SetForceVisibility(bShow ? eForceVisible : eForceNone);
			Pawn.UpdatePawnVisibility();
		}
		Pawn.bAffectedByTargetDefinition = bShow || bMarked;
		Pawn.MarkAuxParametersAsDirty(Pawn.m_bAuxParamNeedsPrimary, Pawn.m_bAuxParamNeedsSecondary, Pawn.m_bAuxParamUse3POutline);
	}
}

static function bool Near(array<vector> Skins, vector At)
{
	local vector S;

	foreach Skins(S)
		if (VSize(S - At) <= REACH)
			return true;
	return false;
}
