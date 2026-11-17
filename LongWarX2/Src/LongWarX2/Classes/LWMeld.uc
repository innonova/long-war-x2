// Long War's meld canisters (features/lw-loot.md), read from its code (XGBattleDesc.ShouldSpawnMeldCanisters,
// XGBattle_SP.InitMeldContainers, XComMeldContainerActor) and placed at EW's own places on its maps (the converter's
// MeldPoints): on abductions, crash sites and landed UFOs, of the spawn group of the soldiers' drop zone, one hard canister,
// an easy one on a roll of 2 or more out of 3, a second hard one on 3. Each is XCOM 2's loot drop (its marker, its turns
// shown, taken by a soldier who reaches it, brought home in the backpack) holding Long War's meld: the aliens' resources
// / 10, 5 to 30 (the patch's own factor not read, taken as 1); gone on EW's turn for it.
// Without Recon (second wave #29: "You will see meld cans … in the fog") a canister is hidden in the fog until XCOM sees it:
// it waits unmade (XComGameState_LWX2Meld) until its tile has been seen (Reveal), as XCOM 2 would show its marker anywhere.
class LWMeld extends Object dependson(LWX2EWMapPieces, XComGameState_LWX2Meld);

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
	local XComGameState_LWX2Meld Waiting;
	local XComGameState_LWX2Meld.LWX2HiddenCanister H;

	History = `XCOMHISTORY;
	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || (S.PendingKind != 1 && S.PendingKind != 2 && S.PendingKind != 3) || !class'LWX2EWMapPieces'.static.HasMap())
		return;
	// Once a mission (the HUD comes up again on a load).
	foreach History.IterateByClassType(class'XComGameState_LootDrop', Drop)
		if (Drop.LastLootOwnerName == "Meld canister")
			return;
	if (History.GetSingleGameStateObjectForClass(class'XComGameState_LWX2Meld', true) != none)
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
	// (Dynamic War: ÷ SW_MARATHON, XComMeldContainerActor.GetMeldAmount.)
	Amount = class'LWX2SecondWave'.static.War(Clamp(S.AlienResources / 10, 5, 30));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: meld canisters");
	// Without Recon: kept unmade until seen (Reveal).
	if (!class'LWX2SecondWave'.static.On(29))
	{
		Waiting = XComGameState_LWX2Meld(NewGameState.CreateNewStateObject(class'XComGameState_LWX2Meld'));
		foreach Chosen(P)
		{
			H.Tile = TileOf(P, Shift);
			H.Turns = Max(1, P.Turns);
			H.Amount = Amount;
			Waiting.Hidden.AddItem(H);
		}
		`TACTICALRULES.SubmitGameState(NewGameState);
		`log("LongWarX2: meld:" @ Chosen.Length @ "canisters hidden in the fog until seen", , 'LongWarX2');
		return;
	}
	foreach Chosen(P)
		Canister(NewGameState, Source, TileOf(P, Shift), Max(1, P.Turns), Amount);
	// Each one's marker where it is, with its turns (XCOM 2's fountain, which CreateLootDrop asks for, would fly the meld
	// from the soldier).
	NewGameState.GetContext().PostBuildVisualizationFn.Length = 0;
	foreach NewGameState.IterateByClassType(class'XComGameState_LootDrop', Drop)
		NewGameState.GetContext().PostBuildVisualizationFn.AddItem(Drop.VisualizeLootFountainMove);
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("LongWarX2: meld:" @ Chosen.Length @ "canisters (roll" @ Roll $ ", group" @ Group $ ";" @ Hard.Length @ "hard," @ Easy.Length @ "easy places)," @ Amount @ "meld each", , 'LongWarX2');
}

/** A canister's tile: the floor at EW's place. */
static function TTile TileOf(LWX2EWMapPieces.LWX2Meld P, vector Shift)
{
	local TTile Tile;
	local vector At;

	At = P.Loc + Shift;
	if (!`XWORLD.GetFloorTileForPosition(At, Tile, true))
		Tile = `XWORLD.GetTileCoordinatesFromPosition(At);
	return Tile;
}

/** Without Recon: each canister waiting whose tile XCOM has now seen made, with the turns it has left; one gone already is
 *  dropped. (Every two seconds of a mission: UIScreenListener_LongWarX2Tactical.CheckSwept.) */
static function Reveal()
{
	local XComGameStateHistory History;
	local XComGameState_LWX2Meld Waiting;
	local XComGameState_Unit Source, Unit;
	local XComGameState NewGameState;
	local XComGameState_LootDrop Drop;
	local FOWTileStatus Status;
	local byte Flags;
	local TTile T;
	local int i, Left;
	local bool bAny;

	History = `XCOMHISTORY;
	Waiting = XComGameState_LWX2Meld(History.GetSingleGameStateObjectForClass(class'XComGameState_LWX2Meld', true));
	if (Waiting == none || Waiting.Hidden.Length == 0)
		return;
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_XCom && Unit.IsSoldier() && Unit.IsAlive())
		{
			Source = Unit;
			break;
		}
	for (i = Waiting.Hidden.Length - 1; i >= 0; i--)
	{
		T = Waiting.Hidden[i].Tile;
		`XWORLD.GetTileFOWValue(T, Status, Flags);
		Left = Waiting.Hidden[i].Turns - (class'LWX2CovertExtraction'.static.TurnNow() - 1);
		if (Left > 0 && Status == eFOWTileStatus_NeverSeen)
			continue;
		if (NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a meld canister seen");
			Waiting = XComGameState_LWX2Meld(NewGameState.ModifyStateObject(class'XComGameState_LWX2Meld', Waiting.ObjectID));
		}
		if (Left > 0 && Source != none)
		{
			Canister(NewGameState, Source, Waiting.Hidden[i].Tile, Left, Waiting.Hidden[i].Amount);
			bAny = true;
		}
		Waiting.Hidden.Remove(i, 1);
	}
	if (NewGameState == none)
		return;
	if (bAny)
	{
		NewGameState.GetContext().PostBuildVisualizationFn.Length = 0;
		foreach NewGameState.IterateByClassType(class'XComGameState_LootDrop', Drop)
			NewGameState.GetContext().PostBuildVisualizationFn.AddItem(Drop.VisualizeLootFountainMove);
	}
	`TACTICALRULES.SubmitGameState(NewGameState);
}

/** One canister: a loot drop holding the meld on its tile, gone after Turns. */
static function Canister(XComGameState NewGameState, XComGameState_Unit Source, TTile Tile, int Turns, int Amount)
{
	local XComGameState_Item Item;
	local XComGameState_LootDrop Drop;
	local array<XComGameState_Item> Items;
	local X2ItemTemplate Template;

	Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'X2Item_LWArtifacts'.static.ItemFor('Meld'));
	if (Template == none)
		return;
	Item = Template.CreateInstanceFromTemplate(NewGameState);
	Item.Quantity = Amount;
	Items.AddItem(Item);
	class'XComGameState_LootDrop'.static.CreateLootDrop(NewGameState, Items, Source, true);
	foreach NewGameState.IterateByClassType(class'XComGameState_LootDrop', Drop)
	{
		if (Drop.LastLootOwnerName == "Meld canister")
			continue;
		Drop.TileLocation = Tile;
		Drop.LastLootOwnerName = "Meld canister";
		Drop.LootExpirationTurnsRemaining = Turns;
	}
}

