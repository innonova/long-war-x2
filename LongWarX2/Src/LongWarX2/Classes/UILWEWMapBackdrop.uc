// The black background behind EW's Situation Room (features/lw-ew-screens.md): in EW its Flash lay over a 3D room; here,
// loaded into the movie without joining the screen stack, before the Situation Room, so the Avenger no longer shows
// through. It also loads EW's converted Situation Room package (EWSitRoomMap.upk: its earth, made teal by
// tools/convert/ew-earth.ts), whose earth the Situation Room puts into its map area (UILWEWSituationRoom.AddEarth).
class UILWEWMapBackdrop extends UIScreen;

/** The black background, before the Situation Room; EW's earth package loaded (by its world, then the earth is found by
 *  its own path). */
static function bool ShowIfAvailable()
{
	local XComHQPresentationLayer HQPres;
	local UILWEWMapBackdrop Backdrop;
	local Object Earth, World;

	HQPres = `HQPRES;
	if (HQPres == none)
		return false;
	World = DynamicLoadObject("EWSitRoomMap.TheWorld", class'Object', true);
	Earth = DynamicLoadObject("FX_Globe.T_Earth_Holo", class'Texture2D', true);
	`log("LongWarX2: EW screen: the earth" @ (Earth != none ? PathName(Earth) : "not found") $ (World != none ? ", from" @ PathName(World) : ""), , 'LongWarX2');
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
	// Two of XCOM 2's dark boxes over the whole stage: black enough.
	Spawn(class'UIBGBox', self).InitBG('LWEWBlack0', 0, 0, 1920, 1080);
	Spawn(class'UIBGBox', self).InitBG('LWEWBlack1', 0, 0, 1920, 1080);
}

defaultproperties
{
	InputState = eInputState_None
	bConsumeMouseEvents = false
}
