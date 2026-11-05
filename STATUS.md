# Where the port stands, system by system

One row per system of Long War, kept by hand as work lands (last brought up
to date 2026-11-02). Each row points at the feature whose reports hold the
detail, the decisions and what was checked.

**Status** says how much of Long War's behaviour is in:
**done** (Long War's rules, numbers from stock Long War 1.0),
**most** (the core is in, named pieces missing), **part** (a start),
**stand-in** (XCOM 2's thing in its place), **none**.
**Looks** says what the player sees: **LW** (Long War's own look),
**X2** (XCOM 2's screens or art doing the job), **plain** (our own
buttons and text, no art).

## Strategy

| System | Status | Looks | What is in | What is missing | Feature |
|---|---|---|---|---|---|
| EW's own strategy screens | part | LW | research, the strategy HUD (resources, clock) and the Situation Room (countries, panic, funding, satellites, doom tracker, HQ, UFOs on EW's earth) | each screen wired to Long War's state; EW's pictures; the 3D globe and base | `lw-ew-screens` |
| The Geoscape: clock, month, decisions | most | plain | Long War's time, month and events on a screen of our own, over XCOM 2's Avenger | a globe; the squad's flight time; XCOM 2's resource bar still shows | `lw-geoscape` |
| Council, panic, funding | done | plain | countries, panic, leaving, the council report, funding | the monthly tallies (terrors thwarted …) in the report | `lw-geoscape` |
| Satellites | done | plain | launching, coverage, detection | | `lw-geoscape` |
| The aliens' plan | most | plain | resources, research, the monthly plan, UFOs, abductions, terror targets | scout hunts after scouting; UFOs seen as they cross watched countries | `lw-geoscape` |
| The air war | most | plain | jets per continent, interception, damage, repair, refits, orders, transfers | consumables, Friendly Skies, fuel, the Firestorm's refits | `lw-hangar` |
| The base | most | plain | the grid, digging, facilities, power, upkeep, steam | facilities' effects (containment, Hyperwave, Gollop chamber); removing a facility | `lw-base` |
| Research | most | X2 + plain | Long War's techs, costs, times, prerequisites, credits; labs and their adjacency (`lw-base`) | XCOM 2's research room still shows its own staff | `lw-research` |
| Engineering | most | plain | building items and armour at Long War's costs and requirements; workshops' discount and rebate (`lw-base`) | | `lw-gear`, `lw-research` |
| Foundry | part | plain | projects run; done: the air and salvage projects, pistols, Improved Medikit, Ammo Conservation, Tactical Rigging, Alien Grenades, S.C.O.P.E. (the laser sight's half; the targeting module is not an item yet) | SHIV and MEC projects, Improved Arc Thrower, Shaped Armor, Elerium fuel, the Alien Grenades perk | `lw-research` |
| Loot | most | plain | kill loot, corpses, fragments, captives (arc thrower), salvage, the first mission's, meld canisters at EW's places | the grey market; explosions destroying loot | `lw-loot` |
| Psi Labs | most | plain | training at Long War's hours and chance (0.45) | psi ranks and XP; fatigue | `lw-psi` |
| Genetics Lab | most | plain | the ten mods, slots, cost and time | the mods' fatigue | `lw-genemods` |
| Officer Training School | part | plain | squad size I and II (7, 8) | the officers and their abilities | `lw-officers` (planned) |
| Start and country bonuses | none | | (rules read from Long War's code) | all of it | `lw-startbonus` (planned) |
| The story | most | plain | alien bases, Overseers, the Temple Ship | the HQ assault from month 4; Act 3; EXALT | `lw-story` |
| EXALT | none | | | all of it | |
| MECs, SHIVs, cybernetics | none | | | all of it | |
| Fatigue | most | X2 | Long War's hours, all in, shown as War of the Chosen's Tired | officers' hours, the country bonuses' | `lw-fatigue` |
| Soldiers: recruits, ranks | most | X2 | Long War's eight classes, ranks, stat gains and experience in XCOM 2's barracks | Wet Work, medals' experience | `lw-classes` |

## Tactical

| System | Status | Looks | What is in | What is missing | Feature |
|---|---|---|---|---|---|
| Classes and perk trees | done | X2 | the eight subclasses, their trees and stat gains | | `lw-classes` |
| Perks | most | X2 | most of the 78 Long War perks act; approximations marked in Decisions | Lock N' Load, Concealment, Extra Conditioning, Javelin, Neural Feedback, Pyrokinesis; Bioelectric Skin's reveal; Muscle Fiber Density as a passive jump (a grapple for now) | `lw-classes`, `lw-psi`, `lw-genemods` |
| Psi powers in missions | most | X2 | ten of twelve | Neural Feedback, Pyrokinesis | `lw-psi` |
| Weapons and armour | done | X2 | Long War's stats, slots, ammo, who may carry what | Long War's weapon perks while carried | `lw-gear` |
| Small items | most | X2 | grenades, medikits, rockets (with scatter), the arc thrower, scanners, beacons | the Shadow Device, the Battle Computer | `lw-gear` |
| Aliens | part | LW + X2 | Long War's squads (which aliens, how many) as XCOM 2's nearest aliens, drawn as Enemy Within's (15 species' bodies, animations and weapons converted by the setup), with Long War's stats: base, difficulty and the research upgrades (HP, aim, defense, mobility, will, crit, shields, damage reduction, damage, each species' weapon damage); pod leaders and navigators with their stats, scale and perks (as the soldiers' perks work) ; the Sectoid's psionics (Mind Merge, Psi Panic, Mindfray), the Commander's Mind Control, the Muton's Blood Call, the Drone's repair, the Cyberdisc's Death Blossom, the Floater's Launch, the Seeker's Strangle and cloak and the Muton's Intimidate, used by their XCOM 2 AI; EW's animations playing on their bodies | the other species' own abilities (the Drone's Overload, the Berserker's charge …) Sectopod, Ethereal | `lw-aliens`, `lw-ew-units`, `lw-missions` |
| Missions | most | X2 | each kind as an XCOM 2 mission type; won when every alien is dead or taken; no turn limit, sitreps, Chosen, concealment or reinforcements; Long War's squad size; terror civilians counted | Long War's objectives per kind | `lw-missions` |
| Maps | most | LW | Enemy Within's maps as real XCOM 2 plots written by the setup (geometry, walls, walls that break, doors that open, roofs cut away by XCOM 2's building visibility, materials incl. glass, cut-outs (tree cards, fences, decals) and road paint, lights, what can be stood on, not cars or sandbags); Long War's squad at EW's pods (terror pods too), 18 terror civilians by EW's rules; the campaign's first mission on an EW plot; every map of 83 loads (the two crashes found) | night maps dark-blue | `lw-missions`, `hard-parts` |
| Wounds | most | X2 | Long War's recovery times on XCOM 2's healing; Field Surgeon | MEC and SHIV repairs | `lw-classes` |

## The build and the tools

| System | Status | What is in | What is missing | Feature |
|---|---|---|---|---|
| The player's build | done | the mod, its config and a setup program that writes Long War's words and converts EW's screens, earth and (when asked) maps from the player's own install (v0.1.0-preview.1) | | `playable-build` |
| Config from stock Long War | done | `scripts/config-all.sh` | | `lw-psi` (the answer) |
| XCOM 2 test harness | done | control port, scripts, test aids (`tools/test`): state and wait/go on it, units and move, enemies (fog, viewers, bodies), doors, bodies | | |
| Crash at mission load | done | a Wwise callback during `LoadMap` after launching with the Avenger's cinematics running: voices and cinematics stopped, the map loaded 1.5 s later (0 in 20 under provoked conditions) | more play to confirm | `lw-missions` |
| EW Long War test harness | part | EW (stock Long War 1.0) started through Steam and its launcher, windowed; mouse input, screenshots, saves read | the keyboard; a campaign by clicks; the measurements | `ew-harness` |
