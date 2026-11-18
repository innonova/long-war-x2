// Enemy Within's own hangar screen (its ShipList movie, features/lw-ew-screens.md): XCOM's craft by continent, with their
// weapons and status, the interceptors ordered, and an empty bay to order into or transfer to; driven as EW's UIShipList
// drives the movie (SetTitle, SetColumnLabels, ClearAll, AddShip, AddPendingShip, SetContinentTitle, SetSelection; clicks
// 391 on a row's "theButton" or its help button "clickableButton"). A craft's row opens its loadout
// (UILWEWShipLoadout); its TRANSFER picks it up, and TRANSFER HERE on another continent's empty bay sends it; an empty
// bay's ORDER INTERCEPTORS orders one (EW's order dialog, UILWEWHiring.OpenOrder). The rules are LWHangar's; the words
// EW's (UIShipList), each craft with Long War's icon (its Raven or Firestorm) before its callsign, its status in EW's words
// and colours (XGShip_Interceptor.GetStatusString; red while damaged, yellow while refuelling, refitting or transferring).
class UILWEWHangar extends UILWEWScreen;

var localized string m_strScreenTitle, m_strEmptySlotLabel, m_strFullContinentLabel, m_strTransferShipButtonHelp,
	m_strTransferShipHereButtonHelp, m_strHireShipButtonHelp, m_strCancelHireButtonHelp, m_strCancelTransferButtonHelp,
	m_strPendingInterceptorInfo, m_strPendingOrderRemainingDays, m_strColumnShipName, m_strColumnShipWeapon,
	m_strColumnShipStatus;
/** The cancel-order confirmation (XGHangarUI.ConfirmRemovalOfPendingShipOrder). */
var localized string CancelOrderTitle, CancelOrderText;
var localized string m_strConfirmTransferDialogTitle, m_strConfirmTransferDialogAcceptText, m_strConfirmTransferDialogText;
var localized string m_strHangarsFullDialogTitle, m_strHangarsFullDialogText;

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
	EWScreen = HQPres.Spawn(class'UILWEWHangar', HQPres);
	EWScreen.Package = name("/ package/ewxShipList/ShipList");
	EWScreen.MCName = 'theScreen';
	EWScreen.Transferring = -1;
	HQPres.ScreenStack.Push(EWScreen);
}

simulated function OnInit()
{
	super.OnInit();
	// (Long War's craft icons, in its own package: LongWar.Icons.)
	DynamicLoadObject("LongWar.Icons.IC_Raven", class'Object', true);
	MC.FunctionString("SetTitle", Word(m_strScreenTitle, "AIRCRAFT LIST"));
	MC.BeginFunctionOp("SetColumnLabels");
	MC.QueueString(Word(m_strColumnShipName, "SHIP NAME"));
	MC.QueueString(Word(m_strColumnShipWeapon, "WEAPON"));
	MC.QueueString(Word(m_strColumnShipStatus, "STATUS"));
	MC.EndOp();
	Fill();
}

simulated function OnRemoved()
{
	class'UILWEWMapBackdrop'.static.HideAll();
	super.OnRemoved();
}

/** EW's list stays in view under its dialogs (the order, the transfer and cancel confirmations: bHideOnLoseFocus off), not
 *  under the ship's own screen (hidden as that opens, OnRow). */
simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Show();
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
			// (A craft in transit listed at its new home, as EW moves it there as it sets off: TransferInterceptor.)
			if ((AirWar.Jets[i].Status == 6 ? AirWar.Jets[i].TransferTo : AirWar.Jets[i].Continent) != c)
				continue;
			RowState = AirWar.Jets[i].Status == 0 ? 0 : 1;
			// (UIShipList.UpdateData: the row greyed and its status red while damaged (EW's statuses 3 to 5), yellow while
			// refuelling, transferring or refitting (2, 6, 7), green when ready.)
			switch (AirWar.Jets[i].Status)
			{
			case 3: case 4: case 5: Colour = 3; break;
			case 2: case 6: case 7: Colour = 4; break;
			default: Colour = 2;
			}
			Status = class'UILWEWAlert'.static.StatusText(AirWar.Jets[i]);
			if (Transferring >= 0)
				Help = Transferring == i ? Word(m_strCancelTransferButtonHelp, "CANCEL TRANSFER") : "";
			else
				Help = class'LWHangar'.static.IsReady(AirWar.Jets[i]) ? Word(m_strTransferShipButtonHelp, "TRANSFER") : "";
			MC.BeginFunctionOp("AddShip");
			MC.QueueNumber(c);
			MC.QueueString("<img src='img:///LongWar.Icons." $ (AirWar.Jets[i].Type == 3 ? "IC_Firestorm" : "IC_Raven") $ "' height='16' width='16'>" $ AirWar.Jets[i].Callsign);
			MC.QueueString("          " $ class'LWHangar'.static.WeaponName(AirWar.Jets[i].Weapon));
			MC.QueueString(EWColoured(Status, Colour));
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
				MC.QueueString(Word(m_strPendingInterceptorInfo, "Interceptor Purchase"));
				MC.QueueString(EWColoured(Repl(Word(m_strPendingOrderRemainingDays, "Ready in <XGParam:StrValue0/> day(s)"), "<XGParam:StrValue0/>", string((AirWar.Orders[i].HoursLeft + 23) / 24)), 4));
				// (The first of a continent's pending ones offers CANCEL ORDER, as UIShipList.UpdateData does.)
				MC.QueueString((n == 0 && Transferring < 0) ? EWColoured(Word(m_strCancelHireButtonHelp, "CANCEL ORDER"), 3) : "");
				MC.QueueNumber(1);
				MC.EndOp();
				R.AddItem(n == 0 ? -3 : -1);
			}
		}
		Taken = class'LWHangar'.static.BaysTaken(AirWar, c);
		if (Taken < class'LWBaseRules'.default.HangarBays)
		{
			MC.BeginFunctionOp("AddShip");
			MC.QueueNumber(c);
			MC.QueueString(Word(m_strEmptySlotLabel, "( Empty Slot )"));
			MC.QueueString("");
			MC.QueueString("");
			MC.QueueString(Transferring >= 0 ? (AirWar.Jets[Transferring].Continent != c ? Word(m_strTransferShipHereButtonHelp, "TRANSFER HERE") : "") : Word(m_strHireShipButtonHelp, "ORDER INTERCEPTORS"));
			MC.QueueNumber(-1);
			MC.EndOp();
			R.AddItem(-2);
		}
		MC.BeginFunctionOp("SetContinentTitle");
		MC.QueueNumber(c);
		MC.QueueString(class'LWStrategyRules'.static.ContinentName(c) @ "(" $ Taken $ "/" $ class'LWBaseRules'.default.HangarBays $ ")"
			$ (Taken >= class'LWBaseRules'.default.HangarBays ? " " $ EWColoured(Word(m_strFullContinentLabel, "FULL"), 3) : ""));
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

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (Transferring >= 0)
	{
		// (TRANSFER HERE: EW's confirmation first, UIShipList.TransferShip.)
		if (Row == -2 && AirWar.Jets[Transferring].Continent != SelectedContinent)
		{
			ConfirmTransfer();
			return;
		}
		Transferring = -1;
		Fill();
		return;
	}
	if (Row >= 0)
	{
		if (bHelp && class'LWHangar'.static.IsReady(AirWar.Jets[Row]))
		{
			// (UIShipList.OnAccept: a transfer needs another hangar with room, and Long War lets no ferry fly while a
			// retaliation is under way; EW's words for each.)
			if (!FreeBayElsewhere(AirWar, AirWar.Jets[Row].Continent))
				Notice(Word(m_strHangarsFullDialogText, "There are currently no slots available to which a ship can be transferred."));
			else if (class'LWHangar'.static.FerryRestricted())
				Notice(Word(m_strHangarsFullDialogTitle, "Ferry flights restricted due to heavy UFO activity."));
			else
			{
				Transferring = Row;
				Fill();
			}
		}
		else if (!bHelp)
		{
			Hide();
			class'UILWEWShipSummary'.static.Open(XComHQPresentationLayer(Movie.Pres), Row);
		}
		return;
	}
	if (Row == -2)
		class'UILWEWHiring'.static.OpenOrder(XComHQPresentationLayer(Movie.Pres), SelectedContinent);
	if (Row == -3 && bHelp)
		ConfirmCancel();
}

function bool FreeBayElsewhere(XComGameState_LWAirWar AirWar, int From)
{
	local int c;

	for (c = 0; c < 5; c++)
		if (c != From && class'LWHangar'.static.BaysTaken(AirWar, c) < class'LWBaseRules'.default.HangarBays)
			return true;
	return false;
}

/** EW's one-line notice (an untitled dialog with its OK). */
function Notice(string Text)
{
	local TDialogueBoxData Data;

	Data.eType = eDialog_Normal;
	Data.strText = Text;
	Data.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	Movie.Pres.UIRaiseDialog(Data);
}

/** CONFIRM TRANSFER: "Do you want to transfer <ship> from <continent> to <continent>? Hours to complete: <n>". */
function ConfirmTransfer()
{
	local XComGameState_LWAirWar AirWar;
	local TDialogueBoxData Data;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	Data.eType = eDialog_Normal;
	Data.strTitle = Word(m_strConfirmTransferDialogTitle, "CONFIRM TRANSFER");
	Data.strText = Repl(Repl(Repl(Repl(Word(m_strConfirmTransferDialogText, "Do you want to transfer <XGParam:StrValue0/> from <XGParam:StrValue1/> to <XGParam:StrValue2/>?<br><br>Hours to complete: <XGParam:IntValue0/>"),
		"<XGParam:StrValue0/>", AirWar.Jets[Transferring].Callsign),
		"<XGParam:StrValue1/>", class'LWStrategyRules'.static.ContinentName(AirWar.Jets[Transferring].Continent)),
		"<XGParam:StrValue2/>", class'LWStrategyRules'.static.ContinentName(SelectedContinent)),
		"<XGParam:IntValue0/>", string(class'LWBaseRules'.default.TransferHours));
	Data.strAccept = Word(m_strConfirmTransferDialogAcceptText, "CONFIRM");
	Data.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Data.fnCallback = OnTransferDialog;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnTransferDialog(Name Action)
{
	local string Why;

	if (Action == 'eUIAction_Accept')
	{
		if (!class'LWHangar'.static.Transfer(Transferring, SelectedContinent, Why))
			`log("LongWarX2: EW hangar:" @ Why, , 'LongWarX2');
		PlaySound(SoundCue'SoundUI.MenuSelectCue', true);
	}
	Transferring = -1;
	Fill();
}

/** CANCEL ORDER: EW's confirmation, then one interceptor of the continent's order cancelled, its price back. */
function ConfirmCancel()
{
	local TDialogueBoxData Data;

	Data.eType = eDialog_Normal;
	Data.strTitle = Word(CancelOrderTitle, "CANCEL ORDER");
	Data.strText = Word(CancelOrderText, "Are you sure you want to cancel your Interceptor order?");
	Data.strAccept = class'UIUtilities_Text'.default.m_strGenericConfirm;
	Data.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Data.fnCallback = OnCancelDialog;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnCancelDialog(Name Action)
{
	if (Action == 'eUIAction_Accept' && class'LWHangar'.static.CancelOrder(SelectedContinent))
		PlaySound(SoundCue'SoundUI.MenuSelectCue', true);
	Fill();
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
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
	// (Over EW's the hangar, as EW shows it.)
	BaseCamera = HANGAR
	bHideOnLoseFocus = false
}
