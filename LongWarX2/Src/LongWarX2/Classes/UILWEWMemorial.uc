// Enemy Within's memorial (features/strategy-flow.md; the barracks' View the Memorial): its Memorial movie, driven as EW's
// UIMemorial drives it (SetTitleLabels; AddSoldier per fallen soldier: name, kills, missions, last operation, date,
// medals, cause of death), through EW's memorial camera, without the resource bar (AS_HideResourcesPanel). The fallen are
// XCOM 2's (XComHQ.DeadCrew), each with the operation, date (in Long War's calendar) and cause XCOM 2 records as a
// soldier dies, written as EW writes them ("PFC Ana Pita (Trooper)").
class UILWEWMemorial extends UILWEWScreen;

var localized string m_strMemorialTitle, m_strKillsTitle, m_strMissionsTitle, m_strLastOpTitle, m_strTimeOfDeathTitle;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWMemorial S;

	DynamicLoadObject(default.UIPackage $ ".ewxMemorial", class'Object', true);
	S = HQPres.Spawn(class'UILWEWMemorial', HQPres);
	S.Package = name("/ package/ewxMemorial/Memorial");
	S.MCName = 'theScreen';
	HQPres.ScreenStack.Push(S);
}

simulated function OnInit()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;

	super.OnInit();
	MC.BeginFunctionOp("SetTitleLabels");
	MC.QueueString(Word(m_strMemorialTitle, "MEMORIAL"));
	MC.QueueString(Word(m_strKillsTitle, "KILLS"));
	MC.QueueString(Word(m_strMissionsTitle, "MISSIONS"));
	MC.QueueString(Word(m_strLastOpTitle, "LAST OP"));
	MC.QueueString(Word(m_strTimeOfDeathTitle, "DATE"));
	MC.EndOp();
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	foreach XComHQ.DeadCrew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none)
			continue;
		MC.BeginFunctionOp("AddSoldier");
		MC.QueueString(Unit.GetName(eNameType_RankFull) $ (Unit.GetSoldierClassTemplate() != none ? " (" $ Unit.GetSoldierClassTemplate().DisplayName $ ")" : ""));
		MC.QueueString(string(Unit.GetNumKills()));
		MC.QueueString(string(Unit.GetNumMissions()));
		MC.QueueString(Unit.m_strKIAOp);
		MC.QueueString(class'X2StrategyGameRulesetDataStructures'.static.GetDateString(class'XComGameState_LWStrategy'.static.LongWarDate(Unit.m_KIADate), true));
		MC.QueueString("");
		MC.QueueString(Unit.m_strCauseOfDeath);
		MC.EndOp();
	}
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

defaultproperties
{
	BaseCamera = "Memorial"
}
