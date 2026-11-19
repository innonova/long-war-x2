// Enemy Within's objectives panel (features/ew-sitroom-ticker.md): its ObjectivesScreen movie, as EW's UIObjectivesScreen
// drives it over the Situation Room's main view: OBJECTIVES, the objective's steps in brief (UISituationRoom.
// RealizeObjectives' small text), and MORE INFO (its button) for each step's explanation, BACK to the brief again. Its
// contents are Long War's objective (LWObjectives). Opened by the hub while the Situation Room is entered (not on the screen
// stack: the hub keeps the keys; the movie's button still reaches it through its path).
class UILWEWObjectives extends UILWEWScreen;

var bool bLarge;

static function UILWEWObjectives Make(UIScreen Owner)
{
	local UILWEWObjectives O;

	DynamicLoadObject(default.UIPackage $ ".ewxObjectivesScreen", class'Object', true);
	O = Owner.Spawn(class'UILWEWObjectives', Owner);
	O.Package = name("/ package/ewxObjectivesScreen/ObjectivesScreen");
	O.MCName = 'theScreen';
	O.InitScreen(XComPlayerController(Owner.Movie.Pres.Owner), Owner.Movie);
	Owner.Movie.LoadScreen(O);
	return O;
}

simulated function OnInit()
{
	super.OnInit();
	Refresh();
}

/** UIObjectivesScreen.RefreshContents: the title, the button's labels, the brief and the full text; hidden with no
 *  objective (CanBeShown). */
function Refresh()
{
	local XComGameState_LWStrategy S;
	local array<ASValue> Params;
	local string Brief;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (!bIsInited || S == none)
		return;
	Brief = class'LWObjectives'.static.Brief(S);
	if (Brief == "")
	{
		Hide();
		return;
	}
	Params.AddItem(Str(class'LWObjectives'.default.Header != "" ? class'LWObjectives'.default.Header : "OBJECTIVES"));
	CallNow("SetTitle", Params);
	Params.Length = 0;
	Params.AddItem(Str(class'LWObjectives'.default.Back != "" ? class'LWObjectives'.default.Back : "BACK"));
	Params.AddItem(Str(class'LWObjectives'.default.MoreInfo != "" ? class'LWObjectives'.default.MoreInfo : "MORE INFO"));
	CallNow("SetLabels", Params);
	Params.Length = 0;
	Params.AddItem(Str(Brief));
	CallNow("SetSmallBody", Params);
	Params.Length = 0;
	Params.AddItem(Str(class'LWObjectives'.static.Large(S)));
	CallNow("SetLargeBody", Params);
	ShowLarge(bLarge);
	Show();
}

/** MORE INFO and BACK (UIObjectivesScreen.ShowLarge, ShowSmall). */
function ShowLarge(bool bShow)
{
	local array<ASValue> Params;
	local ASValue V;

	bLarge = bShow;
	V.Type = AS_Boolean;
	V.b = bShow;
	Params.AddItem(V);
	CallNow("ShowLarge", Params);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	// (UIObjectivesScreen.OnMouseEvent: the button, MORE INFO or BACK, on its release.)
	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP && args.Length > 0 && args[args.Length - 1] == "button")
	{
		ShowLarge(!bLarge);
		return;
	}
	super.OnMouseEvent(cmd, args);
}

defaultproperties
{
	bConsumeMouseEvents = false
}
