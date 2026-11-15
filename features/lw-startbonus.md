---
title: "Long War's home country and its bonuses: the starting bonus and the country bonuses"
status: in-progress
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

## Report (2026-11-15, the start screen and what acts at the start)

The person (2026-11-15): start bonuses and officers aren't his to decide; follow Long War's
code. So this follows `XGContinentUI`, `XGHeadQuarters.HasBonus` and the code that asks it.

Built and seen in the game on wingpu:

- **The bonuses as config.** `scripts/strategy-config.mjs` writes `[LongWarX2.LWBonuses]`
  in `XComLWStrategy.ini`. That is all 62 of `ItemBalance_Classic`'s bonus lines (39
  starting, 16 country, 5 continent, in order, the commented-out ones left out, as the game
  reads it), plus `Scale` (FundingBalance 8 to 11).
- **`LWBonuses.Has(type)`** is Long War's `HasBonus`, the sum of every bonus of the type that
  holds:
  - a starting bonus holds when its option was chosen with its home country;
  - a country's holds while that country (not home) is under a satellite and on the council;
  - a continent's holds while all its countries are under satellites.

  The types are named after the stock bonus that carries each. They were read off the
  decompiled `HasBonus` calls (the enum names there are garbled, `eCB_Experts_<n>`, type =
  6 + (n + 1) / 2^24), and the ini's comments agree for every type checked.
- **The words** come from the player's Long War. `lw-words.mjs` `makeBonusWords` writes
  `Localization/LongWarX2.int` (gitignored) with each type's name and description, plus
  the start screen's labels. The setup and `write-words.mjs` write it beside
  `XComGame.int`.
- **The start screen** (`UILWStartSelect`) uses Enemy Within's own ContinentSelect movie,
  from the converted strategy UI package, driven as Long War drives it. It shows on the
  first opening of the Long War Geoscape in a campaign not yet begun, over the black
  backdrop the Situation Room uses.
  - Its 40 options are the (option, country) pairs. Each line shows the country and its
    bonus's name ("MEXICO: WEALTHY BENEFACTOR").
  - The info panel shows the country, its starting money, the bonus's words with its
    number, and the continent bonus.
  - Click or arrows select, double click, Enter or Begin Game start. There is no way back.
- **What it begins with** (`XComGameState_LWStrategy.GetOrCreate(home, option)`): the home
  country's satellite, Long War's objectives aimed at the home, and the jets based on the
  home continent.
- **Acting at the start** (`LWBonusEffects.AtStart`, `LWBase.Generate`):
  - Wealthy Benefactor's money.
  - The Foundry projects granted: Resourceful (with Advanced Salvage), Jai Jawan, Sukhoi
    Company, Their Finest Hour, For the Sake of Glory.
  - Jai Jawan's two interceptors.
  - Ring of Fire's steam vents.
  - Cheyenne Mountain's lifts, and its cheaper digging.
  - Skunkworks' Foundry, Advanced Preparations' lab and workshop, Roscosmos's second small
    radar, Wei Renmin Fuwu's repair bay and workshop.
- **Per soldier** (`LWBonusEffects.GiveSoldier`, once each, in the arming pass):
  - every recruit's: Pax Nigerina, SAS, Patriae Semper Vigilis, Survival Training;
  - then, once the soldier has a Long War class, its base class's: 1st Recce, Southern
    Cross, Task Force Arrowhead, Spetznaz.
- **Control port:** `start` lists the options and `start <n>` chooses one; `bonuses` shows
  the home and what holds; `continue` on the start screen begins with the selected option.

Seen:

- **The screen.** 40 options with their bonuses, the info panel ("ARGENTINA, Starting:
  §500, Patriae Semper Vigilis: All soldiers receive +5 will", the continent's Power to the
  People), and Begin Game, on black.
- **Mexico, Wealthy Benefactor:** §1000 (§500 and the bonus's 500), the satellite over
  Mexico, the bonus in the events.
- **Japan, Ring of Fire:** both jets based in Asia, 4 steam vents (1 and the bonus's 3).
- **Argentina, Patriae Semper Vigilis:** every soldier +5 will (41 in the log).

### Decisions

- The option list shows the country and the bonus's name, in a smaller font. EW lists the
  country alone, which with up to five options per country can only be read through the
  info panel.
- The bonuses that come with a soldier are given when the arming pass first sees the
  soldier (the Geoscape, armory, squad select, after-action report), as they hold then.
  Long War gives them as it makes the soldier. A soldier who was already there in a
  campaign begun before this gets the country and continent bonuses holding now.
- A campaign begun before the start screen keeps the United States as home, with no
  starting bonus.

### Left open

- **The bonuses that wait on their system:**
  - SHIVs and MECs: Ghost in the Machine, Robotics, NeoPanzers, Cyberware (NeoPanzers and
    Cyberware are wired into item costs already and act once those items exist);
  - officers: the officer side of Sandhurst, and Gift of Osiris's medal hours;
  - council requests and intel: Quai d'Orsay;
  - the Illuminator Gunsight item: Ancient Artifact;
  - small slots on early armour: Jungle Scouts.
- **The country bonuses on the Situation Room,** as EW shows them.

## Report (2026-11-15, the bonuses that change a rule as it is used)

Each is asked for where its rule is, with `LWBonuses.Has`, following the Long War function
named:

- **Costs** (`LWBonusEffects`, applied where the def is read, so screens and prices agree):
  - Architects of the Future: labs and workshops, price and upkeep (`GetFacility`);
  - Power to the People: the three generators, price and upkeep;
  - Baumeister: facility build time (`GetFacilityBuildTime`);
  - Cheyenne Mountain: digging (`GetConstructionProjectCost`);
  - Air Superiority: interceptors, Firestorms and craft weapons (`GetItem`), interceptor
    orders, craft upkeep (`GetShipMaintenanceCost`);
  - NeoPanzers and Cyberware: SHIV and MEC items (`GetItem`);
  - New Warfare: Foundry projects' cash, alloys and elerium (`GetFoundryTech`);
  - Roscosmos: satellites;
  - Deus Ex: gene mods' cash, meld and hours (`BuildGeneModTech`);
  - Special Warfare School: the Officer Training School's cash (`GetOTSTech`);
  - Sandhurst: the ranks its squad sizes need (`HasOTSPrereqs`).
- **Money:** Wealth of Nations raises the council's funding (`GetIncome`). Bounties raises
  an abduction's cash, before its difficulty's scale (`DetermineAbductionReward`).
- **Research:** Expertise adds its points to every research credit, for techs and Foundry
  projects (`GetCreditAdjustedTechHours`). We Have Ways cuts autopsies and interrogations
  (`GetTech`). Jai Vidwan makes each lab adjacency worth more (`UpdateLabBonus`). The techs'
  time cuts are set again at each research sync, since country bonuses come and go with
  satellites.
- **Psi:** The Old Path cuts training time (`AddSoldier`). Legacy of Uxmal adds to the
  chance, up to 99 (`RollForGift`).
- **Fatigue:** Gift of Osiris cuts every psi power's and gene mod's hours; without it, Call
  to Arms cuts those whose line has alloys (`DetermineTimeOut`). The generator now writes
  each line's iAlloys.

Per Ardua Ad Astra now acts too, through Long War's rookie stat roll (lw-classes): its 5
points go into the pool. Seen: Australian recruits spending 42 points, Long War's 37 and 5.

Seen in the game: Cheyenne Mountain's three lifts down the shaft, and a dig in row 2 for §5
instead of §10. The rest is built and compiles, but hasn't been seen in the game yet.

## Report (2026-11-15, the bonuses that make soldiers)

Long War's `XGFacility_Barracks.InitNewGame`: Foreign Legion adds its number of recruits,
Kiryu-Kai Commander a Japanese soldier of its rank in a random base class, Cadre four of its
rank, one of each base class. They are made the way XCOM 2 makes its starting soldiers (the
character pool, kit, barracks: `LWBonusEffects.NewSoldier`). A ranked one gets one of its
base class's two Long War classes at random, ranks up to the bonus's rank, and gets the
experience that rank needs, so no promotion waits. Like every recruit, they then get the
rookie stat roll and the soldier bonuses.

Seen (Canada, Cadre): Édith Girard as a sniper, François Thomas as a rocketeer, Thor Jensen
as a medic, Kate Hill as infantry, all at rank 3, with rolled stats.

### Decisions

- Which of a base class's two Long War classes a made soldier gets is random. Long War
  creates them in the base class, and its subclass follows from the perk taken later. The
  port has no base-class stage.

Xenological Remedies acts now too, on the grey market's corpse prices (lw-greymarket): Sectoid corpses at §4 instead of §2 with China's.
