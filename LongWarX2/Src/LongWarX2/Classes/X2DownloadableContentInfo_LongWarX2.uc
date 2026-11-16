// The mod's entry point for XCOM 2 (features/hard-parts.md).
class X2DownloadableContentInfo_LongWarX2 extends X2DownloadableContentInfo;

/** A new campaign starts with Long War's jets. */
static event InstallNewCampaign(XComGameState StartState)
{
	class'XComGameState_LWAirWar'.static.CreateIn(StartState);
	ReplaceFactionHeroes(StartState);
	FirstMissionOnEWMap(StartState);
}

/**
 * The campaign's first mission (XCOM 2's, made with the campaign) played on an Enemy Within abduction map's own plot, with
 * Long War X2's mission: Long War's first mission squad stands at EW's pods (LWMissionSquads.SquadNow), its rule ends it.
 * Without converted maps it stays XCOM 2's.
 */
static function FirstMissionOnEWMap(XComGameState StartState)
{
	local XComGameState_MissionSite Mission;
	local PlotDefinition Plot;
	local MissionDefinition Def;
	local BiomeDefinition Biome;
	local string EWMap;

	if (!class'UIScreenListener_LongWarX2Tactical'.default.PlaceEWMapWhole)
		return;
	EWMap = class'LWX2EWMapPieces'.static.ChooseMap('Abduction', 0);
	if (EWMap == "")
		return;
	foreach StartState.IterateByClassType(class'XComGameState_MissionSite', Mission)
	{
		if (Mission.Source != 'MissionSource_Start')
			continue;
		foreach class'XComParcelManager'.default.arrPlots(Plot)
			if (Plot.MapName ~= ("LWX2_" $ EWMap))
				break;
		if (!(Plot.MapName ~= ("LWX2_" $ EWMap)))
			return;
		foreach class'XComTacticalMissionManager'.default.arrMissions(Def)
			if (Def.sType == class'UILWHeadquarters'.default.EWMission)
				break;
		if (Def.sType != class'UILWHeadquarters'.default.EWMission)
			return;
		foreach class'XComParcelManager'.default.arrBiomes(Biome)
			if (Biome.strType == class'UILWHeadquarters'.default.EWBiome)
				break;
		Mission.GeneratedMission.Plot = Plot;
		Mission.GeneratedMission.Mission = Def;
		Mission.GeneratedMission.Biome = Biome;
		Mission.GeneratedMission.SitReps.Length = 0;
		Mission.TacticalGameplayTags.Length = 0;
		`log("LongWarX2: the first mission on" @ Plot.MapName @ "with" @ Def.sType, , 'LongWarX2');
		return;
	}
}

/**
 * War of the Chosen's starting faction soldier (a Reaper, Skirmisher or Templar, without its narrative) replaced by
 * a recruit as the other starting soldiers are made: Long War has no factions (lw-missions.md).
 */
static function ReplaceFactionHeroes(XComGameState StartState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit, Recruit;
	local array<XComGameState_Unit> Heroes;
	local StateObjectReference Ref;
	local int k;

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
		break;
	if (XComHQ == none)
		return;
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(StartState.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit != none && Unit.GetMyTemplate().bIsResistanceHero)
			Heroes.AddItem(Unit);
	}
	foreach Heroes(Unit)
	{
		Recruit = `CHARACTERPOOLMGR.CreateCharacter(StartState, `XPROFILESETTINGS.Data.m_eCharPoolUsage);
		Recruit.RandomizeStats();
		Recruit.ApplyInventoryLoadout(StartState);
		Recruit.bIsFamous = true;
		Recruit.SetHQLocation(eSoldierLoc_Barracks);
		// The hero's unit is left out of the crew only (nothing else refers to it at the start).
		XComHQ.RemoveFromCrew(Unit.GetReference());
		XComHQ.AddToCrew(StartState, Recruit);
		Recruit.m_RecruitDate = Unit.m_RecruitDate;
		k = XComHQ.Squad.Find('ObjectID', Unit.ObjectID);
		if (k != INDEX_NONE)
			XComHQ.Squad[k] = Recruit.GetReference();
		`log("LongWarX2: the starting faction soldier" @ Unit.GetFullName() @ "replaced by a recruit," @ Recruit.GetFullName(), , 'LongWarX2');
	}
}

/** A campaign from before the mod gets them when it is loaded. */
static event OnLoadedSavedGameToStrategy()
{
	class'XComGameState_LWAirWar'.static.EnsureExists();
}

/** A mission from the campaign begins without squad concealment: Long War has none (lw-missions.md). */
static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_BattleData BattleData;

	foreach StartGameState.IterateByClassType(class'XComGameState_BattleData', BattleData)
		BattleData.bForceNoSquadConcealment = true;
}

/** Templates are built: Long War's classes armed in War of the Chosen's Skirmish Mode; XCOM 2's techs hidden behind Long War's; Long War's weapons given XCOM 2's looks. */
static event OnPostTemplatesCreated()
{
	class'LWX2SkirmishWeapons'.static.AddClasses();
	class'LWX2EWBodies'.static.AddAnimSets();
	class'LWAlienStats'.static.AddAbilities();
	class'LWOfficers'.static.AddAbilities();
	class'X2Ability_LWDamageReduction'.static.AddAbilities();
	class'X2Ability_LWMobileCover'.static.AddAbilities();
	class'X2StrategyElement_LWTechs'.static.HideXCom2Techs();
	class'X2Item_LWWeapons'.static.CopyLooks();
	class'X2Item_LWArmors'.static.CopyLooks();
	class'X2Item_LWSmallItems'.static.CopyLooks();
	class'X2Ability_LWStandins'.static.AddBonusRadii();
	class'X2Ability_LWStandins'.static.AddHealBonuses();
	class'X2Ability_LWStandins'.static.AddSmokeBonuses();
	class'X2Ability_LWStandins'.static.AddShredders();
	class'X2Ability_LWStandins'.static.AddPsiChecks();
	class'X2Ability_LWStandins'.static.AddBlocks();
	class'X2Ability_LWStandins'.static.AddScatter();
	class'X2Ability_LWStandins'.static.AddGrenadeRange();
}

/** Abilities a unit gets for the mission beyond its template's and its class's (XCOM 2's hook): the SHIVs' Foundry
 *  projects (LWSHIVs.AddFoundryAbilities). */
static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local LWX2CouncilBomb.LWX2BombDef Bomb;
	local LWX2CovertExtraction.LWX2CovertDef Covert;

	class'LWSHIVs'.static.AddFoundryAbilities(UnitState, SetupData);
	// Neural Feedback's answer to psionic attacks (X2Ability_LWNeuralFeedback).
	if (UnitState.GetTeam() == eTeam_XCom && UnitState.HasSoldierAbility('LW_NeuralFeedback'))
		class'LWSHIVs'.static.AddAbility(UnitState, 'LWX2_NeuralFeedback', eInvSlot_Unknown, SetupData);
	// Extra Conditioning's hit points by armour (X2Effect_LWExtraConditioning).
	if (UnitState.GetTeam() == eTeam_XCom && UnitState.HasSoldierAbility('LW_ExtraConditioning'))
		class'LWSHIVs'.static.AddAbility(UnitState, 'LWX2_ExtraConditioning', eInvSlot_Unknown, SetupData);
	// Concealment: hidden in high cover (X2Effect_LWConcealment).
	if (UnitState.GetTeam() == eTeam_XCom && UnitState.HasSoldierAbility('LW_Concealment'))
		class'LWSHIVs'.static.AddAbility(UnitState, 'LWX2_Concealment', eInvSlot_Unknown, SetupData);
	// Long War's ammo, every source added up (X2Effect_LWAmmoOdds).
	if (UnitState.GetTeam() == eTeam_XCom && UnitState.IsSoldier())
		class'LWSHIVs'.static.AddAbility(UnitState, 'LWX2_AmmoOdds', eInvSlot_Unknown, SetupData);
	// A council bomb disposal: XCOM's soldiers can switch its power nodes off and disarm it (LWX2CouncilBomb).
	if (UnitState.GetTeam() == eTeam_XCom && UnitState.IsSoldier() && class'LWX2CouncilBomb'.static.Active(Bomb))
	{
		class'LWSHIVs'.static.AddAbility(UnitState, 'LWX2_DeactivateNode', eInvSlot_Unknown, SetupData);
		class'LWSHIVs'.static.AddAbility(UnitState, 'LWX2_DisarmBomb', eInvSlot_Unknown, SetupData);
	}
	// EXALT's covert extraction: the operative can hack its comm relays (LWX2CovertExtraction).
	if (class'LWX2CovertExtraction'.static.Operative() != none && UnitState.ObjectID == class'LWX2CovertExtraction'.static.Operative().ObjectID
		&& class'LWX2CovertExtraction'.static.Active(Covert))
		class'LWSHIVs'.static.AddAbility(UnitState, 'LWX2_HackRelay', eInvSlot_Unknown, SetupData);
}

