// Long War 1.0's interception screen, built from XCOM 2's UI pieces
// (features/hard-parts.md, experiment 3): the jet and the UFO, the stance,
// the odds at it, then the fight played out as it is rolled (LWAirWar), with
// Aim, Dodge, Boost and breaking off as Long War has them. From a campaign,
// the jet's damage and kills go into the campaign's state.
class UILWInterception extends UIScreen;

/** Opened from a campaign's geoscape: its jets, its month; else a demo jet. */
var bool bCampaign;

/** How many fights the odds are counted from. */
var int OddsRuns;

var int JetIndex;
var int UfoIndex;
var int Stance;
var int Category;
var array<int> UfoTypes;

var LWAirWar.LWShip Jet;
var LWAirWar.LWShip TheUfo;
var array<LWAirWar.LWShot> Shots;
var LWAirWar.LWActions Act;
var LWAirWar.LWResult Result;

/** The fight being played back: its clock, and how many of its events are shown. */
var bool bFighting;
var bool bDone;
var float Clock;
var int Shown;
var int HpJet;
var int HpUfo;
var array<string> LogLines;
var string JetInfo, UfoInfo;

var UIText Title, SubTitle, JetText, UfoText, OddsText, LogText, OutcomeText;
var UIProgressBar JetBar, UfoBar;
var UIButton StanceButtons[3];
var UIButton EngageButton, AimButton, DodgeButton, BoostButton, AbortButton, PrevUfoButton, NextUfoButton, NextJetButton, CloseButton;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int i;

	super.InitScreen(InitController, InitMovie, InitName);
	UfoTypes = class'LWAirWar'.static.UfoTypes();
	Stance = 1;
	Category = bCampaign ? CampaignCategory() : 4;

	Spawn(class'UIBGBox', self).InitBG('LWBg', 360, 120, 1200, 840);
	Title = Spawn(class'UIText', self).InitText('LWTitle', "LONG WAR: AIR WAR", true);
	Title.SetPosition(390, 140);
	Title.SetWidth(800);
	SubTitle = Spawn(class'UIText', self).InitText('LWSub', "");
	SubTitle.SetPosition(390, 196);
	SubTitle.SetWidth(1140);

	JetText = Spawn(class'UIText', self).InitText('LWJet', "");
	JetText.SetPosition(390, 250);
	JetText.SetSize(540, 150);
	JetBar = Spawn(class'UIProgressBar', self).InitProgressBar('LWJetBar', 390, 410, 540, 14, 1.0, eUIState_Good);
	UfoText = Spawn(class'UIText', self).InitText('LWUfo', "");
	UfoText.SetPosition(990, 250);
	UfoText.SetSize(540, 150);
	UfoBar = Spawn(class'UIProgressBar', self).InitProgressBar('LWUfoBar', 990, 410, 540, 14, 1.0, eUIState_Bad);

	for (i = 0; i < 3; i++)
	{
		StanceButtons[i] = Spawn(class'UIButton', self).InitButton(name("LWStance" $ i), "", OnStance);
		StanceButtons[i].SetPosition(390 + i * 200, 450);
	}
	PrevUfoButton = Spawn(class'UIButton', self).InitButton('LWPrevUfo', "PREV UFO", OnPrevUfo);
	PrevUfoButton.SetPosition(990, 450);
	NextUfoButton = Spawn(class'UIButton', self).InitButton('LWNextUfo', "NEXT UFO", OnNextUfo);
	NextUfoButton.SetPosition(1150, 450);
	NextJetButton = Spawn(class'UIButton', self).InitButton('LWNextJet', "NEXT JET", OnNextJet);
	NextJetButton.SetPosition(1310, 450);

	OddsText = Spawn(class'UIText', self).InitText('LWOdds', "");
	OddsText.SetPosition(390, 510);
	OddsText.SetWidth(1140);

	EngageButton = Spawn(class'UIButton', self).InitButton('LWEngage', "ENGAGE", OnEngage);
	EngageButton.SetPosition(390, 570);
	AimButton = Spawn(class'UIButton', self).InitButton('LWAim', "AIM", OnAim);
	AimButton.SetPosition(560, 570);
	DodgeButton = Spawn(class'UIButton', self).InitButton('LWDodge', "DODGE", OnDodge);
	DodgeButton.SetPosition(700, 570);
	BoostButton = Spawn(class'UIButton', self).InitButton('LWBoost', "BOOST", OnBoost);
	BoostButton.SetPosition(840, 570);
	AbortButton = Spawn(class'UIButton', self).InitButton('LWAbort', "BREAK OFF", OnAbort);
	AbortButton.SetPosition(980, 570);

	OutcomeText = Spawn(class'UIText', self).InitText('LWOutcome', "");
	OutcomeText.SetPosition(390, 630);
	OutcomeText.SetWidth(1140);
	LogText = Spawn(class'UIText', self).InitText('LWLog', "");
	LogText.SetPosition(390, 680);
	LogText.SetSize(1140, 240);

	CloseButton = Spawn(class'UIButton', self).InitButton('LWClose', "CLOSE", OnClose);
	CloseButton.SetPosition(1420, 900);

	Setup();
}

/** The aliens' progress: Long War's category grows about one a month (alien research / 30). */
simulated function int CampaignCategory()
{
	local XComGameState_GameTime Time;
	local TDateTime Start;

	Time = XComGameState_GameTime(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_GameTime', true));
	if (Time == none)
		return 0;
	class'X2StrategyGameRulesetDataStructures'.static.SetTime(Start, 0, 0, 0,
		class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
		class'X2StrategyGameRulesetDataStructures'.default.START_DAY,
		class'X2StrategyGameRulesetDataStructures'.default.START_YEAR);
	return Max(0, class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(Time.CurrentTime, Start));
}

/** The jet and the UFO for the choices made; the odds at the stance. */
simulated function Setup()
{
	local XComGameState_LWAirWar AirWar;
	local int Crashed, Destroyed, Escaped, Lost, i;
	local string Callsign;

	AirWar = bCampaign ? class'XComGameState_LWAirWar'.static.Get() : none;
	if (AirWar != none && AirWar.Jets.Length > 0)
	{
		JetIndex = JetIndex % AirWar.Jets.Length;
		Jet = class'LWAirWar'.static.Craft(AirWar.Jets[JetIndex].Type, AirWar.Jets[JetIndex].Weapon, Category);
		Jet.Hp = AirWar.Jets[JetIndex].Hp;
		Jet.Kills = AirWar.Jets[JetIndex].Kills;
		Callsign = AirWar.Jets[JetIndex].Callsign;
	}
	else
	{
		Jet = class'LWAirWar'.static.Craft(1, 3, Category);
		Callsign = "Demo";
	}
	TheUfo = class'LWAirWar'.static.Ufo(UfoTypes[UfoIndex], Category);
	HpJet = Jet.Hp;
	HpUfo = TheUfo.Hp;
	bFighting = false;
	bDone = false;
	LogLines.Length = 0;

	SubTitle.SetText((bCampaign ? "This campaign" : "Demo (no campaign)") $ ": the aliens at category" @ Category $ ". Long War 1.0's rules and numbers.");
	JetInfo = Callsign @ "-" @ Jet.Name @ "-" @ WeaponsOf(Jet) $ "\n" $ "Armor" @ Jet.Armor $ ", penetration" @ Jet.Ap $ ", speed" @ int(Jet.BattleSpeed) $ ", kills" @ Jet.Kills;
	UfoInfo = TheUfo.Name @ "(" $ TheUfo.Size $ ") -" @ WeaponsOf(TheUfo) $ "\n" $ "Armor" @ TheUfo.Armor $ ", penetration" @ TheUfo.Ap $ ", speed" @ int(TheUfo.BattleSpeed);
	for (i = 0; i < 3; i++)
		StanceButtons[i].SetText(i == Stance ? "[" @ Caps(class'LWAirWar'.static.StanceName(i)) @ "]" : Caps(class'LWAirWar'.static.StanceName(i)));
	NextJetButton.SetDisabled(!bCampaign);

	if (Jet.Hp <= 0)
		OddsText.SetText("This jet is lost.");
	else
	{
		class'LWAirWar'.static.Odds(TheUfo, Jet, Stance, OddsRuns, Crashed, Destroyed, Escaped, Lost);
		OddsText.SetText("Of" @ OddsRuns @ "fights at this stance, with no consumables: down" @ Pct(Crashed + Destroyed) $ " (broke up" @ Pct(Destroyed) $ "), got away" @ Pct(Escaped) $ "; the jet lost" @ Pct(Lost) $ ". It keeps up for" @ int(class'LWAirWar'.static.EscapeTime(TheUfo, Jet, 0)) @ "s.");
	}
	OutcomeText.SetText("");
	LogText.SetText("");
	UpdateBars();
	UpdateButtons();
}

simulated function string Pct(int n)
{
	return string(int(n * 100.0 / OddsRuns + 0.5)) $ "%";
}

simulated function string WeaponsOf(LWAirWar.LWShip S)
{
	local string Out;
	local int i;

	for (i = 0; i < S.Weapons.Length; i++)
		Out $= (i > 0 ? " + " : "") $ S.Weapons[i].Name;
	return Out == "" ? "unarmed" : Out;
}

simulated function UpdateBars()
{
	JetBar.SetPercent(FClamp(float(HpJet) / Jet.MaxHp, 0.0, 1.0));
	UfoBar.SetPercent(FClamp(float(HpUfo) / TheUfo.MaxHp, 0.0, 1.0));
	JetText.SetText(JetInfo $ "\nHP" @ Max(0, HpJet) @ "/" @ Jet.MaxHp);
	UfoText.SetText(UfoInfo $ "\nHP" @ Max(0, HpUfo) @ "/" @ TheUfo.MaxHp);
}

simulated function UpdateButtons()
{
	local int i;

	EngageButton.SetDisabled(bFighting || Jet.Hp <= 0);
	AimButton.SetDisabled(!bFighting || Act.Aim >= 0 || !class'LWAirWar'.static.ConsumableAllowed(0, Stance));
	DodgeButton.SetDisabled(!bFighting || Act.Dodge >= 0 || !class'LWAirWar'.static.ConsumableAllowed(1, Stance));
	BoostButton.SetDisabled(!bFighting || Act.Boost >= 0);
	AbortButton.SetDisabled(!bFighting || Act.Abort >= 0);
	for (i = 0; i < 3; i++)
		StanceButtons[i].SetDisabled(bFighting);
	PrevUfoButton.SetDisabled(bFighting);
	NextUfoButton.SetDisabled(bFighting);
}

// --- The fight, played back ------------------------------------------------------

simulated function OnEngage(UIButton Button)
{
	// After a fight: the button reads AGAIN, and sets the next one up.
	if (bDone)
	{
		EngageButton.SetText("ENGAGE");
		Setup();
		return;
	}
	Shots = class'LWAirWar'.static.RollShots(TheUfo, Jet, Stance, false);
	Act = class'LWAirWar'.static.NoActions();
	Result = class'LWAirWar'.static.PlayBack(TheUfo, Jet, Stance, Shots, Act);
	Clock = 0;
	Shown = 0;
	bFighting = true;
	bDone = false;
	LogLines.Length = 0;
	OutcomeText.SetText("Engaging at" @ class'LWAirWar'.static.StanceName(Stance) $ "...");
	UpdateButtons();
}

/** A consumable or breaking off, now: the rest of the fight played back again from the same shots. */
simulated function Replay()
{
	Result = class'LWAirWar'.static.PlayBack(TheUfo, Jet, Stance, Shots, Act);
	UpdateButtons();
}

simulated function OnAim(UIButton Button) { Act.Aim = Clock; Replay(); }
simulated function OnDodge(UIButton Button) { Act.Dodge = Clock; Replay(); }
simulated function OnBoost(UIButton Button) { Act.Boost = Clock; Replay(); }
simulated function OnAbort(UIButton Button) { Act.Abort = Clock; Replay(); }

simulated event Tick(float DeltaTime)
{
	local LWAirWar.LWEvent E;

	super.Tick(DeltaTime);
	if (!bFighting)
		return;
	Clock += DeltaTime;
	while (Shown < Result.Events.Length && Result.Events[Shown].Time <= Clock)
	{
		E = Result.Events[Shown++];
		ShowEvent(E);
		if (E.Kind == eLWEvent_End)
		{
			Finished();
			return;
		}
	}
}

simulated function ShowEvent(LWAirWar.LWEvent E)
{
	local string Who, Line;

	Who = E.Source == 1 ? Jet.Weapons[E.Slot].Name : TheUfo.Weapons[E.Slot].Name;
	switch (E.Kind)
	{
		case eLWEvent_Shot:
			if (E.Damage > 0)
				Line = Who @ (E.Source == 1 ? "fired at the" @ TheUfo.Name : "fired at the jet") $ (E.Aimed ? " (Aim)" : "");
			else
				Line = Who $ ": missed";
			break;
		case eLWEvent_Hit:
			if (E.Source == 1)
				HpUfo = E.Hp;
			else
				HpJet = E.Hp;
			Line = Who @ "hit for" @ E.Damage $ (E.Crit ? " (critical)" : "") $ ":" @ (E.Source == 1 ? TheUfo.Name : "the jet") @ "at" @ Max(0, E.Hp) @ "HP";
			UpdateBars();
			break;
		case eLWEvent_Dodged: Line = "Dodged:" @ Who @ "missed the jet"; break;
		case eLWEvent_Aim: Line = "Aim: the next two missed shots will hit"; break;
		case eLWEvent_Dodge: Line = "Dodge: the next two hits on the jet will miss"; break;
		case eLWEvent_Boost: Line = "Boost: the jet keeps up for longer"; break;
		case eLWEvent_Abort: Line = "Breaking off"; break;
		default: return;
	}
	LogLines.AddItem(Seconds(E.Time) $ " s   " $ Line);
	if (LogLines.Length > 9)
		LogLines.Remove(0, LogLines.Length - 9);
	LogText.SetText(JoinLines(LogLines));
}

/** "12.3" */
simulated function string Seconds(float T)
{
	local int Tenths;

	Tenths = int(T * 10);
	return string(Tenths / 10) $ "." $ string(Tenths % 10);
}

simulated function string JoinLines(array<string> Lines)
{
	local string Out;
	local int i;

	for (i = 0; i < Lines.Length; i++)
		Out $= (i > 0 ? "\n" : "") $ Lines[i];
	return Out;
}

simulated function Finished()
{
	local bool Kill;

	bFighting = false;
	bDone = true;
	Kill = Result.Outcome == eLWOutcome_Crashed || Result.Outcome == eLWOutcome_Destroyed;
	OutcomeText.SetText(class'LWAirWar'.static.OutcomeText(Result, TheUfo) $ (bCampaign ? " Recorded in the campaign." : ""));
	if (bCampaign)
	{
		class'XComGameState_LWAirWar'.static.Record(JetIndex, Result.CraftHp, Kill);
		`log("LongWarX2: interception recorded: jet" @ JetIndex @ "HP" @ Result.CraftHp @ "kill" @ Kill, , 'LongWarX2');
	}
	UpdateButtons();
	EngageButton.SetText("AGAIN");
	EngageButton.SetDisabled(false);
}

// --- Choices ----------------------------------------------------------------------

simulated function OnStance(UIButton Button)
{
	local int i;

	for (i = 0; i < 3; i++)
		if (StanceButtons[i] == Button)
			Stance = i;
	Setup();
}

simulated function OnPrevUfo(UIButton Button)
{
	UfoIndex = (UfoIndex + UfoTypes.Length - 1) % UfoTypes.Length;
	Setup();
}

simulated function OnNextUfo(UIButton Button)
{
	UfoIndex = (UfoIndex + 1) % UfoTypes.Length;
	Setup();
}

simulated function OnNextJet(UIButton Button)
{
	JetIndex++;
	Setup();
}

simulated function OnClose(UIButton Button)
{
	CloseScreen();
}

defaultproperties
{
	InputState = eInputState_Consume;
	OddsRuns = 1000;
}
