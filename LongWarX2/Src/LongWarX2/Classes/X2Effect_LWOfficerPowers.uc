// The squad's officer powers on each of its soldiers (features/lw-officers.md): the powers of the squad's leader, marked on
// every soldier at launch (LWOfficers.MarkSquad: LWX2SquadPowers), as Long War copies the leader's medal perks to the squad.
// Stats for the mission: Legio Patria Nostra (will per nationality in the squad), Band of Warriors (aim per continent bonus
// held), Esprit de Corps (will, not for robots, and defence). When shot at: Semper Vigilans (defence in cover).
// Combined Arms and Fortiores Una act through Long War's damage reduction (X2Ability_LWDamageReduction).
class X2Effect_LWOfficerPowers extends X2Effect_ModifyStats;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Unit;
	local StatChange Change;
	local int Will, Aim;

	Unit = XComGameState_Unit(kNewTargetState);
	if (Unit != none)
	{
		if (class'LWOfficers'.static.SquadHad(Unit, class'LWOfficers'.const.LEGIO_PATRIA_NOSTRA))
			Will += class'LWOfficers'.default.InternationalWill * Nationalities();
		if (class'LWOfficers'.static.SquadHad(Unit, class'LWOfficers'.const.ESPRIT_DE_CORPS) && !Unit.IsRobotic())
			Will += class'LWOfficers'.default.TerraWill;
		if (class'LWOfficers'.static.SquadHad(Unit, class'LWOfficers'.const.BAND_OF_WARRIORS))
			Aim += class'LWOfficers'.default.InternationalAim * ContinentBonuses();
		if (Will != 0)
		{
			Change.StatType = eStat_Will;
			Change.StatAmount = Will;
			NewEffectState.StatChanges.AddItem(Change);
		}
		if (Aim != 0)
		{
			Change.StatType = eStat_Offense;
			Change.StatAmount = Aim;
			NewEffectState.StatChanges.AddItem(Change);
		}
		if (class'LWOfficers'.static.SquadHad(Unit, class'LWOfficers'.const.ESPRIT_DE_CORPS))
		{
			Change.StatType = eStat_Defense;
			Change.StatAmount = class'LWOfficers'.default.TerraDefense;
			NewEffectState.StatChanges.AddItem(Change);
		}
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

/** The different nationalities among XCOM's soldiers in this mission. */
static function int Nationalities()
{
	local XComGameState_Unit Unit;
	local array<name> Seen;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.IsSoldier() && Unit.GetTeam() == eTeam_XCom && !Unit.bRemovedFromPlay && Seen.Find(Unit.GetCountry()) == INDEX_NONE)
			Seen.AddItem(Unit.GetCountry());
	return Seen.Length;
}

/** The continent bonuses XCOM holds (every country of the continent under a satellite). */
static function int ContinentBonuses()
{
	local XComGameState_LWStrategy S;
	local int c, n;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return 0;
	for (c = 0; c < 8; c++)
		if (class'LWBonuses'.static.ContinentCovered(S, c))
			n++;
	return n;
}

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local GameRulesCache_VisibilityInfo VisInfo;
	local ShotModifierInfo Mod;

	if (Target == none || Attacker == none || !class'LWOfficers'.static.SquadHad(Target, class'LWOfficers'.const.SEMPER_VIGILANS))
		return;
	// In cover as the attacker sees it (flanked: none).
	if (!`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo) || VisInfo.TargetCover == CT_None)
		return;
	Mod.ModType = eHit_Success;
	Mod.Value = -class'LWOfficers'.default.UrbanDefense;
	Mod.Reason = class'LWOfficers'.static.PowerName(class'LWOfficers'.const.SEMPER_VIGILANS);
	ShotModifiers.AddItem(Mod);
}

defaultproperties
{
	EffectName = "LWX2_OfficerPowers"
	DuplicateResponse = eDupe_Ignore
}
