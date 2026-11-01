// The mod's entry point for XCOM 2 (features/hard-parts.md).
class X2DownloadableContentInfo_LongWarX2 extends X2DownloadableContentInfo;

/** A new campaign starts with Long War's jets. */
static event InstallNewCampaign(XComGameState StartState)
{
	class'XComGameState_LWAirWar'.static.CreateIn(StartState);
}

/** A campaign from before the mod gets them when it is loaded. */
static event OnLoadedSavedGameToStrategy()
{
	class'XComGameState_LWAirWar'.static.EnsureExists();
}

/** Templates are built: Long War's classes armed in War of the Chosen's Skirmish Mode; XCOM 2's techs hidden behind Long War's; Long War's weapons given XCOM 2's looks. */
static event OnPostTemplatesCreated()
{
	class'LWX2SkirmishWeapons'.static.AddClasses();
	class'X2StrategyElement_LWTechs'.static.HideXCom2Techs();
	class'X2Item_LWWeapons'.static.CopyLooks();
	class'X2Item_LWArmors'.static.CopyLooks();
	class'X2Item_LWSmallItems'.static.CopyLooks();
}
