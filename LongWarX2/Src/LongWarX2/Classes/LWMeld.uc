// Long War's meld canisters (features/lw-loot.md), read from its code (XGBattleDesc.ShouldSpawnMeldCanisters,
// XGBattle_SP.InitMeldContainers, XComMeldContainerActor) and placed at EW's own places on its maps (the converter's
// MeldPoints): on abductions, crash sites and landed UFOs, of the spawn group of the soldiers' drop zone, one hard canister,
// an easy one on a roll of 2 or more out of 3, a second hard one on 3. Each is XCOM 2's loot drop (its marker, its turns
// shown, taken by a soldier who reaches it, brought home in the backpack) holding Long War's meld: the aliens' resources
// / 10, 5 to 30 (the patch's own factor not read, taken as 1); gone on EW's turn for it.
class LWMeld extends Object dependson(LWX2EWMapPieces);

static function Place()
{
	local XComGameStateHistory History;
	local XComGameState_LWStrategy S;
	local XComGameState_BattleData Battle;
	local XComGameState_LootDrop Drop;
	local XComGameState_Unit Source, Unit;
	local XComGameState NewGameState;
	local LWX2EWMapData Map;
	local array<LWX2EWMapPieces.LWX2Meld> Easy, Hard, Chosen;
	local LWX2EWMapPieces.LWX2Meld P;
	local vector Shift;
	local float Best;
	local int Group, Roll, k, First, Second, Amount;

	History = `XCOMHISTORY;
	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || (S.PendingKind != 1 && S.PendingKind != 2 && S.PendingKind != 3) || !class'LWX2EWMapPieces'.static.HasMap())
		return;
	// Once a mission (the HUD comes up again on a load).
	foreach History.IterateByClassType(class'XComGameState_LootDrop', Drop)
		if (Drop.LastLootOwnerName == "Meld canister")
			return;
	Map = class'LWX2EWMapPieces'.static.Map();
	if (Map.MeldPoints.Length == 0)
		return;
	Battle = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	Shift = class'LWX2PartPlacer'.default.EWShift;
	// The soldiers' drop zone: EW's group of the same number.
	Best = -1;
	for (k = 0; k < Map.DropZones.Length; k++)
	{
		if (Best < 0 || VSize(Map.DropZones[k] + Shift - Battle.MapData.SoldierSpawnLocation) < Best)
		{
			Best = VSize(Map.DropZones[k] + Shift - Battle.MapData.SoldierSpawnLocation);
			Group = k;
		}
	}
	foreach Map.MeldPoints(P)
	{
		if (P.Group != Group)
			continue;
		if (P.Hard)
			Hard.AddItem(P);
		else
			Easy.AddItem(P);
	}
	Roll = 1 + Rand(3);
	First = -1;
	if (Hard.Length > 0)
	{
		First = Rand(Hard.Length);
		Chosen.AddItem(Hard[First]);
	}
	if (Easy.Length > 0 && Roll > 1)
		Chosen.AddItem(Easy[Rand(Easy.Length)]);
	if (Hard.Length > 1 && Roll > 2)
	{
		Second = Rand(Hard.Length - 1);
		Chosen.AddItem(Hard[Second >= First ? Second + 1 : Second]);
	}
	if (Chosen.Length == 0)
		return;
	// XCOM 2's loot drop wants a source (for its place and name, both set here): the first soldier.
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() == eTeam_XCom && Unit.IsSoldier() && Unit.IsAlive())
		{
			Source = Unit;
			break;
		}
	}
	if (Source == none)
		return;
	Amount = Clamp(S.AlienResources / 10, 5, 30);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: meld canisters");
	foreach Chosen(P)
		Canister(NewGameState, Source, P, Shift, Amount);
	// Each one's marker where it is, with its turns (XCOM 2's fountain, which CreateLootDrop asks for, would fly the meld
	// from the soldier).
	NewGameState.GetContext().PostBuildVisualizationFn.Length = 0;
	foreach NewGameState.IterateByClassType(class'XComGameState_LootDrop', Drop)
		NewGameState.GetContext().PostBuildVisualizationFn.AddItem(Drop.VisualizeLootFountainMove);
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("LongWarX2: meld:" @ Chosen.Length @ "canisters (roll" @ Roll $ ", group" @ Group $ ";" @ Hard.Length @ "hard," @ Easy.Length @ "easy places)," @ Amount @ "meld each", , 'LongWarX2');
}

/** One canister: a loot drop holding the meld at EW's place, gone on its turn. */
static function Canister(XComGameState NewGameState, XComGameState_Unit Source, LWX2EWMapPieces.LWX2Meld P, vector Shift, int Amount)
{
	local XComGameState_Item Item;
	local XComGameState_LootDrop Drop;
	local array<XComGameState_Item> Items;
	local X2ItemTemplate Template;
	local XComWorldData World;
	local TTile Tile;
	local vector At;

	Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'X2Item_LWArtifacts'.static.ItemFor('Meld'));
	if (Template == none)
		return;
	Item = Template.CreateInstanceFromTemplate(NewGameState);
	Item.Quantity = Amount;
	Items.AddItem(Item);
	class'XComGameState_LootDrop'.static.CreateLootDrop(NewGameState, Items, Source, true);
	World = `XWORLD;
	At = P.Loc + Shift;
	if (!World.GetFloorTileForPosition(At, Tile, true))
		Tile = World.GetTileCoordinatesFromPosition(At);
	foreach NewGameState.IterateByClassType(class'XComGameState_LootDrop', Drop)
	{
		if (Drop.LastLootOwnerName == "Meld canister")
			continue;
		Drop.TileLocation = Tile;
		Drop.LastLootOwnerName = "Meld canister";
		Drop.LootExpirationTurnsRemaining = Max(1, P.Turns);
	}
}

