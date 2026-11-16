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
/** A view of the base in place of EW's own (tagged Base): where the camera stands in EW's coordinates and its field of
 *  view; zero: EW's own (as EW shows its base: the rooms at the top, close; features/lw-base-view.md). */
var config vector ViewLoc;
var config float ViewFOV;

var array<Actor> Fixed;
var array<Actor> Tiles;
/** The tiles' types and facilities as placed (Refresh places them again when they differ). */
var array<int> PlacedType, PlacedFacility;
/** The cameras of ours where EW's stood (LookAt), by their tags, and the view the base is seen through. */
var array<name> CamTags;
var array<CameraActor> Cams;
var name ViewTag;
/** The strategy world's sky lights and suns switched off while the base is in view (Fog), to switch on again. */
var array<LightComponent> WorldLights;
/** The lighting level streamed in at the base while it is in view, for its ambient light (one of XCOM 2's environment
 *  lighting levels, as a map's plot has: its ambient cube lights the base evenly; its sun and fog are switched off with
 *  the world's). "": none, the base lit by EW's own lights alone (dark: EW baked most of its light). */
var config string BaseLighting;
/** XCOM 2's squad select in EW's hangar (UILWSquadSelect), where EW lined its squad up in front of the Skyranger: through
 *  EW's camera for it (SquadCamera), the soldiers in a row SquadDistance in front of it, SquadSpacing apart, standing on
 *  SquadFloorZ (EW's coordinates), facing it. Off: the Avenger's launch bay. */
var config bool SquadInHangar;
/** EW's lights in the base at this brightness (1: EW's own). */
var config float BaseLightScale;
var config name SquadCamera;
var config float SquadDistance, SquadSpacing, SquadFloorZ;
var LevelStreaming LightingLevel;
/** The streamed levels hidden while the base is in view (HideWorld), to show again. */
var array<name> HiddenLevels;

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
	local string Level;

	if (!Converted())
		return;
	Command = Data("Command1");
	// (The world's fog and sun off first: what is placed is lit without them. And the Avenger hidden: its rooms, its
	// terrain, and its sky-and-light level for the hour, whose ambient light cast the base blue, purple, red or green from one
	// campaign to the next.)
	Fog(false);
	HideWorld();
	// (Loaded once and kept; shown and hidden with the base: removed and added again at once, as a screen over the hub
	// hides the base and the next shows it, it came back unseen, and the Avenger's ambient light with it.)
	if (BaseLighting != "" && LightingLevel == none)
	{
		LightingLevel = `MAPS.AddStreamingMap(BaseLighting, BaseOffset, rot(0, 0, 0), false, true, true);
		`log("LongWarX2: EW base: lighting level" @ BaseLighting @ (LightingLevel != none ? "streamed in" : "not found"), , 'LongWarX2');
	}
	else if (LightingLevel != none)
		`MAPS.SetStreamingLevelVisible(LightingLevel, true);
	RefreshAmbient();
	if (Fixed.Length == 0)
	{
		class'LWX2EWMapPieces'.static.PlaceOf(Command, self, vect(0, 0, 0), 0, BaseOffset, class'DynamicSMActor_Spawnable', Fixed, false, true);
		class'LWX2EWMapPieces'.static.PlaceLightsOf(Command, self, BaseOffset, Fixed, true, BaseLightScale, true);
		foreach FixedLevels(Level)
		{
			if (Data(Level).Pieces.Length == 0)
				continue;
			class'LWX2EWMapPieces'.static.PlaceOf(Data(Level), self, vect(0, 0, 0), 0, BaseOffset, class'DynamicSMActor_Spawnable', Fixed, false, true);
			class'LWX2EWMapPieces'.static.PlaceLightsOf(Data(Level), self, BaseOffset, Fixed, true, BaseLightScale, true);
		}
		`log("LongWarX2: EW base: the shell and" @ FixedLevels.Length @ "fixed rooms placed," @ Fixed.Length @ "actors", , 'LongWarX2');
	}
	Refresh();
	LookAt(ViewTag, 0);
}

/**
 * The view through one of EW's cameras (Command1's, by tag: Base, the base's view; a room's, as EW enters a room:
 * ScienceLab, ENGINEERING, BARRACKS, HANGAR, Cam_SituationRoom, MissionControl; Expansion …), moved to over Interp
 * seconds. XCOM 2's HQ camera takes a room view from a camera actor with the room's tag (XComHeadquartersCamera.
 * StartRoomView, GetViewFromCameraName), so each EW camera gets an actor of ours, tagged LWX2EWBase_<tag>, where EW's
 * stood. (A CameraActor cannot be spawned while the game runs: its spawnable kind.)
 */
function LookAt(name Tag, optional float Interp)
{
	local LWX2EWMapData Command;
	local LWX2EWMapPieces.LWX2Camera C;
	local CameraActor Cam;
	local name CamName;
	local int k;

	Command = Data("Command1");
	k = Command.Cameras.Find('Tag', Tag);
	if (k == INDEX_NONE)
	{
		`log("LongWarX2: EW base: no camera" @ Tag, , 'LongWarX2');
		return;
	}
	C = Command.Cameras[k];
	if (Tag == 'Base' && ViewFOV > 0)
	{
		C.Loc = ViewLoc;
		C.FOV = ViewFOV;
	}
	CamName = name("LWX2EWBase_" $ Tag);
	k = CamTags.Find(CamName);
	if (k == INDEX_NONE)
	{
		Cam = Spawn(class'DynamicCameraActor', self, CamName, C.Loc + BaseOffset, C.Rot);
		if (Cam == none)
			return;
		Cam.FOVAngle = C.FOV;
		Cam.bConstrainAspectRatio = false;
		NeutralLook(Cam);
		CamTags.AddItem(CamName);
		Cams.AddItem(Cam);
	}
	ViewTag = Tag;
	if (`HQPRES != none)
		`HQPRES.CAMLookAtNamedLocation(string(CamName), Interp);
	// (The world hidden after the camera's move: XCOM 2's HQ camera shows the Avenger again as it leaves its globe view for a
	// room view, XComHeadquartersCamera.StartRoomView.)
	HideWorld();
	RefreshAmbient();
	// And again once the camera has arrived: the ambient light comes from a cube the engine captures, and one captured while
	// the camera was still elsewhere (the Avenger, a moment before) kept that place's light.
	SetTimer(Interp + 0.5, false, nameof(RefreshAmbient));
	SetTimer(Interp + 1.5, false, nameof(RefreshAmbientLater));
}

function RefreshAmbientLater()
{
	RefreshAmbient();
}

/** The camera's own post-process, which XCOM 2's HQ camera takes from the camera it views through
 *  (XComCamState_HQ_BaseRoomView.GetViewFromCameraName): a neutral colour grade (no lookup table, tint or desaturation)
 *  and no fog. Without it the world's settings apply, which follow the Avenger's time of day: the base cast blue, purple,
 *  red or orange from one campaign to the next. */
static function NeutralLook(CameraActor Cam)
{
	local vector One;

	One = vect(1, 1, 1);
	Cam.CamOverridePostProcessAlpha = 1.0;
	Cam.CamOverridePostProcess.bOverride_Scene_ColorGradingLUT = true;
	Cam.CamOverridePostProcess.ColorGrading_LookupTable = none;
	Cam.CamOverridePostProcess.bOverride_Scene_Desaturation = true;
	Cam.CamOverridePostProcess.Scene_Desaturation = 0;
	Cam.CamOverridePostProcess.bOverride_Scene_Colorize = true;
	Cam.CamOverridePostProcess.Scene_Colorize = One;
	Cam.CamOverridePostProcess.bOverride_Scene_HighLights = true;
	Cam.CamOverridePostProcess.Scene_HighLights = One;
	Cam.CamOverridePostProcess.bOverride_Scene_MidTones = true;
	Cam.CamOverridePostProcess.Scene_MidTones = One;
	Cam.CamOverridePostProcess.bOverride_Scene_Shadows = true;
	Cam.CamOverridePostProcess.Scene_Shadows = vect(0, 0, 0);
	Cam.CamOverridePostProcess.bOverride_ShowFog = true;
	Cam.CamOverridePostProcess.bShowFog = false;
}

/** The strategy world's height fog, sky lights and sun off while EW's base is in view, back on with the Avenger's views.
 *  The base lies far below the Avenger, inside its fog (the scene drowned in the Avenger's sky colour), and the Avenger's
 *  sky and sun reach everywhere (the scene cast in its sky's colour); EW's own lights, placed with the base, light it. */
function Fog(bool bOn)
{
	local HeightFog F;
	local ExponentialHeightFog E;
	local Light L;
	local LightComponent C;
	local int n;

	foreach AllActors(class'HeightFog', F)
	{
		F.Component.SetEnabled(bOn);
		n++;
	}
	foreach AllActors(class'ExponentialHeightFog', E)
	{
		E.Component.SetEnabled(bOn);
		n++;
	}
	if (bOn)
	{
		foreach WorldLights(C)
			if (C != none)
				C.SetEnabled(true);
		WorldLights.Length = 0;
	}
	else
	{
		foreach AllActors(class'Light', L)
		{
			// (EW's own lights, placed with the base, are LWX2 lights, spawned without an owner.)
			if (L.Owner == self || LWX2SkyLight(L) != none || L.LightComponent == none || !L.LightComponent.bEnabled)
				continue;
			if (DirectionalLight(L) != none || SkyLight(L) != none)
			{
				L.LightComponent.SetEnabled(false);
				WorldLights.AddItem(L.LightComponent);
			}
		}
	}
	`log("LongWarX2: EW base:" @ n @ "height fogs" @ (bOn ? "on" : "off") $ "," @ WorldLights.Length @ "of the world's sky lights and suns off", , 'LongWarX2');
}

/** The ambient light taken again from the visible lighting levels: the engine takes it as a level loads, not as one is
 *  shown or hidden (shown again, the base kept the Avenger's light of the hour, loaded in between). */
function RefreshAmbient()
{
	if (XComEngine(class'Engine'.static.GetEngine()) != none)
		XComEngine(class'Engine'.static.GetEngine()).bRefreshAmbientCubeRequested = true;
}

/** Whether XCOM 2's squad select stands the squad in EW's hangar (converted here, and asked for). */
static function bool SquadHere()
{
	return default.SquadInHangar && Converted() && Data("Command1").Cameras.Find('Tag', default.SquadCamera) != INDEX_NONE;
}

/** Where a soldier of the squad stands in EW's hangar: Column of Columns, left to right as the camera sees them. */
static function SquadSpot(int Column, int Columns, out vector Loc, out rotator Rot)
{
	local LWX2EWMapPieces.LWX2Camera C;
	local vector Forward, Right;
	local LWX2EWMapData Command;

	Command = Data("Command1");
	C = Command.Cameras[Command.Cameras.Find('Tag', default.SquadCamera)];
	Forward = vector(C.Rot);
	Forward.Z = 0;
	Forward = Normal(Forward);
	// (Unreal's axes: Z up, left-handed; the camera's right is Forward rotated a quarter turn about Z.)
	Right.X = -Forward.Y;
	Right.Y = Forward.X;
	Loc = C.Loc + Forward * default.SquadDistance + Right * (Column - (Columns - 1) / 2.0) * default.SquadSpacing;
	Loc.Z = default.SquadFloorZ;
	Loc += default.BaseOffset;
	Rot = rotator(-Forward);
}

/**
 * Every streamed level hidden while EW's base is in view but its own lighting level: the Avenger, its terrain, its rooms
 * and their lighting and display levels. The engine takes its ambient light from the visible lighting levels, and the
 * Avenger's (its sky and light of the hour, its rooms', its photo booth's) lit the base red, blue or teal. Asked of the
 * engine directly (PlayerController.ClientUpdateLevelStreamingStatus): XCOM 2's own hiding of the Avenger
 * (XGBase.SetAvengerVisibility) did not hold on every path. Shown again, exactly those, by ShowWorld.
 */
function HideWorld()
{
	local LevelStreaming L;
	local PlayerController PC;
	local int n;

	PC = GetALocalPlayerController();
	if (PC == none)
		return;
	foreach WorldInfo.StreamingLevels(L)
	{
		if (L == none || L == LightingLevel || !L.bShouldBeVisible || HiddenLevels.Find(L.PackageName) != INDEX_NONE)
			continue;
		HiddenLevels.AddItem(L.PackageName);
		PC.ClientUpdateLevelStreamingStatus(L.PackageName, true, false, false);
		n++;
	}
	if (n > 0)
		`log("LongWarX2: EW base:" @ n @ "streamed levels hidden," @ HiddenLevels.Length @ "in all", , 'LongWarX2');
}

/** The levels HideWorld hid shown again. */
function ShowWorld()
{
	local PlayerController PC;
	local name N;

	PC = GetALocalPlayerController();
	if (PC != none)
		foreach HiddenLevels(N)
			PC.ClientUpdateLevelStreamingStatus(N, true, true, false);
	HiddenLevels.Length = 0;
}

/** The Avenger shown or hidden, as XCOM 2 does it for its globe (XGBase.SetAvengerVisibility). */
function AvengerShown(bool bShown)
{
	local XGGeoscape Geo;

	Geo = `GAME != none ? `GAME.GetGeoscape() : none;
	if (Geo != none && Geo.m_kBase != none)
		Geo.m_kBase.SetAvengerVisibility(bShown);
}

/** The camera given back to the strategy layer (the Avenger's views). bKeepCamera: where the next screen has already set
 *  its own (the armory, opened from squad select, looks at its room: the Avenger's overview would take its place). */
function Hide(optional bool bKeepCamera)
{
	ShowWorld();
	ViewTag = 'Base';
	if (LightingLevel != none)
		`MAPS.SetStreamingLevelVisible(LightingLevel, false);
	RefreshAmbient();
	AvengerShown(true);
	if (`HQPRES != none && !bKeepCamera)
		`HQPRES.CAMLookAtNamedLocation("Base", 0);
	Fog(true);
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
			class'LWX2EWMapPieces'.static.PlaceOf(Data(Level), self, vect(0, 0, 0), 0, Command.Rooms[k].Loc + BaseOffset, class'DynamicSMActor_Spawnable', Placed, false, true);
			class'LWX2EWMapPieces'.static.PlaceLightsOf(Data(Level), self, Command.Rooms[k].Loc + BaseOffset, Placed, true, BaseLightScale, true);
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
	ViewTag = Base
	bHidden = true
}
