// Long War's SHIV weapons as XCOM 2's (features/lw-shivs-mecs.md): Long War's numbers (Weapons=), the ADVENT MEC's gun as
// their look, a category only SHIVs carry (lw_shiv). The Minigun comes with every SHIV.
class X2Item_LWSHIVWeapons extends X2Item dependson(LWSHIVs);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWSHIVs.LWSHIVWeapon W;

	foreach class'LWSHIVs'.default.Weapons(W)
		Templates.AddItem(WeaponTemplate(W));
	return Templates;
}

static function X2WeaponTemplate WeaponTemplate(LWSHIVs.LWSHIVWeapon W)
{
	local X2WeaponTemplate Template;
	local WeaponDamageValue Damage;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, W.Template);
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'lw_shiv';
	Template.WeaponTech = 'conventional';
	Template.WeaponPanelImage = "_ConventionalRifle";
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventMecGun";
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Damage.Damage = W.Damage;
	Damage.Spread = 1;
	Damage.Crit = (W.Damage + 1) / 2;
	Template.BaseDamage = Damage;
	Template.Aim = W.Aim;
	Template.CritChance = W.Crit;
	Template.iClipSize = Max(1, W.Ammo);
	Template.iSoundRange = 27;
	Template.iEnvironmentDamage = W.Environment;
	Template.NumUpgradeSlots = 0;
	Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.MEDIUM_CONVENTIONAL_RANGE;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.GameArchetype = "WP_AdvMec_Gun.WP_AdvMecGun";
	Template.DamageTypeTemplateName = 'Projectile_Conventional';
	Template.StartingItem = W.Template == class'LWSHIVs'.default.Weapons[0].Template;
	Template.bInfiniteItem = Template.StartingItem;
	Template.CanBeBuilt = false;
	return Template;
}
