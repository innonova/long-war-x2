// Enemy Within's own ship loadout screen (its ShipLoadout movie, features/lw-ew-screens.md): the craft weapons XCOM has,
// with how many are in the stores and Long War's numbers for the one selected; driven as EW's UIShipLoadout drives it
// (SetTitle, SetListLabels, clear, AddWeapon, SetSelected, SetWeaponName, SetWeaponDescription, SetStatData; a click
// 391 on "theItems" selects and equips, 392 selects). Equipped once confirmed, with LWHangar.Equip.
class UILWEWShipLoadout extends UILWEWScreen;

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

simulated function OnInit()
{
	local XComGameState_LWAirWar AirWar;
	local int w;

	super.OnInit();
	AirWar = class'XComGameState_LWAirWar'.static.Get();
	MC.FunctionString("SetTitle", "LOADOUT:" @ Caps(AirWar.Jets[Jet].Callsign));
	MC.BeginFunctionOp("SetListLabels");
	MC.QueueString("SHIP WEAPON");
	MC.QueueString("QUANTITY");
	MC.EndOp();
	MC.FunctionVoid("clear");
	// The weapons Long War's interceptors carry (Avalanche and Stingray missiles always there, the rest from the stores).
	for (w = 1; w <= 7; w++)
	{
		if (w != AirWar.Jets[Jet].Weapon && class'LWHangar'.static.WeaponItem(w) != '' && class'LWEngineering'.static.Held(class'LWHangar'.static.WeaponItem(w)) < 1)
			continue;
		Weapons.AddItem(w);
		MC.BeginFunctionOp("AddWeapon");
		MC.QueueString(class'LWHangar'.static.WeaponName(w) $ (w == AirWar.Jets[Jet].Weapon ? " (EQUIPPED)" : ""));
		MC.QueueString(class'LWHangar'.static.WeaponItem(w) == '' ? "-" : string(class'LWEngineering'.static.Held(class'LWHangar'.static.WeaponItem(w))));
		MC.QueueBoolean(w == AirWar.Jets[Jet].Weapon);
		MC.EndOp();
	}
	Select(Max(0, Weapons.Find(AirWar.Jets[Jet].Weapon)));
}

/** A weapon selected: its name and Long War's numbers (to-hit, firing time, damage, armour piercing). */
function Select(int Index)
{
	local LWAirWar.LWWeaponDef W;

	if (Weapons.Length == 0)
		return;
	Selected = (Index + Weapons.Length) % Weapons.Length;
	foreach class'LWAirWar'.default.Weapons(W)
		if (W.Id == Weapons[Selected])
			break;
	MC.FunctionNum("SetSelected", Selected);
	MC.FunctionString("SetWeaponName", Caps(W.Name));
	MC.FunctionString("SetWeaponDescription", "Equipping takes" @ ((W.Id == 2 || W.Id == 3) ? 12 : class'LWBaseRules'.default.RearmHours) @ "hours, during which the craft cannot fly.");
	Stat(0, "HIT CHANCE", W.ToHit $ "%");
	Stat(1, "FIRING TIME", Left(string(W.FiringTime), InStr(string(W.FiringTime), ".") + 2) $ "s");
	Stat(2, "DAMAGE", string(W.Damage));
	Stat(3, "ARMOR PIERCING", string(W.Ap));
	Stat(4, "", "");
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
	Data.strTitle = "CONFIRM LOADOUT CHANGE";
	Data.strText = "New loadout:" @ class'LWHangar'.static.WeaponName(Weapons[Selected]) $ ".<br><br>Hours until combat ready:"
		@ ((Weapons[Selected] == 2 || Weapons[Selected] == 3) ? 12 : class'LWBaseRules'.default.RearmHours) $ ".";
	Data.strAccept = "CONFIRM";
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
