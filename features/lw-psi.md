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
