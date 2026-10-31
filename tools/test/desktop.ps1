# Runs one of these scripts in the logged-in user's desktop session and waits for it.
param([Parameter(Mandatory)][string]$Script, [Parameter(ValueFromRemainingArguments)][string[]]$Rest)
$path = Join-Path $PSScriptRoot $Script
$argsLine = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$path`" " + (($Rest | ForEach-Object { "`"$_`"" }) -join ' ')
$name = "lwx2-" + [IO.Path]::GetFileNameWithoutExtension($Script)
$a = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argsLine
$p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
Register-ScheduledTask -TaskName $name -Action $a -Principal $p -Force | Out-Null
Start-ScheduledTask -TaskName $name
do { Start-Sleep -Milliseconds 300 } while ((Get-ScheduledTask -TaskName $name).State -eq 'Running')
Unregister-ScheduledTask -TaskName $name -Confirm:$false
