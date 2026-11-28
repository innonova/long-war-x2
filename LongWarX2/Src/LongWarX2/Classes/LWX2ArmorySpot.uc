// XCOM 2's armory spot on EW's pad (UILWEWSoldierSummary.ArmoryPlacementAt): a PointInSpace tagged UIPawnLocation_Armory,
// where XCOM 2's Customize puts the soldier before or after (XComCharacterCustomization.CreatePawnVisuals). XCOM 2 places
// its own in the Avenger's levels, which EW's base does not load; PointInSpace itself is placed only (static, not to be
// spawned), so this one may be spawned and moved.
class LWX2ArmorySpot extends PointInSpace;

defaultproperties
{
	bStatic = false
	bNoDelete = false
	bMovable = true
	Tag = UIPawnLocation_Armory
}
