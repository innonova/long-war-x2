// Long War's base (features/lw-base.md): XCOM's headquarters as Long War's grid of 7 x 5 tiles under
// the ground (XGBase), its rooms dug out and built, its power, upkeep and adjacency bonuses. The tiles
// and the work under way are the Geoscape's state (XComGameState_LWStrategy), moved on with its clock.
//
// Long War's rules, read from its code:
// - The start (XGBase.GenerateTiles): the top row open, with the hangar, barracks, mission control and
//   research; an access lift and a satellite uplink below; the second row open on the left and three in
//   four of its right-hand tiles rock; the rows below rock, a fifth open, and two steam vents.
// - A tile can be worked once it has access (the top row; the access shaft below a lift; a row with a
//   lift in the shaft) and the tiles between it and the shaft are open (XGBase.HasAccess, HasExcavation).
// - Digging costs ExcavateCash x 2^(row - 1) and takes ExcavateDays; a lift is built in the shaft, the
//   other facilities beside it; a thermo generator needs a steam vent (XGBuildUI).
// - A facility needs its tech, its power free, and for labs, workshops and uplinks enough staff
//   (XGItemTree.CanFacilityBeBuilt, XGFacility_Engineering.GetFacilityProjectCost); it is paid at the
//   start and takes its days whatever the engineers.
// - Adjacent facilities of a kind (power, satellites, science, engineering) give bonuses
//   (XGBase.GetAdjacencies): power, satellites, research, and the workshops' cuts.
class LWBase extends Object dependson(LWBaseRules, XComGameState_LWStrategy);

const W = 7;
const H = 5;
const SHAFT = 3;

const ROCK = 0;
const ROCK_STEAM = 1;
const OPEN = 2;
const DUG = 3;
const DUG_STEAM = 4;
const BUILT = 5;

const ADJ_POWER = 1;
const ADJ_SATELLITES = 2;
const ADJ_SCIENCE = 3;
const ADJ_ENGINEERING = 4;

static function int TileIndex(int X, int Y) { return X + Y * W; }
static function bool IsValid(int X, int Y) { return X >= 0 && X < W && Y >= 0 && Y < H; }

/** Long War's starting base (GenerateTiles; no council bonuses yet). */
static function Generate(XComGameState_LWStrategy S)
{
	local array<int> DeepRock;
	local int X, Y, i, k;

	S.TileType.Length = 0;
	S.TileFacility.Length = 0;
	S.TileType.Add(W * H);
	S.TileFacility.Add(W * H);
	for (Y = 0; Y < H; Y++)
	{
		for (X = 0; X < W; X++)
		{
			if (Y == 0)
				S.TileType[TileIndex(X, Y)] = DUG;
			else if (Y == 1)
				S.TileType[TileIndex(X, Y)] = (X > W / 2 && Rand(100) < 75) ? ROCK : DUG;
			else if (X == SHAFT)
				S.TileType[TileIndex(X, Y)] = DUG;
			else if (Rand(100) < 20)
				S.TileType[TileIndex(X, Y)] = OPEN;
			else
			{
				S.TileType[TileIndex(X, Y)] = ROCK;
				DeepRock.AddItem(TileIndex(X, Y));
			}
		}
	}
	for (i = 0; i < class'LWBaseRules'.default.SteamVents && DeepRock.Length > 0; i++)
	{
		k = Rand(DeepRock.Length);
		S.TileType[DeepRock[k]] = ROCK_STEAM;
		DeepRock.Remove(k, 1);
	}
	SetFacility(S, 1, 0, 0);
	SetFacility(S, 3, 2, 0);
	SetFacility(S, 2, 4, 0);
	SetFacility(S, 4, 6, 0);
	SetFacility(S, 6, 3, 1);
	SetFacility(S, 9, 2, 1);
}

static function SetFacility(XComGameState_LWStrategy S, int Id, int X, int Y)
{
	local LWBaseRules.LWFacilityDef F;

	S.TileType[TileIndex(X, Y)] = BUILT;
	S.TileFacility[TileIndex(X, Y)] = Id;
	if (class'LWBaseRules'.static.FacilityFor(Id, F) && F.Size == 2 && IsValid(X + 1, Y))
		S.TileType[TileIndex(X + 1, Y)] = BUILT;
}

static function int FacilityAt(XComGameState_LWStrategy S, int X, int Y)
{
	return IsValid(X, Y) ? S.TileFacility[TileIndex(X, Y)] : 0;
}

static function bool HasAccess(XComGameState_LWStrategy S, int X, int Y)
{
	if (Y == 0)
		return true;
	if (X == SHAFT)
		return FacilityAt(S, X, Y - 1) == 6;
	return FacilityAt(S, SHAFT, Y) == 6;
}

static function bool Passable(int Type)
{
	return Type == BUILT || Type == DUG || Type == DUG_STEAM || Type == OPEN;
}

static function bool HasExcavation(XComGameState_LWStrategy S, int X, int Y)
{
	local int i;

	if (X > SHAFT)
	{
		for (i = SHAFT + 1; i < X; i++)
			if (!Passable(S.TileType[TileIndex(i, Y)]))
				return false;
	}
	else if (X < SHAFT)
	{
		for (i = SHAFT - 1; i > X; i--)
			if (!Passable(S.TileType[TileIndex(i, Y)]))
				return false;
	}
	else
		return Y == 0 || FacilityAt(S, X, Y - 1) == 6;
	return true;
}

static function bool Reachable(XComGameState_LWStrategy S, int X, int Y)
{
	return IsValid(X, Y) && HasAccess(S, X, Y) && HasExcavation(S, X, Y);
}

/** The work under way on a tile (-1: none). */
static function int JobAt(XComGameState_LWStrategy S, int X, int Y)
{
	local int i;

	for (i = 0; i < S.BaseJobs.Length; i++)
		if (S.BaseJobs[i].X == X && S.BaseJobs[i].Y == Y)
			return i;
	return -1;
}

// --- What the base has ---------------------------------------------------------------------

static function int Count(XComGameState_LWStrategy S, int Id)
{
	local int i, n;

	for (i = 0; i < S.TileFacility.Length; i++)
		if (S.TileFacility[i] == Id)
			n++;
	return n;
}

static function int Building(XComGameState_LWStrategy S, int Id)
{
	local int i, n;

	for (i = 0; i < S.BaseJobs.Length; i++)
		if (S.BaseJobs[i].Kind == 1 && S.BaseJobs[i].Facility == Id)
			n++;
	return n;
}

static function int KindOf(int Id)
{
	switch (Id)
	{
	case 10: case 15: case 16: return ADJ_POWER;
	case 9: case 14: return ADJ_SATELLITES;
	case 7: case 23: case 17: return ADJ_SCIENCE;
	case 8: case 22: case 11: return ADJ_ENGINEERING;
	}
	return 0;
}

static function int AdjacencyOf(XComGameState_LWStrategy S, int X1, int Y1, int X2, int Y2)
{
	local int A, B;

	if (!IsValid(X1, Y1) || !IsValid(X2, Y2))
		return 0;
	A = FacilityAt(S, X1, Y1);
	B = FacilityAt(S, X2, Y2);
	if (A == 0 || B == 0 || KindOf(A) == 0 || KindOf(A) != KindOf(B))
		return 0;
	return KindOf(A);
}

/** Adjacent pairs of a kind (XGBase.GetAdjacencies: counted from the rows below the top, halved). */
static function int Adjacencies(XComGameState_LWStrategy S, int Which)
{
	local int X, Y, n;

	if (S.TileFacility.Length == 0)
		return 0;
	for (Y = 1; Y < H; Y++)
	{
		for (X = 0; X < W; X++)
		{
			n += int(AdjacencyOf(S, X - 1, Y, X, Y) == Which);
			n += int(AdjacencyOf(S, X + 1, Y, X, Y) == Which);
			n += int(AdjacencyOf(S, X, Y - 1, X, Y) == Which);
			n += int(AdjacencyOf(S, X, Y + 1, X, Y) == Which);
		}
	}
	return n / 2;
}

static function int PowerCapacity(XComGameState_LWStrategy S)
{
	local LWBaseRules.LWFacilityDef F;
	local int P;

	P = class'LWBaseRules'.default.BasePower[Clamp(class'LWStrategyRules'.static.Difficulty(), 0, class'LWBaseRules'.default.BasePower.Length - 1)];
	foreach class'LWBaseRules'.default.Facilities(F)
		if (F.Power > 0)
			P += F.Power * Count(S, F.Id);
	return P + Adjacencies(S, ADJ_POWER) * class'LWBaseRules'.default.PowerAdjacencyBonus;
}

static function int PowerUsed(XComGameState_LWStrategy S)
{
	local LWBaseRules.LWFacilityDef F;
	local int P, i;

	foreach class'LWBaseRules'.default.Facilities(F)
		if (F.Power < 0)
			P -= F.Power * Count(S, F.Id);
	for (i = 0; i < S.BaseJobs.Length; i++)
		if (S.BaseJobs[i].Kind == 1 && class'LWBaseRules'.static.FacilityFor(S.BaseJobs[i].Facility, F) && F.Power < 0)
			P -= F.Power;
	return P;
}

/** Satellites the uplinks can hold (XGHeadQuarters.GetSatelliteLimit). */
static function int SatelliteLimit(XComGameState_LWStrategy S)
{
	return Count(S, 9) * class'LWBaseRules'.default.UplinkCapacity + Count(S, 14) * class'LWBaseRules'.default.NexusCapacity
		+ Adjacencies(S, ADJ_SATELLITES) * class'LWBaseRules'.default.UplinkAdjacencyBonus;
}

static function int SatellitesUp(XComGameState_LWStrategy S)
{
	local int i, n;

	for (i = 0; i < S.Countries.Length; i++)
		if (S.Countries[i].bSatellite && !S.Countries[i].bLeft)
			n++;
	return n;
}

/** The month's upkeep: the facilities, the Skyranger and the interceptors (XGHeadQuarters.GetMaintenanceTotal). */
static function int Upkeep(XComGameState_LWStrategy S)
{
	local LWBaseRules.LWFacilityDef F;
	local int U;

	foreach class'LWBaseRules'.default.Facilities(F)
		if (F.Upkeep > 0)
			U += F.Upkeep * Count(S, F.Id);
	return U + class'LWBaseRules'.default.SkyrangerUpkeep + class'LWHangar'.static.Upkeep();
}

/** The labs' share added to the scientists' research (XGFacility_Labs.UpdateLabBonus). */
static function float LabBonus(XComGameState_LWStrategy S)
{
	if (S.TileFacility.Length == 0)
		return 0;
	return class'LWResearchRules'.default.LabBonus * Count(S, 7) + class'LWBaseRules'.default.LabAdjacencyBonus * Adjacencies(S, ADJ_SCIENCE);
}

/** An item's cash cost after the workshops' cut (XGItemTree.ScaleCost). */
static function float WorkshopCashScale(XComGameState_LWStrategy S)
{
	local float n;

	if (S == none || S.TileFacility.Length == 0)
		return 1.0;
	n = Count(S, 8) + 0.5 * Adjacencies(S, ADJ_ENGINEERING);
	return 0.5 + 0.5 * (1.0 - FMin(99, class'LWGearRules'.default.WorkshopBonus * 2) / 100.0) ** n;
}

/** What the workshops give back of an item's alloys or elerium when it is built (CalcWorkshopRebate). */
static function int Rebate(XComGameState_LWStrategy S, int Cost)
{
	local float n;

	if (Cost <= 0 || S.TileFacility.Length == 0 || (Count(S, 8) == 0 && Adjacencies(S, ADJ_ENGINEERING) == 0))
		return 0;
	n = 2 * Count(S, 8) + Adjacencies(S, ADJ_ENGINEERING);
	return Cost - int(Cost * (0.5 + 0.5 * (1.0 - FMin(99, class'LWBaseRules'.default.WorkshopRebatePct * 2) / 100.0) ** (n / 2)));
}

static function int HighestRank()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;
	local int Best;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	foreach XComHQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Unit != none && Unit.IsSoldier())
			Best = Max(Best, Unit.GetRank());
	}
	return Best;
}

// --- Building ------------------------------------------------------------------------------

static function string FacilityName(int Id)
{
	local X2TechTemplate Template;

	Template = X2TechTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(class'LWBaseRules'.static.FacilityTemplateFor(Id)));
	return (Template != none && Template.DisplayName != "") ? Template.DisplayName : "facility" @ Id;
}

static function int DigCost(int Y)
{
	return int(class'LWBaseRules'.default.ExcavateCash * 2.0 ** (Y - 1));
}

/** Staff a facility needs (GetFacilityProjectCost: labs scientists, workshops and uplinks engineers; 0: none). */
static function int StaffNeeded(XComGameState_LWStrategy S, int Id)
{
	local int n;

	switch (Id)
	{
	case 7:
	case 8:
		n = Count(S, Id) + Building(S, Id);
		if (Id == 7)
			return n == 0 ? class'LWBaseRules'.default.LabMinimum : class'LWBaseRules'.default.LabMinimum - 1 + n * class'LWBaseRules'.default.LabMultiple;
		return n == 0 ? class'LWBaseRules'.default.WorkshopMinimum : class'LWBaseRules'.default.WorkshopMinimum - 1 + n * class'LWBaseRules'.default.WorkshopMultiple;
	case 9:
	case 14:
		n = (Count(S, 9) - 1 + Building(S, 9)) * class'LWBaseRules'.default.UplinkMultiple + (Count(S, 14) + Building(S, 14)) * class'LWBaseRules'.default.NexusMultiple;
		return n + (Id == 9 ? class'LWBaseRules'.default.UplinkMultiple : class'LWBaseRules'.default.NexusMultiple);
	}
	return 0;
}

/** May the facility be built at all now, wherever (CanFacilityBeBuilt and the staff, power and cost)? Why says what is missing. */
static function bool CanBuild(XComGameState_LWStrategy S, LWBaseRules.LWFacilityDef F, out string Why)
{
	local name Tech;
	local int Staff;

	Why = "";
	if (F.Cash < 0)
		Why = "not built";
	else if (!F.Multiple && Count(S, F.Id) + Building(S, F.Id) > 0)
		Why = "one only";
	else if (F.Id == 12 && HighestRank() < class'LWBaseRules'.default.OTSRank)
		Why = "a soldier of rank" @ class'LWBaseRules'.default.OTSRank;
	if (Why == "" && F.Tech != 0)
	{
		Tech = class'LWResearchRules'.static.TemplateForId(F.Tech);
		if (Tech == '' || !class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched(Tech))
			Why = "research";
	}
	if (Why != "")
		return false;
	Staff = StaffNeeded(S, F.Id);
	if (F.Id == 7 && S.Scientists < Staff)
		Why = Staff @ "scientists";
	else if ((F.Id == 8 || F.Id == 9 || F.Id == 14) && S.Engineers < Staff)
		Why = Staff @ "engineers";
	else if (F.Power < 0 && -F.Power > PowerCapacity(S) - PowerUsed(S))
		Why = -F.Power @ "power";
	else if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < F.Cash)
		Why = class'LWStrategyRules'.static.Money(F.Cash);
	else if (class'LWEngineering'.static.Held('AlienAlloy') < F.Alloys)
		Why = F.Alloys @ class'X2Item_LWArtifacts'.static.DisplayName('Alloys');
	else if (class'LWEngineering'.static.Held('EleriumDust') < F.Elerium)
		Why = F.Elerium @ class'X2Item_LWArtifacts'.static.DisplayName('Elerium');
	else if (F.Item != '' && class'LWEngineering'.static.Held(F.Item) < F.Items)
		Why = F.Items @ class'LWEngineering'.static.ItemName(F.Item);
	return Why == "";
}

/** Work on a tile: dig it (rock), a lift (the shaft) or the facility (beside it). Why says what stopped it. */
static function bool Work(int X, int Y, int Facility, out string Why)
{
	local XComGameState NewGameState;
	local XComGameState_LWStrategy S;
	local XComGameState_HeadquartersXCom XComHQ;
	local LWBaseRules.LWFacilityDef F;
	local XComGameState_LWStrategy.LWBaseJob Job;
	local int Type;

	S = class'XComGameState_LWStrategy'.static.Get();
	if (S == none || S.TileType.Length == 0 || !IsValid(X, Y))
	{
		Why = "No such tile.";
		return false;
	}
	if (JobAt(S, X, Y) >= 0)
	{
		Why = "Work is already under way there.";
		return false;
	}
	if (!Reachable(S, X, Y))
	{
		Why = HasAccess(S, X, Y) ? "The tiles between it and the shaft must be dug first." : "It needs an access lift above it, or in its row.";
		return false;
	}
	Type = S.TileType[TileIndex(X, Y)];
	Job.X = X;
	Job.Y = Y;
	if (Type == ROCK || Type == ROCK_STEAM)
	{
		if (class'UIUtilities_Strategy'.static.GetXComHQ().GetSupplies() < DigCost(Y))
		{
			Why = "Digging there costs" @ class'LWStrategyRules'.static.Money(DigCost(Y)) $ ".";
			return false;
		}
		Job.Kind = 0;
		Job.HoursLeft = class'LWBaseRules'.default.ExcavateDays * 24;
	}
	else if (Type == BUILT)
	{
		Why = "There is a facility there.";
		return false;
	}
	else
	{
		if (X == SHAFT)
			Facility = 6;
		else if (Facility == 6)
		{
			Why = "Access lifts go in the shaft.";
			return false;
		}
		if (!class'LWBaseRules'.static.FacilityFor(Facility, F))
		{
			Why = "Long War has no facility" @ Facility $ ".";
			return false;
		}
		if (Facility == 15 && Type != DUG_STEAM)
		{
			Why = "A thermo generator needs a steam vent.";
			return false;
		}
		if (!CanBuild(S, F, Why))
		{
			Why = FacilityName(Facility) $ ": needs" @ Why $ ".";
			return false;
		}
		Job.Kind = 1;
		Job.Facility = Facility;
		Job.HoursLeft = F.Days * 24;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Long War X2: work in the base");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', class'UIUtilities_Strategy'.static.GetXComHQ().ObjectID));
	if (Job.Kind == 0)
		XComHQ.AddResource(NewGameState, 'Supplies', -DigCost(Y));
	else
	{
		XComHQ.AddResource(NewGameState, 'Supplies', -F.Cash);
		class'LWEngineering'.static.Take(NewGameState, 'AlienAlloy', F.Alloys);
		class'LWEngineering'.static.Take(NewGameState, 'EleriumDust', F.Elerium);
		if (F.Item != '')
			class'LWEngineering'.static.Take(NewGameState, F.Item, F.Items);
	}
	S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', S.ObjectID));
	S.BaseJobs.AddItem(Job);
	S.Note((Job.Kind == 0 ? "Digging began" : FacilityName(Facility) @ "begun") @ "at" @ TileName(X, Y) $ ", done in" @ (Job.HoursLeft / 24) @ "days.");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Why = "";
	return true;
}

static function string TileName(int X, int Y)
{
	return "row" @ (Y + 1) $ ", column" @ (X + 1);
}

/** An hour of the base's work (XComGameState_LWStrategy.Tick). */
static function Tick(XComGameState_LWStrategy S)
{
	local int i, k;

	for (i = S.BaseJobs.Length - 1; i >= 0; i--)
	{
		S.BaseJobs[i].HoursLeft--;
		if (S.BaseJobs[i].HoursLeft > 0)
			continue;
		k = TileIndex(S.BaseJobs[i].X, S.BaseJobs[i].Y);
		if (S.BaseJobs[i].Kind == 0)
		{
			S.TileType[k] = S.TileType[k] == ROCK_STEAM ? DUG_STEAM : DUG;
			S.Note("Digging done at" @ TileName(S.BaseJobs[i].X, S.BaseJobs[i].Y) $ (S.TileType[k] == DUG_STEAM ? ": a steam vent." : "."));
		}
		else
		{
			SetFacility(S, S.BaseJobs[i].Facility, S.BaseJobs[i].X, S.BaseJobs[i].Y);
			S.Note(FacilityName(S.BaseJobs[i].Facility) @ "built.");
		}
		S.BaseJobs.Remove(i, 1);
		S.bStop = true;
	}
}

/** A tile as the base screen and the control port show it. */
static function string TileText(XComGameState_LWStrategy S, int X, int Y)
{
	local int Job;
	local string Text;

	Job = JobAt(S, X, Y);
	if (Job >= 0)
		return (S.BaseJobs[Job].Kind == 0 ? "DIGGING" : Caps(FacilityName(S.BaseJobs[Job].Facility))) @ (S.BaseJobs[Job].HoursLeft + 23) / 24 $ "d";
	switch (S.TileType[TileIndex(X, Y)])
	{
	case BUILT:
		Text = S.TileFacility[TileIndex(X, Y)] != 0 ? FacilityName(S.TileFacility[TileIndex(X, Y)]) : "(room)";
		break;
	case ROCK: Text = "rock"; break;
	case ROCK_STEAM: Text = "rock, steam"; break;
	case DUG_STEAM: Text = "STEAM VENT"; break;
	default: Text = X == SHAFT ? "shaft" : "empty";
	}
	if (S.TileType[TileIndex(X, Y)] != BUILT && !Reachable(S, X, Y))
		Text $= " (no access)";
	return Text;
}

/** The base's numbers, a line. */
static function string Summary(XComGameState_LWStrategy S)
{
	return "Power" @ PowerUsed(S) $ "/" $ PowerCapacity(S) $ "   Satellites" @ SatellitesUp(S) $ "/" $ SatelliteLimit(S)
		$ "   Labs +" $ int(LabBonus(S) * 100) $ "%   Workshops -" $ int((1.0 - WorkshopCashScale(S)) * 100) $ "% cash   Upkeep" @ class'LWStrategyRules'.static.Money(Upkeep(S)) $ "/month";
}

/** For the control port's auto play: one step towards another uplink, if none is under way: the uplink on
 * empty ground, else rock dug, else a lift further down. What was begun in What. */
static function bool GrowForUplink(out string What)
{
	local XComGameState_LWStrategy S;
	local int X, Y, i, Type;

	S = class'XComGameState_LWStrategy'.static.Get();
	for (i = 0; i < S.BaseJobs.Length; i++)
		if (S.BaseJobs[i].Kind == 0 || S.BaseJobs[i].Facility == 9 || S.BaseJobs[i].Facility == 6)
			return false;
	for (i = 0; i < 3; i++)
	{
		for (Y = 0; Y < H; Y++)
		{
			for (X = 0; X < W; X++)
			{
				if (JobAt(S, X, Y) >= 0 || !Reachable(S, X, Y))
					continue;
				Type = S.TileType[TileIndex(X, Y)];
				if ((i == 0 && X != SHAFT && (Type == OPEN || Type == DUG))
					|| (i == 1 && (Type == ROCK || Type == ROCK_STEAM))
					|| (i == 2 && X == SHAFT && Type != BUILT))
				{
					if (!Work(X, Y, 9, What))
						return false;
					What = (i == 0 ? "an uplink" : (i == 1 ? "digging" : "a lift")) @ "at" @ TileName(X, Y);
					return true;
				}
			}
		}
	}
	return false;
}
