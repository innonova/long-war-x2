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

The game runs windowed at 1600x900, so a whole screenshot shows it; clicks
are given in the UI's own 1920x1080 coordinates and scaled to the window.

The main menu has a test campaign button (behind `ShowTestCampaign` in
`Config/XComLWAirWar.ini`): the game's own "Debug NonCheat Start", a new
campaign without its first mission. It saves like any campaign; back up the
player's `SaveData` first and remove the test saves after.
