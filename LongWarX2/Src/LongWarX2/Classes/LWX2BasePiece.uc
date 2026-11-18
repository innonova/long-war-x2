// A piece of EW's base (LWX2EWBase), as XCOM 2's spawnable mesh actor but with no physics at all: the base needs none, and
// making it cooked each piece's collision from its mesh's vertices at runtime (UStaticMeshComponent.InitComponentRBPhys,
// "No Cached Per-Tri StaticMesh Physics Data … Cooking"), reading the converted meshes' vertex positions where they were
// no longer held: the crash at a campaign's start now and then (features/strategy-flow.md).
class LWX2BasePiece extends DynamicSMActor_Spawnable;

defaultproperties
{
	Begin Object Name=StaticMeshComponent0
		bDisableAllRigidBody=true
		BlockRigidBody=false
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
	End Object
	bCollideActors=false
	bBlockActors=false
}
