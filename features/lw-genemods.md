---
title: "Long War's gene mods: the Genetics Lab's tanks, and the mods in missions"
status: review
priority: 31
dependsOn: [lw-base, lw-classes, lw-psi]
---

# Long War's gene mods

Enemy Within's gene mods, as Long War tuned them: ten mods in five slots
(chest, brain, eyes, skin, legs), a soldier one mod a slot. Each is made in
the Genetics Lab for a price, meld and days in the tank, once its research
is done.

## What Long War does (read from the player's install)

- **Its "Gene Mod Configuration"** (`ItemBalance_Easy` entries, its
  `DefaultGameCore.ini` comment naming the columns): the cost, the tech
  required, the meld, the days in the tank, the post-mission fatigue.
- **The slots** (`XComPerkManager.GeneModPerkTree`): chest (Secondary Heart,
  Adrenal Neurosympathy), brain (Neural Damping, Smart Macrophages), eyes
  (Hyper-Reactive Pupils, Depth Perception), skin (Bioelectric Skin, Iron
  Skin), legs (Muscle Fiber Density, Adaptive Bone Marrow).
- **The tanks**: `PSI_NUM_TRAINING_SLOTS` (3) a lab; its ini says this
  number counts for the Psi Labs, the Genetics Lab and the Cybernetics Lab.
- **The mods' numbers** (EW's code constants): Pupils +10 aim after a miss,
  Depth Perception +5 aim and +5 crit from height, Neural Damping +20 will
  against psi, Bone Marrow 2 HP a turn, Secondary Heart +2 bleed-out turns.

## Report (2026-11-02 night)

**Done:**
- **Config**: `base-config.mjs` writes the ten mods to `XComLWBase.ini`
  (`LWBaseRules.GeneMods`), with their slots. `classes-config.mjs` makes
  each an ability with Long War's name, words and XCOM 2's gene mod icons
  (`X2Ability_LWStandins.GeneAbilities`).
- **The tank** (`XComGameState_LWStrategy.GeneTrainees`):
  - `StartGeneMod` needs the Genetics Lab built, a free tank, a soldier
    ready for duty with no mod in that slot, the research, the cost and
    the meld;
  - the cost and meld are paid at the start;
  - the soldier is out of the barracks for the days, and comes out with
    the mod as their own ability, noted on the Geoscape.
- **The base screen** has a Genetics Lab line once the Lab is built
  (soldier, mod and slot, cost, MODIFY, who is in the tanks).
- **In missions**:
  - Iron Skin: damage taken −1;
  - Depth Perception: +5 aim and crit with height;
  - Hyper-Reactive Pupils: +10 aim after a miss (each shot's result
    noted for the next);
  - Neural Damping: immune to panic;
  - Smart Macrophages: immune to poison and acid, and medikits used on
    the soldier heal 2 more;
  - Adaptive Bone Marrow: 2 HP a turn (XCOM 2's regeneration).
- **Control port**: `gene` lists the mods, what each needs, who is in the
  tanks. `gene <soldier> <perk>` puts a soldier in.

**Checked in the game:**
- With the Lab placed and Xenogenetics researched (Long War's renamed
  `eTech_Meld`), two soldiers went in for Hyper-Reactive Pupils and Depth
  Perception: 72 hours each, 6 meld each (32 → 20).
- With the clock run on, both came out with their mod. A second eyes mod
  for one of them was refused: "needs a soldier without a mod there
  (Eyes)".
- On the screen: the mod chosen, MODIFY clicked, "Into the gene tank"; the
  line read "§10, 6 Meld, 3 days | April Gordon: … 72h".
- In a mission (mods given by the test aid), a frag grenade at the
  squad's feet:
  - the soldiers with Iron Skin took 2 (7 → 5, 8 → 6), the one without
    took 3 (7 → 4);
  - at the next turn the wounded regenerated 2 (4 → 6, 6 → 8: Bone
    Marrow).
  - Smart Macrophages' extra heal was not seen: the heal reached the
    soldier's maximum.

### Decisions

- **The tanks share the Psi Labs' number (3 a lab)**, as Long War's ini
  says.
- **The cost is Long War's number as it stands** (§10 to §30). Its column
  is labelled "$Cost"; no multiplier was found.
- **The slot is kept as a string.** As an UnrealScript name, "Brain"
  showed as another name's case ("bRain").

## Report (2026-11-02 night, Secondary Heart)

**Secondary Heart is an effect of its own** (`X2Effect_LWSecondaryHeart`),
named in XCOM 2's `PreDeathCheckEffects` (XComGameData.ini, generated):
- When XCOM 2 decides a soldier with it dies, the effect puts them into
  bleeding out instead, as XCOM 2's protected `ApplyBleedingOut` does.
- It works once a mission, and adds 2 turns to the bleed-out timer
  (`GENEMOD_SECONDHEART_BLEEDOUT`).

**Checked, partly:** frag grenades thrown at a squad that all had it left
two soldiers bleeding out. But the effect's log line did not appear: XCOM
2's own bleed-out chance had put them there, before any death was
decided. The effect's own path is not yet seen in play.

**Left open:** the 2 extra turns apply only when the effect itself saves
the soldier, not to XCOM 2's own bleed-outs.

### Left open

- Stand-ins still:
  - Adrenal Neurosympathy: a kill's buff to nearby squadmates;
  - Bioelectric Skin: nearby enemies revealed;
  - Muscle Fiber Density: climbing.
- Neural Damping's +20 will against psi; the post-mission fatigue of
  every mod.
