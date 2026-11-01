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

/** Templates are built: Long War's classes armed in War of the Chosen's Skirmish Mode. */
static event OnPostTemplatesCreated()
{
	class'LWX2SkirmishWeapons'.static.AddClasses();
}
