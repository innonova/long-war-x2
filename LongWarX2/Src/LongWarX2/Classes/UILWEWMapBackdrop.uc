// The world behind EW's Situation Room (features/lw-ew-screens.md): in EW its Flash lies over a 3D world map in the
// room; here EW's own holographic earth (FX_Globe.T_Earth_Holo, from EW's Static_SituationRoom package converted by
// tools/convert/ew-package.ts as EWSitRoomMap.upk) is drawn where the movie's map maps 0..1 (longitude and latitude),
// under the movie. Loaded into the movie without joining the screen stack, before the Situation Room, so it lies below.
class UILWEWMapBackdrop extends UIScreen;

var UIImage Earth;

/** Shown under where the Situation Room will be loaded; false when the converted map package is not there. */
static function bool ShowIfAvailable()
{
	local XComHQPresentationLayer HQPres;
	local UILWEWMapBackdrop Backdrop;
	local Object Earth, World;

	HQPres = `HQPRES;
	if (HQPres == none)
		return false;
	// The converted package loaded whole (by its world) first, then its earth found by its own path.
	World = DynamicLoadObject("EWSitRoomMap.TheWorld", class'Object', true);
	Earth = DynamicLoadObject("FX_Globe.T_Earth_Holo", class'Texture2D', true);
	`log("LongWarX2: EW screen: the earth" @ (Earth != none ? PathName(Earth) : "not found") $ (World != none ? ", from" @ PathName(World) : ""), , 'LongWarX2');
	if (Earth == none)
		return false;
	HideAll();
	Backdrop = HQPres.Spawn(class'UILWEWMapBackdrop', HQPres);
	Backdrop.InitScreen(XComPlayerController(HQPres.Owner), HQPres.Get2DMovie());
	HQPres.Get2DMovie().LoadScreen(Backdrop);
	return true;
}

static function HideAll()
{
	local UILWEWMapBackdrop Backdrop;

	foreach `HQPRES.AllActors(class'UILWEWMapBackdrop', Backdrop)
	{
		`HQPRES.Get2DMovie().RemoveScreen(Backdrop);
		Backdrop.Destroy();
	}
}

simulated function OnInit()
{
	super.OnInit();
	// The movie's map, 0..1 across both ways, measured on XCOM 2's 1920 x 1080 stage (the Situation Room scaled to it).
	Earth = Spawn(class'UIImage', self).InitImage('LWEWEarth', "img:///FX_Globe.T_Earth_Holo");
	Earth.SetPosition(590, 158);
	Earth.SetSize(750, 498);
}

defaultproperties
{
	InputState = eInputState_None
	bConsumeMouseEvents = false
}
