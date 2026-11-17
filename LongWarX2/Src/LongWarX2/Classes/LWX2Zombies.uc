// Enemy Within's zombies and their Chryssalid eggs (features/lw-aliens.md; EW's XGAIChryssalidEgg, XGUnit.ImplantEgg and
// XComZombieManager, which Long War keeps), in place of XCOM 2's cocoons:
// - a human a Chryssalid kills rises as a zombie (XCOM 2's poison spawns a psi zombie in place of the cocoon: AddZombies), with
//   Long War's zombie stats;
// - such a zombie carries an egg (EW's eZombieDeath stage, 3 turns): when its turns are over a Chryssalid bursts out of it and
//   the zombie dies; a zombie killed before then still lets it out, 4 health down, unless explosives killed it
//   (XGAIChryssalidEgg.CanSurviveDamage);
// - in the Chryssalid hive, a zombie XCOM sees is given an egg of the next stage (the hive's OnEnemySeen: eChryssalidSpawn,
//   1 turn), which hatches only if the zombie is still alive and well.
// The turns are XCOM's (EW counts every side's turns: its stage lengths are rounds); hatching happens as XCOM's turn begins.
class LWX2Zombies extends Object;

/** XCOM 2's Chryssalid poison spawns a psi zombie, not a cocoon (OnPostTemplatesCreated). */
static function AddZombies()
{
	local X2AbilityTemplateManager Manager;
	local X2ItemTemplateManager Items;
	local X2AbilityTemplate Template;
	local X2WeaponTemplate Weapon;
	local X2DataTemplate Data;
	local X2Effect Effect;
	local int n;

	Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach Manager.IterateTemplates(Data, none)
	{
		Template = X2AbilityTemplate(Data);
		if (Template != none)
			foreach Template.AbilityTargetEffects(Effect)
				n += Raise(Effect);
	}
	// (And where the poison rides on a weapon: the Chryssalid's claws.)
	Items = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach Items.IterateTemplates(Data, none)
	{
		Weapon = X2WeaponTemplate(Data);
		if (Weapon != none)
			foreach Weapon.BonusWeaponEffects(Effect)
				n += Raise(Effect);
	}
	`log("LongWarX2: zombies: the Chryssalid's poison raises zombies (" $ n @ "effects)", , 'LongWarX2');
}

static function int Raise(X2Effect Effect)
{
	local X2Effect_ParthenogenicPoison Poison;

	Poison = X2Effect_ParthenogenicPoison(Effect);
	if (Poison == none)
		return 0;
	Poison.UnitToSpawnName = 'PsiZombie';
	Poison.AltUnitToSpawnName = 'PsiZombieHuman';
	return 1;
}

static function bool IsZombie(XComGameState_Unit Unit)
{
	return Unit != none && Unit.GetMyTemplate().CharacterGroupName == 'PsiZombie';
}

/** Asked twice a second in a mission (UIScreenListener_LongWarX2Tactical): risen zombies given Long War's stats and their egg,
 *  the hive's seen zombies theirs, the eggs due hatched. */
static function Update()
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local UnitValue HatchAt, Stage, Species;
	local array<int> Due;
	local array<XComGameState_Unit> Squad;
	local array<vector> At;
	local bool bHive;
	local int Now, ID;

	Now = class'LWX2CovertExtraction'.static.TurnNow();
	bHive = class'LWX2ChryssalidHive'.static.State() != none;
	if (bHive)
		Squad = class'LWX2ChryssalidHive'.static.Seeing();
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!IsZombie(Unit) || Unit.GetTeam() != eTeam_Alien)
			continue;
		if (!Unit.GetUnitValue('LWX2EggHatch', HatchAt))
		{
			// Risen from a Chryssalid's kill (no species yet: the pods' zombies have one): Long War's zombie, and its egg.
			if (!Unit.GetUnitValue('LWX2Species', Species) && Unit.IsAlive())
			{
				if (NewGameState == none)
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a zombie rises");
				Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
				Unit.SetUnitFloatValue('LWX2Species', 14, eCleanup_Never);
				class'LWAlienStats'.static.ApplyTo(Unit, 14, 0, NewGameState);
				Unit.SetUnitFloatValue('LWX2EggHatch', Now + 3, eCleanup_BeginTactical);
				Unit.SetUnitFloatValue('LWX2EggStage', 2, eCleanup_BeginTactical);
				`log("LongWarX2: zombies: a zombie rose; its Chryssalid hatches on turn" @ Now + 3, , 'LongWarX2');
			}
			// The hive's zombies: an egg once XCOM sees them (eChryssalidSpawn, a turn).
			else if (bHive && Unit.IsAlive())
			{
				At.Length = 0;
				At.AddItem(`XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation));
				if (class'LWX2ChryssalidHive'.static.PointSeen(Squad, At))
				{
					if (NewGameState == none)
						NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a hive zombie implanted");
					Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
					Unit.SetUnitFloatValue('LWX2EggHatch', Now + 1, eCleanup_BeginTactical);
					Unit.SetUnitFloatValue('LWX2EggStage', 1, eCleanup_BeginTactical);
					`log("LongWarX2: zombies: a hive zombie seen; its Chryssalid hatches on turn" @ Now + 1, , 'LongWarX2');
				}
			}
			continue;
		}
		if (HatchAt.fValue > 0 && Now >= int(HatchAt.fValue))
			Due.AddItem(Unit.ObjectID);
	}
	if (NewGameState != none)
		`TACTICALRULES.SubmitGameState(NewGameState);
	foreach Due(ID)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ID));
		Unit.GetUnitValue('LWX2EggStage', Stage);
		Hatch(Unit, int(Stage.fValue));
	}
}

/** An egg's turns are over (OnStageComplete): the Chryssalid out of its zombie, or none. */
static function Hatch(XComGameState_Unit Zombie, int Stage)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Spawned;
	local array<name> Names;
	local array<int> Kinds, Before, Hunters;
	local bool bKilled;
	local vector At;

	bKilled = !Zombie.IsAlive();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a zombie's egg");
	Zombie = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Zombie.ObjectID));
	Zombie.SetUnitFloatValue('LWX2EggHatch', -1, eCleanup_BeginTactical);
	// (The hive's egg: only from a zombie alive and well; a zombie's own: not out of one blown up.)
	if ((Stage == 1 && (bKilled || Zombie.IsBleedingOut() || Zombie.IsUnconscious())) || (Stage == 2 && bKilled && Zombie.bKilledByExplosion))
	{
		`TACTICALRULES.SubmitGameState(NewGameState);
		`log("LongWarX2: zombies: an egg died with its zombie", , 'LongWarX2');
		return;
	}
	if (!bKilled)
		Zombie.SetCurrentStat(eStat_HP, 0);
	`TACTICALRULES.SubmitGameState(NewGameState);
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Spawned)
		if (Spawned.GetTeam() == eTeam_Alien)
			Before.AddItem(Spawned.ObjectID);
	At = `XWORLD.GetPositionFromTileCoordinates(Zombie.TileLocation);
	Names.AddItem(class'LWMissionSquads'.static.TemplateFor(13));
	Kinds.AddItem(13);
	class'LWMissionSquads'.static.SpawnPod(name("LWX2_Egg" $ Zombie.ObjectID), At, Names, Kinds);
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Spawned)
		if (Spawned.GetTeam() == eTeam_Alien && Before.Find(Spawned.ObjectID) == INDEX_NONE)
			Hunters.AddItem(Spawned.ObjectID);
	// A zombie killed first: its Chryssalid 4 health down.
	if (bKilled && Hunters.Length > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a weakened Chryssalid");
		Spawned = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Hunters[0]));
		Spawned.SetCurrentStat(eStat_HP, Max(1, int(Spawned.GetCurrentStat(eStat_HP)) - 4));
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	if (Hunters.Length > 0)
		class'LWX2ChryssalidHive'.static.Hunt(Hunters);
	`log("LongWarX2: zombies: a Chryssalid burst out of a zombie" $ (bKilled ? " (killed first: 4 health down)" : ""), , 'LongWarX2');
}
