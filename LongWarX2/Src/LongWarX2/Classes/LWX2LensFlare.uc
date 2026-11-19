// One of EW's lens flares in its base (features/ew-emitters.md): Unreal's LensFlareSource is placed in levels only
// (bNoDelete), so a spawnable one of ours.
class LWX2LensFlare extends LensFlareSource;

defaultproperties
{
	bNoDelete = false
	bStatic = false
}
