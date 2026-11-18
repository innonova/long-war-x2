// Enemy Within's ship loadout screen (its ShipLoadout movie, features/lw-ew-screens.md; the craft summary's EDIT LOADOUT),
// driven as EW's UIShipLoadout drives it from XGHangarUI's table: CHOOSE LOADOUT, the craft weapons XCOM has with how many
// are in the stores ("x2"; none shown for the missiles, which never run out), the equipped one greyed; for the one selected
// its name, picture and summary, and EW's five ratings from Long War's numbers: to hit at the three stances
// ("% To Hit (D/B/A): 25/40/55"), range, fire rate, damage and armour penetration as EW bins them (XGHangarUI's
// GetShipWeapon*Bin). A click 391 on "theItems" selects and equips, 392 selects; equipped once confirmed (LWHangar.Equip).
class UILWEWShipLoadout extends UILWEWScreen;

var localized string m_strScreenTitle, m_strShipWeaponColumnLabel, m_strQuantityColumnLabel, m_strConfirmEquipDialogTitle,
	m_strConfirmEquipDialogAcceptText, m_strConfirmEquipDialogText;
/** UIItemCards' labels and ratings (XComGame.int). */
var localized string m_strHitChanceLabel, m_strRangeLabel, m_strFireRateLabel, m_strDamageLabel, m_strArmorPenetrationLabel,
	m_strRangeShort, m_strRangeMedium, m_strRangeLong, m_strRateSlow, m_strRateMedium, m_strRateRapid, m_strGenericScaleLow,
	m_strGenericScaleMedium, m_strGenericScaleHigh;

/** The jet (its index in the air war) and the weapons listed (Long War's ship weapon numbers). */
var int Jet;
var array<int> Weapons;
var int Selected;

static function Open(XComHQPresentationLayer HQPres, int JetIndex)
{
	local UILWEWShipLoadout EWScreen;

	DynamicLoadObject(default.UIPackage $ ".ewxShipLoadout", class'Object', true);
	EWScreen = HQPres.Spawn(class'UILWEWShipLoadout', HQPres);
	EWScreen.Package = name("/ package/ewxShipLoadout/ShipLoadout");
	EWScreen.MCName = 'theScreen';
	EWScreen.Jet = JetIndex;
	HQPres.ScreenStack.Push(EWScreen);
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

/** The hours a change of weapon takes (missiles 12, the rest Long War's rearm time). */
static function int RefitHours(int Weapon)
{
	return (Weapon == 2 || Weapon == 3) ? 12 : class'LWBaseRules'.default.RearmHours;
}

simulated function OnInit()
{
	local XComGameState_LWAirWar AirWar;
	local name Item;
	local int w;

	super.OnInit();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	MC.FunctionString("SetTitle", Word(m_strScreenTitle, "CHOOSE LOADOUT"));
	MC.BeginFunctionOp("SetListLabels");
	MC.QueueString(Word(m_strShipWeaponColumnLabel, "SHIP WEAPON"));
	MC.QueueString(Word(m_strQuantityColumnLabel, "QUANTITY"));
	MC.EndOp();
	MC.FunctionVoid("clear");
	// The weapons Long War's interceptors carry (Avalanche and Stingray missiles always there, the rest from the stores).
	for (w = 1; w <= 7; w++)
	{
		Item = class'LWHangar'.static.WeaponItem(w);
		if (w != AirWar.Jets[Jet].Weapon && Item != '' && class'LWEngineering'.static.Held(Item) < 1)
			continue;
		Weapons.AddItem(w);
		MC.BeginFunctionOp("AddWeapon");
		MC.QueueString(class'LWHangar'.static.WeaponName(w));
		MC.QueueString(Item == '' ? "" : "x" $ class'LWEngineering'.static.Held(Item));
		MC.QueueBoolean(w == AirWar.Jets[Jet].Weapon);
		MC.EndOp();
	}
	Select(Max(0, Weapons.Find(AirWar.Jets[Jet].Weapon)));
}

/** A weapon selected (UIShipLoadout.RealizeSelected). */
function Select(int Index)
{
	local LWAirWar.LWWeaponDef W;
	local X2ItemTemplate Template;
	local string Rating;

	if (Weapons.Length == 0)
		return;
	Selected = (Index + Weapons.Length) % Weapons.Length;
	foreach class'LWAirWar'.default.Weapons(W)
		if (W.Id == Weapons[Selected])
			break;
	Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'LWHangar'.static.WeaponItem(W.Id));
	Stat(0, Word(m_strHitChanceLabel, "% To Hit (D/B/A):"), Min(W.ToHit - 15, 95) $ "/" $ Min(W.ToHit, 95) $ "/" $ Min(W.ToHit + 15, 95));
	Rating = W.Range <= 90 ? m_strRangeShort : (W.Range <= 95 ? m_strRangeMedium : m_strRangeLong);
	Stat(1, Word(m_strRangeLabel, "Range:"), Rating);
	Rating = W.FiringTime < 1.0 ? m_strRateRapid : (W.FiringTime <= 1.25 ? m_strRateMedium : m_strRateSlow);
	Stat(2, Word(m_strFireRateLabel, "Fire Rate:"), Rating);
	Rating = W.Damage <= 200 ? m_strGenericScaleLow : (W.Damage < 600 ? m_strGenericScaleMedium : m_strGenericScaleHigh);
	Stat(3, Word(m_strDamageLabel, "Damage:"), Rating);
	Rating = W.Ap < 10 ? m_strGenericScaleLow : (W.Ap <= 20 ? m_strGenericScaleMedium : m_strGenericScaleHigh);
	Stat(4, Word(m_strArmorPenetrationLabel, "Armor Penetration:"), Rating);
	MC.FunctionNum("SetSelected", Selected);
	MC.FunctionString("SetWeaponName", class'LWHangar'.static.WeaponName(W.Id));
	MC.BeginFunctionOp("SetWeaponImage");
	MC.QueueString(class'LWX2Pictures'.static.Item(class'UILWEWShipSummary'.static.WeaponItemNumber(W.Id), ""));
	MC.QueueNumber(0.9);
	MC.EndOp();
	MC.FunctionString("SetWeaponDescription", Template != none ? Template.GetItemBriefSummary() : "");
}

function Stat(int i, string Label, string Value)
{
	MC.BeginFunctionOp("SetStatData");
	MC.QueueNumber(i);
	MC.QueueString(Label);
	MC.QueueString(Value);
	MC.QueueString("");
	MC.EndOp();
}

/** The selected weapon equipped (refitting the craft for its hours), once confirmed. */
function Accept()
{
	local TDialogueBoxData Data;
	local XComGameState_LWAirWar AirWar;

	AirWar = class'XComGameState_LWAirWar'.static.Get();
	if (Weapons.Length == 0 || Weapons[Selected] == AirWar.Jets[Jet].Weapon)
		return;
	Data.eType = eDialog_Normal;
	Data.strTitle = Word(m_strConfirmEquipDialogTitle, "CONFIRM LOADOUT CHANGE");
	Data.strText = Repl(Repl(Word(m_strConfirmEquipDialogText, "New loadout: <XGParam:StrValue0/>. <br><br>Hours until combat ready: <XGParam:IntValue0/>."),
		"<XGParam:StrValue0/>", class'LWHangar'.static.WeaponName(Weapons[Selected])), "<XGParam:IntValue0/>", string(RefitHours(Weapons[Selected])));
	Data.strAccept = Word(m_strConfirmEquipDialogAcceptText, "CONFIRM");
	Data.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Data.fnCallback = OnEquipDialog;
	Movie.Pres.UIRaiseDialog(Data);
}

simulated function OnEquipDialog(Name Action)
{
	local string Why;

	if (Action != 'eUIAction_Accept')
		return;
	if (!class'LWHangar'.static.Equip(Jet, Weapons[Selected], Why))
		`log("LongWarX2: EW ship loadout:" @ Why, , 'LongWarX2');
	CloseScreen();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	if ((cmd == 391 || cmd == 392) && args.Length > 2 && args[args.Length - 2] == "theItems")
	{
		Select(int(args[args.Length - 1]));
		if (cmd == 391)
			Accept();
	}
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
