---
title: "A test harness for Enemy Within with Long War: run it as XCOM 2 is run, to compare the port with the original"
status: in-progress
priority: 12
dependsOn: []
---

# A test harness for Enemy Within with Long War

## Purpose

The person's idea: drive Enemy Within with Long War the way `tools/test`
drives XCOM 2, so the two can be compared and contrasted. It also answers
what Long War's code does not show: what lives in Enemy Within's native
code (the arc thrower's stun chance, how a rocket is displaced) can be
measured in the original instead of approximated. And it lets screens and
numbers be put side by side.

## What exists to build on

- The test machine has Enemy Within with stock Long War 1.0 installed
  (`C:\Program Files (x86)\Steam\steamapps\common\XCom-Enemy-Unknown\XEW`),
  its own saves and logs under `Documents\My Games\XCOM - Enemy Within`.
- `tools/test`'s screen capture, keys, clicks and remote runs (`on.sh`,
  `shot.ps1`, `key.ps1`, `click.ps1`) work on any game window.
- EW's log records its map loads (`LoadMap: XComShell`, `LoadMap: Command1`)
  and its screens' inits (`UIShell:OnInit`): usable "ready" markers.
- `../xcomsave` reads an EW strategy save into JSON and writes it back
  (`xcom2json`, `json2xcom`; tactical saves are only partly read). Built
  here (`cmake -S ../xcomsave -B /tmp/lwx2-xcomsave`), it read a Geoscape
  autosave of the test machine (version 16, game 55, December 2016).
- EW's base config names a console (`ConsoleClassName=Engine.Console`,
  `ConsoleKey=Tilde`, `TypeKey=Backslash`); whether the shipped game opens
  it is to be tried.

## Plan

1. **Start, stop, see**: `tools/ew-test/start-ew.ps1` (EW windowed, XCOM 2
   stopped first, ready at the shell screen's init), `stop-ew.ps1`; the
   screenshots and input from `tools/test`.
2. **Read its state**: `tools/ew-test/save.sh` fetches the newest save and
   reads it with `xcom2json`.
3. **A console, if EW keeps one**: then EW's cheat commands and `exec`
   lines give the same kind of control as XCOM 2's control port.
4. **Prepared situations**: a save written with `json2xcom` (a soldier, an
   item, a research state), loaded, then measured; the first measurements
   are those the port approximates (stun chance by health, rocket
   scatter, psi chances).

## Report (2026-11-02, started)

**Enemy Within with Long War starts, shows, and takes mouse input under
the harness; its saves are read.**
- `tools/ew-test/start-ew.ps1` starts it as a player does: through Steam
  (`steam://rungameid/200510`), clicking the XCOM launcher's Enemy Within
  button. Started by itself, `XComEW.exe` had Steam start the app's
  default, Enemy Unknown's `XComGame.exe` (seen: EU's menu), and a
  `steam_appid.txt` beside it made it exit at once (removed again). It
  sets the game windowed at 1600 × 900 in its own `XComEngine.ini`. The
  main menu ("LONG WAR", "LOAD GAME" …) was up after 19 s.
- **The install is stock Long War 1.0**: its `DefaultGameCore.ini`,
  `XComGame.upk` and `XComStrategyGame.upk` hash the same as the stock
  installer's files in the Tree's samples. (Its old saves say "LWR v2.06",
  from an earlier install.)
- **Mouse: yes** (`tools/test/click-screen.ps1`: LOAD GAME opened the load
  screen, BACK closed it). **Keyboard: not yet**: neither Right on the
  menu nor Tilde did anything, even after a click into the window; EW may
  read the keyboard another way than XCOM 2. So whether it keeps a console
  is still open.
- `save.sh` and `xcomsave` read its saves into JSON.

### Left open

- The keyboard (and with it the console).
- Starting a campaign and reaching a mission by clicks; then the first
  measurements (stun chance by health, rocket scatter).
