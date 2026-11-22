// One of EW's movies kept loaded, hidden and without input, beneath the hub for as long as the base is up
// (features/e2e-tests.md, 2026-11-22). Flash's classes are global and the first movie to define one wins: EW's Mission
// Control movie defines its list's classes (MissionControl_MissionList, its items) itself, so once the first Mission
// Control screen closed and its movie was unloaded, the next one's list worked no more (rows without text, no new rows;
// the alerts load the same movie). Loaded here first and never closed, its definitions stay.
class UILWEWMovieKeeper extends UILWEWScreen;

static function Keep(XComHQPresentationLayer HQPres, string Group, string MovieName)
{
	local UILWEWMovieKeeper K;

	foreach HQPres.AllActors(class'UILWEWMovieKeeper', K)
		if (K.Package == name("/ package/" $ Group $ "/" $ MovieName))
			return;
	DynamicLoadObject(default.UIPackage $ "." $ Group, class'Object', true);
	K = HQPres.Spawn(class'UILWEWMovieKeeper', HQPres);
	K.Package = name("/ package/" $ Group $ "/" $ MovieName);
	K.MCName = name("keep" $ MovieName);
	HQPres.ScreenStack.Push(K);
	`log("LongWarX2: EW movie kept loaded:" @ MovieName, , 'LongWarX2');
}

simulated function OnInit()
{
	super(UIScreen).OnInit();
	Hide();
}

simulated function OnReceiveFocus();
simulated function OnLoseFocus();
simulated function Show();
simulated function bool OnUnrealCommand(int cmd, int arg) { return false; }
simulated function OnMouseEvent(int cmd, array<string> args);

defaultproperties
{
	InputState = eInputState_None
	bShowsBase = false
}
