// Long War's base screen (features/lw-base.md), opened from the Geoscape: the 7 x 5 tiles under the
// ground, each a button (rock: dig it; the shaft: an access lift; empty: the facility chosen), the
// facility to build, the base's power, satellites, bonuses and upkeep; with the Psi Labs built, their
// training (features/lw-psi.md: the soldier and the power chosen, the chance and hours, who is
// training); with the Genetics Lab built, its gene mods (features/lw-genemods.md). The rules are
// LWBase's; time passes on the Geoscape.
class UILWBase extends UIScreen dependson(LWBaseRules, XComGameState_LWStrategy);

const TILES = 35;

var UIText Header, SummaryText, StatusText, ChoiceText;
var UIButton TileButtons[TILES];
var UIButton PrevFacility, NextFacility, CloseButton;
/** The Psi Labs (features/lw-psi.md): the soldier and the power chosen, training begun; who is training. */
var UIButton PsiSoldierButton, PsiPowerButton, PsiTrainButton;
var UIText PsiText;
var int PsiSoldier, PsiPower;
/** The Genetics Lab (features/lw-genemods.md): the soldier and the mod chosen, the tank begun; who is in the tanks. */
var UIButton GeneSoldierButton, GeneModButton, GeneStartButton;
var UIText GeneText;
var int GeneSoldier, GeneMod;
/** The Officer Training School (lw-missions.md): the next squad size. */
var UIButton OTSButton;
var UIText OTSText;
/** The buildable facilities (Long War's ids) and the one chosen. */
var array<int> Choices;
var int Choice;
var string Status;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local LWBaseRules.LWFacilityDef F;
	local int i;

	super.InitScreen(InitController, InitMovie, InitName);
	foreach class'LWBaseRules'.default.Facilities(F)
		if (F.Cash >= 0 && F.Id != 6)
			Choices.AddItem(F.Id);
	Spawn(class'UIBGBox', self).InitBG('LWBaseBg', 60, 60, 1800, 960);
	Header = Spawn(class'UIText', self).InitText('LWBaseHeader', "", true);
	Header.SetPosition(90, 75);
	Header.SetWidth(1700);
	SummaryText = Spawn(class'UIText', self).InitText('LWBaseSummary', "");
	SummaryText.SetPosition(90, 120);
	SummaryText.SetWidth(1700);
	for (i = 0; i < TILES; i++)
	{
		TileButtons[i] = Spawn(class'UIButton', self).InitButton(name("LWBaseTile" $ i), "", OnTile);
		TileButtons[i].SetPosition(90 + (i % class'LWBase'.const.W) * 250, 180 + (i / class'LWBase'.const.W) * 110);
		TileButtons[i].SetWidth(240);
	}
	PrevFacility = Spawn(class'UIButton', self).InitButton('LWBasePrev', "PREV", OnPrev);
	PrevFacility.SetPosition(90, 760);
	NextFacility = Spawn(class'UIButton', self).InitButton('LWBaseNext', "NEXT", OnNext);
	NextFacility.SetPosition(250, 760);
	ChoiceText = Spawn(class'UIText', self).InitText('LWBaseChoice', "");
	// Right of the PREV and NEXT buttons ("<" drew as an empty button: Flash reads it as the start of a tag).
	ChoiceText.SetPosition(410, 760);
	ChoiceText.SetWidth(1600);
	StatusText = Spawn(class'UIText', self).InitText('LWBaseStatus', "");
	StatusText.SetPosition(90, 830);
	StatusText.SetWidth(1700);
	PsiSoldierButton = Spawn(class'UIButton', self).InitButton('LWBasePsiSoldier', "SOLDIER", OnPsiSoldier);
	PsiSoldierButton.SetPosition(90, 880);
	PsiSoldierButton.SetWidth(380);
	PsiPowerButton = Spawn(class'UIButton', self).InitButton('LWBasePsiPower', "POWER", OnPsiPower);
	PsiPowerButton.SetPosition(490, 880);
	PsiPowerButton.SetWidth(300);
	PsiTrainButton = Spawn(class'UIButton', self).InitButton('LWBasePsiTrain', "TRAIN", OnPsiTrain);
	PsiTrainButton.SetPosition(810, 880);
	PsiText = Spawn(class'UIText', self).InitText('LWBasePsiText', "");
	PsiText.SetPosition(960, 870);
	PsiText.SetWidth(820);
	GeneSoldierButton = Spawn(class'UIButton', self).InitButton('LWBaseGeneSoldier', "SOLDIER", OnGeneSoldier);
	GeneSoldierButton.SetPosition(90, 925);
	GeneModButton = Spawn(class'UIButton', self).InitButton('LWBaseGeneMod', "MOD", OnGeneMod);
	GeneModButton.SetPosition(490, 925);
	GeneStartButton = Spawn(class'UIButton', self).InitButton('LWBaseGeneStart', "MODIFY", OnGeneStart);
	GeneStartButton.SetPosition(810, 925);
	GeneText = Spawn(class'UIText', self).InitText('LWBaseGeneText', "");
	GeneText.SetPosition(960, 915);
	GeneText.SetWidth(700);
	OTSButton = Spawn(class'UIButton', self).InitButton('LWBaseOTS', "SQUAD SIZE", OnOTS);
	OTSButton.SetPosition(90, 970);
	OTSText = Spawn(class'UIText', self).InitText('LWBaseOTSText', "");
	OTSText.SetPosition(330, 960);
	OTSText.SetWidth(1200);
	CloseButton = Spawn(class'UIButton', self).InitButton('LWBaseClose', "CLOSE", OnClose);
	CloseButton.SetPosition(1700, 970);
	Refresh();
}

function Refresh()
{
	local XComGameState_LWStrategy S;
	local LWBaseRules.LWFacilityDef F;
	local string Why;
	local int i;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return;
	if (S.TileType.Length == 0)
		class'XComGameState_LWStrategy'.static.Run(0);
	S = class'XComGameState_LWStrategy'.static.Get();
	Header.SetText("LONG WAR: BASE -" @ class'LWStrategyRules'.static.Money(class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies()) $ "    " $ S.Scientists @ "scientists," @ S.Engineers @ "engineers");
	SummaryText.SetText(S.TileType.Length > 0 ? class'LWBase'.static.Summary(S) : "");
	for (i = 0; i < TILES && i < S.TileType.Length; i++)
		TileButtons[i].SetText(class'LWBase'.static.TileText(S, i % class'LWBase'.const.W, i / class'LWBase'.const.W));
	if (Choices.Length > 0 && class'LWBaseRules'.static.FacilityFor(Choices[Choice], F))
	{
		class'LWBase'.static.CanBuild(S, F, Why);
		ChoiceText.SetText("TO BUILD:" @ class'LWBase'.static.FacilityName(F.Id) @ "-" @ class'LWStrategyRules'.static.Money(F.Cash)
			$ (F.Alloys > 0 ? "," @ F.Alloys @ "alloys" : "") $ (F.Elerium > 0 ? "," @ F.Elerium @ "elerium" : "")
			$ ", power" @ F.Power $ ", upkeep" @ class'LWStrategyRules'.static.Money(F.Upkeep) $ "," @ F.Days @ "days" $ (Why != "" ? "  (needs" @ Why $ ")" : ""));
	}
	StatusText.SetText(Status != "" ? Status : "Rock: dig it. The shaft: an access lift. Empty ground: the facility chosen below.");
	RefreshPsi(S);
	RefreshGene(S);
	RefreshOTS(S);
}

/** The Officer Training School's line: the next squad size, shown once the school is built. */
function RefreshOTS(XComGameState_LWStrategy S)
{
	local string Why;

	if (class'LWBase'.static.Count(S, 12) == 0 || class'LWStrategyRules'.default.SquadSizes.Length == 0)
	{
		OTSButton.Hide();
		OTSText.SetText("");
		return;
	}
	OTSButton.Show();
	class'XComGameState_LWStrategy'.static.CanBuySquadSize(S, Why);
	if (S.SquadSizesBought < class'LWStrategyRules'.default.SquadSizes.Length)
		OTSText.SetText("Officer Training School: squad" @ class'UILWHeadquarters'.static.SquadSize() @ "->" @ (class'UILWHeadquarters'.static.SquadSize() + 1) $ "," @ class'LWStrategyRules'.static.Money(class'LWStrategyRules'.default.SquadSizes[S.SquadSizesBought].Cash) $ (Why != "" ? " (needs" @ Why $ ")" : ""));
	else
		OTSText.SetText("Officer Training School: squad" @ class'UILWHeadquarters'.static.SquadSize() $ ", both squad sizes bought");
}

simulated function OnOTS(UIButton Button)
{
	local string Why;

	Status = class'XComGameState_LWStrategy'.static.BuySquadSize(Why) ? "Squad size" @ class'UILWHeadquarters'.static.SquadSize() $ "." : "The squad size needs" @ Why $ ".";
	if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
	Refresh();
}

/** The Genetics Lab's line: shown once the Lab is built. */
function RefreshGene(XComGameState_LWStrategy S)
{
	local array<XComGameState_Unit> Soldiers;
	local LWBaseRules.LWGeneMod G;
	local XComGameState_LWStrategy.LWPsiTrainee T;
	local XComGameState_Unit Unit;
	local string Text, Why;

	if (class'LWBase'.static.Count(S, 23) == 0 || class'LWBaseRules'.default.GeneMods.Length == 0)
	{
		GeneSoldierButton.Hide();
		GeneModButton.Hide();
		GeneStartButton.Hide();
		GeneText.SetText("");
		return;
	}
	GeneSoldierButton.Show();
	GeneModButton.Show();
	GeneStartButton.Show();
	Soldiers = PsiCandidates(S);
	GeneMod = GeneMod % class'LWBaseRules'.default.GeneMods.Length;
	G = class'LWBaseRules'.default.GeneMods[GeneMod];
	GeneModButton.SetText(class'X2Ability_LWStandins'.static.PsiPowerName(class'X2Ability_LWStandins'.static.GeneAbilityFor(G.Perk)) @ "(" $ G.Slot $ ")");
	Text = class'LWStrategyRules'.static.Money(G.Cash) $ "," @ G.Meld @ class'X2Item_LWArtifacts'.static.DisplayName('Meld') $ "," @ G.Days @ "days";
	if (Soldiers.Length > 0)
	{
		GeneSoldier = GeneSoldier % Soldiers.Length;
		Unit = Soldiers[GeneSoldier];
		GeneSoldierButton.SetText("GENE:" @ Unit.GetFullName());
		class'XComGameState_LWStrategy'.static.CanGeneMod(S, Unit, G, Why);
		Text $= (Why != "" ? " (needs" @ Why $ ")" : "");
	}
	else
		GeneSoldierButton.SetText("GENE: no soldier ready");
	foreach S.GeneTrainees(T)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(T.Unit));
		Text $= " | " $ (Unit != none ? Unit.GetFullName() : "?") $ ":" @ class'X2Ability_LWStandins'.static.PsiPowerName(class'X2Ability_LWStandins'.static.GeneAbilityFor(T.Perk)) @ T.HoursLeft $ "h";
	}
	GeneText.SetText(Text);
}

simulated function OnGeneSoldier(UIButton Button) { GeneSoldier++; Refresh(); }
simulated function OnGeneMod(UIButton Button) { GeneMod++; Refresh(); }

simulated function OnGeneStart(UIButton Button)
{
	local XComGameState_LWStrategy S;
	local array<XComGameState_Unit> Soldiers;
	local string Why;

	S = class'XComGameState_LWStrategy'.static.Get();
	Soldiers = PsiCandidates(S);
	if (Soldiers.Length == 0)
		return;
	if (class'XComGameState_LWStrategy'.static.StartGeneMod(Soldiers[GeneSoldier % Soldiers.Length].ObjectID, class'LWBaseRules'.default.GeneMods[GeneMod % class'LWBaseRules'.default.GeneMods.Length].Perk, Why))
		Status = "Into the gene tank.";
	else
		Status = "The gene mod needs" @ Why $ ".";
	if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
	Refresh();
}

/** The soldiers who may train: ready for duty, not already training. */
function array<XComGameState_Unit> PsiCandidates(XComGameState_LWStrategy S)
{
	local array<XComGameState_Unit> Out;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;

	foreach class'UIUtilities_Strategy'.static.GetXComHQ().Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit != none && Unit.IsSoldier() && Unit.CanGoOnMission() && !S.InPsiTraining(Unit.ObjectID))
			Out.AddItem(Unit);
	}
	return Out;
}

/** The Psi Labs' line: shown once the Labs are built. */
function RefreshPsi(XComGameState_LWStrategy S)
{
	local array<XComGameState_Unit> Soldiers;
	local LWBaseRules.LWPsiPower P;
	local XComGameState_LWStrategy.LWPsiTrainee T;
	local XComGameState_Unit Unit;
	local string Text, Why;
	local int Will;

	if (class'LWBase'.static.Count(S, 17) == 0 || class'LWBaseRules'.default.PsiPowers.Length == 0)
	{
		PsiSoldierButton.Hide();
		PsiPowerButton.Hide();
		PsiTrainButton.Hide();
		PsiText.SetText("");
		return;
	}
	PsiSoldierButton.Show();
	PsiPowerButton.Show();
	PsiTrainButton.Show();
	Soldiers = PsiCandidates(S);
	PsiPower = PsiPower % class'LWBaseRules'.default.PsiPowers.Length;
	P = class'LWBaseRules'.default.PsiPowers[PsiPower];
	PsiPowerButton.SetText(class'X2Ability_LWStandins'.static.PsiPowerName(class'X2Ability_LWStandins'.static.PsiAbilityFor(P.Perk)));
	if (Soldiers.Length > 0)
	{
		PsiSoldier = PsiSoldier % Soldiers.Length;
		Unit = Soldiers[PsiSoldier];
		Will = int(Unit.GetMaxStat(eStat_Will));
		PsiSoldierButton.SetText("PSI:" @ Unit.GetFullName() @ "(will" @ Will $ ")");
		class'XComGameState_LWStrategy'.static.CanTrainPsi(S, Unit, P, Why);
		Text = class'LWBaseRules'.static.PsiChance(Will, P) $ "%," @ class'LWBaseRules'.static.PsiHours(Will, P) @ "hours" $ (Why != "" ? " (needs" @ Why $ ")" : "");
	}
	else
	{
		PsiSoldierButton.SetText("PSI: no soldier ready");
		Text = "";
	}
	foreach S.PsiTrainees(T)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(T.Unit));
		Text $= " | " $ (Unit != none ? Unit.GetFullName() : "?") $ ":" @ class'X2Ability_LWStandins'.static.PsiPowerName(class'X2Ability_LWStandins'.static.PsiAbilityFor(T.Perk)) @ T.HoursLeft $ "h";
	}
	PsiText.SetText(Text);
}

simulated function OnPsiSoldier(UIButton Button) { PsiSoldier++; Refresh(); }
simulated function OnPsiPower(UIButton Button) { PsiPower++; Refresh(); }

simulated function OnPsiTrain(UIButton Button)
{
	local XComGameState_LWStrategy S;
	local array<XComGameState_Unit> Soldiers;
	local string Why;

	S = class'XComGameState_LWStrategy'.static.Get();
	Soldiers = PsiCandidates(S);
	if (Soldiers.Length == 0)
		return;
	if (class'XComGameState_LWStrategy'.static.StartPsi(Soldiers[PsiSoldier % Soldiers.Length].ObjectID, class'LWBaseRules'.default.PsiPowers[PsiPower % class'LWBaseRules'.default.PsiPowers.Length].Perk, Why))
		Status = "Psi training begun.";
	else
		Status = "Psi training needs" @ Why $ ".";
	Refresh();
}

simulated function OnTile(UIButton Button)
{
	local int i;

	for (i = 0; i < TILES; i++)
		if (TileButtons[i] == Button)
		{
			if (class'LWBase'.static.Work(i % class'LWBase'.const.W, i / class'LWBase'.const.W, Choices.Length > 0 ? Choices[Choice] : 0, Status))
				Status = "Begun.";
			if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
				XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
		}
	Refresh();
}

simulated function OnPrev(UIButton Button) { Choice = (Choice + Choices.Length - 1) % Max(1, Choices.Length); Refresh(); }
simulated function OnNext(UIButton Button) { Choice = (Choice + 1) % Max(1, Choices.Length); Refresh(); }
simulated function OnClose(UIButton Button) { CloseScreen(); }

defaultproperties
{
	InputState = eInputState_Consume;
}
