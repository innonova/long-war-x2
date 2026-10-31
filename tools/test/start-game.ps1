# Starts War of the Chosen with only our mod enabled (the player's list kept
# aside until stop-game.ps1) and waits until the main menu is up.
param([int]$TimeoutSeconds = 180)
. (Join-Path $PSScriptRoot 'game.ps1')
Get-Process XCom2 -ErrorAction SilentlyContinue | Stop-Process -Force
if (-not (Test-Path "$ModOptions.lwx2-backup")) { Copy-Item $ModOptions "$ModOptions.lwx2-backup" }
# Keep the file's own sections ([IniVersion]): without them the game rewrites it and drops ours.
$lines = Get-Content $ModOptions | Where-Object { $_ -notmatch '^ActiveMods=' }
Set-Content $ModOptions ($lines | ForEach-Object { $_; if ($_ -eq '[Engine.XComModOptions]') { 'ActiveMods="LongWarX2"' } })
$exe = "$GameDir\Binaries\Win64\XCom2.exe"
$a = New-ScheduledTaskAction -Execute $exe -Argument "-review -noRedScreens -nostartupmovies -windowed -ResX=1600 -ResY=900" -WorkingDirectory (Split-Path $exe)
$p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
Register-ScheduledTask -TaskName lwx2-game -Action $a -Principal $p -Force | Out-Null
Start-ScheduledTask -TaskName lwx2-game
$t0 = Get-Date
do {
  Start-Sleep 3
  $ready = (Test-Path $GameLog) -and (Select-String -Path $GameLog -SimpleMatch 'LongWarX2: air war button on' -Quiet)
} until ($ready -or ((Get-Date) - $t0).TotalSeconds -gt $TimeoutSeconds)
Unregister-ScheduledTask -TaskName lwx2-game -Confirm:$false
Start-Sleep 5
& (Join-Path $PSScriptRoot 'desktop.ps1') focus.ps1
if ($ready) { "main menu up after {0:N0} s" -f ((Get-Date) - $t0).TotalSeconds } else { "no main menu after $TimeoutSeconds s"; exit 1 }
