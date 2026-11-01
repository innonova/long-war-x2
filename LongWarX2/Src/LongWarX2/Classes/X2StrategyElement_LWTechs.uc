// Long War's techs as XCOM 2's (features/lw-research.md): a tech template each, from LWResearchRules,
// researched on XCOM 2's research screen at Long War's rate (XComGameState_LWStrategy.SyncResearch).
// Its points are Long War's (TechBalance days x 720); it requires Long War's techs (all of Requires,
// one of AnyOf) and items (one of InStores; the item it counts if it consumes none; a marker for a UFO
// type captured), XCOM 2's alternate requirements making the "one of"s; it costs Long War's alloys,
// elerium, weapon fragments and the items it consumes, in XCOM 2's own resources and the mod's items.
// What must have been held is asked as held now (XCOM 2 keeps no archive of what was held): the same
// whenever the tech consumes it. Its words are Long War's, written on the player's
// machine (lw-words.mjs makeTechWords). XCOM 2's own techs are hidden (HideXCom2Techs).
class X2StrategyElement_LWTechs extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWResearchRules.LWTechDef T;

	local LWGearRules.LWFoundryDef F;
	local X2TechTemplate Words;

	foreach class'LWResearchRules'.default.Techs(T)
		Templates.AddItem(TechTemplate(T));
	// The Foundry's projects carry their words here (LWEngineering.FoundryName); never researched.
	foreach class'LWGearRules'.default.Foundry(F)
	{
		`CREATE_X2TEMPLATE(class'X2TechTemplate', Words, class'LWGearRules'.static.FoundryTemplateFor(F.Id));
		Words.Requirements.SpecialRequirementsFn = Never;
		Words.PointsToComplete = 1;
		Templates.AddItem(Words);
	}
	return Templates;
}

static function X2TechTemplate TechTemplate(LWResearchRules.LWTechDef T)
{
	local X2TechTemplate Template;
	local StrategyRequirement Base, Option;
	local array<StrategyRequirement> Options;
	local ArtifactCost Resource;
	local int i, j, nTechs, nItems;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, class'LWResearchRules'.static.TemplateFor(T));
	Template.PointsToComplete = T.Days * class'LWResearchRules'.default.PointsPerDay;
	Template.strImage = T.Image;
	Template.SortingTier = 1;
	for (i = 0; i < T.Requires.Length; i++)
		Base.RequiredTechs.AddItem(class'LWResearchRules'.static.TemplateForId(T.Requires[i]));
	if (T.EverHad != '' && T.Items <= 0)
		Base.RequiredItems.AddItem(class'X2Item_LWArtifacts'.static.ItemFor(T.EverHad));
	if (T.CapturedUfo > 0)
		Base.RequiredItems.AddItem(class'X2Item_LWArtifacts'.static.CapturedMarker(T.CapturedUfo));
	// The "one of"s: a requirement for each tech of AnyOf with each item of InStores; the first is the
	// tech's requirements, the others XCOM 2's alternates.
	nTechs = Max(1, T.AnyOf.Length);
	nItems = Max(1, T.InStores.Length);
	for (i = 0; i < nTechs; i++)
	{
		for (j = 0; j < nItems; j++)
		{
			Option = Base;
			if (T.AnyOf.Length > 0)
				Option.RequiredTechs.AddItem(class'LWResearchRules'.static.TemplateForId(T.AnyOf[i]));
			if (T.InStores.Length > 0)
				Option.RequiredItems.AddItem(class'X2Item_LWArtifacts'.static.ItemFor(T.InStores[j]));
			Options.AddItem(Option);
		}
	}
	Template.Requirements = Options[0];
	for (i = 1; i < Options.Length; i++)
		Template.AlternateRequirements.AddItem(Options[i]);
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
	if (T.Fragments > 0)
	{
		Resource.ItemTemplateName = class'X2Item_LWArtifacts'.static.ItemFor('WeaponFragment');
		Resource.Quantity = T.Fragments;
		Template.Cost.ResourceCosts.AddItem(Resource);
	}
	if (T.EverHad != '' && T.Items > 0)
	{
		Resource.ItemTemplateName = class'X2Item_LWArtifacts'.static.ItemFor(T.EverHad);
		Resource.Quantity = T.Items;
		Template.Cost.ArtifactCosts.AddItem(Resource);
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
