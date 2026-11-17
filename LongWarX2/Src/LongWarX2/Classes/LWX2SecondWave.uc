// Long War's second-wave options (features/lw-second-wave.md), chosen on XCOM 2's new-campaign screen: XComUI.ini puts Long
// War's 31 there in place of XCOM 2's own (IDs LWSW_<nn>_<name>, Long War's order), and the campaign's settings keep the
// ones chosen (XComGameState_CampaignSettings). Each rule asks On(n) with Long War's number (#0 Damage Roulette … #30
// Green Fog), as Long War asks IsOptionEnabled.
class LWX2SecondWave extends Object config(LWGear);

/** Red Fog's caps (Long War's SW_ABDUCTION_SITES and SW_COVER_INCREASE, the names notwithstanding: aim 35, mobility 6). */
var config float RedFogAim, RedFogMobility;
/** Diminishing Returns' step (Long War's SW_SATELLITE_INCREASE). */
var config float SatelliteIncrease;
/** Quick and Dirty's share, least and most (Long War's ContBalance_Classic[33]: 60%, 6, 55). */
var config int QuickAndDirtyPct, QuickAndDirtyMin, QuickAndDirtyMax;
/** Green Fog's losses (ContBalance_Normal[1] and [2]: aim and will, one a turn when on, at most 30 and 20). */
var config int GreenFogAimStep, GreenFogAimMax, GreenFogWillStep, GreenFogWillMax;

/** Long War's option n chosen for this campaign. */
/** Save Scum (#5): "Loading a save game will reset the random number seed, so taking an identical action may yield different
 *  results." XCOM 2 restores the seed a save was made with (Checkpoint.PostLoadCheckpoint): with the option a new one is
 *  drawn as the game comes up again (the Avenger's HUD in strategy, the tactical HUD in a mission; also at a mission's
 *  start, where it changes nothing that was decided). */
static function SaveScum()
{
	if (On(5))
		class'Engine'.static.GetEngine().SetRandomSeeds(class'Engine'.static.GetEngine().GetARandomSeed());
}

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
	local XComGameState_LWStrategy S;
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
	// (New Economy and We Are Legion act as a campaign begins: in a running one, now.)
	S = class'XComGameState_LWStrategy'.static.Get();
	if (bOn && S != none && (n == 1 || n == 25))
	{
		S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
		if (n == 1)
			S.RandomizeFunding();
		else
			S.SquadSizesBought = Max(S.SquadSizesBought, class'LWStrategyRules'.default.SquadSizes.Length);
	}
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

/**
 * #0 Damage Roulette (XGTacticalGameCore.CalcOverallDamage), as a mission begins: Long War rolls (3D + 1 + rand(2D + 2)) / 4
 * without it, about D ± 1 (the port's spread 1), and (2D + 1 + rand(4D + 2)) / 4 with it, about D ± 2, a crit about 2D
 * (the port's spread 2 and crit D, where it is (D + 1) / 2). Every weapon with a spread (XCOM 2's alien weapons too: Long
 * War's roll is every weapon's; their crit stays XCOM 2's) is set so; without the option, as it was.
 */
static function ApplyDamageRoulette()
{
	local X2ItemTemplateManager Manager;
	local X2DataTemplate Data;
	local array<X2DataTemplate> All;
	local array<name> Names;
	local XComGameState_Item Item;
	local name N;
	local bool bOn;
	local int Changed;

	bOn = On(0);
	Manager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach Manager.IterateTemplates(Data, none)
		if (X2WeaponTemplate(Data) != none)
			Names.AddItem(Data.DataName);
	foreach Names(N)
	{
		All.Length = 0;
		Manager.FindDataTemplateAllDifficulties(N, All);
		foreach All(Data)
			Changed += Roulette(X2WeaponTemplate(Data), bOn);
	}
	// (And the templates the items in play hold: an item keeps the template it first found, and the port's arming pass
	// makes Long War's weapons' templates again, so these can be others than the manager's.)
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Item', Item)
		Changed += Roulette(X2WeaponTemplate(Item.GetMyTemplate()), bOn);
	`log("LongWarX2: Damage Roulette" @ (bOn ? "on:" : "off:") @ Changed @ "weapon templates changed", , 'LongWarX2');
}

/** A weapon template widened (or put back): its spread one more, and Long War's own weapons' crit D (else (D + 1) / 2).
 *  Marked on its damage's tag (the templates are shared by every campaign); one whose tag is something else's left alone. */
static function int Roulette(X2WeaponTemplate W, bool bOn)
{
	if (W == none || (W.BaseDamage.Tag != '' && W.BaseDamage.Tag != 'LWX2Roulette'))
		return 0;
	if (bOn == (W.BaseDamage.Tag == 'LWX2Roulette') || (bOn && W.BaseDamage.Spread <= 0))
		return 0;
	W.BaseDamage.Spread += bOn ? 1 : -1;
	W.BaseDamage.Tag = bOn ? 'LWX2Roulette' : '';
	if (Left(string(W.DataName), 9) == "LWWeapon_")
		W.BaseDamage.Crit = bOn ? W.BaseDamage.Damage : (W.BaseDamage.Damage + 1) / 2;
	return 1;
}

/** The satellites XCOM has: ready, in orbit, being built (CalcEscalatingSatelliteCost's count). */
static function int SatellitesHeld()
{
	local XComGameState_LWStrategy S;
	local int i, n;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return 0;
	n = S.SatellitesReady + S.SatellitesDue.Length;
	for (i = 0; i < S.Countries.Length; i++)
		if (S.Countries[i].bSatellite)
			n++;
	return n;
}

/**
 * #30 Green Fog (XGAbility_Targeted's aim, XGUnit's will; ContBalance_Normal[1] and [2]), asked twice a second in a mission:
 * XCOM's units lose aim and will with each of their turns, one a turn up to 30 and 20, back after the mission (the change is
 * the battle's, kept in the unit's LWX2GreenFogAim and LWX2GreenFogWill and taken back before the new one).
 */
static function UpdateGreenFog()
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local UnitValue OldAim, OldWill;
	local int Turn, Aim, Will;

	if (!On(30))
		return;
	Turn = class'LWX2CovertExtraction'.static.TurnNow();
	Aim = -Min(Turn * default.GreenFogAimStep, default.GreenFogAimMax);
	Will = -Min(Turn * default.GreenFogWillStep, default.GreenFogWillMax);
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() != eTeam_XCom || !Unit.IsAlive() || Unit.bRemovedFromPlay || Unit.GetMyTemplate().bIsCosmetic)
			continue;
		OldAim.fValue = 0;
		OldWill.fValue = 0;
		Unit.GetUnitValue('LWX2GreenFogAim', OldAim);
		Unit.GetUnitValue('LWX2GreenFogWill', OldWill);
		if (Aim == int(OldAim.fValue) && Will == int(OldWill.fValue))
			continue;
		if (NewGameState == none)
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Green Fog");
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetCurrentStat(eStat_Offense, Unit.GetCurrentStat(eStat_Offense) - int(OldAim.fValue) + Aim);
		Unit.SetCurrentStat(eStat_Will, Max(0, Unit.GetCurrentStat(eStat_Will) - int(OldWill.fValue) + Will));
		Unit.SetUnitFloatValue('LWX2GreenFogAim', Aim, eCleanup_BeginTactical);
		Unit.SetUnitFloatValue('LWX2GreenFogWill', Will, eCleanup_BeginTactical);
	}
	if (NewGameState != none)
	{
		`TACTICALRULES.SubmitGameState(NewGameState);
		`log("LongWarX2: Green Fog: turn" @ Turn $ ": aim" @ Aim @ "will" @ Will, , 'LongWarX2');
	}
}
