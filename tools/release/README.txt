Long War X2 — a preview build (@BUILD@)
=========================================

Long War 1.0 played in XCOM 2: War of the Chosen. A new campaign runs Long
War's strategy game (its Geoscape, council, panic, air war, base, research,
Foundry, engineering, psi and gene mods) on its own screens, with its eight
soldier classes, perk trees, weapons and alien squads in the missions. Long
War's numbers are stock Long War 1.0's. Where XCOM 2 has nothing of Long War's,
Enemy Within's own content is used, converted from your install: its strategy
screens (the resource bar and clock, research, the Situation Room) and,
if you choose, its maps for the missions.

What it needs
- XCOM 2 with War of the Chosen (Steam).
- XCOM: Enemy Within with Long War installed: Long War's names and words, and
  Enemy Within's screens and maps, are read from your install, not shipped.

Install
1. Unpack this whole folder anywhere.
2. Run LongWarX2-setup.exe. It finds the games through Steam, copies the mod
   into War of the Chosen's Mods folder, turns it on in the game's list of
   active mods (your other mods stay on), writes Long War's words and converts
   Enemy Within's strategy screens. It then asks whether to convert Enemy
   Within's maps for the missions: about 18 GB and a few minutes; without them
   the missions play on XCOM 2's maps. Converted content is kept when you run
   a newer build's setup.
   (Windows may warn about an unknown publisher: the program is not signed.)
   If a game is elsewhere: LongWarX2-setup.exe --xcom2 "<…\XCOM 2\XCom2-WarOfTheChosen>" --ew "<…\XCom-Enemy-Unknown\XEW>"
   Without asking: --maps or --no-maps.
3. Start XCOM 2: War of the Chosen from Steam and begin a new campaign. (If you
   use a mod launcher such as the Alternative Mod Launcher, tick "Long War X2"
   there, as it rewrites the list of active mods when it starts the game.)

Remove: LongWarX2-setup.exe --uninstall (removes the folder and takes it off the list).

A preview: much is still plain (our own buttons and text where Enemy Within's
screens are not wired yet), the aliens are XCOM 2's stand-ins for Long War's,
and Enemy Within's maps do not all look right yet. Saves made with the mod may
not load without it. What is done and what is not: STATUS.md in the source.

Source and notes: https://github.com/innonova/long-war-x2
