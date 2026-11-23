// Long War's species by their own names on the field (features/lw-species-names.md). Each species fights as an XCOM 2
// template (LWStrategyRules.FightAs); XCOM 2 names an alien by its template alone (XComGameState_Unit.GetName), so each
// species gets a copy of its template of its own, LWX2Char_<species> (X2Character_LWSpecies), named as EW names it
// (EW's XLocalizedData.m_aCharacterName, written into LongWarX2.int on the player's machine by the setup: Names).
class LWX2Species extends Object;

/** EW's name for each species, by its ECharacter number (empty: the template's own name kept). */
var localized array<string> Names;

/**
 * Each species' copy named as EW names it, on every difficulty's (OnPostTemplatesCreated: the mod's localization is not
 * read yet when the templates are made, X2Character_LWSpecies).
 */
static function NameCopies()
{
	local X2CharacterTemplateManager Manager;
	local array<X2DataTemplate> Templates;
	local X2DataTemplate T;
	local LWStrategyRules.LWFightAs F;
	local int n;

	Manager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	foreach class'LWStrategyRules'.default.FightAs(F)
	{
		if (F.Char >= default.Names.Length)
			continue;
		Templates.Length = 0;
		Manager.FindDataTemplateAllDifficulties(CopyName(F.Char), Templates);
		foreach Templates(T)
			if (X2CharacterTemplate(T) != none)
			{
				if (default.Names[F.Char] != "")
					X2CharacterTemplate(T).strCharacterName = default.Names[F.Char];
				// (No XCOM 2 loot: Long War gives its own corpses and artifacts after the mission, by species; XCOM 2's
				// corpse of the template, "ADVENT Trooper Corpse dropped" for an EXALT soldier, is not Long War's.)
				X2CharacterTemplate(T).Loot.LootReferences.Length = 0;
				X2CharacterTemplate(T).TimedLoot.LootReferences.Length = 0;
				X2CharacterTemplate(T).VultureLoot.LootReferences.Length = 0;
				// (No XCOM 2 advisor's line on its first sighting, Shen or Tygan on "the Sectoid" at a pod's reveal: XCOM 2's
				// story, not Long War's; the click tests, 2026-11-23.)
				X2CharacterTemplate(T).SightedNarrativeMoments.Length = 0;
				n++;
			}
	}
	`log("LongWarX2: species:" @ n @ "templates named as Enemy Within's species (" $ default.Names.Length @ "names)", , 'LongWarX2');
}

/** A species' own template's name. */
static function name CopyName(int Char)
{
	return name("LWX2Char_" $ Char);
}

/** Whether a template is one of the species' copies; its species then. */
static function bool IsCopy(name Template, optional out int Char)
{
	if (Left(string(Template), 9) != "LWX2Char_")
		return false;
	Char = int(Mid(string(Template), 9));
	return Char > 0;
}

/** The XCOM 2 template a species fights as (FightAs), none when Long War gives it none. */
static function name SourceOf(int Char)
{
	local int k;

	k = class'LWStrategyRules'.default.FightAs.Find('Char', Char);
	return k == INDEX_NONE ? '' : class'LWStrategyRules'.default.FightAs[k].Template;
}

/** The template a species is spawned as: its copy where it was made, else the XCOM 2 template it fights as. */
static function name SpawnTemplate(int Char)
{
	if (class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(CopyName(Char)) != none)
		return CopyName(Char);
	return SourceOf(Char);
}

/**
 * The templates something given for an XCOM 2 template applies to (an EW body, an alien passive): with a species, that
 * species' copy (its template where it has none); without, the template and every species' copy made from it.
 */
static function array<name> TemplatesFor(name Template, optional int Species)
{
	local array<name> Out;
	local LWStrategyRules.LWFightAs F;

	if (Species > 0 && SourceOf(Species) == Template)
	{
		Out.AddItem(CopyName(Species));
		return Out;
	}
	Out.AddItem(Template);
	foreach class'LWStrategyRules'.default.FightAs(F)
		if (F.Template == Template && Out.Find(CopyName(F.Char)) == INDEX_NONE)
			Out.AddItem(CopyName(F.Char));
	return Out;
}
