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

## What Long War keeps (the Tree's samples, Long War 1.0d)

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

## Questions before building it

- **How Long War assigns the starting bonus.** The player picks the
  country; is the bonus then picked by the player, or drawn among the
  country's? The ini does not say.
- **When a country bonus applies**: with a satellite over the country,
  or while it stays in the council?
- **The columns' exact meaning** (`iAlloys`), to be confirmed from Long
  War's code (`XGStrategy` / `XGHeadquarters`), as was done for psi.

## Steps (proposed)

1. The bonuses as generated config, and the choice of home country (and
   bonus) at the start of a Long War campaign.
2. The effects, system by system: they touch the base, engineering, psi,
   gene mods, soldiers at creation, and the Foundry, which exist now.
