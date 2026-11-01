// For development (features/lw-classes.md): on the Avenger of a campaign, the rookies promoted
// to Corporal in Long War's classes, one class after another, so the classes and their trees
// can be looked at without playing missions first; behind its switch.
class UIScreenListener_LongWarX2TestBarracks extends UIScreenListener config(LWAirWar);

var config bool PromoteRookies;

event OnInit(UIScreen Screen)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local array<name> Classes;
	local name ClassName;
	local int n;

	if (!default.PromoteRookies || UIAvengerHUD(Screen) == none)
		return;
	foreach class'X2SoldierClass_DefaultClasses'.default.SoldierClasses(ClassName)
		if (Left(string(ClassName), 4) == "LWS_")
			Classes.AddItem(ClassName);
	if (Classes.Length == 0)
		return;
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("LongWarX2: rookies promoted for a look at the classes");
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier() || Unit.GetRank() != 0)
			continue;
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.RankUpSoldier(NewGameState, Classes[n % Classes.Length]);
		Unit.ApplySquaddieLoadout(NewGameState, XComHQ);
		Unit.RankUpSoldier(NewGameState);
		n++;
	}
	if (n == 0)
	{
		History.CleanupPendingGameState(NewGameState);
		return;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("LongWarX2: test barracks:" @ n @ "rookies promoted to Corporal in Long War's classes", , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = none;
}
