// Commander's Choice (second wave #18): XCOM 2's class chooser (the training center's) with Long War's eight classes; the
// one chosen is the rookie's class at once, as XCOM 2's PromoteSoldier gives a class (the rank, the squaddie's kit, the best
// gear, its PromotionEvent), and XCOM 2's promotion screen follows.
class UILWChooseClass extends UIChooseClass;

simulated function array<X2SoldierClassTemplate> GetClasses()
{
	local X2SoldierClassTemplateManager Manager;
	local X2SoldierClassTemplate T;
	local array<X2SoldierClassTemplate> Out;
	local name ClassName;

	Manager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	foreach class'LWX2TrainingRoulette'.default.Classes(ClassName)
	{
		T = Manager.FindSoldierClassTemplate(ClassName);
		if (T != none)
			Out.AddItem(T);
	}
	return Out;
}

simulated function array<Commodity> ConvertClassesToCommodities()
{
	local array<Commodity> Out;
	local Commodity C;
	local int i;

	m_arrClasses = GetClasses();
	for (i = 0; i < m_arrClasses.Length; i++)
	{
		C.Title = m_arrClasses[i].DisplayName;
		C.Image = m_arrClasses[i].IconImage;
		C.Desc = m_arrClasses[i].ClassSummary;
		C.OrderHours = 0;
		Out.AddItem(C);
	}
	return Out;
}

/** XCOM 2's rows without the training time (UILWClassListItem), each with XCOM 2's PROMOTE SOLDIER for its button. */
simulated function PopulateData()
{
	local int i;

	List.ClearItems();
	List.bSelectFirstAvailable = false;
	for (i = 0; i < arrItems.Length; i++)
		Spawn(class'UILWClassListItem', List.itemContainer).InitInventoryListCommodity(arrItems[i], , GetButtonString(i), m_eStyle, , 126);
}

simulated function string GetButtonString(int ItemIndex)
{
	return class'UIArmory_MainMenu'.default.m_strPromote;
}

function bool OnClassSelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_Unit Unit;

	if (iOption < 0 || iOption >= m_arrClasses.Length)
		return false;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: Commander's Choice");
	HQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', m_UnitRef.ObjectID));
	if (Unit.GetRank() != 0 || !Unit.CanRankUpSoldier())
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		return true;
	}
	Unit.RankUpSoldier(NewGameState, m_arrClasses[iOption].DataName);
	Unit.ApplySquaddieLoadout(NewGameState, HQ);
	Unit.ApplyBestGearLoadout(NewGameState);
	`XEVENTMGR.TriggerEvent('PromotionEvent', Unit, Unit, NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`HQPRES.ShowPromotionUI(m_UnitRef);
	return true;
}
