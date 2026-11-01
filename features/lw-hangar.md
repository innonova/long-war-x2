---
title: "Long War's hangar: interceptors by continent, repair, refits, orders"
status: review
priority: 2
dependsOn:
  - lw-geoscape
  - lw-base
---

## Purpose

The air war was fought by Long War's rules, but its jets lived nowhere:
- any jet met any UFO anywhere;
- damage was never repaired;
- none could be bought;
- the weapons engineering can build could not be fitted.

Long War's air war is about where the jets are and keeping them flying.
This brings its hangar.

## What the person should see

- A HANGAR button on the Geoscape, a screen listing each jet: its
  continent, weapon, HP, kills, and whether it is ready, repairing, on its
  way or being refitted.
  - SEND sends a jet to the continent chosen; REFIT fits the weapon
    chosen; ORDER buys an interceptor for the continent chosen.
- **An interception is offered** only when a ready jet is over the UFO's
  continent, and says how many are.
- **After a fight:**
  - a damaged jet is out for repair, its HP coming back hour by hour;
  - a destroyed one is gone.
- **Engineering builds** the interceptor weapons (Phoenix, Laser, Plasma,
  EMP, Fusion) and the Firestorm, which joins the hangar.

## Report (2026-11-01)

**The hangar is Long War's** (`LWHangar`, the jets in
`XComGameState_LWAirWar`, the screen `UILWHangar`, its numbers in
`XComLWBase.ini`). Long War's rules, read from `XGFacility_Hangar` and
`XGHeadQuarters`:
- **Which jets fight:** a jet meets only UFOs over its own continent,
  and only when ready.
- **Repair:**
  - a damaged jet is out for 600 h × the share of HP lost
    (`INTERCEPTOR_REPAIR_HOURS`);
  - two thirds of that once the Foundry's Advanced Repair is done;
  - its HP comes back a little each hour;
  - a destroyed jet is lost.
- **Orders:** an interceptor costs §200 and arrives in 72 hours; a
  continent has 6 bays, orders and jets on their way counted.
- **Transfers** take 36 hours.
- **A new weapon** takes 168 hours to fit (missiles 12); the old one goes
  back to the stores, except the Avalanche and Stingray missiles Long War
  never builds.
- **Engineering builds:**
  - the interceptor weapons, at Long War's costs;
  - the Firestorm, which also consumes 4 UFO power sources and 8 UFO
    navigation computers (`GetItemProjectCost`) and joins the hangar at
    home.
- **Upkeep:** each interceptor §40 and each Firestorm §50 a month, with
  the base's upkeep at the council report.

**The control port:**
- `hangar`;
- `order [continent] [n]`;
- `transfer <jet> <continent>`;
- `equip <jet> <weapon>`;
- `auto` keeps two interceptors at home.

**Checked in the game** (new campaigns, control port):
- an interceptor ordered for Europe arrived in 3 days;
- a jet sent to Asia arrived in 36 hours;
- a Phoenix Cannon was built and fitted (168 hours);
- a Scout over the United States was intercepted from North America
  ("2 jets ready"): Raven-1, down to 575 of 2500 HP, went for 462 hours
  of repair, and was 671 a day later;
- three months of `auto` fought eight interceptions.

**Found on the way:** in UnrealScript, `.Length` of a function's array
result reads 0 (`ReadyFor(i).Length`). It hid every interception until
the count went through a local. Recorded as learning #214; the earlier
`Kit().Length` oddity was the same.

### Decisions

- **The starting two interceptors are in North America**, the home
  continent. No other continent has jets until some are sent or ordered.
- **No continent needs a satellite to base jets on.** Long War only
  greys such a continent out in its list.
- **Callsigns** are "Raven-n" and "Firestorm-n": Long War's own are its
  words, still to wire.

### Left open

- **Interceptor consumables** (Long War's aim, dodge and boost modules)
  and the Foundry's air projects (Wingtip Sparrowhawks, Penetrator
  Weapons, Improved Avionics and the rest).
- **Long War's "Friendly Skies"** and UFO analyses that change the air
  war; the Firestorm's own refits.
- **Long War's fuel and refuelling:** jets here never run out on the way.

## Report (2026-11-01, the Foundry's air and salvage projects)

**What the Foundry's projects do to the air war**, from the Tree's air
war data (generated into `XComLWAirWar.ini`: `FoundryMods`,
`FoundryWeapons`, `FoundrySecond`), applied when a craft or weapon is
assembled:
- **Craft:**
  - Armored Fighters: +1000 HP for interceptors and Firestorms;
  - Elerium Afterburners: +5 battle speed;
  - Penetrator Weapons: +5 penetration;
  - Wingtip Sparrowhawks: a second weapon, Stingray missiles.
- **Weapons:**
  - Improved Avionics: +10 to hit for XCOM's weapons;
  - UFO Countermeasures: −15 to hit for the UFOs';
  - Phoenix Coilguns and Supercapacitors remake the Phoenix and Laser
    cannons.
- **A ready jet below its HP**, after Armored Fighters, goes in for
  repair to the new maximum.

**And the strategic ones**, from Long War's code:
- **Brought home:** Alien Metallurgy, Alien Nucleonics and Improved
  Salvage each add a fifth to the alloys, elerium and fragments from
  salvage and kill loot (`UnloadArtifacts`).
- **Stealth Satellites:** UFOs find a satellite at 30 % (50 % on a second
  pass) instead of 60 % (90 %) (`XGAlienObjective`).
- **Enhanced UFO Detection:** each ready interceptor on a continent
  doubles its 4 % chance of spotting a UFO there.
  - Detection now counts only ready interceptors, as Long War's
    `GetNumInterceptorsInRangeAndAvailable` does.
- **Advanced Repair:** two thirds of the repair time (already in the
  first report).

**Checked in the game:**
- with Armored Fighters and Wingtip Sparrowhawks marked done (the new
  test aid `foundry done <id>`), both jets went in for repair to 3500 HP;
- a Scout was fought with two weapons.
