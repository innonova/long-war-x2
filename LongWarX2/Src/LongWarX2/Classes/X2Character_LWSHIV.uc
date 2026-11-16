// Long War's SHIVs as XCOM 2 characters (features/lw-shivs-mecs.md): one per body (SHIV, Alloy SHIV, Hover SHIV), a robot on
// XCOM's side that XCOM 2 puts in a squad as it does War of the Chosen's SPARKs (a soldier, robotic), on the ADVENT MEC's
// pawn (a robot's walk and death; no cover, as XCOM 2's robots); Long War's stats: the SHIV's (eChar_Tank) plus its deck's
// (Armors) and the hit points repair restores. No will, no panic, no ranks (its class, LWS_SHIV, has none).
class X2Character_LWSHIV extends X2Character dependson(LWSHIVs);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWSHIVs.LWSHIVBody B;

	foreach class'LWSHIVs'.default.Bodies(B)
		Templates.AddItem(SHIVTemplate(B));
	return Templates;
}

static function X2CharacterTemplate SHIVTemplate(LWSHIVs.LWSHIVBody B)
{
	local X2CharacterTemplate T;
	local LWSHIVs.LWSHIVStats S;

	`CREATE_X2CHARACTER_TEMPLATE(T, B.Template);
	S = class'LWSHIVs'.default.Base;
	T.CharacterGroupName = 'LWSHIV';
	T.BehaviorClass = class'XGAIBehavior';
	T.strPawnArchetypes.AddItem("GameUnit_AdvMEC_M3.ARC_GameUnit_AdvMEC_M3");
	T.UnitSize = 1;
	T.UnitHeight = 2;
	T.bCanUse_eTraversal_Normal = true;
	T.bCanUse_eTraversal_ClimbOver = true;
	T.bCanUse_eTraversal_ClimbOnto = true;
	T.bCanUse_eTraversal_ClimbLadder = false;
	T.bCanUse_eTraversal_DropDown = true;
	T.bCanUse_eTraversal_Grapple = false;
	T.bCanUse_eTraversal_Landing = true;
	T.bCanUse_eTraversal_BreakWindow = true;
	T.bCanUse_eTraversal_KickDoor = true;
	T.bCanUse_eTraversal_JumpUp = B.Fly;
	T.bCanUse_eTraversal_Flying = B.Fly;
	T.bCanUse_eTraversal_WallClimb = false;
	T.bCanUse_eTraversal_BreakWall = false;
	T.bAppearanceDefinesPawn = false;
	T.bCanTakeCover = false;
	T.bAllowRushCam = false;
	T.bIsAlien = false;
	T.bIsAdvent = false;
	T.bIsCivilian = false;
	T.bIsPsionic = false;
	T.bIsRobotic = true;
	T.bIsSoldier = true;
	T.bCanBeCriticallyWounded = false;
	T.bCanBeTerrorist = false;
	T.bCanBeCarried = false;
	T.bCanBeRevived = false;
	T.bDiesWhenCaptured = true;
	T.bIsAfraidOfFire = false;
	T.bUsePoolSoldiers = false;
	T.bIsTooBigForArmory = true;
	T.bStaffingAllowed = false;
	T.bAppearInBase = false;
	T.bIgnoreEndTacticalHealthMod = true;
	T.bUsesWillSystem = false;
	T.DefaultSoldierClass = class'LWSHIVs'.default.SoldierClass;
	T.strMatineePackages.AddItem("CIN_AdventMEC");
	T.strTargetingMatineePrefix = "CIN_AdventMEC_FF_StartPos";
	T.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_XCom;
	T.Abilities.AddItem('RobotImmunities');
	T.Abilities.AddItem('Loot');
	T.Abilities.AddItem('Evac');
	T.Abilities.AddItem('PlaceEvacZone');
	T.Abilities.AddItem('LiftOffAvenger');
	T.CharacterBaseStats[eStat_HP] = S.HP + B.HP + B.RepairHP;
	T.CharacterBaseStats[eStat_Offense] = S.Aim;
	T.CharacterBaseStats[eStat_Defense] = S.Defense + B.Defense;
	T.CharacterBaseStats[eStat_Mobility] = S.Mobility + B.Mobility;
	T.CharacterBaseStats[eStat_SightRadius] = S.Sight;
	T.CharacterBaseStats[eStat_DetectionRadius] = 12;
	T.CharacterBaseStats[eStat_Will] = 0;
	T.CharacterBaseStats[eStat_PsiOffense] = 0;
	T.CharacterBaseStats[eStat_UtilityItems] = 0;
	T.CharacterBaseStats[eStat_CritChance] = 0;
	return T;
}
