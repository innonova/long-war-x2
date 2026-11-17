// A mission variant level's alien drops (features/lw-council-missions.md, step 4), as its Kismet has them (read by
// tools/convert/ew-objectives.ts readDrops into XComLWX2EWObjectives.ini): a soldier entering one of its volumes opens a
// gate, and as the aliens' turn ends the gate's aliens drop at their spawn points, once. Progeny's Portent and Furies
// have them, and so have the council's variants (the Thin Men of the Highway extraction, the Research Outpost rescue).
// The dropped aliens are set on the nearest soldier (EW's bRevealSpawn, bTriggerOverwatch).
class LWX2LevelDrops extends Object config(LWX2EWObjectives);

struct LWX2DropVolume
{
	var string Level;
	var vector Center, Extent;
};

struct LWX2LevelDrop
{
	var string Level;
	var int Volume;
	var int Char;
	var vector At;
};

var config array<LWX2DropVolume> Volumes;
var config array<LWX2LevelDrop> Drops;

/** The variant level being played (the plot LWX2V_<level>), when it has drops. */
static function bool Active(out string Level)
{
	local XComGameState_BattleData Battle;

	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (Battle == none || Left(Battle.MapData.PlotMapName, 6) != "LWX2V_")
		return false;
	Level = Mid(Battle.MapData.PlotMapName, 6);
	return default.Drops.Find('Level', Level) != INDEX_NONE;
}

static function XComGameState_LWX2Drops State()
{
	local XComGameState_LWX2Drops D;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWX2Drops', D)
		return D;
	return none;
}

static function array<LWX2DropVolume> VolumesOf(string Level)
{
	local array<LWX2DropVolume> Out;
	local LWX2DropVolume V;

	foreach default.Volumes(V)
		if (V.Level ~= Level)
			Out.AddItem(V);
	return Out;
}

static function array<LWX2LevelDrop> DropsOf(string Level)
{
	local array<LWX2LevelDrop> Out;
	local LWX2LevelDrop D;

	foreach default.Drops(D)
		if (D.Level ~= Level)
			Out.AddItem(D);
	return Out;
}

/** Asked twice a second in the mission (UIScreenListener_LongWarX2Tactical): volumes entered, drops made at the aliens' turn's end. */
static function Update()
{
	local XComGameState_LWX2Drops S;
	local XComGameState NewGameState;
	local array<LWX2DropVolume> Vols;
	local array<LWX2LevelDrop> All;
	local array<XComGameState_Unit> Squad;
	local array<int> Before, Hunters, Due;
	local array<name> Names;
	local array<int> Species;
	local XComGameState_Unit Unit;
	local string Level;
	local int i, Now;
	local bool bChanged, bAlienTurnEnded;

	if (!Active(Level))
		return;
	Vols = VolumesOf(Level);
	All = DropsOf(Level);
	S = State();
	if (S == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the level's drops");
		S = XComGameState_LWX2Drops(NewGameState.CreateNewStateObject(class'XComGameState_LWX2Drops'));
		for (i = 0; i < Vols.Length; i++)
			S.Entered.AddItem(0);
		for (i = 0; i < All.Length; i++)
			S.Dropped.AddItem(0);
		S.LastTurn = class'LWX2CovertExtraction'.static.TurnNow();
		`TACTICALRULES.SubmitGameState(NewGameState);
		`log("LongWarX2: level drops on" @ Level $ ":" @ Vols.Length @ "volumes," @ All.Length @ "drops", , 'LongWarX2');
		return;
	}
	Squad = class'LWX2ChryssalidHive'.static.Seeing();
	Now = class'LWX2CovertExtraction'.static.TurnNow();
	bAlienTurnEnded = Now != S.LastTurn;
	for (i = 0; i < Vols.Length && i < S.Entered.Length; i++)
		if (S.Entered[i] == 0 && AnyInside(Squad, Vols[i]))
			bChanged = true;
	if (bAlienTurnEnded)
		for (i = 0; i < All.Length && i < S.Dropped.Length; i++)
			if (S.Dropped[i] == 0 && All[i].Volume < S.Entered.Length && S.Entered[All[i].Volume] != 0)
				Due.AddItem(i);
	if (!bChanged && !bAlienTurnEnded)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the level's drops");
	S = XComGameState_LWX2Drops(NewGameState.ModifyStateObject(class'XComGameState_LWX2Drops', S.ObjectID));
	S.LastTurn = Now;
	for (i = 0; i < Vols.Length && i < S.Entered.Length; i++)
		if (S.Entered[i] == 0 && AnyInside(Squad, Vols[i]))
		{
			S.Entered[i] = 1;
			`log("LongWarX2: level drops: volume" @ i @ "entered", , 'LongWarX2');
		}
	foreach Due(i)
		S.Dropped[i] = 1;
	`TACTICALRULES.SubmitGameState(NewGameState);
	if (Due.Length == 0)
		return;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien)
			Before.AddItem(Unit.ObjectID);
	foreach Due(i)
	{
		Names.Length = 0;
		Species.Length = 0;
		Names.AddItem(class'LWMissionSquads'.static.TemplateFor(All[i].Char));
		Species.AddItem(All[i].Char);
		class'LWMissionSquads'.static.SpawnPod(name("LWX2_Drop" $ i), All[i].At, Names, Species);
	}
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && Before.Find(Unit.ObjectID) == INDEX_NONE)
			Hunters.AddItem(Unit.ObjectID);
	if (Hunters.Length > 0)
		class'LWX2ChryssalidHive'.static.Hunt(Hunters);
	`log("LongWarX2: level drops:" @ Hunters.Length @ "aliens dropped", , 'LongWarX2');
}

static function bool AnyInside(array<XComGameState_Unit> Squad, LWX2DropVolume V)
{
	local XComGameState_Unit Unit;

	foreach Squad(Unit)
		if (class'LWX2ChryssalidHive'.static.Inside(V.Center, V.Extent, `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation)))
			return true;
	return false;
}
