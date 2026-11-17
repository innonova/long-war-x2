// Long War's damaged gear and its repair (features/lw-gear-repair.md), with the second wave's Wear and Tear (#13), Durability
// (#22) and Miracle Workers (#26). The numbers are Long War's (XComLWGear.ini, scripts/gear-config.mjs).
// - After a mission (XGStrategySoldier.DEMOUltimateSoldier, which Long War rewrote for this): each item a soldier carries that
//   is not infinite is damaged with a chance of (1 - HP / max HP) x the item's damage chance; with Wear and Tear a second roll
//   of WearChance % whatever the soldier's health; never with Durability. A damaged item leaves the soldier, who gets the
//   infinite gear in its place, and waits in the campaign's DamagedItems for repair.
// - Repair (XGFacility_CyberneticsLab.AddMecForRepair): CostShare of the item's build cost, paid at once (nothing with
//   Miracle Workers); the build time x TimeShare %, x FasterScale once Foundry project FasterFoundry is done, at the work all
//   of XCOM's engineers do in an hour; at least MinHours. Then the item is back in storage.
class LWGearRepair extends Object config(LWGear) dependson(XComGameState_LWStrategy, LWGearRules, LWSHIVs, LWMECs);

struct LWWearChance
{
	var int Item;
	var int Chance;
};

var config array<LWWearChance> Chances;
var config int WearChance, TimeShare, MinHours, FasterFoundry;
var config float CostShare, FasterScale;

/** Long War's number for one of the mod's item templates (its weapons, armours, MEC suits and weapons, small items, SHIV
 *  weapons); 0 when it is none of Long War's. */
static function int ItemNumber(name Template)
{
	local string T;
	local int k;

	T = string(Template);
	if (Left(T, 9) == "LWWeapon_")
		return int(Mid(T, 9));
	if (Left(T, 8) == "LWArmor_")
		return int(Mid(T, 8));
	if (Left(T, 11) == "LWMEC_Suit_")
		return int(Mid(T, 11));
	if (Left(T, 13) == "LWMEC_Weapon_")
		return int(Mid(T, 13));
	k = class'LWGearRules'.default.SmallItems.Find('Template', Template);
	if (k != INDEX_NONE)
		return class'LWGearRules'.default.SmallItems[k].Item;
	k = class'LWSHIVs'.default.Weapons.Find('Template', Template);
	if (k != INDEX_NONE)
		return class'LWSHIVs'.default.Weapons[k].Item;
	return 0;
}

/** The item's damage chance after a mission, % (Long War's Max%DamagedChance); 0: never damaged. */
static function int ChanceFor(name Template)
{
	local int n, k;

	n = ItemNumber(Template);
	k = n > 0 ? default.Chances.Find('Item', n) : INDEX_NONE;
	return k != INDEX_NONE ? default.Chances[k].Chance : 0;
}

/** The strategy layer opened: the gear of each soldier back from a mission not yet counted (LWExperience marks them, as
 *  for fatigue) rolled for damage. */
static function Apply()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	local StateObjectReference Ref;
	local int Mission;

	History = `XCOMHISTORY;
	S = class'XComGameState_LWStrategy'.static.Get();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (S == none || XComHQ == none)
		return;
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier() || Unit.IsDead())
			continue;
		Mission = class'LWFatigue'.static.ValueOf(Unit, 'LWX2XPMission');
		if (Mission == 0 || Mission == class'LWFatigue'.static.ValueOf(Unit, 'LWX2GearMission'))
			continue;
		if (NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: damaged gear");
			S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		}
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetUnitFloatValue('LWX2GearMission', Mission, eCleanup_Never);
		DamageGear(NewGameState, S, XComHQ, Unit);
	}
	if (NewGameState != none)
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** The unit's gear rolled for damage as it is now (its health now); how many items were damaged. */
static function int DamageGear(XComGameState NewGameState, XComGameState_LWStrategy S, XComGameState_HeadquartersXCom XComHQ, XComGameState_Unit Unit)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;
	local X2ItemTemplate T;
	local float Hurt;
	local int C, n;

	if (class'LWX2SecondWave'.static.On(22))
		return 0;
	Hurt = 1.0 - Unit.GetCurrentStat(eStat_HP) / FMax(1, Unit.GetMaxStat(eStat_HP));
	Items = Unit.GetAllInventoryItems(NewGameState, true);
	foreach Items(Item)
	{
		T = Item.GetMyTemplate();
		if (T == none || T.bInfiniteItem || !Worn(Item.InventorySlot))
			continue;
		// (A SHIV's armour: none; Long War's IsATank.)
		if (Item.InventorySlot == eInvSlot_Armor && class'LWSHIVs'.static.IsSHIV(Unit))
			continue;
		C = ChanceFor(T.DataName);
		if (C <= 0)
			continue;
		if (!(Rand(100) < int(Hurt * C) || (class'LWX2SecondWave'.static.On(13) && Rand(100) < default.WearChance)))
			continue;
		Item = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Item.ObjectID));
		Unit.RemoveItemFromInventory(Item, NewGameState);
		NewGameState.RemoveStateObject(Item.ObjectID);
		S.DamagedItems.AddItem(T.DataName);
		S.Note(Unit.GetFullName() $ "'s" @ T.GetItemFriendlyName() @ "was damaged and waits for repair.");
		n++;
	}
	if (n > 0)
		Refit(NewGameState, XComHQ, Unit);
	return n;
}

/** The slots Long War's roll covers (its pistol, large and small items, armour): not what a soldier picked up. */
static function bool Worn(EInventorySlot Slot)
{
	switch (Slot)
	{
	case eInvSlot_PrimaryWeapon:
	case eInvSlot_SecondaryWeapon:
	case eInvSlot_Armor:
	case eInvSlot_Utility:
	case eInvSlot_HeavyWeapon:
	case eInvSlot_GrenadePocket:
	case eInvSlot_AmmoPocket:
		return true;
	}
	return false;
}

/** The infinite gear in place of what was damaged (Long War: the infinite primary and secondary, the basic armour, a MEC
 *  the first suit). */
static function Refit(XComGameState NewGameState, XComGameState_HeadquartersXCom XComHQ, XComGameState_Unit Unit)
{
	local X2ItemTemplate T;

	if (class'LWMECs'.static.IsMEC(Unit))
	{
		T = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'LWMECs'.static.SuitTemplate(class'LWMECs'.default.Suits[0].Item));
		if (T != none && Unit.GetItemInSlot(eInvSlot_Armor, NewGameState) == none)
			Unit.AddItemToInventory(T.CreateInstanceFromTemplate(NewGameState), eInvSlot_Armor, NewGameState);
		T = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'LWMECs'.static.WeaponTemplate(class'LWMECs'.default.Weapons[0].Item));
		if (T != none && Unit.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState) == none)
			Unit.AddItemToInventory(T.CreateInstanceFromTemplate(NewGameState), eInvSlot_PrimaryWeapon, NewGameState);
	}
	else if (class'LWSHIVs'.static.IsSHIV(Unit))
	{
		T = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'LWSHIVs'.default.Weapons[0].Template);
		if (T != none && Unit.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState) == none)
			Unit.AddItemToInventory(T.CreateInstanceFromTemplate(NewGameState), eInvSlot_PrimaryWeapon, NewGameState);
	}
	else
		class'LWX2Gear'.static.Arm(Unit, NewGameState, XComHQ);
}

/** A repair's cost: CostShare of the item's build cost (nothing with Miracle Workers). */
static function CostOf(name Template, out int Cash, out int Elerium, out int Alloys, out int Meld)
{
	local LWGearRules.LWBuildDef B;

	Cash = 0;
	Elerium = 0;
	Alloys = 0;
	Meld = 0;
	if (class'LWX2SecondWave'.static.On(26) || !class'LWGearRules'.static.BuildFor(ItemNumber(Template), B))
		return;
	Cash = int(B.Cash * default.CostShare);
	Elerium = int(B.Elerium * default.CostShare);
	Alloys = int(B.Alloys * default.CostShare);
	Meld = int(B.Meld * default.CostShare);
}

/** A repair's hours, begun now. */
static function int HoursFor(XComGameState_LWStrategy S, name Template)
{
	local LWGearRules.LWBuildDef B;
	local float Work;
	local int w;

	if (class'LWGearRules'.static.BuildFor(ItemNumber(Template), B))
		Work = class'LWEngineering'.static.UnitWork(B) * default.TimeShare / 100.0;
	if (S.FoundryDone.Find(default.FasterFoundry) != INDEX_NONE)
		Work *= default.FasterScale;
	w = class'LWEngineering'.static.WorkPerHour(S.Engineers, S.Engineers);
	return Max(w > 0 ? int(Work / w) : default.MinHours, default.MinHours);
}

/** The cost in words ("§45, 4 Alloys"), or "" when it costs nothing. */
static function string CostText(name Template)
{
	local array<string> Out;
	local int Cash, Elerium, Alloys, Meld;

	CostOf(Template, Cash, Elerium, Alloys, Meld);
	if (Cash > 0)
		Out.AddItem(class'LWStrategyRules'.static.Money(Cash));
	if (Alloys > 0)
		Out.AddItem(Alloys @ class'X2Item_LWArtifacts'.static.DisplayName('Alloys'));
	if (Elerium > 0)
		Out.AddItem(Elerium @ class'X2Item_LWArtifacts'.static.DisplayName('Elerium'));
	if (Meld > 0)
		Out.AddItem(Meld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld'));
	return class'LWEngineering'.static.JoinStrings(Out);
}

/** Short of something for the repair: what, in words; "" when it can be paid. */
static function string Short(name Template)
{
	local array<string> Out;
	local int Cash, Elerium, Alloys, Meld;

	CostOf(Template, Cash, Elerium, Alloys, Meld);
	if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < Cash)
		Out.AddItem(class'LWStrategyRules'.static.Money(Cash));
	if (class'LWEngineering'.static.Held('AlienAlloy') < Alloys)
		Out.AddItem(Alloys @ class'X2Item_LWArtifacts'.static.DisplayName('Alloys'));
	if (class'LWEngineering'.static.Held('EleriumDust') < Elerium)
		Out.AddItem(Elerium @ class'X2Item_LWArtifacts'.static.DisplayName('Elerium'));
	if (class'LWEngineering'.static.Held(class'X2Item_LWArtifacts'.static.ItemFor('Meld')) < Meld)
		Out.AddItem(Meld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld'));
	return class'LWEngineering'.static.JoinStrings(Out);
}

/** One damaged item of the template put into repair: paid now, back in storage in HoursFor. */
static function bool StartRepair(name Template, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy.LWItemRepair R;
	local int Cash, Elerium, Alloys, Meld, k;

	S = class'XComGameState_LWStrategy'.static.Get();
	k = S != none ? S.DamagedItems.Find(Template) : INDEX_NONE;
	if (k == INDEX_NONE)
	{
		Why = "No damaged" @ Template @ "to repair.";
		return false;
	}
	Why = Short(Template);
	if (Why != "")
	{
		Why = "Short of" @ Why $ ".";
		return false;
	}
	CostOf(Template, Cash, Elerium, Alloys, Meld);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a repair begins");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -Cash);
	class'LWEngineering'.static.Take(NewGameState, 'AlienAlloy', Alloys);
	class'LWEngineering'.static.Take(NewGameState, 'EleriumDust', Elerium);
	class'LWEngineering'.static.Take(NewGameState, class'X2Item_LWArtifacts'.static.ItemFor('Meld'), Meld);
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	S.DamagedItems.Remove(k, 1);
	R.Template = Template;
	R.HoursLeft = HoursFor(S, Template);
	S.Repairs.AddItem(R);
	S.Note("Repair began:" @ class'LWEngineering'.static.ItemName(Template) $ ", done in" @ class'LWEngineering'.static.HoursText(R.HoursLeft) $ ".");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

/** An hour of the campaign: repairs done are back in storage (XGFacility_CyberneticsLab.UpdateRepairingMecs). */
static function Hour(XComGameState NewGameState, XComGameState_LWStrategy S)
{
	local int i;

	for (i = S.Repairs.Length - 1; i >= 0; i--)
	{
		if (--S.Repairs[i].HoursLeft > 0)
			continue;
		class'X2Item_LWArtifacts'.static.GiveItem(NewGameState, S.Repairs[i].Template, 1);
		S.Note("Repaired:" @ class'LWEngineering'.static.ItemName(S.Repairs[i].Template) $ ", back in storage.");
		S.Repairs.Remove(i, 1);
	}
}
