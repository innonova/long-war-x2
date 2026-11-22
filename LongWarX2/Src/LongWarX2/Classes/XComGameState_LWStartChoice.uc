// The base's place chosen before the campaign's first mission, as EW's order has it (features/first-mission-order.md):
// Long War's start screen's choice (home country and starting bonus, UILWStartSelect in the main menu's world), made with
// the campaign's start state (X2DownloadableContentInfo_LongWarX2.InstallNewCampaign) so that it lasts through the first
// mission and its saves; Long War's campaign is made with it when the strategy layer first opens. And the first mission's
// country: a council country of the home's continent (EW: a city of the base's continent, XGStrategyAI.CreateFirstMission).
class XComGameState_LWStartChoice extends XComGameState_BaseObject;

var int Home, Choice, FirstCountry;

static function XComGameState_LWStartChoice Get()
{
	return XComGameState_LWStartChoice(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LWStartChoice', true));
}

/** Into the campaign's start state, when the main menu's start screen chose (LWX2FirstMissionStart.StartHome). */
static function CreateIn(XComGameState StartState)
{
	local XComGameState_LWStartChoice C;
	local array<int> Near;
	local int i, Home;

	Home = class'LWX2FirstMissionStart'.default.StartHome;
	if (Home < 0)
		return;
	C = XComGameState_LWStartChoice(StartState.CreateNewStateObject(class'XComGameState_LWStartChoice'));
	C.Home = Home;
	C.Choice = class'LWX2FirstMissionStart'.default.StartChoice;
	for (i = 0; i < class'LWStrategyRules'.default.Countries.Length; i++)
		if (class'LWStrategyRules'.default.Countries[i].Continent == class'LWStrategyRules'.default.Countries[Home].Continent)
			Near.AddItem(i);
	C.FirstCountry = Near.Length > 0 ? Near[Rand(Near.Length)] : Home;
	class'LWX2FirstMissionStart'.default.StartHome = -1;
	`log("LongWarX2: the campaign's start: home" @ class'LWStrategyRules'.default.Countries[Home].Name $ ", option" @ C.Choice $ "; the first mission in" @ class'LWStrategyRules'.default.Countries[C.FirstCountry].Name, , 'LongWarX2');
}
