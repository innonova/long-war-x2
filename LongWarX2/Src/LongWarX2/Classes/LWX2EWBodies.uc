// Enemy Within's bodies on XCOM 2's aliens (features/lw-ew-units.md): a template's units drawn with EW's skeletal mesh and
// a material made here from EW's textures, animated by EW's own animations under XCOM 2's names (the converted unit
// package's AnimSet, tools/convert/ew-unit-anims.ts), added to the template's AdditionalAnimSets after XCOM 2's own.
// The packages are the player's own conversions in the mod's Content, and so is the list (Config/XComLWX2EWUnits.ini,
// written by the setup: tools/convert/ew-units.ts); a body whose package is not there is left out.
class LWX2EWBodies extends Object config(LWX2EWUnits);

struct LWX2Body
{
	var name Template;
	var string Mesh;
	var string AnimSet;
	var string Diffuse;
	var string Normal;
};

var config array<LWX2Body> Bodies;
/** The parent of the bodies' materials (XCOM 2's material for its aliens). */
var config string MaterialParent;

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
	local int i;

	if (Unit == none || XGUnit(Unit.GetVisualizer()) == none)
		return false;
	Pawn = XGUnit(Unit.GetVisualizer()).GetPawn();
	if (Pawn == none || Pawn.Mesh == none)
		return false;
	foreach default.Bodies(B)
	{
		if (B.Template != Unit.GetMyTemplateName())
			continue;
		Mesh = SkeletalMesh(DynamicLoadObject(B.Mesh, class'SkeletalMesh', true));
		if (Mesh == none || Pawn.Mesh.SkeletalMesh == Mesh)
			return false;
		Pawn.Mesh.SetSkeletalMesh(Mesh);
		Material = Standin(B);
		if (Material != none)
			for (i = 0; i < Mesh.Materials.Length; i++)
				Pawn.Mesh.SetMaterial(i, Material);
		Pawn.UpdateAnimations();
		return true;
	}
	return false;
}

/** Every unit on the field given its body (at the battle's start, after a load). Returns how many. */
static function int ApplyAll()
{
	local XComGameState_Unit Unit;
	local int n;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Apply(Unit))
			n++;
	return n;
}

/** An instance of MaterialParent with the body's diffuse and normal maps (none when the parent or a map is missing). */
static function MaterialInterface Standin(LWX2Body B)
{
	local Material Parent;
	local MaterialInstanceConstant MIC;
	local Texture T;

	Parent = Material(DynamicLoadObject(default.MaterialParent, class'Material', true));
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

defaultproperties
{
	MaterialParent="Materials.Approved.AlienUnit_TC"
}
