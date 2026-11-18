// One of Enemy Within's people in its base (features/ew-base-people.md): EW's skeletal mesh with EW's AnimSets, looping
// the animation EW's matinee plays on it (SkeletalMeshActor's own AnimNodeSequence), placed by LWX2EWBase.PlacePeople.
class LWX2BasePerson extends SkeletalMeshActor;

/** EW's mesh, AnimSets, the loop, and its slots' stand-ins. */
function Setup(SkeletalMesh Mesh, array<AnimSet> Sets, name Loop, array<MaterialInterface> Slots)
{
	local AnimNodeSequence Seq;
	local int i;

	SkeletalMeshComponent.SetSkeletalMesh(Mesh);
	SkeletalMeshComponent.AnimSets = Sets;
	for (i = 0; i < Slots.Length; i++)
		if (Slots[i] != none)
			SkeletalMeshComponent.SetMaterial(i, Slots[i]);
	SkeletalMeshComponent.UpdateAnimations();
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
