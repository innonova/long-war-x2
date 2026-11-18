// Enemy Within's lab screens (features/strategy-flow.md: the labs on EW's screens): its SoldierSlots movie in the lab's room,
// driven as EW's UISoldierSlots drives it (ClearSoldiers; SetTitleLabels; AddSlot: the soldier, the status, the button, greyed;
// SetSelected): a row a place in the lab, the soldier there and the time left, or (EMPTY) with ADD SOLDIER. ADD SOLDIER opens
// EW's soldier list for the lab (UILWEWSoldierList.OpenFor), those who cannot go greyed; the soldier chosen goes on as the lab
// takes them (Chosen). Each lab is a subclass with Long War's rows and words: UILWEWPsiLabs (XGPsiLabsUI), UILWEWGeneLab
// (XGGeneLabUI), UILWEWCyberneticsLab (XGCyberneticsUI).
class UILWEWSoldierSlots extends UILWEWScreen;

/** Long War's words for the lab (its UI manager's, and UISoldierSlots' STATUS), from the player's install (lw-words.mjs,
 *  makeLabWords). */
var localized string Title, StatusLabel, Empty, AddSoldier, RemoveSoldier, Days, Hours, RemoveTitle, RemoveText, RemoveAccept;

/** The lab's facility (EW's number: 17 the Psi Labs, 23 the Genetics Lab, 22 the Cybernetics Lab). */
var int Facility;

struct LabRow
{
	var string Soldier, Status, Button;
	var bool bDisabled;
	/** The soldier there (0: the place is free). */
	var int Unit;
};
var array<LabRow> Rows;
var int Selected;

static function UILWEWSoldierSlots OpenLab(XComHQPresentationLayer HQPres, class<UILWEWSoldierSlots> Lab)
{
	local UILWEWSoldierSlots S;

	DynamicLoadObject(default.UIPackage $ ".ewxSoldierSlots", class'Object', true);
	S = HQPres.Spawn(Lab, HQPres);
	S.Package = name("/ package/ewxSoldierSlots/SoldierSlots");
	S.MCName = 'theScreen';
	HQPres.ScreenStack.Push(S);
	return S;
}

simulated function OnInit()
{
	super.OnInit();
	ShowLab();
	Fill();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (!bIsInited)
		return;
	ShowLab();
	Fill();
}

/** EW's base behind it, the camera in the (first) lab of its kind. */
function ShowLab()
{
	local XComGameState_LWStrategy S;
	local LWX2EWBase B;
	local int i;

	if (!class'LWX2EWBase'.static.Converted())
		return;
	B = class'LWX2EWBase'.static.Get(self);
	B.Show();
	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = 0; S != none && i < S.TileFacility.Length; i++)
		if (S.TileFacility[i] == Facility)
		{
			B.LookAt(name("AddonCam_R" $ (i / class'LWBase'.const.W) $ "_C" $ (i % class'LWBase'.const.W + 1)), 1.0);
			return;
		}
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

/** How many places the lab has (Long War's places per lab built). */
function int Places()
{
	return class'LWBaseRules'.default.PsiSlots * class'LWBase'.static.Count(class'XComGameState_LWStrategy'.static.Get(), Facility);
}

/** Long War's rows (the lab's BuildTrainees). */
function BuildRows();

/** What keeps a soldier out of the lab now ("" if nothing). */
function string WhyNot(XComGameState_Unit U)
{
	return "";
}

/** A soldier chosen on the lab's list (the lab's OnChooseSoldier). */
function Chosen(StateObjectReference UnitRef);

/** A soldier in the lab, by its row (Long War's psi trainees can be taken out). */
function RemoveAt(int i)
{
	PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
}

/** EW's UpdateDataFromGame and UpdateDisplay. */
function Fill()
{
	local LabRow R;

	Rows.Length = 0;
	BuildRows();
	MC.FunctionVoid("ClearSoldiers");
	MC.BeginFunctionOp("SetTitleLabels");
	MC.QueueString(Title);
	MC.QueueString(Word(StatusLabel, "STATUS"));
	MC.EndOp();
	foreach Rows(R)
	{
		MC.BeginFunctionOp("AddSlot");
		MC.QueueString(R.Soldier);
		MC.QueueString(R.Status);
		MC.QueueString(R.Button);
		MC.QueueBoolean(R.bDisabled);
		MC.EndOp();
	}
	Select(Clamp(Selected, 0, Max(0, Rows.Length - 1)));
}

/** A free place's row (Long War's: (EMPTY), and the button where a soldier may be added). */
function AddEmptyRow(bool bButton)
{
	local LabRow R;

	R.Soldier = class'UIUtilities_Text'.static.GetColoredText(Word(Empty, "(EMPTY)"), eUIState_Disabled);
	R.Button = bButton ? Word(AddSoldier, "ADD SOLDIER") : "";
	Rows.AddItem(R);
}

/** Long War's time left: hours under a day, else days (rounded up), as the Genetics and Cybernetics Labs write it. */
function string TimeLeft(int HoursLeft)
{
	if (HoursLeft < 24)
		return HoursLeft @ Word(Hours, "Hours");
	return ((HoursLeft + 23) / 24) @ Word(Days, "Days");
}

/** Long War's name for a soldier in a lab (XGStrategySoldier.GetName, type 6): rank, first name, 'nickname', last name. */
static function string SoldierName(XComGameState_Unit U)
{
	local string Nick;

	Nick = Repl(U.GetNickName(), "'", "");
	Nick = Repl(Nick, " ", "") != "" ? "'" $ Nick $ "' " : "";
	return class'UILWEWSoldierList'.static.RankShort(U) @ U.GetName(eNameType_First) @ Nick $ U.GetName(eNameType_Last);
}

function Select(int i)
{
	Selected = i;
	MC.FunctionNum("SetSelected", i);
}

/** EW's OnChooseSlot: a soldier in the place (taken out where the lab allows), or the list to add one. */
function Accept(int i)
{
	if (i < 0 || i >= Rows.Length || Rows[i].bDisabled)
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	Select(i);
	if (Rows[i].Unit != 0)
		RemoveAt(i);
	else if (Rows[i].Button != "")
	{
		PlaySound(SoundCue'SoundUI.MenuSelectCue', true);
		class'UILWEWSoldierList'.static.OpenFor(XComHQPresentationLayer(Movie.Pres), self);
	}
	else
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int i, k;

	super.OnMouseEvent(cmd, args);
	// (…theItems.<i>…, UISoldierSlots.OnMouseEvent: the row or its button; hovered, the selection; clicked, the place chosen.)
	i = -1;
	for (k = 1; k < args.Length && i < 0; k++)
		if (args[k - 1] == "theItems" && string(int(args[k])) == args[k])
			i = int(args[k]);
	if (i < 0)
		return;
	if (cmd == 392)
		Select(i);
	else if (cmd == 391 || cmd == 398)
		Accept(i);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0 && Rows.Length > 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			Select(Selected > 0 ? Selected - 1 : Rows.Length - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			Select(Selected + 1 < Rows.Length ? Selected + 1 : 0);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Accept(Selected);
			return true;
		}
	}
	return super.OnUnrealCommand(cmd, arg);
}
