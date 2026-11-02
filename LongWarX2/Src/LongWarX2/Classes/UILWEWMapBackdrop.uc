// The world around EW's Situation Room (features/lw-ew-screens.md): in EW its Flash lies over a 3D room with a world map.
// Here, loaded into the movie without joining the screen stack: a black background before the Situation Room (the
// Avenger no longer shows through), and EW's own holographic earth (FX_Globe.T_Earth_Holo, from EW's
// Static_SituationRoom package converted by tools/convert/ew-package.ts as EWSitRoomMap.upk) after it, half seen over the
// movie's map where that maps 0..1 (longitude and latitude): under it, the map's tinted panel left it too dark to read.
class UILWEWMapBackdrop extends UIScreen;

var UIImage Earth;
/** The earth (over the Situation Room) rather than the black background (under it). */
var bool bEarth;

/** The black background (bWithEarth false: before the Situation Room) or the earth (true: after it); false when the
 *  earth's converted package is not there. */
static function bool ShowIfAvailable(bool bWithEarth)
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
	if (bWithEarth && Earth == none)
		return false;
	Backdrop = HQPres.Spawn(class'UILWEWMapBackdrop', HQPres);
	Backdrop.bEarth = bWithEarth;
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
	if (!bEarth)
	{
		// Two of XCOM 2's dark boxes over the whole stage: black enough.
		Spawn(class'UIBGBox', self).InitBG('LWEWBlack0', 0, 0, 1920, 1080);
		Spawn(class'UIBGBox', self).InitBG('LWEWBlack1', 0, 0, 1920, 1080);
		return;
	}
	// The movie's map, 0..1 across both ways, measured on XCOM 2's 1920 x 1080 stage (the Situation Room scaled to it).
	Earth = Spawn(class'UIImage', self).InitImage('LWEWEarth', "img:///FX_Globe.T_Earth_Holo");
	Earth.SetPosition(590, 158);
	Earth.SetSize(750, 498);
	Earth.SetAlpha(50);
}

defaultproperties
{
	InputState = eInputState_None
	bConsumeMouseEvents = false
}
