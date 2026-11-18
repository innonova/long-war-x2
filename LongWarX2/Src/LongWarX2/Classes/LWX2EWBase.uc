// Enemy Within's base as the strategy layer's scene (features/lw-base-view.md): EW's base map (Command1: its shell and its
// fixed rooms, the Static_ levels) and, at each tile's room location (Command1's XComHQ_RoomLocation R<row>_C<column>),
// the level EW streams there for what the Long War base has (XGBase.StreamInRoom: a facility's Addon_ level, else the
// terrain's), placed in the strategy world away from the Avenger from the converted levels (tools/convert/ew-map.ts, each
// its LWX2EWMapData section), with the camera on EW's view of it (Command1's camera tagged Base).
//
// An actor of the strategy world: made while a Long War screen is up (Show), the camera given back when it closes (Hide);
// placed once per world, the tiles placed again when the base changes (Refresh).
class LWX2EWBase extends Actor config(LWEWMaps) dependson(LWX2EWBodies, LWX2EWMapPieces);

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
/** Each placed tile actor's tile (its index in the base's grid), beside Tiles: a tile placed again takes its old actors away. */
var array<int> TileOf;
/** Mission Control's hologlobe (EW's Globe mesh at its full size; the moon beside it is the same mesh, smaller), turned as
 *  EW turns it while nothing is shown on it, a turn in GlobeSeconds. */
var Actor Globe;
var config float GlobeSeconds;
/** Where EW's flat earth (LWStrategyRules.MapPlaces: 0 to 1 across and down, equirectangular) lies on the globe's mesh: the
 *  yaw of longitude 0 in the mesh's frame, and whether longitude runs the other way round. */
var config float GlobeLonOffset;
var config bool bGlobeMirrored;
/** Degrees of the mesh's turn per degree of longitude (EW's texture lies on the mesh a little more than once round). */
var config float GlobeLonScale;
/** The markers on it (the headquarters, the UFOs seen, the missions waiting), and the turn it is held at while an alert
 *  shows a place (EW's CAMLookAtEarth); -1: turning freely. */
var array<Actor> GlobeMarkers;
var int GlobeHoldYaw;
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
/** EW's people in its base (features/ew-base-people.md): the Anim_ levels whose people stand in the fixed rooms. */
var config array<string> PeopleLevels;
/** A test aid (off): the fixed rooms placed at the main menu (UIScreenListener_LongWarX2Shell), the campaign start's crash
 *  reproduced at every start (features/strategy-flow.md). */
var config bool PlaceInShell;
/** EW's main menu scene (ShowShell): on, and where it is placed. */
var config bool ShellScene;
var config vector ShellOffset;
var array<Actor> ShellPlaced;
var LevelStreaming ShellLighting;
/** The parent of EW's people's stand-ins (XCOM 2's material for its own base's staff); empty: the bodies' (LWX2EWBodies). */
var config string PeopleMaterialParent;
/** Whether they play EW's animations (false: they stand in their reference pose; a test switch). */
var config bool PeopleAnimate;
/** A level's people placed at their matinee's first key plus this, where set (features/ew-base-people.md). */
struct LWX2PeopleFrame
{
	var string Level;
	var vector Offset;
};
var config array<LWX2PeopleFrame> PeopleFrames;
var array<LWX2BasePerson> People;
/** The level of EW's hangar bays (RefreshBays), its pads and craft as placed, and the bays' states they show. */
var config string BaysLevel;
var array<LWX2BasePerson> BayActors;
var string BaysShown;
var array<Object> BayAssets;
/** The craft the craft summary shows (its jet's index + 1; 0: none): EW's SetupWeaponView, in bay 1's ViewWeapons pose. */
var int ViewJet;

/** EW's screens on their 3D panels in the rooms (features/ew-3d-screens.md), and the panel's mesh and material: XCOM 2's
 *  (its material takes the 3D movie in its Movie parameter), scaled from EW's. */
var config bool ScreensIn3D;
/** The satellites' view on the Situation Room's wall too, its HUD over it (features/ew-3d-screens.md). */
var config bool SatellitesOnWall;
var config string DisplayMesh, DisplayMaterial;
var config float DisplayScale;
/** XCOM 2's plate turned to face as EW's panel mesh faces (added to EW's rotation). */
var config rotator DisplayTurn;
/** A tag's panels replaced by one XCOM 2 plate showing the whole movie (the Situation Room's wall: EW's wall meshes take
 *  slices of EW's movie layout, which XCOM 2's 3D movie does not reproduce). */
struct LWX2PlateDisplay
{
	var name Tag;
	var vector Loc;
	var rotator Rot;
	var float Scale;
};
var config array<LWX2PlateDisplay> PlateDisplays;
/** The panels placed (PlaceDisplays). */
var array<LWX2UIDisplay> Displays;
var config string BaseLighting;
/** XCOM 2's squad select in EW's hangar (UILWSquadSelect), where EW lined its squad up in front of the Skyranger: through
 *  EW's camera for it (SquadCamera), the soldiers in a row SquadDistance in front of it, SquadSpacing apart, standing on
 *  SquadFloorZ (EW's coordinates), facing it. Off: the Avenger's launch bay. */
var config bool SquadInHangar;
/** EW's lights in the base at this brightness (1: EW's own). */
var config float BaseLightScale;
var config name SquadCamera;
var config float SquadDistance, SquadSpacing, SquadFloorZ;
/** XCOM 2's armory screens over EW's armory (UIScreenListener_LWArmory): through EW's own armory cameras (ArmoryCameras: the
 *  main menu's, the loadout's, the promotion's), the soldier standing ArmoryDistance in front of the camera on EW's floor
 *  there, facing it. Off: the Avenger's armory. */
var config bool ArmoryInBase;
var config float ArmoryDistance;
/** XCOM 2's screens on EW's panels (the armory's in EW's armory: UIScreenListener_LWArmory). XCOM 2's 3D movie draws a
 *  screen on the displays tagged as its DisplayTag (Screen): a display of ours with that tag stands on EW's panel (Panel,
 *  Command1's tag), and the view goes through EW's camera for it (Camera). */
struct LWX2ScreenDisplay
{
	var name Screen;
	var name Panel;
	var name Camera;
};
var config array<LWX2ScreenDisplay> ScreenDisplays;
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

/** Command1 and the fixed rooms placed, once. */
function PlaceFixed()
{
	local string Level;

	if (Fixed.Length > 0)
		return;
	class'LWX2EWMapPieces'.static.PlaceOf(Data("Command1"), self, vect(0, 0, 0), 0, BaseOffset, class'LWX2BasePiece', Fixed, false, true);
	class'LWX2EWMapPieces'.static.PlaceLightsOf(Data("Command1"), self, BaseOffset, Fixed, true, BaseLightScale, true);
	foreach FixedLevels(Level)
	{
		if (Data(Level).Pieces.Length == 0)
			continue;
		class'LWX2EWMapPieces'.static.PlaceOf(Data(Level), self, vect(0, 0, 0), 0, BaseOffset, class'LWX2BasePiece', Fixed, false, true);
		class'LWX2EWMapPieces'.static.PlaceLightsOf(Data(Level), self, BaseOffset, Fixed, true, BaseLightScale, true);
	}
	`log("LongWarX2: EW base: the shell and" @ FixedLevels.Length @ "fixed rooms placed," @ Fixed.Length @ "actors", , 'LongWarX2');
	FindGlobe();
}

/**
 * EW's main menu scene (features/strategy-flow.md): EW's shell map (XComShell, its own Mission Control room with the globe
 * and the officer at the console), converted with the base, placed below the shell's world at ShellOffset, its lights and
 * its people with it, seen through its camera as EW's shell shows it (XComHeadquartersCamera.StartStrategyShellView: the
 * map's first camera). The shell's own scene is left where it is, out of view.
 */
function ShowShell()
{
	local LWX2EWMapData D;
	local CameraActor Cam;
	local XComPresentationLayerBase Pres;
	local name CamName;

	D = Data("XComShell");
	if (D.Pieces.Length == 0 || D.Cameras.Length == 0)
		return;
	Fog(false);
	if (ShellPlaced.Length == 0)
	{
		class'LWX2EWMapPieces'.static.PlaceOf(D, self, vect(0, 0, 0), 0, ShellOffset, class'LWX2BasePiece', ShellPlaced, false, true);
		class'LWX2EWMapPieces'.static.PlaceLightsOf(D, self, ShellOffset, ShellPlaced, true, BaseLightScale, true);
		PlacePeopleOf("XComShell", ShellOffset, ShellPlaced);
		`log("LongWarX2: EW shell scene:" @ ShellPlaced.Length @ "actors placed", , 'LongWarX2');
	}
	CamName = 'LWX2EWShell';
	Cam = Spawn(class'DynamicCameraActor', self, CamName, D.Cameras[0].Loc + ShellOffset, D.Cameras[0].Rot);
	if (Cam == none)
		return;
	Cam.FOVAngle = D.Cameras[0].FOV;
	Cam.bConstrainAspectRatio = false;
	Pres = XComPlayerController(GetALocalPlayerController()) != none ? XComPlayerController(GetALocalPlayerController()).Pres : none;
	if (Pres != none)
		Pres.CAMLookAtNamedLocation(string(CamName), 0);
	// (As the base's view: the shell's own scene hidden, the base's lighting level beneath the room for its ambient light,
	// and the ambient captured again once the camera is there; captured in the shell's bright scene it washed the room
	// out.)
	HideWorld();
	if (BaseLighting != "" && ShellLighting == none)
		ShellLighting = `MAPS.AddStreamingMap(BaseLighting, ShellOffset, rot(0, 0, 0), false, true, true);
	RefreshAmbient();
	SetTimer(0.5, false, nameof(RefreshAmbient));
	SetTimer(1.5, false, nameof(RefreshAmbientLater));
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
	PlaceFixed();
	PlacePeople();
	// (The 3D panels too: XCOM 2's screens ask for their display as they open, before any listener of ours runs.)
	PlaceDisplays();
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
	if (k != INDEX_NONE)
		C = Command.Cameras[k];
	// (A facility's own camera, in its level: CyberneticsLab_UIDisplayCam …, where that facility stands.)
	// (A camera of a level placed where it stands: the hangar's craft view, Anim_Hangar_LaunchBays'.)
	else if (!LevelCameraOf(Tag, C) && !FacilityCameraOf(Tag, C))
	{
		`log("LongWarX2: EW base: no camera" @ Tag, , 'LongWarX2');
		return;
	}
	// (EW's cut surfaces drawn for its base and room views; out of the way of a facility's own camera, which looks from
	// behind them: the Genetics Lab's showed black.)
	ShowCutaway(k != INDEX_NONE);
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

/**
 * A view placed relative to one plinth as another view is to its own (EW's UISoldierGeneMods.MatchCameras: the Genetics
 * Lab's camera put to the lab's plinth as the armory's promotion camera is to the armory's, with its field of view): the
 * camera FromCam's offset and turn from FromSpot, applied at ToSpot. False where a camera or plinth is missing.
 */
function bool LookAtMatched(name FromCam, name FromSpot, name ToSpot, name AsTag, optional float Interp)
{
	local LWX2EWMapPieces.LWX2Camera C;
	local LWX2EWMapData Command;
	local vector FromLoc, ToLoc;
	local rotator FromRot, ToRot;
	local CameraActor Cam;
	local name CamName;
	local int k;

	Command = Data("Command1");
	k = Command.Cameras.Find('Tag', FromCam);
	if (k != INDEX_NONE)
		C = Command.Cameras[k];
	else if (!FacilityCameraOf(FromCam, C))
		return false;
	if (!SpotFor(FromSpot, FromLoc, FromRot) || !SpotFor(ToSpot, ToLoc, ToRot))
		return false;
	CamName = name("LWX2EWBase_" $ AsTag);
	k = CamTags.Find(CamName);
	if (k == INDEX_NONE)
	{
		Cam = Spawn(class'DynamicCameraActor', self, CamName);
		if (Cam == none)
			return false;
		Cam.bConstrainAspectRatio = false;
		NeutralLook(Cam);
		CamTags.AddItem(CamName);
		Cams.AddItem(Cam);
	}
	else
		Cam = Cams[k];
	Cam.SetLocation(ToLoc + (C.Loc + BaseOffset - FromLoc));
	Cam.SetRotation(ToRot + (C.Rot - FromRot));
	Cam.FOVAngle = C.FOV;
	ViewTag = AsTag;
	if (`HQPRES != none)
		`HQPRES.CAMLookAtNamedLocation(string(CamName), Interp);
	ShowCutaway(false);
	HideWorld();
	RefreshAmbient();
	SetTimer(Interp + 0.5, false, nameof(RefreshAmbient));
	SetTimer(Interp + 1.5, false, nameof(RefreshAmbientLater));
	return true;
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

/** Another lighting level for the base, live (a test aid: the control port's baselighting). */
function string SetLighting(string Level)
{
	if (LightingLevel != none)
		`MAPS.SetStreamingLevelVisible(LightingLevel, false);
	LightingLevel = none;
	BaseLighting = Level;
	if (Level != "")
		LightingLevel = `MAPS.AddStreamingMap(Level, BaseOffset, rot(0, 0, 0), false, true, true);
	RefreshAmbient();
	SetTimer(1.0, false, nameof(RefreshAmbient));
	return "ok" @ Level @ ((Level == "" || LightingLevel != none) ? "" : "not found");
}

/** EW's people placed, once (their levels converted with the base); shown and hidden with it. */
function PlacePeople()
{
	local string Level;
	local array<Actor> Placed;
	local Actor A;

	if (People.Length > 0)
		return;
	foreach PeopleLevels(Level)
	{
		Placed.Length = 0;
		PlacePeopleOf(Level, BaseOffset, Placed);
		foreach Placed(A)
			People.AddItem(LWX2BasePerson(A));
	}
	`log("LongWarX2: EW base:" @ People.Length @ "people placed", , 'LongWarX2');
}

/** A level's people (and its animated props: the Genetics Lab's tanks …), placed with the level at Offset; added to Placed. */
function PlacePeopleOf(string Level, vector Offset, out array<Actor> Placed)
{
	local LWX2EWMapPieces.LWX2Person P;
	local LWX2EWMapData D;
	local LWX2BasePerson A;

	D = Data(Level);
	if (D == none || D.People.Length == 0)
		return;
	if (D.MapPackage != "")
		DynamicLoadObject(D.MapPackage $ ".TheWorld", class'Object', true);
	foreach D.People(P)
	{
		// (A hangar bay's pad or craft: placed by the hangar's state, RefreshBays.)
		if (P.Bay > 0)
			continue;
		A = PlacePerson(P, Level, Offset);
		if (A != none)
			Placed.AddItem(A);
	}
}

/** One of a level's people (or animated props) spawned at Offset, posed and animated. */
function LWX2BasePerson PlacePerson(LWX2EWMapPieces.LWX2Person P, string Level, vector Offset)
{
	local LWX2EWMapPieces.LWX2PersonSlot S;
	local LWX2EWMapPieces.LWX2Look GlowLook;
	local LWX2BasePerson A;
	local SkeletalMesh Mesh;
	local array<AnimSet> Sets;
	local array<MaterialInterface> Slots;
	local AnimSet Set;
	local LWX2EWBodies.LWX2Body B;
	local string Path;
	local MaterialInterface Slot;
	local MaterialInstanceConstant MIC;
	local Texture T;
	local int k;
	local vector At;

	Mesh = SkeletalMesh(DynamicLoadObject(P.Mesh, class'SkeletalMesh', true));
	if (Mesh == none)
	{
		`log("LongWarX2: EW base:" @ Level $ "'s" @ P.Mesh @ "not found", , 'LongWarX2');
		return none;
	}
	Sets.Length = 0;
	foreach P.AnimSets(Path)
	{
		Set = AnimSet(DynamicLoadObject(Path, class'AnimSet', true));
		if (Set != none)
			Sets.AddItem(Set);
	}
	Slots.Length = 0;
	foreach P.Slots(S)
	{
		B.Diffuse = S.Diffuse;
		B.Normal = S.Normal;
		// (A slot without a texture found, the eye lashes: the body's stand-in; our unlit material cannot go on a
		// skeletal mesh.)
		if (S.Glow)
		{
			GlowLook.Diffuse = "";
			GlowLook.Tint = S.Tint;
			Slots.AddItem(class'LWX2EWMapPieces'.static.GlowStandin(GlowLook, self));
			continue;
		}
		Slot = S.Diffuse != "" ? class'LWX2EWBodies'.static.Standin(B, PeopleMaterialParent) : (Slots.Length > 0 ? Slots[0] : none);
		// (The props' textures and scalars on it too: XCOM 2's placeholder Masks darkened the white coats.)
		MIC = MaterialInstanceConstant(Slot);
		if (MIC != none && S.Diffuse != "")
		{
			for (k = 0; k < class'LWX2EWMapPieces'.default.StandinTextures.Length; k++)
			{
				T = Texture(DynamicLoadObject(class'LWX2EWMapPieces'.default.StandinTextures[k].Path, class'Texture', true));
				if (T != none)
					MIC.SetTextureParameterValue(class'LWX2EWMapPieces'.default.StandinTextures[k].Name, T);
			}
			for (k = 0; k < class'LWX2EWMapPieces'.default.StandinScalars.Length; k++)
				MIC.SetScalarParameterValue(class'LWX2EWMapPieces'.default.StandinScalars[k].Name, class'LWX2EWMapPieces'.default.StandinScalars[k].Value);
		}
		Slots.AddItem(Slot);
	}
	k = PeopleFrames.Find('Level', Level);
	At = (k != INDEX_NONE && VSize(P.Key) > 0) ? P.Key + PeopleFrames[k].Offset : P.Loc;
	// (Wherever it stands, overlapping or not: a Firestorm on its pad had failed to spawn.)
	A = Spawn(class'LWX2BasePerson', self, , At + Offset, P.Rot, , true);
	if (A == none)
	{
		`log("LongWarX2: EW base:" @ Level $ "'s" @ P.Mesh @ "not spawned at" @ At + Offset, , 'LongWarX2');
		return none;
	}
	A.SetDrawScale(P.Scale > 0 ? P.Scale : 1.0);
	if (!PeopleAnimate)
		Sets.Length = 0;
	A.Setup(Mesh, Sets, (PeopleAnimate && P.Seqs.Length > 0) ? P.Seqs[0] : '', Slots);
	return A;
}

/**
 * EW's hangar bays as XGFacility_Hangar.UpdateHangarBays has them: the home continent's craft in bays 1-4 (EW's
 * m_iHomeBay: each jet's Bay, LWHangar.AssignBays), each bay's launch pad posed
 * for its state (Open: its craft ready; Repair: down, refuelling, repairing or refitting; Closed: empty) with its
 * Interceptor or Firestorm on it (Anim_Hangar_LaunchBays' Base_Bay<n>_<state> matinees, read by the setup). Placed again
 * when that changes.
 */
function RefreshBays()
{
	local XComGameState_LWAirWar AirWar;
	local LWX2EWMapData D;
	local LWX2EWMapPieces.LWX2Person P;
	local array<string> States;
	local array<name> Parts;
	local LWX2BasePerson A;
	local XComGameState_LWAirWar.LWJet J;
	local string Sig, Path;
	local name ViewPart;
	local int i, Home;

	D = Data(BaysLevel);
	if (D == none || D.People.Length == 0)
		return;
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	Home = class'LWHangar'.static.HomeContinent();
	States.Length = 4;
	Parts.Length = 4;
	for (i = 0; i < 4; i++)
	{
		States[i] = "Closed";
		Parts[i] = '';
	}
	if (AirWar != none)
		foreach AirWar.Jets(J)
		{
			if (J.Bay < 1 || J.Bay > 4 || J.Continent != Home || J.Status == 6)
				continue;
			States[J.Bay - 1] = class'LWHangar'.static.IsReady(J) ? "Open" : "Repair";
			Parts[J.Bay - 1] = J.Type == 3 ? 'FireStorm' : 'Interceptor';
		}
	for (i = 0; i < 4; i++)
		Sig $= States[i] $ Parts[i] $ ";";
	// (The craft summary's view: every bay's craft away, bay 1's pad and the chosen craft in the ViewWeapons pose.)
	if (ViewJet > 0 && AirWar != none && ViewJet <= AirWar.Jets.Length)
	{
		ViewPart = AirWar.Jets[ViewJet - 1].Type == 3 ? 'FireStorm' : 'Interceptor';
		Sig $= "View" $ ViewPart;
	}
	if (Sig == BaysShown && BayActors.Length > 0)
		return;
	foreach BayActors(A)
		if (A != none)
			A.Destroy();
	BayActors.Length = 0;
	BaysShown = Sig;
	if (D.MapPackage != "")
		DynamicLoadObject(D.MapPackage $ ".TheWorld", class'Object', true);
	// (Every bay's meshes and animations held while the base lives: those of a craft not yet in a bay had been collected
	// with the level's package by the time one came, a Firestorm then not found.)
	if (BayAssets.Length == 0)
		foreach D.People(P)
			if (P.Bay > 0)
			{
				BayAssets.AddItem(DynamicLoadObject(P.Mesh, class'SkeletalMesh', true));
				foreach P.AnimSets(Path)
					BayAssets.AddItem(DynamicLoadObject(Path, class'AnimSet', true));
			}
	foreach D.People(P)
	{
		if (ViewPart != '')
		{
			if (P.BayState == "ViewWeapons" ? (P.BayPart != 'Track' && P.BayPart != ViewPart) : (P.BayPart != 'Track' || P.Bay == 1 || P.BayState != States[P.Bay - 1]))
				continue;
		}
		else if (P.Bay < 1 || P.Bay > 4 || P.BayState != States[P.Bay - 1] || (P.BayPart != 'Track' && P.BayPart != Parts[P.Bay - 1]))
			continue;
		A = PlacePerson(P, BaysLevel, BaseOffset);
		if (A == none)
			continue;
		BayActors.AddItem(A);
	}
	`log("LongWarX2: EW base: hangar bays" @ Sig @ "(" $ BayActors.Length @ "placed)", , 'LongWarX2');
}

/** The craft summary's view of a craft (EW's XGFacility_Hangar.SetupWeaponView), or the bays as they are (-1). */
function ViewCraft(int JetIndex)
{
	ViewJet = JetIndex + 1;
	RefreshBays();
}

/** EW's 3D UI panels placed, once, hidden (XCOM 2's 3D movie shows the one a screen asks for). */
function PlaceDisplays()
{
	local LWX2EWMapPieces.LWX2Display D;
	local LWX2UIDisplay A;
	local StaticMesh Mesh;
	local LWX2PlateDisplay P;
	local LWX2ScreenDisplay S;
	local MaterialInterface Mat;

	if (!ScreensIn3D || Displays.Length > 0)
		return;
	Mesh = StaticMesh(DynamicLoadObject(DisplayMesh, class'StaticMesh', true));
	Mat = MaterialInterface(DynamicLoadObject(DisplayMaterial, class'MaterialInterface', true));
	if (Mesh == none || Mat == none)
	{
		`log("LongWarX2: EW base: no display mesh or material (" $ DisplayMesh $ "," @ DisplayMaterial $ ")", , 'LongWarX2');
		return;
	}
	foreach PlateDisplays(P)
	{
		A = Spawn(class'LWX2UIDisplay', self, P.Tag, P.Loc + BaseOffset, P.Rot);
		if (A == none)
			continue;
		A.StaticMeshComponent.SetStaticMesh(Mesh);
		A.StaticMeshComponent.SetMaterial(0, Mat);
		A.StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0).SetScalarParameterValue('Visibility', 1.0);
		A.SetDrawScale3D(vect(1, 1, 1) * P.Scale);
		A.Tag = P.Tag;
		A.bEWMesh = true;
		A.StaticMeshComponent.SetHidden(true);
		Displays.AddItem(A);
	}
	foreach Data("Command1").Displays(D)
	{
		if (PlateDisplays.Find('Tag', D.Tag) != INDEX_NONE)
			continue;
		PlaceDisplay(D, D.Tag, Mesh, Mat);
		// (XCOM 2's screens drawn on this panel: one more display here, with the screen's tag.)
		foreach ScreenDisplays(S)
			if (S.Panel == D.Tag)
				PlaceDisplay(D, S.Screen, Mesh, Mat);
	}
	`log("LongWarX2: EW base:" @ Displays.Length @ "3D panels placed", , 'LongWarX2');
}

/** A display of ours on EW's panel D, tagged Tag: EW's own panel mesh, at EW's rotation and scale, where the converter
 *  found it; else XCOM 2's plate (Mesh), turned and scaled to EW's panel. */
function LWX2UIDisplay PlaceDisplay(LWX2EWMapPieces.LWX2Display D, name Tag, StaticMesh Mesh, MaterialInterface Mat, optional bool bAt, optional vector At)
{
	local LWX2UIDisplay A;
	local StaticMesh EWMesh;

	EWMesh = D.Mesh != "" ? StaticMesh(DynamicLoadObject(D.Mesh, class'StaticMesh', true)) : none;
	A = Spawn(class'LWX2UIDisplay', self, Tag, D.Loc + (bAt ? At : BaseOffset), EWMesh != none ? D.Rot : D.Rot + DisplayTurn);
	if (A == none)
		return none;
	A.StaticMeshComponent.SetStaticMesh(EWMesh != none ? EWMesh : Mesh);
	// (An instance: XCOM 2's 3D movie sets its Movie on the panel's instance, UIMovie_3D.ShowDisplayByInst.)
	A.StaticMeshComponent.SetMaterial(0, Mat);
	A.StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0).SetScalarParameterValue('Visibility', 1.0);
	A.SetDrawScale3D(EWMesh != none ? D.Scale : D.Scale * (DisplayScale > 0 ? DisplayScale : 1.0));
	A.Tag = Tag;
	A.bEWMesh = EWMesh != none;
	// (The mesh hidden, not the actor: XCOM 2's 3D movie unhides the mesh, UIMovie_3D.ShowDisplayByInst.)
	A.StaticMeshComponent.SetHidden(true);
	Displays.AddItem(A);
	return A;
}

/**
 * A facility level's own panels (the Cybernetics Lab's, on which EW draws its MEC inventory; the Genetics Lab's), placed
 * with its tile at the tile's place, and taken away with it (Placed: the tile's actors).
 */
function PlaceDisplaysOf(string Level, vector At, out array<Actor> Placed)
{
	local LWX2EWMapPieces.LWX2Display D;
	local LWX2UIDisplay A;
	local StaticMesh Mesh;
	local MaterialInterface Mat;

	if (!ScreensIn3D || Data(Level).Displays.Length == 0)
		return;
	// (Those of tiles changed since: gone with their tile.)
	Displays.RemoveItem(none);
	Mesh = StaticMesh(DynamicLoadObject(DisplayMesh, class'StaticMesh', true));
	Mat = MaterialInterface(DynamicLoadObject(DisplayMaterial, class'MaterialInterface', true));
	if (Mesh == none || Mat == none)
		return;
	foreach Data(Level).Displays(D)
	{
		A = PlaceDisplay(D, D.Tag, Mesh, Mat, true, At);
		if (A != none)
			Placed.AddItem(A);
	}
}

/** EW's camera for an XCOM 2 screen drawn on one of EW's panels (ScreenDisplays), by the screen's display tag; '' if none. */
static function name ScreenCamera(name DisplayTag)
{
	local int k;

	k = default.ScreenDisplays.Find('Screen', DisplayTag);
	return k != INDEX_NONE ? default.ScreenDisplays[k].Camera : '';
}

/** The panel of this tag (the first). */
static function LWX2UIDisplay DisplayFor(Actor Finder, name Tag)
{
	local LWX2EWBase B;
	local LWX2UIDisplay A;

	B = Get(Finder);
	if (B == none)
		return none;
	B.PlaceDisplays();
	// (The tiles brought up to date first: a facility's panels come with its tile, which a screen opened right after the
	// facility was built would otherwise look for before the base has placed it.)
	B.Refresh();
	// (A facility's panels go with its tile: none once it is gone.)
	foreach B.Displays(A)
		if (A != none && A.Tag == Tag)
			return A;
	return none;
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

/** Whether XCOM 2's armory screens show the soldier in EW's armory (converted here, its cameras there, and asked for). */
static function bool ArmoryHere()
{
	return default.ArmoryInBase && Converted() && Data("Command1").Cameras.Find('Tag', 'Armory_UIDisplayCam_Loadout') != INDEX_NONE;
}

/** Where the soldier stands in EW's armory for one of its cameras: ArmoryDistance in front of it, on the floor under that
 *  spot (EW's pieces placed with collision), facing it. */
/** A camera of EW's base (Command1's, by tag): where it is and how it looks; false when there is none. */
function bool CameraOf(name CameraTag, out vector Loc, out rotator Rot)
{
	local LWX2EWMapData Command;
	local int k;

	Command = Data("Command1");
	k = Command.Cameras.Find('Tag', CameraTag);
	if (k == INDEX_NONE)
		return false;
	Loc = Command.Cameras[k].Loc + default.BaseOffset;
	Rot = Command.Cameras[k].Rot;
	return true;
}

function ArmorySpot(name CameraTag, out vector Loc, out rotator Rot)
{
	// (Where EW stands the soldier for its armory screens: its plinth, XGStrategySoldier.PlaceOnPlinth.)
	if (Left(string(CameraTag), 6) ~= "Armory" && SpotFor('ArmorySoldierPlinth', Loc, Rot))
		return;
	CameraSpot(CameraTag, Loc, Rot);
}

/** EW's plinth of this tag (its Spots: Command1's, else in the first facility level that has it, placed with it), the
 *  base's offset added. False where the converted base has none. */
function bool SpotFor(name Tag, out vector Loc, out rotator Rot)
{
	local XComGameState_LWStrategy S;
	local LWX2EWMapData Command, D;
	local string Level;
	local int X, Y, i, k, Spot;

	Command = Data("Command1");
	// (The levels placed where they stand: Command1, the fixed rooms, EW's people's scenes, as the armory's Anim_Armory.)
	if (SpotIn(Command, Tag, Loc, Rot))
		return true;
	foreach FixedLevels(Level)
		if (SpotIn(Data(Level), Tag, Loc, Rot))
			return true;
	foreach PeopleLevels(Level)
		if (SpotIn(Data(Level), Tag, Loc, Rot))
			return true;
	S = class'XComGameState_LWStrategy'.static.Get();
	for (Y = 1; S != none && Y < class'LWBase'.const.H; Y++)
		for (X = 0; X < class'LWBase'.const.W; X++)
		{
			i = Y * class'LWBase'.const.W + X;
			if (i >= S.TileType.Length)
				continue;
			Level = LevelFor(S.TileType[i], S.TileFacility[i], X == class'LWBase'.const.SHAFT);
			k = Command.Rooms.Find('Tag', name("R" $ Y $ "_C" $ (X + 1)));
			D = (Level != "" && k != INDEX_NONE) ? Data(Level) : none;
			Spot = D != none ? D.Spots.Find('Tag', Tag) : INDEX_NONE;
			if (Spot == INDEX_NONE)
				continue;
			Loc = D.Spots[Spot].Loc + Command.Rooms[k].Loc + BaseOffset;
			Rot = D.Spots[Spot].Rot;
			return true;
		}
	return false;
}

/** A level's plinth of this tag, the base's offset added (the level placed where it stands). */
function bool SpotIn(LWX2EWMapData D, name Tag, out vector Loc, out rotator Rot)
{
	local int Spot;

	Spot = D != none ? D.Spots.Find('Tag', Tag) : INDEX_NONE;
	if (Spot == INDEX_NONE)
		return false;
	Loc = D.Spots[Spot].Loc + BaseOffset;
	Rot = D.Spots[Spot].Rot;
	return true;
}

/** In front of an armory camera (ArmoryDistance), on the floor, facing it: where the converted base has no plinth. */
function CameraSpot(name CameraTag, out vector Loc, out rotator Rot)
{
	local LWX2EWMapPieces.LWX2Camera C;
	local LWX2EWMapData Command;
	local vector Forward, HitLocation, HitNormal, Top, Bottom;
	local int k;

	Command = Data("Command1");
	k = Command.Cameras.Find('Tag', CameraTag);
	if (k == INDEX_NONE)
		return;
	C = Command.Cameras[k];
	Forward = vector(C.Rot);
	Forward.Z = 0;
	Forward = Normal(Forward);
	Loc = C.Loc + Forward * default.ArmoryDistance + default.BaseOffset;
	Top = Loc;
	Bottom = Loc;
	Bottom.Z -= 1000;
	if (Trace(HitLocation, HitNormal, Bottom, Top, false) != none)
		Loc.Z = HitLocation.Z;
	Rot = rotator(-Forward);
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
		TileOf.Length = 0;
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
			// (A tile placed before: its old level's actors taken away first, the rock an excavation removes, the facility a
			// removal does. They had stayed until the base was shown in a new world, over the new level.)
			for (k = Tiles.Length - 1; k >= 0; k--)
				if (TileOf[k] == i)
				{
					if (Tiles[k] != none)
						Tiles[k].Destroy();
					Tiles.Remove(k, 1);
					TileOf.Remove(k, 1);
				}
			PlacedType[i] = Type;
			PlacedFacility[i] = Facility;
			Level = LevelFor(Type, Facility, X == class'LWBase'.const.SHAFT);
			k = Command.Rooms.Find('Tag', name("R" $ Y $ "_C" $ (X + 1)));
			if (Level == "" || k == INDEX_NONE || Data(Level).Pieces.Length == 0)
				continue;
			Placed.Length = 0;
			class'LWX2EWMapPieces'.static.PlaceOf(Data(Level), self, vect(0, 0, 0), 0, Command.Rooms[k].Loc + BaseOffset, class'LWX2BasePiece', Placed, false, true);
			class'LWX2EWMapPieces'.static.PlaceLightsOf(Data(Level), self, Command.Rooms[k].Loc + BaseOffset, Placed, true, BaseLightScale, true);
			// (The facility's people and animated props too: the Genetics Lab's scientists and tanks, the Foundry's workers.)
			PlacePeopleOf(Level, Command.Rooms[k].Loc + BaseOffset, Placed);
			PlaceDisplaysOf(Level, Command.Rooms[k].Loc + BaseOffset, Placed);
			foreach Placed(A)
			{
				Tiles.AddItem(A);
				TileOf.AddItem(i);
			}
			n++;
		}
	}
	if (n > 0)
		`log("LongWarX2: EW base:" @ n @ "tiles placed," @ Tiles.Length @ "actors in all", , 'LongWarX2');
	RefreshBays();
}

/** EW's cut surfaces between the rooms and floors (the base's black, LWX2EWMapPieces' BaseBlackMaterials) shown or hidden. */
function ShowCutaway(bool bShow)
{
	local DynamicSMActor_Spawnable A;

	foreach DynamicActors(class'DynamicSMActor_Spawnable', A)
		if (A.Tag == 'LWX2BaseCutaway')
			A.SetHidden(!bShow);
}

/** A camera of a facility's level (EW's screens' m_strCameraTag: GeneLab_FacilityCamera, CyberneticsLab_UIDisplayCam …),
 *  where the first facility with that level stands: its place in the level and the tile's room (as PlaceTiles puts the
 *  level). False if no such facility is built. */
/** A camera of one of the levels placed where they stand (the fixed rooms, EW's people's scenes). */
function bool LevelCameraOf(name Tag, out LWX2EWMapPieces.LWX2Camera C)
{
	local string Level;
	local LWX2EWMapData D;
	local int k;

	foreach PeopleLevels(Level)
	{
		D = Data(Level);
		k = D != none ? D.Cameras.Find('Tag', Tag) : INDEX_NONE;
		if (k != INDEX_NONE)
		{
			C = D.Cameras[k];
			return true;
		}
	}
	return false;
}

function bool FacilityCameraOf(name Tag, out LWX2EWMapPieces.LWX2Camera C)
{
	local XComGameState_LWStrategy S;
	local LWX2EWMapData Command, D;
	local string Level;
	local int X, Y, i, k, Cam;

	S = class'XComGameState_LWStrategy'.static.Get();
	Command = Data("Command1");
	for (Y = 1; S != none && Y < class'LWBase'.const.H; Y++)
		for (X = 0; X < class'LWBase'.const.W; X++)
		{
			i = Y * class'LWBase'.const.W + X;
			if (i >= S.TileType.Length)
				continue;
			Level = LevelFor(S.TileType[i], S.TileFacility[i], X == class'LWBase'.const.SHAFT);
			k = Command.Rooms.Find('Tag', name("R" $ Y $ "_C" $ (X + 1)));
			if (Level == "" || k == INDEX_NONE)
				continue;
			D = Data(Level);
			Cam = D != none ? D.Cameras.Find('Tag', Tag) : INDEX_NONE;
			if (Cam == INDEX_NONE)
				continue;
			C = D.Cameras[Cam];
			C.Loc += Command.Rooms[k].Loc;
			return true;
		}
	return false;
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

/** The hologlobe among the placed pieces. */
function FindGlobe()
{
	local Actor A;

	foreach Fixed(A)
		if (DynamicSMActor(A) != none && DynamicSMActor(A).StaticMeshComponent.StaticMesh != none
			&& DynamicSMActor(A).StaticMeshComponent.StaticMesh.Name == 'Globe' && A.DrawScale3D.X > 0.5)
		{
			Globe = A;
			`log("LongWarX2: EW base: the hologlobe found, turning", , 'LongWarX2');
			return;
		}
}

event Tick(float DeltaTime)
{
	local rotator R;
	local int Step;

	super.Tick(DeltaTime);
	if (Globe == none)
		return;
	R = Globe.Rotation;
	if (GlobeHoldYaw >= 0)
	{
		// Towards the held turn, the short way round, at most a turn in a few seconds.
		Step = ((GlobeHoldYaw - R.Yaw) % 65536 + 98304) % 65536 - 32768;
		R.Yaw += Clamp(Step, -int(16384.0 * DeltaTime), int(16384.0 * DeltaTime));
	}
	else if (GlobeSeconds > 0)
		R.Yaw += int(65536.0 * DeltaTime / GlobeSeconds);
	else
		return;
	Globe.SetRotation(R);
}

/** A place on EW's flat earth (0 to 1 across and down) as a direction in the globe's own frame. */
function vector GlobeDir(float MapX, float MapY)
{
	local float Lon, Lat;
	local vector D;

	Lon = (MapX - 0.5) * 2 * Pi * (bGlobeMirrored ? -1 : 1) * (GlobeLonScale > 0 ? GlobeLonScale : 1.0) + GlobeLonOffset * Pi / 180;
	Lat = (0.5 - MapY) * Pi;
	D.X = Cos(Lat) * Cos(Lon);
	D.Y = Cos(Lat) * Sin(Lon);
	D.Z = Sin(Lat);
	return D;
}

/** The globe's markers set again: each place a small sphere on its surface in its colour, turning with it. */
function SetGlobeMarkers(array<float> Xs, array<float> Ys, array<LinearColor> Colours)
{
	local Actor A;
	local DynamicSMActor M;
	local float R;
	local int i;
	local vector At, Centre;

	foreach GlobeMarkers(A)
		A.Destroy();
	GlobeMarkers.Length = 0;
	if (Globe == none)
		return;
	// (The sphere's centre is its bounds' centre: the mesh's pivot need not be.)
	R = DynamicSMActor(Globe).StaticMeshComponent.Bounds.SphereRadius;
	Centre = DynamicSMActor(Globe).StaticMeshComponent.Bounds.Origin;
	for (i = 0; i < Xs.Length; i++)
	{
		At = Centre + ((GlobeDir(Xs[i], Ys[i]) * R) >> Globe.Rotation);
		M = Spawn(class'LWX2BasePiece', self, , At);
		if (M == none)
			continue;
		M.SetStaticMesh(DynamicSMActor(Globe).StaticMeshComponent.StaticMesh);
		M.SetDrawScale3D(vect(1, 1, 1) * Globe.DrawScale3D.X * 0.035);
		M.SetCollision(false, false);
		M.StaticMeshComponent.SetMaterial(0, class'LWX2EWMapPieces'.static.TintedStandin(Colours[i], M));
		M.SetHardAttach(true);
		M.SetBase(Globe);
		GlobeMarkers.AddItem(M);
	}
}

/** The globe turned to show a place to the camera (EW's CAMLookAtEarth as an alert opens), held there; or turning again. */
function FaceGlobe(float MapX, float MapY, optional bool bRelease)
{
	local vector ToCam, D, CamLoc;
	local rotator CamRot;
	local float CamYaw, PlaceYaw;

	if (Globe == none || bRelease)
	{
		GlobeHoldYaw = -1;
		return;
	}
	GetALocalPlayerController().GetPlayerViewPoint(CamLoc, CamRot);
	ToCam = CamLoc - DynamicSMActor(Globe).StaticMeshComponent.Bounds.Origin;
	CamYaw = Atan2(ToCam.Y, ToCam.X);
	D = GlobeDir(MapX, MapY);
	PlaceYaw = Atan2(D.Y, D.X);
	GlobeHoldYaw = ((int((CamYaw - PlaceYaw) * 32768.0 / Pi) % 65536) + 65536) % 65536;
}

defaultproperties
{
	GlobeHoldYaw = -1
	ViewTag = Base
	bHidden = true
}
