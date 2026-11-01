// For development: one connection to the control port (LWX2Control): a command a line, the
// answer's lines, then ".". "help" lists the commands. Text mode, lines split here.
class LWX2ControlClient extends TcpLink;

/** What came in and is not yet a whole line. */
var string Pending;

event ReceivedText(string Text)
{
	local int i;

	Pending $= Text;
	for (i = InStr(Pending, Chr(10)); i != INDEX_NONE; i = InStr(Pending, Chr(10)))
	{
		Answer(Repl(Left(Pending, i), Chr(13), ""));
		Pending = Mid(Pending, i + 1);
	}
}

function Answer(string Line)
{
	local array<string> Out;
	local string L;

	`log("LongWarX2: control:" @ Line, , 'LongWarX2');
	Handle(Line, Out);
	// A line at a time: a dump is thousands of them.
	foreach Out(L)
		SendText(L $ Chr(10));
	SendText("." $ Chr(10));
}

function Handle(string Line, out array<string> Out)
{
	local array<string> Args;
	local XComGameState_LWStrategy S;
	local UILWGeoscape Geo;
	local string Cmd;
	local int Before;

	ParseStringIntoArray(Line, Args, " ", true);
	if (Args.Length == 0)
		return;
	Cmd = Locs(Args[0]);
	S = class'XComGameState_LWStrategy'.static.Get();
	switch (Cmd)
	{
	case "help":
		Out.AddItem("ping | screens | geo | decisions | geoscape | run <hours> | act <n> | intercepted <ufo> <outcome 0 crashed 1 destroyed 2 escaped> <ufo hp>");
		Out.AddItem("sat build | sat launch <country> | win | exec <console command>");
		Out.AddItem("dump [class name part]: every game state object with all its fields (tools/test/lw-dump.sh saves it)");
		return;
	case "ping":
		Out.AddItem("pong" @ (Pres().ScreenStack.GetCurrentScreen() != none ? string(Pres().ScreenStack.GetCurrentScreen().Class.Name) : "none"));
		return;
	case "screens":
		Screens(Out);
		return;
	case "exec":
		Out.AddItem(GetALocalPlayerController().ConsoleCommand(Mid(Line, Len(Args[0]) + 1), true));
		return;
	case "win":
		if (XComTacticalController(GetALocalPlayerController()) == none)
		{
			Out.AddItem("ERR not in a mission");
			return;
		}
		class'UIScreenListener_LongWarX2Tactical'.static.TestWin();
		Out.AddItem("ok");
		return;
	case "dump":
		DumpAll(Args.Length > 1 ? Args[1] : "", Out);
		return;
	case "geoscape":
		Out.AddItem(OpenGeoscape() != none ? "ok" : "ERR not on the Avenger");
		return;
	}
	// The rest needs the campaign's Geoscape.
	if (S == none)
	{
		Out.AddItem("ERR no Geoscape in this campaign yet (geoscape opens it)");
		return;
	}
	switch (Cmd)
	{
	case "geo":
		Dump(S, Out);
		return;
	case "decisions":
		Decisions(S, Out);
		return;
	case "run":
		Before = S.EventCount;
		Out.AddItem("hours" @ class'XComGameState_LWStrategy'.static.Run(Args.Length > 1 ? int(Args[1]) : 1));
		S = class'XComGameState_LWStrategy'.static.Get();
		NewEvents(S, Before, Out);
		Refreshed();
		return;
	case "act":
		Geo = OpenGeoscape();
		if (Geo == none)
			Out.AddItem("ERR not on the Avenger");
		else
			Out.AddItem(Geo.Act(Args.Length > 1 ? int(Args[1]) : 0) ? "ok" : "ERR no such decision");
		return;
	case "intercepted":
		if (Args.Length < 4 || int(Args[1]) < 0 || int(Args[1]) >= S.Ufos.Length)
		{
			Out.AddItem("ERR intercepted <ufo> <outcome> <hp>");
			return;
		}
		Before = S.EventCount;
		class'XComGameState_LWStrategy'.static.Intercepted(int(Args[1]), int(Args[2]), int(Args[3]));
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		Refreshed();
		return;
	case "sat":
		if (Args.Length > 1 && Args[1] ~= "build")
			Out.AddItem(class'XComGameState_LWStrategy'.static.BuildSatellite() ? "ok" : "ERR not enough money");
		else if (Args.Length > 2 && Args[1] ~= "launch")
			Out.AddItem(class'XComGameState_LWStrategy'.static.LaunchSatellite(int(Args[2])) ? "ok" : "ERR none ready, or the country has one or has left");
		else
			Out.AddItem("ERR sat build | sat launch <country>");
		Refreshed();
		return;
	}
	Out.AddItem("ERR unknown command (help)");
}

function XComPresentationLayerBase Pres()
{
	return XComPlayerController(GetALocalPlayerController()).Pres;
}

function Screens(out array<string> Out)
{
	local UIScreen Screen;

	foreach Pres().ScreenStack.Screens(Screen)
		Out.AddItem(string(Screen.Class.Name));
}

/** The Geoscape screen, opened if it is not up (only on the Avenger). */
function UILWGeoscape OpenGeoscape()
{
	local XComHQPresentationLayer HQ;
	local UILWGeoscape Geo;

	HQ = XComHQPresentationLayer(Pres());
	if (HQ == none)
		return none;
	Geo = UILWGeoscape(HQ.ScreenStack.GetScreen(class'UILWGeoscape'));
	if (Geo == none)
	{
		Geo = HQ.Spawn(class'UILWGeoscape', HQ);
		HQ.ScreenStack.Push(Geo);
	}
	return Geo;
}

function Refreshed()
{
	local UILWGeoscape Geo;

	if (XComHQPresentationLayer(Pres()) == none)
		return;
	Geo = UILWGeoscape(Pres().ScreenStack.GetScreen(class'UILWGeoscape'));
	if (Geo != none)
		Geo.Refresh();
}

function NewEvents(XComGameState_LWStrategy S, int Before, out array<string> Out)
{
	local int i;

	for (i = Max(0, S.Events.Length - (S.EventCount - Before)); i < S.Events.Length; i++)
		Out.AddItem("event" @ S.Events[i]);
}

function Decisions(XComGameState_LWStrategy S, out array<string> Out)
{
	local array<int> Kinds, Indexes;
	local array<string> Labels;
	local int i;

	S.Decisions(Kinds, Indexes, Labels);
	for (i = 0; i < Kinds.Length; i++)
		Out.AddItem("decision" @ i @ "kind" @ Kinds[i] @ "index" @ Indexes[i] @ "|" @ Labels[i]);
}

/**
 * The whole game as XCOM 2 holds it: the screens up, then every object of its history, newest
 * version, with all its fields (BaseObject.ToString). With a filter, only the classes whose name
 * holds it. (The game's FileWriter does not open files in the shipped game: it comes back here.)
 */
function DumpAll(string Filter, out array<string> Out)
{
	local XComGameState_BaseObject Obj;
	local UIScreen Screen;

	foreach Pres().ScreenStack.Screens(Screen)
		Out.AddItem("== screen" @ Screen.Class.Name);
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_BaseObject', Obj)
	{
		if (Filter != "" && InStr(Locs(string(Obj.Class.Name)), Locs(Filter)) == INDEX_NONE)
			continue;
		Out.AddItem("== " $ Obj.Class.Name @ Obj.ObjectID);
		Out.AddItem(Obj.ToString(true));
	}
}

/** The Geoscape's state, a line a thing: "key value" pairs after the thing's name and number. */
function Dump(XComGameState_LWStrategy S, out array<string> Out)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int i;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Out.AddItem("date" @ S.DateText() @ "| month" @ S.Month @ "hours" @ S.Hours @ "money" @ XComHQ.GetSupplies() @ "resources" @ S.AlienResources @ "aggression" @ S.AlienAggression
		@ "satellites_ready" @ S.SatellitesReady @ "satellites_building" @ S.SatellitesDue.Length @ "pending" @ S.PendingKind @ "events" @ S.EventCount);
	for (i = 0; i < S.Countries.Length; i++)
		Out.AddItem("country" @ i @ S.Countries[i].Id @ "panic" @ S.Countries[i].Panic @ "satellite" @ int(S.Countries[i].bSatellite) @ "left" @ int(S.Countries[i].bLeft) @ "hunted" @ int(S.Countries[i].bHunted));
	for (i = 0; i < S.Ufos.Length; i++)
		Out.AddItem("ufo" @ i @ "objective" @ S.Ufos[i].Objective @ "group" @ S.Ufos[i].Group @ "last" @ int(S.Ufos[i].bLast) @ "ship" @ S.Ufos[i].Ufo @ "country" @ S.Ufos[i].Country
			@ "hour" @ S.Ufos[i].Hour @ "status" @ S.Ufos[i].Status @ "detected" @ int(S.Ufos[i].bDetected) @ "flight" @ S.Ufos[i].Flight @ "hp" @ S.Ufos[i].Hp @ "maxhp" @ S.Ufos[i].MaxHp
			@ "until" @ S.Ufos[i].Until @ "attacked" @ int(S.Ufos[i].bAttacked));
	for (i = 0; i < S.Sites.Length; i++)
		Out.AddItem("site" @ i @ "terror" @ int(S.Sites[i].bTerror) @ "country" @ S.Sites[i].Country @ "status" @ S.Sites[i].Status @ "until" @ S.Sites[i].Until);
	Decisions(S, Out);
	for (i = Max(0, S.Events.Length - 10); i < S.Events.Length; i++)
		Out.AddItem("event" @ S.Events[i]);
}

defaultproperties
{
	LinkMode = MODE_Text;
	ReceiveMode = RMODE_Event;
	bAlwaysTick = true;
}
