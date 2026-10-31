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
};

/** The converted map package: loaded first, so its meshes exist (they live in the packages it carries). */
var config string MapPackage;
var config array<LWX2Piece> Pieces;

/** Spawns the pieces with their positions relative to Origin; returns how many were placed. */
static function int PlaceAll(Actor Spawner, vector Origin)
{
	local LWX2Piece P;
	local StaticMesh Mesh;
	local DynamicSMActor_Spawnable A;
	local int Placed, Missing;
	local Object Loaded;

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
		Placed++;
	}
	`log("LongWarX2: EW map:" @ Placed @ "pieces placed," @ Missing @ "meshes not found, of" @ default.Pieces.Length, , 'LongWarX2');
	return Placed;
}
