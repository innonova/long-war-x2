// An Enemy Within unit shown in XCOM 2, as an animated skeletal mesh with nothing
// of a unit about it (features/hard-parts.md, experiment 1): the proof that EW's
// content, converted on the player's machine (tools/convert/), loads and draws in
// the game. Its package is the player's own, in the mod's Content folder, never
// shipped.
class LWX2EWUnitDisplay extends SkeletalMeshActorSpawnable config(LWAirWar);

/** What to show: package objects by path, and the animation to loop. */
var config string MeshPath;
var config string AnimSetPath;
var config name IdleAnim;
/** The material to put on it; when it does not load, the mesh keeps its own. */
var config string MaterialPath;

/** Shown beside a pawn, facing it: loads everything, says in the log what did and did not. */
function bool ShowBeside(Actor Next)
{
	local SkeletalMesh Mesh;
	local AnimSet Set;
	local MaterialInterface Mat;
	local AnimNodeSequence Seq;
	local vector Offset;

	Mesh = SkeletalMesh(DynamicLoadObject(MeshPath, class'SkeletalMesh', true));
	`log("LongWarX2: EW unit: mesh" @ MeshPath @ (Mesh != none ? "loaded" : "NOT loaded"), , 'LongWarX2');
	if (Mesh == none)
		return false;
	SkeletalMeshComponent.SetSkeletalMesh(Mesh);
	if (MaterialPath != "")
	{
		Mat = MaterialInterface(DynamicLoadObject(MaterialPath, class'MaterialInterface', true));
		`log("LongWarX2: EW unit: material" @ MaterialPath @ (Mat != none ? "loaded" : "NOT loaded, the mesh keeps its own"), , 'LongWarX2');
		if (Mat != none)
			SkeletalMeshComponent.SetMaterial(0, Mat);
	}
	Set = AnimSet(DynamicLoadObject(AnimSetPath, class'AnimSet', true));
	`log("LongWarX2: EW unit: animations" @ AnimSetPath @ (Set != none ? "loaded," @ Set.Sequences.Length @ "sequences" : "NOT loaded"), , 'LongWarX2');
	if (Set != none)
	{
		SkeletalMeshComponent.AnimSets.Length = 0;
		SkeletalMeshComponent.AnimSets.AddItem(Set);
		SkeletalMeshComponent.UpdateAnimations();
		Seq = AnimNodeSequence(SkeletalMeshComponent.Animations);
		if (Seq != none)
		{
			Seq.SetAnim(IdleAnim);
			Seq.PlayAnim(true, 1.0);
			`log("LongWarX2: EW unit: playing" @ IdleAnim @ (Seq.AnimSeq != none ? "" : "(not found in the set)"), , 'LongWarX2');
		}
	}
	// Two tiles (96 units each) along the pawn's facing, turned to face it.
	Offset = vector(Next.Rotation) * 192;
	SetLocation(Next.Location + Offset);
	SetRotation(rotator(-Offset));
	SetHidden(false);
	`log("LongWarX2: EW unit: shown at" @ Location, , 'LongWarX2');
	return true;
}

defaultproperties
{
	MeshPath="LWX2_Floater.SM_MedFloater"
	AnimSetPath="LWX2_Floater.AS_MedFloater"
	IdleAnim="AC_NO_IdleA"
}
