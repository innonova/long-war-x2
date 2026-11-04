// Long War's experience (features/lw-classes.md, 2026-11-04), read from its code (XGTacticalGameCore.CalcXP, the kill
// and mission values; XGBattle.AdditionalBonuses, the mission's bonuses and the cap; XGCharacter_Soldier.LeveledUp) and its
// DefaultGameCore.ini (m_iSoldierXPLevels, the experience each rank needs). XCOM 2 promotes by kills: the ranks' kills are
// Long War's experience (XComGameData_XpData.ini, generated), and each soldier's Long War experience is kept on the unit
// (LWX2XP) and made their kill count with the kills XCOM 2 keeps for missions not played (NonTacticalKills). Awarded as the
// mission summary opens, while the mission's units are still there and before XCOM 2 looks at the soldiers' ranks.
class LWExperience extends Object;

/** A kill; a better alien's (one of BetterAliens, by a soldier below BetterKillBelowRank). */
var int KillXP, BetterKillXP, BetterKillBelowRank;
/** A mission won, each soldier alive: plain and special missions (SpecialKinds), each more for a soldier up to BetterWinUpToRank once the squad has seen a better alien. */
var int WinXP, BetterWinXP, SpecialWinXP, BetterSpecialWinXP, BetterWinUpToRank;
/** A mission won with nobody lost. */
var int NoDeathsXP;
/** EW's character types counted as better aliens (XGTacticalGameCore.IsBetterAlien). */
var array<int> BetterAliens;
/** The Long War Geoscape's mission kinds that are EW's special missions (a landed UFO, terror, an alien base, the HQ assault). */
var array<int> SpecialKinds;

/** A soldier's Long War experience: what has been awarded, or, never awarded, what their rank needs. */
static function int XPOf(XComGameState_Unit Unit)
{
	local UnitValue V;

	if (Unit.GetUnitValue('LWX2XP', V))
		return int(V.fValue);
	return class'X2ExperienceConfig'.static.GetRequiredKills(Unit.GetRank());
}

static function int ValueOf(XComGameState_Unit Unit, name Key)
{
	local UnitValue V;

	return Unit.GetUnitValue(Key, V) ? int(V.fValue) : 0;
}

/** The mission over (the summary opens): each soldier of the squad gets Long War's experience for it. */
static function MissionOver()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_BattleData Battle;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit, Victim;
	local XComGameState_AIGroup Group;
	local XComGameState NewGameState;
	local StateObjectReference Ref;
	local array<StateObjectReference> Kills;
	local array<XComGameState_Unit> Squad;
	local bool bWon, bNoDeaths, bSawBetter, bSpecial;
	local int XP, Gained, Earned, Rank, k, Level, Killed;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	Battle = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	if (XComHQ == none || Battle == none)
		return;
	bWon = Battle.bLocalPlayerWon;
	bNoDeaths = true;
	foreach XComHQ.Squad(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		// Awarded once for a mission.
		if (ValueOf(Unit, 'LWX2XPMission') == Battle.ObjectID)
			return;
		Squad.AddItem(Unit);
		if (Unit.IsDead() || Unit.bCaptured)
			bNoDeaths = false;
	}
	// The squad saw a better alien (XGUnit's event 13): one of the mission's was sighted or killed.
	foreach History.IterateByClassType(class'XComGameState_Unit', Victim)
	{
		if (Victim.GetTeam() != eTeam_Alien || default.BetterAliens.Find(ValueOf(Victim, 'LWX2Species')) == INDEX_NONE)
			continue;
		Group = Victim.GetGroupMembership();
		if (Victim.IsDead() || (Group != none && Group.EverSightedByEnemy))
		{
			bSawBetter = true;
			break;
		}
	}
	S = class'XComGameState_LWStrategy'.static.Get();
	bSpecial = S != none && default.SpecialKinds.Find(S.PendingKind) != INDEX_NONE;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: experience");
	foreach Squad(Unit)
	{
		if (Unit.IsDead())
			continue;
		XP = XPOf(Unit);
		Rank = Unit.GetRank();
		Gained = 0;
		Killed = 0;
		// The kills of this mission: those after the ones counted before, of enemies who died here.
		Kills = Unit.GetKills();
		for (k = ValueOf(Unit, 'LWX2KillsCounted'); k < Kills.Length; k++)
		{
			Victim = XComGameState_Unit(History.GetGameStateForObjectID(Kills[k].ObjectID));
			if (Victim == none || !Victim.IsDead() || Victim.GetVisualizer() == none || !Unit.IsEnemyUnit(Victim))
				continue;
			Earned = (Rank < default.BetterKillBelowRank && default.BetterAliens.Find(ValueOf(Victim, 'LWX2Species')) != INDEX_NONE) ? default.BetterKillXP : default.KillXP;
			// A pod leader's kill is worth a tenth more per level.
			Level = ValueOf(Victim, 'LWX2Leader');
			if (Level > 0)
				Earned = int(Earned * (1.0 + float(Level) / 10.0));
			Gained += Earned;
			Killed++;
		}
		if (bWon && !Unit.bCaptured)
		{
			if (bSpecial)
				Gained += (bSawBetter && Rank <= default.BetterWinUpToRank) ? default.BetterSpecialWinXP : default.SpecialWinXP;
			else
				Gained += (bSawBetter && Rank <= default.BetterWinUpToRank) ? default.BetterWinXP : default.WinXP;
			if (bNoDeaths)
				Gained += default.NoDeathsXP;
		}
		XP += Gained;
		// A mission won promotes at most one rank.
		if (bWon && Rank < 6)
			XP = Min(XP, class'X2ExperienceConfig'.static.GetRequiredKills(Rank + 2) - 1);
		else if (bWon && Rank == 6)
			XP = Min(XP, class'X2ExperienceConfig'.static.GetRequiredKills(7));
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetUnitFloatValue('LWX2XP', XP, eCleanup_Never);
		Unit.SetUnitFloatValue('LWX2KillsCounted', Kills.Length, eCleanup_Never);
		Unit.SetUnitFloatValue('LWX2XPMission', Battle.ObjectID, eCleanup_Never);
		Unit.NonTacticalKills = Max(0, XP - Unit.GetTotalNumKills(false));
		`log("LongWarX2: experience:" @ Unit.GetFullName() @ "+" $ Gained @ "(" $ Killed @ "kills," @ (bWon ? (bSpecial ? "special mission won" : "mission won") : "mission lost") $ (bNoDeaths ? ", nobody lost" : "") $ (bSawBetter ? ", a better alien seen" : "") $ "):" @ XP @ "of" @ (Rank < 7 ? class'X2ExperienceConfig'.static.GetRequiredKills(Rank + 1) : XP) @ "for the next rank", , 'LongWarX2');
	}
	if (NewGameState.GetNumGameStateObjects() > 0)
		History.AddGameStateToHistory(NewGameState);
	else
		History.CleanupPendingGameState(NewGameState);
}

defaultproperties
{
	KillXP=20
	BetterKillXP=40
	BetterKillBelowRank=4
	WinXP=80
	BetterWinXP=110
	SpecialWinXP=120
	BetterSpecialWinXP=180
	BetterWinUpToRank=4
	NoDeathsXP=20
	BetterAliens(0)=9
	BetterAliens(1)=11
	BetterAliens(2)=12
	BetterAliens(3)=16
	BetterAliens(4)=18
	BetterAliens(5)=21
	SpecialKinds(0)=2
	SpecialKinds(1)=4
	SpecialKinds(2)=5
	SpecialKinds(3)=7
}
