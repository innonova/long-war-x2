// Enemy Within's debrief after a mission (features/strategy-flow.md): its Debrief movie, driven as EW's UIDebrief drives it
// for XGDebriefUI's soldier view, through EW's Cargo camera on the hangar (XGDebriefUI.Init: CAMLookAtNamedLocation
// "Cargo"): DEBRIEF, the operation's name, After Action Report, and a slot per soldier of the squad (UIDebrief.
// ShowSoldierDebrief: the flag, rank and class icons, the name and nickname, kills and missions, the promotion where one is
// due, the status as Long War gives it: Active, Wounded with the days, KIA); SHIVs and MECs in their own kind of slot.
// CONTINUE goes on (UILWAfterAction: XCOM 2's own after-action bookkeeping, then the items recovered).
class UILWEWDebrief extends UILWEWScreen;

var localized string m_strDebrief, m_strKills, m_strMissions, m_strActive, m_strWounded, m_strDays, m_strKIA, m_strContinue,
	m_strPromote, m_strPromoteMouse;
var localized string AfterReport, ArtifactsRecovered, CouncilTransmission;

var UILWAfterAction AfterAction;
/** The view shown: 0 the soldiers (After Action Report), 2 what was recovered (Artifacts Recovered). */
var int View;
/** What the mission brought back: the stores' items before and after Long War applied its result (Cargo, CargoCounts). */
var array<name> Cargo;
var array<int> CargoCounts;

static function UILWEWDebrief Open(XComHQPresentationLayer HQPres, UILWAfterAction From)
{
	local UILWEWDebrief S;

	DynamicLoadObject(default.UIPackage $ ".ewxDebrief", class'Object', true);
	S = HQPres.Spawn(class'UILWEWDebrief', HQPres);
	S.Package = name("/ package/ewxDebrief/Debrief");
	S.MCName = 'theDebrief';
	S.AfterAction = From;
	HQPres.ScreenStack.Push(S);
	return S;
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

simulated function OnInit()
{
	super.OnInit();
	SetTimer(0.1, false, nameof(Fill));
}

function Fill()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWStrategy S;
	local XComGameState_MissionSite Mission;
	local XComGameState_Unit Unit;
	local array<ASValue> Params, NoArgs;
	local StateObjectReference Ref;
	local string Status, Promote;
	local int Slot, UIState, k;
	local bool bRobot;

	// (Long War's result of the mission applied first, as EW's debrief comes after it: its wounds and fatigue for the
	// statuses below, its loot for what was recovered. The hub would apply it next; once applied, it is not again.)
	TakeCargo();
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	S = class'XComGameState_LWStrategy'.static.Get();
	Mission = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
	// (UIDebrief.RealizeLabels.)
	Params.AddItem(Str(Word(m_strDebrief, "DEBRIEF")));
	Params.AddItem(Str(Mission != none ? Caps(Mission.GeneratedMission.BattleOpName) : ""));
	Params.AddItem(Str(Word(AfterReport, "After Action Report")));
	Params.AddItem(Str(Word(ArtifactsRecovered, "Artifacts Recovered:")));
	Params.AddItem(Str(Word(CouncilTransmission, "Council Transmission")));
	Params.AddItem(Str(""));
	Params.AddItem(Str(""));
	CallNow("SetTitles", Params);
	Params.Length = 0;
	Params.AddItem(Str(Word(m_strKills, "KILLS")));
	Params.AddItem(Str(Word(m_strMissions, "MISSIONS")));
	Params.AddItem(Str(Word(m_strActive, "ACTIVE")));
	Params.AddItem(Str(Word(m_strWounded, "WOUNDED")));
	Params.AddItem(Str(Word(m_strDays, "DAYS")));
	Params.AddItem(Str(Word(m_strKIA, "KIA")));
	Params.AddItem(Str(Word(m_strContinue, "CONTINUE")));
	Params.AddItem(Str(Word(m_strPromote, "PROMOTE")));
	Params.AddItem(Str(Word(m_strPromoteMouse, "CLICK TO PROMOTE")));
	CallNow("SetLabels", Params);
	foreach XComHQ.Squad(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none)
			continue;
		Status = class'UILWEWSoldierList'.static.StatusOf(Unit, S, UIState);
		bRobot = Unit.IsRobotic() || class'LWMECs'.static.IsMEC(Unit);
		Params.Length = 0;
		Params.AddItem(Num(Slot));
		if (!bRobot)
		{
			k = class'UILWEWSoldierList'.default.Classes.Find('Template', Unit.GetSoldierClassTemplateName());
			// (A promotion due: XCOM 2 holds it until it is made in the armory, as EW's debrief offered it: the rank it
			// leads to.)
			Promote = Unit.ShowPromoteIcon() ? class'X2ExperienceConfig'.static.GetRankName(Min(Unit.GetRank() + 1, 7), Unit.GetSoldierClassTemplateName()) : "";
			Params.AddItem(Str(""));
			Params.AddItem(Str(class'UILWEWSoldierList'.static.FlagOf(Unit.GetCountry())));
			Params.AddItem(Str("rank" $ Clamp(Unit.GetRank(), 0, 7)));
			Params.AddItem(Str(k != INDEX_NONE ? class'UILWEWSoldierList'.default.Classes[k].Frame : ""));
			Params.AddItem(Str(Unit.GetName(eNameType_FullNick)));
			Params.AddItem(Str(Repl(Unit.GetNickName(), "'", "")));
			Params.AddItem(Num(Unit.GetNumKills()));
			Params.AddItem(Num(-1));
			Params.AddItem(Num(Unit.GetNumMissions()));
			Params.AddItem(Num(Min(Unit.GetRank() + 1, 7)));
			Params.AddItem(Str(Promote));
			Params.AddItem(Str(""));
			Params.AddItem(Str(EWColoured(Caps(Status), UIState)));
			Params.AddItem(AsBool(Unit.IsDead()));
			Params.AddItem(AsBool(false));
			CallNow("SetSoldier", Params);
		}
		else
		{
			Params.AddItem(Str(Unit.GetName(eNameType_FullNick)));
			Params.AddItem(Num(Unit.GetNumKills()));
			Params.AddItem(Num(-1));
			Params.AddItem(Num(Unit.GetNumMissions()));
			Params.AddItem(AsBool(!Unit.IsDead()));
			Params.AddItem(Str(EWColoured(Caps(Status), UIState)));
			Params.AddItem(Str("shiv1"));
			CallNow("SetShiv", Params);
		}
		Slot++;
	}
	CallNow("ShowSoldierDebrief", NoArgs);
}

/** The stores' counts before and after Long War's result is applied (XComGameState_LWStrategy.Arrived): the difference is
 *  what came back (EW's m_arrLastCargo). */
function TakeCargo()
{
	local array<name> Names;
	local array<int> Before;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item Item;
	local StateObjectReference Ref;
	local int k, Now;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	foreach XComHQ.Inventory(Ref)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Item == none)
			continue;
		Names.AddItem(Item.GetMyTemplateName());
		Before.AddItem(Item.Quantity);
	}
	class'XComGameState_LWStrategy'.static.Arrived();
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	foreach XComHQ.Inventory(Ref)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Item == none)
			continue;
		k = Names.Find(Item.GetMyTemplateName());
		Now = Item.Quantity - (k != INDEX_NONE ? Before[k] : 0);
		// (Long War's own artifacts and corpses only: XCOM 2's resources the mission paid are its rewards, not salvage.)
		if (Now > 0 && Item.GetMyTemplateName() != 'Supplies' && Item.GetMyTemplateName() != 'Intel')
		{
			Cargo.AddItem(Item.GetMyTemplateName());
			CargoCounts.AddItem(Now);
		}
	}
}

/** The Artifacts Recovered view (UIDebrief.ShowScienceDebrief): each item recovered, how many, its picture. */
function ShowScience()
{
	local X2ItemTemplate Template;
	local array<ASValue> Params, NoArgs;
	local int i, Id, k;

	View = 2;
	Params.AddItem(Num(Id++));
	Params.AddItem(Str(Word(ArtifactsRecovered, "Artifacts Recovered:")));
	CallNow("AddListHeader", Params);
	for (i = 0; i < Cargo.Length; i++)
	{
		Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(Cargo[i]);
		k = class'LWGreyMarket'.default.Sales.Find('Template', Cargo[i]);
		Params.Length = 0;
		Params.AddItem(Num(Id++));
		Params.AddItem(Str(Template != none ? Template.GetItemFriendlyName() : string(Cargo[i])));
		Params.AddItem(Num(CargoCounts[i]));
		Params.AddItem(Str(k != INDEX_NONE ? class'LWX2Pictures'.static.Item(class'LWGreyMarket'.default.Sales[k].Item, Template != none ? Template.strImage : "") : (Template != none ? Template.strImage : "")));
		CallNow("AddScienceItem", Params);
	}
	CallNow("ShowScienceDebrief", NoArgs);
}

static function ASValue AsBool(bool V)
{
	local ASValue A;

	A.Type = AS_Boolean;
	A.b = V;
	return A;
}

/** CONTINUE: XCOM 2's after-action bookkeeping, and on (UILWAfterAction.Continue). */
function GoOn()
{
	local UILWAfterAction A;

	// (After the soldiers, what was recovered, when anything was: XGDebriefUI.OnAdvance.)
	if (View == 0 && Cargo.Length > 0)
	{
		ShowScience();
		return;
	}
	A = AfterAction;
	CloseScreen();
	if (A != none)
		A.GoOn();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP && args.Length > 0 && args[args.Length - 1] == "continueButton")
	{
		GoOn();
		return;
	}
	super.OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			GoOn();
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			// (Nothing to go back to: EW's debrief only goes on.)
			return true;
		}
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	// (EW's: XGDebriefUI.Init, the Cargo view of the hangar.)
	BaseCamera = Cargo
	bShowsBase = true
}
