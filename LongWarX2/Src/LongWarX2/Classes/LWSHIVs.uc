// Long War's SHIVs (features/lw-shivs-mecs.md): its numbers (Config/XComLWSHIVs.ini, scripts/shivs-config.mjs) and a SHIV
// joining XCOM's crew when engineering builds one.
class LWSHIVs extends Object config(LWSHIVs);

struct LWSHIVStats
{
	var int HP, Aim, Defense, Mobility, Sight;
};

/** A SHIV body, built in engineering (Long War's item), and the deck it wears. */
struct LWSHIVBody
{
	var int Item;
	var name Template;
	var int Deck;
	var int HP, Defense, Mobility, SmallItems;
	var bool Fly;
	var int Fuel;
	/** Hit points beyond the deck's that repair restores. */
	var int RepairHP;
};

struct LWSHIVWeapon
{
	var int Item;
	var name Enum;
	var name Template;
	var int Damage, Crit, Aim, Environment, Ammo;
};

var config LWSHIVStats Base;
var config int RepairHours;
var config int RestHours, RestRollHours, RepairRollMin, RepairFoundry;
var config float RepairFoundryScale;
var config array<LWSHIVBody> Bodies;
var config array<LWSHIVWeapon> Weapons;

/** The XCOM 2 soldier class every SHIV has (no ranks: Long War's SHIVs gain none). */
var name SoldierClass;

static function bool BodyForItem(int Item, out LWSHIVBody B)
{
	local int k;

	k = default.Bodies.Find('Item', Item);
	if (k == INDEX_NONE)
		return false;
	B = default.Bodies[k];
	return true;
}

static function bool BodyForTemplate(name Template, out LWSHIVBody B)
{
	local int k;

	k = default.Bodies.Find('Template', Template);
	if (k == INDEX_NONE)
		return false;
	B = default.Bodies[k];
	return true;
}

static function bool IsSHIV(XComGameState_Unit Unit)
{
	local LWSHIVBody B;

	return Unit != none && BodyForTemplate(Unit.GetMyTemplateName(), B);
}

/** A new SHIV of a body in XCOM's crew, with the SHIV Minigun (XGFacility_Barracks.AddTank: a SHIV joins the barracks). */
static function XComGameState_Unit AddSHIV(XComGameState NewGameState, name Template)
{
	local X2CharacterTemplate CharTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local XComGameState_Item Weapon;
	local X2ItemTemplate WeaponTemplate;
	local int n;

	CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(Template);
	if (CharTemplate == none)
		return none;
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	if (XComHQ == none)
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	Unit = CharTemplate.CreateInstanceFromTemplate(NewGameState);
	n = Count() + 1;
	// (Named in one part, "SHIV #2": XCOM 2's lists show a soldier's last name.)
	Unit.SetCharacterName("", (CharTemplate.strCharacterName != "" ? CharTemplate.strCharacterName : "SHIV") @ "#" $ n, "");
	Unit.SetCountry('Country_USA');
	Unit.SetSoldierClassTemplate(default.SoldierClass);
	Unit.SetXPForRank(1);
	Unit.StartingRank = 1;
	Unit.RankUpSoldier(NewGameState, default.SoldierClass);
	Unit.SetHQLocation(eSoldierLoc_Barracks);
	WeaponTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(default.Weapons[0].Template);
	if (WeaponTemplate != none)
	{
		Weapon = WeaponTemplate.CreateInstanceFromTemplate(NewGameState);
		Unit.AddItemToInventory(Weapon, eInvSlot_PrimaryWeapon, NewGameState);
	}
	XComHQ.AddToCrew(NewGameState, Unit);
	// No will (a robot): ready for duty, never shaken (XCOM 2 reads a unit's state from its will, and 0 of 0 reads Shaken).
	Unit.MentalState = eMentalState_Ready;
	`log("LongWarX2: SHIVs:" @ Template @ Unit.GetFullName() @ "joins the crew, hp" @ int(Unit.GetMaxStat(eStat_HP)), , 'LongWarX2');
	return Unit;
}

/** A damaged SHIV's hours in repair (XGFacility_Barracks.DetermineTimeOut's tank part): RepairHours per hit point lost,
 *  twice that per point below a quarter of its health, plus up to half of that (at least RepairRollMin); two thirds of it once
 *  the Foundry's Vehicle Repair is done. */
static function int RepairHoursFor(XComGameState_Unit Unit, XComGameState_LWStrategy S)
{
	local int HP, MaxHP, H;

	HP = int(Unit.GetCurrentStat(eStat_HP));
	MaxHP = int(Unit.GetBaseStat(eStat_HP));
	H = default.RepairHours * (MaxHP - HP) + Max(2 * default.RepairHours * (MaxHP / 4 - HP), 0);
	H += Rand(Max(H / 2, default.RepairRollMin));
	if (S != none && S.FoundryDone.Find(default.RepairFoundry) != INDEX_NONE)
		H *= default.RepairFoundryScale;
	return Max(1, H);
}

/** A SHIV's hours out after a mission (the same: its own, whatever it did; no going all in). */
static function int RestHoursFor()
{
	return default.RestHours + Rand(default.RestRollHours);
}

/** The SHIVs XCOM has. */
static function int Count()
{
	local StateObjectReference Ref;
	local int n;

	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
		if (IsSHIV(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID))))
			n++;
	return n;
}

defaultproperties
{
	SoldierClass = "LWS_SHIV"
}
