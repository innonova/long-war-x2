// Long War's MEC troopers as an XCOM 2 character (features/lw-shivs-mecs.md, phase 3): a soldier in a MEC suit, on the ADVENT
// MEC's pawn (a mech's walk and death; EW's MECs took no cover); Long War's soldier base stats again with 4 more HP
// (XGStrategySoldier.SetSoldierClass, eSC_Mec), its class one of the eight MEC classes. Not robotic (a person inside), never
// psionic. Made by augmentation (LWMECs.AugmentDone).
class X2Character_LWMEC extends X2Character dependson(LWMECs);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(MECTemplate());
	return Templates;
}

static function X2CharacterTemplate MECTemplate()
{
	local X2CharacterTemplate T;
	local LWMECs.LWMECStats S;

	`CREATE_X2CHARACTER_TEMPLATE(T, 'LWMEC');
	S = class'LWMECs'.default.Base;
	T.CharacterGroupName = 'LWMEC';
	T.BehaviorClass = class'XGAIBehavior';
	T.strPawnArchetypes.AddItem("GameUnit_AdvMEC_M2.ARC_GameUnit_AdvMEC_M2");
	T.UnitSize = 1;
	T.UnitHeight = 3;
	T.bCanUse_eTraversal_Normal = true;
	T.bCanUse_eTraversal_ClimbOver = true;
	T.bCanUse_eTraversal_ClimbOnto = true;
	T.bCanUse_eTraversal_ClimbLadder = false;
	T.bCanUse_eTraversal_DropDown = true;
	T.bCanUse_eTraversal_Grapple = false;
	T.bCanUse_eTraversal_Landing = true;
	T.bCanUse_eTraversal_BreakWindow = true;
	T.bCanUse_eTraversal_KickDoor = true;
	T.bCanUse_eTraversal_JumpUp = true;
	T.bCanUse_eTraversal_WallClimb = false;
	T.bCanUse_eTraversal_BreakWall = false;
	T.bAppearanceDefinesPawn = false;
	T.bCanTakeCover = false;
	T.bAllowRushCam = false;
	T.bIsAlien = false;
	T.bIsAdvent = false;
	T.bIsCivilian = false;
	T.bIsPsionic = false;
	T.bIsRobotic = false;
	T.bIsSoldier = true;
	T.bCanBeCriticallyWounded = true;
	T.bCanBeTerrorist = false;
	T.bCanBeCarried = false;
	T.bCanBeRevived = true;
	T.bIsAfraidOfFire = false;
	T.bUsePoolSoldiers = false;
	T.bIsTooBigForArmory = true;
	T.bStaffingAllowed = false;
	T.bAppearInBase = false;
	T.strMatineePackages.AddItem("CIN_AdventMEC");
	T.strTargetingMatineePrefix = "CIN_AdventMEC_FF_StartPos";
	T.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_XCom;
	T.Abilities.AddItem('Loot');
	T.Abilities.AddItem('Evac');
	T.Abilities.AddItem('PlaceEvacZone');
	T.Abilities.AddItem('LiftOffAvenger');
	T.Abilities.AddItem('Interact_OpenDoor');
	T.CharacterBaseStats[eStat_HP] = S.HP;
	T.CharacterBaseStats[eStat_Offense] = S.Aim;
	T.CharacterBaseStats[eStat_Defense] = S.Defense;
	T.CharacterBaseStats[eStat_Mobility] = S.Mobility;
	T.CharacterBaseStats[eStat_Will] = S.Will;
	T.CharacterBaseStats[eStat_SightRadius] = 27;
	T.CharacterBaseStats[eStat_DetectionRadius] = 12;
	T.CharacterBaseStats[eStat_UtilityItems] = 1;
	T.CharacterBaseStats[eStat_CritChance] = 0;
	return T;
}
