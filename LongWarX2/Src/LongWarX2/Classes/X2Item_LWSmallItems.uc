// Long War's small items and the Rocketeer's rocket launcher as XCOM 2's (features/lw-gear.md, phase 5): an item
// template each, from LWGearRules.SmallItems. Grenades, the medikit, the battle scanner and the mimic beacon take
// an XCOM 2 item's abilities and effects (CopyLooks, once every template is built), with Long War's damage,
// radius, range and one charge an item (XGUnit.UpdateItemCharges); the launcher is the Rocketeer's secondary
// weapon, XCOM 2's rocket launcher with Long War's numbers; the passive items are a stat ability each
// (X2Ability_LWSmallItems). Those Long War holds without limit are unlimited. Words: Long War's (lw-words.mjs).
class X2Item_LWSmallItems extends X2Item dependson(LWGearRules);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWGearRules.LWSmallDef D;

	foreach class'LWGearRules'.default.SmallItems(D)
		Templates.AddItem(SmallTemplate(D));
	return Templates;
}

/** XCOM 2's battle scanner and mimic beacon are weapons, its grenades grenades. */
static function bool IsWeaponLook(name Look)
{
	return Look == 'BattleScanner' || Look == 'MimicBeacon' || Look == 'Medikit' || Look == 'RocketLauncher';
}

static function X2ItemTemplate SmallTemplate(LWGearRules.LWSmallDef D)
{
	local X2GrenadeTemplate Grenade;
	local X2WeaponTemplate Weapon;
	local X2EquipmentTemplate Item;
	local WeaponDamageValue Damage;

	Damage.Damage = D.Damage;
	Damage.Pierce = D.Pierce;
	if (D.Kind == 'Passive' || D.Kind == 'Rocket')
	{
		`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Item, D.Template);
		Item.ItemCat = 'utility';
		Item.InventorySlot = eInvSlot_Utility;
		Item.Abilities.AddItem(class'X2Ability_LWSmallItems'.static.StatsFor(D.Item));
		if (D.Aim != 0)
			Item.SetUIStatMarkup(class'XLocalizedData'.default.AimLabel, eStat_Offense, D.Aim);
		if (D.Crit != 0)
			Item.SetUIStatMarkup(class'XLocalizedData'.default.CritChanceLabel, eStat_CritChance, D.Crit);
		if (D.HP != 0)
			Item.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, D.HP);
	}
	else if (D.Kind == 'Grenade' && !IsWeaponLook(D.Look))
	{
		`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Grenade, D.Template);
		Grenade.ItemCat = 'grenade';
		Grenade.WeaponCat = 'grenade';
		Grenade.InventorySlot = eInvSlot_Utility;
		Grenade.BaseDamage = Damage;
		Grenade.iRadius = D.Radius;
		Grenade.iRange = D.Range;
		Grenade.iEnvironmentDamage = D.Environment;
		Grenade.iClipSize = 1;
		Item = Grenade;
	}
	else
	{
		`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Weapon, D.Template);
		Weapon.ItemCat = D.Kind == 'Launcher' ? 'weapon' : (D.Kind == 'Medikit' ? 'heal' : 'utility');
		Weapon.WeaponCat = D.Kind == 'Launcher' ? 'lw_rocketeer_engineer' : (D.Kind == 'Medikit' ? 'medikit' : 'utility');
		Weapon.InventorySlot = D.Kind == 'Launcher' ? eInvSlot_SecondaryWeapon : eInvSlot_Utility;
		Weapon.BaseDamage = Damage;
		Weapon.iRadius = D.Radius;
		Weapon.iRange = D.Range;
		Weapon.iEnvironmentDamage = D.Environment;
		Weapon.iClipSize = 1;
		Weapon.InfiniteAmmo = false;
		Item = Weapon;
	}
	Item.StartingItem = D.Infinite;
	Item.bInfiniteItem = D.Infinite;
	Item.CanBeBuilt = false;
	return Item;
}

/** Every small item takes its XCOM 2 item's abilities, effects and look (OnPostTemplatesCreated). */
static function CopyLooks()
{
	local X2ItemTemplateManager Manager;
	local array<X2DataTemplate> Variants;
	local X2DataTemplate Data;
	local X2ItemTemplate Look;
	local LWGearRules.LWSmallDef D;
	local int Copied;

	Manager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach class'LWGearRules'.default.SmallItems(D)
	{
		Look = Manager.FindItemTemplate(D.Look);
		if (Look == none)
		{
			`log("LongWarX2: gear: no XCOM 2 item" @ D.Look @ "for small item" @ D.Item, , 'LongWarX2');
			continue;
		}
		Manager.FindDataTemplateAllDifficulties(D.Template, Variants);
		foreach Variants(Data)
			CopyLook(X2ItemTemplate(Data), Look, D);
		Copied++;
	}
	`log("LongWarX2: gear:" @ Copied @ "of" @ class'LWGearRules'.default.SmallItems.Length @ "small items look like XCOM 2's", , 'LongWarX2');
}

static function CopyLook(X2ItemTemplate Mine, X2ItemTemplate Look, LWGearRules.LWSmallDef D)
{
	local X2GrenadeTemplate MyGrenade, LookGrenade;
	local X2WeaponTemplate MyWeapon, LookWeapon;
	local X2EquipmentTemplate MyItem, LookItem;
	local name A;

	Mine.strImage = Look.strImage;
	MyItem = X2EquipmentTemplate(Mine);
	LookItem = X2EquipmentTemplate(Look);
	if (MyItem != none && LookItem != none)
	{
		MyItem.GameArchetype = LookItem.GameArchetype;
		MyItem.EquipSound = LookItem.EquipSound;
		// The passive items are stats of their own; the rest act as XCOM 2's item does (not as the SPARK's).
		if (D.Kind != 'Passive' && D.Kind != 'Rocket')
			foreach LookItem.Abilities(A)
				if (MyItem.Abilities.Find(A) == INDEX_NONE && Left(string(A), 5) != "Spark")
					MyItem.Abilities.AddItem(A);
	}
	MyWeapon = X2WeaponTemplate(Mine);
	LookWeapon = X2WeaponTemplate(Look);
	if (MyWeapon != none && LookWeapon != none && D.Kind != 'Passive' && D.Kind != 'Rocket')
	{
		MyWeapon.DamageTypeTemplateName = LookWeapon.DamageTypeTemplateName;
		MyWeapon.iSoundRange = LookWeapon.iSoundRange;
		MyWeapon.WeaponTech = LookWeapon.WeaponTech;
		MyWeapon.iTypicalActionCost = LookWeapon.iTypicalActionCost;
		MyWeapon.bMergeAmmo = LookWeapon.bMergeAmmo;
		MyWeapon.HideIfResearched = LookWeapon.HideIfResearched;
		MyWeapon.BonusWeaponEffects = LookWeapon.BonusWeaponEffects;
		MyWeapon.UIArmoryCameraPointTag = LookWeapon.UIArmoryCameraPointTag;
		MyWeapon.bCanBeDodged = LookWeapon.bCanBeDodged;
		MyWeapon.DefaultAttachments = LookWeapon.DefaultAttachments;
		MyWeapon.StowedLocation = LookWeapon.StowedLocation;
		if (D.Kind == 'Launcher')
			MyWeapon.WeaponPanelImage = LookWeapon.WeaponPanelImage;
	}
	MyGrenade = X2GrenadeTemplate(Mine);
	LookGrenade = X2GrenadeTemplate(Look);
	if (MyGrenade != none && LookGrenade != none)
	{
		MyGrenade.ThrownGrenadeEffects = LookGrenade.ThrownGrenadeEffects;
		MyGrenade.LaunchedGrenadeEffects = LookGrenade.LaunchedGrenadeEffects;
		MyGrenade.OnThrowBarkSoundCue = LookGrenade.OnThrowBarkSoundCue;
	}
}
