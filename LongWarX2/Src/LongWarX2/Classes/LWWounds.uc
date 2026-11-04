// Long War's wound recovery (features/lw-classes.md, 2026-11-04), read from its code (XGFacility_Barracks.DetermineTimeOut,
// the wounded's part) and its DefaultGameCore.ini (XComLWStrategy.ini, generated): a wounded soldier is out for Base hours
// times the share of health lost, less a roll up to one hit point's share, where Base grows with the campaign's days
// (WoundHours less WoundHours × xx / (days + yy), WoundDays = xxyy); Adaptive Bone Marrow takes its share off, the Foundry's
// alien surgery 30 %. XCOM 2 heals a hit point a block (its heal project, which follows Long War's clock:
// XComGameState_LWStrategy.XCom2TimePasses); each new heal project is given Long War's hours, spread over its blocks.
// Not here: Long War's fatigue for the unhurt (features/lw-fatigue.md), MECs' and SHIVs' repairs.
class LWWounds extends Object config(LWStrategy);

var config int WoundHours;
var config int WoundDays;
var config float BoneMarrowBonus;
var config int SurgeryFoundry;
var config float SurgeryScale;

/** A wounded soldier's hours out, as Long War counts them. */
static function int HoursFor(XComGameState_Unit Unit, XComGameState_LWStrategy S)
{
	local int Base, H, HP, MaxHP;

	HP = int(Unit.GetCurrentStat(eStat_HP));
	MaxHP = Max(1, int(Unit.GetBaseStat(eStat_HP)));
	Base = default.WoundHours - default.WoundHours * (default.WoundDays / 100) / (S.Days() + default.WoundDays % 100);
	H = Base - Base * HP / MaxHP - Rand(Max(1, Base / MaxHP));
	if (Unit.HasSoldierAbility('LW_AdaptiveBoneMarrow'))
		H *= 1.0 - default.BoneMarrowBonus;
	if (S.FoundryDone.Find(default.SurgeryFoundry) != INDEX_NONE)
		H *= default.SurgeryScale;
	return Max(1, H);
}

/** Every heal project not given Long War's hours yet gets them (on the Geoscape, after a mission). */
static function Apply()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectHealSoldier Heal;
	local XComGameState_GameTime TimeState;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	local StateObjectReference Ref;
	local UnitValue V;
	local int H, Blocks;

	History = `XCOMHISTORY;
	S = class'XComGameState_LWStrategy'.static.Get();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime', true));
	if (S == none || XComHQ == none || TimeState == none)
		return;
	foreach XComHQ.Projects(Ref)
	{
		Heal = XComGameState_HeadquartersProjectHealSoldier(History.GetGameStateForObjectID(Ref.ObjectID));
		if (Heal == none)
			continue;
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Heal.ProjectFocus.ObjectID));
		if (Unit == none || (Unit.GetUnitValue('LWX2WoundProject', V) && int(V.fValue) == Heal.ObjectID))
			continue;
		if (NewGameState == none)
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: wounds");
		H = HoursFor(Unit, S);
		Heal = XComGameState_HeadquartersProjectHealSoldier(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectHealSoldier', Heal.ObjectID));
		Blocks = Max(1, Heal.BlocksRemaining);
		Heal.UpdateWorkPerHour(NewGameState);
		Heal.PointsPerBlock = Max(1, Round(float(H * Heal.WorkPerHour) / float(Blocks)));
		Heal.BlockPointsRemaining = Heal.PointsPerBlock;
		Heal.ProjectPointsRemaining = Heal.PointsPerBlock * Blocks;
		Heal.InitialProjectPoints = Heal.ProjectPointsRemaining;
		Heal.StartDateTime = TimeState.CurrentTime;
		Heal.SetProjectedCompletionDateTime(Heal.StartDateTime);
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetUnitFloatValue('LWX2WoundProject', Heal.ObjectID, eCleanup_Never);
		`log("LongWarX2: wounds:" @ Unit.GetFullName() @ int(Unit.GetCurrentStat(eStat_HP)) $ "/" $ int(Unit.GetBaseStat(eStat_HP)) @ "HP, out" @ H @ "hours (" $ (H + 23) / 24 @ "days), day" @ S.Days(), , 'LongWarX2');
	}
	if (NewGameState != none)
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
