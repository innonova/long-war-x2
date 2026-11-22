// A new campaign's first mission launched once its setup is done (UIScreenListener_LWX2FirstMission).
// XCOM 2's new campaign (XGStrategy, state Initing) prepares the first mission, then waits for the movie
// playing to end before launching it: there, the campaign's intro film played as the loading screen, which
// ends or is skipped. The port leaves XCOM 2's intro out (UILWEWDifficulty.Start), so the movie playing
// then is XCOM 2's looping loading screen, which neither ends nor takes a key: the wait never ended and the
// game stood on the loading screen for ever (aek 2026-11-22). That movie is stopped here once the wait has
// begun, which is what skipping the intro did.
class LWX2FirstMissionStart extends Actor config(LWAirWar);

/** Set by the campaign's start (the EW new-game screen, the control port), across the map change to the
 *  strategy map; cleared once the first mission is on its way. (Config only so that its default may be set: never in an
 *  ini, never saved.) */
var config bool bPending;
/** The main menu's start screen's choice (UILWStartSelect in the shell), for the campaign's start state
 *  (XComGameState_LWStartChoice); -1 none. (Config only so that its default may be set.) */
var config int StartHome, StartChoice;
var float Waited;

static function Expect()
{
	default.bPending = true;
}

event Tick(float DeltaTime)
{
	local XGStrategy Strategy;

	Waited += DeltaTime;
	Strategy = `GAME;
	if (!default.bPending || Waited > 600)
	{
		default.bPending = false;
		Destroy();
		return;
	}
	if (Strategy == none)
		return;
	if (!Strategy.IsInState('Initing'))
	{
		// (Past the campaign's start, or a strategy map that is not one: nothing to wait for.)
		if (Waited > 5)
		{
			default.bPending = false;
			Destroy();
		}
		return;
	}
	// (StartNewGame has run when the history holds more than the campaign's start state; it, the plot's preload
	// and the wait follow one another in one tick of the state's code, so the wait has begun.)
	if (`XCOMHISTORY.GetNumGameStates() <= 1 || !class'XComEngine'.static.IsAnyMoviePlaying())
		return;
	`log("LongWarX2: new campaign: the loading screen stopped, so that the first mission launches (no XCOM 2 intro)", , 'LongWarX2');
	class'XComEngine'.static.StopCurrentMovie();
	default.bPending = false;
	Destroy();
}

defaultproperties
{
	bAlwaysTick = true;
	StartHome = -1;
}
