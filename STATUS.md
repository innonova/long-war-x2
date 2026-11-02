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
| Foundry | part | plain | projects run; done: the air and salvage projects, pistols, Improved Medikit, Ammo Conservation, Tactical Rigging, Alien Grenades | SHIV and MEC projects, SCOPE, Improved Arc Thrower, Shaped Armor, Elerium fuel, the Alien Grenades perk | `lw-research` |
| Loot | most | plain | kill loot, corpses, fragments, captives (arc thrower), salvage, the first mission's | the grey market; explosions destroying loot | `lw-loot` |
| Psi Labs | most | plain | training at Long War's hours and chance (0.45) | psi ranks and XP; fatigue | `lw-psi` |
| Genetics Lab | most | plain | the ten mods, slots, cost and time | the mods' fatigue | `lw-genemods` |
| Officer Training School | part | plain | squad size I and II (7, 8) | the officers and their abilities | `lw-officers` (planned) |
| Start and country bonuses | none | | (rules read from Long War's code) | all of it | `lw-startbonus` (planned) |
| The story | most | plain | alien bases, Overseers, the Temple Ship | the HQ assault from month 4; Act 3; EXALT | `lw-story` |
| EXALT | none | | | all of it | |
| MECs, SHIVs, cybernetics | none | | | all of it | |
| Fatigue | none | | | all of it | |
| Soldiers: recruits, ranks | most | X2 | Long War's eight classes, ranks and stat gains in XCOM 2's barracks | Long War's XP rules; the starting soldiers' number | `lw-classes` |

## Tactical

| System | Status | Looks | What is in | What is missing | Feature |
|---|---|---|---|---|---|
| Classes and perk trees | done | X2 | the eight subclasses, their trees and stat gains | | `lw-classes` |
| Perks | most | X2 | most of the 78 Long War perks act; approximations marked in Decisions | Lock N' Load, Concealment, Extra Conditioning, Javelin, Neural Feedback, Pyrokinesis; Bioelectric Skin's reveal; Muscle Fiber Density as a passive jump (a grapple for now) | `lw-classes`, `lw-psi`, `lw-genemods` |
| Psi powers in missions | most | X2 | ten of twelve | Neural Feedback, Pyrokinesis | `lw-psi` |
| Weapons and armour | done | X2 | Long War's stats, slots, ammo, who may carry what | Long War's weapon perks while carried | `lw-gear` |
| Small items | most | X2 | grenades, medikits, rockets (with scatter), the arc thrower, scanners, beacons | the Shadow Device, the Battle Computer | `lw-gear` |
| Aliens | stand-in | X2 | Long War's squads (which aliens, how many) as XCOM 2's nearest aliens | Enemy Within's aliens as units: their models, abilities, AI (step 3) | `lw-missions` |
| Missions | most | X2 | each kind as an XCOM 2 mission type; won when every alien is dead or taken; no turn limit, sitreps, Chosen, concealment or reinforcements; Long War's squad size; terror civilians counted | Long War's objectives per kind; the landing spot | `lw-missions` |
| Maps | part | LW + X2 | Enemy Within's maps chosen per mission kind and ship from Long War's list, converted by the setup program when the player asks (else XCOM 2's plots), each a mission of its own: on XCOM 2's empty test plot (its volume stretched to the map), with XCOM 2's test mission (no aliens, timer or items of its own), a clear day's light and Long War's objective; placed whole (pods, lights, patrols) | each map's look (glossy, washed-out stand-in materials; a ×3 street lamp); terror sites keep XCOM 2's terror mission; package size | `lw-missions`, `hard-parts` |
| Wounds | most | X2 | XCOM 2's healing; Field Surgeon | Long War's own recovery times | `lw-classes` |

## The build and the tools

| System | Status | What is in | What is missing | Feature |
|---|---|---|---|---|
| The player's build | done | the mod, its config and a setup program that writes Long War's words and converts EW's screens, earth and (when asked) maps from the player's own install (v0.1.0-preview.1) | | `playable-build` |
| Config from stock Long War | done | `scripts/config-all.sh` | | `lw-psi` (the answer) |
| XCOM 2 test harness | done | control port, scripts, test aids (`tools/test`) | | |
| Crash at mission load | done | a Wwise callback during `LoadMap` after launching with the Avenger's cinematics running: voices and cinematics stopped, the map loaded 1.5 s later (0 in 20 under provoked conditions) | more play to confirm | `lw-missions` |
| EW Long War test harness | part | EW (stock Long War 1.0) started through Steam and its launcher, windowed; mouse input, screenshots, saves read | the keyboard; a campaign by clicks; the measurements | `ew-harness` |
