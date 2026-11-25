// Enemy Within's own ChooseFacility screen (features/lw-base-view.md): the facilities Long War can build on an empty tile,
// on EW's movie as EW's UIChooseFacility drives it (clear; AddOption per facility: index, label, state; UpdateInfo: name,
// requirements, description, image; setFocus), while the camera looks at the tile (EW's AddonCam_R<row>_C<column>). Its
// rules are Long War's (LWBaseRules.Facilities, LWBase.CanBuild and Work); chosen, the facility is begun and the screen
// closes back to the base. A facility that cannot be built is greyed with what it needs.
class UILWEWChooseFacility extends UILWEWScreen dependson(LWBaseRules);

var int TileX, TileY;
var array<int> Choices;
var array<string> Whys;
var int Selected;

static function Open(XComHQPresentationLayer HQPres, int AtX, int AtY)
{
	local UILWEWChooseFacility EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxChooseFacility", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWChooseFacility', HQPres);
	EWScreen.Package = name("/ package/ewxChooseFacility/ChooseFacility");
	EWScreen.MCName = 'theChooseFacilityScreen';
	EWScreen.TileX = AtX;
	EWScreen.TileY = AtY;
	HQPres.ScreenStack.Push(EWScreen);
}

simulated function OnInit()
{
	local LWX2EWBase B;

	super.OnInit();
	B = class'LWX2EWBase'.static.Get(self);
	B.Show();
	B.LookAt(name("AddonCam_R" $ TileY $ "_C" $ (TileX + 1)), 1.0);
	Fill();
	// (EW selects the option under the mouse as it moves, its list items' mouse-in; here read off the movie.)
	SetTimer(0.1, true, nameof(HoverSelect));
}

/** The option under the mouse selected, as EW's list does on the mouse coming over it (UIChooseFacility.OnMouseEvent 400). */
function HoverSelect()
{
	local int i;

	if (Movie == none || Movie.Pres.ScreenStack.GetCurrentScreen() != self)
		return;
	i = OptionUnderMouse();
	if (i >= 0 && i != Selected)
		Select(i);
}

/** The facilities for the tile, buildable first (as EW sorts them), each with what it needs when it cannot be built. */
function Fill()
{
	local XComGameState_LWStrategy S;
	local LWBaseRules.LWFacilityDef F;
	local array<int> Able, Unable;
	local array<string> UnableWhy;
	local string Why;
	local int Type, k;

	S = class'XComGameState_LWStrategy'.static.Get();
	Type = S.TileType[TileY * class'LWBase'.const.W + TileX];
	foreach class'LWBaseRules'.default.Facilities(F)
	{
		// (Not built on a tile: the starting rooms; the access lift, the shaft's own.)
		if (F.Cash < 0 || F.Id == 6)
			continue;
		Why = "";
		if (F.Id == 15 && Type != class'LWBase'.const.DUG_STEAM)
			Why = class'UILWEWHub'.static.Word(class'UILWEWBuildFacilities'.default.ErrNeedSteam, "It needs a steam vent.");
		else if (!class'LWBase'.static.CanBuild(S, F, Why))
			Why = class'UILWEWBuildFacilities'.default.RequiredBuild @ Why;
		if (Why == "")
			Able.AddItem(F.Id);
		else
		{
			Unable.AddItem(F.Id);
			UnableWhy.AddItem(Why);
		}
	}
	Choices.Length = 0;
	Whys.Length = 0;
	for (k = 0; k < Able.Length; k++)
	{
		Choices.AddItem(Able[k]);
		Whys.AddItem("");
	}
	for (k = 0; k < Unable.Length; k++)
	{
		Choices.AddItem(Unable[k]);
		Whys.AddItem(UnableWhy[k]);
	}
	MC.FunctionVoid("clear");
	for (k = 0; k < Choices.Length; k++)
	{
		MC.BeginFunctionOp("AddOption");
		MC.QueueNumber(k);
		MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(class'LWBase'.static.FacilityName(Choices[k]), Whys[k] == "" ? eUIState_Normal : eUIState_Disabled));
		MC.QueueNumber(0);
		MC.EndOp();
	}
	Select(0);
}

function Select(int i)
{
	local LWBaseRules.LWFacilityDef F;
	local string Info;

	if (Choices.Length == 0)
		return;
	Selected = Clamp(i, 0, Choices.Length - 1);
	class'LWBaseRules'.static.FacilityFor(Choices[Selected], F);
	Info = class'UILWEWHub'.static.Word(class'UILWEWBuildFacilities'.default.Cost, "Cost:") @ class'LWStrategyRules'.static.Money(F.Cash);
	if (F.Alloys > 0)
		Info $= "," @ F.Alloys @ class'LWEngineering'.static.ItemName('AlienAlloy');
	if (F.Elerium > 0)
		Info $= "," @ F.Elerium @ class'LWEngineering'.static.ItemName('EleriumDust');
	if (F.Item != '' && F.Items > 0)
		Info $= "," @ F.Items @ class'LWEngineering'.static.ItemName(F.Item);
	Info $= "\n" $ (F.Power >= 0 ? "Power +" $ F.Power : "Power" @ F.Power) $ "    Upkeep" @ class'LWStrategyRules'.static.Money(F.Upkeep) $ "/month    "
		$ class'LWBonusEffects'.static.FacilityHours(F.Days) / 24 @ "days";
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(Caps(class'LWBase'.static.FacilityName(Choices[Selected])));
	MC.QueueString(Whys[Selected] != "" ? class'UIUtilities_Text'.static.GetColoredText(Whys[Selected], eUIState_Bad) : class'UILWEWBuildFacilities'.default.NoRequirements);
	MC.QueueString(Info);
	MC.QueueString(class'UILWEWBuildFacilities'.static.FacilityIcon(Choices[Selected]));
	MC.EndOp();
	MC.FunctionString("setFocus", string(Selected));
}

/** The selected facility begun on the tile, back to the base. */
function Accept()
{
	local string Why;

	if (Choices.Length == 0 || Whys[Selected] != "")
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	if (!class'LWBase'.static.Work(TileX, TileY, Choices[Selected], Why))
	{
		`log("LongWarX2: EW base building:" @ Why, , 'LongWarX2');
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	CloseScreen();
}

/** The option under the mouse, or -1 (EW's list items do not report their clicks to XCOM 2). */
function int OptionUnderMouse()
{
	local string Path;
	local float MouseX, MouseY, W, H;
	local int i;

	for (i = 0; i < Choices.Length; i++)
	{
		Path = MCPath $ ".itemList.theItems." $ i;
		W = Movie.GetVariableNumber(Path $ "._width");
		H = Movie.GetVariableNumber(Path $ "._height");
		MouseX = Movie.GetVariableNumber(Path $ "._xmouse");
		MouseY = Movie.GetVariableNumber(Path $ "._ymouse");
		if (W > 0 && MouseX >= 0 && MouseY >= 0 && MouseX <= W && MouseY <= H)
			return i;
	}
	return -1;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if ((cmd == 391 || cmd == 398) && Target == "theBackButton")
	{
		CloseScreen();
		return;
	}
	super(UIScreen).OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int i;

	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
		// (A click on a facility builds it, as in EW (OnMouseEvent 398: RealizeSelected, OnAccept); the help bar's BEGIN
		// BUILD builds the one selected, UILWEWStrategyHUD.)
		i = OptionUnderMouse();
		if (i >= 0)
		{
			Select(i);
			Accept();
			return true;
		}
		break;
	case class'UIUtilities_Input'.const.FXS_ARROW_UP:
	case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		Select(Selected - 1);
		return true;
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		Select(Selected + 1);
		return true;
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		Accept();
		return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	bShowsBase = true
}
