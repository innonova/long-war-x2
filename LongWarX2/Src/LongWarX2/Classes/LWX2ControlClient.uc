// For development: one connection to the control port (LWX2Control): a command a line, the
// answer's lines, then ".". "help" lists the commands. Text mode, lines split here.
class LWX2ControlClient extends TcpLink dependson(XComGameState_LWStrategy, LWBaseRules, XComGameState_LWAirWar, LWX2CouncilBomb, LWX2CouncilVIP, LWX2Furies);

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
	local UILWEWRadar Radar;
	local array<string> Args;
	local XComGameState_LWStrategy S;
	local UILWGeoscape Geo;
	local XComNarrativeMoment Moment;
	local string Cmd, Why;
	local XComGameState_Unit EffUnit;
	local int Before;
	local Color AmbientColour;
	local LevelStreaming Streamed;
	local UIScreen Scr;
	local array<Actor> Placed;
	local PlayerController PC;
	local UIDisplay_LevelActor Disp;

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
		Out.AddItem("start [option]: Long War's start screen's options (home country and starting bonus); with an option, chosen there (the campaign begins) | bonuses: the bonuses holding now, and the home");
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
	case "pov":
		// A test aid: where the camera is and its field of view now, nothing moved.
		Out.AddItem("camera at" @ XComHeadquartersController(Pres().Owner).PlayerCamera.CameraCache.POV.Location @ "rot" @ XComHeadquartersController(Pres().Owner).PlayerCamera.CameraCache.POV.Rotation
			@ "fov" @ XComHeadquartersController(Pres().Owner).PlayerCamera.CameraCache.POV.FOV);
		return;
	case "basecam":
		// A test aid: EW's base view asked for again, and where the camera is (features/lw-base-view.md).
		class'LWX2EWBase'.static.Get(Pres()).Show();
		Out.AddItem("camera at" @ XComHeadquartersController(Pres().Owner).PlayerCamera.CameraCache.POV.Location @ "fov" @ XComHeadquartersController(Pres().Owner).PlayerCamera.CameraCache.POV.FOV
			@ "rooms" @ class'LWX2EWBase'.static.Data("Command1").Rooms.Length @ "cameras" @ class'LWX2EWBase'.static.Data("Command1").Cameras.Length);
		return;
	case "lightoff":
		// A test aid: every actor of a lighting kind switched off or on by its class name (LightInjector,
		// PostProcessVolume, a light class): lightoff <class> [on|off] [lights of at least this radius only].
		Out.AddItem(LightOff(Args.Length > 1 ? Args[1] : "", Args.Length > 2 && Args[2] ~= "on", Args.Length > 3 ? float(Args[3]) : 0.0));
		return;
	case "levels":
		// levels [filter]: every streamed level (whose name holds the filter), whether it should be loaded and visible, and
		// whether it is (a test aid: what LWX2EWBase hid and showed again).
		foreach `XWORLDINFO.StreamingLevels(Streamed)
			if (Streamed != none && (Args.Length < 2 || InStr(Locs(string(Streamed.PackageName)), Locs(Args[1])) != INDEX_NONE))
				Out.AddItem(Streamed.PackageName @ "load" @ Streamed.bShouldBeLoaded @ "visible" @ Streamed.bShouldBeVisible
					@ "(" $ (Streamed.LoadedLevel != none ? "loaded" : "not loaded") $ (Streamed.bHasLoadRequestPending ? ", pending" : "") $ ")");
		return;
	case "armorypawn":
		// The armory's pawn: where it stands, whether drawn, where the armory wants it (a test aid).
		ArmoryPawn(Out);
		return;
	case "ui3d":
		// ui3d [tag] [show]: XCOM 2's 3D UI displays (UIDisplay_LevelActor) and blueprints with that tag, whether each is
		// drawn; show: the 3D movie shown on it, as the armory asks (a test aid).
		UI3D(Args.Length > 1 ? name(Args[1]) : '', Args.Length > 2 && Args[2] == "show", Out);
		return;
	case "levelshow":
		// levelshow <package> [false]: a streamed level made visible (or hidden), as the engine is asked to (a test aid).
		GetALocalPlayerController().ClientUpdateLevelStreamingStatus(name(Args[1]), true, Args.Length < 3 || Args[2] != "false", false);
		Out.AddItem("ok" @ Args[1]);
		return;
	case "basenear":
		// A test aid: EW's base's pieces and people within <radius> of the camera, nearest first: basenear <radius>.
		BaseNear(Args.Length > 1 ? float(Args[1]) : 1500.0, Out);
		return;
	case "basemesh":
		// A test aid: EW's base's pieces whose mesh's path holds <text>: their component's bounds, flags, scale and when the
		// engine last drew them (LastRenderTime against now), to tell a culled piece from one drawn invisibly.
		BaseMesh(Args.Length > 1 ? Args[1] : "", Out);
		return;
	case "persontex":
		// A test aid: persontex <mesh text> <slot> <texture path>: that slot of EW's base people whose mesh holds the text
		// given that texture as its Diffuse, live.
		Out.AddItem(PersonTex(Args));
		return;
	case "basemat":
		// A test aid: EW's base's pieces whose mesh's path holds <text> given another material, live, with scalars and colours
		// set on an instance of it: basemat <text> <material> [<scalar> <value> | <vector> <r>,<g>,<b>,<a>]…
		Out.AddItem(BaseMat(Args));
		return;
	case "movie3d":
		// A test aid: XCOM 2's 3D movie as it renders EW's 3D screens: its render target's size, and a panel's (by tag)
		// material: its UV adjustment (UIMovie_3D.ScaleUVs).
		Out.AddItem(Movie3D(Args.Length > 1 ? name(Args[1]) : ''));
		return;
	case "tonemap":
		// A test aid: the local player's post-process chain's tonemapper (UberPostProcessEffect.TonemapperType) shown, or set:
		// tonemap [off|filmic|custom].
		Out.AddItem(Tonemap(Args.Length > 1 ? Args[1] : ""));
		return;
	case "basehide":
		// A test aid: EW's base's pieces and people whose mesh's path holds <text> hidden, or shown again: basehide <text> [show];
		// or the people among them turned or moved, live: basehide <text> yaw|z <add>; or posed: basehide <text> pose <seconds>.
		Out.AddItem(BaseHide(Args.Length > 1 ? Args[1] : "", Args.Length > 2 && Args[2] == "show", Args.Length > 3 ? Args[2] : "", Args.Length > 3 ? float(Args[3]) : 0.0));
		return;
	case "people":
		// A test aid: EW's people's light, live: people glow <v> (their light environment's ambient glow) | le on|off.
		Out.AddItem(PeopleLight(Args));
		return;
	case "ewdisplay":
		// A test aid: one of EW's 3D panels changed live: ewdisplay <tag> scale <s> | yaw <add> | pitch <add> | roll <add>.
		Out.AddItem(EWDisplay(Args));
		return;
	case "baseparents":
		// A test aid: EW's base's pieces' materials counted by their parent (features/ew-lightmaps.md).
		BaseParents(Out);
		return;
	case "basedle":
		// A test aid: the light environments of EW's base's pieces (DynamicSMActor_Spawnable) on or off, live:
		// basedle on|off. Off, each piece is lit by the lights themselves instead of their summary.
		Out.AddItem(BaseLightEnvironments(Args.Length > 1 && Args[1] == "on"));
		return;
	case "worldambient":
		// A test aid: the world's ambient light overridden (WorldInfo's world ambient: on, its intensity), live, and the
		// ambient cube taken again: worldambient <intensity> | off.
		WorldInfo.bUseWorldAmbientVars = Args.Length > 1 && Args[1] != "off";
		if (WorldInfo.bUseWorldAmbientVars)
			WorldInfo.WorldAmbientIntensity = float(Args[1]);
		`XENGINE.bRefreshAmbientCubeRequested = true;
		Out.AddItem("ok world ambient" @ (WorldInfo.bUseWorldAmbientVars ? string(WorldInfo.WorldAmbientIntensity) : "off") @ "cube" @ PathName(WorldInfo.WorldAmbientCubemap));
		return;
	case "baselighting":
		// A test aid: EW's base lit by another of XCOM 2's lighting levels, live (LWX2EWBase.BaseLighting; "" none):
		// baselighting <EnvLighting_…>.
		Out.AddItem(class'LWX2EWBase'.static.Get(Pres()).SetLighting(Args.Length > 1 ? Args[1] : ""));
		return;
	case "ambient":
		// A test aid: the ambient light's colour as the engine has it (from the visible lighting level's cube: the Avenger's
		// sky-and-light level for the hour, or EW's base's own, LWX2EWBase.BaseLighting).
		AmbientColour = `XENGINE.GetNonDirectionalAmbientCubeLighting();
		Out.AddItem("ambient cube colour" @ AmbientColour.R $ "," $ AmbientColour.G $ "," $ AmbientColour.B);
		// And the streamed levels visible now (one of them brings the ambient cube).
		foreach Pres().WorldInfo.StreamingLevels(Streamed)
			if (Streamed != none && Streamed.bIsVisible)
				Out.AddItem("visible level" @ Streamed.PackageName @ (Streamed.bShouldBeVisible ? "" : "(to be hidden)"));
		return;
	case "hub":
		// A test aid: the hub driven as its clicks drive it: hub <room 0-4> | option <n> | back | mc.
		Out.AddItem(HubCommand(Args));
		return;
	case "lights":
		// A test aid: the world's lights that are not EW's base's own (class, on, brightness, colour, distance from the base),
		// how many are the base's, and the actors of a lighting kind by class (features/lw-base-view.md); lights near <radius>:
		// every light that is on within that distance of the camera, the nearest first.
		if (Args.Length > 2 && Args[1] ~= "near")
			LightsNear(Out, float(Args[2]));
		else
			LightsReport(Out);
		return;
	case "baselook":
		// A test aid: EW's base shown through one of its cameras (by tag: Base, Expansion, AwayTeam, AddonCam_R1_C1 …).
		class'LWX2EWBase'.static.Get(Pres()).Show();
		class'LWX2EWBase'.static.Get(Pres()).LookAt(name(Args.Length > 1 ? Args[1] : "Base"), 0);
		Out.AddItem("ok");
		return;
	case "peek":
		// A test aid: the Geoscape hidden (or shown again) to look at what is behind it (EW's base, features/lw-base-view.md).
		Geo = UILWGeoscape(Pres().ScreenStack.GetFirstInstanceOf(class'UILWGeoscape'));
		if (Geo == none)
			Out.AddItem("ERR no Geoscape");
		else if (Geo.bIsVisible)
		{
			Geo.Hide();
			Out.AddItem("Geoscape hidden");
		}
		else
		{
			Geo.Show();
			Out.AddItem("Geoscape shown");
		}
		return;
	case "storm":
		// A test aid: XCOM 2's weather actor at a storm level (0 none, 2 light rain, 3 light storm, … 6 hurricane), the ground
		// wet from 2 (LWX2EWMapPieces.SetStorm, as EW's map's own level is set at the battle's start): storm <level>.
		Out.AddItem(class'LWX2EWMapPieces'.static.SetStorm(Pres(), Args.Length > 1 ? int(Args[1]) : 2) ? "ok storm" @ (Args.Length > 1 ? Args[1] : "2") : "ERR no weather actor");
		return;
	case "narrative":
		// A test aid: one of XCOM 2's headquarters narratives played as its own code plays them (HQPres.UINarrative), to see
		// it stopped (UIScreenListener_LWX2NoHQNarrative): narrative [<path>] (XCOM 2's objective-added comm link by default).
		Moment = XComNarrativeMoment(DynamicLoadObject(Args.Length > 1 ? Args[1] : "X2NarrativeMoments.Strategy.Avenger_Objective_Added", class'XComNarrativeMoment', true));
		if (Moment == none || XComHQPresentationLayer(Pres()) == none)
			Out.AddItem("ERR" @ (Moment == none ? "no such narrative" : "not at headquarters"));
		else
		{
			XComHQPresentationLayer(Pres()).UINarrative(Moment);
			Out.AddItem("ok playing" @ PathName(Moment));
		}
		return;
	case "ping":
		Out.AddItem("pong" @ (Pres().ScreenStack.GetCurrentScreen() != none ? string(Pres().ScreenStack.GetCurrentScreen().Class.Name) : "none"));
		return;
	case "screens":
		Screens(Out);
		return;
	case "lmcheck":
		// A test aid: a few of the mission's light-mapped materials (M_EWLightmappedLit's instances): their light map texture,
		// its size, the second atlas and the brightness, as the shader gets them.
		LMCheck(Out);
		return;
	case "micset":
		// A test aid: on every light-mapped material of the mission (M_EWLightmappedLit's instances), a parameter set:
		// 'micset tex <name> <texture path>', 'micset scalar <name> <value>', 'micset vector <name> <r> <g> <b> <a>', 'micset parent <material>'.
		Out.AddItem(MicSet(Args));
		return;
	case "custpawn":
		// A test aid: XCOM 2's Customize's soldier (where, hidden) and the armory's spot (PointInSpace UIPawnLocation_Armory).
		CustPawn(Out);
		return;
	case "shadowcopies":
		// shadowcopies <min z>: a shadow-only copy (LWX2ShadowPiece) of every piece of the map at or above that height (a test aid
		// for the roofs' shadows under XCOM 2's floor hiding).
		Out.AddItem(ShadowCopies(Args.Length > 1 ? float(Args[1]) : 150.0) @ "shadow copies");
		return;
	case "reattach":
		// A test aid: every static mesh component of the map re-attached (after a console 'set' of a property its scene proxy
		// reads only when made, e.g. bCastHiddenShadow).
		Out.AddItem(Reattach() @ "components re-attached");
		return;
	case "windows":
		// A test aid: the map's windows (level actors flagged bIsWindow) and whether XCOM 2's path solver goes through each,
		// from the tile on one side to the tile on the other (a path of 2 or 3 tiles: through; longer: round; none: no way).
		Windows(Out);
		return;
	case "load":
		// A test aid: an object loaded by its path (DynamicLoadObject, quietly), its class and full path, or none.
		Out.AddItem(Args.Length > 1 ? (DynamicLoadObject(Args[1], class'Object', true) != none ? PathName(DynamicLoadObject(Args[1], class'Object', true)) @ DynamicLoadObject(Args[1], class'Object', true).Class.Name : "none") : "ERR load <path>");
		return;
	case "screensv":
		// A test aid: the screen stack with each screen's visibility, its cinematic mode, XCOM 2's navigation help's.
		foreach Pres().ScreenStack.Screens(Scr)
			Out.AddItem(string(Scr.Class.Name) @ (Scr.bIsVisible ? "shown" : "hidden"));
		Out.AddItem("cinematic mode" @ Pres().ScreenStack.bCinematicMode);
		if (XComHQPresentationLayer(Pres()) != none && XComHQPresentationLayer(Pres()).m_kAvengerHUD != none)
		{
			Out.AddItem("nav help" @ (XComHQPresentationLayer(Pres()).m_kAvengerHUD.NavHelp.bIsVisible ? "shown" : "hidden"));
			// (And as Flash has it: the help's clip and each clip above it, _visible and _alpha.)
			Cmd = string(XComHQPresentationLayer(Pres()).m_kAvengerHUD.NavHelp.MCPath);
			while (InStr(Cmd, ".") != INDEX_NONE)
			{
				Out.AddItem(Cmd @ "visible" @ XComHQPresentationLayer(Pres()).m_kAvengerHUD.Movie.GetVariableBool(Cmd $ "._visible")
					@ "alpha" @ XComHQPresentationLayer(Pres()).m_kAvengerHUD.Movie.GetVariableNumber(Cmd $ "._alpha")
					@ "y" @ XComHQPresentationLayer(Pres()).m_kAvengerHUD.Movie.GetVariableNumber(Cmd $ "._y"));
				Cmd = Left(Cmd, InStr(Cmd, ".", true));
			}
		}
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
		// 'abilities' the soldiers'; 'abilities #<id>' any unit's, with why each is not available now.
		if (Args.Length > 1 && Left(Args[1], 1) == "#")
			UnitAbilities(int(Mid(Args[1], 1)), Out);
		else
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
		// crew: how many soldiers XCOM has, and of what rank; 'crew list': each soldier's id, name, class, rank and status.
		Out.AddItem(Crew());
		if (Args.Length > 1 && Args[1] ~= "list")
			CrewList(Out);
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
	case "exalt":
		// EXALT: 'exalt' its state; 'exalt begin' (active now, two cells), 'exalt place', 'exalt act <country>', 'exalt sweep',
		// 'exalt intel <n>' (test aids but the sweep).
		Exalt(Args, Out);
		return;
	case "img":
		// img <path>: whether a texture loads (EW's strategy pictures, Command1.QILibrary_StrategyImages.GeneMods.GeneMods_Adrenal).
		// ('img find <path>': only if in memory, nothing loaded.)
		if (Args.Length > 2 && Args[1] == "find")
			Out.AddItem(Args[2] @ "->" @ PathName(FindObject(Args[2], class'Object')) @ FindObject(Args[2], class'Object').Class);
		else
			Out.AddItem(Args.Length > 1 ? (Args[1] @ "->" @ PathName(DynamicLoadObject(Args[1], class'Object', true)) @ DynamicLoadObject(Args[1], class'Object', true).Class) : "ERR img <path>");
		return;
	case "range":
		// range <soldier name or class part> <ability>: the reach of the soldier's aim with it, in tiles (a test aid).
		if (Args.Length > 2)
			Out.AddItem(AbilityRange(Args[1], name(Args[2])));
		return;
	case "put":
		// put <unit index (units) | #object id> <x> <y> <z>: a unit set on that tile at once (a test aid).
		if (Args.Length < 5)
		{
			Out.AddItem("ERR put <unit index | #id> <tile x> <tile y> <tile z>");
			return;
		}
		Out.AddItem(PutUnit(Args[1], int(Args[2]), int(Args[3]), int(Args[4])));
		return;
	case "repair":
		// repair: the damaged items and the repairs under way (features/lw-gear-repair.md); 'repair <template>': one put into
		// repair; 'repair wear <soldier> <hp>': a test aid, the soldier's health set and its gear rolled for damage as after a
		// mission (soldier: as give-to counts them).
		Repair(Args, Out);
		return;
	case "bt":
		// bt #<unit> <behaviour tree>: the tree run for the unit as the AI runs it, the unit given an action point if it has
		// none (a test aid: Itchy Trigger Tentacle's scamper, LWX2ScamperRoot_NoCover).
		if (Args.Length < 3)
			Out.AddItem("ERR bt #<unit> <behaviour tree>");
		else
			Out.AddItem(RunTree(int(Mid(Args[1], 1)), Args[2]));
		return;
	case "war":
		// war: Dynamic War's passes (second wave #9) and the aliens' objectives so far by kind (a test aid); 'war late': a
		// Firestorm on the next continent and Long War's late mission planned at once.
		if (Args.Length > 1 && Args[1] ~= "late")
			WarLate(Out);
		War(Out);
		return;
	case "meld":
		// meld: the mission's meld canisters, made (tile, turns left) and, without Recon, still hidden in the fog (a test aid).
		Meld(Out);
		return;
	case "scamper":
		// scamper #<AI group id>: the group revealed as if a soldier had just seen it, its units scampering (a test aid; the
		// group's id is in 'enemies').
		Out.AddItem(Scamper(Args.Length > 1 ? int(Mid(Args[1], 1)) : 0));
		return;
	case "perfectinfo":
		// perfectinfo: Perfect Information's listener's counts (a test aid); 'perfectinfo say <text>': a world message over the
		// first soldier, as it shows one.
		PerfectInfo(Args, Out);
		return;
	case "coverscan":
		// coverscan <shooter #id> <target #id> [radius]: tiles around the target (its floor) where it would have cover from the
		// shooter, with XCOM 2's angle to that cover (a test aid, for Aiming Angles).
		if (Args.Length < 3)
			Out.AddItem("ERR coverscan <shooter #id> <target #id> [radius]");
		else
			CoverScan(int(Mid(Args[1], InStr(Args[1], "#") == 0 ? 1 : 0)), int(Mid(Args[2], InStr(Args[2], "#") == 0 ? 1 : 0)), Args.Length > 3 ? int(Args[3]) : 4, Out);
		return;
	case "tile":
		// tile <x> <y>: the column of tiles at a world point (EW's coordinates on its own plot): each floor's tile, whether it
		// is a floor and units can enter it, and what a trace down from above hits first (a test aid).
		if (Args.Length < 3)
		{
			Out.AddItem("ERR tile <x> <y>");
			return;
		}
		TileColumn(float(Args[1]), float(Args[2]), Out);
		return;
	case "evac":
		// evac: XCOM's evac zone, whether Evac is allowed, and an EXALT covert extraction's state (a test aid).
		Evac(Out);
		return;
	case "spawns":
		// spawns: the map's soldier spawns (XComGroupSpawn) and the one XCOM 2 chose (a test aid).
		Spawns(Out);
		return;
	case "council":
		// council: the council's clock and missions; 'council now [id]': the month's council mission made at once, or that one
		// (Long War's EFCMission; a test aid).
		Council(Args, Out);
		return;
	case "request":
		// request [now [id]]: the council's open requests; 'request now [id]': a new one at once (that request if it passes; a
		// test aid).
		Requests(Args, Out);
		return;
	case "report":
		// report: the month's tallies so far and the council's last report (its grade, funding, whether it is still to be
		// seen); 'report show': EW's transmission and report opened again (a test aid).
		Report(Args, Out);
		return;
	case "hive":
		// hive: the Chryssalid hive's state (LWX2ChryssalidHive): its objective, turns, spawns made; 'hive stage <n>': the
		// objectives moved to that one (a test aid: 3 the transponder, as on seeing the whale).
		Hive(Args, Out);
		return;
	case "hit":
		// hit <attacker #id> <target #id> [ability, default StandardShot]: the shot's chance, crit and what made them.
		if (Args.Length < 3)
			Out.AddItem("ERR hit <attacker #id> <target #id> [ability]");
		else
			HitChance(Out, int(Mid(Args[1], InStr(Args[1], "#") == 0 ? 1 : 0)), int(Mid(Args[2], InStr(Args[2], "#") == 0 ? 1 : 0)), Args.Length > 3 ? name(Args[3]) : 'StandardShot');
		return;
	case "dr":
		// Long War's damage reduction: 'dr' each unit's own; 'dr <attacker #id> <target #id> <damage> [melee]' what a hit leaves, and why.
		DamageReduction(Args, Out);
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
	case "secondwave":
		// secondwave: Long War's second-wave options on in this campaign; 'secondwave <n> on|off': one set (a test aid).
		if (Args.Length > 2)
			Out.AddItem(class'LWX2SecondWave'.static.Set(int(Args[1]), Args[2] ~= "on") ? "ok" @ class'LWX2SecondWave'.static.IdOf(int(Args[1])) @ Args[2] : "ERR no option" @ Args[1]);
		Out.AddItem("second wave:" @ class'LWX2SecondWave'.static.Listed());
		return;
	case "furiesboom":
		// furiesboom: a small explosion at Furies' command console (a test aid: the console destroyed, LWX2Furies.ConsoleHit).
		Out.AddItem(FuriesBoom());
		return;
	case "globe":
		// globe <yaw> [lonoffset] [mirrored 0|1] [scale]: Mission Control's hologlobe held at a turn, with markers at 0°/0° (red),
		// 90°E/0° (yellow), 0°/45°N (cyan), 90°W/0° (magenta) and 90°W/45°N (white), for placing EW's flat earth on it (a
		// test aid: LWX2EWBase.GlobeLonOffset).
		Out.AddItem(GlobeTest(Args));
		return;
	case "ew3d":
		// A test aid: each EW screen on the stack, whether it is in the 3D movie and on which panel.
		foreach Pres().ScreenStack.Screens(Scr)
			if (UILWEWScreen(Scr) != none)
				Out.AddItem(Scr.Name @ "3D" @ Scr.bIsIn3D @ "display" @ UILWEWScreen(Scr).EWDisplay @ "on" @ UILWEWScreen(Scr).ShownOn @ "found" @ class'LWX2EWBase'.static.DisplayFor(Pres(), UILWEWScreen(Scr).EWDisplay));
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
	case "sumvar":
		// A test aid: a variable of the soldier summary's movie (in XCOM 2's 3D movie), read or set: sumvar <path> [number].
		Out.AddItem(SummaryVar(Args.Length > 1 ? Args[1] : "", Args.Length > 2 ? Args[2] : ""));
		return;
	case "ewset":
		// A variable inside the open EW movie set: ewset <path below the screen's clip> <true|false|number>.
		Out.AddItem(class'UILWEWScreen'.static.SetVar(Args.Length > 1 ? Args[1] : "", Args.Length > 2 ? Args[2] : ""));
		return;
	case "ewinvoke":
		// A function of the open EW movie called at once, its result printed: ewinvoke <function> [arguments; s:<text> a string, _ for a space].
		Out.AddItem(class'UILWEWScreen'.static.InvokeMovie(Args));
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
	case "fade":
		// The camera's fade (a screen left black): fade [off].
		PC = GetALocalPlayerController();
		Out.AddItem("fading" @ PC.PlayerCamera.bEnableFading @ "amount" @ PC.PlayerCamera.FadeAmount @ "colour" @ PC.PlayerCamera.FadeColor.R $ "," $ PC.PlayerCamera.FadeColor.G $ "," $ PC.PlayerCamera.FadeColor.B @ "cinematic" @ PC.bCinematicMode);
		Out.AddItem("hud" @ (PC.myHUD != none ? string(PC.myHUD.Class.Name) : "none") @ "shown" @ (PC.myHUD != none && PC.myHUD.bShowHUD)
			@ "mouse target" @ (XComHUD(PC.myHUD) != none ? string(XComHUD(PC.myHUD).CachedMouseInteractionInterface) : "-")
			@ (UIDisplay_LevelActor(XComHUD(PC.myHUD).CachedMouseInteractionInterface) != none ? "tag" @ UIDisplay_LevelActor(XComHUD(PC.myHUD).CachedMouseInteractionInterface).Tag @ "at" @ UIDisplay_LevelActor(XComHUD(PC.myHUD).CachedMouseInteractionInterface).Location : "")
			@ "travel processed" @ XComPlayerController(PC).bProcessedTravelDestinationLoaded @ "input state" @ PC.GetStateName()
			@ "cam" @ CamBusy()
			@ "mouse on 2D" @ XComInputBase(PC.PlayerInput).TestMouseConsumedByFlash() @ "on 3D" @ XComInputBase(PC.PlayerInput).TestMouseConsumedBy3DFlash());
		foreach AllActors(class'UIDisplay_LevelActor', Disp)
			Out.AddItem("display" @ Disp.Name @ "tag" @ Disp.Tag @ "hidden" @ Disp.bHidden @ "collide" @ Disp.bCollideActors @ (Disp.StaticMeshComponent != none ? "block" @ Disp.StaticMeshComponent.BlockZeroExtent @ "mesh" @ Disp.StaticMeshComponent.StaticMesh : ""));
		if (Args.Length > 1 && Args[1] == "off")
			PC.ClientSetCameraFade(false);
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
	case "techdone":
		// techdone <Long War tech number>: that tech marked researched at once (a test aid).
		Out.AddItem(TechDone(Args.Length > 1 ? int(Args[1]) : -1));
		return;
	case "psixp":
		// psixp [<soldier index> <psi XP> [<psi rank>]]: the soldiers' psi experience and psi ranks (features/lw-psi.md), or
		// one's psi XP (and psi rank) set (a test aid).
		PsiXP(Args, Out);
		return;
	case "psichance":
		PsiChances(Out, Args.Length > 1 ? name(Args[1]) : '');
		return;
	case "hurt":
		Out.AddItem(Hurt(Args.Length > 1 ? Args[1] : "", Args.Length > 2 ? int(Args[2]) : 1));
		return;
	case "uvadjust":
		// uvadjust <display tag> [x y]: the display material's UVAdjust read, or set (a test aid: the 3D panels' mouse mapping).
		Out.AddItem(UVAdjust(Args.Length > 1 ? name(Args[1]) : '', Args.Length > 3, Args.Length > 3 ? float(Args[2]) : 1.0, Args.Length > 3 ? float(Args[3]) : 1.0));
		return;
	case "ewlook":
		// ewlook <sun scale> <light-map factor> <fog density> [filmic|off]: a mission map's look tuned live against EW's (a
		// test aid; -1 leaves a part as it is; the light-map factor multiplies what the light maps are now).
		if (Args.Length > 4)
			class'LWX2EWMapPieces'.static.SetTonemapper(self, Args[4] ~= "filmic");
		Out.AddItem(class'LWX2EWMapPieces'.static.TuneLook(self, Args.Length > 1 ? float(Args[1]) : -1.0, Args.Length > 2 ? float(Args[2]) : -1.0,
			Args.Length > 3 ? float(Args[3]) : -1.0));
		return;
	case "screencam":
		// screencam <XCOM 2's camera name> <forward> <right> <up>: that camera moved from EW's (a test aid, ScreenCameraShifts).
		if (Args.Length > 4)
			Out.AddItem(class'LWX2EWBase'.static.Get(self).ShiftScreenCamera(name(Args[1]), vect(1, 0, 0) * float(Args[2]) + vect(0, 1, 0) * float(Args[3]) + vect(0, 0, 1) * float(Args[4])));
		else
			Out.AddItem("ERR screencam <camera> <forward> <right> <up>");
		return;
	case "radar":
		// radar: EW's radar's last blips ("type,x,y//…") and turn (a test aid, UILWEWRadar).
		foreach AllActors(class'UILWEWRadar', Radar)
			Out.AddItem("radar shown" @ Radar.bShown @ "turn" @ Radar.LastTurn @ "blips" @ Radar.LastBlips);
		return;
	case "probe":
		// probe <x> <y> [n]: what is drawn under that point of the screen (fractions of its width and height, 0.5 0.5 the
		// centre): the pieces whose bounds the line of sight passes through, nearest first (n, default 8), each with its
		// actor's class, mesh and first materials (and their parents). No collision needed: puddles and decals have none.
		Probe(Out, Args.Length > 2 ? float(Args[1]) : 0.5, Args.Length > 2 ? float(Args[2]) : 0.5, Args.Length > 3 ? int(Args[3]) : 8);
		return;
	case "click3d":
		// A click on what lies under the mouse in the 3D movie (XCOM 2's Steam controller confirm; a test aid).
		Pres().ClickPathUnderMouse3D(true);
		Out.AddItem("clicked under the mouse in 3D");
		return;
	case "closescreen":
		// closescreen <class>: that screen taken off the stack (a test aid: what a screen below does to the one on top).
		Scr = Args.Length > 1 ? Pres().ScreenStack.GetScreen(class<UIScreen>(DynamicLoadObject("LongWarX2." $ Args[1], class'Class', true))) : none;
		if (Scr == none)
			Out.AddItem("ERR no such screen in the stack");
		else
		{
			Pres().ScreenStack.Pop(Scr);
			Out.AddItem("closed" @ Scr.Name);
		}
		return;
	case "remove":
		// remove #<unit>: a unit taken off the field (a test aid: a mind-controlled soldier out of the aliens' aim).
		Out.AddItem(RemoveUnit(Args.Length > 1 ? int(Mid(Args[1], 1)) : 0));
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
	case "env":
		// env [off|on]: XCOM 2's own environment on a mission (its suns, sky lights, height fogs, post-process volumes, not
		// the EW map's): listed, or switched off or on (a test aid, features/ew-lightmaps.md: EW's atmosphere in its place).
		EnvLights(Out, Args.Length > 1 ? (Args[1] $ (Args.Length > 2 ? " " $ Args[2] : "") $ (Args.Length > 3 ? " " $ Args[3] : "")) : "");
		return;
	case "emitters":
		// emitters [filter]: the EW map's own emitters placed now (a test aid): those whose template's path holds filter,
		// "!filter" those that do not.
		// (emitters list: every EW emitter in the world, by template, counted.)
		if (Args.Length > 1 && Args[1] == "list")
		{
			EmitterList(Out);
			return;
		}
		Out.AddItem(class'LWX2EWMapPieces'.static.PlaceEmittersOf(class'LWX2EWMapPieces'.static.Map(), self, vect(0, 0, 0), Placed, Args.Length > 1 ? Args[1] : "") @ "emitters placed");
		return;
	case "grade":
		// grade <shadows> <highlights> <midtones> [desaturation]: the world's default post-process grading set live (a test
		// aid: EW's base's darker blacks); each a grey level, e.g. grade 0.04 1.0 1.0.
		if (Args.Length < 4)
		{
			Out.AddItem("ERR grade <shadows> <highlights> <midtones> [desaturation]");
			return;
		}
		WorldInfo.DefaultPostProcessSettings.bOverride_Scene_Shadows = true;
		WorldInfo.DefaultPostProcessSettings.Scene_Shadows = vect(1, 1, 1) * float(Args[1]);
		WorldInfo.DefaultPostProcessSettings.bOverride_Scene_HighLights = true;
		WorldInfo.DefaultPostProcessSettings.Scene_HighLights = vect(1, 1, 1) * float(Args[2]);
		WorldInfo.DefaultPostProcessSettings.bOverride_Scene_MidTones = true;
		WorldInfo.DefaultPostProcessSettings.Scene_MidTones = vect(1, 1, 1) * float(Args[3]);
		WorldInfo.DefaultPostProcessSettings.bOverride_Scene_Desaturation = Args.Length > 4;
		WorldInfo.DefaultPostProcessSettings.Scene_Desaturation = Args.Length > 4 ? float(Args[4]) : 0.0;
		// (And as the local player's override, which XCOM 2's own debug screen uses: the world's default had no effect.)
		if (LocalPlayer(GetALocalPlayerController().Player) != none)
			LocalPlayer(GetALocalPlayerController().Player).OverridePostProcessSettings(WorldInfo.DefaultPostProcessSettings, 0.0);
		Out.AddItem("ok graded");
		return;
	case "bloom":
		// bloom <scale> <threshold>: the local player's post-process bloom set live, over the current grade (a test aid: EW's
		// lamps' halos are bloom on colours over 1).
		if (Args.Length < 3)
		{
			Out.AddItem("ERR bloom <scale> <threshold>");
			return;
		}
		WorldInfo.DefaultPostProcessSettings.bOverride_EnableBloom = true;
		WorldInfo.DefaultPostProcessSettings.bEnableBloom = true;
		WorldInfo.DefaultPostProcessSettings.bOverride_Bloom_Scale = true;
		WorldInfo.DefaultPostProcessSettings.Bloom_Scale = float(Args[1]);
		WorldInfo.DefaultPostProcessSettings.bOverride_Bloom_Threshold = true;
		WorldInfo.DefaultPostProcessSettings.Bloom_Threshold = float(Args[2]);
		if (LocalPlayer(GetALocalPlayerController().Player) != none)
			LocalPlayer(GetALocalPlayerController().Player).OverridePostProcessSettings(WorldInfo.DefaultPostProcessSettings, 0.0);
		Out.AddItem("ok bloom");
		return;
	case "wall":
		// wall hide|show|alpha <0-100>: the Situation Room's wall screen (its 3D movie) hidden, shown, or its root's alpha
		// set (a test aid: what lies over EW's map plane on the bare wall).
		Out.AddItem(WallScreen(Args.Length > 1 ? Args[1] : "", Args.Length > 2 ? int(Args[2]) : 100));
		return;
	case "yaw":
		// yaw <degrees>: the tactical camera turned as the player's Q/E turn it (X2CameraStack.YawCameras), without keys to
		// the window (bringing the game's window forward to send them left its world black).
		if (XComCamera(GetALocalPlayerController().PlayerCamera) == none || XComCamera(GetALocalPlayerController().PlayerCamera).CameraStack == none)
		{
			Out.AddItem("ERR no tactical camera");
			return;
		}
		XComCamera(GetALocalPlayerController().PlayerCamera).CameraStack.YawCameras(Args.Length > 1 ? float(Args[1]) : 90.0);
		Out.AddItem("ok yawed" @ (Args.Length > 1 ? Args[1] : "90"));
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
	case "aoe":
		// aoe #<unit> <profile>: where that alien's AI would aim the profile's area ability now (XGAIBehavior.FindAoETarget),
		// and each place it tried (targets hit, allies hit).
		if (Args.Length < 3 || Left(Args[1], 1) != "#")
		{
			Out.AddItem("ERR aoe #<unit> <AoE profile>");
			return;
		}
		AoETest(int(Mid(Args[1], 1)), name(Args[2]), Out);
		return;
	case "history":
		// history [n]: the last n abilities used in the mission (default 20), newest last: who, what, on whom.
		History(Out, Args.Length > 1 ? int(Args[1]) : 20);
		return;
	case "anims":
		// anims [n] [all|relink1|relink2|play <name>]: the n-th enemy's (else the nearest's) animation nodes in play: the name asked for, found or not, weight.
		// (n -10, -11 …: squad select's line-up pawns, first, second ….)
		// (Or #<unit id>: that enemy, as spawn reports it.)
		Anims(Out, Args.Length > 1 ? (Left(Args[1], 1) == "#" ? EnemyIndexOf(int(Mid(Args[1], 1))) : int(Args[1])) : -1, Args.Length > 2 && Args[2] == "all", (Args.Length > 2 && Left(Args[2], 6) == "relink") ? int(Mid(Args[2], 6)) : 0, (Args.Length > 3 && Args[2] == "play") ? name(Args[3]) : '');
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
	case "inview":
		// inview [unit]: the unit (by default the one selected) put on a floor tile 6 to 9 tiles from the nearest alien, with a clear line to it (a test aid:
		// a shot by keys in the click tests).
		Out.AddItem(PutInView(Args.Length > 1 ? int(Args[1]) : -1));
		return;
	case "approach":
		// approach <unit> <tile x> <tile y>: the unit walks as far as its move goes along the way there (a test aid: a soldier
		// brought into sight of a pod over turns, for the click tests' shots).
		Out.AddItem(Args.Length > 3 ? ApproachUnit(int(Args[1]), int(Args[2]), int(Args[3])) : "ERR approach <unit> <tile x> <tile y>");
		return;
	case "spawn":
		// spawn [template] [tiles] [Long War species, as the pods tag theirs: its EW body by species] [leader level]
		Out.AddItem(SpawnAlien(Args.Length > 1 ? name(Args[1]) : 'Sectoid', Args.Length > 2 ? int(Args[2]) : 2, Args.Length > 3 ? int(Args[3]) : 0, Args.Length > 4 ? int(Args[4]) : 0));
		return;
	case "use":
		if (Args.Length < 3)
		{
			Out.AddItem("ERR use <soldier name or class part | #unit id> <ability> [target index]");
			return;
		}
		// <ability>:<item template>: the ability of that item (a soldier's grenades each have their ThrowGrenade).
		Out.AddItem(UseAbility(Args[1], name(InStr(Args[2], ":") == INDEX_NONE ? Args[2] : Left(Args[2], InStr(Args[2], ":"))), Args.Length > 3 ? int(Args[3]) : -1, InStr(Args[2], ":") == INDEX_NONE ? '' : name(Mid(Args[2], InStr(Args[2], ":") + 1))));
		return;
	case "mec":
		// mec: the Cybernetics Lab and XCOM's MECs; 'mec augment <unit id>' a soldier in (Long War's rules); 'mec done' the lab's
		// work finished at once (a test aid).
		MECs(Args, Out);
		return;
	case "shiv":
		// shiv: XCOM's SHIVs; 'shiv add [LWSHIV|LWSHIV_Alloy|LWSHIV_Hover] [front]' one built at once (a test aid; front: first
		// in the crew, so the next mission's squad takes it).
		SHIVs(Args, Out);
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
		// The armory's loadout of the first soldier (arm's order), or of a unit ('open loadout #<id>'), as the armory opens it.
		if (Args.Length > 1 && (Args[1] ~= "loadout" || Args[1] ~= "armory"))
		{
			Out.AddItem(OpenLoadout(Args.Length > 2 ? int(Mid(Args[2], 1)) : 0, Args[1] ~= "armory"));
			return;
		}
		// EW's soldier summary or promotion tree of the first soldier, or of a unit ('open summary #<id>'), as the barracks'
		// soldier list opens them.
		// (open psitree [#id]: EW's promotion screen in psi mode, Long War's psi tree, as the Psi Labs open it.)
		// (open soldiers: EW's soldier list, as the barracks' View Soldiers opens it.)
		if (Args.Length > 1 && Args[1] ~= "soldiers")
		{
			class'UILWEWSoldierList'.static.Open(`HQPRES);
			Out.AddItem("ok soldiers");
			return;
		}
		if (Args.Length > 1 && Args[1] ~= "psitree")
		{
			Out.AddItem(OpenEWSoldier(Args.Length > 2 ? int(Mid(Args[2], 1)) : 0, false, true));
			return;
		}
		if (Args.Length > 1 && (Args[1] ~= "summary" || Args[1] ~= "abilities"))
		{
			Out.AddItem(OpenEWSoldier(Args.Length > 2 ? int(Mid(Args[2], 1)) : 0, Args[1] ~= "abilities"));
			return;
		}
		// The promotion screen of the first soldier (arm's order) or of a unit ('open promotion #<id>'), as the armory opens it.
		if (Args.Length > 1 && Args[1] ~= "promotion")
		{
			Out.AddItem(OpenPromotion(Args.Length > 2 ? int(Mid(Args[2], 1)) : 0));
			return;
		}
		// The Long War hub (EW's base and room menu), whether or not it is the strategy layer's root yet.
		if (Args.Length > 1 && Args[1] ~= "hub")
		{
			if (`HQPRES == none)
				Out.AddItem("ERR not on the Avenger");
			else
			{
				class'UILWEWHub'.static.Open(`HQPRES);
				Out.AddItem("ok hub");
			}
			return;
		}
		// A Geoscape screen opened, as its button opens it (a test aid: base, hangar, engineering).
		Geo = OpenGeoscape();
		if (Geo == none)
			Out.AddItem("ERR not on the Avenger");
		else if (Args.Length > 1 && Args[1] ~= "base")
			Geo.OnBase(none);
		// EW's Build Facilities screen (UILWEWBuildFacilities), as the hub's Engineering opens it.
		else if (Args.Length > 1 && Args[1] ~= "build")
			class'UILWEWBuildFacilities'.static.Open(`HQPRES);
		else if (Args.Length > 1 && Args[1] ~= "hangar")
			Geo.OnHangar(none);
		else if (Args.Length > 1 && Args[1] ~= "engineering")
			Geo.OnEngineering(none);
		else if (Args.Length > 1 && Args[1] ~= "foundry")
			Geo.OnFoundry(none);
		else if (Args.Length > 1 && Args[1] ~= "greymarket")
			Geo.OnGreyMarket(none);
		else
			Out.AddItem("ERR open base|hangar|engineering|foundry|greymarket|loadout|hub");
		return;
	}
	// Long War's start screen, before the campaign's Geoscape exists.
	if (Cmd == "start")
	{
		Out.AddItem(StartCampaign(Args.Length > 1 ? int(Args[1]) : -1));
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
	case "bonuses":
		Bonuses(S, Out);
		return;
	case "act":
		Geo = OpenGeoscape();
		if (Geo == none)
			Out.AddItem("ERR not on the Avenger");
		else
		{
			// (Its decisions as they are now: a change made through the control port does not refresh the screen.)
			Geo.Refresh();
			Out.AddItem(Geo.Act(Args.Length > 1 ? int(Args[1]) : 0) ? "ok" : "ERR no such decision");
		}
		return;
	case "officers":
		// officers: the officer projects and posts, and the soldiers' officer ranks; officers buy <0-4>: an officer project
		// bought; officers promote <soldier> [second]: made an officer by Long War's rules; officers set <soldier> <rank>
		// <powers bits>: a test aid, set directly (soldier: an index in XCOM's crew of soldiers).
		Officers(Args, Out);
		return;
	case "rankup":
		// rankup <soldier> [times]: a test aid, the soldier ranked up as a promotion does (soldier: an index in XCOM's crew of
		// soldiers) in one game state; each rank's gains printed as XCOM 2's class data gives them, then the stats once Long War's
		// gains are made (LWX2StatGains).
		// 'rankup rookie [times]': the first rookie; 'rankup new [times]': a new recruit. The soldier's ability tree is printed after.
		RankUp(Args.Length > 1 ? (Args[1] ~= "rookie" ? -1 : (Args[1] ~= "new" ? -2 : int(Args[1]))) : 0, Args.Length > 2 ? int(Args[2]) : 1, Out);
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
		// base remove <x> <y>: the facility there removed by Long War's rules (LWBase.Remove; columns and rows from 1).
		if (Args.Length > 3 && Args[1] ~= "remove")
		{
			Out.AddItem(class'LWBase'.static.Remove(int(Args[2]) - 1, int(Args[3]) - 1, Why) ? "ok removed" : "ERR" @ Why @ "(block" @ class'LWBase'.static.RemoveBlock(S, int(Args[2]) - 1, int(Args[3]) - 1) $ ")");
			S = class'XComGameState_LWStrategy'.static.Get();
			Refreshed();
		}
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
		Out.AddItem("consumables usable: aim" @ class'LWAirWar'.static.ConsumableStock(0) @ "dodge" @ class'LWAirWar'.static.ConsumableStock(1)
			@ "boost" @ class'LWAirWar'.static.ConsumableStock(2));
		return;
	case "jet":
		// A test aid: a jet's status and hours down (and kind: 1 Interceptor, 3 Firestorm), the base's hangar bays placed again:
		// jet <index> <status> <hours> [kind].
		if (Args.Length > 3 && class'LWHangar'.static.TestSetJet(int(Args[1]), int(Args[2]), int(Args[3]), Args.Length > 4 ? int(Args[4]) : 0))
			Out.AddItem("ok");
		else
			Out.AddItem("ERR jet <index> <status> <hours> [kind]");
		class'LWX2EWBase'.static.Get(Pres()).RefreshBays();
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
	if (bFirstMission)
		class'LWX2FirstMissionStart'.static.Expect();
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
function string UVAdjust(name DisplayTag, bool bSet, float X, float Y)
{
	local UIDisplay_LevelActor D;
	local MaterialInstanceConstant M;
	local LinearColor C;
	local string Result;

	foreach AllActors(class'UIDisplay_LevelActor', D)
	{
		if (D.Tag != DisplayTag || D.StaticMeshComponent == none)
			continue;
		M = MaterialInstanceConstant(D.StaticMeshComponent.GetMaterial(0));
		if (M == none)
		{
			Result @= string(D.Name) @ "no instance;";
			continue;
		}
		M.GetVectorParameterValue('UVAdjust', C);
		Result @= string(D.Name) @ "UVAdjust" @ C.R @ C.G @ C.B @ C.A @ "scale" @ D.DrawScale @ D.DrawScale3D @ "rot" @ D.Rotation @ "parent" @ M.Parent;
		if (bSet)
		{
			C.R = X;
			C.G = Y;
			M.SetVectorParameterValue('UVAdjust', C);
			Result @= "set";
		}
		Result $= ";";
	}
	return Result != "" ? Result : "ERR no display" @ DisplayTag;
}

/** The HQ camera's state as XCOM 2's input sees it (XComHeadquartersInput.LMouse drops clicks while it is busy). */
function string CamBusy()
{
	local XComHQPresentationLayer HQ;

	HQ = XComHQPresentationLayer(XComPlayerController(GetALocalPlayerController()).Pres);
	if (HQ == none || HQ.m_kCamera == none)
		return "-";
	return "busy" @ HQ.CAMIsBusy() @ "state" @ HQ.m_kCamera.GetStateName();
}

function string GameState()
{
	local string Phase, Screen, Mission;
	local bool bMovie, bReady, bBusy;
	local XComGameState_Player Player;
	local XComGameState_Unit Active;
	local int XComAP;
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
			@ "ended=" $ int(`TACTICALRULES.HasTacticalGameEnded()) @ "round=" $ (Player != none ? Player.PlayerTurnCount : 0);
		// The unit selected and its action points (the click tests: a move or a shot taken).
		Active = XComTacticalController(GetALocalPlayerController()) != none ? XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComTacticalController(GetALocalPlayerController()).GetActiveUnitStateRef().ObjectID)) : none;
		if (Active != none)
			Mission @= "selected_ap=" $ Active.ActionPoints.Length;
		// XCOM's action points left this turn, all its units (a shot taken shows here: XCOM 2 selects the next unit after it).
		XComAP = 0;
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Active)
			if (Active.GetTeam() == eTeam_XCom && Active.IsAlive() && !Active.bRemovedFromPlay)
				XComAP += Active.ActionPoints.Length;
		Mission @= "xcom_ap=" $ XComAP;
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
	{
		// (What the Skyranger's "press any key" does, XComInputBase: the drop ship's end and the fade into the mission. Only
		// the flag set, the mission's next key press did the rest later, and its fade to black never lifted: the world black
		// under the HUD in tests.)
		if (XComPlayerController(GetALocalPlayerController()) != none && !XComPlayerController(GetALocalPlayerController()).bProcessedTravelDestinationLoaded
			&& XComPlayerController(GetALocalPlayerController()).bSeamlessTravelDestinationLoaded)
		{
			XComPlayerController(GetALocalPlayerController()).CleanupDropshipStart();
			GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.5);
		}
		WorldInfo.bContinueToSeamlessTravelDestination = true; // what the Skyranger's "press any key" sets (X2TacticalGameRuleset waits on it)
	}
	else if (UILWEWDebrief(Top) != none)
		UILWEWDebrief(Top).GoOn();
	else if (UIAfterAction(Top) != none)
		UIAfterAction(Top).OnContinue();
	else if (UILWStartSelect(Top) != none)
		UILWStartSelect(Top).Accept(); // the option selected (the first, unless one was picked)
	else if (UILWSquadSelect(Top) != none)
		UILWSquadSelect(Top).OnLaunchMission(none); // the squad as it stands (squad select fills it with the first able to go)
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
	Out.AddItem("interceptor" @ class'LWStrategyRules'.static.Money(class'LWBonusEffects'.static.AirCost(class'LWBaseRules'.default.InterceptorCost)) @ "upkeep" @ class'LWStrategyRules'.static.Money(class'LWHangar'.static.Upkeep()) $ "/month");
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
		class'LWBonusEffects'.static.AdjustFacility(F);
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
	local X2WeaponTemplate Frag;

	Ids = class'LWEngineering'.static.FoundryAvailable();
	foreach Ids(Id)
		Out.AddItem("project" @ Id @ class'LWEngineering'.static.FoundryLine(Id, S));
	foreach S.FoundryProjects(P)
		Out.AddItem("under_way" @ P.Item @ "work" @ P.WorkLeft @ "engineers" @ P.Engineers @ "hours" @ class'LWEngineering'.static.HoursFor(P.WorkLeft, P.Engineers, S.Engineers));
	foreach S.FoundryDone(Id)
		Done @= string(Id);
	Out.AddItem("done" $ Done);
	Frag = X2WeaponTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name("LWSmall_" $ class'LWX2Gear'.default.FragGrenade)));
	Out.AddItem("perks (a Foundry in the base):" @ (S.TileFacility.Length == 0 || class'LWBase'.static.Count(S, 11) > 0) @ "| Shaped Armor" @ class'X2Effect_LWFoundry'.static.Perk(22)
		@ "| frag grenade radius" @ (Frag != none ? string(Frag.iRadius) : "?") @ "m");
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
function string OpenLoadout(optional int UnitID, optional bool bMenu)
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
		if (Unit == none || !Unit.IsSoldier() || (UnitID != 0 && Unit.ObjectID != UnitID))
			continue;
		if (bMenu)
			HQPres.UIArmory_MainMenu(Ref);
		else
			HQPres.UIArmory_Loadout(Ref);
		return "ok" @ Unit.GetFullName() $ (bMenu ? "'s armory" : "'s loadout");
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
	local XComGameState_Item Item, Held;
	local array<XComGameState_Item> Utility;
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
	// (A full utility slot, a rookie's starting kit: its first item that takes room taken out, as a player swaps it; not the
	// XPad, which takes none: removed, the slot stayed full and the give failed on a release campaign's rookies.)
	if (Slot == eInvSlot_Utility && !Unit.CanAddItemToInventory(Template, Slot, NewGameState))
		Utility = Unit.GetAllItemsInSlot(Slot, NewGameState);
	foreach Utility(Held)
		if (X2EquipmentTemplate(Held.GetMyTemplate()) != none && X2EquipmentTemplate(Held.GetMyTemplate()).iItemSize > 0)
		{
			Unit.RemoveItemFromInventory(XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Held.ObjectID)), NewGameState);
			break;
		}
	if (!Unit.AddItemToInventory(Item, Slot, NewGameState))
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		return "ERR the slot takes no more";
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return "ok" @ Unit.GetFullName() @ "carries" @ ItemName @ "in" @ Slot;
}

function CustPawn(out array<string> Out)
{
	local UICustomize C;
	local PointInSpace P;
	local Actor A;
	local int i;

	for (i = 0; i < `SCREENSTACK.Screens.Length; i++)
		if (UICustomize(`SCREENSTACK.Screens[i]) != none)
			C = UICustomize(`SCREENSTACK.Screens[i]);
	if (C != none && C.CustomizeManager != none)
	{
		A = C.CustomizeManager.ActorPawn;
		Out.AddItem("customize pawn" @ (A != none ? A.Name @ "at" @ A.Location @ "hidden" @ A.bHidden : "none") @ "unit" @ C.CustomizeManager.UpdatedUnitState.GetFullName());
	}
	else
		Out.AddItem("no customize screen");
	foreach AllActors(class'PointInSpace', P)
		if (P.Tag == 'UIPawnLocation_Armory')
			Out.AddItem(PathName(P) @ "at" @ P.Location @ "static" @ P.bStatic @ "movable" @ P.bMovable);
}

function int ShadowCopies(float MinZ)
{
	local XComLevelActor A;
	local LWX2ShadowPiece P;
	local int n;

	foreach AllActors(class'XComLevelActor', A)
	{
		if (A.StaticMeshComponent == none || A.StaticMeshComponent.StaticMesh == none || A.Location.Z < MinZ)
			continue;
		P = Spawn(class'LWX2ShadowPiece', , , A.Location, A.Rotation);
		if (P == none)
			continue;
		P.StaticMeshComponent.SetStaticMesh(A.StaticMeshComponent.StaticMesh);
		P.SetDrawScale3D(A.DrawScale3D);
		P.SetDrawScale(A.DrawScale);
		n++;
	}
	return n;
}

function int Reattach()
{
	local Actor A;
	local StaticMeshComponent C;
	local int n;

	foreach AllActors(class'Actor', A)
		foreach A.AllOwnedComponents(class'StaticMeshComponent', C)
		{
			A.ReattachComponent(C);
			n++;
		}
	return n;
}

function string MicSet(array<string> Args)
{
	local Actor A;
	local StaticMeshComponent C;
	local MaterialInstanceConstant MIC;
	local array<MaterialInstanceConstant> Seen;
	local Texture T;
	local LinearColor V;
	local int k, n;
	local bool bGlass;

	if (Args.Length > 1 && Args[1] == "glass")
	{
		bGlass = true;
		Args.Remove(1, 1);
	}
	if (Args.Length < 3 || (Args.Length < 4 && Args[1] != "parent"))
		return "ERR micset tex|scalar|vector <name> <value…> | parent <material>";
	if (Args[1] == "tex")
	{
		T = Texture(DynamicLoadObject(Args[3], class'Texture', true));
		if (T == none)
			return "ERR no texture" @ Args[3];
	}
	if (Args[1] == "vector")
	{
		if (Args.Length < 7)
			return "ERR micset vector <name> <r> <g> <b> <a>";
		V.R = float(Args[3]); V.G = float(Args[4]); V.B = float(Args[5]); V.A = float(Args[6]);
	}
	foreach AllActors(class'Actor', A)
		foreach A.AllOwnedComponents(class'StaticMeshComponent', C)
			for (k = 0; k < C.GetNumElements(); k++)
			{
				MIC = MaterialInstanceConstant(C.GetMaterial(k));
				// ('micset glass …': the plot's glass panes instead, LWX2Glass_*.)
				if (MIC == none || MIC.Parent == none || Seen.Find(MIC) != INDEX_NONE)
					continue;
				if (bGlass != (InStr(string(MIC.Name), "LWX2Glass") == 0) || (!bGlass && InStr(PathName(MIC.Parent), "LWX2Lightmap.") == INDEX_NONE))
					continue;
				Seen.AddItem(MIC);
				if (Args[1] == "parent")
					MIC.SetParent(MaterialInterface(DynamicLoadObject(Args[2], class'MaterialInterface', true)));
				else if (Args[1] == "tex")
					MIC.SetTextureParameterValue(name(Args[2]), T);
				else if (Args[1] == "scalar")
					MIC.SetScalarParameterValue(name(Args[2]), float(Args[3]));
				else
					MIC.SetVectorParameterValue(name(Args[2]), V);
				n++;
			}
	return "ok" @ n @ "materials";
}

function LMCheck(out array<string> Out)
{
	local Actor A;
	local StaticMeshComponent C;
	local MaterialInstanceConstant MIC;
	local Texture T, D;
	local float V, G;
	local int k, n, j;
	local array<string> Parents;
	local array<int> Counts;
	local string Parent;

	foreach AllActors(class'Actor', A)
		foreach A.AllOwnedComponents(class'StaticMeshComponent', C)
			for (k = 0; k < C.GetNumElements(); k++)
			{
				// (Every material counted by its parent.)
				Parent = PathName(C.GetMaterial(k));
				if (MaterialInstance(C.GetMaterial(k)) != none && MaterialInstance(C.GetMaterial(k)).Parent != none)
					Parent = PathName(MaterialInstance(C.GetMaterial(k)).Parent);
				j = Parents.Find(Parent);
				if (j == INDEX_NONE)
				{
					Parents.AddItem(Parent);
					Counts.AddItem(0);
					j = Parents.Length - 1;
				}
				Counts[j]++;
				if (n >= 6)
					continue;
				MIC = MaterialInstanceConstant(C.GetMaterial(k));
				if (MIC == none || MIC.Parent == none || InStr(PathName(MIC.Parent), "Lightmapped") == INDEX_NONE)
					continue;
				T = none; D = none; V = -1; G = -1;
				MIC.GetTextureParameterValue('LightMap', T);
				MIC.GetTextureParameterValue('LightMapDir', D);
				MIC.GetScalarParameterValue('LMBrightness', V);
				MIC.GetScalarParameterValue('LMGamma', G);
				Out.AddItem(PathName(C.StaticMesh) @ "<" $ PathName(MIC.Parent) @ "LM=" $ PathName(T) $ (Texture2D(T) != none ? "(" $ Texture2D(T).SizeX $ ")" : "") @ "Dir=" $ PathName(D) @ "x" $ V @ "gamma" @ G);
				n++;
			}
	for (j = 0; j < Parents.Length; j++)
		if (Counts[j] >= 20)
			Out.AddItem(Counts[j] @ Parents[j]);
}

function Windows(out array<string> Out)
{
	local XComLevelActor A;
	local XComGameState_Unit Unit;
	local array<TTile> Path;
	local TTile T1, T2;
	local vector L, Axis, P1, P2;
	local int n, k;
	local string Line;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_XCom && Unit.IsSoldier() && !Unit.bRemovedFromPlay)
			break;
	foreach AllActors(class'XComLevelActor', A)
	{
		if (!A.VisibilityBlockingData.bIsWindow)
			continue;
		n++;
		if (n > 12)
			continue;
		L = A.Location;
		Line = "window" @ int(L.X) $ "," $ int(L.Y) $ "," $ int(L.Z);
		if (A.StaticMeshComponent != none)
		{
			Line @= string(A.StaticMeshComponent.StaticMesh.Name) @ "hidden" @ A.bHidden $ "/" $ A.StaticMeshComponent.HiddenGame;
			if (A.StaticMeshComponent.GetMaterial(0) != none)
				Line @= "mat0" @ A.StaticMeshComponent.GetMaterial(0).Name;
			if (A.StaticMeshComponent.GetNumElements() > 1 && A.StaticMeshComponent.GetMaterial(1) != none)
				Line @= "mat1" @ A.StaticMeshComponent.GetMaterial(1).Name;
		}
		Line $= ":";
		for (k = 0; k < 2; k++)
		{
			Axis = k == 0 ? vect(1, 0, 0) : vect(0, 1, 0);
			P1 = L + Axis * 60 + vect(0, 0, 40);
			P2 = L - Axis * 60 + vect(0, 0, 40);
			T1 = `XWORLD.GetTileCoordinatesFromPosition(P1);
			T2 = `XWORLD.GetTileCoordinatesFromPosition(P2);
			Path.Length = 0;
			Line @= (k == 0 ? "x" : "y") $ ":" $ (class'X2PathSolver'.static.BuildPath(Unit, T1, T2, Path, false) ? string(Path.Length) : "none")
				$ "(" $ T1.X $ "," $ T1.Y $ "," $ T1.Z $ "-" $ T2.X $ "," $ T2.Y $ "," $ T2.Z $ ")";
		}
		Out.AddItem(Line);
	}
	Out.AddItem(n @ "windows");
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

function UnitAbilities(int UnitID, out array<string> Out)
{
	local XComGameState_Unit Unit;
	local XComGameState_Ability Ability;
	local StateObjectReference Ref;
	local AvailableAction Action;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (Unit == none)
	{
		Out.AddItem("ERR no unit #" $ UnitID);
		return;
	}
	Out.AddItem(Unit.GetMyTemplateName() @ "behavior" @ Unit.GetMyTemplate().strBehaviorTree @ "ap" @ Unit.ActionPoints.Length);
	foreach Unit.Abilities(Ref)
	{
		Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Ability == none)
			continue;
		Action.AbilityObjectRef = Ref;
		Ability.UpdateAbilityAvailability(Action);
		Out.AddItem("  " $ Ability.GetMyTemplateName() @ Action.AvailableCode @ "targets" @ Action.AvailableTargets.Length);
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
		// (Allies too for an ability aimed at them, as Command.)
		if (Enemy.bRemovedFromPlay || Enemy.ObjectID == Source.ObjectID || (Enemy.GetTeam() == eTeam_XCom && Ability.GetMyTemplate().Hostility == eHostility_Offensive))
			continue;
		Out @= (Enemy.GetTeam() == eTeam_XCom ? Enemy.GetFullName() : string(Enemy.GetMyTemplateName())) $ ":";
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
/** A test aid (wall): the wall's screen hidden, shown or faded. */
function string WallScreen(string Mode, int Alpha)
{
	local UILWEWSituationRoom W;

	W = UILWEWSituationRoom(Pres().ScreenStack.GetScreen(class'UILWEWSituationRoom'));
	if (W == none)
		return "ERR no wall screen";
	if (Mode == "hide")
		W.Hide();
	else if (Mode == "show")
		W.Show();
	else if (Mode == "alpha")
		W.MC.SetNum("_alpha", Alpha);
	return "ok wall" @ Mode @ "bWall" @ W.bWall @ "visible" @ W.bIsVisible;
}

/** The spawned emitters in the world (EW's, placed by the mod), by template, counted (emitters list). */
function EmitterList(out array<string> Out)
{
	local EmitterSpawnable E;
	local array<string> Names;
	local array<int> Counts;
	local string T;
	local int i;

	foreach AllActors(class'EmitterSpawnable', E)
	{
		T = E.ParticleSystemComponent != none ? PathName(E.ParticleSystemComponent.Template) : "none";
		T $= " tag " $ E.Tag;
		i = Names.Find(T);
		if (i == INDEX_NONE)
		{
			Names.AddItem(T);
			Counts.AddItem(1);
		}
		else
			Counts[i]++;
	}
	for (i = 0; i < Names.Length; i++)
		Out.AddItem(Counts[i] @ Names[i]);
}

/** XCOM 2's environment lighting on a mission (env): the lights, fogs and post-process volumes not of the EW map. */
function EnvLights(out array<string> Out, string Mode)
{
	local Light L;
	local Actor A;
	local PostProcessVolume V;
	local X2EnvMapCaptureActor Cap;

	foreach AllActors(class'Light', L)
	{
		if (DirectionalLight(L) == none && SkyLight(L) == none)
			continue;
		if (L.LightComponent != none && (Mode == "on" || Mode == "off"))
			L.LightComponent.SetEnabled(Mode == "on" || LWX2SunLight(L) != none || LWX2SkyLight(L) != none);
		Out.AddItem(PathName(L) @ L.Class.Name @ (L.LightComponent != none ? ("brightness" @ L.LightComponent.Brightness @ "colour" @ L.LightComponent.LightColor.R $ "," $ L.LightComponent.LightColor.G $ "," $ L.LightComponent.LightColor.B @ "on" @ L.LightComponent.bEnabled) : "no component"));
	}
	foreach AllActors(class'Actor', A)
	{
		if (ExponentialHeightFog(A) != none && ExponentialHeightFog(A).Component != none)
		{
			if (Mode == "on" || Mode == "off")
				ExponentialHeightFog(A).Component.SetEnabled(Mode == "on");
			Out.AddItem(PathName(A) @ "exponential height fog density" @ ExponentialHeightFog(A).Component.FogDensity @ "on" @ ExponentialHeightFog(A).Component.bEnabled);
		}
		if (HeightFog(A) != none && HeightFog(A).Component != none)
		{
			if (Mode == "on" || Mode == "off")
				HeightFog(A).Component.SetEnabled(Mode == "on");
			Out.AddItem(PathName(A) @ "height fog density" @ HeightFog(A).Component.Density @ "on" @ HeightFog(A).Component.bEnabled);
		}
	}
	// (env ambient <diffuse> [specular]: XCOM 2's environment map's light on lit surfaces, its sky's blue among it.)
	if (Left(Mode, 8) == "ambient ")
	{
		foreach AllActors(class'X2EnvMapCaptureActor', Cap)
		{
			if (Cap.EnvMapSceneCapture == none)
				continue;
			Cap.EnvMapSceneCapture.fDiffuseIntensity = float(Split(Mode, " ", true));
			if (InStr(Split(Mode, " ", true), " ") != INDEX_NONE)
			{
				Cap.EnvMapSceneCapture.fDiffuseIntensity = float(Left(Split(Mode, " ", true), InStr(Split(Mode, " ", true), " ")));
				Cap.EnvMapSceneCapture.fSpecularIntensity = float(Split(Split(Mode, " ", true), " ", true));
			}
			Cap.ReattachComponent(Cap.EnvMapSceneCapture);
			Out.AddItem(PathName(Cap) @ "diffuse" @ Cap.EnvMapSceneCapture.fDiffuseIntensity @ "specular" @ Cap.EnvMapSceneCapture.fSpecularIntensity @ "world ambient" @ Cap.EnvMapSceneCapture.bUseAsWorldAmbient);
		}
		return;
	}
	// (env sky off|on: the environment level's own meshes, its sky dome, hidden or shown.)
	if (Left(Mode, 4) == "sky ")
	{
		foreach AllActors(class'Actor', A)
			if (XComLevelActor(A) != none && InStr(PathName(A), "EnvLighting") != INDEX_NONE)
			{
				A.SetHidden(Mode == "sky off");
				Out.AddItem(PathName(A) @ "hidden" @ A.bHidden @ (XComLevelActor(A).StaticMeshComponent != none ? PathName(XComLevelActor(A).StaticMeshComponent.StaticMesh) : ""));
			}
		return;
	}
	// (env all: every actor of XCOM 2's environment levels, by class, counted.)
	if (Mode == "all")
	{
		foreach AllActors(class'Actor', A)
			if (InStr(PathName(A), "EnvLighting") != INDEX_NONE || InStr(PathName(A), "Env_") != INDEX_NONE)
				Out.AddItem(PathName(A) @ A.Class.Name);
		return;
	}
	foreach AllActors(class'PostProcessVolume', V)
	{
		if (Mode == "on" || Mode == "off")
			V.bEnabled = Mode == "on";
		Out.AddItem(PathName(V) @ "post-process volume priority" @ V.Priority @ "on" @ V.bEnabled @ "colorize" @ V.Settings.Scene_Colorize);
	}
}

/** The probe aid: the line of sight through a point of the screen, and the static meshes' bounds it passes through. */
function Probe(out array<string> Out, float SX, float SY, int Most)
{
	local Texture ProbeTex;
	local float ProbeV;
	local LocalPlayer LP;
	local vector2D At;
	local vector Origin, Dir, Lo, Hi;
	local Actor A;
	local StaticMeshComponent C;
	local array<float> Dists;
	local array<string> Lines;
	local float TNear, TFar, T1, T2, Tmp;
	local int k, i, Axis;
	local string Line;
	local MaterialInterface M;

	LP = LocalPlayer(GetALocalPlayerController().Player);
	if (LP == none)
	{
		Out.AddItem("ERR no local player");
		return;
	}
	At.X = SX;
	At.Y = SY;
	LP.DeProject(At, Origin, Dir);
	foreach AllActors(class'Actor', A)
	{
		if (A.bHidden)
			continue;
		foreach A.AllOwnedComponents(class'StaticMeshComponent', C)
		{
			if (C.StaticMesh == none || C.HiddenGame || !C.bAttached)
				continue;
			// (The line against the bounds' box, slab by slab.)
			Lo = C.Bounds.Origin - C.Bounds.BoxExtent;
			Hi = C.Bounds.Origin + C.Bounds.BoxExtent;
			TNear = 0.0;
			TFar = 1000000.0;
			for (Axis = 0; Axis < 3 && TNear <= TFar; Axis++)
			{
				if (Abs(Axis == 0 ? Dir.X : Axis == 1 ? Dir.Y : Dir.Z) < 0.000001)
				{
					Tmp = Axis == 0 ? Origin.X : Axis == 1 ? Origin.Y : Origin.Z;
					if (Tmp < (Axis == 0 ? Lo.X : Axis == 1 ? Lo.Y : Lo.Z) || Tmp > (Axis == 0 ? Hi.X : Axis == 1 ? Hi.Y : Hi.Z))
						TNear = TFar + 1;
					continue;
				}
				T1 = ((Axis == 0 ? Lo.X : Axis == 1 ? Lo.Y : Lo.Z) - (Axis == 0 ? Origin.X : Axis == 1 ? Origin.Y : Origin.Z)) / (Axis == 0 ? Dir.X : Axis == 1 ? Dir.Y : Dir.Z);
				T2 = ((Axis == 0 ? Hi.X : Axis == 1 ? Hi.Y : Hi.Z) - (Axis == 0 ? Origin.X : Axis == 1 ? Origin.Y : Origin.Z)) / (Axis == 0 ? Dir.X : Axis == 1 ? Dir.Y : Dir.Z);
				if (T1 > T2)
				{
					Tmp = T1; T1 = T2; T2 = Tmp;
				}
				TNear = FMax(TNear, T1);
				TFar = FMin(TFar, T2);
			}
			if (TNear > TFar)
				continue;
			Line = int(TNear) @ A.Class.Name @ PathName(C.StaticMesh);
			for (k = 0; k < Min(2, C.GetNumElements()); k++)
			{
				M = C.GetMaterial(k);
				Line @= "[" $ k $ "]" $ PathName(M);
				if (MaterialInstance(M) != none && MaterialInstance(M).Parent != none)
					Line @= "<" $ PathName(MaterialInstance(M).Parent);
				// (And a light-mapped one's light map, as the shader gets it: its texture and brightness.)
				if (MaterialInstanceConstant(M) != none && MaterialInstanceConstant(M).GetTextureParameterValue('LightMap', ProbeTex))
					Line @= "LM=" $ PathName(ProbeTex) $ (MaterialInstanceConstant(M).GetScalarParameterValue('LMBrightness', ProbeV) ? "x" $ ProbeV : "");
			}
			// (Kept sorted by distance.)
			for (i = 0; i < Dists.Length && Dists[i] <= TNear; i++);
			Dists.InsertItem(i, TNear);
			Lines.InsertItem(i, Line);
		}
	}
	Out.AddItem("probe" @ SX @ SY $ ":" @ Lines.Length @ "pieces on the line of sight, from" @ Origin);
	for (i = 0; i < Min(Most, Lines.Length); i++)
		Out.AddItem(Lines[i]);
}

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
	// Fog of war off, so the place is seen (never seen ground is drawn black); 'fow' as the last word keeps it (what the
	// soldiers see).
	if (Args[Args.Length - 1] != "fow")
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
	return "dropped" @ CharacterTemplate @ Tiles @ "tiles from" @ Unit.GetFullName() @ (Species > 0 ? "as species" @ Species @ "leader level" @ LeaderLevel : "")
		@ (Newest != none ? "#" $ Newest.ObjectID : "");
}

/** The index anims counts an enemy by (the living, visualized, non-XCOM units in history order), from its unit id; -1 none. */
function int EnemyIndexOf(int ObjectID)
{
	local XComGameState_Unit Unit;
	local int n;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() == eTeam_XCom || !Unit.IsAlive() || Unit.bRemovedFromPlay || XGUnit(Unit.GetVisualizer()) == none)
			continue;
		if (Unit.ObjectID == ObjectID)
			return n;
		n++;
	}
	return -1;
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
function ArmoryPawn(out array<string> Out)
{
	local UIArmory Armory;
	local XComGameState_Unit Unit;
	local Actor A, Place;
	local int i;

	for (i = 0; i < `SCREENSTACK.Screens.Length; i++)
		if (UIArmory(`SCREENSTACK.Screens[i]) != none)
		{
			Armory = UIArmory(`SCREENSTACK.Screens[i]);
			break;
		}
	if (Armory == none)
	{
		Out.AddItem("ERR no armory screen");
		return;
	}
	A = Armory.ActorPawn;
	Place = Armory.GetPlacementActor();
	Out.AddItem(Armory.Class.Name @ "pawn" @ (A != none ? A.Name @ "at" @ A.Location @ "hidden" @ A.bHidden : "none")
		@ "placement" @ Armory.PawnLocationTag @ (Place != none ? string(Place.Location) : "none"));
	// (Its look: the unit's armour and the body parts it wears, and whether it wears its underlay.)
	Unit = Armory.GetUnit();
	if (Unit != none)
		Out.AddItem("armour" @ (Unit.GetItemInSlot(eInvSlot_Armor) != none ? string(Unit.GetItemInSlot(eInvSlot_Armor).GetMyTemplateName()) : "none")
			@ "torso" @ Unit.kAppearance.nmTorso @ "arms" @ Unit.kAppearance.nmArms @ "legs" @ Unit.kAppearance.nmLegs
			@ "underlay" @ (XComHumanPawn(A) != none ? string(XComHumanPawn(A).bShouldUseUnderlay) : "-")
			@ "pawn torso" @ (XComHumanPawn(A) != none ? string(XComHumanPawn(A).m_kAppearance.nmTorso) : "-"));
}

function UI3D(name Tag, bool bShow, out array<string> Out)
{
	local UIDisplay_LevelActor Display;
	local XComBlueprint Blueprint;
	local array<Actor> Actors;
	local Actor A;

	foreach `XWORLDINFO.AllActors(class'UIDisplay_LevelActor', Display)
		if (Tag == '' || Display.Tag == Tag)
			Out.AddItem("display" @ Display.Name @ "tag" @ Display.Tag @ "hidden" @ Display.StaticMeshComponent.HiddenGame @ "level" @ Display.GetPackageName() @ "at" @ Display.Location
				@ "mesh" @ PathName(Display.StaticMeshComponent.StaticMesh) @ "material" @ PathName(Display.StaticMeshComponent.GetMaterial(0))
				@ (MaterialInstance(Display.StaticMeshComponent.GetMaterial(0)) != none ? "parent" @ PathName(MaterialInstance(Display.StaticMeshComponent.GetMaterial(0)).Parent) : "")
				@ "scale" @ Display.DrawScale3D * Display.DrawScale);
	foreach `XWORLDINFO.AllActors(class'XComBlueprint', Blueprint)
	{
		if (Tag != '' && Blueprint.Tag != Tag)
			continue;
		Actors.Length = 0;
		Blueprint.GetLoadedLevelActors(Actors);
		Out.AddItem("blueprint" @ Blueprint.Name @ "tag" @ Blueprint.Tag @ Actors.Length @ "actors at" @ Blueprint.Location
			@ "its level" @ (Blueprint.StreamingLevel != none ? Blueprint.StreamingLevel.PackageName @ "visible" @ Blueprint.StreamingLevel.bShouldBeVisible
				@ "in world list" @ (`XWORLDINFO.StreamingLevels.Find(Blueprint.StreamingLevel) != INDEX_NONE) : "none"));
		foreach Actors(A)
			if (UIDisplay_LevelActor(A) != none)
				Out.AddItem("  its display" @ A.Name @ "hidden" @ UIDisplay_LevelActor(A).StaticMeshComponent.HiddenGame @ "actor hidden" @ A.bHidden
					@ "attached" @ UIDisplay_LevelActor(A).StaticMeshComponent.bAttached @ "at" @ A.Location @ "level" @ A.GetPackageName()
					@ "material" @ UIDisplay_LevelActor(A).StaticMeshComponent.GetMaterial(0));
	}
	if (`HQPRES != none)
		Out.AddItem("3D movie inited" @ `HQPRES.Get3DMovie().bIsInited @ "visible" @ `HQPRES.Get3DMovie().bIsVisible
			@ "screens on it:" @ `HQPRES.ScreenStack.GetCurrentScreen().Movie == `HQPRES.Get3DMovie());
	if (bShow && `HQPRES != none)
	{
		`HQPRES.Get3DMovie().Show();
		`HQPRES.Get3DMovie().ShowDisplay(Tag);
		Out.AddItem("shown" @ Tag);
	}
}

function MECs(array<string> Args, out array<string> Out)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local XComGameState_Item Weapon, Suit;
	local string Why;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	// 'mec make': the first soldier who may be augmented made a MEC at once, first in the next squad (a test aid).
	if (Args.Length > 1 && Args[1] == "make")
	{
		foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
			if (class'LWMECs'.static.CanAugment(S, Unit, Why))
				break;
			Unit = none;
		}
		if (Unit == none)
		{
			Out.AddItem("ERR nobody can be augmented (" $ Why $ ")");
			return;
		}
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: a MEC made");
		S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
		Unit = class'LWMECs'.static.AugmentDone(NewGameState, S, Unit.ObjectID);
		if (Unit != none)
		{
			Unit.SetUnitFloatValue('LWX2TestFirst', 1, eCleanup_Never);
			// ('mec make <item>': that item, a subsystem, in its utility slot; a suit in place of the first.)
			if (Args.Length > 2 && X2ArmorTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name(Args[2]))) != none)
			{
				Suit = Unit.GetItemInSlot(eInvSlot_Armor, NewGameState);
				if (Suit != none)
					Unit.RemoveItemFromInventory(XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Suit.ObjectID)), NewGameState);
				Unit.AddItemToInventory(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name(Args[2])).CreateInstanceFromTemplate(NewGameState), eInvSlot_Armor, NewGameState);
			}
			else if (Args.Length > 2 && class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name(Args[2])) != none)
				Unit.AddItemToInventory(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name(Args[2])).CreateInstanceFromTemplate(NewGameState), eInvSlot_Utility, NewGameState);
		}
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		S = class'XComGameState_LWStrategy'.static.Get();
	}
	if (Args.Length > 2 && Args[1] == "augment")
	{
		Out.AddItem(class'LWMECs'.static.StartAugment(int(Mid(Args[2], InStr(Args[2], "#") == 0 ? 1 : 0)), Why) ? "ok" : "ERR needs" @ Why);
		S = class'XComGameState_LWStrategy'.static.Get();
	}
	if (Args.Length > 1 && Args[1] == "done")
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: augmentation done");
		S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
		for (i = S.MECPatients.Length - 1; i >= 0; i--)
		{
			class'LWMECs'.static.AugmentDone(NewGameState, S, S.MECPatients[i].Unit);
			S.MECPatients.Remove(i, 1);
		}
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	Out.AddItem("Cybernetics Lab:" @ class'LWBase'.static.Count(S, 22) @ "built," @ S.MECPatients.Length @ "in it");
	for (i = 0; i < S.MECPatients.Length; i++)
		Out.AddItem("  lab: #" $ S.MECPatients[i].Unit @ XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.MECPatients[i].Unit)).GetFullName() @ S.MECPatients[i].HoursLeft @ "hours left");
	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		if (class'LWMECs'.static.IsMEC(Unit))
		{
			Weapon = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon);
			Suit = Unit.GetItemInSlot(eInvSlot_Armor);
			Out.AddItem("MEC #" $ Unit.ObjectID @ Unit.GetFullName() @ Unit.GetSoldierClassTemplateName() @ "rank" @ Unit.GetRank() @ "hp" @ int(Unit.GetMaxStat(eStat_HP))
				@ "aim" @ int(Unit.GetMaxStat(eStat_Offense)) @ "mob" @ int(Unit.GetMaxStat(eStat_Mobility)) @ "will" @ int(Unit.GetMaxStat(eStat_Will))
				@ "kills" @ Unit.GetNumKills() @ "missions" @ Unit.GetNumMissions() @ "suit" @ (Suit != none ? string(Suit.GetMyTemplateName()) : "none")
				@ "weapon" @ (Weapon != none ? string(Weapon.GetMyTemplateName()) : "none") @ "ready" @ Unit.CanGoOnMission());
		}
		else if (Args.Length < 2 || Args[1] == "can")
		{
			class'LWMECs'.static.CanAugment(S, Unit, Why);
			if (Args.Length > 1)
				Out.AddItem("#" $ Unit.ObjectID @ Unit.GetFullName() @ Unit.GetSoldierClassTemplateName() @ "rank" @ Unit.GetRank() @ (Why == "" ? "can be augmented" : "needs" @ Why));
		}
	}
}

function SHIVs(array<string> Args, out array<string> Out)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local XComGameState_Item Weapon;

	if (Args.Length > 1 && Args[1] == "add")
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: a SHIV built");
		Unit = class'LWSHIVs'.static.AddSHIV(NewGameState, (Args.Length > 2 && Args[2] != "front") ? name(Args[2]) : 'LWSHIV');
		if (Unit == none)
		{
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
			Out.AddItem("ERR no SHIV template" @ (Args.Length > 2 ? Args[2] : "LWSHIV"));
			return;
		}
		// ('front': first in the crew, so a mission's squad, filled from the first ready, takes it.)
		if (Args.Find("front") != INDEX_NONE)
			Unit.SetUnitFloatValue('LWX2TestFirst', 1, eCleanup_Never);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		Out.AddItem("ok" @ Unit.GetFullName() @ "#" $ Unit.ObjectID);
	}
	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (!class'LWSHIVs'.static.IsSHIV(Unit))
			continue;
		Weapon = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon);
		Out.AddItem("#" $ Unit.ObjectID @ Unit.GetFullName() @ Unit.GetMyTemplateName() @ Unit.GetSoldierClassTemplateName() @ "rank" @ Unit.GetRank()
			@ "hp" @ int(Unit.GetCurrentStat(eStat_HP)) $ "/" $ int(Unit.GetMaxStat(eStat_HP)) @ "aim" @ int(Unit.GetMaxStat(eStat_Offense))
			@ "def" @ int(Unit.GetMaxStat(eStat_Defense)) @ "mob" @ int(Unit.GetMaxStat(eStat_Mobility)) @ "will" @ int(Unit.GetMaxStat(eStat_Will))
			@ "weapon" @ (Weapon != none ? string(Weapon.GetMyTemplateName()) : "none") @ "ready" @ Unit.CanGoOnMission()
			@ "(soldier" @ Unit.IsSoldier() @ "status" @ Unit.GetStatus() @ "mental" @ Unit.GetMentalState() @ "injured" @ Unit.IsInjured() $ ")");
	}
}

function AoETest(int UnitID, name Profile, out array<string> Out)
{
	local XGUnit Visualizer;
	local XGAIBehavior Behavior;
	local AvailableAction Ability;
	local XComGameState_Ability AbilityState;
	local XGAIBehavior.AoETargetingInfo Info;
	local bool bFound;
	local int i, AbilityID;

	Visualizer = XGUnit(`XCOMHISTORY.GetVisualizer(UnitID));
	Behavior = Visualizer != none ? Visualizer.m_kBehavior : none;
	if (Behavior == none)
	{
		Out.AddItem("ERR no AI for #" $ UnitID);
		return;
	}
	Behavior.UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	Behavior.DebugAoEList.Length = 0;
	bFound = Behavior.FindAoETarget(Profile);
	Out.AddItem((bFound ? "found" : "none") @ Profile $ (bFound ? " at " $ Behavior.TopAoETarget.Location : ""));
	// The behavior tree's next steps (SelectAoETarget-<profile>): the ability among the unit's AoE abilities, the place in
	// its reach (CanHitAoETarget, validity ignored as the tree does), the reach.
	Ability = Behavior.FindAbilityByName(Behavior.GetAbilityFromTargetingProfile(Profile, Info), AbilityState);
	Out.AddItem("  ability #" $ Ability.AbilityObjectRef.ObjectID @ "code" @ Ability.AvailableCode @ "AoE" @ Behavior.HasAoEAbility(AbilityID, Info.Ability)
		@ "reach" @ (AbilityState != none ? string(Behavior.GetAoEHitRange(AbilityState)) : "?")
		@ "from" @ Behavior.m_kUnit.GetGameStateLocation()
		@ "in reach" @ (AbilityID > 0 && Behavior.CanHitAoETarget(AbilityID, Behavior.TopAoETarget, Info, true))
		@ "selected" @ Behavior.BT_SelectAoETarget(Profile));
	for (i = 0; i < Behavior.DebugAoEList.Length && i < 20; i++)
		Out.AddItem("  " $ Behavior.DebugAoEList[i].Label @ "good" @ Behavior.DebugAoEList[i].nGoodHits @ "bad" @ Behavior.DebugAoEList[i].nBadHits @ "at" @ Behavior.DebugAoEList[i].TestLoc);
}

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
function CrewList(out array<string> Out)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local int i;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	for (i = 0; XComHQ != none && i < XComHQ.Crew.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
		if (Unit != none && Unit.IsSoldier())
			Out.AddItem("#" $ Unit.ObjectID @ Unit.GetFullName() @ Unit.GetSoldierClassTemplateName() @ "rank" @ Unit.GetRank() @ Unit.GetStatus());
	}
}

function string Crew()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local array<int> Ranks;
	local int i, n, Shaken, TimeValue;
	local string S, Tired, Status, TimeLabel;

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
		{
			Unit.GetMentalStateStringsSeparate(Status, TimeLabel, TimeValue);
			Tired $= " " $ Unit.GetLastName() $ "(" $ int(Unit.GetCurrentStat(eStat_Will)) $ "/" $ int(Unit.GetMaxStat(eStat_Will)) @ Status @ TimeValue @ TimeLabel $ ")";
		}
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
	// ('anims <-10 - n>': squad select's n-th line-up pawn, a strategy pawn.)
	if (Index <= -10 && UISquadSelect(Pres().ScreenStack.GetFirstInstanceOf(class'UISquadSelect')) != none
		&& -10 - Index < UISquadSelect(Pres().ScreenStack.GetFirstInstanceOf(class'UISquadSelect')).UnitPawns.Length)
		Pawn = UISquadSelect(Pres().ScreenStack.GetFirstInstanceOf(class'UISquadSelect')).UnitPawns[-10 - Index];
	else if (Pick == none)
	{
		Out.AddItem("ERR no such enemy");
		return;
	}
	else
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
	if (Pick != none)
	{
		foreach Pick.Abilities(Ref)
			if (XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID)) != none)
				Sets @= XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID)).GetMyTemplateName();
		Out.AddItem("  abilities:" $ Sets @ "| behaviour tree" @ Pick.GetMyTemplate().strBehaviorTree);
		Sets = "";
		foreach Pick.GetMyTemplate().AdditionalAnimSets(Set)
			Sets @= (Set != none ? PathName(Set) $ "(" $ Set.Sequences.Length $ ")" : "none");
		Out.AddItem("  the template's AdditionalAnimSets:" $ Sets @ "| difficulty variant" @ Pick.GetMyTemplate().Name @ Pick.GetMyTemplate());
	}
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

function Exalt(array<string> Args, out array<string> Out)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local string Why, Line;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
	{
		Out.AddItem("ERR no Long War campaign");
		return;
	}
	if (Args.Length > 3 && Args[1] ~= "send")
	{
		// 'exalt send #<unit id> <country>': a covert operative sent (as the Situation Room sends one).
		Out.AddItem(class'LWExalt'.static.SendOperative(int(Mid(Args[2], 1)), int(Args[3]), Why) ? "ok" : "ERR" @ Why);
		S = class'XComGameState_LWStrategy'.static.Get();
	}
	else if (Args.Length > 2 && Args[1] ~= "accuse")
	{
		// 'exalt accuse <country>': as the Situation Room accuses (Long War's rules apply).
		Out.AddItem(class'LWExalt'.static.Accuse(int(Args[2])) ? "ok" : "ERR not allowed");
		S = class'XComGameState_LWStrategy'.static.Get();
	}
	else if (Args.Length > 1 && Args[1] ~= "sweep")
	{
		Out.AddItem(class'LWExalt'.static.Sweep(Why) ? "ok" : "ERR" @ Why);
		S = class'XComGameState_LWStrategy'.static.Get();
	}
	else if (Args.Length > 1)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: EXALT (control port)");
		S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
		if (Args[1] ~= "begin")
		{
			if (S.ExaltState == class'LWExalt'.const.NOT_BEGUN)
				class'LWExalt'.static.Begin(S);
			S.ExaltCooldown = 1;
			class'LWExalt'.static.DayForExalt(NewGameState, S);
		}
		else if (Args[1] ~= "place")
			class'LWExalt'.static.PlaceNextCell(S, true);
		else if (Args[1] ~= "act" && Args.Length > 2)
			class'LWExalt'.static.PerformRandomOperation(NewGameState, S, int(Args[2]));
		else if (Args[1] ~= "intel" && Args.Length > 2)
			S.ExaltIntel = int(Args[2]);
		// ('exalt kind <1|2>': the covert mission an extraction or a data recovery, a test aid.)
		else if (Args[1] ~= "kind" && Args.Length > 2)
			S.ExaltMissionKind = int(Args[2]);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		class'XComGameState_LWStrategy'.static.SyncResearch();
		S = class'XComGameState_LWStrategy'.static.Get();
		Out.AddItem("ok");
	}
	Out.AddItem("state" @ S.ExaltState @ "base" @ (S.ExaltState > 0 ? S.CountryName(S.ExaltCountry) : "-") @ "cooldown" @ S.ExaltCooldown @ "days since an operation" @ S.ExaltDaysSinceOperation
		@ "scans" @ S.ExaltSweeps @ "(next" @ class'LWStrategyRules'.static.Money(class'LWExalt'.static.SweepCost(S)) $ (class'LWExalt'.static.CanSweep(S, Why) ? ")" : "; not now:" @ Why $ ")") @ "intel" @ S.ExaltIntel);
	if (S.ExaltOperative > 0)
		Out.AddItem("operative #" $ S.ExaltOperative @ "in" @ S.CountryName(S.ExaltOperativeCountry) @ "days" @ S.ExaltOperativeDays @ (S.ExaltMissionUntil > 0 ? "extraction for" @ (S.ExaltMissionUntil - S.Hours) $ "h" : "")
			@ "status" @ XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.ExaltOperative)).GetStatus());
	Out.AddItem("covert missions fought" @ S.ExaltMissionsFought @ "raid ready" @ S.bExaltRaidReady);
	for (i = 0; i < S.ExaltCells.Length; i++)
		Out.AddItem("cell" @ S.ExaltCells[i].Country @ S.CountryName(S.ExaltCells[i].Country) @ (S.ExaltCells[i].DaysUntilHidden > 0 ? "EXPOSED for" @ S.ExaltCells[i].DaysUntilHidden : "hidden") @ "acts in" @ S.ExaltCells[i].DaysUntilNextActivity);
	Line = "clues (of" @ class'LWExalt'.default.Clues.Length $ "):";
	for (i = 0; i < S.ExaltClues.Length; i++)
		Line @= string(class'LWExalt'.default.Clues[S.ExaltClues[i]].Text);
	Out.AddItem(Line);
	for (i = Max(0, S.Events.Length - 4); i < S.Events.Length; i++)
		Out.AddItem("event" @ S.Events[i]);
}

function DamageReduction(array<string> Args, out array<string> Out)
{
	local XComGameState_Unit Unit, Attacker, Target;
	local string Parts;
	local float Left;

	if (Args.Length > 2 && Args[1] ~= "tocover")
	{
		// 'dr tocover <unit index>': the soldier walked to the nearest tile with cover it can reach (a test aid).
		Out.AddItem(ToCover(int(Args[2]), Args.Length > 3 && Args[3] ~= "high"));
		return;
	}
	if (Args.Length > 3)
	{
		Attacker = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(int(Mid(Args[1], 1))));
		Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(int(Mid(Args[2], 1))));
		if (Attacker == none || Target == none)
		{
			Out.AddItem("ERR dr <attacker #id> <target #id> <damage>");
			return;
		}
		Left = class'X2Ability_LWDamageReduction'.static.Absorb(Target, Attacker, Attacker.GetPrimaryWeapon(), int(Args[3]), Parts, Args.Length > 4 && Args[4] == "melee");
		Out.AddItem(Attacker.GetFullName() @ "(" $ (Attacker.GetPrimaryWeapon() != none ? string(Attacker.GetPrimaryWeapon().GetMyTemplateName()) : "no weapon") $ ") on"
			@ Target.GetFullName() @ "for" @ Args[3] $ ": left" @ Left $ ";" $ (Parts != "" ? Parts : " nothing taken off"));
		return;
	}
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (!Unit.bRemovedFromPlay && Unit.IsAlive() && (Unit.GetTeam() == eTeam_XCom || Unit.GetTeam() == eTeam_Alien))
			Out.AddItem("#" $ Unit.ObjectID @ Unit.GetFullName() @ Unit.GetMyTemplateName() @ "own" @ class'X2Ability_LWDamageReduction'.static.OwnReduction(Unit)
				@ "armour" @ int(Unit.GetCurrentStat(eStat_ArmorMitigation)) @ "cover" @ Unit.GetCoverTypeFromLocation() @ "passive" @ (Unit.FindAbility('LWX2_DamageReduction').ObjectID > 0));
}

/** A soldier of XCOM's (by index) walked to the nearest reachable tile with cover (high cover only, bHigh). */
function string ToCover(int Index, bool bHigh)
{
	local array<XComGameState_Unit> Units;
	local array<TTile> Tiles;
	local TTile T, Best;
	local vector At;
	local XGUnit Visualizer;
	local int D, BestD;

	Units = FieldXCom();
	if (Index < 0 || Index >= Units.Length)
		return "ERR no unit" @ Index;
	Visualizer = XGUnit(Units[Index].GetVisualizer());
	if (Visualizer == none)
		return "ERR not in a mission";
	Visualizer.m_kReachableTilesCache.GetAllPathableTiles(Tiles);
	BestD = 1000;
	foreach Tiles(T)
	{
		At = `XWORLD.GetPositionFromTileCoordinates(T);
		if (!(`XWORLD.IsLocationHighCover(At) || (!bHigh && `XWORLD.IsLocationLowCover(At))))
			continue;
		D = Abs(T.X - Units[Index].TileLocation.X) + Abs(T.Y - Units[Index].TileLocation.Y);
		if (D > 0 && D < BestD)
		{
			BestD = D;
			Best = T;
		}
	}
	if (BestD == 1000)
		return "ERR no tile with cover in reach";
	return MoveUnit(Index, Best.X, Best.Y, Best.Z);
}

function XComUnits(out array<string> Out)
{
	local array<XComGameState_Unit> Units;
	local int i;

	Units = FieldXCom();
	if (Units.Length == 0)
		Out.AddItem("ERR no units of XCOM on the field (not in a mission?)");
	for (i = 0; i < Units.Length; i++)
		Out.AddItem(i @ Units[i].GetFullName() @ "#" $ Units[i].ObjectID @ "(" $ Units[i].GetMyTemplateName() $ "," @ Units[i].GetSoldierClassTemplateName() $ ") at" @ Units[i].TileLocation.X @ Units[i].TileLocation.Y @ Units[i].TileLocation.Z
			@ "ap" @ Units[i].ActionPoints.Length @ "sight" @ int(Units[i].GetCurrentStat(eStat_SightRadius)) @ "hp" @ int(Units[i].GetCurrentStat(eStat_HP)) $ "/" $ int(Units[i].GetMaxStat(eStat_HP))
			@ "mob" @ int(Units[i].GetCurrentStat(eStat_Mobility)) @ "def" @ int(Units[i].GetCurrentStat(eStat_Defense)) @ "flankcrit" @ int(Units[i].GetCurrentStat(eStat_FlankingCritChance)) $ "/" $ int(Units[i].GetBaseStat(eStat_FlankingCritChance)) $ "/" $ int(Units[i].GetMyTemplate().CharacterBaseStats[eStat_FlankingCritChance])
			@ "weapon" @ (Units[i].GetItemInSlot(eInvSlot_PrimaryWeapon) != none ? string(Units[i].GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplateName()) : "-")
			$ (X2WeaponTemplate(Units[i].GetItemInSlot(eInvSlot_PrimaryWeapon) != none ? Units[i].GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate() : none) != none
				? " dmg" @ X2WeaponTemplate(Units[i].GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate()).BaseDamage.Damage $ "s" $ X2WeaponTemplate(Units[i].GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate()).BaseDamage.Spread
					$ "c" $ X2WeaponTemplate(Units[i].GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate()).BaseDamage.Crit : "")
			$ (Units[i].IsConcealed() ? " concealed" : "") $ (Units[i].IsUnitAffectedByEffectName('RangerStealth') ? " stealth" : ""));
}

/**
 * A unit of XCOM's walked to a tile as the player's click does it: the path found by XCOM 2's path solver (within the
 * unit's reach this turn) and submitted by the tactical controller's move, so the game's rules all apply (what it
 * sees, the pods it reveals, reaction fire).
 */
function string FuriesBoom()
{
	local LWX2Furies.LWX2FuriesDef F;
	local XComGameState NewGameState;
	local XComGameState_EnvironmentDamage D;

	if (!class'LWX2Furies'.static.Active(F))
		return "ERR not in Furies";
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a test explosion at Furies' console");
	D = XComGameState_EnvironmentDamage(NewGameState.CreateNewStateObject(class'XComGameState_EnvironmentDamage'));
	D.DEBUG_SourceCodeLocation = "LWX2ControlClient.FuriesBoom";
	D.DamageAmount = 10;
	D.DamageTypeTemplateName = 'Explosion';
	D.HitLocation = F.Console;
	D.HitLocationTile = `XWORLD.GetTileCoordinatesFromPosition(F.Console);
	D.DamageRadius = 144;
	D.bRadialDamage = true;
	D.bSpawnExplosionVisuals = true;
	`TACTICALRULES.SubmitGameState(NewGameState);
	return "ok an explosion at" @ F.Console;
}

function string GlobeTest(array<string> Args)
{
	local LWX2EWBase B;
	local array<float> Xs, Ys;
	local array<LinearColor> Colours;
	local rotator R;

	B = class'LWX2EWBase'.static.Get(GetALocalPlayerController());
	if (B == none || B.Globe == none)
		return "ERR no hologlobe placed";
	if (Args.Length > 2)
		B.GlobeLonOffset = float(Args[2]);
	if (Args.Length > 3)
		B.bGlobeMirrored = Args[3] == "1";
	if (Args.Length > 4)
		B.GlobeLonScale = float(Args[4]);
	B.GlobeSeconds = 0;
	B.GlobeHoldYaw = -1;
	R = B.Globe.Rotation;
	R.Yaw = Args.Length > 1 ? int(Args[1]) : 0;
	B.Globe.SetRotation(R);
	Xs.AddItem(0.5); Ys.AddItem(0.5); Colours.AddItem(MakeLinearColor(1, 0, 0, 1));
	Xs.AddItem(0.75); Ys.AddItem(0.5); Colours.AddItem(MakeLinearColor(1, 1, 0, 1));
	Xs.AddItem(0.5); Ys.AddItem(0.25); Colours.AddItem(MakeLinearColor(0, 1, 1, 1));
	// 90°W at the equator (magenta) and at 45°N (white).
	Xs.AddItem(0.25); Ys.AddItem(0.5); Colours.AddItem(MakeLinearColor(1, 0, 1, 1));
	Xs.AddItem(0.25); Ys.AddItem(0.25); Colours.AddItem(MakeLinearColor(1, 1, 1, 1));
	B.SetGlobeMarkers(Xs, Ys, Colours);
	return "ok globe yaw" @ R.Yaw @ "offset" @ B.GlobeLonOffset @ "mirrored" @ B.bGlobeMirrored @ "scale" @ B.GlobeLonScale;
}

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

function string PutInView(int Index)
{
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit Unit, Alien, Best;
	local XComWorldData World;
	local XComGameState NewGameState;
	local TTile T, Tile, AlienTile;
	local vector At;
	local GameRulesCache_VisibilityInfo Vis;
	local int d, dx, dy, BestD;

	Units = FieldXCom();
	if (Index < 0 && XComTacticalController(GetALocalPlayerController()) != none)
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComTacticalController(GetALocalPlayerController()).GetActiveUnitStateRef().ObjectID));
	else if (Index >= 0 && Index < Units.Length)
		Unit = Units[Index];
	if (Unit == none)
		return "ERR no unit" @ Index;
	World = `XWORLD;
	BestD = 9999;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Alien)
		if (Alien.GetTeam() == eTeam_Alien && Alien.IsAlive() && !Alien.bRemovedFromPlay && Alien.TileDistanceBetween(Unit) < BestD)
		{
			Best = Alien;
			BestD = Alien.TileDistanceBetween(Unit);
		}
	if (Best == none)
		return "ERR no alien";
	for (d = 6; d <= 9; d++)
		for (dx = -d; dx <= d; dx++)
			for (dy = -d; dy <= d; dy++)
			{
				if (Abs(dx) != d && Abs(dy) != d)
					continue;
				T.X = Best.TileLocation.X + dx;
				T.Y = Best.TileLocation.Y + dy;
				T.Z = World.NumZ - 1;
				At = World.GetPositionFromTileCoordinates(T);
				if (!World.GetFloorTileForPosition(At, Tile, true) || World.IsTileOccupied(Tile) || !World.CanUnitsEnterTile(Tile))
					continue;
				// (A clear line from the tile to the alien, as the game's visibility sees it.)
				AlienTile = Best.TileLocation;
				if (!World.CanSeeTileToTile(Tile, AlienTile, Vis) || !Vis.bClearLOS)
					continue;
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a unit put in view (control port)");
				Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
				Unit.SetVisibilityLocation(Tile);
				`TACTICALRULES.SubmitGameState(NewGameState);
				XGUnit(Unit.GetVisualizer()).GetPawn().SetLocation(World.GetPositionFromTileCoordinates(Tile));
				return "ok" @ Unit.GetFullName() @ "at" @ Tile.X @ Tile.Y @ Tile.Z @ "in view of" @ Best.GetMyTemplateName() @ "#" $ Best.ObjectID;
			}
	return "ERR no tile in view of the nearest alien";
}

/** The unit walked along its way to a tile, as far as one move reaches (the farthest tile of the whole path it can reach). */
function string ApproachUnit(int Index, int X, int Y)
{
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit Unit;
	local XComWorldData World;
	local array<TTile> Path, Reach;
	local TTile Dest;
	local vector At;
	local int k;

	Units = FieldXCom();
	if (Index < 0 || Index >= Units.Length)
		return "ERR no unit" @ Index;
	Unit = Units[Index];
	World = `XWORLD;
	// (The tile itself, or one near it: a unit's own tile has no path to it.)
	for (k = 0; k < 49 && Path.Length < 2; k++)
	{
		Dest.X = X + (k % 7) - 3;
		Dest.Y = Y + (k / 7) - 3;
		Dest.Z = World.NumZ - 1;
		At = World.GetPositionFromTileCoordinates(Dest);
		if (World.GetFloorTileForPosition(At, Dest, true))
			class'X2PathSolver'.static.BuildPath(Unit, Unit.TileLocation, Dest, Path, false);
	}
	if (Path.Length < 2)
		return "ERR no path for" @ Unit.GetFullName() @ "to" @ X @ Y;
	for (k = Path.Length - 1; k > 0; k--)
		if (class'X2PathSolver'.static.BuildPath(Unit, Unit.TileLocation, Path[k], Reach, true) && Reach.Length >= 2)
			return MoveUnit(Index, Path[k].X, Path[k].Y, Path[k].Z);
	return "ERR" @ Unit.GetFullName() @ "can reach no tile of the way to" @ X @ Y;
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
		Out.AddItem(Unit.GetMyTemplateName() @ "#" $ Unit.ObjectID @ "(" $ Unit.GetMyTemplate().CharacterGroupName $ ") \"" $ Unit.GetName(eNameType_Full) $ "\" team" @ Unit.GetTeam() @ "hp" @ int(Unit.GetCurrentStat(eStat_HP)) $ "/" $ int(Unit.GetMaxStat(eStat_HP)) @ "tiles" @ Best
			@ "at" @ T.X $ "," $ T.Y $ "," $ T.Z @ (World.GetFloorPositionForTile(T, Floor) ? "floor" : "NOT floor") @ "open around" @ Open
			@ "ai data" @ Unit.GetAIUnitDataID() @ "group" @ (Unit.GetGroupMembership() != none ? Unit.GetGroupMembership().ObjectID : 0) @ "ap" @ Unit.ActionPoints.Length
			@ "effects" @ JoinNames(Unit.AffectedByEffectNames));
		// What decides whether it is drawn: its tile's fog, how many of XCOM see it, its visualizer's team flags.
		World.GetTileFOWValue(T, FogStatus, FogFlags);
		Vis = XGUnit(Unit.GetVisualizer());
		Out.AddItem("  seen by" @ class'X2TacticalVisibilityHelpers'.static.GetNumEnemyViewersOfTarget(Unit.ObjectID) @ "tile fog" @ FogStatus @ "flags" @ FogFlags
			@ "visible to teams" @ (Vis != none ? string(Vis.m_eTeamVisibilityFlags) : "no visualizer") @ "pawn hidden" @ ((Vis != none && Vis.GetPawn() != none) ? string(Vis.GetPawn().bHidden) : "-") @ "outlined" @ ((Vis != none && Vis.GetPawn() != none) ? string(Vis.GetPawn().bAffectedByTargetDefinition) : "-")
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
/** A Long War tech marked researched (techdone). */
function string TechDone(int Id)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech Tech;
	local name Template;

	Template = class'LWResearchRules'.static.TemplateForId(Id);
	if (Template == '')
		return "ERR no Long War tech" @ Id;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', Tech)
		if (Tech.GetMyTemplateName() == Template)
			break;
	if (Tech == none || Tech.GetMyTemplateName() != Template)
		return "ERR no state for" @ Template;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ.IsTechResearched(Template))
		return "ok already" @ Template;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: tech done (test aid)");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.TechsResearched.AddItem(Tech.GetReference());
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return "ok" @ Template @ "researched";
}

/** The soldiers' psi experience and ranks; psixp <i> <xp> sets one's. */
function PsiXP(array<string> Args, out array<string> Out)
{
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local XComGameState NewGameState;
	local int n;

	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		if (Args.Length > 2 && n == int(Args[1]))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: psi XP set (test aid)");
			Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			Unit.SetUnitFloatValue('LWX2PsiXP', int(Args[2]), eCleanup_Never);
			if (Args.Length > 3)
				Unit.SetUnitFloatValue('LWX2PsiRank', int(Args[3]), eCleanup_Never);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			Out.AddItem("ok" @ Unit.GetFullName() @ "psi XP" @ int(Args[2]) @ "rank" @ class'XComGameState_LWStrategy'.static.PsiRankOf(Unit));
			return;
		}
		if (Args.Length <= 2 && n < 8)
			Out.AddItem(n @ Unit.GetFullName() @ "psi XP" @ class'XComGameState_LWStrategy'.static.PsiXPOf(Unit) @ "rank" @ class'XComGameState_LWStrategy'.static.PsiRankOf(Unit)
				@ "next" @ class'XComGameState_LWStrategy'.static.PsiXPNeeded(class'XComGameState_LWStrategy'.static.PsiRankOf(Unit) + 1) @ "will" @ int(Unit.GetBaseStat(eStat_Will)));
		n++;
	}
}

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

/** Gene mods (features/lw-genemods.md): with no arguments the mods and who is in the tank; 'gene <soldier index> <perk>…' puts a
 *  soldier in for those mods. */
function Gene(array<string> Args, out array<string> Out)
{
	local XComGameState_LWStrategy S;
	local LWBaseRules.LWGeneMod G;
	local XComGameState_LWStrategy.LWGenePatient T;
	local XComGameState_Unit Unit, First;
	local StateObjectReference Ref;
	local array<int> Perks;
	local string Why, Line;
	local int n, i;

	S = class'XComGameState_LWStrategy'.static.Get();
	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier())
			continue;
		if (Args.Length > 2 && n == int(Args[1]))
		{
			for (i = 2; i < Args.Length; i++)
				Perks.AddItem(int(Args[i]));
			Out.AddItem(class'XComGameState_LWStrategy'.static.StartGeneMods(Unit.ObjectID, Perks, Why) ? "ok" @ Unit.GetFullName() @ "in the tank" : "ERR needs" @ Why);
			return;
		}
		if (First == none && Unit.CanGoOnMission() && !S.InPsiTraining(Unit.ObjectID))
			First = Unit;
		n++;
	}
	Out.AddItem("Genetics Lab:" @ class'LWBase'.static.Count(S, 23) @ "built," @ S.GenePatients.Length @ "in the tanks");
	foreach class'LWBaseRules'.default.GeneMods(G)
	{
		class'XComGameState_LWStrategy'.static.CanGeneMod(S, First, G, Why);
		Out.AddItem(G.Perk @ class'X2Ability_LWStandins'.static.GeneAbilityFor(G.Perk) @ G.Slot @ class'LWStrategyRules'.static.Money(G.Cash) @ G.Meld @ "meld" @ G.Days @ "days" $ (Why != "" ? "; needs" @ Why : ""));
	}
	foreach S.GenePatients(T)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(T.Unit));
		Line = "tank:" @ (Unit != none ? Unit.GetFullName() : string(T.Unit));
		for (i = 0; i < T.Perks.Length; i++)
			Line @= class'X2Ability_LWStandins'.static.GeneAbilityFor(T.Perks[i]) @ T.HoursLeft[i] @ "hours" $ (i + 1 < T.Perks.Length ? "," : "");
		Out.AddItem(Line);
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
/** The Chryssalid hive (LWX2ChryssalidHive): its config, its state; 'hive stage <n>' (a test aid). */
function Hive(array<string> Args, out array<string> Out)
{
	local LWX2ChryssalidHive.LWX2HiveDef H;
	local XComGameState_LWX2Hive Hive;
	local XComGameState NewGameState;
	local int i, n;

	Out.AddItem("config:" @ class'LWX2ChryssalidHive'.default.Hives.Length @ "hives," @ class'LWX2ChryssalidHive'.default.Volumes.Length @ "volumes,"
		@ class'LWX2ChryssalidHive'.default.Spawns.Length @ "spawns" $ (class'LWX2ChryssalidHive'.default.Spawns.Length > 0 ? " (first: level" @ class'LWX2ChryssalidHive'.default.Spawns[0].Level
		@ "char" @ class'LWX2ChryssalidHive'.default.Spawns[0].Char @ "when" @ class'LWX2ChryssalidHive'.default.Spawns[0].When $ ")" : ""));
	if (!class'LWX2ChryssalidHive'.static.Active(H))
	{
		Out.AddItem("not on the hive");
		return;
	}
	Hive = class'LWX2ChryssalidHive'.static.State();
	if (Hive == none)
	{
		Out.AddItem("no state yet");
		return;
	}
	if (Args.Length > 2 && Args[1] ~= "stage")
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: the hive's stage");
		XComGameState_LWX2Hive(NewGameState.ModifyStateObject(class'XComGameState_LWX2Hive', Hive.ObjectID)).Stage = int(Args[2]);
		`TACTICALRULES.SubmitGameState(NewGameState);
		Hive = class'LWX2ChryssalidHive'.static.State();
	}
	for (i = 0; i < Hive.Spawned.Length; i++)
		if (Hive.Spawned[i] != 0)
			n++;
	Out.AddItem("stage" @ Hive.Stage @ "enemy level" @ Hive.EnemyLevel @ "hive turn" @ Hive.HiveTurn @ "strike in" @ Hive.StrikeLeft @ "spawned" @ n @ "of" @ Hive.Spawned.Length
		@ "| transponder" @ H.Transponder @ "evac" @ H.EvacCenter);
	Out.AddItem("objective:" @ class'LWX2ChryssalidHive'.static.ObjectiveText());
}

/** The council's missions (LWCouncil): its clock, the missions offered; 'council now' one made at once. */
function string AbilityRange(string Who, name AbilityName)
{
	local XComGameState_Unit Unit;
	local XComGameState_Ability Ability;
	local StateObjectReference Ref;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		if (Unit.GetTeam() == eTeam_XCom && !Unit.bRemovedFromPlay && InStr(Caps(Unit.GetFullName()), Caps(Who)) != INDEX_NONE)
			break;
	if (Unit == none)
		return "ERR no such soldier";
	foreach Unit.Abilities(Ref)
	{
		Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Ability != none && Ability.GetMyTemplateName() == AbilityName && X2AbilityTarget_Cursor(Ability.GetMyTemplate().AbilityTargetStyle) != none)
			return Unit.GetFullName() @ AbilityName @ "reach" @ X2AbilityTarget_Cursor(Ability.GetMyTemplate().AbilityTargetStyle).GetCursorRangeMeters(Ability) / 1.5 @ "tiles ("
				$ Ability.GetMyTemplate().AbilityTargetStyle.Class.Name $ ")";
	}
	return "ERR" @ Unit.GetFullName() @ "has no aimed" @ AbilityName;
}

function string PutUnit(string Who, int X, int Y, int Z)
{
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	local TTile Tile;

	if (Left(Who, 1) == "#")
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(int(Mid(Who, 1))));
	else
	{
		Units = FieldXCom();
		if (int(Who) >= 0 && int(Who) < Units.Length)
			Unit = Units[int(Who)];
	}
	if (Unit == none)
		return "ERR no unit" @ Who;
	Tile.X = X;
	Tile.Y = Y;
	Tile.Z = Z;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: a unit put on a tile");
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Unit.SetVisibilityLocation(Tile);
	`TACTICALRULES.SubmitGameState(NewGameState);
	if (XGUnit(Unit.GetVisualizer()) != none)
		XGUnit(Unit.GetVisualizer()).GetPawn().SetLocation(`XWORLD.GetPositionFromTileCoordinates(Tile));
	return "ok" @ Unit.GetFullName() @ "put on" @ X @ Y @ Z;
}

function TileColumn(float X, float Y, out array<string> Out)
{
	local XComWorldData World;
	local vector At, HitLocation, HitNormal, Top;
	local TTile T;
	local Actor Hit;
	local int z;

	World = `XWORLD;
	At.X = X;
	At.Y = Y;
	At.Z = 0;
	T = World.GetTileCoordinatesFromPosition(At);
	Out.AddItem("tile" @ T.X @ T.Y @ "in the world:" @ !World.IsTileOutOfRange(T));
	for (z = 0; z < 8; z++)
	{
		T.Z = z;
		Out.AddItem("z" @ z @ "floor" @ World.IsFloorTile(T) @ "enter" @ World.CanUnitsEnterTile(T) @ "blocked" @ World.IsTileFullyOccupied(T));
	}
	Top = At;
	Top.Z = 3000;
	At.Z = -500;
	Hit = Trace(HitLocation, HitNormal, At, Top, false);
	if (Hit != none)
		Out.AddItem("from above, first hit at z" @ int(HitLocation.Z) @ ":" @ PathName(Hit) @ (StaticMeshActor(Hit) != none ? PathName(StaticMeshActor(Hit).StaticMeshComponent.StaticMesh) : ""));
	else
		Out.AddItem("from above: nothing hit");
}

function Evac(out array<string> Out)
{
	local XComGameState_EvacZone Zone;
	local XComGameState_BattleData Battle;
	local XComGameState_LWX2Covert Covert;
	local XComGameState_Unit Op;
	local int i;

	Zone = class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom);
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	Out.AddItem("evac zone" @ (Zone != none ? (Zone.CenterLocation.X @ Zone.CenterLocation.Y @ Zone.CenterLocation.Z) : "none")
		@ "Evac disabled" @ (Battle != none && Battle.IsAbilityGloballyDisabled('Evac')));
	Covert = class'LWX2CovertExtraction'.static.State();
	Op = class'LWX2CovertExtraction'.static.Operative();
	if (Covert != none)
	{
		for (i = 0; i < Covert.Active.Length; i++)
			Out.AddItem("relay" @ Covert.Active[i] @ (Covert.Hacked[i] ? "hacked" : "active"));
		Out.AddItem("hacked on turn" @ Covert.HackedOnTurn @ "now" @ class'LWX2CovertExtraction'.static.TurnNow() @ "operative" @ (Op != none ? Op.GetFullName() : "none")
			@ "in reach of" @ class'LWX2CovertExtraction'.static.InReach(Op) @ "away" @ Covert.bExtracted);
	}
}

function Spawns(out array<string> Out)
{
	local XComGroupSpawn Spawn;
	local XComGameState_BattleData Battle;

	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	foreach WorldInfo.AllActors(class'XComGroupSpawn', Spawn)
		Out.AddItem(PathName(Spawn) @ "at" @ Spawn.Location @ ((`PARCELMGR != none && `PARCELMGR.SoldierSpawn == Spawn) ? "CHOSEN" : ""));
	if (Battle != none)
		Out.AddItem("the battle's soldier spawn" @ Battle.MapData.SoldierSpawnLocation @ "plot" @ Battle.MapData.PlotMapName);
}

/** The month's tallies (XComGameState_LWStrategy.MonthTally, summed) and the council's last report. */
/** The council's requests (LWCouncilRequests), and 'request now [id]' one made at once. */
function Requests(array<string> Args, out array<string> Out)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local int i;
	local bool bMade;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
	{
		Out.AddItem("ERR no Long War campaign");
		return;
	}
	if (Args.Length > 1 && Args[1] ~= "now")
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: a council request");
		S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
		bMade = class'LWCouncilRequests'.static.NewRequest(S, Args.Length > 2 ? int(Args[2]) : 0);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		Out.AddItem(bMade ? "ok a request made" : "ERR no request passes now");
		S = class'XComGameState_LWStrategy'.static.Get();
		Refreshed();
	}
	Out.AddItem("next request in" @ S.RequestCountdown $ "h; made so far:" @ S.RequestsMade.Length);
	for (i = 0; i < S.Requests.Length; i++)
		Out.AddItem("request" @ i @ "id" @ S.Requests[i].Id @ S.CountryName(S.Requests[i].Country) @ class'LWCouncilRequests'.static.Words(S.Requests[i]) @ "held"
			@ class'LWCouncilRequests'.static.Held(S.Requests[i]) @ "for" @ class'LWCouncil'.static.RewardsText(S.Requests[i].Rewards) @ (S.Requests[i].bPending ? "pending" : S.Requests[i].HoursLeft $ "h"));
}

function Report(array<string> Args, out array<string> Out)
{
	local XComGameState_LWStrategy S;
	local XComGameState NewGameState;
	local string Line;
	local int T;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
	{
		Out.AddItem("ERR no Long War campaign");
		return;
	}
	if (Args.Length > 1 && Args[1] ~= "show")
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: the report shown again");
		S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
		S.bReportDue = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		Out.AddItem(class'UILWEWWorldReport'.static.OpenIfDue(`HQPRES) ? "ok the transmission opened" : "ERR not opened (no EW screens, or one open)");
		return;
	}
	for (T = 0; T < class'XComGameState_LWStrategy'.const.TALLIES; T++)
		Line @= T $ "=" $ S.Tallied(T);
	Out.AddItem("month" @ S.Month @ "tallies" $ Line);
	Line = "";
	for (T = 0; T < S.ReportTally.Length; T++)
		Line @= T $ "=" $ S.ReportTally[T];
	Out.AddItem("last report: grade" @ Mid("ABCDF", Clamp(S.ReportGrade, 0, 4), 1) @ "funding" @ S.ReportFunding @ "scientists" @ S.ReportScientists @ "engineers" @ S.ReportEngineers
		@ "mismanaged" @ S.bReportMismanaged @ "left" @ S.ReportLeaving.Length @ "due" @ S.bReportDue @ "hour" @ S.ReportHours @ "tallies" $ Line);
}

function Council(array<string> Args, out array<string> Out)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local LWX2CouncilBomb.LWX2BombDef Bomb;
	local LWX2CouncilVIP.LWX2VIPDef VIPDef;
	local XComGameState_Unit VIP;
	local TTile Tile;
	local vector At;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
	{
		Out.AddItem("ERR the campaign has not begun");
		return;
	}
	if (Args.Length > 1 && Args[1] == "now")
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: a council mission");
		S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
		class'LWCouncil'.static.NewMission(S, Args.Length > 2 ? int(Args[2]) : 0);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		S = class'XComGameState_LWStrategy'.static.Get();
	}
	// ('council disarm': the bomb disarmed at once, a test aid.)
	if (Args.Length > 1 && Args[1] == "disarm" && class'LWX2CouncilBomb'.static.State() != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: the bomb disarmed");
		XComGameState_LWX2Bomb(NewGameState.ModifyStateObject(class'XComGameState_LWX2Bomb', class'LWX2CouncilBomb'.static.State().ObjectID)).bDisarmed = true;
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	// (In a bomb disposal: the bomb's and the nodes' tiles, and the turns left.)
	if (class'LWX2CouncilBomb'.static.Active(Bomb) && `XWORLD != none)
	{
		At = Bomb.Bomb;
		Tile = `XWORLD.GetTileCoordinatesFromPosition(At);
		Out.AddItem("bomb at" @ Tile.X @ Tile.Y @ Tile.Z @ "turns left" @ class'LWX2CouncilBomb'.static.TurnsLeft(Bomb, class'LWX2CouncilBomb'.static.State()));
		for (i = 0; i < Bomb.NodeAt.Length; i++)
		{
			At = Bomb.NodeAt[i];
			Tile = `XWORLD.GetTileCoordinatesFromPosition(At);
			Out.AddItem("node" @ i @ "at" @ Tile.X @ Tile.Y @ Tile.Z @ ((class'LWX2CouncilBomb'.static.State() != none && class'LWX2CouncilBomb'.static.State().NodeOff[i]) ? "off" : "on"));
		}
	}
	// (In an extraction or rescue: the VIP's, the place they are reached and the Skyranger's tiles.)
	if (class'LWX2CouncilVIP'.static.Active(VIPDef) && `XWORLD != none)
	{
		VIP = class'LWX2CouncilVIP'.static.VIPUnit();
		if (VIP != none)
			Out.AddItem("vip" @ VIP.GetFullName() @ "#" $ VIP.ObjectID @ "at" @ VIP.TileLocation.X @ VIP.TileLocation.Y @ VIP.TileLocation.Z @ "team" @ VIP.GetTeam()
				@ "joined" @ class'LWX2CouncilVIP'.static.State().bJoined @ "away" @ class'LWX2CouncilVIP'.static.State().bExtracted @ "dead" @ VIP.IsDead());
		Tile = `XWORLD.GetTileCoordinatesFromPosition(VIPDef.Approach);
		Out.AddItem("reached at" @ (VIPDef.bApproach ? (Tile.X @ Tile.Y @ Tile.Z) : "(a rescue: from the start)"));
		At = class'LWX2CouncilVIP'.static.Skyranger(VIPDef);
		Tile = `XWORLD.GetTileCoordinatesFromPosition(At);
		if (class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom) != none)
			Out.AddItem("evac zone centre" @ class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).CenterLocation.X @ class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).CenterLocation.Y
				@ class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).CenterLocation.Z @ "vip in it" @ (VIP != none && class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom).IsUnitInEvacZone(VIP)));
		Out.AddItem("skyranger at" @ Tile.X @ Tile.Y @ Tile.Z @ "| objective:" @ class'LWX2CouncilVIP'.static.ObjectiveText());
	}
	Out.AddItem("council: next in" @ S.CouncilCountdown @ "hours; played" @ S.CouncilPlayed.Length @ "| Progeny next" @ class'LWCouncil'.static.NextProgeny(S)
		@ (class'LWCouncil'.static.ProgenyOn() ? "" : "(off)"));
	for (i = 0; i < S.Sites.Length; i++)
		if (S.Sites[i].bCouncil)
			Out.AddItem(i @ "mission" @ S.Sites[i].CouncilMission @ class'LWCouncil'.static.KindName(S.Sites[i].CouncilKind) @ "in" @ S.CountryName(S.Sites[i].Country)
				@ "status" @ S.Sites[i].Status @ "until" @ S.Sites[i].Until @ "|" @ class'LWCouncil'.static.RewardsText(S.Sites[i].Rewards));
}

/** A shot's chance (its ability's to-hit calculation, as the targeting shows it), its crit and the modifiers' reasons. */
function string OpenEWSoldier(int UnitID, bool bAbilities, optional bool bPsi)
{
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;

	if (UnitID == 0)
		foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
			if (Unit != none && Unit.IsSoldier())
			{
				UnitID = Unit.ObjectID;
				break;
			}
		}
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (Unit == none || `HQPRES == none)
		return "ERR no such soldier, or not at the base";
	if (bPsi)
		class'UILWEWPsiPromotion'.static.OpenPsi(`HQPRES, Unit.GetReference());
	else if (bAbilities)
		class'UILWEWSoldierPromotion'.static.Open(`HQPRES, Unit.GetReference());
	else
		class'UILWEWSoldierSummary'.static.Open(`HQPRES, Unit.GetReference());
	return "ok" @ (bAbilities ? "abilities" : "summary") @ "of" @ Unit.GetFullName() @ "rank" @ Unit.GetRank();
}

function string OpenPromotion(int UnitID)
{
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;

	if (UnitID == 0)
		foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
			if (Unit != none && Unit.IsSoldier())
			{
				UnitID = Unit.ObjectID;
				break;
			}
		}
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (Unit == none || `HQPRES == none)
		return "ERR no such soldier, or not at the base";
	`HQPRES.UIArmory_Promotion(Unit.GetReference());
	return "ok promotion of" @ Unit.GetFullName() @ "rank" @ Unit.GetRank();
}

function Repair(array<string> Args, out array<string> Out)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;
	local XComGameState_Unit Before;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local array<XComGameState_Unit> Soldiers;
	local StateObjectReference Ref;
	local string Why;
	local int i, n;

	if (Args.Length > 3 && Args[1] ~= "wear")
	{
		foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
			if (Unit != none && Unit.IsSoldier())
				Soldiers.AddItem(Unit);
		}
		if (int(Args[2]) < 0 || int(Args[2]) >= Soldiers.Length)
		{
			Out.AddItem("ERR no such soldier");
			return;
		}
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: gear worn (control port)");
		S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldiers[int(Args[2])].ObjectID));
		Unit.SetCurrentStat(eStat_HP, int(Args[3]));
		n = class'LWGearRepair'.static.DamageGear(NewGameState, S, XComHQ, Unit);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		Out.AddItem(Unit.GetFullName() @ "hp" @ int(Unit.GetCurrentStat(eStat_HP)) $ "/" $ int(Unit.GetMaxStat(eStat_HP)) @ "items damaged" @ n);
	}
	else if (Args.Length > 2 && Args[1] ~= "dead")
	{
		// 'repair dead <soldier>': a test aid, the soldier dead with the body recovered (its items into storage, as XCOM 2 puts
		// them), then the dead's gear rolled as at the Geoscape.
		foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
			if (Unit != none && Unit.IsSoldier())
				Soldiers.AddItem(Unit);
		}
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a death (control port)");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldiers[int(Args[2])].ObjectID));
		Items = Unit.GetAllInventoryItems(NewGameState, true);
		foreach Items(Item)
		{
			Item = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Item.ObjectID));
			if (Unit.RemoveItemFromInventory(Item, NewGameState))
				XComHQ.PutItemInInventory(NewGameState, Item, false);
		}
		Unit.SetCurrentStat(eStat_HP, 0);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		class'LWGearRepair'.static.Apply();
		Out.AddItem(Unit.GetFullName() @ "dead, items in storage; held Carapace" @ class'LWEngineering'.static.Held('LWArmor_60'));
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID));
		i = 0;
		Before = Unit;
		while (Before != none && Before.InventoryItems.Length == 0 && i < 50)
		{
			Before = XComGameState_Unit(Before.GetPreviousVersion());
			i++;
		}
		Out.AddItem("  dead" @ Unit.IsDead() @ "soldier" @ Unit.IsSoldier() @ "marked" @ class'LWFatigue'.static.ValueOf(Unit, 'LWX2GearDead') @ "items now" @ Unit.InventoryItems.Length
			@ "earlier version back" @ i @ "with" @ (Before != none ? Before.InventoryItems.Length : -1) @ "items");
	}
	else if (Args.Length > 1)
		Out.AddItem(class'LWGearRepair'.static.StartRepair(name(Args[1]), Why) ? "ok" : "ERR" @ Why);
	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = 0; i < S.DamagedItems.Length; i++)
		Out.AddItem("damaged" @ S.DamagedItems[i] @ "(" $ class'LWEngineering'.static.ItemName(S.DamagedItems[i]) $ "): chance"
			@ class'LWGearRepair'.static.ChanceFor(S.DamagedItems[i]) $ "%, repair" @ class'LWGearRepair'.static.CostText(S.DamagedItems[i])
			@ "in" @ class'LWGearRepair'.static.HoursFor(S, S.DamagedItems[i]) @ "hours");
	for (i = 0; i < S.Repairs.Length; i++)
		Out.AddItem("repairing" @ S.Repairs[i].Template @ S.Repairs[i].HoursLeft @ "hours left");
	if (S.DamagedItems.Length == 0 && S.Repairs.Length == 0)
		Out.AddItem("no damaged gear");
}

function WarLate(out array<string> Out)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_LWAirWar AirWar;
	local int n;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a late mission (control port)");
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
	AirWar = class'LWHangar'.static.InState(NewGameState);
	class'LWHangar'.static.NewJet(AirWar, 3, (class'LWHangar'.static.HomeContinent() + 1) % 5);
	n = S.Ufos.Length;
	S.AddLateMission(S.Hours);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Out.AddItem("late mission:" @ (S.Ufos.Length - n) @ "UFO(s) planned" $ (S.Ufos.Length > n ? ", over" @ S.CountryName(S.Ufos[n].Country) @ "at hour" @ S.Ufos[n].Hour @ "(now" @ S.Hours $ ")" : ""));
}

function War(out array<string> Out)
{
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local XComGameState_LWStrategy S;
	local array<int> ByKind, Groups;
	local string Line;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	Line = "passes";
	for (i = 0; i < S.WarPasses.Length; i++)
		Line @= i $ ":" $ S.WarPasses[i];
	Out.AddItem(Line @ "| Dynamic War" @ class'LWX2SecondWave'.static.On(9) @ "resources" @ S.AlienResources @ "aggression" @ S.AlienAggression @ "day" @ S.Days());
	// (Objectives counted once each: an objective's UFOs share a group.)
	ByKind.Length = 11;
	for (i = 0; i < S.Ufos.Length; i++)
		if (Groups.Find(S.Ufos[i].Group) == INDEX_NONE)
		{
			Groups.AddItem(S.Ufos[i].Group);
			ByKind[Clamp(S.Ufos[i].Objective, 0, 10)]++;
		}
	Line = "objectives";
	for (i = 0; i < ByKind.Length; i++)
		if (ByKind[i] > 0)
			Line @= class'LWStrategyRules'.static.ObjectiveName(i) $ ":" $ ByKind[i];
	Out.AddItem(Line);
	// The soldiers' Long War experience (LWX2XP), the first six.
	Line = "xp";
	i = 0;
	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit == none || !Unit.IsSoldier() || i++ >= 6)
			continue;
		Line @= class'LWExperience'.static.XPOf(Unit);
	}
	Out.AddItem(Line);
}

function Meld(out array<string> Out)
{
	local XComGameState_LootDrop Drop;
	local XComGameState_LWX2Meld Waiting;
	local FOWTileStatus Status;
	local byte Flags;
	local TTile T;
	local int i;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LootDrop', Drop)
		if (Drop.LastLootOwnerName == "Meld canister")
			Out.AddItem("canister at" @ Drop.TileLocation.X @ Drop.TileLocation.Y @ Drop.TileLocation.Z @ "turns left" @ Drop.LootExpirationTurnsRemaining);
	Waiting = XComGameState_LWX2Meld(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LWX2Meld', true));
	if (Waiting != none)
		for (i = 0; i < Waiting.Hidden.Length; i++)
		{
			T = Waiting.Hidden[i].Tile;
			`XWORLD.GetTileFOWValue(T, Status, Flags);
			Out.AddItem("hidden at" @ T.X @ T.Y @ T.Z @ "turns" @ Waiting.Hidden[i].Turns @ "meld" @ Waiting.Hidden[i].Amount @ "fog" @ Status);
		}
	Out.AddItem("turn" @ class'LWX2CovertExtraction'.static.TurnNow() @ "Recon" @ class'LWX2SecondWave'.static.On(29));
}

function string RunTree(int UnitID, string Tree)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (Unit == none)
		return "ERR no such unit";
	if (Unit.ActionPoints.Length == 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: an action point (control port)");
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
		`TACTICALRULES.SubmitGameState(NewGameState);
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	}
	if (!`BEHAVIORTREEMGR.QueueBehaviorTreeRun(Unit, Tree, 1, `XCOMHISTORY.GetCurrentHistoryIndex() + 1, true))
		return "ERR the tree was not queued";
	`BEHAVIORTREEMGR.TryUpdateBTQueue();
	return "ok" @ Tree @ "queued for" @ Unit.GetMyTemplateName() @ "#" $ UnitID;
}

function string Scamper(int GroupID)
{
	local XComGameState NewGameState;
	local XComGameState_AIGroup Group;
	local XComGameState_Unit Soldier;
	local StateObjectReference Ref;

	Group = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(GroupID));
	if (Group == none)
		return "ERR no such AI group";
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Soldier)
		if (Soldier.GetTeam() == eTeam_XCom && Soldier.IsAlive() && Soldier.IsSoldier())
			break;
	// (Units dropped by 'spawn' come without a reveal to play: each is given one.)
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: a reveal (control port)");
	foreach Group.m_arrMembers(Ref)
		XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Ref.ObjectID)).bTriggerRevealAI = true;
	`TACTICALRULES.SubmitGameState(NewGameState);
	Group = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(GroupID));
	Group.InitiateReflexMoveActivate(Soldier, eAC_SeesSpottedUnit);
	return "ok group" @ GroupID @ "revealed by" @ Soldier.GetFullName();
}

function PerfectInfo(array<string> Args, out array<string> Out)
{
	local XComGameState_Unit Unit;
	local XComGameState_Effect Effect;
	local X2Effect_LWSecondWave E;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Effect', Effect)
	{
		E = X2Effect_LWSecondWave(Effect.GetX2Effect());
		if (E != none)
			break;
	}
	Out.AddItem("seen" @ (E != none ? E.Seen : -1) @ "announced" @ (E != none ? E.Announced : -1) @ "option" @ class'LWX2SecondWave'.static.On(28));
	if (Args.Length > 2 && Args[1] ~= "say")
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
			if (Unit.GetTeam() == eTeam_XCom && Unit.IsAlive() && Unit.IsSoldier())
				break;
		`PRES.QueueWorldMessage(Repl(Args[2], "_", " "), `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation), Unit.GetReference(), eColor_Bad, , , eTeam_All);
		Out.AddItem("said over" @ Unit.GetFullName());
	}
}

function CoverScan(int ShooterID, int TargetID, int Radius, out array<string> Out)
{
	local XComGameState_Unit Shooter, Target;
	local TTile T;
	local vector From, To;
	local float Angle;
	local ECoverType Cover;
	local int dx, dy, n;

	Shooter = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ShooterID));
	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetID));
	if (Shooter == none || Target == none)
	{
		Out.AddItem("ERR no such units");
		return;
	}
	From = `XWORLD.GetPositionFromTileCoordinates(Shooter.TileLocation);
	for (dx = -Radius; dx <= Radius && n < 30; dx++)
		for (dy = -Radius; dy <= Radius && n < 30; dy++)
		{
			T = Target.TileLocation;
			T.X += dx;
			T.Y += dy;
			if (!`XWORLD.CanUnitsEnterTile(T))
				continue;
			To = `XWORLD.GetPositionFromTileCoordinates(T);
			Angle = -1;
			Cover = `XWORLD.GetCoverTypeForTarget(From, To, Angle);
			if (Cover == CT_None)
				continue;
			Out.AddItem(T.X @ T.Y @ T.Z @ Cover @ "angle" @ int(Angle));
			n++;
		}
	if (n == 0)
		Out.AddItem("no cover within" @ Radius @ "tiles");
}

function HitChance(out array<string> Out, int AttackerID, int TargetID, name AbilityName)
{
	local XComGameState_Unit Attacker, Target;
	local XComGameState_Ability Ability;
	local AvailableTarget Pick;
	local ShotBreakdown Breakdown;
	local GameRulesCache_VisibilityInfo VisInfo;
	local string Why;
	local int i;

	Attacker = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AttackerID));
	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetID));
	if (Attacker == none || Target == none)
	{
		Out.AddItem("ERR no such units");
		return;
	}
	Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Attacker.FindAbility(AbilityName).ObjectID));
	if (Ability == none || Ability.GetMyTemplate().AbilityToHitCalc == none)
	{
		Out.AddItem("ERR" @ Attacker.GetMyTemplateName() @ "has no" @ AbilityName);
		return;
	}
	Pick.PrimaryTarget = Target.GetReference();
	Ability.GetMyTemplate().AbilityToHitCalc.GetShotBreakdown(Ability, Pick, Breakdown);
	for (i = 0; i < Breakdown.Modifiers.Length; i++)
		Why @= Breakdown.Modifiers[i].Reason $ "=" $ Breakdown.Modifiers[i].Value $ (Breakdown.Modifiers[i].ModType == eHit_Crit ? "(crit)" : "");
	// (XCOM 2's view of the target's cover from the shooter: its kind and angle, as the hit calculation reads them.)
	if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo))
		Why @= "| cover" @ VisInfo.TargetCover @ "angle" @ int(class'X2Effect_LWSecondWave'.static.CoverAngle(Attacker, Target));
	Out.AddItem(Attacker.GetMyTemplateName() @ AbilityName @ "->" @ Target.GetFullName() @ "(" $ Attacker.TileDistanceBetween(Target) @ "tiles):" @ Breakdown.FinalHitChance $ "% crit" @ Breakdown.ResultTable[eHit_Crit] $ "% |" $ Why);
}

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

function string RemoveUnit(int UnitID)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (Unit == none || `TACTICALRULES == none)
		return "ERR no unit #" $ UnitID $ " in a mission";
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2 test: a unit removed");
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitID));
	Unit.RemoveUnitFromPlay();
	`TACTICALRULES.SubmitGameState(NewGameState);
	return "ok" @ Unit.GetFullName() @ "removed";
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
	local XComGameState NewGameState;
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

	// (#<id>: any unit, an alien too; given an action point if it has none, to act in XCOM's turn: a test aid.)
	if (Left(Who, 1) == "#")
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(int(Mid(Who, 1))));
		if (Unit != none && Unit.ActionPoints.Length == 0)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: an action point (control port)");
			Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			Unit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}
	else
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
			// (*: the first soldier who has the ability.)
			if (Unit.GetTeam() == eTeam_XCom && !Unit.bRemovedFromPlay && ((Who == "*" && Unit.FindAbility(AbilityName).ObjectID > 0) || (Who != "*" && (InStr(Caps(Unit.GetFullName()), Caps(Who)) != INDEX_NONE || InStr(Caps(string(Unit.GetSoldierClassTemplateName())), Caps(Who)) != INDEX_NONE))))
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
			return class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0, Here) ? "used at" @ Here[0] @ "on" @ Area.AdditionalTargets.Length @ "units in its area" : "ERR it did not go";
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
	// A council request: given (won) or refused (LWCouncilRequests).
	if (Kinds[n] == 20 || Kinds[n] == 21)
		return (class'LWCouncilRequests'.static.Answer(Indexes[n], Kinds[n] == 20) ? "answered" : "ERR not answered") @ Labels[n];
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
			else if (XComHQ.GetSupplies() >= class'LWStrategyRules'.static.SatelliteCash() && class'XComGameState_LWStrategy'.static.BuildSatellite())
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
/** Long War's start screen: its options, or one chosen (the screen opened first if it is not up). */
function string StartCampaign(int Option)
{
	local XComHQPresentationLayer HQ;
	local UILWStartSelect Start;
	local string Line;
	local int i;

	HQ = XComHQPresentationLayer(Pres());
	if (HQ == none)
		return "ERR not on the Avenger";
	if (class'XComGameState_LWStrategy'.static.Get() != none)
		return "ERR the campaign has begun (home" @ class'XComGameState_LWStrategy'.static.Get().CountryName(class'XComGameState_LWStrategy'.static.Get().HomeCountry()) $ ")";
	Start = UILWStartSelect(HQ.ScreenStack.GetScreen(class'UILWStartSelect'));
	if (Start == none)
	{
		class'UILWStartSelect'.static.OpenGeoscape(HQ);
		return "start screen opened (start again once it is up)";
	}
	if (Option < 0)
	{
		for (i = 0; i < Start.Choices.Length; i++)
			Line $= i $ "=" $ Start.OptionLabel(i) $ "; ";
		return Line;
	}
	Start.Select(Option);
	Start.Accept();
	return "ok" @ Start.OptionLabel(Option);
}

/** The bonuses that hold now, and the home and its starting option. */
function Bonuses(XComGameState_LWStrategy S, out array<string> Out)
{
	local array<string> Lines;
	local string L;

	if (S == none)
	{
		Out.AddItem("ERR the campaign has not begun");
		return;
	}
	Out.AddItem("home" @ S.CountryName(S.HomeCountry()) @ "start option" @ S.StartChoice);
	Lines = class'LWBonuses'.static.Holding(S);
	foreach Lines(L)
		Out.AddItem(L);
}

/** The Geoscape screen, opened if it is not up (only on the Avenger). */
/** The hub command. */
function string HubCommand(array<string> Args)
{
	local UILWEWHub Hub;

	Hub = UILWEWHub(Pres().ScreenStack.GetFirstInstanceOf(class'UILWEWHub'));
	if (Hub == none)
		return "ERR no hub (open hub)";
	if (Args.Length < 2)
		return "room" @ Hub.Room @ "options" @ Hub.RoomOptions.Length;
	if (Args[1] ~= "back")
		Hub.LeaveRoom();
	else if (Args[1] ~= "mc")
		Hub.EnterMissionControl();
	else if (Args[1] ~= "option" && Args.Length > 2 && int(Args[2]) < Hub.RoomOptions.Length)
		Hub.ChooseOption(Hub.RoomOptions[int(Args[2])]);
	else
		Hub.EnterRoom(int(Args[1]));
	return "ok room" @ Hub.Room @ "options" @ Hub.RoomOptions.Length;
}

/** The officers command. */
function RankUp(int Index, int Times, out array<string> Out)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local array<XComGameState_Unit> Soldiers;
	local StateObjectReference Ref;
	local int HP, Aim, Will, r, j;
	local string Line;

	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit != none && Unit.IsSoldier() && Unit.IsAlive())
			Soldiers.AddItem(Unit);
	}
	if (Index == -1)
		for (r = Soldiers.Length - 1; r >= 0; r--)
			if (Soldiers[r].GetRank() == 0)
				Index = r;
	if (Index != -2 && (Index < 0 || Index >= Soldiers.Length))
	{
		Out.AddItem("ERR no such soldier");
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: rank up (control port)");
	if (Index == -2)
	{
		Unit = class'LWBonusEffects'.static.NewSoldier(NewGameState, XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom',
			class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID)), 0, 0);
		// ('rankup new 0': a recruit with the experience for the first promotion, to be promoted in the armory.)
		if (Times == 0)
			Unit.NonTacticalKills = class'X2ExperienceConfig'.static.GetRequiredKills(1);
	}
	else
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldiers[Index].ObjectID));
	Out.AddItem("was: hp" @ int(Unit.GetBaseStat(eStat_HP)) @ "aim" @ int(Unit.GetBaseStat(eStat_Offense)) @ "will" @ int(Unit.GetBaseStat(eStat_Will)) @ "mob" @ int(Unit.GetBaseStat(eStat_Mobility)));
	while (Times-- > 0)
	{
		HP = Unit.GetBaseStat(eStat_HP);
		Aim = Unit.GetBaseStat(eStat_Offense);
		Will = Unit.GetBaseStat(eStat_Will);
		Unit.RankUpSoldier(NewGameState, Unit.GetRank() == 0 ? '' : Unit.GetSoldierClassTemplateName());
		Out.AddItem(Unit.GetFullName() @ Unit.GetSoldierClassTemplateName() @ "rank" @ Unit.GetRank() @ "hp +" $ (int(Unit.GetBaseStat(eStat_HP)) - HP)
			@ "aim +" $ (int(Unit.GetBaseStat(eStat_Offense)) - Aim) @ "will +" $ (int(Unit.GetBaseStat(eStat_Will)) - Will));
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Out.AddItem("#" $ Unit.ObjectID @ Unit.GetFullName() @ "rank" @ Unit.GetRank() @ "can rank up" @ Unit.CanRankUpSoldier());
	// (Long War's gains follow in a game state of their own: the soldier's stats as they are now.)
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID));
	Out.AddItem("now: hp" @ int(Unit.GetBaseStat(eStat_HP)) @ "aim" @ int(Unit.GetBaseStat(eStat_Offense)) @ "will" @ int(Unit.GetBaseStat(eStat_Will)) @ "mob" @ int(Unit.GetBaseStat(eStat_Mobility)) @ "(" $ (class'LWX2SecondWave'.static.On(3) ? "Hidden Potential" : "normal") $ ")");
	for (r = 0; r < Unit.AbilityTree.Length; r++)
	{
		Line = "tree" @ r $ ":";
		for (j = 0; j < Unit.AbilityTree[r].Abilities.Length; j++)
			Line @= string(Unit.AbilityTree[r].Abilities[j].AbilityName);
		Out.AddItem(Line);
	}
}

function Officers(array<string> Args, out array<string> Out)
{
	local XComGameState_LWStrategy S;
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	local array<XComGameState_Unit> Soldiers;
	local StateObjectReference Ref;
	local string Why;
	local int i, r;

	S = class'XComGameState_LWStrategy'.static.Get();
	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit != none && Unit.IsSoldier() && Unit.IsAlive())
			Soldiers.AddItem(Unit);
	}
	if (Args.Length > 2 && Args[1] ~= "buy")
		Out.AddItem(class'LWOfficers'.static.Buy(int(Args[2]), Why) ? "ok" : "ERR" @ Why);
	else if (Args.Length > 2 && Args[1] ~= "promote" && int(Args[2]) < Soldiers.Length)
		Out.AddItem(class'LWOfficers'.static.Promote(Soldiers[int(Args[2])].ObjectID, Args.Length > 3 && Args[3] ~= "second", Why) ? "ok" : "ERR" @ Why);
	else if (Args.Length > 1 && Args[1] ~= "mark")
	{
		// A test aid: the squad's leader and powers marked again, as at launch (after 'officers set' in a mission).
		class'LWOfficers'.static.MarkSquad();
		Out.AddItem("ok squad marked");
	}
	else if (Args.Length > 2 && Args[1] ~= "ready" && (Left(Args[2], 1) == "#" || int(Args[2]) < Soldiers.Length))
	{
		// A test aid: the soldier ranked up to the next officer rank's requirement and its missions in grade counted done.
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: officer ready (control port)");
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Left(Args[2], 1) == "#" ? int(Mid(Args[2], 1)) : Soldiers[int(Args[2])].ObjectID));
		while (Unit.GetRank() < class'LWOfficers'.static.Rank(Unit) + 3)
			Unit.RankUpSoldier(NewGameState, Unit.GetSoldierClassTemplateName());
		Unit.SetUnitFloatValue('LWX2OfficerMissionsAt', Unit.GetNumMissions() - class'LWOfficers'.default.MissionsPerGrade, eCleanup_Never);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		Out.AddItem("ok" @ Unit.GetFullName() @ "rank" @ Unit.GetRank());
	}
	else if (Args.Length > 4 && Args[1] ~= "set" && (Left(Args[2], 1) == "#" || int(Args[2]) < Soldiers.Length))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: officer set (control port)");
		// (#<ObjectID>: the unit by its ID, as the squad lists it.)
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Left(Args[2], 1) == "#" ? int(Mid(Args[2], 1)) : Soldiers[int(Args[2])].ObjectID));
		Unit.SetUnitFloatValue('LWX2OfficerRank', int(Args[3]), eCleanup_Never);
		Unit.SetUnitFloatValue('LWX2OfficerPowers', int(Args[4]), eCleanup_Never);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		Out.AddItem("ok" @ Unit.GetFullName() @ class'LWOfficers'.static.RankName(int(Args[3])));
	}
	S = class'XComGameState_LWStrategy'.static.Get();
	Out.AddItem("officer projects bought" @ S.OfficerProjectsBought);
	for (r = 0; r < 5; r++)
		Out.AddItem(class'LWOfficers'.static.RankName(r + 1) $ ": open" @ (S.OfficersAvailable.Length > r ? S.OfficersAvailable[r] : 0) @ "filled" @ (S.OfficersUsed.Length > r ? S.OfficersUsed[r] : 0));
	for (i = 0; i < Soldiers.Length; i++)
	{
		Unit = Soldiers[i];
		if (class'LWOfficers'.static.Rank(Unit) > 0 || (Args.Length > 1 && Args[1] ~= "all"))
			Out.AddItem(i @ "#" $ Unit.ObjectID @ Unit.GetFullName() @ "rank" @ Unit.GetRank() @ "missions" @ Unit.GetNumMissions() @ "officer" @ class'LWOfficers'.static.Rank(Unit)
				@ "powers" @ class'LWOfficers'.static.ValueOf(Unit, 'LWX2OfficerPowers') @ (class'LWOfficers'.static.CanPromote(S, Unit, Why) ? "promotable" : "not:" @ Why));
	}
}

/** The lightoff command: actors of the class switched off (or on again). */
function string LightOff(string ClassName, bool bOn, float MinRadius)
{
	local Actor A;
	local int n;

	foreach Pres().AllActors(class'Actor', A)
	{
		if (!(string(A.Class.Name) ~= ClassName))
			continue;
		if (MinRadius > 0 && (Light(A) == none || PointLightComponent(Light(A).LightComponent) == none || PointLightComponent(Light(A).LightComponent).Radius < MinRadius))
			continue;
		if (LightInjector(A) != none)
			LightInjector(A).SetEnabled(bOn);
		else if (PostProcessVolume(A) != none)
			PostProcessVolume(A).bEnabled = bOn;
		else if (Light(A) != none && Light(A).LightComponent != none)
			Light(A).LightComponent.SetEnabled(bOn);
		else
			A.SetHidden(!bOn);
		n++;
	}
	return n @ ClassName @ (bOn ? "on" : "off");
}

/** The lights that are on near the camera (the lights near command). */
function LightsNear(out array<string> Out, float Radius)
{
	local Light L;
	local vector At;
	local float D;

	At = XComHeadquartersController(Pres().Owner).PlayerCamera.CameraCache.POV.Location;
	foreach Pres().AllActors(class'Light', L)
	{
		if (L.LightComponent == none || !L.LightComponent.bEnabled)
			continue;
		D = VSize(L.Location - At);
		if (D > Radius)
			continue;
		Out.AddItem(int(D) @ string(L.Class.Name) @ "brightness" @ L.LightComponent.Brightness @ "colour" @ L.LightComponent.LightColor.R $ "," $ L.LightComponent.LightColor.G $ "," $ L.LightComponent.LightColor.B
			@ (PointLightComponent(L.LightComponent) != none ? "radius" @ int(PointLightComponent(L.LightComponent).Radius) : ""));
	}
}

/** The world's lights and lighting actors (the lights command). */
function LightsReport(out array<string> Out)
{
	local Light L;
	local Actor A;
	local LWX2EWBase B;
	local int Ours, k;
	local array<string> Kinds;
	local array<int> Counts;
	local string Kind;

	B = class'LWX2EWBase'.static.Get(Pres());
	foreach Pres().AllActors(class'Light', L)
	{
		if (L.Owner == B)
		{
			Ours++;
			continue;
		}
		Out.AddItem(string(L.Class.Name) @ string(L.Name) @ (L.LightComponent == none ? "no component" : ((L.LightComponent.bEnabled ? "on" : "off")
			@ "brightness" @ L.LightComponent.Brightness @ "colour" @ L.LightComponent.LightColor.R $ "," $ L.LightComponent.LightColor.G $ "," $ L.LightComponent.LightColor.B))
			@ "distance" @ int(VSize(L.Location - B.BaseOffset)));
	}
	Out.AddItem(Ours @ "lights of the base's own");
	foreach Pres().AllActors(class'Actor', A)
	{
		Kind = string(A.Class.Name);
		if (InStr(Locs(Kind), "light") == INDEX_NONE && InStr(Locs(Kind), "fog") == INDEX_NONE && InStr(Locs(Kind), "sky") == INDEX_NONE
			&& InStr(Locs(Kind), "environment") == INDEX_NONE && InStr(Locs(Kind), "postprocess") == INDEX_NONE && InStr(Locs(Kind), "weather") == INDEX_NONE
			&& InStr(Locs(Kind), "ambient") == INDEX_NONE && InStr(Locs(Kind), "reflection") == INDEX_NONE)
			continue;
		k = Kinds.Find(Kind);
		if (k == INDEX_NONE)
		{
			Kinds.AddItem(Kind);
			Counts.AddItem(1);
		}
		else
			Counts[k]++;
	}
	for (k = 0; k < Kinds.Length; k++)
		Out.AddItem("actors" @ Kinds[k] @ Counts[k]);
}

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
	Out.AddItem("satellite price" @ class'LWStrategyRules'.static.SatelliteCash() @ "held" @ class'LWX2SecondWave'.static.SatellitesHeld());
	for (i = 0; i < S.Countries.Length; i++)
		Out.AddItem("country" @ i @ S.Countries[i].Id @ "panic" @ S.Countries[i].Panic @ "satellite" @ int(S.Countries[i].bSatellite) @ "left" @ int(S.Countries[i].bLeft) @ "hunted" @ int(S.Countries[i].bHunted) @ "funding" @ S.CountryFunding(i, true) $ "/" $ S.CountryFunding(i, false));
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
function string PeopleLight(array<string> Args)
{
	local LWX2BasePerson P;
	local DynamicLightEnvironmentComponent LE;
	local LinearColor C;
	local int n;

	foreach WorldInfo.AllActors(class'LWX2BasePerson', P)
	{
		LE = P.LightEnvironment;
		if (Args.Length > 2 && Args[1] ~= "glow" && LE != none)
		{
			C.R = float(Args[2]); C.G = C.R; C.B = C.R; C.A = 1;
			LE.AmbientGlow = C;
			LE.ResetEnvironment();
		}
		else if (Args.Length > 2 && Args[1] ~= "le")
			P.SkeletalMeshComponent.SetLightEnvironment(Args[2] ~= "on" ? P.LightEnvironment : none);
		n++;
	}
	return "ok" @ n @ "people";
}

function string EWDisplay(array<string> Args)
{
	local LWX2UIDisplay D;
	local rotator R;
	local string Out_Material;

	D = class'LWX2EWBase'.static.DisplayFor(Pres(), Args.Length > 1 ? name(Args[1]) : '');
	if (D == none || Args.Length < 4)
		return "ERR ewdisplay <tag> scale|yaw|pitch|roll <n>";
	R = D.Rotation;
	if (Args[2] ~= "scale")
		D.SetDrawScale3D(vect(1, 1, 1) * float(Args[3]));
	else if (Args[2] ~= "yaw")
		R.Yaw += int(Args[3]);
	else if (Args[2] ~= "pitch")
		R.Pitch += int(Args[3]);
	else if (Args[2] ~= "roll")
		R.Roll += int(Args[3]);
	else if (Args[2] ~= "move")
		D.SetLocation(D.Location + vect(1, 0, 0) * float(Args[3]) + vect(0, 1, 0) * float(Args.Length > 4 ? Args[4] : "0") + vect(0, 0, 1) * float(Args.Length > 5 ? Args[5] : "0"));
	else if (Args[2] ~= "show")
		`HQPRES.Get3DMovie().ShowDisplay(D.Tag, D);
	else if (Args[2] ~= "material")
		Out_Material = PathName(D.StaticMeshComponent.GetMaterial(0)) @ (MaterialInstance(D.StaticMeshComponent.GetMaterial(0)) != none ? PathName(MaterialInstance(D.StaticMeshComponent.GetMaterial(0)).Parent) : "");
	D.SetRotation(R);
	return "ok" @ D.Tag @ "at" @ D.Location @ "rot" @ D.Rotation @ "scale" @ D.DrawScale3D @ "bounds" @ D.StaticMeshComponent.Bounds.SphereRadius @ "hidden" @ D.bHidden @ D.StaticMeshComponent.HiddenGame @ "movie of" @ D.m_kMovie @ Out_Material;
}

function BaseParents(out array<string> Out)
{
	local DynamicSMActor_Spawnable A;
	local MaterialInterface M;
	local MaterialInstance MI;
	local array<string> Names;
	local array<int> Counts;
	local string N;
	local int i, k;

	foreach WorldInfo.AllActors(class'DynamicSMActor_Spawnable', A)
	{
		for (i = 0; i < A.StaticMeshComponent.GetNumElements(); i++)
		{
			M = A.StaticMeshComponent.GetMaterial(i);
			MI = MaterialInstance(M);
			N = MI != none ? "instance of " $ PathName(MI.Parent) : (M != none ? string(M.Class.Name) @ PathName(M) : "none");
			k = Names.Find(N);
			if (k == INDEX_NONE)
			{
				Names.AddItem(N);
				Counts.AddItem(0);
				k = Names.Length - 1;
			}
			Counts[k]++;
		}
	}
	for (i = 0; i < Names.Length; i++)
		if (Counts[i] > 5 || InStr(Names[i], "Lightmap") != INDEX_NONE)
			Out.AddItem(Counts[i] @ Names[i]);
}

function string BaseLightEnvironments(bool bOn)
{
	local DynamicSMActor_Spawnable A;
	local int n;

	foreach WorldInfo.AllActors(class'DynamicSMActor_Spawnable', A)
	{
		if (A.LightEnvironment == none)
			continue;
		A.LightEnvironment.SetEnabled(bOn);
		A.StaticMeshComponent.SetLightEnvironment(bOn ? A.LightEnvironment : none);
		n++;
	}
	return "ok" @ n @ "light environments" @ (bOn ? "on" : "off");
}

function string SetEWMaterials(name Param, string Value)
{
	local Actor A;
	local StaticMeshComponent SMC;
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
	// (The mission maps' pieces and EW's base's, DynamicSMActor_Spawnable.)
	foreach WorldInfo.AllActors(class'Actor', A)
	{
		SMC = LWX2LevelActor(A) != none ? LWX2LevelActor(A).StaticMeshComponent : (DynamicSMActor(A) != none ? DynamicSMActor(A).StaticMeshComponent : none);
		if (SMC == none)
			continue;
		for (i = 0; i < SMC.GetNumElements(); i++)
		{
			MIC = MaterialInstanceConstant(SMC.GetMaterial(i));
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

/** A test aid: EW's base's pieces and people by their mesh's path (basehide). */
function string BaseHide(string Text, bool bShow, optional string Move, optional float By)
{
	local DynamicSMActor_Spawnable Piece;
	local LWX2BasePerson Person;
	local int n;
	local string Where;

	if (Text == "")
		return "ERR basehide <text> [show]";
	// (basehide cutaway [show]: the base's black cut surfaces, as a facility's camera hides them.)
	if (Text == "cutaway")
	{
		class'LWX2EWBase'.static.Get(Pres()).ShowCutaway(bShow);
		return "ok cutaway" @ (bShow ? "shown" : "hidden");
	}
	foreach AllActors(class'DynamicSMActor_Spawnable', Piece)
		if (Move == "" && InStr(PathName(Piece.StaticMeshComponent.StaticMesh), Text, , true) != INDEX_NONE)
		{
			Piece.SetHidden(!bShow);
			n++;
		}
	foreach AllActors(class'LWX2BasePerson', Person)
		if (InStr(PathName(Person.SkeletalMeshComponent.SkeletalMesh), Text, , true) != INDEX_NONE)
		{
			if (Move == "yaw")
				Person.SetRotation(Person.Rotation + rot(0, 1, 0) * By);
			else if (Move == "z")
				Person.SetLocation(Person.Location + vect(0, 0, 1) * By);
			else if (Move == "pose" && AnimNodeSequence(Person.SkeletalMeshComponent.Animations) != none)
			{
				// (Its animation stopped at this many seconds; the sequence's length reported.)
				AnimNodeSequence(Person.SkeletalMeshComponent.Animations).StopAnim();
				AnimNodeSequence(Person.SkeletalMeshComponent.Animations).SetPosition(By, false);
				Where $= " length" @ AnimNodeSequence(Person.SkeletalMeshComponent.Animations).AnimSeq.SequenceLength;
			}
			else
				Person.SetHidden(!bShow);
			n++;
			Where $= " [" $ Person.Location @ Person.Rotation.Yaw $ "]";
		}
	return "ok" @ n @ (Move != "" ? Move @ By : (bShow ? "shown" : "hidden")) $ Where;
}

/** A test aid: the soldier summary's movie variables (sumvar). */
function string SummaryVar(string Path, string Value)
{
	local UILWEWSoldierSummary S;

	S = UILWEWSoldierSummary(Pres().ScreenStack.GetCurrentScreen());
	if (S == none)
		S = UILWEWSoldierSummary(Pres().ScreenStack.GetScreen(class'UILWEWSoldierSummary'));
	if (S == none)
		return "no soldier summary";
	if (Value != "")
		S.Movie.SetVariableNumber(S.MCPath $ "." $ Path, float(Value));
	return S.MCPath $ "." $ Path @ "=" @ S.Movie.GetVariableNumber(S.MCPath $ "." $ Path) @ "(stage" @ S.Movie.GetVariableNumber("Stage.width") @ "x" @ S.Movie.GetVariableNumber("Stage.height") $ ")";
}

/** A test aid: XCOM 2's 3D movie and a panel's UV adjustment (movie3d). */
function string Movie3D(name Tag)
{
	local UIMovie_3D M;
	local LWX2UIDisplay D;
	local MaterialInstance MI;
	local LinearColor C;
	local string S;

	M = XComHQPresentationLayer(Pres()).Get3DMovie();
	if (M == none)
		return "no 3D movie";
	S = "render target" @ (M.RenderTexture != none ? (M.RenderTexture.SizeX $ "x" $ M.RenderTexture.SizeY) : "none");
	foreach AllActors(class'LWX2UIDisplay', D)
		if (Tag == '' || D.Tag == Tag)
		{
			MI = MaterialInstance(D.StaticMeshComponent.GetMaterial(0));
			if (MI != none && MI.GetVectorParameterValue('UVAdjust', C))
				S $= ";" @ D.Tag @ "UVAdjust" @ C.R $ "," $ C.G $ "," $ C.B $ "," $ C.A;
			else
				S $= ";" @ D.Tag @ "no UVAdjust";
			S @= PathName(D.StaticMeshComponent.StaticMesh) @ "scale" @ D.DrawScale3D;
		}
	return S;
}

/** A test aid: the local player's tonemapper, shown or set (tonemap). */
function string Tonemap(string To)
{
	local LocalPlayer LP;
	local PostProcessChain Chain;
	local PostProcessEffect E;
	local UberPostProcessEffect U;
	local string S;

	LP = LocalPlayer(GetALocalPlayerController().Player);
	if (LP == none)
		return "ERR no local player";
	foreach LP.PlayerPostProcessChains(Chain)
		foreach Chain.Effects(E)
		{
			U = UberPostProcessEffect(E);
			if (U == none)
				continue;
			if (To ~= "off")
				U.TonemapperType = Tonemapper_Off;
			else if (To ~= "filmic")
				U.TonemapperType = Tonemapper_Filmic;
			else if (To ~= "custom")
				U.TonemapperType = Tonemapper_Customizable;
			S @= string(U.Name) $ "=" $ string(U.TonemapperType) $ "(range" @ U.TonemapperRange $ ", desat" @ U.SceneDesaturation $ ")";
		}
	if (LP.PlayerPostProcess != none)
		foreach LP.PlayerPostProcess.Effects(E)
		{
			U = UberPostProcessEffect(E);
			if (U == none)
				continue;
			if (To ~= "off")
				U.TonemapperType = Tonemapper_Off;
			else if (To ~= "filmic")
				U.TonemapperType = Tonemapper_Filmic;
			else if (To ~= "custom")
				U.TonemapperType = Tonemapper_Customizable;
			S @= "player:" $ string(U.Name) $ "=" $ string(U.TonemapperType);
		}
	return S == "" ? "ERR no uber post-process effect" : "ok" $ S;
}

/** A test aid: EW's base's pieces' material swapped, live (basemat). */
function string BaseMat(array<string> Args)
{
	local DynamicSMActor_Spawnable Piece;
	local MaterialInterface M;
	local MaterialInstanceConstant MIC;
	local array<string> V;
	local LinearColor C;
	local int n, k, i;

	if (Args.Length < 3)
		return "ERR basemat <text> <material>|self [<param> <value>]...";
	// (self: each element's own material kept as the parent, only the parameters given changed.)
	if (Args[2] != "self")
	{
		M = MaterialInterface(DynamicLoadObject(Args[2], class'MaterialInterface', true));
		if (M == none)
			return "ERR no material" @ Args[2];
	}
	foreach AllActors(class'DynamicSMActor_Spawnable', Piece)
	{
		if (InStr(PathName(Piece.StaticMeshComponent.StaticMesh), Args[1], , true) == INDEX_NONE)
			continue;
		for (k = 0; k < Piece.StaticMeshComponent.GetNumElements(); k++)
		{
			if (Args[2] == "self" && Piece.StaticMeshComponent.GetMaterial(k) == none)
				continue;
			MIC = new(Piece) class'MaterialInstanceConstant';
			MIC.SetParent(Args[2] == "self" ? Piece.StaticMeshComponent.GetMaterial(k) : M);
			for (i = 3; i + 1 < Args.Length; i += 2)
			{
				V = SplitString(Args[i + 1], ",");
				// (A value with a dot and letters, a texture's path: set as a texture parameter.)
				if (InStr(Args[i + 1], ".") != INDEX_NONE && Texture(DynamicLoadObject(Args[i + 1], class'Texture', true)) != none)
					MIC.SetTextureParameterValue(name(Args[i]), Texture(DynamicLoadObject(Args[i + 1], class'Texture', true)));
				else if (V.Length >= 3)
				{
					C = MakeLinearColor(float(V[0]), float(V[1]), float(V[2]), V.Length > 3 ? float(V[3]) : 1.0);
					MIC.SetVectorParameterValue(name(Args[i]), C);
				}
				else
					MIC.SetScalarParameterValue(name(Args[i]), float(Args[i + 1]));
			}
			Piece.StaticMeshComponent.SetMaterial(k, MIC);
		}
		n++;
	}
	return "ok" @ n @ "pieces given" @ (M != none ? PathName(M) : "their own materials, changed");
}

/** A test aid: EW's base's pieces by their mesh's path, as the engine has them (basemesh). */
function BaseMesh(string Text, out array<string> Out)
{
	local DynamicSMActor_Spawnable Piece;
	local StaticMeshComponent C;

	foreach AllActors(class'DynamicSMActor_Spawnable', Piece)
	{
		C = Piece.StaticMeshComponent;
		if (Text == "" || InStr(PathName(C.StaticMesh), Text, , true) == INDEX_NONE)
			continue;
		Out.AddItem(PathName(C.StaticMesh) @ "at" @ Piece.Location @ "rot" @ Piece.Rotation @ "scale" @ Piece.DrawScale @ Piece.DrawScale3D
			@ "bounds" @ C.Bounds.Origin @ "extent" @ C.Bounds.BoxExtent @ "r" @ int(C.Bounds.SphereRadius)
			@ "hidden" @ Piece.bHidden @ C.HiddenGame @ "attached" @ C.bAttached @ "maxdraw" @ C.CachedMaxDrawDistance
			@ "depth" @ C.DepthPriorityGroup @ "drawn" @ (WorldInfo.TimeSeconds - C.LastRenderTime) @ "s ago" @ "owner-only" @ C.bOnlyOwnerSee
			@ "translation" @ C.Translation @ "scale3d" @ C.Scale3D @ "elements" @ C.GetNumElements());
	}
	Out.AddItem("now" @ WorldInfo.TimeSeconds);
}

/** A test aid (persontex): a slot of EW's base people given a texture as its Diffuse. */
function string PersonTex(array<string> Args)
{
	local LWX2BasePerson P;
	local MaterialInstanceConstant MIC;
	local Texture T;
	local int n;

	if (Args.Length < 4)
		return "ERR persontex <mesh text> <slot> <texture path>";
	T = Texture(DynamicLoadObject(Args[3], class'Texture', true));
	if (T == none)
		return "ERR no texture" @ Args[3];
	foreach AllActors(class'LWX2BasePerson', P)
	{
		if (InStr(PathName(P.SkeletalMeshComponent.SkeletalMesh), Args[1]) == INDEX_NONE)
			continue;
		MIC = new class'MaterialInstanceConstant';
		MIC.SetParent(P.SkeletalMeshComponent.GetMaterial(int(Args[2])));
		MIC.SetTextureParameterValue('Diffuse', T);
		P.SkeletalMeshComponent.SetMaterial(int(Args[2]), MIC);
		n++;
	}
	return "ok" @ n @ "people";
}

/** A test aid: what of EW's base stands near the camera (basenear). */
function BaseNear(float Radius, out array<string> Out)
{
	local DynamicSMActor_Spawnable Piece;
	local LWX2BasePerson Person;
	local vector At;
	local float D;
	local string Mats;
	local int k;
	local Texture Tex;

	At = XComHeadquartersController(Pres().Owner).PlayerCamera.CameraCache.POV.Location;
	foreach AllActors(class'DynamicSMActor_Spawnable', Piece)
	{
		D = VSize(Piece.Location - At);
		if (D <= Radius && !Piece.bHidden)
		{
			Mats = "";
			for (k = 0; k < Piece.StaticMeshComponent.GetNumElements(); k++)
			{
				Mats @= "[" $ k $ "]" $ PathName(MaterialInstance(Piece.StaticMeshComponent.GetMaterial(k)) != none ? MaterialInstance(Piece.StaticMeshComponent.GetMaterial(k)).Parent : Piece.StaticMeshComponent.GetMaterial(k));
				if (MaterialInstance(Piece.StaticMeshComponent.GetMaterial(k)) != none && MaterialInstance(Piece.StaticMeshComponent.GetMaterial(k)).GetTextureParameterValue('Diffuse', Tex))
					Mats @= "(" $ Tex.Name $ ")";
			}
			Out.AddItem(int(D) @ PathName(Piece.StaticMeshComponent.StaticMesh) @ Piece.Location @ "radius" @ int(Piece.StaticMeshComponent.Bounds.SphereRadius) @ "materials" $ Mats);
		}
	}
	foreach AllActors(class'LWX2BasePerson', Person)
	{
		D = VSize(Person.Location - At);
		if (D <= Radius && !Person.bHidden)
		{
			Mats = "";
			for (k = 0; k < Person.SkeletalMeshComponent.GetNumElements(); k++)
			{
				Mats @= "[" $ k $ "]" $ PathName(MaterialInstance(Person.SkeletalMeshComponent.GetMaterial(k)) != none ? MaterialInstance(Person.SkeletalMeshComponent.GetMaterial(k)).Parent : Person.SkeletalMeshComponent.GetMaterial(k));
				if (MaterialInstance(Person.SkeletalMeshComponent.GetMaterial(k)) != none && MaterialInstance(Person.SkeletalMeshComponent.GetMaterial(k)).GetTextureParameterValue('Diffuse', Tex))
					Mats @= "diffuse" @ PathName(Tex);
			}
			Out.AddItem(int(D) @ PathName(Person.SkeletalMeshComponent.SkeletalMesh) @ Person.Location @ "materials" $ Mats);
			// (Where its animation has its last bone, its bounds, its physics asset: a canister on the Genetics Lab's conveyor.)
			if (Person.SkeletalMeshComponent.PhysicsAsset != none)
				Out.AddItem("    bone" @ Person.SkeletalMeshComponent.GetBoneName(Person.SkeletalMeshComponent.SkeletalMesh.RefSkeleton.Length - 1) @ "at" @ Person.SkeletalMeshComponent.GetBoneLocation(Person.SkeletalMeshComponent.GetBoneName(Person.SkeletalMeshComponent.SkeletalMesh.RefSkeleton.Length - 1)) @ "bounds" @ Person.SkeletalMeshComponent.Bounds.Origin @ "r" @ int(Person.SkeletalMeshComponent.Bounds.SphereRadius) @ "anim" @ (AnimNodeSequence(Person.SkeletalMeshComponent.Animations) != none ? string(AnimNodeSequence(Person.SkeletalMeshComponent.Animations).AnimSeqName) @ AnimNodeSequence(Person.SkeletalMeshComponent.Animations).CurrentTime @ "of" @ AnimNodeSequence(Person.SkeletalMeshComponent.Animations).GetAnimPlaybackLength() @ (AnimNodeSequence(Person.SkeletalMeshComponent.Animations).AnimSeq != none ? "found" : "MISSING") : "no node") @ PathName(Person.SkeletalMeshComponent.PhysicsAsset));
		}
	}
	Out.AddItem("camera at" @ At);
}

defaultproperties
{
	LinkMode = MODE_Text;
	ReceiveMode = RMODE_Event;
	bAlwaysTick = true;
}
