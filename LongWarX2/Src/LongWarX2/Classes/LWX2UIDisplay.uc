// One of Enemy Within's 3D UI panels in its base (features/ew-3d-screens.md): XCOM 2's display actor, spawned at EW's place
// with EW's tag (LWX2EWBase.PlaceDisplays), so that EW's screens drawn into XCOM 2's 3D movie stand in the room as in EW.
class LWX2UIDisplay extends UIDisplay_LevelActor;

/** Whether it wears EW's own panel mesh (else XCOM 2's plate, LWX2EWBase.DisplayMesh). */
var bool bEWMesh;

defaultproperties
{
	bNoDelete = false
	bStatic = false
	bMovable = true
}
