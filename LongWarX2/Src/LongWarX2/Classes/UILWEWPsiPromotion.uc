// Enemy Within's promotion screen in its psi mode (features/lw-psi.md; UISoldierPromotion with m_bPsiPromotion): Long War's
// psi tree, six columns (the psi ranks Awakened to Master, Long War's words) of up to three powers each (its SoldierPerkTrees
// of eSC_Psi: LWBaseRules.PsiPowers' Column and Row), the soldier's powers lit; the columns up to their next psi rank open
// (UpdateAbilityData: the psi rank, one more when the psi experience is there), the first highlighted. A power chosen, with
// EW's confirmation, begins its training in the Psi Labs (XComGameState_LWStrategy.StartPsi), as the Labs' soldier list leads
// here (XGPsiLabsUI.OnChooseSoldier: UISoldier in psi mode).
class UILWEWPsiPromotion extends UILWEWSoldierPromotion;

/** Long War's words (lw-words.mjs, makePsiWords): the title and the psi ranks' names (0 None to 7 Volunteer). */
var localized string PsiTitle;
var localized string PsiRankNames[8];

/** Each cell's power (Long War's perk number; 0 none), column * ROWS + row. */
var array<int> Perks;

static function OpenPsi(XComHQPresentationLayer HQPres, StateObjectReference Unit)
{
	local UILWEWPsiPromotion S;

	DynamicLoadObject(default.UIPackage $ ".ewxSoldierPromotion", class'Object', true);
	S = HQPres.Spawn(class'UILWEWPsiPromotion', HQPres);
	S.Package = name("/ package/ewxSoldierPromotion/SoldierPromotion");
	S.MCName = 'theScreen';
	S.UnitRef = Unit;
	S.EWDisplay = 'UIDisplay_SoldierPromote';
	S.EWDisplayCamera = 'Armory_UIDisplayCam_Promote';
	Push3D(HQPres, S);
}

function Fill()
{
	local XComGameState_Unit U;

	U = Unit();
	if (U == none)
		return;
	MC.BeginFunctionOp("InitializeTree");
	MC.QueueString(Word(PsiTitle, "PSIONIC ABILITIES"));
	MC.QueueString("");
	MC.QueueBoolean(true);
	MC.EndOp();
	FillTree(U);
	FillInfo(U, class'XComGameState_LWStrategy'.static.Get());
	FillStats(U);
	MC.FunctionVoid("ShowAbilityTree");
}

/** The columns open to the soldier: their psi rank, one more with the psi experience for it (UpdateAbilityData). */
function int OpenColumns(XComGameState_Unit U)
{
	local int Rank;

	Rank = class'XComGameState_LWStrategy'.static.PsiRankOf(U);
	if (class'XComGameState_LWStrategy'.static.PsiXPOf(U) >= class'XComGameState_LWStrategy'.static.PsiXPNeeded(Rank + 1))
		Rank++;
	return Rank;
}

function bool Trainable(XComGameState_Unit U, int Perk)
{
	local LWBaseRules.LWPsiPower P;
	local string Why;

	return Perk != 0 && class'LWBaseRules'.static.PsiPowerFor(Perk, P) && class'XComGameState_LWStrategy'.static.CanTrainPsi(class'XComGameState_LWStrategy'.static.Get(), U, P, Why);
}

function FillTree(XComGameState_Unit U)
{
	local LWBaseRules.LWPsiPower P;
	local name Ability;
	local int c, r, Open, ColumnState, Perk;
	local bool bFirst, bAny;

	Cells.Length = 0;
	Cells.Length = COLUMNS * ROWS;
	Perks.Length = 0;
	Perks.Length = COLUMNS * ROWS;
	foreach class'LWBaseRules'.default.PsiPowers(P)
		if (P.Column >= 1 && P.Column <= 6 && P.Row >= 0 && P.Row < ROWS)
		{
			Perks[(P.Column - 1) * ROWS + P.Row] = P.Perk;
			Cells[(P.Column - 1) * ROWS + P.Row] = class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk);
		}
	Open = OpenColumns(U);
	bFirst = true;
	for (c = 0; c < COLUMNS; c++)
	{
		bAny = false;
		for (r = 0; r < ROWS; r++)
		{
			Ability = Cells[c * ROWS + r];
			Perk = Perks[c * ROWS + r];
			if (Ability == '')
				continue;
			// (Lit: the soldier's own, or one they may train now.)
			SetIcon(c, r, class'LWPerkIcons'.static.FrameOf(Ability) != "" ? class'LWPerkIcons'.static.FrameOf(Ability) : "unknown",
				U.HasSoldierAbility(Ability) || Trainable(U, Perk));
			if (c < Open && !U.HasSoldierAbility(Ability) && Trainable(U, Perk))
				bAny = true;
		}
		ColumnState = c >= 6 ? 3 : 0;
		if (bAny)
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
		MC.BeginFunctionOp("SetColumnData");
		MC.QueueNumber(c);
		MC.QueueString(c < 6 ? Caps(Word(PsiRankNames[c + 1], "PSI RANK" @ (c + 1))) : "");
		MC.QueueNumber(ColumnState);
		MC.EndOp();
	}
	if (!bSelectionSet)
	{
		Col = Clamp(Open - 1, 0, 5);
		Row = FirstRow(Col, 0);
		bSelectionSet = true;
	}
	RealizeSelected();
}

/** The power's name and words, and what training it needs now (the hours and the chance, or what is missing). */
function RealizeSelected()
{
	local X2AbilityTemplate T;
	local XComGameState_Unit U;
	local LWBaseRules.LWPsiPower P;
	local string Description, Why, Status, Words;
	local int Will;

	if (Row < 0)
	{
		super.RealizeSelected();
		return;
	}
	MC.BeginFunctionOp("SetSelectedIcon");
	MC.QueueNumber(Col);
	MC.QueueNumber(Row);
	MC.EndOp();
	U = Unit();
	T = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Cells[Col * ROWS + Row]);
	MC.BeginFunctionOp("SetAbilityDescription");
	if (T == none || U == none || !class'LWBaseRules'.static.PsiPowerFor(Perks[Col * ROWS + Row], P))
	{
		MC.QueueString("");
		MC.QueueString("");
	}
	else
	{
		// (What training it needs first, then its words; Long War's longer words in a smaller size, so that they fit EW's
		// box of four lines.)
		Will = int(U.GetMaxStat(eStat_Will));
		if (U.HasSoldierAbility(T.DataName))
			Status = "Learned.";
		else if (class'XComGameState_LWStrategy'.static.CanTrainPsi(class'XComGameState_LWStrategy'.static.Get(), U, P, Why))
			Status = class'LWBaseRules'.static.PsiHours(Will, P) @ "hours," @ class'LWBaseRules'.static.PsiChance(Will, P) $ "%.";
		else
			Status = "Needs" @ Why $ ".";
		Words = T.HasLongDescription() ? T.GetMyLongDescription(, U) : "";
		Description = class'UIUtilities_Text'.static.GetColoredText(Status, Left(Status, 5) == "Needs" ? eUIState_Bad : eUIState_Good) @ Words;
		if (Len(Status @ Words) > 130)
			Description = "<font size='" $ (Len(Status @ Words) > 200 ? 16 : 19) $ "'>" $ Description $ "</font>";
		MC.QueueString(T.LocFriendlyName);
		MC.QueueString(Description);
	}
	MC.EndOp();
}

function Accept()
{
	local XComGameState_Unit U;
	local TDialogueBoxData D;
	local XGParamTag Tag;
	local X2AbilityTemplate T;

	U = Unit();
	if (U == none || Row < 0 || U.HasSoldierAbility(Cells[Col * ROWS + Row]) || !Trainable(U, Perks[Col * ROWS + Row]))
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	T = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Cells[Col * ROWS + Row]);
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Tag.StrValue0 = T != none ? T.LocFriendlyName : string(Cells[Col * ROWS + Row]);
	PendingCol = Col;
	PendingRow = Row;
	D.eType = eDialog_Normal;
	D.strTitle = Word(ConfirmTitle, "NEW TRAINING");
	D.strText = class'XComLocalizer'.static.ExpandString(Word(ConfirmText, "Training: <XGParam:StrValue0/>"));
	D.strAccept = Word(OKPromote, class'UIUtilities_Text'.default.m_strGenericOK);
	D.strCancel = Word(CancelPromote, class'UIUtilities_Text'.default.m_strGenericCancel);
	D.fnCallback = ConfirmAnswered;
	Movie.Pres.UIRaiseDialog(D);
}

/** The training begun (StartPsi), and back to the Psi Labs. */
simulated function ConfirmAnswered(Name Action)
{
	local string Why;

	if (Action != 'eUIAction_Accept')
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	if (!class'XComGameState_LWStrategy'.static.StartPsi(UnitRef.ObjectID, Perks[PendingCol * ROWS + PendingRow], Why))
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true);
		return;
	}
	Movie.Pres.PlayUISound(eSUISound_SoldierPromotion);
	CloseScreen();
}

/** One soldier only: the Labs chose them. */
function Cycle(int By)
{
}
