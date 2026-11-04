// Long War's fatigue in place of War of the Chosen's (features/lw-fatigue.md; the person, 2026-11-04: in place of), read
// from its code (XGFacility_Barracks.DetermineTimeOut, HealAndRest): a soldier back from a mission is out of action for
// hours: 96 and a roll up to 47 more, 144 if they were hurt or went "all in" (sent while still fatigued; they also lose a
// point of maximum health, down to 1); a wounded soldier's healing comes on top; scaled by RAND_DAYS_INJURED_TANK (in per
// cent). Shown as War of the Chosen's Tired (the squad screens show it, and a Tired soldier may still be sent, as Long War
// lets a fatigued one go all in): the will set to the top of the Tired band as the Geoscape opens after the mission, XCOM
// 2's own will recovery taken off, the will full again when Long War's hours are over (each hour of Long War's clock).
// Each psi power and gene mod the soldier has adds its own hours (config PerkHours).
// Not yet: officers' hours, the critical wounds' hours, the psi armour, the country bonuses that lessen the powers' hours.
class LWFatigue extends Object config(LWStrategy);

/** A psi power's or a gene mod's own hours (Long War's ItemBalance_Easy: the perk, its iEng). */
struct LWPerkHours
{
	var int Perk;
	var int Hours;
};
var config array<LWPerkHours> PerkHours;

var int BaseHours, RollHours, HardHours, ScalePct;

static function int ValueOf(XComGameState_Unit Unit, name Key)
{
	local UnitValue V;

	return Unit.GetUnitValue(Key, V) ? int(V.fValue) : 0;
}

/** On the Geoscape after a mission: each soldier of the squad rests Long War's hours, Tired meanwhile. */
static function Apply()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	local StateObjectReference Ref;
	local bool bAllIn, bHurt;
	local int Mission, H, Wound;

	History = `XCOMHISTORY;
	S = class'XComGameState_LWStrategy'.static.Get();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (S == none || XComHQ == none)
		return;
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier() || Unit.IsDead())
			continue;
		// A mission not counted yet (LWExperience marks the squad's living soldiers with it).
		Mission = ValueOf(Unit, 'LWX2XPMission');
		if (Mission == 0 || Mission == ValueOf(Unit, 'LWX2FatigueMission'))
			continue;
		if (NewGameState == none)
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: fatigue");
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		bAllIn = ValueOf(Unit, 'LWX2AllIn') > 0;
		bHurt = Unit.GetCurrentStat(eStat_HP) < Unit.GetMaxStat(eStat_HP);
		H = (bAllIn || bHurt) ? default.HardHours : default.BaseHours + Rand(default.RollHours);
		H += PowersHours(Unit);
		H = H * default.ScalePct / 100;
		Wound = WoundHours(Unit);
		if (bAllIn)
		{
			Unit.SetBaseMaxStat(eStat_HP, Max(1, int(Unit.GetBaseStat(eStat_HP)) - 1));
			Unit.SetCurrentStat(eStat_HP, Min(int(Unit.GetCurrentStat(eStat_HP)), int(Unit.GetBaseStat(eStat_HP))));
		}
		Unit.SetUnitFloatValue('LWX2AllIn', 0, eCleanup_Never);
		Unit.SetUnitFloatValue('LWX2FatigueMission', Mission, eCleanup_Never);
		Unit.SetUnitFloatValue('LWX2RestedAt', S.Hours + Wound + H, eCleanup_Never);
		Unit.SetCurrentStat(eStat_Will, Unit.GetMaxWillForMentalState(eMentalState_Tired));
		Unit.UpdateMentalState();
		XComHQ = NoWillProject(NewGameState, XComHQ, Unit);
		ShowRest(NewGameState, Unit, Wound + H);
		`log("LongWarX2: fatigue:" @ Unit.GetFullName() @ "rests" @ H @ "hours" $ (Wound > 0 ? " after" @ Wound @ "of healing" : "") $ (bAllIn ? ", went all in (maximum health now" @ int(Unit.GetBaseStat(eStat_HP)) $ ")" : "") $ (bHurt ? ", hurt" : "") $ "; Tired until hour" @ S.Hours + Wound + H, , 'LongWarX2');
	}
	if (NewGameState != none)
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** Each hour of Long War's clock: the soldiers whose rest is over are ready again; those resting keep no XCOM 2 recovery. */
static function Tick(XComGameState NewGameState, XComGameState_LWStrategy S)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local int At;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (XComHQ == none)
		return;
	if (XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(XComHQ.ObjectID)) != none)
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(XComHQ.ObjectID));
	foreach XComHQ.Crew(Ref)
	{
		// As this change has it (several hours may pass in one change), else as the history has it.
		Unit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none)
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		At = ValueOf(Unit, 'LWX2RestedAt');
		if (At <= 0)
			continue;
		if (At > S.Hours && WillProjectOf(XComHQ, Unit) == none)
			continue;
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		XComHQ = NoWillProject(NewGameState, XComHQ, Unit);
		if (At > S.Hours)
			continue;
		Unit.SetUnitFloatValue('LWX2RestedAt', 0, eCleanup_Never);
		Unit.SetCurrentStat(eStat_Will, Unit.GetMaxStat(eStat_Will));
		Unit.UpdateMentalState();
		ShowRest(NewGameState, Unit, 0);
		`log("LongWarX2: fatigue:" @ Unit.GetFullName() @ "rested, ready again at hour" @ S.Hours, , 'LongWarX2');
	}
}

/** A test aid (control aid tire): the squad as if back from a mission, resting the hours given. */
static function string Tire(int H)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	local StateObjectReference Ref;
	local int n;

	History = `XCOMHISTORY;
	S = class'XComGameState_LWStrategy'.static.Get();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (S == none || XComHQ == none)
		return "ERR no campaign";
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: tired");
	foreach XComHQ.Squad(Ref)
	{
		if (Ref.ObjectID <= 0)
			continue;
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		Unit.SetUnitFloatValue('LWX2RestedAt', S.Hours + H, eCleanup_Never);
		Unit.SetCurrentStat(eStat_Will, Unit.GetMaxWillForMentalState(eMentalState_Tired));
		Unit.UpdateMentalState();
		n++;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return "ok" @ n @ "of the squad tired for" @ H @ "hours";
}

/** At a mission's start: those of the squad still resting go all in. */
static function MarkAllIn()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	local StateObjectReference Ref;

	History = `XCOMHISTORY;
	S = class'XComGameState_LWStrategy'.static.Get();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (S == none || XComHQ == none)
		return;
	foreach XComHQ.Squad(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier() || ValueOf(Unit, 'LWX2RestedAt') <= S.Hours || ValueOf(Unit, 'LWX2AllIn') > 0)
			continue;
		if (NewGameState == none)
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: all in");
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetUnitFloatValue('LWX2AllIn', 1, eCleanup_Never);
		`log("LongWarX2: fatigue:" @ Unit.GetFullName() @ "goes all in (still" @ ValueOf(Unit, 'LWX2RestedAt') - S.Hours @ "hours from rested)", , 'LongWarX2');
	}
	if (NewGameState != none)
		History.AddGameStateToHistory(NewGameState);
}

/** The hours the soldier's psi powers and gene mods add. */
static function int PowersHours(XComGameState_Unit Unit)
{
	local LWPerkHours P;
	local name Ability;
	local int H;

	foreach default.PerkHours(P)
	{
		Ability = class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk);
		if (Ability == '')
			Ability = class'X2Ability_LWStandins'.static.GeneAbilityFor(P.Perk);
		if (Ability != '' && Unit.HasSoldierAbility(Ability, true))
			H += P.Hours;
	}
	return H;
}

/** The hours left of a soldier's healing (its heal project), none if not healing. */
static function int WoundHours(XComGameState_Unit Unit)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectHealSoldier Heal;
	local StateObjectReference Ref;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (XComHQ == none)
		return 0;
	foreach XComHQ.Projects(Ref)
	{
		Heal = XComGameState_HeadquartersProjectHealSoldier(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Heal != none && Heal.ProjectFocus.ObjectID == Unit.ObjectID)
			return Heal.GetCurrentNumHoursRemaining();
	}
	return 0;
}

static function XComGameState_HeadquartersProjectRecoverWill WillProjectOf(XComGameState_HeadquartersXCom XComHQ, XComGameState_Unit Unit)
{
	local XComGameState_HeadquartersProjectRecoverWill Will;
	local StateObjectReference Ref;

	foreach XComHQ.Projects(Ref)
	{
		Will = XComGameState_HeadquartersProjectRecoverWill(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Will != none && Will.ProjectFocus.ObjectID == Unit.ObjectID)
			return Will;
	}
	return none;
}

/**
 * The rest's days shown where XCOM 2 shows a Tired soldier's (XComGameState_Unit.GetMentalStateStringsSeparate: any will
 * recovery project in the history naming the soldier, its completion date): one such project kept for each resting soldier,
 * outside the headquarters' projects (so XCOM 2 neither advances nor completes it), completing at Long War's hour; none
 * once rested (Hours 0).
 */
static function ShowRest(XComGameState NewGameState, XComGameState_Unit Unit, int Hours)
{
	local XComGameState_HeadquartersProjectRecoverWill Will;
	local XComGameState_GameTime TimeState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_HeadquartersProjectRecoverWill', Will)
		if (Will.ProjectFocus.ObjectID == Unit.ObjectID && NewGameState.GetGameStateForObjectID(Will.ObjectID) == none)
			NewGameState.RemoveStateObject(Will.ObjectID);
	if (Hours <= 0)
		return;
	TimeState = XComGameState_GameTime(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	Will = XComGameState_HeadquartersProjectRecoverWill(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectRecoverWill'));
	Will.ProjectFocus = Unit.GetReference();
	Will.WorkPerHour = 1;
	Will.StartDateTime = TimeState.CurrentTime;
	Will.CompletionDateTime = TimeState.CurrentTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(Will.CompletionDateTime, Hours);
}

/** XCOM 2's will recovery for the soldier taken off (Long War's hours decide when they are ready). */
static function XComGameState_HeadquartersXCom NoWillProject(XComGameState NewGameState, XComGameState_HeadquartersXCom XComHQ, XComGameState_Unit Unit)
{
	local XComGameState_HeadquartersProjectRecoverWill Will;

	Will = WillProjectOf(XComHQ, Unit);
	if (Will == none)
		return XComHQ;
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.Projects.RemoveItem(Will.GetReference());
	NewGameState.RemoveStateObject(Will.ObjectID);
	return XComHQ;
}

defaultproperties
{
	BaseHours=96
	RollHours=48
	HardHours=144
	ScalePct=100
}
