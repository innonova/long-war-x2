// Long War's second-wave options (features/lw-second-wave.md), chosen on XCOM 2's new-campaign screen: XComUI.ini puts Long
// War's 31 there in place of XCOM 2's own (IDs LWSW_<nn>_<name>, Long War's order), and the campaign's settings keep the
// ones chosen (XComGameState_CampaignSettings). Each rule asks On(n) with Long War's number (#0 Damage Roulette … #30
// Green Fog), as Long War asks IsOptionEnabled.
class LWX2SecondWave extends Object;

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
