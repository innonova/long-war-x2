// Long War's alien squads (features/lw-loot.md): which aliens a mission holds, as Long War's
// XGStrategyAI decides them (DetermineUFOSquad and the Determine*Squad of each UFO type,
// DetermineAbductionSquad, DetermineTerrorSquad; ProcessPodTypes, DistributeAliens, BuildPod,
// GetPossibleAliens, GetSupportingAlien; XComGame's XGBattleDesc.GetSupportAlien). A squad here is
// its aliens' species (ECharacter numbers), one entry an alien. Long War's hand-patched code packs
// counts into its pods' "alt weapon" fields; read here as: a pod is its main alien, one more of it
// when its flag (64) is set, and its supports. What the code leaves to state not kept yet: the act
// (1: Outsider commanders), alien bases assaulted (none). No EXALT: none before EXALT is revealed and
// none in the aliens' pods before its HQ is taken (the person), and the campaign has no EXALT yet:
// where Long War's tables bring one, the pod's main alien comes instead.
class LWAlienSquads extends Object;

/** Pod types (EAlienPodType): soldier, commander, secondary, roaming. */
const POD_SOLDIER = 0;
const POD_COMMANDER = 1;
const POD_SECONDARY = 2;
const POD_ROAMING = 3;

struct LWChance
{
	var int Alien;
	var int Chance;
};

struct LWPossible
{
	var array<LWChance> Commanders, Soldiers, Secondaries, Roaming;
};

/** The squad a mission holds. Kind: 1 crash site, 2 landed UFO, 3 abduction, 4 terror; Ufo: the ship (crash, landed). */
static function array<int> SquadFor(int Kind, int Ufo, int Days, int Aggression, int Resources, int AbductionDifficulty, int TerrorsTaken)
{
	switch (Kind)
	{
	case 1: return UfoSquad(Ufo, false, Days, Aggression);
	case 2: return UfoSquad(Ufo, true, Days, Aggression);
	case 3: return AbductionSquad(AbductionDifficulty, Days, Resources);
	case 4: return TerrorSquad(TerrorsTaken, Days);
	}
}

/** Long War's pod-size factor (its GetAltWeapon(1)): 1, 2, 3 by the campaign's day. */
static function int Factor(int Days)
{
	return Days > 240 ? 3 : (Days > 120 ? 2 : 1);
}

/** The aliens' commander (GetCommanderType): an Outsider before act 3. */
static function int Commander()
{
	return 18;
}

/** XGStrategyAI.DetermineUFOSquad: a landed UFO's crew is chosen a month ahead (m_bFirstMission). */
static function array<int> UfoSquad(int Ufo, bool bLanded, int Days, int Aggression)
{
	local array<int> Types, Out;
	local int n, Month;

	Month = Days / 28 + (bLanded ? 1 : 0);
	switch (Ufo)
	{
	case 4: // small scout, fighter
	case 10:
		Types.AddItem(POD_SOLDIER);
		Types.AddItem(POD_SOLDIER);
		if (Factor(Days) <= 2 || Rand(2) == 1)
			Types.AddItem(POD_SOLDIER);
		n = 9 + Rand(3);
		if (!bLanded)
			n -= Rand(5);
		else if (Rand(30) < Aggression)
		{
			Types.AddItem(POD_SOLDIER);
			Types.AddItem(POD_SECONDARY);
			n += 12;
		}
		if (Ufo == 10)
			n -= 2;
		if (Days > 360)
		{
			Types.AddItem(POD_SOLDIER);
			n += 3;
		}
		ProcessPodTypes(n, Types, Days);
		AddPod(Out, POD_COMMANDER, Commander(), 1, Days);
		break;
	case 5: // large scout (destroyer), raider
	case 11:
		Types.AddItem(POD_SOLDIER);
		Types.AddItem(POD_SOLDIER);
		Types.AddItem(POD_SOLDIER); // Factor <= 3: always
		n = 11 + Rand(5);
		if (Days > 360)
		{
			Types.AddItem(POD_SOLDIER);
			n += 4;
		}
		if (bLanded)
		{
			Types.AddItem(POD_SOLDIER);
			n += 5;
			if (Rand(30) < Aggression)
			{
				Types.AddItem(POD_SOLDIER);
				Types.AddItem(POD_SECONDARY);
				n += 16;
			}
		}
		ProcessPodTypes(n, Types, Days);
		AddPod(Out, POD_COMMANDER, Commander(), Ufo == 11 ? 2 : 3, Days);
		break;
	case 6: // abductor, harvester
	case 12:
		Types.AddItem(POD_SECONDARY);
		Types.AddItem(POD_SOLDIER);
		Types.AddItem(POD_SOLDIER);
		Types.AddItem(POD_SOLDIER);
		n = 13 + Rand(8);
		if (bLanded)
		{
			n = 18 + Rand(8);
			Types.AddItem(POD_SOLDIER); // Factor <= 3: always
			if (Rand(30) < Aggression)
			{
				Types.AddItem(POD_SOLDIER);
				Types.AddItem(POD_SECONDARY);
				n += 20;
			}
		}
		if (Days > 360)
		{
			Types.AddItem(POD_SOLDIER);
			n += 5;
		}
		ProcessPodTypes(n, Types, Days);
		AddPod(Out, POD_COMMANDER, Commander(), 4, Days);
		break;
	case 7: // supply ship (transport), terror ship
	case 13:
		Types.AddItem(POD_SECONDARY);
		Types.AddItem(POD_SECONDARY);
		Types.AddItem(POD_SOLDIER);
		Types.AddItem(POD_SOLDIER);
		Types.AddItem(POD_SOLDIER);
		if (Factor(Days) <= 2 || Rand(2) == 1)
			Types.AddItem(POD_SOLDIER);
		Types.AddItem(POD_SECONDARY); // Factor <= 3: always
		n = 30 + Rand(4) + Rand(4) + Rand(4);
		if (Days > 360)
		{
			Types.AddItem(POD_SOLDIER);
			n += 5;
		}
		if (!bLanded)
			n -= Rand(5) + Rand(5);
		else if (Rand(30) < Aggression)
			n = Types.Length * 8;
		n = Min(n, 40);
		ProcessPodTypes(n, Types, Days);
		AddPod(Out, POD_COMMANDER, Commander(), bLanded ? 6 : 3 + Rand(4), Days);
		break;
	case 8: // battleship, assault carrier
	case 14:
		Types.AddItem(POD_SOLDIER);
		Types.AddItem(POD_SECONDARY);
		Types.AddItem(POD_SOLDIER); // Factor <= 3: always
		Types.AddItem(POD_SECONDARY);
		Types.AddItem(POD_SOLDIER);
		Types.AddItem(Ufo == 14 ? POD_SECONDARY : POD_SOLDIER);
		Types.AddItem(Ufo == 14 ? POD_SECONDARY : POD_SOLDIER);
		Types.AddItem(Ufo == 14 ? POD_SECONDARY : POD_SOLDIER);
		if (Factor(Days) <= 2)
			Types.AddItem(POD_SECONDARY);
		n = 26 + Rand(6);
		if (Days > 360)
		{
			Types.AddItem(POD_SOLDIER);
			n += 5;
		}
		if (bLanded)
			n = 38;
		ProcessPodTypes(n, Types, Days);
		// A pod of one kind of alien, by alien bases assaulted (none yet): GetAlienAssetCost(0), 5 of it.
		AddPod(Out, POD_SOLDIER, AssetAlien(0), 95, Days);
		AddPod(Out, POD_COMMANDER, Commander(), 7, Days);
		break;
	case 9: // overseer
		AddPod(Out, POD_COMMANDER, 12, 3, Days);
		AddPod(Out, POD_SECONDARY, 16, 3, Days);
		AddPod(Out, POD_SOLDIER, 11, 5, Days);
		AddPod(Out, POD_SOLDIER, 11, 4, Days);
		return Out;
	}
	DistributeAliens(Out, Types, n, Days, Month);
	return Out;
}

/** XGStrategyAI.DetermineFirstMissionSquad: three pods of Sectoids. */
static function array<int> FirstMissionSquad()
{
	local array<int> Out;

	AddPod(Out, POD_SOLDIER, 4, 4, 1);
	AddPod(Out, POD_SOLDIER, 4, 3, 1);
	AddPod(Out, POD_SOLDIER, 4, 3, 1);
	return Out;
}

/** XGStrategyAI.DetermineAbductionSquad, by the mission's difficulty (0-3). */
static function array<int> AbductionSquad(int Diff, int Days, int Resources)
{
	local array<int> Types, Out;
	local int n, Pods, i;

	n = Diff * 3 + 7 + Rand(3);
	Pods = Clamp(Diff + 3 - Rand(Factor(Days)), Diff / 2 + 2, 4);
	if (Days <= 180)
	{
		n = Diff * 2 + 8 + Rand(3);
		if (Diff == 0)
		{
			Pods = 3;
			n--;
		}
	}
	if (Resources >= 180)
		n += Rand(4);
	for (i = 0; i < Pods; i++)
		Types.AddItem(POD_SOLDIER);
	DistributeAliens(Out, Types, n, Days, Days / 28);
	return Out;
}

/** XGStrategyAI.DetermineTerrorSquad, by the terror missions taken before. */
static function array<int> TerrorSquad(int Taken, int Days)
{
	local array<int> Types, Out;
	local int n, Month;

	Month = Days / 28;
	if (Taken == 0)
	{
		AddPod(Out, POD_SECONDARY, 13, 4, Days);
		AddPod(Out, POD_SECONDARY, 5, 4, Days);
		AddPod(Out, POD_SECONDARY, 5, 4, Days);
		return Out;
	}
	if (Taken == 2)
	{
		AddPod(Out, POD_SECONDARY, 13, 3, Days);
		AddPod(Out, POD_SECONDARY, 13, 3, Days);
		AddPod(Out, POD_SECONDARY, 14, 5, Days);
		AddPod(Out, POD_SECONDARY, 14, 5, Days);
		AddPod(Out, POD_SECONDARY, 14, 5, Days);
		AddPod(Out, POD_SECONDARY, 14, 3, Days);
		return Out;
	}
	Types.AddItem(POD_SECONDARY);
	Types.AddItem(POD_SECONDARY);
	Types.AddItem(POD_SECONDARY);
	Types.AddItem(POD_SECONDARY);
	if (Taken == 9)
	{
		AddPod(Out, POD_SECONDARY, 13, 95, Days);
		n = 10;
	}
	else if (Taken == 18)
	{
		AddPod(Out, POD_SECONDARY, 17, 98, Days);
		n = 7;
	}
	else
	{
		Types.AddItem(POD_SECONDARY);
		n = 15;
	}
	if (Month >= 6)
		n += 3;
	if (Month >= 9)
		n += 3;
	if (Month >= 12)
		n += 3;
	if (Month >= 15)
		n += 6;
	DistributeAliens(Out, Types, n, Days, Month);
	return Out;
}

/** XGStrategyAI.GetAlienAssetCost, which Long War made a choice of alien: by its argument plus 0-9. */
static function int AssetAlien(int k)
{
	switch (k + Rand(10))
	{
	case 0: return 17;
	case 1: return 4;
	case 2: return 6;
	case 3: return 5;
	case 4: return 13;
	case 5: return 7;
	case 6: return 23;
	case 7: return 18;
	case 8: return 8;
	case 9: return 15;
	case 10: return 10;
	case 11: return 9;
	case 12: return 21;
	case 13: return 11;
	case 14: return 16;
	}
	return 12;
}

/** XGStrategyAI.ProcessPodTypes: the aliens kept within the pods' room, and the pods to what the aliens fill. */
static function ProcessPodTypes(out int n, out array<int> Types, int Days)
{
	local int f, MinPods, MaxPods, Pods;

	f = Factor(Days);
	if (n >= Types.Length * (f * 2))
	{
		n = Types.Length * (f * 2);
		return;
	}
	MinPods = n / (f * 2);
	if ((n % f) * 2 != 0) // as Long War wrote it
		MinPods += 1;
	MaxPods = n / f;
	Pods = MinPods + Rand(MaxPods - MinPods + 1);
	while (Types.Length > Pods)
		Types.Remove(Rand(Types.Length), 1);
}

/** XGStrategyAI.DistributeAliens: the aliens shared out over the pods, each pod's main alien chosen by its type. */
static function DistributeAliens(out array<int> Out, array<int> Types, int n, int Days, int Month)
{
	local LWPossible Possible;
	local int Pods, i, InPod;

	Possible = PossibleAliens(Month);
	Pods = Types.Length;
	for (i = 0; i < Types.Length && Pods > 0; i++)
	{
		InPod = n / Pods;
		if (n % Pods != 0)
			InPod += 1;
		AddPod(Out, Types[i], ChooseAlien(Types[i], Possible), InPod, Days);
		n -= InPod;
		Pods--;
	}
}

/**
 * XGStrategyAI.BuildPod: the main alien, then for each further alien: the first a support, the
 * second at 30 % a second kind of support (else one more of the first), then at 10 % (once) one more
 * of the main alien (its flag, 64), else at 30 % the second support (at most two), else one more of
 * the first. Over 8: the tens are a weapon choice, the units the aliens (95: 5 aliens).
 */
static function AddPod(out array<int> Out, int Type, int Main, int n, int Days)
{
	local int i, Support1, Support2, Count1, Count2;
	local bool bFlag;

	if (n > 8)
		n = n % 10;
	if (n <= 0)
		return;
	for (i = 1; i < n; i++)
	{
		if (i == 1)
		{
			Support1 = SupportingAlien(Main, false, Days);
			Count1 = 1;
		}
		else if (i == 2)
		{
			if (Rand(100) < 30)
			{
				Support2 = SupportingAlien(Main, true, Days);
				Count2 = 1;
			}
			else
				Count1++;
		}
		else if (!bFlag && Rand(100) < 10)
			bFlag = true;
		else if (Count2 < 2 && Rand(100) < 30)
		{
			if (Support2 == 0)
				Support2 = SupportingAlien(Main, true, Days);
			Count2++;
		}
		else
			Count1++;
	}
	Out.AddItem(Main);
	if (bFlag)
		Out.AddItem(Main);
	for (i = 0; i < Count1; i++)
		Out.AddItem(Support1);
	for (i = 0; i < Count2; i++)
		Out.AddItem(Support2);
}

/** XGStrategyAI.GetSupportingAlien: some main aliens' supports change with the months (their +32 sets), then XGBattleDesc.GetSupportAlien. */
static function int SupportingAlien(int Main, bool bAlt, int Days)
{
	local int Month, Support;

	Month = Days / 28;
	if ((Main == 4 && Month >= 11) || (Main == 5 && Month >= 12) || (Main == 7 && Month >= 8) || (Main == 10 && Month >= 13)
		|| (Main == 11 && Month >= 14) || (Main == 28 && Month >= 6))
		Support = SupportAlien(Main + 32, bAlt);
	else
		Support = SupportAlien(Main, bAlt);
	return (Support >= 24 && Support <= 31) ? (Main > 31 ? Main - 32 : Main) : Support;
}

/** XComGame's XGBattleDesc.GetSupportAlien (as Long War's package has it). */
static function int SupportAlien(int A, bool bAlt)
{
	if (!bAlt)
	{
		switch (A)
		{
		case 4: return 4;
		case 5: return 5;
		case 6: return Rand(3) <= 0 ? 23 : 6;
		case 7: return Rand(3) <= 0 ? 7 : 5;
		case 8: return 17;
		case 9: return Rand(2) * 14 + 4;
		case 10: return Rand(3) <= 0 ? 10 : 5;
		case 11: return Rand(3) <= 1 ? 7 : Rand(2) * 4 + 11;
		case 12: return Rand(3) <= 0 ? 10 : 11;
		case 13: return 13;
		case 14: return 14;
		case 15: return Rand(3) <= 0 ? 5 : 7;
		case 16: return 17;
		case 17: return 17;
		case 18: return 18;
		case 19: return 11;
		case 21: return 4;
		case 22: return Rand(2) * 3 + 4;
		case 23: return 23;
		case 24: case 25: case 26: case 27: return 24;
		case 28: return Rand(3) <= 0 ? 24 : 28;
		case 29: case 30: case 31: return 28;
		case 36: return Rand(2) <= 0 ? 28 : 4;
		case 37: return Rand(3) <= 0 ? 10 : 5;
		case 39: return Rand(3) <= 0 ? 5 : 7;
		case 42: return Rand(3) <= 0 ? 5 : 10;
		case 43: return Rand(4) <= 1 ? 11 : Rand(2) * 8 + 7;
		case 60: return 28;
		}
	}
	else
	{
		switch (A)
		{
		case 4: return Rand(2) <= 0 ? 17 : 4;
		case 5: return 5;
		case 6: return Rand(2) <= 0 ? 4 : 6;
		case 7: return Rand(2) <= 0 ? 5 : 4;
		case 8: return 23;
		case 9: return Rand(2) <= 0 ? 18 : 21;
		case 10: return Rand(2) <= 0 ? 5 : 13;
		case 11: return Rand(5) <= 1 ? 11 : Rand(2) * 11 + 10;
		case 12: return Rand(2) <= 0 ? 21 : 11;
		case 13: return Rand(3) <= 0 ? 14 : 13;
		case 14: return 14;
		case 15: return Rand(2) <= 0 ? 5 : 15;
		case 16: return 23;
		case 17: return 17;
		case 18: return Rand(3) <= 0 ? 6 : 18;
		case 19: return 11;
		case 21: return 17;
		case 22: return Rand(2) <= 0 ? 17 : 9;
		case 23: return Rand(2) <= 0 ? 23 : 17;
		case 24: return Rand(2) <= 0 ? 25 : 26;
		case 25: return Rand(2) <= 0 ? 27 : 26;
		case 26: return Rand(2) <= 0 ? 25 : 27;
		case 27: return Rand(2) <= 0 ? 25 : 26;
		case 28: case 60: return Rand(2) <= 0 ? 29 : 30;
		case 29: return Rand(2) <= 0 ? 30 : 31;
		case 30: return Rand(2) <= 0 ? 29 : 31;
		case 31: return Rand(2) <= 0 ? 29 : 30;
		case 36: return Rand(2) <= 0 ? 28 : 21;
		case 37: return Rand(3) <= 0 ? 10 : 5;
		case 39: return Rand(3) <= 0 ? 23 : 7;
		case 42: return Rand(2) <= 0 ? 13 : 10;
		case 43: return Rand(5) <= 1 ? 11 : Rand(2) * 11 + 10;
		}
	}
	return A <= 31 ? A : A - 32;
}

/** XGStrategyAI.GetPossibleAliens: the species a pod's main alien is chosen from, by its type, by the month. */
static function LWPossible PossibleAliens(int Month)
{
	local LWPossible P;

	AddPossible(P.Commanders, Commander(), 100);
	AddPossible(P.Roaming, 7, 1);
	AddPossible(P.Soldiers, 4, Month <= 2 ? 80 : 50);
	AddPossible(P.Soldiers, 17, Month <= 6 ? 25 : 20);
	AddPossible(P.Secondaries, 13, 125);
	if (Month >= 1)
	{
		AddPossible(P.Soldiers, 5, Month <= 5 ? 100 : 35);
		AddPossible(P.Secondaries, 5, Month <= 6 ? 50 : 25);
		AddPossible(P.Soldiers, 6, 85);
		AddPossible(P.Secondaries, 6, 25);
	}
	if (Month >= 2)
	{
		AddPossible(P.Soldiers, 23, Month <= 8 ? 65 : 50);
		AddPossible(P.Secondaries, 23, Month <= 8 ? 65 : 35);
	}
	if (Month == 2)
		AddPossible(P.Soldiers, 7, 35);
	if (Month >= 3)
	{
		AddPossible(P.Soldiers, 7, (Month >= 4 && Month <= 8) ? 100 : 80);
		AddPossible(P.Secondaries, 7, 25);
	}
	if (Month == 3)
		AddPossible(P.Secondaries, 8, 15);
	if (Month >= 4)
	{
		AddPossible(P.Soldiers, 8, Month <= 7 ? 40 : 65);
		AddPossible(P.Secondaries, 8, 90);
	}
	if (Month == 5)
		AddPossible(P.Secondaries, 15, 15);
	if (Month >= 5)
	{
		AddPossible(P.Soldiers, 21, Month <= 7 ? 35 : 80);
		AddPossible(P.Secondaries, 21, Month <= 7 ? 35 : 50);
	}
	if (Month >= 6)
	{
		AddPossible(P.Soldiers, 15, Month <= 8 ? 100 : 50);
		AddPossible(P.Secondaries, 15, 50);
	}
	if (Month >= 7)
	{
		AddPossible(P.Soldiers, 9, Month <= 9 ? 30 : 65);
		AddPossible(P.Secondaries, 9, 25);
		AddPossible(P.Soldiers, 22, Month <= 12 ? 35 : 50);
		AddPossible(P.Secondaries, 22, Month <= 12 ? 15 : 35);
	}
	if (Month >= 8)
	{
		AddPossible(P.Soldiers, 10, Month <= 9 ? 100 : 75);
		AddPossible(P.Secondaries, 10, 50);
		// Long War adds EXALT's eight here (5 and 10): none until EXALT's HQ is taken, and no EXALT yet.
	}
	if (Month >= 9)
	{
		AddPossible(P.Soldiers, 11, Month <= 11 ? 50 : 85);
		AddPossible(P.Secondaries, 11, 25);
	}
	if (Month >= 10)
		AddPossible(P.Secondaries, 16, Month <= 11 ? 35 : 55);
	if (Month >= 11)
		AddPossible(P.Secondaries, 12, 25);
	if (Month >= 12)
		AddPossible(P.Soldiers, 12, 25);
	if (Month >= 13)
		AddPossible(P.Soldiers, 16, 25);
	NormalizeChances(P.Commanders);
	NormalizeChances(P.Soldiers);
	NormalizeChances(P.Secondaries);
	NormalizeChances(P.Roaming);
	return P;
}

static function AddPossible(out array<LWChance> A, int Alien, int Chance)
{
	local LWChance C;

	C.Alien = Alien;
	C.Chance = Chance;
	A.AddItem(C);
}

/** XGStrategyAI.NormalizeValues: the chances made cumulative out of 100. */
static function NormalizeChances(out array<LWChance> A)
{
	local float Factor, Total, Chance;
	local int i, Sum;

	for (i = 0; i < A.Length; i++)
		Sum += A[i].Chance;
	if (Sum <= 0)
		return;
	Total = 0;
	Factor = 100.0 / Sum;
	for (i = 0; i < A.Length; i++)
	{
		Chance = A[i].Chance * Factor;
		A[i].Chance = int(Total + Chance);
		Total += Chance;
	}
}

/** XGStrategyAI.ChooseAlien. */
static function int ChooseAlien(int Type, LWPossible P)
{
	local array<LWChance> A;
	local int Roll, i;

	switch (Type)
	{
	case POD_COMMANDER: A = P.Commanders; break;
	case POD_SECONDARY: A = P.Secondaries; break;
	case POD_ROAMING: A = P.Roaming; break;
	default: A = P.Soldiers;
	}
	Roll = Rand(100);
	for (i = 0; i < A.Length; i++)
		if (Roll < A[i].Chance)
			return A[i].Alien;
	return A[A.Length - 1].Alien;
}
