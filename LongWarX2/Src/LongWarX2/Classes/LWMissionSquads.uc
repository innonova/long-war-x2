// Long War's alien squads in XCOM 2's missions (features/lw-missions.md): a mission sent from the Long War Geoscape is
// fought against the squad Long War gives it (LWAlienSquads: by UFO, kind of mission, day, the aliens' resources and
// aggression), its species as XCOM 2's nearest aliens (LWStrategyRules.FightAs, APPROXIMATION until Enemy Within's
// aliens are units). XCOM 2's mission keeps its pods' number and places (its map's); Long War's aliens are shared out
// among them, the first alien (the commander) in the first pod. Pods that are not aliens' (a VIP, a strategy unit)
// are left as they are.
class LWMissionSquads extends Object dependson(LWStrategyRules);

static function name TemplateFor(int Char)
{
	local int k;

	k = class'LWStrategyRules'.default.FightAs.Find('Char', Char);
	return k == INDEX_NONE ? 'Sectoid' : class'LWStrategyRules'.default.FightAs[k].Template;
}

/** The mission's pods given Long War's squad (the mission site in the change being built, its pods cached first). */
static function ApplyTo(XComGameState_MissionSite Mission, array<int> Squad)
{
	local array<int> Pods;
	local int i, k, p, n, Size;

	Mission.UpdateSelectedMissionData();
	for (i = 0; i < Mission.SelectedMissionData.SelectedEncounters.Length; i++)
		if (Mission.SelectedMissionData.SelectedEncounters[i].EncounterSpawnInfo.Team == eTeam_Alien
			&& Mission.SelectedMissionData.SelectedEncounters[i].EncounterSpawnInfo.StrategyUnitTag == '')
			Pods.AddItem(i);
	if (Pods.Length == 0 || Squad.Length == 0)
		return;
	for (p = 0; p < Pods.Length; p++)
	{
		i = Pods[p];
		Mission.SelectedMissionData.SelectedEncounters[i].EncounterSpawnInfo.SelectedCharacterTemplateNames.Length = 0;
		// An even share, the first pods taking the remainder.
		Size = Squad.Length / Pods.Length + (p < Squad.Length % Pods.Length ? 1 : 0);
		for (n = 0; n < Size && k < Squad.Length; n++)
			Mission.SelectedMissionData.SelectedEncounters[i].EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem(TemplateFor(Squad[k++]));
		Mission.SelectedMissionData.SelectedEncounters[i].EncounterSpawnInfo.MaxGroupSize = Max(1, Size);
	}
	`log("LongWarX2: missions: Long War's squad of" @ Squad.Length @ "in" @ Pods.Length @ "pods", , 'LongWarX2');
}
