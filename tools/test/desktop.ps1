# Runs one of these scripts in the logged-in user's desktop session and waits for it.
param([Parameter(Mandatory)][string]$Script, [Parameter(ValueFromRemainingArguments)][string[]]$Rest)
$path = Join-Path $PSScriptRoot $Script
$argsLine = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$path`" " + (($Rest | ForEach-Object { "`"$_`"" }) -join ' ')
$name = "lwx2-" + [IO.Path]::GetFileNameWithoutExtension($Script)
# Through a headless console host: Windows Terminal would otherwise show a window even for -WindowStyle Hidden.
$a = New-ScheduledTaskAction -Execute "conhost.exe" -Argument "--headless powershell.exe $argsLine"
$p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
Register-ScheduledTask -TaskName $name -Action $a -Principal $p -Force | Out-Null
Start-ScheduledTask -TaskName $name
do { Start-Sleep -Milliseconds 300 } while ((Get-ScheduledTask -TaskName $name).State -eq 'Running')
Unregister-ScheduledTask -TaskName $name -Confirm:$false
