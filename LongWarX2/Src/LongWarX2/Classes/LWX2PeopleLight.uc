// EW's base's light for its people (Command1's movable directional light, on the Cinematic and Unnamed lighting channels
// that only EW's people answer): ours lights only the base's people, who are put on the Cinematic_1 channel
// (LWX2EWBase.PlacePerson); the rooms' placed lights and baked light leave them as they are. Spawnable.
class LWX2PeopleLight extends DirectionalLightToggleable;

defaultproperties
{
	Begin Object Name=DirectionalLightComponent0
		LightAffectsClassification=LAC_DYNAMIC_AFFECTING
		CastShadows=FALSE
		CastStaticShadows=FALSE
		CastDynamicShadows=FALSE
		bForceDynamicLight=TRUE
		UseDirectLightMap=FALSE
		LightingChannels=(Cinematic_1=TRUE,bInitialized=TRUE)
	End Object
	bNoDelete=false
	bStatic=false
}
