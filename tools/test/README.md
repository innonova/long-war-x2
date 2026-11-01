# Driving the game on the test machine

For checking the mod in War of the Chosen on a Windows machine reached over
ssh (wingpu). An ssh session has no desktop, so anything that shows or
clicks runs in the logged-in user's session as a scheduled task
(`desktop.ps1`). Run from the repository's checkout there:

    pwsh tools\test\build.ps1                 # the mod built into the game; errors and warnings
    pwsh tools\test\start-game.ps1            # only our mod enabled; waits for the main menu
    pwsh tools\test\desktop.ps1 shot.ps1 C:\path\shot.png
    pwsh tools\test\desktop.ps1 click.ps1 960 540   # a point in the game's 1920x1080 UI
    pwsh tools\test\stop-game.ps1             # stops it; the player's mod list put back
    pwsh tools\test\desktop.ps1 key.ps1 W 1500    # holds a key (scan code) in the focused window

From this machine, `tools/test/on.sh '<line>' …` runs lines in the desktop session
(through `am exec`), and `tools/test/quick-launch-view.sh <png>` runs the whole check of
experiment 2: build, start, the Tactical Quick Launch screen, a generated map (the screen
draws the world only then), the debug camera held by the mod at the view in
`Config/XComLWAirWar.ini`, a screenshot copied back.
`tools/test/campaign-mission.sh <png> [--launch]` does the same for a campaign:
a new test campaign, the LONG WAR HQ, and with `--launch` a mission played
until the soldiers can move.

## Driving it without the mouse: the control port

A development build listens on a TCP port on the test machine (`LWX2Control`,
`ControlPort=7531` in `Config/XComLWAirWar.ini`; 0, off, in the player's build).
It takes one command a line and answers in lines ending with a line holding a
single `.`. From this machine:

    tools/test/lw.sh help                      # the commands
    tools/test/lw.sh ping screens              # the screen on top; the screen stack
    tools/test/lw.sh geoscape geo              # the Geoscape opened; its state, a line a thing
    tools/test/lw.sh 'run 720' decisions       # time run until something wants a decision
    tools/test/lw.sh 'act 0'                   # that decision taken (intercept, assault, respond)
    tools/test/lw.sh 'intercepted 3 0 0'       # an interception's result without the air war
    tools/test/lw.sh 'sat build' 'sat launch 4'
    tools/test/lw.sh win                       # the mission ended as won (any campaign mission)
    tools/test/lw.sh 'exec <console command>'
    tools/test/lw-dump.sh /tmp/state.txt [Unit]  # the whole game state, all fields, to grep
    tools/test/lw.sh 'run 720 all'             # a month with the player answering nothing
    tools/test/lw.sh 'resolve 0 won'           # a decision taken without playing it (air war fought, mission result given)
    tools/test/lw.sh 'auto 2160 70 2 sats'     # three months at full speed: every decision taken, missions won 70 % (a captive when it can),
                                               # interceptions fought on Aggressive, satellites bought, the base grown for uplinks,
                                               # interceptors replaced, research kept going (about a second)
    tools/test/lw.sh research 'research 0'     # XCOM 2's research list (Long War's techs, hours, affordable); one started
    tools/test/lw.sh builds 'build 215 2'      # engineering: what can be built (Long War's item numbers); 2 laser rifles begun
    tools/test/lw.sh 'give AlienAlloy 50'      # items put in the stores (a test aid; any item template)
    tools/test/lw.sh 'exec GiveTech LWTech_LaserWeapons'  # a tech researched at once (XCOM 2's cheat)
    tools/test/lw.sh continue                  # the top screen passed (reports, loot, alerts, tips)
    tools/test/lw.sh 'key 510'                 # any input (UIUtilities_Input codes: 510 Esc)

And around it:

    tools/test/sync-build.sh                   # this working tree built on wingpu (game stopped, patch applied)
    tools/test/new-campaign.sh [0-3] [--first] # game started, new campaign, reports passed, Geoscape open (~45 s)
    tools/test/shot.sh /tmp/shot.png           # a screenshot copied here
    tools/test/to-mission.sh ['give-to 0 LWSmall_73' …]  # a new campaign into its first abduction, soldiers ready to move
    LWX2_EWMAP=1 tools/test/sync-build.sh      # built, and the whole EW map placed in missions (the converted map
                                               # in the checkout's Content and Config: tools/convert/README.md)
    tools/test/lw.sh enemies                   # in a mission: the aliens, their templates, tiles away
    tools/test/lw.sh endturn                   # in a mission: XCOM's turn ended (as the button)
    tools/test/lw.sh 'look -7440 2544 200'     # the camera to an EW map place (EW's coordinates; 'look pod 1'), fog off

The dump is every XCOM 2 game state object, newest version, with all its fields
(about a thousand objects, 60,000 lines, a few seconds), and the screens up. Screenshots
remain for what only they show: how a screen looks, its words, the 3D view.
The game's FileWriter does not open files in the shipped game, so the dump comes
over the socket. A firewall rule on wingpu lets XCom2.exe listen without a dialog
(`netsh advfirewall firewall add rule name="XCOM 2 WotC (LWX2 control)" …`, made over ssh).

## Long War on the test machine

wingpu has Enemy Within with Long War 1.0 installed (its own installer, silent, into
`C:\Program Files (x86)\Steam\steamapps\common\XCom-Enemy-Unknown\XEW`, 2026-11-01), so the
setup program's words step runs there for real, and words can be written in place:

    tools/test/on.sh 'node scripts\write-words.mjs "C:\Program Files (x86)\Steam\steamapps\common\XCom-Enemy-Unknown\XEW"'

## The window

The game runs windowed at 1600x900, so a whole screenshot shows it; clicks
are given in the UI's own 1920x1080 coordinates and scaled to the window.

The main menu has a test campaign button (behind `ShowTestCampaign` in
`Config/XComLWAirWar.ini`): the game's own "Debug NonCheat Start", a new
campaign without its first mission. It saves like any campaign; back up the
player's `SaveData` first and remove the test saves after.
