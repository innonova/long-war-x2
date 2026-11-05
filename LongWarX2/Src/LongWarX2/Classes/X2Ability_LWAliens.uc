// Long War's aliens' passives (features/lw-aliens.md): their damage bonus from the aliens' research, given to every alien
// template Long War's species fight as (LWAlienStats.AddAbilities); and species' own abilities XCOM 2 has nothing like
// (the Muton's Blood Call, the Drone's repair), given by species (LWAlienStats, +SpeciesAbilities). EW's numbers are its
// constants (XGTacticalGameCoreNativeBase), set here from the config.
class X2Ability_LWAliens extends X2Ability config(LWAliens);

/** Blood Call (EW's BLOODCALL_*): aim, will and mobility for the Muton's allies within BloodCallTiles, for its turn and the next. */
var config int BloodCallAim, BloodCallWill, BloodCallMobility, BloodCallTiles;
/** The Drone's repair (EW's DRONE_REPAIR_HP): a damaged robotic ally within RepairTiles. */
var config int RepairHP, RepairTiles;
/** The Cyberdisc's Death Blossom (EW's DEATH_BLOSSOM_*): everyone within DeathBlossomTiles of it takes DeathBlossomMin to
 *  DeathBlossomMax damage; then DeathBlossomCooldown turns. */
var config int DeathBlossomTiles, DeathBlossomMin, DeathBlossomMax, DeathBlossomCooldown;
/** Intimidate (EW's INTIMIDATE_CHANCE_MUTON, _BERSERKER; the morale event's will and the panic test's chance at even will). */
var config int IntimidateChance, IntimidateChanceBerserker, IntimidateMorale, IntimidateEvenFail;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AlienDamage());
	Templates.AddItem(BloodCall());
	Templates.AddItem(Repair());
	Templates.AddItem(DeathBlossom());
	Templates.AddItem(Launch());
	Templates.AddItem(Strangle('LW_Strangle'));
	Templates.AddItem(Strangle('LW_StrangleSustained'));
	Templates.AddItem(SeekerCloak());
	Templates.AddItem(Intimidate('LW_Intimidate', default.IntimidateChance));
	Templates.AddItem(Intimidate('LW_IntimidateBerserker', default.IntimidateChanceBerserker));
	return Templates;
}

static function X2AbilityTemplate AlienDamage()
{
	local X2AbilityTemplate Template;
	local X2Effect_LWAlienDamage Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LWX2_AlienDamage');
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Effect = new class'X2Effect_LWAlienDamage';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.EffectName = 'LWX2_AlienDamage';
	Template.AddTargetEffect(Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

/** The Muton's Blood Call: its allies near it (and itself) gain aim, will and mobility; once a battle. */
static function X2AbilityTemplate BloodCall()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2AbilityCharges Charges;
	local X2AbilityCost_Charges ChargeCost;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Condition_UnitProperty Allies;
	local X2Effect_PersistentStatChange Called;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LW_BloodCall');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_bloodcall";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(Cost);
	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = 1;
	Template.AbilityCharges = Charges;
	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);
	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.BloodCallTiles * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	Radius.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = Radius;
	Allies = new class'X2Condition_UnitProperty';
	Allies.ExcludeHostileToSource = true;
	Allies.ExcludeFriendlyToSource = false;
	Allies.ExcludeDead = true;
	Allies.ExcludeCivilian = true;
	Template.AbilityMultiTargetConditions.AddItem(Allies);
	Called = new class'X2Effect_PersistentStatChange';
	Called.EffectName = 'LW_BloodCalled';
	Called.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnBegin);
	Called.AddPersistentStatChange(eStat_Offense, default.BloodCallAim);
	Called.AddPersistentStatChange(eStat_Will, default.BloodCallWill);
	Called.AddPersistentStatChange(eStat_Mobility, default.BloodCallMobility);
	Called.DuplicateResponse = eDupe_Refresh;
	Template.AddTargetEffect(Called);
	Template.AddMultiTargetEffect(Called);
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

/** The Drone's repair: a damaged robotic ally within RepairTiles regains RepairHP. */
static function X2AbilityTemplate Repair()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2Condition_UnitProperty Damaged;
	local X2Effect_ApplyMedikitHeal Heal;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LW_Repair');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_repair";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Defensive;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Cost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(Cost);
	Damaged = new class'X2Condition_UnitProperty';
	Damaged.ExcludeHostileToSource = true;
	Damaged.ExcludeFriendlyToSource = false;
	Damaged.ExcludeDead = true;
	Damaged.ExcludeOrganic = true;
	Damaged.ExcludeFullHealth = true;
	Damaged.RequireWithinRange = true;
	Damaged.WithinRange = default.RepairTiles * class'XComWorldData'.const.WORLD_StepSize;
	Damaged.FailOnNonUnits = true;
	Template.AbilityTargetConditions.AddItem(Damaged);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Heal = new class'X2Effect_ApplyMedikitHeal';
	Heal.PerUseHP = default.RepairHP;
	Template.AddTargetEffect(Heal);
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

/** The Cyberdisc's Death Blossom: everyone around it within DeathBlossomTiles hit, friend or foe, the scenery too. */
static function X2AbilityTemplate DeathBlossom()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2AbilityCooldown Cooldown;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Condition_UnitProperty Living;
	local X2Condition_LWEnemyNear Near;
	local X2Effect_ApplyWeaponDamage Damage;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LW_DeathBlossom');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_deathblossom";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Near = new class'X2Condition_LWEnemyNear';
	Near.Tiles = default.DeathBlossomTiles;
	Template.AbilityShooterConditions.AddItem(Near);
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Cost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(Cost);
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.DeathBlossomCooldown;
	Template.AbilityCooldown = Cooldown;
	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.DeathBlossomTiles * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	Radius.bExcludeSelfAsTargetIfWithinRadius = true;
	Template.AbilityMultiTargetStyle = Radius;
	Living = new class'X2Condition_UnitProperty';
	Living.ExcludeDead = true;
	Living.ExcludeFriendlyToSource = false;
	Template.AbilityMultiTargetConditions.AddItem(Living);
	Damage = new class'X2Effect_ApplyWeaponDamage';
	Damage.bIgnoreBaseDamage = true;
	Damage.EffectDamageValue.Damage = (default.DeathBlossomMin + default.DeathBlossomMax) / 2;
	Damage.EffectDamageValue.Spread = (default.DeathBlossomMax - default.DeathBlossomMin) / 2;
	Damage.EnvironmentalDamageAmount = 10;
	Template.AddMultiTargetEffect(Damage);
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

/**
 * The Floater's Launch (EW's eAbility_Launch): it jets up and comes down anywhere in sight of its side with open sky above,
 * and its turn is over (a fire action in EW). As EW's AI has it: only with another Floater on the field, one Floater a turn
 * (XGAIPlayer.UpdateLaunchCandidate), each every other turn at most, from under open sky. Played as XCOM 2's teleport (the
 * Codex's): its game state and path, its start and stop animations (EW's jet up and jet down, converted under those names,
 * tools/convert/ew-unit-anims.ts).
 */
static function X2AbilityTemplate Launch()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2AbilityTarget_Cursor Cursor;
	local X2Condition_UnitProperty Outdoors;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LW_Launch');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_codex_teleport";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Movement;
	Template.AbilityToHitCalc = default.DeadEye;
	Cursor = new class'X2AbilityTarget_Cursor';
	Cursor.bRestrictToSquadsightRange = true;
	Template.AbilityTargetStyle = Cursor;
	Template.TargetingMethod = class'X2TargetingMethod_LWLaunch';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Outdoors = new class'X2Condition_UnitProperty';
	Outdoors.ExcludeFriendlyToSource = false;
	Outdoors.IsOutdoors = true;
	Outdoors.HasClearanceToMaxZ = true;
	Template.AbilityShooterConditions.AddItem(Outdoors);
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_LWLaunchMate');
	Template.AddShooterEffectExclusions();
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Cost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(Cost);
	// One Floater a turn; each again two of its turns later (EW's MIN_TURNS_TO_LAUNCH, its battle's turns being rounds).
	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = 2;
	Cooldown.NumGlobalTurns = 1;
	Template.AbilityCooldown = Cooldown;
	Template.ModifyNewContextFn = Launch_ModifyContext;
	Template.BuildNewGameStateFn = class'X2Ability_Cyberus'.static.Teleport_BuildGameState;
	Template.BuildVisualizationFn = Launch_BuildVisualization;
	Template.bFrameEvenWhenUnitIsHidden = true;
	return Template;
}

/** A spot with open sky above it (EW's HasOverheadClearance for a Launch, to the top of the level). */
static function bool OpenSky(vector Loc)
{
	return `XWORLD.HasOverheadClearance(Loc, class'XComWorldData'.const.WORLD_FloorHeightsPerLevel * class'XComWorldData'.const.WORLD_TotalLevels * class'XComWorldData'.const.WORLD_FloorHeight);
}

/**
 * The path: XCOM 2's teleport's. The AI's destination search knows nothing of the sky, so a spot under a roof is moved to
 * the nearest floor within three tiles that has open sky (the player's cursor allows only those).
 */
static simulated function Launch_ModifyContext(XComGameStateContext Context)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComWorldData World;
	local TTile Tile, Try, Best;
	local vector Loc;
	local int X, Y, Z, D, BestD;

	AbilityContext = XComGameStateContext_Ability(Context);
	World = `XWORLD;
	if (AbilityContext.InputContext.TargetLocations.Length > 0)
		Loc = AbilityContext.InputContext.TargetLocations[0];
	if (AbilityContext.InputContext.TargetLocations.Length > 0 && !OpenSky(Loc))
	{
		Tile = World.GetTileCoordinatesFromPosition(Loc);
		BestD = 1000;
		for (X = -3; X <= 3; X++)
			for (Y = -3; Y <= 3; Y++)
				for (Z = -2; Z <= 2; Z++)
				{
					Try = Tile;
					Try.X += X;
					Try.Y += Y;
					Try.Z += Z;
					D = X * X + Y * Y + Z * Z;
					if (D >= BestD || !World.IsFloorTileAndValidDestination(Try) || World.IsTileOccupied(Try))
						continue;
					Loc = World.GetPositionFromTileCoordinates(Try);
					if (!OpenSky(Loc))
						continue;
					Best = Try;
					BestD = D;
				}
		if (BestD < 1000)
			AbilityContext.InputContext.TargetLocations[0] = World.GetPositionFromTileCoordinates(Best);
		`log("LongWarX2: Launch: no open sky at" @ Tile.X $ "," $ Tile.Y $ "," $ Tile.Z $ (BestD < 1000 ? ", lands at" @ Best.X $ "," $ Best.Y $ "," $ Best.Z : ", none near"), , 'LongWarX2');
	}
	if (AbilityContext.InputContext.TargetLocations.Length > 0)
	{
		Loc = AbilityContext.InputContext.TargetLocations[0];
		Tile = World.GetTileCoordinatesFromPosition(Loc);
		`log("LongWarX2: Launch: unit" @ AbilityContext.InputContext.SourceObject.ObjectID @ "to" @ Tile.X $ "," $ Tile.Y $ "," $ Tile.Z, , 'LongWarX2');
	}
	class'X2Ability_Cyberus'.static.Teleport_ModifyActivatedAbilityContext(Context);
}

/** XCOM 2's teleport's visualization (X2Ability_Cyberus.Teleport_BuildVisualization), for a unit alone: turn, then the path. */
simulated function Launch_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local VisualizationActionMetadata Track;
	local X2Action_MoveTurn Turn;

	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	Track.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	Track.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);
	Track.VisualizeActor = History.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID);
	Turn = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(Track, AbilityContext));
	Turn.m_vFacePoint = AbilityContext.InputContext.TargetLocations[0];
	class'X2VisualizerHelpers'.static.ParsePath(AbilityContext, Track);
}

/**
 * The Seeker's Strangle (EW's eAbility_Strangle) and its hold each turn after: played as XCOM 2's Bind (the Viper's): the
 * Seeker and the soldier held where they meet, neither acting, until the soldier dies or the Seeker is hurt (EW's abort with
 * a wound: XCOM 2's bind broken by any damage to its source) or dies. EW's damage (X2Effect_LWStrangleDamage) in place of
 * the Viper's; the Seeker's animations are EW's strangle under Bind's names (tools/convert/ew-unit-anims.ts).
 */
static function X2AbilityTemplate Strangle(name AbilityName)
{
	local X2AbilityTemplate Template;
	local X2Effect Effect;
	local X2Condition Condition;
	local X2Effect_RemoveEffects Uncloak;

	if (AbilityName == 'LW_Strangle')
	{
		Template = class'X2Ability_Viper'.static.CreateBindAbility(true, AbilityName, 'LW_StrangleSustained');
		Template.AdditionalAbilities.RemoveItem('BindSustained');
		Template.AdditionalAbilities.AddItem('LW_StrangleSustained');
	}
	else
		Template = class'X2Ability_Viper'.static.CreateBindSustainedAbility(AbilityName);
	// The Viper's damage switched off (the template's effects are its own to write), EW's added.
	foreach Template.AbilityTargetEffects(Effect)
	{
		if (X2Effect_ViperBindSustained(Effect) != none)
			X2Effect_ViperBindSustained(Effect).FragileAmount = 1;
		if (Effect.Class == class'X2Effect_ApplyWeaponDamage')
			Effect.bApplyOnHit = false;
	}
	Template.AddTargetEffect(new class'X2Effect_LWStrangleDamage');
	// Seizing someone shows a cloaked Seeker (LW_SeekerCloak).
	if (AbilityName == 'LW_Strangle')
	{
		Uncloak = new class'X2Effect_RemoveEffects';
		Uncloak.EffectNamesToRemove.AddItem('LW_SeekerCloak');
		Template.AddShooterEffect(Uncloak);
	}
	// A soldier in high cover can be seized too (XCOM 2's Viper cannot bind one; EW's Seeker strangles anyone it reaches).
	foreach Template.AbilityTargetConditions(Condition)
		if (X2Condition_Visibility(Condition) != none)
			X2Condition_Visibility(Condition).bRequireNotMatchCoverType = false;
	return Template;
}

/**
 * The Seeker's stealth (EW's eAbility_Stealth): it cloaks as a move (an action, not its turn) and is out of its enemies'
 * sight and reach until it seizes someone, is hurt (EW's abort with a wound), or five of its turns have passed (EW ends it
 * after five turns unseen). Played as XCOM 2's Vanish (the Chosen Assassin's): hidden from XCOM's side in play and on
 * screen, shown again when it ends. EW's AI cloaks only with someone to strangle and no soldier able to see it near;
 * here XCOM 2's tree cloaks as the first action when it cannot strangle yet.
 */
static function X2AbilityTemplate SeekerCloak()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2Effect_Vanish Cloak;
	local X2Condition_UnitEffects NotCloaked;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LW_SeekerCloak');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_vanishingwind";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	NotCloaked = new class'X2Condition_UnitEffects';
	NotCloaked.AddExcludeEffect('LW_SeekerCloak', 'AA_DuplicateEffectIgnored');
	NotCloaked.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BoundName, 'AA_UnitIsBound');
	Template.AbilityShooterConditions.AddItem(NotCloaked);
	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(Cost);
	Cloak = new class'X2Effect_Vanish';
	Cloak.EffectName = 'LW_SeekerCloak';
	Cloak.BuildPersistentEffect(5, false, true, false, eGameRule_PlayerTurnBegin);
	Cloak.bRemoveWhenSourceDamaged = true;
	Cloak.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(Cloak);
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

/**
 * The Muton's Intimidate (EW's eAbility_Intimidate; the Berserker's comes with its Bloodlust, at its own chance): hurt by a
 * soldier on that soldier's turn (not by overwatch), once a turn, with the soldier in sight, the Muton may intimidate them:
 * a panic test (X2AbilityToHitCalc_LWIntimidate) and XCOM 2's panic if failed. EW's Berserker also charges at whoever hurt
 * it (its Bloodlust); not here.
 */
static function X2AbilityTemplate Intimidate(name AbilityName, int Chance)
{
	local X2AbilityTemplate Template;
	local X2AbilityToHitCalc_LWIntimidate HitCalc;
	local X2AbilityTrigger_EventListener Trigger;
	local X2AbilityCooldown Cooldown;
	local X2Condition_UnitProperty Soldier;
	local X2Condition_UnitEffects NotPanicked;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_intimidate";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Offensive;
	HitCalc = new class'X2AbilityToHitCalc_LWIntimidate';
	HitCalc.Chance = Chance;
	HitCalc.Morale = default.IntimidateMorale;
	HitCalc.EvenFail = default.IntimidateEvenFail;
	Template.AbilityToHitCalc = HitCalc;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'UnitTakeEffectDamage';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = IntimidateListener;
	Template.AbilityTriggers.AddItem(Trigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Soldier = new class'X2Condition_UnitProperty';
	Soldier.ExcludeDead = true;
	Soldier.ExcludeFriendlyToSource = true;
	Soldier.ExcludeRobotic = true;
	Template.AbilityTargetConditions.AddItem(Soldier);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	NotPanicked = new class'X2Condition_UnitEffects';
	NotPanicked.AddExcludeEffect(class'X2AbilityTemplateManager'.default.PanickedName, 'AA_UnitIsPanicked');
	Template.AbilityTargetConditions.AddItem(NotPanicked);
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 1;
	Template.AbilityCooldown = Cooldown;
	Template.AddTargetEffect(class'X2StatusEffects'.static.CreatePanickedStatusEffect());
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

/** A Muton hurt: Intimidate against whoever hurt it, if that was an enemy acting on their own side's turn. */
static function EventListenerReturn IntimidateListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Ability Ability;
	local XComGameState_Unit Me, Attacker;
	local XComGameStateContext_Ability Context;

	Ability = XComGameState_Ability(CallbackData);
	Me = XComGameState_Unit(EventData);
	Context = XComGameStateContext_Ability(GameState.GetContext());
	if (Ability == none || Me == none || Context == none || !Me.IsAlive())
		return ELR_NoInterrupt;
	Attacker = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	if (Attacker == none || !Attacker.IsEnemyUnit(Me) || Attacker.ControllingPlayer.ObjectID != `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID)
		return ELR_NoInterrupt;
	Ability.AbilityTriggerAgainstSingleTarget(Attacker.GetReference(), false);
	return ELR_NoInterrupt;
}
