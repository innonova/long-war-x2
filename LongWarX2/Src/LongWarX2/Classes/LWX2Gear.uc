// Long War's soldiers carry what Long War lets them (features/lw-gear.md). XCOM 2 gives a promoted
// soldier their class's starting kit only in empty slots (ApplySquaddieLoadout), so a rookie becoming a
// Long War soldier keeps XCOM 2's rifle (and armour: a Long War soldier not in Long War's armour is put
// in its starting one, Tac Armor). Here a Long War soldier's weapon their class may not carry (or
// none where their kit has one) is put back in the stores and replaced by their kit's (the class's
// SquaddieLoadout, Long War's unlimited starting weapons). Run when soldiers are looked at or sent out
// (UIScreenListener_LWX2Gear) and after the test promotions.
class LWX2Gear extends Object dependson(LWGearRules);

/** XCOM 2's soldier's utility slots without armour (its 'Soldier' character), before Tactical Rigging. */
var int UtilityBase;

/** Every unlimited Long War item in XCOM's stores (XCOM 2 adds its starting items only when a campaign begins). */
static function EnsureInfinite()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local LWGearRules.LWWeaponDef W;
	local LWGearRules.LWArmorDef A;
	local LWGearRules.LWSmallDef D;
	local array<name> Missing;
	local name N;
	local X2ItemTemplate Template;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ == none)
		return;
	foreach class'LWGearRules'.default.Weapons(W)
		if (W.Infinite && XComHQ.GetItemByName(class'LWGearRules'.static.TemplateFor(W.Item)) == none)
			Missing.AddItem(class'LWGearRules'.static.TemplateFor(W.Item));
	foreach class'LWGearRules'.default.Armors(A)
		if (A.Infinite && XComHQ.GetItemByName(class'LWGearRules'.static.ArmorTemplateFor(A.Item)) == none)
			Missing.AddItem(class'LWGearRules'.static.ArmorTemplateFor(A.Item));
	foreach class'LWGearRules'.default.SmallItems(D)
		if (D.Infinite && XComHQ.GetItemByName(D.Template) == none)
			Missing.AddItem(D.Template);
	if (Missing.Length == 0)
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Long War's unlimited items in the stores");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	foreach Missing(N)
	{
		Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(N);
		if (Template != none)
			XComHQ.PutItemInInventory(NewGameState, Template.CreateInstanceFromTemplate(NewGameState));
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("LongWarX2: gear:" @ Missing.Length @ "unlimited Long War items put in the stores", , 'LongWarX2');
}

/** Every Long War soldier in XCOM's crew armed as their class allows. Returns how many were changed. */
/**
 * The Foundry's Tactical Rigging (24): "granting all soldiers the ability to carry one additional small item". XCOM 2
 * puts a soldier's utility slots back to the character's base (+1 for an armour that adds one) whenever the loadout
 * changes, so the base itself is raised, from the campaign's state, before the soldiers are armed; and each Long War
 * soldier's slots are put to it. Returns the slots a soldier then has without armour.
 */
static function int ApplyRigging(XComGameState NewGameState, XComGameState_HeadquartersXCom XComHQ)
{
	local array<X2DataTemplate> Templates;
	local X2DataTemplate Data;
	local XComGameState_Unit Unit;
	local XComGameState_Item Armor;
	local StateObjectReference Ref;
	local int Base, Slots;

	Base = default.UtilityBase + (class'X2Effect_LWFoundry'.static.Done(24) ? 1 : 0);
	class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindDataTemplateAllDifficulties('Soldier', Templates);
	foreach Templates(Data)
		X2CharacterTemplate(Data).CharacterBaseStats[eStat_UtilityItems] = Base;
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier() || Unit.GetMyTemplateName() != 'Soldier' || Left(string(Unit.GetSoldierClassTemplateName()), 4) != "LWS_")
			continue;
		Armor = Unit.GetItemInSlot(eInvSlot_Armor);
		Slots = Base + ((Armor != none && X2ArmorTemplate(Armor.GetMyTemplate()) != none && X2ArmorTemplate(Armor.GetMyTemplate()).bAddsUtilitySlot) ? 1 : 0);
		if (int(Unit.GetMaxStat(eStat_UtilityItems)) == Slots)
			continue;
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetBaseMaxStat(eStat_UtilityItems, Slots);
		Unit.SetCurrentStat(eStat_UtilityItems, Slots);
	}
	return Base;
}

static function int ArmAll()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local int n;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (XComHQ == none)
		return 0;
	EnsureInfinite();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: soldiers armed as Long War allows");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	ApplyRigging(NewGameState, XComHQ);
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier() || Unit.GetSoldierClassTemplate() == none || Left(string(Unit.GetSoldierClassTemplateName()), 4) != "LWS_")
			continue;
		if (NeedsArming(Unit))
		{
			Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			Arm(Unit, NewGameState, XComHQ);
			n++;
		}
	}
	if (n > 0 || NewGameState.GetNumGameStateObjects() > 1)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		`log("LongWarX2: gear:" @ n @ "soldiers armed as Long War allows", , 'LongWarX2');
	}
	else
		History.CleanupPendingGameState(NewGameState);
	return n;
}

/** The items of a soldier's kit (their class's SquaddieLoadout). */
static function array<X2WeaponTemplate> Kit(XComGameState_Unit Unit)
{
	local X2ItemTemplateManager Manager;
	local array<X2WeaponTemplate> Out;
	local InventoryLoadout Loadout;
	local InventoryLoadoutItem Item;
	local X2WeaponTemplate Template;

	Manager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach Manager.Loadouts(Loadout)
	{
		if (Loadout.LoadoutName != Unit.GetSoldierClassTemplate().SquaddieLoadout)
			continue;
		foreach Loadout.Items(Item)
		{
			Template = X2WeaponTemplate(Manager.FindItemTemplate(Item.Item));
			if (Template != none)
				Out.AddItem(Template);
		}
	}
	return Out;
}

static function bool NeedsArming(XComGameState_Unit Unit)
{
	local array<X2WeaponTemplate> Templates;
	local X2WeaponTemplate T;
	local XComGameState_Item Held;

	Templates = Kit(Unit);
	foreach Templates(T)
	{
		Held = Unit.GetItemInSlot(T.InventorySlot);
		if (Held == none || X2WeaponTemplate(Held.GetMyTemplate()) == none || !Unit.GetSoldierClassTemplate().IsWeaponAllowedByClass(X2WeaponTemplate(Held.GetMyTemplate())))
			return true;
	}
	// An armour not Long War's (XCOM 2's Kevlar): Long War's starting armour instead.
	if (!IsLongWarArmor(Unit.GetItemInSlot(eInvSlot_Armor)))
		return true;
	// A small item the class may not carry (the battle scanner for a Gunner): back to the stores.
	if (ForbiddenSmallItems(Unit).Length > 0)
		return true;
	// A slot the class may not use at all (a Rocketeer's or Gunner's pistol): emptied.
	Held = Unit.GetItemInSlot(eInvSlot_SecondaryWeapon);
	return Held != none && X2WeaponTemplate(Held.GetMyTemplate()) != none && !Unit.GetSoldierClassTemplate().IsWeaponAllowedByClass(X2WeaponTemplate(Held.GetMyTemplate()));
}

static function string SmallText(XComGameState_Unit Unit)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;
	local string S;

	Items = Unit.GetAllItemsInSlot(eInvSlot_Utility);
	foreach Items(Item)
		S @= string(Item.GetMyTemplateName());
	return S == "" ? "-" : S;
}

/** The small items a soldier carries that their class may not (LWGearRules.SmallItems' Classes). */
static function array<XComGameState_Item> ForbiddenSmallItems(XComGameState_Unit Unit, optional XComGameState NewGameState)
{
	local array<XComGameState_Item> Items, Out;
	local XComGameState_Item Item;
	local LWGearRules.LWSmallDef D;

	Items = Unit.GetAllItemsInSlot(eInvSlot_Utility, NewGameState);
	foreach Items(Item)
	{
		if (class'LWGearRules'.static.SmallFor(Item.GetMyTemplateName(), D))
		{
			if (D.Classes.Length > 0 && D.Classes.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE)
				Out.AddItem(Item);
		}
		// XCOM 2's own small items (its frag grenade), the XPad apart (it takes no slot).
		else if (X2EquipmentTemplate(Item.GetMyTemplate()) != none && X2EquipmentTemplate(Item.GetMyTemplate()).iItemSize > 0)
			Out.AddItem(Item);
	}
	return Out;
}

static function bool IsLongWarArmor(XComGameState_Item Item)
{
	return Item != none && Left(string(Item.GetMyTemplateName()), 8) == "LWArmor_";
}

static function Arm(XComGameState_Unit Unit, XComGameState NewGameState, XComGameState_HeadquartersXCom XComHQ)
{
	local array<X2WeaponTemplate> Templates;
	local X2WeaponTemplate T;
	local XComGameState_Item Held, Item;
	local EInventorySlot Slot;
	local X2ItemTemplate Armor;
	local array<XComGameState_Item> Forbidden;
	local X2ItemTemplate Small;
	local bool bSwap;

	Forbidden = ForbiddenSmallItems(Unit, NewGameState);
	foreach Forbidden(Held)
	{
		bSwap = Held.GetMyTemplateName() == 'FragGrenade';
		Held = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Held.ObjectID));
		Unit.RemoveItemFromInventory(Held, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, Held);
		// XCOM 2's frag grenade: Long War's HE grenade in its place.
		Small = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate('LWSmall_81');
		if (bSwap && Small != none)
			Unit.AddItemToInventory(Small.CreateInstanceFromTemplate(NewGameState), eInvSlot_Utility, NewGameState);
	}
	Held = Unit.GetItemInSlot(eInvSlot_Armor, NewGameState);
	Armor = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'LWGearRules'.static.ArmorTemplateFor(class'LWGearRules'.default.StartingArmor));
	if (!IsLongWarArmor(Held) && Armor != none)
	{
		if (Held != none)
		{
			Held = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Held.ObjectID));
			Unit.RemoveItemFromInventory(Held, NewGameState);
			XComHQ.PutItemInInventory(NewGameState, Held);
		}
		Unit.AddItemToInventory(Armor.CreateInstanceFromTemplate(NewGameState), eInvSlot_Armor, NewGameState);
	}
	Templates = Kit(Unit);
	for (Slot = eInvSlot_PrimaryWeapon; Slot <= eInvSlot_SecondaryWeapon; Slot = EInventorySlot(Slot + 1))
	{
		Held = Unit.GetItemInSlot(Slot, NewGameState);
		if (Held != none && X2WeaponTemplate(Held.GetMyTemplate()) != none && Unit.GetSoldierClassTemplate().IsWeaponAllowedByClass(X2WeaponTemplate(Held.GetMyTemplate())))
			continue;
		if (Held != none)
		{
			Held = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Held.ObjectID));
			Unit.RemoveItemFromInventory(Held, NewGameState);
			XComHQ.PutItemInInventory(NewGameState, Held);
		}
		foreach Templates(T)
		{
			if (T.InventorySlot != Slot)
				continue;
			Item = T.CreateInstanceFromTemplate(NewGameState);
			Unit.AddItemToInventory(Item, Slot, NewGameState);
		}
	}
}

/** Each Long War soldier's class, kit and weapons (the control port's "arm"). */
static function Report(out array<string> Out)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local array<X2WeaponTemplate> Templates;
	local X2WeaponTemplate T;
	local string Line;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		Templates = Kit(Unit);
		Line = Unit.GetSoldierClassTemplateName() @ "kit";
		foreach Templates(T)
			Line @= T.DataName;
		Line @= "| holds" @ (Unit.GetItemInSlot(eInvSlot_PrimaryWeapon) != none ? string(Unit.GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplateName()) : "-")
			@ (Unit.GetItemInSlot(eInvSlot_SecondaryWeapon) != none ? string(Unit.GetItemInSlot(eInvSlot_SecondaryWeapon).GetMyTemplateName()) : "-")
			@ "| wears" @ (Unit.GetItemInSlot(eInvSlot_Armor) != none ? string(Unit.GetItemInSlot(eInvSlot_Armor).GetMyTemplateName()) : "-")
			@ "hp" @ int(Unit.GetMaxStat(eStat_HP)) @ "mobility" @ int(Unit.GetMaxStat(eStat_Mobility)) @ "defense" @ int(Unit.GetMaxStat(eStat_Defense))
			@ "| small" @ SmallText(Unit) @ "slots" @ Unit.GetCurrentStat(eStat_UtilityItems);
		Out.AddItem(Line);
	}
}

defaultproperties
{
	UtilityBase = 1
}
