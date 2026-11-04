---
title: "Long War's loot: what missions bring back"
status: in-progress
priority: 2
dependsOn:
  - lw-geoscape
  - lw-research
---

## Purpose

Long War's research and engineering are paid for in what missions bring
back:
- alloys and elerium;
- weapon fragments;
- a UFO's artifacts (power sources, navigation computers…);
- corpses and captives.

Without loot the tree stops at its first steps (`lw-research.md`). This
feature brings Long War's loot to the missions the Geoscape sends.

## What the person should see

After a crash site or landed UFO is taken, the salvage lands in XCOM's
stores (XCOM 2's inventory) in Long War's amounts, with a crash leaving
less. After any mission, the aliens killed leave corpses and weapon
fragments in Long War's way. Research that needs them can then start.

## Requirements

- **Long War's numbers, generated** from its `DefaultGameCore.ini` and its
  code (`XGItemTree.DetermineShipSalvage`, `XGStrategyAI.DetermineCrashLoot`,
  and the kill loot's own code).
- **Long War's artifacts become XCOM 2 resource items.** XCOM 2's own
  are used where it has them: alloys, elerium, weapon fragments. Their
  names and texts are Long War's, written on the player's machine.
- **Then enforced in research:** fragments, consumed items, and what
  must have been held or captured.

## Report (2026-11-01, phase 1: UFO salvage)

- **A UFO's salvage** (generated into `XComLWStrategy.ini` as `+Salvage`):
  - each type's artifacts as Long War's `DetermineShipSalvage` gives them
    (a Transport: 4 navigation computers, 4 power sources, 2 surgery, 8
    stasis tanks, 10 food, 2 entertainment);
  - its alloys: `UFOAlloys` by size × `ALLOY_UFO_BALANCE` (by difficulty);
  - its elerium: power sources × `UFO_ELERIUM_PER_POWER_SOURCE`;
  - 20 % more alloys and elerium once its UFO analysis is researched.
- **A crash** (`DetermineCrashLoot`):
  - 30–45 % of the alloys survive;
  - each artifact survives at its own chance (power source 20 %,
    navigation 25 %, stasis 30 %, surgery 30 %, food 50 %, entertainment
    100 %);
  - 70–100 % of a power source's elerium is lost with each power source
    destroyed.
- **Paid** when a crash site or landed UFO is won, from a real mission
  or from `resolve` and `auto`, and noted in the Geoscape's events.
- **The artifacts are XCOM 2 resource items** (`X2Item_LWArtifacts`,
  `LWItem_<Long War's name>`), with names, plurals and summaries from Long
  War's localization (`makeItemWords`).

**Checked** (new campaign, simulated by `auto`):
- After three more months with every mission won, the stores held 420
  alloys, 14 navigation computers, 2 power sources and 6 alien surgery,
  among others.
- Alien Materials, which costs alloys and elerium, became affordable.

### Decisions

- **The salvage table is written out in the generator, with its source,
  rather than parsed from bytecode**, like the ship table. It is short,
  and the parse would be fragile.
- **A landed UFO taken gives its full salvage.** Long War also counts
  what the fight destroyed. Our missions are XCOM 2's maps with XCOM 2's
  aliens, so there is nothing to count yet.

### Left open

- **The rest of the loot:**
  - kills: corpses, captives and weapon fragments;
  - abduction and terror rewards;
  - the damaged artifacts a crash leaves, which only sell.
- **Research gates** (fragments, consumed items, held or captured) are
  still not enforced: next, once kills bring fragments and corpses.
- **Selling artifacts** (Long War's grey market).

## Report (2026-11-01, phase 2: the aliens, their loot; research's gates enforced)

**Long War's squads** (`LWAlienSquads`, ported from `XGStrategyAI` and
XComGame's `XGBattleDesc`):
- **The squad code:**
  - every UFO type's crew (`DetermineSmallScoutSquad` …
    `DetermineOverseerSquad`), abductions by difficulty, terror by the
    terror missions taken;
  - the pods, the aliens shared out over them, the species chosen by pod
    type from Long War's table by month (`GetPossibleAliens`);
  - each pod's supports (`GetSupportingAlien`, with the month-dependent
    "+32" sets, and `GetSupportAlien`).
- **A landed UFO's crew is chosen a month ahead**, as in Long War.
- **Long War's hand-patched code packs counts into its pods' fields.**
  Read here as: the main alien, one more of it when its flag is set,
  then up to two kinds of support. Each step adds one alien, so the
  pod's size comes out right.
- **What is not kept yet:** the act (1, so Outsider commanders) and
  alien bases assaulted (none).
- **Abduction difficulty** is Long War's: act, the country's panic,
  chance.

**What the aliens leave** (`XGSummaryUI.CollectArtifactsFromDeadAliens`,
`XGUnit`, `GenerateWeaponFragments`; a species table generated into
`XComLWStrategy.ini`):
- each one's corpse;
- each weapon's fragments × `FragmentBalance`, at least one;
- the mechanical aliens' elerium, alloys and meld;
- 0.3 meld for every other kill;
- an abduction pays Long War's cash × its difficulty.

On a mission won (real, or `resolve` and `auto`), every alien of the
squad counts as killed, none by an explosion and none taken alive, since
our missions do not tell yet. The squad is drawn when the mission comes
back, not when it appears. Corpses are items with Long War's names.

**Research's gates, enforced** (`X2StrategyElement_LWTechs`):
- weapon fragments, and the items a tech consumes (its `eItemReq` ×
  `iNumItems`: Xenobiology, 5 Sectoid corpses), are costs;
- "one of these in stores" and "one of these techs" become XCOM 2's
  alternate requirements, crossed;
- the UFO analyses ask for their UFO type captured: a hidden marker item,
  given when a crash site or landed UFO of it is taken;
- "must have been held" is asked as "held now", since XCOM 2 keeps no
  archive. The two are the same whenever the tech consumes the item.

**Checked** (new campaign without its first mission, control port):
- **Sample squads:**
  - an early Scout crash: an Outsider with 6 Sectoids and Drones;
  - landed (a month ahead): Floaters, Thin Men, a Seeker;
  - a landed Battleship on day 100: 30 aliens;
  - the first terror site: 4 Chryssalids and 8 Floaters, as Long War's
    code sets.
- **Loot:** three months with every mission won left, among others, 54
  Sectoid and 58 Floater corpses, 185 weapon fragments, 49 meld and 249
  elerium.
- **Research:**
  - at the start only Alien Weaponry, Alien Materials and Alien Computers
    show, none affordable, and Xenobiology is hidden until a corpse is
    held;
  - after a month of missions won, Xenobiology shows, and Weaponry and
    Materials can be paid for;
  - Alien Computers waits for a navigation computer.

### Decisions

- **Every alien of the squad counts as killed on a win.** Until our
  missions are Long War's (its aliens on its maps), the squad is Long
  War's strategic answer to "who was there", and the fight's details
  (explosions, stuns, retreats) are not ours to read yet.
- **Long War's code, ported literally where it is odd.**
  - Chryssalids are possible in secondary pods from month 0.
  - An upgraded Sectoid pod can bring an EXALT Elite.
  - The minimum pod count uses Long War's `(n % f) * 2`.
  - The person's memory of playing is the check.

### Left open

- **Captives and alien weapons** (from aliens taken alive): the
  interrogations and the plasma research that ask for them stay locked
  until missions can stun.
- **The tactical side:** explosions destroying corpses and weapons, and
  aliens left behind.
- **Terror rewards.**
- **The first mission:** a Long War campaign now begins with what Long
  War's first mission left (`DetermineFirstMissionSquad`: 10 Sectoids, so
  10 corpses, 10 fragments and some meld). XCOM 2's own first mission,
  played or skipped, leaves nothing of Long War's. Xenobiology and Alien
  Weaponry can start at once, as in Long War.
- **What only sells:** damaged artifacts, and the grey market.

## Response handled (2026-11-01): EXALT, a win from the Geoscape, the stores

The person, after trying it:
- No EXALT before EXALT is revealed, and none in the aliens' pods until
  their HQ has been taken.
- A month-1 landed UFO is a suicide mission anyway; Chryssalids would not
  shock.
- There is no win button on the Geoscape, the in-mission one did not
  seem to bring loot, and the stores are nowhere to be seen.

What changed:
- **No EXALT at all**, since the campaign has none yet. Long War's eight
  EXALT secondaries (month 8 on) are left out, and where a support table
  brings an EXALT (an upgraded Sectoid pod) the pod's main alien comes
  instead. The person's rule becomes the gate when EXALT is in.
- **WIN (SKIP MISSION)** beside each mission on the Geoscape: the mission
  counts as won without being played, its loot and rewards booked at
  once.
- **STORES** on the Geoscape: the right-hand text switches to Long War's
  stores (staff, alloys, elerium, fragments, artifacts, corpses).
- **Weapon fragments are an item of the mod's.** XCOM 2's own
  WeaponFragment has no name in War of the Chosen, and showed as an
  error.
- **The events name items as the game does** ("Sectoid Corpse").
- **A mission played** books its loot when the Geoscape next opens: that
  is where the result is read. The Avenger's alloys and elerium can
  rightly stay at 0 after an early abduction: Sectoids leave corpses,
  fragments and meld, not elerium.

## Report (2026-11-01, aliens taken alive)

**Captives and intact alien weapons**, the gate to Long War's
interrogations, plasma research and plasma engineering. Long War takes
them with the arc thrower in a mission. XCOM 2 has nothing that stuns, so
for now an alien is taken alive only in a **mission won without playing
it, with a captive**:
- on the Geoscape, the WIN + CAPTIVE button beside each mission;
- on the control port, `resolve <n> captive`.

The rules, from Long War's code:
- **Who:** the species that can be stunned and have a captive item
  (`CaptiveToCorpse` the other way). Chryssalids, zombies and the Uber
  Ethereal never are (`TryStunned`).
- **Which one:** the most valuable kind in the mission's squad,
  - leaders first: Sectoid Commander, Ethereal, Muton Elite, Heavy
    Floater, Berserker;
  - then Muton, Thin Man, Floater, Sectoid.
  - It is taken out of the dead, so its corpse and fragments are not
    counted.
- **What comes home:**
  - its plasma weapons, intact (generated per species from Long War's
    loadouts: `Weapons=` on each `+Species`);
  - the captive, to Alien Containment. Without one it dies on the way
    and its corpse comes home (`UnloadArtifacts`).
- **The Arc Thrower** must be researched.
- **The interrogation** (research, Long War's) consumes the captive, as
  before.

**Checked in the game:**
- without the Arc Thrower: no capture, and the note says so;
- with it, but no containment: "Taken alive, but without Alien
  Containment it died: Sectoid Corpse, Alien Pistol";
- with a Fission Generator and Alien Containment built in the base:
  "Taken alive: Thin Man Captive to Alien Containment, Alien Carbine".

### Decisions

- **A captive by the skip-mission button**, as the WIN itself is: a
  stand-in until missions are Long War's (an arc thrower, stun chances,
  `CalcStunChance`).
- **The most valuable alien is chosen** for the player. In Long War the
  player chooses whom to stun.

### Left open

- The arc thrower in played missions.
- The captive capacity: one per containment, which Long War itself does
  not check on the way home.

## Meld canisters: read, not built (2026-11-04)

Long War keeps EW's meld canisters. Read from its code (upkit's decompiler, kept out of the
repository); a spec for the work, not done yet:
- **Which missions** (`XGBattleDesc.ShouldSpawnMeldCanisters`): abductions, crash sites, landed
  UFOs (EW's mission types 2, 3, 4) and EW's meld tutorial map; not terror, not the base defence.
- **Where:** EW's maps carry `XComMeldContainerSpawnPoint` actors, each with its spawn group
  (`m_iSpawnGroup`, the map's start chosen for the mission, as the soldiers' spawn), a difficulty
  (easy or hard) and the turn it self-destructs on (`m_iDestroyedOnTurn`, 3 by default; none:
  the canister cannot be destroyed). The converter does not read them yet (`ew-map.ts` reads the
  pods and the spawn points only).
- **How many** (`XGBattle_SP.InitMeldContainers`, Long War's version): a roll of 1 to 3; always one
  hard canister (if the group has one), an easy one on 2 or more, a second hard one on 3.
- **How much** (`XComMeldContainerActor.GetMeldAmount`, hand-patched): a recap stat / 10 clamped to
  5–30, times a value the patch reads from the game core's defaults (not identified yet).
- **In the mission:** a unit next to it collects it (an interaction); its countdown starts when
  it is seen (`m_bBeginCountdownWhenSeen`) and it is destroyed when the turns run out; the HUD shows
  the canisters and their turns (`UISpecialMissionHUD_MeldStats`).
- **To build:** the spawn points in the converted map's section (a converter version, so the maps
  are converted again); the canisters placed as the mission starts (XCOM 2's interactive objects,
  an EW-looking mesh); collecting, the countdown, the HUD line; the meld booked as loot when the
  Geoscape next opens.
- **Seen in EW's maps** (the farm, the bar; a reading kept in /tmp): the farm has 12 spawn points
  in groups 0–2 (its three player starts), easy and hard, self-destructing on turns 4 to 11; the
  bar 4, all group 0, on turns 4 and 8. The meld tutorial's are not in its persistent level (its
  streamed level, to read).

## Report (2026-11-04 day, meld canisters)

- **Built:** the converter reads EW's meld canisters' places (`MeldPoints` in each map's section:
  the place, its group, its turn, hard or easy; converter version 16, so the setup converts the
  maps again). As the mission's HUD comes up, `LWMeld` places Long War's canisters on an
  abduction, crash site or landed UFO played on an EW map: the spawn group of the drop zone
  nearest the soldiers, one hard, an easy one on a roll of 2 or more, a second hard on 3 (EW's
  rule). Each is XCOM 2's timed loot drop (its marker with the turns left, taken by a soldier who
  walks up to it, brought home in the backpack) holding the aliens' resources / 10 meld, 5 to 30;
  gone at the start of XCOM's turn EW gives it.
- **Seen** (the bar, an abduction): "2 canisters (roll 2, group 0; 2 hard, 2 easy places), 11
  meld each"; the markers at EW's places (by the parking lot, in the kitchen); the easy one's turns
  4 → 1 after two turns ended; the Scout walked into the kitchen, XCOM 2's LOOT RECOVERY "Meld x11";
  the mission won, the Geoscape's meld 14 (11 of them the canister's).
- **Decisions:** the loot drop keeps the first soldier as its source (XCOM 2 wants one; the place
  and the turns are set after). Its recovery dialog therefore names that soldier as where the meld
  came from. Without a source it would say "Meld canister", but the one run made so crashed at
  the end of the first turn; with the source kept, five turns, the pick-up and the mission's end
  went through. Not proven to be the cause.
- **Not like EW yet:** EW's canister model and its sounds (XCOM 2's loot marker instead); destroying
  a canister with explosives; the HUD's canister line. (EW's countdown from the mission's start is as
  here: `m_bBeginCountdownWhenSeen` is off by default and none of the places read sets it.) The meld tutorial map's places are in its
  streamed level, not read.
