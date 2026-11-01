// Long War's item charges (XGUnit.UpdateItemCharges), set at a mission's start for each small item a soldier carries
// (XCOM 2 merges a soldier's items of a kind into one, its charges their sum): one an item, and the perks':
// - Grenadier: HE, Alien and AP grenades x2;
// - Smoke and Mirrors: flashbangs, chem grenades and mimic beacons x2; +1 smoke grenade and battle scanner an item;
// - Packmaster (Long War's Deep Pockets): +1 a charge an item for grenades, beacons, the arc thrower, smoke and
//   the scanner, and the medikit;
// - Repair: +2 arc thrower charges an item;
// - Smoke Bomb (LW_SmokeGrenade) and Battle Scanner: +1 smoke, +2 scans (Long War gives them without an item: here
//   only to a soldier who carries one, APPROXIMATION);
// - Shock and Awe (Long War's Rocketeer perk): a second rocket.
// - Savior: +2 medikit charges (Long War gives them without an item: here only to a soldier who carries one).
// Carried by every Long War armour's stat ability (X2Ability_LWArmorStats), so every Long War soldier has it.
class X2Effect_LWCharges extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Unit;
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item, Holder;
	local array<name> Done;
	local int n, Charges;

	Unit = XComGameState_Unit(kNewTargetState);
	if (Unit == none)
		return;
	Items = Unit.GetAllInventoryItems(NewGameState);
	foreach Items(Item)
	{
		if (Left(string(Item.GetMyTemplateName()), 8) != "LWSmall_" || Done.Find(Item.GetMyTemplateName()) != INDEX_NONE)
			continue;
		Done.AddItem(Item.GetMyTemplateName());
		n = Count(Items, Item.GetMyTemplateName(), Holder);
		Charges = ChargesFor(Unit, int(Mid(string(Item.GetMyTemplateName()), 8)), n, Holder.Ammo);
		if (Charges == Holder.Ammo)
			continue;
		Holder = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Holder.ObjectID));
		Holder.Ammo = Charges;
	}
}

/** How many items of a template the soldier has; Holder: the one holding their (merged) charges. */
static function int Count(array<XComGameState_Item> Items, name Template, out XComGameState_Item Holder)
{
	local XComGameState_Item Item;
	local int n;

	Holder = none;
	foreach Items(Item)
	{
		if (Item.GetMyTemplateName() != Template)
			continue;
		n++;
		if (Holder == none || Item.Ammo > Holder.Ammo)
			Holder = Item;
	}
	return n;
}

/** Long War's charges for n items of Long War's item number (Current: what XCOM 2 has given, kept for other kinds). */
static function int ChargesFor(XComGameState_Unit Unit, int Item, int n, int Current)
{
	local bool bDeep, bGrenadier, bSmoke;
	local int c;

	bDeep = Unit.HasSoldierAbility('LW_Packmaster');
	bGrenadier = Unit.HasSoldierAbility('LW_Grenadier');
	bSmoke = Unit.HasSoldierAbility('LW_SmokeandMirrors');
	switch (Item)
	{
	case 81: case 84: case 87:
		return n * (bGrenadier ? 2 : 1) + (bDeep ? n : 0);
	case 83: case 86: case 88:
		return n * (bSmoke ? 2 : 1) + (bDeep ? n : 0);
	case 73:
		return n + (bDeep ? n : 0) + (Unit.HasSoldierAbility('LW_Repair') ? 2 * n : 0);
	case 69:
		// Savior: two charges more (Long War's are on no item; here on the medikit the soldier carries).
		return n + (bDeep ? n : 0) + (Unit.HasSoldierAbility('LW_Savior') ? 2 : 0);
	case 82:
		c = n + (bDeep ? n : 0) + (bSmoke ? n : 0);
		if (Unit.HasSoldierAbility('LW_SmokeGrenade'))
			c += 1 + (bDeep ? 1 : 0) + (bSmoke ? 1 : 0);
		return c;
	case 97:
		c = n + (bDeep ? n : 0) + (bSmoke ? n : 0);
		if (Unit.HasSoldierAbility('LW_BattleScanner'))
			c += 2 + (bDeep ? 1 : 0) + (bSmoke ? 1 : 0);
		return c;
	case 218:
		// The launcher's rocket, a second with Shock and Awe (the Rocket item's own is X2Effect_LWSmallItem's).
		return Current + (Unit.HasSoldierAbility('LW_ShockAndAwe') ? 1 : 0);
	}
	return Current;
}
