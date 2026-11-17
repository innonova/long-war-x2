// Enemy Within's Situation Room HUD (its SituationRoomHUD movie, EW's UISituationRoomHUD) over the port's Situation Room in
// its satellites' view (UILWEWSituationRoom.bSatellite): the continent's panel (its name, the country's staff and bonuses),
// the country's panel (its name, funding, panic, satellite) and the launch button, filled by the Situation Room. It takes
// no input of its own but its buttons' clicks, which go to the Situation Room, as EW's do.
class UILWEWSituationRoomHUD extends UILWEWScreen;

var UILWEWSituationRoom SitRoom;

static function UILWEWSituationRoomHUD Open(XComHQPresentationLayer HQPres, UILWEWSituationRoom Owner)
{
	local UILWEWSituationRoomHUD EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxSituationRoomHUD", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWSituationRoomHUD', HQPres);
	EWScreen.Package = name("/ package/ewxSituationRoomHUD/SituationRoomHUD");
	EWScreen.MCName = 'theScreen';
	EWScreen.SitRoom = Owner;
	HQPres.ScreenStack.Push(EWScreen);
	return EWScreen;
}

simulated function OnInit()
{
	super.OnInit();
	// (DISPLAY_MODE_SATELLITE.)
	MC.FunctionNum("SetDisplayMode", 0);
	if (SitRoom != none)
		SitRoom.UpdateSatelliteHUD();
}

function SetContinentInfo(string ContinentName, string Body)
{
	MC.BeginFunctionOp("SetContinentInfo");
	MC.QueueString(ContinentName);
	MC.QueueString(Body);
	MC.QueueNumber(0);
	MC.EndOp();
}

function SetCountryInfo(string CountryName, string Body, int Panic)
{
	MC.BeginFunctionOp("SetCountryInfo");
	MC.QueueString(CountryName);
	MC.QueueString(Body);
	MC.QueueNumber(Panic);
	MC.EndOp();
}

function SetSatStatus(bool bHas)
{
	MC.BeginFunctionOp("SetSatStatus");
	MC.QueueBoolean(bHas);
	MC.EndOp();
}

function SetLaunchButton(string Label, bool bEnabled)
{
	MC.BeginFunctionOp("SetLaunchButton");
	MC.QueueString("");
	MC.QueueString(Label);
	MC.QueueBoolean(bEnabled);
	MC.EndOp();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (Target == "launchButtonMC" && cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP && SitRoom != none)
	{
		SitRoom.AskLaunch();
		return;
	}
	super.OnMouseEvent(cmd, args);
}

/** The keys and clicks elsewhere go on to the Situation Room under it. */
simulated function bool OnUnrealCommand(int cmd, int arg)
{
	return false;
}

defaultproperties
{
	InputState = eInputState_None
}
