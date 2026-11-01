// Long War's soldiers carry what Long War lets them (features/lw-gear.md). XCOM 2 gives a promoted
// soldier their class's starting kit only in empty slots (ApplySquaddieLoadout), so a rookie becoming a
// Long War soldier keeps XCOM 2's rifle. Here a Long War soldier's weapon their class may not carry (or
// none where their kit has one) is put back in the stores and replaced by their kit's (the class's
// SquaddieLoadout, Long War's unlimited starting weapons). Run when soldiers are looked at or sent out
// (UIScreenListener_LWX2Gear) and after the test promotions.
class LWX2Gear extends Object;

/** Every Long War soldier in XCOM's crew armed as their class allows. Returns how many were changed. */
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
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: soldiers armed as Long War allows");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
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
	if (n > 0)
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
	// A slot the class may not use at all (a Rocketeer's or Gunner's pistol): emptied.
	Held = Unit.GetItemInSlot(eInvSlot_SecondaryWeapon);
	return Held != none && X2WeaponTemplate(Held.GetMyTemplate()) != none && !Unit.GetSoldierClassTemplate().IsWeaponAllowedByClass(X2WeaponTemplate(Held.GetMyTemplate()));
}

static function Arm(XComGameState_Unit Unit, XComGameState NewGameState, XComGameState_HeadquartersXCom XComHQ)
{
	local array<X2WeaponTemplate> Templates;
	local X2WeaponTemplate T;
	local XComGameState_Item Held, Item;
	local EInventorySlot Slot;

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
			@ (Unit.GetItemInSlot(eInvSlot_SecondaryWeapon) != none ? string(Unit.GetItemInSlot(eInvSlot_SecondaryWeapon).GetMyTemplateName()) : "-");
		Out.AddItem(Line);
	}
}
