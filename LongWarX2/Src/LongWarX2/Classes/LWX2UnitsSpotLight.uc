// EW's static spot light on a mission map whose pieces carry its light maps: the units only (LWX2EWMapPieces.UnitsOnly).
class LWX2UnitsSpotLight extends LWX2SpotLight;

defaultproperties
{
	Begin Object Name=SpotLightComponent0
		CastShadows=FALSE
		CastStaticShadows=FALSE
		CastDynamicShadows=FALSE
		LightingChannels=(bInitialized=TRUE,BSP=FALSE,Static=FALSE,Dynamic=TRUE,CompositeDynamic=TRUE)
	End Object
}
