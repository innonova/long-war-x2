# Starts Enemy Within (Long War installed) windowed, as XCOM 2's start-game.ps1 starts XCOM 2 (both games are never up
# at once: XCOM 2 is stopped first), and waits until its main menu is up (its shell screen's init in the log).
param([int]$TimeoutSeconds = 180)
. (Join-Path $PSScriptRoot 'ew.ps1')
Get-Process XCom2, XComEW -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
if (Test-Path $EWLog) { Remove-Item $EWLog -Force -ErrorAction SilentlyContinue }
$a = New-ScheduledTaskAction -Execute $EWExe -Argument "-windowed -ResX=1600 -ResY=900 -nostartupmovies -log" -WorkingDirectory (Split-Path $EWExe)
$p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
Register-ScheduledTask -TaskName lwx2-ew -Action $a -Principal $p -Force | Out-Null
Start-ScheduledTask -TaskName lwx2-ew
$t0 = Get-Date
do {
  Start-Sleep 3
  $ready = (Test-Path $EWLog) -and (Select-String -Path $EWLog -Pattern 'UIFinalShell:OnInit|UIShell:OnInit' -Quiet)
} until ($ready -or ((Get-Date) - $t0).TotalSeconds -gt $TimeoutSeconds)
Unregister-ScheduledTask -TaskName lwx2-ew -Confirm:$false
Start-Sleep 5
if ($ready) { "EW main menu up after {0:N0} s" -f ((Get-Date) - $t0).TotalSeconds } else { "no EW main menu after $TimeoutSeconds s"; exit 1 }
