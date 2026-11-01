// Long War's engineering screen (features/lw-gear.md, phase 3), opened from the Geoscape: what research
// has unlocked with its cost and time, a button to build it, and the projects under way. The rules are
// LWEngineering's; time passes on the Geoscape.
class UILWEngineering extends UIScreen;

const ROWS = 14;

var UIText Header, ProjectsText, StatusText;
var UIButton BuildButtons[ROWS];
var UIText BuildTexts[ROWS];
var int RowItem[ROWS];
var UIButton QuantityButton, PrevButton, NextButton, CloseButton;
var int Page;
var int Quantity;
var string Status;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int i;

	super.InitScreen(InitController, InitMovie, InitName);
	Quantity = 1;
	Spawn(class'UIBGBox', self).InitBG('LWEngBg', 60, 60, 1800, 960);
	Header = Spawn(class'UIText', self).InitText('LWEngHeader', "", true);
	Header.SetPosition(90, 75);
	Header.SetWidth(1700);
	for (i = 0; i < ROWS; i++)
	{
		BuildButtons[i] = Spawn(class'UIButton', self).InitButton(name("LWEngBuild" $ i), "BUILD", OnBuild);
		BuildButtons[i].SetPosition(90, 140 + i * 56);
		BuildTexts[i] = Spawn(class'UIText', self).InitText(name("LWEngText" $ i), "");
		BuildTexts[i].SetPosition(230, 140 + i * 56);
		BuildTexts[i].SetWidth(1000);
	}
	ProjectsText = Spawn(class'UIText', self).InitText('LWEngProjects', "");
	ProjectsText.SetPosition(1260, 140);
	ProjectsText.SetSize(580, 700);
	StatusText = Spawn(class'UIText', self).InitText('LWEngStatus', "");
	StatusText.SetPosition(90, 925);
	StatusText.SetWidth(1700);
	QuantityButton = Spawn(class'UIButton', self).InitButton('LWEngQuantity', "", OnQuantity);
	QuantityButton.SetPosition(90, 970);
	PrevButton = Spawn(class'UIButton', self).InitButton('LWEngPrev', "PREVIOUS", OnPrev);
	PrevButton.SetPosition(1260, 970);
	NextButton = Spawn(class'UIButton', self).InitButton('LWEngNext', "NEXT", OnNext);
	NextButton.SetPosition(1440, 970);
	CloseButton = Spawn(class'UIButton', self).InitButton('LWEngClose', "CLOSE", OnClose);
	CloseButton.SetPosition(1700, 970);
	Refresh();
}

function Refresh()
{
	local XComGameState_LWStrategy S;
	local array<int> Items;
	local int i, k, Pages;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none)
		return;
	Items = class'LWEngineering'.static.Buildable();
	Pages = Max(1, (Items.Length + ROWS - 1) / ROWS);
	Page = Clamp(Page, 0, Pages - 1);
	Header.SetText("LONG WAR: ENGINEERING -" @ S.Engineers @ "engineers    " $ class'LWStrategyRules'.static.Money(class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies()) $ "    page" @ (Page + 1) @ "of" @ Pages);
	for (i = 0; i < ROWS; i++)
	{
		k = Page * ROWS + i;
		RowItem[i] = k < Items.Length ? Items[k] : -1;
		BuildButtons[i].SetVisible(RowItem[i] >= 0);
		BuildTexts[i].SetText(RowItem[i] >= 0 ? class'LWEngineering'.static.BuildLine(RowItem[i], S.Engineers) : "");
	}
	ProjectsText.SetText("UNDER WAY:\n" $ (S.Builds.Length > 0 ? class'LWEngineering'.static.ProjectsText(S) : "nothing"));
	StatusText.SetText(Items.Length == 0 ? "Research has unlocked nothing to build yet." : Status);
	QuantityButton.SetText("QUANTITY:" @ Quantity);
	PrevButton.SetDisabled(Page == 0);
	NextButton.SetDisabled(Page >= Pages - 1);
}

simulated function OnBuild(UIButton Button)
{
	local int i;

	for (i = 0; i < ROWS; i++)
		if (BuildButtons[i] == Button && RowItem[i] >= 0)
		{
			if (class'LWEngineering'.static.Start(RowItem[i], Quantity, Status))
				Status = "Begun.";
			if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
				XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
		}
	Refresh();
}

/** 1, 2, 3, 4, 5, 10, then 1 again. */
simulated function OnQuantity(UIButton Button)
{
	Quantity = Quantity >= 10 ? 1 : (Quantity == 5 ? 10 : Quantity + 1);
	Refresh();
}

simulated function OnPrev(UIButton Button) { Page--; Refresh(); }
simulated function OnNext(UIButton Button) { Page++; Refresh(); }
simulated function OnClose(UIButton Button) { CloseScreen(); }

defaultproperties
{
	InputState = eInputState_Consume;
}
