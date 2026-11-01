// Long War's artifacts as XCOM 2's resources (features/lw-loot.md): what a UFO's salvage brings
// (LWStrategyRules.Salvage). Elerium and alloys are XCOM 2's own (EleriumDust, AlienAlloy), weapon
// fragments XCOM 2's WeaponFragment; the rest are LWItem_<Long War's name>. Their words are Long
// War's, written on the player's machine (lw-words.mjs makeItemWords).
class X2Item_LWArtifacts extends X2Item;

/** Long War's artifacts the mod has as items of its own (EItemType names without eItem_). */
static function array<name> Artifacts()
{
	local array<name> A;

	A.AddItem('UFONavigation');
	A.AddItem('UFOPowerSource');
	A.AddItem('AlienSurgery');
	A.AddItem('AlienStasisTank');
	A.AddItem('AlienFood');
	A.AddItem('AlienEntertainment');
	A.AddItem('UFOFusionLauncher');
	A.AddItem('PsiLink');
	A.AddItem('HyperwaveBeacon');
	A.AddItem('Meld');
	return A;
}

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2ItemTemplate Template;
	local array<name> All;
	local name A;

	All = Artifacts();
	foreach All(A)
	{
		`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, ItemFor(A));
		Template.ItemCat = 'resource';
		Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Elerium_Core";
		Template.CanBeBuilt = false;
		Templates.AddItem(Template);
	}
	return Templates;
}

/** The XCOM 2 item for a Long War artifact: XCOM 2's own for alloys, elerium and fragments. */
static function name ItemFor(name Artifact)
{
	switch (Artifact)
	{
	case 'Alloys': return 'AlienAlloy';
	case 'Elerium': return 'EleriumDust';
	case 'WeaponFragment': return 'WeaponFragment';
	}
	return name("LWItem_" $ Artifact);
}

/** Some of an item added to XCOM's stores (a resource's count raised; one not held yet made). */
static function Give(XComGameState NewGameState, name Artifact, int Count)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item Item;
	local X2ItemTemplate Template;

	if (Count <= 0)
		return;
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	if (XComHQ == none)
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	Item = XComHQ.GetItemByName(ItemFor(Artifact));
	if (Item != none)
	{
		Item = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Item.ObjectID));
		Item.Quantity += Count;
		return;
	}
	Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemFor(Artifact));
	if (Template == none)
		return;
	Item = Template.CreateInstanceFromTemplate(NewGameState);
	Item.Quantity = Count;
	XComHQ.PutItemInInventory(NewGameState, Item);
}
