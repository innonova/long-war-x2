// Enemy Within's pending council requests (features/strategy-flow.md; the Situation Room's Pending Requests): its
// PendingRequests movie, filled as EW's UIPendingRequests.UpdateData fills it from Long War's open requests
// (XComGameState_LWStrategy.Requests): each request's line (a satellite's "Satellite Transfer: <country>", else EW's request
// title), its status as EW words it (CAN COMPLETE, AWAITING SATELLITE COVERAGE, AWAITING JET TRANSFER, OPERATION IN PROGRESS,
// CAN NOT COMPLETE), its hours left. VIEW REQUEST opens an item request on EW's request screen (UILWEWCouncilRequest); the
// satellite and jet requests are met as the satellite or jet arrives, as in Long War.
class UILWEWPendingRequests extends UILWEWScreen;

var localized string m_strPendingRequests, m_strFunding, m_strMissions, m_strViewRequest, m_strHoursLeft,
	m_strSatelliteTransferLabel, m_strNoPendingRequests, m_strStatus_OperationInProgress, m_strStatus_TransferComplete,
	m_strStatus_AwaitingJetTransfer, m_strStatus_SatelliteEnRoute, m_strStatus_SatelliteCoverageComplete,
	m_strStatus_AwaitingSatelliteCoverage, m_strStatus_CanNotComplete, m_strStatus_CanComplete;

var int Highlight;
var int Shown;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWPendingRequests S;

	DynamicLoadObject(default.UIPackage $ ".ewxPendingRequests", class'Object', true);
	S = HQPres.Spawn(class'UILWEWPendingRequests', HQPres);
	S.Package = name("/ package/ewxPendingRequests/pendingRequests");
	S.MCName = 'thePendingRequests';
	HQPres.ScreenStack.Push(S);
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

simulated function OnInit()
{
	super.OnInit();
	MC.FunctionString("SetNoneMessage", Word(m_strNoPendingRequests, "No requests are pending"));
	// (The list's items are made once the movie has run its first frame, as on EW's request screen.)
	SetTimer(0.1, false, nameof(Fill));
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Fill();
}

/** A request's status in EW's words, and whether it can be completed, is under way, is complete (UpdateData). */
static function string Status(XComGameState_LWStrategy S, XComGameState_LWStrategy.LWRequest R, out int bCan, out int bGoing, out int bDone)
{
	local XComGameState_LWAirWar AirWar;
	local int i;

	bCan = 1;
	bGoing = 0;
	bDone = 0;
	if (R.Transfer == 2)
	{
		AirWar = class'XComGameState_LWAirWar'.static.Get();
		for (i = 0; AirWar != none && i < AirWar.Jets.Length; i++)
			if (AirWar.Jets[i].Status == 6 && AirWar.Jets[i].TransferTo == S.CountryContinent(R.Country))
			{
				bGoing = 1;
				return Word(default.m_strStatus_OperationInProgress, "(OPERATION IN PROGRESS)");
			}
		if (class'LWCouncilRequests'.static.CanTransferJet(S, R.Country))
		{
			bGoing = 1;
			return Word(default.m_strStatus_AwaitingJetTransfer, "(AWAITING JET TRANSFER)");
		}
	}
	else if (R.Transfer == 1)
	{
		if (S.Countries[R.Country].bSatellite)
		{
			bDone = 1;
			return Word(default.m_strStatus_SatelliteCoverageComplete, "(SATELLITE COVERAGE COMPLETE)");
		}
		if (S.SatellitesReady > 0 && (S.TileType.Length == 0 || class'LWBase'.static.SatellitesUp(S) < class'LWBase'.static.SatelliteLimit(S)))
			return Word(default.m_strStatus_AwaitingSatelliteCoverage, "(AWAITING SATELLITE COVERAGE)");
	}
	else if (class'LWCouncilRequests'.static.Held(R) >= R.Amount)
		return Word(default.m_strStatus_CanComplete, "(CAN COMPLETE)");
	bCan = 0;
	return Word(default.m_strStatus_CanNotComplete, "(CAN NOT COMPLETE)");
}

function Fill()
{
	local XComGameState_LWStrategy S;
	local array<ASValue> Params;
	local string Text;
	local int i, bCan, bGoing, bDone;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return;
	Shown = S.Requests.Length;
	// (Every call at once, Movie.Invoke: XCOM 2's queued calls would run after the items and clear them.)
	Params.Length = 0;
	Params.AddItem(Str(Word(m_strPendingRequests, "PENDING REQUESTS")));
	Params.AddItem(Str(Word(m_strFunding, "Funding")));
	Params.AddItem(Str(Word(m_strMissions, "Missions")));
	Params.AddItem(Str(Shown > 0 ? Word(m_strViewRequest, "View Request") : ""));
	Params.AddItem(Str(class'UIUtilities_Text'.default.m_strGenericCancel));
	CallNow("SetLabels", Params);
	Params.Length = 0;
	CallNow("Clear", Params);
	for (i = 0; i < Shown; i++)
	{
		if (S.Requests[i].Transfer == 1)
			Text = Word(m_strSatelliteTransferLabel, "Satellite Transfer: ") $ S.CountryName(S.Requests[i].Country);
		else
			Text = Repl(class'UILWEWCouncilRequest'.default.TitleLabel, "<XGParam:StrValue0/>", S.CountryName(S.Requests[i].Country));
		Params.Length = 0;
		Params.AddItem(Num(i));
		Params.AddItem(Str(Text));
		Params.AddItem(Str(Status(S, S.Requests[i], bCan, bGoing, bDone)));
		Params.AddItem(Str(S.Requests[i].bPending ? "" : Word(m_strHoursLeft, "HOURS LEFT") $ ":" @ S.Requests[i].HoursLeft));
		Params.AddItem(AsBool(bCan == 1));
		Params.AddItem(AsBool(bGoing == 1));
		Params.AddItem(AsBool(bDone == 1));
		CallNow("AddFundingRequest", Params);
	}
	if (Shown > 0)
	{
		Highlight = Clamp(Highlight, 0, Shown - 1);
		Select(Highlight);
	}
}

static function ASValue AsBool(bool V)
{
	local ASValue A;

	A.Type = AS_Boolean;
	A.b = V;
	return A;
}

/** VIEW REQUEST (OnAccept): an item request on EW's request screen; the satellite and jet requests have none. */
function Accept()
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || Highlight < 0 || Highlight >= S.Requests.Length || S.Requests[Highlight].Transfer != 0
		|| !class'UILWEWCouncilRequest'.static.Open(none, Highlight, XComHQPresentationLayer(Movie.Pres)))
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
}

function Select(int i)
{
	local array<ASValue> Params;

	if (i < 0 || i >= Shown)
		return;
	Highlight = i;
	Params.AddItem(Num(Highlight));
	CallNow("SetSelection", Params);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		if (Target == "theStartButton")
		{
			Accept();
			return;
		}
		if (Target == "theBackButton")
		{
			CloseScreen();
			return;
		}
		if (args.Length > 1 && args[args.Length - 2] == "theItems")
		{
			Select(int(Target));
			Accept();
			return;
		}
	}
	else if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN && args.Length > 1 && args[args.Length - 2] == "theItems")
	{
		Select(int(Target));
		return;
	}
	super.OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Accept();
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			Select(Highlight - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			Select(Highlight + 1);
			return true;
		}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	BaseCamera = Cam_SituationRoom
}
