---
title: "Long War's officers: the Officer Training School's officer ranks and their abilities"
status: planned
priority: 33
dependsOn: [lw-base, lw-classes, lw-missions]
---

# Long War's officers

The Officer Training School's squad sizes are in (`lw-missions.md`). Its
other five projects make officers. A soldier promoted to an officer rank
gains officer abilities, and a squad's officers bring their bonuses to the
mission.

## What Long War keeps (the Tree's samples, Long War 1.0d)

- **The projects** (`OTSBalance`, eTech 3 to 7): Lieutenant §100, Captain
  §200, Major §300, Colonel §400, Field Commander §500. Each is available
  once the barracks' ranks add up to 20, 45, 75, 110 and 150.
- **Officers per rank** (`ContBalance_Classic[0]`, a reused array; its
  comment names the columns): 3 lieutenants, 2 captains, 2 majors,
  2 colonels, 1 field commander.
- **The abilities** (its `XComStrategyGame.int`, `OTSTechSummary`):
  - Lieutenant: Lead By Example (the officer's will to nearby soldiers,
    and the Command ability), and Legio Patria Nostra (will:
    `INTERNATIONAL_WILL`, 1 per nationality) or Stay Frosty (fatigue);
  - Captain: Semper Vigilans (defence) or Fortiores Una (cover damage
    reduction near the officer); +1 Command charge;
  - Major: Into the Breach (mission XP for lower ranks) or So Shall You
    Fight (kill XP); +1 Command charge;
  - Colonel: Band of Warriors (aim for continent bonuses) or Esprit de
    Corps (will and defence); +1 Command charge;
  - Field Commander: So Others May Live (aim and will after missions with
    no deaths) or Combined Arms (lower enemy damage reduction); +1 Command
    charge.

## Questions before building it

- How a soldier becomes an officer: a promotion chosen by the player,
  limited by the counts above?
- The abilities' numbers, beyond `INTERNATIONAL_WILL`: from Long War's code
  (as was done for psi and the bonuses), or its constants.
- How this sits with XCOM 2's ranks, which the classes already use.
