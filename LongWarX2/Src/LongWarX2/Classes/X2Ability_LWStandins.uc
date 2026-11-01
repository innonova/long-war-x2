// Long War's perks that XCOM 2 has no ability for yet, as passive abilities with Long War's
// name, words and an icon but no effect, so the classes' trees are whole
// (features/lw-classes.md). The list is generated (scripts/classes-config.mjs); each
// becomes a real ability in later rounds.
class X2Ability_LWStandins extends X2Ability config(LWClasses);

struct LWStandin
{
	var name Name;
	var string Icon;
};

var config array<LWStandin> Standins;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWStandin S;

	foreach default.Standins(S)
		Templates.AddItem(PurePassive(S.Name, S.Icon, false, 'eAbilitySource_Perk', true));
	return Templates;
}
