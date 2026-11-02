---
title: "Long War's psionics: training psi powers in the Psi Labs, and the powers in missions"
status: in-progress
priority: 30
dependsOn: [lw-base, lw-classes]
---

# Long War's psionics

Long War 1.0 replaced Enemy Within's single psi test with training, one
power at a time, in the Psi Labs. Here it is ported: the Labs' training
(time, the chance, the slots) on the Long War Geoscape's clock, and the
powers as XCOM 2 abilities in missions.

## What Long War does (read from the player's install)

- **Twelve psi powers**, each with a **target will**, the **tech** that
  opens it, a **tier** and the **post-mission fatigue** it imposes. Long
  War keeps these in `ItemBalance_Easy` entries, whose cash, elerium,
  alloys and engineers fields it reads as those four numbers
  (`XComPerkManager.GetPerkInTreePsi`).
  - Neural Feedback, Regen Biofield and Mindfray: will 50.
  - Inspiration and Distortion Field: 60.
  - Mind Merge and Panic: 70.
  - Telekinetic Field, Pyrokinesis and Psychokinetic Strike: 80.
  - Mind Control: 95.
  - Rift: 120.
- **Training** (`XGFacility_PsiLabs.AddSoldier`): up to
  `PSI_NUM_TRAINING_SLOTS` (3) soldiers at once. Each trains one power for
  `PSI_TRAINING_HOURS` (192) × the power's target will ÷ the soldier's
  will, in hours. The soldier is out of the barracks meanwhile.
- **The chance** (`XGFacility_PsiLabs.RollForGift`), with W the soldier's
  will, T the power's target will and G = 100 × `PSI_GIFT_CHANCE` (45):
  - while W ≤ T + 80 − G: W − T + G, at least 1;
  - above that: 100 − 400 / ((W − T) + (G − 60)), at most 99;
  - plus a council bonus (not ported).
  So a soldier of will 50 has 45 % for a will-50 power, and one of will
  70 has 65 %.

## Steps

1. **The Labs' training on the Geoscape**: the powers as config (generated
   from the player's install), a training list in Long War's campaign
   state, time passing, the roll, the power given as the soldier's ability.
   A screen in the base (the Psi Labs built), and control port commands.
2. **The powers in missions**: Mindfray, Panic, Mind Control, Inspiration
   first, on XCOM 2's status effects; psi strength from the soldier's will.
   The rest as stand-ins until done.

## Report (2026-11-02, step 1: training in the Psi Labs)

**Done:**
- **The powers as config.** `base-config.mjs` writes Long War's training
  numbers and the twelve powers to `XComLWBase.ini`
  (`LWBaseRules.PsiPowers`).
- **Each power an ability with Long War's name and words.**
  `classes-config.mjs` adds them to the stand-ins and to the words plan
  (`X2Ability_LWStandins.PsiAbilities`). Where Long War left a power's
  title empty (Pyrokinesis), the name in its ini's comment is used.
- **Training in Long War's campaign state** (`PsiTrainees`):
  - it begins with `StartPsi`;
  - it needs the Psi Labs built, a free place (3 per Labs), a soldier
    ready for duty without the power, and the power's research;
  - Rift needs Mind Control first, as Long War codes it.
- **Time and the roll.** The hours count down on the Geoscape's clock. At
  the end comes the roll with Long War's chance; on success the power is
  the soldier's own ability (a class-agnostic soldier ability), and the
  Geoscape notes it either way.
- **Soldiers in training are not sent on missions.**
- **Control port:** `psi` lists the Labs, each power's target will, the
  first ready soldier's chance and hours, what is missing, and who is
  training. `psi <soldier> <perk>` begins training.

**Checked in the game:**
- With the Labs placed (test aid) the list read, for a soldier of will
  45: Mindfray 40 %, 213 hours (45 − 50 + 45; 192 × 50 ÷ 45); Mind Control
  1 %; Rift "needs Mind Control first". Before the research, every power
  said "needs its research".
- After Xenopsionics, two soldiers trained Mindfray: 213 hours at 40 % and
  188 hours at 46 %.
- With the clock run on, both gained it ("rolled 31 against 46", "rolled
  18 against 40"), and the Geoscape noted each.

### Decisions

- **A failed roll costs only the time.** The soldier may train again; the
  part of Long War's code that would say otherwise could not be read
  (decompiled with gaps).
- **The council's bonus to the chance (`HasBonus(55)`) is left out.**
- **The power's tier and its post-mission fatigue are kept in the config
  but not applied yet.**
- **No screen yet.** Training is begun from the control port. A Psi Labs
  panel in the base screen is next, with step 2.

## Report (2026-11-02, step 2: four powers in missions)

**Mindfray, Panic, Mind Control and Inspiration work as abilities**
(`X2Ability_LWStandins.PsiPower`, for stand-ins with a `PsiKind`):
- **The attacking three** check will: XCOM 2's
  `X2AbilityToHitCalc_StatCheck_UnitVsUnit` with the soldier's will
  against the target's, base 50. Mind Control's base is 15 (50 + Long
  War's `MIND_CONTROL_DIFFICULTY`, −35). Robots are immune.
  - Mindfray: XCOM 2's disoriented, and 1 damage (Long War's text: "one
    base damage").
  - Panic: XCOM 2's panicked; cooldown 2.
  - Mind Control: XCOM 2's mind control for 3 turns; cooldown 5.
- **Inspiration**: aimed at a place. Allies within 3 tiles lose
  disorientation and panic and gain +30 will (`PSIINSPIRED_WILL_BONUS`)
  for 2 turns; cooldown 4.
- Each costs an action and ends the turn. The cooldowns and durations are
  EW's, from its ability table, counted as the soldier's own turns.
- **Bound to the soldier's primary weapon**, both when the Labs give the
  power and in the test aid. XCOM 2 measures a single-target ability's
  reach by its weapon (its psi powers by the psi amp's); unbound, every
  target was "not in range".
- **No firing animation.** Soldiers have no psi animations; the effects
  show without one.
- **Icons**: XCOM 2 still carries EW's psi icons (`UIPerk_psi_mindfray`
  …), now found by the generator for all the powers.

**Checked in the game** (all four given to the squad by the test aid,
soldiers put 6 tiles from a pod):
- Mindfray from four soldiers: one hit. The Sectoid went from 8/8 to 7/8
  and carried `Disoriented`.
- Inspiration at a soldier's feet: the three soldiers in its area gained
  `LW_PsiInspiration_Will`, with their will up 21 to 27.
- Panic was used and then reported `AA_CoolingDown`. The target listed
  first was one of our soldiers, mind-controlled by a Sectoid, so its
  effect was not seen.
- **Mind Control not tried**: its soldier was bleeding out.
- The `near` test aid put three soldiers on one tile (it does not check
  for units there).

### Decisions

- **Base 50 for the will check** (APPROXIMATION). EW's psi chance formula
  was not read.
- **Each power ends the turn.**
- **Mindfray has no cooldown, and lasts as XCOM 2's disorientation does.**
  Long War's duration and cooldown for it are not known (its words show
  them unfilled).

### Left open

- The other powers are stand-ins: Neural Feedback, Regen Biofield,
  Distortion Field, Mind Merge, Telekinetic Field, Pyrokinesis,
  Psychokinetic Strike, Rift.
- Psi XP and ranks (`m_iPsiXPLevels`); the tier and fatigue numbers.
- ~~A Psi Labs panel in the base screen.~~ Done the same night, below.

## Report (2026-11-02, the Psi Labs panel)

**The base screen has a Psi Labs line once the Labs are built**
(`UILWBase.RefreshPsi`). It holds the soldier (cycled among those ready and
not training, with their will), the power (cycled), the chance and hours,
what is missing ("needs its research"), and who is training with the hours
left. TRAIN begins training.

**Checked on the screen:**
- The Labs placed, the power cycled to Mindfray, TRAIN clicked: "Psi
  training begun." The line read "46 %, 188 hours | Olav Karlsen: Mindfray
  204h", and the control port's list agreed.
- With the words written on the test machine, the powers show Long War's
  names (Neural Feedback, Mindfray).

**On the way:** the facility line's text moved right of its arrow buttons,
which covered "TO BUILD". The "<" button draws as a thin line only, as it
did before.

**Test aid:** `open base|hangar|engineering` opens the Geoscape's screens
as their buttons do.

## Report (2026-11-02 night, Telekinetic Field and Rift)

- **Telekinetic Field**: the psion and allies within 12 tiles gain +40
  defence (`TELEKINETIC_FIELD_DEFENSE_BONUS`) until the psion's next turn,
  so through the enemy turn; cooldown 4.
- **Rift**: 8 psi damage (`RIFT_START_DMG`) to every unit within 6 tiles of
  the place chosen (XCOM 2's Void Rift targeting); cooldown 4.
- **Checked:** Telekinetic Field cast by one soldier put
  `LW_TelekineticField_Defense` on all four. Rift aimed at the nearest
  Sectoid killed the two nearest (8 HP each); they were gone from the list
  of the living.

### Decisions

- **The radii are read as tiles.** EW's constants (12.75, 6.75) follow
  Inspiration's pattern: 3.75 for Long War's "within 3 tiles".
- **Rift does the same damage to every target** (APPROXIMATION). Long War
  scales it by the target's will (`RIFT_WILL_BALANCE`, `RIFT_WILL_DMG_SLICE`,
  a minimum of 4 to 5). Its psi armour requirement is not applied yet.

## Report (2026-11-02 night, Mind Merge and Psychokinetic Strike)

- **Mind Merge**: an ally in view gains +25 critical chance
  (`MINDMERGE_CRIT_BONUS`) and takes 1 less damage until the psion's next
  turn; cooldown 1. Long War's "bonus will" is left out: its number is not
  known.
- **Psychokinetic Strike**: environment damage within a tile of the place
  chosen, no unit harmed; cooldown 2. The radius and strength are guesses
  (APPROXIMATION).
- **Checked:** Mind Merge put `LW_MindMerge_Merged` on the soldier
  chosen. The first try had picked a non-unit object from the target list;
  the condition now refuses those.
- **Psychokinetic Strike** was used ("used at …") but its effect on the
  ground was not checked.
