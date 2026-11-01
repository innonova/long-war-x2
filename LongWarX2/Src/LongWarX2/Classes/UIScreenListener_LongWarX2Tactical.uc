// In a tactical mission, for the experiments (features/hard-parts.md), each behind its switch:
// an Enemy Within unit shown beside the first soldier (experiment 1), and the effect on the
// tile data of the EW map part placed on the Tactical Quick Launch screen (LWX2PartPlacer,
// experiment 2). Both need the player's converted packages in the mod's Content.
class UIScreenListener_LongWarX2Tactical extends UIScreenListener config(LWAirWar);

var config bool ShowEWUnit;
var config bool PlaceEWMapPart;
/** The whole EW map in place of the generated one (instead of a part). */
var config bool PlaceEWMapWhole;
/** The part of the EW map (its coordinates): the pieces within the radius of the centre. */
var config vector PartCenter;
var config float PartRadius;
/** Where the part's centre goes, from the soldiers' spawn (its floor). */
var config vector PartOffset;

event OnInit(UIScreen Screen)
{
	local XComUnitPawn Pawn;
	local LWX2EWUnitDisplay Display;

	if (UITacticalHUD(Screen) == none)
		return;
	class'LWX2PerkProbe'.static.Start(Screen);
	if (class'UIScreenListener_LongWarX2HQ'.default.ShowTestEndMission && XGBattle_SP(`BATTLE) != none && !`BATTLE.m_kDesc.bIsTacticalQuickLaunch)
		AddEndButton(Screen);
	foreach Screen.WorldInfo.AllActors(class'LWX2EWUnitDisplay', Display)
		return;
	foreach Screen.WorldInfo.AllActors(class'XComUnitPawn', Pawn)
	{
		if (XComHumanPawn(Pawn) != none)
			break;
	}
	`log("LongWarX2: tactical HUD; first soldier pawn" @ Pawn, , 'LongWarX2');
	if (Pawn == none)
		return;
	if (default.PlaceEWMapPart || default.PlaceEWMapWhole)
	{
		ReportMapPart(Screen, Pawn);
		Screen.SetTimer(40.0, false, nameof(ReportReach), self);
	}
	if (!default.ShowEWUnit)
		return;
	Display = Screen.WorldInfo.Spawn(class'LWX2EWUnitDisplay');
	if (!Display.ShowBeside(Pawn))
		Display.Destroy();
}

/** For development (experiment 4): a button that ends a campaign's mission as won, through the ruleset, as XCOM 2's cheat does. */
function AddEndButton(UIScreen Screen)
{
	local UIButton Button;

	Button = Screen.Spawn(class'UIButton', Screen);
	Button.InitButton('LWX2EndMission', "LONG WAR TEST: END MISSION AS WON", OnEndMission);
	Button.SetPosition(40, 200);
}

function OnEndMission(UIButton Button)
{
	`log("LongWarX2: test: mission ended as won", , 'LongWarX2');
	`TACTICALRULES.EndBattle(XGBattle_SP(`BATTLE).GetHumanPlayer());
}

/** After the battle started: the EW map's effect on the tile data around the placement, and whether its pieces collide. */
function ReportMapPart(UIScreen Screen, XComUnitPawn Pawn)
{
	local XComWorldData World;
	local LWX2LevelActor Piece;
	local vector At, HitLocation, HitNormal, FloorPos, Probe;
	local Actor Hit;
	local TTile Centre, T;
	local int n, dx, dy, Floors, Enterable;
	local XGUnit Unit;
	local array<TTile> Reachable;

	World = `XWORLD;
	foreach Screen.WorldInfo.AllActors(class'LWX2LevelActor', Piece)
		n++;
	if (n == 0)
		return;
	At = class'LWX2PartPlacer'.default.PlacedAt;
	Hit = Screen.Trace(HitLocation, HitNormal, At - vect(0, 0, 400), At + vect(0, 0, 2000), false);
	Centre = World.GetTileCoordinatesFromPosition(At);
	for (dx = -7; dx <= 7; dx++)
		for (dy = -7; dy <= 7; dy++)
		{
			T = Centre;
			T.X += dx;
			T.Y += dy;
			Probe = World.GetPositionFromTileCoordinates(T);
			if (World.GetFloorTileForPosition(Probe, T, true))
			{
				Floors++;
				if (World.GetFloorPositionForTile(T, FloorPos) && World.CanUnitsEnterTile(T))
					Enterable++;
			}
		}
	Unit = XGUnit(Pawn.GetGameUnit());
	if (Unit != none && Unit.m_kReachableTilesCache != none)
	{
		Unit.m_kReachableTilesCache.UpdateTileCacheIfNeeded();
		Unit.m_kReachableTilesCache.GetAllPathableTiles(Reachable);
	}
	`log("LongWarX2: EW map in the battle: the first soldier" @ Unit @ "can reach" @ Reachable.Length @ "tiles; the line hits" @ (StaticMeshActor(Hit) != none ? string(StaticMeshActor(Hit).StaticMeshComponent.StaticMesh) : "-") @ "collide" @ Hit.bCollideActors @ "block" @ Hit.bBlockActors @ "hidden" @ Hit.bHidden, , 'LongWarX2');
	`log("LongWarX2: EW map in the battle:" @ n @ "pieces; around" @ At @ "(tile" @ Centre.X $ "," $ Centre.Y $ "," $ Centre.Z $ "): floor tiles" @ Floors @ "of 225, enterable" @ Enterable $ "; cover points" @ class'LWX2EWMapPieces'.static.CountCover(World, At, default.PartRadius) $ "; a line down hits" @ Hit @ "at" @ HitLocation $ "; the first soldier at" @ Pawn.Location, , 'LongWarX2');
}

/** Of the tiles 1 to 5 tiles away from the unit (a ring of 120), how many its path cache says it can reach. */
function int CountReachableAround(XGUnit Unit)
{
	local XComWorldData World;
	local TTile Centre, T;
	local vector Probe;
	local int dx, dy, n;

	World = `XWORLD;
	Probe = Unit.GetPawn().Location;
	Centre = World.GetTileCoordinatesFromPosition(Probe);
	for (dx = -5; dx <= 5; dx++)
		for (dy = -5; dy <= 5; dy++)
		{
			if (dx == 0 && dy == 0)
				continue;
			T = Centre;
			T.X += dx;
			T.Y += dy;
			Probe = World.GetPositionFromTileCoordinates(T);
			if (World.GetFloorTileForPosition(Probe, T, true) && Unit.m_kReachableTilesCache.IsTileReachable(T))
				n++;
		}
	return n;
}

/** Later, once the mission has settled: how far each soldier can move. */
function ReportReach()
{
	local XGUnit Unit;
	local array<TTile> Reachable;
	local string Out;

	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XGUnit', Unit)
	{
		if (Unit.m_kReachableTilesCache == none)
			continue;
		Unit.m_kReachableTilesCache.ForceCacheUpdate();
		Unit.m_kReachableTilesCache.UpdateTileCacheIfNeeded();
		Reachable.Length = 0;
		Unit.m_kReachableTilesCache.GetAllPathableTiles(Reachable, 100000, false);
		Out @= Unit.GetVisualizedGameState().GetMyTemplateName() $ ":" $ Reachable.Length $ "/" $ CountReachableAround(Unit);
	}
	`log("LongWarX2: EW map in the battle, later: tiles each unit can reach:" $ Out, , 'LongWarX2');
	ReportPerks();
}

/** Each soldier of a Long War class: its Long War effects in play (features/lw-classes.md). */
function ReportPerks()
{
	local XComGameState_Unit Unit;
	local name Effect;
	local string Out;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Left(string(Unit.GetSoldierClassTemplateName()), 4) != "LWS_")
			continue;
		Out = "";
		foreach Unit.AffectedByEffectNames(Effect)
			if (Left(string(Effect), 3) == "LW_")
				Out @= string(Effect);
		`log("LongWarX2: Long War perks in play:" @ Unit.GetFullName() @ "(" $ Unit.GetSoldierClassTemplateName() @ "rank" @ Unit.GetRank() $ "): aim" @ Unit.GetCurrentStat(eStat_Offense) @ "mobility" @ Unit.GetCurrentStat(eStat_Mobility) $ ";" $ Out, , 'LongWarX2');
	}
}

defaultproperties
{
	ScreenClass = none;
}
