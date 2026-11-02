---
title: "Long War's research, Foundry and engineering"
status: in-progress
priority: 2
dependsOn:
  - lw-geoscape
---

## Purpose

The strategy layer's choices: what to research, what to build, what the
Foundry improves. Long War's tree, which the Long War Tech Tree already
reads from Long War's own code and has checked against the person's saves,
with Long War's numbers, so a campaign's pace is Long War's. Step 4 of
`port-plan.md`.

## What the person should see

XCOM 2's research screen listing Long War's techs, by Long War's names
and texts, opening in Long War's order. Each takes Long War's time at
Long War's research rate (scientists, and labs once there are labs) and
costs Long War's alloys, elerium, weapon fragments and items. Research
credits from interrogations make the techs they cover cheaper. Then the
Foundry's projects, and engineering: items and facilities, with Long
War's costs and engineers.

## Requirements

- **Long War's rules, generated.**
  - The techs' requirements, credits and gates come from the Long War
    Tech Tree's `data/techtree.json`, which is read from Long War's
    package.
  - Times and costs come from the player's `DefaultGameCore.ini`
    (`TechBalance`, `FoundryBalance`, `ItemBalance`), via
    `scripts/research-config.mjs`.
- **The names and texts are Long War's.** They are written on the
  player's machine (setup, `scripts/write-words.mjs`) and never
  committed.
- **XCOM 2's own techs are hidden.** Nothing of XCOM 2's research
  machinery that Long War lacks (inspirations, breakthroughs) is left.
- **The phases:**
  1. Research: in this report.
  2. Engineering: the items Long War's techs unlock, with Long War's
     costs. This needs Long War's weapons and items as XCOM 2's
     (`port-plan.md` step 2).
  3. The Foundry's projects.
  4. The base's facilities: labs (the research bonus), workshops,
     power, uplinks.

## Report (2026-11-01, phase 1: research)

**Long War's research runs on XCOM 2's research screen.**

- **The techs** (`X2StrategyElement_LWTechs`, config `XComLWResearch.ini`):
  - Each of Long War's 75 techs is an XCOM 2 tech template.
  - Its points are Long War's: `TechBalance` days × `TECH_TIME_BALANCE`
    × 72, the Tree's base days × 720.
  - It requires Long War's techs: all of `Requires`, one of `AnyOf` (as
    XCOM 2's alternate requirements).
  - It costs Long War's alloys and elerium, in XCOM 2's own resources.
  - It has a picture from XCOM 2's research by kind of tech (autopsy,
    interrogation, weapons, armour…).
- **XCOM 2's 125 techs are hidden** (a requirement that never holds, at
  every difficulty).
- **XCOM 2's inspirations and breakthroughs are switched off**: their
  timers never run out, and one already given is taken back.
- **The rate is Long War's** (`XGFacility_Labs.GetResearchPerHour`):
  scientists × (1 + labs' bonus), with no labs yet.
  - XCOM 2's science score is its research points an hour, so the
    Geoscape sets its bonus to make up the difference from XCOM 2's own
    staff (`SyncResearch`, after every run of time).
  - Long War's starting staff: 10 scientists and 10 engineers.
  - Each country under a satellite sends its `ContBalance` scientist or
    engineer at the council meeting (the strategy config's countries now
    carry them).
- **Research credits**: an interrogation done holds its credit, and every
  tech it covers costs its share less (25 %, the Ethereal's "All" 20 %),
  credits stacking by multiplying, through XCOM 2's own
  `TimeReductionScalar`.
- **The words** (`makeTechWords`, `scripts/write-words.mjs`, used by setup
  too): name, summary, code name and research report from Long War's
  `XComStrategyGame.int`. Long War's own techs (the UFO analyses, the
  armours) are keyed there by number.

**Checked in the game** (new campaign, by the control port's new
`research` command and on screen):

- The research screen lists Long War's opening techs with Long War's
  words: Xenobiology, Alien Weaponry, Alien Materials, Alien Computers.
- Xenobiology takes 18 days (432 h at 10 scientists).
- Alien Materials is shown in red, since it costs alloys and elerium XCOM
  has none of.
- Xenobiology completes on its day with XCOM 2's research-complete
  screen, and opens Long War's next techs: Xenoneurology, Xenogenetics,
  the Sectoid, Thin Man and Muton autopsies (288, 432, 576 h).
- No inspirations.

**A trap found:** UE3's config reader stops reading a struct at an empty
array (`AnyOf=()`). Every field after it was 0, which made the first
build's techs "instant". The generators now leave empty arrays out.

### Decisions

- **XCOM 2's research machinery with Long War's content and numbers,
  not a screen of our own.** XCOM 2's research is one project at a time
  on a points-per-hour rate, as Long War's is. Its science score can be
  set to Long War's rate exactly, so its research screen, reports, alerts
  and saved state come for free, and only the content is ours.
- **The rules come from the Tree's data** rather than from decompiling
  Long War's package again. The Tree read them from that package and
  checked them against 1,711 saves. It is the same code, read once.
- **Gates that need loot are recorded but not enforced yet.** Weapon
  fragments, the items a tech consumes (corpses, captives) and what must
  have been held or captured first are all in `XComLWResearch.ini`.
  Missions bring no loot yet, so enforcing them now would close most of
  the tree. They come with the missions' loot.

### Left open

- **Loot.** Fragments, items and gates are not enforced. Alloys and
  elerium are, but nothing brings them yet: the missions' loot is next.
- **Labs** (`LAB_BONUS` 20 % each, adjacency) wait for the base.
- **XCOM 2's research room** still shows "SCIENTISTS 0", XCOM 2's own
  staff count; Long War's scientists are in the Geoscape's state.
- **What a tech unlocks** (items, Foundry projects, facilities) comes
  with phases 2 to 4.
- **Existing campaigns** started before this build have no state for
  Long War's techs; only new campaigns do.

## Report (2026-11-01, research's gates)

Weapon fragments, consumed items, "one of these in stores", UFO types
captured, and "held" (asked as "held now") are now enforced, since
missions bring loot. See `lw-loot.md`, phase 2.

## Report (2026-11-02 night, the Foundry's projects in missions)

**Four of the Foundry's projects now change soldiers in missions once done**
in the campaign. The campaign's state comes into the mission with the rest
of the strategy game, so `X2Effect_LWFoundry`, on every Long War armour's
stat ability, reads the projects done.
- **Mag Pistols**: pistols +25 critical chance (`PISTOL_I_CRIT_BONUS`).
- **Rail Pistols**: pistols +15 aim. Its constant is named for defence
  (`PISTOL_II_DEF_BONUS`), but Long War's text says aim.
- **Reflex Pistols**: pistols +1 damage ("an increase in the maximum damage
  output").
- **Improved Medikit**: medikits heal 3 more a charge, Long War's text ("by
  three for medikits"). An extra heal on XCOM 2's medikit abilities, under
  `X2Condition_LWFoundry`.
- Pistols are Long War's weapons of the Pistol family.

**Checked in the game** (the four projects marked done by the test aid):
the pistol shot's breakdown read "Mag Pistols: crit=25, Rail Pistols:
aim=15" for both soldiers carrying pistols. Reflex Pistols' damage and
Improved Medikit's heal were not seen in play.

The shot probe now also logs the pistol shot's breakdown.

### Decisions

- **Improved Medikit gives +3, Long War's text.** EW's constant
  `MEDIKIT_FOUNDRY_BONUS` is 2, which matches the text's number for
  Restorative Mist.
- **These numbers are in the mod's code**, not generated from the player's
  install. They are EW's constants or Long War's text, written in the
  effect.

### Left open

- ~~Tactical Rigging~~, ~~Alien Grenades~~ (done since, below), Improved Arc Thrower (EW's stun thresholds 3 and
  6 HP), Ammo Conservation, Advanced Servomotors, and the projects for SHIVs
  and MECs.

**Ammo Conservation** (the Foundry's project 10). Long War keeps both clips
in a weapon's `iSuppression` as xxyy: xx with the project, yy without (its
ini says so). The gear config now carries both (`AmmoConserved`). At a
mission's start the charges effect sets the clip on Long War's weapon
templates from whether the project is done, so reloads fill to it, and
fills each soldier's weapons.
- **Checked:** with the project done, the clips were sniper rifle 6,
  pistol 3, rifle 4, LMG 7. Without it, in that night's other missions, they
  were 5, 2, 3, 6.

## Report (2026-11-02 night, Tactical Rigging)

The Foundry's Tactical Rigging (project 24): "granting all soldiers the
ability to carry one additional small item" (Long War's words for the
starting bonus that gives it).
- XCOM 2 puts a soldier's utility slots back to the character's base
  (+1 for an armour that adds one) whenever the loadout changes, so a slot
  given on the soldier alone would not last. **`LWX2Gear.ApplyRigging`**
  raises the base of XCOM 2's `Soldier` character from the campaign's state
  (1, or 2 once the project is done), and puts each Long War soldier's
  slots to it. It runs with the arming pass, whenever soldiers are looked
  at or sent out.
- **Checked** (a new campaign): soldiers in Tac Armor had 2 slots. With
  the project marked done and the arming pass run, they had 3. A soldier
  then given two more small items carried "XPad LWSmall_81 LWSmall_73
  LWSmall_73, slots 3": XCOM 2's reset on equipping kept the third.

### Decisions

- **The character's base is changed in memory**, set again from the
  campaign at every arming pass. Templates are not saved, so loading
  another campaign sets it to that campaign's state at its first pass.
- **Every soldier, of any armour**, as Long War's words say "all
  soldiers".
- **Looked at in the armory** afterwards (a new test aid, `open loadout`):
  a sniper in Tac Armor showed three utility item slots, an HE grenade
  and two empty.

## Report (2026-11-02 night, Alien Grenades)

Read from Long War's code (`XGFacility_Engineering.OnFoundryProjectCompleted`,
`XGFacility_Barracks.UpdateGrenades`): when Alien Grenades (project 2) is
done, **the alien grenade (84) becomes unlimited in the stores, and every
frag grenade (81) a soldier carries is replaced by one**. Long War never
builds the alien grenade otherwise (its item tree gives Foundry 255).
- **`LWX2Gear.SetFoundryInfinite`** marks the alien grenade's template
  unlimited from the campaign's state, and the stores get one as the
  other unlimited items do.
- **`LWX2Gear.ApplyFoundryGear`** makes the swap once, from the arming
  pass after the project is done. It records the project in
  `FoundryApplied`, so a player may carry frag grenades again afterwards,
  as in Long War, and leaves a note.
- **Checked** (a new campaign): soldiers carried "XPad LWSmall_81". With
  the project marked done and the arming pass run: "LWSmall_84", and the
  note "Alien Grenades: 12 frag grenades carried are alien grenades now".
  The project was recorded as applied, and a second pass changed nothing.
  The alien grenade was in the stores.

### Decisions

- **Only what Long War's code does.** The project's text also promises
  deadlier AP grenades and HE grenades with 40 % more area; the completion
  code does neither, and no constant for them was found. Not added.
- **Once, from the arming pass**, rather than at each of the three places
  a project completes (engineering's start, the hourly tick, the test
  aid). The pass runs at the Geoscape and whenever soldiers are looked at.

### Found after, left open

- Long War also gives every soldier a **perk per Foundry project**
  (`XGFacility_Barracks.UpdateFoundryPerksForSoldier`), and only while the
  base has a Foundry: Scope, the pistols, Ammo Conservation, Improved Arc
  Thrower, the capture drone, Elerium fuel, Shaped Armor and **Alien
  Grenades** (`ePerk_Foundry_AlienGrenades`, 125).
- That perk is read in EW's tactical code in three places:
  - `XGWeapon.GetDamageRadius`: the frag grenade's (81) radius times 2.0
    (as decompiled; the text says "40 % more area", which does not fit);
  - `XGAbility_Targeted.TShotInfo_ToString`: +2 for items 79 and 86, in a
    function that only displays;
  - `XComWeapon.PrepareProjectile`: another projectile for item 24.
- Not built: what the radius line means needs a closer reading, and the
  damage itself is not in readable code. The port's pistol projects and
  Ammo Conservation do not ask for a Foundry in the base either.
