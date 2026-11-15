// An Enemy Within base's spot light (LWX2EWBase): as LWX2SpotLight, without shadows (EW baked them into lightmaps; its
// base has hundreds of lights, more shadowing ones than XCOM 2 draws).
class LWX2BaseSpotLight extends LWX2SpotLight;

defaultproperties
{
	Begin Object Name=SpotLightComponent0
		CastShadows=false
		CastDynamicShadows=false
	End Object
}
