---
title: "Long War's missions: its alien squads, Enemy Within's maps and aliens"
status: in-progress
priority: 2
dependsOn:
  - lw-loot
  - hard-parts
---

## Purpose

A Long War mission is the aliens Long War's strategy sent, on Enemy Within's
maps, as Enemy Within's aliens. The hard parts are proven (`hard-parts.md`):
- Enemy Within's maps can be the ground of XCOM 2's missions;
- its aliens come across animated.

This feature makes the missions Long War's, in steps:
1. **Long War's alien squads in XCOM 2's missions**: the composition
   Long War's strategy gives each mission, as XCOM 2's nearest aliens.
2. **Enemy Within's maps** as the missions' ground, with the pods and
   objectives at Enemy Within's places, its lights, the squad landing in the
   open.
3. **Enemy Within's aliens as units:** pawns, animations through XCOM 2's
   systems, abilities, AI.

## Report (2026-11-01, step 1: Long War's squads)

**A mission sent from the Long War Geoscape is fought against Long War's
squad for it** (`LWMissionSquads`, from `UILWHeadquarters.OnLaunch`).
- **The squad** is `LWAlienSquads`' for the mission, by UFO, kind of
  mission, day, the aliens' resources and aggression. For the story's
  missions it is a Battleship's or Assault Carrier's crew.
- **The species** are fought as XCOM 2's nearest aliens (`+FightAs` in
  `XComLWStrategy.ini`, APPROXIMATION):
  - Sectoid and Sectoid Commander: Sectoid;
  - Floater and Heavy Floater: Archon;
  - Thin Man: Viper;
  - Muton: Muton; Muton Elite: Andromedon; Berserker: Berserker;
  - Cyberdisc: Gatekeeper; Drone: ADVENT MEC; Mechtoid: MEC Mk II;
  - Sectopod, Chryssalid: themselves; Zombie: Psi Zombie;
  - Outsider: Codex; Seeker: Faceless;
  - Ethereal and the Uber Ethereal: the Avatar;
  - EXALT: ADVENT.
- **The pods:** XCOM 2's mission keeps its pods' number and places. Long
  War's aliens are shared out among them, the first in the first pod; a
  VIP's or strategy unit's pod is left as it is.
- **The kill loot** of a mission played is that squad's, the one it was
  given (`PendingSquad`), not a fresh roll.

**Checked in the game:** an abduction in the first month launched with
"Long War's squad of 11 in 3 pods", and the mission held 7 Sectoids and 4
drones (as ADVENT MECs), Long War's early abduction crew.

**Found on the way:**
- The development build's EW-map experiment (`PlaceEWMapWhole`) left
  missions without any alien. The pods spawn where the hidden XCOM 2 map
  had them, and none did.
- It was also why units dropped in for testing never became visible.
- The experiment and the EW unit display are now off by default, in
  development too, until step 2 places the pods on Enemy Within's maps.
- With them off, the arc thrower was fired for real at a visible Sectoid:
  charge spent, "42 % → miss" (`lw-gear.md`).

### Decisions

- **XCOM 2's pods' number and places**, not Long War's pod structure. The
  maps are still XCOM 2's, and its pods sit where the map has room.
- **The mapping above is a stand-in** to judge in play. It goes when Enemy
  Within's aliens are units (step 3).

### Left open

- XCOM 2's own mission rules on top: its objectives, timers and sitreps, the
  Chosen and the Alien Rulers (the DLCs are installed).
- Kill loot from what was actually killed (now: the whole squad when the
  mission is won).
- Steps 2 and 3.

## Report (2026-11-01, step 2 begun: Enemy Within's pods read)

**The map converter now exports Enemy Within's pods and spawn points**
(`tools/convert/ew-map.ts` → the map's ini, `LWX2EWMapPieces.Pods`,
`SpawnPoints`). Each `XComAlienPod` comes with its location, the commander
flag and its min and max aliens; each `XComSpawnPoint` with its location.
- Run on wingpu on `CSmallScout_Badlands`: 4 pods (the commander's beside
  the crashed Small Scout, 1 to 3 aliens each) and 18 spawn points.
- The same map also holds its lights (47 point, 13 spot, a directional, a
  sky light), not yet read.

**Next (the plan, with what XCOM 2 offers):**
1. **Spawn Long War's pods at Enemy Within's pods** once the mission has
   begun on the EW map, the commander's pod first.
   - XCOM 2's `XComAISpawnManager.SpawnPodAtLocation(NewGameState,
     SpawnInfo, …)` spawns a pod of the given templates at a location.
     `XComGameState_AIReinforcementSpawner.SpawnReinforcements` shows the
     rest: a change with `BuildVisualizationForUnitSpawning` for the units'
     visuals.
   - Its alert step (`AlertAndScamperUnits`) is to be left out: a pod at
     the start doesn't know where XCOM is. The group's turn starts with
     `XGAIGroup.InitTurn`.
   - The EW coordinates are shifted by the placer's offset (the EW play
     area centred in the generated map's level volume).
2. **EW's lights** as movable XCOM 2 lights (point, spot), for the map's
   darkness.
3. **The landing spot** (two soldiers walled in on the truck stop) and a
   host plot of our own, as `hard-parts.md` left them.

## Report (2026-11-01, step 2: Long War's pods at Enemy Within's pods)

**When the whole EW map is placed in a mission, Long War's squad now
spawns at Enemy Within's pods** (`LWMissionSquads.SpawnAtEWPods`, called
by the tactical listener once the HUD is up).
- The placer keeps its shift from EW's coordinates to the mission's
  (`LWX2PartPlacer.EWShift`); each pod's location is shifted by it and put
  on the floor there.
- The aliens are those of the squad sent (`PendingSquad`), shared out over
  the pods in order, the commander's pod first.
- Each pod is spawned by XCOM 2's `SpawnPodAtLocation`, made visible by a
  visualization of our own (each unit's visualizer made and synced), and
  given its first turn by `XGAIGroup.InitTurn`.

**Checked in the game** (wingpu, `CSmallScout_Badlands`, a first-month
abduction): "pod LWX2_EWPod0 of 3 … spawned", Pod1 of 3, Pod2 of 2; the
enemies list showed 6 Sectoids and 2 ADVENT MECs, 17 to 39 tiles from the
squad. A screenshot showed the squad on the (dark) EW map.

### Decisions

- **Only pods with a Max above 0 are used**; all the map's pods if none
  has. EW's empty pods (Max 0) are placeholders its level designers left.
- **The commander's pod is first**, so it gets the squad's first alien, as
  Long War's squad lists its commander first.
- **No alert step**: a pod at the start does not know where XCOM is. This
  leaves out XCOM 2's reinforcement scamper (`AlertAndScamperUnits`).
- **Only once a mission, and only when no alien is alive on the field**, so
  a reloaded save or a second HUD init does not spawn a second squad.
- **The EW map stays off by default, in development too.** Pods spawn now,
  but the map is still dark and the drop spot can wall the squad in. The
  test machine's installed config turns it on for testing. It goes back on
  in development when the lights and the landing spot are done.

### Left open

- EW's lights; the landing spot; objectives at EW places.
- Pods use XCOM 2's stand-in templates until step 3.

## Report (2026-11-01, step 2: Enemy Within's lights; no squad concealment)

**EW's lights are placed with its map.** The converter reads every light
of the map (point, spot, its directional "sun", its sky light) with its
place, direction, radius, brightness, colour, falloff and cone, and writes
them to the map's ini (`+Lights=`). The mod spawns each as a movable light
when it places the whole map (`LWX2EWMapPieces.PlaceLights`).
- XCOM 2's movable light classes cannot be spawned at run time
  (`bNoDelete`), so the mod has its own: `LWX2PointLight` (no shadows),
  `LWX2SpotLight`, `LWX2SunLight`, `LWX2SkyLight`.
- A dominant light's properties come after its shadow map in the package;
  the converter now finds them there. Before, the sun read as Unreal's
  defaults.
- `CSmallScout_Badlands` is a night map. Its sun is a dim blue moon
  (brightness 0.5) and its sky is purple. Most of its light is orange
  point lights around the crashed UFO.

**Checked in the game** (wingpu, three missions on the badlands map):
- "60 of 62 lights placed" with points and spots only. The scene stayed
  dull grey.
- With the brightness ×3 and the moon and sky added, the drop area reads as
  a moonlit badlands, with the rock warm in the point lights' colour.
- The UFO, seen from close by with the new `look` test aid, is dark apart
  from its own glowing ports.

**No squad concealment** in campaign missions
(`X2DownloadableContentInfo_LongWarX2.OnPreMission` sets the battle's
`bForceNoSquadConcealment`, as XCOM 2's High Alert dark event does). Long
War has none, and its blue tint got in the way of judging the light (the
person's suggestion). The tint was gone in the next mission.

**Test aids:**
- `look <x> <y> [z]` / `look pod <n>`: the camera to a place on the placed
  EW map, with the fog of war off. Ground never seen is drawn black, which
  had made the first tries look empty.
- `LWX2_EWMAP=1 tools/test/sync-build.sh`: builds, then turns the whole
  EW map on in the installed config.

### Decisions

- **Brightness ×3, all four kinds of light** (`LightScale`, `LightKinds` in
  the generated ini), judged by eye on one map. EW's lightmaps also carried
  bounced light, which movable lights do not give, so the lights alone, at
  ×1, left the map grey.
  - The mission's own XCOM 2 sun and sky still light the map as well.
  - Both settings are in the generated ini, so they can be tuned without
    converting again.
- **Point lights without shadows; spots, the sun and the sky with
  XCOM 2's defaults.** A map has dozens of point lights, and EW baked
  their shadows.
- **No squad concealment in any campaign mission**, not only on EW maps.
  Long War has none. Phantom-style abilities of XCOM 2's classes would
  still conceal a unit, but Long War's classes do not have them.

### Found, left open

- **The campaign's squad held 'Stiletto', a Reaper** (War of the Chosen's
  starting faction soldier, with its own concealment). Long War has no
  factions. Fixed the same evening: a new campaign's faction soldier is
  replaced by a recruit, made as XCOM 2 makes the other starting soldiers
  (`ReplaceFactionHeroes`, in `InstallNewCampaign`). A new campaign then
  had 13 soldiers, all in Long War's classes and none of them a Reaper.
  - Decision: replaced, not just removed, so the crew keeps XCOM 2's
    starting number.
  - Still open: the hero's unit is only left out of the crew, not deleted.
  - Still open: faction soldiers XCOM 2 might give later (covert actions)
    are not handled; Long War's strategy layer gives no such rewards.
- The UFO's interior and its hull are dark; whether EW lit them by
  lightmap only or by lights not read (the `GeneratedMeshAreaLight`s,
  emissive surfaces) is not known yet.
- The landing spot; objectives at EW places.

## Report (2026-11-01, step 2: the pods move; boxed-in soldiers moved out)

**The pods spawned at EW's places did not move.** Three alien turns
passed with every alien on the same tile. XCOM 2's own pods, in the same
test with the EW map off, moved (two of three pods, 6 to 9 tiles in two
turns).
- The test aid now shows each alien's tile, whether it is floor, how many
  tiles around it can be entered, its AI data, its group and its action
  points. Our aliens stood on floor with open ground around them, but had
  **no AI unit data** (`-1`).
- The spawn manager makes none mid-mission. XCOM 2's reinforcements get
  theirs after spawning, in `XComGameState_AIReinforcementSpawner`.
- `SpawnPod` now creates it for each alien and rebuilds the AI player's
  list. It also gives the pod an encounter zone (16 × 16 tiles, holding the
  EW place; the offsets are found by trying with XCOM 2's
  `BuildEncounterZone` / `PointInEncounterZone`) and tells the AI's patrol
  groups of it.
- **Checked:** after two alien turns all three pods had moved 10 to 13
  tiles, towards the squad.

**Boxed-in soldiers are moved out** (`LWX2PartPlacer.FreeBoxedIn`, 3 s
after the HUD is up). Each soldier who can reach fewer than 40 tiles goes
to the free floor tile nearest the soldier who reaches the most, among the
tiles that soldier reaches. On the badlands map nobody needed it: the four
soldiers reached 529 to 656 tiles.

**Test aid:** `endturn` ends XCOM's turn as the button does.
`XGPlayer.EndTurn` always answers false, so the answer says nothing.

### Decisions

- **A 16-tile patrol zone around EW's place** rather than XCOM 2's
  36-tile default band. The pod stays near where EW's designers put it
  until it sees XCOM, or until XCOM passes it (XCOM 2's intercept rule).
- **The boxed-in fix moves soldiers after landing**, rather than choosing
  their tiles before the units exist. XCOM 2's group spawn picks the tiles
  itself, and two earlier tries to pick a spot beforehand did not see what
  walled the two in (`hard-parts.md`).

## Report (2026-11-01, step 2: the truck stop; pods in sub-levels)

**Long War's truck stop (`URB_TruckStop`) keeps its pods in its
sub-levels**, which the converter did not read:
- the main map: 4 abduction pods (`XComAlienPod_Abduction`);
- `_Stream`: 4 pods;
- `_EWI` (Enemy Within's abduction variant): 4 abduction pods;
- `_CNH`: 2 pods.

The converter now reads the pods from the map's sibling packages as well,
each noted with its level (`Level=Stream`, `EWI`, `CNH`; `Abduction` for
the map's own abduction pods). The mod uses the map's own ordinary pods
and `_Stream`'s first, then the abduction ones, then any.
- Checked: 4 pods spawned on the truck stop, the squad of 9 shared out over
  them.
- The truck stop's lights: 21, with a warm low sun (brightness 4).

**The converter ran out of memory on the truck stop** (12 GB heap) after
the sun change. Reading tags at every offset of a component made bogus
arrays. It now tries only dominant lights' components, and only offsets
that start with a property name.

**The boxed-in fix waited for the soldiers' paths.** Three seconds after
the HUD came up, every soldier still reached 1 tile. The check is now
repeated every 3 seconds (on a looping timer on the HUD screen; a timer on
`WorldInfo` never fired) until the best soldier reaches 40 tiles, for a
minute at most.
- Reproduced once: two soldiers reached 14 tiles, inside a rectangle with
  no visible wall. Most likely it is EW's Skyranger beside the drop zone,
  or a hidden XCOM 2 volume.
- The first version of the fix found no free tile.
  `XComWorldData.IsTileOccupied` counts more than units, so only the tiles
  units stand on now count as taken.
- In the six truck stop missions that followed, nobody landed boxed in, so
  the move itself is still untested in a real landing. The `unbox <min>`
  test aid runs the check at a higher threshold.

**Found, left open: XCOM 2 crashes now and then while loading a mission
map.** It is an access violation at the same address every time
(`XCom2.exe+0x6d0695`), at `LoadMap`, before any of the mod's placing,
with memory to spare (23 GB free).
- It happened twice with the truck stop placed. The third time, later
  that night, the EW map was off entirely, so it is not the truck stop or
  the EW map.
- About 3 in 25 mission loads that night, on three plots
  (`Plot_TWN_Guerilla_MdObj_Ravine`, `Plot_TWN_GOps_Cemetery_02`,
  `Plot_SLM_Guerilla_MdObj_Overpass`).
- The last lines before it are XCOM 2's own warnings about a missing
  encounter list (`LIST_TheLost_PrePlaced`), which also appear in loads
  that succeed.
- Not yet known: whether the game did this before the mod's work of that
  night, or with the mod off.
- The test machine is back on the badlands map. The truck stop's config
  is kept beside the checkout (`lwx2-truckstop.ini`).

## Report (2026-11-02 night, Long War's win: every alien dead or taken)

**A mission from Long War's Geoscape is now won when the aliens that came
are all dead or taken.** None may be alive on the field, after at least
one was there (`CheckSwept`, every 2 seconds from the tactical HUD). The
mission then ends as the test button ends it: XCOM 2's objectives marked
done, `EndBattle` for XCOM.
- XCOM 2 leaves victory to each mission's kismet, which on an Enemy
  Within map has nothing to act on. Before this, EW-map missions could
  only be ended by the test button.

**Checked in the game** (an abduction, XCOM 2's map; the aliens killed by
XCOM 2's `KillAllAIs` cheat): "all 14 aliens dead or taken: the mission is
won", the mission summary, back to the Avenger. On Long War's Geoscape:
"The aliens killed (14) left: 14 weapon fragments, 3 elerium, 3 alloys,
3 meld, 11 Sectoid Corpse, 3 Drone Wreck. The abduction's reward: §90.
The mission in France succeeded."

**Found and fixed on the way: XCOM 2 stopped when leaving a mission**
("World UMS_MissionCore.TheWorld not cleaned up by garbage collection").
The tactical listener lives on after the mission, and it held the HUD
screen for its timers (this check's, and the boxed-in check's). It now
holds no screen and looks the HUD up when a timer is to be cleared.
- The player's preview build of that night (270fcb8) has only the
  boxed-in reference, which is set only with the development EW map on
  (off in the player's config).

### Decisions

- **The rule applies to every mission sent from Long War's Geoscape**, on
  XCOM 2's maps too: Long War's abductions, crashes and landings are won by
  clearing the aliens.
  - XCOM 2's own objectives can still end a mission first, or fail it:
    their timers, for one.
  - Units of other teams (the Lost, civilians) are not counted.

**The same loop on Enemy Within's map** (the badlands placed whole, the
development switch on): Long War's squad spawned at EW's pods. The boxed-in
check waited for the soldiers' paths (7 tries) and found nobody boxed in
(the best reached 670 tiles). With all 7 aliens killed the mission was won.
On the Geoscape: "The aliens killed (7) left: … The abduction's reward:
§80. The mission in Russia succeeded." It was the first EW-map mission
played to its end and counted by Long War's campaign.

## Report (2026-11-02 night, no turn limit)

**XCOM 2's mission timer is suspended for the whole of a Long War
mission** (`NoTimer`, at the HUD's start). Long War's missions have no turn
limit, but XCOM 2's mission types brought theirs ("Container Detonation",
"Data Transfer"), which could fail a mission. The timer is suspended the
way War of the Chosen suspends it while the squad is concealed
(`XComGameState_UITimer.SuspendTimer`). Missions whose timer is their point
refuse it (XCOM 2's `DisallowUITimerSuspension`).
- **Checked:** "Data Transfer: 9 turns until completion" at the start, and
  still 9 after two turns ended. Log: "XCOM 2's mission timer suspended".

### Decisions

- **Suspended rather than removed.** XCOM 2's own mechanism, so its timer
  display and its kismet stay consistent.

## Report (2026-11-02 night, no sitreps, no Chosen)

**A mission from Long War's Geoscape has no sitreps and no Chosen.** Before
this, XCOM 2's sitreps could come with it: one test mission had "SITREP:
The Lost", and a Lost swarm was drawn by a grenade.
- No sitreps from the mission source (`bForceNoSitRep` before
  `BuildMission`).
- The sitreps the plot forces (the Lost on abandoned cities) and the
  mission's gameplay tags (which bring the Chosen and a sitrep's units) are
  cleared after it.
- **Checked** in two missions: only aliens (team 16), plus the slum
  map's civilians (team 1); no sitrep on the HUD.

### Decisions

- **The mission's gameplay tags are cleared whole**, not one by one. Only
  sitreps and the Chosen put tags there; Long War has neither.

## Report (2026-11-02 night, Long War's squad size)

**A mission takes Long War's squad of 6** (`SKYRANGER_CAPACITY`, now in the
strategy config as `SkyrangerCapacity`), not XCOM 2's 4. The Officer
Training School's Squad Size I and II (+1 each) wait for the school.
- **Checked:** "launching Hack_ADV on Plot_TWN_Guerilla_LgObj_Boulevard
  with 6 soldiers"; all six landed and could act.

**The Officer Training School's Squad Size I and II** (`OTSBalance`): a
soldier more each, at §200, once the barracks' ranks add up to 40 and 115
(Long War's count: rookie 0, squaddie 1 …).
- They are bought from a line in the base screen (once the school is
  built) or with the `ots` test aid.
- The campaign keeps how many were bought (`SquadSizesBought`).
- The school's officer projects (Long War's officer ranks and their
  abilities) are not ported.

**Checked:** with the school placed and the ranks at 24, the line read
"squad 6 -> 7, §200 (needs ranks adding up to 40 (now 24))". With the ranks
raised to 48 (XCOM 2's `LevelUpBarracks` cheat) it was bought: "squad size
7", and the next needed 115. A mission after that: "launching ProtectDevice
… with 7 soldiers", all seven on the field.

**The boxed-in fix in a real landing** (the badlands, later that night):
one soldier reached fewer than 40 tiles. On the fifth try, once the
soldiers' paths were known, she was moved: "soldier Estela Suárez boxed in,
moved to tile 75,25,1 beside Fergus Clark (who reaches 684 tiles)". Her
reach after the move was not measured: the mission ended by the cheat
first. The same run went on to "The mission in United States succeeded" on
the Geoscape.

In the next such landing it was measured: "soldier Paul Johnson boxed in,
moved to tile 76,27,13 beside Ella Willems (who reaches 655 tiles)", and 28
seconds later every soldier reached 411 to 660 tiles.

## Report (2026-11-02 night, XCOM 2's mission for Long War's kind)

**A Long War mission now plays the XCOM 2 mission closest to its kind**
(`UILWHeadquarters.SourceForKind`):
- a crash site or landed UFO: XCOM 2's landed UFO (`MissionSource_LandedUFO`,
  "Secure the UFO");
- a terror site: XCOM 2's retaliation (`MissionSource_Retaliation`, its
  "Terror" mission, with its civilians); War of the Chosen's Chosen
  retaliation is excluded;
- an abduction and the rest: a guerrilla op, as before.
- The reward is the one XCOM 2 pairs with the source (`Reward_None`; a
  guerrilla op keeps the empty supplies reward).

**Checked** (a new campaign run on until its first terror site, in China):
"launching Terror on Plot_SHN_Terror_HighwayAssault with 6 soldiers". The
mission read "Rescue at least 6 Civilians from Alien Forces", with 15
civilians and Long War's squad of 12. Won by clearing (cheat). Back on the
Avenger: "The aliens killed (12) left: … 4 Chryssalid Carcass, 8 Floater
Corpse. The mission in China succeeded." XCOM 2's retaliation code at the
mission's end did no harm.
- The first try crashed at the map load: the known crash (`+0x6d0695`), now
  4 in about 35 loads.

### Decisions

- **A terror mission is won by clearing the aliens, as the others are.**
  Long War's terror rewards depend on the civilians saved, which XCOM 2's
  mission counts; feeding that count to Long War's result is left open.
  (Done since: "the civilians of a terror mission", below.)

**Landed UFO checked, and a gap found and closed.** A landed Transport
became "launching SecureUFO on Plot_WLD_UFO_Ravine": "Neutralize all
enemies guarding UFO", on a UFO plot. Won by clearing; back on the Geoscape:
"The aliens killed (20) left: … 6 Outsider Shard … The mission in United
States succeeded."
- **But only 10 of the squad of 20 had been on the field.** XCOM 2 places
  a pod whole or not at all, and its pods are made for fewer aliens than
  Long War's squads share into them ("Unable to find valid spawn location
  for the ENTIRE group 'OPNx3_Standard'", twice).
- **Now `LWMissionSquads.TopUp`**, at the HUD's start on XCOM 2's maps,
  spawns those who did not come as pods of up to 4 beside aliens already on
  the field (with AI data and a patrol zone, as the EW-map pods).
- **Checked:** "7 of Long War's squad of 20 did not come … spawned beside
  the others", two pods spawned, and 20 aliens on the field.

### Decisions

- **The missing ones are taken as the squad's last.** Which pod failed is
  not known; the squad is shared out in order.
- **Placed beside aliens already there**, not at the failed encounter's
  place. XCOM 2 found no room there.

## Report (2026-11-02 night, no reinforcements)

Long War's missions have no reinforcements. XCOM 2's arrive by its
missions' kismet, through `XComGameState_AIReinforcementSpawner` (a pod and
a countdown in turns).
- **Now `NoReinforcements`**, in the tactical listener's 2-second check on
  Long War's missions: a spawner waiting to land (countdown 1 to 89, nobody
  spawned yet) gets its countdown put to 99, with a log line.
- **Checked, in a landed UFO** (a new campaign, UFOs intercepted until
  "ASSAULT: landed UFO in United States"; Secure the UFO, 20 aliens with
  the top-up): kismet logged "Critical reinforcements queued" at the start,
  and then "No RNF call queued" each turn for 14 turns. The mission's
  "Distress Beacon: turns until alien response" is XCOM 2's mission timer,
  already suspended ("Mission timer is currently suspended"): it stayed at
  6, and its reinforcements never came. The aliens stayed at 20. Won by
  clearing (cheat): "all 20 aliens dead or taken".
- **So the new guard did not fire here.** It stays for missions whose
  kismet sets a spawner without the timer; none has been seen yet.
- The test aid `endturn` reported "the turn could not end" while the turn
  ended (the game's answer is false either way): it now says only that the
  end was asked.

### Decisions

- **A guard rather than a change to the missions' kismet.** The kismet is
  XCOM 2's; holding the spawner back is the one place all of its
  reinforcements pass through.
- **A spawner whose countdown is already 0 is not caught**: it lands in the
  same turn it is made. If one is seen, the next step is to remove its pod
  as it lands.

## Report (2026-11-02 night, the civilians of a terror mission)

A terror mission won now moves panic as Long War's does. Read from its
`XGStrategyAI.ApplyMissionPanic` (terror) and `CalcTerrorMissionPanicResult`:
- **Won:** the country panics by the civilians lost × `PANIC_TERROR_COUNTRY`
  (2), its continent by the civilians lost × `UFO_LIMIT` (1; the ini's
  comment says so). **With no civilian saved, the country leaves the
  council** all the same.
- **Lost:** the country leaves, the continent +20. The port did this
  already (`SiteIgnored`).
- A country gone already (Long War's secret pact) moves only its
  continent. Long War does not spare the home country.

How:
- **`CountCivilians`**, in the tactical listener, when the mission summary
  opens on a Long War terror mission. It counts the civilians with a pawn
  in this mission (the dead keep theirs) and those alive. Faceless posing
  as civilians (`FacelessCivilian`) are left out. The count goes to
  `PendingCivilians` / `PendingCiviliansSaved`, added to the history
  directly: the tactical rules take no changes after the game's end.
- **`TerrorWon`**, on the way back. A mission won without playing it
  (WIN, resolve) has no count (−1) and changes no panic.
- Config: `PanicTerrorCivilianCountry`, `PanicTerrorCivilianContinent`
  (generated from the Tree's samples).
- **A new test aid, `killaliens`**: XCOM 2's `KillAllAIs` kills the
  civilians too (they are the AI's, the SDK shows). The first test with it
  read "0 of 13 civilians alive", and the United States left the council.

**Checked** (a new campaign, terror in France; three alien turns, then
`killaliens`): "terror mission over, 11 of 13 civilians alive". Back on
the Geoscape: "11 of 13 civilians saved in France. The mission in France
succeeded." France's panic went from 88 to 94: 2 lost × 2 for the country,
plus 2 × 1 for the continent, which reaches each of its countries
(`AddContinentPanic`, as EW's).

### Decisions

- **Counted when the summary opens**, not at each death. The summary
  comes for every ending (won, lost, evacuated), and the tally is then
  final.
- **Alive means saved.** Long War's civilians are saved unless killed;
  XCOM 2's rescue (a soldier beside them) is not required.
- **A count of none is not "none saved".** Without a count, the country
  does not leave.
- **Long War's monthly terror tallies** (`iTerror`, `iTerrorThwarted`, for
  the council report) are not kept: the port's council report does not
  show them yet.

## Report (2026-11-02, Enemy Within's maps chosen per mission)

Toward EW's maps as the missions' ground (the person's request: playable
first, the maps a big part of it). The pipeline held one converted map at a
time; now it holds many and picks one per mission.
- **Long War's map list, generated** (`scripts/maps-config.mjs` →
  `Config/XComLWEWMaps.ini`, from stock Long War's `DefaultMaps.ini`): every
  map in rotation for an abduction (44), a crash site (39), a landed UFO
  (21) or a terror site (22), with its ship and whether it is a night map.
  Long War lists its five new ships by number, the same maps again
  ("LSmallScout_River (Fighter)"), so each ship has its own maps; the
  Tree's ship images confirm the hulls (Fighter = Scout's, Raider =
  Destroyer's, Harvester = Abductor's, Terror Ship = Transport's, Assault
  Carrier = Battleship's).
- **One section per converted map** (`LWX2EWMapData`, per-object config;
  `ew-map.ts` writes `[<map> LWX2EWMapData]`), joined by the new batch
  converter **`tools/convert/ew-maps.ts`** (`--all`, `--kind <Kind>`, or
  names; work files in `BuildCache/ewmaps`). The shared settings (lights,
  material parents) moved to the generated, committed `XComLWEWMaps.ini`.
- **At launch** (`UILWHeadquarters`), with the EW-map switch on: a converted
  map Long War lists for the mission's kind and ship, at random
  (`LWX2EWMapPieces.ChooseMap`), kept in the campaign
  (`PendingEWMap`). A kind with no converted map plays XCOM 2's plot as
  before. The tactical side places the mission's map (`Map()`, `HasMap()`).

**Checked** (the test machine; four maps converted in 2 to 3 s each,
114 to 302 MB: CSmallScout_Badlands, LSmallScout_River, URB_Bar,
URB_CommercialAlley_Terror): a first-month abduction chose "URB_Bar",
loaded it, placed 880 pieces (8 meshes not found), and spawned Long War's
squad of 8 at 4 of EW's pods. After the boxed-in check the best soldier
reached 510 tiles.

### Decisions

- **Long War's own list decides** which maps a kind and ship may have; at
  random among those converted.
- **Without a converted map, XCOM 2's plot**: a player who converted only
  some maps still plays every mission.

### Found, left open

- **URB_Bar looked wrong**: surfaces as grey noise, and one EW light (a
  street lamp, at the ×3 brightness judged on a day map) flooded the
  squad's area orange. Per-map look: textures and night lighting.
- The switch is still a development setting; the player's build neither
  converts maps nor turns it on.
- Package size (114 to 302 MB a map) and loading time; a texture cache of
  our own would shrink them.

## Report (2026-11-02, the crash at mission load: found and fixed)

**XCOM 2 died now and then while loading a mission map** (`XCom2.exe+0x6d0695`,
first seen 2026-11-01 21:40 UTC). Found, and fixed in our launch.
- **The pattern** (the test machine's 124 kept campaign launch logs): 5 of
  them end at `LoadMap`, each on a different plot; all five were campaign
  launches from our headquarters screen. Quick launches never crashed.
- **The dump** (Windows' local crash dumps turned on for XCom2.exe on the
  test machine): a null object (`rcx` 0) in a small engine helper, called
  from a function that handles a Wwise callback of type 8 (a sound's
  duration) and walks every cinematic sound track
  (`InterpTrackInstAkEvent`). The callback is registered with Wwise's
  `PostEvent` (flags 9). So a sound posted from a cinematic (or a voice)
  calls back on the audio thread while the old world is torn down, and
  the engine reaches for the world. Three more dumps: the same address and
  caller.
- **Our launch** went straight from our screen into the tactical battle
  in the same frame, with the Avenger's cinematics running (16 of them at
  a launch). XCOM 2's own launch leaves the Avenger view first.

**Tested** (the test machine, new campaigns launched into their first
abduction, `crashloop.sh`):
- as before: 1 crash in 20 (and 5 in 124 in the logs);
- Long War's squad not written into XCOM 2's encounters: 0 in 20 (the
  first suspect; not the cause, as the dumps say);
- a narrative voice started at launch, no delay: **3 in 15**;
- the same with a 1.5 s delay alone (the voice still playing): 2 in 20;
- **the same with the fix: 0 in 20.**

**The fix** (`UILWHeadquarters`): the mission is prepared, then after
0.5 s voices are stopped (`StopConversations`) and every running cinematic
is stopped (`SeqAct_Interp`'s Stop input), and the map loads 1.5 s later
(`LaunchDelay`). The test voice is a development switch
(`TestVoiceAtLaunch`, off).

### Decisions

- **Stop what plays, then wait**, rather than avoid launching from the
  Avenger: the port's headquarters screen stays where it is.
- **`SquadsInEncounters` stays** as a switch (on): the test cleared it.

### Left open

- The rate after the fix rests on 20 runs under the provoked condition;
  more campaign play will tell. The crash dumps stay on for the test
  machine.

## The person's review (2026-11-02, recorded by the agent)

- Terror missions: **civilians alive at the end count as saved** (as
  built).

## Report (2026-11-02, Enemy Within's maps as missions of their own)

The person, on the first build with EW maps: "a weird second layer of
xcom2 stuff in addition to a haze and not being very bright"; "why is there
a host mission?"; "can we not convert the maps into proper missions in
their own right?"; and "it only requires an editor step if we are not able
to replicate whatever the editor does".

**An EW map is now the whole mission, with no editor step and nothing
shipped.** The host was never needed for the map, only for what XCOM 2
asks of a mission: a plot (a level volume, a spawn, a parcel), a lighting
map and a mission def. XCOM 2 builds tiles, cover and paths from geometry
itself, so a map package of our own adds nothing the pieces do not. What
had leaked through was the host plot's own content and its weather. Now:
- **The plot: XCOM 2's empty test plot** (`Plot_WLD_Test_Lg`, cooked in
  every retail install: a level volume, a spawn, one parcel and 13 ground
  pieces), set as the mission's plot at launch
  (`UILWHeadquarters.UseEWPlot`, `EWPlot` in `XComLWAirWar.ini`).
- **Its volume stretched to the EW map** (`LWX2PartPlacer.FitVolume`):
  the plot's volume is 36 × 36 tiles. Before placing, it is scaled to
  EW's play area plus two tiles each side and XCOM 2's tile grid made again
  for it (`BuildWorldData(Volume)`). The volume is a static actor; scaling
  its draw scale works all the same. Seen: 36 × 36 → 48 × 42 (URB_FastFood,
  45 × 39), → 53 × 47 (URB_Demolition_EWI, 50 × 44).
- **The light: a clear day.** The mod's new `Config/XComMaps.ini` gives
  that plot a lighting map of its own (`EnvLighting_Day_Arid`). XCOM 2
  prefers a plot map's own lighting over its type's, so no rain map
  (Wilderness can have one), no weather fog.
- **The mission: XCOM 2's test mission** (`TestMission`, made for test
  plots: kismet `Obj_Test`, `NullSchedule`, no timer, no objective items),
  except on a terror site, whose XCOM 2 retaliation brings and counts the
  civilians. Long War's aliens stand at EW's pods as before, and Long War's
  rule (every alien dead or taken) ends the mission.
- **The objective list shows Long War's objective**
  (`UIScreenListener_LongWarX2Tactical.LongWarObjectives`): "Kill or
  capture every alien" in place of XCOM 2's, whenever XCOM 2's kismet
  writes its own. Not on a terror site.

**Checked** (the test machine, three campaign abductions, screenshots):
- With the test plot and the day light (URB_HighwayFallen): no rain, no
  fog, no XCOM 2 props around the map. But the 36 × 36 volume cut the map
  off: "There are no valid spawn locations", and the aliens could reach
  one tile.
- With the stretched volume (URB_FastFood): the map fits, and Long War's
  squad of 9 stood at 6 EW pods. XCOM 2's guerrilla op still brought its
  objectives and a "Container Detonation" countdown.
- With the test mission and Long War's objective (URB_Demolition_EWI):
  "launching TestMission on Plot_WLD_Test_Lg", Long War's squad of 11 at
  4 EW pods, "the objective list shows Long War's objective", no soldier
  boxed in (the best reaches 268 tiles). On screen: the EW map alone, in
  daylight, with only "Kill or capture every alien" listed and no timer.

### Decisions

- **XCOM 2's own test plot and test mission**, not a plot of our own made
  in the editor or written as a package: they are in every install, they
  do what a host has to do and nothing more, and the volume can be fitted
  at run time. A plot of our own stays the fallback if a patch removes them
  (the launch falls back to an outdoor plot when `EWPlot` is not listed).
- **One lighting map for now, a clear day**: brightness first, as the
  person asked. EW's night maps (80 of the 126) are played in daylight too;
  night lighting comes with each map's look.
- **Terror sites keep XCOM 2's terror mission and its objective list**:
  the civilians count toward Long War's result.

### Left open

- **Each map's look**: surfaces are glossy and washed out (the stand-in
  materials' parents and parameters). One EW street lamp at ×3
  (`LightScale`, judged on a darker host) still floods its corner orange
  under the day light.
- A terror site on an EW map still plays on the test plot with XCOM 2's
  terror mission: not yet seen.
- Night: a night lighting map for EW's night maps, once they look right.

## Report (2026-11-02, the maps' look: no gloss; a spawn on a highway's deck; interiors)

**EW's surfaces no longer look wet and grey.** The stand-in materials'
parent (`Materials.Approved.Props_SD`) has a `Masks` texture (XCOM 2's
packed specular, roughness and metal) that nothing of EW's fills. Its
placeholder made every surface glossy, speckled white and washed out.
Compared live on URB_HighwayFallen with two new control-port aids
(`ewmat <parameter> <value>`: a parameter on every stand-in;
`ewlight <kind> <scale>`: EW's placed lights by kind), each from the same
camera:
- `SpecularScale 0`: the sheen and speckle gone, the colours back (the
  taxi yellow again). Roughness ×4 changed nothing more after it.
- A black `Masks`: everything darker. A white one: brighter but tinted
  (the taxi pink, as metal). So the placeholder stays.
- EW's own lights (its sun, its sky, 74 point and 9 spot lights) at 0 or
  a third: hardly any difference under XCOM 2's daylight.
- Now **`StandinScalars`** in `XComLWEWMaps.ini` (generated):
  `SpecularScale` 0 on every stand-in.

**A drop zone above the ground** (URB_HighwayFallen: on a highway's deck,
400 units up): the spawn search looked for open ground at EW's lowest
floor, found none ("no open ground near the drop zone") and put the squad
under the bridge, where every unit could reach one tile. It now looks at
the drop zone's own floor. Checked: "spawn on open ground 0 tiles from the
drop zone", the squad on the deck, the best soldier reaching 503 tiles.
(The first test-plot run had not shown it: there the floor happened to
read higher.)

**Found: interiors are hidden under their roofs.** URB_OfficePaper_EWI (an
office) was placed and walkable (the best soldier 535 tiles, 12 aliens at
4 pods), but the screen showed only the roof. XCOM 2 cuts roofs and upper
floors away inside its building volumes, and the placed pieces have none.
The next step: EW's levels carry their building volumes with their floors.
The converter can read their bounds, and the mod can spawn XCOM 2 building
volumes from them. A volume is a brush, but the plot's level volume is a box
brush that can be stretched (as the level volume itself now is), so its
brush can serve.

Also new: `ForceMap` (`XComLWEWMaps.ini`, development): one converted map
for every Long War mission, to look at a given map.

**Checked** after the change (a random abduction: URB_SmallCemetery): the
volume stretched to 38 × 49, the spawn on open ground, Long War's
objective, the best soldier reaching 469 tiles. On screen: matte surfaces
with their colours, no speckle.

### Left open

- Interiors: building volumes from EW's (above).
- The scene is still on the dark side on several maps (dark asphalt under
  a noon light); a brighter lighting map or exposure to try.
- A terror site on an EW map: not yet seen.

## Report (2026-11-02, Enemy Within's maps as real XCOM 2 plots)

The person, on the hiding and the test plots: "why do we not build a
proper plot instead of trying to hack it in?" and, on the choice between
one plot of our own with the map placed at run time and a real XCOM 2 map
per EW map: "lets do option 2 … it will make life so much easier from that
point on".

**An Enemy Within map is now a real XCOM 2 plot**, written on the player's
machine from the converted map, and XCOM 2 loads it as it loads its own
(`LoadMap: LWX2_URB_HighwayFallen`).
- **A template plot of our own** (`tools/maps/LWX2_EWPlotTemplate.umap`):
  made in the SDK editor from T3D text we write (`tools/maps/template.py`:
  a box level volume, a group spawn, a parcel slot, and one sample each of
  a level actor with its mesh component, a movable point light and a
  movable spot light), pasted into a blank map, its geometry built, saved.
  The editor's save builds its tile grid (32 × 32 × 18). And an empty
  parcel map (`LWX2_EmptyParcel.umap`), so XCOM 2's objective parcel brings
  nothing into the plot.
- **The plot writer** (`tools/convert/ew-plot.ts`) clones the template's
  samples, with their properties set, for each EW piece (an
  `XComLevelActor` and its `StaticMeshComponent`: mesh, place, rotation,
  scale, materials; backdrop pieces without collision), each EW material
  (a `MaterialInstanceConstant` of the XCOM 2 parent for its kind, with
  EW's textures, the white mask and no specular), each EW point and spot
  light, and each drop zone (a group spawn). It sizes the level volume and
  the tile grid to EW's play area (two tiles to spare on each side, on EW's
  floor) and writes the level's actor list. upkit writes the package (a
  new GUID each).
- **The converter nests EW's carried packages in the map's package**
  (`ew-map.ts`: their forced-export flag cleared). `Qighway_B.Meshes.X` is
  now `URB_HighwayFallen.Qighway_B.Meshes.X`, so a plot imports it the
  ordinary way, by loading the map's package. The config paths it writes
  carry the prefix.
- **Our own plot type, parcel, mission and light** (`Config/XComPlots.ini`,
  `XComParcels.ini`, `XComMissionDefs.ini`, `XComMaps.ini`): plot type
  `LWX2_EW`; mission `LWX2_EWMission` (XCOM 2's test kismet `Obj_Test`,
  `NullSchedule`, no timer or items); a clear day for the type.
- **The mod** launches onto `LWX2_<map>` when it is listed as a plot
  (`UILWHeadquarters.UseEWPlot`). On it, nothing is placed or hidden: the
  pods stand at EW's coordinates (`LWX2EWMapPieces.OnOwnPlot`). Without a
  plot for the map, the template with the run-time placement is the
  fallback.
- On the test machine `tools/test/build.ps1` links `tools/maps/*.umap` and
  the generated plots into the built mod and lists the plots.

**Checked** (the test machine, URB_HighwayFallen reconverted and its plot
written: 786 pieces, 87 stand-in materials, 83 lights, one drop zone,
24 × 72 × 14 tiles, 650 KB; a campaign abduction): "launching
LWX2_EWMission on LWX2_URB_HighwayFallen"; the map loaded in about 11 s,
where the run-time placement took over 30; "on its own plot"; Long War's
squad of 7 at 4 EW pods; Long War's objective; no soldier boxed in, the
best reaching 482 tiles. On screen: the EW map with the squad on the
highway's deck.

### Decisions

- **Clones of samples from an editor-made template**, not a level written
  from nothing: the editor makes the parts whose format is hardest (the
  level, the world, the volume's brush and its generated mesh, the tile
  grid's record), once; the writer only adds actors and sets properties.
- **The plot imports EW's content from the converted package** rather than
  holding it: one converted package per map as before, a small plot
  (hundreds of KB) beside it.
- **EW's sun and sky lights are not written**: XCOM 2's lighting map
  lights the plot. EW's point and spot lights are, without shadows.

### Left open

- The setup program does not write plots yet, and maps converted by an
  earlier setup must be converted again (nested packages): the next step.
- EW's lights at ×3 tint the squad orange under XCOM 2's sun.
- Warnings: the template references editor-only packages (`UI_Cover`) the
  retail game does not have; no mission template for `LWX2_EWMission`
  (`GetMissionSquad`).
- Terror sites on our mission bring no civilians yet (EW's civilian spawn
  points to use); interiors' roofs (building volumes, now authorable in the
  plot); EW's destructible pieces as XCOM 2 destructibles.

## Report (2026-11-02, plots in the player's setup)

**The setup program now makes every converted map a plot of its own.**
- The batch converter (`ew-maps.ts`) writes each map's plot after
  converting (`writePlots`; the stand-ins' parents and parameters and the
  lights read from the mod's `XComLWEWMaps.ini`; EW's lights at
  `PlotLightScale` 1 under XCOM 2's sun). The setup lists the plots in the
  installed `XComPlots.ini`; the release ships the template plot and the
  empty parcel in the mod's `Content`, and a reinstall keeps them beside
  the kept conversions.
- **Older conversions are redone**: each map's section records the
  converter's version (`; ew-map.ts 2`). A section of an older version is
  converted again when maps are wanted, and has no plot until then (its
  map is placed at run time, as before). So the person's maps will be
  converted once more by the next setup with maps.
- The writer indexes names and imports: 0.1 s a plot (the first version
  took about 10 s, a quadratic lookup; a full setup took 21 minutes).

**Found on the way**
- **The release had been built from stale code**, twice today:
  `package.sh` checked out the commit on the test machine, but files a
  development sync left there blocked the checkout without the script
  noticing, and the build was of the old commit. It now cleans the
  checkout and refuses to package unless the test machine is at the commit.
- **The empty parcel was registered as small**; the template's slot is
  32 × 32 tiles, which XCOM 2 counts as large, so no parcel fitted and the
  game crashed generating the map ("Map package does not exist"). Now
  large. Why the first plot test (URB_HighwayFallen) passed with it is not
  known: its log was overwritten.

**Checked** (the release zip unpacked on the test machine, the mod
uninstalled, its setup run with `--maps`: 83 maps converted and 83 plots
written in 230 s; then a campaign abduction): "launching LWX2_EWMission on
LWX2_URB_CommercialRestaurant", "on its own plot", Long War's squad of 11
at 2 EW pods, Long War's objective, the best soldier reaching 382 tiles.
On screen: the EW street with its own colours, no orange cast.

### Left open

- Interiors and overpasses: the roof or the deck hides the squad
  (URB_OfficePaper_EWI, URB_StreetOverpass). Next: EW's building volumes
  and floors, read by the converter, written into the plot as XCOM 2
  building volumes (a sample to add to the template).
- Terror sites: civilians at EW's civilian spawn points.
- No mission template for `LWX2_EWMission` (a warning).

## Night log (2026-11-02 to 03, written as it happens)

The person, on the build with real plots: the first mission
(Gatecrasher) still runs the old way; missions from the Geoscape crash
more often than not; the one that did not crash is "mostly black and
white" (fog of war), "the big building in the middle is clearly missing
pieces and … the sides should have big windows". Their crash log: the
game dies right after the battle starts, as Long War's pods are spawned
at EW's places (`SpawnAtEWPods`), on `LWX2_CSmallScout_Marshlands` (a
crash site).

Order for the night, by what blocks playing first: the crash; the fog;
the first mission on an EW plot; the missing pieces (glass and other
materials without a stand-in); then building volumes (roofs), terror
civilians.

- **20:55, the crash.** Not reproduced on the test machine (the same map,
  a crash site, release build: the mission ran, 9 aliens at 3 pods). The
  person's crashes all came at the same moment: right after the mod set
  the fog of war at the battle's start (`Fog`, which they had on "never
  seen shown as seen"), before any pod spawned. Changing the fog while its
  own thread draws it is the likely race (more often than not on their
  machine, never on the slower test machine). **Decision:** the fog is set
  only at the dropship briefing, before the battle, and only what differs
  is written; with the default now off, nothing is. And pods are kept
  inside the tile grid (`SpawnPod`), in case a pod of EW's stands beyond
  the plot's grid. To confirm with the person's crash dumps (asked for).
- **The fog's look.** "Never seen shown as seen" made everything grey (XCOM
  2 draws ground seen before desaturated). **Decision:** off again
  (XCOM 2's own fog); a live aid (`fog <never> <seen> <0|1>`) to compare
  levels on screen.
- **Missing pieces and windows.** 1158 of 9472 EW materials across the 83
  maps have no diffuse map, so no stand-in: glass, skies, markers,
  decal-like effects (road paint, puddles, scorches), alien machinery. The
  plot used the EW material itself, which XCOM 2 cannot draw.
  **Decision** (`ew-plot.ts`): glass and windows become translucent panes
  (`Materials.Approved.Translucent_SD`, white, opacity 0.35); markers,
  skies and decal-like effects are not written (an opaque stand-in would
  draw them as slabs; XCOM 2's lighting map brings its own sky); anything
  else a plain grey stand-in (the prop parent, white tinted grey).
- **21:00, the first mission.** XCOM 2 makes its first mission with the
  campaign; Long War counts its own first mission as won before the
  campaign (the loot when its Geoscape opens), so the two stay apart.
  **Decision:** the first mission is played on an EW abduction map's own
  plot with our mission (`X2DownloadableContentInfo.FirstMissionOnEWMap`,
  in `InstallNewCampaign`), and Long War's first mission squad (its three
  Sectoid pods) stands at EW's pods (`LWMissionSquads.SquadNow`; Long
  War's state does not exist yet). The map is known from the plot's own
  name in the mission (`LWX2EWMapPieces.MapName`). Checked so far: the
  campaign's start sets it ("the first mission on
  LWX2_URB_CommercialRestaurant with LWX2_EWMission"). Not yet seen in
  play: the control port's campaign start stops at the intro's event
  notice (a test path problem, not the player's); to drive through the
  real menus.
- **21:00, roofs.** EW's buildings carry building volumes with floors, and
  each floor lists floor volumes (box actors; EW works out the heights at
  run time), as XCOM 2's do. The dockyard has 9 buildings, 20 floors.
  **Decision:** the converter reads them (`+Buildings=` with each floor's
  box); the plot writer adds an `XComBuildingVolume` per building and an
  `XComFloorVolume` per floor, reusing the template's box brush, scaled.
  XCOM 2's own building visibility then cuts roofs and upper floors away.
- **21:15, roofs, first look.** With the building and floor volumes in the
  plot alone, nothing changed: the dockyard's big building kept its roof.
  XCOM 2 links building and floor volumes as a map loads (`InitVolumes`),
  but which actors belong to which floor is made in the editor for a plot.
  **Decision:** on our own plots the mod has each building cache its floors'
  actors at the dropship briefing (`RebuildCachedActors`, with
  `CacheBuildingVolumeInChildrenFloorVolumes` and
  `CacheFloorCenterAndExtent`). First look: the roof gone and the aliens
  inside drawn whole; then, after a click on the building, the whole view
  black (units too). Being tested: whether the floors took in far more than
  their building (EW's ground and backdrop pieces overlap every building).
- **22:05, roofs, second look.** The floors cached correctly (the big
  building: 4 floors, 114, 35, 124 and 44 actors; heights 96, 288, 480,
  800), but with them the whole building vanished, from outside too, and
  neither revealing all floors nor showing floors 0 to 3 (new control aid
  `buildings [n reveal|show lo hi|rebuild]`) brought it back; the aliens
  inside stood on nothing. So it is not which floors are shown: most
  likely the actors, once a building's, are drawn through XCOM 2's
  building shader (its cutaway and "scanline" modes), which our stand-in
  materials do not render. **Decision:** the run-time caching is off
  (`CacheBuildingFloors`, development switch): buildings show whole with
  their roofs, as before; the volumes stay in the plots. Next, for a later
  session: a small plot made in the SDK editor with one box building,
  cached there, to compare the editor's floor data with the run time's.
- **22:20, the dockyard again** (caching off): the big building whole with
  its roof; its windows now dark glass panes in their frames, no holes or
  checker. Colour everywhere (the fog of war at XCOM 2's own).
- **22:40, terror civilians.** On our mission XCOM 2 brings no civilians.
  **Decision:** on a terror site on its own plot, a civilian (`Civilian`,
  neutral) at each of EW's spawn points, up to 16
  (`LWMissionSquads.SpawnCivilians`, the spawn manager's `CreateUnit`, as
  XCOM 2's `DropCivilian` cheat does); Long War counts those alive at the
  end as saved (as built). `ForceKind` (development) now sets Long War's
  pending kind too, or the tactical side never knew it was a terror site.
- **23:30, terror sites, properly.** Two finds on URB_CommercialAlley_Terror:
  its alien pods are `XComAlienPod_Terror`, which the converter did not
  read (so no aliens came and the mission could not end); and its
  `XComSpawnPoint`s are the soldiers' places (six, the squad), not
  civilians' (the first try put the civilians among the squad). Enemy
  Within places a terror site's civilians itself
  (`XGAIPlayer_Animal.SpawnCivilians`, decompiled from stock Long War):
  18 (`m_iNumTerrorCivilians`), at random good places at least 10 tiles
  from the squad's start, 5 from an alien pod and 5 from each other, not
  in no-spawn zones. **Decision:** the converter reads terror pods and
  each spawn point's type (converter version 4: every map converted
  again); the mod places 18 civilians by EW's rules on random floor tiles
  (EW's cover points and no-spawn volumes not yet carried over).
  **Checked** (URB_CommercialAlley_Terror, reconverted): Long War's squad
  of 8 at the map's 5 terror pods; "18 civilians placed as Enemy Within
  placed them", none among the squad.
- **00:40, the first mission, seen in play.** Through the control port's
  campaign start (its intro movie stopped with a new aid, `stopmovie`: the
  first mission waits for the movie, and the scripted start could not skip
  it): "LoadMap: LWX2_URB_ConvienienceStore", Long War's first mission
  squad of 10 at 8 EW pods, XCOM 2's four soldiers at EW's drop zone, the
  best reaching 807 tiles. Won (Long War's rule), the after-action report
  and the loot passed, back on the Avenger: the campaign goes on.
- **01:00, release.** `LongWarX2-20261102-3ca85c9.zip` (replaced at 01:10 by `79b0b3f`, the same without the earth's fill) on the draft
  release, checked from the zip on the test machine (uninstalled, setup
  with `--maps`: 83 maps converted again, as the converter is now version
  4, and 83 plots; then a mission on LWX2_URB_CommercialRestaurant with
  Long War's squad of 7 at 4 pods). The person's maps will be converted
  again by its setup (about four minutes).
- **00:15, roofs, third look: on XCOM 2's own plot.** A retaliation on
  Plot_SHN_Retalliation_LgObj_Ravine (EW maps off): its buildings have
  floors 256 units tall (centres 144, 400, 656), one to four floor volumes
  each, hundreds of actors cached, and with the camera on one the roof is
  cut away and the room shown. Rebuilding that building's cache at run time
  (`buildings 3 rebuild`) left it as it was. So the run-time caching is
  sound, and the difference is in our plots.
- **00:30, fourth look.** EW's backdrop pieces now carry
  `bExcludeFromBuildingVolume` (XCOM 2's flag on level actors), so the
  ground and cliffs cannot be taken into a floor. The building still
  vanished, but the aliens inside now showed as silhouettes: the geometry
  is there and blocks the view, it is only drawn invisible. So it is the
  shader: an actor of a building is drawn with XCOM 2's cutaway heights, and
  the retail game has those shaders for the materials it cooked for
  buildings only (it cannot compile new ones: "Compiling … at run-time").
  **Experiment:** pieces standing inside an EW building get stand-ins of
  XCOM 2's building material (`Materials.Approved.Buildings_VP`, EW's
  texture in its three layers) instead of the props parent.
- **01:20, fifth look: what XCOM 2 does to them.** A probe of the cached
  actors' building visibility state (`buildings n`): XCOM 2's own actors
  in a working building stand at cutdown 999999, cutout −999999, mask
  999999, their meshes shown; ours at cutdown 1152, cutout 1152, mask
  −9999999, their meshes hidden (`HiddenGame`). XCOM 2's building material
  as the parent changed nothing. So XCOM 2 puts our buildings' actors
  into its fully hidden state; being tested: whether forcing them back
  holds, or its logic hides them again.
- **01:45, sixth look: it works above the ground floor.** Resetting a
  building's cached actors to XCOM 2's uncut state brings it back, and
  XCOM 2 does not hide it again until its building visibility next
  updates. More telling: our actors' cutout height was 1152, XCOM 2's
  −999999, so XCOM 2 had cut our building out (its transparency for what
  stands between the camera and the focus), top to bottom, with the focus
  on the ground. With the focus inside the building at its first floor
  (Z 300), XCOM 2 cut the roof away and showed the floor: walls with their
  windows, barrels and crates, as it does for its own buildings. With the
  focus on the ground floor (Z 96) it still hid everything. Being checked:
  the floor volumes' numbers (we write 0, 1, 2…; XCOM 2 may count from 1).
- **02:50, the floor numbers.** XCOM 2's floor volumes count from 1
  (`FloorNumber` 1, 2, 3; its top floor an empty one for the roof); ours
  counted from 0, so our ground floor was no floor to it. **Decision:** the
  writer numbers floors from 1. Being tested.
  **Checked:** with floors numbered from 1, the dockyard's big building
  shows its interior with the roof cut away at every focus height (the
  ground, 96 and 300): the warehouse floor with its crates, forklift,
  barrels and window walls. **Decision:** the caching is on by default
  now (`CacheBuildingFloors=true`); with it, each building's actors are
  reset to XCOM 2's uncut state at the dropship and at the battle's start
  (`LWX2PartPlacer.ShowBuildings`), and XCOM 2 cuts from there.
- **03:35, a crash.** On URB_OfficePaper_EWI the game died 0.07 s into
  "Generating Map", right after the buildings were cached at the dropship
  briefing: there the briefing comes before XCOM 2 has generated the map
  (on the dockyard it came after). **Decision:** the buildings are cached
  and shown only when the battle starts (`LWX2PartPlacer.CacheBuildings`,
  `ShowBuildings`, from the tactical HUD's start), never at the dropship.
- **04:00, the crash was the plot.** It came again with the caching
  moved (no "floors cached" before it), so it is the plot itself, as
  XCOM 2 generates the map (its own `InitVolumes` reads our building
  volumes). URB_OfficePaper_EWI has a building whose floors overlap (its
  second floor reaches into its third) and one without floors.
  **Decision** (`ew-plot.ts`): floors stacked as XCOM 2 has them, sorted
  by height, each floor's bottom raised to the top of the one below,
  floors left without height dropped; buildings without floors left out.
- **04:55, still crashing.** With the floors stacked, URB_OfficePaper_EWI
  still crashed, now 3.5 s after its plot began to load: a null pointer
  read in the engine (`XCom2.exe+0x6940a0`, address 0, from the minidump),
  so something of our building or floor volumes on that map is read as
  missing. The dockyard (9 buildings) loads and cuts its roofs; the office
  (3) does not load. **Decision, for the person's build:** building
  volumes off (`PlotBuildings=false` in `XComLWEWMaps.ini`; the writer's
  `buildings` setting): the plots as they were before, which loaded on
  every map tried, roofs drawn. The roof work stays (the volumes, the
  1-based floors, the stacking, the caching and showing at the battle's
  start) for the next session, starting from this crash.
- **05:15, not the buildings.** With building volumes off the office still
  crashed, so the last entry's reading was wrong. This office plot had in
  fact never loaded: its first crash, at 19:36, was put down to the parcel.
  What sets it apart: it has no EW point or spot lights, and the writer
  drops the template's sample lights, so the plot had no light at all;
  XCOM 2's map generation calls on its light clipping manager
  (`MyLightClippingManager.BuildFromScript`), which a level without lights
  seemingly has none of: a null read as the generation begins.
  **Decision:** a plot without EW lights keeps the template's point light,
  dark, high above the map. Being tested.
- **05:35, the office map: not solved.** With a light kept, it still
  crashed at the same moment (the start of "Generating Map"). So three
  explanations are ruled out (the building volumes, the floors' order, the
  missing light); the null read at `XCom2.exe+0x6940a0` stays. What is
  known: the dockyard, the restaurant, the convenience store, the cemetery,
  the fast food, the highway, the train station's terror and the
  commercial alley's terror plots load; this one does not, and it never
  did as a plot (its first try, at 19:36, crashed too, put down then to the
  parcel). Next: diff this plot against one that loads (its parcel's
  place, its volume, its spawn, an import that fails), and test more maps
  in a row to know how many share it.

**State at the end of the night.** The release on the draft
(`LongWarX2-20261102-79b0b3f.zip`) is the one checked from the zip at
01:00: the fog race fixed, glass and grey stand-ins, the first mission and
terror sites (pods and civilians) on EW plots, its maps converted again by
its setup. Since then, in the repository but in no release: building
volumes (switched off, `PlotBuildings=false`), the caching and showing of
building floors at the battle's start (on, without effect while no plot has
volumes), and the dark light in plots without lights. The office map
(URB_OfficePaper_EWI) crashes as its plot loads, in the release too.

## Morning (2026-11-03)

The person: the first mission loaded (screenshot: the convenience store,
Long War's aliens); the first crash site crashed. Their crash folders (three
from the evening, one from the morning) give two exception addresses:
- **`XCom2.exe+0xb39b6c`**, the evening's two at the battle's start and the
  morning's: each right before Long War's pods spawn, each on a small scout
  crash site (CSmallScout_Marshlands, CSmallScout_Farm twice). So the fog
  was not the cause (the morning's release no longer touched it then).
  On the test machine CSmallScout_Farm has a pod at (7442, 3899), far
  outside the plot's tile grid; the release pulled such a pod to the grid's
  edge, where there may be no floor at all, and XCOM 2's spawner read a
  null. **Fix** (`LWMissionSquads.SpawnPod`): each pod moved onto the
  nearest floor tile units can enter, within six tiles (`EnterableNear`),
  else not spawned; templates the game lacks replaced by a Sectoid; no
  encounter zone search when the squad stands on the objective (no line of
  play); each pod logged before it spawns. **Checked:** CSmallScout_Farm,
  four pods spawned (the far one moved inside), the mission running.
- **`XCom2.exe+0x6940a0`**, the evening's first (URB_Boulevard) and the
  office map on the test machine: during the map's generation, before any
  step of the mod. Open.
- **Release** `LongWarX2-20261103-6061fad.zip`, checked from the zip on the
  test machine (uninstalled, setup with `--maps`, then the farm crash site:
  Long War's squad of 7 at 4 pods, the mission running). Its setup leaves
  the person's conversions as they are (converter version unchanged).
- **The person's look at the first mission** (the convenience store): the
  colours a real improvement; but windows hanging in mid air, walls
  missing, odd rock formations on the ground, and the fog of war off
  altogether (every alien on the map in view). Crashes first, by their
  word; these next.

### 2026-11-03, the map-generation crash (XCom2.exe+0x6940a0), bisected

- The plot writer takes `LWX2_PLOT_DEBUG` (`nopieces`, `pieces=a-b`, `only=MeshA,MeshB`,
  `nomats`) to write cut-down plots of one map; each tried on wingpu in place of the
  installed plot (scratch scripts, not in the repository).
- Office map (`URB_OfficePaper_EWI`): without EW's pieces it loads; pieces 0 to 435
  load; 436 to 872 crash. So a piece, not the plot's skeleton (volume, spawns, parcel).
- Meshes in both crashing maps (office, boulevard) and in none of three that load
  (store, pier, highway), less two that sit in the half that loads: `TrashPileC_Small`,
  `BlastDecal_A`, `BoundSidewalkStrA16x4`, `SidewalkStains_E`. Tried next, alone.
- **The fog of war is off on our plots** (the person: every alien visible). Not
  switched off on purpose: what went off on 2026-11-02 was only "unexplored shown as
  seen". The plots' WorldInfo and world data match XCOM 2's own test plot; a control
  aid (`fog state`, `fog on`) reports and switches on XCOM 2's fog effect live, to
  find whether the effect is missing or just not on.
- **Missing walls found:** EW's walls are fracturable actors (`XComFracLevelActor`,
  `XComDecoFracLevelActor`, their mesh in a `FracturedStaticMeshComponent`); the
  converter took only `StaticMeshComponent`, so every wall was left out and windows,
  their own pieces, hung in the air. It now takes both (converter version 5: every map
  is converted again). The store map gains 79 wall pieces.
- **Rock formations, likely:** EW's tree cards and signs use parents with opacity in
  the diffuse alpha (`PROP_DifOpc`, `PROP_OpacityMask_Tile`); they were stood in by an
  opaque parent, so leaf cards draw as solid shapes. XCOM 2's switchless masked parent
  is `Props_OpcMask_TC` (two-sided); to try with the diffuse in Diffuse and Masks.
- **Office crash found (08:41):** pieces narrowed by halves, by a script, to one:
  piece 857, mesh `StaticMesh_0`, alone crashes the game. It is the one mesh at the
  root of EW's map package (road stripes); the converter put the map package in front
  of carried content only, so the section said `StaticMesh_0` and the plot imported a
  *package* of that name. The converter now treats a one-part path as the map
  package's own (version 5). Two maps of 83 have such meshes: `URB_OfficePaper_EWI`
  (26 pieces) and `CLrgScout_City` (6).
- The boulevard has none, so its crash is another cause: the same bisect runs on it.
- Seen on the way, not the cause: every map's load logs hundreds of `(AddNetObject)
  … duplicate NetIndex` errors, as the carried packages, nested since version 2, keep
  the object numbers of their own packages; maps that load show them as much as maps
  that crash. Left as is.
- **Boulevard crash found (08:59):** the same bisect, piece 351, `Qoliage.grassPatch`.
  EW's package holds a static mesh and a texture both `Foliage.grassPatch` (same
  outer, name and number; EW's cooker allowed it); in XCOM 2 one name holds one
  object, so the piece got the texture. Same-named objects occur in about 25 of the
  83 maps (`Foliage.grassPatch`, `Foliage.fernBig`, a door both skeletal and static
  mesh, destructibles' `Action` subobjects). The converter now gives the second and
  later of a name a name number of their own (`grassPatch_0`), before reading
  anything; references inside the package are by index, so nothing else moves.
- **Checked on wingpu** after converting all 83 maps again (version 5, 4 minutes):
  the office, the boulevard, `CLrgScout_City` and the convenience store load and
  play; the store has its walls and interior; on the farm the jagged dark shapes
  are gone (cut-out materials).
- **Fog, live** (`fog state` on the office): the world's fog enabled, XCOM 2's fog
  effect in the player's post-process chain and shown, sized to the level. So it
  is on, yet draws nothing visible; setting its two levels (never seen, seen) live
  changed nothing visible either. Next: the same report in a stock XCOM 2 mission,
  for what differs.
- **Release** `LongWarX2-20261103-9870eb1.zip`, checked from the zip on wingpu
  (uninstalled, setup with `--maps`: 83 maps converted again, as the converter is
  now version 5; then the office map, which crashed before, loads and plays). The
  person's setup converts their maps again too (about four minutes).
