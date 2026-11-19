// The campaign's objective (features/ew-sitroom-ticker.md), as Long War's XGObjectiveManager keeps it: one objective at a
// time, each a list of steps whose state (to do, in progress, done) is read from the campaign; it advances only forward
// (NewObjective), and is cleared once all its steps are done (Update, hourly). Shown in the Situation Room in EW's
// ObjectivesScreen (UILWEWObjectives). EW's words from the player's install (lw-words.mjs, makeObjectiveWords): each line
// "Obj|<objective>|text", "Sub|<step>|text" or "Deep|<step>|text".
class LWObjectives extends Object;

var localized string Title, Complete, InProgress, Header, MoreInfo, Back;
var localized array<string> Lines;

/** EW's EGameObjective. */
const OBJ_NONE = 0;
const OBJ_CAPTURE_ALIEN = 1;
const OBJ_CAPTURE_OUTSIDER = 2;
const OBJ_OBTAIN_SHARDS = 3;
const OBJ_ASSAULT_ALIEN_BASE = 4;
const OBJ_BUILD_HYPERWAVE = 5;
const OBJ_SHOOT_DOWN_OVERSEER = 6;
const OBJ_USE_DEVICE = 7;
const OBJ_TEMPLE_SHIP = 8;

/** A step's state (EObjectiveStatus). */
const TODO = 0;
const DOING = 1;
const DONE = 2;

static function string ObjectiveName(int Obj)
{
	switch (Obj)
	{
	case OBJ_CAPTURE_ALIEN: return "CaptureAlien";
	case OBJ_CAPTURE_OUTSIDER: return "CaptureOutsider";
	case OBJ_OBTAIN_SHARDS: return "ObtainShards";
	case OBJ_ASSAULT_ALIEN_BASE: return "AssaultAlienBase";
	case OBJ_BUILD_HYPERWAVE: return "BuildHyperwaveUplink";
	case OBJ_SHOOT_DOWN_OVERSEER: return "ShootDownOverseer";
	case OBJ_USE_DEVICE: return "UseDevice";
	case OBJ_TEMPLE_SHIP: return "TempleShip";
	}
	return "";
}

static function string Word(string Kind, string Name)
{
	local string Prefix;
	local int i;

	Prefix = Kind $ "|" $ Name $ "|";
	for (i = 0; i < default.Lines.Length; i++)
		if (Left(default.Lines[i], Len(Prefix)) == Prefix)
			return Mid(default.Lines[i], Len(Prefix));
	return "";
}

/** A new objective, only ever forward (XGObjectiveManager.NewObjective). */
static function Advance(XComGameState_LWStrategy S, int Obj)
{
	if (S.Objective >= Obj)
		return;
	S.Objective = Obj;
	`log("LongWarX2: objective:" @ ObjectiveName(Obj), , 'LongWarX2');
}

/** A research done (XGResearchUI, as the report closes): Xenobiology (1) brings the capture of an alien; an interrogation
 *  while that is the objective, the Outsider's; Alien Operations (3), a satellite over an occupied country. */
static function Researched(XComGameState_LWStrategy S, int Tech)
{
	if (Tech == 1)
		Advance(S, OBJ_CAPTURE_ALIEN);
	else if (class'LWResearchRules'.static.IsInterrogation(Tech) && S.Objective == OBJ_CAPTURE_ALIEN)
		Advance(S, OBJ_CAPTURE_OUTSIDER);
	else if (Tech == 3)
		Advance(S, OBJ_OBTAIN_SHARDS);
}

/** An hour (XGObjectiveManager.Update): the objective cleared once all its steps are done. */
static function Hour(XComGameState_LWStrategy S)
{
	local array<name> Steps;
	local array<int> States;
	local int i;

	// APPROXIMATION: Long War cracks the aliens' code when a satellite watches a country that signed their pact, and then
	// sets the base's assault (XGFacility_SituationRoom.OnCodeCracked); the port has no satellites over countries that left,
	// so an alien base known, once the code is the objective, stands for it.
	if (S.Objective == OBJ_OBTAIN_SHARDS && S.AlienBases.Length > 0)
		Advance(S, OBJ_ASSAULT_ALIEN_BASE);
	if (S.Objective == OBJ_NONE)
		return;
	StepsOf(S, S.Objective, Steps, States);
	for (i = 0; i < States.Length; i++)
		if (States[i] != DONE)
			return;
	`log("LongWarX2: objective done:" @ ObjectiveName(S.Objective), , 'LongWarX2');
	S.Objective = OBJ_NONE;
}

/** An objective's steps and their states (XGObjectiveManager.GetSubObjectives). */
static function StepsOf(XComGameState_LWStrategy S, int Obj, out array<name> Steps, out array<int> States)
{
	Steps.Length = 0;
	States.Length = 0;
	switch (Obj)
	{
	case OBJ_CAPTURE_ALIEN:
		Add(S, 'BuildAlienContainment', Steps, States);
		Add(S, 'ResearchArcThrower', Steps, States);
		Add(S, 'CaptureLiveAlien', Steps, States);
		Add(S, 'InterrogateCaptive', Steps, States);
		break;
	case OBJ_CAPTURE_OUTSIDER:
		Add(S, 'CaptureOutsider', Steps, States);
		if (States[States.Length - 1] == DONE && TechDone(4))
			Add(S, 'ResearchShard', Steps, States);
		if (!TechDone(13))
			Add(S, 'BuildArcThrower', Steps, States);
		else if (!TechDone(4))
			Add(S, 'ResearchPsionics', Steps, States);
		break;
	case OBJ_OBTAIN_SHARDS:
		Add(S, 'ObtainShards', Steps, States);
		break;
	case OBJ_ASSAULT_ALIEN_BASE:
		Add(S, 'BuildSkeletonKey', Steps, States);
		Add(S, 'AssaultAlienBase', Steps, States);
		break;
	case OBJ_BUILD_HYPERWAVE:
		Add(S, 'ResearchHyperwaveBeacon', Steps, States);
		if (States[States.Length - 1] == DONE)
		{
			Add(S, 'BuildHyperwaveUplink', Steps, States);
			Add(S, 'DetectAnOverseer', Steps, States);
		}
		break;
	case OBJ_SHOOT_DOWN_OVERSEER:
		Add(S, TechDone(5) ? 'ResearchFirestorm' : 'BuildFirestorm', Steps, States);
		Add(S, 'ShootDownOverseer', Steps, States);
		Add(S, 'AssaultOverseer', Steps, States);
		break;
	case OBJ_USE_DEVICE:
		if (class'LWBase'.static.Count(S, 17) == 0)
			Add(S, 'BuildPsiLabs', Steps, States);
		else if (!S.bHadPsiSoldier)
			Add(S, 'TestTroops', Steps, States);
		Add(S, 'ResearchPsiLink', Steps, States);
		if (States[States.Length - 1] == DONE)
			Add(S, 'BuildGollopChamber', Steps, States);
		if (S.bHadPsiSoldier)
			Add(S, 'DevelopPsiStrength', Steps, States);
		Add(S, 'UseDevice', Steps, States);
		break;
	case OBJ_TEMPLE_SHIP:
		Add(S, 'AssaultTempleShip', Steps, States);
		break;
	}
}

static function Add(XComGameState_LWStrategy S, name Step, out array<name> Steps, out array<int> States)
{
	Steps.AddItem(Step);
	States.AddItem(StateOf(S, Step));
}

static function bool TechDone(int Tech)
{
	local name T;

	T = class'LWResearchRules'.static.TemplateForId(Tech);
	return T != '' && class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(T);
}

static function int Researching()
{
	local XComGameState_Tech Tech;

	Tech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().GetCurrentResearchTech().ObjectID));
	return Tech == none ? -1 : class'LWResearchRules'.static.IdOfTemplate(Tech.GetMyTemplateName());
}

/** A research step: done when researched, in progress while being researched. */
static function int ResearchState(int Tech)
{
	return TechDone(Tech) ? DONE : (Researching() == Tech ? DOING : TODO);
}

/** A facility step: done when built, in progress while being built. */
static function int FacilityState(XComGameState_LWStrategy S, int Facility)
{
	return class'LWBase'.static.Count(S, Facility) > 0 ? DONE : (class'LWBase'.static.Building(S, Facility) > 0 ? DOING : TODO);
}

/** An item step: done once XCOM has ever held it, in progress while engineering builds it. */
static function int ItemState(XComGameState_LWStrategy S, int Item, name Template)
{
	local int i;

	if (EverHad(Template))
		return DONE;
	for (i = 0; i < S.Builds.Length; i++)
		if (S.Builds[i].Item == Item)
			return DOING;
	return TODO;
}

static function bool EverHad(name Template)
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().EverAcquiredInventoryTypes.Find(Template) != INDEX_NONE;
}

static function bool Interrogated()
{
	local int Id;

	for (Id = 0; Id < 100; Id++)
		if (class'LWResearchRules'.static.IsInterrogation(Id) && TechDone(Id))
			return true;
	return false;
}

/** A step's state (XGObjectiveManager.BuildSubObjective). */
static function int StateOf(XComGameState_LWStrategy S, name Step)
{
	local int i;

	switch (Step)
	{
	case 'BuildAlienContainment': return FacilityState(S, 13);
	case 'BuildHyperwaveUplink': return FacilityState(S, 18);
	case 'BuildPsiLabs': return FacilityState(S, 17);
	case 'BuildGollopChamber': return FacilityState(S, 19);
	case 'BuildArcThrower': return ResearchState(13);
	case 'ResearchShard': return ResearchState(3);
	case 'ResearchHyperwaveBeacon': return ResearchState(7);
	case 'ResearchFirestorm': return ResearchState(5);
	case 'ResearchPsionics': return ResearchState(4);
	case 'ResearchPsiLink': return ResearchState(8);
	case 'CaptureOutsider': return ItemState(S, 183, 'LWItem_Base_Shard');
	case 'BuildSkeletonKey': return ItemState(S, 184, 'LWItem_Skeleton_Key');
	case 'BuildFirestorm':
		// (A Firestorm built becomes a craft in the hangar here, not a stored item.)
		for (i = 0; class'XComGameState_LWAirWar'.static.Get() != none && i < class'XComGameState_LWAirWar'.static.Get().Jets.Length; i++)
			if (class'XComGameState_LWAirWar'.static.Get().Jets[i].Type == 3)
				return DONE;
		return ItemState(S, 104, 'LWItem_Firestorm');
	case 'AssaultOverseer': return S.bHadPsiLink ? DONE : TODO;
	case 'ResearchArcThrower':
		// (Xenoneurology researched and an arc thrower made: done; researched, or being researched: in progress.)
		if (TechDone(2))
			return EverHad('LWSmall_73') ? DONE : DOING;
		return Researching() == 2 ? DOING : TODO;
	case 'CaptureLiveAlien': return Interrogated() ? DONE : TODO;
	case 'InterrogateCaptive':
		if (Interrogated())
			return DONE;
		return class'LWResearchRules'.static.IsInterrogation(Researching()) ? DOING : TODO;
	// APPROXIMATION: the port has no alien code to crack; an alien base known stands for it.
	case 'ObtainShards': return S.AlienBases.Length > 0 ? DONE : TODO;
	case 'AssaultAlienBase': return S.bHadHyperwaveBeacon ? DONE : (S.PendingKind == 5 ? DOING : TODO);
	case 'DetectAnOverseer': return class'LWBase'.static.Count(S, 18) > 0 ? DOING : TODO;
	case 'ShootDownOverseer': return S.bHadPsiLink ? DONE : TODO;
	case 'TestTroops': return S.bHadPsiSoldier ? DONE : (S.PsiTrainees.Length > 0 ? DOING : TODO);
	case 'DevelopPsiStrength': return Researching() == 14 ? DOING : TODO;
	case 'UseDevice': return S.bCampaignWon ? DONE : TODO;
	case 'AssaultTempleShip': return S.bCampaignWon ? DONE : (S.PendingKind == 6 ? DOING : TODO);
	}
	return TODO;
}

/** The brief list (UISituationRoom.RealizeObjectives' small text): each step bulleted, coloured by its state, with EW's
 *  "(In Progress)" or "- Completed!". */
static function string Brief(XComGameState_LWStrategy S)
{
	local array<name> Steps;
	local array<int> States;
	local string Out;
	local int i;

	StepsOf(S, S.Objective, Steps, States);
	for (i = 0; i < Steps.Length; i++)
	{
		if (Out != "")
			Out $= "<br>";
		Out $= StepLine(Steps[i], States[i]);
	}
	return Out;
}

/** The full text (MORE INFO): each step and its explanation. */
static function string Large(XComGameState_LWStrategy S)
{
	local array<name> Steps;
	local array<int> States;
	local string Out;
	local int i;

	StepsOf(S, S.Objective, Steps, States);
	if (Steps.Length == 0)
		return "";
	Out = Word("Obj", ObjectiveName(S.Objective));
	for (i = 0; i < Steps.Length; i++)
		Out $= "<br><br>" $ StepLine(Steps[i], States[i]) $ "<br>" $ Word("Deep", string(Steps[i]));
	return Out;
}

static function string StepLine(name Step, int State)
{
	local string Line;

	Line = Chr(8226) @ Word("Sub", string(Step));
	if (State == DONE)
		return class'UIUtilities_Text'.static.GetColoredText(Line @ default.Complete, eUIState_Good);
	if (State == DOING)
		return class'UIUtilities_Text'.static.GetColoredText(Line @ default.InProgress, eUIState_Warning);
	return class'UIUtilities_Text'.static.GetColoredText(Line, eUIState_Highlight);
}
