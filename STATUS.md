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
| EW's own strategy screens | part | LW | the start screen, research, engineering (items, manufacturing), the Foundry, the hangar (ship list, loadout), the grey market, the strategy HUD (resources, clock) and the Situation Room (countries, panic, funding, satellites, doom tracker, HQ, UFOs on EW's earth) | each screen wired to Long War's state; EW's pictures; the 3D globe and base | `lw-ew-screens` |
| The Geoscape: clock, month, decisions | most | plain | Long War's time, month and events on a screen of our own, with EW's base behind it (the Avenger hidden, given back for squad select and the armory) | a globe; the squad's flight time; XCOM 2's resource bar still shows | `lw-geoscape` |
| EW's base as the strategy scene | part | LW | EW's base (shell, fixed rooms, a level per tile from Long War's base) behind the Long War screens, in even light of its own; the hub on EW's layout (its five rooms, MISSION CONTROL above the clock, the camera into each room, the room's menu: EW's own submenu), the strategy layer's root; the setup converts the base | EW's glowing light strips (grey); the armory in EW's rooms | `lw-base-view` |
| Council, panic, funding | done | EW | countries, panic, leaving, funding; the council's monthly report on EW's World Report and End of Month Report screens, with Long War's tallies and grade | EW's council spokesman | `lw-geoscape` |
| Council requests | done | plain | Long War's 41 requests (items, satellites, jets) on its clock, its reward rolls, pending or waiting, given or refused on the Geoscape, met on arrival, science up | EW's own screens for them | `lw-council-requests` |
| Satellites | done | plain | launching, coverage, detection | | `lw-geoscape` |
| The aliens' plan | most | plain | resources, research, the monthly plan, UFOs, abductions, terror targets, the hunts after scouting | UFOs seen as they cross watched countries | `lw-geoscape` |
| The air war | most | plain | jets per continent, interception, damage, repair, refits, orders, transfers, consumables (built, stocked, used up) | a flight's own fuel (no globe; jets refuel an hour after a fight), the Firestorm's refits (Friendly Skies is a second-wave option, which the port does not offer) | `lw-hangar` |
| The base | most | LW | the grid, digging, facilities, power, upkeep, steam; built on EW's own Build Facilities and ChooseFacility screens over EW's base; removing a facility (Long War's rules, EW's dialogs); Alien Containment (captives, the arc thrower), the Hyperwave Relay (UFOs identified), the Gollop Chamber (the Temple Ship) | the arc thrower can still be equipped without containment (its stun is withheld) | `lw-base`, `lw-base-view` |
| Research | most | X2 + plain | Long War's techs, costs, times, prerequisites, credits; labs and their adjacency (`lw-base`) | XCOM 2's research room still shows its own staff | `lw-research` |
| Engineering | most | plain | building items and armour at Long War's costs and requirements; workshops' discount and rebate (`lw-base`) | | `lw-gear`, `lw-research` |
| Foundry | most | plain | projects run; done: the air and salvage projects, pistols, Improved Medikit, Ammo Conservation, Tactical Rigging, Alien Grenades (its swap and its perk's wider frag blast), S.C.O.P.E., the SHIV and MEC projects, Shaped Armor; the soldiers' project perks only while the base has a Foundry | Improved Arc Thrower (EW's native stun chance), Jellied Elerium (the MEC flamethrower is a stand-in) | `lw-research` |
| Loot | done | plain | kill loot, corpses, fragments, captives (arc thrower), salvage, the first mission's, meld canisters at EW's places; explosions wreck the weapons (no fragments); the grey market buys it (`lw-greymarket`) | | `lw-loot` |
| Psi Labs | most | X2 | training at Long War's hours and chance (0.45), on XCOM 2's soldier list and a screen in EW's words over the Psi Labs | psi ranks and XP (in Long War only names, and +255 from the council power) | `lw-psi` |
| Genetics Lab | most | EW | the ten mods, slots, cost and time, several in one stay, a mod replacing the other of its body part; on EW's own Gene Mods screen | the soldier on the lab's plinth; the mods' fatigue | `lw-genemods` |
| Officer Training School and officers | most | LW | the school on EW's screen: squad sizes and the five officer projects; officer ranks, Long War's promotion rules, the squad's leader, Command, Lead By Example, all ten powers, the officers' fatigue; promotions on EW's own Officer Billets screen in the hub's Barracks (ranks and billets, the soldiers Long War allows on XCOM 2's list, the two powers, EW's confirmation); the officer rank in the soldier lists (LT, CAPT …) | EW's insignia picture | `lw-officers` |
| Start and country bonuses | most | LW | the start screen (EW's own ContinentSelect: home country and starting bonus together), all 62 bonuses as config with Long War's `HasBonus`; what acts at the start (money, Foundry projects, jets, steam vents, starting facilities, soldiers) and on soldiers (stats at creation, by base class); the bonuses on costs, funding, abductions, research, labs, psi, gene mods, fatigue and the Officer Training School; words from the player's Long War | Sandhurst's officer side, the Illuminator Gunsight, Jungle Scouts' small slots | `lw-startbonus` |
| The story | most | plain | alien bases, Overseers, the Temple Ship, the HQ assault (Long War's months), the acts (abduction difficulty, the aliens' commander); EXALT (`lw-exalt`) | the HQ assault's own map | `lw-story` |
| EXALT | most | LW + X2 | Long War's simulation (cells placed by its score, sabotage, propaganda, research hacks, exposure, scans, the panic addition, clues); EXALT's view in EW's Situation Room (cells, clues, Intel Scan, accusations); covert operatives and their missions on EW's own maps: the extraction (the operative hacks two comm relays, then evacuates) and the data recovery (EXALT's waves after the capture areas), Long War's cash; the raid on EXALT's base | the relays' and areas' looks; the raid's own map; EXALT's own bodies | `lw-exalt` |
| MECs, SHIVs, cybernetics | part | X2 + LW | SHIVs: three bodies built in engineering, Long War's stats, weapons and Foundry projects, EW's bodies, rest and repair, squad select and armory; MECs: the Cybernetics Lab's augmentation, the eight MEC classes, seven suits in EW's MEC bodies, five weapons, Kinetic Strike and five subsystems (XCOM 2 items standing in); the Alloy SHIV as high cover for the soldiers beside it (a rule on the shot); the Hover SHIV flies (XCOM 2's flying traversal, no fuel) | the Hover SHIV's fuel | `lw-shivs-mecs` |
| Grey market | done | LW | Long War's prices (built items at 40%, corpses with Xenological Remedies), what can be sold, NOT RESEARCHED, on EW's own GreyMarket screen | | `lw-greymarket` |
| Squad selection and loadout | most | X2 | XCOM 2's squad select and armory for a Long War mission (Long War's squad size, rested soldiers first, Long War's launch, backing out leaves the mission) | the armory and loadout still in the Avenger's armory (squad select itself is in EW's hangar, all slots picked) | `lw-squad-select` |
| Fatigue | done | X2 | Long War's hours, all in, shown as War of the Chosen's Tired; psi powers' and gene mods' hours, officers' hours, critical wounds' hours, Stay Frosty, the psi armour, Gift of Osiris and Call to Arms | | `lw-fatigue` |
| Soldiers: recruits, ranks | done | X2 | Long War's eight classes, ranks, stat gains and experience in XCOM 2's barracks; Long War's random rookie stats; the officer powers on experience (So Shall You Fight, Into the Breach) | | `lw-classes` |

## Tactical

| System | Status | Looks | What is in | What is missing | Feature |
|---|---|---|---|---|---|
| Damage reduction | done | LW | Long War's rule on every unit: the aliens' own and armour's, shields, acid, cover as the attacker sees it (0.667 low, 1 high), hunkering, Will to Survive, Fortiores Una; Combined Arms, Gauss weapons, shotguns' extra; the fraction rolled up by chance | | `lw-damage-reduction` |
| Classes and perk trees | done | X2 | the eight subclasses, their trees and stat gains | | `lw-classes` |
| Perks | most | X2 | most of the 78 Long War perks act, Lock N' Load, Concealment, Extra Conditioning, Javelin, Neural Feedback, Pyrokinesis and Muscle Fiber Density (a passive jump up) among them; approximations marked in Decisions | Bioelectric Skin's reveal | `lw-classes`, `lw-psi`, `lw-genemods` |
| Psi powers in missions | most | X2 | all twelve | | `lw-psi` |
| Weapons and armour | done | X2 | Long War's stats, slots, ammo, who may carry what | `BalanceMods` (mobility and will by weapon) | `lw-gear` |
| Small items | most | X2 | grenades, medikits, rockets (with scatter), the arc thrower, scanners, beacons, the Respirator Implant, Reaper Rounds, the Ghost and Psi Grenades | | `lw-gear` |
| Aliens | part | LW + X2 | Long War's squads (which aliens, how many) as XCOM 2's nearest aliens, drawn as Enemy Within's (15 species' bodies, animations and weapons converted by the setup), with Long War's stats: base, difficulty and the research upgrades (HP, aim, defense, mobility, will, crit, shields, damage reduction, damage, each species' weapon damage); pod leaders and navigators with their stats, scale and perks (as the soldiers' perks work) ; the Sectoid's psionics (Mind Merge, Psi Panic, Mindfray), the Commander's Mind Control, the Muton's Blood Call, the Drone's repair, the Cyberdisc's Death Blossom, the Floater's Launch, the Seeker's Strangle and cloak, the Muton's Intimidate and the Berserker's Bloodlust, the Drone's Overload, the Ethereals' Mind Control, Psi Drain, Mindfray and Rift, used by their XCOM 2 AI; the Berserker's Bull Rush as XCOM 2's Berserker charge; EW's animations playing on their bodies | the Cyberdisc's closing is only its look (XCOM 2's Gatekeeper's own) | `lw-aliens`, `lw-ew-units`, `lw-missions` |
| Missions | most | X2 | each kind as an XCOM 2 mission type; won when every alien is dead or taken; no turn limit, sitreps, Chosen, concealment or reinforcements; Long War's squad size; terror civilians counted; the council's missions on their EW variant levels (bomb disposals with nodes and timer, VIP extractions and rescues to the evac zone, the levels' gated alien drops); the Chryssalid hive (its objectives, transponder, run and air strike, scripted spawns); Progeny's chain (Portent, Deluge, Furies, the named soldiers); EXALT's covert missions (`lw-exalt`) | the council assaults' own variant Kismet beyond their drops; the Meld tutorial (EW's tutorial only); the hive's implanted zombies; Furies' console destroyed by fire | `lw-missions`, `lw-council-missions` |
| Maps | most | LW | Enemy Within's maps as real XCOM 2 plots written by the setup (geometry, walls, walls that break, doors that open, roofs cut away by XCOM 2's building visibility, materials incl. glass, cut-outs (tree cards, fences, decals) and road paint, lights, what can be stood on, not cars or sandbags); Long War's squad at EW's pods (terror pods too), 18 terror civilians by EW's rules; the campaign's first mission on an EW plot; every map of 83 loads (the two crashes found); EW's night maps at night (XCOM 2's city and nature nights) | | `lw-missions`, `hard-parts` |
| Wounds | most | X2 | Long War's recovery times on XCOM 2's healing; Field Surgeon; SHIV repair and MEC rest (lw-shivs-mecs) | | `lw-classes` |

## The build and the tools

| System | Status | What is in | What is missing | Feature |
|---|---|---|---|---|
| The player's build | done | the mod, its config and a setup program that writes Long War's words and converts EW's screens, earth and (when asked) maps from the player's own install (v0.1.0-preview.1) | | `playable-build` |
| Config from stock Long War | done | `scripts/config-all.sh` | | `lw-psi` (the answer) |
| XCOM 2 test harness | done | control port, scripts, test aids (`tools/test`): state and wait/go on it, units and move, enemies (fog, viewers, bodies), doors, bodies | | |
| Crash at mission load | done | a Wwise callback during `LoadMap` after launching with the Avenger's cinematics running: voices and cinematics stopped, the map loaded 1.5 s later (0 in 20 under provoked conditions) | more play to confirm | `lw-missions` |
| EW Long War test harness | part | EW (stock Long War 1.0) started through Steam and its launcher, windowed; mouse input, screenshots, saves read | the keyboard; a campaign by clicks; the measurements | `ew-harness` |
