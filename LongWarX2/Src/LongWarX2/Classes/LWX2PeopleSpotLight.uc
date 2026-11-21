// EW's people levels' own spot lights (the Anim_ levels' movable lights: the labs' key light on Vahlen, brightness 8):
// as LWX2PeopleLight, they light only the base's people (the Cinematic_1 channel, LWX2EWBase.PlacePerson), no shadows.
class LWX2PeopleSpotLight extends LWX2SpotLight;

defaultproperties
{
	Begin Object Name=SpotLightComponent0
		LightAffectsClassification=LAC_DYNAMIC_AFFECTING
		CastShadows=FALSE
		CastStaticShadows=FALSE
		CastDynamicShadows=FALSE
		bForceDynamicLight=TRUE
		UseDirectLightMap=FALSE
		LightingChannels=(Cinematic_1=TRUE,bInitialized=TRUE)
	End Object
}
