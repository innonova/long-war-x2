// An Enemy Within map's geometry placed in XCOM 2 (features/hard-parts.md, experiment 2):
// its static meshes, from the map's package converted on the player's machine
// (tools/convert/ew-map.ts, which also writes this config), spawned where EW placed
// them, around Origin. Neither the package nor the config is in the repository.
class LWX2EWMapPieces extends Object config(LWX2EWMap);

struct LWX2Piece
{
	var string Mesh;
	var vector Loc;
	var rotator Rot;
	var vector Scale;
	/** Its materials slot by slot (EW's meshes carry none XCOM 2 can read: the placed pieces and their archetypes do). */
	var array<string> Materials;
};

/** An EW material's textures, for its XCOM 2 stand-in; Kind picks the parent. */
struct LWX2Look
{
	var string Material;
	var name Kind;
	var string Diffuse;
	var string Normal;
};

struct LWX2Standin
{
	var string Material;
	var MaterialInterface Standin;
};

/** The converted map package: loaded first, so its meshes exist (they live in the packages it carries). */
var config string MapPackage;
/**
 * XCOM 2 cannot draw EW's materials (their shaders are not in its caches and the game does
 * not compile them), so each is replaced by an instance of one of XCOM 2's parents, by its
 * kind, given the EW material's textures. Empty: the EW materials are kept.
 */
var config string PropParent;
var config string FoliageParent;
var config string AlienParent;
var config array<LWX2Look> Looks;
var config array<LWX2Piece> Pieces;

/** Spawns the pieces with their positions relative to Origin; returns how many were placed. */
static function int PlaceAll(Actor Spawner, vector Origin)
{
	local LWX2Piece P;
	local StaticMesh Mesh;
	local DynamicSMActor_Spawnable A;
	local int Placed, Missing, i;
	local Object Loaded;
	local array<LWX2Standin> Standins;
	local MaterialInterface M;

	if (default.Pieces.Length == 0)
		return 0;
	// Any object of the package loads it whole: then the meshes are found by their paths.
	Loaded = DynamicLoadObject(default.MapPackage $ ".TheWorld", class'Object', true);
	`log("LongWarX2: EW map: package" @ default.MapPackage @ (Loaded != none ? "loaded" : "not loaded (its meshes may still be found)"), , 'LongWarX2');
	foreach default.Pieces(P)
	{
		Mesh = StaticMesh(DynamicLoadObject(P.Mesh, class'StaticMesh', true));
		if (Mesh == none)
		{
			Missing++;
			continue;
		}
		A = Spawner.Spawn(class'DynamicSMActor_Spawnable', , , Origin + P.Loc, P.Rot);
		if (A == none)
			continue;
		A.SetStaticMesh(Mesh);
		A.SetDrawScale3D(P.Scale);
		A.SetCollision(false, false);
		for (i = 0; i < P.Materials.Length; i++)
		{
			M = MaterialFor(P.Materials[i], A, Standins);
			if (M != none)
				A.StaticMeshComponent.SetMaterial(i, M);
		}
		Placed++;
	}
	`log("LongWarX2: EW map:" @ Placed @ "pieces placed," @ Missing @ "meshes not found, of" @ default.Pieces.Length $ ";" @ Standins.Length @ "materials", , 'LongWarX2');
	return Placed;
}

/** The material a slot gets: the EW material's XCOM 2 stand-in, made once; the EW material itself when it has none. */
static function MaterialInterface MaterialFor(string Path, Object Outer, out array<LWX2Standin> Standins)
{
	local int k;
	local LWX2Look L;
	local LWX2Standin S;
	local string ParentPath;
	local Material Parent;
	local MaterialInstanceConstant MIC;
	local Texture T;

	if (Path == "")
		return none;
	k = Standins.Find('Material', Path);
	if (k != INDEX_NONE)
		return Standins[k].Standin;
	S.Material = Path;
	k = default.Looks.Find('Material', Path);
	if (k != INDEX_NONE)
	{
		L = default.Looks[k];
		ParentPath = L.Kind == 'Foliage' ? default.FoliageParent : (L.Kind == 'Alien' ? default.AlienParent : default.PropParent);
	}
	if (ParentPath != "" && L.Diffuse != "")
		Parent = Material(DynamicLoadObject(ParentPath, class'Material', true));
	if (Parent != none)
	{
		MIC = new(Outer) class'MaterialInstanceConstant';
		MIC.SetParent(Parent);
		T = Texture(DynamicLoadObject(L.Diffuse, class'Texture', true));
		if (T != none)
			MIC.SetTextureParameterValue('Diffuse', T);
		if (L.Normal != "")
		{
			T = Texture(DynamicLoadObject(L.Normal, class'Texture', true));
			if (T != none)
				MIC.SetTextureParameterValue('Normal', T);
		}
		S.Standin = MIC;
	}
	else
		S.Standin = MaterialInterface(DynamicLoadObject(Path, class'MaterialInterface', true));
	Standins.AddItem(S);
	return S.Standin;
}
