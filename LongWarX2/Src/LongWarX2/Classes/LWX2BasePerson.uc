// One of Enemy Within's people in its base (features/ew-base-people.md): EW's skeletal mesh with EW's AnimSets, looping
// the animation EW's matinee plays on it (SkeletalMeshActor's own AnimNodeSequence), placed by LWX2EWBase.PlacePeople.
class LWX2BasePerson extends SkeletalMeshActor;

/** EW's mesh, AnimSets, the loop, and its slots' stand-ins. */
function Setup(SkeletalMesh Mesh, array<AnimSet> Sets, name Loop, array<MaterialInterface> Slots, optional PhysicsAsset Bodies)
{
	local AnimNodeSequence Seq;
	local int i;

	SkeletalMeshComponent.SetSkeletalMesh(Mesh);
	SkeletalMeshComponent.AnimSets = Sets;
	for (i = 0; i < Slots.Length; i++)
		if (Slots[i] != none)
			SkeletalMeshComponent.SetMaterial(i, Slots[i]);
	SkeletalMeshComponent.UpdateAnimations();
	// (Bounds from its bodies, which follow its bones, and its bones kept moving while it is out of view: else it stays
	// culled where the bounds were last, the Genetics Lab's canisters at the rack instead of the column.)
	if (Bodies != none)
	{
		SkeletalMeshComponent.SetPhysicsAsset(Bodies);
		SkeletalMeshComponent.bUpdateSkelWhenNotRendered = true;
		SkeletalMeshComponent.bTickAnimNodesWhenNotRendered = true;
	}
	Seq = AnimNodeSequence(SkeletalMeshComponent.Animations);
	if (Seq != none && Loop != '')
	{
		Seq.SetAnim(Loop);
		Seq.PlayAnim(true, 1.0, FRand());
	}
}

defaultproperties
{
	bNoDelete = false
	bStatic = false
}
