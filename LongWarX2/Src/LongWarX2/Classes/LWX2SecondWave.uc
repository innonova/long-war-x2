// Long War's second-wave options (features/lw-second-wave.md), chosen on XCOM 2's new-campaign screen: XComUI.ini puts Long
// War's 31 there in place of XCOM 2's own (IDs LWSW_<nn>_<name>, Long War's order), and the campaign's settings keep the
// ones chosen (XComGameState_CampaignSettings). Each rule asks On(n) with Long War's number (#0 Damage Roulette … #30
// Green Fog), as Long War asks IsOptionEnabled.
class LWX2SecondWave extends Object config(LWGear);

/** Red Fog's caps (Long War's SW_ABDUCTION_SITES and SW_COVER_INCREASE, the names notwithstanding: aim 35, mobility 6). */
var config float RedFogAim, RedFogMobility;

/** Long War's option n chosen for this campaign. */
static function bool On(int n)
{
	local XComGameState_CampaignSettings Settings;
	local name ID;

	ID = IdOf(n);
	if (ID == '')
		return false;
	Settings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	return Settings != none && Settings.IsSecondWaveOptionEnabled(ID);
}

/** Option n's ID on XCOM 2's screen (LWSW_<nn>_…), '' if XComUI.ini has none. */
static function name IdOf(int n)
{
	local string Prefix;
	local int i;

	Prefix = "LWSW_" $ (n < 10 ? "0" : "") $ n $ "_";
	for (i = 0; i < class'UIShellDifficulty'.default.SecondWaveOptions.Length; i++)
		if (Left(string(class'UIShellDifficulty'.default.SecondWaveOptions[i].ID), Len(Prefix)) == Prefix)
			return class'UIShellDifficulty'.default.SecondWaveOptions[i].ID;
	return '';
}

/** The options on, in words (the control port). */
static function string Listed()
{
	local string S;
	local int n;

	for (n = 0; n <= 30; n++)
		if (On(n))
			S @= string(IdOf(n));
	return S == "" ? "none" : S;
}

/** An option switched on or off in the running campaign (a test aid; the player chooses as the campaign starts). */
static function bool Set(int n, bool bOn)
{
	local XComGameState NewGameState;
	local XComGameState_CampaignSettings Settings;
	local name ID;

	ID = IdOf(n);
	Settings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if (ID == '' || Settings == none)
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a second-wave option set");
	Settings = XComGameState_CampaignSettings(NewGameState.ModifyStateObject(class'XComGameState_CampaignSettings', Settings.ObjectID));
	if (bOn)
		Settings.AddSecondWaveOption(ID);
	else
		Settings.RemoveSecondWaveOption(ID);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

/**
 * #6 Red Fog (XGUnit.SetUnitHP, ApplyHPStatPenalties), asked twice a second in a mission: every unit hurt has its aim and
 * mobility down as its health is down, at most RedFogAim and RedFogMobility at none left. The share: its health's share,
 * doubled for a robot, else raised by will over 60 (1 + max(0, 1 - 60 / will)); at a share of one or more, none. Applied as
 * Long War does, to the current stats, the last penalty taken back first (kept in the unit's LWX2RedFogAim and
 * LWX2RedFogMob).
 */
static function UpdateRedFog()
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local UnitValue OldAim, OldMob;
	local float Pct, Will;
	local int Aim, Mob;

	if (!On(6))
		return;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!Unit.IsAlive() || Unit.bRemovedFromPlay || Unit.GetMaxStat(eStat_HP) <= 0 || Unit.GetMyTemplate().bIsCosmetic)
			continue;
		Pct = Unit.GetCurrentStat(eStat_HP) / Unit.GetMaxStat(eStat_HP);
		if (Unit.IsRobotic())
			Pct *= 2;
		else
		{
			Will = Unit.GetCurrentStat(eStat_Will);
			Pct *= 1 + FMax(0, Will > 0 ? 1 - 60 / Will : 0.0);
		}
		Aim = Pct >= 1 ? 0 : int((Pct - 1) * default.RedFogAim);
		Mob = Pct >= 1 ? 0 : int((Pct - 1) * default.RedFogMobility);
		// (Cleared first: a unit without the value leaves the struct as the last unit's.)
		OldAim.fValue = 0;
		OldMob.fValue = 0;
		Unit.GetUnitValue('LWX2RedFogAim', OldAim);
		Unit.GetUnitValue('LWX2RedFogMob', OldMob);
		if (Aim == int(OldAim.fValue) && Mob == int(OldMob.fValue))
			continue;
		if (NewGameState == none)
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Red Fog");
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetCurrentStat(eStat_Offense, Unit.GetCurrentStat(eStat_Offense) - int(OldAim.fValue) + Aim);
		Unit.SetCurrentStat(eStat_Mobility, Max(1, Unit.GetCurrentStat(eStat_Mobility) - int(OldMob.fValue) + Mob));
		Unit.SetUnitFloatValue('LWX2RedFogAim', Aim, eCleanup_BeginTactical);
		Unit.SetUnitFloatValue('LWX2RedFogMob', Mob, eCleanup_BeginTactical);
		`log("LongWarX2: Red Fog:" @ Unit.GetFullName() @ "aim" @ Aim @ "mobility" @ Mob, , 'LongWarX2');
	}
	if (NewGameState != none)
		`TACTICALRULES.SubmitGameState(NewGameState);
}
