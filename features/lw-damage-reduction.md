---
title: "Long War's damage reduction: a fraction of each hit taken off, by cover, armour and the aliens' own"
status: review
priority: 34
dependsOn:
  - lw-classes
  - lw-aliens
  - lw-officers
---

## Purpose

Long War takes part of every hit off before it lands: units in cover, hunkered units, heavy
armour, armoured aliens. It is what makes cover matter for damage as well as for aim, and what
makes a Muton Elite or a Sectopod tough. The port had none of it (STATUS: Damage reduction,
none, found while doing the officers); the aliens' reduction had been rounded into XCOM 2's
armour, which works differently (whole points, shredded, pierced). Fortiores Una, the tenth
officer power, waited on it.

## Long War's rule, as read (2026-11-16)

From Long War's `XGUnit.AbsorbDamage` (stock Long War 1.0's `XComGame.upk`, read with the
Tree's `upk_script.py`; decompiled output kept out of the repository), its item texts and its
`DefaultGameCore.ini`. The damage of a hit, as a fraction, in this order:

- **The unit's own** less: the `xxyy` stat Long War keeps it in, in tenths. The aliens' comes from
  their species and research upgrades (`BalanceMods_Normal`, already read by `aliens-config.mjs`);
  items' from `BalanceMods_Classic` `iHP` ("damage reduction, works for weapons/armor/items; 5 =
  0.5"): Titan armour 0.5, Archangel 0.3, the SHIV decks and MEC suits, Reinforced Armor 1.
- Mind Merge's (`m_iWillCheatBonus / 50`), Damage Control (1.5 for some turns), One For All (1),
  a Mechtoid's link (15), Combat Stims (×0.6), Chitin Plating against melee (×0.6).
- **A shield up**: ×0.5.
- Shock-Absorbent Armor (×0.67 within 4 tiles), Absorption Fields (×(0.6 + 0.4 × min(2 / damage, 1))).
- **Acid**: back at least 3, or half of what was taken off so far.
- **In cover and not flanked by the attacker** (and not hit by a needle grenade):
  - low cover 0.667, high cover 1;
  - **hunkered down**, as much again;
  - **Will to Survive** 1.5 ("1 to 2 points");
  - **Fortiores Una** ("members of your squad within 8 tiles gain double the base damage
    reduction from cover"), as much again.
- **The attacker**: **Combined Arms** ignores 1; Armor Piercing Ammo 2 (not with sidearms or
  shotguns); **Gauss weapons** 0.34 (`COUNCIL_FUNDING_MULTIPLIER_EASY`, "1 in 3 chance of
  nullifying a point"), 0.68 with the Foundry's project 44 (its `m_arrFoundryHistory[44]`; "Phoenix
  Coilguns" in Long War's words). Never more than the hit.
- **Shotguns** (Long War's assault-class weapons, not the sawed-off) meet the reduction once more
  at half (×1.5); Breaching Ammo cancels that.
- Not below 0; then the fraction rounds **up by chance** (2.5 is 3 half the time).

## Report (2026-11-16)

**In:** one passive on every character (`LWX2_DamageReduction`, `X2Ability_LWDamageReduction`)
whose effect changes the damage of each hit as XCOM 2 lets a target do
(`GetDefendingDamageModifier`), with Long War's order and numbers for what the port has:

- the unit's own: Long War's aliens' (`LWX2DR`, set by `LWAlienStats`) and its armour's
  (`LWGearRules.Armors` `DR`, from `BalanceMods_Classic`: Titan 0.5, Archangel 0.3);
- a shield up; acid (XCOM 2's poison or acid on the unit);
- cover as the attacker sees it (in its line of sight; else, as for a grenade out of sight, the
  best cover at the tile), hunkering, Will to Survive (1.5), Fortiores Una (the leader and those
  within the officers' 8 tiles);
- the attacker's Combined Arms and Gauss weapons (twice with Foundry project 44); shotguns' ×1.5;
- the fraction rolled up by chance on the hit; the preview shows the nearer whole number.

Burning, acid and poison each turn are not reduced (XCOM 2 passes its armour by for them too).
Long War's aliens no longer carry XCOM 2's armour: their reduction is Long War's (an ADVENT MEC
standing in for a Drone had XCOM 2's 2; it now has the Drone's 1.0).

**Changed with it:**
- Will to Survive was XCOM 2-style 2 points off in cover (EW's constant); it is Long War's 1.5 in
  the reduction now.
- Combined Arms was a point of XCOM 2 armour piercing; it is Long War's point of reduction now.
- **Aliens on XCOM 2's own plots** (a mission whose kind has no converted Enemy Within map)
  had XCOM 2's stats: Long War's squad was written into XCOM 2's encounters by template, but
  nothing recorded each alien's species. At the battle's start each alien that came is now
  matched to the squad in order (`LWMissionSquads.SpeciesForEncounters`) and given its species
  and Long War's stats, as the aliens at Enemy Within's pods are; the top-up pods pass theirs
  too. Checked: an abduction on an XCOM 2 plot, 11 aliens given theirs (Sectoids at Long War's
  3 HP, where they had XCOM 2's 8).

**Checked on wingpu** (abductions on XCOM 2 plots, the control port's `dr`):
- a grenade's 3 on a soldier in Titan armour: "left 2.5, rolled 3" in the log, the others in the
  open 3 with nothing taken off;
- a Sectoid's 4 on a soldier in high cover 3, in low cover 3.333; with a Fortiores Una captain
  leading, 2 and 2.666; hunkered down as well, 1 (5: 2);
- the same soldiers seen by an adjacent squadmate: flanked, nothing taken off;
- the Drone (an ADVENT MEC) 1.0 of its own: a 4 leaves 3.

Control port: `dr` (each unit's own reduction, XCOM 2 armour and cover), `dr <#attacker>
<#target> <damage>` (what a hit leaves, and why), `dr tocover <unit> [high]` (a soldier walked
to the nearest tile with cover); `officers mark` (the squad's leader marked again in a mission).

### Decisions

- **One effect on every unit**, not XCOM 2's armour: Long War's reduction is a fraction rounded
  by chance and is not shredded; XCOM 2's armour stays for what still has it (nothing of Long
  War's).
- **Cover out of the attacker's sight** (a grenade over a wall) is the best cover at the tile:
  XCOM 2's record of a pair without a line of sight keeps no cover worth reading; Long War's
  `IsFlankedBy` is geometry alone.
- **The preview rounds to the nearer whole number**; the hit rolls.

### Left open

- What the port does not have yet: MEC and SHIV reductions (Damage Control, One For All,
  Absorption Fields, Shock-Absorbent Armor, their suits' own), Combat Stims, Chitin Plating,
  Armor Piercing and Breaching Ammo, Reinforced Armor, the Mechtoid's link. Mind Merge keeps its
  whole point (its will bonus, which Long War divides by 50, is not known).
- Psi Screen ("1 DR to Psi") is left out: its text says against psi only.
- The number beside the shield icon Long War shows after a hit (the reduction resisted) is not
  shown; XCOM 2 shows its own armour's.

## Report (2026-11-16, SHIV decks and MEC suits)

A SHIV's deck and a MEC's suit now reduce damage by their items' amounts in Long War's
`BalanceMods_Classic` (`iHP`, in tenths), as the soldiers' armours already did:
- SHIV decks: SHIV 1.5, Alloy SHIV 2.5, Hover SHIV 2.0;
- MEC suits: 1.0 to 2.5.

`shivs-config.mjs` and `mecs-config.mjs` write them as `DR=`; `OwnReduction` adds them.

**Checked on wingpu:** a Sectoid's 6 left 3.5 on an Alloy SHIV and 5 on a MEC in its first suit.

Still left open from the MEC and SHIV list: Damage Control, Absorption Fields and Shock-Absorbent
Armor. These are MEC perks; they act as stand-ins today. One For All is no Long War MEC's.

## Report (2026-11-16, Shock-Absorbent Armor and Absorption Fields)

Two of the MEC classes' perks now act as Long War's `AbsorbDamage` has them, after a shield:
- **Shock-Absorbent Armor** (upgrade 143): damage ×0.67 from an attacker within 4 tiles
  (`ShockFactor`, `ShockTiles`).
- **Absorption Fields** (142): over 1 damage, ×(0.6 + 0.4 × min(2 / damage, 1)), so at most 40%
  off.

**Checked on wingpu** with the control port's `perk` and `dr` on a soldier given both perks. A
Sectoid's 6:
- from 5 tiles or more left 4.4 (Absorption Fields ×0.733);
- from 3 tiles left 3.21 (×0.67, then ×0.799).

**Damage Control is left out.** Long War's rule takes 1.5 off while `m_iDamageControlTurns` is
above 0. The only places in Long War's code that set that number are `XGAction_Strangle` (2) and
`XGUnit.UpdateItemCharges`, which uses it as a loop counter and leaves it at 0. Nothing gives a
MEC its turns when it is hit, so the perk does next to nothing in stock Long War, and the port
leaves it as a stand-in.

Repair Servos (repairs half the damage taken, at most 2 a turn) is still a stand-in.
