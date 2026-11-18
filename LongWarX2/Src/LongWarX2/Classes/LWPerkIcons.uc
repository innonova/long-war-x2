// EW's perk icon for each of the port's abilities (features/strategy-flow.md: the soldier screens on EW's): the frame of
// EW's perk icon clip that the ability's Long War perk shows (XComPerkManager.BuildPerkTables' image), generated into
// XComLWClasses.ini by scripts/classes-config.mjs from the Tree's data/perks.json. EW's screens take the frame's name
// (UIUtilities.GetPerkIconLabel), e.g. the soldier summary's ability list.
class LWPerkIcons extends Object config(LWClasses);

struct PerkIcon
{
	var name Ability;
	var string Frame;
};

var config array<PerkIcon> Icons;

/** The frame for an ability, else "" (EW's list then shows no icon). */
static function string FrameOf(name Ability)
{
	local int i;

	i = default.Icons.Find('Ability', Ability);
	return i == INDEX_NONE ? "" : default.Icons[i].Frame;
}
