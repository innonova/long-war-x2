// Enemy Within's wave system (XComWaveSystem) for a level whose Kismet runs (LWX2Kismet; the level's XComWaveSystem read by
// tools/convert/ew-kismet.ts into XComLWX2Kismet.ini). Its alien sets each begin at the start (no event) or when the Kismet
// fires their remote event, and end when it fires their disable event; each wave of a begun set comes on its turn after the
// set began (TurnAppearance), at the beginning or the end of the aliens' turn; each group of a wave is that many aliens of its
// type (a scalable one: one of the species the mission's squad holds, by how it arrives) at its spawn points, coming for XCOM
// (Hunter). A group's events go back to the Kismet: one as it is called, one once it has spawned. The battle cannot be won
// while a set is not done (XGBattle_SP.IsVictory: IsAlienWaveSystemActive).
class LWX2WaveSystem extends Object config(LWX2Kismet);

struct LWX2WaveGroup
{
	var int L;
	var int Set;
	var string Start;
	var string Stop;
	/** -1: a set without waves. */
	var int Wave;
	var int Turn;
	/** 0 at the beginning of the aliens' turn, 1 at its end. */
	var int When;
	/** Long War's character (ECharacter); for a scalable group, what the level has, replaced. */
	var int Char;
	var bool Scalable;
	/** 0 dropped in, 1 walking in, 2 flying in. */
	var int Method;
	var int N;
	var bool Hunter;
	var string OnActivated;
	var string OnSpawned;
	var array<vector> At;
};

var config array<LWX2WaveGroup> Groups;
/** Long War's species that fly (EW's scalable fly-in list: those with the fly ability). */
var config array<int> Flyers;

/** The sets of the level (each set number once). */
static function array<int> SetsOf(int Level)
{
	local array<int> Sets;
	local LWX2WaveGroup G;

	foreach default.Groups(G)
		if (G.L == Level && Sets.Find(G.Set) == INDEX_NONE)
			Sets.AddItem(G.Set);
	return Sets;
}

/** The waves of a set (each wave number once; none for a set without waves). */
static function array<int> WavesOf(int Level, int Set)
{
	local array<int> Waves;
	local LWX2WaveGroup G;

	foreach default.Groups(G)
		if (G.L == Level && G.Set == Set && G.Wave >= 0 && Waves.Find(G.Wave) == INDEX_NONE)
			Waves.AddItem(G.Wave);
	return Waves;
}

static function bool GroupOf(int Level, int Set, out LWX2WaveGroup Found)
{
	local LWX2WaveGroup G;

	foreach default.Groups(G)
		if (G.L == Level && G.Set == Set)
		{
			Found = G;
			return true;
		}
	return false;
}

/** The aliens' turn begins (When 0) or ends (When 1): the sets' states brought up to date, then the waves due spawned. */
static function Update(int When)
{
	local XComGameState_LWX2Kismet K;
	local XComGameState NewGameState;
	local array<int> Sets, Waves, DueSet, DueWave;
	local LWX2WaveGroup G;
	local int Set, Wave, Now, i, Spawned;
	local bool bAllSpawned;

	K = class'LWX2Kismet'.static.Current();
	if (K == none)
		return;
	Now = class'LWX2CovertExtraction'.static.TurnNow();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the wave system's turn");
	K = XComGameState_LWX2Kismet(NewGameState.ModifyStateObject(class'XComGameState_LWX2Kismet', K.ObjectID));
	Sets = SetsOf(K.Level);
	foreach Sets(Set)
	{
		while (K.SetState.Length <= Set)
		{
			K.SetState.AddItem(0);
			K.SetTurn.AddItem(0);
		}
		if (K.SetState[Set] == 2 || !GroupOf(K.Level, Set, G))
			continue;
		Waves = WavesOf(K.Level, Set);
		// Done: disabled by the Kismet, or without waves (UpdateActiveFlags).
		if ((G.Stop != "" && K.Fired.Find(G.Stop) != INDEX_NONE) || Waves.Length == 0)
		{
			K.SetState[Set] = 2;
			continue;
		}
		if (K.SetState[Set] == 0)
		{
			if (G.Start == "")
			{
				K.SetState[Set] = 1;
				K.SetTurn[Set] = 0;
			}
			else if (K.Fired.Find(G.Start) != INDEX_NONE)
			{
				K.SetState[Set] = 1;
				K.SetTurn[Set] = Now;
			}
		}
		if (K.SetState[Set] != 1)
			continue;
		// The waves due (UpdateWaveSpawning): on their turn after the set began, at this point of the aliens' turn.
		bAllSpawned = true;
		foreach Waves(Wave)
		{
			if (K.WavesSpawned.Find(Set * 100 + Wave) != INDEX_NONE)
				continue;
			bAllSpawned = false;
			for (i = 0; i < default.Groups.Length; i++)
				if (default.Groups[i].L == K.Level && default.Groups[i].Set == Set && default.Groups[i].Wave == Wave)
					break;
			if (i >= default.Groups.Length)
				continue;
			G = default.Groups[i];
			if (G.Turn < 0 || G.When != When || K.SetTurn[Set] + G.Turn > Now)
				continue;
			K.WavesSpawned.AddItem(Set * 100 + Wave);
			DueSet.AddItem(Set);
			DueWave.AddItem(Wave);
		}
		if (bAllSpawned)
			K.SetState[Set] = 2;
	}
	`TACTICALRULES.SubmitGameState(NewGameState);
	for (i = 0; i < DueSet.Length; i++)
		Spawned += SpawnWave(K.Level, DueSet[i], DueWave[i], K.Species);
	if (DueSet.Length > 0)
		`log("LongWarX2: wave system: turn" @ Now @ (When == 0 ? "(the aliens' turn begins):" : "(the aliens' turn ends):") @ DueSet.Length @ "waves," @ Spawned @ "aliens", , 'LongWarX2');
}

/** A wave's groups spawned (SpawnWave, SpawnGroup); the aliens that came. */
static function int SpawnWave(int Level, int Set, int Wave, array<int> Species)
{
	local LWX2WaveGroup G;
	local array<vector> Points;
	local array<name> Names;
	local array<int> Kinds, Before, Hunters;
	local XComGameState_Unit Unit;
	local int i, k, n, Char, Came;

	foreach default.Groups(G)
	{
		if (G.L != Level || G.Set != Set || G.Wave != Wave)
			continue;
		Points = G.At;
		n = Min(G.N, Points.Length);
		Char = G.Scalable ? Scaled(G.Method, Species) : G.Char;
		if (Char <= 0)
			Char = G.Char;
		if (n <= 0 || Char <= 0)
			continue;
		if (G.OnActivated != "")
			class'LWX2Kismet'.static.Fire('SeqEvent_RemoteEvent', G.OnActivated);
		Before.Length = 0;
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
			if (Unit.GetTeam() == eTeam_Alien)
				Before.AddItem(Unit.ObjectID);
		for (i = 0; i < n; i++)
		{
			// Each at a point of its own, chosen at random (and a scalable one of its own species).
			k = Rand(Points.Length);
			Names.Length = 0;
			Kinds.Length = 0;
			Names.AddItem(class'LWMissionSquads'.static.TemplateFor(Char));
			Kinds.AddItem(Char);
			class'LWMissionSquads'.static.SpawnPod(name("LWX2_Wave" $ Set $ "_" $ Wave $ "_" $ i), Points[k], Names, Kinds);
			Points.Remove(k, 1);
			if (G.Scalable)
				Char = Scaled(G.Method, Species) > 0 ? Scaled(G.Method, Species) : Char;
		}
		Hunters.Length = 0;
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
			if (Unit.GetTeam() == eTeam_Alien && Before.Find(Unit.ObjectID) == INDEX_NONE)
				Hunters.AddItem(Unit.ObjectID);
		Came += Hunters.Length;
		if (G.Hunter && Hunters.Length > 0)
			class'LWX2ChryssalidHive'.static.Hunt(Hunters);
		if (G.OnSpawned != "")
			class'LWX2Kismet'.static.Fire('SeqEvent_RemoteEvent', G.OnSpawned);
	}
	return Came;
}

/** A scalable group's alien (SetScalingAliens): one of the squad's species that arrives this way (flying in: one that flies;
 *  dropped in: one that does not); 0 when the squad has none. */
static function int Scaled(int Method, array<int> Species)
{
	local array<int> Fit;
	local int c;

	foreach Species(c)
	{
		if (Method == 2 && default.Flyers.Find(c) == INDEX_NONE)
			continue;
		if (Method == 0 && default.Flyers.Find(c) != INDEX_NONE)
			continue;
		if (Fit.Find(c) == INDEX_NONE)
			Fit.AddItem(c);
	}
	return Fit.Length > 0 ? Fit[Rand(Fit.Length)] : 0;
}

/** A set not yet done: the battle cannot be won. */
static function bool Active()
{
	local XComGameState_LWX2Kismet K;
	local array<int> Sets;
	local int Set;

	K = class'LWX2Kismet'.static.Current();
	if (K == none)
		return false;
	Sets = SetsOf(K.Level);
	foreach Sets(Set)
		if (Set >= K.SetState.Length || K.SetState[Set] != 2)
			return true;
	return false;
}
