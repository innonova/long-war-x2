// The Floater's Launch aimed (features/lw-aliens.md): XCOM 2's teleport cursor, to a spot with open sky above it, as EW's
// Launch (XGAIBehavior_Floater.IsValidLaunchToLoc, HasOverheadClearance). The Archon King's Icarus Jump does the same,
// in a DLC's package the mod does not count on.
class X2TargetingMethod_LWLaunch extends X2TargetingMethod_Teleport;

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	local name Result;

	Result = super.ValidateTargetLocations(TargetLocations);
	if (Result == 'AA_Success' && !class'X2Ability_LWAliens'.static.OpenSky(TargetLocations[0]))
		Result = 'AA_TileIsBlocked';
	return Result;
}
