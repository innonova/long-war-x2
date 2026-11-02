// Long War's hangar screen (features/lw-hangar.md), opened from the Geoscape: each jet with its continent,
// weapon, HP and status, a button to send it to the continent chosen and one to refit it with the weapon
// chosen; interceptors ordered for the continent chosen. The rules are LWHangar's; time passes on the
// Geoscape.
class UILWHangar extends UIScreen dependson(XComGameState_LWAirWar);

const ROWS = 12;

var UIText Header, OrdersText, StatusText, ChoiceText;
var UIButton TransferButtons[ROWS], EquipButtons[ROWS];
var UIText JetTexts[ROWS];
var UIButton ContinentButton, WeaponButton, OrderButton, CloseButton;
var int Continent;
var int Weapon;
var string Status;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int i;

	super.InitScreen(InitController, InitMovie, InitName);
	class'XComGameState_LWAirWar'.static.EnsureExists();
	Continent = class'LWHangar'.static.HomeContinent();
	Weapon = 1;
	Spawn(class'UIBGBox', self).InitBG('LWHangarBg', 60, 60, 1800, 960);
	Header = Spawn(class'UIText', self).InitText('LWHangarHeader', "", true);
	Header.SetPosition(90, 75);
	Header.SetWidth(1700);
	for (i = 0; i < ROWS; i++)
	{
		TransferButtons[i] = Spawn(class'UIButton', self).InitButton(name("LWHangarTransfer" $ i), "SEND", OnTransfer);
		TransferButtons[i].SetPosition(90, 140 + i * 52);
		EquipButtons[i] = Spawn(class'UIButton', self).InitButton(name("LWHangarEquip" $ i), "REFIT", OnEquip);
		EquipButtons[i].SetPosition(260, 140 + i * 52);
		JetTexts[i] = Spawn(class'UIText', self).InitText(name("LWHangarJet" $ i), "");
		JetTexts[i].SetPosition(430, 140 + i * 52);
		JetTexts[i].SetWidth(1400);
	}
	OrdersText = Spawn(class'UIText', self).InitText('LWHangarOrders', "");
	OrdersText.SetPosition(90, 780);
	OrdersText.SetWidth(1700);
	ContinentButton = Spawn(class'UIButton', self).InitButton('LWHangarContinent', "", OnContinent);
	ContinentButton.SetPosition(90, 860);
	WeaponButton = Spawn(class'UIButton', self).InitButton('LWHangarWeapon', "", OnWeapon);
	WeaponButton.SetPosition(560, 860);
	OrderButton = Spawn(class'UIButton', self).InitButton('LWHangarOrder', "", OnOrder);
	OrderButton.SetPosition(1060, 860);
	StatusText = Spawn(class'UIText', self).InitText('LWHangarStatus', "");
	StatusText.SetPosition(90, 920);
	StatusText.SetWidth(1500);
	CloseButton = Spawn(class'UIButton', self).InitButton('LWHangarClose', "CLOSE", OnClose);
	CloseButton.SetPosition(1700, 970);
	Refresh();
}

function Refresh()
{
	local XComGameState_LWAirWar AirWar;
	local string Orders;
	local int i;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (AirWar == none)
		return;
	Header.SetText("LONG WAR: HANGAR -" @ class'LWStrategyRules'.static.Money(class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies()) $ "    craft upkeep" @ class'LWStrategyRules'.static.Money(class'LWHangar'.static.Upkeep()) $ "/month");
	for (i = 0; i < ROWS; i++)
	{
		TransferButtons[i].SetVisible(i < AirWar.Jets.Length);
		EquipButtons[i].SetVisible(i < AirWar.Jets.Length);
		JetTexts[i].SetText(i < AirWar.Jets.Length ? class'LWHangar'.static.JetText(AirWar.Jets[i]) : "");
	}
	for (i = 0; i < AirWar.Orders.Length; i++)
		Orders $= (i > 0 ? "; " : "") $ AirWar.Orders[i].Count @ "for" @ class'LWStrategyRules'.static.ContinentName(AirWar.Orders[i].Continent) @ "in" @ AirWar.Orders[i].HoursLeft $ "h";
	OrdersText.SetText("ORDERED:" @ (Orders != "" ? Orders : "none"));
	ContinentButton.SetText("CONTINENT:" @ Caps(class'LWStrategyRules'.static.ContinentName(Continent)) @ "(" $ class'LWHangar'.static.BaysTaken(AirWar, Continent) $ "/" $ class'LWBaseRules'.default.HangarBays $ ")");
	WeaponButton.SetText("WEAPON:" @ Caps(class'LWHangar'.static.WeaponName(Weapon)) @ (class'LWHangar'.static.WeaponItem(Weapon) != '' ? "(" $ class'LWEngineering'.static.Held(class'LWHangar'.static.WeaponItem(Weapon)) @ "in stores)" : ""));
	OrderButton.SetText("ORDER AN INTERCEPTOR (" $ class'LWStrategyRules'.static.Money(class'LWBaseRules'.default.InterceptorCost) $ ")");
	StatusText.SetText(Status != "" ? Status : "SEND: to the continent chosen. REFIT: with the weapon chosen.");
}

simulated function OnTransfer(UIButton Button)
{
	local int i;

	for (i = 0; i < ROWS; i++)
		if (TransferButtons[i] == Button && class'LWHangar'.static.Transfer(i, Continent, Status))
			Status = "Sent.";
	Refresh();
}

simulated function OnEquip(UIButton Button)
{
	local int i;

	for (i = 0; i < ROWS; i++)
		if (EquipButtons[i] == Button && class'LWHangar'.static.Equip(i, Weapon, Status))
			Status = "Refitting.";
	Refresh();
}

simulated function OnOrder(UIButton Button)
{
	if (class'LWHangar'.static.Order(Continent, 1, Status))
		Status = "Ordered.";
	if (XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
	Refresh();
}

simulated function OnContinent(UIButton Button) { Continent = (Continent + 1) % 5; Refresh(); }
simulated function OnWeapon(UIButton Button) { Weapon = Weapon % 7 + 1; Refresh(); }
simulated function OnClose(UIButton Button) { CloseScreen(); }

defaultproperties
{
	InputState = eInputState_Consume;
}
