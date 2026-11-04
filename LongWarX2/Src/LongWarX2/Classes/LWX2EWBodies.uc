// Enemy Within's bodies on XCOM 2's aliens (features/lw-ew-units.md): a template's units drawn with EW's skeletal mesh and
// a material made here from EW's textures, animated by EW's own animations under XCOM 2's names (the converted unit
// package's AnimSet, tools/convert/ew-unit-anims.ts), added to the template's AdditionalAnimSets after XCOM 2's own.
// The packages are the player's own conversions in the mod's Content, and so is the list (Config/XComLWX2EWUnits.ini,
// written by the setup: tools/convert/ew-units.ts); a body whose package is not there is left out.
class LWX2EWBodies extends Object config(LWX2EWUnits);

struct LWX2Body
{
	var name Template;
	/** Long War's species (EW's ECharacter), for one that shares its template with another (0: any on the template). */
	var int Species;
	var string Mesh;
	var string AnimSet;
	var string Diffuse;
	var string Normal;
	/** EW's weapon for it, in place of its XCOM 2 weapon's mesh ("none": XCOM 2's hidden; empty: XCOM 2's kept). */
	var string WeaponMesh;
	var string WeaponDiffuse;
	var string WeaponNormal;
};

var config array<LWX2Body> Bodies;
/** The parent of the bodies' materials (XCOM 2's material for its aliens). */
var config string MaterialParent;
/** The parent of the weapons' materials; unset (as the setup writes it), the bodies' parent, which draws EW's weapons. */
var config string WeaponMaterialParent;

/** The bodies' AnimSets in their templates' AdditionalAnimSets (as the templates are made). */
static function AddAnimSets()
{
	local X2CharacterTemplateManager Manager;
	local array<X2DataTemplate> Templates;
	local X2DataTemplate T;
	local AnimSet Set;
	local LWX2Body B;
	local int n;

	Manager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	foreach default.Bodies(B)
	{
		Set = AnimSet(DynamicLoadObject(B.AnimSet, class'AnimSet', true));
		if (Set == none)
		{
			`log("LongWarX2: EW bodies:" @ B.Template @ "keeps XCOM 2's body (no" @ B.AnimSet $ ")", , 'LongWarX2');
			continue;
		}
		Templates.Length = 0;
		Manager.FindDataTemplateAllDifficulties(B.Template, Templates);
		foreach Templates(T)
			if (X2CharacterTemplate(T) != none && X2CharacterTemplate(T).AdditionalAnimSets.Find(Set) == INDEX_NONE)
			{
				X2CharacterTemplate(T).AdditionalAnimSets.AddItem(Set);
				// XCOM 2's reveal and first-sighting scenes bring their own model of the alien (its cinematic packages):
				// without them XCOM 2 reveals the unit itself, in its EW body.
				X2CharacterTemplate(T).strMatineePackages.Length = 0;
				X2CharacterTemplate(T).RevealMatineePrefix = "";
				X2CharacterTemplate(T).bNeverShowFirstSighted = true;
				n++;
			}
	}
	`log("LongWarX2: EW bodies:" @ n @ "templates given EW's animations", , 'LongWarX2');
}

/** A unit's pawn given its template's EW body (once: its mesh, then its animations made again). True when given. */
static function bool Apply(XComGameState_Unit Unit)
{
	local XComUnitPawn Pawn;
	local SkeletalMesh Mesh;
	local MaterialInterface Material;
	local LWX2Body B;
	local UnitValue Species;
	local int i, Mine, Pick;

	if (Unit == none || XGUnit(Unit.GetVisualizer()) == none)
		return false;
	// The species' own body before its template's (the pods' aliens carry their species, LWMissionSquads.SpawnPod).
	Mine = Unit.GetUnitValue('LWX2Species', Species) ? int(Species.fValue) : 0;
	Pick = INDEX_NONE;
	for (i = 0; i < default.Bodies.Length; i++)
		if (default.Bodies[i].Template == Unit.GetMyTemplateName() && (default.Bodies[i].Species == Mine || (default.Bodies[i].Species == 0 && Pick == INDEX_NONE)))
			Pick = i;
	if (Pick == INDEX_NONE)
		return false;
	Pawn = XGUnit(Unit.GetVisualizer()).GetPawn();
	if (Pawn == none || Pawn.Mesh == none)
		return false;
	B = default.Bodies[Pick];
	// Given already (asked every two seconds in a mission: a load each time would read the package again).
	if (Pawn.Mesh.SkeletalMesh != none && string(Pawn.Mesh.SkeletalMesh.Name) == Mid(B.Mesh, InStr(B.Mesh, ".") + 1))
	{
		QuietControls(Pawn);
		FixMasks(Pawn);
		return false;
	}
	Mesh = SkeletalMesh(DynamicLoadObject(B.Mesh, class'SkeletalMesh', true));
	if (Mesh == none || Pawn.Mesh.SkeletalMesh == Mesh)
		return false;
	Pawn.Mesh.SetSkeletalMesh(Mesh);
	Material = Standin(B);
	if (Material != none)
		for (i = 0; i < Mesh.Materials.Length; i++)
			Pawn.Mesh.SetMaterial(i, Material);
	Pawn.UpdateAnimations();
	QuietControls(Pawn);
	FixMasks(Pawn);
	Weapon(Unit, B);
	return true;
}

/**
 * XCOM 2's soldier tree turns bones after the animation (twist bones, look-ats, the elbow and knee "splitters", the arms'
 * IK), finding them by name; EW's skeletons have bones of those names (the Sectoid's LArmTwist01, LElbowSplitter …), which
 * EW's animations pose themselves, and the controls threw the Sectoid's left arm out sideways (the person's "arms-out
 * pose", 2026-11-04). On an EW body every control but the feet's placement is off; asked again with the body (every two
 * seconds), as the tree may switch them on again.
 */
static function QuietControls(XComUnitPawn Pawn)
{
	local AnimTree Tree;
	local SkelControlBase Control;
	local int i;

	Tree = AnimTree(Pawn.Mesh.Animations);
	if (Tree == none)
		return;
	for (i = 0; i < Tree.SkelControlLists.Length; i++)
		for (Control = Tree.SkelControlLists[i].ControlHead; Control != none; Control = Control.NextControl)
			if (SkelControlFootPlacement(Control) == none && Control.ControlStrength > 0)
				Control.SetSkelControlStrength(0, 0);
}

/**
 * XCOM 2's channel masks (XComAnimNodeBlendMasks: full body, upper body, the arms, the head) start from its skeletons'
 * bones ("Root", "Spine1", "lShoulder", "rShoulder", "Neck"); on EW's skeletons they covered no bone, so no full-body
 * animation reached the body and every EW body stood in its reference pose (the person's "arms-out" Sectoids; found
 * 2026-11-04 night). Each such mask is rebuilt on EW's bones: its start bone mapped (Root: the mesh's first bone; the rest
 * EW's RigSpine1, RigLArmCollarbone, RigRArmCollarbone, RigNeck where the skeleton has them), every bone under it in the
 * mask, and the chain from the root to it as the bones blended in model space, as XCOM 2 builds them. The start bone is
 * then EW's, so a mask done is not done again; a tree made anew has XCOM 2's names and is done again.
 */
static function FixMasks(XComUnitPawn Pawn)
{
	local XComAnimNodeBlendMasks Masks;
	local array<name> Bones;
	local array<byte> Chain;
	local name Start, Bone;
	local int i, k, n;

	foreach Pawn.Mesh.AllAnimNodes(class'XComAnimNodeBlendMasks', Masks)
	{
		for (i = 0; i < Masks.BlendMasks.Length; i++)
		{
			if (Pawn.Mesh.MatchRefBone(Masks.BlendMasks[i].BranchStartBoneName) != INDEX_NONE)
				continue;
			if (Bones.Length == 0)
				for (k = 0; k < 1024 && Pawn.Mesh.GetBoneName(k) != ''; k++)
					Bones.AddItem(Pawn.Mesh.GetBoneName(k));
			Start = EWBoneFor(Masks.BlendMasks[i].BranchStartBoneName, Bones);
			if (Start == '')
				continue;
			Masks.BlendMasks[i].PerBoneMask.Length = Bones.Length;
			for (k = 0; k < Bones.Length; k++)
			{
				Masks.BlendMasks[i].PerBoneMask[k] = 0;
				Bone = Bones[k];
				n = 0;
				while (Bone != '' && n < 64)
				{
					if (Bone == Start)
					{
						Masks.BlendMasks[i].PerBoneMask[k] = 1;
						break;
					}
					Bone = Pawn.Mesh.GetParentBone(Bone);
					n++;
				}
			}
			// The chain from the root down to the start bone.
			Chain.Length = 0;
			Bone = Start;
			n = 0;
			while (Bone != '' && n < 64)
			{
				Chain.InsertItem(0, Pawn.Mesh.MatchRefBone(Bone));
				Bone = Pawn.Mesh.GetParentBone(Bone);
				n++;
			}
			Masks.BlendMasks[i].ModelSpaceBones = Chain;
			Masks.BlendMasks[i].BranchStartBoneName = Start;
		}
	}
}

/** An XCOM 2 skeleton's bone named as on an EW skeleton (none where the skeleton has no such bone). */
static function name EWBoneFor(name X2Bone, array<name> Bones)
{
	local name EW;

	switch (X2Bone)
	{
	case 'Root':
		return Bones.Length > 0 ? Bones[0] : '';
	case 'Spine1':
		EW = 'RigSpine1';
		break;
	case 'lShoulder':
		EW = 'RigLArmCollarbone';
		break;
	case 'rShoulder':
		EW = 'RigRArmCollarbone';
		break;
	case 'Neck':
		EW = 'RigNeck';
		break;
	default:
		return '';
	}
	return Bones.Find(EW) != INDEX_NONE ? EW : '';
}

/** The unit's primary weapon drawn as EW's (its mesh and a stand-in), where the body names one and XCOM 2's is skeletal. */
static function Weapon(XComGameState_Unit Unit, LWX2Body B)
{
	local XComGameState_Item Item;
	local XComWeapon Entity;
	local SkeletalMesh Mesh;
	local MaterialInterface Material;
	local LWX2Body Look;
	local int i;

	if (B.WeaponMesh == "")
		return;
	Item = Unit.GetPrimaryWeapon();
	if (Item == none || XGWeapon(Item.GetVisualizer()) == none)
		return;
	Entity = XComWeapon(XGWeapon(Item.GetVisualizer()).m_kEntity);
	// EW's species with nothing in its hands: XCOM 2's weapon not drawn.
	if (B.WeaponMesh == "none")
	{
		if (Entity != none && Entity.Mesh != none)
			Entity.Mesh.SetHidden(true);
		return;
	}
	Mesh = SkeletalMesh(DynamicLoadObject(B.WeaponMesh, class'SkeletalMesh', true));
	if (Entity == none || SkeletalMeshComponent(Entity.Mesh) == none || Mesh == none)
		return;
	SkeletalMeshComponent(Entity.Mesh).SetSkeletalMesh(Mesh);
	Look.Diffuse = B.WeaponDiffuse;
	Look.Normal = B.WeaponNormal;
	Material = Standin(Look, default.WeaponMaterialParent);
	if (Material != none)
		for (i = 0; i < Mesh.Materials.Length; i++)
			Entity.Mesh.SetMaterial(i, Material);
}

/** Every unit on the field given its body (at the battle's start, after a load). Returns how many. */
static function int ApplyAll()
{
	local XComGameState_Unit Unit;
	local int n;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Apply(Unit))
			n++;
		Scale(Unit);
	}
	return n;
}

/** A pod leader drawn at its size (Long War's leader lines scale the pawn: LWX2Scale, in percent; 0.2 to 10 times). */
static function Scale(XComGameState_Unit Unit)
{
	local UnitValue V;
	local XComUnitPawn Pawn;
	local float S;

	if (!Unit.GetUnitValue('LWX2Scale', V) || XGUnit(Unit.GetVisualizer()) == none)
		return;
	Pawn = XGUnit(Unit.GetVisualizer()).GetPawn();
	S = FClamp(1.0 + V.fValue / 100.0, 0.2, 10.0);
	if (Pawn != none && Pawn.Mesh != none && Abs(Pawn.Mesh.Scale - S) > 0.001)
		Pawn.Mesh.SetScale(S);
}

/** An instance of MaterialParent with the body's diffuse and normal maps (none when the parent or a map is missing). */
static function MaterialInterface Standin(LWX2Body B, optional string ParentPath)
{
	local Material Parent;
	local MaterialInstanceConstant MIC;
	local Texture T;

	Parent = Material(DynamicLoadObject(ParentPath != "" ? ParentPath : default.MaterialParent, class'Material', true));
	T = Texture(DynamicLoadObject(B.Diffuse, class'Texture', true));
	if (Parent == none || T == none)
		return none;
	MIC = new class'MaterialInstanceConstant';
	MIC.SetParent(Parent);
	MIC.SetTextureParameterValue('Diffuse', T);
	T = Texture(DynamicLoadObject(B.Normal, class'Texture', true));
	if (T != none)
		MIC.SetTextureParameterValue('Normal', T);
	return MIC;
}
