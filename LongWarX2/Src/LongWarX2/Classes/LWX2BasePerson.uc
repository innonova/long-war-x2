// One of Enemy Within's people in its base (features/ew-base-people.md): EW's skeletal mesh with EW's AnimSets, looping
// the animation EW's matinee plays on it (SkeletalMeshActor's own AnimNodeSequence), placed by LWX2EWBase.PlacePeople.
class LWX2BasePerson extends SkeletalMeshActor;

/** A window of its animation replayed as EW's looping matinee does (Setup's Window), else none. */
var AnimNodeSequence LoopSeq;
var float LoopStart, LoopRate, LoopWindow;
var array<LWX2EWMapPieces.LWX2AnimKey> LoopKeys;

/** EW's mesh, AnimSets, the loop, and its slots' stand-ins. */
function Setup(SkeletalMesh Mesh, array<AnimSet> Sets, name Loop, array<MaterialInterface> Slots, optional PhysicsAsset Bodies,
	optional float Start, optional float Rate, optional float Window, optional array<LWX2EWMapPieces.LWX2AnimKey> Keys)
{
	local AnimNodeSequence Seq;
	local float Length;
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
		// (EW's own place in the loop where its matinee says, a start before the loop's taken from its end; else a random
		// second, so a room's people do not move in step.)
		Length = Seq.GetAnimPlaybackLength();
		if (Start != 0 && Length > 0)
			Start = Start - Length * float(FFloor(Start / Length));
		else
			Start = FRand();
		// (A window of a longer animation, as EW's looping matinee plays it: posed each tick, Tick.)
		if (Window > 0)
		{
			LoopStart = Start;
			LoopRate = Rate > 0 ? Rate : 1.0;
			LoopWindow = Window;
			LoopKeys = Keys;
			LoopSeq = Seq;
			Seq.StopAnim();
			return;
		}
		Seq.PlayAnim(true, Rate > 0 ? Rate : 1.0, Start);
	}
}

/** The window's pose now: the matinee's time in its loop (at its rate) from Start, held at the animation's end. */
event Tick(float DeltaTime)
{
	local float T, Length, Hi;
	local int i, k;

	super.Tick(DeltaTime);
	if (LoopSeq == none || LoopWindow <= 0)
		return;
	T = WorldInfo.TimeSeconds * LoopRate;
	T = T - LoopWindow * float(FFloor(T / LoopWindow));
	Length = LoopSeq.GetAnimPlaybackLength();
	if (LoopKeys.Length == 0)
	{
		LoopSeq.SetPosition(FClamp(LoopStart + T, 0, Length), false);
		return;
	}
	// (UE3's animation track: the last key begun, else the first, its stretch from its own time.)
	k = 0;
	for (i = 0; i < LoopKeys.Length; i++)
		if (LoopKeys[i].Time <= T)
			k = i;
	Hi = Length - LoopKeys[k].End;
	T = FMax(0, T - LoopKeys[k].Time);
	LoopSeq.SetPosition(FClamp(LoopKeys[k].Reverse ? Hi - T : LoopKeys[k].From + T, LoopKeys[k].From, Hi), false);
}

defaultproperties
{
	bNoDelete = false
	bStatic = false
}
