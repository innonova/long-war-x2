// Long War 1.0's air war: an interceptor against a UFO, by the rules of its
// XGInterceptionEngagement and UIInterceptionEngagement, ported from the Long
// War Tech Tree's model of them (innonova/xcom-ew-lw-tree, src/model/airwar.ts,
// checked there against the script). The data is Long War's own
// (Config/XComLWAirWar.ini, scripts/airwar-config.mjs).
//
// A fight is rolled as Long War rolls it: every shot of the first 60 seconds,
// before anything is shown (RollShots). It is then played back (PlayBack):
// shots in time order, a hit landing 0.3 s after its shot, Aim turning the next
// two missed shots of the jet's own weapon into hits, Dodge cancelling the next
// two hits on the jet, Boost keeping up with the UFO for longer, until a ship
// is down or the UFO outruns the jet.
class LWAirWar extends Object config(LWAirWar);

struct LWWeaponDef
{
	var int Id;
	var string Name;
	var float FiringTime;
	var int Damage;
	var int DamagePerCategory;
	var int Ap;
	var int ToHit;
	var int ToHitPerCategory;
};

struct LWShipDef
{
	var int Id;
	var string Name;
	var string Size;
	var float BattleSpeed;
	var int Hp;
	var int HpPerCategory;
	var int Armor;
	var int Ap;
	var array<int> Weapons;
	/** A downed UFO breaks up with chance overkill / DestroyDivisor % (0: never). */
	var int DestroyDivisor;
	var bool AlwaysCrash;
};

/** A UFO re-armed, or rebuilt, once the aliens are past a category. */
struct LWUfoChange
{
	var int Ship;
	var int AboveCategory;
	var array<int> Weapons;
	var string Size;
	var bool HasStats;
	var float BattleSpeed;
	var int Hp;
	var int HpPerCategory;
	var int Armor;
	var int Ap;
};

/** What a Foundry project done changes (features/lw-hangar.md): a weapon's or a craft's stat raised; a weapon remade; a second weapon. */
struct LWFoundryMod
{
	var int Foundry;
	var int Weapon;
	var int Ship;
	var int ToHit;
	var int BattleSpeed;
	var int Hp;
	var int Ap;
};

struct LWFoundryWeapon
{
	var int Foundry;
	var int Weapon;
	var float FiringTime;
	var int Damage;
	var int Ap;
	var int ToHit;
};

struct LWFoundrySecond
{
	var int Foundry;
	var int Ship;
	var int Weapon;
};

var config array<LWWeaponDef> Weapons;
var config array<LWShipDef> Ships;
var config array<LWUfoChange> UfoChanges;
var config array<LWFoundryMod> FoundryMods;
var config array<LWFoundryWeapon> FoundryWeapons;
var config array<LWFoundrySecond> FoundrySecond;

struct LWWeapon
{
	var int Id;
	var string Name;
	var float FiringTime;
	var int Damage;
	var int Ap;
	var int ToHit;
};

struct LWShip
{
	var int Type;
	var string Name;
	var string Size;
	var float BattleSpeed;
	var int MaxHp;
	var int Hp;
	var int Armor;
	var int Ap;
	var array<LWWeapon> Weapons;
	/** The jet's confirmed kills: +3 aim each (at most 30) and +1 % damage each. */
	var int Kills;
	var int DestroyDivisor;
	var bool AlwaysCrash;
};

struct LWShot
{
	var float Time;
	/** 0: the UFO, 1: the jet. */
	var int Source;
	/** Which of the source's weapons: the jet's second weapon does half. */
	var int Slot;
	var bool Hit;
	var bool Crit;
	var int Damage;
	var int ToHit;
};

enum ELWEvent
{
	eLWEvent_Shot,
	eLWEvent_Hit,
	eLWEvent_Dodged,
	eLWEvent_Aim,
	eLWEvent_Dodge,
	eLWEvent_Boost,
	eLWEvent_Abort,
	eLWEvent_End,
};

struct LWEvent
{
	var float Time;
	var ELWEvent Kind;
	/** For shots and hits: who fired (0 the UFO, 1 the jet), and the weapon. */
	var int Source;
	var int Slot;
	var int Damage;
	var bool Crit;
	/** A shot Aim turned into a hit. */
	var bool Aimed;
	/** For hits: the target's HP after. */
	var int Hp;
};

enum ELWOutcome
{
	eLWOutcome_Crashed,
	eLWOutcome_Destroyed,
	eLWOutcome_Escaped,
	eLWOutcome_Disengaged,
};

struct LWResult
{
	var ELWOutcome Outcome;
	var bool CraftLost;
	var int UfoHp;
	var int CraftHp;
	var float Time;
	var array<LWEvent> Events;
};

/** When the player used each consumable or broke off, in seconds; -1: not used (NoActions). */
struct LWActions
{
	var float Aim;
	var float Dodge;
	var float Boost;
	var float Abort;
};

/** Stances, as Long War's launch screen sets them: 0 defensive, 1 balanced, 2 aggressive. */
static function int StanceAim(int Stance)
{
	return Stance == 0 ? -15 : (Stance == 2 ? 15 : 0);
}

static function string StanceName(int Stance)
{
	return Stance == 0 ? "Defensive" : (Stance == 2 ? "Aggressive" : "Balanced");
}

/** CanUseConsumable: no Aim when defensive, no Dodge when aggressive. 0 Aim, 1 Dodge, 2 Boost. */
static function bool ConsumableAllowed(int Kind, int Stance)
{
	if (Kind == 0)
		return Stance != 0;
	if (Kind == 1)
		return Stance != 2;
	return true;
}

/** Nothing used yet. */
static function LWActions NoActions()
{
	local LWActions A;

	A.Aim = -1;
	A.Dodge = -1;
	A.Boost = -1;
	A.Abort = -1;
	return A;
}

// --- Ships and weapons, as the aliens' progress makes them ----------------------

static function bool WeaponDef(int Id, out LWWeaponDef Def)
{
	local int i;

	for (i = 0; i < default.Weapons.Length; i++)
	{
		if (default.Weapons[i].Id == Id)
		{
			Def = default.Weapons[i];
			return true;
		}
	}
	return false;
}

static function bool ShipDef(int Id, out LWShipDef Def)
{
	local int i;

	for (i = 0; i < default.Ships.Length; i++)
	{
		if (default.Ships[i].Id == Id)
		{
			Def = default.Ships[i];
			return true;
		}
	}
	return false;
}

static function LWWeapon WeaponFor(int Id, int Category)
{
	local LWWeaponDef Def;
	local LWWeapon W;
	local LWFoundryWeapon FW;
	local LWFoundryMod M;

	if (!WeaponDef(Id, Def))
		return W;
	W.Id = Id;
	W.Name = Def.Name;
	W.FiringTime = Def.FiringTime;
	W.Damage = Def.Damage + Def.DamagePerCategory * Category;
	W.Ap = Def.Ap;
	W.ToHit = Def.ToHit + Def.ToHitPerCategory * Category;
	// The Foundry's projects done in the campaign (none in the demo).
	foreach default.FoundryWeapons(FW)
		if (FW.Weapon == Id && FoundryDone(FW.Foundry))
		{
			W.FiringTime = FW.FiringTime;
			W.Damage = FW.Damage;
			W.Ap = FW.Ap;
			W.ToHit = FW.ToHit;
		}
	foreach default.FoundryMods(M)
		if (M.Weapon == Id && FoundryDone(M.Foundry))
			W.ToHit += M.ToHit;
	return W;
}

/** Has the campaign's Foundry done the project? */
static function bool FoundryDone(int Foundry)
{
	local XComGameState_LWStrategy S;

	S = class'XComGameState_LWStrategy'.static.Get();
	return S != none && S.FoundryDone.Find(Foundry) != INDEX_NONE;
}

static function LWShip ShipFrom(LWShipDef Def, array<int> WeaponIds, int Category)
{
	local LWShip S;
	local int i;

	S.Type = Def.Id;
	S.Name = Def.Name;
	S.Size = Def.Size;
	S.BattleSpeed = Def.BattleSpeed;
	S.MaxHp = Def.Hp + Def.HpPerCategory * Category;
	S.Hp = S.MaxHp;
	S.Armor = Def.Armor;
	S.Ap = Def.Ap;
	S.DestroyDivisor = Def.DestroyDivisor;
	S.AlwaysCrash = Def.AlwaysCrash;
	for (i = 0; i < WeaponIds.Length; i++)
		if (WeaponIds[i] > 0)
			S.Weapons.AddItem(WeaponFor(WeaponIds[i], Category));
	return S;
}

/** An interceptor (1) or Firestorm (3) carrying one weapon. */
static function LWShip Craft(int Type, int WeaponId, int Category)
{
	local LWShipDef Def;
	local array<int> WeaponIds;
	local LWFoundryMod M;
	local LWFoundrySecond Second;

	ShipDef(Type, Def);
	WeaponIds.AddItem(WeaponId);
	// The Foundry's projects done: speed, HP, penetration; a second weapon (Wingtip Sparrowhawks).
	foreach default.FoundryMods(M)
		if (M.Ship == Type && FoundryDone(M.Foundry))
		{
			Def.BattleSpeed += M.BattleSpeed;
			Def.Hp += M.Hp;
			Def.Ap += M.Ap;
		}
	foreach default.FoundrySecond(Second)
		if (Second.Ship == Type && FoundryDone(Second.Foundry) && WeaponId != Second.Weapon)
			WeaponIds.AddItem(Second.Weapon);
	return ShipFrom(Def, WeaponIds, Category);
}

/** A UFO as the aliens' progress makes it: grown per category, re-armed or rebuilt past some. */
static function LWShip Ufo(int Type, int Category)
{
	local LWShipDef Def;
	local array<int> WeaponIds;
	local int i;
	local LWUfoChange C;

	ShipDef(Type, Def);
	WeaponIds = Def.Weapons;
	for (i = 0; i < default.UfoChanges.Length; i++)
	{
		C = default.UfoChanges[i];
		if (C.Ship != Type || Category <= C.AboveCategory)
			continue;
		if (C.Weapons.Length > 0)
			WeaponIds = C.Weapons;
		if (C.Size != "")
			Def.Size = C.Size;
		if (C.HasStats)
		{
			Def.BattleSpeed = C.BattleSpeed;
			Def.Hp = C.Hp;
			Def.HpPerCategory = C.HpPerCategory;
			Def.Armor = C.Armor;
			Def.Ap = C.Ap;
		}
	}
	return ShipFrom(Def, WeaponIds, Category);
}

/** The UFO types, in Long War's order (Scout 4 … Overseer 14). */
static function array<int> UfoTypes()
{
	local array<int> Types;
	local int i;

	for (i = 0; i < default.Ships.Length; i++)
		if (default.Ships[i].Id >= 4)
			Types.AddItem(default.Ships[i].Id);
	return Types;
}

// --- The fight --------------------------------------------------------------------

/** Chance to hit before the roll, as UpdateWeapons computes it (5–95). */
static function int ToHitFor(LWShip Craft, int Source, int Stance, LWWeapon W)
{
	local int Kills;

	Kills = Source == 1 ? Clamp(3 * Craft.Kills, 0, 30) : 0;
	return Clamp(W.ToHit + Kills + StanceAim(Stance), 5, 95);
}

/** GetDamageMitigation: 5 % per point of armor beyond the attacker's penetration, 0–95 %. */
static function float Mitigation(LWWeapon W, LWShip Attacker, LWShip Target)
{
	return FClamp(0.05 * (Target.Armor - (W.Ap + Attacker.Ap)), 0.0, 0.95);
}

/** The critical chance before the roll: (penetration − armor) / 2, 5–25. */
static function int CritFor(LWWeapon W, LWShip Attacker, LWShip Target)
{
	return Clamp((W.Ap + Attacker.Ap - Target.Armor) / 2, 5, 25);
}

/** GetCombat: every shot of the first 60 seconds, rolled. */
static function array<LWShot> RollShots(LWShip TheUfo, LWShip TheCraft, int Stance, bool Analysis)
{
	local array<LWShot> Shots;
	local array<float> Cd0, Cd1;
	local float Start, T, Next, Dist0, Dist1;
	local int k;

	// Every XCOM weapon reaches 100 and every UFO weapon 101; the fight opens at
	// the longest range and closes at 5 a second, each ship stopping at its own
	// shortest range (GetPosition). Each ship fires once all its weapons reach.
	Start = TheUfo.Weapons.Length > 0 ? 101.0 : 100.0;
	Dist0 = Start;
	Dist1 = Start;
	for (k = 0; k < TheUfo.Weapons.Length; k++)
		Cd0.AddItem(Rand(20) / 10.0);
	for (k = 0; k < TheCraft.Weapons.Length; k++)
		Cd1.AddItem(Rand(20) / 10.0);
	T = 0;
	while (T < 60)
	{
		Next = 9999;
		if (TheUfo.Weapons.Length > 0 && Dist0 <= 101.0)
			for (k = 0; k < Cd0.Length; k++)
				Next = FMin(Next, Cd0[k]);
		if (TheCraft.Weapons.Length > 0 && Dist1 <= 100.0)
			for (k = 0; k < Cd1.Length; k++)
				Next = FMin(Next, Cd1[k]);
		T += Next;
		Dist0 = FMax(101.0, Start + T * -5.0);
		Dist1 = FMax(100.0, Start + T * -5.0);
		for (k = 0; k < Cd0.Length; k++)
			if (Cd0[k] > 0)
				Cd0[k] = FMax(0, Cd0[k] - Next);
		for (k = 0; k < Cd1.Length; k++)
			if (Cd1[k] > 0)
				Cd1[k] = FMax(0, Cd1[k] - Next);
		if (Dist0 <= 101.0)
			Fire(Shots, Cd0, TheUfo, TheCraft, TheCraft, 0, Stance, Analysis, T);
		if (Dist1 <= 100.0)
			Fire(Shots, Cd1, TheCraft, TheUfo, TheCraft, 1, Stance, Analysis, T);
	}
	return Shots;
}

static function Fire(out array<LWShot> Shots, out array<float> Cd, LWShip Me, LWShip Them, LWShip TheCraft, int Source, int Stance, bool Analysis, float T)
{
	local int k, Damage;
	local LWWeapon W;
	local LWShot S;

	for (k = 0; k < Me.Weapons.Length; k++)
	{
		if (Cd[k] > 0)
			continue;
		W = Me.Weapons[k];
		Cd[k] += W.FiringTime;
		S.Time = T;
		S.Source = Source;
		S.Slot = k;
		S.ToHit = ToHitFor(TheCraft, Source, Stance, W);
		Damage = W.Damage == 0 ? 0 : int(W.Damage * (1.0 - Mitigation(W, Me, Them)));
		S.Crit = Rand(100) <= CritFor(W, Me, Them);
		if (S.Crit)
			Damage *= 2;
		Damage += Rand(Damage / 2);
		if (Source == 1)
		{
			if (Analysis)
				Damage = int(Damage * 1.1);
			Damage = int(Damage * (1.0 + TheCraft.Kills / 100.0));
			if (k != 0)
				Damage /= 2;
		}
		S.Hit = Rand(100) <= S.ToHit;
		// A miss keeps its damage only for the jet's own weapon, which Aim can turn into a hit.
		if (!S.Hit && (Source == 0 || k != 0))
			Damage = 0;
		S.Damage = Damage;
		Shots.AddItem(S);
	}
}

/** GetTimeUntilOutrun: seconds the jet keeps up; each Boost adds half its battle speed. */
static function float EscapeTime(LWShip TheUfo, LWShip TheCraft, int Boosts)
{
	local float Speed;

	Speed = TheCraft.BattleSpeed + int(TheCraft.BattleSpeed * 0.5) * Boosts;
	return TheUfo.BattleSpeed > 0 ? 30.0 * (Speed / TheUfo.BattleSpeed) : 9999.0;
}

/**
 * The playback: shots in time order, skipped once either ship is down; a hit
 * lands 0.3 s after its shot; Aim, Dodge, Boost and breaking off when the
 * player used them. A downed UFO breaks up rather than crashes with chance
 * overkill / k % (UpdateEngagementResult).
 */
static function LWResult PlayBack(LWShip TheUfo, LWShip TheCraft, int Stance, array<LWShot> Shots, LWActions Act)
{
	local LWResult R;
	local LWEvent E;
	local int HpUfo, HpCraft, AimLeft, DodgeLeft, Boosts, si, ui, Kind, Target, i, j;
	local float End, Now, TShot, THit, TUse, Swap;
	local bool Aborted, Hit, Aimed;
	local array<float> HitTime;
	local array<int> HitTarget, HitDamage, HitShot;
	local array<float> UseTime;
	local array<int> UseKind;

	HpUfo = TheUfo.Hp;
	HpCraft = TheCraft.Hp;
	si = 0;
	ui = 0;
	Aborted = false;
	End = EscapeTime(TheUfo, TheCraft, 0);
	// The player's actions in time order: 0 Aim, 1 Dodge, 2 Boost, 3 break off.
	if (Act.Aim >= 0) { UseTime.AddItem(Act.Aim); UseKind.AddItem(0); }
	if (Act.Dodge >= 0) { UseTime.AddItem(Act.Dodge); UseKind.AddItem(1); }
	if (Act.Boost >= 0) { UseTime.AddItem(Act.Boost); UseKind.AddItem(2); }
	if (Act.Abort >= 0) { UseTime.AddItem(Act.Abort); UseKind.AddItem(3); }
	for (i = 1; i < UseTime.Length; i++)
	{
		for (j = i; j > 0 && UseTime[j - 1] > UseTime[j]; j--)
		{
			Swap = UseTime[j]; UseTime[j] = UseTime[j - 1]; UseTime[j - 1] = Swap;
			Kind = UseKind[j]; UseKind[j] = UseKind[j - 1]; UseKind[j - 1] = Kind;
		}
	}

	while (true)
	{
		TShot = si < Shots.Length ? Shots[si].Time : 1000000.0;
		THit = HitTime.Length > 0 ? HitTime[0] : 1000000.0;
		TUse = ui < UseTime.Length ? UseTime[ui] : 1000000.0;
		Now = FMin(TShot, FMin(THit, TUse));
		if (Now > End || Now >= 1000000.0)
			return Finish(R, End, Aborted ? eLWOutcome_Disengaged : eLWOutcome_Escaped, HpUfo, HpCraft);
		if (TUse == Now)
		{
			Kind = UseKind[ui++];
			E.Time = Now;
			E.Aimed = false;
			if (Kind == 3)
			{
				Aborted = true;
				// The break-off completes once what is in flight has landed.
				End = FMin(End, Now + 0.3);
				E.Kind = eLWEvent_Abort;
			}
			else if (ConsumableAllowed(Kind, Stance))
			{
				if (Kind == 0) { AimLeft += 2; E.Kind = eLWEvent_Aim; }
				if (Kind == 1) { DodgeLeft += 2; E.Kind = eLWEvent_Dodge; }
				if (Kind == 2)
				{
					Boosts++;
					End = FMax(End, EscapeTime(TheUfo, TheCraft, Boosts));
					E.Kind = eLWEvent_Boost;
				}
			}
			else
				continue;
			R.Events.AddItem(E);
			continue;
		}
		if (TShot == Now)
		{
			i = si++;
			if (HpUfo <= 0 || HpCraft <= 0)
				continue;
			if (Aborted && Shots[i].Source == 1)
				continue;
			Hit = Shots[i].Hit;
			Aimed = false;
			if (AimLeft > 0 && Shots[i].Source == 1 && Shots[i].Damage > 0 && !Hit)
			{
				AimLeft--;
				Hit = true;
				Aimed = true;
			}
			E.Time = Now;
			E.Kind = eLWEvent_Shot;
			E.Source = Shots[i].Source;
			E.Slot = Shots[i].Slot;
			E.Damage = Hit ? Shots[i].Damage : 0;
			E.Crit = Shots[i].Crit;
			E.Aimed = Aimed;
			R.Events.AddItem(E);
			if (Hit)
			{
				HitTime.AddItem(Now + 0.3);
				HitTarget.AddItem(Shots[i].Source == 0 ? 1 : 0);
				HitDamage.AddItem(Shots[i].Damage);
				HitShot.AddItem(i);
			}
			continue;
		}
		// A hit lands.
		Target = HitTarget[0];
		i = HitShot[0];
		E.Time = Now;
		E.Source = Shots[i].Source;
		E.Slot = Shots[i].Slot;
		E.Damage = HitDamage[0];
		E.Crit = Shots[i].Crit;
		E.Aimed = false;
		HitTime.Remove(0, 1);
		HitTarget.Remove(0, 1);
		HitDamage.Remove(0, 1);
		HitShot.Remove(0, 1);
		if (Target == 1 && DodgeLeft > 0)
		{
			DodgeLeft--;
			E.Kind = eLWEvent_Dodged;
			E.Hp = HpCraft;
			R.Events.AddItem(E);
			continue;
		}
		if (Target == 0)
			HpUfo -= E.Damage;
		else
			HpCraft -= E.Damage;
		E.Kind = eLWEvent_Hit;
		E.Hp = Target == 0 ? HpUfo : HpCraft;
		R.Events.AddItem(E);
		if (HpUfo <= 0)
		{
			// Overkill decides whether it crashes or breaks up.
			if (!TheUfo.AlwaysCrash && TheUfo.DestroyDivisor > 0 && Rand(100) < (-HpUfo) / TheUfo.DestroyDivisor)
				return Finish(R, Now, eLWOutcome_Destroyed, HpUfo, HpCraft);
			return Finish(R, Now, eLWOutcome_Crashed, HpUfo, HpCraft);
		}
		if (HpCraft <= 0)
			return Finish(R, Now, eLWOutcome_Escaped, HpUfo, HpCraft);
	}
}

static function LWResult Finish(LWResult R, float Time, ELWOutcome Outcome, int HpUfo, int HpCraft)
{
	local LWEvent E;

	E.Time = Time;
	E.Kind = eLWEvent_End;
	R.Events.AddItem(E);
	R.Outcome = Outcome;
	R.CraftLost = HpCraft <= 0;
	R.UfoHp = HpUfo;
	R.CraftHp = HpCraft;
	R.Time = Time;
	return R;
}

static function LWResult Fight(LWShip TheUfo, LWShip TheCraft, int Stance, LWActions Act)
{
	return PlayBack(TheUfo, TheCraft, Stance, RollShots(TheUfo, TheCraft, Stance, false), Act);
}

/** Many fights with no consumables: how often the UFO comes down, breaks up or gets away, and the jet is lost. */
static function Odds(LWShip TheUfo, LWShip TheCraft, int Stance, int Runs, out int Crashed, out int Destroyed, out int Escaped, out int Lost)
{
	local LWResult R;
	local int i;

	Crashed = 0;
	Destroyed = 0;
	Escaped = 0;
	Lost = 0;
	for (i = 0; i < Runs; i++)
	{
		R = Fight(TheUfo, TheCraft, Stance, NoActions());
		if (R.Outcome == eLWOutcome_Crashed)
			Crashed++;
		else if (R.Outcome == eLWOutcome_Destroyed)
			Destroyed++;
		else
			Escaped++;
		if (R.CraftLost)
			Lost++;
	}
}

static function string OutcomeText(LWResult R, LWShip TheUfo)
{
	switch (R.Outcome)
	{
		case eLWOutcome_Crashed: return "The" @ TheUfo.Name @ "is down: a crash site to recover.";
		case eLWOutcome_Destroyed: return "The" @ TheUfo.Name @ "broke up: nothing to recover.";
		case eLWOutcome_Disengaged: return "Broke off: the" @ TheUfo.Name @ "goes on its way.";
		default: return R.CraftLost ? "The jet is lost." : "The" @ TheUfo.Name @ "outran the jet.";
	}
}
