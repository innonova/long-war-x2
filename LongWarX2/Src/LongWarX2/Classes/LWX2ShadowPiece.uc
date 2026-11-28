// A shadow-only copy of a piece of an EW map's upper floors and roofs (LWX2EWMapPieces.ShadowCopies): never drawn, always
// casting the sun's and moon's shadows. XCOM 2's floor hiding takes a building's roof and upper floors out of the main
// render channel when it shows the floor below, and their shadows went with them, so EW's sun fell into the room below
// (aek 2026-11-28: random-bright.png); EW keeps that shadow (its dominant light's static shadow maps). This copy is no
// piece of XCOM 2's building visibility, so it stays.
class LWX2ShadowPiece extends LWX2BasePiece;

defaultproperties
{
	Begin Object Name=StaticMeshComponent0
		HiddenGame=true
		bCastHiddenShadow=true
		CastShadow=true
		bCastDynamicShadow=true
		bAcceptsLights=false
		bAcceptsDynamicLights=false
	End Object
}
