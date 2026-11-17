---
title: "Long War's officers: the Officer Training School's officer ranks and their abilities"
status: review
priority: 33
dependsOn: [lw-base, lw-classes, lw-missions]
---

# Long War's officers

The Officer Training School's squad sizes are in (`lw-missions.md`). Its
other five projects make officers. A soldier promoted to an officer rank
gains officer abilities, and a squad's officers bring their bonuses to the
mission.

## What Long War keeps (stock Long War 1.0)

- **The projects** (`OTSBalance`, eTech 3 to 7): Lieutenant §100, Captain
  §200, Major §300, Colonel §400, Field Commander §500. Each is available
  once the barracks' ranks add up to 20, 45, 75, 110 and 150.
- **Officers per rank** (`ContBalance_Classic[0]`, a reused array; its
  comment names the columns): 3 lieutenants, 2 captains, 2 majors,
  2 colonels, 1 field commander.
- **The abilities** (its `XComStrategyGame.int`, `OTSTechSummary`):
  - Lieutenant: Lead By Example (the officer's will to nearby soldiers,
    and the Command ability), and Legio Patria Nostra (will:
    `INTERNATIONAL_WILL`, 1 per nationality) or Stay Frosty (fatigue);
  - Captain: Semper Vigilans (defence) or Fortiores Una (cover damage
    reduction near the officer); +1 Command charge;
  - Major: Into the Breach (mission XP for lower ranks) or So Shall You
    Fight (kill XP); +1 Command charge;
  - Colonel: Band of Warriors (aim for continent bonuses) or Esprit de
    Corps (will and defence); +1 Command charge;
  - Field Commander: So Others May Live (aim and will after missions with
    no deaths) or Combined Arms (lower enemy damage reduction); +1 Command
    charge.

## Questions before building it

- How a soldier becomes an officer: a promotion chosen by the player,
  limited by the counts above?
- The abilities' numbers, beyond `INTERNATIONAL_WILL`: from Long War's code
  (as was done for psi and the bonuses), or its constants.
- How this sits with XCOM 2's ranks, which the classes already use.

## Note (2026-11-15, read from Long War's code)

Long War's officers are Enemy Within's medals, repurposed:
- Its officer abilities are EW's medal perks (`XGTacticalGameCoreNativeBase.IsMedalPerk`).
- The Officer Training School's officer projects unlock them, gated by the barracks' ranks
  (`XGTechTree.HasOTSPrereqs`, `GetNumMedalsAvailable`), with Sandhurst's cut.
- A soldier is made an officer on EW's medal screen (`UIMedals`,
  `UISoldierList_AssignMedal`).
- An officer's fatigue carries `SPECIES_POINT_LIMIT` hours per medal
  (`DetermineTimeOut`), with Gift of Osiris's cut.

So building this means porting the medal screen, each officer ability as a tactical ability,
and the medal count's place in fatigue. The person (2026-11-15) wants Long War's code
followed, so nothing here waits on him. Left for after the strategy screens (playability
first).

## Report (2026-11-16, the Officer Training School on EW's own screen)

The school's screen is Enemy Within's own (`UILWEWOTS`, its `OfficerTrainingSchool` movie,
driven as EW's `UIOTS` drives it), from the hub's Barracks room once the school is built,
with EW's base behind it through the barracks' camera.
- Long War's seven projects in its order, with Long War's names and summaries from the
  player's install (`makeOTSWords`, 20 words): Squad Size I and II, Tactical, Company,
  Field and Regimental Officers, Commanding Officer.
- The barracks' total ranks in the header (EW's "TOTAL RANKS"), each project's cost, in red
  where it can't be bought; the selected one's reason, the ranks it needs and its summary in
  the info panel.
- Squad Size I and II are bought there, in order, after EW's own confirmation ("Acquire the
  Squad Size I upgrade for §200?"), on the rules that were already in (cost, ranks, Special
  Warfare School, Sandhurst).
- The officer projects' prices and ranks come from stock Long War's `OTSBalance` (eTech 3 to
  7: §100/20 ranks, §200/45, §300/75, §400/110, §500/150), now in `XComLWStrategy.ini` as
  `OfficerProjects`.

Checked on wingpu: Squad Size I bought from the screen (§500 → §300, squad size 7, the row's
cost cleared and "Bought."); the officer projects listed in red with their reason
(`logs/wingpu_ew_ots.png`, not committed).

### Decisions

- The five officer projects show but can't be bought until officers are in ("Officers are
  not in the port yet."): the school reads as Long War's, and nothing is sold that does
  nothing.

## Plan (2026-11-16, read from Long War's code)

**Strategy** (`XGFacility_Barracks`: `BuildMedals`, `UnlockMedal`, `CanAwardMedalToSoldier`, `AwardMedalToSoldier`;
`XGDebriefUI`; `DetermineTimeOut`):
- Five officer ranks, Long War's medals: lieutenant, captain, major, colonel, field commander. Each
  officer project bought unlocks its rank, with `ContBalance_Classic[0]`'s count of officers (3, 2,
  2, 2, 1) added to that rank and to every rank below it (`UnlockMedal`).
- A soldier can be made an officer of a rank when one is available, they hold the rank below
  (lieutenant: none), their class rank is at least the officer rank + 2 (lieutenant: sergeant),
  they have done 5 missions since their last officer promotion (`NUM_MEDALOFHONOR_MISSIONS`; half
  with Marathon), and they are not psionic, a MEC, augmented, or away (gene mods, psi testing).
- Each rank gives one of two powers, the player's choice (lieutenant: Legio Patria Nostra or Stay
  Frosty; captain: Semper Vigilans or Fortiores Una; major: Into the Breach or So Shall You Fight;
  colonel: Band of Warriors or Esprit de Corps; field commander: So Others May Live or Combined
  Arms), and one Command charge. A lieutenant also gets Lead By Example.
- Kept on the unit (unit values: rank, the powers chosen, missions at the last promotion).
- A screen to promote them: EW's officer screen (its medals screen), from the Barracks room.
- An officer's fatigue: `SPECIES_POINT_LIMIT` hours more per officer rank.

**Tactical** (`XGFacility_Barracks` before launch; `XGSquad.AddPermanentUnit`; `XGUnit`):
- The squad's leader is the officer with the most ranks (ties: the higher will). Their powers
  apply to the whole squad.
- The leader gets Command (EW's War Cry: a move for a soldier in sight whose turn is done, not on
  overwatch or hunkered; four-turn cooldown; one charge per officer rank) and Lead By Example
  (soldiers near the leader, 8 tiles, with lower will use the leader's).
- The powers' numbers from stock Long War: Semper Vigilans +5 defence in cover; Legio Patria
  Nostra +1 will per nationality; Band of Warriors +2 aim per continent bonus held; Esprit de
  Corps +5 will (not robots) and +5 defence; Into the Breach +¼ mission XP up to sergeant; So
  Shall You Fight +25% kill XP; So Others May Live +1 aim and will after a mission with no
  deaths, up to +8; Combined Arms ignores a point of damage reduction; Stay Frosty a day less
  of fatigue.

### Found on the way

- **Long War's damage reduction is not in the port**: every unit in cover takes 0.667 (low) or 1
  (high) less damage, more when hunkered down (`XGUnit`, the damage taken), and aliens have their
  own. Fortiores Una doubles the cover part, so it waits on that; noted in STATUS.

## Report (2026-11-16, officers: rules, powers, Command, Lead By Example)

Built on the plan above, the rules from stock Long War (`[LWOfficers]` and
`[X2Ability_LWOfficers]` in `XComLWStrategy.ini`, generated by `strategy-config.mjs`):
- **`LWOfficers`**: officer ranks kept on the soldier (unit values); the officer projects
  (`Buy`: each opens its rank, its officers added to it and every rank below, as
  `UnlockMedal`); promotion (`CanPromote`, `Promote`: Long War's conditions); the squad's
  leader picked at launch and their powers stamped on every soldier going (`MarkSquad`); the
  officers' fatigue hours. Words from the player's install (`makeOfficerWords`, 34 words:
  ranks, powers, Lead By Example, Command), the powers' live numbers filled in.
- **The school sells the officer projects** on its EW screen (`UILWEWOTS`), in order, with
  Long War's prerequisites (the ranks, Sandhurst's cut; the one before), Special Warfare
  School's discount.
- **In a mission** (`X2Ability_LWOfficers`, on every soldier, acting by what launch stamped):
  - the squad's powers (`X2Effect_LWOfficerPowers`): Legio Patria Nostra, Band of Warriors,
    Esprit de Corps (stats for the mission), Semper Vigilans (defence when in cover as the
    attacker sees it), Combined Arms (a point of armour ignored);
  - **Command** for the leader: a move for a squadmate in sight whose turn is done (no
    actions, none held for overwatch, not hunkered, not a robot), one action, one charge
    per officer rank, five-turn cooldown;
  - **Lead By Example**: at the mission's start and as each XCOM turn begins and ends, squad-
    mates within 8 tiles of the leader with lower will are raised to the leader's.
- **After a mission**: Into the Breach (+¼ of the win XP up to sergeant), So Shall You Fight
  (+¼ per kill), So Others May Live (+1 aim and will after a win with nobody lost, up to +8)
  in `LWExperience`; the officer's hours and Stay Frosty (a day off) in `LWFatigue`.

Checked on wingpu (a field commander set on the control port, powers Legio Patria Nostra,
Semper Vigilans, Into the Breach, Esprit de Corps, Combined Arms):
- launch picked her as leader and stamped the powers (409);
- every squadmate +11 will (+1 × 6 nationalities, +5 Esprit de Corps) and +5 defence;
  Lead By Example lifted a soldier from 39 to the leader's 40, and left those above it;
- Command refused squadmates with actions left or out of sight, then gave one with none a
  move back for one of the leader's actions, and went on cooldown
  (`logs/wingpu_officer_command.png`, not committed);
- the mission won: each soldier +120 XP (80 + 20 Into the Breach + 20 nobody lost); the
  leader resting 167 hours (60 of them for her five officer ranks).

Control port: `officers` (posts, ranks, who is promotable and why), `officers buy <k>`,
`officers promote <soldier> [second]`, `officers set <soldier|#id> <rank> <powers>`.

### Decisions

- Lead By Example's "nearby" is 8 tiles: EW's officer radius is native code; Fortiores Una's
  text, which works off the same nearness (`HasBonus(170)`), says 8 tiles.
- Command's cooldown is five XCOM 2 turns: EW's 10 counts both sides' turns, which is Long
  War's "four-turn cooldown" between uses; it costs one action (EW's War Cry isn't marked free).
- Lead By Example is worked out at the start and end of each XCOM turn (positions then),
  not continuously.
- Semper Vigilans counts cover as the attacker sees it (flanked: no bonus), as the port's other
  "in cover" bonuses do.

### Left open

- ~~The promotion screen (EW's officer screen) for the player; until then the control port.~~
  Done: the report below.
- Fortiores Una, waiting on Long War's damage reduction (STATUS).
- ~~Officer rank shown on the soldier (EW put the rank's insignia beside the class).~~ In the soldier lists: the report below.

## Report (2026-11-16, the promotion screen)

Officer promotions are in the hub's Barracks room as **Officer Promotions** (EW's own word
from the player's install), once the first officer project is bought, as EW's appeared once
medals were. The screen (`UILWOfficers`) is built from XCOM 2's widgets over EW's base,
through the barracks' camera:

- **Officer Billets:** the five ranks, each with its open billets or LOCKED (EW's words).
- A rank with an open billet chosen: XCOM 2's soldier list (`UIPersonnel_LWOfficer`) with
  only the soldiers Long War lets be promoted to it (`LWOfficers.CanPromote`: the rank below,
  the soldier's rank, missions in grade, not psionic, not in the labs).
- A soldier chosen: **ASSIGN ABILITY - <rank>** with the rank's two powers as buttons and
  their descriptions (Long War's text, its numbers filled in).
- A power chosen: EW's confirmation, in EW's words ("Awarding a promotion is permanent…"),
  with the power named; Yes promotes (`LWOfficers.Promote`). Esc steps back from the powers to
  the ranks, and from the ranks out to the hub.

Verified on wingpu in a new campaign (Officer Training School placed and the lieutenant
project bought by the control port, two soldiers readied with the new `officers ready` aid):
both promoted by mouse through the screen, one to each power. `officers` then showed
"Lieutenant: open 1 filled 2", each soldier officer rank 1 with the power chosen.

A first try clicked a power button with no dialog; the same click raised it on every try
since, with the button's mouse events logged. I could not make it happen again and found
nothing in the log, so it is noted here rather than fixed.

Control port: `officers ready <soldier|#id>` ranks a soldier up to the next officer rank's
requirement and counts its missions in grade done (a test aid).

### Decisions

- XCOM 2's widgets rather than EW's Officer Billets movie (posted in the chat): the movie's
  rows come from EW's shared components, which don't resolve in XCOM 2 (the hub's submenu has
  the same cause), and renaming those classes broke the hub's menu. EW's movie can come back
  once that is solved.

### Left open

- ~~Fortiores Una, waiting on Long War's damage reduction (STATUS).~~ Done (below).
- ~~Officer rank shown on the soldier (EW put the rank's insignia beside the class).~~ In the soldier lists: the report below.

## Report (2026-11-16, Fortiores Una)

Fortiores Una acts now, through Long War's damage reduction (`features/lw-damage-reduction.md`):
the leader and the squad within 8 tiles of the leader take the cover part of the reduction
twice. Checked on wingpu with a captain holding it: a Sectoid's 4 on a soldier in high cover 2
(3 without), in low cover 2.666. Combined Arms moved there too: a point of Long War's
reduction ignored, no longer a point of XCOM 2 armour piercing. All ten powers act.

## Report (2026-11-16, EW's own Officer Billets screen)

With EW's screens running on EW's own Flash framework (`features/lw-base-view.md`), EW's Medals
movie draws its rows, and the promotions now use it (`UILWEWOfficers`), driven as Long War's
`UIMedals` drives it:
- **Officer Billets** (display mode 0): the five ranks with their insignia (EW's medal frames:
  `urbancombat`, `defender`, `international`, `honor`, `starofterra`, Long War's
  `UIUtilities.GetMedalLabel`), "Open Billets: N" or LOCKED with EW's lock.
- A rank with an open billet chosen: XCOM 2's soldier list of those Long War lets be promoted
  (`UIPersonnel_LWOfficer`, unchanged).
- **ASSIGN ABILITY - <rank>** (display mode 2): the two powers' texts and EW's buttons with their
  names; no pictures (stock Long War's picture table is empty, so its screen shows none either).
- EW's confirmation; promoted. Mouse as Long War reads it (`option<n>`, `highlightMC<n>`: the
  movie's own mouse events reach the screen), arrows, Enter, Escape (powers → ranks → closed).

Checked on wingpu by mouse: Lieutenant chosen, a soldier, STAY FROSTY, Yes: "Lieutenant: open 2
filled 1", the soldier officer rank 1 with the second power. Screenshots
`logs/wingpu_ew_officer_billets.png`, `logs/wingpu_ew_officer_assign.png`.

`UILWOfficers` (XCOM 2's widgets) stays for a player whose EW screens are not converted.

## Report (2026-11-16, officer rank in the soldier lists)

An officer's rank now shows in XCOM 2's soldier lists: the barracks, squad select's picker and
the labs' lists. Long War's short name for it (LT, CAPT, MAJ, COL, CMDR; `RankShort`, from
`m_arrMedalNames[6…10]`) **stands in place of the soldier's rank**. That is how Long War names an
officer: `XGStrategySoldier.GetName` gives the officer rank instead of the soldier rank once the
soldier has one.

It is done by `UIPersonnel_LWSoldierListItem`, an override of XCOM 2's row
(`+ModClassOverrides` in `XComEngine.ini`; the mod's first). Only the rank text changes; the
rank icon and the rest of the row are XCOM 2's.

**Checked on wingpu** (officer ranks set with `officers set`): rows read LT, MAJ and CMDR for
officer ranks 1, 3 and 5; everyone else LCPL.

**Not done:**
- EW's insignia picture. XCOM 2's row has no place for one beside the class, and the medal frames
  live in EW's Medals movie, not as images.
- The armory's soldier header still shows the soldier rank.

## Report (2026-11-17, the officer rank in the armory's header)

- **Done:** `UISoldierHeader_LW` (in XCOM 2's place by `XComEngine.ini`'s ModClassOverrides) shows an officer's rank as
  Long War names it: the header's rank line reads the officer rank ("CAPTAIN"), and the name leads with its short form
  ("CAPT CLAUDIA MÜLLER") where XCOM 2 put the soldier rank's ("LCPL"), as the soldier lists already do. Everything
  else in the header is XCOM 2's.
- **Seen on wingpu:** the hub's Barracks → View Soldiers → a captain: the armory's header as above
  (`logs/wingpu_armory_officer_header.png`).
