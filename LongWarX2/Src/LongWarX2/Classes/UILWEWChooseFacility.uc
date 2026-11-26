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
/** EW's blueprint of the chosen facility over the screen's top, in EW's frame (XComHQHUD.DrawHUD: the frame 80% of the
 *  screen's width and 55% of its height, 20 down; the blueprint 70% by 57.5% within it), the converter's copies
 *  (ew-map.ts, blueprintMip: cyan on black, added over the scene as EW composites it). */
var UIImage BlueprintFrame, Blueprint;

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
	ShowBlueprintFrame();
	Fill();
	// (EW's BACK and BEGIN CONSTRUCTION in the panel's own help bar, UIChooseFacility.UpdateButtonHelp.)
	HelpButton("helpBarMC", false, 0, Caps(W(class'UILWEWBuildFacilities'.default.BackLabel, class'UIUtilities_Text'.default.m_strGenericBack)), "Icon_B_CIRCLE");
	HelpButton("helpBarMC", true, 1, Caps(W(class'UILWEWBuildFacilities'.default.BeginBuild, "Begin Construction")), "Icon_START");
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
	// (In EW's order, its facilities' numbers: Laboratory, Workshop, Satellite Uplink, Fission Generator …)
	for (k = 0; k < 24; k++)
	{
		if (!class'LWBaseRules'.static.FacilityFor(k, F))
			continue;
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
	local X2TechTemplate Template;
	local string Desc;

	if (Choices.Length == 0)
		return;
	Selected = Clamp(i, 0, Choices.Length - 1);
	class'LWBaseRules'.static.FacilityFor(Choices[Selected], F);
	class'LWBonusEffects'.static.AdjustFacility(F);
	Template = X2TechTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(class'LWBaseRules'.static.FacilityTemplateFor(Choices[Selected])));
	// (As EW's UIChooseFacility.UpdateInfoPanelData: what stops it in red above its description, FacilityTypeSummary.)
	Desc = Whys[Selected] != "" ? class'UIUtilities_Text'.static.GetColoredText(Whys[Selected], eUIState_Bad) $ "\n" : "";
	Desc $= Template != none ? Repl(Template.Summary, "\\n", "\n") : "";
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(Caps(class'LWBase'.static.FacilityName(Choices[Selected])), Whys[Selected] == "" ? eUIState_Normal : eUIState_Disabled));
	MC.QueueString(Requirements(F));
	MC.QueueString(Desc);
	MC.QueueString(class'UILWEWBuildFacilities'.static.FacilityIcon(Choices[Selected]));
	MC.EndOp();
	MC.FunctionString("setFocus", string(Selected));
	ShowBlueprint(Choices[Selected]);
}

/** The name of EW's blueprint material for a facility (XComHQHUD's ChooseFacilityMICs: M_<name>), by Long War's facility. */
static function string BlueprintName(int Id)
{
	switch (Id)
	{
	case 7: return "Laboratory";
	case 8: return "Workshop";
	case 9: return "SmallRadar";
	case 10: return "PowerGenerator";
	case 11: return "Foundry";
	case 12: return "OTS";
	case 13: return "AlienContainment";
	case 14: return "LargeRadar";
	case 15: return "ThermalPower";
	case 16: return "EleriumPower";
	case 17: return "PsionicLab";
	case 18: return "Hyperwave";
	case 19: return "GollopChamber";
	case 22: return "CyberneticsLab";
	case 23: return "GeneticsLab";
	}
	return "";
}

/** An image of EW's facility chooser in the converted base (its ChooseFacilities group, renamed by the converter), as an
 *  image path; "" when the base was converted before it had them. */
static function string ChooserImage(string Name)
{
	local string P;

	P = "QhooseFacilities.EWTextrs." $ Name;
	if (DynamicLoadObject(P, class'Texture2D', true) == none)
	{
		P = "Command1." $ P;
		if (DynamicLoadObject(P, class'Texture2D', true) == none)
			return "";
	}
	return "img:///" $ P;
}

function ShowBlueprintFrame()
{
	local string P;

	P = ChooserImage("facility_border");
	`log("LongWarX2: EW's facility blueprints:" @ (P != "" ? P : "not in the converted base (converter 97)"), , 'LongWarX2');
	if (P == "")
		return;
	// (In the screen's own frame: EW's stage, scaled by STAGE_SCALE from its origin, StageX, StageY.)
	BlueprintFrame = Spawn(class'UIImage', self).InitImage('LWEWBlueprintFrame', P);
	BlueprintFrame.SetPosition(1920 * 0.1 / STAGE_SCALE - StageX, 20 / STAGE_SCALE - StageY);
	BlueprintFrame.SetSize(1920 * 0.8 / STAGE_SCALE, 1080 * 0.55 / STAGE_SCALE);
	Blueprint = Spawn(class'UIImage', self).InitImage('LWEWBlueprint');
	Blueprint.SetPosition(1920 * 0.15 / STAGE_SCALE - StageX, (1080 * (0.55 - 0.575) * 0.5 + 20) / STAGE_SCALE - StageY);
	Blueprint.SetSize(1920 * 0.7 / STAGE_SCALE, 1080 * 0.575 / STAGE_SCALE);
	// (Added over the scene: black adds nothing, as EW's AlphaComposite drew its black.)
	Blueprint.MC.SetString("blendMode", "add");
}

function ShowBlueprint(int Id)
{
	local string P;

	if (Blueprint == none)
		return;
	P = BlueprintName(Id) != "" ? ChooserImage("LWX2Blueprint_" $ BlueprintName(Id)) : "";
	if (P == "")
	{
		Blueprint.Hide();
		return;
	}
	Blueprint.LoadImage(P);
	Blueprint.Show();
}

/**
 * What a facility takes, as EW's chooser lists it (XGFacility_Engineering.GetFacilityCostSummary, GetCostSummary):
 * "Required to Build:" and, comma-separated, its power, the scientists or engineers Long War wants on staff, the money,
 * elerium, alloys and items, each in its colour and red when XCOM is short; "No Build Requirements" when nothing.
 */
function string Requirements(LWBaseRules.LWFacilityDef F)
{
	local XComGameState_LWStrategy S;
	local array<string> Parts;
	local string Out, P;
	local int Staff;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (F.Power < 0)
		Parts.AddItem(Colored(-F.Power @ W(class'UILWEWBuildFacilities'.default.CostPower, "Power"), eUIState_Warning,
			-F.Power > class'LWBase'.static.PowerCapacity(S) - class'LWBase'.static.PowerUsed(S)));
	Staff = class'LWBase'.static.StaffNeeded(S, F.Id);
	if (F.Id == 7 && Staff > 0)
		Parts.AddItem(Colored(Staff @ W(class'UILWEWBuildFacilities'.default.CostScientists, "Scientists"), eUIState_Warning, S.Scientists < Staff));
	else if ((F.Id == 8 || F.Id == 9 || F.Id == 14) && Staff > 0)
		Parts.AddItem(Colored(Staff @ W(class'UILWEWBuildFacilities'.default.CostEngineers, "Engineers"), eUIState_Warning, S.Engineers < Staff));
	if (F.Cash > 0)
		Parts.AddItem(Colored(class'LWStrategyRules'.static.Money(F.Cash), eUIState_Cash, class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < F.Cash));
	if (F.Elerium > 0)
		Parts.AddItem(Colored(F.Elerium $ "x" @ W(class'UILWEWBuildFacilities'.default.CostElerium, "Elerium"), eUIState_Psyonic, class'LWEngineering'.static.Held('EleriumDust') < F.Elerium));
	if (F.Alloys > 0)
		Parts.AddItem(Colored(F.Alloys $ "x" @ W(class'UILWEWBuildFacilities'.default.CostAlloys, "Alloys"), eUIState_Highlight, class'LWEngineering'.static.Held('AlienAlloy') < F.Alloys));
	if (F.Item != '' && F.Items > 0)
		Parts.AddItem(Colored(F.Items $ "x" @ class'LWEngineering'.static.ItemName(F.Item), eUIState_Normal, class'LWEngineering'.static.Held(F.Item) < F.Items));
	if (Parts.Length == 0)
		return W(class'UILWEWBuildFacilities'.default.NoRequirements, "No Build Requirements");
	Out = W(class'UILWEWBuildFacilities'.default.RequiredBuild, "Required to Build:");
	foreach Parts(P)
		Out $= (Out == W(class'UILWEWBuildFacilities'.default.RequiredBuild, "Required to Build:") ? " " : ", ") $ P;
	return Out;
}

static function string Colored(string Text, EUIState State, bool bShort)
{
	if (bShort)
		return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Bad);
	return class'UIUtilities_Text'.static.GetColoredText(Text, State);
}

static function string W(string Localized, string Fallback)
{
	return Localized != "" ? Localized : Fallback;
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

	// (From the last up, as the build screen's: a row's box can cover the next row's, and the first row then took every
	// click; UILWEWEngineering.OptionUnderMouse.)
	for (i = Choices.Length - 1; i >= 0; i--)
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
		// (The panel's BACK and BEGIN CONSTRUCTION; a click on a facility builds it, as in EW (OnMouseEvent 398:
		// RealizeSelected, OnAccept).)
		if (InStr(HelpButtonUnderMouse(), "buttonHelp_0") != INDEX_NONE)
		{
			CloseScreen();
			return true;
		}
		if (InStr(HelpButtonUnderMouse(), "buttonHelp_1") != INDEX_NONE)
		{
			Accept();
			return true;
		}
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
