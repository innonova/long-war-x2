// An Enemy Within base's point light (LWX2EWBase): as LWX2PointLight, without shadows (EW baked them into lightmaps; its
// base has hundreds of lights, more shadowing ones than XCOM 2 draws).
class LWX2BasePointLight extends LWX2PointLight;

defaultproperties
{
	Begin Object Name=PointLightComponent0
		CastShadows=false
		CastDynamicShadows=false
	End Object
}
