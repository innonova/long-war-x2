# Driving the game on the test machine

For checking the mod in War of the Chosen on a Windows machine reached over
ssh (wingpu). An ssh session has no desktop, so anything that shows or
clicks runs in the logged-in user's session as a scheduled task
(`desktop.ps1`). Run from the repository's checkout there:

    pwsh tools\test\start-game.ps1            # only our mod enabled; waits for the main menu
    pwsh tools\test\desktop.ps1 shot.ps1 C:\path\shot.png
    pwsh tools\test\desktop.ps1 click.ps1 960 540   # a point in the game's 1920x1080 UI
    pwsh tools\test\stop-game.ps1             # stops it; the player's mod list put back

The game runs windowed at 1600x900, so a whole screenshot shows it; clicks
are given in the UI's own 1920x1080 coordinates and scaled to the window.
