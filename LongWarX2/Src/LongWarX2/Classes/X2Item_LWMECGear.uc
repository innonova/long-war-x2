// Long War's MEC suits and MEC weapons as XCOM 2's (features/lw-shivs-mecs.md, phase 3): Long War's numbers (LWMECs, from its
// config). A suit is an armour only MEC troopers wear (lw_mec), its HP, defence, mobility and will a stat ability with the
// immunities to poison and fire (eAP_MEC: Long War's MEC suits' properties); a MEC weapon is a primary weapon only MECs carry,
// the ADVENT MEC's gun as its look. The first suit and the Minigun come with every MEC; the rest engineering builds.
class X2Item_LWMECGear extends X2Item dependson(LWMECs);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWMECs.LWMECSuit S;
	local LWMECs.LWMECWeapon W;

	foreach class'LWMECs'.default.Suits(S)
		Templates.AddItem(SuitTemplate(S));
	foreach class'LWMECs'.default.Weapons(W)
		Templates.AddItem(WeaponTemplate(W));
	if (class'LWMECs'.default.KineticStrike.Item != 0)
		Templates.AddItem(KineticTemplate(class'LWMECs'.default.KineticStrike));
	return Templates;
}

/** The Kinetic Strike Module: a subsystem (a utility slot, MEC classes only: lw_mec_kinetic) whose strike is XCOM 2's
 *  sword slice (move and strike an adjacent enemy) with Long War's damage (12). */
static function X2WeaponTemplate KineticTemplate(LWMECs.LWMECWeapon W)
{
	local X2WeaponTemplate Template;
	local WeaponDamageValue Damage;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'LWMEC_KineticStrike');
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'lw_mec_kinetic';
	Template.WeaponTech = 'conventional';
	Template.InventorySlot = eInvSlot_Utility;
	Template.StowedLocation = eSlot_None;
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventMecGun";
	Damage.Damage = W.Damage;
	Damage.Spread = 1;
	Damage.Crit = (W.Damage + 1) / 2;
	Template.BaseDamage = Damage;
	Template.iRange = 0;
	Template.iRadius = 1;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;
	Template.iEnvironmentDamage = W.Environment;
	Template.NumUpgradeSlots = 0;
	Template.Abilities.AddItem('SwordSlice');
	Template.DamageTypeTemplateName = 'Melee';
	Template.CanBeBuilt = false;
	return Template;
}

static function X2ArmorTemplate SuitTemplate(LWMECs.LWMECSuit S)
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, class'LWMECs'.static.SuitTemplate(S.Item));
	Template.ItemCat = 'armor';
	Template.ArmorCat = 'lw_mec';
	Template.ArmorTechCat = 'conventional';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Kevlar_Armor";
	Template.Tier = class'LWMECs'.default.Suits.Find('Item', S.Item);
	Template.Abilities.AddItem(class'X2Ability_LWMECSuit'.static.StatsFor(S.Item));
	// (A second utility slot for a subsystem, as Long War's suits all carry more than one item.)
	Template.bAddsUtilitySlot = S.LargeItems + S.SmallItems >= 2;
	Template.StartingItem = S.Item == class'LWMECs'.default.Suits[0].Item;
	Template.bInfiniteItem = Template.StartingItem;
	Template.CanBeBuilt = false;
	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, S.HP, true);
	if (S.Mobility != 0)
		Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, S.Mobility);
	if (S.Defense != 0)
		Template.SetUIStatMarkup(class'XLocalizedData'.default.DefenseLabel, eStat_Defense, S.Defense);
	if (S.Will != 0)
		Template.SetUIStatMarkup(class'XLocalizedData'.default.WillLabel, eStat_Will, S.Will);
	return Template;
}

static function X2WeaponTemplate WeaponTemplate(LWMECs.LWMECWeapon W)
{
	local X2WeaponTemplate Template;
	local WeaponDamageValue Damage;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, class'LWMECs'.static.WeaponTemplate(W.Item));
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'lw_mec';
	Template.WeaponTech = 'conventional';
	Template.WeaponPanelImage = "_ConventionalRifle";
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventMecGun";
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Tier = class'LWMECs'.default.Weapons.Find('Item', W.Item);
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
	Template.StartingItem = W.Item == class'LWMECs'.default.Weapons[0].Item;
	Template.bInfiniteItem = Template.StartingItem;
	Template.CanBeBuilt = false;
	return Template;
}
