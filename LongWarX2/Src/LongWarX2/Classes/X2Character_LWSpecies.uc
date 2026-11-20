// Each Long War species' own template (LWX2Species): the XCOM 2 template it fights as, made again by XCOM 2's own function
// (so its stats, abilities, pawn, loot and behaviour are that template's), renamed LWX2Char_<species> and named as EW
// names the species.
class X2Character_LWSpecies extends X2Character;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWStrategyRules.LWFightAs F;
	local X2CharacterTemplate T, Src;

	foreach class'LWStrategyRules'.default.FightAs(F)
	{
		Src = Source(F.Template);
		if (Src == none)
			continue;
		// (Copied into an object of its own name: XCOM 2's function makes its template under the template's own object
		// name, so what it returns is XCOM 2's own object made again; renamed, XCOM 2's own ADVENT troopers had become
		// EXALT, and two species of one template, the Sectoid and its Commander, had been the same object.)
		T = new(None, string(class'LWX2Species'.static.CopyName(F.Char))) class'X2CharacterTemplate'(Src);
		T.SetTemplateName(class'LWX2Species'.static.CopyName(F.Char));
		if (F.Char < class'LWX2Species'.default.Names.Length && class'LWX2Species'.default.Names[F.Char] != "")
			T.strCharacterName = class'LWX2Species'.default.Names[F.Char];
		Templates.AddItem(T);
	}
	return Templates;
}

/** XCOM 2's template of that name, made afresh by its own function; none for one not listed. */
static function X2CharacterTemplate Source(name Template)
{
	switch (Template)
	{
		case 'Sectoid': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Sectoid();
		case 'Archon': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Archon();
		case 'Viper': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Viper();
		case 'Muton': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Muton();
		case 'Gatekeeper': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Gatekeeper();
		case 'Andromedon': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Andromedon();
		case 'Chryssalid': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Chryssalid();
		case 'PsiZombie': return class'X2Character_DefaultCharacters'.static.CreateTemplate_PsiZombie();
		case 'Berserker': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Berserker();
		case 'Sectopod': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Sectopod();
		case 'Faceless': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Faceless();
		case 'Cyberus':
		case 'Codex': return class'X2Character_DefaultCharacters'.static.CreateTemplate_Cyberus();
		case 'AdvMEC_M1': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvMEC_M1();
		case 'AdvMEC_M2': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvMEC_M2();
		case 'AdvPsiWitchM2': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvPsiWitchM2();
		case 'AdvPsiWitchM3': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvPsiWitchM3();
		case 'AdvTrooperM1': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvTrooperM1();
		case 'AdvTrooperM3': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvTrooperM3();
		case 'AdvCaptainM1': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvCaptainM1();
		case 'AdvCaptainM3': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvCaptainM3();
		case 'AdvShieldBearerM2': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvShieldBearerM2();
		case 'AdvShieldBearerM3': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvShieldBearerM3();
		case 'AdvStunLancerM1': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvStunLancerM1();
		case 'AdvStunLancerM3': return class'X2Character_DefaultCharacters'.static.CreateTemplate_AdvStunLancerM3();
	}
	return none;
}
