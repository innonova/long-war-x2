// Enemy Within's own grey market screen (its GreyMarket movie, features/lw-greymarket.md): what XCOM holds that the grey
// market buys, how many are in storage, the price, how many to sell and what they bring; driven as EW's UIGreyMarket
// drives it (SetTitle, SetHeader, clear, AddItem, SetListSelection, UpdateInfo; clicks 391 on an item's leftArrow or
// rightArrow, 392 on an item selects it). The transaction is completed with SELL (EW puts that button on its HUD's help
// bar; here an XCOM 2 button below the movie) or Enter. The rules are LWGreyMarket's.
class UILWEWGreyMarket extends UILWEWScreen;

var array<int> Offered;
var array<int> Selling;
var int Highlight;
var UIButton SellButton;

static function Open(XComHQPresentationLayer HQPres)
{
	local UILWEWGreyMarket EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxGreyMarket", class'Object', true);
	class'UILWEWMapBackdrop'.static.ShowIfAvailable();
	EWScreen = HQPres.Spawn(class'UILWEWGreyMarket', HQPres);
	EWScreen.Package = name("/ package/ewxGreyMarket/GreyMarket");
	EWScreen.MCName = 'theScreen';
	HQPres.ScreenStack.Push(EWScreen);
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	// The movie is scaled to the stage (UILWEWScreen): the button is placed in its 1280 x 720 terms.
	SellButton = Spawn(class'UIButton', self).InitButton('LWGreyMarketSell', "COMPLETE TRANSACTION", OnSellButton);
	SellButton.SetPosition(560, 660);
}

simulated function OnInit()
{
	super.OnInit();
	MC.FunctionString("SetTitle", "GREY MARKET");
	Header(0, "IN STORAGE");
	Header(1, "");
	Header(2, "SELL");
	Fill(true);
}

simulated function OnRemoved()
{
	class'UILWEWMapBackdrop'.static.HideAll();
	super.OnRemoved();
}

function Header(int i, string Text)
{
	MC.BeginFunctionOp("SetHeader");
	MC.QueueNumber(i);
	MC.QueueString(Text);
	MC.EndOp();
}

/** The list, as EW's UpdateData writes it (bReset: what is offered read again, the counts to sell cleared). */
function Fill(bool bReset)
{
	local int i, k, Total;
	local LWGreyMarket.LWSaleDef D;

	if (bReset)
	{
		Offered = class'LWGreyMarket'.static.Offered();
		Selling.Length = 0;
		Selling.Length = Offered.Length;
		Highlight = Clamp(Highlight, 0, Max(0, Offered.Length - 1));
		MC.FunctionVoid("clear");
	}
	for (i = 0; i < Offered.Length; i++)
	{
		k = Offered[i];
		D = class'LWGreyMarket'.default.Sales[k];
		Total += Selling[i] * class'LWGreyMarket'.static.Price(k);
		MC.BeginFunctionOp("AddItem");
		MC.QueueNumber(i);
		MC.QueueString(string(class'LWGreyMarket'.static.Available(k) - Selling[i]));
		MC.QueueString(class'LWEngineering'.static.ItemName(D.Template));
		MC.QueueString(class'LWStrategyRules'.static.Money(class'LWGreyMarket'.static.Price(k)));
		MC.QueueString(Selling[i] > 0 ? string(Selling[i]) : "-");
		MC.QueueString(Selling[i] > 0 ? class'UIUtilities_Text'.static.GetColoredText(class'LWStrategyRules'.static.Money(Selling[i] * class'LWGreyMarket'.static.Price(k)), eUIState_Cash) : "");
		MC.QueueNumber(0);
		MC.QueueBoolean(class'LWGreyMarket'.static.CanSell(k));
		MC.EndOp();
	}
	Header(3, class'UIUtilities_Text'.static.GetColoredText("TOTAL" @ class'LWStrategyRules'.static.Money(Total), eUIState_Cash));
	ShowSelected();
	SellButton.SetDisabled(Total == 0);
}

/** The selected row and its item in the info panel (EW's RealizeSelected: the rows stay as they are). */
function ShowSelected()
{
	local int k;
	local string Info;
	local X2ItemTemplate Template;

	MC.FunctionNum("SetListSelection", Highlight);
	// The selected row's arrows shown, the others' hidden, once the movie has handled the click (it hides them after).
	SetTimer(0.15, false, nameof(ShowArrows));
	if (Offered.Length == 0)
		Info = class'UIUtilities_Text'.static.GetColoredText("No more items to sell", eUIState_Disabled);
	else
	{
		k = Offered[Highlight];
		Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'LWGreyMarket'.default.Sales[k].Template);
		Info = Caps(class'LWEngineering'.static.ItemName(class'LWGreyMarket'.default.Sales[k].Template));
		if (class'LWGreyMarket'.static.NotResearched(k))
			Info $= "\n" $ class'UIUtilities_Text'.static.GetColoredText("NOT RESEARCHED", eUIState_Warning);
		if (!class'LWGreyMarket'.static.CanSell(k))
			Info $= "\n" $ class'UIUtilities_Text'.static.GetColoredText("Cannot sell this item", eUIState_Bad);
		if (Template != none)
			Info $= "\n" $ Template.GetItemBriefSummary();
	}
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(Info);
	MC.QueueString((Highlight >= 0 && Highlight < Offered.Length) ? class'LWX2Pictures'.static.Item(class'LWGreyMarket'.default.Sales[Offered[Highlight]].Item, Template != none ? Template.strImage : "") : (Template != none ? Template.strImage : ""));
	MC.EndOp();
}

function ShowArrows()
{
	local int k;

	for (k = 0; k < Offered.Length; k++)
		Movie.SetVariableBool(MCPath $ ".itemList.theItems." $ k $ ".theArrows._visible", k == Highlight && class'LWGreyMarket'.static.CanSell(Offered[k]));
}

function Change(int By)
{
	local int k;

	if (Offered.Length == 0)
		return;
	k = Offered[Highlight];
	if (By > 0 && (!class'LWGreyMarket'.static.CanSell(k) || Selling[Highlight] >= class'LWGreyMarket'.static.Available(k)))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Selling[Highlight] = Clamp(Selling[Highlight] + By, 0, class'LWGreyMarket'.static.Available(k));
	Fill(false);
}

function Select(int i)
{
	if (Offered.Length == 0 || Clamp(i, 0, Offered.Length - 1) == Highlight)
		return;
	Highlight = Clamp(i, 0, Offered.Length - 1);
	ShowSelected();
}

function OnSellButton(UIButton Button)
{
	Complete();
}

/** Everything marked sold, paid now; the list read again. */
function Complete()
{
	local string Why;

	if (!class'LWGreyMarket'.static.Sell(Offered, Selling, Why))
	{
		`log("LongWarX2: EW grey market:" @ Why, , 'LongWarX2');
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
	Fill(true);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string Target;

	Target = args.Length > 0 ? args[args.Length - 1] : "";
	if (cmd == 392 && args.Length > 6)
		Select(int(args[6]));
	else if (cmd == 391 && Target == "rightArrow")
		Change(1);
	else if (cmd == 391 && Target == "leftArrow")
		Change(-1);
	super(UIScreen).OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return super.OnUnrealCommand(cmd, arg);
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			Select(Highlight - 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			Select(Highlight + 1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
			Change(1);
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
			Change(-1);
			return true;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			Complete();
			return true;
	}
	return super.OnUnrealCommand(cmd, arg);
}
