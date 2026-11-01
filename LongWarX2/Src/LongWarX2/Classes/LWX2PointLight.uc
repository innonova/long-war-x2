// An Enemy Within map's point light in XCOM 2 (LWX2EWMapPieces.PlaceLights): movable, spawnable, without shadows (a map has
// dozens; EW baked theirs into its lightmaps).
class LWX2PointLight extends PointLightMovable;

defaultproperties
{
	Begin Object Name=PointLightComponent0
		CastShadows=FALSE
		CastStaticShadows=FALSE
		CastDynamicShadows=FALSE
	End Object
	bNoDelete=false
}
