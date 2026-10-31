# Stops the game and puts the player's mod list back.
. (Join-Path $PSScriptRoot 'game.ps1')
Get-Process XCom2 -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
if (Test-Path "$ModOptions.lwx2-backup") { Move-Item "$ModOptions.lwx2-backup" $ModOptions -Force; "mod list restored" }
