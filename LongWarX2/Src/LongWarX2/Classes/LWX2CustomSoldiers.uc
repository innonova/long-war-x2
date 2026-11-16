// Long War's named soldiers that its council missions reward (features/lw-council-missions.md, step 4: Progeny's), as
// XGFundingCouncil.BuildMission makes them and GiveCustomSoldier gives them: read from the player's own Long War by
// tools/convert/ew-objectives.ts (readCustomSoldiers) into XComLWX2EWObjectives.ini, since their names are Long War's.
class LWX2CustomSoldiers extends Object config(LWX2EWObjectives);

struct LWX2CustomSoldier
{
	/** The council mission (EFCMission) whose reward it is. */
	var int Mission;
	var string First, Last, Nick;
	var name Country;
	var bool Female;
	/** EW's base class (1 sniper, 2 heavy weapons, 3 support, 4 assault) and rank. */
	var int BaseClass;
	var int Rank;
	var int HP, Aim, Will;
	/** GiveCustomSoldier's own additions: a mobility (0: as rolled), psi powers (each Alt, when not 0, given instead half the
	 *  time), the psi rank. */
	var int Mobility;
	var array<int> Perks;
	var array<int> Alt;
	var int PsiRank;
};

var config array<LWX2CustomSoldier> Soldiers;

/** The mission's n-th named soldier, if this install has it. */
static function bool Find(int Mission, int Index, out LWX2CustomSoldier Out)
{
	local LWX2CustomSoldier C;
	local int n;

	foreach default.Soldiers(C)
		if (C.Mission == Mission && n++ == Index)
		{
			Out = C;
			return true;
		}
	return false;
}

/** The soldier joins XCOM (GiveCustomSoldier): made with its class and rank in its country, named, with its own HP, aim and
 *  will, no defence, its mobility, the bonuses a recruit and its class get, and its psi powers. */
static function XComGameState_Unit Give(XComGameState NewGameState, XComGameState_HeadquartersXCom XComHQ, int Mission, int Index)
{
	local LWX2CustomSoldier C;
	local XComGameState_Unit Unit;
	local ClassAgnosticAbility Power;
	local name Ability;
	local int i, Perk;

	if (!Find(Mission, Index, C))
	{
		`log("LongWarX2: council: no named soldier" @ Index @ "for mission" @ Mission @ "in this install's config", , 'LongWarX2');
		return none;
	}
	Unit = class'LWBonusEffects'.static.NewSoldier(NewGameState, XComHQ, C.BaseClass, C.Rank, C.Country, C.Female ? 2 : 1);
	if (Unit == none)
		return none;
	Unit.SetCharacterName(C.First, C.Last, C.Nick);
	// Its own stats in place of a recruit's roll (the roll's HP, aim and will are overwritten in Long War, its defence set
	// to 0; its mobility the roll's midpoint, unless it has its own); then the recruit's mobility bonus and its class's.
	class'LWRookieStats'.static.SetStat(Unit, eStat_HP, C.HP > 0 ? C.HP : class'LWRookieStats'.default.HP.Mid);
	class'LWRookieStats'.static.SetStat(Unit, eStat_Offense, C.Aim > 0 ? C.Aim : class'LWRookieStats'.default.Aim.Mid);
	class'LWRookieStats'.static.SetStat(Unit, eStat_Will, C.Will > 0 ? C.Will : class'LWRookieStats'.default.Will.Mid);
	class'LWRookieStats'.static.SetStat(Unit, eStat_Defense, 0);
	class'LWRookieStats'.static.SetStat(Unit, eStat_Mobility, C.Mobility > 0 ? C.Mobility : class'LWRookieStats'.default.Mobility.Mid);
	if (C.Mobility == 0)
		class'LWBonusEffects'.static.Raise(Unit, eStat_Mobility, class'LWBonuses'.static.Has(class'LWBonuses'.const.PAX_NIGERINA));
	Unit.SetUnitFloatValue('LWX2Bonus', 1, eCleanup_Never);
	class'LWBonusEffects'.static.GiveSoldier(Unit);
	for (i = 0; i < C.Perks.Length; i++)
	{
		Perk = (i < C.Alt.Length && C.Alt[i] > 0 && Rand(2) == 1) ? C.Alt[i] : C.Perks[i];
		Ability = class'X2Ability_LWStandins'.static.PsiAbilityFor(Perk);
		if (Ability == '')
			continue;
		// As a power trained in the Psi Labs (XComGameState_LWStrategy.PsiTrainingDone).
		Power.AbilityType.AbilityName = Ability;
		Power.AbilityType.ApplyToWeaponSlot = eInvSlot_PrimaryWeapon;
		Power.bUnlocked = true;
		Unit.AWCAbilities.AddItem(Power);
	}
	`log("LongWarX2: council: named soldier" @ Unit.GetFullName() @ "joins (mission" @ Mission $ ", class" @ C.BaseClass @ "rank" @ C.Rank $ "," @ Unit.AWCAbilities.Length @ "psi powers)", , 'LongWarX2');
	return Unit;
}
