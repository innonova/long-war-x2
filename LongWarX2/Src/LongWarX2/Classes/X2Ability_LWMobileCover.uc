// Long War's mobile cover (features/lw-shivs-mecs.md): the Alloy SHIV is high cover for the soldiers beside it (Long War's
// XGUnit.StartProvidingCover: its pawn counted as cover, the tiles round it built again; the same code serves EW's One For
// All, a perk no tree of Long War's MECs has). XCOM 2 builds cover from the level's geometry only, so here it is a rule on the shot instead: a soldier on a
// tile beside such a unit (not diagonally), on the side the shot comes from, is as in high cover against it
// (X2Effect_LWMobileCover: XCOM 2's high cover bonus less the cover it has, and not flanked) and takes high cover's
// damage reduction (X2Ability_LWDamageReduction.CoverReduction).
class X2Ability_LWMobileCover extends X2Ability;

/** The Alloy SHIV's character (the bodies that are cover). */
var name CoverTemplate;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(MobileCover());
	return Templates;
}

static function X2AbilityTemplate MobileCover()
{
	local X2AbilityTemplate Template;
	local X2Effect_LWMobileCover Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_MobileCover');
	// (A rule's carrier, not a perk: not listed among the soldier's abilities.)
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_LWMobileCover';
	Effect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(Effect);
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

/** On the soldiers' character templates (those that take cover). */
static function AddAbilities()
{
	local X2CharacterTemplateManager Manager;
	local X2DataTemplate T;
	local array<X2DataTemplate> Templates;
	local X2CharacterTemplate C;

	Manager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	foreach Manager.IterateTemplates(T, none)
	{
		Templates.Length = 0;
		Manager.FindDataTemplateAllDifficulties(T.DataName, Templates);
		foreach Templates(T)
		{
			C = X2CharacterTemplate(T);
			if (C != none && C.bIsSoldier && C.bCanTakeCover && C.Abilities.Find('LWX2_MobileCover') == INDEX_NONE)
				C.Abilities.AddItem('LWX2_MobileCover');
		}
	}
}

/** Whether a unit is cover for the soldiers beside it: the Alloy SHIV, alive and on the field. */
static function bool IsCover(XComGameState_Unit Unit)
{
	return Unit != none && Unit.IsAlive() && !Unit.bRemovedFromPlay && Unit.GetMyTemplateName() == default.CoverTemplate;
}

/** The unit that is cover for Target against a shot from From: on a tile beside Target's (north, south, east or west, the
 *  same floor), of its team, on the side the shot comes from (towards the shooter, as cover faces). None if none. */
static function XComGameState_Unit CoverFor(XComGameState_Unit Target, vector From)
{
	local XComGameState_Unit Unit;
	local TTile T, U;
	local vector ToCover, ToShooter;

	if (Target == none || !Target.CanTakeCover())
		return none;
	T = Target.TileLocation;
	ToShooter = From - `XWORLD.GetPositionFromTileCoordinates(T);
	ToShooter.Z = 0;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.ObjectID == Target.ObjectID || Unit.GetTeam() != Target.GetTeam() || !IsCover(Unit))
			continue;
		U = Unit.TileLocation;
		if (U.Z != T.Z || Abs(U.X - T.X) + Abs(U.Y - T.Y) != 1)
			continue;
		ToCover = `XWORLD.GetPositionFromTileCoordinates(U) - `XWORLD.GetPositionFromTileCoordinates(T);
		ToCover.Z = 0;
		if ((ToCover dot ToShooter) > 0)
			return Unit;
	}
	return none;
}

/** The cover the attacker sees on the target (XCOM 2's record of the pair, as its to-hit calculation reads it; none
 *  flanked), and high where mobile cover stands between them. */
static function ECoverType CoverAgainst(XComGameState_Unit Target, XComGameState_Unit Attacker, out ECoverType Seen)
{
	local GameRulesCache_VisibilityInfo VisInfo;

	Seen = CT_None;
	if (Attacker != none && `TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo))
		Seen = VisInfo.TargetCover;
	if (Attacker != none && CoverFor(Target, `XWORLD.GetPositionFromTileCoordinates(Attacker.TileLocation)) != none)
		return CT_Standing;
	return Seen;
}

defaultproperties
{
	CoverTemplate = "LWSHIV_Alloy"
}
