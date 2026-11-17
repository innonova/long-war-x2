// The Temple Ship on its EW map (features/lw-story.md; EW's XComSpecialMissionHandler_Templeship and the TempleShip level's
// Kismet, read by tools/convert/ew-objectives.ts readTemple into XComLWX2EWObjectives.ini). Not Long War's squad at the map's
// pods: the level's own arenas, each pod of the alien type EW's level forces on it, with Long War's stats for that species.
// - The first arena stands at the start. When FirstSwarmAt or fewer aliens are left (the handler's LiveAliensThreshold, counted
//   when an alien is hurt), its first swarm (Cyberdiscs and Drones) comes as the aliens' turn ends; at SecondSwarmAt or fewer, its second (Chryssalids).
// - When all of those are dead, the second arena's pods stand (OpenSecondArena); when they are dead too, the boss gate opens:
//   two Elite Mutons at it (BossGateOpen) and the Uber Ethereal in the boss arena (BossArena_Begin). Once XCOM sees the Uber
//   Ethereal, its guard comes: two Ethereals and two Elite Mutons (UberVisibleComplete).
// - The Uber Ethereal's death wins the battle: every alien left dies with it (the handler's DoWin). Killing the rest wins
//   nothing before that.
class LWX2TempleShip extends Object config(LWX2EWObjectives);

struct LWX2TemplePod
{
	var int Arena;
	var int Char;
	var int Min, Max;
	var vector At;
};

struct LWX2TempleSpawn
{
	/** 1 the first swarm, 2 the second, 3 the boss gate, 4 the boss arena (the Uber Ethereal), 5 the Uber Ethereal seen. */
	var int Stage;
	var int Char;
	var vector At;
};

var config array<LWX2TemplePod> Pods;
var config array<LWX2TempleSpawn> Spawns;
/** EW's handler: the first swarm once this many aliens or fewer are left (FirstArena's LiveAliensThreshold), the second
 *  once this many (FirstArena_Wave1's). */
var config int FirstSwarmAt;
var config int SecondSwarmAt;
/** Long War's character of the Uber Ethereal (ECharacter). */
var config int UberChar;

/** The Temple Ship being played: its plot, and its level read on this machine. */
static function bool Active()
{
	local XComGameState_BattleData Battle;

	if (default.Pods.Length == 0)
		return false;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	return Battle != none && Battle.MapData.PlotMapName ~= "LWX2_TempleShip";
}

static function XComGameState_LWX2Temple State()
{
	local XComGameState_LWX2Temple T;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWX2Temple', T)
		return T;
	return none;
}

/** The aliens alive and on the field (the handler's count: its squad's members alive and well). */
static function int LiveAliens()
{
	local XComGameState_Unit Unit;
	local int n;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && Unit.IsAlive() && !Unit.bRemovedFromPlay && !Unit.GetMyTemplate().bIsCosmetic)
			n++;
	return n;
}

/** Asked twice a second in the mission (UIScreenListener_LongWarX2Tactical): the arenas, the swarms, the boss, the win.
 *  False while the Temple Ship holds the victory back (until the Uber Ethereal is dead). */
static function bool Update()
{
	local XComGameState_LWX2Temple S;
	local XComGameState NewGameState;
	local XComGameState_Unit Uber;
	local int Live, Now, Stage, Swarm1, Swarm2;
	local bool bAlienTurnEnded;

	if (!Active())
		return true;
	S = State();
	if (S == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the Temple Ship");
		S = XComGameState_LWX2Temple(NewGameState.CreateNewStateObject(class'XComGameState_LWX2Temple'));
		S.Stage = 1;
		S.LastTurn = class'LWX2CovertExtraction'.static.TurnNow();
		`TACTICALRULES.SubmitGameState(NewGameState);
		SpawnArena(1);
		`log("LongWarX2: Temple Ship: the first arena stands (" $ LiveAliens() @ "aliens)", , 'LongWarX2');
		return false;
	}
	if (S.Stage >= 7)
		return true;
	// The Uber Ethereal dead: every alien left dies with it, and the battle is won.
	if (S.UberID > 0)
	{
		Uber = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.UberID));
		if (Uber == none || !Uber.IsAlive() || Uber.bRemovedFromPlay)
		{
			Win(S);
			return true;
		}
	}
	Live = LiveAliens();
	Now = class'LWX2CovertExtraction'.static.TurnNow();
	bAlienTurnEnded = Now != S.LastTurn;
	Stage = S.Stage;
	Swarm1 = S.Swarm1;
	Swarm2 = S.Swarm2;
	// (EW's handler counts only when an alien's stats change: OnAlienUnitDamaged. So not before the first one is hurt.)
	if (Stage == 1 && Live <= default.FirstSwarmAt && AnyHurt())
		Stage = 2;
	if (Stage == 2 && Swarm1 == 0 && bAlienTurnEnded)
	{
		SpawnStage(1);
		Swarm1 = 1;
		Live = LiveAliens();
	}
	if (Stage == 2 && Swarm1 != 0 && Live <= default.SecondSwarmAt)
		Stage = 3;
	if (Stage == 3 && Swarm2 == 0 && bAlienTurnEnded)
	{
		SpawnStage(2);
		Swarm2 = 1;
		Live = LiveAliens();
	}
	if (Stage == 3 && Swarm2 != 0 && Live == 0)
	{
		Stage = 4;
		SpawnArena(2);
		Live = LiveAliens();
	}
	if (Stage == 4 && Live == 0)
	{
		Stage = 5;
		SpawnStage(3);
		SpawnStage(4);
	}
	if (Stage == 5 && S.UberID > 0 && class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(S.UberID))
	{
		Stage = 6;
		SpawnStage(5);
	}
	if (Stage != S.Stage || Swarm1 != S.Swarm1 || Swarm2 != S.Swarm2 || bAlienTurnEnded || (Stage >= 5 && S.UberID <= 0))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the Temple Ship's stage");
		S = XComGameState_LWX2Temple(NewGameState.ModifyStateObject(class'XComGameState_LWX2Temple', S.ObjectID));
		if (Stage != S.Stage)
			`log("LongWarX2: Temple Ship: stage" @ S.Stage @ "->" @ Stage @ "(" $ Live @ "aliens left)", , 'LongWarX2');
		S.Stage = Stage;
		S.Swarm1 = Swarm1;
		S.Swarm2 = Swarm2;
		S.LastTurn = Now;
		if (S.UberID <= 0)
			S.UberID = FindUber();
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	return false;
}

/** An alien hurt or dead (stunned or taken counts too). */
static function bool AnyHurt()
{
	local XComGameState_Unit Unit;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && !Unit.GetMyTemplate().bIsCosmetic
			&& (!Unit.IsAlive() || Unit.bRemovedFromPlay || Unit.GetCurrentStat(eStat_HP) < Unit.GetMaxStat(eStat_HP)))
			return true;
	return false;
}

/** The Uber Ethereal on the field (its Long War species), or 0. */
static function int FindUber()
{
	local XComGameState_Unit Unit;
	local UnitValue V;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && Unit.IsAlive() && Unit.GetUnitValue('LWX2Species', V) && int(V.fValue) == default.UberChar)
			return Unit.ObjectID;
	return 0;
}

/** An arena's pods, each of its forced alien, EW's NumAliens_Min to _Max of them, unaware of XCOM (SpawnArenaPods). */
static function SpawnArena(int Arena)
{
	local LWX2TemplePod P;
	local array<name> Names;
	local array<int> Species;
	local int i, n, k;

	foreach default.Pods(P)
	{
		if (P.Arena != Arena)
			continue;
		Names.Length = 0;
		Species.Length = 0;
		n = P.Min + Rand(Max(0, P.Max - P.Min) + 1);
		for (k = 0; k < n; k++)
		{
			Names.AddItem(class'LWMissionSquads'.static.TemplateFor(P.Char));
			Species.AddItem(P.Char);
		}
		if (Names.Length > 0)
			class'LWMissionSquads'.static.SpawnPod(name("LWX2_Temple" $ Arena $ "_" $ i++), P.At, Names, Species);
	}
}

/** A stage's scripted spawns (EW's SeqAct_SpawnAlien), each alone at its point, coming for XCOM. */
static function SpawnStage(int Stage)
{
	local LWX2TempleSpawn T;
	local XComGameState_Unit Unit;
	local array<int> Before, Hunters, Species;
	local array<name> Names;
	local int n;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien)
			Before.AddItem(Unit.ObjectID);
	foreach default.Spawns(T)
	{
		if (T.Stage != Stage)
			continue;
		Names.Length = 0;
		Species.Length = 0;
		Names.AddItem(class'LWMissionSquads'.static.TemplateFor(T.Char));
		Species.AddItem(T.Char);
		class'LWMissionSquads'.static.SpawnPod(name("LWX2_TempleSpawn" $ Stage $ "_" $ n++), T.At, Names, Species);
	}
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_Alien && Before.Find(Unit.ObjectID) == INDEX_NONE)
			Hunters.AddItem(Unit.ObjectID);
	if (Hunters.Length > 0)
		class'LWX2ChryssalidHive'.static.Hunt(Hunters);
	`log("LongWarX2: Temple Ship: stage" @ Stage $ "'s spawns:" @ Hunters.Length @ "aliens", , 'LongWarX2');
}

/** The Uber Ethereal dead: every alien left dies (the handler's WinInitiated), and the battle is won. */
static function Win(XComGameState_LWX2Temple S)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local int n;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the Uber Ethereal is dead");
	XComGameState_LWX2Temple(NewGameState.ModifyStateObject(class'XComGameState_LWX2Temple', S.ObjectID)).Stage = 7;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!Unit.IsAlive() || Unit.bRemovedFromPlay || Unit.GetTeam() != eTeam_Alien)
			continue;
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetCurrentStat(eStat_HP, 0);
		n++;
	}
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("LongWarX2: Temple Ship: the Uber Ethereal is dead;" @ n @ "aliens die with it; the mission is won", , 'LongWarX2');
	if (!`TACTICALRULES.HasTacticalGameEnded())
		class'UIScreenListener_LongWarX2Tactical'.static.TestWin();
}

/** The objective: the port's own words once the Uber Ethereal has come (EW's level shows none of its own). */
static function string ObjectiveText()
{
	local XComGameState_LWX2Temple S;

	if (!Active())
		return "";
	S = State();
	if (S != none && S.Stage >= 5 && S.Stage < 7)
		return "Kill the Uber Ethereal";
	return "";
}
