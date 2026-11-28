// Enemy Within's interception (aek 2026-11-28: "the air war is still using our old custom interface"): EW's own movie
// (gfxInterception, converted by the setup into EWInterceptionUI.upk) on EW's interception panel in Mission Control,
// through EW's camera onto it, driven as EW's UIInterceptionEngagement drives it, by Long War's air war (LWAirWar): its
// shots rolled once, played back on the clock, Aim, Dodge, Track (Long War's Boost) and breaking off replayed from the
// moment they are used. The jet's damage, kills and the UFO's fate go into the campaign as with UILWInterception, which
// stays for the demo and for a setup without EW's screens.
//   EW's flow: the contact alert (UILWEWAlert: the jet and the stance) → UILWGeoscape.Intercept → this.
class UILWEWInterception extends UILWEWScreen;

// EW's words, its [UIInterceptionEngagement] section copied by the setup from the player's install (scripts/lw-words.mjs).
var localized string m_strAbilityDescriptions[3];
var localized string m_strTimeSufixSymbol, m_strReport_Subtitle, m_strReport_Title, m_strReport_ShotDown, m_strReport_SevereDamage;
var localized string m_strReport_HeavyDamage, m_strReport_LightDamage, m_strReport_NoDamage, m_strResult_UFODisengaged;
var localized string m_strResult_UFOEscaped, m_strResult_UFODestroyed, m_strResult_UFOCrashed, m_strEscapeTimerTitle;
var localized string m_strTrackingText, m_strTrackAbility, m_strAimAbility, m_strDodgeAbility, m_strAbortedMission;
var localized string m_strAbortingMission, m_strAbortMission, m_strLeaveReportButtonLabel, m_strPlayerDamageLabel;
var localized string m_strEstablishingLinkLabel;

/** EW's movie's ship numbers (UIInterceptionEngagement: ALIEN_SHIP_ID, PLAYER_SHIP_ID), which are LWAirWar's sources too. */
const ALIEN = 0;
const PLAYER = 1;
/** EW's seconds from the screen's start to its intro (INTRO_SEQUENCE_DELAY), and our wait for the intro's end where the
 *  movie's IntroSequenceComplete does not come through. */
const INTRO_DELAY = 0.75;
const INTRO_LONGEST = 4.0;

/** The Geoscape's UFO met, the jet (its index among the campaign's jets) and the stance (0 defensive, 1 balanced, 2
 *  aggressive). */
var int StrategyUfo, JetIndex, Stance;
var string Callsign;
var LWAirWar.LWShip Jet, TheUfo;
var array<LWAirWar.LWShot> Shots;
var LWAirWar.LWActions Act;
var LWAirWar.LWResult Result;

var float IntroClock, Clock;
var bool bIntroStarted, bIntroDone, bFighting, bResults, bRecorded;
/** The events of Result shown so far. */
var int Shown;
/** EW's bullet numbers: the last given, and those in flight that will land (a hit lands 0.3 s after its shot, in order). */
var int Bullet;
var array<int> InFlight;
var int AimLeft, DodgeLeft, Boosts;
/** When the escape would happen now (Track pushes it back), and until when the countdown stands while tracking. */
var float EscapeAt, TrackUntil;
var int ShownTenths;

/** EW's interception movie in the mod's Content (the setup converts it with EW's other screens). */
static function bool Available()
{
	return DynamicLoadObject("EWInterceptionUI.ewxInterception", class'Object', true) != none;
}

/** The fight pushed over Mission Control: false if the jet cannot fly at that UFO. */
static function bool Open(XComHQPresentationLayer HQPres, int Ufo, int Jet, int TheStance)
{
	local UILWEWInterception S;
	local array<int> Ready;

	Ready = class'LWHangar'.static.ReadyFor(Ufo);
	if (HQPres == none || Ready.Find(Jet) == INDEX_NONE)
		return false;
	DynamicLoadObject("EWInterceptionUI.ewxInterception", class'Object', true);
	S = HQPres.Spawn(class'UILWEWInterception', HQPres);
	S.Package = name("/ package/ewxInterception/Interception");
	S.MCName = 'theInterceptionScreen';
	S.StrategyUfo = Ufo;
	S.JetIndex = Jet;
	S.Stance = TheStance >= 0 ? TheStance : 1;
	Push3D(HQPres, S);
	return true;
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	SetUp();
	super.InitScreen(InitController, InitMovie, InitName);
}

/** The jet and the UFO as the campaign has them, the shots rolled (as UILWInterception.Setup and OnEngage). */
function SetUp()
{
	local XComGameState_LWAirWar AirWar;
	local XComGameState_LWStrategy S;
	local int Category;

	S = class'XComGameState_LWStrategy'.static.Get();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	Category = S.Category();
	Jet = class'LWAirWar'.static.Craft(AirWar.Jets[JetIndex].Type, AirWar.Jets[JetIndex].Weapon, Category);
	Jet.Hp = AirWar.Jets[JetIndex].Hp;
	Jet.Kills = AirWar.Jets[JetIndex].Kills;
	Callsign = AirWar.Jets[JetIndex].Callsign;
	TheUfo = class'LWAirWar'.static.Ufo(S.Ufos[StrategyUfo].Ufo, Category);
	TheUfo.Hp = S.Ufos[StrategyUfo].Hp;
	Shots = class'LWAirWar'.static.RollShots(TheUfo, Jet, Stance, false);
	Act = class'LWAirWar'.static.NoActions();
	Result = class'LWAirWar'.static.PlayBack(TheUfo, Jet, Stance, Shots, Act);
	EscapeAt = class'LWAirWar'.static.EscapeTime(TheUfo, Jet, 0);
}

simulated function OnInit()
{
	local array<ASValue> Args;

	super.OnInit();
	CallAS("SetResultsTitleLabels", Strs(m_strReport_Title, m_strReport_Subtitle));
	Args.Length = 0;
	Args.AddItem(Num(Jet.Type));
	Args.AddItem(Num(EnemyShipType(TheUfo.Type)));
	Args.AddItem(Str(m_strPlayerDamageLabel));
	Args.AddItem(Str(m_strEstablishingLinkLabel));
	CallAS("InitializeData", Args);
	// (EW sets each ship's hull first, then the HP it has now.)
	SetHP(ALIEN, TheUfo.MaxHp, true);
	SetHP(ALIEN, TheUfo.Hp, true);
	SetHP(PLAYER, Jet.MaxHp, true);
	SetHP(PLAYER, Jet.Hp, true);
	CallAS("SetAbortButtonText", Strs(m_strAbortMission));
	CallAS("SetEnemyEscapeTimerLabels", Strs(m_strEscapeTimerTitle, m_strTimeSufixSymbol));
	SetAbilityButtons(0);
	// The UFO's damage shows once XCOM knows it (EW's: the Foundry's UFO analysis, 45, or that UFO's own research).
	if (!class'X2Effect_LWFoundry'.static.Done(45) && !UfoResearched(TheUfo.Type))
		CallAS("HideUFODamage");
	`log("LongWarX2: EW interception: jet" @ JetIndex @ Callsign @ "HP" @ Jet.Hp @ "against UFO" @ StrategyUfo @ TheUfo.Name @ "HP" @ TheUfo.Hp @ "stance" @ Stance @ "events" @ Result.Events.Length, , 'LongWarX2');
}

/** EW's movie draws ten kinds of UFO; Long War's later ones as the nearest of those (UIInterceptionEngagement.OnInit). */
static function int EnemyShipType(int Type)
{
	switch (Type)
	{
	case 10: return 4;
	case 11: return 5;
	case 12: return 6;
	case 13: return 7;
	case 14: return 8;
	}
	return Type;
}

/** The research on that kind of UFO done (EW's tech 57 + its type). */
static function bool UfoResearched(int Type)
{
	local name Tech;

	Tech = class'LWResearchRules'.static.TemplateForId(57 + EnemyShipType(Type));
	return Tech != '' && class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(Tech);
}

// --- The movie's functions, called as EW's AS_ functions call them --------------------------------------------------

function CallAS(string Func, optional array<ASValue> Args)
{
	Movie.Invoke(MCPath $ "." $ Func, Args);
}

static function array<ASValue> Strs(string A, optional string B = "\n", optional string C = "\n")
{
	local array<ASValue> Args;

	Args.AddItem(Str(A));
	if (B != "\n")
		Args.AddItem(Str(B));
	if (C != "\n")
		Args.AddItem(Str(C));
	return Args;
}

static function ASValue BoolV(bool B)
{
	local ASValue V;

	V.Type = AS_Boolean;
	V.b = B;
	return V;
}

function SetHP(int Ship, int Hp, bool bInit, optional int BulletId = -1)
{
	local array<ASValue> Args;

	Args.AddItem(Num(Ship));
	Args.AddItem(Num(Max(0, Hp)));
	Args.AddItem(BoolV(bInit));
	Args.AddItem(Num(BulletId));
	CallAS("SetHP", Args);
}

function Effect(int Kind, bool bOn, optional int Data = -1)
{
	local array<ASValue> Args;

	Args.AddItem(Num(Kind));
	Args.AddItem(Str(m_strAbilityDescriptions[Kind]));
	Args.AddItem(BoolV(bOn));
	Args.AddItem(Num(Data));
	CallAS("DisplayEffectEvent", Args);
}

function Movement(int Ship, int Kind, float Duration)
{
	local array<ASValue> Args;

	Args.AddItem(Num(Ship));
	Args.AddItem(Num(Kind));
	Args.AddItem(Num(Duration));
	CallAS("MovementEvent", Args);
}

function EscapeTimer(int Tenths)
{
	local array<ASValue> Args;

	Args.AddItem(Num(Tenths));
	CallAS("SetEnemyEscapeTimer", Args);
}

/** EW's ability buttons (SetConsumablesState): 0 available, 1 active, 2 used up or not allowed, 3 not researched. Long War's
 *  stances bar Aim when defensive and Dodge when aggressive (LWAirWar.ConsumableAllowed). */
function SetAbilityButtons(int Override)
{
	local array<ASValue> Args;

	Args = Strs(m_strAimAbility);
	Args.AddItem(Num(AbilityState(0, Act.Aim, Override)));
	CallAS("SetAimButton", Args);
	Args = Strs(m_strDodgeAbility);
	Args.AddItem(Num(AbilityState(1, Act.Dodge, Override)));
	CallAS("SetDodgeButton", Args);
	Args = Strs(m_strTrackAbility, m_strTrackingText);
	Args.AddItem(Num(AbilityState(2, Act.Boost, Override)));
	CallAS("SetTrackButton", Args);
}

function int AbilityState(int Kind, float UsedAt, int Override)
{
	if (class'LWAirWar'.static.ConsumableStock(Kind) <= 0 && UsedAt < 0)
		return 3;
	if (Override >= 2 || UsedAt >= 0 || !class'LWAirWar'.static.ConsumableAllowed(Kind, Stance) || bResults)
		return 2;
	return Override;
}

// --- The fight on the clock ------------------------------------------------------------------------------------------

simulated function OnCommand(string Cmd, string Arg)
{
	if (Cmd == "IntroSequenceComplete")
		bIntroDone = true;
	super.OnCommand(Cmd, Arg);
}

simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	if (!bIsInited || bResults)
		return;
	if (!bFighting)
	{
		IntroClock += DeltaTime;
		if (!bIntroStarted && IntroClock >= INTRO_DELAY)
		{
			bIntroStarted = true;
			CallAS("BeginIntroSequence", Strs(""));
		}
		if (bIntroStarted && (bIntroDone || IntroClock >= INTRO_DELAY + INTRO_LONGEST))
			StartFight();
		return;
	}
	Clock += DeltaTime;
	CountDown();
	while (Shown < Result.Events.Length && Result.Events[Shown].Time <= Clock)
	{
		if (!ShowEvent(Result.Events[Shown++]))
			return;
	}
}

function StartFight()
{
	local int i;

	bFighting = true;
	Clock = 0;
	Movement(ALIEN, 0, EscapeAt);
	ShownTenths = int(EscapeAt * 10);
	EscapeTimer(ShownTenths);
	// A cannon closes in first (EW's IsShortDistanceWeapon: the Phoenix, laser and EMP cannons): until its first shot.
	if (Jet.Weapons.Length > 0 && (Jet.Weapons[0].Id == 1 || Jet.Weapons[0].Id == 4 || Jet.Weapons[0].Id == 6))
	{
		i = 0;
		while (i < Shots.Length && Shots[i].Source != PLAYER)
			i++;
		Movement(ALIEN, 1, i < Shots.Length ? FClamp(Shots[i].Time, 0.5, 5.0) : 1.0);
	}
}

/** The contact loss countdown, in tenths, standing while Track holds the UFO (EW's UpdateEnemyEscapeTimer). */
function CountDown()
{
	local int Tenths;

	if (TrackUntil > 0)
	{
		if (Clock < TrackUntil)
			return;
		TrackUntil = 0;
		Effect(2, false);
	}
	Tenths = int(FMax(0, EscapeAt - Clock) * 10);
	if (Tenths != ShownTenths)
	{
		ShownTenths = Tenths;
		EscapeTimer(Tenths);
	}
}

/** One of the fight's events on EW's movie; false at the end. */
function bool ShowEvent(LWAirWar.LWEvent E)
{
	local array<ASValue> Args;
	local int Weapon, Id;

	switch (E.Kind)
	{
	case eLWEvent_Shot:
		Bullet++;
		Weapon = E.Source == PLAYER ? Jet.Weapons[E.Slot].Id : TheUfo.Weapons[E.Slot].Id;
		// (EW draws the Stingray as the Avalanche: AS_AttackEvent.)
		if (Weapon == 2)
			Weapon = 3;
		Args.AddItem(Num(E.Source));
		Args.AddItem(Num(1 - E.Source));
		Args.AddItem(Num(Weapon));
		Args.AddItem(Num(Bullet));
		Args.AddItem(Num(E.Damage));
		// (EW's: a hit flies 0.3 s, a miss 0.3 s more.)
		Args.AddItem(Num(E.Damage > 0 ? 0.3 : 0.6));
		Args.AddItem(BoolV(E.Damage > 0));
		CallAS("AttackEvent", Args);
		if (E.Damage > 0)
			InFlight.AddItem(Bullet);
		if (E.Aimed && AimLeft > 0)
		{
			AimLeft--;
			if (AimLeft == 0)
				Effect(0, false, Bullet);
		}
		break;
	case eLWEvent_Hit:
		Id = TakeInFlight();
		SetHP(1 - E.Source, E.Hp, false, Id);
		break;
	case eLWEvent_Dodged:
		TakeInFlight();
		if (DodgeLeft > 0)
		{
			DodgeLeft--;
			if (DodgeLeft == 0)
			{
				Effect(1, false);
				SetAbilityButtons(2);
			}
		}
		break;
	case eLWEvent_Aim:
		AimLeft = 2;
		Effect(0, true);
		break;
	case eLWEvent_Dodge:
		DodgeLeft = 2;
		Effect(1, true, 2);
		break;
	case eLWEvent_Boost:
		Boosts++;
		// (The countdown stands for the time Track adds, then runs on to the new escape: EW's m_fTrackingTimer.)
		TrackUntil = Clock + (class'LWAirWar'.static.EscapeTime(TheUfo, Jet, Boosts) - EscapeAt);
		EscapeAt = class'LWAirWar'.static.EscapeTime(TheUfo, Jet, Boosts);
		Effect(2, true);
		break;
	case eLWEvent_End:
		Finished();
		return false;
	}
	return true;
}

function int TakeInFlight()
{
	local int Id;

	if (InFlight.Length == 0)
		return -1;
	Id = InFlight[0];
	InFlight.Remove(0, 1);
	return Id;
}

/** A consumable or breaking off, now: the rest of the fight played back again from the same shots (as
 *  UILWInterception.Replay). Only what is still to come changes: the events shown stay as they were. */
function Use(int Kind)
{
	`log("LongWarX2: EW interception: use" @ Kind @ "at" @ Clock @ (bFighting ? "" : "(not fighting yet)"), , 'LongWarX2');
	// (Breaking off during the intro too: as soon as the fight starts, at its first moment.)
	if (Kind == 3 && !bFighting && !bResults && Act.Abort < 0)
	{
		Act.Abort = 0;
		CallAS("SetAbortLabel", Strs(m_strAbortingMission));
		CallAS("AbortAttempted");
		Result = class'LWAirWar'.static.PlayBack(TheUfo, Jet, Stance, Shots, Act);
		return;
	}
	if (!bFighting || bResults || Act.Abort >= 0)
		return;
	switch (Kind)
	{
	case 0:
		if (Act.Aim >= 0 || !class'LWAirWar'.static.ConsumableAllowed(0, Stance) || class'LWAirWar'.static.ConsumableStock(0) <= 0)
			return;
		Act.Aim = Clock;
		break;
	case 1:
		if (Act.Dodge >= 0 || !class'LWAirWar'.static.ConsumableAllowed(1, Stance) || class'LWAirWar'.static.ConsumableStock(1) <= 0)
			return;
		Act.Dodge = Clock;
		break;
	case 2:
		if (Act.Boost >= 0 || class'LWAirWar'.static.ConsumableStock(2) <= 0)
			return;
		Act.Boost = Clock;
		break;
	case 3:
		Act.Abort = Clock;
		CallAS("SetAbortLabel", Strs(m_strAbortingMission));
		CallAS("AbortAttempted");
		break;
	}
	Result = class'LWAirWar'.static.PlayBack(TheUfo, Jet, Stance, Shots, Act);
	SetAbilityButtons(0);
}

/** The fight over: its report (EW's ShowResultScreen), and the campaign told (as UILWInterception.Finished). */
function Finished()
{
	local array<ASValue> Args;
	local string Description, Report;
	local int Outcome;
	local float Health;
	local bool Kill;

	bResults = true;
	switch (Result.Outcome)
	{
	case eLWOutcome_Crashed: Outcome = 1; Description = m_strResult_UFOCrashed; break;
	case eLWOutcome_Destroyed: Outcome = 1; Description = m_strResult_UFODestroyed; break;
	case eLWOutcome_Escaped: Outcome = 0; Description = m_strResult_UFOEscaped; break;
	case eLWOutcome_Disengaged: Outcome = 2; Description = m_strResult_UFODisengaged; CallAS("SetAbortLabel", Strs(m_strAbortedMission)); break;
	}
	Health = Jet.MaxHp > 0 ? float(Max(0, Result.CraftHp)) / float(Jet.MaxHp) : 0.0;
	if (Health <= 0)
	{
		Outcome = 3;
		Report = m_strReport_ShotDown;
	}
	else if (Health < 0.33)
		Report = m_strReport_SevereDamage;
	else if (Health < 0.66)
		Report = m_strReport_HeavyDamage;
	else if (Health < 1.0)
		Report = m_strReport_LightDamage;
	else
		Report = m_strReport_NoDamage;
	SetAbilityButtons(2);
	Args = Strs(Expand(Description) $ "\n" $ Expand(Report));
	Args.AddItem(Num(Outcome));
	Args.AddItem(Str(m_strLeaveReportButtonLabel));
	CallAS("ShowResults", Args);

	if (!bRecorded)
	{
		bRecorded = true;
		Kill = Result.Outcome == eLWOutcome_Crashed || Result.Outcome == eLWOutcome_Destroyed;
		class'XComGameState_LWAirWar'.static.Record(JetIndex, Result.CraftHp, Kill);
		class'LWAirWar'.static.UseConsumables(Act);
		class'XComGameState_LWStrategy'.static.Intercepted(StrategyUfo, int(Result.Outcome), Result.UfoHp);
		`log("LongWarX2: EW interception recorded: jet" @ JetIndex @ "HP" @ Result.CraftHp @ "kill" @ Kill @ "outcome" @ Result.Outcome, , 'LongWarX2');
	}
}

/** EW's report lines: the jet's name for <XGParam:StrValue0/>, a bullet for <Bullet/>. */
function string Expand(string Line)
{
	return Repl(Repl(Line, "<XGParam:StrValue0/>", Callsign), "<Bullet/>", Chr(8226));
}

function Leave()
{
	local UILWGeoscape Geo;

	`log("LongWarX2: EW interception: left", , 'LongWarX2');
	CloseScreen();
	foreach AllActors(class'UILWGeoscape', Geo)
		Geo.Refresh();
}

// --- Input: EW's buttons by their names, its keys --------------------------------------------------------------------

simulated function OnMouseEvent(int Cmd, array<string> Args)
{
	super.OnMouseEvent(Cmd, Args);
	// (391: a movie's release, as EW's UIInterceptionEngagement.OnMouseEvent takes it.)
	if (Cmd != 391 || Args.Length == 0)
		return;
	`log("LongWarX2: EW interception: mouse on" @ ButtonIn(Args) @ "of" @ Args.Length @ "parts, the last '" $ Args[Args.Length - 1] $ "'", , 'LongWarX2');
	switch (ButtonIn(Args))
	{
	// (Closed on the next tick: closing inside the movie's own callback left the screen up, the click tests found.)
	case "leaveReportButton": if (bResults) SetTimer(0.01, false, nameof(Leave)); break;
	case "btnAbort": Use(3); break;
	case "btnTrack": Use(2); break;
	case "btnAim": Use(0); break;
	case "btnDodge": Use(1); break;
	}
}

/** Which of EW's buttons the event names (any part of its path: its last part need not be the button). */
static function string ButtonIn(array<string> Args)
{
	local string A;

	foreach Args(A)
		if (A == "leaveReportButton" || A == "btnAbort" || A == "btnTrack" || A == "btnAim" || A == "btnDodge")
			return A;
	return "";
}

simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	if ((Arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return true;
	`log("LongWarX2: EW interception: input" @ Cmd @ (bResults ? "on the report" : (bFighting ? "in the fight" : "in the intro")), , 'LongWarX2');
	if (bResults)
	{
		switch (Cmd)
		{
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			Leave();
			return true;
		}
		return true;
	}
	// (During the fight Esc, a pad's B or a right click break off, as EW's B did; nothing closes the screen mid-fight.)
	switch (Cmd)
	{
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		Use(3);
		return true;
	case class'UIUtilities_Input'.const.FXS_BUTTON_X:
		Use(0);
		return true;
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		Use(1);
		return true;
	case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
		Use(2);
		return true;
	}
	return true;
}

defaultproperties
{
	UIPackage = "EWInterceptionUI"
	// (EW's: UIInterceptionEngagement on UIDisplay_Interception through MissionControl_UIDisplayCam_Interception.)
	EWDisplay = UIDisplay_Interception
	EWDisplayCamera = MissionControl_UIDisplayCam_Interception
	BaseCamera = MissionControl_UIDisplayCam_Interception
	StrategyUfo = -1
	Stance = 1
}
