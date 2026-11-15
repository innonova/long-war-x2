// Long War's rookie stats (XGFacility_Barracks.RandomizeStats, features/lw-classes.md): no two recruits alike. A recruit
// starts at each stat's minimum and spends a pool of points worth the midpoints (the soldier's Characters= line); each
// draw picks a stat weighted by its range and buys one point of it (HP, mobility) or a few (aim, defence, will), never past
// twice its range. Per Ardua Ad Astra adds to the pool. Long War rolls this unless its second-wave option is on; the port
// always does. Generated from Long War's DefaultGameCore.ini by scripts/strategy-config.mjs.
class LWRookieStats extends Object config(LWStrategy);

struct LWStatRoll
{
	/** The midpoint (the soldier's Characters= value), the minimum, and the points one more costs. */
	var int Mid;
	var int Min;
	var int Cost;
};

var config LWStatRoll HP, Aim, Defense, Mobility, Will;

/** The soldier's stats rolled as Long War rolls a recruit's, and set as the difference from XCOM 2's soldier template (so a
 * soldier who has ranked up keeps the ranks' gains). */
static function Roll(XComGameState_Unit Unit)
{
	local array<LWStatRoll> S;
	local array<int> Gain, Range, Weight;
	local int Pool, Total, Pick, Sum, Chunk, Iter, i;

	S.AddItem(default.HP);
	S.AddItem(default.Aim);
	S.AddItem(default.Defense);
	S.AddItem(default.Mobility);
	S.AddItem(default.Will);
	if (S[0].Mid == 0)
		return;
	for (i = 0; i < S.Length; i++)
	{
		Range.AddItem(S[i].Mid - S[i].Min);
		Gain.AddItem(0);
		Pool += Range[i] * S[i].Cost;
		Weight.AddItem(1260 * Range[i] / (1 + Max(1, (Range[i] - 1) / 3)));
		Total += Weight[i];
	}
	Pool += class'LWBonuses'.static.Has(class'LWBonuses'.const.PER_ARDUA);
	while (Pool > 0 && Iter < 512 && Total > 0)
	{
		Pick = Rand(Total);
		Sum = 0;
		for (i = 0; i < S.Length; i++)
		{
			Sum += Weight[i];
			if (Sum > Pick)
				break;
		}
		if (i < S.Length && Gain[i] < 2 * Range[i] && Pool - S[i].Cost >= 0)
		{
			// HP and mobility a point at a time; aim, defence and will a few.
			if (i == 0 || i == 3)
				Chunk = 1;
			else
				Chunk = Min(Min(1 + Rand((Range[i] - 1) / 3), 2 * Range[i] - Gain[i]), Pool / Max(1, S[i].Cost));
			Pool -= Chunk * S[i].Cost;
			Gain[i] += Chunk;
		}
		Iter++;
	}
	SetStat(Unit, eStat_HP, S[0].Min + Gain[0]);
	SetStat(Unit, eStat_Offense, S[1].Min + Gain[1]);
	SetStat(Unit, eStat_Defense, S[2].Min + Gain[2]);
	SetStat(Unit, eStat_Mobility, S[3].Min + Gain[3]);
	SetStat(Unit, eStat_Will, S[4].Min + Gain[4]);
	`log("LongWarX2: rookie stats:" @ Unit.GetFullName() @ "HP" @ S[0].Min + Gain[0] @ "aim" @ S[1].Min + Gain[1] @ "defence" @ S[2].Min + Gain[2]
		@ "mobility" @ S[3].Min + Gain[3] @ "will" @ S[4].Min + Gain[4] $ " (" $ Pool @ "points left)", , 'LongWarX2');
}

/** A stat moved to Long War's value, as the difference from the soldier's template (its ranks' gains kept). */
static function SetStat(XComGameState_Unit Unit, ECharStatType Stat, int Value)
{
	local int Delta;
	local float Gap;

	Delta = Value - int(Unit.GetMyTemplate().CharacterBaseStats[Stat]);
	if (Delta == 0)
		return;
	// The current value kept as far below the maximum as it was (a wound, will spent): SetBaseMaxStat sets the current
	// HP to the new maximum itself, and leaves will as it was, so adding the change to the current value as well left
	// fresh recruits with half their HP ("Wounded" at the campaign's start).
	Gap = Unit.GetMaxStat(Stat) - Unit.GetCurrentStat(Stat);
	Unit.SetBaseMaxStat(Stat, Unit.GetBaseStat(Stat) + Delta);
	Unit.SetCurrentStat(Stat, FMax(Stat == eStat_HP ? 1.0 : 0.0, Unit.GetMaxStat(Stat) - Gap));
}
