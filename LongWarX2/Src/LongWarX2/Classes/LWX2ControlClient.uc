// For development: one connection to the control port (LWX2Control): a command a line, the
// answer's lines, then ".". "help" lists the commands. Text mode, lines split here.
class LWX2ControlClient extends TcpLink dependson(XComGameState_LWStrategy, LWBaseRules, XComGameState_LWAirWar);

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

	if (!(Line ~= "ping" || Line ~= "screens" || Line ~= "geo" || Line ~= "decisions" || Line ~= "continue"))
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
	local string Cmd, Why;
	local XComGameState_Unit EffUnit;
	local int Before;

	ParseStringIntoArray(Line, Args, " ", true);
	if (Args.Length == 0)
		return;
	Cmd = Locs(Args[0]);
	S = class'XComGameState_LWStrategy'.static.Get();
	switch (Cmd)
	{
	case "help":
		Out.AddItem("ping | screens | geo | decisions | geoscape | run <hours> [all] | act <n> | intercepted <ufo> <outcome 0 crashed 1 destroyed 2 escaped> <ufo hp>");
		Out.AddItem("resolve <decision> won|captive|lost [stance]: a decision taken without playing it (an interception fought by the air war's rules, a mission's result given; captive: won with an alien taken alive)");
		Out.AddItem("auto <hours> [mission win %, default 100] [stance 0-2, default 1] [sats]: time at full speed, every decision taken (interceptions fought, missions won at the %, an alien taken alive when it can be); with sats also satellites bought and launched (the base grown for uplinks), two interceptors kept at home, research kept going");
		Out.AddItem("squad <kind 1 crash 2 landed 3 abduction 4 terror> [ufo or abduction difficulty] [day]: a squad Long War would send (its species, counted)");
		Out.AddItem("research [n]: XCOM 2's research list (Long War's techs: hours, affordable), the project under way; with n, that tech started");
		Out.AddItem("campaign [difficulty 0-3, default 1] [first]: a new campaign from the main menu, without its first mission unless 'first'");
		Out.AddItem("continue: the top screen's own way on (reports, loot, alerts, tips; else Enter) | key <UIUtilities_Input code>: any input (300 A, 301 B, 510 Esc, 513 Space)");
		Out.AddItem("sat build | sat launch <country> | win | exec <console command>");
		Out.AddItem("give-to <soldier> <item template>: an item put on a soldier (a test aid) | abilities: in a mission, each soldier's abilities and charges | use <soldier> <ability> [target, 99: force the nearest enemy, 98: at the soldier's feet, 97: at the nearest alien]: an ability used (no target: the targets) | enemies | spawn [alien] [tiles]: an alien dropped near the squad | capture: the arc thrower's capture on the nearest enemy (test aids)");
		Out.AddItem("builds: what engineering can build (Long War's item numbers, cost, time) and its projects | build <item> [n]: n of it begun | give <template> <n>: items put in the stores (a test aid)");
		Out.AddItem("foundry: the Foundry's available projects (ids), the one under way, those done | foundry <id>: that project begun | foundry done <id>: marked done (a test aid) | hqassault: the HQ assault from now (a test aid)");
		Out.AddItem("base: the base's tiles, numbers and facilities | base set <column> <row> <facility>: placed at once (a test aid) | work <column> <row> [facility id]: dig rock, a lift in the shaft, or the facility");
		Out.AddItem("hangar: the jets (index first), orders, bays | order [continent 0-4] [n] | transfer <jet> <continent> | equip <jet> <weapon 1-7>");
		Out.AddItem("units: in a mission, XCOM's units on the field (index first: tile, action points, sight) | move <unit> <x> <y> [z]: that unit walks to the tile by XCOM 2's own move (its path found as the game finds it; z omitted: the floor there)");
		Out.AddItem("state: one line of what the game is doing: phase (shell, strategy, tactical), map, top screen, film playing, in a mission the team whose turn it is and whether the game is still showing what happened (busy), and ready=1 when it waits on the player | lw.sh wait <regex> [s] / go <regex> [s]: until state matches (go also skips films and continues screens)");
		Out.AddItem("dump [class name part]: every game state object with all its fields (tools/test/lw-dump.sh saves it)");
		return;
	case "state":
		Out.AddItem(GameState());
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
	case "continue":
	case "key":
		Out.AddItem(Cmd == "continue" ? Continue() : Press(int(Args.Length > 1 ? Args[1] : "0")));
		return;
	case "campaign":
		Out.AddItem(NewCampaign(Args.Length > 1 ? int(Args[1]) : 1, Args.Length > 2 && Args[2] ~= "first"));
		return;
	case "research":
		Research(Args.Length > 1 ? Args[1] : "", Out);
		return;
	case "perk":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR perk <soldier index> <ability>");
			return;
		}
		Out.AddItem(GivePerk(int(Args[1]), name(Args[2])));
		return;
	case "give-to":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR give-to <soldier index (arm's order)> <item template>");
			return;
		}
		Out.AddItem(GiveTo(int(Args[1]), name(Args[2])));
		return;
	case "abilities":
		Abilities(Out);
		return;
	case "enemies":
		// enemies all: XCOM's units too.
		Enemies(Out, Args.Length > 1 && Args[1] == "all");
		return;
	case "parts":
		Parts(Out);
		return;
	case "crew":
		// crew: how many soldiers XCOM has, and of what rank.
		Out.AddItem(Crew());
		return;
	case "armory":
		Out.AddItem(OpenArmory(Args.Length > 1 ? int(Args[1]) : 0));
		return;
	case "capture":
		Out.AddItem(CaptureNearest());
		return;
	case "psi":
		Psi(Args, Out);
		return;
	case "gene":
		Gene(Args, Out);
		return;
	case "ots":
		// The Officer Training School's squad sizes: 'ots' what the next needs, 'ots buy' buys it.
		if (Args.Length > 1 && Args[1] ~= "buy")
			Out.AddItem(class'XComGameState_LWStrategy'.static.BuySquadSize(Why) ? "ok squad size" @ class'UILWHeadquarters'.static.SquadSize() : "ERR needs" @ Why);
		else
		{
			class'XComGameState_LWStrategy'.static.CanBuySquadSize(class'XComGameState_LWStrategy'.static.Get(), Why);
			Out.AddItem("squad size" @ class'UILWHeadquarters'.static.SquadSize() $ "; ranks in the barracks" @ class'XComGameState_LWStrategy'.static.RanksInBarracks() $ (Why != "" ? "; the next needs" @ Why : "; the next can be bought"));
		}
		return;
	case "effects":
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', EffUnit)
			if (EffUnit.GetTeam() == eTeam_XCom && EffUnit.IsSoldier() && !EffUnit.bRemovedFromPlay)
				Out.AddItem(EffUnit.GetFullName() @ "will" @ int(EffUnit.GetCurrentStat(eStat_Will)) @ "hp" @ int(EffUnit.GetCurrentStat(eStat_HP)) $ "/" $ int(EffUnit.GetMaxStat(eStat_HP)) @ (EffUnit.IsInWorldEffectTile(class'X2Effect_ApplySmokeGrenadeToWorld'.Name) ? "IN SMOKE" : "") @ "ap" @ EffUnit.ActionPoints.Length @ "reserve" @ JoinNames(EffUnit.ReserveActionPoints) $ ":" @ JoinNames(EffUnit.AffectedByEffectNames));
		return;
	case "near":
		Out.AddItem(MoveNear(Args.Length > 1 ? Args[1] : "", Args.Length > 2 ? int(Args[2]) : 8));
		return;
	case "next":
		Out.AddItem(MoveNext(Args.Length > 1 ? Args[1] : "", Args.Length > 2 ? Args[2] : ""));
		return;
	case "unbox":
		Out.AddItem("moved" @ class'LWX2PartPlacer'.static.FreeBoxedIn(Args.Length > 1 ? int(Args[1]) : 40));
		return;
	case "ewscreen":
		Out.AddItem(Args.Length > 1 ? class'UILWEWScreen'.static.ShowMovie(Args[1], Args.Length > 2 ? Args[2] : "") : "ERR ewscreen <EW movie: MissionControl, StrategyHUD …>");
		return;
	case "ewhudcall":
		// ewhudcall <function> [arguments; _ for a space]: a function of EW's strategy HUD movie (a test aid).
		Out.AddItem(HUDCall(Args));
		return;
	case "ewhud":
		class'UILWEWStrategyHUD'.static.ShowIfAvailable();
		Out.AddItem("ok");
		return;
	case "ewsitroom":
		Out.AddItem(class'UILWEWSituationRoom'.static.Open());
		return;
	case "ewresearch":
		Out.AddItem(class'UILWEWResearch'.static.Open());
		return;
	case "ewvar":
		// A variable inside the open EW movie: ewvar <path below the screen's clip>.
		Out.AddItem(class'UILWEWScreen'.static.ReadVar(Args.Length > 1 ? Args[1] : ""));
		return;
	case "ewcall":
		// A function of the open EW movie: ewcall <function> [arguments; _ for a space].
		Out.AddItem(class'UILWEWScreen'.static.CallMovie(Args));
		return;
	case "ewmat":
		// A parameter of every stand-in material on the EW map, live: ewmat <parameter> <number | texture path>.
		Out.AddItem(SetEWMaterials(Args.Length > 1 ? name(Args[1]) : '', Args.Length > 2 ? Args[2] : ""));
		return;
	case "stopmovie":
		// The movie playing (the new campaign's intro, which the first mission waits for) stopped.
		Out.AddItem("movie playing:" @ class'XComEngine'.static.IsAnyMoviePlaying());
		class'XComEngine'.static.StopCurrentMovie();
		return;
	case "buildings":
		// The plot's building volumes as XCOM 2 sees them; with an action on the n-th: buildings [n show <lo> <hi> | n reveal | n rebuild].
		Buildings(Args, Out);
		return;
	case "fog":
		// The fog of war's state (fog state), turned on as XCOM 2 does at the battle's start (fog on), or its levels, live:
		// fog <never seen> <seen before> <never seen shown as seen: 0 or 1>.
		if (Args.Length > 1 && (Args[1] == "state" || Args[1] == "on"))
		{
			if (Args[1] == "on")
			{
				`XWORLD.bEnableFOW = true;
				`XWORLD.bDebugEnableFOW = true;
				`XWORLD.bEnableFOWUpdate = true;
				`BATTLE.m_kLevel.SetupXComFOW(true);
				`XWORLD.bFOWTextureBufferIsDirty = true;
				`XWORLD.ForceUpdateAllFOWViewers();
				`BATTLE.SetFOW(true);
			}
			FogState(Out);
			return;
		}
		class'LWX2PartPlacer'.default.FogNeverSeen = Args.Length > 1 ? float(Args[1]) : 0.0;
		class'LWX2PartPlacer'.default.FogHaveSeen = Args.Length > 2 ? float(Args[2]) : 0.0;
		class'LWX2PartPlacer'.default.FogNeverSeenAsHaveSeen = Args.Length > 3 && Args[3] == "1";
		class'LWX2PartPlacer'.static.Fog(`XWORLD);
		`XWORLD.ForceUpdateAllFOWViewers();
		Out.AddItem("fog never" @ `XWORLD.FOWNeverSeen @ "seen" @ `XWORLD.FOWHaveSeen @ "never as seen" @ `XWORLD.bShowNeverSeenAsHaveSeen);
		return;
	case "ewlight":
		// EW's placed lights of a kind (point, spot, sun, sky; all) at a scale of their brightness now, live: ewlight <kind> <scale>.
		Out.AddItem(ScaleEWLights(Args.Length > 1 ? Args[1] : "", Args.Length > 2 ? float(Args[2]) : 1.0));
		return;
	case "psichance":
		PsiChances(Out, Args.Length > 1 ? name(Args[1]) : '');
		return;
	case "hurt":
		Out.AddItem(Hurt(Args.Length > 1 ? Args[1] : "", Args.Length > 2 ? int(Args[2]) : 1));
		return;
	case "killaliens":
		Out.AddItem(KillAliens());
		return;
	case "endturn":
		if (XComTacticalController(GetALocalPlayerController()) == none)
		{
			Out.AddItem("ERR not in a mission");
			return;
		}
		// PerformEndTurn answers false while the turn ends all the same (seen in a mission's log): its answer is not reported.
		XComTacticalController(GetALocalPlayerController()).PerformEndTurn(ePlayerEndTurnType_PlayerInput);
		Out.AddItem("ok end of turn asked");
		return;
	case "tire":
		// tire <hours>: the squad tired as if back from a mission (a test aid for Long War's fatigue).
		Out.AddItem(class'LWFatigue'.static.Tire(Args.Length > 1 ? int(Args[1]) : 100));
		return;
	case "windowsight":
		// Sight across each window piece (two tiles either side, along X and Y), and across walls for comparison.
		Out.AddItem(WindowSight("Window"));
		Out.AddItem(WindowSight("Wall"));
		return;
	case "seethrough":
		// How many placed pieces units see through (EW's windows, foliage, cars), and how many are windows.
		Out.AddItem(SeeThrough());
		return;
	case "look":
		if (Args.Length < 3 && !(Args.Length == 2 && Args[1] == "unit"))
		{
			Out.AddItem("ERR look <x> <y> [z] (Enemy Within's coordinates on its placed map; 'look pod <n>' its pod n; 'look unit [n]' the n-th living unit, none: the list)");
			return;
		}
		Out.AddItem(Look(Args));
		return;
	case "doors":
		// The level's interactive actors (doors): where, whether XCOM 2 takes it for a door, its mesh, tree and sets;
		// doors register: each added to the world's tile data again (what its PostBeginPlay does), then listed.
		if (Args.Length > 1 && Args[1] == "register")
			RegisterDoors(Out);
		Doors(Out);
		return;
	case "ewbody":
		// An experiment (features/lw-ew-units.md): every unit of a template given an EW body, live:
		// ewbody <template> <mesh path> <AnimSet path> <diffuse path> <normal path>.
		if (Args.Length < 4)
		{
			Out.AddItem("ERR ewbody <template> <mesh> <AnimSet> [diffuse] [normal]");
			return;
		}
		Out.AddItem(EWBody(name(Args[1]), Args[2], Args[3], Args.Length > 4 ? Args[4] : "", Args.Length > 5 ? Args[5] : ""));
		return;
	case "bodies":
		// Every unit on the field given its template's EW body (features/lw-ew-units.md), as the battle's start does.
		Out.AddItem(class'LWX2EWBodies'.static.ApplyAll() @ "units given Enemy Within's body");
		return;
	case "blast":
		// blast <x> <y> <z> [radius, default 192] [damage, default 10]: environment damage there, as an explosion's (walls).
		if (Args.Length < 4)
		{
			Out.AddItem("ERR blast <x> <y> <z> [radius] [damage]");
			return;
		}
		Out.AddItem(Blast(vect(0,0,0) + vect(1,0,0) * float(Args[1]) + vect(0,1,0) * float(Args[2]) + vect(0,0,1) * float(Args[3]), Args.Length > 4 ? float(Args[4]) : 192.0, Args.Length > 5 ? int(Args[5]) : 10));
		return;
	case "meshes":
		// meshes <part of a mesh's path>: each placed piece of such a mesh: class, hidden, its cut heights, the floor caching it.
		if (Args.Length > 1)
			Meshes(Args[1], Out);
		return;
	case "standable":
		// standable <part of a mesh's path>: for the placed pieces of such meshes, the tiles over them units can stand on.
		Out.AddItem(Args.Length > 1 ? Standable(Args[1]) : "ERR standable <part of a mesh's path>");
		return;
	case "pod":
		// pod [tiles]: a pod of two Sectoids spawned as the missions spawn Long War's pods (LWMissionSquads.SpawnPod), near the squad.
		Out.AddItem(TestPod(Args.Length > 1 ? int(Args[1]) : 4));
		return;
	case "history":
		// history [n]: the last n abilities used in the mission (default 20), newest last: who, what, on whom.
		History(Out, Args.Length > 1 ? int(Args[1]) : 20);
		return;
	case "anims":
		// anims [n] [all|relink1|relink2|play <name>]: the n-th enemy's (else the nearest's) animation nodes in play: the name asked for, found or not, weight.
		Anims(Out, Args.Length > 1 ? int(Args[1]) : -1, Args.Length > 2 && Args[2] == "all", (Args.Length > 2 && Left(Args[2], 6) == "relink") ? int(Mid(Args[2], 6)) : 0, (Args.Length > 3 && Args[2] == "play") ? name(Args[3]) : '');
		return;
	case "flashnum":
		// flashnum <path under the top screen's clip>: a Flash number there (where the EW screens' clips sit).
		Out.AddItem(Args.Length > 1 ? (Args[1] @ "=" @ Pres().ScreenStack.GetCurrentScreen().MC.GetNum(Args[1])) : "ERR flashnum <path>");
		return;
	case "units":
		XComUnits(Out);
		return;
	case "move":
		if (Args.Length < 4)
		{
			Out.AddItem("ERR move <unit index (units)> <tile x> <tile y> [tile z]");
			return;
		}
		Out.AddItem(MoveUnit(int(Args[1]), int(Args[2]), int(Args[3]), Args.Length > 4 ? int(Args[4]) : -1));
		return;
	case "spawn":
		// spawn [template] [tiles] [Long War species, as the pods tag theirs: its EW body by species] [leader level]
		Out.AddItem(SpawnAlien(Args.Length > 1 ? name(Args[1]) : 'Sectoid', Args.Length > 2 ? int(Args[2]) : 2, Args.Length > 3 ? int(Args[3]) : 0, Args.Length > 4 ? int(Args[4]) : 0));
		return;
	case "use":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR use <soldier name or class part> <ability> [target index]");
			return;
		}
		// <ability>:<item template>: the ability of that item (a soldier's grenades each have their ThrowGrenade).
		Out.AddItem(UseAbility(Args[1], name(InStr(Args[2], ":") == INDEX_NONE ? Args[2] : Left(Args[2], InStr(Args[2], ":"))), Args.Length > 3 ? int(Args[3]) : -1, InStr(Args[2], ":") == INDEX_NONE ? '' : name(Mid(Args[2], InStr(Args[2], ":") + 1))));
		return;
	case "give":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR give <template> <n>");
			return;
		}
		Give(name(Args[1]), int(Args[2]), Out);
		return;
	case "arm":
		if (Args.Length > 1 && Args[1] ~= "now")
			Out.AddItem("armed" @ class'LWX2Gear'.static.ArmAll());
		class'LWX2Gear'.static.Report(Out);
		return;
	case "geoscape":
		Out.AddItem(OpenGeoscape() != none ? "ok" : "ERR not on the Avenger");
		return;
	case "open":
		// The armory's loadout of the first soldier (arm's order), as the armory opens it.
		if (Args.Length > 1 && Args[1] ~= "loadout")
		{
			Out.AddItem(OpenLoadout());
			return;
		}
		// A Geoscape screen opened, as its button opens it (a test aid: base, hangar, engineering).
		Geo = OpenGeoscape();
		if (Geo == none)
			Out.AddItem("ERR not on the Avenger");
		else if (Args.Length > 1 && Args[1] ~= "base")
			Geo.OnBase(none);
		else if (Args.Length > 1 && Args[1] ~= "hangar")
			Geo.OnHangar(none);
		else if (Args.Length > 1 && Args[1] ~= "engineering")
			Geo.OnEngineering(none);
		else
			Out.AddItem("ERR open base|hangar|engineering|loadout");
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
		Out.AddItem("hours" @ class'XComGameState_LWStrategy'.static.Run(Args.Length > 1 ? int(Args[1]) : 1, Args.Length > 2 && Args[2] ~= "all"));
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
	case "squad":
		Squad(S, Args.Length > 1 ? int(Args[1]) : 1, Args.Length > 2 ? int(Args[2]) : 4, Args.Length > 3 ? int(Args[3]) : S.Days(), Out);
		return;
	case "resolve":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR resolve <decision> won|captive|lost [stance 0-2]");
			return;
		}
		Before = S.EventCount;
		Out.AddItem(ResolveDecision(int(Args[1]), Args[2] ~= "won" || Args[2] ~= "captive", Args.Length > 3 ? int(Args[3]) : 1, Args[2] ~= "captive"));
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		Refreshed();
		return;
	case "auto":
		AutoPlay(Args.Length > 1 ? int(Args[1]) : 720, Args.Length > 2 ? int(Args[2]) : 100, Args.Length > 3 ? int(Args[3]) : 1, InStr(Locs(Line), " sats") != INDEX_NONE, Out);
		Refreshed();
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
	case "builds":
		Builds(S, Out);
		return;
	case "build":
		if (Args.Length < 2)
		{
			Out.AddItem("ERR build <item> [n]");
			return;
		}
		Before = S.EventCount;
		Out.AddItem(class'LWEngineering'.static.Start(int(Args[1]), Args.Length > 2 ? int(Args[2]) : 1, Why) ? "ok" : "ERR" @ Why);
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		Refreshed();
		return;
	case "base":
		if (Args.Length > 4 && Args[1] ~= "set")
		{
			BaseSet(int(Args[2]) - 1, int(Args[3]) - 1, int(Args[4]));
			S = class'XComGameState_LWStrategy'.static.Get();
			Refreshed();
		}
		Base(S, Out);
		return;
	case "hangar":
		Hangar(Out);
		return;
	case "order":
		Before = S.EventCount;
		Out.AddItem(class'LWHangar'.static.Order(Args.Length > 1 ? int(Args[1]) : class'LWHangar'.static.HomeContinent(), Args.Length > 2 ? int(Args[2]) : 1, Why) ? "ok" : "ERR" @ Why);
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		return;
	case "transfer":
	case "equip":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR" @ Cmd @ "<jet> <" $ (Cmd == "equip" ? "weapon 1-7" : "continent 0-4") $ ">");
			return;
		}
		Before = S.EventCount;
		if (Cmd == "equip")
			Out.AddItem(class'LWHangar'.static.Equip(int(Args[1]), int(Args[2]), Why) ? "ok" : "ERR" @ Why);
		else
			Out.AddItem(class'LWHangar'.static.Transfer(int(Args[1]), int(Args[2]), Why) ? "ok" : "ERR" @ Why);
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		return;
	case "work":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR work <column 1-7> <row 1-5> [facility id]");
			return;
		}
		Before = S.EventCount;
		Out.AddItem(class'LWBase'.static.Work(int(Args[1]) - 1, int(Args[2]) - 1, Args.Length > 3 ? int(Args[3]) : 0, Why) ? "ok" : "ERR" @ Why);
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		Refreshed();
		return;
	case "hqassault":
		HQAssaultNow();
		Out.AddItem("the aliens go for XCOM's headquarters from now (a test aid)");
		return;
	case "foundry":
		if (Args.Length < 2)
		{
			Foundry(S, Out);
			return;
		}
		if (Args[1] ~= "done" && Args.Length > 2)
		{
			FoundryDone(int(Args[2]));
			Out.AddItem("done" @ class'LWEngineering'.static.FoundryName(int(Args[2])));
			Refreshed();
			return;
		}
		Before = S.EventCount;
		Out.AddItem(class'LWEngineering'.static.StartFoundry(int(Args[1]), Why) ? "ok" : "ERR" @ Why);
		NewEvents(class'XComGameState_LWStrategy'.static.Get(), Before, Out);
		Refreshed();
		return;
	case "sat":
		if (Args.Length > 1 && Args[1] ~= "build")
			Out.AddItem(class'XComGameState_LWStrategy'.static.BuildSatellite() ? "ok" : "ERR not enough money");
		else if (Args.Length > 2 && Args[1] ~= "launch")
			Out.AddItem(class'XComGameState_LWStrategy'.static.LaunchSatellite(int(Args[2])) ? "ok" : "ERR none ready, the uplinks are full, or the country has one or has left");
		else
			Out.AddItem("ERR sat build | sat launch <country>");
		Refreshed();
		return;
	}
	Out.AddItem("ERR unknown command (help)");
}

/**
 * A new campaign from the main menu, as the difficulty screen's Start makes one
 * (UIShellDifficulty.OnDifficultyConfirm): no tutorial, no narrative, no intro movie; without its
 * first mission unless asked (the development shell's "skip first tactical").
 */
function string NewCampaign(int Difficulty, bool bFirstMission)
{
	local XComGameState Start;
	local XComGameState_CampaignSettings Settings;
	local UIShellDifficulty.DifficultyConfiguration D;
	local array<name> NoOptions;

	if (XComShellPresentationLayer(Pres()) == none)
		return "ERR not at the main menu";
	Difficulty = Clamp(Difficulty, 0, 3);
	D = class'UIShellDifficulty'.default.DifficultyConfigurations[Difficulty];
	NoOptions.Length = 0;
	`XCOMHISTORY.ResetHistory();
	Start = class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(, , false, false, true, Difficulty,
		D.TacticalDifficulty, D.StrategyDifficulty, D.GameLength, true, NoOptions, , false, , , NoOptions);
	Settings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	Settings.SetStartTime(Start.TimeStamp);
	Settings.bSkipFirstTactical = !bFirstMission;
	Settings.SetDifficulty(Difficulty, D.TacticalDifficulty, D.StrategyDifficulty, D.GameLength);
	GetALocalPlayerController().ConsoleCommand("open Avenger_Root?game=XComGame.XComHeadQuartersGame");
	return "ok difficulty" @ Difficulty @ (bFirstMission ? "with" : "without") @ "the first mission";
}

/**
 * The top screen passed the way its continue button would, for the screens that only report:
 * the Skyranger's briefing launched or left, the after-action report's Continue, an alert's
 * confirm, the loot, mission summary, tips and rewards recap closed. Nothing on the screens where
 * the player decides (the base, a facility, the maps, a mission's HUD, the main menu), and nothing on
 * a screen it does not know: a blind Enter there takes decisions (it bonded two soldiers once).
 */
/**
 * One line a script can wait on (lw.sh wait / go): phase=shell|strategy|tactical|other map=<map> screen=<top screen>
 * movie=0|1, in a mission turn=<team whose units act> busy=0|1 (the visualizer still showing what happened) ended=0|1,
 * and ready=1 when the game waits on the player (no film, nothing being shown; in a mission XCOM's turn with the HUD up).
 */
function string GameState()
{
	local string Phase, Screen, Mission;
	local bool bMovie, bReady, bBusy;
	local XComGameState_Player Player;
	local UIScreen Top;

	if (XComTacticalGame(WorldInfo.Game) != none)
		Phase = "tactical";
	else if (XComHeadquartersGame(WorldInfo.Game) != none)
		Phase = "strategy";
	else if (XComShell(WorldInfo.Game) != none)
		Phase = "shell";
	else
		Phase = "other";
	Top = (Pres() != none && Pres().ScreenStack != none) ? Pres().ScreenStack.GetCurrentScreen() : none;
	Screen = Top != none ? string(Top.Class.Name) : "none";
	bMovie = class'XComEngine'.static.IsAnyMoviePlaying();
	bReady = !bMovie && Top != none;
	if (Phase == "tactical" && `TACTICALRULES != none)
	{
		Player = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID));
		bBusy = !class'XComGameStateVisualizationMgr'.static.VisualizerIdleAndUpToDateWithHistory();
		// cinematic: the mission's intro camera (the squad leaving the Skyranger) still running, the HUD already up.
		Mission = " turn=" $ (Player != none ? string(Player.TeamFlag) : "none") @ "busy=" $ int(bBusy) @ "cinematic=" $ int(GetALocalPlayerController().bCinematicMode)
			@ "ended=" $ int(`TACTICALRULES.HasTacticalGameEnded());
		bReady = bReady && !bBusy && !GetALocalPlayerController().bCinematicMode && Player != none && Player.TeamFlag == eTeam_XCom && (UITacticalHUD(Top) != none || UISpecialMissionHUD(Top) != none);
	}
	return "phase=" $ Phase @ "map=" $ WorldInfo.GetMapName() @ "screen=" $ Screen @ "movie=" $ int(bMovie) $ Mission @ "ready=" $ int(bReady);
}

function string Continue()
{
	local UIScreen Top;

	Top = Pres().ScreenStack.GetCurrentScreen();
	if (Top == none || UIFacilityGrid(Top) != none || UIFacility(Top) != none || UIStrategyMap(Top) != none || UILWGeoscape(Top) != none
		|| UITacticalHUD(Top) != none || UISpecialMissionHUD(Top) != none || UIShell(Top) != none)
		return "nothing to continue:" @ (Top != none ? string(Top.Class.Name) : "no screen");
	if (UIDropShipBriefing_MissionStart(Top) != none || UIDropShipBriefing_MissionEnd(Top) != none)
		WorldInfo.bContinueToSeamlessTravelDestination = true; // what the Skyranger's "press any key" sets (X2TacticalGameRuleset waits on it)
	else if (UIAfterAction(Top) != none)
		UIAfterAction(Top).OnContinue();
	else if (UIAlert(Top) != none)
		UIAlert(Top).OnConfirmClicked(none);
	else if (UIInventory_LootRecovered(Top) != none || UIMissionSummary(Top) != none || UITutorialBox(Top) != none || UIRewardsRecap(Top) != none
		|| UISoldierBondAlert(Top) != none || UIArmory_Photobooth(Top) != none || UIMissionIntro(Top) != none)
		Top.CloseScreen();
	else
		return "unknown screen, not touched:" @ Top.Class.Name;
	return "continued" @ Top.Class.Name;
}

/** An input pressed and released on the screen stack, as the keyboard or a gamepad would: what was on top before and after. */
function string Press(int Code)
{
	local string Before;

	Before = Pres().ScreenStack.GetCurrentScreen() != none ? string(Pres().ScreenStack.GetCurrentScreen().Class.Name) : "none";
	Pres().ScreenStack.OnInput(Code, class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
	Pres().ScreenStack.OnInput(Code, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
	return "pressed" @ Code @ "on" @ Before;
}

/** A squad as Long War would make it now (or on the given day): its species, counted. */
function Squad(XComGameState_LWStrategy S, int Kind, int Which, int Day, out array<string> Out)
{
	local array<int> Aliens, Kinds, Counts;
	local int a, k;
	local string Line;

	Aliens = class'LWAlienSquads'.static.SquadFor(Kind, Which, Day, S.AlienAggression, S.AlienResources, Which, S.TerrorsTaken);
	foreach Aliens(a)
	{
		k = Kinds.Find(a);
		if (k == INDEX_NONE)
		{
			Kinds.AddItem(a);
			Counts.AddItem(1);
		}
		else
			Counts[k]++;
	}
	for (k = 0; k < Kinds.Length; k++)
		Line @= Counts[k] @ (class'LWStrategyRules'.default.Species.Find('Char', Kinds[k]) != INDEX_NONE
			? string(class'LWStrategyRules'.default.Species[class'LWStrategyRules'.default.Species.Find('Char', Kinds[k])].Name) : string(Kinds[k])) $ ",";
	Out.AddItem("squad of" @ Aliens.Length $ ":" $ Line);
}

/** XCOM 2's research: the techs available, with their hours and whether they can be paid for; or one started (as the research screen starts it). */
/** Engineering: each unlocked item (its number first, for build), then the projects. */
function Builds(XComGameState_LWStrategy S, out array<string> Out)
{
	local array<int> Items;
	local int Item;
	local XComGameState_LWStrategy.LWBuild P;

	Items = class'LWEngineering'.static.Buildable();
	foreach Items(Item)
		Out.AddItem("item" @ Item @ class'LWEngineering'.static.BuildLine(Item, S.Engineers));
	foreach S.Builds(P)
		Out.AddItem("project item" @ P.Item @ "quantity" @ P.Quantity @ "work" @ P.WorkLeft @ "engineers" @ P.Engineers @ "hours" @ class'LWEngineering'.static.HoursFor(P.WorkLeft, P.Engineers, S.Engineers));
	Out.AddItem("engineers" @ S.Engineers);
}

/** The hangar: a line per jet (its index first), the orders, the bays per continent. */
function Hangar(out array<string> Out)
{
	local XComGameState_LWAirWar AirWar;
	local int i;
	local string Line;

	class'XComGameState_LWAirWar'.static.EnsureExists();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	for (i = 0; i < AirWar.Jets.Length; i++)
		Out.AddItem("jet" @ i @ class'LWHangar'.static.JetText(AirWar.Jets[i]));
	for (i = 0; i < AirWar.Orders.Length; i++)
		Out.AddItem("order" @ AirWar.Orders[i].Count @ "to" @ class'LWStrategyRules'.static.ContinentName(AirWar.Orders[i].Continent) @ "in" @ AirWar.Orders[i].HoursLeft $ "h");
	Line = "bays taken:";
	for (i = 0; i < 5; i++)
		Line @= i $ "=" $ class'LWStrategyRules'.static.ContinentName(i) @ class'LWHangar'.static.BaysTaken(AirWar, i) $ "/" $ class'LWBaseRules'.default.HangarBays $ ";";
	Out.AddItem(Line);
	Out.AddItem("interceptor" @ class'LWStrategyRules'.static.Money(class'LWBaseRules'.default.InterceptorCost) @ "upkeep" @ class'LWStrategyRules'.static.Money(class'LWHangar'.static.Upkeep()) $ "/month");
}

/** The base: a line per row of tiles, its numbers, and each facility that could be built with what it needs. */
function Base(XComGameState_LWStrategy S, out array<string> Out)
{
	local LWBaseRules.LWFacilityDef F;
	local string Line, Why;
	local int X, Y;

	if (S.TileType.Length == 0)
	{
		class'XComGameState_LWStrategy'.static.Run(0);
		S = class'XComGameState_LWStrategy'.static.Get();
	}
	for (Y = 0; Y < class'LWBase'.const.H; Y++)
	{
		Line = "row" @ (Y + 1) $ ":";
		for (X = 0; X < class'LWBase'.const.W; X++)
			Line @= "[" $ class'LWBase'.static.TileText(S, X, Y) $ "]";
		Out.AddItem(Line);
	}
	Out.AddItem(class'LWBase'.static.Summary(S));
	foreach class'LWBaseRules'.default.Facilities(F)
	{
		if (F.Cash < 0)
			continue;
		class'LWBase'.static.CanBuild(S, F, Why);
		Out.AddItem("facility" @ F.Id @ class'LWBase'.static.FacilityName(F.Id) @ class'LWStrategyRules'.static.Money(F.Cash) @ "power" @ F.Power @ "days" @ F.Days @ (Why != "" ? "needs" @ Why : "ok"));
	}
}

/** The Foundry: each available project (its id first, for foundry <id>), the one under way, those done. */
function Foundry(XComGameState_LWStrategy S, out array<string> Out)
{
	local array<int> Ids;
	local int Id;
	local XComGameState_LWStrategy.LWBuild P;
	local string Done;

	Ids = class'LWEngineering'.static.FoundryAvailable();
	foreach Ids(Id)
		Out.AddItem("project" @ Id @ class'LWEngineering'.static.FoundryLine(Id, S));
	foreach S.FoundryProjects(P)
		Out.AddItem("under_way" @ P.Item @ "work" @ P.WorkLeft @ "engineers" @ P.Engineers @ "hours" @ class'LWEngineering'.static.HoursFor(P.WorkLeft, P.Engineers, S.Engineers));
	foreach S.FoundryDone(Id)
		Done @= string(Id);
	Out.AddItem("done" $ Done);
}

/** For auto play: the quickest tech XCOM can pay for started, if none is under way. What in What. */
function bool AutoResearch(out string What)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech Tech;
	local array<StateObjectReference> Refs;
	local int i, Best, Hours, BestHours;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ == none || XComHQ.GetCurrentResearchTech() != none)
		return false;
	Refs = XComHQ.GetAvailableTechsForResearch();
	Best = -1;
	for (i = 0; i < Refs.Length; i++)
	{
		Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Refs[i].ObjectID));
		if (!XComHQ.MeetsRequirmentsAndCanAffordCost(Tech.GetMyTemplate().Requirements, Tech.GetMyTemplate().Cost, XComHQ.ResearchCostScalars, 0.0, Tech.GetMyTemplate().AlternateRequirements))
			continue;
		Hours = XComHQ.GetResearchHours(Refs[i]);
		if (Best < 0 || Hours < BestHours)
		{
			Best = i;
			BestHours = Hours;
		}
	}
	if (Best < 0)
		return false;
	XComHQ.SetNewResearchProject(Refs[Best]);
	What = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Refs[Best].ObjectID)).GetMyTemplate().DisplayName @ "(" $ BestHours $ "h)";
	return true;
}

/** The HQ assault planned from this hour (a test aid). */
function HQAssaultNow()
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the HQ assault (control port)");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
	S.AddHQAssault(S.Hours - 48);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** A facility put on a tile at once, whatever the tile (a test aid). */
function BaseSet(int X, int Y, int Facility)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	if (!class'LWBase'.static.IsValid(X, Y))
		return;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a facility placed (control port)");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
	class'LWBase'.static.SetFacility(S, Facility, X, Y);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** A Foundry project marked done (a test aid). */
function FoundryDone(int Id)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a Foundry project done (control port)");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
	if (S.FoundryDone.Find(Id) == INDEX_NONE)
		S.FoundryDone.AddItem(Id);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/** The armory's loadout screen for the first soldier (a test aid: the small-item slots seen as the player sees them). */
function string OpenLoadout()
{
	local XComHQPresentationLayer HQPres;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;

	HQPres = `HQPRES;
	if (HQPres == none)
		return "ERR not on the Avenger";
	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		HQPres.UIArmory_Loadout(Ref);
		return "ok" @ Unit.GetFullName() $ "'s loadout";
	}
	return "ERR no soldier";
}

/** A perk given to a soldier (XCOM 2's training-centre abilities; a test aid). */
function string GivePerk(int Index, name AbilityName)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local ClassAgnosticAbility Perk;
	local X2AbilityTemplate Template;
	local int n;

	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier() || n++ != Index)
			continue;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a perk given (control port)");
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Perk.AbilityType.AbilityName = AbilityName;
		// Shots with the weapon (as the classes' trees give them: ApplyToWeaponSlot).
		Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
		if (Template != none && (Template.AbilitySourceName == 'eAbilitySource_Psionic' || X2AbilityTarget_Single(Template.AbilityTargetStyle) != none && Template.AbilityToHitCalc != none && X2AbilityToHitCalc_StandardAim(Template.AbilityToHitCalc) != none))
			Perk.AbilityType.ApplyToWeaponSlot = eInvSlot_PrimaryWeapon;
		Perk.bUnlocked = true;
		Unit.AWCAbilities.AddItem(Perk);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		return "ok" @ Unit.GetFullName() @ "has" @ AbilityName;
	}
	return "ERR no such soldier";
}

/** An item from the stores (made if none) put on a soldier, in its own slot (a test aid). */
function string GiveTo(int Index, name ItemName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local X2EquipmentTemplate Template;
	local XComGameState_Item Item;
	local array<XComGameState_Unit> Soldiers;
	local StateObjectReference Ref;
	local EInventorySlot Slot;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit != none && Unit.IsSoldier())
			Soldiers.AddItem(Unit);
	}
	Template = X2EquipmentTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemName));
	if (Index < 0 || Index >= Soldiers.Length || Template == none)
		return "ERR no such soldier or item";
	Slot = Template.InventorySlot;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: an item given to a soldier (control port)");
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldiers[Index].ObjectID));
	Item = Template.CreateInstanceFromTemplate(NewGameState);
	if (Slot != eInvSlot_Utility && Unit.GetItemInSlot(Slot, NewGameState) != none)
		Unit.RemoveItemFromInventory(XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Unit.GetItemInSlot(Slot, NewGameState).ObjectID)), NewGameState);
	if (!Unit.AddItemToInventory(Item, Slot, NewGameState))
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		return "ERR the slot takes no more";
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return "ok" @ Unit.GetFullName() @ "carries" @ ItemName @ "in" @ Slot;
}

/** In a mission: each of XCOM's units with the abilities it can use (and their charges). */
function Abilities(out array<string> Out)
{
	local XComGameState_Unit Unit;
	local XComGameState_Ability Ability;
	local StateObjectReference Ref;
	local string Line;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() != eTeam_XCom || !Unit.IsSoldier() || Unit.bRemovedFromPlay)
			continue;
		Line = Unit.GetFullName() @ "(" $ Unit.GetSoldierClassTemplateName() $ ") hp" @ int(Unit.GetCurrentStat(eStat_HP)) @ "aim" @ int(Unit.GetCurrentStat(eStat_Offense)) $ ":";
		foreach Unit.Abilities(Ref)
		{
			Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
			if (Ability != none && Ability.GetMyTemplate().eAbilityIconBehaviorHUD != eAbilityIconBehavior_NeverShow)
				Line @= Ability.GetMyTemplateName() $ (Ability.GetSourceWeapon() != none ? "[" $ Ability.GetSourceWeapon().GetMyTemplateName() $ " " $ Ability.GetSourceWeapon().Ammo $ "]" : "");
		}
		Out.AddItem(Line);
	}
}

/** XCOM 2's armory opened on a soldier of the crew (by its index). */
function string OpenArmory(int Index)
{
	local XComHQPresentationLayer HQ;
	local StateObjectReference Ref;
	local XComGameState_Unit Unit;
	local int n;

	HQ = XComHQPresentationLayer(Pres());
	if (HQ == none)
		return "ERR not on the Avenger";
	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		if (n++ == Index)
		{
			HQ.UIArmory_MainMenu(Ref);
			return "ok" @ Unit.GetFullName();
		}
	}
	return "ERR no such soldier";
}

/** A tree's nodes under a node, indented, with the weights of each blend's children (control aid anims n relink8). */
function TreeLines(out array<string> Out, AnimNode Node, int Depth)
{
	local AnimNodeBlendBase Blend;
	local string Pad;
	local int i;

	if (Node == none || Depth > 22 || Out.Length > 500)
		return;
	for (i = 0; i < Depth; i++)
		Pad $= "  ";
	Blend = AnimNodeBlendBase(Node);
	Out.AddItem("  " $ Pad $ Node.Class.Name @ Node.NodeName @ "total" @ Node.NodeTotalWeight $ (AnimNodeSequence(Node) != none ? " anim " $ AnimNodeSequence(Node).AnimSeqName $ (AnimNodeSequence(Node).AnimSeq != none ? "" : " MISSING") : ""));
	if (Blend == none)
		return;
	for (i = 0; i < Blend.Children.Length; i++)
	{
		if (Blend.Children[i].Weight <= 0.001 && Depth > 0)
			continue;
		Out.AddItem("  " $ Pad $ "- child" @ i @ Blend.Children[i].Name @ "weight" @ Blend.Children[i].Weight);
		TreeLines(Out, Blend.Children[i].Anim, Depth + 1);
	}
}

/** Each soldier's body parts: name, and the armour the part belongs to (MISSING: no such part). */
function Parts(out array<string> Out)
{
	local XComGameState_Unit Unit;
	local X2BodyPartTemplateManager Mgr;
	local StateObjectReference Ref;
	local string Line;

	Mgr = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		Line = Unit.GetFullName() @ "wears" @ (Unit.GetItemInSlot(eInvSlot_Armor) != none ? string(Unit.GetItemInSlot(eInvSlot_Armor).GetMyTemplateName()) : "-") $ ":";
		Line @= PartText(Mgr, "Torso", Unit.kAppearance.nmTorso);
		Line @= PartText(Mgr, "Arms", Unit.kAppearance.nmArms);
		Line @= PartText(Mgr, "LeftArm", Unit.kAppearance.nmLeftArm);
		Line @= PartText(Mgr, "RightArm", Unit.kAppearance.nmRightArm);
		Line @= PartText(Mgr, "LeftForearm", Unit.kAppearance.nmLeftForearm);
		Line @= PartText(Mgr, "RightForearm", Unit.kAppearance.nmRightForearm);
		Line @= PartText(Mgr, "Legs", Unit.kAppearance.nmLegs);
		Line @= PartText(Mgr, "Thighs", Unit.kAppearance.nmThighs);
		Line @= PartText(Mgr, "Shins", Unit.kAppearance.nmShins);
		Line @= PartText(Mgr, "Helmets", Unit.kAppearance.nmHelmet);
		Out.AddItem(Line);
	}
}

function string PartText(X2BodyPartTemplateManager Mgr, string PartType, name PartName)
{
	local X2BodyPartTemplate Part;

	if (PartName == '')
		return PartType $ "=-";
	Part = Mgr.FindUberTemplate(PartType, PartName);
	return PartType $ "=" $ PartName $ "(" $ (Part != none ? string(Part.ArmorTemplate) $ "," @ Part.ArchetypeName $ "," @ Part.DLCName $ "," @ Part.Tech : "MISSING") $ ")";
}

/** Each target condition of an ability, tried against each enemy. */
function string WhyNoTargets(XComGameState_Unit Source, XComGameState_Ability Ability)
{
	local XComGameState_Unit Enemy;
	local X2Condition Condition;
	local string Out;
	local name Code;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Enemy)
	{
		if (Enemy.GetTeam() == eTeam_XCom || Enemy.bRemovedFromPlay)
			continue;
		Out @= string(Enemy.GetMyTemplateName()) $ ":";
		foreach Ability.GetMyTemplate().AbilityTargetConditions(Condition)
		{
			Code = Condition.MeetsCondition(Enemy);
			if (Code == 'AA_Success')
				Code = Condition.MeetsConditionWithSource(Enemy, Source);
			Out @= string(Condition.Class.Name) $ "=" $ Code;
		}
	}
	return Out;
}

/** In a mission: the arc thrower's capture applied to the nearest enemy (a test aid: what a successful stun does). */
function string CaptureNearest()
{
	local XComGameState NewGameState;
	local XComGameState_Unit Target, Soldier;
	local EffectAppliedData Data;
	local X2Effect_LWCapture Effect;
	local name Result;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Soldier)
		if (Soldier.GetTeam() == eTeam_XCom && Soldier.IsSoldier() && !Soldier.bRemovedFromPlay)
			break;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Target)
		if (Target.GetTeam() != eTeam_XCom && !Target.bRemovedFromPlay && Target.IsAlive())
			break;
	if (Soldier == none || Target == none)
		return "ERR no soldier or enemy";
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a capture (control port)");
	Target = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Target.ObjectID));
	Data.SourceStateObjectRef = Soldier.GetReference();
	Data.TargetStateObjectRef = Target.GetReference();
	Effect = new class'X2Effect_LWCapture';
	Result = Effect.ApplyEffect(Data, Target, NewGameState);
	`TACTICALRULES.SubmitGameState(NewGameState);
	return "capture" @ Result @ Target.GetMyTemplateName();
}

/** In a mission: an alien dropped on the aliens' team a few tiles from the first soldier (a test aid, XCOM 2's cheat). */
/** The tactical camera to a place on the placed EW map for 20 seconds, fog of war off (a test aid: its lights, its pods). */
function string Look(array<string> Args)
{
	local X2Camera_LookAtLocationTimed Camera;
	local XComGameState_Unit Unit;
	local vector At;
	local int n;
	local string Name;

	if (Args[1] == "unit")
	{
		// A unit on the field by its place among the living ones with a body (any side): where its body is. 'look unit'
		// with no number lists them.
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			if (!Unit.IsAlive() || Unit.bRemovedFromPlay || XGUnit(Unit.GetVisualizer()) == none)
				continue;
			if (Args.Length < 3)
			{
				Name @= n $ "=" $ Unit.GetMyTemplateName() $ (Unit.IsSoldier() ? "(" $ Unit.GetLastName() $ ")" : "");
				n++;
				continue;
			}
			if (n++ != int(Args[2]))
				continue;
			Name = string(Unit.GetMyTemplateName());
			if (XGUnit(Unit.GetVisualizer()) == none)
				return "ERR no body";
			At = XGUnit(Unit.GetVisualizer()).Location - class'LWX2PartPlacer'.default.EWShift;
			break;
		}
		if (Args.Length < 3)
			return "units:" $ Name;
		if (At == vect(0, 0, 0))
			return "ERR no such unit";
	}
	else if (Args[1] == "pod")
	{
		if (int(Args[2]) >= class'LWX2EWMapPieces'.static.Map().Pods.Length)
			return "ERR no such pod";
		At = class'LWX2EWMapPieces'.static.Map().Pods[int(Args[2])].Loc;
	}
	else
	{
		At.X = float(Args[1]);
		At.Y = float(Args[2]);
		At.Z = Args.Length > 3 ? float(Args[3]) : 0.0;
	}
	At += class'LWX2PartPlacer'.default.EWShift;
	Camera = new class'X2Camera_LookAtLocationTimed';
	Camera.LookAtLocation = At;
	Camera.LookAtDuration = 20;
	Camera.Priority = eCameraPriority_Cinematic;
	`CAMERASTACK.AddCamera(Camera);
	// Fog of war off, so the place is seen (never seen ground is drawn black).
	GetALocalPlayerController().ConsoleCommand("SetFOW false");
	return "ok looking at" @ At @ Name;
}

function string WindowSight(string Part)
{
	local XComLevelActor A;
	local XComWorldData World;
	local GameRulesCache_VisibilityInfo Info;
	local TTile T, From, To;
	local vector At;
	local string List;
	local int Pieces, Through, Blocking, Axis;
	local bool bSeen;

	World = `XWORLD;
	foreach WorldInfo.AllActors(class'XComLevelActor', A)
	{
		if (A.StaticMeshComponent == none || InStr(PathName(A.StaticMeshComponent.StaticMesh), Part) < 0)
			continue;
		Pieces++;
		if (A.VisibilityBlockingData.bBlockUnitVisibility)
			Blocking++;
		At = A.Location + vect(0, 0, 64);
		T = World.GetTileCoordinatesFromPosition(At);
		// Seen across both ways: one of them crosses the piece (the other may only pass beside it).
		bSeen = true;
		for (Axis = 0; Axis < 2 && bSeen; Axis++)
		{
			From = T;
			To = T;
			if (Axis == 0) { From.X -= 2; To.X += 2; } else { From.Y -= 2; To.Y += 2; }
			if (!World.CanSeeTileToTile(From, To, Info))
				bSeen = false;
		}
		if (bSeen)
			Through++;
		if (Part == "Window" && Pieces <= 30)
			List @= T.X $ "," $ T.Y $ "," $ T.Z $ (bSeen ? "+" : "-");
	}
	if (List != "")
		`log("LongWarX2: control: window tiles" $ List, , 'LongWarX2');
	return Part $ ":" @ Pieces @ "pieces," @ Blocking @ "blocking sight by their flag," @ Through @ "seen across both ways" $ List;
}

function string SeeThrough()
{
	local XComLevelActor A;
	local int All, Through, Windows;

	foreach WorldInfo.AllActors(class'XComLevelActor', A)
	{
		All++;
		if (!A.VisibilityBlockingData.bBlockUnitVisibility)
			Through++;
		if (A.VisibilityBlockingData.bIsWindow)
			Windows++;
	}
	return All @ "level actors," @ Through @ "seen through," @ Windows @ "windows";
}

function string SpawnAlien(name CharacterTemplate, int Tiles, optional int Species, optional int LeaderLevel)
{
	local XComTacticalCheatManager Cheats;
	local XComGameState_Unit Unit, Newest;
	local XComGameState NewGameState;
	local vector Position;

	Cheats = XComTacticalCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_XCom && Unit.IsSoldier() && !Unit.bRemovedFromPlay)
			break;
	if (Cheats == none || Unit == none)
		return "ERR not in a mission (or no cheats)";
	Position = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);
	Position.X += Tiles * class'XComWorldData'.const.WORLD_StepSize;
	Position.Z = `XWORLD.GetFloorZForPosition(Position);
	Cheats.DropUnitAt(Position, CharacterTemplate, 1);
	if (Species > 0)
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
			if (Unit.GetMyTemplateName() == CharacterTemplate && (Newest == none || Unit.ObjectID > Newest.ObjectID))
				Newest = Unit;
		if (Newest != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a test alien's species");
			Newest = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Newest.ObjectID));
			Newest.SetUnitFloatValue('LWX2Species', Species, eCleanup_Never);
			class'LWAlienStats'.static.ApplyTo(Newest, Species, LeaderLevel, NewGameState);
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}
	return "dropped" @ CharacterTemplate @ Tiles @ "tiles from" @ Unit.GetFullName() @ (Species > 0 ? "as species" @ Species @ "leader level" @ LeaderLevel : "");
}

/** The abilities a unit has for Long War's alien perks (X2Ability_LWStandins.AlienAbilities), and the scale; "-" for none. */
static function string AlienPerksOf(XComGameState_Unit Unit)
{
	local StateObjectReference Ref;
	local XComGameState_Ability Ability;
	local UnitValue Scale;
	local string S;

	foreach Unit.Abilities(Ref)
	{
		Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Ability != none && class'X2Ability_LWStandins'.default.AlienAbilities.Find('Ability', Ability.GetMyTemplateName()) != INDEX_NONE)
			S $= (S != "" ? "," : "") $ Ability.GetMyTemplateName();
	}
	if (Unit.GetUnitValue('LWX2Scale', Scale))
		S $= " scale" @ int(Scale.fValue) $ "%";
	return S != "" ? S : "-";
}

/** The placed pieces of meshes whose path holds Part, as XCOM 2's building visibility sees them (the first 12). */
function Meshes(string Part, out array<string> Out)
{
	local Actor A;
	local StaticMeshComponent C;
	local XComBuildingVolume B;
	local float Cutdown, Cutout, Mask, PrevMask;
	local int f, k, n;
	local string Where;
	local MaterialInterface M;

	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'Actor', A)
		foreach A.ComponentList(class'StaticMeshComponent', C)
		{
			if (C.StaticMesh == none || InStr(PathName(C.StaticMesh), Part) < 0 || n++ >= 12)
				continue;
			Where = "";
			foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XComBuildingVolume', B)
				for (f = 0; f < B.Floors.Length; f++)
					for (k = 0; k < B.Floors[f].m_aCachedActors.Length; k++)
						if (B.Floors[f].m_aCachedActors[k].ResidentActor == A)
							Where @= B.Name $ "/floor" $ f;
			Cutdown = 0;
			Cutout = 0;
			if (XComLevelActor(A) != none)
				XComLevelActor(A).GetPrimitiveVisHeight(Cutdown, Cutout, Mask, PrevMask);
			else if (XComFracLevelActor(A) != none)
				XComFracLevelActor(A).GetPrimitiveVisHeight(Cutdown, Cutout, Mask, PrevMask);
			Out.AddItem(A.Class.Name @ A.Name @ "z" @ int(C.Bounds.Origin.Z - C.Bounds.BoxExtent.Z) $ ".." $ int(C.Bounds.Origin.Z + C.Bounds.BoxExtent.Z) @ "hidden" @ A.bHidden @ "comp hidden" @ C.HiddenGame @ "cutdown" @ Cutdown @ "cutout" @ Cutout @ "floors:" $ (Where != "" ? Where : " none"));
			// Its materials as drawn: each element's, and the parent of an instance.
			Where = "";
			for (f = 0; f < C.GetNumElements(); f++)
			{
				M = C.GetMaterial(f);
				Where @= f $ ":" $ (M == none ? "none" : string(M.Name));
				if (MaterialInstance(M) != none && MaterialInstance(M).Parent != none)
					Where $= "(" $ PathName(MaterialInstance(M).Parent) $ ")";
			}
			Out.AddItem("    materials" $ Where);
		}
	Out.AddItem(n @ "pieces of" @ Part);
}

/** The pieces whose mesh's path holds Part: how many have tiles over them (a floor higher than the piece's base) units
 *  can enter, and how many such tiles a soldier can walk to (features/lw-missions.md, cars and sandbags). */
function string Standable(string Part)
{
	local Actor A;
	local StaticMeshComponent C;
	local XComWorldData World;
	local TTile Lo, Hi, T;
	local vector Floor, Corner;
	local int Pieces, Over, Stand, Reached, Climbable, Destinations, OnTop;
	local array<XComGameState_Unit> Units;
	local array<TTile> Path;

	World = `XWORLD;
	Units = FieldXCom();
	if (World == none || Units.Length == 0)
		return "ERR not in a mission";
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'Actor', A)
		foreach A.ComponentList(class'StaticMeshComponent', C)
		{
			if (C.StaticMesh == none || InStr(PathName(C.StaticMesh), Part) < 0)
				continue;
			Pieces++;
			if (XComLevelActor(A) != none && XComLevelActor(A).bCanClimbOnto)
				Climbable++;
			Corner = C.Bounds.Origin - C.Bounds.BoxExtent;
			Lo = World.GetTileCoordinatesFromPosition(Corner);
			Corner = C.Bounds.Origin + C.Bounds.BoxExtent;
			Hi = World.GetTileCoordinatesFromPosition(Corner);
			Stand = 0;
			for (T.X = Lo.X; T.X <= Hi.X; T.X++)
				for (T.Y = Lo.Y; T.Y <= Hi.Y; T.Y++)
					for (T.Z = Lo.Z; T.Z <= Hi.Z + 1; T.Z++)
						if (World.CanUnitsEnterTile(T) && World.GetFloorPositionForTile(T, Floor) && Floor.Z > C.Bounds.Origin.Z - C.Bounds.BoxExtent.Z + 24)
						{
							Stand++;
							if (World.IsFloorTileAndValidDestination(T))
								Destinations++;
							if (class'X2PathSolver'.static.BuildPath(Units[0], Units[0].TileLocation, T, Path, false))
							{
								Reached++;
								// On the piece itself: its floor at the piece's top, not the ground beside it (slopes).
								if (Abs(Floor.Z - (C.Bounds.Origin.Z + C.Bounds.BoxExtent.Z)) < 16)
									OnTop++;
							}
						}
			if (Stand > 0)
				Over++;
		}
	return Pieces @ "pieces of" @ Part @ "(" $ Climbable @ "climbable onto);" @ Over @ "with tiles over them units can enter;" @ Destinations @ "such tiles valid destinations," @ Reached @ "a soldier can walk to," @ OnTop @ "of those at the piece's top";
}

/** The last N abilities used (their contexts in the history), oldest first. */
function History(out array<string> Out, int N)
{
	local XComGameStateHistory H;
	local XComGameStateContext_Ability C;
	local array<string> Lines;
	local XComGameState_Unit Source, Target;
	local int i;

	H = `XCOMHISTORY;
	for (i = H.GetCurrentHistoryIndex(); i > 0 && Lines.Length < N; i--)
	{
		C = XComGameStateContext_Ability(H.GetGameStateFromHistory(i).GetContext());
		if (C == none || C.InterruptionStatus == eInterruptionStatus_Interrupt)
			continue;
		Source = XComGameState_Unit(H.GetGameStateForObjectID(C.InputContext.SourceObject.ObjectID));
		Target = XComGameState_Unit(H.GetGameStateForObjectID(C.InputContext.PrimaryTarget.ObjectID));
		Lines.InsertItem(0, i @ (Source != none ? string(Source.GetMyTemplateName()) $ "#" $ Source.ObjectID : "?") @ C.InputContext.AbilityTemplateName
			@ (Target != none ? "on" @ Target.GetMyTemplateName() $ "#" $ Target.ObjectID : "") @ (C.IsResultContextHit() ? "hit" : "miss"));
	}
	for (i = 0; i < Lines.Length; i++)
		Out.AddItem(Lines[i]);
}

/** XCOM's soldiers: how many, by rank. */
function string Crew()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local array<int> Ranks;
	local int i, n, Shaken;
	local string S, Tired;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ == none)
		return "ERR no headquarters";
	for (i = 0; i < XComHQ.Crew.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		n++;
		if (Ranks.Length <= Unit.GetRank())
			Ranks.Length = Unit.GetRank() + 1;
		Ranks[Unit.GetRank()]++;
		if (Unit.GetMentalState() == eMentalState_Tired)
			Tired $= " " $ Unit.GetLastName() $ "(" $ int(Unit.GetCurrentStat(eStat_Will)) $ "/" $ int(Unit.GetMaxStat(eStat_Will)) $ ")";
		else if (Unit.GetMentalState() == eMentalState_Shaken)
			Shaken++;
	}
	for (i = 0; i < Ranks.Length; i++)
		S @= "rank" @ i $ ":" @ Ranks[i];
	return n @ "soldiers;" $ S $ "; tired:" $ (Tired != "" ? Tired : " none") $ "; shaken:" @ Shaken;
}

/** A function of EW's strategy HUD, which is loaded beside the screen stack, not on it. */
function string HUDCall(array<string> Args)
{
	local UILWEWStrategyHUD HUD;
	local int i;

	foreach AllActors(class'UILWEWStrategyHUD', HUD)
		break;
	if (HUD == none || Args.Length < 2)
		return "ERR no EW strategy HUD up, or no function given";
	HUD.MC.BeginFunctionOp(Args[1]);
	for (i = 2; i < Args.Length; i++)
	{
		if (string(int(Args[i])) == Args[i])
			HUD.MC.QueueNumber(int(Args[i]));
		else
			HUD.MC.QueueString(Repl(Args[i], "_", " "));
	}
	HUD.MC.EndOp();
	return "ok" @ HUD.MCPath $ "." $ Args[1] @ "with" @ (Args.Length - 2) @ "arguments";
}

/** A pod of two Sectoids (species 4) spawned the missions' way, Tiles east of the first soldier. */
function string TestPod(int Tiles)
{
	local array<XComGameState_Unit> Units;
	local vector Position;
	local array<name> Templates;
	local array<int> Species;

	Units = FieldXCom();
	if (Units.Length == 0)
		return "ERR not in a mission";
	Position = `XWORLD.GetPositionFromTileCoordinates(Units[0].TileLocation);
	Position.X += Tiles * class'XComWorldData'.const.WORLD_StepSize;
	Templates.AddItem('Sectoid');
	Templates.AddItem('Sectoid');
	Species.AddItem(4);
	Species.AddItem(4);
	class'LWMissionSquads'.static.SpawnPod('LWX2_TestPod', Position, Templates, Species);
	return "pod of 2 Sectoids spawned near" @ Position;
}

/** An enemy's pawn's animation nodes with weight: what XCOM 2 asked its body to play, and whether its AnimSets have it. */
function Anims(out array<string> Out, int Index, optional bool bAll, optional int Relink, optional name Play)
{
	local XComGameState_Unit Unit, Pick, Soldier;
	local XComUnitPawn Pawn;
	local AnimNodeSequence Seq;
	local SkelControlBase Control;
	local AnimNodeBlendPerBone PerBone;
	local AnimTree Simple;
	local AnimNodeAdditiveBlending Additive;
	local AnimNodeAimOffset Aim;
	local XComAnimNodeBlendMasks Masks;
	local AnimNodeSequence One;
	local array<name> Bones;
	local name Bone;
	local vector At;
	local int Best;
	local StateObjectReference Ref;
	local CustomAnimParams Params;
	local AnimSet Set;
	local int n, i, b;
	local string Sets;

	Best = 9999;
	Bones.AddItem('RigLArmUpperarm');
	Bones.AddItem('RigLArmHand');
	Bones.AddItem('RigRArmUpperarm');
	Bones.AddItem('RigRArmHand');
	Bones.AddItem('RigHead');
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() == eTeam_XCom || !Unit.IsAlive() || Unit.bRemovedFromPlay || XGUnit(Unit.GetVisualizer()) == none)
			continue;
		if (n++ == Index)
			Pick = Unit;
		// No index: the one nearest the squad (one in sight, whose animations are ticking).
		if (Index < 0)
			foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Soldier)
				if (Soldier.GetTeam() == eTeam_XCom && Soldier.IsSoldier() && !Soldier.bRemovedFromPlay && Soldier.TileDistanceBetween(Unit) < Best)
				{
					Best = Soldier.TileDistanceBetween(Unit);
					Pick = Unit;
				}
	}
	if (Pick == none)
	{
		Out.AddItem("ERR no such enemy");
		return;
	}
	Pawn = XGUnit(Pick.GetVisualizer()).GetPawn();
	if (Pawn == none || Pawn.Mesh == none)
	{
		Out.AddItem("ERR no pawn");
		return;
	}
	if (Relink == 1)
		Pawn.UpdateAnimations();
	if (Relink == 2)
		Pawn.Mesh.UpdateAnimations();
	// The tree made again on the mesh as it is now (its nodes linked to EW's skeleton, not XCOM 2's).
	if (Relink == 3)
		Pawn.Mesh.SetAnimTreeTemplate(Pawn.Mesh.AnimTreeTemplate);
	// The skeleton composed from the tree now (whether an update is what is missing).
	if (Relink == 4)
		Pawn.Mesh.ForceSkelUpdate();
	// Only the sets whose tracks are the mesh's (XCOM 2's own set, for its own skeleton, taken off), relinked.
	if (Relink == 6)
	{
		for (i = Pawn.Mesh.AnimSets.Length - 1; i >= 0; i--)
			if (Pawn.Mesh.AnimSets[i] == none || Pawn.Mesh.AnimSets[i].TrackBoneNames.Length == 0 || Pawn.Mesh.MatchRefBone(Pawn.Mesh.AnimSets[i].TrackBoneNames[0]) == INDEX_NONE)
				Pawn.Mesh.AnimSets.Remove(i, 1);
		Pawn.Mesh.UpdateAnimations();
	}
	// A minimal tree (one looping node, the idle), as the display actor that played EW's animations had.
	if (Relink == 7)
	{
		Simple = new class'AnimTree';
		One = new class'AnimNodeSequence';
		Simple.Children.Length = 1;
		Simple.Children[0].Anim = One;
		Simple.Children[0].Weight = 1.0;
		Pawn.Mesh.SetAnimTreeTemplate(Simple);
		foreach Pawn.Mesh.AllAnimNodes(class'AnimNodeSequence', Seq)
		{
			Seq.SetAnim('NO_IdleGunUpA');
			Seq.PlayAnim(true);
		}
		Out.AddItem("  minimal tree:" @ Pawn.Mesh.Animations);
	}
	// The additive layers off (XCOM 2's reproportioning and joint offsets, whose animations EW's bodies lack).
	if (Relink == 9)
	{
		foreach Pawn.Mesh.AllAnimNodes(class'AnimNodeAdditiveBlending', Additive)
		{
			Additive.SetBlendTarget(0, 0);
			Out.AddItem("  additive off:" @ Additive.NodeName);
		}
	}
	// The aim offsets off.
	if (Relink == 10)
	{
		foreach Pawn.Mesh.AllAnimNodes(class'AnimNodeAimOffset', Aim)
		{
			Aim.Aim.X = 0;
			Aim.Aim.Y = 0;
			Aim.bBakeFromAnimations = false;
			Aim.SetActiveProfileByIndex(-1);
			Out.AddItem("  aim offset off:" @ Aim.NodeName @ Aim.CurrentProfileIndex);
		}
	}
	// XCOM 2's channel masks (BlendChannels): each mask's start bone, weights, how many bones it covers, its child.
	if (Relink == 11)
	{
		foreach Pawn.Mesh.AllAnimNodes(class'XComAnimNodeBlendMasks', Masks)
		{
			Out.AddItem("  masks" @ Masks.NodeName @ Masks.BlendMasks.Length @ "children" @ Masks.Children.Length);
			for (i = 0; i < Masks.BlendMasks.Length; i++)
			{
				b = 0;
				for (n = 0; n < Masks.BlendMasks[i].PerBoneMask.Length; n++)
					if (Masks.BlendMasks[i].PerBoneMask[n] != 0)
						b++;
				Sets = "";
				for (n = 0; n < Masks.BlendMasks[i].PerBoneMask.Length && n < 12; n++)
					Sets @= string(Masks.BlendMasks[i].PerBoneMask[n]);
				Sets $= " | model space" @ Masks.BlendMasks[i].ModelSpaceBones.Length $ ":";
				for (n = 0; n < Masks.BlendMasks[i].ModelSpaceBones.Length && n < 12; n++)
					Sets @= string(Masks.BlendMasks[i].ModelSpaceBones[n]);
				Out.AddItem("      values" $ Sets);
				Out.AddItem("    mask" @ i @ Masks.BlendMasks[i].BranchStartBoneName @ (Pawn.Mesh.MatchRefBone(Masks.BlendMasks[i].BranchStartBoneName) != INDEX_NONE ? "on the mesh" : "NOT on the mesh") @ "weight" @ Masks.BlendMasks[i].CurrentWeight @ "desired" @ Masks.BlendMasks[i].DesiredWeight @ "bones" @ b $ "/" $ Masks.BlendMasks[i].PerBoneMask.Length @ "child" @ (i + 1 < Masks.Children.Length ? Masks.Children[i + 1].Name : 'None'));
			}
		}
	}
	// The tree from its root: each blend node's children, their weights, to a depth (where the body's pose goes).
	if (Relink == 8)
		TreeLines(Out, Pawn.Mesh.Animations, 0);
	// Every node with no animation that still counts given the idle (whether one of them holds the body in its pose).
	if (Relink == 5)
	{
		foreach Pawn.Mesh.AllAnimNodes(class'AnimNodeSequence', Seq)
		{
			if (Seq.AnimSeq != none || Seq.NodeTotalWeight <= 0 || XComAnimNodeSequenceAdditive(Seq) != none)
				continue;
			Out.AddItem("  given the idle:" @ Seq.NodeName @ Seq.AnimSeqName);
			Seq.SetAnim('NO_IdleGunUpA');
			Seq.PlayAnim(true);
		}
	}
	foreach Pawn.Mesh.AnimSets(Set)
		Sets @= (Set != none ? string(Set.Name) $ "(" $ Set.Sequences.Length $ ")" : "none");
	Out.AddItem(Pick.GetMyTemplateName() @ "mesh" @ PathName(Pawn.Mesh.SkeletalMesh) @ "tree" @ PathName(Pawn.Mesh.AnimTreeTemplate) @ "sets" $ Sets);
	Sets = "";
	foreach Pick.Abilities(Ref)
		if (XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID)) != none)
			Sets @= XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID)).GetMyTemplateName();
	Out.AddItem("  abilities:" $ Sets @ "| behaviour tree" @ Pick.GetMyTemplate().strBehaviorTree);
	Sets = "";
	foreach Pick.GetMyTemplate().AdditionalAnimSets(Set)
		Sets @= (Set != none ? PathName(Set) $ "(" $ Set.Sequences.Length $ ")" : "none");
	Out.AddItem("  the template's AdditionalAnimSets:" $ Sets @ "| difficulty variant" @ Pick.GetMyTemplate().Name @ Pick.GetMyTemplate());
	foreach Pawn.Mesh.AnimSets(Set)
		if (Set != none)
		{
			for (i = 0; i < Set.Sequences.Length && Set.Sequences[i].SequenceName != 'NO_IdleGunDwnA'; i++);
			for (b = 0; b < Set.TrackBoneNames.Length && Pawn.Mesh.MatchRefBone(Set.TrackBoneNames[b]) != INDEX_NONE; b++);
			Out.AddItem("  set" @ PathName(Set) @ "NO_IdleGunDwnA" @ (i < Set.Sequences.Length ? "in it" : "not in it") @ "| bones:" @ Set.TrackBoneNames.Length @ "tracks, the first" @ b @ "on the mesh" @ (b < Set.TrackBoneNames.Length ? "(not:" @ Set.TrackBoneNames[b] $ ")" : "") @ "| preview mesh" @ Set.PreviewSkelMeshName);
		}
	Out.AddItem("  the mesh finds NO_IdleGunDwnA:" @ (Pawn.Mesh.FindAnimSequence('NO_IdleGunDwnA') != none ? PathName(Pawn.Mesh.FindAnimSequence('NO_IdleGunDwnA')) : "none"));
	// play <name>: the animation played on the whole body, looping, as XCOM 2's unit code plays one (its anim tree controller).
	if (Play != '')
	{
		Params.AnimName = Play;
		Params.Looping = true;
		Out.AddItem("  playing" @ Play @ (Pawn.GetAnimTreeController().CanPlayAnimation(Play) ? "found" : "MISSING"));
		Pawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	}
	// Where the arm joints are now, in the unit's own frame (from its mesh's origin, unturned by its rotation).
	Sets = "";
	foreach Bones(Bone)
	{
		if (Pawn.Mesh.MatchRefBone(Bone) == INDEX_NONE)
			continue;
		At = (Pawn.Mesh.GetBoneLocation(Bone) - Pawn.Mesh.GetPosition()) << Pawn.Mesh.GetRotation();
		Sets @= Bone $ "=" $ int(At.X) $ "," $ int(At.Y) $ "," $ int(At.Z);
	}
	// A mesh without those bones (XCOM 2's own): a few by index.
	if (Sets == "")
	{
		for (b = 10; b < 70; b += 20)
		{
			Bone = Pawn.Mesh.GetBoneName(b);
			if (Bone == '')
				continue;
			At = (Pawn.Mesh.GetBoneLocation(Bone) - Pawn.Mesh.GetPosition()) << Pawn.Mesh.GetRotation();
			Sets @= Bone $ "=" $ int(At.X) $ "," $ int(At.Y) $ "," $ int(At.Z);
		}
	}
	Out.AddItem("  joints:" $ Sets);
	Out.AddItem("  lod: predicted" @ Pawn.Mesh.PredictedLODLevel @ "forced" @ Pawn.Mesh.ForcedLodModel @ "of" @ Pawn.Mesh.SkeletalMesh.LODInfo.Length @ "| recently rendered" @ Pawn.Mesh.bRecentlyRendered);
	Out.AddItem("  mesh: force ref pose" @ Pawn.Mesh.bForceRefpose @ "| no skeleton update" @ Pawn.Mesh.bNoSkeletonUpdate @ "| anims paused" @ Pawn.Mesh.bPauseAnims @ "| update when not rendered" @ Pawn.Mesh.bUpdateSkelWhenNotRendered @ "| tree" @ Pawn.Mesh.Animations @ "| parent anim comp" @ Pawn.Mesh.ParentAnimComponent @ "| hidden" @ Pawn.Mesh.HiddenGame @ "| pawn class" @ Pawn.Class.Name);
	// The per-bone blends whose start bones the mesh has (the rest do nothing on it): their bones, children and weights.
	foreach Pawn.Mesh.AllAnimNodes(class'AnimNodeBlendPerBone', PerBone)
	{
		Sets = "";
		for (b = 0; b < PerBone.BranchStartBoneName.Length; b++)
			if (Pawn.Mesh.MatchRefBone(PerBone.BranchStartBoneName[b]) != INDEX_NONE)
				Sets @= PerBone.BranchStartBoneName[b];
		if (Sets == "")
			continue;
		Out.AddItem("  per-bone" @ PerBone.NodeName @ "from" $ Sets @ "weight" @ PerBone.NodeTotalWeight @ "child 1 weight" @ (PerBone.Children.Length > 1 ? PerBone.Children[1].Weight : 0.0) @ "child 1" @ ((PerBone.Children.Length > 1 && PerBone.Children[1].Anim != none) ? string(PerBone.Children[1].Anim.NodeName) $ "(" $ PerBone.Children[1].Anim.Class.Name $ ")" : "none"));
	}
	// The skeletal controls acting on the bones after the animation (IK, look-at, aim), with their strength.
	if (AnimTree(Pawn.Mesh.Animations) != none)
	{
		for (i = 0; i < AnimTree(Pawn.Mesh.Animations).SkelControlLists.Length; i++)
		{
			for (Control = AnimTree(Pawn.Mesh.Animations).SkelControlLists[i].ControlHead; Control != none; Control = Control.NextControl)
				if (Control.ControlStrength > 0)
					Out.AddItem("  control" @ Control.Class.Name @ Control.ControlName @ "on" @ AnimTree(Pawn.Mesh.Animations).SkelControlLists[i].BoneName @ "strength" @ Control.ControlStrength);
		}
	}
	foreach Pawn.Mesh.AllAnimNodes(class'AnimNodeSequence', Seq)
		if (Seq.NodeTotalWeight > 0.01 || (bAll && Seq.AnimSeqName != ''))
			Out.AddItem("  " $ Seq.Class.Name @ Seq.AnimSeqName @ (Seq.AnimSeq != none ? "found (" $ PathName(Seq.AnimSeq) $ ")" : "MISSING") @ "weight" @ Seq.NodeTotalWeight @ (Seq.bPlaying ? "playing" : "stopped") @ "at" @ Seq.CurrentTime);
}

/** In a mission: each enemy, its HP and how far (tiles) from the nearest soldier. */
function RegisterDoors(out array<string> Out)
{
	local XComInteractiveLevelActor Door;
	local int n;

	foreach WorldInfo.AllActors(class'XComInteractiveLevelActor', Door)
	{
		`XWORLD.AddActorTileData(Door);
		n++;
	}
	Out.AddItem(n @ "interactive actors added to the tile data again");
}

function Doors(out array<string> Out)
{
	local XComInteractiveLevelActor Door;
	local XComWorldData World;
	local TTile T;
	local vector At;
	local rotator Facing;
	local int n, i;

	World = `XWORLD;
	foreach WorldInfo.AllActors(class'XComInteractiveLevelActor', Door)
	{
		T = World.GetTileCoordinatesFromPosition(Door.Location);
		Out.AddItem(n++ @ Door.Name @ "at" @ Door.Location @ "tile" @ T.X @ T.Y @ T.Z @ "door" @ Door.IsDoor() @ "open" @ Door.IsOpenDoor()
			@ "mesh" @ (Door.SkeletalMeshComponent != none ? PathName(Door.SkeletalMeshComponent.SkeletalMesh) : "no component")
			@ "tree" @ (Door.SkeletalMeshComponent != none ? PathName(Door.SkeletalMeshComponent.AnimTreeTemplate) : "-")
			@ "hidden" @ Door.bHidden @ (Door.SkeletalMeshComponent != none ? string(Door.SkeletalMeshComponent.HiddenGame) : "-")
			@ "points" @ Door.InteractionPoints.Length @ "anim node" @ (Door.AnimNode != none) @ "interact points" @ Door.InteractPoints.Length);
		// Each socket's place as the game computed it, and the tile there (the world data's door crossings come from these).
		for (i = 0; i < Door.InteractionPoints.Length; i++)
			if (Door.GetSocketTransform(GetEnum(enum'EInteractionSocket', Door.InteractionPoints[i].SrcSocket), At, Facing))
			{
				T = World.GetTileCoordinatesFromPosition(At);
				Out.AddItem("    socket" @ Door.InteractionPoints[i].SrcSocket @ "at" @ At @ "tile" @ T.X @ T.Y @ T.Z);
			}
			else
				Out.AddItem("    socket" @ Door.InteractionPoints[i].SrcSocket @ "not on the mesh");
	}
	if (n == 0)
		Out.AddItem("no interactive level actors");
}

/** The unit's primary weapon's drawn mesh (its XComWeapon's), for the EW bodies' checks. */
function string WeaponMeshOf(XComGameState_Unit Unit)
{
	local XComGameState_Item Item;
	local XComWeapon Entity;

	Item = Unit.GetPrimaryWeapon();
	if (Item == none || XGWeapon(Item.GetVisualizer()) == none)
		return "no visualizer";
	Entity = XComWeapon(XGWeapon(Item.GetVisualizer()).m_kEntity);
	if (Entity == none || Entity.Mesh == none)
		return "no entity";
	if (SkeletalMeshComponent(Entity.Mesh) != none)
		return PathName(SkeletalMeshComponent(Entity.Mesh).SkeletalMesh);
	if (StaticMeshComponent(Entity.Mesh) != none)
		return "static" @ PathName(StaticMeshComponent(Entity.Mesh).StaticMesh);
	return string(Entity.Mesh.Class.Name);
}

function string EWBody(name Template, string MeshPath, string SetPath, string DiffusePath, string NormalPath)
{
	local XComGameState_Unit Unit;
	local XComUnitPawn Pawn;
	local SkeletalMesh Mesh;
	local AnimSet Set;
	local Material Parent;
	local MaterialInstanceConstant MIC;
	local Texture T;
	local int n, i;

	Mesh = SkeletalMesh(DynamicLoadObject(MeshPath, class'SkeletalMesh', true));
	Set = AnimSet(DynamicLoadObject(SetPath, class'AnimSet', true));
	if (Mesh == none || Set == none)
		return "ERR mesh" @ (Mesh != none) @ "AnimSet" @ (Set != none);
	Parent = Material(DynamicLoadObject("Materials.Approved.AlienUnit_TC", class'Material', true));
	if (Parent != none && DiffusePath != "")
	{
		MIC = new(self) class'MaterialInstanceConstant';
		MIC.SetParent(Parent);
		T = Texture(DynamicLoadObject(DiffusePath, class'Texture', true));
		if (T != none)
			MIC.SetTextureParameterValue('Diffuse', T);
		T = Texture(DynamicLoadObject(NormalPath, class'Texture', true));
		if (T != none)
			MIC.SetTextureParameterValue('Normal', T);
	}
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetMyTemplateName() != Template || XGUnit(Unit.GetVisualizer()) == none)
			continue;
		Pawn = XGUnit(Unit.GetVisualizer()).GetPawn();
		if (Pawn == none || Pawn.Mesh == none)
			continue;
		Pawn.Mesh.SetSkeletalMesh(Mesh);
		Pawn.Mesh.AnimSets.Length = 0;
		Pawn.Mesh.AnimSets.AddItem(Set);
		Pawn.Mesh.UpdateAnimations();
		if (MIC != none)
			for (i = 0; i < Mesh.Materials.Length; i++)
				Pawn.Mesh.SetMaterial(i, MIC);
		n++;
	}
	return "ok" @ n @ "of" @ Template @ "given" @ PathName(Mesh) @ "and" @ PathName(Set) @ (MIC != none ? "and a stand-in material" : "");
}

function string Blast(vector At, float Radius, int Damage)
{
	local XComGameState NewGameState;
	local XComGameState_EnvironmentDamage Event;

	if (`TACTICALRULES == none)
		return "ERR not in a mission";
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, class'XComGameStateContext_AreaDamage'.static.CreateXComGameStateContext());
	Event = XComGameState_EnvironmentDamage(NewGameState.CreateNewStateObject(class'XComGameState_EnvironmentDamage'));
	Event.DamageAmount = Damage;
	Event.DamageTypeTemplateName = 'Explosion';
	Event.HitLocation = At;
	Event.DamageRadius = Radius;
	Event.bRadialDamage = true;
	Event.bAffectFragileOnly = false;
	`TACTICALRULES.SubmitGameState(NewGameState);
	return "ok blast of" @ Damage @ "at" @ At @ "radius" @ Radius;
}

/** XCOM's units on the field, in the order move counts them. */
function array<XComGameState_Unit> FieldXCom()
{
	local XComGameState_Unit Unit;
	local array<XComGameState_Unit> Units;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_XCom && Unit.IsAlive() && !Unit.bRemovedFromPlay && Unit.TileLocation.X >= 0 && !Unit.GetMyTemplate().bIsCosmetic)
			Units.AddItem(Unit);
	return Units;
}

function XComUnits(out array<string> Out)
{
	local array<XComGameState_Unit> Units;
	local int i;

	Units = FieldXCom();
	if (Units.Length == 0)
		Out.AddItem("ERR no units of XCOM on the field (not in a mission?)");
	for (i = 0; i < Units.Length; i++)
		Out.AddItem(i @ Units[i].GetFullName() @ "(" $ Units[i].GetMyTemplateName() $ "," @ Units[i].GetSoldierClassTemplateName() $ ") at" @ Units[i].TileLocation.X @ Units[i].TileLocation.Y @ Units[i].TileLocation.Z
			@ "ap" @ Units[i].ActionPoints.Length @ "sight" @ int(Units[i].GetCurrentStat(eStat_SightRadius)) @ "hp" @ int(Units[i].GetCurrentStat(eStat_HP)) $ "/" $ int(Units[i].GetMaxStat(eStat_HP)));
}

/**
 * A unit of XCOM's walked to a tile as the player's click does it: the path found by XCOM 2's path solver (within the
 * unit's reach this turn) and submitted by the tactical controller's move, so the game's rules all apply (what it
 * sees, the pods it reveals, reaction fire).
 */
function string MoveUnit(int Index, int X, int Y, int Z)
{
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit Unit;
	local XComTacticalController Controller;
	local XComWorldData World;
	local array<TTile> Path;
	local TTile Dest;
	local vector At;

	Units = FieldXCom();
	if (Index < 0 || Index >= Units.Length)
		return "ERR no unit" @ Index @ "(units lists them)";
	Unit = Units[Index];
	Controller = XComTacticalController(GetALocalPlayerController());
	if (Controller == none || XGUnit(Unit.GetVisualizer()) == none)
		return "ERR not in a mission";
	if (Unit.ActionPoints.Length == 0)
		return "ERR" @ Unit.GetFullName() @ "has no action points left";
	World = `XWORLD;
	Dest.X = X;
	Dest.Y = Y;
	Dest.Z = Max(Z, 0);
	if (Z < 0)
	{
		// The floor at that column: from the top of the level down.
		Dest.Z = World.NumZ - 1;
		At = World.GetPositionFromTileCoordinates(Dest);
		if (!World.GetFloorTileForPosition(At, Dest, true))
			return "ERR no floor at" @ X @ Y;
	}
	if (!class'X2PathSolver'.static.BuildPath(Unit, Unit.TileLocation, Dest, Path, true) || Path.Length < 2)
		return "ERR no path for" @ Unit.GetFullName() @ "to" @ Dest.X @ Dest.Y @ Dest.Z @ "within its reach";
	if (!Controller.GameStateMoveUnitSingle(XGUnit(Unit.GetVisualizer()), Path))
		return "ERR the move was refused";
	return "ok" @ Unit.GetFullName() @ "moving" @ (Path.Length - 1) @ "tiles to" @ Dest.X @ Dest.Y @ Dest.Z;
}

function Enemies(out array<string> Out, optional bool bAll)
{
	local XComGameState_Unit Unit, Soldier;
	local XComWorldData World;
	local TTile T, N;
	local vector Floor;
	local int Best, dx, dy, Open;
	local FOWTileStatus FogStatus;
	local byte FogFlags;
	local XGUnit Vis;
	local UnitValue DmgBonus;
	local array<StateObjectReference> Viewers;
	local XComGameState_Unit Viewer;
	local int v;

	World = `XWORLD;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if ((Unit.GetTeam() == eTeam_XCom && !bAll) || Unit.bRemovedFromPlay || !Unit.IsAlive() || Unit.TileLocation.X < 0)
			continue;
		Best = 9999;
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Soldier)
			if (Soldier.GetTeam() == eTeam_XCom && Soldier.IsSoldier() && !Soldier.bRemovedFromPlay)
				Best = Min(Best, Soldier.TileDistanceBetween(Unit));
		// Its tile, whether that is floor, and how many of the 8 around it units can enter (0: stuck).
		T = Unit.TileLocation;
		Open = 0;
		for (dx = -1; dx <= 1; dx++)
			for (dy = -1; dy <= 1; dy++)
			{
				N = T;
				N.X += dx;
				N.Y += dy;
				if ((dx != 0 || dy != 0) && World.CanUnitsEnterTile(N))
					Open++;
			}
		Out.AddItem(Unit.GetMyTemplateName() @ "(" $ Unit.GetMyTemplate().CharacterGroupName $ ") team" @ Unit.GetTeam() @ "hp" @ int(Unit.GetCurrentStat(eStat_HP)) $ "/" $ int(Unit.GetMaxStat(eStat_HP)) @ "tiles" @ Best
			@ "at" @ T.X $ "," $ T.Y $ "," $ T.Z @ (World.GetFloorPositionForTile(T, Floor) ? "floor" : "NOT floor") @ "open around" @ Open
			@ "ai data" @ Unit.GetAIUnitDataID() @ "group" @ (Unit.GetGroupMembership() != none ? Unit.GetGroupMembership().ObjectID : 0) @ "ap" @ Unit.ActionPoints.Length
			@ "effects" @ JoinNames(Unit.AffectedByEffectNames));
		// What decides whether it is drawn: its tile's fog, how many of XCOM see it, its visualizer's team flags.
		World.GetTileFOWValue(T, FogStatus, FogFlags);
		Vis = XGUnit(Unit.GetVisualizer());
		Out.AddItem("  seen by" @ class'X2TacticalVisibilityHelpers'.static.GetNumEnemyViewersOfTarget(Unit.ObjectID) @ "tile fog" @ FogStatus @ "flags" @ FogFlags
			@ "visible to teams" @ (Vis != none ? string(Vis.m_eTeamVisibilityFlags) : "no visualizer") @ "pawn hidden" @ ((Vis != none && Vis.GetPawn() != none) ? string(Vis.GetPawn().bHidden) : "-")
			@ "forced" @ Unit.ForceModelVisible()
			@ "mesh" @ ((Vis != none && Vis.GetPawn() != none && Vis.GetPawn().Mesh != none) ? PathName(Vis.GetPawn().Mesh.SkeletalMesh) : "-")
			@ "weapon" @ WeaponMeshOf(Unit)
			@ "aim" @ int(Unit.GetCurrentStat(eStat_Offense)) @ "def" @ int(Unit.GetCurrentStat(eStat_Defense)) @ "mob" @ int(Unit.GetCurrentStat(eStat_Mobility))
			@ "dmg+" $ (Unit.GetUnitValue('LWX2DamageBonus', DmgBonus) ? string(int(DmgBonus.fValue)) : "-")
			@ "lwdmg" @ (Unit.GetUnitValue('LWX2WeaponDamage', DmgBonus) ? string(int(DmgBonus.fValue)) : "-") @ "passive" @ (Unit.FindAbility('LWX2_AlienDamage').ObjectID > 0)
			@ "perks" @ AlienPerksOf(Unit));
		// Where a unit of XCOM's that is not a soldier came from: the change that first held it.
		if (Unit.GetTeam() == eTeam_XCom && Unit.GetMyTemplateName() != 'Soldier')
			Out.AddItem("  a soldier" @ Unit.IsSoldier() @ "in XCOM's squad" @ (XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom')).Squad.Find('ObjectID', Unit.ObjectID) != INDEX_NONE)
				@ "controlled by player" @ Unit.ControllingPlayer.ObjectID @ "name" @ Unit.GetFullName());
		if (Unit.GetTeam() == eTeam_XCom && Unit.GetMyTemplateName() != 'Soldier' && `XCOMHISTORY.GetOriginalGameStateRevision(Unit.ObjectID) != none)
			Out.AddItem("  first in:" @ `XCOMHISTORY.GetOriginalGameStateRevision(Unit.ObjectID).GetParentGameState().GetContext().SummaryString()
				@ "(history" @ `XCOMHISTORY.GetOriginalGameStateRevision(Unit.ObjectID).GetParentGameState().HistoryIndex $ ")");
		// Who sees it: each viewer's kind, sight range (in tiles) and distance.
		Viewers.Length = 0;
		class'X2TacticalVisibilityHelpers'.static.GetEnemyViewersOfTarget(Unit.ObjectID, Viewers);
		for (v = 0; v < Viewers.Length; v++)
		{
			Viewer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Viewers[v].ObjectID));
			if (Viewer != none)
				Out.AddItem("    by" @ Viewer.GetMyTemplateName() @ "team" @ Viewer.GetTeam() @ "sight" @ int(Viewer.GetCurrentStat(eStat_SightRadius)) @ "at" @ Viewer.TileDistanceBetween(Unit) @ "tiles"
					@ "on" @ Viewer.TileLocation.X $ "," $ Viewer.TileLocation.Y $ "," $ Viewer.TileLocation.Z @ "concealed" @ Viewer.IsConcealed());
			else
				Out.AddItem("    by object" @ Viewers[v].ObjectID @ `XCOMHISTORY.GetGameStateForObjectID(Viewers[v].ObjectID).Class);
		}
	}
}

/** In a mission: a soldier's ability used on a target (its index among the available targets; -1: list them). */
/**
 * Psi training (features/lw-psi.md): with no arguments the powers (target will, what is missing for the first
 * soldier ready) and the soldiers in training; 'psi <soldier index> <perk>' begins training.
 */
function Psi(array<string> Args, out array<string> Out)
{
	local XComGameState_LWStrategy S;
	local LWBaseRules.LWPsiPower P;
	local XComGameState_LWStrategy.LWPsiTrainee T;
	local XComGameState_Unit Unit, First;
	local StateObjectReference Ref;
	local string Why;
	local int n;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
	{
		Out.AddItem("ERR no Long War campaign");
		return;
	}
	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		if (Args.Length > 2 && n == int(Args[1]))
		{
			Out.AddItem(class'XComGameState_LWStrategy'.static.StartPsi(Unit.ObjectID, int(Args[2]), Why) ? "ok" @ Unit.GetFullName() @ "begins" : "ERR needs" @ Why);
			return;
		}
		if (First == none && Unit.CanGoOnMission() && !S.InPsiTraining(Unit.ObjectID))
			First = Unit;
		n++;
	}
	if (Args.Length > 2)
	{
		Out.AddItem("ERR no such soldier");
		return;
	}
	Out.AddItem("Psi Labs:" @ class'LWBase'.static.Count(S, 17) @ "built," @ S.PsiTrainees.Length @ "training," @ class'LWBaseRules'.default.PsiSlots @ "places each");
	foreach class'LWBaseRules'.default.PsiPowers(P)
	{
		class'XComGameState_LWStrategy'.static.CanTrainPsi(S, First, P, Why);
		Out.AddItem(P.Perk @ class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk) @ "will" @ P.TargetWill
			$ (First != none ? " | " $ First.GetFullName() @ "(will" @ int(First.GetMaxStat(eStat_Will)) $ "):" @ class'LWBaseRules'.static.PsiChance(int(First.GetMaxStat(eStat_Will)), P) $ "%," @ class'LWBaseRules'.static.PsiHours(int(First.GetMaxStat(eStat_Will)), P) @ "hours" : "")
			$ (Why != "" ? "; needs" @ Why : ""));
	}
	foreach S.PsiTrainees(T)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(T.Unit));
		Out.AddItem("training:" @ (Unit != none ? Unit.GetFullName() : string(T.Unit)) @ class'X2Ability_LWStandins'.static.PsiAbilityFor(T.Perk) @ T.HoursLeft @ "hours left," @ T.Chance $ "%");
	}
}

/** Gene mods (features/lw-genemods.md): with no arguments the mods and who is in the tank; 'gene <soldier index> <perk>' begins one. */
function Gene(array<string> Args, out array<string> Out)
{
	local XComGameState_LWStrategy S;
	local LWBaseRules.LWGeneMod G;
	local XComGameState_LWStrategy.LWPsiTrainee T;
	local XComGameState_Unit Unit, First;
	local StateObjectReference Ref;
	local string Why;
	local int n;

	S = class'XComGameState_LWStrategy'.static.Get();
	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		if (Args.Length > 2 && n == int(Args[1]))
		{
			Out.AddItem(class'XComGameState_LWStrategy'.static.StartGeneMod(Unit.ObjectID, int(Args[2]), Why) ? "ok" @ Unit.GetFullName() @ "in the tank" : "ERR needs" @ Why);
			return;
		}
		if (First == none && Unit.CanGoOnMission() && !S.InPsiTraining(Unit.ObjectID))
			First = Unit;
		n++;
	}
	Out.AddItem("Genetics Lab:" @ class'LWBase'.static.Count(S, 23) @ "built," @ S.GeneTrainees.Length @ "in the tanks");
	foreach class'LWBaseRules'.default.GeneMods(G)
	{
		class'XComGameState_LWStrategy'.static.CanGeneMod(S, First, G, Why);
		Out.AddItem(G.Perk @ class'X2Ability_LWStandins'.static.GeneAbilityFor(G.Perk) @ G.Slot @ class'LWStrategyRules'.static.Money(G.Cash) @ G.Meld @ "meld" @ G.Days @ "days" $ (Why != "" ? "; needs" @ Why : ""));
	}
	foreach S.GeneTrainees(T)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(T.Unit));
		Out.AddItem("tank:" @ (Unit != none ? Unit.GetFullName() : string(T.Unit)) @ class'X2Ability_LWStandins'.static.GeneAbilityFor(T.Perk) @ T.HoursLeft @ "hours left");
	}
}

static function string JoinNames(array<name> Names)
{
	local string S;
	local name N;

	foreach Names(N)
		S @= string(N);
	return S;
}

static function bool TileTaken(TTile T)
{
	local XComGameState_Unit Any;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Any)
		if (!Any.bRemovedFromPlay && Any.IsAlive() && Any.TileLocation == T)
			return true;
	return false;
}

/** A soldier moved to a free floor tile beside another (a test aid: a medikit's reach). */
/**
 * In a mission: the aliens' psi abilities' chances against each soldier (Long War's will against psi counted); with an
 * ability's name, that ability's chances instead, with what made them.
 */
function PsiChances(out array<string> Out, name Only)
{
	local XComGameState_Unit Alien, Soldier;
	local XComGameState_Ability Ability;
	local StateObjectReference Ref;
	local AvailableTarget Target;
	local ShotBreakdown Breakdown;
	local X2AbilityToHitCalc Check;
	local string Why;
	local int i;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Alien)
	{
		if (!Alien.IsAlive() || Alien.GetTeam() != eTeam_Alien)
			continue;
		foreach Alien.Abilities(Ref)
		{
			Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
			Check = Ability == none ? none : Ability.GetMyTemplate().AbilityToHitCalc;
			if (Check == none || (Only == '' ? X2AbilityToHitCalc_LWPsiCheck(Check) == none : Ability.GetMyTemplateName() != Only))
				continue;
			foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Soldier)
			{
				if (!Soldier.IsSoldier() || !Soldier.IsAlive() || Soldier.GetTeam() != eTeam_XCom)
					continue;
				Target.PrimaryTarget = Soldier.GetReference();
				if (Only == '')
				{
					Out.AddItem(Alien.GetMyTemplateName() @ Ability.GetMyTemplateName() @ "->" @ Soldier.GetFullName() @ "will" @ int(Soldier.GetCurrentStat(eStat_Will)) @ "+" @ class'X2Ability_LWStandins'.static.PsiWillOf(Soldier) $ ":" @ Check.GetShotBreakdown(Ability, Target, Breakdown) $ "%");
					continue;
				}
				Why = "";
				i = Check.GetShotBreakdown(Ability, Target, Breakdown);
				for (i = 0; i < Breakdown.Modifiers.Length; i++)
					Why @= Breakdown.Modifiers[i].Reason $ "=" $ Breakdown.Modifiers[i].Value;
				Out.AddItem(Alien.ObjectID @ Ability.GetMyTemplateName() @ "->" @ Soldier.GetFullName() @ "(" $ Alien.TileDistanceBetween(Soldier) @ "tiles):" @ Breakdown.FinalHitChance $ "%" @ Ability.GetMyTemplate().CheckTargetConditions(Ability, Alien, Soldier) @ "|" $ Why);
			}
		}
	}
	if (Out.Length == 0)
		Out.AddItem("none: no alien with a psi ability");
}

/** In a mission: a soldier (name or class part) loses health, as a hit would (their lowest health in the mission too). */
function string Hurt(string Who, int Amount)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		// A soldier by name or class, an alien by its template's name (the first one alive), any unit by #its object id.
		if (!Unit.IsAlive() || Unit.bRemovedFromPlay)
			continue;
		if (Left(Who, 1) == "#" ? Unit.ObjectID != int(Mid(Who, 1)) : (Unit.GetTeam() == eTeam_XCom ? (!Unit.IsSoldier() || InStr(Locs(Unit.GetFullName() @ Unit.GetSoldierClassTemplateName()), Locs(Who)) < 0) : string(Unit.GetMyTemplateName()) != Who))
			continue;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: a soldier hurt");
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetCurrentStat(eStat_HP, Max(1, Unit.GetCurrentStat(eStat_HP) - Amount));
		Unit.LowestHP = Min(Unit.LowestHP, Unit.GetCurrentStat(eStat_HP));
		`TACTICALRULES.SubmitGameState(NewGameState);
		return "ok" @ Unit.GetFullName() @ "hp" @ int(Unit.GetCurrentStat(eStat_HP)) $ "/" $ Unit.HighestHP @ "lowest" @ Unit.LowestHP;
	}
	return "ERR no such soldier in a mission";
}

/** In a mission: every alien killed, the civilians left alone (XCOM 2's KillAllAIs kills them too: they are the AI's). */
function string KillAliens()
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local int n;

	if (`TACTICALRULES == none)
		return "ERR not in a mission";
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: aliens killed");
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!Unit.IsAlive() || Unit.bRemovedFromPlay || Unit.GetTeam() != eTeam_Alien)
			continue;
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetCurrentStat(eStat_HP, 0);
		n++;
	}
	`TACTICALRULES.SubmitGameState(NewGameState);
	return "ok" @ n @ "aliens killed";
}

function string MoveNext(string Who, string Whom)
{
	local XComGameState_Unit Unit, Other, Any;
	local XComWorldData World;
	local XComGameState NewGameState;
	local TTile T;
	local vector P;
	local int dx, dy;
	local bool bTaken;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Any)
		if (Any.GetTeam() == eTeam_XCom && !Any.bRemovedFromPlay)
		{
			if (InStr(Caps(Any.GetFullName()), Caps(Who)) != INDEX_NONE)
				Unit = Any;
			if (InStr(Caps(Any.GetFullName()), Caps(Whom)) != INDEX_NONE)
				Other = Any;
		}
	if (Unit == none || Other == none)
		return "ERR no such soldiers";
	World = `XWORLD;
	for (dx = -1; dx <= 1; dx++)
		for (dy = -1; dy <= 1; dy++)
		{
			if (dx == 0 && dy == 0)
				continue;
			T = Other.TileLocation;
			T.X += dx;
			T.Y += dy;
			P = World.GetPositionFromTileCoordinates(T);
			if (!World.GetFloorTileForPosition(P, T, false) || !World.CanUnitsEnterTile(T))
				continue;
			bTaken = false;
			foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Any)
				if (!Any.bRemovedFromPlay && Any.TileLocation == T)
					bTaken = true;
			if (bTaken)
				continue;
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a soldier moved beside another (control port)");
			XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = class'LWMissionSquads'.static.BuildPodVisualization;
			Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			Unit.bRequiresVisibilityUpdate = true;
			Unit.SetVisibilityLocation(T);
			`TACTICALRULES.SubmitGameState(NewGameState);
			return "ok" @ Unit.GetFullName() @ "beside" @ Other.GetFullName();
		}
	return "ERR no free tile beside" @ Other.GetFullName();
}

/** A soldier moved to a floor tile Tiles from the nearest living alien, on the side towards the soldier (a test aid: a target in view). */
function string MoveNear(string Who, int Tiles)
{
	local XComGameState_Unit Unit, Target, Other;
	local XComWorldData World;
	local XComGameState NewGameState;
	local vector From, To, Dir;
	local TTile T;
	local int Best, d;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_XCom && !Unit.bRemovedFromPlay && (InStr(Caps(Unit.GetFullName()), Caps(Who)) != INDEX_NONE || InStr(Caps(string(Unit.GetSoldierClassTemplateName())), Caps(Who)) != INDEX_NONE))
			break;
	if (Unit == none)
		return "ERR no such soldier";
	Best = MaxInt;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Other)
		if (Other.GetTeam() == eTeam_Alien && Other.IsAlive() && !Other.bRemovedFromPlay)
		{
			d = Unit.TileDistanceBetween(Other);
			if (d < Best)
			{
				Best = d;
				Target = Other;
			}
		}
	if (Target == none)
		return "ERR no alien";
	World = `XWORLD;
	From = World.GetPositionFromTileCoordinates(Target.TileLocation);
	Dir = Normal(World.GetPositionFromTileCoordinates(Unit.TileLocation) - From);
	To = From + Dir * Tiles * class'XComWorldData'.const.WORLD_StepSize;
	if (!World.GetFloorTileForPosition(To, T, false))
		return "ERR no floor there";
	// Not onto another unit: the next tile towards the soldier while one stands there.
	for (d = 0; d < 6 && TileTaken(T); d++)
	{
		To += Dir * class'XComWorldData'.const.WORLD_StepSize;
		World.GetFloorTileForPosition(To, T, false);
	}
	if (TileTaken(T))
		return "ERR no free tile there";
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a soldier moved near an alien (control port)");
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = class'LWMissionSquads'.static.BuildPodVisualization;
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Unit.bRequiresVisibilityUpdate = true;
	Unit.SetVisibilityLocation(T);
	`TACTICALRULES.SubmitGameState(NewGameState);
	return "ok" @ Unit.GetFullName() @ "at" @ T.X $ "," $ T.Y $ "," $ T.Z @ "," @ Tiles @ "tiles from" @ Target.GetMyTemplateName();
}

function string UseAbility(string Who, name AbilityName, int TargetIndex, optional name ItemName)
{
	local XComGameState_Unit Unit, Target;
	local GameRulesCache_Unit Cache;
	local AvailableAction Action;
	local AvailableTarget Forced;
	local string Targets;
	local array<vector> Here;
	local XComGameState_Ability Ability;
	local AvailableTarget Area;
	local XComGameState_Unit Near;
	local int Best;
	local int i;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_XCom && !Unit.bRemovedFromPlay && (InStr(Caps(Unit.GetFullName()), Caps(Who)) != INDEX_NONE || InStr(Caps(string(Unit.GetSoldierClassTemplateName())), Caps(Who)) != INDEX_NONE))
			break;
	if (Unit == none || `TACTICALRULES == none || !`TACTICALRULES.GetGameRulesCache_Unit(Unit.GetReference(), Cache))
		return "ERR no such soldier in a mission";
	foreach Cache.AvailableActions(Action)
	{
		Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
		if (Ability.GetMyTemplateName() != AbilityName || (ItemName != '' && (Ability.GetSourceWeapon() == none || Ability.GetSourceWeapon().GetMyTemplateName() != ItemName)))
			continue;
		// force: the nearest enemy as the target, whatever the conditions say (a test aid).
		if (TargetIndex == 99 && Action.AvailableTargets.Length == 0)
		{
			foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Target)
				if (Target.GetTeam() != eTeam_XCom && !Target.bRemovedFromPlay && Target.IsAlive())
					break;
			if (Target == none)
				return "ERR no enemy";
			Forced.PrimaryTarget = Target.GetReference();
			Action.AvailableTargets.AddItem(Forced);
			Action.AvailableCode = 'AA_Success';
			TargetIndex = 0;
		}
		// 98: at the soldier's own feet (a grenade's smoke on the soldier); 97: at the nearest alien (test aids).
		if (TargetIndex == 98 || TargetIndex == 97)
		{
			Near = Unit;
			if (TargetIndex == 97)
			{
				Best = MaxInt;
				foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Target)
					if (Target.GetTeam() == eTeam_Alien && Target.IsAlive() && !Target.bRemovedFromPlay && Unit.TileDistanceBetween(Target) < Best)
					{
						Best = Unit.TileDistanceBetween(Target);
						Near = Target;
					}
			}
			Here.AddItem(`XWORLD.GetPositionFromTileCoordinates(Near.TileLocation));
			if (Action.AvailableTargets.Length == 0)
				Action.AvailableTargets.Length = 1;
			// The units in its area, as the targeting UI gathers them before it activates the ability.
			Area = Action.AvailableTargets[0];
			if (Ability.GetMyTemplate().AbilityMultiTargetStyle != none)
				Ability.GetMyTemplate().AbilityMultiTargetStyle.GetMultiTargetsForLocation(Ability, Here[0], Area);
			Action.AvailableTargets[0] = Area;
			return class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0, Here) ? "used at" @ Here[0] : "ERR it did not go";
		}
		if (TargetIndex < 0 || TargetIndex >= Action.AvailableTargets.Length)
		{
			for (i = 0; i < Action.AvailableTargets.Length; i++)
			{
				Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Action.AvailableTargets[i].PrimaryTarget.ObjectID));
				Targets @= i $ "=" $ (Target != none ? string(Target.GetMyTemplateName()) : string(Action.AvailableTargets[i].PrimaryTarget.ObjectID));
			}
			return AbilityName @ "available" @ Action.AvailableCode @ "targets:" $ Targets $ (Action.AvailableTargets.Length == 0 ? " |" $ WhyNoTargets(Unit, XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID))) : "");
		}
		return class'XComGameStateContext_Ability'.static.ActivateAbility(Action, TargetIndex) ? "used" : "ERR it did not go";
	}
	return "ERR" @ Unit.GetFullName() @ "has no" @ AbilityName;
}

function Give(name ItemName, int n, out array<string> Out)
{
	local XComGameState NewGameState;

	if (class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemName) == none)
	{
		Out.AddItem("ERR no item template" @ ItemName);
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: items given (control port)");
	class'X2Item_LWArtifacts'.static.GiveItem(NewGameState, ItemName, n);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Out.AddItem("held" @ class'LWEngineering'.static.Held(ItemName));
}

function Research(string Which, out array<string> Out)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech Tech;
	local array<StateObjectReference> Refs;
	local int i;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ == none)
	{
		Out.AddItem("ERR not in a campaign");
		return;
	}
	Refs = XComHQ.GetAvailableTechsForResearch();
	if (Which != "")
	{
		i = int(Which);
		if (i < 0 || i >= Refs.Length)
		{
			Out.AddItem("ERR no such tech");
			return;
		}
		Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Refs[i].ObjectID));
		if (!XComHQ.MeetsRequirmentsAndCanAffordCost(Tech.GetMyTemplate().Requirements, Tech.GetMyTemplate().Cost, XComHQ.ResearchCostScalars, 0.0, Tech.GetMyTemplate().AlternateRequirements))
		{
			Out.AddItem("ERR cannot pay for" @ Tech.GetMyTemplate().DisplayName);
			return;
		}
		XComHQ.SetNewResearchProject(Refs[i]);
		Out.AddItem("started" @ Tech.GetMyTemplateName() @ Tech.GetMyTemplate().DisplayName);
		return;
	}
	Tech = XComHQ.GetCurrentResearchTech();
	if (Tech != none)
		Out.AddItem("under way" @ Tech.GetMyTemplateName() @ "hours" @ XComHQ.GetHoursLeftOnResearchProject() @ "|" @ Tech.GetMyTemplate().DisplayName);
	for (i = 0; i < Refs.Length; i++)
	{
		Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(Refs[i].ObjectID));
		Out.AddItem("tech" @ i @ Tech.GetMyTemplateName() @ "hours" @ XComHQ.GetResearchHours(Refs[i])
			@ "affordable" @ int(XComHQ.MeetsRequirmentsAndCanAffordCost(Tech.GetMyTemplate().Requirements, Tech.GetMyTemplate().Cost, XComHQ.ResearchCostScalars, 0.0, Tech.GetMyTemplate().AlternateRequirements))
			@ "inspired" @ int(Tech.bInspired) @ "|" @ Tech.GetMyTemplate().DisplayName);
	}
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

/**
 * A decision taken without playing it: an interception fought by the air war's rules with the
 * healthiest jet at the stance (its result recorded for the jet and the Geoscape), a mission given
 * its result (sent and come back, as XCOM 2's mission path would report it).
 */
function string ResolveDecision(int n, bool bWon, int Stance, optional bool bCapture)
{
	local XComGameState_LWStrategy S;
	local XComGameState_LWAirWar AirWar;
	local array<int> Kinds, Indexes;
	local array<string> Labels;
	local LWAirWar.LWResult R;
	local LWAirWar.LWShip Jet, TheUfo;
	local int Best;

	S = class'XComGameState_LWStrategy'.static.Get();
	S.Decisions(Kinds, Indexes, Labels);
	if (n < 0 || n >= Kinds.Length)
		return "ERR no such decision";
	if (Kinds[n] != 1)
	{
		if (bWon)
			class'XComGameState_LWStrategy'.static.WonWithoutPlaying(Kinds[n] - 1, Indexes[n], bCapture);
		else
		{
			class'XComGameState_LWStrategy'.static.MissionSent(Kinds[n] - 1, Indexes[n]);
			class'XComGameState_LWStrategy'.static.MissionBack(false);
		}
		return "resolved" @ Labels[n] @ (bWon ? "won" : "lost");
	}
	class'XComGameState_LWAirWar'.static.EnsureExists();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	Best = class'LWHangar'.static.BestFor(Indexes[n]);
	if (Best < 0)
		return "no jet fit to fly:" @ Labels[n];
	Jet = class'LWAirWar'.static.Craft(AirWar.Jets[Best].Type, AirWar.Jets[Best].Weapon, S.Category());
	Jet.Hp = AirWar.Jets[Best].Hp;
	TheUfo = class'LWAirWar'.static.Ufo(S.Ufos[Indexes[n]].Ufo, S.Category());
	TheUfo.Hp = S.Ufos[Indexes[n]].Hp;
	R = class'LWAirWar'.static.Fight(TheUfo, Jet, Clamp(Stance, 0, 2), class'LWAirWar'.static.NoActions());
	class'XComGameState_LWAirWar'.static.Record(Best, R.CraftHp, R.Outcome == eLWOutcome_Crashed || R.Outcome == eLWOutcome_Destroyed);
	class'XComGameState_LWStrategy'.static.Intercepted(Indexes[n], int(R.Outcome), R.UfoHp);
	return "fought" @ Labels[n] @ "with" @ AirWar.Jets[Best].Callsign $ ":" @ R.Outcome @ "ufo hp" @ R.UfoHp @ "jet hp" @ R.CraftHp;
}

/**
 * The campaign at full speed: time runs, and every decision is taken as it comes: interceptions
 * fought (resolve), missions won at WinPct %; with bSatellites, a satellite bought whenever there is
 * the money and room in the uplinks (else the base grown for an uplink) and launched over the most
 * panicked country without one, and two interceptors kept at home. A line a decision, then the
 * Geoscape's summary line.
 */
function AutoPlay(int Hours, int WinPct, int Stance, bool bSatellites, out array<string> Out)
{
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<int> Kinds, Indexes;
	local array<string> Labels;
	local int Done, Passed, k, Best, Guard;
	local string Why;

	Done = 0;
	while (Done < Hours && Guard++ < 5000)
	{
		Passed = class'XComGameState_LWStrategy'.static.Run(Hours - Done);
		Done += Passed;
		S = class'XComGameState_LWStrategy'.static.Get();
		if (S.bLost)
			break;
		if (bSatellites)
		{
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			// Satellites up to what the uplinks hold; the base grown for more (an uplink, else a dig or a lift).
			if (S.TileType.Length > 0 && class'LWBase'.static.SatellitesUp(S) + S.SatellitesReady + S.SatellitesDue.Length >= class'LWBase'.static.SatelliteLimit(S))
			{
				if (class'LWBase'.static.GrowForUplink(Why))
					Out.AddItem("day" @ S.Days() @ "base:" @ Why);
			}
			else if (XComHQ.GetSupplies() >= class'LWStrategyRules'.default.SatelliteCost && class'XComGameState_LWStrategy'.static.BuildSatellite())
				Out.AddItem("satellite ordered");
			// Two interceptors kept at home: a lost one replaced.
			if (class'LWHangar'.static.BaysTaken(class'XComGameState_LWAirWar'.static.Get(), class'LWHangar'.static.HomeContinent()) < 2
				&& class'LWHangar'.static.Order(class'LWHangar'.static.HomeContinent(), 1, Why))
				Out.AddItem("day" @ S.Days() @ "interceptor ordered");
			S = class'XComGameState_LWStrategy'.static.Get();
			while (S.SatellitesReady > 0)
			{
				Best = -1;
				for (k = 0; k < S.Countries.Length; k++)
					if (!S.Countries[k].bLeft && !S.Countries[k].bSatellite && (Best < 0 || S.Countries[k].Panic > S.Countries[Best].Panic))
						Best = k;
				if (Best < 0 || !class'XComGameState_LWStrategy'.static.LaunchSatellite(Best))
					break;
				Out.AddItem("satellite launched over" @ S.CountryName(Best));
				S = class'XComGameState_LWStrategy'.static.Get();
			}
		}
		// The decisions, the first each time (taking one can change the others); an interception
		// only with a jet fit to fly.
		S.Decisions(Kinds, Indexes, Labels);
		for (k = 0; k < Kinds.Length; k++)
			if (Kinds[k] != 1 || class'LWHangar'.static.BestFor(Indexes[k]) >= 0)
				break;
		if (k < Kinds.Length)
			Out.AddItem("day" @ S.Days() @ ResolveDecision(k, Rand(100) < WinPct, Stance, true));
		// Research kept going: the quickest affordable tech when none is under way.
		if (bSatellites && AutoResearch(Why))
			Out.AddItem("day" @ S.Days() @ "research:" @ Why);
		else if (Passed == 0)
			break;
	}
	Dump(class'XComGameState_LWStrategy'.static.Get(), Labels);
	Out.AddItem(Labels[0]);
}

/** A jet with HP left. */
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
	Out.AddItem("date" @ S.DateText() @ "| xcom2" @ class'X2StrategyGameRulesetDataStructures'.static.GetDateString(`STRATEGYRULES.GameTime) @ class'X2StrategyGameRulesetDataStructures'.static.GetTimeString(`STRATEGYRULES.GameTime) @ "lost" @ int(S.bLost) @ "| month" @ S.Month @ "hours" @ S.Hours @ "money" @ XComHQ.GetSupplies() @ "resources" @ S.AlienResources @ "aggression" @ S.AlienAggression
		@ "satellites_ready" @ S.SatellitesReady @ "satellites_building" @ S.SatellitesDue.Length @ "pending" @ S.PendingKind @ "events" @ S.EventCount
		@ "scientists" @ S.Scientists @ "engineers" @ S.Engineers @ "research_per_hour" @ class'UIUtilities_Strategy'.static.GetXComHQ().GetScienceScore(true) @ "credits" @ S.Credits.Length);
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

/** ewmat: a scalar (a number) or texture (a path) parameter set on every stand-in material of the EW map's pieces. */
function string SetEWMaterials(name Param, string Value)
{
	local LWX2LevelActor A;
	local MaterialInstanceConstant MIC;
	local array<MaterialInstanceConstant> Done;
	local Texture T;
	local int i;

	if (Param == '' || Value == "")
		return "ERR ewmat <parameter> <number | texture path>";
	if (InStr(Value, ".") >= 0 && float(Value) == 0 && Left(Value, 1) != "0")
	{
		T = Texture(DynamicLoadObject(Value, class'Texture', true));
		if (T == none)
			return "ERR no texture" @ Value;
	}
	foreach WorldInfo.AllActors(class'LWX2LevelActor', A)
	{
		if (A.StaticMeshComponent == none)
			continue;
		for (i = 0; i < A.StaticMeshComponent.GetNumElements(); i++)
		{
			MIC = MaterialInstanceConstant(A.StaticMeshComponent.GetMaterial(i));
			if (MIC == none || Done.Find(MIC) != INDEX_NONE)
				continue;
			Done.AddItem(MIC);
			if (T != none)
				MIC.SetTextureParameterValue(Param, T);
			else
				MIC.SetScalarParameterValue(Param, float(Value));
		}
	}
	return "ewmat" @ Param @ "=" @ Value @ "on" @ Done.Length @ "materials";
}

/** ewlight: EW's placed lights of a kind (or all) at Scale times their brightness now. */
/** What decides whether the fog of war is drawn: the world's switches, its size, and each fog effect of the player's post-process chains. */
function FogState(out array<string> Out)
{
	local LocalPlayer LP;
	local PostProcessChain Chain;
	local XComFOWEffect Effect;
	local int i, j, Effects;

	Out.AddItem("fog world: enabled" @ `XWORLD.bEnableFOW @ "debug enabled" @ `XWORLD.bDebugEnableFOW @ "updating" @ `XWORLD.bEnableFOWUpdate
		@ "visibility updates off" @ `XWORLD.bDisableVisibilityUpdates @ "tiles" @ `XWORLD.NumX @ `XWORLD.NumY @ `XWORLD.NumZ
		@ "bounds" @ `XWORLD.WorldBounds.Min @ `XWORLD.WorldBounds.Max);
	LP = LocalPlayer(GetALocalPlayerController().Player);
	for (i = 0; LP != none && i < LP.PlayerPostProcessChains.Length; i++)
	{
		Chain = LP.PlayerPostProcessChains[i];
		Out.AddItem("chain" @ i @ PathName(Chain) @ (Chain != none ? Chain.Effects.Length : 0) @ "effects");
		for (j = 0; Chain != none && j < Chain.Effects.Length; j++)
		{
			Effect = XComFOWEffect(Chain.Effects[j]);
			if (Effect == none)
				continue;
			Effects++;
			Out.AddItem("  fog effect" @ PathName(Effect) @ "shown" @ Effect.bShowFOW @ "volume at" @ Effect.LevelVolumePosition @ "inverse size" @ Effect.LevelVolumeDimensions);
		}
	}
	if (Effects == 0)
		Out.AddItem("no fog effect in the player's post-process chains");
}

function string ScaleEWLights(string Kind, float Scale)
{
	local Light A;
	local int n;

	foreach WorldInfo.AllActors(class'Light', A)
	{
		if (A.LightComponent == none)
			continue;
		if (!((Kind ~= "point" && LWX2PointLight(A) != none) || (Kind ~= "spot" && LWX2SpotLight(A) != none)
			|| (Kind ~= "sun" && LWX2SunLight(A) != none) || (Kind ~= "sky" && LWX2SkyLight(A) != none)
			|| (Kind ~= "all" && (LWX2PointLight(A) != none || LWX2SpotLight(A) != none || LWX2SunLight(A) != none || LWX2SkyLight(A) != none))))
			continue;
		A.LightComponent.SetLightProperties(A.LightComponent.Brightness * Scale, A.LightComponent.LightColor);
		n++;
	}
	return "ewlight" @ Kind @ "x" $ Scale @ "on" @ n @ "lights";
}

/** buildings: each building volume's floors (centre, half height, cached actors), or an action on one. */
function Buildings(array<string> Args, out array<string> Out)
{
	local XComBuildingVolume B;
	local int n, f, Want;
	local string Line;

	Want = Args.Length > 1 ? int(Args[1]) : -1;
	foreach WorldInfo.AllActors(class'XComBuildingVolume', B)
	{
		if (Want >= 0 && n != Want)
		{
			n++;
			continue;
		}
		if (Args.Length > 2 && Args[2] ~= "show")
			B.ShowFloors(int(Args[3]), int(Args[4]));
		else if (Args.Length > 2 && Args[2] ~= "reveal")
			B.RevealAllFloors();
		else if (Args.Length > 2 && Args[2] ~= "rebuild")
			B.RebuildCachedActors();
		else if (Args.Length > 2 && Args[2] ~= "force")
			ForceShown(B, Out);
		Line = "building" @ n @ B.Name @ "at" @ B.Location @ "inside" @ B.IsInside @ "floors" @ B.Floors.Length $ ":";
		for (f = 0; f < B.Floors.Length; f++)
		{
			Line @= "[" $ f @ "z" @ int(B.Floors[f].fCenterZ) @ "+-" @ int(B.Floors[f].fExtent) @ "vols" @ B.Floors[f].FloorVolumes.Length;
			if (B.Floors[f].FloorVolumes.Length > 0 && B.Floors[f].FloorVolumes[0] != none)
				Line @= "number" @ B.Floors[f].FloorVolumes[0].FloorNumber @ "type" @ int(B.Floors[f].FloorVolumes[0].m_FloorVolumeType) @ "empty" @ B.Floors[f].FloorVolumes[0].m_bIsEmptyFloor @ "bottom" @ int(B.Floors[f].FloorVolumes[0].Location.Z);
			Line @= "actors" @ B.Floors[f].m_aCachedActors.Length $ "]";
		}
		Out.AddItem(Line);
		// With a building chosen: its floors' first actors' visibility state (cutdown, cutout, opacity heights; hidden).
		if (Want >= 0)
			for (f = 0; f < B.Floors.Length; f++)
				VisState(B, f, Out);
		n++;
	}
	if (n == 0)
		Out.AddItem("no building volumes");
}

/** A floor's first few cached level actors: their building visibility heights and hidden state. */
function VisState(XComBuildingVolume B, int f, out array<string> Out)
{
	local XComLevelActor A;
	local float Cutdown, Cutout, Mask, PrevMask, TCut, TOut;
	local int k;

	for (k = 0; k < Min(3, B.Floors[f].m_aCachedActors.Length); k++)
	{
		A = XComLevelActor(B.Floors[f].m_aCachedActors[k].ResidentActor);
		if (A == none)
			continue;
		A.GetPrimitiveVisHeight(Cutdown, Cutout, Mask, PrevMask);
		A.GetTargetVisibility(TCut, TOut);
		Out.AddItem("  floor" @ f @ A.Name @ "at" @ int(A.Location.Z) @ "cutdownfloor" @ B.Floors[f].m_aCachedActors[k].CutdownFloor @ "cutdown" @ Cutdown @ "cutout" @ Cutout @ "mask" @ Mask @ "target" @ TCut @ TOut @ "hidden" @ A.bHidden @ "comp hidden" @ (A.StaticMeshComponent != none && A.StaticMeshComponent.HiddenGame) @ "offset" @ A.GetCutdownOffset());
	}
}

/** buildings n force: every cached actor of a building reset to XCOM 2's uncut values and shown. */
function ForceShown(XComBuildingVolume B, out array<string> Out)
{
	local XComLevelActor A;
	local int f, k, n;

	for (f = 0; f < B.Floors.Length; f++)
		for (k = 0; k < B.Floors[f].m_aCachedActors.Length; k++)
		{
			A = XComLevelActor(B.Floors[f].m_aCachedActors[k].ResidentActor);
			if (A == none)
				continue;
			A.SetHideableFlag(false);
			A.SetPrimitiveCutdownFlag(false);
			A.SetPrimitiveCutoutFlag(false);
			A.SetPrimitiveVisHeight(999999, -999999, 999999, 999999);
			if (A.StaticMeshComponent != none)
				A.StaticMeshComponent.SetHidden(false);
			n++;
		}
	Out.AddItem("forced shown:" @ n @ "actors");
}

defaultproperties
{
	LinkMode = MODE_Text;
	ReceiveMode = RMODE_Event;
	bAlwaysTick = true;
}
