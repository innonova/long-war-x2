// Long War's aliens' passives (features/lw-aliens.md): their damage bonus from the aliens' research, given to every alien
// template Long War's species fight as (LWAlienStats.AddAbilities).
class X2Ability_LWAliens extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AlienDamage());
	return Templates;
}

static function X2AbilityTemplate AlienDamage()
{
	local X2AbilityTemplate Template;
	local X2Effect_LWAlienDamage Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_AlienDamage');
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_LWAlienDamage';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.EffectName = 'LWX2_AlienDamage';
	Template.AddTargetEffect(Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}
