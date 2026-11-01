// For development (features/lw-classes.md): in a mission, the shot breakdown of each Long War
// soldier's standard shot against the nearest enemies, with each modifier and where it comes from
// (Lone Wolf +10 …), logged whenever it changes. How the perks are checked without playing:
// Skirmish Mode or Tactical Quick Launch with a chosen squad, and this log.
class LWX2PerkProbe extends Actor config(LWAirWar);

var config bool ProbePerks;
var string LastReport;

static function Start(Actor InWorld)
{
	local LWX2PerkProbe Probe;

	if (!default.ProbePerks)
		return;
	foreach InWorld.AllActors(class'LWX2PerkProbe', Probe)
		return;
	Probe = InWorld.Spawn(class'LWX2PerkProbe');
	Probe.SetTimer(5.0, true, nameof(Report));
}

function Report()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit, Enemy;
	local array<XComGameState_Unit> Enemies;
	local StateObjectReference Shot;
	local ShotBreakdown Breakdown;
	local ShotModifierInfo M;
	local string Out, Line;
	local int i, j, Best;
	local float Dist, BestDist;
	local name ShotName;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Left(string(Unit.GetSoldierClassTemplateName()), 4) != "LWS_" || !Unit.IsAlive() || Unit.bRemovedFromPlay)
			continue;
		// The two nearest living enemies.
		Enemies.Length = 0;
		for (j = 0; j < 2; j++)
		{
			Best = -1;
			BestDist = 1000000;
			foreach History.IterateByClassType(class'XComGameState_Unit', Enemy)
			{
				if (!Enemy.IsAlive() || Enemy.bRemovedFromPlay || !Unit.IsEnemyUnit(Enemy) || Enemies.Find(Enemy) != INDEX_NONE)
					continue;
				Dist = Unit.TileDistanceBetween(Enemy);
				if (Dist < BestDist)
				{
					BestDist = Dist;
					Best = Enemy.ObjectID;
				}
			}
			if (Best > 0)
				Enemies.AddItem(XComGameState_Unit(History.GetGameStateForObjectID(Best)));
		}
		ShotName = 'StandardShot';
		Shot = Unit.FindAbility(ShotName);
		if (Shot.ObjectID == 0)
		{
			ShotName = 'SniperStandardFire';
			Shot = Unit.FindAbility(ShotName);
		}
		Out $= Perks(Unit, Enemies.Length > 0 ? Enemies[0] : none);
		for (i = 0; i < Enemies.Length; i++)
		{
			class'XComGameState_Ability'.static.LookupShotBreakdown(Unit.GetReference(), Enemies[i].GetReference(), Shot, Breakdown);
			Line = Unit.GetSoldierClassTemplateName() @ Unit.GetFullName() @ ShotName @ "->" @ Enemies[i].GetMyTemplateName() @ "at" @ Unit.TileDistanceBetween(Enemies[i]) @ "tiles: hit" @ Breakdown.FinalHitChance @ "crit" @ Breakdown.ResultTable[eHit_Crit] $ ";";
			foreach Breakdown.Modifiers(M)
				Line @= M.Reason $ ":" $ (M.ModType == eHit_Crit ? "crit" : (M.ModType == eHit_Success ? "aim" : string(M.ModType))) $ "=" $ M.Value;
			Out $= Line $ "\n";
		}
		Enemies.Length = 0;
	}
	if (Out == LastReport)
		return;
	LastReport = Out;
	`log("LongWarX2: perk probe:\n" $ Out, , 'LongWarX2');
}

/** The unit's Long War bonus effects, each with its numbers and whether its conditions hold against Target now. */
function string Perks(XComGameState_Unit Unit, XComGameState_Unit Target)
{
	local StateObjectReference Ref;
	local XComGameState_Effect EffectState;
	local X2Effect_LWModifiers E;
	local string Out;

	Out = "  " $ Unit.GetSoldierClassTemplateName() @ Unit.GetFullName() @ "rank" @ Unit.GetRank() $ ":";
	foreach Unit.AffectedByEffects(Ref)
	{
		EffectState = XComGameState_Effect(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		E = EffectState != none ? X2Effect_LWModifiers(EffectState.GetX2Effect()) : none;
		if (E == none)
			continue;
		Out @= string(E.EffectName) $ "[";
		if (E.Aim != 0) Out $= "aim" $ E.Aim $ "x" $ E.Holds(E.AimIf, Unit, Target, none, false) $ " ";
		if (E.Crit != 0) Out $= "crit" $ E.Crit $ "x" $ E.Holds(E.CritIf, Unit, Target, none, false) $ " ";
		if (E.Defense != 0) Out $= "def" $ E.Defense $ "x" $ E.Holds(E.DefenseIf, Target, Unit, none, true) $ " ";
		if (E.Damage != 0) Out $= "dmg" $ E.Damage $ (E.DamageIf != '' ? "if" $ E.DamageIf : "") $ " ";
		if (E.DamagePct != 0) Out $= "dmg" $ E.DamagePct $ "%if" $ E.DamageIf $ " ";
		if (E.CritAgainst != 0) Out $= "critimmune ";
		Out $= "]";
	}
	return Out $ "\n";
}

defaultproperties
{
	bHidden = true;
}
