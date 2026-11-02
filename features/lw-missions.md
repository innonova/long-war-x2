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
