# Starts the SDK's editor in the desktop session, maximized, and waits for its window.
param([int]$TimeoutSeconds = 240, [string]$Extra = '-d3d11')
$sdk = "C:\Program Files (x86)\Steam\steamapps\common\XCOM 2 War of the Chosen SDK"
$exe = "$sdk\Binaries\Win64\XComGame.exe"
Get-Process XComGame -ErrorAction SilentlyContinue | Stop-Process -Force
$a = New-ScheduledTaskAction -Execute $exe -Argument "editor -noscriptcompile -nogadwarning $Extra" -WorkingDirectory (Split-Path $exe)
$p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
Register-ScheduledTask -TaskName lwx2-editor -Action $a -Principal $p -Force | Out-Null
Start-ScheduledTask -TaskName lwx2-editor
$t0 = Get-Date
do { Start-Sleep 3; $proc = Get-Process XComGame -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match 'Unreal Editor' } } until ($proc -or ((Get-Date) - $t0).TotalSeconds -gt $TimeoutSeconds)
Unregister-ScheduledTask -TaskName lwx2-editor -Confirm:$false
if ($proc) { "editor up after {0:N0} s: {1}" -f ((Get-Date) - $t0).TotalSeconds, $proc.MainWindowTitle } else { "no editor window after $TimeoutSeconds s"; exit 1 }
