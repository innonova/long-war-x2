// EW's static sun (a DirectionalLight, baked into EW's light maps) on a mission map whose pieces carry those light maps:
// it lights the units only (the dynamic lighting channels), not the map a second time (LWX2EWMapPieces.UnitsOnly).
class LWX2UnitsSunLight extends LWX2SunLight;

defaultproperties
{
	Begin Object Name=DominantDirectionalLightComponent0
		LightingChannels=(bInitialized=TRUE,BSP=FALSE,Static=FALSE,Dynamic=TRUE,CompositeDynamic=TRUE)
	End Object
}
