// Enemy Within's own hangar screen (its ShipList movie, features/lw-ew-screens.md): XCOM's craft by continent, with their
// weapons and status, the interceptors ordered, and an empty bay to order into or transfer to; driven as EW's UIShipList
// drives the movie (SetTitle, SetColumnLabels, ClearAll, AddShip, AddPendingShip, SetContinentTitle, SetSelection; clicks
// 391 on a row's "theButton" or its help button "clickableButton"). A craft's row opens its loadout
// (UILWEWShipLoadout); its TRANSFER picks it up, and TRANSFER HERE on another continent's empty bay sends it; an empty
// bay's ORDER INTERCEPTORS orders one. The rules are LWHangar's.
class UILWEWHangar extends UILWEWScreen;

/** For each continent's rows: the jet (its index in the air war), -1 an order, -2 the empty bay. */
var array<int> Rows0, Rows1, Rows2, Rows3, Rows4;
var int SelectedContinent, SelectedRow;
/** A jet picked up to transfer (its index), or -1. */
var int Transferring;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWHangar EWScreen;

	if (!class'UILWEWScreen'.static.HasEWScreens())
	{
		HQPres.ScreenStack.Push(HQPres.Spawn(class'UILWHangar', HQPres));
		return;
	}
	DynamicLoadObject(default.UIPackage $ ".ewxShipList", class'Object', true);
	class'UILWEWMapBackdrop'.static.ShowIfAvailable();
	EWScreen = HQPres.Spawn(class'UILWEWHangar', HQPres);
	EWScreen.Package = name("/ package/ewxShipList/ShipList");
	EWScreen.MCName = 'theScreen';
	EWScreen.Transferring = -1;
	HQPres.ScreenStack.Push(EWScreen);
}

simulated function OnInit()
{
	super.OnInit();
	MC.FunctionString("SetTitle", "HANGAR");
	MC.BeginFunctionOp("SetColumnLabels");
	MC.QueueString("CRAFT");
	MC.QueueString("WEAPON");
	MC.QueueString("STATUS");
	MC.EndOp();
	Fill();
}

simulated function OnRemoved()
{
	class'UILWEWMapBackdrop'.static.HideAll();
	super.OnRemoved();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (bIsInited)
		Fill();
}

function array<int> RowsOf(int c)
{
	switch (c)
	{
	case 0: return Rows0;
	case 1: return Rows1;
	case 2: return Rows2;
	case 3: return Rows3;
	}
	return Rows4;
}

function SetRows(int c, array<int> R)
{
	switch (c)
	{
	case 0: Rows0 = R; break;
	case 1: Rows1 = R; break;
	case 2: Rows2 = R; break;
	case 3: Rows3 = R; break;
	default: Rows4 = R;
	}
}

/** Every continent's hangar, as EW's UpdateData lists it. */
function Fill()
{
	local XComGameState_LWAirWar AirWar;
	local array<int> R;
	local int c, i, n, Taken, RowState, Colour;
	local string Status, Help;

	class'XComGameState_LWAirWar'.static.EnsureExists();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	MC.FunctionVoid("ClearAll");
	for (c = 0; c < 5; c++)
	{
		R.Length = 0;
		for (i = 0; i < AirWar.Jets.Length; i++)
		{
			if (AirWar.Jets[i].Continent != c)
				continue;
			RowState = AirWar.Jets[i].Status == 0 ? 0 : 1;
			if (AirWar.Jets[i].Status == 0)
				Colour = eUIState_Good;
			else if (AirWar.Jets[i].Status == 4)
				Colour = eUIState_Bad;
			else
				Colour = eUIState_Warning;
			Status = StatusText(AirWar.Jets[i]);
			if (Transferring >= 0)
				Help = Transferring == i ? "CANCEL TRANSFER" : "";
			else
				Help = class'LWHangar'.static.IsReady(AirWar.Jets[i]) ? "TRANSFER" : "";
			MC.BeginFunctionOp("AddShip");
			MC.QueueNumber(c);
			MC.QueueString(AirWar.Jets[i].Callsign);
			MC.QueueString("          " $ class'LWHangar'.static.WeaponName(AirWar.Jets[i].Weapon));
			MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(Status, EUIState(Colour)));
			MC.QueueString(Help);
			MC.QueueNumber(RowState);
			MC.EndOp();
			R.AddItem(i);
		}
		for (i = 0; i < AirWar.Orders.Length; i++)
		{
			if (AirWar.Orders[i].Continent != c)
				continue;
			for (n = 0; n < AirWar.Orders[i].Count; n++)
			{
				MC.BeginFunctionOp("AddPendingShip");
				MC.QueueNumber(c);
				MC.QueueString("Interceptor Purchase");
				MC.QueueString(class'UIUtilities_Text'.static.GetColoredText("Ready in" @ class'LWEngineering'.static.HoursText(AirWar.Orders[i].HoursLeft), eUIState_Warning));
				MC.QueueString("");
				MC.QueueNumber(1);
				MC.EndOp();
				R.AddItem(-1);
			}
		}
		Taken = class'LWHangar'.static.BaysTaken(AirWar, c);
		if (Taken < class'LWBaseRules'.default.HangarBays)
		{
			MC.BeginFunctionOp("AddShip");
			MC.QueueNumber(c);
			MC.QueueString("( Empty Slot )");
			MC.QueueString("");
			MC.QueueString("");
			MC.QueueString(Transferring >= 0 ? (AirWar.Jets[Transferring].Continent != c ? "TRANSFER HERE" : "") : "ORDER INTERCEPTORS");
			MC.QueueNumber(-1);
			MC.EndOp();
			R.AddItem(-2);
		}
		MC.BeginFunctionOp("SetContinentTitle");
		MC.QueueNumber(c);
		MC.QueueString(Caps(class'LWStrategyRules'.static.ContinentName(c)) @ "(" $ Taken $ "/" $ class'LWBaseRules'.default.HangarBays $ ")"
			$ (Taken >= class'LWBaseRules'.default.HangarBays ? " " $ class'UIUtilities_Text'.static.GetColoredText("FULL", eUIState_Bad) : ""));
		MC.EndOp();
		SetRows(c, R);
	}
	MC.BeginFunctionOp("SetSelection");
	MC.QueueNumber(SelectedContinent);
	MC.QueueNumber(SelectedRow);
	MC.EndOp();
}

static function string StatusText(XComGameState_LWAirWar.LWJet J)
{
	switch (J.Status)
	{
	case 2: return "Refuelling (" $ class'LWEngineering'.static.HoursText(J.HoursDown) $ ")";
	case 4: return "Repairing (" $ class'LWEngineering'.static.HoursText(J.HoursDown) $ ")";
	case 6: return "To" @ class'LWStrategyRules'.static.ContinentName(J.TransferTo) @ "(" $ class'LWEngineering'.static.HoursText(J.HoursDown) $ ")";
	case 7: return "Refitting (" $ class'LWEngineering'.static.HoursText(J.HoursDown) $ ")";
	}
	return "Ready, HP" @ J.Hp $ "/" $ class'LWHangar'.static.MaxHp(J);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int i, Row;
	local string S, Target;
	local array<int> R;

	if (cmd != 391)
	{
		super(UIScreen).OnMouseEvent(cmd, args);
		return;
	}
	// The row clicked, as EW reads it: "option<continent>", then "theItems" and the row.
	for (i = 0; i < args.Length; i++)
	{
		S = args[i];
		if (InStr(S, "option") == 0)
			SelectedContinent = int(Mid(S, 6));
		else if (S == "theItems" && i + 1 < args.Length)
			SelectedRow = int(args[i + 1]);
	}
	Target = args.Length > 0 ? args[args.Length - 1] : "";
	R = RowsOf(SelectedContinent);
	if (SelectedRow < 0 || SelectedRow >= R.Length)
		return;
	Row = R[SelectedRow];
	if (Target == "theButton")
		OnRow(Row, false);
	else if (Target == "clickableButton")
		OnRow(Row, true);
	super(UIScreen).OnMouseEvent(cmd, args);
}

/** A row clicked (or its help button): a craft to its loadout or to transfer, an empty bay to order or receive. */
function OnRow(int Row, bool bHelp)
{
	local XComGameState_LWAirWar AirWar;
	local string Why;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (Transferring >= 0)
	{
		if (Row == -2 && AirWar.Jets[Transferring].Continent != SelectedContinent)
		{
			if (!class'LWHangar'.static.Transfer(Transferring, SelectedContinent, Why))
				`log("LongWarX2: EW hangar:" @ Why, , 'LongWarX2');
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		}
		Transferring = -1;
		Fill();
		return;
	}
	if (Row >= 0)
	{
		if (bHelp && class'LWHangar'.static.IsReady(AirWar.Jets[Row]))
		{
			Transferring = Row;
			Fill();
		}
		else if (!bHelp)
			class'UILWEWShipLoadout'.static.Open(XComHQPresentationLayer(Movie.Pres), Row);
		return;
	}
	if (Row == -2)
		ConfirmOrder();
}

/** An interceptor ordered into the selected continent's hangar, once confirmed. */
function ConfirmOrder()
{
	local TDialogueBoxData Data;

	Data.eType = eDialog_Normal;
	Data.strTitle = "ORDER AN INTERCEPTOR";
	Data.strText = "Order an interceptor for" @ class'LWStrategyRules'.static.ContinentName(SelectedContinent) $ "'s hangar, for"
		@ class'LWStrategyRules'.static.Money(class'LWBonusEffects'.static.AirCost(class'LWBaseRules'.default.InterceptorCost)) $ "? It arrives in"
		@ class'LWEngineering'.static.HoursText(class'LWBaseRules'.default.OrderHours) $ ".";
	Data.strAccept = "ORDER";
	Data.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Data.fnCallback = OnOrderDialog;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnOrderDialog(Name Action)
{
	local string Why;

	if (Action != 'eUIAction_Accept')
		return;
	if (!class'LWHangar'.static.Order(SelectedContinent, 1, Why))
	{
		`log("LongWarX2: EW hangar:" @ Why, , 'LongWarX2');
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}
	Fill();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0 && Transferring >= 0
		&& (cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE || cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B))
	{
		Transferring = -1;
		Fill();
		return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	// EW's ShipList places itself by the stage's edges (as its HUD does): not scaled up.
	bScaleToStage = false
}
