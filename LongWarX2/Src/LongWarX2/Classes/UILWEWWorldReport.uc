// The council's transmission before its monthly report, on Enemy Within's own World Report screen (its WorldReport movie,
// driven as EW's UIWorldReport and XGWorldReportUI drive it): first the link ("Transmitting encrypted data...", decrypting,
// then its status), then, when countries left the council at the meeting, who withdrew; then EW's End of Month Report
// (UILWEWEndOfMonth). Its button, Enter or a click carries on. Opened once the month's end has kept a report
// (XComGameState_LWStrategy.bReportDue), from the Long War Geoscape.
class UILWEWWorldReport extends UILWEWScreen;

/** 0 the link, 1 the defections. */
var int View;

static function bool Due()
{
	return class'XComGameState_LWStrategy'.static.Get() != none && class'XComGameState_LWStrategy'.static.Get().bReportDue;
}

/** The report seen: it is not opened again. */
static function Seen()
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the council's report seen");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
	S.bReportDue = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** The transmission opened, if a report is due and EW's screens are converted; the report is then marked seen. */
static function bool OpenIfDue(XComHQPresentationLayer HQPres)
{
	local UILWEWWorldReport EWScreen;

	if (HQPres == none || !Due() || HQPres.ScreenStack.GetFirstInstanceOf(class'UILWEWWorldReport') != none
		|| HQPres.ScreenStack.GetFirstInstanceOf(class'UILWEWEndOfMonth') != none)
		return false;
	if (!HasEWScreens())
	{
		Seen();
		return false;
	}
	Seen();
	DynamicLoadObject(default.UIPackage $ ".ewxWorldReport", class'Object', true);
	class'UILWEWMapBackdrop'.static.ShowIfAvailable();
	EWScreen = HQPres.Spawn(class'UILWEWWorldReport', HQPres);
	EWScreen.Package = name("/ package/ewxWorldReport/WorldReport");
	EWScreen.MCName = 'theWorldReport';
	HQPres.ScreenStack.Push(EWScreen);
	return true;
}

simulated function OnInit()
{
	local string Status;

	super.OnInit();
	Status = class'UILWEWEndOfMonth'.static.Word(class'UILWEWEndOfMonth'.default.LinkStatus, "Transmitting encrypted data...");
	MC.FunctionString("SetText", "");
	MC.BeginFunctionOp("SetDecryptingText");
	MC.QueueString(Status);
	MC.QueueString(class'UILWEWEndOfMonth'.static.Word(class'UILWEWEndOfMonth'.default.Decoded, "Transmission Decoded"));
	MC.EndOp();
	View = 0;
	MC.FunctionString("SetText", Status);
	// (EW's "Authorize Transmission" is longer than the button: its screen's "Next".)
	MC.ChildFunctionString("theStartButton", "setText", Caps(class'UILWEWEndOfMonth'.static.Word(class'UILWEWEndOfMonth'.default.Next, "Next")));
}

simulated function OnRemoved()
{
	class'UILWEWMapBackdrop'.static.HideAll();
	super.OnRemoved();
}

/** Who withdrew, as EW words it (XGWorldReportUI.UpdateDefections): "A, B and C have withdrawn …". */
static function string DefectionsText(XComGameState_LWStrategy S)
{
	local string Names, Text;
	local int i;

	for (i = 0; i < S.ReportLeaving.Length; i++)
	{
		if (Names != "")
			Names = i == S.ReportLeaving.Length - 1 ? Names @ class'UILWEWEndOfMonth'.static.Word(class'UILWEWEndOfMonth'.default.AndAppend, "and") $ " " : Names $ ", ";
		Names $= S.CountryName(S.ReportLeaving[i]);
	}
	Text = S.ReportLeaving.Length > 1
		? class'UILWEWEndOfMonth'.static.Word(class'UILWEWEndOfMonth'.default.ManyWithdrawn, "<XGParam:StrValue0/> have withdrawn from the XCOM project.")
		: class'UILWEWEndOfMonth'.static.Word(class'UILWEWEndOfMonth'.default.OneWithdrawn, "<XGParam:StrValue0/> has withdrawn from the XCOM project.");
	return Repl(Text, "<XGParam:StrValue0/>", Names);
}

/** On from the link: to the defections when countries left, else (and after them) to the report (XGWorldReportUI.OnAdvance). */
function Advance()
{
	local XComGameState_LWStrategy S;

	MC.FunctionVoid("HideDecrypting");
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	S = class'XComGameState_LWStrategy'.static.Get();
	if (View == 0 && S != none && S.ReportLeaving.Length > 0)
	{
		View = 1;
		MC.FunctionString("SetText", DefectionsText(S));
		return;
	}
	CloseScreen();
	class'UILWEWEndOfMonth'.static.Open(`HQPRES);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Joined;
	local int i;

	for (i = 0; i < args.Length; i++)
		Joined @= args[i];
	if (cmd == 391 && InStr(Joined, "theStartButton") != INDEX_NONE)
	{
		Advance();
		return;
	}
	super.OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			Advance();
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
}
