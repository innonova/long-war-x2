// Long War's MEC troopers (features/lw-shivs-mecs.md, phase 3): its numbers (Config/XComLWMECs.ini, scripts/mecs-config.mjs)
// and augmentation: a soldier into the Cybernetics Lab (XGFacility_CyberneticsLab.AddSoldierToCyberneticsLab), and out as a
// MEC trooper, a unit of its own (character LWMEC) in the soldier's place (XGStrategySoldier.SetSoldierClass, eSC_Mec).
class LWMECs extends Object config(LWMECs);

struct LWMECStats
{
	var int HP, Aim, Defense, Mobility, Will;
};

struct LWMECSuit
{
	var int Item;
	/** Its EItemType name (for its words: scripts/lw-words.mjs). */
	var name Enum;
	var int HP, Defense, Mobility, Will, LargeItems, SmallItems;
	/** Its damage reduction (Long War's BalanceMods_Classic iHP, in tenths). */
	var float DR;
	var bool Built;
	var int Cash, Elerium, Alloys, Meld, Days, Engineers, Tech, ItemReq;
};

struct LWMECWeapon
{
	var int Item;
	/** Its EItemType name (for its words: scripts/lw-words.mjs). */
	var name Enum;
	var int Damage, Crit, Aim, Environment, Ammo;
	var bool Built;
	var int Cash, Elerium, Alloys, Meld, Days, Engineers, Tech, ItemReq;
};

var config int AugmentCash, AugmentMeld, AugmentDays;
/** The Kinetic Strike Module (a melee strike, X2Item_LWMECGear). */
var config LWMECWeapon KineticStrike;
var config LWMECStats Base;
var config array<LWMECSuit> Suits;
var config array<LWMECWeapon> Weapons;

/** Each Long War class's MEC class (Long War's subclass + 20). */
var array<name> FromClasses, MECClasses;

static function name SuitTemplate(int Item) { return name("LWMEC_Suit_" $ Item); }
static function name WeaponTemplate(int Item) { return name("LWMEC_Weapon_" $ Item); }

static function bool IsMEC(XComGameState_Unit Unit)
{
	return Unit != none && Unit.GetMyTemplateName() == 'LWMEC';
}

static function name MECClassFor(name SoldierClass)
{
	local int k;

	k = default.FromClasses.Find(SoldierClass);
	return k == INDEX_NONE ? '' : default.MECClasses[k];
}

/** Whether a soldier may be augmented now (the Cybernetics Lab, a free place, ready, a Long War class; not an officer, not
 *  psionic, no gene mods: Long War's words for the lab); Why says what is missing. */
static function bool CanAugment(XComGameState_LWStrategy S, XComGameState_Unit Unit, out string Why)
{
	local LWBaseRules.LWGeneMod G;
	local LWBaseRules.LWPsiPower P;

	Why = "";
	if (S == none || class'LWBase'.static.Count(S, 22) == 0)
		Why = "the Cybernetics Lab";
	else if (S.MECPatients.Length >= class'LWBaseRules'.default.PsiSlots * class'LWBase'.static.Count(S, 22))
		Why = "a free place in the Cybernetics Lab";
	else if (Unit == none || !Unit.IsSoldier() || Unit.IsRobotic() || IsMEC(Unit) || !Unit.CanGoOnMission() || S.InPsiTraining(Unit.ObjectID)
		|| S.MECPatients.Find('Unit', Unit.ObjectID) != INDEX_NONE)
		Why = "a soldier ready for duty";
	else if (MECClassFor(Unit.GetSoldierClassTemplateName()) == '')
		Why = "a soldier of a Long War class";
	else if (class'LWOfficers'.static.Rank(Unit) > 0)
		Why = "a soldier who is not an officer";
	else
	{
		foreach class'LWBaseRules'.default.PsiPowers(P)
			if (Unit.HasSoldierAbility(class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk)))
				Why = "a soldier who is not psionic";
		foreach class'LWBaseRules'.default.GeneMods(G)
			if (class'XComGameState_LWStrategy'.static.HasGeneMod(Unit, G.Perk))
				Why = "a soldier without gene mods";
	}
	if (Why == "" && class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < default.AugmentCash)
		Why = class'LWStrategyRules'.static.Money(default.AugmentCash);
	if (Why == "" && class'LWEngineering'.static.Held(class'X2Item_LWArtifacts'.static.ItemFor('Meld')) < default.AugmentMeld)
		Why = default.AugmentMeld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld');
	return Why == "";
}

/** A soldier into the Cybernetics Lab: paid now, out of the barracks for AugmentDays. */
static function bool StartAugment(int UnitID, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local XComGameState_LWStrategy.LWMECPatient P;

	S = class'XComGameState_LWStrategy'.static.Get();
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (!CanAugment(S, Unit, Why))
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: augmentation begun");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', -default.AugmentCash);
	class'LWEngineering'.static.Take(NewGameState, class'X2Item_LWArtifacts'.static.ItemFor('Meld'), default.AugmentMeld);
	P.Unit = UnitID;
	P.HoursLeft = default.AugmentDays * 24;
	S.MECPatients.AddItem(P);
	S.Note(Unit.GetFullName() @ "went into the Cybernetics Lab.");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("LongWarX2: MECs:" @ Unit.GetFullName() @ "augmented for" @ P.HoursLeft @ "hours", , 'LongWarX2');
	return true;
}

/**
 * Augmentation done: a MEC trooper in the soldier's place (SetSoldierClass, eSC_Mec): the soldier's name, nickname, country,
 * kills and missions; one rank lower (at least squaddie), the MEC class of the soldier's, the first MEC suit and the MEC
 * Minigun; Long War's soldier base stats again (+4 HP) and the class's gains for each rank. The soldier leaves the crew.
 */
static function XComGameState_Unit AugmentDone(XComGameState NewGameState, XComGameState_LWStrategy S, int UnitID)
{
	local X2CharacterTemplate CharTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Old, MEC;
	local XComGameState_Item Item;
	local X2ItemTemplate ItemTemplate;
	local name MECClass;
	local int Rank, i;

	Old = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	MECClass = Old != none ? MECClassFor(Old.GetSoldierClassTemplateName()) : '';
	CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('LWMEC');
	if (Old == none || MECClass == '' || CharTemplate == none)
		return none;
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	if (XComHQ == none)
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	MEC = CharTemplate.CreateInstanceFromTemplate(NewGameState);
	MEC.SetCharacterName(Old.GetName(eNameType_First), Old.GetName(eNameType_Last), Old.GetName(eNameType_Nick));
	MEC.SetCountry(Old.GetCountry());
	MEC.SetSoldierClassTemplate(MECClass);
	Rank = Max(1, Old.GetRank() - 1);
	MEC.SetXPForRank(Rank);
	MEC.StartingRank = Rank;
	for (i = 0; i < Rank; i++)
		MEC.RankUpSoldier(NewGameState, MECClass);
	// The squaddie's perk and the class's first choice at each rank (XCOM 2's ranks each give a pick; the player chooses later).
	// Robotics' aim (SetSoldierClass, a MEC: aStats[1] += HasBonus(48)).
	class'LWBonusEffects'.static.Raise(MEC, eStat_Offense, class'LWBonuses'.static.Has(class'LWBonuses'.const.ROBOTICS, S));
	MEC.SetHQLocation(eSoldierLoc_Barracks);
	ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(SuitTemplate(default.Suits[0].Item));
	if (ItemTemplate != none)
	{
		Item = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
		MEC.AddItemToInventory(Item, eInvSlot_Armor, NewGameState);
	}
	ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(WeaponTemplate(default.Weapons[0].Item));
	if (ItemTemplate != none)
	{
		Item = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
		MEC.AddItemToInventory(Item, eInvSlot_PrimaryWeapon, NewGameState);
	}
	// The soldier's record: kills and missions.
	MEC.SetUnitFloatValue('LWX2AugmentedFrom', UnitID, eCleanup_Never);
	MEC.iNumMissions = Old.iNumMissions;
	for (i = 0; i < Old.GetKills().Length; i++)
		MEC.SimGetKill(Old.GetKills()[i]);
	XComHQ.AddToCrew(NewGameState, MEC);
	// The soldier leaves the crew (not dead: augmented).
	XComHQ.RemoveFromCrew(Old.GetReference());
	S.Note(Old.GetFullName() @ "came out of the Cybernetics Lab a" @ MEC.GetSoldierClassTemplate().DisplayName $ ".");
	`log("LongWarX2: MECs:" @ Old.GetFullName() @ "is now" @ MECClass @ "rank" @ MEC.GetRank() @ "#" $ MEC.ObjectID, , 'LongWarX2');
	return MEC;
}

defaultproperties
{
	FromClasses(0) = "LWS_Sniper"
	FromClasses(1) = "LWS_Scout"
	FromClasses(2) = "LWS_Rocketeer"
	FromClasses(3) = "LWS_Gunner"
	FromClasses(4) = "LWS_Medic"
	FromClasses(5) = "LWS_Engineer"
	FromClasses(6) = "LWS_Assault"
	FromClasses(7) = "LWS_Infantry"
	MECClasses(0) = "LWS_Jaeger"
	MECClasses(1) = "LWS_Pathfinder"
	MECClasses(2) = "LWS_Archer"
	MECClasses(3) = "LWS_Goliath"
	MECClasses(4) = "LWS_Guardian"
	MECClasses(5) = "LWS_Shogun"
	MECClasses(6) = "LWS_Marauder"
	MECClasses(7) = "LWS_Valkyrie"
}
