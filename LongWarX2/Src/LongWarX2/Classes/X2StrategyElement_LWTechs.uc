// Long War's techs as XCOM 2's (features/lw-research.md): a tech template each, from LWResearchRules,
// researched on XCOM 2's research screen at Long War's rate (XComGameState_LWStrategy.SyncResearch).
// Its points are Long War's (TechBalance days x 720); it requires Long War's techs (all of Requires,
// one of AnyOf: XCOM 2's alternate requirements); it costs Long War's alloys and elerium in XCOM 2's
// own resources. Not yet: weapon fragments, the items a tech consumes, and what must have been held
// or captured first: missions bring no loot yet. Its words are Long War's, written on the player's
// machine (lw-words.mjs makeTechWords). XCOM 2's own techs are hidden (HideXCom2Techs).
class X2StrategyElement_LWTechs extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWResearchRules.LWTechDef T;

	foreach class'LWResearchRules'.default.Techs(T)
		Templates.AddItem(TechTemplate(T));
	return Templates;
}

static function X2TechTemplate TechTemplate(LWResearchRules.LWTechDef T)
{
	local X2TechTemplate Template;
	local StrategyRequirement Alternate;
	local ArtifactCost Resource;
	local int i;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, class'LWResearchRules'.static.TemplateFor(T));
	Template.PointsToComplete = T.Days * class'LWResearchRules'.default.PointsPerDay;
	Template.strImage = T.Image;
	Template.SortingTier = 1;
	for (i = 0; i < T.Requires.Length; i++)
		Template.Requirements.RequiredTechs.AddItem(class'LWResearchRules'.static.TemplateForId(T.Requires[i]));
	// One of AnyOf as well: the first in the requirements, each other as an alternative with the same rest.
	for (i = 0; i < T.AnyOf.Length; i++)
	{
		if (i == 0)
			continue;
		Alternate = Template.Requirements;
		Alternate.RequiredTechs.AddItem(class'LWResearchRules'.static.TemplateForId(T.AnyOf[i]));
		Template.AlternateRequirements.AddItem(Alternate);
	}
	if (T.AnyOf.Length > 0)
		Template.Requirements.RequiredTechs.AddItem(class'LWResearchRules'.static.TemplateForId(T.AnyOf[0]));
	if (T.Alloys > 0)
	{
		Resource.ItemTemplateName = 'AlienAlloy';
		Resource.Quantity = T.Alloys;
		Template.Cost.ResourceCosts.AddItem(Resource);
	}
	if (T.Elerium > 0)
	{
		Resource.ItemTemplateName = 'EleriumDust';
		Resource.Quantity = T.Elerium;
		Template.Cost.ResourceCosts.AddItem(Resource);
	}
	if (T.GrantsCredit > 0)
		Template.ResearchCompletedFn = CreditGranted;
	return Template;
}

/** An interrogation done: its research credit held from now on (Long War's XGFacility_Labs credits). */
static function CreditGranted(XComGameState NewGameState, XComGameState_Tech TechState)
{
	local LWResearchRules.LWTechDef T;

	foreach class'LWResearchRules'.default.Techs(T)
	{
		if (class'LWResearchRules'.static.TemplateFor(T) == TechState.GetMyTemplateName())
		{
			class'XComGameState_LWStrategy'.static.CreditHeld(NewGameState, T.GrantsCredit);
			return;
		}
	}
}

/** XCOM 2's own techs never available: Long War's replace them (OnPostTemplatesCreated). */
static function HideXCom2Techs()
{
	local X2StrategyElementTemplateManager Manager;
	local array<X2DataTemplate> Variants;
	local X2DataTemplate Data, Template;
	local X2TechTemplate Tech;
	local int Hidden;

	Manager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	foreach Manager.IterateTemplates(Template, none)
	{
		Tech = X2TechTemplate(Template);
		if (Tech == none || Left(string(Tech.DataName), 7) == "LWTech_")
			continue;
		Manager.FindDataTemplateAllDifficulties(Tech.DataName, Variants);
		foreach Variants(Data)
		{
			Tech = X2TechTemplate(Data);
			Tech.Requirements.SpecialRequirementsFn = Never;
			Tech.AlternateRequirements.Length = 0;
		}
		Hidden++;
	}
	`log("LongWarX2: research: XCOM 2's" @ Hidden @ "techs hidden," @ class'LWResearchRules'.default.Techs.Length @ "of Long War's", , 'LongWarX2');
}

static function bool Never()
{
	return false;
}
