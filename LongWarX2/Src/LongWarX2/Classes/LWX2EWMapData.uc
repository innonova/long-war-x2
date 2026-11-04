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
