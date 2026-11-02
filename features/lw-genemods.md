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

## Report (2026-11-02 night, Adrenal Neurosympathy)

**Adrenal Neurosympathy**: when the soldier kills, squadmates within 6
tiles gain +10 aim, +5 crit and +2 mobility (`GENEMOD_ADRENAL_AIM`, `_CRIT`,
`_MOBILITY`) until the soldier's next turn; then 5 turns before it can
happen again. It is an ability triggered by XCOM 2's `KillMail` event.
- **Checked:** with it and Rift given to the squad, one soldier's Rift
  killed two Sectoids. The three squadmates gained
  `LW_AdrenalNeurosympathy_Rush`; the killer did not ("all nearby
  squadmates").
- **Decision:** the reach is 6 tiles (APPROXIMATION); Long War's number is
  not known.

### Left open

- Stand-ins still:
  - Bioelectric Skin: nearby enemies revealed (its immunity to
    strangulation is in since, below);
  - ~~Muscle Fiber Density: climbing~~ (XCOM 2's grapple since, below).
- ~~Neural Damping's +20 will against psi~~ (done the same night, below);
  the post-mission fatigue of every mod.

## Report (2026-11-02 night, Neural Damping's will against psi)

Neural Damping now gives +20 will against psi attacks
(`GENEMOD_BRAINDAMPING_WILL`; its words say "+<GeneModBrainDampingWill>
will against psionic attacks"), besides its immunity to panic.
- XCOM 2's psi check (`X2AbilityToHitCalc_StatCheck_UnitVsUnit`: base +
  psi offence − will) reads the stat itself and asks no effect. So
  **`AddPsiChecks`** gives every ability checked against will a subclass,
  `X2AbilityToHitCalc_LWPsiCheck`, which adds the target's `PsiWill`
  (a new stand-in field, generated). The log at start: "17 psi abilities
  checked". These are the aliens' and Long War's powers alike.
- A new test aid, `psichance`: the aliens' psi abilities' chances against
  each soldier.
- **Checked** (a new campaign's first abduction, 7 Sectoids): Mindspin
  against Harumi Murakami (will 43) was 122 %. With Neural Damping given,
  it was "will 43 + 20: 102%"; the others were unchanged.

### Decisions

- **Against every psi ability checked against will**, not a list of
  Long War's. The aliens' psi attacks are XCOM 2's (Mindspin and so on),
  which is what the soldier meets.
- **XCOM 2's own numbers stay**: a Sectoid's Mindspin starts above 100 %
  against these soldiers. That is XCOM 2's Sectoid, standing in for EW's
  until step 3.

## Report (2026-11-02 night, Muscle Fiber Density: the grapple)

"Confers superhuman leg strength, enabling the soldier to reach high
positions without the need for ladders or other climbing aids."
- **Now Muscle Fiber Density brings XCOM 2's Grapple** (the Spider Suit's:
  a free action, cooldown 3, to the grapple points XCOM 2 finds on the
  map). This uses a new stand-in field, `AlsoGrants`: an XCOM 2 ability
  that comes with the stand-in, as `AdditionalAbilities`.
- **Checked, in part:** the mod given in the strategy layer to the squad,
  then a mission. The grapple was in the soldier's bar (slot 6), and the
  control port read "Grapple available AA_Success". Given mid-mission with
  the `perk` aid it does not come: that aid writes the soldier's abilities,
  which XCOM 2 reads at the mission's start.
- **Not seen used.** The key sent to open the grapple's targeting did not
  reach the game (nothing in the log). After it, the world drew black
  under a working HUD, and the pause menu came up over the black.
- **Explained the same night: the test tool, not the game.** `key.ps1 6`
  sent the virtual key 6, which is the mouse's XButton2, not the digit. It
  turned the world black again in a second mission. `key.ps1` now sends a
  digit as its key (`D6`), and with that the grapple's targeting opened
  ("Grapple: Deploy a grappling hook to move quickly to an elevated
  position"). In a third mission (the test machine's copy of the tool not
  yet updated, so the world went black once more), the targeting opened
  with `D6` and Enter confirmed it. Afterwards the control port read
  "Grapple available AA_CoolingDown": **the soldier grappled**, and the
  grapple is on its cooldown. The move itself was not seen, since the world
  was black.

### Decisions

- **A grapple for a passive.** Long War's soldier climbs as a way of
  moving; XCOM 2's nearest thing is the grapple, an action with a
  cooldown (APPROXIMATION). The other choice, XCOM 2's wall-climb
  traversal, is a character's setting, not something an ability gives.

## Report (2026-11-02 night, Bioelectric Skin: no strangling)

"The soldier projects an electric field from his or her skin, revealing
but not alerting nearby enemies, and is immune to strangulation." EW's
strangler is the Seeker; XCOM 2's is the Viper's Bind.
- **Now Bind cannot target a soldier with Bioelectric Skin.** A new
  stand-in field, `BlocksAbilities`, names XCOM 2 abilities that cannot
  target the soldier. `AddBlocks` gives those abilities a target condition
  (`X2Condition_LWOwnerLacks` with `bTarget`).
- The test aid `psichance <ability>` now also shows the ability's target
  conditions' answer.
- **Checked** (Bioelectric Skin given to three soldiers; a Viper spawned
  beside the squad): Bind read "AA_UnitIsImmune" against Sung Min Yang and
  Oliver Thomas, 1 tile away, and "AA_Success" against Kaun-Yin Zheng
  beside it, who has no Bioelectric Skin.

### Decisions

- **Only the strangling.** "Revealing but not alerting nearby enemies"
  needs a moving reveal XCOM 2 has no ready piece for; left out.
