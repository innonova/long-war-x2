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
	/** The sky dome, the mountains: drawn, never colliding (they would enclose the map). */
	var bool Backdrop;
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
/** EW's play area (its level volume: centre and half sizes) and drop zones (its player starts). */
var config vector PlayCenter;
var config vector PlayExtent;
var config array<vector> DropZones;
/** EW's alien pods (lw-missions.md, step 2): where its aliens stand, the commander's pod, how many. */
struct LWX2Pod
{
	var vector Loc;
	var bool Commander;
	var int Min;
	var int Max;
	/** The sub-level it is in (Stream, EWI: the abduction variant, CNH); Abduction: the map's own abduction pods; none: the map's own. */
	var name Level;
};
var config array<LWX2Pod> Pods;
var config array<vector> SpawnPoints;
/**
 * EW's lights (lw-missions.md, step 2): baked into its lightmaps, which XCOM 2 cannot use, so each is spawned as
 * a movable light. Kind: Point, Spot, Sun (its directional light), Sky. Unreal's units throughout.
 */
struct LWX2Light
{
	var name Kind;
	var vector Loc;
	var rotator Rot;
	var float Radius;
	var float Brightness;
	var color Color;
	var float Falloff;
	var float Inner;
	var float Outer;
	var float Lower;
};
var config array<LWX2Light> Lights;
/** Each light's brightness times this (EW's lightmaps added bounced light the movable lights do not). */
var config float LightScale;
/** Which kinds are placed (the mission's own sun and sky light the map too). */
var config array<name> LightKinds;

/** Spawns EW's lights (of LightKinds) moved by Shift; returns how many were placed. */
static function int PlaceLights(Actor Spawner, vector Shift)
{
	local LWX2Light L;
	local Light A;
	local int Count;

	foreach default.Lights(L)
	{
		if (default.LightKinds.Find(L.Kind) == INDEX_NONE)
			continue;
		switch (L.Kind)
		{
			case 'Point': A = Spawner.Spawn(class'LWX2PointLight', , , L.Loc + Shift, L.Rot); break;
			case 'Spot': A = Spawner.Spawn(class'LWX2SpotLight', , , L.Loc + Shift, L.Rot); break;
			case 'Sun': A = Spawner.Spawn(class'LWX2SunLight', , , L.Loc + Shift, L.Rot); break;
			case 'Sky': A = Spawner.Spawn(class'LWX2SkyLight', , , L.Loc + Shift, L.Rot); break;
			default: A = none;
		}
		if (A == none || A.LightComponent == none)
			continue;
		if (PointLightComponent(A.LightComponent) != none)
		{
			PointLightComponent(A.LightComponent).Radius = L.Radius;
			PointLightComponent(A.LightComponent).FalloffExponent = L.Falloff;
		}
		if (SpotLightComponent(A.LightComponent) != none)
		{
			SpotLightComponent(A.LightComponent).InnerConeAngle = L.Inner;
			SpotLightComponent(A.LightComponent).OuterConeAngle = L.Outer;
		}
		A.LightComponent.SetLightProperties(L.Brightness * (default.LightScale > 0 ? default.LightScale : 1.0), L.Color);
		A.ReattachComponent(A.LightComponent);
		Count++;
	}
	`log("LongWarX2: EW map:" @ Count @ "of" @ default.Lights.Length @ "lights placed", , 'LongWarX2');
	return Count;
}

/** Spawns the pieces with their positions relative to Origin; returns how many were placed. */
static function int PlaceAll(Actor Spawner, vector Origin)
{
	local array<Actor> Placed;

	if (default.Pieces.Length == 0)
		return 0;
	Place(Spawner, vect(0, 0, 0), 0, Origin, class'DynamicSMActor_Spawnable', Placed);
	return Placed.Length;
}

/**
 * Spawns the pieces within Radius of Center (all when Radius is 0), moved so Center lands
 * on At, as actors of the given class (a StaticMeshActor or a DynamicSMActor). With
 * bCollideInPlayOnly, pieces outside EW's play area (its backdrop) do not collide.
 */
static function Place(Actor Spawner, vector Center, float Radius, vector At, class<Actor> ActorClass, out array<Actor> Placed, optional bool bCollideInPlayOnly)
{
	local LWX2Piece P;
	local StaticMesh Mesh;
	local Actor A;
	local StaticMeshComponent Comp;
	local int Missing, i, Backdrop;
	local array<LWX2Standin> Standins;
	local MaterialInterface M;

	LoadPackage();
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
		// The backdrop does not collide: the huge pieces (the sky dome, the mountains: they would
		// enclose the map), and with bCollideInPlayOnly whatever is outside the play area.
		if (P.Backdrop || (bCollideInPlayOnly && (Abs(P.Loc.X - default.PlayCenter.X) > default.PlayExtent.X || Abs(P.Loc.Y - default.PlayCenter.Y) > default.PlayExtent.Y)))
		{
			A.SetCollision(false, false);
			Comp.SetBlockRigidBody(false);
			Comp.SetActorCollision(false, false);
			Comp.SetTraceBlocking(false, false); // the sky dome's collision box holds the whole map
			Backdrop++;
		}
		for (i = 0; i < P.Materials.Length; i++)
		{
			M = MaterialFor(P.Materials[i], A, Standins);
			if (M != none)
				Comp.SetMaterial(i, M);
		}
		Placed.AddItem(A);
	}
	`log("LongWarX2: EW map:" @ Placed.Length @ "pieces placed as" @ ActorClass.Name $ "," @ Missing @ "meshes not found;" @ Standins.Length @ "materials" $ ";" @ Backdrop @ "backdrop pieces without collision", , 'LongWarX2');
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
static function MaterialInterface MaterialFor(string Path, Object InOuter, out array<LWX2Standin> Standins)
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
	{
		Parent = Material(DynamicLoadObject(ParentPath, class'Material', true));
		if (Parent == none)
			`log("LongWarX2: EW map: parent material" @ ParentPath @ "not loaded; the EW material kept for" @ Path, , 'LongWarX2');
	}
	if (Parent != none)
	{
		MIC = new(InOuter) class'MaterialInstanceConstant';
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
