// A few seconds' watch over XCOM 2's 3D display meshes (UIScreenListener_LWX2Displays). A 3D screen's display lives in its
// blueprint's own level, which the world's actor lists do not reach: XCOM 2's UIMovie_3D finds it there to show the screen
// on it (ShowDisplayByTag) but never to hide it again (HideAllDisplays goes through the world's actors), and its mesh had
// been detached while EW's base hid the world. So here, for the 3D screen on top (its DisplayTag): its blueprint's display
// attached again once XCOM 2 has shown the movie on it, and the displays of other blueprints still showing the movie hidden,
// as HideAllDisplays would have. And a SHIV on the armory's platform given EW's body once its pawn is there.
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

/** The armory's pawn on its platform: made while the armory's room was hidden (opened from squad select in EW's hangar), it
 *  stood at the world's origin, the placement not found then. A SHIV in EW's body (ApplyBody is once only). */
static function SHIVOnPlatform()
{
	local UIArmory Armory;
	local XComGameState_Unit Unit;
	local Actor Place;

	Armory = `HQPRES != none ? UIArmory(`HQPRES.ScreenStack.GetFirstInstanceOf(class'UIArmory')) : none;
	if (Armory == none || XComUnitPawn(Armory.ActorPawn) == none)
		return;
	Place = Armory.GetPlacementActor();
	if (Place != none && VSize(Armory.ActorPawn.Location - Place.Location) > 64 && VSize(Armory.ActorPawn.Location) < 1)
	{
		Armory.ActorPawn.SetLocation(Place.Location);
		`log("LongWarX2: 3D screens: the armory's pawn put on its platform", , 'LongWarX2');
	}
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Armory.UnitReference.ObjectID));
	if (class'LWMECs'.static.IsMEC(Unit))
		class'LWX2EWBodies'.static.ApplyToPawn(XComUnitPawn(Armory.ActorPawn), Unit.GetMyTemplateName(), class'LWX2EWBodies'.static.ArmorOf(Unit), Unit);
	if (class'LWSHIVs'.static.IsSHIV(Unit))
	{
		class'LWX2EWBodies'.static.ApplyToPawn(XComUnitPawn(Armory.ActorPawn), Unit.GetMyTemplateName(), , Unit);
		// (The menu fills its list after the screen's init: what is not a SHIV's greyed again once it has.)
		class'UIScreenListener_LWX2SHIVArmory'.static.Limit(UIArmory_MainMenu(Armory));
	}
}

/** The display tag of the 3D screen on top, if it says one. */
static function name ActiveTag()
{
	local UIScreen Top;

	Top = `HQPRES != none ? `HQPRES.ScreenStack.GetCurrentScreen() : none;
	// (The armory's mouse guard sits over it on the stack.)
	if (UIMouseGuard(Top) != none)
		Top = `HQPRES.ScreenStack.GetFirstInstanceOf(class'UIArmory');
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
	SHIVOnPlatform();
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
