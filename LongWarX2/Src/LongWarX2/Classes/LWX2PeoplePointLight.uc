// EW's people levels' own point lights (the Anim_ levels' movable lights): as LWX2PeopleLight, they light only the base's
// people (the Cinematic_1 channel, LWX2EWBase.PlacePerson), no shadows.
class LWX2PeoplePointLight extends LWX2PointLight;

defaultproperties
{
	Begin Object Name=PointLightComponent0
		LightAffectsClassification=LAC_DYNAMIC_AFFECTING
		bForceDynamicLight=TRUE
		UseDirectLightMap=FALSE
		LightingChannels=(Cinematic_1=TRUE,bInitialized=TRUE)
	End Object
}
