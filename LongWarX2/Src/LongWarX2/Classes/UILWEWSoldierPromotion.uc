// Enemy Within's promotion screen (features/strategy-flow.md; the soldier summary's Abilities): its SoldierPromotion movie
// on EW's promotion panel in EW's armory, through EW's camera (UIDisplay_SoldierPromote, Armory_UIDisplayCam_Promote), the
// soldier on EW's pad. Driven as EW's UISoldierPromotion drives it (InitializeTree, UpdateAbilityData, RealizeSelected):
// a column per rank, Squaddie to Colonel (on screen, a row each), each with its rank's perks in EW's icons (LWPerkIcons);
// the column to choose from now highlighted (COLUMN_HIGHLIGHT_ON), later ones that can also be chosen faded, the others
// plain; with Hidden Trees (second wave #21) the ranks not reached locked. A perk chosen by click or Enter, with EW's
// confirmation (UISoldierPromotion.ConfirmDialogue; "Prior Training Required" while an earlier rank is unchosen), bought as
// LWX2PromotionScreen buys it (XCOM 2's purchase and Long War's stat bonus for the choice). The soldier's information and
// stats are the summary's (UIStrategyComponent_SoldierInfo, SoldierStats); previous/next soldier as there.
class UILWEWSoldierPromotion extends UILWEWSoldierSummary;

/** Long War's words (UISoldierPromotion), written from the player's install (lw-words.mjs). */
var localized string Title, ConfirmTitle, ConfirmText, OKPromote, CancelPromote, CantTitle, CantText, OKCant;

const COLUMNS = 7;
const ROWS = 3;

/** Each column's perks by row (column * ROWS + row; '' none): the rank's abilities in their tree order (the branch XCOM 2
 *  buys), the Squaddie rank's given perks centred. */
var array<name> Cells;
/** The selection (EW's ability tree branch - 1 and option). */
var int Col, Row;
var bool bSelectionSet;
/** The perk being confirmed. */
var int PendingCol, PendingRow;

static function Open(XComHQPresentationLayer HQPres, StateObjectReference Unit)
{
	local UILWEWSoldierPromotion S;

	DynamicLoadObject(default.UIPackage $ ".ewxSoldierPromotion", class'Object', true);
	S = HQPres.Spawn(class'UILWEWSoldierPromotion', HQPres);
	S.Package = name("/ package/ewxSoldierPromotion/SoldierPromotion");
	S.MCName = 'theScreen';
	S.UnitRef = Unit;
	S.EWDisplay = 'UIDisplay_SoldierPromote';
	S.EWDisplayCamera = 'Armory_UIDisplayCam_Promote';
	Push3D(HQPres, S);
}

/** EW's InitializeTree, UpdateAbilityData, ShowAbilityTree; the soldier's panels. */
function Fill()
{
	local XComGameState_Unit U;
	local XGParamTag Tag;
	local int k;

	U = Unit();
	if (U == none)
		return;
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.StrValue0 = U.GetSoldierClassTemplate() != none ? Caps(U.GetSoldierClassTemplate().DisplayName) : "";
	k = class'UILWEWSoldierList'.default.Classes.Find('Template', U.GetSoldierClassTemplateName());
	MC.BeginFunctionOp("InitializeTree");
	MC.QueueString(class'XComLocalizer'.static.ExpandString(Word(Title, "<XGParam:StrValue0/> ABILITIES")));
	MC.QueueString(k != INDEX_NONE ? class'UILWEWSoldierList'.default.Classes[k].Frame : "");
	MC.QueueBoolean(false);
	MC.EndOp();
	FillTree(U);
	FillInfo(U, class'XComGameState_LWStrategy'.static.Get());
	FillStats(U);
	MC.FunctionVoid("ShowAbilityTree");
}

/** Whether a perk of the rank has been chosen (Squaddie's are given). */
static function bool Chosen(XComGameState_Unit U, int Rank)
{
	local array<SoldierClassAbilityType> Tree;
	local SoldierClassAbilityType Slot;

	if (Rank == 0)
		return true;
	Tree = U.GetRankAbilities(Rank);
	foreach Tree(Slot)
		if (Slot.AbilityName != '' && U.HasSoldierAbility(Slot.AbilityName))
			return true;
	return false;
}

/** A rank the soldier can choose a perk for now (reached, none chosen). */
static function bool Promotable(XComGameState_Unit U, int Rank)
{
	return Rank > 0 && Rank < U.GetRank() && !Chosen(U, Rank);
}

/** Hidden Trees: a rank not reached shows locked (EW: column >= the soldier's rank). */
static function bool Locked(XComGameState_Unit U, int Rank)
{
	return U.GetSoldierClassTemplate() == none || (class'LWX2SecondWave'.static.On(21) && Rank >= U.GetRank());
}

/** EW's UpdateAbilityData. */
function FillTree(XComGameState_Unit U)
{
	local array<SoldierClassAbilityType> Tree;
	local array<name> Given;
	local name Ability;
	local int c, r, ColumnState;
	local bool bFirst, bLit;

	Cells.Length = 0;
	Cells.Length = COLUMNS * ROWS;
	for (c = 0; c < COLUMNS; c++)
	{
		Tree = U.GetRankAbilities(c);
		if (c == 0)
		{
			// (The given perks: those EW shows as perks, centred.)
			Given.Length = 0;
			for (r = 0; r < Tree.Length; r++)
				if (class'LWPerkIcons'.static.FrameOf(Tree[r].AbilityName) != "")
					Given.AddItem(Tree[r].AbilityName);
			for (r = 0; r < Given.Length && r < ROWS; r++)
				Cells[(Given.Length == 1 ? 1 : r)] = Given[r];
		}
		else
			for (r = 0; r < Tree.Length && r < ROWS; r++)
				if (class'LWPerkIcons'.static.FrameOf(Tree[r].AbilityName) != "")
					Cells[c * ROWS + r] = Tree[r].AbilityName;
	}
	bFirst = true;
	for (c = 0; c < COLUMNS; c++)
	{
		if (Locked(U, c))
		{
			for (r = 0; r < ROWS; r++)
				if (Cells[c * ROWS + r] != '')
					SetIcon(c, r, "unknown", false);
			ColumnState = 3;
		}
		else
		{
			for (r = 0; r < ROWS; r++)
			{
				Ability = Cells[c * ROWS + r];
				if (Ability == '')
					continue;
				// (Lit: in the column to choose from, a perk that can be chosen; elsewhere, the soldier's own.)
				bLit = Promotable(U, c) ? U.MeetsAbilityPrerequisites(Ability) : U.HasSoldierAbility(Ability);
				SetIcon(c, r, class'LWPerkIcons'.static.FrameOf(Ability), bLit);
			}
			ColumnState = 0;
			if (Promotable(U, c))
			{
				ColumnState = bFirst ? 1 : 2;
				if (bFirst && !bSelectionSet)
				{
					Col = c;
					Row = FirstRow(c, 0);
					bSelectionSet = true;
				}
				bFirst = false;
			}
		}
		MC.BeginFunctionOp("SetColumnData");
		MC.QueueNumber(c);
		MC.QueueString(Caps(class'X2ExperienceConfig'.static.GetRankName(c + 1, U.GetSoldierClassTemplateName())));
		MC.QueueNumber(ColumnState);
		MC.EndOp();
	}
	if (!bSelectionSet)
	{
		// (Nothing to choose: the soldier's latest rank.)
		Col = Clamp(U.GetRank() - 1, 0, COLUMNS - 1);
		Row = FirstRow(Col, 0);
		bSelectionSet = true;
	}
	RealizeSelected();
}

function SetIcon(int c, int r, string Frame, bool bLit)
{
	MC.BeginFunctionOp("SetAbilityIcon");
	MC.QueueNumber(c);
	MC.QueueNumber(r);
	MC.QueueString(Frame);
	MC.QueueBoolean(bLit);
	MC.EndOp();
}

/** The column's row with a perk, from Start on in the direction By (1 or -1, wrapping); -1 none. */
function int FirstRow(int c, int Start, optional int By = 1)
{
	local int i, r;

	for (i = 0; i < ROWS; i++)
	{
		r = (Start + i * By + ROWS * 2) % ROWS;
		if (Cells[c * ROWS + r] != '')
			return r;
	}
	return -1;
}

/** EW's RealizeSelected: the selector on the icon, its name and words (Long War's stat bonus for the choice with them). */
function RealizeSelected()
{
	local X2AbilityTemplate T;
	local XComGameState_Unit U;
	local string Description;
	local LWX2PerkBonuses.LWPerkBonus Bonus;

	if (Row < 0)
	{
		MC.FunctionVoid("HideSelectionIcon");
		MC.BeginFunctionOp("SetAbilityDescription");
		MC.QueueString("");
		MC.QueueString("");
		MC.EndOp();
		return;
	}
	MC.BeginFunctionOp("SetSelectedIcon");
	MC.QueueNumber(Col);
	MC.QueueNumber(Row);
	MC.EndOp();
	U = Unit();
	T = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Cells[Col * ROWS + Row]);
	MC.BeginFunctionOp("SetAbilityDescription");
	if (T == none || Locked(U, Col))
	{
		MC.QueueString("");
		MC.QueueString("");
	}
	else
	{
		Description = T.HasLongDescription() ? T.GetMyLongDescription(, U) : "";
		if (Col > 0 && class'LWX2PerkBonuses'.static.Find(U.GetSoldierClassTemplateName(), Col, Row, Bonus))
			Description $= "\n" $ class'UIUtilities_Text'.static.GetColoredText("With it:" @ class'LWX2PerkBonuses'.static.Describe(Bonus), eUIState_Good);
		MC.QueueString(T.LocFriendlyName);
		MC.QueueString(Description);
	}
	MC.EndOp();
}

function SelectCell(int c, int r)
{
	if (c < 0 || c >= COLUMNS || r < 0 || r >= ROWS || Cells[c * ROWS + r] == '')
		return;
	if (c == Col && r == Row)
		return;
	Col = c;
	Row = r;
	PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
	RealizeSelected();
}

/** Up or down a rank (By -1, 1): the nearest perk of the next column that has one. */
function MoveColumn(int By)
{
	local int c, i, r;

	for (i = 1; i < COLUMNS; i++)
	{
		c = (Col + By * i + COLUMNS) % COLUMNS;
		r = Cells[c * ROWS + Row] != '' ? Row : FirstRow(c, 1);
		if (r >= 0)
		{
			SelectCell(c, r);
			return;
		}
	}
}

/** EW's OnAccept: the confirmation, or "Prior Training Required" while an earlier rank is unchosen. */
function Accept()
{
	local XComGameState_Unit U;
	local TDialogueBoxData D;
	local XGParamTag Tag;
	local X2AbilityTemplate T;
	local int c;

	U = Unit();
	if (U == none || Row < 0 || !Promotable(U, Col) || !U.MeetsAbilityPrerequisites(Cells[Col * ROWS + Row]))
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	T = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Cells[Col * ROWS + Row]);
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.StrValue0 = T != none ? T.LocFriendlyName : string(Cells[Col * ROWS + Row]);
	D.eType = eDialog_Normal;
	for (c = 1; c < Col; c++)
		if (Promotable(U, c))
		{
			D.strTitle = Word(CantTitle, "Prior Training Required");
			D.strText = class'XComLocalizer'.static.ExpandString(Word(CantText, "Earlier training must be chosen first."));
			D.strAccept = Word(OKCant, class'UIUtilities_Text'.default.m_strGenericOK);
			Movie.Pres.UIRaiseDialog(D);
			PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
			return;
		}
	PendingCol = Col;
	PendingRow = Row;
	D.strTitle = Word(ConfirmTitle, "NEW TRAINING");
	D.strText = class'XComLocalizer'.static.ExpandString(Word(ConfirmText, "Training: <XGParam:StrValue0/>"));
	D.strAccept = Word(OKPromote, class'UIUtilities_Text'.default.m_strGenericOK);
	D.strCancel = Word(CancelPromote, class'UIUtilities_Text'.default.m_strGenericCancel);
	D.fnCallback = ConfirmAnswered;
	Movie.Pres.UIRaiseDialog(D);
}

/** XCOM 2's purchase and Long War's stat bonus for the choice, in one change (LWX2PromotionScreen.ComfirmAbilityCallback). */
simulated function ConfirmAnswered(Name Action)
{
	local XComGameStateHistory History;
	local XComGameState UpdateState;
	local XComGameState_Unit U;
	local LWX2PerkBonuses.LWPerkBonus Bonus;

	if (Action != 'eUIAction_Accept')
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	History = `XCOMHISTORY;
	UpdateState = History.CreateNewGameState(true, class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Long War promotion (EW's screen)"));
	U = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
	if (U.BuySoldierProgressionAbility(UpdateState, PendingCol, PendingRow, 0))
	{
		if (class'LWX2PerkBonuses'.static.Find(U.GetSoldierClassTemplateName(), PendingCol, PendingRow, Bonus))
			class'LWX2PerkBonuses'.static.Apply(U, Bonus);
		`GAMERULES.SubmitGameState(UpdateState);
		Movie.Pres.PlayUISound(eSUISound_SoldierPromotion);
		bSelectionSet = false;
		Fill();
	}
	else
	{
		History.CleanupPendingGameState(UpdateState);
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
	}
}

/** Previous/next soldier: the summary under this screen follows (EW: m_kSoldierSummary.PrevSoldier). */
function Cycle(int By)
{
	local UILWEWSoldierSummary Summary;
	local int i;

	bSelectionSet = false;
	super.Cycle(By);
	for (i = 0; i < Movie.Pres.ScreenStack.Screens.Length; i++)
	{
		Summary = UILWEWSoldierSummary(Movie.Pres.ScreenStack.Screens[i]);
		if (Summary != none && Summary != self && UILWEWSoldierPromotion(Summary) == none)
			Summary.SwitchTo(UnitRef);
	}
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local array<string> Parts;
	local string Cell;

	// (Not the summary's menu: EW's icons report …icon<column>_<row>.icon, UISoldierPromotion.OnMouseEvent.)
	super(UILWEWScreen).OnMouseEvent(cmd, args);
	if (args.Length < 2 || args[args.Length - 1] != "icon" || InStr(args[args.Length - 2], "icon") != 0)
		return;
	Cell = Mid(args[args.Length - 2], 4);
	Parts = SplitString(Cell, "_", true);
	if (Parts.Length != 2)
		return;
	if (cmd == 392)
		SelectCell(int(Parts[0]), int(Parts[1]));
	else if (cmd == 391 || cmd == 398)
	{
		SelectCell(int(Parts[0]), int(Parts[1]));
		Accept();
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			MoveColumn(-1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			MoveColumn(1);
			return true;
		// (EW's rows run right to left: row 0 is the rightmost icon.)
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
			SelectCell(Col, FirstRow(Col, Row + 1));
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
			SelectCell(Col, FirstRow(Col, Row - 1, -1));
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Accept();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			Cycle(-1);
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
			Cycle(1);
			return true;
		}
	}
	return super(UILWEWScreen).OnUnrealCommand(cmd, arg);
}
