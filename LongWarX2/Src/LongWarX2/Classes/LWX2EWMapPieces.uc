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
	local array<Actor> Placed;

	if (default.Pieces.Length == 0)
		return 0;
	LoadPackage();
	Place(Spawner, vect(0, 0, 0), 0, Origin, class'DynamicSMActor_Spawnable', Placed);
	return Placed.Length;
}

/**
 * Spawns the pieces within Radius of Center (all when Radius is 0), moved so Center lands
 * on At, as actors of the given class (a StaticMeshActor or a DynamicSMActor).
 */
static function Place(Actor Spawner, vector Center, float Radius, vector At, class<Actor> ActorClass, out array<Actor> Placed)
{
	local LWX2Piece P;
	local StaticMesh Mesh;
	local Actor A;
	local StaticMeshComponent Comp;
	local int Missing, i;
	local array<LWX2Standin> Standins;
	local MaterialInterface M;

	foreach default.Pieces(P)
	{
		if (Radius > 0 && VSize2D(P.Loc - Center) > Radius)
			continue;
		Mesh = StaticMesh(DynamicLoadObject(P.Mesh, class'StaticMesh', true));
		if (Mesh == none)
		{
			Missing++;
			continue;
		}
		A = Spawner.Spawn(ActorClass, , , At + P.Loc - Center, P.Rot);
		if (A == none)
			continue;
		if (DynamicSMActor(A) != none)
		{
			DynamicSMActor(A).SetStaticMesh(Mesh);
			Comp = DynamicSMActor(A).StaticMeshComponent;
			A.SetCollision(false, false);
		}
		else
		{
			Comp = StaticMeshActor(A).StaticMeshComponent;
			Comp.SetStaticMesh(Mesh);
		}
		A.SetDrawScale3D(P.Scale);
		for (i = 0; i < P.Materials.Length; i++)
		{
			M = MaterialFor(P.Materials[i], A, Standins);
			if (M != none)
				Comp.SetMaterial(i, M);
		}
		Placed.AddItem(A);
	}
	`log("LongWarX2: EW map:" @ Placed.Length @ "pieces placed as" @ ActorClass.Name $ "," @ Missing @ "meshes not found;" @ Standins.Length @ "materials", , 'LongWarX2');
}

/** Loads the converted map package (any of its objects loads it whole: then its meshes are found by their paths). */
static function LoadPackage()
{
	local Object Loaded;

	Loaded = DynamicLoadObject(default.MapPackage $ ".TheWorld", class'Object', true);
	`log("LongWarX2: EW map: package" @ default.MapPackage @ (Loaded != none ? "loaded" : "not loaded (its meshes may still be found)"), , 'LongWarX2');
}

/** XCOM 2's cover points within Radius of At (for the experiment's log). */
static function int CountCover(XComWorldData World, vector At, float Radius)
{
	local array<XComCoverPoint> Points;

	World.GetCoverPoints(At, Radius, 256, Points);
	return Points.Length;
}

/** Of the 7x7 tiles around At, how many units cannot enter (a solid hull blocks them). */
static function int CountBlocked(XComWorldData World, vector At)
{
	local TTile Centre, T;
	local int dx, dy, n;

	Centre = World.GetTileCoordinatesFromPosition(At);
	for (dx = -3; dx <= 3; dx++)
		for (dy = -3; dy <= 3; dy++)
		{
			T = Centre;
			T.X += dx;
			T.Y += dy;
			if (!World.CanUnitsEnterTile(T))
				n++;
		}
	return n;
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
