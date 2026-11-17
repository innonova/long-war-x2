// The assault on XCOM's headquarters on its EW map (features/lw-story.md): not Long War's squad at the map's pods (EW's level
// culls them at its start) but the level's own Kismet, run by LWX2Kismet, with EW's wave system (LWX2WaveSystem) bringing the
// aliens and the base's soldiers coming as reinforcements (SeqAct_SpawnReinforcement: Reinforce). The game's side of it: the
// events the Kismet listens to (the level loaded, the roaming alien count, the battle begun, the turns, units killed), the
// waves at the aliens' turns, the script's objectives, and no victory before the script releases it (Delay Victory, at its
// final wave) and the wave system is done.
class LWX2HQAssault extends Object;

/** The HQ assault being played: its plot, with its level's Kismet exported on this machine. */
static function bool Active()
{
	local XComGameState_BattleData Battle;

	if (class'LWX2Kismet'.static.LevelOf("EWI_HQAssault_Stream") <= 0)
		return false;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	return Battle != none && Battle.MapData.PlotMapName ~= "LWX2_EWI_HQAssault";
}

/** Asked twice a second in the mission (UIScreenListener_LongWarX2Tactical). False while the battle cannot be won. */
static function bool Update()
{
	local XComGameState_LWX2Kismet K;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local array<int> Squad, Dead;
	local int ID;

	if (!Active())
		return true;
	K = class'LWX2Kismet'.static.Current();
	if (K == none)
	{
		Squad = class'LWMissionSquads'.static.SquadNow();
		class'LWX2Kismet'.static.Begin(class'LWX2Kismet'.static.LevelOf("EWI_HQAssault_Stream"), Squad);
		// (EW's XGBattle: the roaming alien count, then its begin block done; then XCOM's first turn.)
		class'LWX2Kismet'.static.Fire('SeqEvent_RoamingAlienNumberSet', , , Squad.Length);
		class'LWX2Kismet'.static.Fire('SeqEvent_RemoteEvent', "XGBattle_Running_BeginBlockFinished");
		class'LWX2Kismet'.static.Fire('SeqEvent_OnPlayerBeginTurn');
		return false;
	}
	// Units killed since: each an OnUnitKilled, as its instigator.
	K = class'LWX2Kismet'.static.Current();
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (!Unit.IsAlive() && !Unit.GetMyTemplate().bIsCosmetic && K.DeadSeen.Find(Unit.ObjectID) == INDEX_NONE)
			Dead.AddItem(Unit.ObjectID);
	if (Dead.Length > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the HQ assault's dead");
		K = XComGameState_LWX2Kismet(NewGameState.ModifyStateObject(class'XComGameState_LWX2Kismet', K.ObjectID));
		foreach Dead(ID)
			K.DeadSeen.AddItem(ID);
		`TACTICALRULES.SubmitGameState(NewGameState);
		foreach Dead(ID)
			class'LWX2Kismet'.static.Fire('SeqEvent_OnUnitKilled', , ID);
	}
	K = class'LWX2Kismet'.static.Current();
	return K.bVictoryReleased && !class'LWX2WaveSystem'.static.Active();
}

/** A side's turn begun or ended (XComGameState_LWX2Kismet's turn events): the script's turn events, and the wave system at
 *  both ends of the aliens' turn (EW's XGAIPlayer: OnBeginTurn, OnEndTurn). */
static function Turn(ETeam Team, bool bBegun)
{
	if (!Active() || class'LWX2Kismet'.static.Current() == none)
		return;
	if (Team == eTeam_XCom)
		class'LWX2Kismet'.static.Fire(bBegun ? 'SeqEvent_OnPlayerBeginTurn' : 'SeqEvent_OnPlayerEndingTurn');
	else if (Team == eTeam_Alien)
	{
		if (bBegun)
		{
			class'LWX2Kismet'.static.Fire('SeqEvent_OnAlienBeginTurn');
			class'LWX2WaveSystem'.static.Update(0);
		}
		else
		{
			class'LWX2Kismet'.static.Fire('SeqEvent_OnAlienEndingTurn');
			class'LWX2WaveSystem'.static.Update(1);
		}
	}
}

static function string ObjectiveText()
{
	return Active() ? class'LWX2Kismet'.static.ObjectiveText() : "";
}

/** An XCOM reinforcement (EW's SpawnNextReinforcement): one of the base's soldiers not on the field, or a blueshirt (base
 *  security, made for the battle) when asked for one or when no soldier is left; placed at the destination point. */
static function Reinforce(vector From, vector To, bool bBlueshirt)
{
	local XComGameState_Unit Unit;
	local vector At;

	At = To;
	if (!class'LWMissionSquads'.static.EnterableNear(`XWORLD, At))
	{
		At = From;
		if (!class'LWMissionSquads'.static.EnterableNear(`XWORLD, At))
		{
			`log("LongWarX2: HQ assault: no floor for a reinforcement near" @ To, , 'LongWarX2');
			return;
		}
	}
	Unit = bBlueshirt ? none : ChooseStrategyUnit();
	if (Unit != none)
		Unit = AddStrategyUnitToBoard(Unit, At);
	else
		Unit = AddBlueshirt(At);
	`log("LongWarX2: HQ assault: reinforcement" @ (Unit != none ? Unit.GetFullName() : "none") @ (bBlueshirt ? "(blueshirt asked)" : "") @ "at" @ At, , 'LongWarX2');
}

/** A soldier of the base (the crew in the strategy game before the mission) not on the field: alive, not wounded, not away
 *  (as XCOM 2's SeqAct_SpawnUnitFromAvenger chooses, the wounded left out). */
static function XComGameState_Unit ChooseStrategyUnit()
{
	local XComGameStateHistory History;
	local array<int> InPlay;
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState StrategyState;
	local int Last;

	History = `XCOMHISTORY;
	Last = History.FindStartStateIndex() - 1;
	if (Last <= 0)
		return none;
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
		InPlay.AddItem(Unit.ObjectID);
	StrategyState = History.GetGameStateFromHistory(Last, eReturnType_Copy, false);
	foreach StrategyState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
		break;
	foreach StrategyState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.IsDead() || !Unit.IsSoldier() || Unit.IsTraining() || Unit.IsOnCovertAction() || Unit.IsInjured())
			continue;
		if (XComHQ != none && XComHQ.Crew.Find('ObjectID', Unit.ObjectID) == INDEX_NONE)
			continue;
		if (InPlay.Find(Unit.ObjectID) != INDEX_NONE)
			continue;
		return Unit;
	}
	return none;
}

/** A strategy unit put on the field (SeqAct_SpawnUnitFromAvenger.AddStrategyUnitToBoard), on XCOM's side, with its items
 *  and abilities; it goes home with the squad (bSpawnedFromAvenger). */
static function XComGameState_Unit AddStrategyUnitToBoard(XComGameState_Unit Unit, vector At)
{
	local X2TacticalGameRuleset Rules;
	local XComGameStateContext_TacticalGameRule Context;
	local XComGameState NewGameState;
	local XComGameState_Player Player;
	local StateObjectReference ItemRef;
	local XComGameState_Item Item;

	Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UnitAdded);
	NewGameState = Context.ContextBuildGameState();
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Unit.BeginTacticalPlay(NewGameState);
	Unit.SetVisibilityLocationFromVector(At);
	Unit.bSpawnedFromAvenger = true;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', Player)
		if (Player.GetTeam() == eTeam_XCom)
		{
			Unit.SetControllingPlayer(Player.GetReference());
			break;
		}
	foreach Unit.InventoryItems(ItemRef)
	{
		Item = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemRef.ObjectID));
		Item.BeginTacticalPlay(NewGameState);
		Item.CreateCosmeticItemUnit(NewGameState);
	}
	Rules = `TACTICALRULES;
	XComGameStateContext_TacticalGameRule(NewGameState.GetContext()).UnitRef = Unit.GetReference();
	Rules.SubmitGameState(NewGameState);
	Unit.FindOrCreateVisualizer(NewGameState);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a reinforcement's abilities");
	Rules.InitializeUnitAbilities(NewGameState, Unit);
	Rules.SubmitGameState(NewGameState);
	return Unit;
}

/** Base security made for the battle (EW's blueshirts): a rookie of XCOM 2's soldier template with its loadout, on XCOM's
 *  side; not a member of the crew afterwards. */
static function XComGameState_Unit AddBlueshirt(vector At)
{
	local X2TacticalGameRuleset Rules;
	local XComGameStateContext_TacticalGameRule Context;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local XComGameState_Player Player;
	local X2CharacterTemplate Template;
	local XGCharacterGenerator Generator;
	local TSoldier Soldier;

	Template = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('Soldier');
	if (Template == none)
		return none;
	Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UnitAdded);
	NewGameState = Context.ContextBuildGameState();
	Unit = Template.CreateInstanceFromTemplate(NewGameState);
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', Player)
		if (Player.GetTeam() == eTeam_XCom)
		{
			Unit.SetControllingPlayer(Player.GetReference());
			break;
		}
	Unit.ApplyInventoryLoadout(NewGameState);
	Generator = `XCOMGRI.Spawn(Template.CharacterGeneratorClass);
	if (Generator != none)
	{
		Soldier = Generator.CreateTSoldier();
		Unit.SetTAppearance(Soldier.kAppearance);
		Unit.SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
		Unit.SetCountry(Soldier.nmCountry);
		Generator.Destroy();
	}
	Unit.SetVisibilityLocationFromVector(At);
	Rules = `TACTICALRULES;
	Rules.InitializeUnitAbilities(NewGameState, Unit);
	XComGameStateContext_TacticalGameRule(NewGameState.GetContext()).UnitRef = Unit.GetReference();
	Rules.SubmitGameState(NewGameState);
	return Unit;
}
