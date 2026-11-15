// Enemy Within's base as the strategy layer's scene (features/lw-base-view.md): EW's base map (Command1: its shell and its
// fixed rooms, the Static_ levels) and, at each tile's room location (Command1's XComHQ_RoomLocation R<row>_C<column>),
// the level EW streams there for what the Long War base has (XGBase.StreamInRoom: a facility's Addon_ level, else the
// terrain's), placed in the strategy world away from the Avenger from the converted levels (tools/convert/ew-map.ts, each
// its LWX2EWMapData section), with the camera on EW's view of it (Command1's camera tagged Base).
//
// An actor of the strategy world: made while a Long War screen is up (Show), the camera given back when it closes (Hide);
// placed once per world, the tiles placed again when the base changes (Refresh).
class LWX2EWBase extends Actor config(LWEWMaps);

/** Where EW's base is put in the strategy world (its own coordinates moved by this): below the Avenger's. */
var config vector BaseOffset;
/** EW's fixed rooms (Command1's always-loaded Static_ levels). */
var config array<string> FixedLevels;
/** The view of the whole base (EW's own, tagged Base, framed a part of it for 4:3 and panned): where the camera stands in
 *  EW's coordinates and its field of view; zero: EW's own. */
var config vector ViewLoc;
var config float ViewFOV;

var array<Actor> Fixed;
var array<Actor> Tiles;
/** The tiles' types and facilities as placed (Refresh places them again when they differ). */
var array<int> PlacedType, PlacedFacility;
var CameraActor View;

/** The base of this world (made the first time). */
static function LWX2EWBase Get(Actor Finder)
{
	local LWX2EWBase B;

	foreach Finder.AllActors(class'LWX2EWBase', B)
		return B;
	return Finder.Spawn(class'LWX2EWBase');
}

/** Whether EW's base is converted on this machine (Command1's section with its rooms). */
static function bool Converted()
{
	return Data("Command1").Rooms.Length > 0;
}

static function LWX2EWMapData Data(string Level)
{
	local LWX2EWMapData D;

	D = LWX2EWMapData(FindObject("Transient." $ Level, class'LWX2EWMapData'));
	if (D == none)
		D = new(none, Level) class'LWX2EWMapData';
	return D;
}

/** The base placed (once) and the tiles brought up to date, and the camera on it. */
function Show()
{
	local LWX2EWMapData Command;
	local LWX2EWMapPieces.LWX2Camera C;
	local string Level;
	local int k;

	if (!Converted())
		return;
	Command = Data("Command1");
	if (Fixed.Length == 0)
	{
		class'LWX2EWMapPieces'.static.PlaceOf(Command, self, vect(0, 0, 0), 0, BaseOffset, class'DynamicSMActor_Spawnable', Fixed);
		class'LWX2EWMapPieces'.static.PlaceLightsOf(Command, self, BaseOffset, Fixed);
		foreach FixedLevels(Level)
		{
			if (Data(Level).Pieces.Length == 0)
				continue;
			class'LWX2EWMapPieces'.static.PlaceOf(Data(Level), self, vect(0, 0, 0), 0, BaseOffset, class'DynamicSMActor_Spawnable', Fixed);
			class'LWX2EWMapPieces'.static.PlaceLightsOf(Data(Level), self, BaseOffset, Fixed);
		}
		`log("LongWarX2: EW base: the shell and" @ FixedLevels.Length @ "fixed rooms placed," @ Fixed.Length @ "actors", , 'LongWarX2');
	}
	Refresh();
	k = Command.Cameras.Find('Tag', 'Base');
	if (k == INDEX_NONE)
		return;
	C = Command.Cameras[k];
	if (ViewFOV > 0)
	{
		C.Loc = ViewLoc;
		C.FOV = ViewFOV;
	}
	// A camera of our own, tagged, where EW's was: XCOM 2's HQ camera takes a room view from a camera actor with the
	// room's tag (XComHeadquartersCamera.StartRoomView, GetViewFromCameraName).
	if (View == none)
	{
		// (A CameraActor cannot be spawned while the game runs: its spawnable kind.)
		View = Spawn(class'DynamicCameraActor', self, 'LWX2EWBase', C.Loc + BaseOffset, C.Rot);
		if (View != none)
		{
			View.FOVAngle = C.FOV;
			View.bConstrainAspectRatio = false;
		}
		`log("LongWarX2: EW base: its camera" @ (View != none ? "at" @ View.Location : "not spawned"), , 'LongWarX2');
	}
	if (`HQPRES != none)
		`HQPRES.CAMLookAtNamedLocation("LWX2EWBase", 0);
}

/** The camera given back to the strategy layer (the Avenger's views). */
function Hide()
{
	if (`HQPRES != none)
		`HQPRES.CAMLookAtNamedLocation("Base", 0);
}

/** Each tile below the top row with EW's level for it, placed again where the Long War base has changed. */
function Refresh()
{
	local XComGameState_LWStrategy S;
	local LWX2EWMapData Command;
	local array<Actor> Placed;
	local Actor A;
	local int X, Y, i, k, Type, Facility, n;
	local string Level;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.TileType.Length < class'LWBase'.const.W * class'LWBase'.const.H)
		return;
	Command = Data("Command1");
	if (PlacedType.Length != S.TileType.Length)
	{
		foreach Tiles(A)
			if (A != none)
				A.Destroy();
		Tiles.Length = 0;
		PlacedType.Length = 0;
		PlacedType.Length = S.TileType.Length;
		PlacedFacility.Length = 0;
		PlacedFacility.Length = S.TileType.Length;
		for (i = 0; i < PlacedType.Length; i++)
			PlacedType[i] = -1;
	}
	for (Y = 1; Y < class'LWBase'.const.H; Y++)
	{
		for (X = 0; X < class'LWBase'.const.W; X++)
		{
			i = Y * class'LWBase'.const.W + X;
			Type = S.TileType[i];
			Facility = S.TileFacility[i];
			if (PlacedType[i] == Type && PlacedFacility[i] == Facility)
				continue;
			// (A tile placed before is placed again: its old actors stay until the base is shown in a new world. The
			// first version; tiles change rarely.)
			PlacedType[i] = Type;
			PlacedFacility[i] = Facility;
			Level = LevelFor(Type, Facility, X == class'LWBase'.const.SHAFT);
			k = Command.Rooms.Find('Tag', name("R" $ Y $ "_C" $ (X + 1)));
			if (Level == "" || k == INDEX_NONE || Data(Level).Pieces.Length == 0)
				continue;
			Placed.Length = 0;
			class'LWX2EWMapPieces'.static.PlaceOf(Data(Level), self, vect(0, 0, 0), 0, Command.Rooms[k].Loc + BaseOffset, class'DynamicSMActor_Spawnable', Placed);
			class'LWX2EWMapPieces'.static.PlaceLightsOf(Data(Level), self, Command.Rooms[k].Loc + BaseOffset, Placed);
			foreach Placed(A)
				Tiles.AddItem(A);
			n++;
		}
	}
	if (n > 0)
		`log("LongWarX2: EW base:" @ n @ "tiles placed," @ Tiles.Length @ "actors in all", , 'LongWarX2');
}

/**
 * EW's level for a tile (XGBase.GetMapName: XGGameData.FacilityToMap, TerrainToMap, native; named here by EW's packages):
 * a facility's Addon_ level; an access lift's (in the shaft); else the terrain's. "" for the second half of a large
 * facility.
 */
static function string LevelFor(int Type, int Facility, bool bShaft)
{
	if (Type == class'LWBase'.const.BUILT)
	{
		switch (Facility)
		{
		case 0: return "";
		case 6: return "Addon_AccessLift_Excavated";
		case 7: return "Addon_Laboratory";
		case 8: return "Addon_Workshop";
		case 9: return "Addon_SmallRadar";
		case 10: return "Addon_PowerGenerator";
		case 11: return "Addon_Foundry";
		case 12: return "Addon_OfficerTrainingSchool";
		case 13: return "Addon_AlienContainment";
		case 14: return "Addon_LargeRadar";
		case 15: return "Addon_ThermalPower";
		case 16: return "Addon_EleriumPowerGenerator";
		case 17: return "Addon_PsionicLab";
		case 18: return "Addon_HyperwaveRadar";
		case 19: return "Addon_GollopChamber";
		case 22: return "Addon_CyberneticsLab";
		case 23: return "Addon_Genelab";
		}
		return "Addon_Excavated";
	}
	switch (Type)
	{
	case class'LWBase'.const.ROCK: return "Addon_SolidRock";
	case class'LWBase'.const.ROCK_STEAM: return "Addon_ThermalCave";
	case class'LWBase'.const.OPEN: return "Addon_Cave";
	case class'LWBase'.const.DUG_STEAM: return "Addon_Excavated_Thermal";
	}
	return bShaft ? "Addon_AccessLift_Excavated" : "Addon_Excavated";
}

defaultproperties
{
	bHidden = true
}
