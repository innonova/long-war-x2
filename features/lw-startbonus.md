---
title: "Long War's home country and its bonuses: the starting bonus and the country bonuses"
status: planned
priority: 32
dependsOn: [lw-geoscape]
---

# Long War's home country and its bonuses

The Long War Geoscape starts every campaign in the United States
(`XComGameState_LWStrategy.HomeCountry`); the choice of home and its bonus
are noted as not offered yet (`lw-geoscape.md`). Long War gives each
starting country a set of starting bonuses, and countries further bonuses.
All of it is numbers in its `DefaultGameCore.ini`, with each line's meaning
in a comment.

## What Long War keeps (stock Long War 1.0)

`ItemBalance_Classic` entries, after the "Coded starter bonuses" and
"Country Bonuses" comments:

- **Starting bonuses** (`eItem=0`, 39 lines): `iCash` the bonus's index;
  `iElerium` a country id (grouped: China 2, Germany 4, France 5, Egypt 18,
  Brazil 19 …); `iAlloys` a continent or slot; `iTime` the bonus's type;
  `iEng` its number. One per country is "On Our Own (Nothing / <country>)".
  The comments name every one:
  - Wealthy Benefactor (+500 starting cash), Foreign Legion (bonus
    soldiers), Cadre (4 soldiers of a rank);
  - Advanced Preparations (a lab and a workshop), Skunkworks (a foundry),
    Ring of Fire (steam vents);
  - Baumeister (facility build time), Deus Ex (gene mod cost and time),
    Legacy of Uxmal (psi training chance), The Old Path (psi training
    time), Roscosmos (satellite cost);
  - Foundry projects granted (For the Sake of Glory, Jai Jawan, Sukhoi
    Company, Resourceful, Their Finest Hour);
  - and more.
- **Country bonuses** (`eItem=1`, about 16 lines): the same columns.
  - Call to Arms, The Old Path, 1st Recce, Army of the Southern Cross,
    Jai Vidwan, Xenological Remedies;
  - Robotics, Spetznaz, Sandhurst, Cyberware, NeoPanzers, Bounties;
  - Expertise, Legacy of Uxmal, Task Force Arrowhead, We Have Ways.

## How Long War uses them (read from its code, the same night)

- **The start screen** (`XGContinentUI.Init`) offers every distinct
  (`iCash`, `iElerium`) pair of the starting bonuses: **the player picks a
  bonus and its country together**, one of the 39. The choice is kept in
  `XGHeadQuarters.m_iCountry`: the country, and the bonus's index in the
  high 16 bits.
- **`XGHeadQuarters.HasBonus(eBonus)`** sums the value (`iEng`, via
  `XGWorld.GetContinentByBonus`) of every entry whose `iTime` is eBonus:
  - a starting bonus (`eItem` 0) counts when its country is home and its
    index is the one chosen;
  - a country bonus (`eItem` 1) counts for a country other than home that
    has satellite coverage and has not left the council;
  - a continent bonus (`eItem` 2) counts while that continent's
    (`iAlloys`) bonus is held. The samples have no such entry.
- The rest of Long War's code asks `HasBonus` with the type numbers. Its
  psi code, read for `lw-psi.md`, asks 55 (Legacy of Uxmal: chance) and 43
  (The Old Path: hours), which matches the ini's comments.
- Country ids are EW's `ECountry`, which `strategy-config.mjs` already
  lists. The names are in Long War's `XComStrategyGame.int`
  (`ContinentBonusNames[type]`, `ContinentBonusDesc[type]`); they would
  need a localization file of the mod's own package (`LongWarX2.int`),
  written by the setup program like the other words.

## Why not built that night

The choice only means something once the bonuses' effects are in, across
the base, engineering, psi, gene mods, the soldiers and the Foundry; and
the names need the setup program to write a second file. That is a
feature to shape with the person, not to rush at the end of a night.

## Steps (proposed)

1. The bonuses as generated config, and the choice of home country (and
   bonus) at the start of a Long War campaign.
2. The effects, system by system: they touch the base, engineering, psi,
   gene mods, soldiers at creation, and the Foundry, which exist now.
