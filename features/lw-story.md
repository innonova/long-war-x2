---
title: "Long War's story: alien bases, Overseers, the Temple Ship"
status: review
priority: 2
dependsOn:
  - lw-geoscape
  - lw-base
  - lw-loot
---

## Purpose

Until now a campaign could only be lost. Long War's war is won through
its story:
- **the Outsider's shard** makes a Skeleton Key;
- **the key opens an alien base**, built in a country that left, and
  taking it brings the country back and yields the Hyperwave Beacon;
- **the Overseers** that fly over the world carry the Ethereal Device;
- **the Gollop Chamber** built from it leads to the Temple Ship, whose
  fall ends the war.

This brings that chain into the Long War Geoscape, so a campaign can be
won.

## What the person should see

- **On the Geoscape:**
  - a note when the aliens build a base in a country that has left;
  - with a Skeleton Key in the stores, an ASSAULT decision for each
    alien base;
  - Overseer UFOs passing over watched countries each month;
  - once the Gollop Chamber stands, ASSAULT: the Temple Ship.
- **Engineering** builds the Skeleton Key once the Outsider Shard is
  researched.
- **Winning the Temple Ship** brings XCOM 2's victory screen; losing it
  loses the campaign.

## Report (2026-11-01)

The rules, read from Long War's code:
- **The Outsider Shard:** a downed Outsider (the UFO crews' commander
  before act 3) leaves its shard (`XGUnit`; it has no corpse). It comes
  with the kill loot.
- **The Skeleton Key** is built in engineering once the Outsider Shard
  research (tech 3) is done: §200, 40 elerium, 10 alloys, 10 meld, 20
  days at 25 engineers, and the shard (`GetItemProjectCost`).
- **Alien bases** (`AddToAssets`, `CreateAlienBase`): a country that
  signs the pact gets one.
  - **An assault takes a Skeleton Key**, whatever comes of it
    (`XGStrategy`: `RemoveItem(184)`).
  - **Taken:**
    - the country rejoins the council, at 98 panic less 20; its
      continent loses 5 panic (`CostTest`, the mission's results);
    - the base's artifacts come home: 100 alloys, 3 power sources and
      their elerium, 4 surgery tables, 15 stasis tanks, 10 food, 1
      entertainment;
    - the first base also holds the Hyperwave Beacon.
- **Overseers** (`AddNewOverseers`): until XCOM has an Ethereal Device,
  up to three Overseers fly over watched countries each month (days 5,
  15 and 25), and one over each country that has left.
  - They fly over and leave (`eUM_Flyby`).
  - Brought down, their salvage holds the Ethereal Device (`PsiLink`), as
    the salvage table had it.
  - The infiltration's Overseer, which lands, was already there.
- **The research and facilities** were already Long War's: Hyperwave
  (with the beacon) → the Hyperwave Relay; Interrogate Ethereal and the
  Ethereal Device → Psi Link → the Gollop Chamber.
  - An Ethereal can be taken alive from an Overseer's crew
    (`lw-loot.md`).
- **The Temple Ship:** once the Gollop Chamber stands. Won, XCOM has won
  (XCOM 2's `UIYouWin`); lost, the campaign is lost (`YouWin`,
  `YouLose`).

**Checked in the game** (control port):
- a month in, an Overseer was seen over the United States ("Overseer,
  Flyby") and left three hours later;
- China signed the pact and "The aliens are building a base in China";
- with a Skeleton Key given, the assault was offered and won: "In the
  alien base: a Hyperwave Beacon", and "China rejoins the council";
- with a Gollop Chamber placed (the new test aid `base set`), the Temple
  Ship was offered, and its win brought XCOM 2's VICTORY screen.

### Decisions

- **A Battleship's crew stands in for the alien base's squad** in its
  kill loot (APPROXIMATION in the code): Long War's
  `DetermineAlienBaseSquad` is a 36-alien build of its own.
- **The Temple Ship needs only the Gollop Chamber.** Long War also has
  a psionic volunteer go through the chamber first; that waits for psi
  soldiers.
- **The base is in the country that left**, not on a map location.

### Left open

- The volunteer and psi soldiers; the XCOM HQ assault (Long War's base
  defence, from month 4); the council's own missions.
- Act 3 (no more Outsider commanders once the Overseer is down) and the
  EXALT story.

## Report (2026-11-01, the assault on XCOM's headquarters)

**Long War's HQ assault** (`AddHQAssaultMission`), read from its monthly
plan:
- **When:** in the plan cells that bring it (tier 3 and 4 at aggression
  4, now marked `HQAssault=true` by `scripts/strategy-config.mjs`), every
  third time such a month comes. At month 12 it comes anyway if none has
  (Long War's `eRecap_ContinentsCovered` counter).
- **How:**
  - a Battleship hunts over XCOM's home country (day 2 to 7);
  - an Assault Carrier comes down on the headquarters (day 8 to 25;
    `Infiltrate_1`, a direct landing);
  - shot down first, it never lands.
- **Landed:** "DEFEND: XCOM's headquarters" (24 hours on the Geoscape).
  - Held: the carrier crew's kill loot.
  - Lost or unanswered: the war is lost. Long War forces the mission; an
    unanswered assault counts as lost.

**Checked in the game** (the test aid `hqassault`):
- the Battleship hunted over the United States, then "The aliens are
  assaulting XCOM's headquarters!";
- unanswered, a day later: "XCOM's headquarters has fallen. The war is
  lost.";
- defended in another campaign: "XCOM's headquarters held."

Also seen: thirteen months of `auto … 90 % … sats` lost the campaign in
month 10, sixteen countries gone, before any HQ assault. Long War's pace
with a player who builds nothing but satellites and uplinks.

## Report (2026-11-17, Long War's acts)

- **Read** (`XGStrategy.GetAct`): act 3 once XCOM has ever held a Hyperwave Beacon, act 2 once a captive has been
  interrogated (`LABS().HasInterrogatedCaptive`), else act 1. What the acts change in Long War's code:
  - an abduction's difficulty starts at the act less one (`XGStrategyAI.GetAbductionDifficulty`; the port had act 1
    always);
  - the aliens' commander (`GetCommanderType`): an Outsider before act 3; then a Sectoid Commander, or, once XCOM has
    held a Psi Link, a Sectoid Commander or an Ethereal at even odds. (The rest: the Situation Room's headlines,
    the base's chatter and the music.)
- **Done:** `XComGameState_LWStrategy.Act`, used by `AbductionDifficulty` and `LWAlienSquads.Commander`.
- **Checked on wingpu** (`give` a Hyperwave Beacon and a Psi Link, `squad 2 9 200`): a landed large UFO's commander
  became an Ethereal.

## Report (2026-11-17, the story missions on EW's own maps)

- **Before:** the alien base, the Temple Ship and the HQ assault played on XCOM 2's guerrilla plots (no EW map was
  listed for their kinds).
- **Done:** `scripts/maps-config.mjs` reads EW's `eMission_AlienBase`, `eMission_Final`, `eMission_HQAssault` and
  `eMission_ExaltRaid` maps from `DefaultMaps.ini`, so `XComLWEWMaps.ini` lists AlienBase01 and AlienBase02 (the alien
  base), TempleShip (the final mission), EWI_HQAssault and EWI_ExaltHQAssault (night). `LWX2EWMapPieces.KindFor` maps
  the strategy's mission kinds 5 (alien base), 6 (Temple Ship), 7 (HQ assault) and 9 (EXALT's raid) to those. The setup
  converts and writes plots for them like any listed map; `XComMaps.ini`'s night lighting covers the EXALT HQ.
- **Checked on wingpu:**
  - each of the five maps loaded in a mission with the squad standing, ready for orders (`ForceMap`);
  - a mission of kind 5 chose AlienBase01 by itself and spawned its Battleship crew at EW's pods; one of kind 9 chose
    EWI_ExaltHQAssault and spawned EXALT's raid squad (`ForceKind`).
- **Still standing in:** their objectives are "kill all". EW's own (the base's command centre, the Temple Ship's
  Uber Ethereal and its sequence, the HQ assault's waves) are scripted in their levels' Kismet and not read yet.

## Report (2026-11-17, the Temple Ship as EW scripts it)

**Read** (EW's `XComSpecialMissionHandler_Templeship` and the `TempleShip` level's Kismet; `ew-objectives.ts readTemple`
writes `[LongWarX2.LWX2TempleShip]`; numbers only):
- **Not Long War's squad at the map's pods:** the level's fourteen pods each force an alien type
  (`XComAlienPodManager.GetAlienPawnType`: a forced pod gives its `AlienType`; two of them force none and spawn nothing),
  and the handler stands them arena by arena (`SpawnArenaPods` on the Kismet variables `FirstArenaPod0-6`,
  `SecondArenaPod0-6`). Long War's stats apply to each species.
- **The stages** (`LWX2TempleShip`, state `XComGameState_LWX2Temple`):
  1. the first arena (a Sectoid Commander, Floaters, a Heavy Floater: 6);
  2. once an alien is hurt with 8 or fewer left (the handler's `LiveAliensThreshold`, checked in `OnAlienUnitDamaged`),
     the first swarm at the next aliens' turn end: three Drones and two Cyberdiscs (`FirstSwarmTriggered`);
  3. at 1 or fewer, the second: three Chryssalids (`SecondSwarmTriggered`);
  4. all dead: the second arena (Thin Men, Mutons, a Berserker, two Sectopods: 11; `OpenSecondArena`);
  5. all dead: two Elite Mutons at the boss gate (`BossGateOpen`) and the Uber Ethereal in the boss arena
     (`BossArena_Begin`);
  6. the Uber Ethereal seen: two Ethereals and two Elite Mutons (`UberVisibleComplete`).
- **The win:** the Uber Ethereal's death; every alien left dies with it (`DoWin`). Killing all else wins nothing.
- **The objective** reads "Kill the Uber Ethereal" once it has come: the port's words; EW's level shows no text of its own.
- Scripted spawns come for XCOM (as the hive's do); arena pods stand unaware, as pods.

**Checked on wingpu** (a forced Temple Ship, `ForceKind=6`; stages driven with `killaliens` and `endturn`): 6 aliens in
the first arena; the first swarm (5) at the aliens' turn end after the first kills; the second (3); the second arena
(11); the gate's two Elite Mutons and the Uber Ethereal (60 HP); the Uber came down, was seen, its guard of four came;
the Uber removed: the four died with it and the mission summary showed 32 enemies. Screenshot:
`logs/wingpu_temple_uber_objective.png`.

**Not done:** the arenas' gates: EW's are InterpActors it opens by matinee, and the converter writes no InterpActors, so
the gates are simply absent and the arenas open from the start (their aliens still come only at their stage); the Uber Ethereal fights as XCOM 2's Avatar template with Long War's stats; the
cinematics, music and the Gollop Chamber's volunteer are not ported.

## Report (2026-11-17, the HQ assault as EW scripts it: a Kismet interpreter)

**Decision:** the HQ assault's level (`EWI_HQAssault_Stream`) carries a 5,700-line Kismet: a random choice between two
alien sets, extra groups by difficulty from turn counters, which door the reinforcements use by where the squad stands,
reinforcements when soldiers fall, objectives per wave, victory held until the final wave. Rather than translate that by
hand, the mod now runs the level's Kismet itself:
- **`tools/convert/ew-kismet.ts`** (run by the setup) exports a level's ops with their output links (op and input), variable
  links (each resolved to the variable it stands for: named, a subsequence's external), the few properties acted on, each
  sequence's inputs and outputs, and the variables' values (an actor: its class, place and a volume's box); and the level's
  `XComWaveSystem` (sets, waves, groups). Into `Config/XComLWX2Kismet.ini`, on the player's machine (it holds the level's
  objective texts), gitignored.
- **`LWX2Kismet`** is the interpreter: events (level loaded, the roaming alien count, the battle begun, the four turn
  events, a unit killed, remote events) start ops; set/add/compare ints and bools, random switch, delays (turn-based: they
  only order things), remote events, subsequences in and out, mission handler states (`<State>_Begin`), objectives, units
  counted in volumes, XCOM reinforcements and Delay Victory act as EW's do; cinematics, cameras, sounds, narrative, effects
  and toggles pass on. Its values persist in `XComGameState_LWX2Kismet`.
- **`LWX2WaveSystem`** is EW's wave system: sets begun at the start or by their remote event, ended by their disable event;
  waves on their turn after the set began, at the beginning or end of the aliens' turn; groups of their type (a scalable
  one: one of the squad's species that arrives that way) at their points, coming for XCOM; a group's activated and spawned
  events go back to the Kismet. The battle cannot be won while a set is not done (`IsAlienWaveSystemActive`).
- **`LWX2HQAssault`** ties it to the mission: Long War's squad is not stood at the map's pods (EW's level culls them); the
  turn events come from XCOM 2's `PlayerTurnBegun`/`PlayerTurnEnded` (the mod's 2-second check missed empty aliens' turns);
  reinforcements are the base's soldiers not on the field (as XCOM 2's Avenger defence's `SeqAct_SpawnUnitFromAvenger`
  takes them; the wounded left out; they go home with the squad) or blueshirts made for the battle.

**Checked on wingpu** (a forced HQ assault, `ForceKind=7`; waves killed with `killaliens`, turns ended): the script sent
two blueshirts in at the start and three reinforcements on turn 2 (one soldier from the barracks), as EW's does; waves came
at the end of the aliens' turns 1, 3, 4, 6, 7, 10, 11, 13, 14, 15 and 16 (difficulty groups among them); the objective read
EW's own "Latest enemy wave in Command Center."; after turn 16's final wave the mission was won (42 aliens) and the game
returned to strategy. Screenshot: `logs/wingpu_hq_assault_objective.png`.

**Not done / approximate:**
- Reinforcements are placed at their destination point; EW walks them in from the door.
- Scalable groups choose among the squad's species by flying or not; EW also knows which species can drop in.
- Blueshirts are XCOM 2 rookies with its default loadout, not EW's base security.
- The map is dark in places (its lighting, as with other interiors).
- The council assault variants' own Kismet could now run the same way; not wired yet.
