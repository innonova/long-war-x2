// One converted Enemy Within map (tools/convert/ew-map.ts writes its section, [<map> LWX2EWMapData], into
// XComLWX2EWMap.ini on the player's machine; not in the repository): its package, play area, drop zones, pods,
// spawn points, lights, materials and pieces. LWX2EWMapPieces.Map() gives the mission's.
class LWX2EWMapData extends Object config(LWX2EWMap) perobjectconfig dependson(LWX2EWMapPieces);

/** The converted map package: loaded first, so its meshes exist (they live in the packages it carries). */
var config string MapPackage;
var config array<LWX2EWMapPieces.LWX2Look> Looks;
var config array<LWX2EWMapPieces.LWX2Piece> Pieces;
/** EW's play area (its level volume: centre and half sizes) and drop zones (its player starts). */
var config vector PlayCenter;
var config vector PlayExtent;
var config array<vector> DropZones;
var config array<LWX2EWMapPieces.LWX2Pod> Pods;
var config array<vector> SpawnPoints;
var config array<LWX2EWMapPieces.LWX2Meld> MeldPoints;
var config array<LWX2EWMapPieces.LWX2Light> Lights;
/** EW's base (Command1): its room locations and cameras (features/lw-base-view.md). */
var config array<LWX2EWMapPieces.LWX2Room> Rooms;
var config array<LWX2EWMapPieces.LWX2Camera> Cameras;
/** EW's plinths, where it stands a soldier or MEC for a screen (ArmorySoldierPlinth …: XGStrategySoldier.PlaceOnPlinth);
 *  a place and a rotation by tag (FOV unused). */
var config array<LWX2EWMapPieces.LWX2Camera> Spots;
/** EW's 3D UI panels (features/ew-3d-screens.md). */
var config array<LWX2EWMapPieces.LWX2Display> Displays;
/** EW's people (features/ew-base-people.md). */
var config array<LWX2EWMapPieces.LWX2Person> People;
/** EW's emitters and their sprites (features/ew-emitters.md). */
var config array<LWX2EWMapPieces.LWX2Emitter> Emitters;
var config array<LWX2EWMapPieces.LWX2ParticleLook> ParticleLooks;
