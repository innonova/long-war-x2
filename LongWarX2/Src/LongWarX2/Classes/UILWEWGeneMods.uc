// Long War's gene mods on Enemy Within's own Gene Mods screen (features/lw-genemods.md; agreed 2026-11-16: the Gene Lab
// on EW's screen, choosing the soldier on XCOM 2's list): EW's SoldierGeneMods movie, driven as Long War's
// UISoldierGeneMods drives it. XCOM 2's soldier list of those who could go into a tank (UIPersonnel_LWGene); a soldier
// chosen, EW's tree of the five body parts and their two mods each (InitializeTree, SetRowData, SetIcon: grey not yet
// researched, yellow the soldier's, cyan open), a mod's name, words and price (SetDescription, SetRequirements); mods
// chosen and unchosen by click (ToggleCheckedIcon), EW's confirmation with the days and the price, then into the tank
// (XComGameState_LWStrategy.StartGeneMods). Over the hub's Barracks, the camera in the Genetics Lab.
class UILWEWGeneMods extends UILWEWScreen;

/** Long War's words (UISoldierGeneMods, XGSoldierUI), written from the player's install (lw-words.mjs, makeGeneWords). */
var localized string Title, ImplantLabel, RemoveLabel, Insufficient, ConfirmTitle, ConfirmBody, ConfirmBodyRemoved,
	LockedLabel, LockedDesc, ConfirmButton, NoTanks;
var localized string Rows[5];
var localized string StatusLabel, MissionsLabel, KillsLabel;

/** EW's rows, top first (XComPerkManager.GetPerkInGeneModTree's branches): the slot each shows. */
var array<string> RowSlots;

/** Each mod's picture in EW's icon clip (Long War's XComPerkManager.BuildPerkTables: the perk's strImage). */
struct GeneImage
{
	var int Perk;
	var string Image;
};
var array<GeneImage> Images;
/** The countries EW's icon movie has a flag for (its frame labels, without the underscore). */
var array<string> FlagLabels;

var StateObjectReference Soldier;
var int Row, Column;
/** The mods chosen (Long War's perk ids), in the order chosen (m_arrSelectedPerks). */
var array<int> Chosen;
var UIButton ConfirmButtonWidget;
var bool bTreeShown;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWGeneMods EWScreen;
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (!class'XComGameState_LWStrategy'.static.GeneTankFree(S))
	{
		TanksFull(HQPres, S);
		return;
	}
	DynamicLoadObject(default.UIPackage $ ".ewxSoldierGeneMods", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWGeneMods', HQPres);
	EWScreen.Package = name("/ package/ewxSoldierGeneMods/SoldierGeneMods");
	EWScreen.MCName = 'theScreen';
	HQPres.ScreenStack.Push(EWScreen);
}

/** No tank free: Long War's words for it, and who is in the tanks. */
static function TanksFull(XComHQPresentationLayer HQPres, XComGameState_LWStrategy S)
{
	local TDialogueBoxData Data;
	local XComGameState_Unit Unit;
	local string Text;
	local int i;

	Text = Word(default.NoTanks, "There are no available slots in the Genetics Lab.");
	for (i = 0; S != none && i < S.GenePatients.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(S.GenePatients[i].Unit));
		Text $= "\n" $ (Unit != none ? Unit.GetName(eNameType_FullNick) : "") @ "-" @ ((class'XComGameState_LWStrategy'.static.GeneHoursLeft(S.GenePatients[i]) + 23) / 24)
			@ class'UILWPsiLabs'.static.Word(class'UILWPsiLabs'.default.Days, "Days");
	}
	Data.eType = eDialog_Normal;
	Data.strTitle = Word(default.Title, "GENE MODS");
	Data.strText = Text;
	Data.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;
	HQPres.UIRaiseDialog(Data);
}

static function string Word(string Localized, string Fallback)
{
	return Localized != "" ? Localized : Fallback;
}

simulated function OnInit()
{
	super.OnInit();
	ConfirmButtonWidget = Spawn(class'UIButton', self);
	ConfirmButtonWidget.InitButton('LWGeneConfirm', Caps(Word(ConfirmButton, "Confirm Gene Implants")), OnConfirmClicked);
	// Under the tree's panel, at (60, 640) of EW's stage (the button is inside the screen's clip).
	ConfirmButtonWidget.SetPosition(60 - StageX, 640 - StageY);
	ConfirmButtonWidget.Hide();
	ShowBase();
	ChooseSoldier();
}

/** EW's base behind it, the camera in the (first) Genetics Lab. */
function ShowBase()
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
		if (S.TileFacility[i] == 23)
		{
			B.LookAt(name("AddonCam_R" $ (i / class'LWBase'.const.W) $ "_C" $ (i % class'LWBase'.const.W + 1)), 1.0);
			return;
		}
	B.LookAt('BARRACKS', 1.0);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (bIsInited)
		ShowBase();
}

/** XCOM 2's list of the soldiers who could go into a tank now. */
function ChooseSoldier()
{
	local UIPersonnel_LWGene List;

	Soldier.ObjectID = 0;
	Chosen.Length = 0;
	if (ConfirmButtonWidget != none)
		ConfirmButtonWidget.Hide();
	List = Spawn(class'UIPersonnel_LWGene', Movie.Pres);
	List.onSelectedDelegate = OnSoldierChosen;
	List.OnCancelled = OnListCancelled;
	Movie.Pres.ScreenStack.Push(List);
}

/** Out of the list without a soldier: out of the Genetics Lab. */
function OnListCancelled()
{
	CloseScreen();
}

/** A soldier chosen: EW's tree for them (Long War's UISoldierGeneMods.OnInit). */
function OnSoldierChosen(StateObjectReference UnitRef)
{
	local array<ASValue> Params;
	local int r;

	Soldier = UnitRef;
	Chosen.Length = 0;
	Row = 0;
	Column = 0;
	Params.AddItem(Str(Caps(Word(Title, "Gene Mods"))));
	CallNow("InitializeTree", Params);
	for (r = 0; r < 5; r++)
	{
		Params.Length = 0;
		Params.AddItem(Num(r));
		Params.AddItem(Str(Word(Rows[r], Caps(RowSlots[r]))));
		Params.AddItem(class'UILWEWOfficers'.static.BoolValue(!ModOpenAt(r, 0) && !ModOpenAt(r, 1)));
		CallNow("SetRowData", Params);
	}
	UpdateIcons();
	ShowSoldier();
	if (!bTreeShown)
	{
		CallNow("ShowAbilityTree");
		bTreeShown = true;
	}
	ConfirmButtonWidget.Show();
	Realize();
}

/** The soldier's header and stats on EW's panels (Long War's UIStrategyComponent_SoldierInfo and _SoldierStats): name, flag,
 *  class and rank, missions and kills; health, mobility, will, aim, defence and damage reduction. */
function ShowSoldier()
{
	local XComGameState_Unit U;
	local X2SoldierClassTemplate SoldierClass;
	local array<ASValue> Params;
	local string Stats, Status, TimeLabel, TimeValue;

	U = Unit();
	if (U == none)
		return;
	SoldierClass = U.GetSoldierClassTemplate();
	Params.AddItem(Str(Caps(U.GetName(eNameType_First) @ U.GetName(eNameType_Last))));
	Params.AddItem(Str(U.GetName(eNameType_Nick)));
	class'UIUtilities_Strategy'.static.GetPersonnelStatusSeparate(U, Status, TimeLabel, TimeValue);
	Params.AddItem(Str(class'UIUtilities_Text'.static.GetColoredText(Word(StatusLabel, "STATUS:"), eUIState_Normal) @ class'UIUtilities_Text'.static.GetColoredText(Status, eUIState_Good)));
	Params.AddItem(Str(FlagLabel(U.GetCountry())));
	Params.AddItem(Str(ClassLabel(U)));
	Params.AddItem(Str(SoldierClass != none ? Caps(SoldierClass.DisplayName) : ""));
	Params.AddItem(Str("rank" $ U.GetRank()));
	Params.AddItem(Str(Caps(class'X2ExperienceConfig'.static.GetRankName(U.GetRank(), U.GetSoldierClassTemplateName()))));
	Params.AddItem(class'UILWEWOfficers'.static.BoolValue(false));
	Params.AddItem(Str(Word(MissionsLabel, "MISSIONS:") @ U.GetNumMissions()));
	Params.AddItem(Str(Word(KillsLabel, "KILLS:") @ U.GetNumKills()));
	CallNow("soldierInfoMC.SetSoldierInformation", Params);
	// HP, mobility, will, aim, defence, each with its bonus (none here); damage reduction; fuel, XP and psi XP not shown.
	Stats = int(U.GetMaxStat(eStat_HP)) $ "|0|" $ int(U.GetMaxStat(eStat_Mobility)) $ "|0|" $ int(U.GetMaxStat(eStat_Will)) $ "|0|"
		$ int(U.GetMaxStat(eStat_Offense)) $ "|0|" $ int(U.GetMaxStat(eStat_Defense)) $ "|0|"
		$ Tenths(class'X2Ability_LWDamageReduction'.static.OwnReduction(U)) $ "|0|0|-1|0|-1";
	Params.Length = 0;
	Params.AddItem(Str(Stats));
	Params.AddItem(Str(""));
	Params.AddItem(Str(""));
	Params.AddItem(Str(""));
	CallNow("soldierStatsMC.SetUnitStats", Params);
}

/** A country's flag in EW's icon movie: its frame label (_unitedstates …; _unknown where EW has none). */
static function string FlagLabel(name Country)
{
	local string C;

	C = Locs(Mid(string(Country), 8));
	switch (C)
	{
	case "usa": return "_unitedstates";
	case "uk": return "_unitedkingdom";
	}
	return default.FlagLabels.Find(C) != INDEX_NONE ? "_" $ C : "_unknown";
}

/** A soldier's class icon in EW's icon movie: the EW class Long War's class grew from (sniper, assault, heavy, support), its
 *  gene-modded picture once the soldier has a mod. */
static function string ClassLabel(XComGameState_Unit U)
{
	local LWBaseRules.LWGeneMod G;
	local string Base;
	local bool bGene;

	switch (U.GetSoldierClassTemplateName())
	{
	case 'LWS_Sniper': case 'LWS_Scout': Base = "sniper"; break;
	case 'LWS_Rocketeer': case 'LWS_Gunner': Base = "heavy"; break;
	case 'LWS_Medic': case 'LWS_Engineer': Base = "support"; break;
	case 'LWS_Assault': case 'LWS_Infantry': Base = "assault"; break;
	default: return "unknown";
	}
	foreach class'LWBaseRules'.default.GeneMods(G)
		if (class'XComGameState_LWStrategy'.static.HasGeneMod(U, G.Perk))
			bGene = true;
	return Base $ (bGene ? "_gene" : "");
}

/** A number to its tenths, as EW writes damage reduction ("0.5"; "0" for none). */
static function string Tenths(float F)
{
	local int T;

	T = Round(F * 10);
	return T % 10 == 0 ? string(T / 10) : (T / 10) $ "." $ (T % 10);
}

/** The mod at a place of EW's tree (row: body part, top first; column 0 or 1), as its config entry. */
function bool ModAt(int r, int c, out LWBaseRules.LWGeneMod G)
{
	local LWBaseRules.LWGeneMod M;

	foreach class'LWBaseRules'.default.GeneMods(M)
		if (M.Slot ~= RowSlots[r] && M.Column == c + 1)
		{
			G = M;
			return true;
		}
	return false;
}

function bool ModOpenAt(int r, int c)
{
	local LWBaseRules.LWGeneMod G;

	return ModAt(r, c, G) && class'XComGameState_LWStrategy'.static.GeneModOpen(G);
}

function XComGameState_Unit Unit()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Soldier.ObjectID));
}

static function string ModName(int Perk)
{
	return class'X2Ability_LWStandins'.static.PsiPowerName(class'X2Ability_LWStandins'.static.GeneAbilityFor(Perk));
}

function string ModDesc(int Perk)
{
	local X2AbilityTemplate T;

	T = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(class'X2Ability_LWStandins'.static.GeneAbilityFor(Perk));
	return (T != none && T.HasLongDescription()) ? T.GetMyLongDescription(, Unit()) : "";
}

function string ImageFor(int Perk)
{
	local int k;

	k = Images.Find('Perk', Perk);
	return k == INDEX_NONE ? "unknown" : Images[k].Image;
}

/** Each place's icon: grey (faded) not yet researched, yellow the soldier's, cyan open (UpdateAbilityData). */
function UpdateIcons()
{
	local LWBaseRules.LWGeneMod G;
	local array<ASValue> Params;
	local bool bLocked;
	local int r, c;

	for (r = 0; r < 5; r++)
		for (c = 0; c < 2; c++)
		{
			if (!ModAt(r, c, G))
				continue;
			bLocked = !class'XComGameState_LWStrategy'.static.GeneModOpen(G);
			Params.Length = 0;
			Params.AddItem(Num(r));
			Params.AddItem(Num(c));
			Params.AddItem(Str(bLocked ? "unknown" : ImageFor(G.Perk)));
			Params.AddItem(Str(bLocked ? "grey" : (class'XComGameState_LWStrategy'.static.HasGeneMod(Unit(), G.Perk) ? "yellow" : "cyan")));
			Params.AddItem(class'UILWEWOfficers'.static.BoolValue(bLocked));
			CallNow("SetIcon", Params);
		}
}

function int ChosenCash(optional int Extra)
{
	local LWBaseRules.LWGeneMod G;
	local int Perk, Total;

	foreach Chosen(Perk)
		if (class'LWBaseRules'.static.GeneModFor(Perk, G))
			Total += G.Cash;
	return Total + Extra;
}

function int ChosenMeld(optional int Extra)
{
	local LWBaseRules.LWGeneMod G;
	local int Perk, Total;

	foreach Chosen(Perk)
		if (class'LWBaseRules'.static.GeneModFor(Perk, G))
			Total += G.Meld;
	return Total + Extra;
}

function int ChosenHours()
{
	local LWBaseRules.LWGeneMod G;
	local int Perk, Total;

	foreach Chosen(Perk)
		if (class'LWBaseRules'.static.GeneModFor(Perk, G))
			Total += class'LWBaseRules'.static.GeneHours(G);
	return Total;
}

static function int Supplies()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies();
}

static function int MeldHeld()
{
	return class'LWEngineering'.static.Held(class'X2Item_LWArtifacts'.static.ItemFor('Meld'));
}

/** The price as EW writes it: meld, then cash, red where there is not enough (GetRequiredMeldStr, GetRequiredCashStr). */
static function string MeldText(int Meld, bool bShort)
{
	return class'UIUtilities_Text'.static.GetColoredText(Meld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld'), bShort ? eUIState_Bad : eUIState_Warning);
}

static function string CashText(int Cash, bool bShort)
{
	return class'UIUtilities_Text'.static.GetColoredText(class'LWStrategyRules'.static.Money(Cash), bShort ? eUIState_Bad : eUIState_Cash);
}

/** The place in view: its name and words, what clicking does, its price (RealizeSelected). */
function Realize()
{
	local LWBaseRules.LWGeneMod G;
	local array<ASValue> Params;
	local bool bLocked, bHas, bShortMeld, bShortCash;

	if (!ModAt(Row, Column, G))
		return;
	bLocked = !class'XComGameState_LWStrategy'.static.GeneModOpen(G);
	bHas = class'XComGameState_LWStrategy'.static.HasGeneMod(Unit(), G.Perk);
	Params.AddItem(Num(Row));
	Params.AddItem(Num(Column));
	CallNow("SetSelectedIcon", Params);
	Params.Length = 0;
	Params.AddItem(Str(bLocked ? Word(LockedLabel, "LOCKED") : Caps(ModName(G.Perk))));
	Params.AddItem(Str(bLocked ? Word(LockedDesc, "Not available.") : ModDesc(G.Perk)));
	CallNow("SetDescription", Params);
	// (EW's SetDescription casts the words' clip to its class to set them, and the cast finds nothing in XCOM 2's player:
	// the words are set on the clip as that function does.)
	Params.Remove(0, 1);
	CallNow("bg.theDescription.description.setHTML", Params);
	Params.Length = 0;
	if (!bLocked && !bHas)
	{
		bShortMeld = MeldHeld() < ChosenMeld(G.Meld);
		bShortCash = Supplies() < ChosenCash(G.Cash);
		if (Chosen.Find(G.Perk) != INDEX_NONE)
			Params.AddItem(Str(Word(RemoveLabel, "CLICK TO REMOVE")));
		else if (bShortMeld || bShortCash)
			Params.AddItem(Str(class'UIUtilities_Text'.static.GetColoredText(Word(Insufficient, "INSUFFICIENT RESOURCES"), eUIState_Bad)));
		else
			Params.AddItem(Str(Word(ImplantLabel, "CLICK TO SELECT")));
		Params.AddItem(Str(""));
		CallNow("SetImplantButtonHelp", Params);
		Params.Length = 0;
		Params.AddItem(Str(MeldText(G.Meld, bShortMeld)));
		Params.AddItem(Str(CashText(G.Cash, bShortCash)));
		CallNow("SetRequirements", Params);
	}
	else
	{
		Params.AddItem(Str(""));
		Params.AddItem(Str(""));
		CallNow("SetImplantButtonHelp", Params);
		CallNow("SetRequirements", Params);
	}
	ConfirmButtonWidget.SetDisabled(Chosen.Length == 0 || Supplies() < ChosenCash() || MeldHeld() < ChosenMeld());
}

function Select(int r, int c)
{
	Row = Clamp(r, 0, 4);
	Column = Clamp(c, 0, 1);
	Realize();
}

/** A mod chosen or unchosen (Long War's UISoldierGeneMods.OnAccept): the other of its body part unchosen with it. */
function Toggle()
{
	local LWBaseRules.LWGeneMod G;
	local array<ASValue> Params;
	local bool bHas, bAdding;
	local int Opposite;

	if (Soldier.ObjectID == 0 || !ModAt(Row, Column, G) || !class'XComGameState_LWStrategy'.static.GeneModOpen(G))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	bHas = class'XComGameState_LWStrategy'.static.HasGeneMod(Unit(), G.Perk);
	bAdding = !bHas && Chosen.Find(G.Perk) == INDEX_NONE;
	if (bAdding && (MeldHeld() < ChosenMeld(G.Meld) || Supplies() < ChosenCash(G.Cash)))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Opposite = class'XComGameState_LWStrategy'.static.OppositeGeneMod(G.Perk);
	if (bHas && Chosen.Find(Opposite) != INDEX_NONE)
	{
		Params.AddItem(Num(Row));
		Params.AddItem(Num((Column + 1) % 2));
		CallNow("ToggleCheckedIcon", Params);
	}
	Chosen.RemoveItem(Opposite);
	if (bAdding)
		Chosen.AddItem(G.Perk);
	else
		Chosen.RemoveItem(G.Perk);
	if (!bHas)
	{
		Params.Length = 0;
		Params.AddItem(Num(Row));
		Params.AddItem(Num(Column));
		Params.AddItem(class'UILWEWOfficers'.static.BoolValue(class'XComGameState_LWStrategy'.static.HasGeneMod(Unit(), Opposite)));
		CallNow("ToggleCheckedIcon", Params);
	}
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	Realize();
}

function OnConfirmClicked(UIButton Button)
{
	AskConfirm();
}

/** EW's confirmation: the mods, those they replace, the days and the price (ShowConfirmNotification). */
function AskConfirm()
{
	local TDialogueBoxData Data;
	local XGParamTag Tag;
	local string Added, Removed;
	local int Perk, Opposite;

	if (Chosen.Length == 0 || Supplies() < ChosenCash() || MeldHeld() < ChosenMeld())
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	foreach Chosen(Perk)
	{
		Added $= (Added != "" ? ", " : "") $ ModName(Perk);
		Opposite = class'XComGameState_LWStrategy'.static.OppositeGeneMod(Perk);
		if (class'XComGameState_LWStrategy'.static.HasGeneMod(Unit(), Opposite))
			Removed $= (Removed != "" ? ", " : "") $ ModName(Opposite);
	}
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.StrValue0 = Added;
	Tag.StrValue1 = Removed;
	Tag.StrValue2 = class'LWStrategyRules'.static.Money(ChosenCash()) $ "," @ ChosenMeld() @ class'X2Item_LWArtifacts'.static.DisplayName('Meld');
	Tag.IntValue0 = ChosenHours() / 24;
	Data.eType = eDialog_Normal;
	Data.strTitle = Word(ConfirmTitle, "CONFIRM");
	if (Removed == "")
		Data.strText = ConfirmBody != "" ? `XEXPAND.ExpandString(ConfirmBody) : Added @ "-" @ Tag.IntValue0 @ "days," @ Tag.StrValue2;
	else
		Data.strText = ConfirmBodyRemoved != "" ? `XEXPAND.ExpandString(ConfirmBodyRemoved) : Added @ "(" $ Removed $ ") -" @ Tag.IntValue0 @ "days," @ Tag.StrValue2;
	Data.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	Data.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	Data.fnCallback = OnConfirm;
	Movie.Pres.UIRaiseDialog(Data);
}

/** Confirmed: into the tank (EquipSelectedMods); then the list again while a tank is free, else out of the lab. */
simulated function OnConfirm(Name Action)
{
	local string Why;

	if (Action != 'eUIAction_Accept')
		return;
	if (!class'XComGameState_LWStrategy'.static.StartGeneMods(Soldier.ObjectID, Chosen, Why))
	{
		`log("LongWarX2: gene mods:" @ Why, , 'LongWarX2');
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
	if (class'XComGameState_LWStrategy'.static.GeneTankFree(class'XComGameState_LWStrategy'.static.Get()))
		ChooseSoldier();
	else
		CloseScreen();
}

/** EW's clicks (as Long War's UISoldierGeneMods reads them): an icon's clip, icon<row>_<column>, hovered or clicked. */
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local array<string> Parts;
	local string Target;

	if (args.Length >= 2 && args[args.Length - 1] == "icon")
	{
		Target = Repl(args[args.Length - 2], "icon", "");
		ParseStringIntoArray(Target, Parts, "_", true);
		if (Parts.Length == 2)
		{
			if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN)
				Select(int(Parts[0]), int(Parts[1]));
			else if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
			{
				Select(int(Parts[0]), int(Parts[1]));
				Toggle();
			}
		}
	}
	super(UIScreen).OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super(UIScreen).OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_ARROW_UP:
	case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		Select(Row - 1, Column);
		return true;
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		Select(Row + 1, Column);
		return true;
	case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		Select(Row, Column - 1);
		return true;
	case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		Select(Row, Column + 1);
		return true;
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		Toggle();
		return true;
	case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
		AskConfirm();
		return true;
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		// Out of a soldier's mods, back to the list (EW's BackOutOfScreen).
		ChooseSoldier();
		return true;
	}
	return super(UIScreen).OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	// (Over the hub's Barracks room: the base stays in view behind it.)
	bShowsBase = true
	RowSlots(0) = "Brain"
	RowSlots(1) = "Eyes"
	RowSlots(2) = "Chest"
	RowSlots(3) = "Skin"
	RowSlots(4) = "Legs"
	Images(0) = (Perk=4, Image="SecondaryHeart")
	Images(1) = (Perk=20, Image="Adrenal")
	Images(2) = (Perk=28, Image="NeuralDamping")
	Images(3) = (Perk=155, Image="RestorativeMist")
	Images(4) = (Perk=30, Image="ReactivePupils")
	Images(5) = (Perk=38, Image="DepthPerception")
	Images(6) = (Perk=42, Image="BioelectricSkin")
	Images(7) = (Perk=148, Image="IronSkin")
	Images(8) = (Perk=50, Image="MuscleDensity")
	Images(9) = (Perk=45, Image="BattleFatigue")
	FlagLabels(0) = "argentina"
	FlagLabels(1) = "australia"
	FlagLabels(2) = "brazil"
	FlagLabels(3) = "belgium"
	FlagLabels(4) = "canada"
	FlagLabels(5) = "china"
	FlagLabels(6) = "columbia"
	FlagLabels(7) = "egypt"
	FlagLabels(8) = "france"
	FlagLabels(9) = "germany"
	FlagLabels(10) = "greece"
	FlagLabels(11) = "india"
	FlagLabels(12) = "ireland"
	FlagLabels(13) = "israel"
	FlagLabels(14) = "italy"
	FlagLabels(15) = "japan"
	FlagLabels(16) = "kenya"
	FlagLabels(17) = "mexico"
	FlagLabels(18) = "netherlands"
	FlagLabels(19) = "nigeria"
	FlagLabels(20) = "norway"
	FlagLabels(21) = "pakistan"
	FlagLabels(22) = "russia"
	FlagLabels(23) = "saudiarabia"
	FlagLabels(24) = "scotland"
	FlagLabels(25) = "southafrica"
	FlagLabels(26) = "southkorea"
	FlagLabels(27) = "spain"
	FlagLabels(28) = "sweden"
	FlagLabels(29) = "turkey"
	FlagLabels(30) = "ukraine"
	FlagLabels(31) = "unitedkingdom"
	FlagLabels(32) = "unitedstates"
	FlagLabels(33) = "venezuela"
	FlagLabels(34) = "zimbabwe"
	FlagLabels(35) = "portugal"
	FlagLabels(36) = "poland"
}
