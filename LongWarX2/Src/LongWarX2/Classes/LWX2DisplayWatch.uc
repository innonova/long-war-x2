// A few seconds' watch over XCOM 2's 3D display meshes (UIScreenListener_LWX2Displays). A 3D screen's display lives in its
// blueprint's own level, which the world's actor lists do not reach: XCOM 2's UIMovie_3D finds it there to show the screen
// on it (ShowDisplayByTag) but never to hide it again (HideAllDisplays goes through the world's actors), and its mesh had
// been detached while EW's base hid the world. So here, for the 3D screen on top (its DisplayTag): its blueprint's display
// attached again once XCOM 2 has shown the movie on it, and the displays of other blueprints still showing the movie hidden,
// as HideAllDisplays would have.
class LWX2DisplayWatch extends Actor;

var int Checks;

static function Watch(Actor Outer)
{
	local LWX2DisplayWatch W;

	foreach Outer.WorldInfo.AllActors(class'LWX2DisplayWatch', W)
	{
		W.Checks = 0;
		return;
	}
	W = Outer.Spawn(class'LWX2DisplayWatch');
	W.Check();
	W.SetTimer(0.25, true, nameof(Check));
}

/** The display tag of the 3D screen on top, if it says one. */
static function name ActiveTag()
{
	local UIScreen Top;

	Top = `HQPRES != none ? `HQPRES.ScreenStack.GetCurrentScreen() : none;
	if (UIArmory(Top) != none)
		return UIArmory(Top).DisplayTag;
	if (UICustomize(Top) != none)
		return UICustomize(Top).DisplayTag;
	return '';
}

function Check()
{
	local XComBlueprint Blueprint;
	local UIDisplay_LevelActor Display;
	local array<Actor> Actors;
	local Actor A;
	local name Active;
	local int Attached, Hidden;

	Active = ActiveTag();
	foreach WorldInfo.AllActors(class'XComBlueprint', Blueprint)
	{
		Actors.Length = 0;
		Blueprint.GetLoadedLevelActors(Actors);
		foreach Actors(A)
		{
			Display = UIDisplay_LevelActor(A);
			if (Display == none || Display.StaticMeshComponent == none || Display.m_kMovie == none)
				continue;
			if (Active != '' && Blueprint.Tag != Active)
			{
				Display.m_kMovie = none;
				Display.StaticMeshComponent.SetHidden(true);
				Display.SetCollisionType(COLLIDE_NoCollision);
				Hidden++;
			}
			else if (!Display.StaticMeshComponent.bAttached)
			{
				Display.AttachComponent(Display.StaticMeshComponent);
				Attached++;
			}
		}
	}
	if (Attached + Hidden > 0)
		`log("LongWarX2: 3D screens:" @ Attached @ "display meshes attached again," @ Hidden @ "hidden (" $ Active $ ")", , 'LongWarX2');
	if (++Checks >= 20)
	{
		ClearTimer(nameof(Check));
		Destroy();
	}
}

defaultproperties
{
	bHidden = true
}
