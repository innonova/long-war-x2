# Runs one of these scripts in the logged-in user's desktop session, waits for it,
# and prints what it printed (the session has no console of ours: through a file).
param([Parameter(Mandatory)][string]$Script, [Parameter(ValueFromRemainingArguments)][string[]]$Rest)
$path = Join-Path $PSScriptRoot $Script
$id = [guid]::NewGuid().ToString('N')
$out = Join-Path $env:TEMP "lwx2-desktop-$id.txt"
$wrapper = Join-Path $env:TEMP "lwx2-desktop-$id.ps1"
$quoted = if (-not $Rest) { '' } else { ($Rest | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ' ' }
Set-Content $wrapper "& '$path' $quoted *> '$out'"
$name = "lwx2-" + [IO.Path]::GetFileNameWithoutExtension($Script)
# Through a headless console host: Windows Terminal would otherwise show a window even for -WindowStyle Hidden.
$a = New-ScheduledTaskAction -Execute "conhost.exe" -Argument "--headless powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$wrapper`""
$p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
Register-ScheduledTask -TaskName $name -Action $a -Principal $p -Force | Out-Null
Start-ScheduledTask -TaskName $name
do { Start-Sleep -Milliseconds 300 } while ((Get-ScheduledTask -TaskName $name).State -eq 'Running')
Unregister-ScheduledTask -TaskName $name -Confirm:$false
if (Test-Path $out) { Get-Content $out; Remove-Item $out }
Remove-Item $wrapper -ErrorAction SilentlyContinue
