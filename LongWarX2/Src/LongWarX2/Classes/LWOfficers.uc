// Long War's officers (features/lw-officers.md): Enemy Within's medals, repurposed, read from Long War's code
// (XGFacility_Barracks.BuildMedals, UnlockMedal, CanAwardMedalToSoldier, AwardMedalToSoldier; XGTechTree.HasOTSPrereqs;
// XGUnit, the squad's leader and the powers). Five officer ranks, lieutenant to field commander, each opened by an Officer
// Training School project and holding a count of officers; each rank a choice of two powers and a Command charge.
//
// Kept on the soldier as unit values: LWX2OfficerRank (0 to 5), LWX2OfficerPowers (bit r-1 set: rank r's second power
// chosen), LWX2OfficerMissionsAt (missions done at the last officer promotion). The projects bought and the officers each
// rank holds, available and used (UnlockMedal's arithmetic), on the Long War state.
class LWOfficers extends Object config(LWStrategy) dependson(LWStrategyRules);

/** Officers per rank (lieutenant first) a rank's project adds to it and to each rank below (ContBalance_Classic[0]). */
var config int OfficersPerRank[5];
/** Missions in a grade before the next officer promotion (NUM_MEDALOFHONOR_MISSIONS). */
var config int MissionsPerGrade;
/** Fatigue hours more per officer rank (SPECIES_POINT_LIMIT). */
var config int FatigueHoursPerRank;
/** The powers' numbers. */
var config int UrbanDefense, InternationalWill, InternationalAim, TerraWill, TerraDefense, TerraXPDivisor, CouncilStatMax;

/** The powers, two per rank in Long War's order (BuildMedals: PowerA, PowerB). */
const LEGIO_PATRIA_NOSTRA = 0;
const STAY_FROSTY = 1;
const FORTIORES_UNA = 2;
const SEMPER_VIGILANS = 3;
const INTO_THE_BREACH = 4;
const SO_SHALL_YOU_FIGHT = 5;
const BAND_OF_WARRIORS = 6;
const ESPRIT_DE_CORPS = 7;
const COMBINED_ARMS = 8;
const SO_OTHERS_MAY_LIVE = 9;

/** Long War's perk numbers for the powers (EPerkType), in the order above: its words are read by them. */
var int PowerPerks[10];

/** Long War's words, written from the player's install (scripts/lw-words.mjs, makeOfficerWords): the officer ranks' names
 *  and short names (XGFacility_Barracks.m_arrMedalNames), the powers' names and descriptions (its perks'). */
var localized string RankNames[5], RankShort[5];
var localized string PowerNames[10], PowerDescs[10];
var localized string LeadByExample, LeadByExampleDesc, Command, CommandDesc;

static function int ValueOf(XComGameState_Unit Unit, name Key)
{
	local UnitValue V;

	return (Unit != none && Unit.GetUnitValue(Key, V)) ? int(V.fValue) : 0;
}

static function int Rank(XComGameState_Unit Unit)
{
	return ValueOf(Unit, 'LWX2OfficerRank');
}

/** The power a soldier chose at an officer rank (1 to 5), or -1 below it. */
static function int PowerAt(XComGameState_Unit Unit, int OfficerRank)
{
	if (OfficerRank < 1 || OfficerRank > Rank(Unit))
		return -1;
	return 2 * (OfficerRank - 1) + ((ValueOf(Unit, 'LWX2OfficerPowers') >> (OfficerRank - 1)) & 1);
}

/** A power's name and description, EW's live numbers filled in (its <XGAbility:…/> tags). */
static function string PowerName(int Power)
{
	return default.PowerNames[Power];
}

static function string PowerDesc(int Power)
{
	local string D;

	D = default.PowerDescs[Power];
	D = Repl(D, "<XGAbility:UrbanDefense/>", default.UrbanDefense);
	D = Repl(D, "<XGAbility:InternationalWill/>", default.InternationalWill);
	D = Repl(D, "<XGAbility:InternationalAim/>", default.InternationalAim);
	D = Repl(D, "<XGAbility:TerraWill/>", default.TerraWill);
	D = Repl(D, "<XGAbility:TerraDefense/>", default.TerraDefense);
	return D;
}

static function bool HasPower(XComGameState_Unit Unit, int Power)
{
	return PowerAt(Unit, Power / 2 + 1) == Power;
}

/** Long War's name for an officer rank (1 to 5). */
static function string RankName(int OfficerRank)
{
	if (OfficerRank < 1 || OfficerRank > 5)
		return "";
	return default.RankNames[OfficerRank - 1] != "" ? default.RankNames[OfficerRank - 1] : "Officer rank" @ OfficerRank;
}

/** Whether the soldier is psionic (any of Long War's psi powers). */
static function bool IsPsion(XComGameState_Unit Unit)
{
	local LWBaseRules.LWPsiPower P;
	local name Ability;

	foreach class'LWBaseRules'.default.PsiPowers(P)
	{
		Ability = class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk);
		if (Ability != '' && Unit.HasSoldierAbility(Ability))
			return true;
	}
	return false;
}

/** The next officer project (0: lieutenants), as the Officer Training School offers it: Special Warfare School takes its
 *  share off the cash, Sandhurst off the ranks it needs (as for the squad sizes). */
static function LWStrategyRules.LWSquadSize ProjectNext(int k, XComGameState_LWStrategy S)
{
	local LWStrategyRules.LWSquadSize Next;
	local int v;

	Next = class'LWStrategyRules'.default.OfficerProjects[k];
	v = class'LWBonuses'.static.Has(class'LWBonuses'.const.SPECIAL_WARFARE_SCHOOL, S);
	if (v > 0)
		Next.Cash *= 1.0 - v / 100.0;
	v = class'LWBonuses'.static.Has(class'LWBonuses'.const.SANDHURST, S);
	if (v > 0)
		Next.Ranks = int(Next.Ranks * (1.0 - v / 100.0));
	return Next;
}

/** Whether officer project k can be bought (XGTechTree.HasOTSPrereqs): the school, the barracks' ranks, the project
 *  before it (a captain's needs the lieutenants'), the cash. */
static function bool CanBuy(XComGameState_LWStrategy S, int k, out string Why)
{
	local LWStrategyRules.LWSquadSize Next;

	Why = "";
	if (k < 0 || k >= class'LWStrategyRules'.default.OfficerProjects.Length)
		Why = "nothing";
	else if (k < S.OfficerProjectsBought)
		Why = "nothing: bought";
	else if (k > S.OfficerProjectsBought)
		Why = "the officer project before it";
	else
	{
		Next = ProjectNext(k, S);
		if (class'LWBase'.static.Count(S, 12) == 0)
			Why = "the Officer Training School";
		else if (class'XComGameState_LWStrategy'.static.RanksInBarracks() < Next.Ranks)
			Why = "ranks adding up to" @ Next.Ranks @ "(now" @ class'XComGameState_LWStrategy'.static.RanksInBarracks() $ ")";
		else if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < Next.Cash)
			Why = class'LWStrategyRules'.static.Money(Next.Cash);
	}
	return Why == "";
}

/** Officer project k bought: its rank opened, its officers added to it and every rank below (UnlockMedal). */
static function bool Buy(int k, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local int Cash, r;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || !CanBuy(S, k, Why))
		return false;
	Cash = ProjectNext(k, S).Cash;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: officer project bought");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -Cash);
	S.OfficerProjectsBought = k + 1;
	if (S.OfficersAvailable.Length < 5)
		S.OfficersAvailable.Length = 5;
	for (r = 0; r <= k; r++)
		S.OfficersAvailable[r] += default.OfficersPerRank[k];
	S.Note("The Officer Training School: promotions to" @ RankName(k + 1) @ "open.");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

/** Whether the soldier can be made an officer of the next rank (CanAwardMedalToSoldier); Why says what is missing. */
static function bool CanPromote(XComGameState_LWStrategy S, XComGameState_Unit Unit, out string Why)
{
	local int Next;

	Why = "";
	Next = Rank(Unit) + 1;
	if (Unit == none || !Unit.IsSoldier() || Unit.IsRobotic() || class'LWMECs'.static.IsMEC(Unit) || !Unit.IsAlive())
		Why = "a soldier";
	else if (Next > 5)
		Why = "nothing: the highest rank";
	else if (S.OfficersAvailable.Length < Next || S.OfficersAvailable[Next - 1] <= 0)
		Why = "a" @ RankName(Next) @ "post open (the Officer Training School)";
	else if (Unit.GetRank() < Next + 2)
		Why = "the rank of" @ class'X2ExperienceConfig'.static.GetRankName(Next + 2, Unit.GetSoldierClassTemplateName());
	else if (Unit.GetNumMissions() - ValueOf(Unit, 'LWX2OfficerMissionsAt') < default.MissionsPerGrade)
		Why = default.MissionsPerGrade @ "missions in grade (now" @ (Unit.GetNumMissions() - ValueOf(Unit, 'LWX2OfficerMissionsAt')) $ ")";
	else if (IsPsion(Unit))
		Why = "a soldier who is not psionic";
	else if (S.InPsiTraining(Unit.ObjectID) || S.GenePatients.Find('Unit', Unit.ObjectID) != INDEX_NONE)
		Why = "a soldier not in the labs";
	return Why == "";
}

/** The soldier made an officer of the next rank with the rank's first or second power (bSecond). */
static function bool Promote(int UnitID, bool bSecond, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local int Next;

	S = class'XComGameState_LWStrategy'.static.Get();
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (S == none || !CanPromote(S, Unit, Why))
		return false;
	Next = Rank(Unit) + 1;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: officer promotion");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitID));
	Unit.SetUnitFloatValue('LWX2OfficerRank', Next, eCleanup_Never);
	Unit.SetUnitFloatValue('LWX2OfficerPowers', ValueOf(Unit, 'LWX2OfficerPowers') | ((bSecond ? 1 : 0) << (Next - 1)), eCleanup_Never);
	Unit.SetUnitFloatValue('LWX2OfficerMissionsAt', Unit.GetNumMissions(), eCleanup_Never);
	S.OfficersAvailable[Next - 1]--;
	if (S.OfficersUsed.Length < 5)
		S.OfficersUsed.Length = 5;
	S.OfficersUsed[Next - 1]++;
	S.Note(Unit.GetName(eNameType_FullNick) @ "promoted to" @ RankName(Next) $ ".");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

/** The squad's leader before a mission (XGFacility_Barracks, before launch): the officer with the most ranks, ties to the
 *  higher will; none without officers. */
static function XComGameState_Unit LeaderOf(array<XComGameState_Unit> Squad)
{
	local XComGameState_Unit Unit, Best;

	foreach Squad(Unit)
	{
		if (Unit == none || Rank(Unit) == 0)
			continue;
		if (Best == none || Rank(Unit) > Rank(Best) || (Rank(Unit) == Rank(Best) && Unit.GetCurrentStat(eStat_Will) > Best.GetCurrentStat(eStat_Will)))
			Best = Unit;
	}
	return Best;
}

/**
 * Before launch (XGFacility_Barracks, as Long War copies the leader's medal perks to the squad): the squad's leader picked
 * and, on every soldier going, LWX2SquadLeader (the leader's ObjectID, 0 without officers) and LWX2SquadPowers (the
 * leader's powers, bit p for power p). The tactical abilities and the debrief's powers read them.
 */
static function MarkSquad()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit, Leader;
	local array<XComGameState_Unit> Squad;
	local StateObjectReference Ref;
	local int Powers, r;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	foreach XComHQ.Squad(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit != none)
			Squad.AddItem(Unit);
	}
	Leader = LeaderOf(Squad);
	if (Leader != none)
		for (r = 1; r <= Rank(Leader); r++)
			Powers = Powers | (1 << PowerAt(Leader, r));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the squad's officer");
	foreach Squad(Unit)
	{
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetUnitFloatValue('LWX2SquadLeader', Leader != none ? Leader.ObjectID : 0, eCleanup_Never);
		Unit.SetUnitFloatValue('LWX2SquadPowers', Powers, eCleanup_Never);
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	if (Leader != none)
		`log("LongWarX2: officers: the squad led by" @ Leader.GetFullName() @ "(" $ RankName(Rank(Leader)) $ "), powers" @ Powers, , 'LongWarX2');
}

/** Whether the soldier's last squad had the power from its leader. */
static function bool SquadHad(XComGameState_Unit Unit, int Power)
{
	return (ValueOf(Unit, 'LWX2SquadPowers') & (1 << Power)) != 0;
}

/** The officers' abilities on XCOM 2's soldier template (as the templates are made): each acts only by what launch marked. */
static function AddAbilities()
{
	local array<X2DataTemplate> Templates;
	local X2DataTemplate T;
	local name A;
	local array<name> Officer;

	Officer.AddItem('LWX2_OfficerPowers');
	Officer.AddItem('LWX2_Command');
	Officer.AddItem('LWX2_LeadByExample');
	class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindDataTemplateAllDifficulties('Soldier', Templates);
	foreach Templates(T)
		foreach Officer(A)
			if (X2CharacterTemplate(T) != none && X2CharacterTemplate(T).Abilities.Find(A) == INDEX_NONE)
				X2CharacterTemplate(T).Abilities.AddItem(A);
}

/** Fatigue hours more for the soldier's officer ranks (DetermineTimeOut). */
static function int FatigueHours(XComGameState_Unit Unit)
{
	return Rank(Unit) * default.FatigueHoursPerRank;
}

defaultproperties
{
	PowerPerks(0) = 156
	PowerPerks(1) = 122
	PowerPerks(2) = 140
	PowerPerks(3) = 152
	PowerPerks(4) = 161
	PowerPerks(5) = 1
	PowerPerks(6) = 157
	PowerPerks(7) = 160
	PowerPerks(8) = 138
	PowerPerks(9) = 158
}
