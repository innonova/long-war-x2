# long-war-x2

Long War 1.0, the mod for XCOM: Enemy Within, brought to XCOM 2: War of the
Chosen: its strategy (the base, satellites, the council, the air war), its
classes and rules, its aliens and maps, with XCOM 2's soldiers and looks.

The hard parts were explored first, each answered by a small experiment
before anything is built on it (`features/hard-parts.md`); the port's shape
and order are proposed in `features/port-plan.md`.

## Where it stands (2026-11-01)

- **Enemy Within's aliens** load in XCOM 2 from the player's converted EW
  packages: the Floater in a mission, animated, with its effects.
- **Enemy Within's maps** come across as the ground of XCOM 2 missions: the
  small scout crash site with EW's textures, cover and paths built by XCOM
  2, played in a quick launch mission and in a campaign mission.
- **Long War's air war** runs as an XCOM 2 screen with Long War's exact
  rules, its state in the campaign.
- **Long War's soldiers**: its eight subclasses as XCOM 2 classes with Long
  War's perk trees (three choices a rank, one free), generated from Long
  War's own config; eleven of its own perks working with its numbers
  (`features/lw-classes.md`).
- **A strategy layer of our own**: a Long War headquarters screen sends a
  squad on a mission through XCOM 2's mission path and shows the outcome
  when it comes back.

Everything above is a first version behind development switches
(`LongWarX2/Config/XComLWAirWar.ini`), checked on the test machine
(`tools/test/`).

## What it is made of

- Our own code, MIT licensed (`LICENSE`).
- Nothing of either game. XCOM 2's own content is used the way its mod
  tools allow; Enemy Within's (its aliens, its maps) only from the player's
  own install, converted on their machine.

Not affiliated with or endorsed by Firaxis Games, 2K or Long War Studios.
XCOM is a trademark of Take-Two Interactive Software, Inc.

## Related

- [innonova/upkit](https://github.com/innonova/upkit): reads and writes
  Enemy Within's packages; where Long War 1.0's rules are read from.
- [innonova/xcom-ew-lw-tree](https://github.com/innonova/xcom-ew-lw-tree):
  the Long War Tech Tree, whose models of Long War's research, Foundry,
  council and air war are checked against real campaigns.
