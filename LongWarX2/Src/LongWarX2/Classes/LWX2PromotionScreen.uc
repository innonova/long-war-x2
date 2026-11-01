// Long War's promotion rules on XCOM 2's heroes' promotion screen (features/lw-classes.md):
// the whole tree is shown from the start, names and icons, ranks not reached yet greyed;
// a rank's three perks are equal, free, and exactly one may be chosen. The screen's look and
// its confirmation and purchase are XCOM 2's.
class LWX2PromotionScreen extends UIArmory_PromotionHero;

/** Whether one of the rank's perks has been chosen (Squaddie's are given). */
function bool HasChosenAtRank(XComGameState_Unit Unit, int Rank)
{
	local array<SoldierClassAbilityType> Tree;
	local SoldierClassAbilityType Slot;

	Tree = Unit.GetRankAbilities(Rank);
	foreach Tree(Slot)
		if (Slot.AbilityName != '' && Unit.HasSoldierAbility(Slot.AbilityName))
			return true;
	return false;
}

function int GetAbilityPointCost(int Rank, int Branch)
{
	return 0;
}

function bool CanPurchaseAbility(int Rank, int Branch, name AbilityName)
{
	local XComGameState_Unit Unit;

	Unit = GetUnit();
	return Rank < Unit.GetRank() && !HasChosenAtRank(Unit, Rank) && Unit.MeetsAbilityPrerequisites(AbilityName);
}

function bool UpdateAbilityIcons(out UIArmory_PromotionHeroColumn Column)
{
	local X2AbilityTemplateManager Templates;
	local X2AbilityTemplate Template;
	local array<SoldierClassAbilityType> Tree;
	local XComGameState_Unit Unit;
	local UIPromotionButtonState ButtonState;
	local string Fore, Back;
	local int i;
	local bool bReached, bChosen, bOwned;

	Templates = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Unit = GetUnit();
	Tree = Unit.GetRankAbilities(Column.Rank);
	bReached = Column.Rank < Unit.GetRank();
	bChosen = HasChosenAtRank(Unit, Column.Rank);
	for (i = 0; i < NUM_ABILITIES_PER_COLUMN; i++)
	{
		Template = i < Tree.Length ? Templates.FindAbilityTemplate(Tree[i].AbilityName) : none;
		if (Template == none)
		{
			Column.AbilityNames.AddItem('');
			continue;
		}
		if (Column.AbilityNames.Find(Template.DataName) == INDEX_NONE)
			Column.AbilityNames.AddItem(Template.DataName);
		bOwned = Unit.HasSoldierAbility(Template.DataName);
		ButtonState = bOwned ? eUIPromotionState_Equipped : eUIPromotionState_Normal;
		if (bOwned)
		{
			Fore = class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR;
			Back = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
		}
		else if (bReached && !bChosen)
		{
			// To choose now.
			Fore = class'UIUtilities_Colors'.const.PERK_HTML_COLOR;
			Back = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
		}
		else
		{
			// Not reached yet, or another perk of the rank was chosen: shown, greyed.
			Fore = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
			Back = class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR;
		}
		Column.AS_SetIconState(i, false, Template.IconImage, class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Template.LocFriendlyName), ButtonState, Fore, Back, false);
	}
	// Every column can be looked at; only a reached, unchosen rank can be bought (CanPurchaseAbility).
	Column.SetAvailable(true);
	return bChosen;
}

function PreviewAbility(int Rank, int Branch)
{
	local X2AbilityTemplate Template;
	local XComGameState_Unit Unit;
	local array<SoldierClassAbilityType> Tree;
	local string Cost, CostLabel, Points;

	Unit = GetUnit();
	Tree = Unit.GetRankAbilities(Rank);
	Template = Branch < Tree.Length ? class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Tree[Branch].AbilityName) : none;
	if (Template == none)
	{
		AS_SetDescriptionData("", "", "", "", "", "", "");
		return;
	}
	if (CanPurchaseAbility(Rank, Branch, Template.DataName))
	{
		CostLabel = m_strCostLabel;
		Cost = "0";
		Points = m_strAPLabel;
	}
	AS_SetDescriptionData(Template.IconImage, Template.LocFriendlyName, Template.HasLongDescription() ? Template.GetMyLongDescription(, Unit) : "", "", CostLabel, Cost, Points);
}
