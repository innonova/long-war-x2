// Long War's soldier armours as XCOM 2's (features/lw-gear.md, phase 2): an armour template each, from
// LWGearRules. Long War's numbers (HP, defence, will, mobility) are a stat ability of the armour's
// (X2Ability_LWArmorStats); two small items mean XCOM 2's second utility slot; grapple is XCOM 2's.
// Its look is an XCOM 2 armour's: images and sounds copied, and that armour's body parts cloned for it
// (XCOM 2 picks a soldier's torso, arms and legs by the armour's template name), once every template is
// built (CopyLooks). Those Long War never builds are unlimited. Its words are Long War's (lw-words.mjs).
class X2Item_LWArmors extends X2Item dependson(LWGearRules);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local LWGearRules.LWArmorDef A;

	foreach class'LWGearRules'.default.Armors(A)
		Templates.AddItem(ArmorTemplate(A));
	return Templates;
}

static function X2ArmorTemplate ArmorTemplate(LWGearRules.LWArmorDef A)
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, class'LWGearRules'.static.ArmorTemplateFor(A.Item));
	Template.ItemCat = 'armor';
	Template.Tier = class'LWGearRules'.default.Armors.Find('Item', A.Item);
	Template.Abilities.AddItem(class'X2Ability_LWArmorStats'.static.StatsFor(A.Item));
	if (A.Grapple)
		Template.Abilities.AddItem('Grapple');
	Template.bAddsUtilitySlot = A.SmallItems >= 2;
	Template.StartingItem = A.Infinite;
	Template.bInfiniteItem = A.Infinite;
	Template.CanBeBuilt = false;
	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, A.HP, true);
	if (A.Mobility != 0)
		Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, A.Mobility);
	if (A.Defense != 0)
		Template.SetUIStatMarkup(class'XLocalizedData'.default.DefenseLabel, eStat_Defense, A.Defense);
	if (A.Will != 0)
		Template.SetUIStatMarkup(class'XLocalizedData'.default.WillLabel, eStat_Will, A.Will);
	return Template;
}

/** Body part types XCOM 2 matches to the armour worn. */
static function array<string> PartTypes()
{
	local array<string> T;

	T.AddItem("Torso");
	T.AddItem("Arms");
	T.AddItem("Legs");
	T.AddItem("Helmets");
	T.AddItem("LeftArm");
	T.AddItem("RightArm");
	T.AddItem("LeftArmDeco");
	T.AddItem("RightArmDeco");
	T.AddItem("LeftForearm");
	T.AddItem("RightForearm");
	T.AddItem("Thighs");
	T.AddItem("Shins");
	T.AddItem("TorsoDeco");
	return T;
}

/** Every Long War armour takes its look from its XCOM 2 armour (OnPostTemplatesCreated). */
static function CopyLooks()
{
	local X2ItemTemplateManager Manager;
	local X2BodyPartTemplateManager Parts;
	local array<X2DataTemplate> Variants;
	local array<X2BodyPartTemplate> OfType;
	local X2DataTemplate Data;
	local X2ArmorTemplate Mine, Look;
	local X2BodyPartTemplate Part, Clone;
	local LWGearRules.LWArmorDef A;
	local array<string> Types;
	local string PartType;
	local name CloneName;
	local int Copied, Cloned;

	Manager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	Parts = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	Types = PartTypes();
	foreach class'LWGearRules'.default.Armors(A)
	{
		Look = X2ArmorTemplate(Manager.FindItemTemplate(A.Look));
		if (Look == none)
		{
			`log("LongWarX2: gear: no XCOM 2 armour" @ A.Look @ "for" @ A.Item, , 'LongWarX2');
			continue;
		}
		Manager.FindDataTemplateAllDifficulties(class'LWGearRules'.static.ArmorTemplateFor(A.Item), Variants);
		foreach Variants(Data)
		{
			Mine = X2ArmorTemplate(Data);
			Mine.strImage = Look.strImage;
			Mine.ArmorTechCat = Look.ArmorTechCat;
			Mine.ArmorClass = Look.ArmorClass;
			Mine.AkAudioSoldierArmorSwitch = Look.AkAudioSoldierArmorSwitch;
			Mine.EquipSound = Look.EquipSound;
		}
		Copied++;
		if (Parts == none)
			continue;
		foreach Types(PartType)
		{
			OfType.Length = 0;
			Parts.GetUberTemplates(PartType, OfType);
			foreach OfType(Part)
			{
				if (Part.ArmorTemplate != A.Look)
					continue;
				CloneName = name(Part.DataName $ "_" $ class'LWGearRules'.static.ArmorTemplateFor(A.Item));
				// Unnamed, as XCOM 2 makes its own torsos, arms and legs: their names repeat across part types, and a
				// named object of the same name would be the same object (a torso's clone overwritten by the legs').
				Clone = new class'X2BodyPartTemplate'(Part);
				Clone.SetTemplateName(CloneName);
				Clone.ArmorTemplate = class'LWGearRules'.static.ArmorTemplateFor(A.Item);
				if (Parts.AddUberTemplate(PartType, Clone, true))
					Cloned++;
			}
		}
	}
	`log("LongWarX2: gear:" @ Copied @ "of" @ class'LWGearRules'.default.Armors.Length @ "armours look like XCOM 2's," @ Cloned @ "body parts cloned", , 'LongWarX2');
}
