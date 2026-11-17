// Long War's gains on promotion (features/lw-second-wave.md; XGStrategySoldier.LevelUpStats). XCOM 2's class data gives each
// rank Long War's fixed gains (scripts/classes-config.mjs: the last digits of its SoldierStatProgression); as XCOM 2 ranks a
// soldier up (its UnitRankUp event: X2EventListener_LWStrategy, a game state after), this makes them Long War's:
// - normally, will also gets Rand(iRandWillIncrease) more every level;
// - with Hidden Potential (second wave #3), each gain is rolled instead: HP +1 with a chance of its xx (of xxyy), aim and
//   will xx + Rand(yy) (of xxyyzz), and no random will on top.
// The perk-choice bonuses (LWX2PerkBonuses) are apart from these, as in Long War. Also here: Training Roulette's tree, dealt
// as the soldier gets the class (LWX2TrainingRoulette).
class LWX2StatGains extends Object config(LWClasses);

struct LWStatGain
{
	var name ClassName;
	var int Rank;
	var int HP, Aim, Will;
	var int TreeMobility, TreeAim, TreeWill; // (at squaddie: the tree's squaddie bonus, which XCOM 2's class data adds too)
};

var config int RandWill;
var config array<LWStatGain> Gains;

/** The unit ranked up from rank From (in a game state of its own): each rank's gain since then made Long War's, once (the
 *  unit's LWX2GainsRank: the last rank done). False when there was nothing to do. */
static function bool RankedUp(XComGameState_Unit Unit, int From)
{
	local UnitValue Done;
	local int Rank;
	local bool bChanged;

	if (Unit == none || !Unit.IsSoldier())
		return false;
	if (Unit.GetUnitValue('LWX2GainsRank', Done))
		From = Max(From, int(Done.fValue));
	// Given the class now: Training Roulette's tree.
	if (From == 0 && Unit.GetRank() > 0 && class'LWX2TrainingRoulette'.static.Deal(Unit))
		bChanged = true;
	for (Rank = From + 1; Rank <= Unit.GetRank(); Rank++)
		if (Gain(Unit, Rank))
			bChanged = true;
	if (From < Unit.GetRank())
	{
		Unit.SetUnitFloatValue('LWX2GainsRank', Unit.GetRank(), eCleanup_Never);
		bChanged = true;
	}
	return bChanged;
}

/** One rank's gains made Long War's. */
static function bool Gain(XComGameState_Unit Unit, int Rank)
{
	local int i;
	local LWStatGain G;

	for (i = 0; i < default.Gains.Length; i++)
		if (default.Gains[i].ClassName == Unit.GetSoldierClassTemplateName() && default.Gains[i].Rank == Rank)
			break;
	if (i == default.Gains.Length)
		return false;
	G = default.Gains[i];
	if (class'LWX2SecondWave'.static.On(3))
	{
		Add(Unit, eStat_HP, ((`SYNC_RAND_STATIC(100) < G.HP / 100) ? 1 : 0) - G.HP % 100);
		Add(Unit, eStat_Offense, Rolled(G.Aim) - G.Aim % 100);
		Add(Unit, eStat_Will, Rolled(G.Will) - G.Will % 100);
	}
	else if (default.RandWill > 0)
		Add(Unit, eStat_Will, `SYNC_RAND_STATIC(default.RandWill));
	// No perk-tree bonuses with Training Roulette (LevelUpStats), the squaddie's included.
	if (class'LWX2SecondWave'.static.On(4))
	{
		Add(Unit, eStat_Mobility, -G.TreeMobility);
		Add(Unit, eStat_Offense, -G.TreeAim);
		Add(Unit, eStat_Will, -G.TreeWill);
	}
	return true;
}

/** Hidden Potential's gain of an xxyyzz number: xx + Rand(yy). */
static function int Rolled(int Packed)
{
	local int Spread;

	Spread = Packed / 100 % 100;
	return Packed / 10000 % 10000 + (Spread > 0 ? `SYNC_RAND_STATIC(Spread) : 0);
}

/** As RankUpSoldier adds a gain: to the base and the current value (not current HP while hurt). */
static function Add(XComGameState_Unit Unit, ECharStatType Stat, int Delta)
{
	if (Delta == 0)
		return;
	Unit.SetBaseMaxStat(Stat, Unit.GetBaseStat(Stat) + Delta);
	if (Stat != eStat_HP || !Unit.IsInjured())
		Unit.SetCurrentStat(Stat, Unit.GetCurrentStat(Stat) + Delta);
}
