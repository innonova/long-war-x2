// Long War's pictures for EW's strategy screens (features/lw-ew-pictures.md): each item's, tech's and Foundry project's
// picture, as Long War's UIUtilities finds them (GetItemImagePath, GetTechImagePath, GetFoundryImagePath: its
// DefaultContent.ini's table, keyed by the item's, tech's or project's own number), listed on the player's machine by the
// setup (tools/convert/ew-pictures.ts: XComLWX2Images.ini, EW's own pictures where the converted base carries them, Long
// War's in its converted LongWar.upk). Empty without that list: the screens keep XCOM 2's pictures.
class LWX2Pictures extends Object config(LWX2Images);

struct LWX2Picture
{
	var int Id;
	var string Path;
};

var config array<LWX2Picture> Items, Techs, Foundry;

static function string ItemImage(int Item)
{
	return Find(default.Items, Item);
}

static function string TechImage(int Tech)
{
	return Find(default.Techs, Tech);
}

static function string FoundryImage(int Project)
{
	return Find(default.Foundry, Project);
}

/** The picture for an item, tech or project, or the given one (XCOM 2's) when the list has none. */
static function string Item(int Id, string Fallback)
{
	return Or(ItemImage(Id), Fallback);
}

static function string Tech(int Id, string Fallback)
{
	return Or(TechImage(Id), Fallback);
}

static function string Project(int Id, string Fallback)
{
	return Or(FoundryImage(Id), Fallback);
}

static function string Or(string A, string B)
{
	return A != "" ? A : B;
}

/** The picture's img:/// path; "" when there is none. */
static function string Find(array<LWX2Picture> Table, int Id)
{
	local int i;

	i = Table.Find('Id', Id);
	if (i == INDEX_NONE || Table[i].Path == "")
		return "";
	return "img:///" $ Table[i].Path;
}
