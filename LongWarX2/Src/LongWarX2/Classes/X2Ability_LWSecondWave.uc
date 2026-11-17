// The carrier of Long War's tactical second-wave options (X2Effect_LWSecondWave), on every character as the battle begins.
class X2Ability_LWSecondWave extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(SecondWave());
	return Templates;
}

static function X2AbilityTemplate SecondWave()
{
	local X2AbilityTemplate Template;
	local X2Effect_LWSecondWave Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_SecondWave');
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_LWSecondWave';
	Effect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(Effect);
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

/** On every character template; and every shooter's flanking crit Long War's (FLANKING_CRIT_BONUS, 50, for everyone:
 *  XGTacticalGameCore.GetFlankingCritBonus), where XCOM 2 gives its soldiers 40 and its aliens 33. */
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
			if (C == none)
				continue;
			if (C.Abilities.Find('LWX2_SecondWave') == INDEX_NONE)
				C.Abilities.AddItem('LWX2_SecondWave');
			if (C.CharacterBaseStats[eStat_FlankingCritChance] > 0 && class'X2Effect_LWSecondWave'.default.FlankCrit > 0)
				C.CharacterBaseStats[eStat_FlankingCritChance] = class'X2Effect_LWSecondWave'.default.FlankCrit;
		}
	}
}
