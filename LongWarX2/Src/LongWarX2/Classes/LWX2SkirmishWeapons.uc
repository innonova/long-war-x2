// War of the Chosen's Skirmish Mode (the Legacy Hub's) for Long War's classes (features/lw-classes.md):
// it lists every soldier class, but arms a soldier from per-class weapon tables built in code
// (X2ChallengePrimaryWeaponSelectors, TLEPrimaryRandom and the secondary one); a class it does not
// know gets no weapons. Long War's classes are added, each with the weapons of the XCOM 2 class it
// carries the same arms as. Config: the class and its XCOM 2 counterpart for each table.
class LWX2SkirmishWeapons extends Object config(LWClasses);

struct LWSkirmishArms
{
	var name ClassName;
	var name PrimaryLike;
	var name SecondaryLike;
};

var config array<LWSkirmishArms> Arms;

static function AddClasses()
{
	local X2ChallengeTemplateManager Challenges;
	local X2ChallengePrimaryWeapon Primary;
	local X2ChallengeSecondaryWeapon Secondary;
	local LWSkirmishArms A;
	local int k, Added;

	Challenges = class'X2ChallengeTemplateManager'.static.GetChallengeTemplateManager();
	Primary = X2ChallengePrimaryWeapon(Challenges.FindChallengeTemplate('TLEPrimaryRandom'));
	Secondary = X2ChallengeSecondaryWeapon(Challenges.FindChallengeTemplate('TLESecondaryRandom'));
	foreach default.Arms(A)
	{
		if (Primary != none && Primary.PrimaryWeapons.Find('SoldierClassName', A.ClassName) == INDEX_NONE)
		{
			k = Primary.PrimaryWeapons.Find('SoldierClassName', A.PrimaryLike);
			if (k != INDEX_NONE)
			{
				Primary.PrimaryWeapons.AddItem(Primary.PrimaryWeapons[k]);
				Primary.PrimaryWeapons[Primary.PrimaryWeapons.Length - 1].SoldierClassName = A.ClassName;
				Added++;
			}
		}
		if (Secondary != none && Secondary.SecondaryWeapons.Find('SoldierClassName', A.ClassName) == INDEX_NONE)
		{
			k = Secondary.SecondaryWeapons.Find('SoldierClassName', A.SecondaryLike);
			if (k != INDEX_NONE)
			{
				Secondary.SecondaryWeapons.AddItem(Secondary.SecondaryWeapons[k]);
				Secondary.SecondaryWeapons[Secondary.SecondaryWeapons.Length - 1].SoldierClassName = A.ClassName;
			}
		}
	}
	`log("LongWarX2: skirmish weapons for" @ Added @ "of Long War's classes", , 'LongWarX2');
}
