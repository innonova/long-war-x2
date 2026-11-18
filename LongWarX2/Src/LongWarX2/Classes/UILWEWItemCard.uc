// Enemy Within's item card (its ItemCards movie; EW's UIItemCards): one card over the screen that asked for it, closed by
// Esc, a right click or its back button. Filled as UIItemCards.UpdateData fills a card of its type; the kinds in the port so
// far: a craft weapon's card (eItemCard_ShipWeapon: to hit at the three stances, range, fire rate, damage, armour
// penetration as XGHangarUI bins them, its tactical info, its picture) and a craft's (eItemCard_Interceptor: its type's
// name and Long War's text about it, its picture). The craft summary's WEAPON INFO and SHIP INFO open them.
class UILWEWItemCard extends UILWEWScreen;

/** EW's card words (UIItemCards). */
var localized string m_strTacticalInfoHeader, m_strCloseCardLabel;
/** Craft weapons' and craft types' texts (XGItemTree.ShipWeaponFlavorTxt by EShipWeapon, ShipTypeFlavorTxt by EShipType)
 *  and the craft types' names. */
var localized string WeaponText[8], CraftText[4], CraftName[4];

/** EW's card type (3 a craft weapon, 8 a craft) and what it shows (Long War's craft weapon number, or its craft type). */
var int CardType, What;

static function OpenShipWeapon(XComHQPresentationLayer HQPres, int Weapon)
{
	Open(HQPres, 3, Weapon);
}

/** A craft's card: Long War's craft type (1 interceptor, 3 Firestorm: EW's EShipType). */
static function OpenCraft(XComHQPresentationLayer HQPres, int Type)
{
	Open(HQPres, 8, Type);
}

static function Open(XComHQPresentationLayer HQPres, int Card, int Which)
{
	local UILWEWItemCard S;

	DynamicLoadObject(default.UIPackage $ ".ewxItemCards", class'Object', true);
	S = HQPres.Spawn(class'UILWEWItemCard', HQPres);
	S.Package = name("/ package/ewxItemCards/ItemCards");
	S.MCName = 'theScreen';
	S.CardType = Card;
	S.What = Which;
	HQPres.ScreenStack.Push(S);
}

static function string Word(string W, string Fallback)
{
	return W != "" ? W : Fallback;
}

simulated function OnInit()
{
	super.OnInit();
	SetTimer(0.1, false, nameof(Fill));
}

function Fill()
{
	local LWAirWar.LWWeaponDef W;
	local class<UILWEWShipLoadout> L;
	local array<ASValue> Params, NoArgs;
	local int i;

	L = class'UILWEWShipLoadout';
	Params.AddItem(Str(Word(m_strCloseCardLabel, "CLOSE")));
	Params.AddItem(Str(""));
	CallNow("SetHelp", Params);
	if (CardType == 3)
	{
		foreach class'LWAirWar'.default.Weapons(W)
			if (W.Id == What)
				break;
		Title(Caps(class'LWHangar'.static.WeaponName(What)));
		StatLine(0, Word(L.default.m_strHitChanceLabel, "% To Hit (D/B/A):"), Min(W.ToHit - 15, 95) $ "/" $ Min(W.ToHit, 95) $ "/" $ Min(W.ToHit + 15, 95));
		StatLine(1, Word(L.default.m_strRangeLabel, "Range:"), W.Range <= 90 ? L.default.m_strRangeShort : (W.Range <= 95 ? L.default.m_strRangeMedium : L.default.m_strRangeLong));
		StatLine(2, Word(L.default.m_strFireRateLabel, "Fire Rate:"), W.FiringTime < 1.0 ? L.default.m_strRateRapid : (W.FiringTime <= 1.25 ? L.default.m_strRateMedium : L.default.m_strRateSlow));
		StatLine(3, Word(L.default.m_strDamageLabel, "Damage:"), W.Damage <= 200 ? L.default.m_strGenericScaleLow : (W.Damage < 600 ? L.default.m_strGenericScaleMedium : L.default.m_strGenericScaleHigh));
		StatLine(4, Word(L.default.m_strArmorPenetrationLabel, "Armor Penetration:"), W.Ap < 10 ? L.default.m_strGenericScaleLow : (W.Ap <= 20 ? L.default.m_strGenericScaleMedium : L.default.m_strGenericScaleHigh));
		Params.Length = 0;
		Params.AddItem(Str(Word(m_strTacticalInfoHeader, "TACTICAL INFO")));
		Params.AddItem(Str((What >= 0 && What < 8) ? Repl(WeaponText[What], "<Bullet/>", Chr(8226)) : ""));
		CallNow("AddTacticalInfoCardData", Params);
		Image(class'LWX2Pictures'.static.Item(class'UILWEWShipSummary'.static.WeaponItemNumber(What), ""));
	}
	else
	{
		i = Clamp(What, 0, 3);
		Title(Caps(CraftName[i]));
		Params.Length = 0;
		Params.AddItem(Str(Repl(CraftText[i], "<Bullet/>", Chr(8226))));
		CallNow("AddSimpleTextCardData", Params);
		// (Long War's item numbers for the craft: the Interceptor 103, the Firestorm 104.)
		Image(class'LWX2Pictures'.static.Item(i == 3 ? 104 : 103, ""));
	}
	CallNow("InitializationComplete", NoArgs);
}

function Title(string T)
{
	local array<ASValue> Params;

	Params.AddItem(Str(T));
	CallNow("SetCardTitle", Params);
}

function StatLine(int i, string Label, string Value)
{
	local array<ASValue> Params;

	Params.AddItem(Num(i));
	Params.AddItem(Str(Label));
	Params.AddItem(Str(Value));
	Params.AddItem(Str(""));
	CallNow("SetStatData", Params);
}

function Image(string Path)
{
	local array<ASValue> Params;

	Params.AddItem(Str(Path));
	Params.AddItem(Num(CardType));
	CallNow("SetCardImage", Params);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP && args.Length > 0 && args[args.Length - 1] == "theBackButton")
	{
		CloseScreen();
		return;
	}
	super.OnMouseEvent(cmd, args);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ((arg & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			CloseScreen();
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
			CallNow("ScrollUp");
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
			CallNow("ScrollDown");
			return true;
		}
	}
	return super.OnUnrealCommand(cmd, arg);
}
