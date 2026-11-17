// Progeny's Deluge on its EW map (features/lw-council-missions.md, step 4; the DLC2_2_Deluge_Stream level's Kismet with EW's
// bomb handler, read by tools/convert/ew-objectives.ts readDeluge into XComLWX2EWObjectives.ini). The dam collapses in six
// XCOM turns ("Turns Until Collapse"); each bypass valve a soldier opens from beside it (one action) adds two, until the
// transport vehicle is spotted or every valve is open; each valve opened brings its aliens as the aliens' turn ends. A
// soldier reaching the transport (its volume) once it is spotted, or with every valve open, secures it: the mission is
// won. At 0 the dam breaks: six more turns ("Turns Remaining"), every soldier to report to the EVAC zone; the mission is
// then lost, whether they get out or the time runs out.
class LWX2Deluge extends Object config(LWX2EWObjectives) dependson(LWCouncil);

struct LWX2DelugeDef
{
	var string Map;
	var string Level;
	var array<vector> Valves;
	var vector SpottedCenter, SpottedExtent;
	var vector SecureCenter, SecureExtent;
	var int Turns;
	var int ValveTurns;
	/** EW's texts: locate the transport, open the valves, secure it, report to the EVAC; the counts' labels. */
	var string Locate, ValvesText, SecureText, Report, Collapse, Remaining;
};

struct LWX2DelugeDrop
{
	var string Level;
	var int Valve;
	var int Char;
	var vector At;
};

var config array<LWX2DelugeDef> Deluges;
var config array<LWX2DelugeDrop> Drops;
/** How far from a valve a soldier may open it, in tiles. */
var config float ReachTiles;

/** Deluge being played: the council's mission 26 on its variant plot. */
static function bool Active(out LWX2DelugeDef D)
{
	local LWCouncil.LWCouncilMission M;
	local XComGameState_BattleData Battle;
	local int k;

	if (!class'LWCouncil'.static.Current(M) || M.Id != 26 || M.Level == "")
		return false;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (Battle == none || !(Battle.MapData.PlotMapName ~= ("LWX2V_" $ M.Level)))
		return false;
	k = default.Deluges.Find('Level', M.Level);
	if (k == INDEX_NONE)
		return false;
	D = default.Deluges[k];
	return true;
}

static function XComGameState_LWX2Deluge State()
{
	local XComGameState_LWX2Deluge D;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWX2Deluge', D)
		return D;
	return none;
}

/** The closed valve the unit can open from its tile (while the transport is not yet secured, before the dam breaks), or -1. */
static function int InReach(XComGameState_Unit Unit)
{
	local LWX2DelugeDef D;
	local XComGameState_LWX2Deluge S;
	local vector At;
	local int i;

	if (Unit == none || !Active(D))
		return -1;
	S = State();
	if (S == none || S.Stage > 2)
		return -1;
	At = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
	for (i = 0; i < D.Valves.Length && i < S.ValveOpen.Length; i++)
		if (S.ValveOpen[i] == 0 && VSize2D(D.Valves[i] - At) <= (default.ReachTiles > 0 ? default.ReachTiles : 1.5) * class'XComWorldData'.const.WORLD_StepSize
			&& Abs(D.Valves[i].Z - At.Z) <= 2 * class'XComWorldData'.const.WORLD_FloorHeight)
			return i;
	return -1;
}

/** A valve opened (X2Effect_LWX2Valve): two more turns to the collapse (the AddInt on Turns Left). */
static function Opened(XComGameState NewGameState, XComGameState_Unit Unit)
{
	local LWX2DelugeDef D;
	local XComGameState_LWX2Deluge S;
	local int i;

	S = State();
	i = InReach(Unit);
	if (S == none || i < 0 || !Active(D))
		return;
	S = XComGameState_LWX2Deluge(NewGameState.ModifyStateObject(class'XComGameState_LWX2Deluge', S.ObjectID));
	S.ValveOpen[i] = 1;
	S.TurnsLeft += D.ValveTurns;
	`log("LongWarX2: Deluge: valve" @ i @ "opened;" @ S.ValvesOpen() @ "of" @ D.Valves.Length $ "," @ S.TurnsLeft @ "turns to the collapse", , 'LongWarX2');
}

/** Asked twice a second in the mission (UIScreenListener_LongWarX2Tactical): the objectives, the countdown, the drops, the
 *  transport secured. False while Deluge holds the victory back (until the transport is secured). */
static function bool Update()
{
	local LWX2DelugeDef D;
	local XComGameState_LWX2Deluge S;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local array<XComGameState_Unit> Squad;
	local vector At;
	local int i, Now, Stage;
	local bool bAlienTurnEnded, bXComTurnEnded, bSecured, bStanding, bAway;

	if (!Active(D))
		return true;
	S = State();
	if (S == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Deluge");
		S = XComGameState_LWX2Deluge(NewGameState.CreateNewStateObject(class'XComGameState_LWX2Deluge'));
		S.Stage = 1;
		S.TurnsLeft = D.Turns;
		S.LastTurn = class'LWX2CovertExtraction'.static.TurnNow();
		S.CountedTurn = -1;
		for (i = 0; i < D.Valves.Length; i++)
		{
			S.ValveOpen.AddItem(0);
			S.Dropped.AddItem(0);
		}
		`TACTICALRULES.SubmitGameState(NewGameState);
		`log("LongWarX2: Deluge on" @ D.Map $ ":" @ D.Valves.Length @ "valves," @ D.Turns @ "turns to the collapse", , 'LongWarX2');
		return false;
	}
	if (S.Stage >= 5)
		return true;
	Squad = class'LWX2ChryssalidHive'.static.Seeing();
	Stage = S.Stage;
	foreach Squad(Unit)
	{
		At = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
		if (Stage == 1 && class'LWX2ChryssalidHive'.static.Inside(D.SpottedCenter, D.SpottedExtent, At))
			Stage = 2;
		// (EW's control button: once the transport is spotted, or every valve is open; not once the dam has broken.)
		if (Stage <= 2 && (Stage == 2 || S.ValvesOpen() == D.Valves.Length) && class'LWX2ChryssalidHive'.static.Inside(D.SecureCenter, D.SecureExtent, At))
			bSecured = true;
	}
	Now = class'LWX2CovertExtraction'.static.TurnNow();
	bAlienTurnEnded = Now != S.LastTurn;
	bXComTurnEnded = !bAlienTurnEnded && !class'LWX2ChryssalidHive'.static.XComTurn() && S.CountedTurn != Now;
	if (Stage != S.Stage || bAlienTurnEnded || bXComTurnEnded || bSecured)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Deluge's turn");
		S = XComGameState_LWX2Deluge(NewGameState.ModifyStateObject(class'XComGameState_LWX2Deluge', S.ObjectID));
		S.Stage = bSecured ? 5 : Stage;
		if (bAlienTurnEnded)
			S.LastTurn = Now;
		if (bXComTurnEnded && !bSecured)
		{
			S.CountedTurn = Now;
			S.TurnsLeft--;
			if (S.TurnsLeft <= 0 && S.Stage <= 2)
			{
				// Breaking point: the run to the EVAC (Turn Max again), the zone at the Skyranger.
				S.Stage = 3;
				S.TurnsLeft = D.Turns;
				class'XComGameState_EvacZone'.static.PlaceEvacZone(NewGameState, class'LWX2CouncilVIP'.static.Floor(class'LWX2CovertExtraction'.static.Skyranger()), eTeam_XCom);
				`log("LongWarX2: Deluge: the dam broke; report to the EVAC in" @ S.TurnsLeft @ "turns", , 'LongWarX2');
			}
		}
		`TACTICALRULES.SubmitGameState(NewGameState);
		S = State();
		if (S.Stage == 3 && class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom) != none)
		{
			class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).FindOrCreateVisualizer();
			class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).SyncVisualizer();
		}
		if (bAlienTurnEnded)
			DropDue(D, S);
	}
	if (bSecured)
	{
		`log("LongWarX2: Deluge: the transport is secured; the mission is won", , 'LongWarX2');
		if (!`TACTICALRULES.HasTacticalGameEnded())
			class'UIScreenListener_LongWarX2Tactical'.static.TestWin();
		return true;
	}
	if (S.Stage == 3)
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
			if (Unit.GetTeam() == eTeam_XCom && Unit.IsSoldier() && Unit.IsAlive())
			{
				if (Unit.bRemovedFromPlay)
					bAway = true;
				else
					bStanding = true;
			}
		if ((S.TurnsLeft <= 0 || (bAway && !bStanding)) && !`TACTICALRULES.HasTacticalGameEnded())
		{
			`log("LongWarX2: Deluge: the dam broke and" @ (S.TurnsLeft <= 0 ? "the time ran out" : "the squad left") $ ": the mission is lost", , 'LongWarX2');
			`TACTICALRULES.EndBattle(XGBattle_SP(`BATTLE).GetAIPlayer());
		}
	}
	return false;
}

/** The aliens of each valve opened since, as the aliens' turn ends (Spawn_New_Aliens: the valve's group, once). */
static function DropDue(LWX2DelugeDef D, XComGameState_LWX2Deluge S)
{
	local XComGameState NewGameState;
	local array<int> Due, Before, Hunters;
	local array<name> Names;
	local array<int> Species;
	local XComGameState_Unit Unit;
	local LWX2DelugeDrop Drop;
	local int i, n;

	for (i = 0; i < S.ValveOpen.Length; i++)
		if (S.ValveOpen[i] != 0 && S.Dropped[i] == 0)
			Due.AddItem(i);
	if (Due.Length == 0)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Deluge's drops");
	S = XComGameState_LWX2Deluge(NewGameState.ModifyStateObject(class'XComGameState_LWX2Deluge', S.ObjectID));
	foreach Due(i)
		S.Dropped[i] = 1;
	`TACTICALRULES.SubmitGameState(NewGameState);
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien)
			Before.AddItem(Unit.ObjectID);
	foreach default.Drops(Drop)
	{
		if (!(Drop.Level ~= D.Level) || Due.Find(Drop.Valve) == INDEX_NONE)
			continue;
		Names.Length = 0;
		Species.Length = 0;
		Names.AddItem(class'LWMissionSquads'.static.TemplateFor(Drop.Char));
		Species.AddItem(Drop.Char);
		class'LWMissionSquads'.static.SpawnPod(name("LWX2_Deluge" $ n++), Drop.At, Names, Species);
	}
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && Before.Find(Unit.ObjectID) == INDEX_NONE)
			Hunters.AddItem(Unit.ObjectID);
	if (Hunters.Length > 0)
		class'LWX2ChryssalidHive'.static.Hunt(Hunters);
	`log("LongWarX2: Deluge:" @ Hunters.Length @ "aliens dropped for" @ Due.Length @ "valves", , 'LongWarX2');
}

static function string ObjectiveText()
{
	local LWX2DelugeDef D;
	local XComGameState_LWX2Deluge S;

	if (!Active(D))
		return "";
	S = State();
	if (S == none)
		return D.Locate @ D.ValvesText @ D.Collapse @ D.Turns;
	if (S.Stage == 3)
		return D.Report @ D.Remaining @ S.TurnsLeft;
	if (S.Stage == 2 || S.ValvesOpen() == D.Valves.Length)
		return D.SecureText @ (S.ValvesOpen() < D.Valves.Length ? D.ValvesText $ " " : "") $ D.Collapse @ S.TurnsLeft;
	return D.Locate @ D.ValvesText @ D.Collapse @ S.TurnsLeft;
}
