// Long War's base screen (features/lw-base.md), opened from the Geoscape: the 7 x 5 tiles under the
// ground, each a button (rock: dig it; the shaft: an access lift; empty: the facility chosen), the
// facility to build, the base's power, satellites, bonuses and upkeep. The rules are LWBase's; time
// passes on the Geoscape.
class UILWBase extends UIScreen dependson(LWBaseRules);

const TILES = 35;

var UIText Header, SummaryText, StatusText, ChoiceText;
var UIButton TileButtons[TILES];
var UIButton PrevFacility, NextFacility, CloseButton;
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
	PrevFacility = Spawn(class'UIButton', self).InitButton('LWBasePrev', "<", OnPrev);
	PrevFacility.SetPosition(90, 760);
	NextFacility = Spawn(class'UIButton', self).InitButton('LWBaseNext', ">", OnNext);
	NextFacility.SetPosition(150, 760);
	ChoiceText = Spawn(class'UIText', self).InitText('LWBaseChoice', "");
	ChoiceText.SetPosition(220, 760);
	ChoiceText.SetWidth(1600);
	StatusText = Spawn(class'UIText', self).InitText('LWBaseStatus', "");
	StatusText.SetPosition(90, 830);
	StatusText.SetWidth(1700);
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
