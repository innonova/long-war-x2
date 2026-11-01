// Long War's soldier weapons as XCOM 2's (features/lw-gear.md): a weapon template each, from LWGearRules.
// Long War's numbers: damage (spread 1, a critical hit half again), crit chance, aim, shots between
// reloads (pistols: unlimited, as XCOM 2's), damage to cover; its category says which of Long War's
// classes may carry it (their AllowedWeapons, classes-config.mjs); its shots as XCOM 2's rifles, sniper
// rifles (a move or a shot) and pistols take them; no upgrade slots (Long War has none). Its look is an
// XCOM 2 weapon's, copied once every template is built (CopyLooks). The starting kit is unlimited;
// the rest waits for engineering. Its words are Long War's (lw-words.mjs makeWeaponWords).
class X2Item_LWWeapons extends X2Item;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWGearRules.LWWeaponDef W;

	foreach class'LWGearRules'.default.Weapons(W)
		Templates.AddItem(WeaponTemplate(W));
	return Templates;
}

static function X2WeaponTemplate WeaponTemplate(LWGearRules.LWWeaponDef W)
{
	local X2WeaponTemplate Template;
	local WeaponDamageValue Damage;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, class'LWGearRules'.static.TemplateFor(W.Item));
	Template.ItemCat = 'weapon';
	Template.WeaponCat = W.Category;
	Template.WeaponTech = W.Tech;
	Template.Tier = class'LWGearRules'.default.Weapons.Find('Item', W.Item);
	Template.InventorySlot = W.Slot;
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
	switch (W.Range)
	{
	case 'SHORT': Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.SHORT_CONVENTIONAL_RANGE; break;
	case 'LONG': Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.LONG_CONVENTIONAL_RANGE; break;
	default: Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.MEDIUM_CONVENTIONAL_RANGE;
	}
	switch (W.Kind)
	{
	case 'Pistol':
		Template.InfiniteAmmo = true;
		Template.OverwatchActionPoint = class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint;
		Template.Abilities.AddItem('PistolOverwatch');
		Template.Abilities.AddItem('PistolOverwatchShot');
		Template.Abilities.AddItem('PistolReturnFire');
		Template.Abilities.AddItem('HotLoadAmmo');
		Template.Abilities.AddItem('Reload');
		break;
	case 'Sniper':
		Template.iTypicalActionCost = 2;
		Template.bIsLargeWeapon = true;
		Template.Abilities.AddItem('SniperStandardFire');
		Template.Abilities.AddItem('SniperRifleOverwatch');
		Template.Abilities.AddItem('OverwatchShot');
		Template.Abilities.AddItem('Reload');
		Template.Abilities.AddItem('HotLoadAmmo');
		break;
	default:
		Template.Abilities.AddItem('StandardShot');
		Template.Abilities.AddItem('Overwatch');
		Template.Abilities.AddItem('OverwatchShot');
		Template.Abilities.AddItem('Reload');
		Template.Abilities.AddItem('HotLoadAmmo');
	}
	Template.StartingItem = W.Infinite;
	Template.bInfiniteItem = W.Infinite;
	Template.CanBeBuilt = false;
	return Template;
}

/** Every Long War weapon takes its look from its XCOM 2 weapon (OnPostTemplatesCreated: all of XCOM 2's are built then). */
static function CopyLooks()
{
	local X2ItemTemplateManager Manager;
	local array<X2DataTemplate> Variants;
	local X2DataTemplate Data;
	local X2WeaponTemplate Mine, Look;
	local LWGearRules.LWWeaponDef W;
	local int Copied;

	Manager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach class'LWGearRules'.default.Weapons(W)
	{
		Look = X2WeaponTemplate(Manager.FindItemTemplate(W.Look));
		if (Look == none)
		{
			`log("LongWarX2: gear: no XCOM 2 weapon" @ W.Look @ "for" @ W.Item, , 'LongWarX2');
			continue;
		}
		Manager.FindDataTemplateAllDifficulties(class'LWGearRules'.static.TemplateFor(W.Item), Variants);
		foreach Variants(Data)
		{
			Mine = X2WeaponTemplate(Data);
			Mine.GameArchetype = Look.GameArchetype;
			Mine.DefaultAttachments = Look.DefaultAttachments;
			Mine.strImage = Look.strImage;
			Mine.WeaponPanelImage = Look.WeaponPanelImage;
			Mine.EquipSound = Look.EquipSound;
			Mine.UIArmoryCameraPointTag = Look.UIArmoryCameraPointTag;
			Mine.DamageTypeTemplateName = Look.DamageTypeTemplateName;
			Mine.iPhysicsImpulse = Look.iPhysicsImpulse;
			Mine.StowedLocation = Look.StowedLocation;
		}
		Copied++;
	}
	`log("LongWarX2: gear:" @ Copied @ "of" @ class'LWGearRules'.default.Weapons.Length @ "weapons look like XCOM 2's", , 'LongWarX2');
}
