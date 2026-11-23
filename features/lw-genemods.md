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

## The person's review (2026-11-02, recorded by the agent)

- **Muscle Fiber Density is not a grapple**: it lets the soldier jump up
  without an action. XCOM 2 has that move: the `JumpUp` traversal (ADVENT
  MECs, Chryssalids, Faceless), and `X2Effect_PersistentTraversalChange`
  gives a traversal to any unit. **Next**: the grapple replaced by a
  passive JumpUp traversal; to check that soldiers have an animation for
  it.

## Report (2026-11-16, the Genetics Lab on EW's own Gene Mods screen)

The person's answer (2026-11-16): gene mods on EW's own screen; the soldier
chosen on XCOM 2's list, as for the barracks.

**The hub's Barracks → Genetics Lab** (once built) opens XCOM 2's list of the
soldiers who could go into a tank now (`UIPersonnel_LWGene`: ready for duty,
not in a lab, a tank free), over the base with the camera in the Genetics Lab.
A soldier chosen, **EW's own Gene Mods screen** (`UILWEWGeneMods`, EW's
SoldierGeneMods movie, driven as Long War's `UISoldierGeneMods` drives it):

- the five body parts with their two mods each, in EW's places and with EW's
  pictures for them (Long War's perk images): grey with a question mark until
  researched, yellow the soldier's, cyan open; a body part greyed when neither
  of its mods is researched;
- hovering a mod: its name and Long War's words, what a click does, and its
  meld and cash, in red where there is not enough; "LOCKED" and Long War's
  words for one not researched;
- clicking chooses or unchooses a mod, as EW's tick; choosing one of a body
  part unchooses the other;
- the soldier's header and stats on EW's panels: name, flag, rank, class (the
  EW class Long War's grew from), missions, kills, status; health, mobility,
  will, aim, defence, damage reduction;
- **CONFIRM GENE IMPLANTS** (an XCOM 2 button in Long War's words under the
  tree) raises EW's confirmation with the mods, those they replace, the days
  and the price; confirmed, into the tank, and the list again while a tank is
  free. Esc goes back to the list, and from the list out of the lab. With every
  tank full, the lab says so in Long War's words and names who is in them.

**Changed with it, as Long War's gene lab does it:**
- **Several mods in one stay** (`AddSoldierToGeneLabs`): a soldier goes in for
  all the chosen mods at once, paid at once, made one after the other
  (`XComGameState_LWStrategy.GenePatients`: Long War's `TGeneLabsPatient`,
  where there was one mod a stay). A tank holds a soldier, not a mod.
- **A mod replaces the other of its body part** (`Update`: the opposite perk
  set to 0): the soldier with Hyper-Reactive Pupils can go in for Depth
  Perception and comes out with Depth Perception only. Before, a soldier with
  a mod in a body part could not have the other.
- `XComLWBase.ini`'s gene mods carry their **column** in EW's tree
  (`GeneModPerkTree`'s Chest1/Chest2 …), read by `base-config.mjs`.
- Control port: `gene <soldier> <perk> [<perk>…]` puts a soldier in for
  several; `gene` lists each tank's mods with their hours.

**On the way:**
- **EW screens placed away from the corner of EW's stage** now scale with the
  stage (`UILWEWScreen.ScaleToStage`): XCOM 2's panel scale grows a clip about
  its own origin, so the Gene Mods screen (EW placed it at (582, 397)) reached
  past the top and left edges. The screens already in use are placed at the
  corner and are unchanged.
- `tools/convert/swf-as2.ts labels <movie>` lists a movie's frame labels (how
  the flags and class icons were found in EW's icon movie).
- The hub's Officer Training School fell through to the Psi Labs where EW's
  screens are not converted (my change this morning); it opens the plain
  base screen again there.

**Checked on wingpu** (new campaigns; Xenogenetics and the Sectoid autopsy
given, meld added, a Genetics Lab placed), all by mouse:
- Hyper-Reactive Pupils and Smart Macrophages chosen for one soldier: EW's
  confirmation read "You are about to implant: Hyper-Reactive Pupils, Smart
  Macrophages. This will take 7 days and will cost §25, 18 Meld."; confirmed:
  §500 → §475, meld 62 → 44, the Geoscape's "GENE MOD: <name>" with 7 days,
  the list back without that soldier;
- time run: Pupils made on the fourth day, Macrophages on the eighth, the
  soldier out; the screen showed both in yellow;
- Depth Perception chosen for the same soldier: "Doing so will remove:
  Hyper-Reactive Pupils"; three days later "gained LW_DepthPerception, lost
  LW_HyperReactivePupils".

Screenshots (gitignored): `logs/wingpu_ew_gene_mods.png`,
`logs/wingpu_ew_gene_confirm.png`.

### Decisions

- **EW's tick and the confirmation, not one mod a click**: EW's screen lets
  several mods be chosen and confirmed together; Long War's lab takes them in
  one stay, so the port's tank does too.
- **The confirm button is XCOM 2's**, in Long War's words, under the tree: EW
  confirmed through its strategy HUD's help bar, which this port does not
  have.
- **The class icon is the EW class's** (sniper, heavy, support, assault, and
  their gene-modded pictures): Long War's own class icons come from its
  config's image paths, which are not in XCOM 2.

### Left open

- **The soldier is not stood in the lab**: EW puts the soldier on the lab's
  plinth between the tree and the picture, with the X-ray view of the chosen
  mod. Here the camera looks into the lab with no one in it.
- **The mod's picture** (the large panel on the right): EW's pictures are in
  its strategy images package, which the setup does not convert; the panel
  shows its empty, red state.
- EW's words for a mod's description are set on the words' clip directly:
  EW's `SetDescription` casts the clip to its class first, and the cast finds
  nothing in XCOM 2's Flash player (`CastOp`). Whether other EW screens' casts
  fail the same way is not known.
- The plain base screen's Genetics Lab line remains for where EW's screens are
  not converted.

## Report (2026-11-16, the mods' pictures)

The large panel now shows **EW's own picture of the chosen mod** (`SetCalloutImage`, as EW's
`UISoldierGeneMods.RealizeSelected` sets it), or EW's locked picture for a mod not yet researched.

EW keeps its strategy pictures (`UILibrary_StrategyImages`: gene mods, science, inventory,
facility, interceptor, medal and credit icons; 303 textures) inside its base's map package,
`Command1.upk`. The setup converts that package already for EW's base. The pictures were in the
converted package, but they could not be found by their path. Their groups and textures kept
EW's forced-export flag, so `tools/convert/ew-images.ts` clears it. The setup, and `ew-maps.ts`
in development, run this step after converting the base, on every run; on a second run there
is nothing left to clear. A picture then loads as
`Command1.QILibrary_StrategyImages.<Group>.<Name>` (`UILWEWScreen.EW_IMAGES`).

**Checked on wingpu:** the Gene Mods screen showed EW's locked picture, then, after the Muton
Elite autopsy, EW's Secondary Heart picture when that mod was selected. The control port's `img`
loads or finds a texture by its path.

**Tried and dropped:**
- Converting EW's shell package (`XComShell.upk`), which carries the same pictures, as a package
  of its own: XCOM 2 loads such a package whole and crashed on the shell's level.
- The same package converted as a map but named like the pictures' package: it did not load.

### Left open

- **The other screens' pictures** (research, engineering, the Foundry, facilities, craft): in
  stock Long War these are empty too. Long War gives items, techs and projects image numbers
  (`BuildItem`'s `iImage` …) and turns them into paths through `XComOnlineProfileSettings`'
  `MultiplayerLoadoutSlots`, repurposed by Long War ("variable used to configure new imagedata").
  That table is in no config of stock Long War: its entries in `DefaultGame.ini` are commented
  out, and no package sets it. So its research, Foundry and officer-power screens show none,
  as the officers' report found for the powers. Only the gene mods (by perk), the medals and
  `GetStrategyImagePath`'s 69 paths name EW's pictures in its code. I'm leaving these screens
  as they are.
- The soldier on the lab's plinth.

## Report (2026-11-17, Muscle Fiber Density as a jump up, as the person asked)

**Muscle Fiber Density** is no longer XCOM 2's Grapple: it gives XCOM 2's **JumpUp** traversal (the one its Chryssalids
and ADVENT MECs use), a passive with no action of its own (`X2Effect_PersistentTraversalChange`, `Kind=JumpUp` in
`XComLWClasses.ini`; `classes-config.mjs`).

**Checked on wingpu** (the perk given to a sniper, a council bomb disposal on the Train Station): to the same raised
platform two levels up beside the squad, a soldier without it walked 17 tiles round by the stairs, both actions; the
soldier with it got there in 3 tiles, one action, and stands on the platform. Soldiers have an animation for it (the move
played through; not looked at frame by frame).

## Note (2026-11-17)

The "post-mission fatigue of every mod" left open above is in: `LWFatigue.PowersHours` adds each gene mod's hours
(`PerkHours`, Long War's `ItemBalance_Easy` iEng, with Gift of Osiris and Call to Arms cutting them as
`DetermineTimeOut` does). STATUS no longer lists it.

## Report (2026-11-17, Bioelectric Skin's reveal)

- **The reveal** (`LWX2Bioelectric`, twice a second in a mission): every living enemy within EW's `BioelectricSkinRange`
  (12 of EW's metres of 64 units: 768 units, eight tiles) of a soldier with Bioelectric Skin is drawn even out of sight (its
  visualizer forced visible, as XCOM 2's `X2Action_Fire` shows a target it cannot see; the game's visibility, which targeting
  uses, is untouched, so it cannot be shot unless seen, as in EW) and outlined as XCOM 2 outlines a unit the Reaper's Target
  Definition marked (`bAffectedByTargetDefinition`); both are switched off as it leaves the reach. In place of EW's aura
  particle (`P_Bioelectric_Skin_Enemy_Aura`), which the port does not have.
- **Checked on wingpu** (Bioelectric Skin given by the control port; `enemies` now prints each pawn's outline): Sectoids
  dropped 5 tiles from the squad were outlined and drawn; the pods 10 tiles and more away were not. **Not seen:** an enemy
  within reach but out of sight (the ones within reach were in the soldier's view), and the outline itself was not clearly
  visible in the screenshot at the camera's distance.
- With this the gene mods have no stand-in left (`STATUS.md`).

## Notes (2026-11-23, a false alarm)

- The click tests seemed to find that the mouse no longer chose a mod. It does: a click on Neural Damping at its place
  in the game's 1920 × 1080 UI (548, 135) chooses it ("CLICK TO REMOVE"). The test had clicked at a place read off a
  screenshot of the whole desktop (the windowed game drawn smaller within it), not in the game's UI coordinates; the
  measurements written here earlier came from that mistake and are withdrawn. The `gene-mods` journey checks it.
