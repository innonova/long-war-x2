// Enemy Within's bodies on XCOM 2's aliens (features/lw-ew-units.md): a template's units drawn with EW's skeletal mesh and
// a material made here from EW's textures, animated by EW's own animations under XCOM 2's names (the converted unit
// package's AnimSet, tools/convert/ew-unit-anims.ts), added to the template's AdditionalAnimSets after XCOM 2's own.
// The packages are the player's own conversions in the mod's Content, and so is the list (Config/XComLWX2EWUnits.ini,
// written by the setup: tools/convert/ew-units.ts); a body whose package is not there is left out.
class LWX2EWBodies extends Object config(LWX2EWUnits);

/** One of a body's material slots: its own diffuse and normal (EXALT's soldiers: body, head and arms, kit). */
struct LWX2BodySlot
{
	var string Diffuse;
	var string Normal;
};

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
	/** The armour that brings this body (a MEC's suit: Mark I, II or III), for a template with several (none: any). */
	var name Armor;
	/** EW's animations only, XCOM 2's pawn's own taken off: where they share bone names with EW's skeleton but not its
	 *  poses (EW's MECs on the ADVENT MEC's pawn came out torn into spikes with both). */
	var bool OwnAnimsOnly;
	/** Each material slot's textures, where they differ (else Diffuse and Normal on every slot). */
	var array<LWX2BodySlot> Slots;
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
	local name Each;
	local array<name> Names;
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
		// (The species' own template where the body is a species', else the template and its species' copies: LWX2Species.)
		Names = class'LWX2Species'.static.TemplatesFor(B.Template, B.Species);
		foreach Names(Each)
			Manager.FindDataTemplateAllDifficulties(Each, Templates);
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
	local LWX2Body B;
	local UnitValue Species;
	local int Mine, Pick;

	if (Unit == none || XGUnit(Unit.GetVisualizer()) == none)
		return false;
	// The species' own body before its template's (the pods' aliens carry their species, LWMissionSquads.SpawnPod).
	Mine = Unit.GetUnitValue('LWX2Species', Species) ? int(Species.fValue) : 0;
	Pick = PickFor(Unit.GetMyTemplateName(), Mine, ArmorOf(Unit));
	if (Pick == INDEX_NONE)
		return false;
	Pawn = XGUnit(Unit.GetVisualizer()).GetPawn();
	if (Pawn == none || Pawn.Mesh == none)
		return false;
	B = default.Bodies[Pick];
	if (!ApplyBody(Pawn, B))
		return false;
	Weapon(Unit, B);
	return true;
}

/** A strategy pawn (squad select's line-up, the armory) given its template's body (the mod's SHIVs and MECs). */
static function bool ApplyToPawn(XComUnitPawn Pawn, name Template, optional name Armor, optional XComGameState_Unit Unit)
{
	local CustomAnimParams Idle;
	local bool bGiven;
	local int k, AnimsChanged;

	k = PickFor(Template, 0, Armor);
	if (k == INDEX_NONE || Pawn == none || Pawn.Mesh == none)
		return false;
	bGiven = ApplyBody(Pawn, default.Bodies[k], AnimsChanged);
	// (Its weapon in its hand, drawn as EW's: the unit's primary weapon, found once its pawn has made it.)
	SeatWeapons(Pawn, default.Bodies[k], PrimaryMesh(Unit));
	// A body of EW's animations only, its AnimSets just put right: the idle XCOM 2 had it play (PlayHQIdleAnim, from the
	// sets it put back) is gone, and it stood in its rest pose, its gun (on a bone EW's animations move) at its feet. EW's
	// idle played again, under the name XCOM 2's strategy pawns idle by (the converter's copy of EW's AC_NO_IdleA).
	if (AnimsChanged > 0 && Pawn.GetAnimTreeController() != none)
	{
		Idle.AnimName = 'NO_IdleGunDwnA';
		Idle.Looping = true;
		Pawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Idle);
	}
	return bGiven;
}

/** The body for a template: its species' own before the template's, the one its armour brings before one for any armour. */
static function int PickFor(name Template, int Species, name Armor)
{
	local int i, Pick, Best, Score, Char;

	// (A species' own template: the XCOM 2 template it was made from, its species.)
	if (class'LWX2Species'.static.IsCopy(Template, Char))
	{
		Template = class'LWX2Species'.static.SourceOf(Char);
		if (Species == 0)
			Species = Char;
	}

	Pick = INDEX_NONE;
	Best = -1;
	for (i = 0; i < default.Bodies.Length; i++)
	{
		if (default.Bodies[i].Template != Template)
			continue;
		if (default.Bodies[i].Species != 0 && default.Bodies[i].Species != Species)
			continue;
		if (default.Bodies[i].Armor != '' && default.Bodies[i].Armor != Armor)
			continue;
		Score = (default.Bodies[i].Species != 0 ? 2 : 0) + (default.Bodies[i].Armor != '' ? 1 : 0);
		if (Score > Best)
		{
			Best = Score;
			Pick = i;
		}
	}
	return Pick;
}

static function name ArmorOf(XComGameState_Unit Unit)
{
	local XComGameState_Item Item;

	Item = Unit != none ? Unit.GetItemInSlot(eInvSlot_Armor) : none;
	return Item != none ? Item.GetMyTemplateName() : '';
}

/** The body on a pawn: EW's mesh, its stand-in material, the animations again. */
static function bool ApplyBody(XComUnitPawn Pawn, LWX2Body B, optional out int AnimsChanged)
{
	local SkeletalMesh Mesh;
	local MaterialInterface Material, Slot;
	local int i;

	// Given already (asked every two seconds in a mission: a load each time would read the package again).
	if (Pawn.Mesh.SkeletalMesh != none && string(Pawn.Mesh.SkeletalMesh.Name) == Mid(B.Mesh, InStr(B.Mesh, ".") + 1))
	{
		QuietControls(Pawn);
		FixMasks(Pawn);
		AnimsChanged = (OwnAnims(Pawn, B) || EnsureAnimSet(Pawn, B)) ? 1 : 0;
		SeatWeapons(Pawn, B);
		return false;
	}
	Mesh = SkeletalMesh(DynamicLoadObject(B.Mesh, class'SkeletalMesh', true));
	if (Mesh == none || Pawn.Mesh.SkeletalMesh == Mesh)
		return false;
	Pawn.Mesh.SetSkeletalMesh(Mesh);
	Material = Standin(B);
	for (i = 0; i < Mesh.Materials.Length; i++)
	{
		// A slot of its own textures (EXALT's head and arms, its kit) its own material; the others the body's.
		Slot = i < B.Slots.Length ? SlotStandin(B, i) : none;
		if (Slot != none)
			Pawn.Mesh.SetMaterial(i, Slot);
		else if (Material != none)
			Pawn.Mesh.SetMaterial(i, Material);
	}
	Pawn.UpdateAnimations();
	QuietControls(Pawn);
	FixMasks(Pawn);
	AnimsChanged = (OwnAnims(Pawn, B) || EnsureAnimSet(Pawn, B)) ? 1 : 0;
	SeatWeapons(Pawn, B);
	return true;
}

/**
 * Weapons hanging from no bone of the body. XCOM 2's ADVENT MEC gun hangs from a socket of the ADVENT MEC's skeleton; on
 * EW's MEC it stood at the pawn's feet. The unit's primary weapon (Primary; else the one already drawn as the body's) drawn
 * as EW's and put in EW's hand socket, Inven_R_Hand (as EW's chaingun says); the others, XCOM 2's sockets for them gone,
 * hidden. Only for a body with EW's weapon and that socket.
 */
static function SeatWeapons(XComUnitPawn Pawn, LWX2Body B, optional SkeletalMeshComponent Primary)
{
	local array<SkeletalMeshComponent> Loose;
	local SkeletalMeshComponent C;
	local SkeletalMesh Mine;
	local int i, n;

	if (B.WeaponMesh == "" || B.WeaponMesh == "none" || Pawn == none || Pawn.Mesh.GetSocketByName('Inven_R_Hand') == none)
		return;
	Mine = SkeletalMesh(DynamicLoadObject(B.WeaponMesh, class'SkeletalMesh', true));
	// (XCOM 2 attaches a weapon to its socket by name: on EW's skeleton the socket is not found and the weapon is left
	// unattached, where its actor stands. One attached before the body was given hangs from a bone the body has not: the
	// ADVENT MEC's gun from its Inven_R_Hand bone, which EW's MEC has as a socket only.)
	if (Primary != none && !Pawn.Mesh.IsComponentAttached(Primary))
		Loose.AddItem(Primary);
	// (The primary drawn as EW's weapon wherever it hangs: on EW's MEC, XCOM 2's ADVENT MEC gun hangs from the same bone.)
	if (Primary != none)
		DressWeapon(Primary, B);
	for (i = 0; i < Pawn.Mesh.Attachments.Length; i++)
	{
		C = SkeletalMeshComponent(Pawn.Mesh.Attachments[i].Component);
		if (C != none && (C == Primary || XComWeapon(C.Owner) != none) && Pawn.Mesh.MatchRefBone(Pawn.Mesh.Attachments[i].BoneName) == INDEX_NONE && Loose.Find(C) == INDEX_NONE)
			Loose.AddItem(C);
	}
	foreach Loose(C)
	{
		if (Pawn.Mesh.IsComponentAttached(C))
			Pawn.Mesh.DetachComponent(C);
		if (C == Primary || (Primary == none && C.SkeletalMesh != none && C.SkeletalMesh == Mine))
		{
			DressWeapon(C, B);
			Pawn.Mesh.AttachComponentToSocket(C, 'Inven_R_Hand');
			n++;
		}
		else
			C.SetHidden(true);
	}
	if (Loose.Length > 0)
		`log("LongWarX2: EW bodies:" @ Pawn.Name $ ":" @ n @ "weapon put in its hand," @ (Loose.Length - n) @ "hidden", , 'LongWarX2');
}

/** The unit's primary weapon's mesh on its pawn (in a mission, and on the strategy layer's pawns, which make its visualizer). */
static function SkeletalMeshComponent PrimaryMesh(XComGameState_Unit Unit)
{
	local XComGameState_Item Item;

	Item = Unit != none ? Unit.GetPrimaryWeapon() : none;
	if (Item == none || XGWeapon(Item.GetVisualizer()) == none || XComWeapon(XGWeapon(Item.GetVisualizer()).m_kEntity) == none)
		return none;
	return SkeletalMeshComponent(XComWeapon(XGWeapon(Item.GetVisualizer()).m_kEntity).Mesh);
}

/** A weapon's mesh made the body's EW weapon (its mesh and a stand-in). */
static function DressWeapon(SkeletalMeshComponent C, LWX2Body B)
{
	local SkeletalMesh Mesh;
	local MaterialInterface Material;
	local LWX2Body Look;
	local int i;

	Mesh = SkeletalMesh(DynamicLoadObject(B.WeaponMesh, class'SkeletalMesh', true));
	if (Mesh == none || C.SkeletalMesh == Mesh)
		return;
	C.SetSkeletalMesh(Mesh);
	Look.Diffuse = B.WeaponDiffuse;
	Look.Normal = B.WeaponNormal;
	Material = Standin(Look, default.WeaponMaterialParent);
	if (Material != none)
		for (i = 0; i < Mesh.Materials.Length; i++)
			C.SetMaterial(i, Material);
}

/** For a body of EW's animations only: the pawn's AnimSets that are not EW's taken off (again, if XCOM 2 has put them back).
 *  True when they changed. */
/** The body's AnimSet on the pawn's mesh, last (its animations over XCOM 2's of the same names), whatever the template
 *  carries: the species' template copies (LWX2Char_n) came out with empty AdditionalAnimSets on the field, and the
 *  Sectoid stood in its bind pose under XCOM 2's set, none of whose tracks fit EW's mesh. True when it was added. */
static function bool EnsureAnimSet(XComUnitPawn Pawn, LWX2Body B)
{
	local AnimSet Set;

	if (Pawn.Mesh == none)
		return false;
	Set = AnimSet(DynamicLoadObject(B.AnimSet, class'AnimSet', true));
	if (Set == none || (Pawn.Mesh.AnimSets.Length > 0 && Pawn.Mesh.AnimSets[Pawn.Mesh.AnimSets.Length - 1] == Set))
		return false;
	Pawn.Mesh.AnimSets.RemoveItem(Set);
	Pawn.Mesh.AnimSets.AddItem(Set);
	Pawn.Mesh.UpdateAnimations();
	return true;
}

static function bool OwnAnims(XComUnitPawn Pawn, LWX2Body B)
{
	local AnimSet Set;
	local int i;
	local bool bChanged;

	if (!B.OwnAnimsOnly || Pawn.Mesh == none)
		return false;
	Set = AnimSet(DynamicLoadObject(B.AnimSet, class'AnimSet', true));
	if (Set == none)
		return false;
	for (i = Pawn.Mesh.AnimSets.Length - 1; i >= 0; i--)
		if (Pawn.Mesh.AnimSets[i] != Set)
		{
			Pawn.Mesh.AnimSets.Remove(i, 1);
			bChanged = true;
		}
	if (Pawn.Mesh.AnimSets.Find(Set) == INDEX_NONE)
	{
		Pawn.Mesh.AnimSets.AddItem(Set);
		bChanged = true;
	}
	if (bChanged)
		Pawn.Mesh.UpdateAnimations();
	return bChanged;
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
	if (Entity == none || SkeletalMeshComponent(Entity.Mesh) == none)
		return;
	DressWeapon(SkeletalMeshComponent(Entity.Mesh), B);
	// (Hanging from no bone of the body: in its hand.)
	SeatWeapons(XGUnit(Unit.GetVisualizer()).GetPawn(), B, SkeletalMeshComponent(Entity.Mesh));
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

/** The stand-in for one of a body's slots, from that slot's textures (none when they are the body's or missing). */
static function MaterialInterface SlotStandin(LWX2Body B, int i)
{
	local LWX2Body Look;

	if (B.Slots[i].Diffuse == "" || B.Slots[i].Diffuse == B.Diffuse)
		return none;
	Look.Diffuse = B.Slots[i].Diffuse;
	Look.Normal = B.Slots[i].Normal;
	return Standin(Look);
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
