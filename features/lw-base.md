---
title: "Long War's base: the grid, digging, facilities, power and upkeep"
status: review
priority: 2
dependsOn:
  - lw-geoscape
  - lw-gear
---

## Purpose

Long War's headquarters is a grid dug into the rock: labs speed research,
workshops cut costs, uplinks hold satellites, the Foundry runs projects,
and every room costs power and upkeep. Engineering, the Foundry and the
satellites all lean on it. Without it the satellites are unlimited, and
nothing costs anything each month. This brings Long War's base into the
Long War Geoscape.

## What the person should see

- A BASE button on the Geoscape: a screen with the 7 × 5 tiles.
  - Rock is dug, the shaft takes access lifts, and empty ground takes the
    chosen facility.
  - Above the tiles: the base's power, satellites, lab and workshop
    bonuses, and monthly upkeep.
- Long War's starting base: hangar, barracks, mission control, research,
  an access lift and one satellite uplink. Rock below, two steam vents.
- **Facilities cost:**
  - money, alloys, elerium and items, paid at the start;
  - days to build;
  - power to run;
  - upkeep, paid at the council report.
- **Facilities give:**
  - labs: research;
  - workshops: cheaper items and part of their alloys and elerium back;
  - uplinks: room for satellites;
  - Foundries: Foundry projects.

## Requirements

- Long War's numbers generated from the player's `DefaultGameCore.ini`
  (`FacilityBalance`, the base's constants). Each facility's size and
  tech come from Long War's `XGItemTree.BuildFacilities`, read into the
  Tree's `data/itemtree.json`.
- Long War's rules as its code has them (the Report lists them).

## Report (2026-11-01)

**The base is Long War's** (`LWBase`, `LWBaseRules`, config
`XComLWBase.ini` from `scripts/base-config.mjs`, the screen `UILWBase`,
the state in the Geoscape's). Its rules, read from Long War's code:

**The grid** (`XGBase.GenerateTiles`), 7 × 5:
- the top row holds the hangar, barracks, mission control and research;
- below it: an access lift in the shaft and a satellite uplink;
- the second row is open on the left, and three in four of its right-hand
  tiles are rock;
- lower rows are rock, one in five open, with two steam vents in the rock.

**Reaching a tile** (`HasAccess`, `HasExcavation`):
- a tile has access in the top row, in the shaft below a lift, or in a row
  with a lift in the shaft;
- the tiles between it and the shaft must be open.

**Building and digging:**
- **Digging** costs §10 × 2^(row − 1) and takes 5 days.
- **Lifts** go in the shaft, everything else beside it.
- **A thermo generator** needs a steam vent (`XGBuildUI`).
- **A facility needs:**
  - its tech researched;
  - power free;
  - for labs, workshops and uplinks, enough staff
    (`CanFacilityBeBuilt`, `GetFacilityProjectCost`): 10 scientists for
    the first lab and 10 more for each after, the same in engineers for
    workshops, 10 engineers per uplink and 20 per nexus;
  - for the Officer Training School, a soldier of rank 3;
  - for the single facilities, none already built.
- **The cost** is paid at the start: the Elerium Generator also consumes
  two UFO power sources, the nexus two UFO navigation computers.
- **The days** pass whatever the engineers.

**What the base gives:**
- **Power:** the difficulty's base, plus the generators, plus 3 for each
  pair of adjacent generators.
  - Facilities use theirs, those under construction included.
- **Satellites:** 1 per uplink, 2 per nexus, and 1 per adjacent pair. A
  satellite is launched only into room.
- **Labs:** +20 % research each, and +10 % per adjacent science pair.
- **Workshops** (`ScaleCost`, `CalcWorkshopRebate`):
  - items' cash costs are cut, 10 % for the first;
  - part of their alloys and elerium is given back when built.
  - Adjacent engineering facilities count half a workshop each.
- **Foundry projects:** one at a time per Foundry built. There is none
  at the start.
- **Upkeep:** the facilities, the Skyranger (§20) and each interceptor
  (§40), taken from the council's funding each month. The report
  says how much.

**The control port:**
- `base`: the grid, the numbers, each facility and what it needs;
- `work <column> <row> [facility]`;
- `auto … sats` now grows the base for uplinks (an uplink, else a dig,
  else a lift) once the satellites fill them.

**Checked in the game** (new campaign, control port):
- the starting base came up as Long War's, power 21 of 30;
- a workshop (21 days) and a dig (5 days) were begun and finished;
- the next workshop then needed 19 engineers, and an uplink 8 more power;
- the council report took §155 of upkeep;
- items cost 10 % less with the workshop;
- a satellite could not be launched past the uplink's room;
- three months of `auto … sats` ran.

### Decisions

- **One base, not the screen of the original.** A grid of buttons with
  names stands in for Long War's 3D base view: a taste matter for later.
- **No removing facilities** yet, and no council bonuses: the starting
  facilities and the cheaper digging, building and labs that some
  countries give.
- **A campaign begun before this build** gets a fresh Long War starting
  base the first time time passes.
- **Satellites can still be ordered past the uplinks' room**, as in Long
  War; they wait until there is room.

### Left open

- **What the other facilities do:**
  - Alien Containment (captives, with stun);
  - the Officer Training School (its perks);
  - Psionic Labs, Genetics Lab, the Repair Bay (MECs);
  - Hyperwave Relay, the Gollop Chamber.
- **The hangar:** interceptors bought and kept per continent (the air war
  has jets on one continent for now).
- **Removing a facility** (§5, Long War's `BASE_REMOVE_CASH_COST`).

## Report (2026-11-17, removing a facility; the Hyperwave Relay; Alien Containment and the arc thrower)

- **Removing a facility** (read: `XGBuildUI.UpdateCursor`, `CanRemoveFacility`, `ConfirmRemovalDialogue`,
  `XGBase.PerformAction`, `XGFacility_Engineering.AddConstructionProject`): a built facility on EW's Build Facilities
  screen offers REMOVE with its price (Long War's `BASE_REMOVE_CASH_COST`, §5, now `RemoveCash` in the generated base
  config); it is done at once (the project's hours are 0), and the tile is left dug, a steam vent again if it was one
  (`SteamTiles`, kept from now on; a thermo generator always stood on one). Not the access lift, the Hyperwave Relay,
  the Gollop Chamber, the Foundry or the Officer Training School (`LWBase.Removable`), and nothing of the top row.
  Refused, with EW's own reason, while in use (`LWBase.RemoveBlock`): a generator whose power is needed, Alien
  Containment during an interrogation, a workshop whose engineers the next uplink needs, an uplink or nexus whose
  satellites are up, the Psi Labs, Genetics Lab or Cybernetics Lab with soldiers in them, the Cybernetics Lab with a
  MEC under repair. Alien Containment's confirmation warns that captives will be terminated, as EW's does; Long War's
  code does not terminate them, and neither does the port.
- **Checked on wingpu:** by the test aid (`base remove <x> <y>`), an uplink with its satellite up was refused (code 4)
  and a workshop went for §5. On EW's screen by mouse: the workshop's card asked "Remove Facility?"
  (`logs/wingpu_ew_remove_facility.png`), Yes removed it (cash 500 → 495, the tile empty), and the uplink's card
  answered "Facility Cannot Be Removed" with EW's reason (`logs/wingpu_ew_remove_refused.png`). A slip of mine on the way:
  the test aid removed the hangar of the top row; the top row is now out of reach, as on EW's screen.
- **The Hyperwave Relay** (`XGGeoscape.CanIdentifyCraft`, `XGMissionControlUI.UpdateAlert`): a detected UFO's class is
  shown only with the relay or once XCOM has taken one of that class (a crash site or a landed UFO won:
  `m_arrCraftEncounters`); its objective only with the relay. The Geoscape's notes and decisions now say "unidentified
  small UFO" until then (`Identified`, `UfoLabel`, `CraftEncounters`). Checked: a first scout "unidentified small UFO";
  with the relay "Overseer, Flyby"; after its crash site was won, later scouts "Scout" without the relay.
- **Alien Containment and the arc thrower** (`XGFacility_Lockers.EquipSmallItem`: no arc thrower without containment):
  the arc thrower's stun is not offered in a mission while the base has no Alien Containment
  (`X2Condition_LWContainment`). XCOM 2 still lets the item be equipped. Not seen in a mission yet.
