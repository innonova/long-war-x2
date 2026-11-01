// Long War's stat bonuses for a perk choice (features/lw-classes.md): in Long War, choosing a perk
// at a rank can also give mobility, aim or will, by class and by which of the rank's perks was
// chosen (its "perk tree-dependent bonus stat increases"). Generated (scripts/classes-config.mjs).
class LWX2PerkBonuses extends Object config(LWClasses);

struct LWPerkBonus
{
	var name ClassName;
	var int Rank;
	var int Branch;
	var int Mobility, Aim, Will;
};

var config array<LWPerkBonus> Bonuses;

static function bool Find(name ClassName, int Rank, int Branch, out LWPerkBonus Bonus)
{
	local LWPerkBonus B;

	foreach default.Bonuses(B)
	{
		if (B.ClassName == ClassName && B.Rank == Rank && B.Branch == Branch)
		{
			Bonus = B;
			return true;
		}
	}
	return false;
}

/** "+1 Mobility, +2 Aim" and the like. */
static function string Describe(LWPerkBonus B)
{
	local array<string> Parts;
	local string S;
	local int i;

	if (B.Mobility != 0)
		Parts.AddItem((B.Mobility > 0 ? "+" : "") $ B.Mobility @ class'XLocalizedData'.default.MobilityLabel);
	if (B.Aim != 0)
		Parts.AddItem((B.Aim > 0 ? "+" : "") $ B.Aim @ class'XLocalizedData'.default.AimLabel);
	if (B.Will != 0)
		Parts.AddItem((B.Will > 0 ? "+" : "") $ B.Will @ class'XLocalizedData'.default.WillLabel);
	for (i = 0; i < Parts.Length; i++)
		S $= (i > 0 ? ", " : "") $ Parts[i];
	return S;
}

/** The bonus applied to the unit (in the given change): its base stats raised. */
static function Apply(XComGameState_Unit Unit, LWPerkBonus B)
{
	if (B.Mobility != 0)
		Unit.SetBaseMaxStat(eStat_Mobility, Unit.GetBaseStat(eStat_Mobility) + B.Mobility);
	if (B.Aim != 0)
		Unit.SetBaseMaxStat(eStat_Offense, Unit.GetBaseStat(eStat_Offense) + B.Aim);
	if (B.Will != 0)
		Unit.SetBaseMaxStat(eStat_Will, Unit.GetBaseStat(eStat_Will) + B.Will); // raises the current Will with it
}
